-- ============================================================================
-- File: 02_seed_relationships.sql
-- Description: Bơm dữ liệu mẫu mô phỏng danh sách Linked Profiles
-- ============================================================================

BEGIN;

-- Bơm Dữ liệu Liên Kết (Linked Profiles / user_relationships)
-- Tình huống: Cụ A chia sẻ dữ liệu cho 3 người: Con trai B, Con dâu C, Bác sĩ D

INSERT INTO user_relationships (patient_id, caregiver_id, relationship_type, is_primary, can_view_vitals, can_receive_alerts, can_view_location) VALUES
-- Anh B (con trai) được quyền xem sinh tồn, nhận SOS alert, và xem GPS vị trí
(2, 3, 'family', true, true, true, true),

-- Chị C (con dâu) được quyền xem sinh tồn, nhận SOS, NHƯNG không xem GPS
(2, 4, 'family', false, true, true, false),

-- Bác sĩ D (điều trị) được quyền xem sinh tồn, KO nhận SOS qua device token mà nhận call
(2, 5, 'doctor', false, true, false, false)
ON CONFLICT (patient_id, caregiver_id) DO NOTHING;


-- Thêm case chéo: Hai vợ chồng B và C link tài khoản với nhau để xem nhịp tim lúc tập thể dục
INSERT INTO user_relationships (patient_id, caregiver_id, relationship_type, is_primary, can_view_vitals, can_receive_alerts, can_view_location) VALUES
(3, 4, 'family', false, true, false, false),
(4, 3, 'family', false, true, false, false)
ON CONFLICT (patient_id, caregiver_id) DO NOTHING;


-- Reset sequence
SELECT setval('user_relationships_id_seq', (SELECT MAX(id) FROM user_relationships));

COMMIT;
