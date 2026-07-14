# ICE: rustc panics with `attribute is missing tokens: rustc_test_entrypoint_marker`

## Bug Description

`rustc 1.99.0-nightly (daf2e5e18 2026-07-13)` (released as `nightly-2026-07-14`) panics with an ICE in
`rustc_ast/src/attr/mod.rs` when compiling with `-C instrument-coverage`
(used by `cargo llvm-cov`) together with the `coverage_attribute` feature
and `#[coverage(off)]` attributes.

### Panic message

```
attribute is missing tokens: ... rustc_test_entrypoint_marker
```

### Root cause

The ICE is triggered by the interaction of `-C instrument-coverage` +
`feature(coverage_attribute)` + `#[coverage(off)]` attributes. The
`coverage_attribute` feature causes the compiler to parse and process those
attributes during macro expansion (`fully_expand_fragment`), which is where
the panic occurs: the internal `rustc_test_entrypoint_marker` attribute
(injected when processing `#[test]` functions) is missing its token
representation (`tokens: None`), which `Attribute::token_trees()` requires.

### Regression window

- **Good:** nightly-2026-07-13
- **Bad:** nightly-2026-07-14 (commit `daf2e5e18`)

## Repro Steps

### Via `cargo test` with `-C instrument-coverage`

```sh
cd ice-instrument-coverage-test-entrypoint
RUST_BACKTRACE=1 RUSTFLAGS="-C instrument-coverage --cfg coverage_nightly" cargo test
```

### Via `cargo llvm-cov` (requires [`cargo-llvm-cov`](https://github.com/taiki-e/cargo-llvm-cov))

```sh
cargo install cargo-llvm-cov  # one-time setup
cd ice-instrument-coverage-test-entrypoint
RUST_BACKTRACE=1 RUSTFLAGS="--cfg coverage_nightly" cargo llvm-cov --all-features
```

Both commands use the toolchain pinned in `rust-toolchain.toml` (`nightly-2026-07-14`).

Expected: tests compile and run normally.

Actual: ICE / compiler panic.

## Key details

- The `--cfg coverage_nightly` flag (passed via `RUSTFLAGS`) is essential: it
  activates both `feature(coverage_attribute)` and the `#[coverage(off)]`
  attribute simultaneously, replicating the exact conditions under which the
  ICE occurs.
- `edition = "2024"` in `Cargo.toml` appears to be a factor; try
  `edition = "2021"` to check whether the edition matters.
- The `#[serial]` attribute is **not** needed to reproduce.
- Tracked upstream: <https://github.com/rust-lang/rust> around commit
  `daf2e5e18`.
