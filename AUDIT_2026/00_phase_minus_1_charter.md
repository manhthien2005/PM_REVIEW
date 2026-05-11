# Phase -1 Charter — PM_REVIEW Tier 1 Baseline Rebuild

> **Goal:** Rebuild trust-critical canonical docs (DB schema, API contract, topology) từ actual code, làm baseline cho macro audit Phase 1+.

**Created:** 2026-05-11
**Branch:** `chore/audit-2026-foundation` (PM_REVIEW only)
**Driver:** ThienPDM
**Executor:** Cascade (Cascade-anh-pair)
**Linked bug:** [PM-001](../BUGS/PM-001-pm-review-spec-drift.md) (systemic drift)
**Approach approved:** Option B — Selective rebuild

---

## Why Phase -1 exists

Khi audit code mà reference doc đã stale, output sẽ là **false positive flood**: code đúng nhưng spec sai → flag "code wrong"; code có feature mới mà spec không có → flag "spec missing UC". Cả hai đều mislead audit conclusions.

Phase -1 rebuild **3 trust-critical artifacts** trước Phase 1, để mọi audit từ đó dùng baseline tin cậy.

**KHÔNG rebuild trong Phase -1:**
- UC files (Tier 2 — rebuild lazy qua Phase 3+4)
- SRS chương 1-7 (Tier 2)
- JIRA backlog historical (Tier 2)

Lý do: cost cao, ROI thấp ở giai đoạn này. Sau Phase 4 sẽ tự update incremental.

## Scope Phase -1

### Phase -1.A — DB Canonical Diff

**Question Phase -1.A trả lời:**
> "Schema thực tế DB hiện đang chạy có match canonical SQL không? Prisma + SQLAlchemy + canonical SQL nào là source of truth?"

**Method:**
1. **Parse canonical** — `PM_REVIEW/SQL SCRIPTS/init_full_setup.sql` → table list + column list per table
2. **Parse Prisma** — `HealthGuard/backend/prisma/schema.prisma` → model definitions
3. **Parse SQLAlchemy** — scan `health_system/backend/app/` for ORM model classes hoặc raw SQL
4. **Build comparison matrix:**

   | Table | Canonical | Prisma | SQLAlchemy | Status |
   |---|---|---|---|---|
   | users | ✓ (cols: id, email, ...) | ✓ (model `User`) | ✓ (model `User`) | aligned |
   | password_reset_tokens | ✓ | ? (verify) | ? | drift-candidate |
   | new_table_x | ✗ | ✓ | ✓ | canonical-missing |

5. **Severity flag per drift:**
   - **High** — breaks join/FK (eg. table renamed in Prisma but canonical còn tên cũ)
   - **Medium** — column type mismatch (varchar vs text)
   - **Low** — naming convention diff (camelCase vs snake_case)

**Acceptance criteria:**
- Matrix complete cho mọi table trong canonical SQL + Prisma + SQLAlchemy (union)
- Mỗi drift entry có severity + migration suggestion
- File output ≥ 80% column-level coverage (em không deep-dive constraint/index level ở Phase -1)

**Output file:** `AUDIT_2026/tier1/db_canonical_diff.md`

**Effort:** 3-4 giờ

---

### Phase -1.B — API Contract v1

**Question Phase -1.B trả lời:**
> "Endpoint nào đang được serve, ai consume, schema match không?"

**Scope — 5 services (4 server + 1 consumer mobile):**

| Service | Code path | Tech |
|---|---|---|
| HealthGuard backend | `HealthGuard/backend/src/routes/`, `controllers/` | Express + Prisma |
| health_system backend | `health_system/backend/app/api/` routers | FastAPI + SQLAlchemy |
| healthguard-model-api | `healthguard-model-api/app/routers/` | FastAPI ML serving |
| Iot_Simulator_clean api_server | `Iot_Simulator_clean/api_server/routers/` | FastAPI sim |
| Mobile (consumer) | `health_system/lib/core/network/`, `features/*/data/` | Flutter dio |

**Method:**
1. **Auto-extract endpoints** — em scan code, list:
   - Path + HTTP method
   - Auth requirement (middleware/decorator)
   - Request schema (Pydantic / Zod / Joi / raw)
   - Response shape (annotated return type or sample)
2. **Build endpoint catalog** per service
3. **Cross-check producer ↔ consumer:**
   - Mobile dio call URL → match server endpoint?
   - Schema mobile sends → match server expects?
   - Schema server returns → match mobile parses?
4. **Flag mismatches:**
   - Path mismatch
   - Missing auth header at consumer
   - Schema field rename
   - Dead endpoints (server has, no consumer)
   - Orphan calls (consumer calls, no server endpoint)

**Acceptance criteria:**
- Catalog complete cho 4 server services (mọi route registered)
- Mobile consumer side: cover ≥ 90% feature module data layer
- Mismatch list với severity

**Output file:** `AUDIT_2026/tier1/api_contract_v1.md`

**Effort:** 4-6 giờ

---

### Phase -1.C — Topology v2

**Question Phase -1.C trả lời:**
> "Service nào gọi service nào, qua giao thức gì, payload gì? DB nào read/write bởi service nào?"

**Method:**
1. **Read existing topology.md** (PM_REVIEW root + `.windsurf/topology.md`) — baseline
2. **Verify HTTP outbound calls:**
   - Search `requests.post`, `requests.get`, `httpx.AsyncClient`, `axios`, `fetch`, `dio.post` etc.
   - Map source → destination URL → target service
3. **Verify Socket.IO usage:**
   - HealthGuard backend emit/on
   - Mobile socket consumer
4. **Verify DB access per service:**
   - Prisma client usage in HealthGuard
   - SQLAlchemy session in health_system backend, healthguard-model-api, IoT
   - Identify which tables each service reads/writes
5. **Build call graph:**
   ```
   Mobile (Flutter)
     ├── HTTP → HealthGuard BE (admin only? or also user data?)
     ├── HTTP → health_system BE (vitals, auth, alerts)
     ├── Socket → ? (verify)
     └── FCM ← (push only)

   health_system BE
     ├── HTTP → healthguard-model-api (ML predict)
     ├── HTTP → Iot_Simulator_clean (?)
     └── DB → Postgres (timeseries + alerts)
   ...
   ```
6. **Diff vs old topology** — flag changed/new/removed integrations.

**Acceptance criteria:**
- Call graph complete cho mọi cross-service interaction
- DB access map per service
- Diff list vs old topology.md
- Identify broken/orphan integrations

**Output file:** `AUDIT_2026/tier1/topology_v2.md`

**Effort:** 2-3 giờ

---

## Execution order + dependency

```
-1.A (DB diff) ─┐
                ├──→ -1.B (API contract) ──→ -1.C (Topology)
                │      (uses -1.A schema)     (uses both)
                └─────────────────────────────────┘
```

Em làm sequential vì cần consistent context. Phase -1 không parallel.

## Out of scope (Phase -1)

- ❌ UC drift quantification — Phase 1.E
- ❌ SRS chương rebuild — Phase 4 polish
- ❌ JIRA backlog re-baseline — Phase 4
- ❌ Test coverage measurement — Phase 1
- ❌ Code complexity metrics — Phase 1
- ❌ Refactor recommendation — Phase 3+4

Strict scope. Anti-pattern: gold-plating Phase -1 thành "rebuild everything".

## Output structure

```
PM_REVIEW/AUDIT_2026/
├── 00_phase_minus_1_charter.md         ← THIS FILE
├── tier1/
│   ├── db_canonical_diff.md            ← Phase -1.A output
│   ├── api_contract_v1.md              ← Phase -1.B output
│   └── topology_v2.md                  ← Phase -1.C output
└── _NEXT_PHASES.md                     ← (created when Phase 0 starts)
```

## Definition of Done — Phase -1

- [ ] 3 file tier1/* tồn tại + complete per acceptance criteria
- [ ] Bug PM-001 attempt log updated với findings
- [ ] Branch `chore/audit-2026-foundation` commit + PR
- [ ] PM_REVIEW INDEX.md update để reference AUDIT_2026/
- [ ] ThienPDM review + approve before merge

Sau Done: Phase 0 kicks off (audit framework + module inventory).

## Risks + mitigation

| Risk | Mitigation |
|---|---|
| Phase -1 phình to ngoài scope | Strict charter này, mọi extension push xuống Phase 1+ |
| Em diff sai vì code lớn | Document method per file, ThienPDM review |
| Drift quá nặng → Tier 1 không đủ tin cậy | Sau -1.A nếu thấy DB drift > 50%, escalate Option A (full rebuild) |
| Time overrun | Em estimate 1.5 ngày total. Nếu > 2 ngày, pause + reassess scope |

## Notes

- Đây là **first AUDIT_2026 artifact**. Mọi output Phase 0+ sẽ ở folder này.
- Format markdown, Vietnamese (per rule 25-docs-sql).
- File path absolute trong reference, link relative trong cross-reference.
- Em không tạo file nào ngoài `tier1/*` trong Phase -1.
