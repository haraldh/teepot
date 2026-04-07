# teepot

- `teepot`: The main rust crate that abstracts TEEs.
    - `verify-attestation`: A client utility that verifies the attestation of an enclave.
    - `tee-key-preexec`: A pre-exec utility that generates a p256 secret key and passes it as an environment variable to
      the
      enclave along with the attestation quote containing the hash of the public key.
    - `tdx_google`: A base VM running on Google Cloud TDX. It receives a container URL via the instance metadata,
      measures the sha384 of the URL to RTMR3 and launches the container.
    - `tdx-extend`: A utility to extend an RTMR register with a hash value.
    - `rtmr-calc`: A utility to calculate RTMR1 and RTMR2 from a GPT disk, the linux kernel, the linux initrd
      and a UKI (unified kernel image).
    - `sha384-extend`: A utility to calculate RTMR registers after extending them with a digest.

## Development

### Prerequisites

Install [nix](https://zero-to-nix.com/start/install).

In `~/.config/nix/nix.conf`

```ini
experimental-features = nix-command flakes
sandbox = true
```

or on nixos in `/etc/nixos/configuration.nix` add the following lines:

```nix
{
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
      sandbox = true
    '';
  };
}
```

### Develop

```shell
$ nix develop
```

optionally create `.envrc` for `direnv` to automatically load the environment when entering the directory:

```shell
$ cat <<EOF > .envrc
use flake .#teepot
EOF
$ direnv allow
```

### Format for commit

```shell
$ nix run .#fmt
```

### Build as the CI would

```shell
$ nix run github:nixos/nixpkgs/nixos-25.11#nixci -- build
```

### Build and test individual container

See the `packages` directory for the available packages and containers.

```shell
$ nix build -L .#container-self-attestation-test-sgx-azure
[...]
teepot-self-attestation-test-sgx-azure-manifest-app-customisation-layer> Measurement:
teepot-self-attestation-test-sgx-azure-manifest-app-customisation-layer>     eaaabf210797606bcfde818a52e4a434fbf4f2e620d7edcc7025e3e1bbaa95c4
[...]
$ export IMAGE_TAG=$(docker load < result | grep -Po 'Loaded image.*: \K.*')
$ docker run -v $(pwd):/mnt -i --init --rm $IMAGE_TAG "cp app.sig /mnt"
$ nix shell github:matter-labs/nixsgx#gramine -c gramine-sgx-sigstruct-view app.sig
Attributes:
    mr_signer: c5591a72b8b86e0d8814d6e8750e3efe66aea2d102b8ba2405365559b858697d
    mr_enclave: eaaabf210797606bcfde818a52e4a434fbf4f2e620d7edcc7025e3e1bbaa95c4
    isv_prod_id: 0
    isv_svn: 0
    debug_enclave: False
```

### TDX VM testing

```shell
nixos-rebuild  -L --flake .#tdxtest build-vm && ./result/bin/run-tdxtest-vm
```

## Release

```shell
$ cargo release 0.1.0 --manifest-path crates/teepot-tdx-attest-sys/Cargo.toml  --sign
$ cargo release 0.1.2 --manifest-path crates/teepot-tdx-attest-rs/Cargo.toml  --sign
$ cargo release 0.6.0 --manifest-path crates/teepot-tee-quote-verification-rs/Cargo.toml  --sign
$ cargo release 0.6.0 --sign
```
