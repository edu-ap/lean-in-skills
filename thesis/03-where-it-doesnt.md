# 03. Where it doesn't help

Lean is not always the right tool. The places it earns its keep are narrow; the places it does not are broad. Acknowledging this is what separates pragmatic from cargo-cult.

## Reason 1: taste and perception are not decidable

"Use British English" is not a type. "Frame analogies in physics or formal methods because the user is a polymath" is not a type. "Detect high-stakes decisions and proactively suggest `/rigorous-thinking`" requires a perception step that no type system makes easier.

Formalising taste rules produces type-theatre: a sophisticated-looking encoding that does not constrain behaviour. The encoding is debatable, the debate is not productive, and the rule is no more enforceable than its prose original.

## Reason 2: LLMs read Lean as decorated prose

A Lean snippet embedded in CLAUDE.md is, in practice, parsed by the LLM as English with mathematical notation. The model does not run a type checker during text generation. Without a verifier in the loop, a Lean rule is a comment with extra syntax cost.

This is the most-cited fallacy in formal-methods-for-AI discussions. Lean's force comes from the type checker, not from the reader. If the type checker is not invoked, the formalisation is aesthetic.

## Reason 3: maintenance load is real

Every rule, edge case, and refinement requires re-elaborating the Lean. The team needs at least one person who knows Lean well enough to extend the schema. Onboarding new contributors (human or model) becomes harder.

In life-core today the only practising Lean-literate contributor is Eduardo. A formalisation that depends on him being present is single-pointed by construction. The formalisations chosen should either be small and stable enough to survive author absence, or come with documentation that lets a Lean-novice extend them with model assistance.

## Reason 4: the cost of the encoding can exceed the cost of the rule

A prose rule "the destination must be inside the privilege circle" is fifteen English words. A Lean encoding requires types for `Destination`, `PrivilegeCircle`, `Communication`, and a predicate. Real-world destinations have edge cases (DMs, ephemeral channels, channels with external single-message visitors) that the type encoding must cover.

The encoding is not free. For low-stakes rules the prose is cheaper, the maintenance is cheaper, and the failure modes are bounded.

## Reason 5: prose is more readable for the inverse audience

The most-frequent readers of CLAUDE.md are future Claude sessions. The model parses prose well. The second-most-frequent readers are humans who want to understand or extend the rules. Most humans parse prose well. Lean is a niche skill even among engineers.

A rule that is read often and verified rarely benefits from prose. A rule that is verified often and read rarely benefits from Lean. The selection criterion is the read-to-verify ratio, not the rule's intrinsic structure.

## The discipline

Before formalising a rule in Lean, answer all five:

1. Is the rule decidable?
2. Are the stakes worth the encoding effort?
3. Will a verifier actually run in the right place at the right time?
4. Can the formalisation survive without the original author?
5. Is the read-to-verify ratio low enough to justify the syntax tax?

If any answer is no, keep it in prose. The pilots in this project survive all five tests deliberately.

Continue to `04-pragmatic-architecture.md` for how to ship.
