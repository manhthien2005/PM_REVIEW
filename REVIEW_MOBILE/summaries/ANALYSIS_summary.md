# ANALYSIS (Mobile)

> Sprint 4 | JIRA: EP13-RiskScore | UC: UC016, UC017

## Purpose & Technique
- XGBoost model with 22 features (HRV, HR, BP, SpO2, demographics) → risk score 0-100
- SHAP explainer for top 5 contributing factors (XAI)
- Recalculate every 6h (scheduled job), cache 1h, auto-alert on HIGH/CRITICAL

## API Index
| Endpoint                                     | Method | Note                       |
| -------------------------------------------- | ------ | -------------------------- |
| /api/mobile/patients/{id}/risk-score/latest  | GET    | Cache 1h, XGBoost model    |
| /api/mobile/patients/{id}/risk-score/history | GET    | Risk history               |
| /api/mobile/risk-scores/{id}                 | GET    | Risk detail + SHAP factors |
| /ai/risk-scoring                             | POST   | Internal AI inference      |

## File Index
| Path                    | Role                             |
| ----------------------- | -------------------------------- |
| lib/features/           | No analysis-specific feature dir |
| backend/app/api/routes/ | No analysis route file exists    |
| backend/app/services/   | No risk_service.py exists        |

## Known Issues
- 🔴 Module NOT implemented — no Flutter or backend code exists

## Cross-References
| Type      | Ref                                    |
| --------- | -------------------------------------- |
| DB Tables | risk_scores, risk_explanations, vitals |
| UC Files  | BA/UC/Analysis/UC016-UC017             |
