# Scope Fence

Read this reference when the worktree is dirty, changes are concurrent, ownership is unclear, or packaging needs isolation.

## Session Fence

Derive ownership from the current conversation, user-named paths, task commits, and fixes created by Solo Ship for those paths. If context cannot prove ownership, restrict scope to paths explicitly named by the user. Git dirtiness alone never establishes session ownership.

## Entry Fence

The Entry Fence is content-recoverable, not a path list. Before changing anything, create a Solo-Ship-owned snapshot resource in the secure host temporary directory, outside every repository and normal or integration worktree. Restrict it to the current user: POSIX directory mode `0700` and file mode `0600`, or the host's equivalent current-user-only ACL. Never place a snapshot beneath a worktree tree. Then record:

- branch, upstream, `HEAD`, worktree list, stash list, staged/unstaged/deleted/renamed status;
- tracked staged content as `git diff --cached --binary --full-index`, and tracked unstaged content as `git diff --binary --full-index`;
- every session-owned untracked file copied with its relative path into the owned snapshot (binary files included);
- a manifest containing each path, ownership class, source state, absolute snapshot path, byte size, and a cryptographic content hash; also record the snapshot directory's absolute path and hash both patch files.

Restrict patches and copied files to provably owned paths when the Session Fence is narrower than the dirty tree. Verify permissions or ACLs plus the patch and manifest hashes before packaging. Retain the resource only until merge and post-deploy verification complete, then securely delete it and report the deleted absolute path.

A later change not produced by Solo Ship is external concurrent work and remains excluded. Detect post-entry overlap by comparing current content with the stored hashes and patches. Reconstruct the shipping version from the pinned `HEAD`, binary patches, and copied untracked snapshot in the owned integration worktree; never try to recover entry content from a later path-only status listing.

If an objective blocker requires resumption, preserve the snapshot only while it is necessary for recovery. The checkpoint must report its absolute path, likely sensitivity, current-user-only protection, and exact cleanup instruction. On resume, delete the snapshot as soon as recovery and post-deploy verification complete.

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

When the current worktree cannot safely package the shipping set, prefer a Solo-Ship-owned integration worktree created from the pinned clean base. Before creating or using any linked or owned integration worktree, read `git-topology-and-cleanup.md`. Reconstruct only proven owned commits, verified binary patches, and copied owned-untracked snapshots there, then compare the reconstructed tree with the hash manifest before review and verification. Preserve overlapping user edits in their original worktree. If owned hunks cannot be isolated without guessing or overwriting external content, record the path as an objective blocker.
