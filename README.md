# fynd-skills

Claude Code skills for the Fynd DEX aggregator.

## Skills

### fynd-swap

Sets up and runs a Fynd instance and executes on-chain swaps end-to-end: Rust installation, build, solver startup, quoting via `/v1/quote`, calldata encoding, signing, and transaction submission.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/tanayjain14/fynd-skills/main/skills/fynd-swap/install.sh | bash
```

This downloads the skill files to `~/.claude/skills/fynd-swap/`.

## Usage

Open Claude Code and type:

```
/fynd-swap
```

Or just say things like:
- "set up Fynd"
- "swap 100 USDC to WETH"
- "get a Fynd quote"

The skill walks through five phases:
1. **Prerequisites** - Rust, Fynd repo, env vars
2. **Build** - `cargo build --release --examples`
3. **Run Solver** - Start and health-check the HTTP server
4. **Quote** - Resolve tokens, call `/v1/quote`, show route
5. **Execute** - Permit2 sign, simulate, submit tx

Each phase detects prior completion and skips if already done.

## File Structure

```
skills/fynd-swap/
├── SKILL.md              # Main skill (5-phase workflow)
├── LEARNINGS.md          # Accumulated lessons (grows with use)
├── install.sh            # One-liner installer
└── references/
    ├── setup.md          # Prerequisites, env vars, build
    ├── troubleshooting.md # Error patterns and fixes
    └── tokens.md         # Token addresses, CLI flags, config
```

## Requirements

- [Claude Code](https://claude.ai/claude-code) CLI
- [Tycho API key](https://propellerheads.xyz/tycho) (for solver data)
- Ethereum RPC (defaults to llamarpc.com)
- Private key (only for execution, not for quoting)
