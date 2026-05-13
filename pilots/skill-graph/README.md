# Pilot 1: SKILL.md compositional graph schema

## Goal

Make the `.claude/skills/` directory's `composes:` graph a build-time invariant. Broken references, type-incompatible composes edges, and orphaned skills become compile errors.

## What it formalises

For every SKILL.md file's YAML frontmatter:

- `level: atomic | composite | workflow`
- `operation: READ | WRITE | READ+WRITE`
- `composition.inputs: List IOType`
- `composition.outputs: List IOType`
- `composes: List String` (must point to existing skill names with compatible outputs)

## Architecture

```
.claude/skills/*/SKILL.md
       │
       │  scripts/lean-in-skills/build-skill-registry.py
       ▼
LeanInSkills/Generated/SkillRegistry.lean   (auto-generated, gitignored)
       │
       │  lake build
       ▼
Build passes  ⟺  AllReferencesKnown ∧ TypeCompatible
```

## Implementation tasks

1. Define the canonical IOType enum in `LeanInSkills/SkillGraph.lean` (mostly done in scaffold).
2. Write `scripts/lean-in-skills/build-skill-registry.py` that parses every SKILL.md YAML frontmatter and emits a `Generated/SkillRegistry.lean` file.
3. Add a theorem in `LeanInSkills/SkillGraph.lean` (or a side module) that asserts `AllReferencesKnown skillRegistry` and `∀ edge ∈ skillRegistry.composes, TypeCompatible edge`, both by `decide` or a custom tactic.
4. Add a pre-commit hook to `.git/hooks/pre-commit` (or via `.claude/settings.json` hooks) that runs ingestion + `lake build` when any SKILL.md changes.
5. Add a regression test: a deliberately broken SKILL.md (`tests/broken-reference/`) must fail the build.

## Estimated effort

2 dev-days. The ingestion script is the bulk; the Lean side is small.

## Risks

- IOType vocabulary is debatable. Resolution: start with the union of currently-declared inputs and outputs in the host workspace; refine when the first build fails on a real edge.
- Pre-commit hook latency. `lake build` on a small library is fast (~1s), but ingestion adds latency. Resolution: only re-run on SKILL.md changes, cache aggressively.
- Existing SKILL.md files may not have complete frontmatter. Resolution: the build fails; we fix the SKILL.md files; this is the point.

## Done definition

- `lake build` succeeds on a clean repo.
- A test that deliberately breaks a `composes:` reference fails the build.
- The hook is wired and demonstrated.
- README updated with "how to add a new skill" steps that reference the verifier.
