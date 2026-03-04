# EP01-Database — Stories

## S01: [Admin BE] Setup PostgreSQL & Chạy SQL Scripts
- **Assignee:** Admin BE Dev | **SP:** 3 | **Priority:** Highest | **Component:** Admin-BE
- **Labels:** Backend, Infra, Sprint-1

**Description:** Setup PostgreSQL + TimescaleDB trên dev. Chạy 9 file SQL scripts (01→09). Verify 11 tables + 44 indexes. Document connection string cho team.

**Acceptance Criteria:**
- [ ] Setup PostgreSQL + TimescaleDB trên dev
- [ ] Chạy tuần tự SQL scripts 01→09
- [ ] Verify 11 tables + 44 indexes
- [ ] Verify compression/retention policies active
- [ ] Document connection string cho team

---

## S02: [Mobile BE] Review Schema & Test Kết nối
- **Assignee:** Mobile BE Dev | **SP:** 1 | **Priority:** High | **Component:** Mobile-BE
- **Labels:** Backend, Infra, Sprint-1

**Description:** Review database schema. Test kết nối PostgreSQL từ FastAPI (SQLAlchemy). Chuẩn bị SQLAlchemy models reflect từ DB.

**Acceptance Criteria:**
- [ ] Review schema thành công
- [ ] Kết nối PostgreSQL từ FastAPI hoạt động
- [ ] SQLAlchemy models reflect từ DB

---

## S03: [AI] Review Schema cho AI Pipeline
- **Assignee:** AI Dev | **SP:** 1 | **Priority:** High | **Component:** AI-Models
- **Labels:** AI, Infra, Sprint-1

**Description:** Review schema cho bảng vitals và motion_data (input AI). Review risk_scores + risk_explanations (output AI). Verify TimescaleDB hypertables.

**Acceptance Criteria:**
- [ ] Review input tables (vitals, motion_data)
- [ ] Review output tables (risk_scores, risk_explanations)
- [ ] Verify TimescaleDB hypertables

---

## S04: [QA] Kiểm tra kết nối DB & CRUD cơ bản
- **Assignee:** Tester | **SP:** 1 | **Priority:** High | **Component:** QA
- **Labels:** Test, Infra, Sprint-1

**Description:** Verify DB connection từ cả 2 backend. Test CRUD operations trên sample tables. Verify TimescaleDB continuous aggregates.

**Acceptance Criteria:**
- [ ] DB connection từ Admin BE + Mobile BE ok
- [ ] CRUD operations trên sample tables ok
- [ ] TimescaleDB continuous aggregates hoạt động
