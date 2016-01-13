#!/bin/sh
# This script is based on Jacob Van Order's answer on apple dev forums https://devforums.apple.com/message/971277
# See also http://spin.atomicobject.com/2011/12/13/building-a-universal-framework-for-ios/ for the start

set -e
set -x

# To get this to work with a Xcode 6 Cocoa Touch Framework, create Framework
# Then create a new Aggregate Target. Throw this script into a Build Script Phrase on the Aggregate


######################
# Options
######################

PODSPEC=PCFPush.podspec

REVEAL_ARCHIVE_IN_FINDER="${REVEAL_ARCHIVE_IN_FINDER-true}"

FRAMEWORK_NAME="${PROJECT_NAME}"

SIMULATOR_LIBRARY_PATH="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${FRAMEWORK_NAME}.framework"

DEVICE_LIBRARY_PATH="${BUILD_DIR}/${CONFIGURATION}-iphoneos/${FRAMEWORK_NAME}.framework"

UNIVERSAL_LIBRARY_DIR="${BUILD_DIR}/${CONFIGURATION}-iphoneuniversal"

FRAMEWORK="${UNIVERSAL_LIBRARY_DIR}/${FRAMEWORK_NAME}.framework"

###########################
# Read version from podspec
###########################

set +x

V=$(cat version)

echo "PCF Push Version is '$V'."

set -x

######################
# Build Frameworks
######################

# Note that GCC_PREPROCESSOR_DEFINITIONS is used to set a compiler definition with the current project version and CURRENT_PROJECT_VERSION sets a build setting with the current project version (read from the PCFPush.podspec file above).

xcodebuild -verbose GCC_PREPROCESSOR_DEFINITIONS="_PCF_PUSH_VERSION=\\\"$V\\\"" CURRENT_PROJECT_VERSION=$V -project ${PROJECT_NAME}.xcodeproj -sdk iphonesimulator -target ${PROJECT_NAME} -configuration ${CONFIGURATION} clean build CONFIGURATION_BUILD_DIR=${BUILD_DIR}/${CONFIGURATION}-iphonesimulator

xcodebuild -verbose GCC_PREPROCESSOR_DEFINITIONS="_PCF_PUSH_VERSION=\\\"$V\\\"" CURRENT_PROJECT_VERSION=$V -project ${PROJECT_NAME}.xcodeproj -sdk iphoneos -target ${PROJECT_NAME} -configuration ${CONFIGURATION} clean build CONFIGURATION_BUILD_DIR=${BUILD_DIR}/${CONFIGURATION}-iphoneos

######################
# Create directory for universal
######################

rm -rf "${UNIVERSAL_LIBRARY_DIR}"

mkdir "${UNIVERSAL_LIBRARY_DIR}"

mkdir "${FRAMEWORK}"


######################
# Copy files Framework
######################

cp -r "${DEVICE_LIBRARY_PATH}/." "${FRAMEWORK}"


######################
# Make fat universal binary
######################

lipo "${SIMULATOR_LIBRARY_PATH}/${FRAMEWORK_NAME}" "${DEVICE_LIBRARY_PATH}/${FRAMEWORK_NAME}" -create -output "${FRAMEWORK}/${FRAMEWORK_NAME}" | echo


######################
# On Release, copy the result to desktop folder
######################

if [ "${CONFIGURATION}" == "Release" ]; then
    rm -rf "build/release-universal/"
    mkdir -p "build/release-universal/"
    cp -r "${FRAMEWORK}" "build/release-universal/"
fi


######################
# If needed, open the Framework folder
######################

if [ ${REVEAL_ARCHIVE_IN_FINDER} = true ]; then
    if [ "${CONFIGURATION}" == "Release" ]; then
        open "build/release-universal/"
    else
        open "${UNIVERSAL_LIBRARY_DIR}/"
    fi
fi

