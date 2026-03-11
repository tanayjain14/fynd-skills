# v1 Learning: First End-to-End Test

From the first clean install test (curl install → quote).

## Timeline

| Step | Duration | Result |
|------|----------|--------|
| Install via `curl \| bash` | <1s | Worked (repo was public) |
| Phase 1: Prerequisites | ~10s | Rust 1.92 present, cloned Fynd |
| Phase 2: Build | 5m 20s | `cargo build --release --examples` |
| Phase 3: Solver (3 failed free RPCs) | ~15min wasted | llamarpc, cloudflare, ankr all crashed |
| Phase 3: Solver (QuikNode) | 25s | Healthy on first try |
| Phase 4: Quote (wrong format) | <1s | API schema mismatch |
| Phase 4: Quote (correct format) | <1s | 102ms solve, success |
| Total | ~35min | ~15min avoidable |

## Critical Bugs Found

1. **Cargo CLI syntax wrong** — `cargo run --release serve --` vs correct
   `cargo run --release -- serve`. Basic cargo convention, would block every user.

2. **Quote API format wrong** — Skill documented flat `sell_token`/`buy_token` fields.
   Actual API uses `orders` array with `token_in`/`token_out`/`amount`/`side`/`sender`.
   Written from assumptions, not from reading `fynd-rpc-types/src/lib.rs`.

3. **Free RPCs crash the solver** — Default llamarpc and every free RPC tested caused a
   panic in `gas.rs:39` (unwrap on RPC timeout), killing the entire solver. 3/3 free
   RPCs failed. Dedicated RPC is effectively required.

## Moderate Issues

4. **Health poll timeout too short** (3min) — Changed to 5min.
5. **Noisy polling** — "Attempt 1... Attempt 36..." reduces confidence. Silent polling better.
6. **Binary path wrong** — `target/release/fynd` doesn't exist. Solver runs via `cargo run`.
7. **No crash detection** — Skill kept polling a dead process for minutes instead of
   detecting the solver had exited.

## Root Cause

All critical bugs share one root cause: the skill was written from a plan, not from
running the software. A single test run would have caught all three.

## What Worked

- Skill install and invocation framework
- 5-phase detect-and-skip structure
- Tycho data sync (~12s for uni v2+v3)
- Quote accuracy and speed (102ms)
- LEARNINGS.md pattern for capturing issues
