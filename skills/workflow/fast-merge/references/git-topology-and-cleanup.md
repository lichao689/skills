# Git Topology and Cleanup

Read only when cleanup is requested or is the normal repository-owned finalization step.

## Local-first topology

Identify local `main`, task commits, worktree owner, requested endpoints, and any repository rule that requires remote synchronization or PR review. Remote and Git topology are facts; branch names and a GitHub remote alone do not establish a push or PR requirement.

The default route freezes local `main`, builds and validates a merge commit in an owned local integration worktree, then fast-forwards local `main` only if its checkout remains clean and the base has not drifted. It does not fetch or push. Preserve the candidate for recovery if the final local update is unsafe.

Only an explicit remote route fetches and freezes the remote base. After push or PR merge, fetch again and prove task and integration commits are ancestors of the remote integration branch. Push a feature branch first only on the evidenced PR route.

## Cleanup gates

Delete a local branch or worktree only when all gates pass:

1. ownership is established by the creating tool or current request;
2. its worktree has no staged, unstaged, untracked, or unresolved state;
3. its target commit is reachable from the endpoint preserving the work: local `main` for local-only completion, or the verified remote integration branch for remote completion.

Check every candidate immediately before deletion. Preserve failed or ambiguous candidates and every pre-existing stash. Retain remote feature branches unless the repository has an explicit cleanup policy or the user authorizes deletion.
