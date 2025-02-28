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

echo ${VERSION}

gh release download \
  ${VERSION} \
  --repo ${REPO} \
  -p ${NAME} \
  -D . \
  -O ${NAME} --clobber

mv $NAME $NEW_NAME

SUM=$(swift package compute-checksum ${NEW_NAME} )
DOWNLOAD_URL="https://github.com/${MY_REPO}/releases/download/${VERSION}/${NEW_NAME}"

if [ ! -f $JSON_FILE ]; then
  echo "{}" > $JSON_FILE
fi

# Make Carthage
JSON_CARTHAGE="$(jq --arg version "${VERSION}" --arg url "${DOWNLOAD_URL}" '. + { ($version): $url }' $JSON_FILE)" 
echo $JSON_CARTHAGE > $JSON_FILE

NOTES=$(cat <<END
Carthage
\`\`\`
binary "https://raw.githubusercontent.com/${MY_REPO}/main/${JSON_FILE}"
\`\`\`

Install
\`\`\`
carthage bootstrap --use-xcframeworks
\`\`\`

SPM binaryTarget

\`\`\`
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

# echo ${NEW_VERSION} > version
git add $JSON_FILE
git commit -m "new Version ${NEW_VERSION}"
git tag -s -a ${NEW_VERSION} -m "v${NEW_VERSION}"
# git checkout -b release-v${NEW_VERSION}
git push origin HEAD --tags

gh release create ${NEW_VERSION} ${NEW_NAME} --notes "${NOTES}"
