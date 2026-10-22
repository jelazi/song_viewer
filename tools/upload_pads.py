#!/usr/bin/env python3
"""
Prepares worship pad loops and publishes them on the PocketBase server.

For every source file it cuts a loop out of the middle of the recording,
levels it to a common loudness, encodes it as AAC and uploads it to the
`pads` collection (create it once with tools/setup_pb_pads.py): one record per
pad with the set id and name, the key and the file. A set that is uploaded
again replaces its previous records.

Keys are stored as semitone indices (0 = C) so the app never has to guess
whether a `B` in a file name means B natural or B flat.

The audio itself never goes into the repository. Needs ffmpeg and, for the
AAC encoder, macOS `afconvert`.

Usage:
    python3 tools/upload_pads.py \\
        --set warm Warm "~/Downloads/Warm Pads" \\
        --set hillsong Hillsong "~/Downloads/Hillsong Pads"
    python3 tools/upload_pads.py --set ... --dry-run   # prepare files only
"""

import argparse
import json
import re
import ssl
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

# sslip.io certificates are not in Python's default trust store on macOS.
_SSL_CTX = ssl.create_default_context()
_SSL_CTX.check_hostname = False
_SSL_CTX.verify_mode = ssl.CERT_NONE

SEMITONES = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
KEY_IN_NAME = re.compile(r"PAD - ([A-G]#?)(?=[\s(])")
AUDIO_SUFFIXES = {".m4a", ".opus", ".mp3", ".wav", ".aac", ".ogg", ".flac"}


def request_json(url, method="GET", data=None, token=None):
    body = json.dumps(data).encode() if data is not None else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = token
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60, context=_SSL_CTX) as resp:
            text = resp.read().decode()
            return resp.status, json.loads(text) if text.strip() else {}
    except urllib.error.HTTPError as e:
        text = e.read().decode()
        try:
            return e.code, json.loads(text)
        except json.JSONDecodeError:
            return e.code, {"error": text}


def upload_pad(pb_url, token, fields, filename, file_bytes):
    boundary = f"----SongViewerPads{uuid.uuid4().hex}"
    parts = [f"--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"\r\n\r\n{value}\r\n".encode()
             for name, value in fields.items()]
    parts += [
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"{filename}\"\r\n"
        f"Content-Type: audio/mp4\r\n\r\n".encode(),
        file_bytes,
        f"\r\n--{boundary}--\r\n".encode(),
    ]
    req = urllib.request.Request(
        f"{pb_url}/api/collections/pads/records",
        data=b"".join(parts),
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}", "Authorization": token},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120, context=_SSL_CTX) as resp:
            data = json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        sys.exit(f"Upload of {filename} failed: {e.code} {e.read().decode()}")
    return data["id"]


def integrated_loudness(path, start, length):
    out = subprocess.run(
        ["ffmpeg", "-nostats", "-ss", str(start), "-t", str(length), "-i", str(path),
         "-af", "ebur128=framelog=quiet", "-f", "null", "-"],
        capture_output=True, text=True, check=True,
    ).stderr
    match = re.search(r"Integrated loudness:\s*\n\s*I:\s*(-?[\d.]+) LUFS", out)
    if not match:
        sys.exit(f"Could not measure loudness of {path}")
    return float(match.group(1))


def prepare_loop(source, target, start, length, target_lufs):
    gain = target_lufs - integrated_loudness(source, start, length)
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "loop.wav"
        # The 20 ms ramps only stop a click when the app starts a pad with no fade.
        subprocess.run(
            ["ffmpeg", "-v", "error", "-y", "-ss", str(start), "-t", str(length), "-i", str(source),
             "-af", f"volume={gain:.2f}dB,afade=t=in:d=0.02,afade=t=out:st={length - 0.02}:d=0.02,"
                    "alimiter=limit=0.95:level=disabled",
             "-ar", "44100", "-ac", "2", str(wav)],
            check=True,
        )
        subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "128000", str(wav), str(target)], check=True)
    return gain


def find_sources(directory):
    files = {}
    for path in sorted(Path(directory).expanduser().iterdir()):
        if path.suffix.lower() not in AUDIO_SUFFIXES:
            continue
        match = KEY_IN_NAME.search(path.name)
        if not match:
            print(f"  skipping {path.name}: no key in the name")
            continue
        files[SEMITONES[match.group(1)]] = path
    missing = sorted(set(range(12)) - set(files))
    if missing:
        sys.exit(f"{directory}: missing keys {missing}")
    return files


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--set", nargs=3, action="append", required=True, metavar=("ID", "NAME", "DIR"))
    parser.add_argument("--config", default="~/.songviewer/pocketbase_config.json")
    parser.add_argument("--start", type=float, default=60, help="loop start in the source, seconds")
    parser.add_argument("--length", type=float, default=120, help="loop length, seconds")
    parser.add_argument("--lufs", type=float, default=-18, help="target integrated loudness")
    parser.add_argument("--out", default=None, help="keep the prepared files in this directory")
    parser.add_argument("--dry-run", action="store_true", help="prepare the files but do not upload")
    args = parser.parse_args()

    out_dir = Path(args.out).expanduser() if args.out else Path(tempfile.mkdtemp(prefix="pads_"))
    out_dir.mkdir(parents=True, exist_ok=True)

    prepared = []
    for set_id, set_name, directory in args.set:
        print(f"== {set_name}")
        sources = find_sources(directory)
        files = {}
        for semitone, source in sorted(sources.items()):
            target = out_dir / f"pad_{set_id}_{semitone:02d}.m4a"
            gain = prepare_loop(source, target, args.start, args.length, args.lufs)
            files[semitone] = target
            print(f"  {semitone:2d} {source.name[:40]}…  gain {gain:+.1f} dB  {target.stat().st_size / 1048576:.2f} MB")
        prepared.append((set_id, set_name, files))

    total = sum(f.stat().st_size for _, _, files in prepared for f in files.values())
    print(f"Prepared {sum(len(f) for _, _, f in prepared)} files, {total / 1048576:.1f} MB in {out_dir}")
    if args.dry_run:
        return

    config = json.loads(Path(args.config).expanduser().read_text())
    pb_url = config["pocketbaseUrl"].rstrip("/")
    status, auth = request_json(f"{pb_url}/api/collections/users/auth-with-password", "POST",
                                {"identity": config["email"], "password": config["password"]})
    if status != 200:
        sys.exit(f"Login failed: {auth}")
    token = auth["token"]

    for set_id, set_name, files in prepared:
        query = urllib.parse.urlencode({"filter": f'set="{set_id}"', "perPage": 200})
        status, existing = request_json(f"{pb_url}/api/collections/pads/records?{query}", token=token)
        if status != 200:
            sys.exit(f"Reading the pads collection failed (run tools/setup_pb_pads.py first?): {existing}")
        old_ids = [record["id"] for record in existing.get("items", [])]

        for semitone, path in sorted(files.items()):
            upload_pad(pb_url, token, {"set": set_id, "setName": set_name, "semitone": semitone},
                       path.name, path.read_bytes())
            print(f"  uploaded {path.name}")

        for record_id in old_ids:
            request_json(f"{pb_url}/api/collections/pads/records/{record_id}", "DELETE", token=token)
        if old_ids:
            print(f"  removed {len(old_ids)} previous {set_name} records")

if __name__ == "__main__":
    main()
