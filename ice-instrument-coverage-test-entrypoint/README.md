# ICE: rustc panics with `attribute is missing tokens: rustc_test_entrypoint_marker`

## Bug Description

`rustc 1.99.0-nightly (daf2e5e18 2026-07-13)` (`nightly-2026-07-14`) panics
with an ICE when compiling with `-C instrument-coverage` if
`mockall_double`'s `#[double]` appears alongside `serial_test`'s `#[serial]`
on `#[test]` functions. Regression vs `nightly-2026-07-13`.

### Panic message

```
thread 'rustc' panicked at compiler/rustc_ast/src/attr/mod.rs:307:
attribute is missing tokens: Attribute { kind: Normal(NormalAttr { item: AttrItem {
  path: rustc_test_entrypoint_marker#66, args: Unparsed(Empty) }, tokens: None }), ... }
```

### Root cause

`#[serial]` (from serial_test) rewrites `#[test]` into an item that carries a
`rustc_test_entrypoint_marker` attribute with `tokens: None`. The coverage
instrumentation pass calls `Attribute::token_trees()` on it, which asserts
`tokens.is_some()` — panic.

`#[double]` (from mockall_double) on a module-level `use` item provides the
proc-macro expansion context that pushes the compiler into this path.

### Regression window

- **Good:** `nightly-2026-07-13` (commit `77cf889bc 2026-07-12`)
- **Bad:** `nightly-2026-07-14` (commit `daf2e5e18 2026-07-13`)

## Repro Steps

```sh
cd ice-instrument-coverage-test-entrypoint
RUST_BACKTRACE=1 RUSTFLAGS="-C instrument-coverage --cfg coverage_nightly" \
    cargo +nightly-2026-07-14 test
```

Or use the helper script:

```sh
chmod +x repro.sh
./repro.sh
```

Expected: tests compile and run normally.

Actual: ICE / compiler panic.

## Dependencies

| Crate           | Version |
|-----------------|---------|
| mockall         | 0.15    |
| mockall_double  | 0.3.1   |
| serial_test     | 3.5.0   |
