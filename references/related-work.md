# Related work

## Anthropic-adjacent

- **Aristotle** — Anthropic's theorem prover. Built on Mathlib tactics. Latest improvements landed in Lean v4.29.0 (higher-order Miller pattern in `grind`).
- **Lean Copilot** — proof suggestion plugin; complementary.
- **`anthropics/claude-for-legal`** — a domain-specific application of skill design patterns. The patterns in this repo can be applied there.

## Formal-methods-for-AI references

- **DeepMind's AlphaProof** — proof generation, IMO-level. Different problem (proof generation vs. specification mechanisation).
- **Functional Software Verification** (Coq, Isabelle, Dafny ecosystems) — older traditions of "types as specifications". Conceptually parallel; tooling more enterprise.
- **LiquidHaskell** — refinement types in Haskell; same idea (types carry refinement predicates) in a different ecosystem.

## What this repo is not

The dominant story in "formal methods + AI" is *proof generation* (AlphaProof, Aristotle, Lean Copilot): AI helps write Lean proofs. This project is the *inverse story*: Lean helps specify AI-system behaviour. The two are complementary but distinct.

This repo is not a competitor to Aristotle. It is the spec layer that Aristotle could prove things about.

## Lean toolchain notes

- Canonical: `leanprover/lean4:v4.29.1`
- Quarterly review for toolchain bumps
- Skip release candidates (RC versions) by policy
- v4.29.0 brought `grind` higher-order Miller pattern support; matters for Aristotle-style workflows on goals involving combinators
