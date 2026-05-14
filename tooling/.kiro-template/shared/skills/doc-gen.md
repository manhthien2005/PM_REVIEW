# Skill: Doc Gen — SRS & SDD Generation

Generate standards-compliant SRS and IEEE-1016-2009 SDD documentation using multi-agent brainstorming.

## When to Use

- "write SRS", "write SDD", "generate design document"

## Process

1. Determine: create new or refine existing document
2. Ask: specific module or entire system
3. Knowledge extraction: read existing doc, MASTER_INDEX, JIRA, UCs, source code
4. Multi-agent brainstorming:
   - Primary Designer: draft outline
   - Skeptic/Challenger: verify for gaps
   - Constraint Guardian: review NFRs + architecture
5. Generate/refine document in markdown (mermaid for diagrams)

## Output

- File: `{MODULE_NAME}_SRS.md` or `{MODULE_NAME}_SDD.md`
- Language: Vietnamese (stakeholder-facing)
- Use mermaid syntax for diagrams
- Explain WHY behind architectural patterns
