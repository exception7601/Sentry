NAME=Sentry.xcframework.zip
REPO=getsentry/sentry-cocoa

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

SUM=$(swift package compute-checksum ${NAME} )
URL=$(gh release view ${VERSION} \
  --repo ${REPO} \
  --json assets \
  -q ".assets[] | select(.name == \"${NAME}\").url"
)

NOTES=$(cat <<END
SPM binaryTarget

\`\`\`
.binaryTarget(
  name: "Sentry",
  url: "${URL}",
  checksum: "${SUM}"
)
\`\`\`
END
)
echo "${NOTES}"

BUILD=$(date +%s)
NEW_VERSION=${VERSION}.${BUILD}

echo ${NEW_VERSION} > version
git add version
git commit -m "new Version ${NEW_VERSION}"
git tag -s -a ${NEW_VERSION} -m "v${NEW_VERSION}"
git checkout -b release-v${NEW_VERSION}
git push origin HEAD --tags

gh release create ${NEW_VERSION} ${NAME} --notes "${NOTES}"
