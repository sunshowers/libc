#!/bin/env bash
#:
#: name = "x86_64-unknown-illumos"
#: variety = "basic"
#: target = "helios-latest"

# Note: we use ci/install-rust.sh rather than buildomat to install Rust, for
# consistency with other CI jobs.
exec .github/buildomat/build-and-test.sh illumos
