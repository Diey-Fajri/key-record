#!/usr/bin/env bash
set -euo pipefail

TOKEN="${1:-}"
if [[ -z "$TOKEN" ]]; then
  echo "Usage: $0 <FIREBASE_CI_TOKEN>" >&2
  exit 1
fi

PROJECT="keyrecordpbscb"
BUCKET="keyrecordpbscb.firebasestorage.app"
APK="build/app/outputs/flutter-apk/app-release.apk"
OBJECT="updates/android/app-release.apk"
ENC_OBJECT="updates%2Fandroid%2Fapp-release.apk"
VERSION="$(sed -n 's/^version:[[:space:]]*\([0-9]\+\.[0-9]\+\.[0-9]\+\).*$/\1/p' pubspec.yaml | head -n1)"
if [[ -z "$VERSION" ]]; then
  VERSION="1.0.1"
fi

if [[ ! -f "$APK" ]]; then
  echo "APK not found: $APK" >&2
  exit 1
fi

curl -sS -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/vnd.android.package-archive' \
  --data-binary @"$APK" \
  "https://firebasestorage.googleapis.com/v0/b/$BUCKET/o?uploadType=media&name=$ENC_OBJECT" \
  > /tmp/firebase_storage_upload.json

python3 - <<'PY'
import json
obj=json.load(open('/tmp/firebase_storage_upload.json'))
if 'error' in obj:
    raise SystemExit(f"Storage upload failed: {obj['error']}")
print('UPLOAD_NAME=', obj.get('name'))
print('UPLOAD_BUCKET=', obj.get('bucket'))
print('UPLOAD_SIZE=', obj.get('size'))
print('UPLOAD_UPDATED=', obj.get('updated'))
PY

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 - <<PY
import json
version = "$VERSION"
obj = {
  "fields": {
    "latestVersion": {"stringValue": version},
    "releaseNotes": {"stringValue": "Critical authentication fix and Firebase update flow improvements."},
    "apkStoragePath": {"stringValue": "updates/android/app-release.apk"},
    "forceUpdate": {"booleanValue": False},
    "minimumVersion": {"stringValue": version},
    "updatedAt": {"timestampValue": "$TS"}
  }
}
with open('/tmp/app_update_current.json','w') as f:
    json.dump(obj,f)
PY

curl -sS -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  --data-binary @/tmp/app_update_current.json \
  "https://firestore.googleapis.com/v1/projects/$PROJECT/databases/(default)/documents/app_updates/current" \
  > /tmp/firestore_update_doc.json

python3 - <<'PY'
import json
obj=json.load(open('/tmp/firestore_update_doc.json'))
if 'error' in obj:
    raise SystemExit(f"Firestore update failed: {obj['error']}")
fields=obj.get('fields',{})
print('DOC_NAME=', obj.get('name'))
print('LATEST_VERSION=', fields.get('latestVersion',{}).get('stringValue'))
print('APK_PATH=', fields.get('apkStoragePath',{}).get('stringValue'))
print('FORCE_UPDATE=', fields.get('forceUpdate',{}).get('booleanValue'))
print('MINIMUM_VERSION=', fields.get('minimumVersion',{}).get('stringValue'))
PY
