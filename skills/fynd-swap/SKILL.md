---
name: fynd-swap
description: >-
  Sets up and runs a Fynd DEX aggregator instance and executes on-chain swaps
  end-to-end. Handles Rust installation, Fynd build, solver startup, route
  quoting via /v1/quote, calldata encoding, signing, and transaction submission.
  Use when someone says "set up Fynd", "swap tokens with Fynd", "run a swap",
  "Fynd quickstart", "get a Fynd quote", or "execute a trade with Fynd".
---

Set up Fynd and execute on-chain swaps from zero to tx hash.

## When to Use

- Setting up Fynd for the first time
- Getting a swap quote
- Executing a swap on Ethereum mainnet
- Troubleshooting a Fynd instance

## When NOT to Use

- Modifying Fynd internals (use the Fynd repo docs)
- Multi-chain deployments (Ethereum only for now)
- Production deployment infrastructure

## Learnings

Read [LEARNINGS.md](LEARNINGS.md) first. Apply any lessons before proceeding.

## Workflow

One skill, five phases. Detect which phases are complete and skip them.

### Phase 1: Prerequisites

Check and install dependencies. See [references/setup.md](references/setup.md) for details.

1. Check Rust >= 1.92: `rustc --version`
   - If missing or outdated: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
2. Check Fynd repo at `{{FYND_DIR}}` (default `~/fynd`):
   - If missing: `git clone https://github.com/propeller-heads/fynd.git {{FYND_DIR}}`
3. Check environment variables:
   - `TYCHO_API_KEY` - **required**. Prompt user if not set. Get from propellerheads.xyz/tycho.
   - `RPC_URL` - **strongly recommended**. Free RPCs (llamarpc, cloudflare-eth, ankr) frequently time out on gas price fetches, crashing the solver. Use a dedicated endpoint (Alchemy, Infura, QuikNode).
   - `PRIVATE_KEY` - required only for execution (Phase 5)
4. Verify: `rustc --version` succeeds and `{{FYND_DIR}}/Cargo.toml` exists.

### Phase 2: Build

Build the Fynd solver and tutorial binary.

1. Skip if `target/release/fynd` AND `target/release/examples/tutorial` exist and are newer than source.
2. Build:
   ```bash
   cd {{FYND_DIR}} && cargo build --release --examples
   ```
3. Create `.env` in `{{FYND_DIR}}` if not present (see [references/setup.md](references/setup.md) for template).
4. Verify: both binaries exist.

### Phase 3: Run Solver

Start the Fynd solver HTTP server.

1. Check if already running:
   ```bash
   curl -s http://localhost:3000/v1/health
   ```
2. If not running, start in background:
   ```bash
   cd {{FYND_DIR}} && RUST_LOG=info cargo run --release -- serve \
     --tycho-url tycho-beta.propellerheads.xyz \
     --rpc-url {{RPC_URL}} \
     --protocols uniswap_v2,uniswap_v3
   ```
   Note: `--` goes between `--release` and `serve` (cargo convention).
3. Poll `/v1/health` every 5s until `"healthy": true`. Timeout after 5 minutes. Do not log individual poll attempts.
4. Verify: health endpoint returns healthy.
5. If trouble: see [references/troubleshooting.md](references/troubleshooting.md).

### Phase 4: Get Trade Intent and Quote

Resolve tokens and get a quote from the solver.

1. If user specified tokens and amount (e.g., "swap 100 USDC to WETH"):
   - Resolve symbols to addresses using [references/tokens.md](references/tokens.md).
   - Convert human-readable amount to raw amount using token decimals.
2. If not specified, ask: "What would you like to swap? Example: 100 USDC to WETH"
3. For unknown token symbols, ask the user for the contract address.
4. Get quote:
   ```bash
   curl -s http://localhost:3000/v1/quote \
     -H "Content-Type: application/json" \
     -d '{
       "orders": [{
         "token_in": "<SELL_ADDRESS>",
         "token_out": "<BUY_ADDRESS>",
         "amount": "<RAW_AMOUNT>",
         "side": "sell",
         "sender": "0x0000000000000000000000000000000000000000"
       }]
     }'
   ```
   Use a zero address for `sender` when quoting only. For execution, use the actual wallet address.
5. Show the user: route (protocols, hops), expected output amount (human-readable), gas estimate.
6. If user wants quote only, stop here.

### Phase 5: Execute

Send a real mainnet transaction. Requires `PRIVATE_KEY`.

1. Confirm `PRIVATE_KEY` is set. Prompt if not.
2. **Warn the user**: "This sends a real mainnet transaction. Use a test wallet with small amounts."
3. Run the tutorial binary:
   ```bash
   cd {{FYND_DIR}} && cargo run --example tutorial -- \
     --sell-token <ADDRESS> \
     --buy-token <ADDRESS> \
     --sell-amount <RAW_AMOUNT> \
     --slippage-bps 50
   ```
4. The tutorial prompts interactively: Simulate / Execute / Cancel.
5. On success: show the tx hash and Etherscan link (`https://etherscan.io/tx/<HASH>`).

## Future: fynd-client Upgrade

`fynd-client` at `clients/rust/` wraps quote -> signable_payload -> sign -> execute.
When ready, Phases 4-5 replace the tutorial binary with fynd-client calls.
Phases 1-3 remain unchanged.

## Reference Index

| File | When to read |
|------|-------------|
| [references/setup.md](references/setup.md) | First-time setup, env var questions |
| [references/troubleshooting.md](references/troubleshooting.md) | Any error during workflow |
| [references/tokens.md](references/tokens.md) | Resolving token symbols, CLI flags, config |
