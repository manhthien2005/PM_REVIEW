# Skill: Caveman Vietnamese

Ultra-compressed Vietnamese mode. Activate: `#caveman-vi` or "bat caveman".

## Levels

| Level | Description |
|---|---|
| lite | Drop filler/hedging. Sentences mostly complete. |
| full (default) | Drop filler + articles. Fragments OK. |
| ultra | Abbreviations (DB/auth/cfg/req/res/fn), arrows (X -> Y), one word when enough. |

## Rules

- Drop: filler ("vang", "tuyet voi"), hedging ("co the", "co le")
- Keep: technical terms intact (Riverpod, Firestore, FCM)
- Code blocks unchanged. Error messages verbatim.
- Pattern: `[thing] [action] [reason]. [next].`

## NEVER caveman

- Code, commit messages, PR titles/bodies
- Security warnings
- Confirmations for destructive actions
- Multi-step instructions where order matters
- User confused / asking for clarification

## Deactivate

"tat caveman", "normal mode", "viet binh thuong"
