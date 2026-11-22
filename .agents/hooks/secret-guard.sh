#!/bin/sh
# secret-guard.sh – PreToolUse-Guard: hält Secrets aus dem Kontext des Agenten.
#
# Läuft VOR jedem Werkzeugaufruf (Read, Edit, Write, Bash, Grep, Glob …), liest das JSON des
# Aufrufs von stdin und prüft Pfade, Suchmuster und Shell-Kommandos. Trifft ein Sperrmuster,
# wird der Aufruf mit exit 2 abgebrochen und der Agent bekommt auf stderr eine Begründung
# und eine erlaubte Alternative.
#
# Warum zusätzlich zu Deny-Regeln? Deny-Regeln für Read/Edit greifen nur bei den Datei-
# Werkzeugen. `cat .env` über die Shell ist ein anderes Werkzeug. Dieser Guard schaut auch
# in Shell-Kommandos – aber nur nach bekannten Mustern. Eine echte Grenze ist erst eine
# Sandbox ohne Secrets darin.
#
# Konfiguration (Umgebungsvariablen; geprüft wird gegen den KLEINGESCHRIEBENEN Text,
# Muster also kleinschreiben):
#   SG_PATTERN  erweiterter regulärer Ausdruck (grep -E) für gesperrte Namen.
#               Default: .env-Dateien (.env, .env.local, …) und alles mit "secret".
#   SG_ALLOW    ERE für erlaubte Ausnahmen; Treffer werden vor der Prüfung entfernt.
#               Default: .env.example / .env.sample / .env.template (Struktur ohne Werte).
#               Darf kein '#' enthalten.
#
# Exit-Codes: 0 = erlaubt, 2 = blockiert (exit 1 würde den Aufruf NICHT verhindern).
#
# Test von Hand:
#   echo '{"tool_name":"Bash","tool_input":{"command":"cat .env"}}' | sh .agents/hooks/secret-guard.sh; echo $?

set -u

SG_PATTERN=${SG_PATTERN:-'(^|[^a-z0-9_])\.env($|[^a-z0-9_-])|secret'}
SG_ALLOW=${SG_ALLOW:-'\.env\.(example|sample|template)'}

if [ -t 0 ]; then
    exit 0
fi
input=$(cat)

# --- 1. Relevante Felder aus dem JSON holen ----------------------------------------------
# Geprüft werden nur Pfade, Datei-Globs und Shell-Kommandos – nicht der Inhalt von Edits
# und nicht das Suchmuster von Grep (sonst wäre schon die Suche nach "process.env" tabu).
if command -v jq >/dev/null 2>&1; then
    tool=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null)
    fields=$(printf '%s' "$input" | jq -r '
        (.tool_input // {}) as $t
        | [$t.file_path, $t.notebook_path, $t.path, $t.glob, $t.command,
           (if .tool_name == "Glob" then $t.pattern else null end)]
        | map(select(type == "string")) | .[]' 2>/dev/null)
else
    # Fallback ohne jq: grobe, aber robuste Extraktion per grep.
    tool=$(printf '%s' "$input" | grep -oE '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:[[:space:]]*"//; s/"$//')
    keys='file_path|notebook_path|path|glob|command'
    [ "$tool" = "Glob" ] && keys="$keys|pattern"
    fields=$(printf '%s' "$input" | grep -oE "\"($keys)\"[[:space:]]*:[[:space:]]*\"([^\"\\\\]|\\\\.)*\"")
fi

[ -z "$fields" ] && exit 0

# --- 2. Prüfen: kleinschreiben, erlaubte Ausnahmen entfernen, Sperrmuster suchen ----------
hit=$(printf '%s\n' "$fields" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E "s#${SG_ALLOW}##g" \
    | grep -E "$SG_PATTERN" \
    | head -n 1)

[ -z "$hit" ] && exit 0

# --- 3. Blockieren – mit Begründung und Alternative ---------------------------------------
# Ein Guard, der nur "nein" sagt, erzeugt Umgehungsversuche (cat, grep, base64 …).
# Einer, der sagt warum und was stattdessen geht, führt den Agenten zum richtigen Weg.
shown=$(printf '%s' "$hit" | cut -c1-200)
{
    echo "[secret-guard] BLOCKIERT: ${tool:-Werkzeug}-Aufruf auf \"$shown\"."
    echo "Warum: .env-Dateien und alles mit \"secret\" im Namen enthalten typischerweise Zugangsdaten."
    echo "Was in deinem Kontext landet, gilt als geleakt: Es geht an den Modellanbieter und steht in Transkripten und Logs."
    echo "Stattdessen:"
    echo "- Brauchst du eine Konfiguration, frag den Menschen nach dem NAMEN der Variable (z. B. DB_PASSWORD) und verwende im Code nur diesen Namen. Werte gehören nie in den Kontext."
    echo "- Für die Struktur ohne Werte ist .env.example erlaubt."
    echo "- Versuche NICHT, diese Sperre über andere Befehle oder Pfade zu umgehen. Ist die Aufgabe ohne den Wert nicht lösbar, hör auf und sag das dem Menschen."
} >&2
exit 2
