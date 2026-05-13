# Pilot 3: Draft lifecycle state machine

## Goal

Make the Slack/email/SharePoint draft protocol a mechanical control rather than a reader-vigilance rule. A pre-tool-call hook consults a Lean state machine before any send and rejects illegal transitions.

## What it formalises

```
              ┌──────────┐  user-edit   ┌──────────┐
   start ──▶ │  Draft   │ ───────────▶  │  Draft   │
              └──────────┘                └──────────┘
                  │                          │
                  │ user-says:               │ user-says:
                  │ "post it"                │ "review please"
                  ▼                          ▼
              ┌──────────┐              ┌──────────┐
              │ Approved │              │ Reviewed │
              └──────────┘              └──────────┘
                  │                          │
                  │ tool:send                │ user-says:
                  ▼                          │ "post it"
              ┌──────────┐                   ▼
              │  Posted  │               ┌──────────┐
              └──────────┘               │ Approved │
                                         └──────────┘
                                              │
                                              │ tool:send
                                              ▼
                                          ┌──────────┐
                                          │  Posted  │
                                          └──────────┘
```

Legal transitions only. The illegal transition `Draft -> Posted` is unrepresentable.

## Architecture

```
.claude/settings.json hook (PreToolUse for slack-write, email-send, etc.)
       │
       │  scripts/lean-in-skills/draft-lifecycle-check.py
       │  reads: harness state (last user message, tool args)
       │  consults: precompiled decision table from DraftLifecycle.lean
       ▼
allow / deny
```

The Lean side declares legal transitions; a precompiled JSON decision table is emitted at build time (because spinning Lean from a Python hook is too slow). The decision table is small (a few dozen rows).

## Implementation tasks

1. Define the inductive type `DraftState` and the transition relation `canTransition : DraftState -> Event -> DraftState -> Prop` in `LeanInSkills/DraftLifecycle.lean`.
2. Prove that the transition relation is functional (deterministic).
3. Emit a JSON decision table from Lean at `lake build` time (via `#eval` plus a small writer, or via Lean-extracted code).
4. Write the pre-tool-call hook script that loads the decision table and consults it.
5. Wire into `.claude/settings.json` `hooks.preToolUse` for slack-write, slack-bookmarks-pending, email-draft, email-thread-read, gmail-manage, outlook-manage.
6. Test: an unapproved draft sent to slack-write triggers a deny with the failing transition named.

## Estimated effort

3 dev-days. The harder half is the harness integration, not the Lean side.

## Risks

- Harness state observability. The hook needs to know whether the user said "post it" recently. Resolution: parse the last N user messages; flag if observability is insufficient.
- Latency of pre-tool-call hooks. Must be sub-100ms. Resolution: precompiled decision table makes the hook a table lookup.
- False denies on legitimate sends (e.g. automated daily-synthesis). Resolution: a per-tool exception list for tools whose own contract guarantees approval is unnecessary.

## Done definition

- `lake build` produces a `draft-lifecycle.json` decision table.
- The pre-tool-call hook in `.claude/settings.json` consults it.
- A demo scenario: Claude attempts to post an unapproved draft to Slack; the hook denies; the deny message names the failing transition.
- Documented in root CLAUDE.md's Slack/Email Posting Protocol section as the mechanical enforcement of the prose rule.
