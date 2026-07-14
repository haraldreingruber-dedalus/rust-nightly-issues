#!/usr/bin/env bash
# Reproduce the ICE: rustc panics with
#   "attribute is missing tokens: rustc_test_entrypoint_marker"
# when compiling with -C instrument-coverage on a nightly build.
#
# Usage:
#   ./repro.sh [--edition <2021|2024>] [--toolchain <nightly|nightly-YYYY-MM-DD>]
#
# Defaults:
#   --edition   2024
#   --toolchain nightly

set -euo pipefail

EDITION="2024"
TOOLCHAIN="nightly"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --edition)
            EDITION="$2"
            shift 2
            ;;
        --toolchain)
            TOOLCHAIN="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: $0 [--edition <2021|2024>] [--toolchain <nightly|nightly-YYYY-MM-DD>]" >&2
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CARGO_TOML="$SCRIPT_DIR/Cargo.toml"
CARGO_TOML_BAK="$CARGO_TOML.bak"

echo "==> Repro parameters"
echo "    Edition:   $EDITION"
echo "    Toolchain: $TOOLCHAIN"
echo ""

# Ensure the requested toolchain is installed
rustup toolchain install "$TOOLCHAIN" --no-self-update

# Patch edition in Cargo.toml and restore it on exit
cp "$CARGO_TOML" "$CARGO_TOML_BAK"
trap 'mv "$CARGO_TOML_BAK" "$CARGO_TOML"' EXIT

sed -i "s/^edition = .*/edition = \"$EDITION\"/" "$CARGO_TOML"

echo "==> Running: RUSTFLAGS=\"-C instrument-coverage\" cargo +$TOOLCHAIN test"
echo ""

RUSTFLAGS="-C instrument-coverage" cargo "+$TOOLCHAIN" test --manifest-path "$CARGO_TOML"
