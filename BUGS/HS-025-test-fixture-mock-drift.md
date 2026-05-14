# Bug HS-025: 21 backend tests fail do mock chain/fixture drift voi implementation

**Status:** Open
**Repo(s):** health_system (backend)
**Module:** backend/tests (multiple files)
**Severity:** Low (test-only, khong impact production runtime)
**Reporter:** ThienPDM (via Phase 4 reverify 2026-05-14)
**Created:** 2026-05-14
**Resolved:** _(pending)_

## Symptom

Sau khi run full backend test suite voi DB up va tat ca Phase 4 migrations da apply, 21 test fail do mock chain hoac fixture khong khop voi implementation hien tai. Day la **pre-existing drift** — tests viet truoc khi service refactor + chua update.

Phan biet voi runtime: cac test nay drift o **assertion side**, code service hoat dong dung. App chay binh thuong.

## Affected tests (21 total)

### Auth (7 tests)
- test_auth_route_contract.py - 2 verification code tests
- test_auth_service.py - login + change/reset 5 tests

Root cause: Test mock UserRepository.verify_login nhung AuthService.login impl hien tai goi UserRepository.get_by_email + verify_credential rieng. Mock setup khong trigger code path that.

### Emergency (5 tests)
- test_emergency_routes_http.py - 1 test trigger SOS
- test_emergency_service_contract.py - 4 tests get/trigger SOS

Root cause: SQLAlchemy mock chain incomplete. Test setup db.query.filter.all nhung impl dung db.query.join.filter.first chain khac.

### Relationship (3 tests)
- test_relationship_routes_http.py - 1 test request relationship
- test_relationship_service_contract.py - 2 tests format_relationships

Root cause: format_relationships impl goi db.query(User).filter(User.id.in_(list)).all o middle pipeline. Mock chain test khong cover query nay - return empty users_map - final result empty.

### Monitoring + Notifications (2 tests)
- test_monitoring_service_contract.py - 1 test refresh stale risk
- test_notifications_routes_http.py - 1 test unregister push token

Root cause: Mock fixture missing field/relationship moi added trong subsequent service refactors.

## Root cause classification

3 pattern chinh:

1. **Mock target drift** (Auth 7): test mock method nay nhung impl goi method khac.
2. **Mock chain incomplete** (Emergency 5, Relationship 3): SQLAlchemy mock setup chi cover 1-2 step trong chain, impl extend chain - return None/empty silently.
3. **Fixture stale** (Monitoring + Notifications 2): test fixture ORM object thieu field/relationship moi.

## NOT Phase 4 regression - prove

Em verify cac fail nay khong phai do Phase 4 changes:
- auth_service.py last touched: pre-Phase 4 (commit a784384)
- relationship_service.py last touched: pre-Phase 4 (steering doc only)
- emergency_service backend: lien quan HG repo, khong phai HS Phase 4 scope
- Phase 4 commits (8886325 settings, 1cbf499 telemetry, 57739e4 ORM canonical) khong cham cac service file nay

## Why severity = Low

- 0 production impact (service code OK)
- 0 user-facing bug
- Chi affect dev workflow (CI green-bar khi run full suite)
- Mobile app + IoT sim flows van hoat dong
- Phase 4 production-safe (verify qua 14 BLOCK 6 IoT pass + 62/62 model-api pass + 247/248 HG pass)

## Proposed fix (defer Phase 5+)

### Approach 1: Update mock chain incrementally (recommend)
- Sweep through 21 tests, update mock setup match current impl
- Add helper fixture cho relationship tests
- Re-record mock chain cho emergency tests
- Effort: ~4-6h

### Approach 2: Replace mock-heavy tests bang integration tests
- Drop mock chain, dung TestClient + real DB (test_db fixture)
- Tests cham boundary thay vi internal - match steering 30-testing-discipline.md
- Effort: ~8-12h
- Better long-term but bigger refactor

### Approach 3: Mark tests xfail voi reason
- pytest.mark.xfail reason="HS-025 mock drift, defer Phase 5+"
- Quick win de CI green
- Effort: 30min

## Recommendation

Phase 5+ adopt Approach 1 (update mock chain) hoac Approach 2 (rewrite integration).
Phase 4 closure (now): track 21 fail trong INDEX statistics.

## Related

- HS-026 (separate): 14 telemetry tests regression do thieu X-Internal-Service header (Phase 4 BLOCK 3 HS-004 add guard)
- HS-027 (separate): 1 schema gap DeviceSettingsRequest van expose calibration field

## Notes

- Phat hien trong Phase 4 reverify 2026-05-14 sau khi anh apply migrations + run full test suite
- 21 fail KHONG ngan Phase 4 closure
- Defer Phase 5+ test cleanup sprint
