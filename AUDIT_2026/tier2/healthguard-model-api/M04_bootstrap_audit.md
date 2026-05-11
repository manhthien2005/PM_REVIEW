# Audit: M04 — Bootstrap (main.py + config.py)

**Module:** `healthguard-model-api/app/{main.py, config.py}`
**Audit date:** 2026-05-11
**Auditor:** ThienPDM (via Cascade)
**Framework version:** v1
**Track:** Phase 1 Track 4 (model-api)

## Scope

- `app/main.py` (72 LoC) — FastAPI app init, lifespan, CORS, router include
- `app/config.py` (90 LoC) — pydantic-settings v2 with 3 threshold groups + 8 path fields

## Scores

| Axis | Score | Notes |
|---|---|---|
| Correctness | 2/3 | Lifespan + settings OK. Missing fail-fast option khi model load fail. |
| Readability | 3/3 | Clear OpenAPI desc, structured config. |
| Architecture | 3/3 | Clean lifespan, singleton pattern, immutable settings. |
| **Security** | **0/3** | 🚨 CORS `*` + credentials, no internal_secret field, no rate limit. |
| Performance | 2/3 | Models cached at startup. Sync inference trong async endpoint potential. |
| **Total** | **10/15** | Band: **🔴 Critical** (Security=0 auto-trigger) |

## Findings

### Correctness (2/3)

- ✓ `lifespan` async context manager loads 3 models sequentially (`main.py:37-50`)
- ✓ pydantic-settings v2 with `SettingsConfigDict` (`config.py:41-44`)
- ✓ `Field` with `ge`/`le` validators on `fall_min_sequence_samples` (`config.py:51`)
- ⚠️ Model load failure: services catch exception internally + set `_loaded=False`. App boots even khi ALL models fail → routes return 503 individually. Acceptable design BUT no fail-fast env flag for production preference.
- ⚠️ No `.env` path explicit — pydantic-settings v2 default behavior. Verify `.env.example` exists trong repo (em chưa kiểm tra Phase 1).

### Readability (3/3)

- ✓ OpenAPI `description` markdown formatted, enumerates 3 endpoints + 3 model artifacts (`main.py:23-34`)
- ✓ Threshold classes split per domain (`FallThresholds`, `HealthThresholds`, `SleepThresholds`) thay vì 1 god class
- ✓ Path fields có `description` arg để OpenAPI document (`config.py:62, 71, 76, 81`)
- ✓ Logging format `"%(asctime)s | %(levelname)-8s | %(name)s | %(message)s"` standard

### Architecture (3/3)

- ✓ `asynccontextmanager` đúng pattern cho FastAPI lifespan
- ✓ Service singletons imported at module-level (`fall_service`, `health_service`, `sleep_service`) — load on lifespan startup
- ✓ `settings = Settings()` immutable global (line 89)
- ✓ Router inclusion sequential, no global prefix (per Phase -1.B mapping)

### Security (0/3) — 🚨 Auto-Critical

**🚨 P0:** `main.py:60-66` — CORS misconfigured:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        # ← any origin
    allow_credentials=True,     # ← combined với "*" = browser reject + spec violation
    allow_methods=["*"],
    allow_headers=["*"],
)
```

**Impact:**
- Browsers reject `allow_origins=["*"]` + `allow_credentials=True` per CORS spec — credentials effectively unusable
- Even nếu work, expose CORS to any origin → CSRF risk nếu có auth (currently no auth, but ADR-004 + D-013 sẽ add internal secret)

**🚨 P0 — D-013 prerequisite:** `config.py` MISSING `internal_secret` field. Phase 4 fix D-013 (add `verify_internal_secret`) **cần thêm field này trước**.

**🚨 P1:** No rate limiting middleware. ML inference cost expensive → DDoS risk after D-013 fix.

**⚠️ P2:** No `TrustedHostMiddleware` to prevent Host header injection.

**⚠️ P2:** No request size limit (`max_request_size`) — large fall window payload có thể OOM (`min_length=50` in schema nhưng max không cap).

**Anti-pattern HIT:** CORS `*` in production config → Security score = 0.

### Performance (2/3)

- ✓ Models loaded once on lifespan startup, cached in service instance
- ✓ Async endpoints (FastAPI default uvicorn non-blocking)
- ⚠️ `xgboost`/`lightgbm` inference is **CPU-bound sync** trong async endpoint → blocks event loop for window duration. Should wrap với `asyncio.to_thread`. Acceptable cho dev/low traffic, refactor cho production load.
- ⚠️ No connection pool size config (uvicorn workers managed externally — verify deploy script Phase 1)
- ⚠️ No response streaming — all results buffered (acceptable cho small batches)

## Recommended actions (Phase 4)

- [ ] **P0:** Fix CORS — add `ALLOWED_ORIGINS` env var (comma-separated), parse to list, no `*` in production (`main.py:60-66`)
- [ ] **P0:** Add `internal_secret` field to `Settings` (`config.py`) for D-013 prep
- [ ] **P0:** Add `verify_internal_secret` dependency (likely new file `app/dependencies.py`)
- [ ] **P1:** Add `slowapi` hoặc similar rate limiter cho `/api/v1/{fall,health,sleep}/predict`
- [ ] **P1:** Wrap model inference với `asyncio.to_thread` cho non-blocking
- [ ] **P2:** Add `TrustedHostMiddleware`
- [ ] **P2:** Cap request size via middleware
- [ ] **P2:** Add structured logging (JSON format option for prod)

## Out of scope (defer Phase 3 deep-dive)

- Model loading sequence (em chỉ scan lifespan, không deep-dive service load logic)
- `.env.example` content verification
- Deployment configuration (uvicorn args, Docker)
- Performance benchmarks for inference latency

## Cross-references

- Phase -1.B: [D-013](../../tier1/api_contract_v1.md) predict endpoints no internal secret
- Phase -1.B: [D-014](../../tier1/api_contract_v1.md) `/health` semantic collision
- Phase 0: Module M04 in [04_healthguard_model_api.md](../../module_inventory/04_healthguard_model_api.md)
