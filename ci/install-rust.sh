#!/usr/bin/env sh
# This is intended to be used in CI only.

set -ex

echo "Setup toolchain"
toolchain=
if [ -n "$TOOLCHAIN" ]; then
  toolchain=$TOOLCHAIN
else
  toolchain=nightly
fi

if [ "$INSTALL_RUSTUP" = "1" ]; then
  echo "Install rustup"

  # If the CI system already has Rust installed, we'll override that
  # installation via sourcing ~/.cargo/env.
  export RUSTUP_INIT_SKIP_PATH_CHECK=yes
  curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain none
  . "$HOME/.cargo/env"

  # It is possible that "$HOME/.cargo/bin" was already in the PATH, in which
  # case the above source would not have any effect. If the directory wasn't
  # present on disk, then some shells negatively cache the PATH lookup and not
  # find the directory even after it is created. To work around this, force a
  # change to the PATH.
  #
  # This is a more portable version of `hash -r`. `hash -r` is part of the POSIX
  # spec [1] but may not be available in all shells. The manual suggests the
  # following, more portable option:
  #
  #    PATH="$PATH"
  #
  # But empirically, that has been observed to not invalidate the cache in some
  # shells. Actually making a change to the PATH should always work (hopefully!)
  #
  # [1] https://pubs.opengroup.org/onlinepubs/9799919799/utilities/hash.html

  # First, add a trailing colon.
  PATH="$PATH:"
  # Then, remove it.
  PATH="${PATH%:}"
fi

if [ "$OS" = "windows" ]; then
  : "${TARGET?The TARGET environment variable must be set.}"
  rustup set profile minimal
  rustup update --force "$toolchain-$TARGET"
  rustup default "$toolchain-$TARGET"
else
  rustup set profile minimal
  rustup update --force "$toolchain"
  rustup default "$toolchain"
fi

if [ -n "$TARGET" ]; then
  echo "Install target"
  rustup target add "$TARGET"
fi

if [ -n "$INSTALL_RUST_SRC" ]; then
  echo "Install rust-src"
  rustup component add rust-src
fi

if [ "$OS" = "windows" ]; then
  if [ "$ARCH_BITS" = "i686" ]; then
    echo "Install MinGW32"
    choco install mingw --x86 --force
  fi

  echo "Find GCC libraries"
  gcc -print-search-dirs
  /usr/bin/find "C:\ProgramData\Chocolatey" -name "crt2*"
  /usr/bin/find "C:\ProgramData\Chocolatey" -name "dllcrt2*"
  /usr/bin/find "C:\ProgramData\Chocolatey" -name "libmsvcrt*"

  if [ -n "$ARCH_BITS" ]; then
    echo "Fix MinGW"
    for i in crt2.o dllcrt2.o libmingwex.a libmsvcrt.a ; do
      cp -f "/C/ProgramData/Chocolatey/lib/mingw/tools/install/mingw$ARCH_BITS/$ARCH-w64-mingw32/lib/$i" "$(rustc --print sysroot)/lib/rustlib/$TARGET/lib"
    done
  fi
fi

echo "Query rust and cargo versions"
command -v rustc
command -v cargo
command -v rustup
rustc -Vv
cargo -V
rustup -Vv
rustup show

echo "Generate lockfile"
N=5
n=0
until [ $n -ge $N ]
do
  if cargo generate-lockfile; then
    break
  fi
  n=$((n+1))
  sleep 1
done
