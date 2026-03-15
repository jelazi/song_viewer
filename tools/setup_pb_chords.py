#!/usr/bin/env python3
"""
Setup script for PocketBase chord support.

Creates the `chord_diagrams` collection and adds the `chordOverrides`
field to the existing `songs` collection.

Requires PocketBase superuser credentials.

Usage:
    python3 tools/setup_pb_chords.py
    python3 tools/setup_pb_chords.py --url https://songs.example.com --email admin@example.com --password secret
"""

import argparse
import json
import ssl
import sys
import urllib.request
import urllib.error

# Create SSL context that doesn't verify certificates
# (sslip.io certs are not in Python's default trust store on macOS)
_ssl_ctx = ssl.create_default_context()
_ssl_ctx.check_hostname = False
_ssl_ctx.verify_mode = ssl.CERT_NONE


def api_request(url: str, method: str = "GET", data: dict | None = None,
                token: str | None = None) -> dict:
    """Make an API request to PocketBase."""
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = token

    body = json.dumps(data).encode() if data else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)

    try:
        with urllib.request.urlopen(req, context=_ssl_ctx) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        try:
            error_data = json.loads(error_body)
        except json.JSONDecodeError:
            error_data = {"raw": error_body}
        print(f"  HTTP {e.code}: {json.dumps(error_data, indent=2)}")
        raise


def authenticate(base_url: str, email: str, password: str) -> str:
    """Authenticate as PocketBase superuser, return token."""
    url = f"{base_url}/api/collections/_superusers/auth-with-password"
    result = api_request(url, "POST", {"identity": email, "password": password})
    token = result.get("token", "")
    if not token:
        print("Error: Authentication succeeded but no token received.")
        sys.exit(1)
    return token


def get_collections(base_url: str, token: str) -> list[dict]:
    """List all collections."""
    url = f"{base_url}/api/collections?perPage=200"
    result = api_request(url, "GET", token=token)
    return result.get("items", [])


def collection_exists(collections: list[dict], name: str) -> dict | None:
    """Check if a collection with the given name exists."""
    for c in collections:
        if c.get("name") == name:
            return c
    return None


def create_chord_diagrams_collection(base_url: str, token: str) -> None:
    """Create the chord_diagrams collection."""
    print("\n--- Creating chord_diagrams collection ---")
    url = f"{base_url}/api/collections"
    data = {
        "name": "chord_diagrams",
        "type": "base",
        "fields": [
            {
                "name": "name",
                "type": "text",
                "required": True,
            },
            {
                "name": "positions",
                "type": "json",
                "required": False,
                "maxSize": 2000000,
            },
        ],
        "indexes": [
            "CREATE UNIQUE INDEX idx_chordName ON chord_diagrams (name)"
        ],
        "listRule": "@request.auth.id != ''",
        "viewRule": "@request.auth.id != ''",
        "createRule": "@request.auth.id != ''",
        "updateRule": "@request.auth.id != ''",
        "deleteRule": "@request.auth.id != ''",
    }
    result = api_request(url, "POST", data, token)
    print(f"  Created collection: {result.get('name')} (id: {result.get('id')})")


def add_chord_overrides_to_songs(base_url: str, token: str,
                                  songs_collection: dict) -> None:
    """Add chordOverrides field to the songs collection."""
    print("\n--- Adding chordOverrides field to songs ---")

    existing_fields = songs_collection.get("fields", [])
    for field in existing_fields:
        if field.get("name") == "chordOverrides":
            print("  Field 'chordOverrides' already exists. Skipping.")
            return

    new_field = {
        "name": "chordOverrides",
        "type": "json",
        "required": False,
        "maxSize": 2000000,
    }
    updated_fields = existing_fields + [new_field]

    url = f"{base_url}/api/collections/{songs_collection['id']}"
    data = {"fields": updated_fields}
    api_request(url, "PATCH", data, token)
    print("  Added 'chordOverrides' json field to songs collection.")


def main():
    parser = argparse.ArgumentParser(description="Setup PocketBase chord support")
    parser.add_argument("--url", default="https://your-pocketbase-url.example",
                        help="PocketBase URL")
    parser.add_argument("--email", help="Superuser email")
    parser.add_argument("--password", help="Superuser password")
    args = parser.parse_args()

    base_url = args.url.rstrip("/")
    email = args.email or input("Superuser email: ")
    password = args.password or input("Superuser password: ")

    # 1. Authenticate
    print(f"Authenticating to {base_url} ...")
    try:
        token = authenticate(base_url, email, password)
    except urllib.error.HTTPError:
        print("\nError: Failed to authenticate. Check superuser credentials.")
        sys.exit(1)
    print("  Authenticated successfully.")

    # 2. Get existing collections
    collections = get_collections(base_url, token)
    print(f"  Found {len(collections)} existing collections.")

    # 3. Create chord_diagrams collection (if not exists)
    if collection_exists(collections, "chord_diagrams"):
        print("\n  chord_diagrams collection already exists. Skipping creation.")
    else:
        try:
            create_chord_diagrams_collection(base_url, token)
        except urllib.error.HTTPError:
            print("  Error creating chord_diagrams collection.")
            sys.exit(1)

    # 4. Add chordOverrides to songs (if not exists)
    songs_col = collection_exists(collections, "songs")
    if not songs_col:
        print("\n  Error: 'songs' collection not found!")
        sys.exit(1)

    try:
        add_chord_overrides_to_songs(base_url, token, songs_col)
    except urllib.error.HTTPError:
        print("  Error adding chordOverrides field to songs.")
        sys.exit(1)

    print("\n✅ Done! PocketBase chord support is set up.")


if __name__ == "__main__":
    main()
