---
name: code-simplifier
description: Use when the user wants a behavior-preserving simplification or cleanup of recently changed code, especially requests like simplify this code, clean this up, remove AI slop, reduce defensive noise, align with project conventions, or refactor without changing behavior. Best for tightening modified files, removing redundant comments/checks/abstractions, and applying repository guidance from AGENTS.md, CLAUDE.md, or similar instruction files.
---

# Code Simplifier

## Overview

Simplify recently changed code while preserving exact external behavior. Favor explicit, readable, project-consistent code over clever or overly compact rewrites.

## Scope

Default to code touched in the current session or the current diff. Expand only when the user explicitly asks for a broader pass.

Treat these as in scope:

- files changed in the current conversation
- staged or unstaged diff for the requested work
- small fallout fixes needed to keep the simplification coherent

Do not widen the pass to unrelated legacy code unless the user asks.

## Project Rules

Read the nearest high-authority guidance before editing:

1. `AGENTS.md`
2. a nearer path-local `AGENTS.md` under the target subtree
3. `CLAUDE.md` or `claude.md` if present
4. any explicit style guide or instructions named by the user

Apply those conventions literally when they affect naming, function style, imports, types, error handling, component patterns, or file organization.

## Simplification Rules

Preserve exact functionality and public API.

- do not change outputs, side effects, data contracts, exported names, routes, env keys, persistence shape, or user-visible behavior unless the user asks
- keep logic equivalent; if equivalence is uncertain, stop and narrow the change
- preserve error semantics; do not add or remove `try/catch`, retries, or fallback behavior casually

Prefer clarity over brevity.

- reduce unnecessary nesting
- inline pointless indirection
- remove redundant temporary variables when readability improves
- consolidate duplicated logic when behavior clearly stays the same
- keep helpful abstractions; do not collapse distinct concerns into one function
- avoid dense one-liners and clever tricks
- avoid nested ternaries; use `if/else` or `switch` for multi-branch logic

Remove noise, not signal.

- remove comments that only narrate obvious code
- keep comments that explain intent, invariants, edge cases, or non-obvious tradeoffs
- remove defensive checks only when surrounding guarantees already make them redundant
- simplify casts or assertions only when they are clearly unnecessary

## Workflow

1. Identify the target scope from the current session or diff.
2. Read applicable `AGENTS.md`, `CLAUDE.md`, and nearby code patterns.
3. Simplify the smallest useful unit first.
4. Re-check for behavior, API, and naming regressions.
5. Run the smallest relevant verification available when the change is non-trivial.
6. Report the simplifications made and any intentionally skipped opportunities.

## Good Targets

- redundant guards after prior validation
- obvious comments that restate code
- duplicate branches producing the same result
- helpers used once that hide simple logic
- noisy casts that restate known types
- conditionals that become clearer as early returns

## Avoid

- cross-module rewrites without a request
- formatting-only churn mixed into logic edits
- refactors that require product judgment
- replacing readable code with clever compact code
- deleting useful abstractions, docs, or tests just to shrink line count
