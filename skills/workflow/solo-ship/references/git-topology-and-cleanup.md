# Git Topology and Cleanup

Read this reference during orientation when topology is ambiguous, and always before merge, worktree removal, or branch cleanup.

## Topology

Identify the current branch, upstream, remotes, default/base branch, worktree ownership, existing PR, required checks, protection rules, and whether integration is PR-based or local. Use repository configuration and remote facts rather than branch-name guesses.

Immediately before merge, fetch and compare the pinned base with the current remote base. If it advanced, recompute commits and diff, resolve conflicts, and invalidate evidence affected by the new tree. After merge, fetch again and prove the target commit is reachable from the remote integration branch and that local/remote merge results agree.

## Cleanup Gates

Delete a local branch or worktree only when all three gates pass:

1. **ownership:** Solo Ship created it or the current request explicitly assigns it;
2. **cleanliness:** its worktree has no staged, unstaged, untracked, or unresolved state;
3. **merged:** its target commit is reachable from the verified integration branch.

Check every candidate individually immediately before deletion. A failed gate means preserve and report it. Never delete or move external changes, ambiguous resources, or existing stashes. Remote branches are retained by default; delete one only with explicit user authorization or a proven repository automation policy.
