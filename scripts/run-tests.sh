#!/bin/bash

set -e
set -x

xcodebuild \
  -workspace PCFPush.xcworkspace \
  -scheme "ALL PCFPushSpecs" \
  -destination platform='iOS Simulator',name="${XCODE_SIMULATOR_NAME-iPhone 6}",OS="${XCODE_OS_VERSION-8.4}" \
  clean build test
