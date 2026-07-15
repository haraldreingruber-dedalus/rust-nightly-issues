# ice-repro-2 — instrument-coverage ICE with mockall_double + serial_test

## Bug

`rustc 1.99.0-nightly (daf2e5e18 2026-07-13)` (`nightly-2026-07-14`) panics
with an ICE when compiling a crate in test mode with `-C instrument-coverage`
if the crate uses **mockall_double**'s `#[double]` on a `use` item together
with **serial_test**'s `#[serial]` on `#[test]` functions.

Regression vs `nightly-2026-07-13` (`77cf889bc 2026-07-12`).

## Panic message

```
thread 'rustc' panicked at compiler/rustc_ast/src/attr/mod.rs:307:36:
attribute is missing tokens: Attribute { kind: Normal(NormalAttr { item: AttrItem {
  path: rustc_test_entrypoint_marker#66, args: Unparsed(Empty) }, tokens: None }),
  ... }
```

## Root cause

The `rustc_test_entrypoint_marker` attribute injected by the test-harness
generator ends up with `tokens: None` in this nightly. The coverage
instrumentation pass then calls `Attribute::token_trees()`, which asserts
`tokens.is_some()`, causing the panic.

`#[serial]` (from serial_test) expands the `#[test]` function into an item that
triggers this path; `#[double]` (from mockall_double) provides the necessary
proc-macro expansion context.

## Reproduce

```bash
rustup toolchain install nightly-2026-07-14
RUST_BACKTRACE=1 RUSTFLAGS="-C instrument-coverage --cfg coverage_nightly" \
    cargo +nightly-2026-07-14 test
```

Or use the helper script:

```bash
chmod +x repro.sh
./repro.sh
```

## Dependencies

| Crate           | Version |
|-----------------|---------|
| mockall         | 0.15    |
| mockall_double  | 0.3.1   |
| serial_test     | 3.5.0   |
