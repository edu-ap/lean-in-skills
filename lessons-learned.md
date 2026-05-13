# Lessons learned

What we discovered building lean-in-skills, captured here so future iterations (and future contributors) inherit the lessons without re-doing them.

## On the work

### The first-run-catches-real-bugs pattern

Every verifier shipped in the first session caught a real structural issue on its first run, including on the author's own most recent output. Specifically:

- `game-theory`'s schema rejected a real GameAnalysisJSON because calibration notes were in a top-level array rather than inline on each check.
- `prd-standardiser` rejected 205 of 206 PRDs on first run (most were vocabulary drift; see below).
- `rigorous-thinking` rejected 1 of 5 sampled arg JSONs on a real duplicate-id or missing-rationale violation.

**Implication for new pilots:** the highest-yield test for a newly-shipped verifier is the most recent canonical-looking input the skill has produced. If the verifier accepts everything, it's probably too lax; if it rejects everything, see the next lesson.

### En-masse rejection means the schema is probably too strict

The first `prd-standardiser` run rejected 99% of inputs. The initial framing was "we caught huge structural drift". On inspection most failures were vocabulary drift: the schema rejected `pending`, `completed`, `not-started` while the wild used those. Widening the schema with aliases lifted the pass rate from 1/206 to 56/206 in a five-line change.

**Lesson:** Before reporting "verifier caught N issues", inspect at least 3 failing samples. If most are normalisation gaps (vocabulary alias, type coercion, optional vs required), fix the schema. If most are real structural violations, then celebrate.

### Self-attestation must be explicit, not silent

Eduardo's framing was the load-bearing reframe of the session. The original `done` rule was "completed_on required" — which is quietly self-attestable (anyone can write any date with no proof). The fix:

> A `done` requirement must have *either* `completion_evidence` (URL, commit SHA, artefact path) OR an explicit `self_attested: true` flag.

The verifier doesn't refuse self-attestation; it refuses *invisible* self-attestation. Team reviewers grep for `self_attested: true` to find every completion that lacks evidence.

This is the right shape for any "completed state" schema field in team contexts. Cross-applies to verification status, approval status, sign-off status.

## On the approach

### "Verifier in the loop" is the load-bearing condition

The thesis lists five disqualifying conditions for formalisation:

1. Decidable
2. High-stakes
3. Verifier in the loop
4. Survives author absence
5. Read-to-verify ratio justifies the syntax tax

In practice, (3) does most of the work. If the verifier never actually runs against real artefacts at the right moment, the formalisation is decorative no matter how well the other conditions are satisfied. The other four are necessary but secondary.

**Implication for thesis/03-where-it-doesnt.md:** if rewriting, lead with the verifier check.

### Schema-in-skill, runtime-shared (Option B)

The architecture decision: the schema lives in the skill folder (`.claude/skills/.../lean/<Name>.lean` + `check.py`); the runtime (lakefile, toolchain, generic infrastructure) is shared at `projects/dev/lean-in-skills/`.

Rejected alternatives:

- **Option A: Everything in the runtime.** Schema in `projects/dev/lean-in-skills/LeanInSkills/<Name>.lean`. **Why rejected:** skills aren't portable. Sharing a skill folder doesn't carry the schema. The schema is part of the skill's contract.
- **Option C: Full self-contained bundle per skill.** Each skill has its own lakefile, toolchain, lean module. **Why rejected:** ~10 lines of boilerplate per skill, each Lake project warms the toolchain separately (~30s overhead per build).

**Implication:** use Option B for any new formally-enhanced skill. Three precedents already exist (game-theory, prd-standardiser, rigorous-thinking) — copy the layout.

### Audits do not fire on skill invocation

The audit-mechanism design rejects per-invocation audits explicitly. Reasons:

1. Latency tax (30s audit per call to a normally-fast skill).
2. Cognitive contamination (mixing meta-work with the user's actual task).
3. Audit-without-action (notes accumulate; nothing improves).

The right trigger surfaces are *write events* (skill modification, git commit) and *meta events* (`/lean-audit` invocation). Use events stay sacred.

## On Eduardo's environment

### PRD surface area is much larger than expected

206 tracked `prd.json` files across the workspace, including ~50 in submodules. Four distinct status vocabularies in use across them (modern: `todo/in-progress/done/blocked/partial`; legacy: `not-started/in-progress/completed/deferred/cancelled`; wild: `pending/planned/planning/delivered`). The `/prd-standardiser` skill exists precisely because this drift is real and accumulating.

99% of PRD `done` items had no traceable completion date pre-back-fill. The Lean overlay made this visible in one scan; the back-fill tool fixed 515 items by walking git history.

### The PRD cycle is genuinely load-bearing

The autonomous PRD cycle shapes how Claude works in this repo within minutes of starting a session. Mid-session in the 2026-05-13 work, requirements got queued via the PRD's WSJF and chained autonomously. The mechanism scales beyond Eduardo himself.

## On framing

### "Lean for AI guardrails" is the wrong headline

The honest framing is much narrower:

> Lean replaces prose for the slice that is decidable, high-stakes, has a verifier in the loop, survives author absence, and has a read-to-verify ratio that justifies the syntax tax.

That's ~10% of CLAUDE.md by volume and ~80% of operational risk by impact.

The right blog-post title (if/when we publish) is not *"Formal Methods for AI"* but *"Where Formal Methods Stop Being Type-Theatre"*. The narrower claim is the more credible one and matches what we actually shipped.

### Complementary to proof-generation, not competing

Aristotle, Lean Copilot, AlphaProof: AI generates Lean proofs.

Lean-in-skills: Lean constrains AI outputs.

Different rungs of the ladder. Both useful. Worth pointing this out in any public framing to avoid being read as a competitor to Aristotle.

## Open questions

These remain unresolved as of 2026-05-13. Track them as candidates for thesis updates or follow-up REQs.

- **Cycle detection for PRD dependencies.** The current PRDSchema doesn't reject `REQ-A depends_on REQ-B` and `REQ-B depends_on REQ-A`. Lean cycle detection without Mathlib is non-trivial; with Mathlib it's straightforward via well-founded recursion.
- **Re-audit cadence.** Should `audited-no-benefit` skills be re-audited annually? The underlying conditions (e.g. a skill becomes WRITE-capable) can change. Implementation: a stale-after field.
- **Auditor consistency across model versions.** Different Claude versions may judge the five-condition test differently. Current mitigation: the auditor records the *reason* for its verdict, not just the verdict, so future versions can re-audit with reasoned grounds.
- **Bundle script for external sharing.** A `bundle.py` that produces a tarball with skill + stripped-down runtime + INSTALL.md for sharing outside life-core (e.g. to claude-for-legal upstream). Queued as future work.

## What surprised us

- The first-run-catches-bugs pattern was sharper than expected. We didn't anticipate the verifier catching the author's own output three different times in one session.
- The vocabulary drift across PRDs was wider than expected. Four distinct enum vocabularies; ~50% of failures driven by vocabulary alone.
- Eduardo's self-attestation reframe was the most-impactful design move of the session. The original "completed_on required" rule was meaningfully weaker.

## What didn't surprise us

- Lean's `decide` tactic is plenty for these schema invariants. No tactic engineering needed.
- The submodule story is complicated. Tools have to be submodule-aware from the start.
- Skill-author Eduardo and audit-target Eduardo are the same person. Self-audit needs the same discipline as audit by others.
