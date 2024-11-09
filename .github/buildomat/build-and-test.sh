#!/bin/env bash

set -o errexit
set -o pipefail
set -o xtrace

# Enable ANSI colors in Cargo output.
export CARGO_TERM_COLOR=always

banner install
TOOLCHAIN=stable INSTALL_RUSTUP=1 ptime -m sh ci/install-rust.sh

banner run.sh
ptime -m sh ci/run.sh x86_64-unknown-illumos
