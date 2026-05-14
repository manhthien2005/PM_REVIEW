# Skill: Detailed Feature Review (8-Criteria, 100 Points)

Deep evaluation of a specific feature against 8 standardized criteria. Target: every feature >= 76/100 before release.

## When to Use

- "review code", "danh gia chi tiet", "evaluate feature", "score this module"
- NOT for: PR reviews (use code-review-five-axis), debugging, writing new code

## 8 Criteria (100 points)

| # | Criterion | Max |
|---|---|---|
| 1 | Feature correctness (UC compliance) | 15 |
| 2 | API Design (RESTful, error response) | 10 |
| 3 | Architecture & Patterns (Clean Arch) | 15 |
| 4 | Validation & Error Handling | 12 |
| 5 | Security (Auth, input, rate limit) | 12 |
| 6 | Code Quality (SOLID, clean code) | 12 |
| 7 | Testing (coverage, quality) | 12 |
| 8 | Documentation (code docs, API docs) | 12 |

## Process

1. Detect project (ADMIN/MOBILE)
2. Load context: MASTER_INDEX -> summary -> source code
3. Check previous review (re-review protocol)
4. Score 8 criteria with file:line evidence
5. Cross-reference JIRA Stories
6. SRS/UC verification (main flow + alt flows)
7. Generate Vietnamese report
8. Save + update MASTER_INDEX

## Output

File: `PM_REVIEW/REVIEW_{ADMIN|MOBILE}/{FEATURE}_{MODULE}_review.md`
Score classification: 76-100 = Pass | 51-75 = Needs Fix | 0-50 = Fail
