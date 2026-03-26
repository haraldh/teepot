# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2024 Matter Labs
{ lib
, inputs
, stdenv
, makeRustPlatform
, nixsgx ? null
, pkg-config
, rust-bin
, pkgs
, openssl
,
}:
let
  rustVersion = rust-bin.fromRustupToolchainFile (inputs.src + "/rust-toolchain.toml");
  rustPlatform = makeRustPlatform {
    cargo = rustVersion;
    rustc = rustVersion;
  };
  craneLib = (inputs.crane.mkLib pkgs).overrideToolchain rustVersion;
  commonArgs = {
    nativeBuildInputs = [
      pkg-config
      rustPlatform.bindgenHook
    ];

    buildInputs = [
      openssl.dev
      nixsgx.sgx-dcap-quoteverify
    ]
    ++ lib.optionals (stdenv.hostPlatform.system == "x86_64-linux") [
      nixsgx.sgx-dcap.libtdx_attest
    ];

    strictDeps = true;

    src =
      with lib.fileset;
      toSource {
        root = inputs.src;
        fileset = unions [
          # Default files from crane (Rust and cargo files)
          (craneLib.fileset.commonCargoSources inputs.src)
          # deny.toml and friends
          (fileFilter (file: file.hasExt "toml") inputs.src)
          # Custom test data files
          (maybeMissing (inputs.src + "/crates/teepot/tests/data"))
          (maybeMissing (inputs.src + "/crates/intel-dcap-api/tests/test_data"))
          # special files
          (maybeMissing (inputs.src + "/crates/teepot-tdx-attest-sys/bindings.h"))
        ];
      };

    checkType = "debug";
    env = {
      OPENSSL_NO_VENDOR = "1";
      NIX_OUTPATH_USED_AS_RANDOM_SEED = "aaaaaaaaaa";
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    };
  };

  cargoArtifacts = craneLib.buildDepsOnly (
    commonArgs
    // {
      pname = "teepot-workspace";
    }
  );
in
{
  inherit
    rustPlatform
    rustVersion
    commonArgs
    craneLib
    cargoArtifacts
    ;
}
