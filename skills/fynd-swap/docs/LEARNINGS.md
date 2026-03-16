# Learnings

Lessons learned from running the fynd-swap skill. Updated automatically.

## Cargo CLI syntax

The `--` separator goes between cargo flags and the binary subcommand:
- Correct: `cargo run --release -- serve --tycho-url ...`
- Wrong: `cargo run --release serve -- --tycho-url ...`

## Free RPCs crash the solver

The gas price fetcher panics on RPC timeouts (unwrap on error). Public/free RPCs
(llamarpc, cloudflare-eth, ankr) frequently time out, causing full solver shutdown.
Always use a dedicated RPC (Alchemy, Infura, QuikNode). This is effectively required,
not optional.

## Quote API format

The `/v1/quote` endpoint expects `orders` array, not flat fields:
```json
{
  "orders": [{
    "token_in": "0x...",
    "token_out": "0x...",
    "amount": "1000000000000000000",
    "side": "sell",
    "sender": "0x0000000000000000000000000000000000000000"
  }]
}
```
Fields are `token_in`/`token_out` (not `sell_token`/`buy_token`), `amount` (not
`sell_amount`), and requires `side` and `sender`.

## Solver sync timing

With uniswap_v2+v3 on a good RPC, the solver becomes healthy in ~25s.
Data sync (Tycho) takes ~12s, derived data computation takes ~10s more.
Set health poll timeout to 5 minutes to be safe.

## Binary location

`cargo build --release --examples` does NOT produce `target/release/fynd`.
The solver binary is run via `cargo run --release -- serve`. The tutorial
binary IS at `target/release/examples/tutorial`.

## Tutorial --sell-amount takes human-readable float

`--sell-amount 22.0` means 22 USDC (human-readable), NOT 22000000 (raw).
The tutorial converts internally using token decimals from Tycho.

## Health endpoint: parse JSON, not just HTTP status

`/v1/health` returns HTTP 200 even when `"healthy": false`. Must parse JSON
and check both `"healthy": true` AND `"derived_data_ready": true`.

## Tutorial interactive prompt requires TTY

`dialoguer::Select` fails with "not a terminal" when stdin is piped.
Use `--simulate-only` for non-interactive simulation, or `expect` for execution.

## Tutorial outputs two transactions

Approval tx first, then swap tx. Report both hashes to the user.

## Use fynd-run.sh to start the solver

`fynd-run.sh` lives in the skill directory at `~/.claude/skills/fynd-swap/scripts/fynd-run.sh`,
NOT in the Fynd repo. Use it with `--fynd-dir ~/fynd`. It auto-restarts the solver on
transient Tycho "Missing block!" stream errors.

## --tycho-url defaults to localhost:4242

The solver binary defaults `--tycho-url` to `localhost:4242`, NOT the remote Tycho API.
Always pass `--tycho-url tycho-beta.propellerheads.xyz` explicitly or the solver will
crash with "Unable to load tokens: error sending request for url (https://localhost:4242/v1/tokens)".

## --protocols must be explicit

Without `--protocols`, the solver tries to sync ALL protocols from Tycho. This hangs
for minutes with no progress. Always pass `--protocols uniswap_v2,uniswap_v3` for
fast sync (~20s).

## worker_pools.toml is required

Solver crashes without it. The Fynd repo ships a default one. If running from
a different directory, create it (see tokens.md for the format).
