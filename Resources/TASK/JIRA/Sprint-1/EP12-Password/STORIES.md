# EP12-Password — Stories

## S01: [Admin BE] API Quên/Đặt lại/Đổi Mật khẩu
- **Assignee:** Admin BE Dev | **SP:** 2 | **Priority:** Medium | **Component:** Admin-BE
- **Labels:** Backend, Auth, Sprint-1

**Description:** POST forgot-password + reset-password + change-password. Token JWT 15 phút. Rate limit 3 lần/15 phút. Token dùng 1 lần. Xác thực mật khẩu hiện tại.

**Acceptance Criteria:**
- [ ] POST forgot-password gửi email reset
- [ ] POST reset-password với token JWT 15 phút
- [ ] POST change-password xác thực mật khẩu cũ
- [ ] Rate limit 3 lần/15 phút
- [ ] Token dùng 1 lần (invalidate sau dùng)

---

## S02: [Mobile BE] API Quên/Đặt lại/Đổi Mật khẩu
- **Assignee:** Mobile BE Dev | **SP:** 2 | **Priority:** Medium | **Component:** Mobile-BE
- **Labels:** Backend, Auth, Sprint-1

**Description:** POST forgot-password + reset-password + change-password. Token JWT 15 phút. Deep link app://reset-password?token=xxx. Rate limit. Token dùng 1 lần.

**Acceptance Criteria:**
- [ ] POST forgot-password gửi email với deep link
- [ ] Deep link app://reset-password?token=xxx
- [ ] POST reset-password hoạt động
- [ ] POST change-password hoạt động
- [ ] Rate limit + token dùng 1 lần

---

## S03: [Admin FE] Giao diện Quên & Đổi Mật khẩu
- **Assignee:** Admin FE Dev | **SP:** 2 | **Priority:** Medium | **Component:** Admin-FE
- **Labels:** Frontend, Auth, Sprint-1

**Description:** Trang quên mật khẩu + đặt lại mật khẩu + đổi mật khẩu (Cài đặt > Bảo mật). Gọi Admin APIs.

**Acceptance Criteria:**
- [ ] Trang quên mật khẩu (nhập email)
- [ ] Trang đặt lại mật khẩu (từ link email)
- [ ] Trang đổi mật khẩu (Cài đặt > Bảo mật)

---

## S04: [Mobile FE] Giao diện Quên & Đổi Mật khẩu
- **Assignee:** Mobile FE Dev | **SP:** 2 | **Priority:** Medium | **Component:** Mobile-FE
- **Labels:** Mobile, Auth, Sprint-1

**Description:** Màn hình quên mật khẩu + đặt lại mật khẩu. Xử lý deep link. Màn hình đổi mật khẩu (Cài đặt). Gọi Mobile APIs.

**Acceptance Criteria:**
- [ ] Màn hình quên mật khẩu
- [ ] Đặt lại mật khẩu qua deep link
- [ ] Màn hình đổi mật khẩu (Cài đặt)

---

## S05: [QA] Kiểm thử các luồng Mật khẩu
- **Assignee:** Tester | **SP:** 2 | **Priority:** Medium | **Component:** QA
- **Labels:** Test, Auth, Sprint-1

**Description:** Test quên/đặt lại/đổi trên cả 2 nền tảng. Test token hết hạn 15 phút. Test rate limiting. Test token dùng 1 lần. Test mật khẩu mới trùng cũ.

**Acceptance Criteria:**
- [ ] Quên/đặt lại/đổi hoạt động trên cả Admin + Mobile
- [ ] Token hết hạn sau 15 phút
- [ ] Rate limiting hoạt động
- [ ] Token dùng 1 lần (lần 2 bị reject)
- [ ] Mật khẩu mới trùng cũ → reject
