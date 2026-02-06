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

echo "${VERSION}"

gh release download \
  "${VERSION}" \
  --repo ${REPO} \
  -p ${NAME} \
  -D . \
  -O ${NAME} --clobber

mv $NAME "$NEW_NAME"

DOWNLOAD_URL="https://github.com/${MY_REPO}/releases/download/${VERSION}/${NEW_NAME}"
SUM=$(sha256sum "${NEW_NAME}")
SUM=${SUM%% *}

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
git commit -m "new Version ${NEW_VERSION}" --allow-empty
git tag -a "${NEW_VERSION}" -m "v${NEW_VERSION}"
git push origin HEAD --tags

gh release create "${NEW_VERSION}" "${NEW_NAME}" --notes "${NOTES}"
