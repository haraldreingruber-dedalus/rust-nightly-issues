#!/usr/bin/env bash
# Reproduce the ICE: rustc panics with
#   "attribute is missing tokens: rustc_test_entrypoint_marker"
# when compiling with -C instrument-coverage on nightly-2026-07-14.
#
# Trigger: mockall_double's #[double] on a use item + #[serial] on #[test]
# functions causes the coverage instrumentation pass to call token_trees() on a
# rustc_test_entrypoint_marker attribute that has tokens: None.
#
# Usage:
#   ./repro.sh [--toolchain <nightly|nightly-YYYY-MM-DD>]
#
# Default: --toolchain nightly-2026-07-14

set -euo pipefail

TOOLCHAIN="nightly-2026-07-14"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --toolchain)
            TOOLCHAIN="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: $0 [--toolchain <nightly|nightly-YYYY-MM-DD>]" >&2
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CARGO_TOML="$SCRIPT_DIR/Cargo.toml"

echo "==> Repro parameters"
echo "    Toolchain: $TOOLCHAIN"
echo ""

# Ensure the requested toolchain is installed
rustup toolchain install "$TOOLCHAIN" --no-self-update

echo "==> Running: RUST_BACKTRACE=1 RUSTFLAGS=\"-C instrument-coverage --cfg coverage_nightly\" cargo +$TOOLCHAIN test"
echo ""

RUST_BACKTRACE=1 RUSTFLAGS="-C instrument-coverage --cfg coverage_nightly" cargo "+$TOOLCHAIN" test --manifest-path "$CARGO_TOML"
