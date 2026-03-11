# Token Addresses & CLI Reference

## Token Addresses (Ethereum Mainnet)

| Token | Address | Decimals |
|-------|---------|----------|
| WETH | `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2` | 18 |
| USDC | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` | 6 |
| USDT | `0xdAC17F958D2ee523a2206206994597C13D831ec7` | 6 |
| DAI | `0x6B175474E89094C44Da98b954EedeAC495271d0F` | 18 |
| WBTC | `0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599` | 8 |

For tokens not listed here, ask the user for the contract address and verify it is a valid ERC-20 on Etherscan.

## Contract Addresses

| Contract | Address |
|----------|---------|
| TychoRouter (Ethereum) | `0xabA2fC41e2dB95E77C6799D0F580034395FF2B9E` |
| Permit2 | `0x000000000022D473030F116dDEE9F6B43aC78BA3` |

## Amount Conversion

Convert human-readable amounts to raw amounts using decimals:
- `100 USDC` = `100000000` (100 * 10^6)
- `1 WETH` = `1000000000000000000` (1 * 10^18)
- `0.5 WBTC` = `50000000` (0.5 * 10^8)

## Tutorial CLI Flags

```
cargo run --example tutorial -- \
  --sell-token <ADDRESS>     # Token to sell
  --buy-token <ADDRESS>      # Token to buy
  --sell-amount <RAW_AMOUNT> # Amount in smallest unit (wei, etc.)
  --slippage-bps <BPS>       # Slippage tolerance (default: 50 = 0.5%)
  --solver-endpoint <URL>    # Solver URL (default: http://localhost:3000)
  --use-tenderly             # Use Tenderly for simulation instead of eth_simulate
```

## Solver CLI Flags

```
cargo run --release serve -- \
  --tycho-url <URL>          # Tycho endpoint (default: tycho-beta.propellerheads.xyz)
  --protocols <LIST>         # Comma-separated protocols (e.g., uniswap_v2,uniswap_v3)
  --http-port <PORT>         # HTTP port (default: 3000)
  --tvl-threshold <USD>      # Min TVL for pools (default varies)
```

## Supported Protocols

Common protocols for `--protocols` flag:
- `uniswap_v2` - Uniswap V2 and forks
- `uniswap_v3` - Uniswap V3
- `uniswap_v4` - Uniswap V4
- `sushiswap` - SushiSwap
- `balancer_v2` - Balancer V2
- `curve` - Curve Finance

Start with `uniswap_v2,uniswap_v3` for fastest sync and broadest coverage.

## Fast worker_pools.toml

For faster startup, create `worker_pools.toml` in `{{FYND_DIR}}`:

```toml
[[pools]]
protocols = ["uniswap_v2", "uniswap_v3"]
tvl_threshold = 10000.0
```

This filters to pools with >$10k TVL, reducing sync time significantly.
