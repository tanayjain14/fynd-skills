# Troubleshooting

## Common Errors

| Symptom | Cause | Fix |
|---------|-------|-----|
| `rustc: command not found` | Rust not installed | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` then restart shell |
| Build dependency errors | Stale cargo cache | `cargo clean && cargo build --release --examples` |
| Health returns 503 | Tycho data still syncing | Wait 30-90s for uniswap_v2+v3. Check logs for sync progress. |
| Gas price panic / solver crashes after sync | Free RPC timed out on `eth_getBlockByNumber` | Use a dedicated RPC (Alchemy, Infura, QuikNode). Free RPCs are unreliable for gas price fetches. |
| `stream error: Missing block!` | Tycho sent a block update with no protocol data for subscribed exchanges. Bug in `tycho-simulation` decoder treats empty updates as fatal. | Transient — restart the solver. Use the auto-restart wrapper in Phase 3 to handle this automatically. |
| Connection refused :3000 | Solver not running | Start solver (Phase 3 in SKILL.md) |
| `"No route found"` | No liquidity path between tokens | Check token addresses are correct, try a different pair |
| `"Sell/buy token not found"` | Token not indexed by Tycho | Verify the address is a valid ERC-20 on Etherscan |
| `"Cyclical swaps"` | Encoding limitation with multi-hop | Try `--protocols uniswap_v3` only (single protocol) |
| `"Swap encoder not found"` | Protocol mismatch between solver and tutorial | Use the same `--protocols` flag on both solver and tutorial |
| Simulation failed | RPC doesn't support `eth_simulate` | Try `--use-tenderly` flag on the tutorial binary |
| `"insufficient funds"` | Wallet balance too low | Fund wallet with the sell token + ETH for gas |
| Private key error | Wrong format | Must be hex string without `0x` prefix |
| Port 3000 in use | Another process on that port | Use `--http-port 3001` on solver, update tutorial `--solver-endpoint` |
| `TYCHO_API_KEY` error | Missing or invalid API key | Get key from propellerheads.xyz/tycho, set in `.env` |
| Permit2 approval error | Token not approved for Permit2 | The tutorial handles approval automatically; ensure wallet has ETH for gas |

## Diagnostic Steps

### Solver won't start
1. Check `TYCHO_API_KEY` is set: `echo $TYCHO_API_KEY`
2. Check port is free: `lsof -i :3000`
3. Check logs for errors: look for `ERROR` lines in solver output
4. Try with minimal protocols: `--protocols uniswap_v3`

### Quote returns empty or bad price
1. Verify token addresses in [tokens.md](tokens.md)
2. Check the sell amount is in raw units (not human-readable)
3. Try a well-known pair first (USDC -> WETH) to verify solver works
4. Check solver logs for routing errors

### Transaction fails on-chain
1. Check wallet has enough sell token balance
2. Check wallet has ETH for gas
3. Increase slippage: `--slippage-bps 100` (1%)
4. Try simulation first before executing
5. Check if token has transfer fees or restrictions

## Getting Help

- Fynd repo issues: https://github.com/propeller-heads/fynd/issues
- Tycho API key: https://propellerheads.xyz/tycho
