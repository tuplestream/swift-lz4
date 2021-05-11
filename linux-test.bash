#!/usr/bin/env bash

set -euo pipefail

rm -rf .build
swift test --generate-linuxmain
docker pull tuplestream/swift-env:latest
docker run --rm -v $(pwd):/lz4-testing -w /lz4-testing -it tuplestream/swift-env:latest swift test
