# Git Topology and Cleanup

Read before integration, worktree removal, or branch cleanup.

## Local-first topology

Identify the integration branch, remote, frozen remote base, task commits, worktree owner, and any repository rule that requires PR review. Remote and Git topology are facts; branch names and a GitHub remote alone do not establish a PR requirement.

The default route builds and validates a merge commit in an owned local integration worktree, then pushes that commit directly to the remote integration branch. Push a feature branch first only on the evidenced PR route.

Immediately before integration, fetch and compare the frozen base with the current remote base. Rebuild the candidate when the base advanced. After push or PR merge, fetch again and prove task and integration commits are ancestors of the remote integration branch.

## Cleanup gates

Delete a local branch or worktree only when all gates pass:

1. ownership is established by the creating tool or current request;
2. its worktree has no staged, unstaged, untracked, or unresolved state;
3. its target commit is reachable from the verified remote integration branch.

Check every candidate immediately before deletion. Preserve failed or ambiguous candidates and every pre-existing stash. Retain remote feature branches unless the repository has an explicit cleanup policy or the user authorizes deletion.
