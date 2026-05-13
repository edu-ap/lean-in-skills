-- Lean in Skills: entry module.
--
-- This module is the root of the lean-in-skills Lean library. It imports the
-- per-pilot modules and provides a top-level Status enum so build success
-- means "all currently-implemented pilots compile".

import LeanInSkills.SkillGraph
-- Per-skill schemas are vendored into LeanInSkills/<Name>.lean at verify time
-- by the skill's own check.py. They are gitignored and not imported here so
-- `lake build` of the top-level library succeeds without any skill having run
-- its verifier yet.

namespace LeanInSkills

inductive PilotStatus
  | scaffolded
  | implemented
  | verifierInLoop
  deriving Repr, DecidableEq

structure Pilot where
  name : String
  status : PilotStatus
  deriving Repr

def currentPilots : List Pilot :=
  [ { name := "skill-graph",              status := PilotStatus.scaffolded }
  , { name := "sub-processor-allowlist",  status := PilotStatus.scaffolded }
  , { name := "draft-lifecycle",          status := PilotStatus.scaffolded }
  ]

end LeanInSkills
