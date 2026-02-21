#!/bin/bash

set -e

NAME=Sentry.xcframework.zip
REPO=getsentry/sentry-cocoa
MY_REPO=exception7601/Sentry
BUILD_COMMIT=$(git log --oneline --abbrev=16 --pretty=format:"%h" -1)
NEW_NAME=Sentry-${BUILD_COMMIT}.zip

VERSION=$(gh release list \
  --repo ${REPO} \
  --exclude-pre-releases \
  --limit 1 \
  --json tagName -q '.[0].tagName'
)

if git rev-parse "${VERSION}" >/dev/null 2>&1; then
  echo "Version ${VERSION} already exists. No update needed."
  exit 0
fi

echo "Updating to version ${VERSION}..."

gh release download \
  "${VERSION}" \
  --repo ${REPO} \
  -p ${NAME} \
  -D . \
  -O ${NAME} --clobber

# Extract and filter platforms
TMP_DIR=".build"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
unzip -qo "$NAME" -d "$TMP_DIR"

# SIMPLE CLEANING: Keep only iOS and Info.plist
for f in "$TMP_DIR/Sentry.xcframework"/*; do
  [[ $(basename "$f") =~ ios-|Info.plist ]] || rm -rf "$f"
done

# Re-zip cleaned content
(cd "$TMP_DIR" && zip -r "../$NEW_NAME" .)
rm -rf "$TMP_DIR" "$NAME"

DOWNLOAD_URL="https://github.com/${MY_REPO}/releases/download/${VERSION}/${NEW_NAME}"
SUM=$(sha256sum "${NEW_NAME}" | awk '{print $1}')

NOTES=$(cat <<END
SPM binaryTarget

\`\`\`swift
.binaryTarget(
    name: "Sentry",
    url: "${DOWNLOAD_URL}",
    checksum: "${SUM}"
)
\`\`\`
END
)
echo "${NOTES}"

BUILD=$(date +%s)
NEW_VERSION=${VERSION}

echo "${NEW_VERSION}.${BUILD}" > version
git add version
git commit -m "new Version ${NEW_VERSION}"
git tag -a "${NEW_VERSION}" -m "v${NEW_VERSION}"
git push origin HEAD --tags

gh release create "${NEW_VERSION}" "${NEW_NAME}" --notes "${NOTES}"
