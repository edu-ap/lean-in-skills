# 01. Why not prose?

English prose is the universal substrate for CLAUDE.md guardrails, skill instructions, and the design notes that govern AI behaviour. It is also, in this role, the source of three predictable failures.

## Failure 1: silent incompleteness

A prose rule like "before posting to a public channel, check the destination is in the privilege circle" has implicit completeness. The reader assumes the rule covers every case. The rule does not. The next time a new posting surface appears (a new channel type, a new connector, a new automation), the rule says nothing about it. Compliance becomes interpretation.

A typed predicate `isPrivileged : Destination → Bool` cannot be silently incomplete: every case in `Destination` must be handled, and the compiler enforces exhaustiveness. New posting surfaces appear as new constructors and force the rule to be updated.

## Failure 2: load-bearing parentheticals

Prose carries footnotes, "and also think about" clauses, and edge cases in subordinate sentences. The next editor edits the body and the subordinate clause silently drops. A rule that was "default-on with a narrow exemption when X" becomes "default-on" after one round of editing, or "default-off with the rule as a footnote" after two.

Lean does not have subordinate clauses with semantic weight. The constraint either lives in the type or it does not exist.

## Failure 3: the perception of decidability

Many prose rules read as decidable: "high-stakes decisions get `/rigorous-thinking`". On inspection the rule is not decidable at all. "High-stakes" is a classifier. The rule cannot fire without a perception step that prose cannot codify. Formalising "high-stakes" in Lean does not solve the perception problem, but it does make the perception problem visible. The Lean version forces the rule to be split into a decidable consequent and an explicitly-acknowledged classifier.

## What prose still does better

Prose handles taste, perception, and conditional emphasis better than any type system. "Use British English", "be terse", "the user is a polymath, frame analogies in physics or formal methods" are not type-checkable rules and never will be. The point of this project is to formalise the slice where prose's three failures bite, not to replace prose.

## The asymmetric move

The asymmetric move is to keep prose for taste and perception, and to formalise the predicates that are decidable, high-stakes, and where a verifier can actually run. This is roughly 10% of CLAUDE.md by volume and roughly 80% of the operational risk by impact.

Continue to `02-where-it-helps.md` for the concrete slice.
