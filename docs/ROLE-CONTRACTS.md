# Role Contracts (Grok-native)

Roles are expressed with **official Grok three layers**:

| Layer | Path | Holds |
|---|---|---|
| Agent type | `.grok/agents/<name>.md` | Spawnable type, description, base prompt, frontmatter |
| Role | `.grok/roles/<name>.toml` | `default_capability_mode`, isolation defaults |
| Persona | `.grok/personas/<name>.toml` | Behavioral instructions (injected as persona layer) |

Spawn with:

```text
spawn_subagent(subagent_type: "<name>", prompt: "<task brief>", capability_mode: "...")
```

Grok may resolve matching role/persona during subagent setup. Depth is always 1.

## Task brief

```text
Goal:
Scope:
Out of Scope:
Existing Pattern:
Verification:
Escalation:
```

## Result envelope

```text
Status:
Changed:
Verified:
Not verified:
Needs review by:
Evidence:
```

## Boundaries

| Role | Owns | Does not own |
|---|---|---|
| implementer | Scoped implementation | Review approval, deploy |
| code-reviewer | Evidence-backed review | Business code fixes |
| tester | Independent tests + runner output | Business code under test |
| deployer | Authorized release actions | Implicit deploy authority |
| feedback-observer | `.grok/feedback/` records | progress.md / rule graduation |
| evolution-runner | Proposals only | Unapproved rule edits |
| progress-recorder | progress.md merge | Spec ownership / feedback |

Skill allowlists in personas are routing discipline, not sandbox grants.
