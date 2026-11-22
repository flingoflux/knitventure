import argparse
import json
import re
import time
from pathlib import Path
from urllib.error import URLError
from urllib.request import HTTPRedirectHandler, build_opener

import yaml
from jsonschema import Draft202012Validator
from openapi_spec_validator import validate


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, request, response, code, message, headers, url):
        return None


def require(condition, message):
    if not condition:
        raise ValueError(message)


def fetch(base_url, path, retry=False):
    opener = build_opener(NoRedirect)
    attempts = 30 if retry else 1
    for attempt in range(attempts):
        try:
            with opener.open(base_url + path, timeout=5) as response:
                return response.status, response.headers.get_content_type(), response.read()
        except (URLError, TimeoutError):
            if attempt == attempts - 1:
                raise
            time.sleep(1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("base_url", nargs="?")
    parser.add_argument("--contract", type=Path, default=Path("api/openapi.yaml"))
    args = parser.parse_args()

    contract = yaml.safe_load(args.contract.read_text(encoding="utf-8"))
    validate(contract)
    responses = contract["paths"]["/api/status"]["get"]["responses"]
    expected_schema = responses["200"]["content"]["application/json"]["schema"]
    if args.base_url is None:
        return

    base_url = args.base_url.rstrip("/")
    status, content_type, home = fetch(base_url, "/", retry=True)
    require(status == 200 and content_type == "text/html", "Start page must return HTML with HTTP 200")
    require(b"Willkommen bei Knitventure" in home, "Start page is missing the expected welcome text")
    require(fetch(base_url, "/direkter-aufruf") == (200, "text/html", home), "SPA fallback differs from the start page")

    assets = set(re.findall(r'(?:src|href)="([^"]+\.(?:js|css))"', home.decode()))
    for extension in (".js", ".css"):
        require(any(asset.endswith(extension) for asset in assets), f"No {extension} assets in start page")
    for asset in sorted(assets):
        status, content_type, body = fetch(base_url, "/" + asset.lstrip("/"))
        require(status == 200 and content_type != "text/html" and body, f"Asset failed: {asset}")

    status, content_type, body = fetch(base_url, "/api/status", retry=True)
    require(status == 200 and content_type == "application/json", "Status endpoint must return HTTP 200 and application/json")
    Draft202012Validator(expected_schema).validate(json.loads(body))
    print("Caddy serves the SPA and the status response matches OpenAPI")


if __name__ == "__main__":
    main()
