# 🔬 MODULE SUMMARY: ANALYSIS (Mobile)

> **Module**: ANALYSIS — Risk Scoring & AI Explainability  
> **Project**: Mobile App (health_system/)  
> **Sprint**: Sprint 4  
> **Trello Cards**: Sprint 4 Card 1 (Risk Report), Card 2 (Risk Detail)  
> **UC References**: UC016, UC017

---

## 📋 SRS Requirements (Extracted)

### Functional Requirements
- HG-FUNC-08: Calculate risk score based on: HRV (low) + SpO2 (low) + BP history
- HG-FUNC-09: Provide XAI explanation for high risk. Example: "High risk due to HR spike 120bpm while resting"
- Risk Score: 0-100, Level: LOW/MEDIUM/HIGH/CRITICAL
- XGBoost model with **22 features** (HRV, HR, BP, SpO2, demographics)
- Feature extraction from 24h vitals window
- Recalculate every **6 hours** (scheduled job)
- Cache: if score < 1h old → return cached, else → trigger new AI inference
- If HIGH/CRITICAL → auto-create alert (`alert_type='high_risk_score'`)

### AI Component
- Model: XGBoost
- Input: 22 features extracted from vitals + demographics
- Output: Risk score (0-100), risk level
- XAI: SHAP explainer (top 5 contributing factors)
- Internal API: `POST /ai/risk-scoring`

### Non-Functional Requirements
- Requires minimum **24 hours** of vitals data
- Cache results for 1 hour
- Permission: patient views own, caregiver with permission

---

## 📌 Trello Checklist (Pre-Extracted)

### Card 1 — View Risk Report (Mobile BE Dev)
- [ ] `GET /api/mobile/patients/{id}/risk-score/latest`
  - Res: `{score, level, calculated_at, explanation: {top_factors, text}}`
- [ ] Cache logic: score < 1h → cached, else → trigger AI
- [ ] `GET /api/mobile/patients/{id}/risk-score/history?from=&to=`
- [ ] Permission check (patient/caregiver)
- [ ] If HIGH/CRITICAL → create alert

### Card 1 — Risk Scoring (AI Dev)
- [ ] XGBoost model implementation
- [ ] Feature extraction from vitals (24h window)
- [ ] `POST /ai/risk-scoring` (internal API)
- [ ] SHAP explainer (top 5 factors)
- [ ] Store in `risk_scores` + `risk_explanations` tables
- [ ] Schedule job: every 6 hours

### Card 2 — Risk Detail (Mobile BE Dev)
- [ ] `GET /api/mobile/risk-scores/{id}`
- [ ] Query `risk_scores` + `risk_explanations`

### Mobile FE
- [ ] Risk Report screen: score display (0-100), color-coded, XAI section, trend chart
- [ ] Detail screen: feature importance visualization

---

## 📂 Source Code Files

### Backend (`health_system/backend/app/`)
| File Path | Role |
|-----------|------|
| `api/analysis/` | Risk scoring API routes |
| `services/risk_service.py` | Risk scoring business logic |

### Mobile (`health_system/lib/features/`)
| File Path | Role |
|-----------|------|
| Risk report screens (within features) | Risk display UI |

---

## 🔗 Cross-References

| Type | Reference |
|------|-----------|
| SRS Section | §4.2 HG-FUNC-08, HG-FUNC-09, §1.2 (XAI scope) |
| Use Case Files | `BA/UC/Analysis/UC016-UC017` |
| DB Tables | `risk_scores`, `risk_explanations`, `vitals` (source data) |

---

## 📊 Review Notes
| Key | Value |
|-----|-------|
| Review Date | — |
| Score | —/100 |
| Reviewer Notes | — |
