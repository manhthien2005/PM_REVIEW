---
inclusion: fileMatch
fileMatchPattern: "**/*.{js,ts,jsx,tsx}"
---

# Express + Prisma Rules — HealthGuard Backend

Áp dụng khi đang làm việc với file JS/TS trong HealthGuard.

## Key conventions

- **PrismaClient singleton** từ `lib/prisma.js`
- **Parameterized queries only** — no string concat
- **errorHandler middleware** map Prisma errors → HTTP status
- **JWT verify** trên mọi `/api/admin/*` route
- **Socket.IO** room-based emit, JWT in handshake

## Anti-patterns (flag tự động)

- `new PrismaClient()` ngoài singleton
- SQL string concat
- `app.use(cors())` không có origin allowlist
- `io.emit` broadcast all (dùng rooms)
- Stack trace in 500 response
- `dangerouslySetInnerHTML` với user input
- `localStorage` lưu JWT

## Commands

- `npm test -- <file>` trước `npm test` (full)
- `npm run lint` zero errors
