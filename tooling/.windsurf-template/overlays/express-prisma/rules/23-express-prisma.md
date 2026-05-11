---
trigger: always_on
---

# Express + Prisma Rules — HealthGuard/backend

Áp dụng cho admin backend Node.js. Stack: Express + Prisma + JWT + AWS S3.

## Project structure

```
src/
├── server.js              # Express() init, middleware, listen
├── routes/                # router định nghĩa endpoint
├── controllers/           # request handler (parse + call service + respond)
├── services/              # business logic
├── middleware/            # auth, cors, error, rate-limit
├── lib/                   # prisma client, utils
├── __tests__/             # jest tests
└── prisma/
    ├── schema.prisma
    └── migrations/
```

## Routing pattern

```js
// routes/devices.js
const router = require('express').Router();
const deviceController = require('../controllers/deviceController');
const { authJWT, requireRole } = require('../middleware/auth');

router.get('/', authJWT, requireRole('admin'), deviceController.list);
router.post('/', authJWT, requireRole('admin'), deviceController.create);
// ...

module.exports = router;
```

Mount trong `server.js`:

```js
app.use('/api/admin/devices', require('./routes/devices'));
```

## Controllers

- **Thin:** chỉ parse req, call service, gửi response.
- **Don't put business logic** trong controller.
- **Async + try/catch hoặc express-async-errors:**

```js
exports.list = async (req, res, next) => {
  try {
    const devices = await deviceService.list({ userId: req.user.id });
    res.json(devices);
  } catch (err) { next(err); }
};
```

## Services

- **Business logic** + **transaction orchestration** ở đây.
- **Service nhận plain object**, không nhận `req`.
- **Service không biết HTTP** — throw domain error, controller convert thành HTTP response.

## Prisma usage

- **Singleton client:** `lib/prisma.js`:

```js
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient({ log: ['warn', 'error'] });
module.exports = prisma;
```

- **Use `select`/`include` explicit** — không lấy field thừa.
- **Use transactions** cho multi-step writes: `prisma.$transaction([...])`.
- **Don't expose Prisma errors** ra client — wrap thành domain error.

## Migrations

- `npx prisma migrate dev --name <desc>` cho dev (auto-apply).
- `npx prisma migrate deploy` cho production (CI/CD).
- **Cấm:** edit migration file đã commit. Tạo migration mới thay vì sửa.
- Sync với `PM_REVIEW/SQL SCRIPTS/` — đó là canonical schema. Khi schema diverge, hỏi anh nguồn nào đúng.

## Error handling

- **Global error middleware** ở cuối `server.js`:

```js
app.use((err, req, res, next) => {
  logger.error(err);
  if (err.code === 'P2025') return res.status(404).json({ error: 'Not found' });
  res.status(err.status || 500).json({ error: err.message || 'Internal error' });
});
```

- **Cấm leak stack trace** ra response trong production.

## Auth

- **JWT** với `iss=healthguard-admin`.
- **Middleware `authJWT`** verify token + attach `req.user`.
- **Middleware `requireRole('admin')`** sau `authJWT`.
- **Refresh token rotation** (verify implementation trong codebase).

## Logging

- **`winston` hoặc `pino`** centralize trong `lib/logger.js`.
- **Log levels:** error / warn / info / debug.
- **Cấm:** log password, JWT, PHI raw.

## Testing (Jest)

```js
// __tests__/deviceService.test.js
describe('deviceService.create', () => {
  beforeEach(() => jest.clearAllMocks());

  it('rejects duplicate IMEI', async () => {
    prismaMock.device.findUnique.mockResolvedValue({ id: 1 });
    await expect(deviceService.create({ imei: 'X' })).rejects.toThrow('Duplicate');
  });
});
```

- Mock Prisma qua `jest-mock-extended` hoặc manual mock.
- Run: `npm test -- deviceService.test.js` (specific) trước full.

## Realtime (Socket.IO)

- Codebase dùng socket.io cho realtime health monitor (verify trong `src/`).
- **Auth socket** qua JWT trong `handshake.auth.token`.
- **Room per user** — không broadcast tới tất cả client.

## AWS S3

- **Pre-signed URL** cho client upload — không proxy file qua backend.
- **Bucket policy** tightest — chỉ allow specific origin.

## Anti-patterns flag tự động

- `app.use(cors())` không có config → CORS `*` (XEM 40-security-guardrails)
- SQL string concat (luôn dùng Prisma)
- `console.log` trong production
- Sync function trong async route (block event loop)
- Missing `await` cho async call → unhandled rejection
- Hardcode JWT secret
- `JSON.parse` không try-catch user input

## Commands

- `npm install`
- `npm run dev` (nodemon)
- `npx prisma generate` sau khi sửa schema
- `npx prisma migrate dev --name <desc>`
- `npm test -- <file>` trước `npm test`
- `npx prisma studio` để xem DB (dev only)
