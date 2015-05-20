#!/bin/bash

set -e
set -x

xcodebuild -scheme PCFDataTests clean build test
