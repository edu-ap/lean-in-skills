# Audit Mechanism Design

How life-core skills get progressively Lean-enhanced over time without per-invocation latency cost.

## The four terminal states

Every SKILL.md carries a `lean_audit_status` field in its metadata. Four terminal states:

| Status | Meaning | How a skill reaches it |
|---|---|---|
| `not-audited` | Default. Has not been evaluated for Lean-in-skills applicability. | Initial state for every new skill. |
| `audited-no-benefit` | Audit ran; the five-condition test failed; formalisation would not add value. | `/lean-audit <skill>` after evaluation. |
| `audit-queued-for-formalisation` | Audit identified a useful Lean overlay; a corresponding requirement is in `projects/dev/lean-in-skills/prd.json`. | `/lean-audit <skill>` when the audit fires. |
| `formally-enhanced` | Lean overlay is running with a verifier in the loop. | The PRD requirement is closed and the verifier is wired. |

A skill is "satisfactorily enhanced" when its status is either `audited-no-benefit` or `formally-enhanced`. Both are terminal in the sense that no further audit cycle is needed; both represent progress.

`audit-queued-for-formalisation` is a transient state that resolves to `formally-enhanced` once the queued PRD requirement closes.

## The five-condition test

From `thesis/03-where-it-doesnt.md`, a Lean overlay earns its keep when ALL of:

1. **Decidable** — the rule maps to `X → Bool` or `X → Prop` whose truth value is computable.
2. **High-stakes** — wrong outcome costs more than the encoding effort.
3. **Verifier in the loop** — a build, hook, or CI step can actually run the verifier.
4. **Survives author absence** — the formalisation can be extended by someone other than the original author with reasonable assistance.
5. **Read-to-verify ratio is low enough** — the rule is verified often enough that the syntax tax pays back.

If any answer is no, the skill is `audited-no-benefit` and the disqualifying condition is recorded.

## The frontmatter shape

Added to every SKILL.md `metadata` block:

```yaml
metadata:
  # ...existing fields...
  lean_audit:
    status: not-audited           # or audited-no-benefit | audit-queued-for-formalisation | formally-enhanced
    last_run: null                # YYYY-MM-DD when last evaluated; null if never
    queued_prd_req: null          # e.g. "REQ-012" when status is audit-queued-for-formalisation
    disqualifying_condition: null # e.g. "not-decidable" when status is audited-no-benefit
```

`queued_prd_req` and `disqualifying_condition` are populated only when their corresponding status is set. They are null otherwise.

## Trigger surfaces

| Trigger | What fires | Cost | Frequency |
|---|---|---|---|
| `/lean-audit` with no argument | Pick 1-3 un-audited skills; evaluate; tag | ~30s | On demand, ideally weekly |
| `/lean-audit <skill-name>` | Evaluate a named skill | ~30s | On demand, after material modification |
| `git commit` of a modified SKILL.md | Pre-commit hook checks for stale status | <1s | Per commit touching `.claude/skills/` |
| Direct skill invocation | NOTHING. Skill execution is sacred. | 0s | Never |

The deliberate non-trigger is skill invocation. A skill being *used* is not the moment to audit it. The audit lives on write events and meta events.

## The /lean-audit composite skill

Spec for `.claude/skills/_composite/lean-audit/`:

```yaml
name: lean-audit
description: Evaluate one or more skills against the five-condition test for Lean-in-skills applicability; tag with audit status; queue PRD requirements for formalisation candidates
level: 2
operation: READ+WRITE
composition:
  inputs: [skill-path-optional]
  outputs: [audit-report]
composes: []
metadata:
  tags: [meta, infra]
  exportable: false
  lean_audit:
    status: audited-no-benefit
    last_run: 2026-05-13
    disqualifying_condition: "the auditor itself doesn't need a Lean overlay because its decisions are explicitly subjective"
```

Note that the auditor itself is tagged `audited-no-benefit` immediately. It's the case where the rule's input ("does this skill benefit from Lean?") is fundamentally a judgement call. Putting that into a type would be type-theatre by our own definition.

### Skill behaviour

When run with no argument:
1. Scan `.claude/skills/` for SKILL.md files with `lean_audit.status: not-audited`.
2. Sample 1-3 (configurable via `--count`).
3. For each, read the SKILL.md and assess against the five conditions.
4. Emit a per-skill verdict to stdout.
5. Write back to the SKILL.md frontmatter.
6. If a skill is queued for formalisation, append a new requirement to `projects/dev/lean-in-skills/prd.json` and reference it in `lean_audit.queued_prd_req`.

When run with `<skill-name>`:
- Same as above but for the named skill. Force re-audit even if not in `not-audited` state.

When run with `--coverage`:
- Report `(audited-no-benefit + formally-enhanced) / total` as a percentage. Plus a breakdown by status.

## The pre-commit hook

Fires on `git commit` when any SKILL.md in `.claude/skills/` is staged. Logic:

1. Parse the staged SKILL.md.
2. Read the previous version (`git show HEAD:path`).
3. If the operation field changed (e.g. READ → READ+WRITE), or the `composes` list grew, or the `inputs/outputs` types changed: warn that the status may be stale.
4. Do NOT block the commit. Just emit a warning naming the skill.

The hook is non-blocking because false positives would be annoying enough to disable the hook. Soft nudge wins long-term.

## How requirements get added back to lean-in-skills/prd.json

When `/lean-audit` decides a skill should be formalised, it appends a new requirement:

```json
{
  "id": "REQ-XXX",
  "title": "Formalise lean-in-skills overlay for <skill-name>",
  "description": "Audit-queued via /lean-audit on <date>. Conditions satisfied: <which of the five>. Proposed verifier: <verifier shape>.",
  "wsjf_score": <derived from audit>,
  "status": "todo",
  "acceptance_criteria": [
    "Lean module exists in LeanInSkills/<SkillName>.lean",
    "Verifier hook wired to <surface>",
    "Tests cover the happy path and at least one negative case",
    "SKILL.md lean_audit.status updated to formally-enhanced"
  ],
  "depends_on": [],
  "blockers": []
}
```

The PRD cycle then naturally promotes the new requirement when its WSJF rank comes up.

## Why this design

| Property | Per-invocation audit (rejected) | This design |
|---|---|---|
| Latency on normal skill use | 30s+ | 0s |
| Audit depth | Shallow (auditor is multitasking) | Full (auditor is the only job) |
| Path from finding to action | Implicit (notes accumulate) | Explicit (writes to PRD) |
| "Satisfactorily enhanced" as a typed concept | Free text | Frontmatter enum, four values |
| Self-perpetuating | No (depends on memory) | Yes (PRD cycle + commit hook) |
| Lean-friendly proof | No | Yes (the four-state enum is itself the kind of decidable predicate we're promoting) |

## How future agents discover and use Lean verifiers

When a skill is tagged `formally-enhanced`, a future Claude session should be able to find and run the verifier without prior knowledge of this project. Four discoverability touchpoints, in the order an agent encounters them:

### 1. The SKILL.md frontmatter

```yaml
metadata:
  lean_audit:
    status: formally-enhanced
    verifier_command: "python3 scripts/lean-in-skills/check-<skill-name>.py {file}"
```

The `verifier_command` field is the canonical instruction. The literal token `{file}` is the placeholder the agent substitutes with the path to the saved output JSON. Other tokens are not currently used; reserve them for future fields.

### 2. The SKILL.md body has a `## Lean verifier` section

This section is the doctrine-in-the-skill expression of the rule (per `docs/skill-design.md` rule 2). It explicitly states:

- That the skill is formally-enhanced
- Which invariants are enforced
- How to run the verifier
- When to run it (which step in the workflow)
- What to do on failure (do NOT mark the task done; fix the JSON first)

The body section is load-bearing because the model reads the SKILL.md when the skill fires, not the audit-mechanism doc.

### 3. Naming conventions and bundle layout

The schema and the verifier wrapper are owned by the skill and live in its folder. The Lake project, toolchain pin, and generic infrastructure are shared and live at `projects/dev/lean-in-skills/`. This split keeps each skill folder portable while the runtime is shared.

| Artefact | Canonical path | Owned by |
|---|---|---|
| Schema for skill `<name>` | `.claude/skills/<level>/<name>/lean/<PascalCase>.lean` | Skill |
| Schema README | `.claude/skills/<level>/<name>/lean/README.md` | Skill |
| Verifier entry point | `.claude/skills/<level>/<name>/check.py` | Skill |
| Lakefile, toolchain pin | `projects/dev/lean-in-skills/lakefile.lean` plus `lean-toolchain` | Runtime |
| Vendored schema (working copy) | `projects/dev/lean-in-skills/LeanInSkills/<PascalCase>.lean` (gitignored) | Runtime, populated by `check.py` |
| Generated instance | `projects/dev/lean-in-skills/LeanInSkills/Generated/<PascalCase>Instance.lean` (gitignored) | Runtime, populated by `check.py` |
| Test fixtures | `projects/dev/lean-in-skills/tests/<descriptive-name>.json` | Runtime |

A new agent looking for "is there a verifier for game-theory?" finds it at `.claude/skills/_composite/game-theory/check.py` AND `lean/GameAnalysis.lean` in the same folder. Both travel with the skill.

When `check.py` runs it vendors the local schema into the runtime's source tree at `LeanInSkills/<PascalCase>.lean` (gitignored there because the canonical copy is in the skill folder), generates the instance file, and runs `lake build`.

**For sharing this skill to a machine without the runtime:** `check.py` detects the missing runtime and emits a clear install hint with exit code 3.

### 4. Inverse lookup via `/lean-audit`

If an agent is unsure whether a skill has a verifier, they can ask:

```bash
python3 .claude/skills/_composite/lean-audit/lib.py list --status formally-enhanced
```

Returns the list of skills currently in the formally-enhanced state. Filtering by other states is supported via `--status`.

### Worked example: game-theory

Today's chain for the `/game-theory` skill:

```
.claude/skills/_composite/game-theory/SKILL.md
  └─ frontmatter.metadata.lean_audit.verifier_command:
       "python3 scripts/lean-in-skills/check-game-analysis.py {file}"
  └─ body section "## Lean verifier" explains invariants, when to run, what failure means

scripts/lean-in-skills/check-game-analysis.py
  └─ reads the JSON
  └─ generates projects/dev/lean-in-skills/LeanInSkills/Generated/GameAnalysisInstance.lean
  └─ invokes `lake build` in projects/dev/lean-in-skills/
  └─ exit 0 on success, non-zero with the failing theorem name on failure

projects/dev/lean-in-skills/LeanInSkills/GameAnalysis.lean
  └─ defines Verdict, ChecklistItem, PlanningChecklist, Pitfall, PitfallScan, GameAnalysis
  └─ defines wellFormed predicate
  └─ structural invariants (six required checks, five required pitfalls) are type errors,
     not runtime checks
  └─ value invariants (calibration_note when needed) are decided by `by decide`
```

### What future agents do when they fire a formally-enhanced skill

The protocol is:

1. Run the skill normally.
2. Save the output JSON via the skill's existing persistence path.
3. Read `lean_audit.verifier_command` from the SKILL.md frontmatter.
4. Substitute `{file}` with the path to the saved JSON.
5. Run the command. Capture exit code.
6. If exit 0: report the analysis complete.
7. If non-zero: read the failure output, identify the failing invariant, fix the JSON, re-run the verifier. Loop until pass. Do NOT report complete on a failing verifier.

This protocol should be discoverable from the SKILL.md alone. If an agent can produce a structurally-broken output despite the verifier existing, the SKILL.md's body section is the place to harden the instructions.

### How NOT to do it

- **Do not** add the verifier as a side-effect of the persistence script. The agent should explicitly invoke it as a separate step so the verifier failure is unmissable in the user-facing output.
- **Do not** silently allow a verifier failure to be reported as "warning, continuing". The whole point is that structural-invariant violations block completion.
- **Do not** add the verifier rule only to CLAUDE.md or audit-mechanism.md. Per `docs/skill-design.md` rule 2, the rule belongs in the skill that fires.

## Open questions

- **WSJF scoring inside the auditor.** How does `/lean-audit` assign a WSJF score when it queues a requirement? First pass: derive from the skill's operation (WRITE > READ) and downstream consumer count (more consumers = higher score). Refine when the first three formalisations close.

- **Re-audit cadence.** Should `audited-no-benefit` skills be re-audited annually? Probably yes, because the underlying conditions can change (a skill that was READ-only becomes WRITE-capable). Implementation: a stale-after field; out of scope for the initial implementation.

- **Auditor consistency across model versions.** Different Claude versions may judge the five-condition test differently. Mitigation: the auditor emits the *reason* it chose a verdict, not just the verdict. A later version can re-audit and disagree with reasoned grounds.
