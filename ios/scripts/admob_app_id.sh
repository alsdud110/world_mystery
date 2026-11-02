#!/bin/sh
# Runner build phase "AdMob App ID": sets GADApplicationIdentifier in the
# built Info.plist.
#
# Debug and Profile get Google's sample App ID (also the value in
# Runner/Info.plist), so they never request real ads. Release takes
# ADMOB_IOS_APP_ID from the dart-defines that
# `--dart-define-from-file=config/ads.local.json` (git-ignored) puts in
# DART_DEFINES (Flutter/Generated.xcconfig: comma-separated base64
# "KEY=VALUE" entries), and stops the build when it or one of the two ad unit
# IDs is missing, malformed or Google's sample ID.
# The IDs are never printed.
set -e

PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
SAMPLE_PUBLISHER="ca-app-pub-3940256099942544"
TEST_APP_ID="${SAMPLE_PUBLISHER}~1458002511"

# Prints the value of dart-define $1 (nothing when it is not passed).
dart_define() {
  old_ifs=$IFS
  IFS=','
  for entry in $DART_DEFINES; do
    decoded=$(printf '%s' "$entry" | /usr/bin/base64 -D 2>/dev/null) || continue
    case "$decoded" in
      "$1="*)
        IFS=$old_ifs
        printf '%s' "${decoded#*=}" | tr -d '[:space:]'
        return 0
        ;;
    esac
  done
  IFS=$old_ifs
}

# Checks release ID $1 against separator $2 ("~" App ID, "/" ad unit).
problems=0
check_release_id() {
  value=$(dart_define "$1")
  case "$value" in
    "")
      echo "error: A release build needs $1. Build with --dart-define-from-file=config/ads.local.json (see config/ads.example.json)."
      problems=1
      ;;
    "$SAMPLE_PUBLISHER"*)
      echo "error: $1 is Google's test ID; a release build needs the real ID (config/ads.local.json)."
      problems=1
      ;;
    ca-app-pub-[0-9]*"$2"[0-9]*) ;;
    *)
      echo "error: $1 is not an AdMob ID (config/ads.local.json)."
      problems=1
      ;;
  esac
}

case "$CONFIGURATION" in
  Release*)
    check_release_id ADMOB_IOS_APP_ID "~"
    check_release_id ADMOB_IOS_BANNER_ID "/"
    check_release_id ADMOB_IOS_REWARDED_ID "/"
    if [ "$problems" -ne 0 ]; then
      exit 1
    fi
    APP_ID=$(dart_define ADMOB_IOS_APP_ID)
    ;;
  *)
    APP_ID="$TEST_APP_ID"
    ;;
esac

/usr/libexec/PlistBuddy -c "Set :GADApplicationIdentifier $APP_ID" "$PLIST" >/dev/null
