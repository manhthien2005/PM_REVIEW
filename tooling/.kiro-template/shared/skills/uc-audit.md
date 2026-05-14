# Skill: UC Audit & Cross-Check

Batch-read and audit all 26 Use Cases, evaluate UC-SRS alignment, cross-check UC-SQL-JIRA gaps.

## When to Use

- Verify UC completeness
- Evaluate UC-SRS alignment (HG-FUNC)
- Cross-check UC vs SQL vs JIRA
- After SRS changes, new UCs, or DB schema updates

## Context Loading

1. Read `PM_REVIEW/MASTER_INDEX.md`
2. Read `PM_REVIEW/Resources/SRS_INDEX.md`
3. Read `PM_REVIEW/Resources/UC/00_DANH_SACH_USE_CASE.md`
4. Read `PM_REVIEW/Resources/TASK/JIRA/README.md`
5. Read `PM_REVIEW/SQL SCRIPTS/README.md`

## Phase 1: UC Inventory

Read UCs module by module (8 modules, 26 files). For each UC extract: ID, Name, Module, Actors, Platform, Main Flow Steps, Alt Flow Count, Business Rules, Data Fields, DB Tables.

## Phase 2: SRS Relevance

Score each UC: CORE (directly implements HG-FUNC) | SUPPORTING (enables core) | MANAGEMENT (admin) | LOW (weak connection).

Flag: HG-FUNC without covering UC = UNCOVERED_REQUIREMENT. UC without HG-FUNC = ORPHAN_UC.

## Phase 3: Cross-Check Matrix

- UC vs JIRA: UC_NO_TASK, TASK_NO_UC
- UC vs SQL: MISSING_COLUMN, ORPHAN_COLUMN, TYPE_MISMATCH
- Internal consistency: UC list vs actual files vs MASTER_INDEX

## Output

File: `PM_REVIEW/UC_AUDIT_report.md` (Vietnamese section headers, overwrite if exists).
