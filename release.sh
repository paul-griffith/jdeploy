#!/bin/bash
set -e
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

if [ -f "$HOME/.jdeploy/release_profile" ]; then
  source "$HOME/.jdeploy/release_profile"
fi

#First build the shared library which is used by both cli and installer
cd shared
mvn clean install

#Next build the installer because we need to sign it and bundle it
cd ../installer
mvn clean package
jdeploy clean package

APP_PATH="jdeploy/bundles/mac/jdeploy-installer.app"
ZIP_PATH="${APP_PATH}.zip"

# Create a ZIP archive suitable for notarization.
/usr/bin/ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

TEAM_ID_FLAG=""
if [ ! -z "$APPLE_TEAM_ID" ]; then
  TEAM_ID_FLAG="--team-id $APPLE_TEAM_ID"
fi

xcrun notarytool store-credentials "AC_PASSWORD" --apple-id "$APPLE_ID" $TEAM_ID_FLAG --password "$APPLE_2FA_PASSWORD"
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "AC_PASSWORD" --wait

bash make_installer_templates.sh
cd ../cli

mvn clean package
CLI_VERSION=$(../json.php version)
if [ "$GITHUB_REF_TYPE" == "tag" ] && [ "$GITHUB_REF_NAME" == "$CLI_VERSION" ]; then
  npm publish
fi

cd ../installer
INSTALLER_VERSION=$(../json.php version)
if [ "$GITHUB_REF_TYPE" == "tag" ] && [ "$GITHUB_REF_NAME" == "$INSTALLER_VERSION" ]; then
  jdeploy publish
fi







