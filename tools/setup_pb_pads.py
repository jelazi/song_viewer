#!/usr/bin/env python3
"""
Creates the `pads` collection that holds the worship pad loops.

The general `uploads` collection only accepts images and PDFs, so the audio
gets its own collection. One record per pad: set id and display name, the key
as a semitone index (0 = C) and the audio file. Any signed-in app user may
read and write it, like the other collections.

Requires PocketBase superuser credentials. The password is read without echo
when it is not given on the command line.

Usage:
    python3 tools/setup_pb_pads.py
    python3 tools/setup_pb_pads.py --url https://songs.example.com --email admin@example.com
"""

import argparse
import getpass
import json
import ssl
import sys
import urllib.error
import urllib.request
from pathlib import Path

# sslip.io certificates are not in Python's default trust store on macOS.
_ssl_ctx = ssl.create_default_context()
_ssl_ctx.check_hostname = False
_ssl_ctx.verify_mode = ssl.CERT_NONE

AUDIO_MIME_TYPES = ["audio/mp4", "audio/x-m4a", "audio/aac", "video/mp4", "audio/mpeg"]


def api_request(url, method="GET", data=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = token
    body = json.dumps(data).encode() if data is not None else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, context=_ssl_ctx) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        print(f"  HTTP {e.code}: {e.read().decode()}")
        raise


def default_url():
    config = Path("~/.songviewer/pocketbase_config.json").expanduser()
    if config.exists():
        return json.loads(config.read_text()).get("pocketbaseUrl")
    return None


def main():
    parser = argparse.ArgumentParser(description="Create the PocketBase pads collection")
    parser.add_argument("--url", default=default_url(), help="PocketBase URL (default: from ~/.songviewer)")
    parser.add_argument("--email", help="Superuser email")
    parser.add_argument("--password", help="Superuser password")
    args = parser.parse_args()
    if not args.url:
        sys.exit("No --url given and none found in ~/.songviewer/pocketbase_config.json")

    base_url = args.url.rstrip("/")
    email = args.email or input("Superuser email: ")
    password = args.password or getpass.getpass("Superuser password: ")

    print(f"Authenticating to {base_url} ...")
    try:
        token = api_request(f"{base_url}/api/collections/_superusers/auth-with-password", "POST",
                            {"identity": email, "password": password})["token"]
    except urllib.error.HTTPError:
        sys.exit("Failed to authenticate. Check superuser credentials.")

    collections = api_request(f"{base_url}/api/collections?perPage=200", token=token).get("items", [])
    if any(c.get("name") == "pads" for c in collections):
        print("Collection 'pads' already exists. Nothing to do.")
        return

    auth_rule = "@request.auth.id != ''"
    api_request(f"{base_url}/api/collections", "POST", {
        "name": "pads",
        "type": "base",
        "fields": [
            {"name": "set", "type": "text", "required": True},
            {"name": "setName", "type": "text", "required": False},
            # Not required: PocketBase treats 0 (the key of C) as an empty value.
            {"name": "semitone", "type": "number", "required": False, "min": 0, "max": 11, "onlyInt": True},
            {"name": "file", "type": "file", "required": True, "maxSelect": 1, "maxSize": 20 * 1024 * 1024,
             "mimeTypes": AUDIO_MIME_TYPES, "protected": False},
        ],
        "listRule": auth_rule,
        "viewRule": auth_rule,
        "createRule": auth_rule,
        "updateRule": auth_rule,
        "deleteRule": auth_rule,
    }, token)
    print("Created collection 'pads'.")


if __name__ == "__main__":
    main()
