# lean-in-skills

**Where Lean 4 stops being type-theatre.** Typed schemas plus a verifier-in-the-loop for AI skill outputs.

## What this is

A small library and a methodology for the narrow slice where Lean 4 earns its keep in AI-system design:

- The skill produces structured output (JSON, frontmatter, a typed record).
- The output has invariants you care about (required fields, consistent enums, no dead references, evidence-or-explicit-self-attestation for any "done" state).
- A verifier can actually run against real outputs at the right moment (pre-commit hook, post-skill-invocation check, CI step).

For that slice, a typed Lean schema plus a `by decide` proof beats prose guardrails. Outside that slice, prose wins. This project is the discipline of telling them apart.

## What this is not

- Not a proof-generation system (see Aristotle, Lean Copilot, AlphaProof for that — complementary, not competing).
- Not a comprehensive type system for AI behaviour. Most AI behaviour is perception, not decidability.
- Not Mathlib-dependent at the skeleton level. Add Mathlib per-pilot when a specific tactic needs it.

## The thesis in one sentence

> Lean replaces prose for the slice that is decidable, high-stakes, has a verifier in the loop, survives author absence, and has a read-to-verify ratio that justifies the syntax tax.

That's roughly 10% of typical AI-system guardrails by volume and 80% of operational risk by impact. The full case lives in [`thesis/`](thesis/).

## Why design-time composability, not "let the LLM glue it together"

There is a widely-held alternative position: composability is the LLM's responsibility at runtime. Each skill advertises what it does; the model figures out which to invoke and how to chain them. Many production agent systems take this approach today, and it works well at small N.

It fails predictably as the skill catalogue grows. The failure modes are documented across the industry:

- **Tool-selection lottery.** When N skills have semantic overlap, the same prompt yields different tool selections across runs. The LLM is making an effectively-random choice between near-equivalent options. ([a16z](https://a16z.com/a-deep-dive-into-mcp-and-the-future-of-ai-tooling/) on the workflow gap; [Barry Zhang at Anthropic](https://barryzhang.substack.com/p/making-peace-with-llm-non-determinism) on reducing non-determinism with code components.)
- **Context-window bloat.** Every advertised skill consumes context budget. Tool definitions accumulate; the budget for *actual reasoning* shrinks. With 50+ skills, the model spends a measurable fraction of every turn re-deciding which tool to call.
- **Cascading inconsistency.** A skill chosen on Monday may not be chosen on Tuesday for the same task. Audit trails become non-reproducible.
- **Unverifiable outputs.** A skill that should cite sources, return a value in range, or carry a calibration rationale isn't checked at output time. The reader catches mistakes ad-hoc, or not at all.

Design-time composability addresses each:

| Failure | Design-time response in lean-in-skills |
|---|---|
| Tool-selection lottery | `composes:` field declares dependencies explicitly; type-checking rules out alternatives that don't fit |
| Context-window bloat | Skills are organised into atomics → composites → workflows; the model picks at the level it needs and the rest collapses into a composition |
| Cascading inconsistency | A skill's composition graph is a typed structure, not an LLM choice; same input → same execution path |
| Unverifiable outputs | Typed schemas enforce `requires_source` / `requires_rationale` / range constraints; a `by decide` proof rejects malformed output at save time |

This isn't a claim that runtime LLM composition is wrong everywhere. For exploratory work with a small, well-understood skill catalogue, it works. The argument is narrower: **at scale, with safety-critical outputs, the design-time approach earns its keep**. The runtime camp's elegant simplicity becomes operational unreliability. The design-time camp's syntax tax becomes mechanical correctness.

The five-condition test in [`thesis/03-where-it-doesnt.md`](thesis/03-where-it-doesnt.md) is explicit about where each approach belongs. Most AI behaviour is perception and runtime-glue is fine. The slice we formalise is the slice where wrong-and-confident costs real money.

## How it works

Three layers:

```
Authoring surface          AI/human writes structured output
   (JSON, YAML, MD)        (e.g. a GameAnalysisJSON, a PRD, an ArgumentJSON)
        │
        │  Ingestion (Python → generates a typed Lean instance)
        ▼
Lean representation        A typed value constructed from the JSON,
   (LeanInSkills/*.lean)   with structural invariants baked into types
        │
        │  Verifier (lake build with `by decide`)
        ▼
Verdict                    Pass/fail; failing theorem names what's wrong
```

The pattern: schema lives in the skill folder (`<skill>/lean/<Name>.lean` + `<skill>/check.py`); runtime (lakefile, toolchain, generic infra) is shared at the project root. The runtime is small and portable; schemas travel with the skills that own them.

## Toolchain

Pinned to `leanprover/lean4:v4.29.1`. Build with:

```bash
lake build
```

## What lives where

| Path | Purpose |
|---|---|
| [`thesis/`](thesis/) | Four short docs on the conceptual framing: why-not-prose / where-it-helps / where-it-doesnt / pragmatic-architecture |
| [`audit-mechanism.md`](audit-mechanism.md) | The `lean_audit.status` tag system, four terminal states, and how skill audits happen without contaminating skill execution |
| [`pilots/`](pilots/) | Pilots scaffolded: `skill-graph` (typed skill-composition graph), `draft-lifecycle` (state machine for sends) |
| [`LeanInSkills/`](LeanInSkills/) | Shared Lean modules. Per-skill schemas live in each skill's folder and get vendored at verify time |

## Status

v0.1: three skill-types in production using this pattern (in the author's downstream workspace). One published worked example is queued.

This repo is the canonical home of the pattern. Skill-specific schemas live with the skills that own them (in their respective repos). The runtime here is what all those schemas share.

## Discoverability for AI agents

When a skill carries `lean_audit.status: formally-enhanced` in its frontmatter, the agent finds the verifier via four touchpoints (in order of likely encounter):

1. `lean_audit.verifier_command` in the SKILL.md frontmatter
2. A `## Lean verifier` section in the SKILL.md body
3. Naming conventions: `<skill>/lean/<PascalCase>.lean` + `<skill>/check.py`
4. Inverse lookup via a `/lean-audit` skill that lists formally-enhanced skills

Full design in [`audit-mechanism.md`](audit-mechanism.md).

## Where the pattern came from

Built in 2026 inside a working AI-augmented engineering practice. The first three formally-enhanced skills were strategic-analysis, requirements-tracking, and structured-argumentation tools. The pattern transfers cleanly to other domains; legal-AI applications live with the author's downstream work.

## Contributing

Issues and PRs welcome. The five-condition test in [`thesis/03-where-it-doesnt.md`](thesis/03-where-it-doesnt.md) is the canonical filter: contributions that satisfy all five conditions are likely to land; contributions that satisfy fewer get more discussion. Domain-specific applied examples (your-domain-here schemas) are most valuable as a `pilots/` addition or a separate-repo demonstration linked from this README.

## Roadmap

Items planned but not yet shipped:

- **Cycle detection** for typed composition graphs (Pilot 1 extension; non-Mathlib fuel-bounded recursion is feasible).
- **A worked example schema** for a generic verdict-style skill output (GREEN / YELLOW / RED rating with required-fields-per-rating invariants).
- **A longer-form technical write-up:** *"Design-time vs runtime composability — when does each earn its keep?"* (TODO; not yet authored.)
- **`bundle.py` exporter** for self-contained skill+runtime tarballs (for sharing skills to machines without the runtime installed).

## License

Apache 2.0. See [LICENSE](LICENSE).

## Related work

- Aristotle (Lean theorem prover; complementary)
- Lean Copilot (proof suggestion plugin; complementary)
- AlphaProof (proof generation; different problem)
- LiquidHaskell (refinement types in another language; conceptually parallel)
- agentskills.io and the Agent Skills spec (related design-philosophy space)
- anthropics/claude-for-legal (a domain-specific application of skill patterns; this repo's patterns can be applied there)
