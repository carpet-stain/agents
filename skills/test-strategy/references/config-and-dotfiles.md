# Variant — configuration and dotfiles

Repos that are predominantly configuration consumed by other tools. A
verification harness may not exist, so red takes its degraded
written-prediction form: record in `PLAN.md`, **before** the change, the
observable you expect to differ (a command's output, a tool's read-back, a
rendered value) and why it currently reads otherwise — that written mismatch is
red. After the change, run the observation; it matching the prediction is
green. A change verified only by re-reading the config file proves nothing.

## Layer table

| Layer              | Check artifact                                 | What it proves                     |
| ------------------ | ---------------------------------------------- | ---------------------------------- |
| static             | the format's lint/schema checks                | the file parses, schema satisfied  |
| tool check mode    | the tool's own validate/check/dry-run          | the consuming tool accepts it      |
| runtime read-back  | read the merged/effective value from the tool  | the setting actually took effect   |
| human verification | prediction recorded, named in the final report | what only a human can judge        |
| none               | see "When a test is not required" in the rules | rationale names the catching layer |

## Mapping notes

- Prefer read-back over inspection: the effective value from the running tool
  (not the file) is the behavior. Where the repo already has a read-back
  harness or verification skill, that is the idiom to imitate.
- Layered configs (defaults → overrides → local) fail at merge time; the
  read-back must exercise the same layering the real invocation uses.
- "Config" that carries logic (conditionals, templating, shell in hooks) is
  code — reclassify those behaviors into the app-service or scripts table.
- Human-verifiable-only items (visuals, keybindings, feel) don't block done;
  done includes naming them as unverified, per the definition-of-done's
  CI-only clause.
