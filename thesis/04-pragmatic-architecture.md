# 04. Pragmatic architecture

A Lean overlay on AI-skill design is only useful if it ships. This document is the shape of "ships".

## Architecture in three layers

```
┌────────────────────────────────────────────────────────────────┐
│  Layer 3: Authoring surface (humans + Claude write here)       │
│  - SKILL.md files                                              │
│  - CLAUDE.md files                                             │
│  - JSON artefacts (prd.json, cxdb.json, customer-intel JSONs)  │
│  - Documents (Markdown, DOCX, draft emails)                    │
└────────────────────────────────────────────────────────────────┘
                            │
                            │  Ingestion (Python or Lean directly)
                            ▼
┌────────────────────────────────────────────────────────────────┐
│  Layer 2: Lean representation                                  │
│  - Typed graph (SkillRegistry)                                 │
│  - Typed allowlists (SubProcessor)                             │
│  - Inductive state machines (DraftLifecycle)                   │
│  - JSON-as-Lean-structure (PRD, CXDB)                          │
└────────────────────────────────────────────────────────────────┘
                            │
                            │  Verifier (lake build, decide, custom tactic)
                            ▼
┌────────────────────────────────────────────────────────────────┐
│  Layer 1: Verdict (build pass/fail)                            │
│  - Pre-commit hook                                             │
│  - CI step                                                     │
│  - Pre-tool-call hook in .claude/settings.json                 │
└────────────────────────────────────────────────────────────────┘
```

The unidirectional flow matters. Layer 3 is the authoring surface and nothing else; the model does not write Lean unless extending a pilot. Layer 2 is generated from Layer 3 by ingestion. Layer 1 runs Layer 2 and emits a verdict.

## Why this shape

- **Humans and Claude keep writing in their natural medium.** Markdown, JSON, YAML. The model is not forced to write proofs.
- **The Lean overlay is generated.** Drift between authoring surface and Lean representation is a build-time error, not a vigilance problem.
- **The verifier is where it matters.** Pre-commit catches drift before merge. CI catches it on PRs. Pre-tool-call catches it before a send.

## What the ingestion step actually does

For Pilot 1 (skill graph) the ingestion script reads `.claude/skills/*/SKILL.md`, parses the YAML frontmatter, and emits a Lean file like:

```lean
def skillRegistry : SkillRegistry :=
  [ { name := "email-read", level := .atomic, operation := .read
    , inputs := [], outputs := [.emailRef]
    , composes := [] }
  , { name := "email-triage", level := .composite, operation := .read
    , inputs := [.emailRef], outputs := [.text]
    , composes := ["email-read"] }
  , ...
  ]
```

Then a Lean theorem `example : AllReferencesKnown skillRegistry := by decide` either compiles or fails. If it fails, the failing reference is the build error.

## What the pre-tool-call hook does for Pilot 3

Before any tool that posts, sends, or files runs, a small wrapper:

1. Reads the current draft state from the harness session.
2. Calls a Lean-compiled CLI (or a precompiled decision table) that consults `DraftLifecycle`.
3. Returns allow / deny, with the failing transition named.

The harness already supports pre-tool-call hooks. The hook is the integration point that turns a Lean type into a runtime control.

## What success looks like

| Pilot | Day-zero state | Success state |
|---|---|---|
| skill-graph | Composes references unchecked | Pre-commit fails on broken or type-incompatible references |
| sub-processor-allowlist | Drift detected only when a customer reads a stale document | CI fails on a PR that introduces an unlisted sub-processor |
| draft-lifecycle | Slack draft protocol enforced by reader discipline | Pre-tool-call hook rejects an unapproved-yet-posted draft |

The metric is not "Lean code written" but "build failures prevented".

## What success does not look like

- A Lean library that nobody runs against real artefacts.
- A blog post longer than the actual implementations.
- A formalisation that has more types than the underlying domain has cases.

The discipline of `03-where-it-doesnt.md` applies in reverse here. Ship verifier-first; the formalisation is the means.

## Upstream contribution shape

For claude-for-legal, the upstream-bound artefact is a `references/lean-verified-legal-decision-example/` directory containing:

- A self-contained Lean project (one decidable predicate, one state machine, one Mathlib `grind` proof).
- A README that explains the pattern, not just the code.
- A small synthetic example showing how it would slot into one of the existing plugins (probably `regulatory-legal` or `ai-governance-legal`, where multi-jurisdiction logic benefits most).
- A note on the Eduardo-Anthropic toolchain alignment (v4.29.1, the `grind` improvements that landed in v4.29.0 specifically improve Aristotle-style proofs).

The contribution is the pattern. The repo is the proof that the pattern shipped.
