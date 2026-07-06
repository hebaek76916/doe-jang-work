#!/usr/bin/env bash
# 출근도장 Mac 앱을 Release로 빌드해서 배포용 .dmg를 만든다.
# 앱스토어 없이 GitHub Releases 등으로 파일 공유하는 용도.
#   사용: ./scripts/build-mac-dmg.sh
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="출근도장"
SCHEME="WorkStampMac"
DERIVED="build-release"
DIST="dist"

echo "▶︎ 프로젝트 생성 (xcodegen)"
command -v xcodegen >/dev/null && xcodegen generate

echo "▶︎ Release 빌드"
xcodebuild -project WorkStamp.xcodeproj -scheme "$SCHEME" \
  -configuration Release -derivedDataPath "$DERIVED" build >/dev/null

APP="$DERIVED/Build/Products/Release/$SCHEME.app"
[ -d "$APP" ] || { echo "빌드 산출물 없음: $APP"; exit 1; }

echo "▶︎ .dmg 패키징"
rm -rf "$DIST/dmg-staging" "$DIST/$APP_NAME.dmg"
mkdir -p "$DIST/dmg-staging"
cp -R "$APP" "$DIST/dmg-staging/$APP_NAME.app"
ln -sf /Applications "$DIST/dmg-staging/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$DIST/dmg-staging" \
  -ov -format UDZO "$DIST/$APP_NAME.dmg" >/dev/null
rm -rf "$DIST/dmg-staging"

echo "✅ 완성: $DIST/$APP_NAME.dmg"
echo "   서명 없음(ad-hoc) — 받는 사람은 우클릭 > 열기 로 최초 1회 허용해야 함 (dist/README 참고)"
