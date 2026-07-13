# Scope Fence

Read when the worktree is dirty, changes are concurrent, ownership is unclear, or packaging needs isolation.

## Bind ownership

Derive ownership from the current conversation, user-named paths, task commits, and fixes required for those paths. Git dirtiness alone is not ownership. Classify every observed path as task-owned, pre-existing external, post-entry external, generated/ignored, or ambiguous.

Record an entry fence containing branch, upstream, `HEAD`, status, task-owned and excluded paths, and hashes sufficient to detect later drift. Prefer the repository-native scope snapshot when it can preserve recoverable content.

For mixed files or overlapping concurrent edits, store task-owned binary patches and untracked files in a current-user-only host temporary directory outside every repository and worktree. Record hashes and paths, reconstruct only that owned content in an integration worktree, and delete the snapshot after verified integration or report it in a blocker checkpoint.

## Package

The integration set is the intersection of proven task ownership and the entry fence, plus fixes required by its review, validation, conflict resolution, or factual documentation. Later external changes remain excluded.

Use exact-path staging. Preserve unrelated edits and stashes in place. Prefer an owned integration worktree when the current worktree cannot package the set safely. If task-owned hunks cannot be isolated without guessing or overwriting external content, stop with that path as the blocker.
