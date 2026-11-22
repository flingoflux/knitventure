#!/bin/sh
# quality-gate.sh – generisches Qualitäts-Gate für das Ende eines Agenten-Turns (Stop-Event).
#
# Idee: Der Agent darf erst "fertig" melden, wenn ein Prüfbefehl grün ist. Das Werkzeug
# (nicht das Modell) ruft dieses Skript auf; schlägt der Check fehl, blockiert es das
# Beenden und gibt dem Agenten eine verwertbare Begründung zurück.
#
# Konfiguration über Umgebungsvariablen (alles projektspezifische steht beim Aufrufer):
#   QG_COMMAND  Pflicht. Prüfbefehl, läuft per `sh -c` im Projektwurzelverzeichnis.
#               Beispiel: 'cd backend && ./mvnw -q test'
#   QG_NAME     Name des Checks in Meldungen (Default: "Quality-Gate").
#   QG_PATHS    Leerzeichen-getrennte Pfade relativ zur Wurzel. Der Check läuft nur, wenn
#               `git status --porcelain` dort Änderungen zeigt (Default: ".").
#   QG_ROOT     Projektwurzel (Default: $CLAUDE_PROJECT_DIR, sonst Git-Toplevel, sonst pwd).
#   QG_TAIL     Anzahl Ausgabezeilen, die der Agent als Feedback bekommt (Default: 40).
#   QG_LOCK_WAIT  Sekunden, die auf ein parallel laufendes Gate gewartet wird (Default: 600).
#   QG_PAUSE_FILE Pausenschalter, relativ zur Projektwurzel (Default: .agents/hooks/.qg-pause).
#               Existiert die Datei, läuft kein Check: Hinweis auf stderr, exit 0. Leer gesetzt
#               (QG_PAUSE_FILE=) gibt es keinen Pausenschalter – so ruft der Git-Hook das Gate auf.
#
# Pausenschalter – nur für den Menschen:
#   Manchmal ist ein roter Test als Zwischenstand gewollt (Test zuerst nachstellen, dann fixen).
#   Dann pausiert ein MENSCH das Gate bewusst und hebt die Pause danach wieder auf:
#     touch .agents/hooks/.qg-pause      # Gate pausiert
#     rm .agents/hooks/.qg-pause         # Gate wieder scharf
#   Der Agent legt diesen Schalter nie selbst um. Die Deny-Regeln sperren die Datei-Werkzeuge
#   für .agents/hooks/**; der Umweg über die Shell bleibt möglich und muss beobachtet werden.
#
# Eingabe: JSON des Werkzeugs auf stdin (bei Claude Code u. a. "stop_hook_active").
#
# Exit-Codes – das ist der Kern der Übung:
#   0  grün, nichts geändert, Gate pausiert oder nicht konfiguriert -> Agent darf aufhören.
#   2  rot -> das Werkzeug BLOCKIERT das Beenden und reicht stderr an den Agenten weiter.
#      Nur exit 2 blockiert. exit 1 (oder jeder andere Code) gilt als "nicht blockierender
#      Fehler": Die Meldung sieht höchstens der Mensch, der Agent hört trotzdem auf.
#      Ein Gate mit exit 1 ist also nur eine Bitte.
#
# Als Git-Hook oder in CI funktioniert dasselbe Skript: Dort bricht jeder Code != 0 ab.
#
# Test von Hand (aus der Projektwurzel):
#   echo '{"stop_hook_active":false}' | QG_NAME=Demo QG_COMMAND=false sh .agents/hooks/quality-gate.sh; echo $?

set -u

QG_NAME=${QG_NAME:-Quality-Gate}
QG_PATHS=${QG_PATHS:-.}
QG_TAIL=${QG_TAIL:-40}
QG_LOCK_WAIT=${QG_LOCK_WAIT:-600}
QG_PAUSE_FILE=${QG_PAUSE_FILE-.agents/hooks/.qg-pause}   # ohne ':' – leer heißt: kein Pausenschalter

# --- 1. Eingabe lesen (ohne jq, damit das Skript überall läuft) ---------------------------
if [ -t 0 ]; then
    input=''
else
    input=$(cat)
fi

# Endlosschleife vermeiden: Hat dieses Gate den Agenten schon einmal zurückgeschickt, setzt
# das Werkzeug stop_hook_active=true. Dann nicht erneut blockieren. Die Meldung unten
# verlangt deshalb, dass der Agent den Check nach der Korrektur selbst ausführt;
# Pre-Commit-Hook und CI fangen den Rest.
if printf '%s' "$input" | tr -d ' \t\r\n' | grep -q '"stop_hook_active":true'; then
    exit 0
fi

# --- 2. Konfiguration prüfen --------------------------------------------------------------
if [ -z "${QG_COMMAND:-}" ]; then
    echo "[quality-gate] $QG_NAME: QG_COMMAND ist nicht gesetzt – Gate übersprungen. Bitte in der Hook-Konfiguration ergänzen." >&2
    exit 0
fi

ROOT=${QG_ROOT:-${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}}
if ! cd "$ROOT" 2>/dev/null; then
    echo "[quality-gate] $QG_NAME: Projektwurzel '$ROOT' nicht gefunden – Gate übersprungen." >&2
    exit 0
fi

# --- 2b. Pausenschalter (bewusst von einem Menschen gesetzt, siehe Kopfkommentar) -----------
#         Laut auf stderr, damit eine vergessene oder vom Agenten gesetzte Pause auffällt.
if [ -n "$QG_PAUSE_FILE" ] && [ -e "$QG_PAUSE_FILE" ]; then
    echo "[quality-gate] $QG_NAME: PAUSIERT – '$QG_PAUSE_FILE' existiert, Check übersprungen. Nur ein Mensch hebt die Pause auf: rm $QG_PAUSE_FILE" >&2
    exit 0
fi

# --- 3. Nur prüfen, wenn sich im relevanten Bereich etwas geändert hat --------------------
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    set -f                          # QG_PATHS absichtlich ungequotet (Wortzerlegung), aber ohne Globbing
    changes=$(git status --porcelain -- $QG_PATHS 2>/dev/null)
    set +f
    if [ -z "$changes" ]; then
        echo "[quality-gate] $QG_NAME: keine Änderungen in '$QG_PATHS' – nichts zu prüfen."
        exit 0
    fi
fi

# --- 4. Sperre: Werkzeuge starten mehrere Stop-Hooks parallel. Zwei Builds im selben -------
#        Verzeichnis stören sich gegenseitig (z. B. target/), also nacheinander laufen lassen.
lock="${TMPDIR:-/tmp}/quality-gate-$(printf '%s' "$ROOT" | cksum | cut -d' ' -f1).lock"
have_lock=0
waited=0
while :; do
    if mkdir "$lock" 2>/dev/null; then
        echo $$ >"$lock/pid"
        have_lock=1
        break
    fi
    holder=$(cat "$lock/pid" 2>/dev/null || true)
    if [ -n "$holder" ] && ! kill -0 "$holder" 2>/dev/null; then
        rm -rf "$lock"              # verwaiste Sperre (Prozess existiert nicht mehr)
        continue
    fi
    if [ "$waited" -ge "$QG_LOCK_WAIT" ]; then
        echo "[quality-gate] $QG_NAME: Sperre nach ${QG_LOCK_WAIT}s nicht frei – laufe ohne Sperre." >&2
        break
    fi
    sleep 1
    waited=$((waited + 1))
done

out=$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/quality-gate-out.$$")
cleanup() {
    rm -f "$out"
    if [ "$have_lock" -eq 1 ]; then rm -rf "$lock"; fi
}
trap cleanup EXIT
trap 'exit 143' HUP INT TERM        # sorgt dafür, dass cleanup auch bei Abbruch/Timeout läuft

# --- 5. Check ausführen -------------------------------------------------------------------
sh -c "$QG_COMMAND" >"$out" 2>&1
rc=$?

if [ "$rc" -eq 0 ]; then
    echo "[quality-gate] $QG_NAME: grün."
    exit 0
fi

# --- 6. Rot: begründet blockieren ---------------------------------------------------------
# Ein Guard, der nur "nein" sagt, macht den Agenten kreativ. Einer, der sagt warum, macht
# ihn korrekt. Deshalb: welcher Check, was genau, was jetzt zu tun ist.
{
    echo "[quality-gate] Check \"$QG_NAME\" ist fehlgeschlagen (Exit-Code $rc). Du bist noch NICHT fertig."
    echo "Befehl: $QG_COMMAND"
    echo "--- letzte $QG_TAIL Zeilen der Ausgabe ---"
    tail -n "$QG_TAIL" "$out"
    echo "--- Was jetzt zu tun ist ---"
    echo "1. Lies die Meldung oben und finde die Ursache in deinen Änderungen."
    echo "2. Behebe die Ursache im Produktionscode."
    echo "3. Ändere NICHT den Test, die Prüfregel, diesen Hook oder seine Konfiguration, um den Check grün zu bekommen, und schalte nichts ab."
    echo "4. Führe danach den Befehl oben selbst aus und melde dich erst fertig, wenn er grün ist."
    echo "5. Hältst du den Check selbst für falsch, hör auf und erkläre das dem Menschen, statt ihn zu umgehen."
} >&2
exit 2
