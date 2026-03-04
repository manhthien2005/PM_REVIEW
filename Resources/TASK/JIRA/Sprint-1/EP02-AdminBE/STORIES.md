# EP02-AdminBE — Stories

## S01: [Admin BE] Setup Express + Prisma Project
- **Assignee:** Admin BE Dev | **SP:** 2 | **Priority:** Highest | **Component:** Admin-BE
- **Labels:** Backend, Infra, Sprint-1

**Description:** Setup Express + TypeScript. Prisma Client connect DB. CORS middleware. Logging. Health check endpoint GET /health. Swagger docs. Biến môi trường .env.

**Acceptance Criteria:**
- [ ] Express + TypeScript project setup
- [ ] Prisma Client connect DB thành công
- [ ] CORS middleware hoạt động
- [ ] GET /health trả về 200
- [ ] Swagger docs tại /api-docs
- [ ] .env configuration

---

## S02: [QA] Test Admin BE Health Check & CORS
- **Assignee:** Tester | **SP:** 1 | **Priority:** High | **Component:** QA
- **Labels:** Test, Infra, Sprint-1

**Description:** Test health check endpoint trả về 200. Verify CORS hoạt động đúng.

**Acceptance Criteria:**
- [ ] GET /health trả về 200
- [ ] CORS hoạt động đúng với allowed origins
