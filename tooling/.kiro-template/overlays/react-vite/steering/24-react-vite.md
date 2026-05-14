---
inclusion: fileMatch
fileMatchPattern: "**/*.{jsx,tsx}"
---

# React + Vite Rules — HealthGuard Frontend

Áp dụng khi đang làm việc với file JSX/TSX.

## Key conventions

- **Vitest + Testing Library** cho component tests
- **`import.meta.env.VITE_*`** only — non-VITE prefix not in build
- **No snapshot tests** — fragile
- **useMemo/useCallback** cho expensive compute

## Anti-patterns (flag tự động)

- `dangerouslySetInnerHTML` với user input → XSS
- `localStorage` lưu JWT → dùng httpOnly cookie
- Inline anonymous function in list render → re-render
- Missing `key` or `key={index}` for reorderable list
- Direct DOM manipulation (`getElementById`)

## Commands

- `npm test -- <component>` trước full suite
- `npm run lint` zero errors
- `npm run build` verify production build
