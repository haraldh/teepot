# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Teepot is a Rust toolkit for Trusted Execution Environments (TEEs), providing attestation verification, cryptographic
operations, and utilities for Intel SGX and TDX. Part of the Matter Labs ecosystem.

## Build & Development

Nix is the primary build system. Enter the dev shell with `nix develop` (or `direnv allow` if using direnv).

| Task                               | Command                                                                      |
|------------------------------------|------------------------------------------------------------------------------|
| Build all                          | `nix build .#teepot`                                                         |
| Build as CI would                  | `nix run github:nixos/nixpkgs/nixos-25.11#nixci -- build`                    |
| Run all checks (clippy, fmt, deny) | `nix flake check`                                                            |
| Format (Rust + TOML)               | `nix run .#fmt`                                                              |
| Run all tests                      | `cargo test --workspace`                                                     |
| Run a single test                  | `cargo test -p <crate> <test_name>`                                          |
| Build a container                  | `nix build -L .#container-<name>`                                            |
| TDX VM test                        | `nixos-rebuild -L --flake .#tdxtest build-vm && ./result/bin/run-tdxtest-vm` |
| TOML format check                  | `taplo fmt --check`                                                          |

## Architecture

**Workspace layout:**

- `crates/teepot` — Core TEE abstraction library (config, crypto, quote verification, SGX/TDX support)
- `crates/intel-dcap-api` — Intel DCAP API client with automatic retry on rate limiting
- `crates/teepot-tee-quote-verification-rs` — Fork of Intel's quote verification library
- `crates/teepot-tdx-attest-rs` / `teepot-tdx-attest-sys` — TDX attestation FFI (x86_64-linux only, excluded from
  workspace on other platforms)
- `bin/` — Binary executables (verify-attestation, tee-key-preexec, rtmr-calc, etc.)
- `packages/` — Nix package and OCI container definitions (uses crane for Rust builds)
- `checks/` — Nix flake checks (cargoClippy, cargoDeny, cargoFmt)
- `shells/` — Nix dev shell definition
- `systems/` — NixOS system configurations (TDX VM testing)

**Key patterns:**

- Error handling uses `anyhow::Result` throughout; custom error types for `QuoteError` and `IntelApiError`
- Async runtime is Tokio; HTTP via actix-web and reqwest
- Crypto: secp256k1, p256, RSA, x509-cert; sensitive data uses `zeroize`
- Tracing via OpenTelemetry + tracing-subscriber

## Code Quality Requirements

- **SPDX headers**: Every source file must have an SPDX license header (`// SPDX-License-Identifier: Apache-2.0` or
  `BSD-3-Clause` or `MIT`). Enforced by CI.
- **TOML formatting**: Checked via `taplo fmt --check` in CI.
- **Clippy, cargo fmt, cargo deny**: Run as Nix flake checks (not standalone cargo commands in CI).
- **Rust toolchain**: 1.94.0 (pinned in `rust-toolchain.toml`)
- **License**: Apache-2.0 OR MIT (except forked Intel crates which are BSD-3-Clause)

## Platform Notes

- SGX/TDX features and libraries are only available on x86_64-linux
- `crates/teepot-tdx-attest-rs` and `crates/teepot-tdx-attest-sys` are excluded from the workspace on non-x86_64
  platforms
- CI builds on x86_64-linux, aarch64-linux, and aarch64-darwin
