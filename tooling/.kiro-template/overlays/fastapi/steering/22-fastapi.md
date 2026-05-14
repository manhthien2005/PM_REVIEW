---
inclusion: fileMatch
fileMatchPattern: "**/*.py"
---

# FastAPI Rules — Python Backend

Áp dụng khi đang làm việc với file `.py`.

## Key conventions

- **Pydantic v2** syntax (`model_config = ConfigDict(...)`, `field_validator`)
- **One router per domain** với prefix + tag
- **Business logic ở service**, không trong router
- **Return Pydantic model** — không return dict
- **pydantic-settings** cho config (`.env` gitignored)

## Anti-patterns (flag tự động)

- Mutable default arg (`def f(x=[])`)
- `except Exception:` không log + không re-raise
- Hardcode secret/URL/credential
- Sync I/O trong async function (use `asyncio.to_thread`)
- Global mutable state không thread-safe
- `print()` trong production code
- `str(exc)` leaked to client response

## Commands

- `pytest tests/<file>::<test>` (specific) trước `pytest` (full)
- `black . ; isort .` trước commit
- `uvicorn app.main:app --reload --port <port>` (dev)
