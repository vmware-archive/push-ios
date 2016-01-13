#!/bin/bash

set -e
set -x

xcodebuild \
  -workspace PCFPush.xcworkspace \
  -scheme "ALL PCFPushSpecs" \
  -destination platform='iOS Simulator',name="${XCODE_SIMULATOR_NAME}",OS="${XCODE_OS_VERSION}" \
  clean build test
