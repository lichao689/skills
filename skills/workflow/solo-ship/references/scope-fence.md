# Scope Fence

Read this reference when the worktree is dirty, changes are concurrent, ownership is unclear, or packaging needs isolation.

## Session Fence

Derive ownership from the current conversation, user-named paths, task commits, and fixes created by Solo Ship for those paths. If context cannot prove ownership, restrict scope to paths explicitly named by the user. Git dirtiness alone never establishes session ownership.

## Entry Fence

At invocation record staged, unstaged, deleted, renamed, untracked, stash, branch, upstream, and worktree state. A later change not produced by Solo Ship is external concurrent work and remains excluded.

## Shipping Set

The shipping set is the provable intersection of Session Fence and Entry Fence, plus necessary fixes for its review, tests, factual documentation, conflicts, or deployment. Classify every observed path exactly once:

1. shipping set;
2. pre-existing out-of-session change;
3. post-entry external change;
4. generated or ignored artifact;
5. ambiguous blocker path.

Use exact-path staging. Never substitute the whole dirty worktree for ownership evidence and never automatically stash external work.

## Scope Modes

Parameters from the main skill bind to shipping scope as follows:

| Mode | Selection | Shipping set |
| --- | --- | --- |
| `session` | The user says "this chat", "this session", "what you changed", or equivalent. | Session-owned paths present in the Entry Fence, plus required Solo Ship fixes for their review, tests, factual documentation, conflicts, or deployment. Later external changes stay excluded. |
| `entry` | Only when the user explicitly says to ship all current/local changes or the current working tree. | The classified Entry Fence, while generated/ignored artifacts and ambiguous blocker paths remain preserved and excluded. |
| `explicit` | The user supplies a path allowlist, or provenance is uncertain. | Named allowlist paths plus required fallout fixes; every other path remains excluded. |
| `auto` | Select `session` for "this chat"/"what you changed", `entry` only for explicit all-current/local-working-tree wording, and `explicit` when provenance is uncertain. | The shipping set of the selected mode. |

No scope mode absorbs edits that appear after the Entry Fence unless Solo Ship itself creates them as required fixes for the already-owned shipping set.

## Isolation Priority

When the current worktree cannot safely package the shipping set, prefer a Solo-Ship-owned integration worktree created from the pinned clean base. Before creating or using any linked or owned integration worktree, read `git-topology-and-cleanup.md`. Reconstruct only proven owned commits or patches there, then review and verify the isolated tree. Preserve overlapping user edits in their original worktree. If owned hunks cannot be isolated without guessing or overwriting external content, record the path as an objective blocker.
