# Document Lifecycle

Canonical reference for document statuses in this repository.
Cross-referenced by `AGENTS.md` (§5, §6) and `docs/claude/WORKFLOW.md`.

---

## Valid statuses per document type

| Type         | Valid statuses                                    |
|--------------|---------------------------------------------------|
| PRD          | Draft → Approved                                  |
| Architecture | Draft → Approved                                  |
| Plan         | Draft → Approved → Complete                       |
|              |                  → Superseded                    |
| Review       | Complete (reviews are always written as Complete) |

---

## Status transition diagram

```
PRD / Architecture
  Draft ──────────────► Approved

Plan
  Draft ──────────────► Approved ──────────────► Complete
    ▲                      │
    └──────────────────────┘ (blocking issue requires plan rewrite)
                           └───────────────────► Superseded

Review
  (written directly as Complete — no Draft state)
```

---

## Who updates each status and when

### PRD / Architecture

| Transition       | Who           | Trigger                                       |
|------------------|---------------|-----------------------------------------------|
| Draft → Approved | User/Reviewer | Review passes; user confirms ready to proceed |

### Plan

| Transition            | Who      | Trigger                                                         |
|-----------------------|----------|-----------------------------------------------------------------|
| Draft → Approved      | User     | Plan review passes; user confirms ready to build                |
| Approved → Complete   | Reviewer | Implementation review passes with no blocking issues            |
| Approved → Draft      | Planner  | Blocking issue requires the plan itself to be rewritten         |
| Approved → Superseded | Planner  | A replacement plan is created; reference it in the status line  |

### Review

| State    | Who      | Trigger                                        |
|----------|----------|------------------------------------------------|
| Complete | Reviewer | Always — reviews are written once, as Complete |

---

## Rules

1. Builder must not implement a Plan unless `**Status:** Approved` is present in the plan file.
2. Builder must not change the Plan status — Builder's output ends at "Next Steps".
3. Reviewer marks the Plan Complete only after implementation review passes with no blocking issues.
4. Reviewer must name the completed Plan in the review report Summary.
5. If implementation has blocking issues, the Plan remains Approved.
6. A Superseded plan must include `Superseded by: docs/plans/NNNN-title.md` in its status line.
7. No document whose work is accepted or completed may remain Draft.

---

## Status field examples

Plan — ready to build:

```
**Status:** Approved
```

Plan — implementation done and reviewed:

```
**Status:** Complete
```

Plan — replaced by a newer plan:

```
**Status:** Superseded by: docs/plans/0008-replace-zsh-foundation.md
```

Review report (always):

```
**Status:** Complete
```
