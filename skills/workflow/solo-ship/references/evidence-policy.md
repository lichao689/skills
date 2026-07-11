# Evidence Policy

Read this reference whenever historical review, test, build, CI, QA, or runtime evidence may cover the shipping set.

Each evidence record contains:

- current `HEAD` or applicable tree hash;
- exact covered shipping paths;
- exact command and execution environment;
- exit code, failure count, and key result;
- whether any relevant path changed after the result.

Classify each record:

| Class | Predicate | Action |
| --- | --- | --- |
| `reuse` | Tree, paths, command target, and environment still apply; result passed | Cite it and prove no relevant drift. |
| `rerun-minimal` | Core evidence applies but packaging or a wrapper changed | Rerun only staged-boundary checks, `git diff --check`, or the affected guard. |
| `rerun-required` | Relevant source, environment, scope, or failure state changed | Rerun affected review and verification. |

Failed, blocked, stale, environment-mismatched, or scope-incomplete evidence is never reusable. A remaining related failure needs a baseline comparison showing it predates the shipping tree and the shipping tree adds no failures; otherwise diagnose it. Re-record evidence after every fix, conflict resolution, base advance, or packaging change that invalidates the prior tree or path set.

## Evidence Modes

The `evidence` parameter from the main skill binds as follows:

| Mode | Binding |
| --- | --- |
| `auto` | Apply the `reuse`, `rerun-minimal`, and `rerun-required` classifications above to every relevant gate. |
| `reuse` | Reuse only evidence proven eligible by the `reuse` predicate. Stale, failed, blocked, environment-mismatched, or out-of-scope evidence is rerun at the minimal or required depth indicated by its current classification. |
| `fresh` | Treat every relevant review and verification gate as `rerun-required`. Historical evidence may inform command selection, but cannot satisfy a completion criterion. |

An explicit evidence mode changes evidence treatment only; it never weakens the current-tree, path, environment, or passing-result requirements.
