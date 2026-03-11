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

## User Communication

At each phase, tell the user what's happening and what to expect. Be concise and
confident. Never show retry loops or polling attempts — just report the final result.

## Workflow

One skill, five phases. Detect which phases are complete and skip them.

### Phase 1: Prerequisites

Tell user: **"Checking prerequisites..."**

Check and install dependencies. See [references/setup.md](references/setup.md) for details.

1. Check Rust >= 1.92: `rustc --version`
   - If missing or outdated: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
2. Check Fynd repo at `{{FYND_DIR}}` (default `~/fynd`):
   - If missing: `git clone https://github.com/propeller-heads/fynd.git {{FYND_DIR}}`
3. Check environment variables:
   - `TYCHO_API_KEY` — **required**. Prompt user if not set. Get from propellerheads.xyz/tycho.
   - `RPC_URL` — **strongly recommended**. Free RPCs (llamarpc, cloudflare-eth, ankr) frequently time out on gas price fetches, crashing the solver. Use a dedicated endpoint (Alchemy, Infura, QuikNode).
   - `PRIVATE_KEY` — required only for execution (Phase 5).
4. Verify: `rustc --version` succeeds and `{{FYND_DIR}}/Cargo.toml` exists.

Tell user: **"Prerequisites ready. Rust {version}, Fynd repo at {path}."**

### Phase 2: Build

Tell user: **"Building Fynd. First build takes ~5 minutes — sit tight."**

1. Skip if `target/release/examples/tutorial` exists and is newer than source.
   Note: There is no standalone `target/release/fynd` binary. The solver runs via `cargo run`.
2. Build:
   ```bash
   cd {{FYND_DIR}} && cargo build --release --examples
   ```
3. Create `.env` in `{{FYND_DIR}}` if not present (see [references/setup.md](references/setup.md)).
4. Verify: `target/release/examples/tutorial` exists.

Tell user: **"Build complete ({duration})."**

### Phase 3: Run Solver

Tell user: **"Starting the Fynd solver..."**

1. Check if already running:
   ```bash
   curl -s http://localhost:3000/v1/health
   ```
   If healthy, skip to Phase 4.

2. **Pre-flight RPC check** — before starting the solver, verify the RPC is reachable:
   ```bash
   curl -s -X POST {{RPC_URL}} \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
   ```
   If this fails or times out, tell user their RPC is unreachable and ask for a different one.
   Do NOT proceed with a broken RPC — the solver will crash.

3. Start solver in background **using the auto-restart wrapper**:
   ```bash
   FYND_DIR={{FYND_DIR}} RPC_URL={{RPC_URL}} TYCHO_API_KEY={{TYCHO_API_KEY}} \
     ~/.claude/skills/fynd-swap/scripts/fynd-run.sh
   ```
   The wrapper script (`scripts/fynd-run.sh`) automatically restarts the solver
   on transient crashes (e.g. Tycho `Missing block!` stream errors). It caps at
   10 restarts within 5 minutes to avoid infinite loops on persistent failures.
   The solver re-syncs in ~25s per restart.

   Optional flags: `--protocols`, `--tycho-url`, `--fynd-dir`, `--rpc-url`.

4. Poll `/v1/health` silently every 5s. Timeout after 5 minutes.
   - Do NOT print individual poll attempts.
   - **Crash detection**: if the health endpoint was responding and then stops, check
     if the background process is still alive. If it exited, read the last 20 lines of
     its output log and show the error to the user. Common causes:
       - RPC timeout crashing the gas price fetcher (use dedicated RPC)
       - `Missing block!` from Tycho stream (auto-restart handles this)

Tell user: **"Solver is running and healthy. Synced {num_pools} pool(s) in {duration}."**

### Phase 4: Get Trade Intent and Quote

1. If user specified tokens and amount (e.g., "swap 100 USDC to WETH"):
   - Resolve symbols to addresses using [references/tokens.md](references/tokens.md).
   - Convert human-readable amount to raw amount using token decimals.
2. If not specified, ask: "What would you like to swap? Example: 100 USDC to WETH"
3. For unknown token symbols, ask the user for the contract address.

Tell user: **"Getting quote for {amount} {sell_token} to {buy_token}..."**

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
   Use a zero address for `sender` when quoting only. For execution, use the wallet address.

   Working example (1 WETH to USDC):
   ```bash
   curl -s http://localhost:3000/v1/quote \
     -H "Content-Type: application/json" \
     -d '{
       "orders": [{
         "token_in": "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
         "token_out": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
         "amount": "1000000000000000000",
         "side": "sell",
         "sender": "0x0000000000000000000000000000000000000000"
       }]
     }'
   ```

5. Parse the response. Key fields:
   - `orders[0].status` — "success" or error status
   - `orders[0].amount_out` — raw output amount (convert to human-readable)
   - `orders[0].route.swaps` — array of hops (each has `protocol`, `token_in`, `token_out`)
   - `orders[0].gas_estimate` — gas units
   - `solve_time_ms` — solver computation time

6. Present results clearly:

   Tell user:
   ```
   Quote: {sell_amount} {sell_token} -> {buy_amount} {buy_token}
   Route: {num_hops} hop(s) via {protocols}
   Gas estimate: {gas} units
   Solved in: {solve_time}ms
   ```

7. If user wants quote only, stop here.

### Phase 5: Execute

Send a real mainnet transaction. Requires `PRIVATE_KEY`.

1. Confirm `PRIVATE_KEY` is set. Prompt if not.
2. **Warn the user**: "This sends a real mainnet transaction. Use a test wallet with small amounts."
3. Run the tutorial binary:
   ```bash
   cd {{FYND_DIR}} && cargo run --release --example tutorial -- \
     --sell-token <ADDRESS> \
     --buy-token <ADDRESS> \
     --sell-amount <RAW_AMOUNT> \
     --slippage-bps 50
   ```
4. The tutorial prompts interactively: Simulate / Execute / Cancel.
5. On success: show tx hash and Etherscan link (`https://etherscan.io/tx/<HASH>`).

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
