#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Constants
readonly NAME="Sentry.xcframework.zip"
readonly REPO="getsentry/sentry-cocoa"
readonly MY_REPO="exception7601/Sentry"
readonly JSON_FILE="Carthage/SentryBinary.json"

# Function to print error messages
error_exit() {
  echo "ERROR: $1" >&2
  exit 1
}

# Function to print info messages
info() {
  echo "INFO: $1"
}

# Check required commands
for cmd in gh jq swift git; do
  command -v "$cmd" >/dev/null 2>&1 || error_exit "Required command not found: $cmd"
done

# Check for uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
  error_exit "Working directory has uncommitted changes. Please commit or stash them first."
fi

# Get build commit hash
BUILD_COMMIT=$(git log --oneline --abbrev=16 --pretty=format:"%h" -1)
[[ -n "$BUILD_COMMIT" ]] || error_exit "Failed to get BUILD_COMMIT"

readonly NEW_NAME="Sentry-${BUILD_COMMIT}.zip"

# Get latest version from upstream repo
info "Fetching latest version from ${REPO}..."
VERSION=$(gh release list \
  --repo "$REPO" \
  --exclude-pre-releases \
  --limit 1 \
  --json tagName -q '.[0].tagName')

[[ -n "$VERSION" ]] || error_exit "Failed to fetch VERSION from ${REPO}"
info "Latest version: ${VERSION}"

# Download release
info "Downloading ${NAME} from version ${VERSION}..."
gh release download \
  "$VERSION" \
  --repo "$REPO" \
  -p "$NAME" \
  -D . \
  -O "$NAME" --clobber || error_exit "Failed to download release"

# Verify downloaded file exists
[[ -f "$NAME" ]] || error_exit "Downloaded file ${NAME} not found"

# Rename file
info "Renaming to ${NEW_NAME}..."
mv "$NAME" "$NEW_NAME" || error_exit "Failed to rename file"

# Compute checksum
info "Computing checksum..."
SUM=$(swift package compute-checksum "$NEW_NAME") || error_exit "Failed to compute checksum"
[[ -n "$SUM" ]] || error_exit "Checksum is empty"

readonly DOWNLOAD_URL="https://github.com/${MY_REPO}/releases/download/${VERSION}/${NEW_NAME}"

# Ensure JSON file exists
if [[ ! -f "$JSON_FILE" ]]; then
  info "Creating ${JSON_FILE}..."
  echo "{}" > "$JSON_FILE"
fi

# Update Carthage JSON
info "Updating Carthage JSON..."
jq --arg version "$VERSION" --arg url "$DOWNLOAD_URL" '. + { ($version): $url }' "$JSON_FILE" > "${JSON_FILE}.tmp" || error_exit "Failed to update JSON"
mv "${JSON_FILE}.tmp" "$JSON_FILE" || error_exit "Failed to replace JSON file"

# Generate Package.swift content
info "Generating Package.swift..."
cat > Package.swift <<END
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Sentry",
  platforms: [.iOS(.v12)],
  products: [
    .library(
      name: "Sentry",
      targets: [
        "Sentry",
      ]
    ),
  ],

  targets: [
    .binaryTarget(
      name: "Sentry",
      url: "${DOWNLOAD_URL}",
      checksum: "${SUM}"
    )
  ]
)
END

# Verify Package.swift was created
[[ -f "Package.swift" ]] || error_exit "Failed to create Package.swift"

# Generate release notes
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

info "Release notes:"
echo "${NOTES}"

# Commit changes
info "Committing changes..."
git add Package.swift "$JSON_FILE" || error_exit "Failed to stage files"
git commit -m "new Version ${VERSION}" || error_exit "Failed to commit changes"

# Create tag
info "Creating tag ${VERSION}..."
git tag -s -a "$VERSION" -m "v${VERSION}" || error_exit "Failed to create tag"

# Push changes
info "Pushing to repository..."
git push origin HEAD --tags || error_exit "Failed to push changes"

# Create GitHub release
info "Creating GitHub release ${VERSION}..."
gh release create "$VERSION" "$NEW_NAME" --notes "${NOTES}" || error_exit "Failed to create GitHub release"

info "Update completed successfully!"
