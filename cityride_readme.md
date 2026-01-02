# CityRide: Data Infrastructure & Operational Optimization for Ride-Sharing Growth

CityRide generated strong operations in November 2024 but faced suboptimal promotion strategy and critical data quality issues. This project identifies a **$1,307.87/month revenue opportunity** through intelligent promotion redesign and uncovers a **compliance risk affecting 16 drivers (16% of fleet)**.

**Tools Used:** R, PostgreSQL, Tableau  
**Data Period:** November 2024 (1,200+ rides across 5 U.S. cities)
**Full Business Case:** You can read the complete document with all the process and conclusions [here](https://docs.google.com/document/d/1fddXVlV6fQBr0umGHUAio6tUC8fIrdYKUXU8z2GFzKg/edit?usp=sharing)

---

## 1. Business Context

CityRide was preparing for rapid scale-up but faced three critical problems:
- **Data Infrastructure:** Operating from flat CSV files with no relational structure
- **Promotion Confusion:** Running three discount tiers without understanding customer value drivers
- **Zero Visibility:** No framework to catch data quality issues before they become compliance nightmares

---

## 2. Dataset & Metrics

**Star Schema Design:**
- **Fact Table:** `Fact_Ride` (1,200+ transactions)
- **Dimensions:** Driver (100), Date (30 days), City (5), Promotion (4 tiers)

**Key Metrics:** 1,200+ rides | Avg fare $44.70 | Avg rating 4.26/5 | Avg distance 25.2 km


<img width="812" height="617" alt="Image" src="https://github.com/user-attachments/assets/6d6ff2ef-52a7-4258-a467-dd76a3ed50aa" />

---

## 3. Key Insights & Impact

### Insight 1: Promotion Strategy Disconnect ($1,307.87/month opportunity)

**Finding:** All three discount codes (5%, 10%, 20%) are used in nearly equal proportions. Theory predicts higher discounts should drive higher volume—they don't.

**Root Cause:** Customers value the *presence* of a discount, not its monetary value.

**Recommendation:** Replace the unprofitable 20% "SAVE20" discount with 10% offer.

| Metric | Amount |
|--------|--------|
| Current revenue (SAVE20 rides) | $10,462.95 |
| Hypothetical revenue (10% instead) | $11,770.82 |
| **Monthly opportunity** | **$1,307.87** |
| Annual impact | $15,694 |

---

### Insight 2: Critical Compliance Risk

**Finding:** 16 drivers (16% of fleet) report age/experience combinations that violate legal working requirements. 8 drivers appear licensed before age 16.

**Business Impact:** Reputational catastrophe if discovered publicly + regulatory liability.

**Recommendation:** Immediate audit with authorities + overhaul background check procedures.

---

### Insight 3: City-Level Pricing Anomaly

Chicago shows 9.3% higher average fare ($48.7 vs. $43-44) despite similar distances and ratings. Likely supply-side constraint—opportunity for driver recruitment targeting.

---

## 4. Deliverables

### Data Infrastructure

Migrated from flat CSV to PostgreSQL star schema:
- 40% storage reduction (integer keys vs. repeated text)
- Efficient indexing for 10x data volume scalability
- Foundation for historical tracking and cohort analysis

### Tableau Dashboard (2 pages)

You can access the dashboard using this [link](https://public.tableau.com/app/profile/juan.fernando.moyano.ram.rez/viz/CityRides_17660962208610/CityRidesHistory)

**Page 1 - Operations Overview:**
- KPIs: Revenue, Rides, Avg Fare, Rating, Distance
- Daily volume & pricing trends
- Promotion effectiveness by day type
- Driver performance audit table
  

<img width="1628" height="692" alt="Image" src="https://github.com/user-attachments/assets/5e9e6c43-3a1b-4efd-8cca-a7a74d3c3788" />

**Page 2 - Geographic Analysis:**
- City-level ride distribution map
- Revenue vs. volume scatter (outlier detection)
- Distance vs. duration correlation


<img width="1258" height="732" alt="Image" src="https://github.com/user-attachments/assets/36f095e4-27ab-438a-b7ff-35f2391e27b4" />

---

## 5. Action Plan

**Immediate (Q4 2024 - Q1 2025):**
- [ ] Replace SAVE20 with SAVE10 promotion
- [ ] Monitor weekly churn for 4 weeks (trigger threshold: >5% drop)
- [ ] Audit 16 flagged drivers with authorities
- [ ] Deploy dashboard for management review

**Short-Term (Q1-Q2 2025):**
- [ ] Implement tipping feature for driver retention
- [ ] Investigate Chicago supply constraints
- [ ] Extend data to 12+ months for seasonality analysis

**Future (2026):**
- [ ] Predictive CAC modeling
- [ ] Cohort retention analysis
- [ ] Dynamic pricing optimization

---

## 6. Limitations

- **Single month only** - November 2024 captured pre-holiday patterns; seasonal bias limits generalization
- **Sample size risk** - 30 days at minimum CLT threshold for inferential statistics
- **Missing data** - No intraday timestamps, start/end locations, or rider demographics (GDPR-compliant but analytically limiting)
- **Quality issues** - Drivers with geographically impossible trips on same day; age/experience mismatches suggest faulty data capture
