# Learnings

Lessons learned from running the fynd-swap skill. Updated automatically.

## How the solver works end-to-end

1. **Startup**: `cargo run --release -- serve` launches Fynd, which connects to
   Tycho's WebSocket at `tycho-beta.propellerheads.xyz`.
2. **Sync**: Tycho streams protocol component snapshots (uniswap_v2: ~1930 pools,
   uniswap_v3: ~1059 pools). Takes ~12s on a good RPC.
3. **Derived data**: After sync, Fynd computes spot prices (~4666), token prices
   (~1952), and pool depths (~4463). Takes ~10s more. Solver is healthy after ~25s total.
4. **Streaming**: Tycho sends block-by-block delta updates via WebSocket. Fynd
   decodes them, updates market data, and recomputes derived data each block.
5. **Quoting**: HTTP server on `:3000` accepts `/v1/quote` requests. Worker pools
   (most_liquid_3_hops, most_liquid_2_hops_fast) route through the live market data.

## Known crash: "Missing block!" (Tycho stream)

**Observed**: Solver runs healthy for ~28 minutes, processing blocks normally
(24635259 through 24635393). Then crashes with:
```
ERROR fynd_rpc::builder: tycho feed error error=stream error: Missing block!
```

**Root cause**: `tycho-simulation-0.243.0/src/evm/decoder.rs` in the `decode()`
method. When a `FeedMessage` arrives with an empty `state_msgs` map, the decoder
calls `.next()` on an empty iterator and throws `StreamDecodeError::Fatal`. The
likely trigger is a network-level issue (dropped WebSocket message, Tycho
server hiccup, or deserialization failure) — not necessarily "no protocol
activity" since both protocols were actively streaming updates until the crash.

**Error propagation**: decoder Fatal → `DataFeedError::StreamError` in
`tycho_feed.rs:198` → feed task returns Err → `builder.rs:357` detects feed
died → entire solver shuts down. Fynd has a `reconnect_delay` config but no
actual retry loop — any feed error is terminal.

**Fix**: Created `scripts/fynd-run.sh` — an auto-restart wrapper that relaunches
the solver on crash. Caps at 10 restarts within 5 minutes to avoid infinite
loops on persistent failures. Solver re-syncs cleanly in ~25s per restart.

## Known crash: free RPC timeout

The gas price fetcher panics on RPC timeouts (unwrap on error). Public/free RPCs
(llamarpc, cloudflare-eth, ankr) frequently time out, causing full solver
shutdown. Always use a dedicated RPC (Alchemy, Infura, QuikNode). This is
effectively required, not optional. The pre-flight RPC check in Phase 3 catches
unreachable RPCs but can't predict intermittent timeouts.

## Cargo CLI syntax

The `--` separator goes between cargo flags and the binary subcommand:
- Correct: `cargo run --release -- serve --tycho-url ...`
- Wrong: `cargo run --release serve -- --tycho-url ...`

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

## Binary location

`cargo build --release --examples` does NOT produce `target/release/fynd`.
The solver runs via `cargo run --release -- serve`. The tutorial binary IS at
`target/release/examples/tutorial`.

## Solver sync timing

With uniswap_v2+v3 on a good RPC (QuikNode), the solver becomes healthy in ~25s.
Data sync (Tycho WebSocket) takes ~12s, derived data computation takes ~10s more.
Health poll timeout set to 5 minutes to be safe for slower connections.

## v1 test run timeline

First clean install test (curl install to quote). Total ~35min, ~15min avoidable.

| Step | Duration | Result |
|------|----------|--------|
| Install via `curl \| bash` | <1s | Worked |
| Phase 1: Prerequisites | ~10s | Rust 1.92 present, cloned Fynd |
| Phase 2: Build | 5m 20s | `cargo build --release --examples` |
| Phase 3: Solver (3 free RPCs) | ~15min wasted | llamarpc, cloudflare, ankr all crashed |
| Phase 3: Solver (QuikNode) | 25s | Healthy on first try |
| Phase 4: Quote (wrong format) | <1s | API schema mismatch, fixed |
| Phase 4: Quote (correct format) | <1s | 102ms solve, success |

All v1 critical bugs (cargo CLI syntax, quote API format, free RPC crashes)
shared one root cause: skill was written from a plan, not from running the
software. Fixed in v2 by testing against live solver.
