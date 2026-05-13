-- Pilot 1: SKILL.md compositional graph schema.
--
-- The .claude/skills/ directory contains SKILL.md files with YAML frontmatter
-- declaring a `composes:` list of upstream skills. Today these references are
-- strings; nothing checks that the referenced skills exist or have compatible
-- output types.
--
-- This module formalises the skill graph and gives us a compile-time check
-- that the graph is well-formed: every composes: edge points to an existing
-- node, and the producer's output type matches one of the consumer's input
-- types.
--
-- Status: scaffold. The actual ingestion from .claude/skills/ happens in a
-- Python script that emits Lean source matching the SkillRegistry shape
-- below. See pilots/skill-graph/README.md for the verifier-in-the-loop plan.

namespace LeanInSkills.SkillGraph

inductive Level
  | atomic
  | composite
  | workflow
  deriving Repr, DecidableEq

inductive Operation
  | read
  | write
  | readWrite
  deriving Repr, DecidableEq

inductive IOType
  | text
  | json
  | emailRef
  | calendarEvents
  | slackMessage
  | speechDraft
  | other (tag : String)
  deriving Repr, DecidableEq

structure Skill where
  name      : String
  level     : Level
  operation : Operation
  inputs    : List IOType
  outputs   : List IOType
  composes  : List String
  deriving Repr

abbrev SkillRegistry := List Skill

-- A skill name is known when it appears as the name of some skill in the
-- registry.
def Known (reg : SkillRegistry) (n : String) : Prop :=
  ∃ s ∈ reg, s.name = n

-- All composes edges must point to known skills.
def AllReferencesKnown (reg : SkillRegistry) : Prop :=
  ∀ s ∈ reg, ∀ c ∈ s.composes, Known reg c

-- Placeholder: type-compatibility predicate. When skill A composes skill B,
-- some output of B should match some input of A. Refined in the implementation
-- pass when ingestion has produced real type metadata.
def TypeCompatible (_a _b : Skill) : Prop := True

end LeanInSkills.SkillGraph
