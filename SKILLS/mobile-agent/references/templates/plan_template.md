# 📐 UI Plan Template

> Use this template when running **mode PLAN**. Fill in specifics for each screen.
> Save the output file to: `PM_REVIEW/REVIEW_MOBILE/Screen/build-plan/[MODULE]_[ScreenName]_plan.md`

```markdown
# 📐 UI Plan: [Screen Name]

## 1. Description
- **SRS Ref**: UC0XX
- **User Role**: Patient / Caregiver
- **Purpose**: [1 sentence]

## 2. User Flow
1. User opens app → ...
2. User taps ... → ...
3. System displays ... → ...

## 3. UI States
| State   | Description       | Display               |
| ------- | ----------------- | --------------------- |
| Loading | Fetching data     | Skeleton shimmer      |
| Empty   | No data available | Illustration + CTA    |
| Success | Data loaded       | List/Card/Chart       |
| Error   | API/network error | Error message + Retry |

## 4. Widget Tree (proposed)
- `Scaffold`
  - `AppBar` → title, back button
  - `Body` → ...

## 5. Edge Cases Handled
- [ ] Network loss mid-operation
- [ ] Data too long / too short
- [ ] Accessibility (min font 16sp)

## 6. Dependencies
- Shared widgets needed: [list]
- API endpoints: [list]

## 7. Confidence Score
- **Plan Confidence: X%**
- Reasoning: [Brief explanation of confidence level]
- Uncertainties: [List any areas where more info would help]
```
