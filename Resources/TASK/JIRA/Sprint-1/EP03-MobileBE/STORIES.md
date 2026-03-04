# EP03-MobileBE — Stories

## S01: [Mobile BE] Setup FastAPI + SQLAlchemy Project
- **Assignee:** Mobile BE Dev | **SP:** 2 | **Priority:** Highest | **Component:** Mobile-BE
- **Labels:** Backend, Infra, Sprint-1

**Description:** Setup FastAPI project structure. SQLAlchemy connect DB. CORS middleware. Logging. Health check GET /health. Swagger docs tại /docs. Biến môi trường .env.

**Acceptance Criteria:**
- [ ] FastAPI project structure setup
- [ ] SQLAlchemy connect DB thành công
- [ ] CORS middleware hoạt động
- [ ] GET /health trả về 200
- [ ] Swagger docs tại /docs
- [ ] .env configuration

---

## S02: [QA] Test Mobile BE Health Check & CORS
- **Assignee:** Tester | **SP:** 1 | **Priority:** High | **Component:** QA
- **Labels:** Test, Infra, Sprint-1

**Description:** Test health check endpoint trả về 200. Verify CORS hoạt động đúng. Test với Postman.

**Acceptance Criteria:**
- [ ] GET /health trả về 200
- [ ] CORS hoạt động đúng
- [ ] Postman collection test pass
