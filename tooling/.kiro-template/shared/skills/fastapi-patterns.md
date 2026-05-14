---
inclusion: manual
---

# Skill: FastAPI Patterns (Python BE repos)

Áp dụng cho: `health_system/backend`, `healthguard-model-api`, `Iot_Simulator_clean/api_server`.

## Structure

```
app/
├── main.py             # FastAPI() init, router include, middleware
├── routers/            # endpoints (1 file/module)
├── services/           # business logic
├── models/             # Pydantic schemas
├── repositories/       # data access
├── dependencies.py     # Depends() factories
└── config.py           # pydantic-settings
```

## Routing

- One router per domain: `routers/fall.py`, `routers/auth.py`
- Prefix + tag: `APIRouter(prefix="/fall", tags=["fall"])`
- DI cho auth/DB/service via `Depends()`
- Return Pydantic model — không return dict

## Pydantic v2

- `model_config = ConfigDict(...)`, `field_validator`
- Request suffix `Request`, response `Response`
- Don't reuse DB model as API schema

## Services

- Business logic ở service, không trong router
- Service không biết HTTP — không nhận Request, không return JSONResponse
- Async by default

## Error handling

- Custom exceptions trong `app/exceptions.py`
- Exception handler trong `main.py` — NEVER leak `str(exc)` to client
- `HTTPException` chỉ cho 4xx client errors

## Config — pydantic-settings

```python
class Settings(BaseSettings):
    db_url: str
    jwt_secret: str
    internal_secret: str
    model_config = SettingsConfigDict(env_file=".env")
```

## Testing

- `TestClient` cho API contract
- Mock external deps (model API, DB)
- Run: `pytest tests/<file>::<test>` trước full suite
- Format: `black . ; isort .` trước commit
