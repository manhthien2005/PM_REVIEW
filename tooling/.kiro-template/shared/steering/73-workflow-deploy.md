---
inclusion: manual
---

# Workflow: Deploy Checklist

> **Invoke:** `#73-workflow-deploy` hoac "deploy", "release".

Deploy = production impact. Always: pre-flight -> staging -> smoke test -> production -> monitor.

## Pre-flight (ALL deploys)

- [ ] All tests pass (per stack)
- [ ] No secret committed (`git ls-files | grep .env`)
- [ ] Migration committed (if applicable)
- [ ] Rollback plan written (commit hash + DB rollback script)
- [ ] Backup tag: `git tag pre-deploy-$(date +%Y%m%d-%H%M)`

## Path A: Mobile (Flutter)

```pwsh
flutter clean  # only if pubspec/native changed — confirm first
flutter pub get
flutter build apk --release
flutter build appbundle --release
```

Post-deploy: monitor crash reports 24h, smoke test on device.

## Path B: Admin Backend (Express+Prisma)

```pwsh
npm ci --production
npx prisma migrate deploy  # NEVER prisma migrate dev on prod
pm2 reload ecosystem.config.js --env production
```

Post-deploy: `/health` returns 200, log monitor 15-30 min.

## Path C: Admin Frontend (React+Vite)

```pwsh
npm run build
# Deploy dist/ to static host
```

Post-deploy: hard reload, no console error, WebSocket reconnects.

## Path D: FastAPI services

```pwsh
pytest
pip install -r requirements.txt
systemctl reload <service>
```

Post-deploy: `/health` returns 200, cross-repo dependency check.

## Path E: Database migration

1. Write migration file
2. Update canonical `init_full_setup.sql`
3. Backup production DB: `pg_dump -F c -f backup.dump`
4. Run migration on production
5. Verify: `\d <table>`, `SELECT COUNT(*)`

## Cross-repo deploy order

PM_REVIEW -> DB migration -> Producer -> Consumer -> E2E smoke -> Tag

## Anti-patterns

- Deploy without staging
- Migration without backup
- Deploy app before BE contract ready
- Skip log monitor
- Deploy on Friday evening
- Hardcode prod URL/secret
