---
trigger: always_on
---

# React + Vite Rules — HealthGuard/frontend

Áp dụng cho admin web frontend. Stack: Vite + React (JSX, not TypeScript per codebase verify).

## Project structure

```
src/
├── main.jsx           # ReactDOM.createRoot, App
├── App.jsx            # router root
├── pages/             # route-level components
├── components/        # reusable UI components
├── features/          # feature-specific (Redux slice, hooks, ...)
├── hooks/             # custom hooks
├── lib/               # api client, utils
├── store/             # state management (verify which: Redux/Zustand/Context)
└── assets/            # static images, fonts
```

> Verify cấu trúc thực tế trước khi áp dụng — codebase có thể đã evolve.

## Component patterns

- **Function component + hooks.** No class component cho code mới.
- **Props destructure trong signature**, default values ở đó.
- **Named export** cho component → easier refactor + tree shake.
- **`PropTypes` hoặc JSDoc** cho component props nếu codebase không TS.
- **Extract khi JSX > 80 dòng** hoặc có conditional rendering phức tạp.

## Hooks rules

- **Don't call hook trong condition/loop.**
- **Custom hook:** prefix `use*`. 1 concern per hook.
- **`useEffect` deps:** liệt kê đầy đủ, không suppress eslint warning.
- **`useMemo`/`useCallback`** chỉ khi profile cho thấy cần — premature optimization wastes time.

## State management

- **Local state:** `useState` / `useReducer`.
- **Global state:** verify codebase dùng Redux Toolkit / Zustand / Context. Match pattern hiện có.
- **Server state:** TanStack Query (react-query) nếu codebase có; fall back fetch + useEffect.

## API calls

- **Centralize trong `src/lib/api.js`** — base URL từ `import.meta.env.VITE_API_URL`.
- **Axios interceptor** cho JWT attach + 401 refresh.
- **Don't fetch trong component** — qua custom hook hoặc store action.

## Routing

- **react-router-dom** v6+. Routes trong `App.jsx` hoặc `routes.jsx`.
- **Protected route:** wrapper component check auth + redirect.

## Styling

- Verify codebase: Tailwind / CSS modules / styled-components / plain CSS.
- **Tránh inline style** trừ khi dynamic value.
- **Theme tokens** (color, spacing) tập trung 1 nơi — không hardcode hex code.

## Forms

- **React Hook Form** + **Zod** validation (recommended; verify dùng cái nào).
- **Don't store form state trong useState** cho form lớn — re-render hell.

## Charts (real-time health monitor)

- Verify thư viện: Recharts / Chart.js / Apex (codebase có chart cho dashboard).
- **Don't update chart mỗi second** — debounce/throttle.
- **Cleanup subscription** trong `useEffect` return.

## WebSocket (socket.io-client)

```jsx
useEffect(() => {
  const socket = io(API_URL, { auth: { token } });
  socket.on('vital_update', handleVital);
  return () => socket.disconnect();
}, [token]);
```

- **Don't create socket trong render.**
- **Reconnect handling** — codebase nên có wrapper hook.

## Build & env

- **Env vars:** prefix `VITE_*` để Vite expose. `import.meta.env.VITE_API_URL`.
- **`.env`** không commit, **`.env.example`** commit.
- **Build:** `npm run build` → `dist/`. Serve qua Nginx hoặc static host.

## Anti-patterns flag tự động

- `dangerouslySetInnerHTML` với user input → XSS
- `localStorage` chứa JWT/refresh token → XSS-vulnerable. Dùng httpOnly cookie thay.
- Massive prop drilling (≥ 4 levels) → dùng context/store
- Inline anonymous function trong list render → unnecessary re-render
- Missing `key` trong list, hoặc `key={index}` cho list có reorder
- `useEffect` không return cleanup khi cần (subscription, timer, listener)
- Direct DOM manipulation (`document.getElementById`) trừ khi thật sự cần

## Commands

- `npm install`
- `npm run dev` (Vite dev server, port 5173)
- `npm run build` (production build)
- `npm run preview` (preview build local)
- `npm run lint` (ESLint, check `eslint.config.js`)
