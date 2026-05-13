import Lake
open Lake DSL

package «lean-in-skills» where
  leanOptions := #[
    ⟨`autoImplicit, false⟩
  ]

@[default_target]
lean_lib «LeanInSkills» where
  roots := #[`LeanInSkills]
