#!/usr/bin/env python3
"""
Firebase → PocketBase Migration Script
=======================================
Exports data from Firebase Firestore and imports it into PocketBase.

Usage:
  python3 tools/firebase_to_pocketbase.py

Requirements:
  - Python 3.7+
  - No additional packages needed (uses only stdlib)

The script will:
  1. Authenticate with Firebase using REST API
  2. Download all songs, playlists, users, groups from Firestore
  3. Authenticate with PocketBase
  4. Upload all data to PocketBase collections
"""

import base64
import hashlib
import hmac
import json
import mimetypes
import os
import ssl
import sys
import time
import urllib.request
import urllib.error
import urllib.parse
import uuid
from pathlib import Path

# macOS fix: Python may lack system SSL certs; use unverified context for this migration script
_SSL_CTX = ssl.create_default_context()
_SSL_CTX.check_hostname = False
_SSL_CTX.verify_mode = ssl.CERT_NONE


# ─── Configuration ───────────────────────────────────────────────────────────

# Firebase config - never commit real values here, the script prompts for what
# is missing (see prompt_firebase_config()).
FIREBASE_CONFIG = {
    "apiKey": "",           # Firebase Web API key (from Firebase Console → Project Settings)
    "projectId": "",        # Firebase project ID (e.g., "my-app-12345")
    "email": "",            # Firebase Auth email
    "password": "",         # Firebase Auth password
}

# PocketBase config - loaded from ~/.songviewer/pocketbase_config.json by
# load_pb_config(); leave empty here so no credentials end up in the repository.
PB_CONFIG = {
    "url": "",
    "email": "",
    "password": "",
}

# JSON backup location. Kept outside the repository: the export contains user
# records with plain-text passwords.
BACKUP_DIR = Path.home() / ".songviewer" / "firebase_backup"

# Firestore collection names (as used in the old Firebase app)
FIRESTORE_COLLECTIONS = ["songs", "playlists", "users", "groups"]


# ─── HTTP Helpers ────────────────────────────────────────────────────────────

def http_request(url, method="GET", data=None, headers=None, timeout=30):
    """Simple HTTP request using urllib (no external deps)."""
    if headers is None:
        headers = {}
    if data is not None:
        if isinstance(data, dict):
            data = json.dumps(data).encode("utf-8")
            headers.setdefault("Content-Type", "application/json")
        elif isinstance(data, str):
            data = data.encode("utf-8")

    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout, context=_SSL_CTX) as resp:
            body = resp.read().decode("utf-8")
            return resp.status, json.loads(body) if body.strip() else {}
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        try:
            return e.code, json.loads(body)
        except json.JSONDecodeError:
            return e.code, {"error": body}
    except urllib.error.URLError as e:
        return 0, {"error": str(e.reason)}


def download_file(url, timeout=60):
    """Download a file from URL, return (bytes, filename) or (None, None)."""
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=timeout, context=_SSL_CTX) as resp:
            file_bytes = resp.read()
            # Try to extract filename from Content-Disposition header
            cd = resp.headers.get("Content-Disposition", "")
            filename = None
            if "filename=" in cd:
                filename = cd.split("filename=")[-1].strip().strip('"')
            if not filename:
                # Extract from URL path
                parsed = urllib.parse.urlparse(url)
                path = urllib.parse.unquote(parsed.path)
                filename = path.split("/")[-1] if "/" in path else None
            if not filename or not "." in filename:
                # Guess extension from content type
                ct = resp.headers.get("Content-Type", "application/octet-stream")
                ext = mimetypes.guess_extension(ct.split(";")[0].strip()) or ".bin"
                filename = f"sheet_{uuid.uuid4().hex[:8]}{ext}"
            return file_bytes, filename
    except Exception as e:
        print(f"      ⚠ Download failed: {e}")
        return None, None


def multipart_upload(url, fields, files, headers=None, timeout=60):
    """Send multipart/form-data POST request.
    fields: dict of {name: value}
    files: list of (field_name, filename, file_bytes, content_type)
    """
    boundary = f"----PBMigrate{uuid.uuid4().hex}"
    body_parts = []

    for name, value in fields.items():
        body_parts.append(f"--{boundary}\r\n".encode())
        body_parts.append(f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode())
        body_parts.append(f"{value}\r\n".encode())

    for field_name, filename, file_bytes, content_type in files:
        body_parts.append(f"--{boundary}\r\n".encode())
        body_parts.append(
            f'Content-Disposition: form-data; name="{field_name}"; filename="{filename}"\r\n'.encode()
        )
        body_parts.append(f"Content-Type: {content_type}\r\n\r\n".encode())
        body_parts.append(file_bytes)
        body_parts.append(b"\r\n")

    body_parts.append(f"--{boundary}--\r\n".encode())
    body = b"".join(body_parts)

    if headers is None:
        headers = {}
    headers["Content-Type"] = f"multipart/form-data; boundary={boundary}"

    req = urllib.request.Request(url, data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout, context=_SSL_CTX) as resp:
            resp_body = resp.read().decode("utf-8")
            return resp.status, json.loads(resp_body) if resp_body.strip() else {}
    except urllib.error.HTTPError as e:
        resp_body = e.read().decode("utf-8")
        try:
            return e.code, json.loads(resp_body)
        except json.JSONDecodeError:
            return e.code, {"error": resp_body}


# ─── Firebase Functions ──────────────────────────────────────────────────────

def firebase_auth_service_account(service_account_path):
    """Authenticate using a Firebase service account JSON key.
    Returns an access token for Firestore REST API.
    """
    import struct

    try:
        with open(service_account_path, "r") as f:
            sa = json.load(f)
    except Exception as e:
        print(f"  ✗ Could not read service account file: {e}")
        return None

    private_key_pem = sa.get("private_key", "")
    client_email = sa.get("client_email", "")
    token_uri = sa.get("token_uri", "https://oauth2.googleapis.com/token")

    if not private_key_pem or not client_email:
        print("  ✗ Service account file is missing private_key or client_email")
        return None

    # Build JWT manually using RSA-SHA256 via subprocess (no external deps needed)
    # We'll use Python's ssl/hashlib which supports RSA via the cryptography backend
    # Fallback: use openssl via subprocess
    now = int(time.time())
    header = base64.urlsafe_b64encode(json.dumps({"alg": "RS256", "typ": "JWT"}).encode()).rstrip(b"=").decode()
    payload = base64.urlsafe_b64encode(json.dumps({
        "iss": client_email,
        "sub": client_email,
        "aud": token_uri,
        "iat": now,
        "exp": now + 3600,
        "scope": "https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/firebase",
    }).encode()).rstrip(b"=").decode()

    signing_input = f"{header}.{payload}"

    # Write key to temp file and sign with openssl
    import tempfile, subprocess
    with tempfile.NamedTemporaryFile(mode="w", suffix=".pem", delete=False) as kf:
        kf.write(private_key_pem)
        key_path = kf.name
    try:
        result = subprocess.run(
            ["openssl", "dgst", "-sha256", "-sign", key_path],
            input=signing_input.encode(),
            capture_output=True,
        )
        if result.returncode != 0:
            print(f"  ✗ openssl signing failed: {result.stderr.decode()}")
            return None
        signature = base64.urlsafe_b64encode(result.stdout).rstrip(b"=").decode()
    finally:
        os.unlink(key_path)

    jwt_token = f"{signing_input}.{signature}"

    # Exchange JWT for access token
    status, data = http_request(
        token_uri,
        method="POST",
        data=urllib.parse.urlencode({
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": jwt_token,
        }).encode(),
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    if status == 200 and "access_token" in data:
        return data["access_token"]
    else:
        print(f"  ✗ Service account token exchange failed (HTTP {status}): {data}")
        return None


def firebase_auth(api_key, email, password):
    """Authenticate with Firebase Auth REST API and return ID token."""
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={api_key}"
    status, data = http_request(url, method="POST", data={
        "email": email,
        "password": password,
        "returnSecureToken": True,
    })
    if status == 200 and "idToken" in data:
        return data["idToken"]
    else:
        err = data.get("error", data) if isinstance(data, dict) else data
        msg = err.get("message", err) if isinstance(err, dict) else err
        print(f"  ✗ Firebase auth failed (HTTP {status}): {msg}")
        return None


def firestore_parse_value(value_obj):
    """Parse a Firestore REST API value object into a Python value."""
    if "stringValue" in value_obj:
        return value_obj["stringValue"]
    elif "integerValue" in value_obj:
        return int(value_obj["integerValue"])
    elif "doubleValue" in value_obj:
        return float(value_obj["doubleValue"])
    elif "booleanValue" in value_obj:
        return value_obj["booleanValue"]
    elif "nullValue" in value_obj:
        return None
    elif "arrayValue" in value_obj:
        arr = value_obj["arrayValue"]
        if "values" in arr:
            return [firestore_parse_value(v) for v in arr["values"]]
        return []
    elif "mapValue" in value_obj:
        fields = value_obj["mapValue"].get("fields", {})
        return {k: firestore_parse_value(v) for k, v in fields.items()}
    elif "timestampValue" in value_obj:
        return value_obj["timestampValue"]
    elif "geoPointValue" in value_obj:
        return value_obj["geoPointValue"]
    elif "referenceValue" in value_obj:
        return value_obj["referenceValue"]
    else:
        return str(value_obj)


def firestore_get_all_documents(project_id, collection_name, token):
    """Fetch all documents from a Firestore collection using REST API with pagination."""
    base_url = f"https://firestore.googleapis.com/v1/projects/{project_id}/databases/(default)/documents/{collection_name}"
    headers = {"Authorization": f"Bearer {token}"}
    documents = []
    page_token = None

    while True:
        url = base_url + "?pageSize=300"
        if page_token:
            url += f"&pageToken={page_token}"

        status, data = http_request(url, headers=headers)

        if status != 200:
            print(f"  ✗ Error fetching {collection_name}: HTTP {status} - {data}")
            return documents

        if "documents" in data:
            for doc in data["documents"]:
                doc_id = doc["name"].split("/")[-1]
                fields = doc.get("fields", {})
                parsed = {k: firestore_parse_value(v) for k, v in fields.items()}
                parsed["_docId"] = doc_id
                documents.append(parsed)

        page_token = data.get("nextPageToken")
        if not page_token:
            break

    return documents


# ─── PocketBase Functions ────────────────────────────────────────────────────

def pb_auth(url, email, password):
    """Authenticate with PocketBase and return token."""
    status, data = http_request(
        f"{url}/api/collections/users/auth-with-password",
        method="POST",
        data={"identity": email, "password": password},
    )
    if status == 200 and "token" in data:
        return data["token"]
    else:
        print(f"  ✗ PocketBase auth failed: {data.get('message', data)}")
        return None


def pb_create_record(url, token, collection, body, retries=3):
    """Create a record in PocketBase collection."""
    for attempt in range(1, retries + 1):
        try:
            status, data = http_request(
                f"{url}/api/collections/{collection}/records",
                method="POST",
                data=body,
                headers={"Authorization": f"Bearer {token}"},
                timeout=90,
            )
            return status in (200, 201, 204), data
        except Exception as e:
            if attempt < retries:
                print(f"      ⚠ Attempt {attempt} failed ({e}), retrying...")
                time.sleep(2)
            else:
                return False, {"message": str(e)}


def pb_get_record_count(url, token, collection):
    """Get record count for a PocketBase collection."""
    status, data = http_request(
        f"{url}/api/collections/{collection}/records?perPage=1",
        headers={"Authorization": f"Bearer {token}"},
    )
    if status == 200:
        return data.get("totalItems", 0)
    return -1


def pb_upload_file(pb_url, token, filename, file_bytes):
    """Upload a file to PocketBase 'uploads' collection, return new public URL or None."""
    content_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"
    status, data = multipart_upload(
        f"{pb_url}/api/collections/uploads/records",
        fields={"name": filename},
        files=[("file", filename, file_bytes, content_type)],
        headers={"Authorization": f"Bearer {token}"},
    )
    if status in (200, 201):
        uploaded_name = data.get("file", filename)
        collection_id = data.get("collectionId", "uploads")
        record_id = data.get("id", "")
        return f"{pb_url}/api/files/{collection_id}/{record_id}/{uploaded_name}"
    else:
        print(f"      ✗ Upload failed: {data.get('message', data)}")
        return None


def migrate_sheets(sheets_list, pb_url, pb_token):
    """Download sheet files and re-upload to PocketBase. Returns list of new URLs."""
    if not sheets_list:
        return []

    new_urls = []
    for sheet_url in sheets_list:
        if not isinstance(sheet_url, str) or not sheet_url.startswith("http"):
            # Keep non-URL values (e.g., already local or invalid)
            new_urls.append(sheet_url)
            continue

        # If it's already a PocketBase URL, keep it
        if pb_url in sheet_url:
            new_urls.append(sheet_url)
            continue

        file_bytes, filename = download_file(sheet_url)
        if file_bytes is None:
            print(f"      ⚠ Skipping sheet (download failed): {sheet_url[:80]}")
            new_urls.append(sheet_url)  # Keep old URL as fallback
            continue

        new_url = pb_upload_file(pb_url, pb_token, filename, file_bytes)
        if new_url:
            new_urls.append(new_url)
            print(f"      ✓ Sheet migrated: {filename}")
        else:
            new_urls.append(sheet_url)  # Keep old URL as fallback

    return new_urls


# ─── Data Transformation ────────────────────────────────────────────────────

def transform_song(firebase_doc):
    """Transform Firebase song document to PocketBase format."""
    return {
        "songUuid": firebase_doc.get("id", firebase_doc.get("_docId", "")),
        "title": firebase_doc.get("title", ""),
        "lyrics": firebase_doc.get("lyrics", ""),
        "originalLyrics": firebase_doc.get("originalLyrics", ""),
        "indexSongBook": firebase_doc.get("indexSongBook", 0),
        "interpret": firebase_doc.get("interpret", ""),
        "typeTranspose": firebase_doc.get("typeTranspose", "czech"),
        "songBar": firebase_doc.get("songBar", 0),
        "bmp": firebase_doc.get("bmp", 0),
        "sheets": firebase_doc.get("sheets", []),
        "groups": firebase_doc.get("groups", []),
        "tags": firebase_doc.get("tags", []),
        "notes": firebase_doc.get("notes", []),
        "youtubeVideos": firebase_doc.get("youtubeVideos", []),
    }


def transform_playlist(firebase_doc):
    """Transform Firebase playlist document to PocketBase format."""
    return {
        "playlistUuid": firebase_doc.get("id", firebase_doc.get("_docId", "")),
        "name": firebase_doc.get("name", ""),
        "listSongIds": firebase_doc.get("listSongIds", []),
    }


def transform_user(firebase_doc):
    """Transform Firebase user document to PocketBase app_user format."""
    return {
        "name": firebase_doc.get("name", firebase_doc.get("_docId", "")),
        "appPassword": firebase_doc.get("password", ""),
        "typeUser": firebase_doc.get("typeUser", "none"),
        "allowedGroup": firebase_doc.get("allowedGroup", []),
    }


def transform_group(firebase_doc):
    """Transform Firebase group document to PocketBase format.
    Firebase stores all groups as a single document with a 'groups' array field.
    We expand it into individual records.
    Returns a list of dicts (one per group name).
    """
    groups_array = firebase_doc.get("groups", [])
    if isinstance(groups_array, list) and groups_array:
        return [{"name": name} for name in groups_array if name]
    # Fallback: single record with name field
    name = firebase_doc.get("name", firebase_doc.get("_docId", ""))
    return [{"name": name}] if name else []


# ─── Export to JSON (backup) ────────────────────────────────────────────────

def save_backup(data, filename):
    """Save data as JSON backup file."""
    backup_dir = BACKUP_DIR
    backup_dir.mkdir(parents=True, exist_ok=True)
    filepath = backup_dir / filename
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    return filepath


# ─── Import from JSON (alternative) ─────────────────────────────────────────

def import_from_json_files(backup_dir):
    """Load previously exported JSON backup files."""
    data = {}
    backup_path = Path(backup_dir)
    for collection in FIRESTORE_COLLECTIONS:
        filepath = backup_path / f"{collection}.json"
        if filepath.exists():
            with open(filepath, "r", encoding="utf-8") as f:
                data[collection] = json.load(f)
            print(f"  ✓ Loaded {len(data[collection])} {collection} from {filepath}")
        else:
            print(f"  ⚠ File not found: {filepath}")
            data[collection] = []
    return data


# ─── Main ────────────────────────────────────────────────────────────────────

def load_pb_config():
    """Load PocketBase config from pocketbase_config.json."""
    config_paths = [
        Path.home() / ".songviewer" / "pocketbase_config.json",
    ]
    for path in config_paths:
        if path.exists():
            with open(path, "r") as f:
                config = json.load(f)
                PB_CONFIG["url"] = config.get("pocketbaseUrl", "")
                PB_CONFIG["email"] = config.get("email", "")
                PB_CONFIG["password"] = config.get("password", "")
                print(f"  ✓ Loaded PB config from {path}")
                return True
    return False


def prompt_firebase_config():
    """Interactively prompt for Firebase configuration."""
    print("\n─── Firebase Configuration ───")
    print("You can find these in Firebase Console → Project Settings")
    print()

    FIREBASE_CONFIG["apiKey"] = input("  Firebase Web API Key: ").strip()
    FIREBASE_CONFIG["projectId"] = input("  Firebase Project ID: ").strip()
    FIREBASE_CONFIG["email"] = input("  Firebase Auth Email: ").strip()
    FIREBASE_CONFIG["password"] = input("  Firebase Auth Password: ").strip()

    if not all(FIREBASE_CONFIG.values()):
        print("  ✗ All Firebase fields are required!")
        return False
    return True


def main():
    print("=" * 60)
    print("  Firebase → PocketBase Migration")
    print("=" * 60)

    # Load PocketBase config
    print("\n[1/5] Loading PocketBase configuration...")
    if not load_pb_config():
        print("  ✗ Could not find pocketbase_config.json")
        PB_CONFIG["url"] = input("  PocketBase URL: ").strip()
        PB_CONFIG["email"] = input("  PocketBase Email: ").strip()
        PB_CONFIG["password"] = input("  PocketBase Password: ").strip()

    # Choose mode
    print("\n─── Migration Mode ───")
    print("  1) Full migration: Firebase → JSON backup → PocketBase")
    print("  2) Export only: Firebase → JSON backup files")
    print("  3) Import only: JSON backup files → PocketBase")
    print()
    mode = input("  Choose mode (1/2/3): ").strip()

    firebase_data = {}

    # ─── Export from Firebase ───
    if mode in ("1", "2"):
        print("\n[2/5] Configuring Firebase...")
        if all(FIREBASE_CONFIG.values()):
            print(f"  ✓ Using hardcoded Firebase config (project: {FIREBASE_CONFIG['projectId']})")
        elif not prompt_firebase_config():
            sys.exit(1)

        print("\n[3/5] Authenticating with Firebase...")
        fb_token = None

        # Try service account first (more reliable)
        sa_path = Path(__file__).parent / "firebase_service_account.json"
        if sa_path.exists():
            print(f"  → Using service account: {sa_path.name}")
            fb_token = firebase_auth_service_account(str(sa_path))
        else:
            print("  → Using email/password auth (no firebase_service_account.json found)")
            fb_token = firebase_auth(
                FIREBASE_CONFIG["apiKey"],
                FIREBASE_CONFIG["email"],
                FIREBASE_CONFIG["password"],
            )

        if not fb_token:
            print("  ✗ Cannot proceed without Firebase authentication")
            print("  ℹ Tip: Download service account key from Firebase Console →")
            print("         Project Settings → Service accounts → Generate new private key")
            print(f"         Save as: {sa_path}")
            sys.exit(1)
        print("  ✓ Firebase authenticated")

        print("\n[4/5] Downloading data from Firestore...")
        for collection in FIRESTORE_COLLECTIONS:
            docs = firestore_get_all_documents(
                FIREBASE_CONFIG["projectId"], collection, fb_token
            )
            firebase_data[collection] = docs
            filepath = save_backup(docs, f"{collection}.json")
            print(f"  ✓ {collection}: {len(docs)} documents → {filepath}")

        total = sum(len(v) for v in firebase_data.values())
        print(f"\n  Total: {total} documents exported")

        if mode == "2":
            print(f"\n✓ Export complete! JSON files saved to {BACKUP_DIR}/")
            print("  Run this script again with mode 3 to import into PocketBase.")
            sys.exit(0)

    # ─── Import from JSON backup ───
    elif mode == "3":
        print("\n[2/5] Loading from JSON backup...")
        backup_dir = BACKUP_DIR
        if not backup_dir.exists():
            custom_path = input(f"  Backup directory [{backup_dir}]: ").strip()
            if custom_path:
                backup_dir = Path(custom_path)
        firebase_data = import_from_json_files(backup_dir)
    else:
        print("  Invalid mode!")
        sys.exit(1)

    # ─── Upload to PocketBase ───
    print("\n[5/5] Uploading to PocketBase...")
    print(f"  URL: {PB_CONFIG['url']}")

    pb_token = pb_auth(PB_CONFIG["url"], PB_CONFIG["email"], PB_CONFIG["password"])
    if not pb_token:
        print("  ✗ Cannot proceed without PocketBase authentication")
        sys.exit(1)
    print("  ✓ PocketBase authenticated")

    # Check existing data
    for coll_name in ["songs", "playlists", "app_users", "groups"]:
        count = pb_get_record_count(PB_CONFIG["url"], pb_token, coll_name)
        if count > 0:
            print(f"\n  ⚠ PocketBase collection '{coll_name}' already has {count} records!")
            confirm = input("  Continue and add data? (y/n): ").strip().lower()
            if confirm != "y":
                print("  Aborted.")
                sys.exit(0)
            break

    # Transform and upload
    transformers = {
        "songs": ("songs", transform_song),
        "playlists": ("playlists", transform_playlist),
        "users": ("app_users", transform_user),
        "groups": ("groups", transform_group),
    }

    stats = {"success": 0, "failed": 0}

    # Count sheets to migrate
    total_sheets = 0
    for doc in firebase_data.get("songs", []):
        sheets = doc.get("sheets", [])
        if sheets:
            total_sheets += len(sheets)
    if total_sheets > 0:
        print(f"\n  Found {total_sheets} sheet files to migrate (download + re-upload)")

    for fb_collection, (pb_collection, transformer) in transformers.items():
        docs = firebase_data.get(fb_collection, [])
        if not docs:
            print(f"\n  {fb_collection} → {pb_collection}: 0 documents (skipped)")
            continue

        print(f"\n  {fb_collection} → {pb_collection}: {len(docs)} documents")
        for i, doc in enumerate(docs, 1):
            bodies = [transformer(doc)] if fb_collection != "groups" else transformer(doc)
            if not isinstance(bodies, list):
                bodies = [bodies]

            for body in bodies:
                # Migrate sheet files for songs
                if fb_collection == "songs" and body.get("sheets"):
                    sheets_count = len(body["sheets"])
                    print(f"    [{i}] Migrating {sheets_count} sheet(s) for: {body.get('title', '?')}")
                    body["sheets"] = migrate_sheets(body["sheets"], PB_CONFIG["url"], pb_token)

                ok, result = pb_create_record(PB_CONFIG["url"], pb_token, pb_collection, body)
                if ok:
                    stats["success"] += 1
                else:
                    stats["failed"] += 1
                    name_hint = body.get("title", body.get("name", body.get("songUuid", "?")))
                    msg = result.get("message", str(result))
                    print(f"    \u2717 [{i}] {name_hint}: {msg}")

            # Progress indicator
            if i % 50 == 0 or i == len(docs):
                print(f"    ... {i}/{len(docs)}")

    # Summary
    print("\n" + "=" * 60)
    print(f"  Migration complete!")
    print(f"  ✓ Success: {stats['success']}")
    if stats["failed"]:
        print(f"  ✗ Failed:  {stats['failed']}")
    print("=" * 60)

    # Verify
    print("\n  PocketBase record counts:")
    for coll_name in ["songs", "playlists", "app_users", "groups", "uploads"]:
        count = pb_get_record_count(PB_CONFIG["url"], pb_token, coll_name)
        print(f"    {coll_name}: {count}")


if __name__ == "__main__":
    main()
