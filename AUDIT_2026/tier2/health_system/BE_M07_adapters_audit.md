# Audit: BE-M07 — adapters (boundary translation layer)

**Module:** `health_system/backend/app/adapters/`
**Audit date:** 2026-05-13
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 2 — health_system backend
**Depth mode:** Full

## Scope

Module adapters chứa boundary translation layer Phase 3b — formalise contract giữa router/service/persistence với external healthguard-model-api. Scope audit = 6 file (`__init__.py` + 5 adapter file). ~1,000 LoC. Focus: outbound auth header, timeout config, retry policy, circuit breaker, error translation, secret sourcing, contract drift detection. Phạm vi loại trừ: `model_api_client.py` (BE-M03 services scope), router consumer (BE-M02), schema definition (BE-M05), repository persistence target (BE-M06).

| File | LoC | Purpose | Notes |
|---|---|---|---|
| `__init__.py` | ~30 | Re-export 5 adapter + module docstring giải thích Phase 3b plan | OK. Cross-reference `risk_alert_service` extraction history. |
| `fall_persistence_adapter.py` | ~115 | Persist fall prediction → `fall_events` row | Defensive `_extract_*` helper + clamp confidence [0,1] match `NUMERIC(4,3)` constraint. |
| `model_api_health_adapter.py` | ~370 | Health domain: `to_record` + `from_response` + `from_local_inference` | Largest adapter, 11+ helper static method. Contract pinned by snapshot test. |
| `normalized_explanation.py` | ~75 | Frozen dataclass shared producer/consumer cycle break | Slots+frozen, immutable, well-documented. Clean type. |
| `risk_persistence_adapter.py` | ~145 | Persist `NormalizedExplanation` → `risk_scores` + `risk_explanations` | Single-transaction pattern + `_DecimalEncoder` defensive. |
| `sleep_risk_adapter.py` | ~210 | Sleep domain: inversion `risk = 100 - sleep_score` + risk-level mapping | Plan §4A axis convention captured inline. |

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 3/3 | Defensive `_extract_*` clamp/coerce/truncate match DB constraint (NUMERIC(4,3), VARCHAR(20), VARCHAR(36)). Sleep score inversion logic correct + edge case `0.0 → risk 100` flag model-unavailable. Verbatim port comment captures regression-prevention. Single-transaction persist với rollback on failure. |
| Readability | 3/3 | Module docstring best-in-class với cross-reference plan section + Phase number. `_extract_features` comment captures JSONB snapshot intent. Helper static method `@staticmethod` pure-function — testable isolation. |
| Architecture | 3/3 | Clean separation 3 concern: persistence (fall/risk), translation (model_api_health, sleep_risk), shared type (normalized_explanation). Producer-consumer cycle break documented. `@staticmethod` boundary classes — không state, không singleton. Match plan §3b extraction. |
| Security | 2/3 | KHÔNG hit anti-pattern auto-flag. Trừ điểm: cross-repo outbound `X-Internal-Secret` missing trong `model_api_client.py` (out of scope BE-M07 — verify Task 9); model_request_id truncate `[:36]` defensive nhưng không validate UUID format (P2 defense in-depth). |
| Performance | 3/3 | Persistence adapter single-roundtrip 1 transaction. JSONB feature snapshot O(N) keys. Decimal encoder pure-function. Không N+1 (adapter không query, chỉ insert). Không blocking I/O. |
| **Total** | **14/15** | Band: **🟢 Mature** — không hit anti-pattern auto-flag, layer separation clean, contract pinned. |

## Findings

### Correctness

- `backend/app/adapters/fall_persistence_adapter.py:94-104` — `_extract_probability` clamp [0,1]:
  ```python
  try:
      value = float(raw) if raw is not None else 0.0
  except (TypeError, ValueError):
      value = 0.0
  return max(0.0, min(1.0, value))
  ```
  Defense match DB constraint `confidence: NUMERIC(4, 3)` (max 1.000) + canonical `CHECK (confidence >= 0 AND confidence <= 1)`. Edge case `None`/string/inf → 0.0 thay vì raise. Good.

- `backend/app/adapters/fall_persistence_adapter.py:111-122` — `_extract_model_version` truncate `[:20]`:
  Match `fall_events.model_version: VARCHAR(20)`. Defense forward-compat khi model-api release model name dài. Comment giải thích explicit.

- `backend/app/adapters/sleep_risk_adapter.py:160-176` — Sleep score inversion + edge case:
  ```python
  raw = response.get("predicted_sleep_score")
  if raw is None:
      inner = response.get("prediction") or {}
      if isinstance(inner, dict):
          raw = inner.get("prediction_score")
  try:
      value = float(raw) if raw is not None else 0.0
  except (TypeError, ValueError):
      value = 0.0
  return max(0.0, min(100.0, value))
  ```
  + line 73: `risk_score = max(0.0, min(100.0, round(100.0 - sleep_score, 2)))`.
  
  Comment giải thích "deliberately flags 'we got nothing useful from the model' as critical risk rather than silently treating it as healthy sleep". Defensive design intent đúng — fail-closed cho life-critical sleep risk.

- `backend/app/adapters/risk_persistence_adapter.py:93-124` — Single-transaction persist với rollback:
  ```python
  try:
      ...
      db.add(risk_score_row)
      db.flush()
      ...
      db.add(risk_explanation)
      db.commit()
      db.refresh(risk_score_row)
  except Exception:
      db.rollback()
      logger.exception("Failed to persist risk score for device %s", device_id)
      raise HTTPException(status_code=500, detail="Không thể lưu risk score")
  ```
  Atomic invariant đúng: cả 2 row hoặc đều ghi hoặc đều không. Exception logger có context (`device_id`). HTTPException 500 không leak stack trace. Best pattern.

- `backend/app/adapters/risk_persistence_adapter.py:31-39` — `_DecimalEncoder`:
  ```python
  class _DecimalEncoder(json.JSONEncoder):
      def default(self, o: Any) -> Any:
          if isinstance(o, Decimal):
              return float(o)
          return super().default(o)
  ```
  Defense cho `NUMERIC` columns trả về `Decimal` từ SQLAlchemy. Không xử lý sẽ `TypeError: Object of type Decimal is not JSON serializable`. Comment giải thích scope private. Good.

- `backend/app/adapters/model_api_health_adapter.py:145-161` — `from_response` model_request_id truncate:
  ```python
  raw_request_id = meta.get("request_id") if isinstance(meta, dict) else None
  model_request_id: str | None = None
  if raw_request_id is not None:
      candidate = str(raw_request_id).strip()
      model_request_id = candidate[:36] if candidate else None
  ```
  Match `risk_explanations.model_request_id: VARCHAR(36)` (UUID-shaped). Defense `str()` cast nếu upstream sent number. Truncate `[:36]` nếu future model-api gửi >36 chars. Comment captures Phase 2 traceability rationale.

- `backend/app/adapters/model_api_health_adapter.py:180-195` — `from_local_inference` model_version_label:
  ```python
  model_version_label = f"{backend_label}-v1.0"[:20]
  ```
  Truncate match `risk_scores.model_version: VARCHAR(20)`. Verbatim port comment: "local labels keep '-v1.0' suffix". Forward-compat OK.

- `backend/app/adapters/model_api_health_adapter.py:235-248` — `_normalize_top_features` filter invalid entries. Defensive filter — drop non-dict, empty feature name. Pattern reusable.

- `backend/app/adapters/model_api_health_adapter.py:280-300` — `_feature_importance_from_top_features`:
  ```python
  out[key] = round(float(entry.get("impact") or 0.0), 4)
  ```
  Verbatim port comment "missing or None impact defaults to 0.0 rather than being skipped". Backward-compat cho test pin. Round 4 decimals match Phase 1 contract.

- `backend/app/adapters/sleep_risk_adapter.py:202-216` — Sleep `_default_recommendations` 3 tier (3 items critical / 2 items medium / 2 items low). Comment "Pinned by route-level test test_sleep_risk_route.py — update both together". Contract test discipline good.

- `backend/app/adapters/normalized_explanation.py:34-71` — Dataclass với `frozen=True, slots=True`. Immutable + slot-optimized. Producer-consumer cycle break documented module docstring (line 9-19). 16 field đầy đủ + default cho optional. Good.

- `backend/app/adapters/__init__.py:1-19` — Module docstring best-in-class: history + plan reference + cross-module pointer. Reader hiểu Phase 3b extraction context trong 30s.

### Readability

- `backend/app/adapters/__init__.py:1-19` — module docstring giải thích Phase 3b extraction từ `risk_alert_service.py`. Cross-reference `MobileRiskDtoAdapter` đã tồn tại như `risk_report_builder.py`. Pattern handoff documented.
- `backend/app/adapters/normalized_explanation.py:1-21` — module docstring "intentionally separate from NormalizedRiskRow ... write path vs read path". Cycle-break rationale captured. Best-in-class.
- `backend/app/adapters/normalized_explanation.py:34-49` — class docstring với 5 sub-bullet field semantics. Reader implement consumer biết rõ field intent.
- `backend/app/adapters/fall_persistence_adapter.py:1-22` — module docstring "Phase 4B-thin (see backend/docs/risk-contract-baseline.md §7e)". Cross-reference plan section + WHY tách `RiskPersistenceAdapter` (different lifecycle: state machine vs continuous trend).
- `backend/app/adapters/fall_persistence_adapter.py:130-145` — `_extract_features` comment "snapshot the explainability + traceability bits onto the row ... promote model_request_id to top-level for easier log correlation". Reader hiểu DBA-side query intent.
- `backend/app/adapters/sleep_risk_adapter.py:1-30` — module docstring giải thích sleep-score inversion convention + plan §4A reference + risk-level mapping rationale. Best-in-class cross-domain documentation.
- `backend/app/adapters/sleep_risk_adapter.py:62-76` — `from_response` inversion logic comment "model-api ... high=better. risk_scores ... high=worse risk. So adapter writes risk_score = 100 - predicted_sleep_score". Math operation rationale clear.
- `backend/app/adapters/sleep_risk_adapter.py:170-180` — `_extract_sleep_score` edge case "0.0 → critical risk rather than silently treating as healthy sleep" defense intent.
- `backend/app/adapters/model_api_health_adapter.py:88-100` — `to_record` comment "verbatim port" + "MUST not drift, otherwise model-api receives biased inputs" + medical defaults pinned. Regression-prevention.
- `backend/app/adapters/model_api_health_adapter.py:280-302` — `_feature_importance_from_top_features` "verbatim port" comment + "preserve both transformations so existing tests and downstream consumers see identical numbers". Test compatibility discipline.
- `backend/app/adapters/model_api_health_adapter.py:310-326` — `_default_recommendations` "verbatim port. The exact strings + counts (3 for critical, 2 for medium, 2 for low) are pinned by test_shap_explanation_contract.TestDefaultRecommendations". Contract test discipline.
- `backend/app/adapters/risk_persistence_adapter.py:1-22` — module docstring giải thích Phase 3b extraction history + WHY split (unit-testable + reusable cho sleep/fall future).

### Architecture

- **Clean separation 3 concern**:
  - **Persistence adapter**: `fall_persistence_adapter.py` (FallEvent), `risk_persistence_adapter.py` (RiskScore + RiskExplanation).
  - **Translation adapter**: `model_api_health_adapter.py` (health domain), `sleep_risk_adapter.py` (sleep domain).
  - **Shared type**: `normalized_explanation.py` — break producer-consumer cycle.
  
  Tách concern đúng. Adapter pattern intent clear. Pattern reusable cho future domain.

- **Producer-consumer cycle break documented**:
  ```
  Inference (write path) → NormalizedExplanation → RiskPersistenceAdapter → DB
  DB (read path) → MonitoringService → NormalizedRiskRow → Mobile DTO
  ```
  Phân biệt rõ 2 type không cycle. Plan section §E.3 + module docstring captures.

- **`@staticmethod` boundary class** — không state, không singleton, pure-function helpers. Testable isolation.

- **`MobileRiskDtoAdapter` placement**: `__init__.py` cross-reference `mobile_risk_dto_adapter` đã tồn tại như `services/risk_report_builder.py`. Cycle-break asymmetric (write trong adapters/, read trong services/). Acceptable nhưng inconsistent — Phase 4 cân nhắc move cho symmetric naming. P2.

- `backend/app/adapters/model_api_health_adapter.py` — **largest adapter (370 LoC)**: `to_record` + `from_response` + `from_local_inference` + 11+ private static method. Borderline approach "fat adapter" nhưng cohesion tốt — tất cả method liên quan health domain translation. Acceptable. Hiện sleep_risk_adapter.py đã tách → pattern correct.

- **Persistence adapter NOT consume repository pattern**: `RiskPersistenceAdapter.persist` trực tiếp `db.add(RiskScore)` + `db.add(RiskExplanation)`. Bypass repository layer (BE-M06 finding) — repository hiện không có `risk_repository.py`. Acceptable hiện tại — adapter là boundary tới external (model-api), repository là boundary tới DB. Mixing OK cho persistence adapter (write-only). Phase 4 P2 review.

- `backend/app/adapters/__init__.py` re-export pattern đúng. `from app.adapters import FallPersistenceAdapter` ngắn gọn cho consumer.

### Security

- **Anti-pattern auto-flag scan**:
  - `eval()` / `exec()`? **NO**.
  - SQL string concat? **NO** — toàn ORM `db.add` parameterized.
  - Plaintext credential? **NO** — adapter không touching credential.
  - CORS wildcard? scope BE-M01.
  - SSL verify disabled? **NO** trong adapter scope.
  - Token in localStorage? **NO**.
  - Hardcoded secret? **NO** trong adapter scope.
  - `dangerouslySetInnerHTML`? **NO**.
  
  **Kết luận: 0 hit → Security=0 override KHÔNG áp dụng.**

- **Cross-repo outbound auth header verify** (out of scope BE-M07 thực thi nhưng adapter ảnh hưởng):
  - `model_api_client.py:98-103` set header `X-Internal-Service: health-system-backend` constant cho mọi outbound call.
  - **KHÔNG có `X-Internal-Secret` header** trong client.
  - ADR-005 mandate "Internal service-to-service: `X-Internal-Secret` header".
  - **Verify cross-repo**: model-api side require `X-Internal-Secret` không?
  - Nếu model-api không enforce → cả 2 side fail-open ↔ HS-006 pattern.
  - Nếu model-api enforce → outbound call fail (401/403) khi production.
  - Phase 4 cross-check + tracked qua ADR-005 implementation. Reference only — không re-flag bug ID (HS-006 governs).

- `backend/app/adapters/model_api_health_adapter.py:155-161` — `model_request_id` defensive truncate `[:36]` nhưng không validate UUID format. Defense in-depth: regex `^[a-f0-9-]{36}$` validate. P2.

- `backend/app/adapters/risk_persistence_adapter.py:107-110` — HTTPException 500 generic message. Không leak stack trace tới client. Logger.exception captures full context server-side. Pattern đúng steering "API error response: không expose stack trace tới client".

- `backend/app/adapters/fall_persistence_adapter.py:65-75` — Cùng pattern HTTPException 500 generic message. Sound.

- `backend/app/adapters/normalized_explanation.py` — `frozen=True` immutable post-creation → adapter không thể mutate sau persist. Defense against accidental mutation cross-thread.

- PHI handling adapters: features/top_features/shap_details JSONB blob lưu vào DB plaintext. Không có encryption. Same cross-cutting gap với BE-M04/BE-M06. Đã tracked. Không re-flag.

### Performance

- `backend/app/adapters/risk_persistence_adapter.py:96-105` — Single-transaction: 3 round-trip cho 2 row insert + refresh. Acceptable. `db.flush()` để có `risk_score_row.id` cho FK liên kết. Không tránh được unless dùng `RETURNING id` raw SQL.

- `backend/app/adapters/risk_persistence_adapter.py:73-80` — `build_features_json` round-trip `json.dumps + json.loads` để flatten Decimal. Cost O(N) keys. Acceptable scale per-request.

- `backend/app/adapters/model_api_health_adapter.py` — pure-function helpers. O(N) feature count. Acceptable.

- `backend/app/adapters/sleep_risk_adapter.py:196-197` — Sleep score inversion `100 - x` constant time.

- Adapter không HTTP outbound (mọi call do `model_api_client.py` thực hiện). Không network I/O blocking trong adapter.

- Adapter không query DB đọc (chỉ insert). Không N+1 risk.

- `_DecimalEncoder` custom class init mỗi `json.dumps` call. Micro-perf. P2 negligible.

## Positive findings

- `backend/app/adapters/__init__.py:1-19` — module docstring best-in-class với cross-reference plan + cycle-break documentation.
- `backend/app/adapters/normalized_explanation.py:1-21` — module docstring giải thích "write path vs read path" producer-consumer cycle-break. Architecture intent captured.
- `backend/app/adapters/normalized_explanation.py:34-49` — `@dataclass(frozen=True, slots=True)` immutable shared type với 5-bullet field semantics docstring. Type-safe + memory-optimized.
- `backend/app/adapters/fall_persistence_adapter.py:94-104` — `_extract_probability` clamp [0,1] match DB constraint NUMERIC(4,3). Defensive design.
- `backend/app/adapters/fall_persistence_adapter.py:111-122` — `_extract_model_version` truncate `[:20]` match VARCHAR(20). Forward-compat.
- `backend/app/adapters/sleep_risk_adapter.py:1-30` — module docstring giải thích sleep-score inversion convention + plan §4A reference + edge case "fail-closed for life-critical".
- `backend/app/adapters/sleep_risk_adapter.py:160-176` — `_extract_sleep_score` edge case `None → 0.0 → risk 100` flag model-unavailable thay vì silent healthy.
- `backend/app/adapters/risk_persistence_adapter.py:31-39` — `_DecimalEncoder` defensive cho NUMERIC columns trả Decimal.
- `backend/app/adapters/risk_persistence_adapter.py:93-124` — Single-transaction persist với rollback + HTTPException 500 generic message + logger.exception with context.
- `backend/app/adapters/model_api_health_adapter.py:88-100` — "verbatim port" comment + medical defaults pinned + drift warning. Regression-prevention discipline.
- `backend/app/adapters/model_api_health_adapter.py:235-302` — Multiple "verbatim port" comments captures historical context cho future test/refactor.
- `backend/app/adapters/sleep_risk_adapter.py:202-216` — `_default_recommendations` "pinned by route-level test" + tier 3-2-2 count documented.
- `backend/app/adapters/model_api_health_adapter.py:155-161` + `sleep_risk_adapter.py:185-191` — `model_request_id` truncate `[:36]` + Phase 2 traceability rationale captured.
- Adapter `@staticmethod` pure-function pattern across 6 file — testable isolation + no state coupling.

## New bugs

Không phát hiện bug mới trong module này.

## Recommended actions (Phase 4)

### P0

- [ ] Không có action P0.

### P1

- [ ] Không có action P1.

### P2

- [ ] **`MobileRiskDtoAdapter` placement consistency**: `risk_report_builder.py` (consume `NormalizedRiskRow`) hiện ở `services/`. Cân nhắc move sang `adapters/mobile_risk_dto_adapter.py` cho symmetric với `RiskPersistenceAdapter`. Pure refactor, không thay đổi behavior.
- [ ] **`model_request_id` UUID format validate**: regex `^[a-f0-9-]{36}$` validate trước truncate. Defense in-depth.
- [ ] **Adapter consume repository pattern**: khi BE-M06 P1 tạo `risk_repository.py` + `fall_event_repository.py`, refactor adapter consume repository thay vì `db.add(...)` trực tiếp. Strict layering.
- [ ] **`_DecimalEncoder` module-level singleton**: cache class init thay vì per-call. Micro-perf.
- [ ] **PHI encryption strategy ADR**: cùng action ADR cross-cutting với BE-M04/BE-M06.
- [ ] **`from_local_inference` model_request_id**: document inline ADR-level WHY (no upstream request to correlate).

## Out of scope

- `model_api_client.py` HTTP outbound implementation — BE-M03 services scope (Task 9).
- Circuit breaker implementation (`services/circuit_breaker.py`) — BE-M03 services.
- Service consumer của adapter (`risk_alert_service`, `monitoring_service`) — BE-M03.
- Schema definition — BE-M05 schemas.
- Repository pattern for risk/fall event persistence — BE-M06 (P1 recommendation cover).
- Cross-repo `healthguard-model-api` enforce `X-Internal-Secret` verify — out of scope, ADR-005 governs.
- Mobile DTO read path (`risk_report_builder.py` → `NormalizedRiskRow`) — BE-M03 services.
- Defer Phase 3: per-method unit test coverage gap detection, contract test snapshot for adapter.

## Cross-references

- BUGS INDEX (new):
  - Không phát hiện bug mới trong module này.
- BUGS INDEX (reference, không re-flag — pre-existing):
  - [HS-006](../../../BUGS/INDEX.md) — `require_internal_service` fail-open (BE-M08); cross-link với cross-repo `X-Internal-Secret` outbound missing trong `model_api_client.py` (BE-M03 scope verify Task 9).
  - [HS-019](../../../BUGS/INDEX.md) — Router `risk.py` SQL bypass (BE-M02); adapter là target P1 cho refactor.
  - [HS-020](../../../BUGS/INDEX.md) — Plaintext credential committed (BE-M06); cùng anti-pattern class.
- ADR INDEX:
  - [ADR-005](../../../ADR/INDEX.md) — Internal service-to-service auth strategy. `model_api_client.py` consumer.
  - [ADR-013](../../../ADR/INDEX.md) — IoT Simulator direct-DB write.
  - [ADR-015](../../../ADR/INDEX.md) — Alert severity taxonomy. Adapter `_map_risk_level` consume canonical mapping.
- Intent drift (reference only):
  - Không khớp drift ID nào trong blacklist.
- Related audit files:
  - [`BE_M01_main_bootstrap_audit.md`](./BE_M01_main_bootstrap_audit.md).
  - [`BE_M04_models_audit.md`](./BE_M04_models_audit.md) — ORM `RiskScore`, `RiskExplanation`, `FallEvent` consumer.
  - [`BE_M02_routes_audit.md`](./BE_M02_routes_audit.md) — `telemetry.py` consumer trực tiếp adapter.
  - [`BE_M05_schemas_audit.md`](./BE_M05_schemas_audit.md).
  - [`BE_M06_repositories_db_audit.md`](./BE_M06_repositories_db_audit.md) — Repository pattern coverage gap cross-link.
  - [`BE_M08_core_audit.md`](./BE_M08_core_audit.md).
  - `BE_M03_services_audit.md` (Task 9 pending) — `model_api_client.py` consumer của adapter.
- Preflight context: [`_PREFLIGHT_CONTEXT.md`](./_PREFLIGHT_CONTEXT.md)
- Framework rubric: [`00_audit_framework.md`](../../00_audit_framework.md) v1
- Precedent: [`iot-simulator/M01_routers_audit.md`](../iot-simulator/M01_routers_audit.md)
- Backend doc: `health_system/backend/docs/risk-contract-baseline.md` (referenced trong adapter docstring).
