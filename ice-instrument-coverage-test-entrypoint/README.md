# ICE: rustc panics with `attribute is missing tokens: rustc_test_entrypoint_marker`

## Bug Description

`rustc 1.99.0-nightly (daf2e5e18 2026-07-13)` panics with an ICE in
`rustc_ast/src/attr/mod.rs` when compiling with `-C instrument-coverage`
(used by `cargo llvm-cov`).

### Panic message

```
attribute is missing tokens: ... rustc_test_entrypoint_marker
```

### Root cause

The compiler's internal `rustc_test_entrypoint_marker` attribute (injected
when processing `#[test]` functions) is missing its token representation
(`tokens: None`), which `Attribute::token_trees()` requires. This is called
from the macro expansion path (`fully_expand_fragment`), triggered by the
coverage instrumentation pass.

### Regression window

- **Good:** nightly-2026-07-12
- **Bad:** nightly-2026-07-13 (commit `daf2e5e18`)

## Repro Steps

```sh
cd ice-instrument-coverage-test-entrypoint
RUSTFLAGS="-C instrument-coverage" cargo test
```

Expected: tests compile and run normally.

Actual: ICE / compiler panic.

## Notes

- The `edition = "2024"` in `Cargo.toml` appears to be a factor; try
  `edition = "2021"` to check whether the edition matters.
- The `#[serial]` attribute is **not** needed to reproduce.
- Tracked upstream: <https://github.com/rust-lang/rust> around commit
  `daf2e5e18`.
