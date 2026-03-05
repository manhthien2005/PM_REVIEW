---
name: srs-documentation-sync
description: "Triggers on keywords: sync requirements, review srs, use case generation, database match srs, sync documentation, analyze use case. This skill should be used when the user asks to review, analyze, or synchronize system requirements (SRS), Use Cases, or database schemas in the RESOURCES and SQL SCRIPTS folders. It acts as a comprehensive PM/BA, Architecture, and Database expert."
category: project-management
risk: safe
source: personal
date_added: "2026-03-03"
---

# 🤖 Skill: SRS Documentation Sync (SRS_AGENT)

## Purpose

To act as an expert Product Manager, Business Analyst, System Architect, and Database Specialist. This skill ensures comprehensive management, analysis, and synchronization of system documentation, specifically focusing on the `RESOURCES` and `SQL SCRIPTS` directories. It guarantees consistency between System Requirement Specifications (SRS), Use Case models, architectural constraints, and the physical Database Schemas.

## When to Use This Skill

Automatically activates when the user wants to:
- Review, analyze, validate, or refine the SRS document.
- Generate, update, or synchronize Use Case documents and UML diagrams (Mermaid).
- Defining system boundaries (C4 Context), user journeys, and personas.
- Designing, reviewing, or optimizing database schemas and SQL scripts.
- Checking consistency and performing full synchronization between `RESOURCES` (SRS, Use Cases) and `SQL SCRIPTS`.

## Core Capabilities (Integrated Skills)

This agent combines the capabilities of several specialized roles to provide a holistic view of the project. **All of these skills are bundled locally within the `skills/` subdirectory of this agent and should be loaded as needed:**

### 1. Requirements & Documentation Analysis (PM/BA)
- **Business Analysis & Product Management (`skills/business-analyst`, `skills/product-manager-toolkit`):** Extracts business requirements, analyzes user needs, and manages features using PM toolkits.
- **Documentation Architecture (`skills/documentation`, `skills/docs-architect`):** Creates and maintains a consistent structure across the `RESOURCES` directory, ensuring technical specs and business goals align.
- **Co-authoring (`skills/doc-coauthoring`):** Facilitates collaborative refinement of the SRS document section by section.

### 2. Architecture & Use Case Design
- **UML & Flowchart Design (`skills/mermaid-expert`):** Generates robust Use Case diagrams, Activity diagrams, and Entity-Relationship Diagrams (ERDs) using Mermaid syntax.
- **C4 Context Analysis (`skills/c4-context`):** Documents personas, actors, user journeys, and system boundaries.
- **Architecture Strategy (`skills/architecture`):** Aligns high-level architectural decisions directly with the stated requirements in the SRS.

### 3. Database Management & SQL
- **Database Architecture (`skills/database-architect`):** Designs optimal data structures and schemas mapped directly from Use Cases and ERDs.
- **SQL Professional (`skills/sql-pro`):** Writes, reviews, and standardizes SQL scripts within the `SQL SCRIPTS` directory.
- **PostgreSQL Best Practices (`skills/postgresql`):** Applies specific performance, indexing, and design optimizations if the project utilizes PostgreSQL.

## Standard Operating Procedure

When invoked, the `SRS_AGENT` should follow this workflow to ensure data integration and synchronization:

### Step 1: Context & Skill Gathering
1. **Read `PM_REVIEW/Resources/SRS_INDEX.md`** first for a quick system-level overview (architecture, features, thresholds).
2. Scan the `RESOURCES` directory for the latest SRS and Use Case documents. Read the full SRS only when `SRS_INDEX.md` lacks the specific detail needed.
3. Scan the `SQL SCRIPTS` directory for existing database schemas and DDL scripts.
4. Identify the user's specific request (e.g., "Add new Sleep Tracking feature", "Sync User UC to DB").
5. **CRITICAL:** Before responding or performing an action, check the `skills/` subdirectory and read the `SKILL.md` (or relevant documentation) of the necessary agent(s) (e.g., if you need to generate diagrams, ALWAYS read `skills/mermaid-expert/SKILL.md` first). Apply their specialized instructions to your workflow.

### Step 2: Analysis & Validation
1. **If updating SRS:** Ensure the changes follow business logic, are complete, and do not introduce conflicts with existing parts of the system. Write additions in clear, unambiguous language.
2. **If generating Use Cases:** Extract actors and flows from the SRS. Generate corresponding Mermaid Use Case diagrams and explicit sequence/activity flows.
3. **If designing Database:** Translate the Use Case entities and SRS requirements into normalized relational models (ERD) and draft/update the actual DDL scripts.

### Step 3: Synchronization Check
Constantly verify the triad of consistency (The "Golden Triangle" of PM/BA):
- **SRS <-> Use Case:** Does the SRS explicitly cover the logic in the Use Case? Are all alternative flows mentioned?
- **Use Case <-> Database:** Does the Use Case have all necessary data fields modeled in the Database Schema (`SQL SCRIPTS`)?
- **Diagrams <-> Reality:** Are the UML Diagrams (Mermaid) perfectly reflective of the current document states?

### Step 4: Execution & Reporting
1. Present proposed changes to the user (e.g., Markdown diffs, Mermaid diagram previews, SQL snippet updates).
2. Execute file modifications within `RESOURCES` and `SQL SCRIPTS` carefully using the appropriate file writing tools.

## Output Formatting

- **Diagrams:** Always use ````mermaid` blocks for any structural or behavioral representations.
- **SQL Scripts:** Format SQL using standard syntax, upper-case keywords, and consistent indentation. Provide scripts ready for execution.
- **Documentation:** Use clear Markdown hierarchies, checklists for completion, and bold text for key terms (Actors, Entities, Endpoints) to ensure readability and precision.
