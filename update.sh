NAME=Sentry.xcframework.zip
REPO=getsentry/sentry-cocoa
MY_REPO=exception7601/Sentry
BUILD_COMMIT=$(git log --oneline --abbrev=16 --pretty=format:"%h" -1)
JSON_FILE="Carthage/SentryBinary.json"
NEW_NAME=Sentry-${BUILD_COMMIT}.zip

VERSION=$(gh release list \
  --repo ${REPO} \
  --exclude-pre-releases \
  --limit 1 \
  --json tagName -q '.[0].tagName'
)

if git rev-parse "v${VERSION}" >/dev/null 2>&1; then
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

if [ ! -f $JSON_FILE ]; then
  echo "{}" > $JSON_FILE
fi

# Make Carthage
JSON_CARTHAGE="$(jq --arg version "${VERSION}" --arg url "${DOWNLOAD_URL}" '. + { ($version): $url }' $JSON_FILE)" 
echo "$JSON_CARTHAGE" > "$JSON_FILE"

NOTES=$(cat <<END
Carthage
\`\`\`
binary "https://raw.githubusercontent.com/${MY_REPO}/main/${JSON_FILE}"
\`\`\`

Install
\`\`\`
carthage bootstrap --use-xcframeworks
\`\`\`
END
)
echo "${NOTES}"

# BUILD=$(date +%s)
NEW_VERSION=${VERSION}

# echo "$PACKAGE" > Package.swift
# echo ${NEW_VERSION} > version
git add $JSON_FILE
git commit -m "new Version ${NEW_VERSION}"
git tag -a "${NEW_VERSION}" -m "v${NEW_VERSION}"
# git checkout -b release-v${NEW_VERSION}
git push origin HEAD --tags

gh release create "${NEW_VERSION}" "${NEW_NAME}" --notes "${NOTES}"
