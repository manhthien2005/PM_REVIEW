# EP06-Ingestion — Stories

## S01: [Mobile BE] Setup MQTT + HTTP Ingestion
- **Assignee:** Mobile BE Dev | **SP:** 3 | **Priority:** High | **Component:** Mobile-BE
- **Labels:** Backend, Infra, Sprint-2

**Description:** Setup MQTT broker (Mosquitto). MQTT subscriber. POST /api/mobile/telemetry/ingest. Validate dữ liệu (HR 40-200 SpO2 70-100). Ghi vào bảng vitals + motion_data.

**Acceptance Criteria:**
- [ ] MQTT broker (Mosquitto) hoạt động
- [ ] MQTT subscriber nhận dữ liệu
- [ ] POST /api/mobile/telemetry/ingest hoạt động
- [ ] Validate HR 40-200, SpO2 70-100
- [ ] Ghi vào vitals + motion_data tables

---

## S02: [AI] Kiểm tra Định dạng & Chất lượng Dữ liệu
- **Assignee:** AI Dev | **SP:** 1 | **Priority:** High | **Component:** AI-Models
- **Labels:** AI, Infra, Sprint-2

**Description:** Review định dạng dữ liệu từ ingestion. Test với dữ liệu mẫu từ simulator. Xác minh chất lượng tín hiệu (signal_quality motion_artifact).

**Acceptance Criteria:**
- [ ] Định dạng dữ liệu phù hợp cho AI pipeline
- [ ] Test với simulator data thành công
- [ ] Signal quality + motion artifact fields verified

---

## S03: [QA] Kiểm thử Thu thập Dữ liệu MQTT & HTTP
- **Assignee:** Tester | **SP:** 2 | **Priority:** High | **Component:** QA
- **Labels:** Test, Infra, Sprint-2

**Description:** Test MQTT ingestion với simulator. Test HTTP ingestion. Test validation (giá trị ngoài phạm vi). Verify dữ liệu lưu vào TimescaleDB.

**Acceptance Criteria:**
- [ ] MQTT ingestion với simulator ok
- [ ] HTTP ingestion ok
- [ ] Validation reject giá trị ngoài phạm vi
- [ ] Dữ liệu lưu vào TimescaleDB chính xác
