#!/usr/bin/env bash
set -euo pipefail

GITHUB_TOKEN="${1:-${GITHUB_TOKEN:-}}"
FIREBASE_TOKEN="${2:-${FIREBASE_CI_TOKEN:-}}"
REPO="${REPO:-Diey-Fajri/key-record}"
APK_PATH="${APK_PATH:-build/app/outputs/flutter-apk/app-release.apk}"
PROJECT="${PROJECT:-keyrecordpbscb}"
RELEASE_TAG="${RELEASE_TAG:-}"
RELEASE_NAME="${RELEASE_NAME:-}"
RELEASE_BODY="${RELEASE_BODY:-}"

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Usage: $0 <GITHUB_TOKEN> [FIREBASE_CI_TOKEN]" >&2
  echo "Optional env vars: REPO, APK_PATH, RELEASE_TAG, RELEASE_NAME, RELEASE_BODY, PROJECT" >&2
  exit 1
fi

if [[ ! -f "$APK_PATH" ]]; then
  echo "APK not found: $APK_PATH" >&2
  exit 1
fi

VERSION="$(python3 - <<'PY'
import pathlib, re
text = pathlib.Path('pubspec.yaml').read_text(encoding='utf-8')
match = re.search(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)', text, re.M)
print(match.group(1) if match else '1.0.0')
PY
)"

if [[ -z "$RELEASE_TAG" ]]; then
  RELEASE_TAG="v$VERSION"
fi

if [[ -z "$RELEASE_NAME" ]]; then
  RELEASE_NAME="$RELEASE_TAG"
fi

if [[ -z "$RELEASE_BODY" ]]; then
  RELEASE_BODY="Release $RELEASE_TAG"
fi

API_BASE="https://api.github.com"
UPLOAD_BASE="https://uploads.github.com"

header_json() {
  printf 'Accept: application/vnd.github+json\nAuthorization: Bearer %s\n' "$GITHUB_TOKEN"
}

release_payload="$(python3 - <<PY
import json, os
payload = {
  "tag_name": os.environ["RELEASE_TAG"],
  "name": os.environ["RELEASE_NAME"],
  "body": os.environ["RELEASE_BODY"],
  "draft": False,
  "prerelease": False,
}
print(json.dumps(payload))
PY
)"

echo "Creating or updating GitHub release $RELEASE_TAG for $REPO"
release_json="$(curl -sS -L -H "$(header_json)" "$API_BASE/repos/$REPO/releases/tags/$RELEASE_TAG" 2>/dev/null || true)"

if echo "$release_json" | grep -q '"message": "Not Found"'; then
  release_json="$(curl -sS -X POST -L -H "$(header_json)" \
    "$API_BASE/repos/$REPO/releases" \
    -H 'Content-Type: application/json' \
    --data "$release_payload")"
else
  release_id="$(python3 - <<'PY'
import json, sys
text = sys.stdin.read().strip()
if not text:
    raise SystemExit(0)
try:
    data = json.loads(text)
except json.JSONDecodeError:
    raise SystemExit(0)
print(data.get('id', ''))
PY
<<< "$release_json")"
  if [[ -z "$release_id" ]]; then
    echo "Unable to read existing release metadata." >&2
    exit 1
  fi
  release_json="$(curl -sS -X PATCH -L -H "$(header_json)" \
    "$API_BASE/repos/$REPO/releases/$release_id" \
    -H 'Content-Type: application/json' \
    --data "$release_payload")"
fi

release_id="$(python3 - <<'PY'
import json, sys
text = sys.stdin.read().strip()
if not text:
    raise SystemExit(0)
try:
    data = json.loads(text)
except json.JSONDecodeError:
    raise SystemExit(0)
print(data.get('id', ''))
PY
<<< "$release_json")"

if [[ -z "$release_id" ]]; then
  echo "Failed to create or resolve GitHub release." >&2
  exit 1
fi

echo "Release ID: $release_id"
assets_json="$(curl -sS -L -H "$(header_json)" "$API_BASE/repos/$REPO/releases/$release_id/assets")"

python3 - <<'PY' "$assets_json" "$REPO" "$GITHUB_TOKEN" "$release_id"
import json, sys, urllib.request
assets_json = sys.argv[1]
repo = sys.argv[2]
github_token = sys.argv[3]
release_id = sys.argv[4]
try:
    assets = json.loads(assets_json)
except json.JSONDecodeError:
    assets = []
for asset in assets:
    if asset.get('name') != 'app-release.apk':
        continue
    delete_url = asset.get('url')
    if not delete_url:
        continue
    req = urllib.request.Request(delete_url, method='DELETE')
    req.add_header('Accept', 'application/vnd.github+json')
    req.add_header('Authorization', f'Bearer {github_token}')
    try:
        urllib.request.urlopen(req)
    except Exception as exc:
        print(f'Warning: failed to delete previous asset: {exc}', file=sys.stderr)
PY

asset_response="$(curl -sS -X POST -L -H "$(header_json)" \
  "$UPLOAD_BASE/repos/$REPO/releases/$release_id/assets?name=app-release.apk" \
  -H 'Content-Type: application/vnd.android.package-archive' \
  --data-binary @"$APK_PATH")"

DOWNLOAD_URL="$(python3 - <<'PY'
import json, sys
text = sys.stdin.read().strip()
if not text:
    raise SystemExit(0)
try:
    data = json.loads(text)
except json.JSONDecodeError:
    raise SystemExit(0)
print(data.get('browser_download_url') or data.get('url') or '')
PY
<<< "$asset_response")"

if [[ -z "$DOWNLOAD_URL" ]]; then
  echo "Failed to obtain GitHub asset download URL." >&2
  exit 1
fi

echo "GitHub asset URL: $DOWNLOAD_URL"

if [[ -n "$FIREBASE_TOKEN" ]]; then
  TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  firestore_payload="$(python3 - <<PY
import json, os
payload = {
  "fields": {
    "latestVersion": {"stringValue": os.environ["VERSION"]},
    "releaseNotes": {"stringValue": os.environ["RELEASE_BODY"]},
    "apkUrl": {"stringValue": os.environ["DOWNLOAD_URL"]},
    "forceUpdate": {"booleanValue": False},
    "minimumVersion": {"stringValue": os.environ["VERSION"]},
    "updatedAt": {"timestampValue": os.environ["TS"]},
  }
}
print(json.dumps(payload))
PY
)"

  curl -sS -X PATCH \
    -H "Authorization: Bearer $FIREBASE_TOKEN" \
    -H 'Content-Type: application/json' \
    --data-binary "$firestore_payload" \
    "https://firestore.googleapis.com/v1/projects/$PROJECT/databases/(default)/documents/app_updates/current" \
    > /tmp/app_update_current_response.json

  python3 - <<'PY'
import json
obj = json.load(open('/tmp/app_update_current_response.json'))
if 'error' in obj:
    raise SystemExit(f"Firestore update failed: {obj['error']}")
print('Firestore app_updates/current updated successfully.')
PY
else
  echo "Firebase token not provided; skipping Firestore update."
fi

echo "Release flow completed."
