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
