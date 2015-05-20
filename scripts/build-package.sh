#!/bin/bash

set -e
set -x

xcodebuild -scheme PCFPush-Universal clean build
