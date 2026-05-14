---
inclusion: always
---

# Security Guardrails

VSmartwatch xử lý **dữ liệu sức khỏe** + **PII** + **emergency contact info**. Leak = nghiêm trọng.

## Secrets

- **NEVER hardcode** API key, password, JWT secret, DB credential.
- Use `.env` + dotenv (Node) / pydantic-settings (Python) / flutter_dotenv (mobile).
- `.env.example` checked-in, `.env*` (actual) gitignored.

## Authentication & Authorization

- JWT cho mobile (`iss=healthguard-mobile`) + admin (`iss=healthguard-admin`).
- Internal service-to-service: `X-Internal-Secret` header.
- Mọi endpoint phải có middleware check auth + role. Default: deny.
- Resource ownership check — user A không xem data user B (trừ linked).

## Input validation

- Validate ở boundary (controller/router) trước khi pass vào service.
- Schema validator: zod (Node), pydantic (Python), custom (Dart).
- **Cấm** SQL string concat. Dùng ORM/parameterized query.
- **Cấm** `dangerouslySetInnerHTML` với user input.

## Output sanitization

- API error response: không expose stack trace tới client.
- Không log password/token/health vitals raw. Dùng mask.

## PHI (Personal Health Information)

- Encrypt at rest (pgcrypto hoặc app-layer).
- HTTPS mandatory production.
- Audit log: mọi access PHI phải log (user_id, action, timestamp).

## Em SẼ flag tự động khi phát hiện

- `eval()`, `exec()` với user input
- SQL string concat
- Password trong plaintext
- CORS `*` trong production config
- Disabled SSL verification
- `localStorage` lưu token nhạy cảm
