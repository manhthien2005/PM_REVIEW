---
inclusion: manual
---

# Skill: Express + Prisma Patterns (HealthGuard)

Áp dụng cho: `HealthGuard/backend` (admin BE) + `HealthGuard/frontend` (React+Vite).

## Backend structure

```
src/
├── routes/             # Express routers
├── controllers/        # Request handling
├── services/           # Business logic
├── lib/
│   ├── prisma.js       # Singleton PrismaClient
│   └── auth.js         # JWT verify middleware
├── middleware/
│   ├── errorHandler.js # Centralized error mapping
│   └── auth.js         # Auth middleware
└── __tests__/          # Jest tests
```

## Prisma

- Singleton: `lib/prisma.js` — NEVER `new PrismaClient()` elsewhere
- Parameterized queries only — no string concat SQL
- Error mapping: P2002 → 409, P2025 → 404 (in errorHandler)
- Select only needed fields — no `SELECT *`

## Auth

- JWT verify middleware on all `/api/admin/*` routes
- `iss=healthguard-admin` — reject mobile tokens
- Role check: admin / clinician

## Error handling

- `errorHandler` middleware catches all
- Never expose stack trace to client
- Map Prisma errors to HTTP status codes

## Socket.IO

- JWT verify in handshake middleware
- Room-based emit — never broadcast all
- Namespace per feature if needed

## Frontend (React + Vite)

- Vitest + Testing Library for component tests
- No `dangerouslySetInnerHTML`
- No `localStorage` for JWT (use httpOnly cookie or memory)
- `import.meta.env.VITE_*` only — non-VITE prefix not in build

## Testing

- Jest for backend: `npm test -- <file>`
- Mock Prisma in service tests
- `npm run lint` zero errors before commit
