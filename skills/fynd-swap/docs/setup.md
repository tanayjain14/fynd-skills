# Setup & Prerequisites

## Requirements

- **Rust >= 1.92** (for async trait support and latest features)
- **Git** (to clone the Fynd repo)
- **~2 GB disk** (for Rust toolchain + Fynd build)

## Install Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
rustc --version  # Should be >= 1.92
```

If Rust is already installed but outdated:
```bash
rustup update stable
```

## Clone Fynd

```bash
git clone https://github.com/propeller-heads/fynd.git {{FYND_DIR}}
```

Default `{{FYND_DIR}}` is `~/fynd`. User can override.

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `TYCHO_API_KEY` | Yes | - | Tycho API key (get from propellerheads.xyz/tycho) |
| `RPC_URL` | Yes | - | Dedicated Ethereum RPC (Alchemy, Infura, QuikNode). Free RPCs crash the solver. |
| `PRIVATE_KEY` | For execution | - | Wallet private key (hex, no 0x prefix) |
| `RUST_LOG` | No | `info` | Log verbosity (trace, debug, info, warn, error) |

## .env Template

Create `{{FYND_DIR}}/.env`:

```env
TYCHO_API_KEY={{TYCHO_API_KEY}}
RPC_URL={{RPC_URL}}
# PRIVATE_KEY=<hex-without-0x-prefix>
# RUST_LOG=info
```

## Build

```bash
cd {{FYND_DIR}} && cargo build --release --examples
```

First build takes 3-10 minutes depending on hardware.

## Verify Build

Check that the tutorial binary exists:
```bash
ls -la {{FYND_DIR}}/target/release/examples/tutorial
```

Note: The solver does not produce a standalone `target/release/fynd` binary.
Run the solver via `cargo run --release -- serve`. The tutorial binary IS at
`target/release/examples/tutorial`.

## Skip Build

If `target/release/examples/tutorial` exists and is newer than the latest source
change, the build step can be skipped.
