# Data Governance for SDG Monitoring: Lessons from the UNICEF Experience

## A Primer on Inter-Agency Custodianship Processes

[**Document Status**: Living document | **Last Updated**: January 2026 | **Version**: 2.0]

> **Purpose**: This document distills governance lessons from UNICEF's custodianship of child-focused SDG indicators. It serves both as (1) **authoritative technical reference** for the `unicefData` package, and (2) **transferable framework** for data governance in multisectoral SDG monitoring. All claims are traceable to official sources.

**Intended Audiences**:
- **Statistical practitioners**: NSO staff, international agency methodologists, academic researchers
- **Data governance specialists**: SDG custodian agencies, regional statistical organizations, open data advocates
- **Policy analysts**: Program managers, M&E specialists, development practitioners
- **R/Stata users**: Quantitative analysts working with UNICEF data via `unicefData` package

---

## UNICEF's Unique Positioning: A Multisectoral Comparative Perspective

### Why UNICEF Offers Distinctive Governance Insights

**Institutional Context**: Unlike specialized agencies with single-sector mandates (WHO for health, UNESCO for education, UNFPA for population), UNICEF operates across **six interdependent domains**:

1. **Child Survival and Health**: Mortality (UN-IGME), immunization (WUENIC), HIV/AIDS (paediatric)
2. **Nutrition**: Malnutrition (JME), micronutrients, infant feeding practices
3. **Water, Sanitation, Hygiene**: Household and institutional WASH (JMP)
4. **Education**: Early learning (ECDI2030), out-of-school children, learning poverty
5. **Child Protection**: Child marriage, FGM, child labour, violence, birth registration
6. **Social Protection**: Child poverty, cash transfers, social spending

**Strategic Advantage of Multisectoral Breadth**: This uniquely positions UNICEF to:

**1. Compare governance models across domains**
   - Health, education, WASH, and protection exhibit different:
     - **Data ecosystems**: Vital registration (mortality) vs surveys (nutrition) vs administrative systems (immunization) vs institutional censuses (WASH)
     - **Methodological constraints**: Modeling feasibility (high for mortality/nutrition; low for protection) vs direct measurement (WASH, child marriage)
     - **Stakeholder politics**: Politically salient mortality trends vs lower-profile WASH access vs culturally sensitive harmful practices
   
**2. Identify transferable best practices across initiatives**
   - IGME's transparent TAG model (annual public reports) → adapted for JMP governance redesign
   - JME's equity disaggregation strategies (wealth quintiles, subnational) → influenced child protection monitoring
   - WUENIC's triangulation approach (admin + survey reconciliation) → being adapted for education administrative data validation
   
**3. Navigate complex inter-agency partnerships** with:
   - **WHO**: 4 major co-custodianships (IGME, JME, JMP, WUENIC)
   - **World Bank**: JME, IGME (economic/equity analytics, poverty linkages)
   - **UN DESA Population Division**: IGME (demographic inputs, census coordination)
   - **UNESCO-UIS**: Education (MICS module design, out-of-school children methodology)
   - **UNFPA**: Child marriage, FGM (joint programs; UNICEF retains SDG custodianship)
   - **UNAIDS**: HIV/AIDS (paediatric/adolescent indicators via GAM framework)
   - **ILO**: Child labour (MICS data contributions to SIMPOC)
   
**4. Bridge programmatic and statistical communities**
   - Unlike pure statistical agencies (UN DESA, UNESCO-UIS) or norm-setting bodies (WHO), UNICEF combines:
     - **Statistical custodianship**: 14 lead SDG indicators + 8 co-led
     - **Country program implementation**: 190+ country offices, $5.2 billion annual budget (2023)
     - **Survey infrastructure**: MICS (Multiple Indicator Cluster Surveys) — 330+ surveys in 110+ countries since 1995
   - This creates **feedback loops**:
     - Program staff identify data gaps (e.g., "subnational nutrition data needed for cash transfer targeting")
     - Country validation improves estimates (e.g., "mortality trend inconsistent with our sentinel surveillance—new data provided")
     - Regional advisors translate global methodologies into local contexts

### Comparative Lens: Cross-Sectoral Governance Patterns

**Insight**: Optimal governance varies by data type and political economy—not one-size-fits-all.

| **Governance Element** | **Health (IGME, WUENIC)** | **WASH (JMP)** | **Child Protection (CM, FGM)** |
|------------------------|---------------------------|----------------|--------------------------------|
| **Primary Data Source** | Surveys + vital registration | Surveys + census | Surveys (retrospective reporting) |
| **Country Ownership Model** | Moderate (agencies model; countries validate) | High (NSO data preferred if quality met) | High (survey-driven; NSO collaboration essential) |
| **TAG Transparency** | High (IGME: annual public reports) | Moderate (workshop reports on washdata.org) | Low (no formal TAG; rely on DHS/MICS peer review) |
| **Methodological Complexity** | High (Bayesian models, triangulation) | Moderate (service ladder classification) | Low (direct prevalence from microdata; minimal modeling) |
| **Political Sensitivity** | High (mortality trends politically salient) | Moderate (WASH access less politicized) | Very High (harmful practices; cultural context crucial) |
| **Optimal Governance Fit** | Independent TAG + transparent methods + annual cycles | Collaborative NSO workshops + code transparency | Survey program ethics + regional consultation + longer cycles |

**Lesson**: 
- **Health data** → benefits from modeling expertise and independent oversight (hence IGME's TAG with academic statisticians)
- **WASH data** → prioritizes country ownership and NSO collaboration (hence JMP's participatory workshops)
- **Protection data** → requires cultural sensitivity and ethical safeguards (hence reliance on established DHS/MICS protocols, not top-down modeling)

### Strategic Implications for SDG Data Governance

**1. Multisectoral Agencies as Governance Laboratories**

UNICEF's breadth enables **comparative experimentation**:
- Test governance models (independent TAG vs collaborative workshops vs external peer review) across domains
- Adapt successful patterns (IGME's TAG transparency became template for WHO initiatives)
- Identify domain-specific constraints that prevent one-size-fits-all approaches

**Recommendation**: SDG custodian agencies should document governance choices explicitly and share lessons via IAEG-SDGs network. UN Statistics Division could facilitate annual "governance innovation" sessions.

**2. Inter-Agency Coordination Mechanisms (Replicable Patterns)**

UNICEF partnerships demonstrate **formalized coordination**:
- **Memoranda of Understanding (MoUs)**: Specify division of labor (UNICEF: country consultation; WHO: normative/technical lead), decision rules (consensus; TAG adjudicates disputes), branding (joint logos), release coordination
- **Technical Working Groups**: Rotating chairs; quarterly calls; aligned methodological development
- **Comparative Advantage**: UNICEF's country presence (190+ offices) vs WHO's normative authority vs World Bank's economic analytics vs UN DESA's demographic expertise

**Recommendation**: IAEG-SDGs should template MoU structures for co-custodianship, reducing transaction costs for new partnerships.

**3. Country Presence as Feedback Loop**

UNICEF's field presence creates **bidirectional communication**:
- **Bottom-up**: Program staff signal data gaps; country offices validate during consultation
- **Top-down**: Global methodologies adapted to country contexts by regional advisors

**Lesson**: Data governance benefits from tight coupling between custodian agencies and country users. Agencies without field presence should establish structured user feedback mechanisms (e.g., annual country consultations, user advisory panels).

**4. Equity as Institutionalized Governance Principle**

UNICEF's CRC (Convention on the Rights of the Child) mandate institutionalizes equity:
- **Disaggregation policies explicit** (not ad hoc): Each initiative publishes availability matrices
- **MICS designed for equity analysis** from inception: Sampling frames, oversampling vulnerable groups
- **Methodological investments prioritized**: Small-area estimation for subnational data; disability modules

**Lesson for SDGs**: "Leave No One Behind" requires equity-focused governance:
- Custodian agencies should publish disaggregation availability matrices (wealth, sex, disability, subnational)
- IAEG-SDGs should track disaggregation coverage as data quality metric
- Statistical capacity development should prioritize survey design for equity (not only national averages)

---

## Executive Summary

### The Data Governance Challenge in SDG Monitoring

**Context**: Tracking progress on child-focused SDGs requires harmonized, comparable statistics across 195+ countries, spanning multiple decades and diverse data ecosystems (vital registration, surveys, administrative systems).

**Challenge**: Three persistent barriers compromise SDG data quality:
1. **Fragmentation**: National data systems use heterogeneous definitions, age groupings, and denominators—preventing cross-country comparability
2. **Incompleteness**: 60% of countries lack complete vital registration; 40% missing recent nutrition surveys; institutional WASH data cover only 30-50% of countries
3. **Methodological inconsistency**: Estimation approaches vary (direct measurement, modeling, triangulation), obscuring which differences reflect real trends vs methodological artifacts

### The Custodianship Solution

Inter-agency processes led or co-led by UNICEF establish **five governance pillars**:

1. **Standardization**: Harmonized indicator definitions, code lists, and SDMX-compliant dissemination
2. **Methodological Rigor**: Peer-reviewed estimation methods; documented uncertainty quantification; public code repositories
3. **Independent Oversight**: Technical Advisory Groups (TAGs) with external academics and NSO representatives
4. **Country Consultation**: Systematic validation windows (6 weeks for IGME; annual JRF for WUENIC) before public release
5. **Transparency**: Methods sheets, change logs, TAG reports, and data provenance attributes (SOURCE, OBS_STATUS, CONF_INT)

### Key Governance Lessons for SDG Monitoring

**Lesson 1: Governance Must Adapt to Data Maturity**
- High-maturity domains (child mortality, immunization): Support complex modeling, annual cycles, rigorous uncertainty quantification
- Low-maturity domains (child protection, institutional WASH): Require conservative approaches, longer cycles, explicit data gap reporting
- *Implication*: IAEG-SDGs Tier classification should inform governance intensity (Tier I indicators justify more elaborate TAG structures)

**Lesson 2: Transparency Is the Currency of Legitimacy**
- Public TAG reports (IGME) and code repositories (JMP) build user trust
- Opaque expert judgment (WUENIC triangulation narrative) invites skepticism
- *Implication*: Custodian agencies should default to public documentation; classify only when confidentiality or security concerns justify

**Lesson 3: Country Consultation Balances Global Comparability and National Sovereignty**
- Formal consultation windows (IGME: 6 weeks; WUENIC: JRF cycle) allow NSOs to validate, contest, or supplement estimates
- Dual reporting (UN estimate + national official estimate) respects both mandates
- *Implication*: IAEG-SDGs should template consultation protocols to reduce agency-specific transaction costs

**Lesson 4: Disaggregation Requires Domain-Specific Strategies**
- Wealth quintiles feasible for survey-based indicators (JME, JMP) but not administrative data (WUENIC)
- Sex disaggregation constrained by vital registration gaps (IGME) or cultural sensitivity (FGM)
- *Implication*: "Leave No One Behind" cannot be operationalized uniformly; agencies must publish explicit disaggregation matrices

**Lesson 5: Inter-Agency Coordination Needs Formal Mechanisms**
- Memoranda of Understanding (MoUs) specify division of labor for co-custodianship
- Joint technical working groups with rotating chairs prevent duplication
- Aligned release cycles maximize policy uptake
- *Implication*: IAEG-SDGs should provide MoU templates and facilitate coordination "clinics" for new partnerships

### Constituency and Value Proposition

**Data Suppliers** (NSOs, Ministries of Health, sector agencies):
- Benefit: Reduced reporting burden (harmonized definitions); capacity building (MICS training, estimation methods)
- Expectation: Timely feedback during consultation; dual reporting of national vs harmonized estimates

**Methodological Stewards** (UNICEF, WHO, World Bank, UN DESA, UNESCO-UIS, UNAIDS):
- Benefit: Shared technical infrastructure (SDMX, code lists); reputational gains from peer-reviewed methods
- Expectation: Transparent governance; adherence to FPOS (Fundamental Principles of Official Statistics)

**Data Users** (policymakers, researchers, program managers, civil society):
- Benefit: Comparable time series; documented uncertainty; equity disaggregation (where feasible)
- Expectation: Accessible data (APIs, bulk downloads); clear guidance on appropriate use (see Guardrails section)

### Relevance to Official Statistics Frameworks

UNICEF custodianship processes align with:
- **IAEG-SDGs Custodianship Model**: UNICEF leads 14 SDG indicators; co-leads 8 (with WHO, World Bank, UNFPA)
- **Generic Statistical Business Process Model (GSBPM)**: All eight phases mapped (see Alignment section)
- **Data Quality Assessment Framework (DQAF)**: Five dimensions implemented (integrity, methodological soundness, accuracy, serviceability, accessibility)
- **UN Fundamental Principles of Official Statistics (FPOS)**: All 10 principles operationalized (see FPOS section)

**Status**: While not all outputs are designated "official statistics" (which are produced by NSOs under national legislation), custodianship processes **aspire to FPOS standards** and **support national statistical systems**—bridging global monitoring needs with national sovereignty.

---

## Core Custodianship Processes

### 1. UN Inter-agency Group for Child Mortality Estimation (UN-IGME)

**Established**: 2004 | **Current Scope**: Under-5, infant, neonatal, child (5-14), youth (15-24) mortality; stillbirths

**Co-Custodians**: UNICEF, WHO, UN DESA Population Division, World Bank Group

**Problem Addressed**: 
- Fragmented vital registration systems (only ~40% of countries with complete death registration)
- Survey-based estimates with sampling variability and coverage gaps
- Lack of harmonized age definitions and denominators across data sources

**Methodological Framework**:
- Bayesian penalized B-splines model for time series smoothing
- Bias-adjustment procedures for survey data vs vital registration
- Systematic country consultation process before release
- Uncertainty quantification via Markov Chain Monte Carlo (MCMC)
- Methods documented in peer-reviewed publications (see References)

**Governance Structure**:
- Annual Technical Advisory Group (TAG) meetings
- Country consultation rounds (6-week window for data validation)
- Transparent change-log for methodological updates
- Public release of estimation code (R packages)

**Outputs**:
- CME Database (1950-present): 17,800+ time series
- Country-specific methods sheets (195 countries)
- Global/regional aggregates with 80% and 90% uncertainty intervals
- API access via UNICEF Data Warehouse (SDMX 2.1 compliant)

**Data Quality Indicators**:
- Completeness: Coverage of 195 UN member states
- Consistency: Cross-validated against census and DHS/MICS
- Timeliness: Annual releases (September)
- Uncertainty: Confidence intervals published for all modelled estimates

**References**:
- Portal: https://childmortality.org/
- Methods: https://childmortality.org/methods
- 2023 TAG Report: https://childmortality.org/wp-content/uploads/2024/01/TAG-2023-Report.pdf

---

### 2. Joint Child Malnutrition Estimates (JME)

**Established**: 2000s (formalized 2012) | **Current Scope**: Stunting, wasting, severe wasting, underweight, overweight (children <5 years)

**Co-Custodians**: UNICEF, WHO, World Bank Group

**Problem Addressed**:
- Heterogeneous anthropometric measurement protocols
- Inconsistent age groupings (0-59 months vs 6-59 months)
- Limited trend analysis due to single-survey snapshots
- Gaps in primary data (40% of countries lack recent surveys)

**Methodological Framework**:
- WHO Child Growth Standards (2006) as reference
- Standardized data inclusion criteria (survey quality, sample size >1000)
- Multilevel regression models for regional/global aggregates
- Country-specific empirical best linear unbiased prediction (EBLUP) for smoothing
- Methods peer-reviewed in *Lancet Global Health*, *PLOS Medicine*

**Governance Structure**:
- Biennial release cycle (odd years)
- Country consultation via UNICEF Regional Offices
- External technical review by academic partners
- Documentation of exclusions (surveys failing quality criteria)

**Outputs**:
- JME Database (1985-present): 3,500+ country-year observations
- Interactive dashboards: https://data.unicef.org/resources/jme/
- SDG 2.2 monitoring brief (annual)
- Microdata harmonization protocols (MICS, DHS, national surveys)

**Data Quality Indicators**:
- Timeliness: Biennial updates within 12 months of survey release
- Accuracy: Cross-validation against WHO Growth Curve data
- Disaggregation: Sex available for 95% of estimates; wealth/residence for 70%
- Uncertainty: Standard errors for national estimates; confidence intervals for trends

**References**:
- Portal: https://data.unicef.org/resources/jme/
- Methods: UNICEF (2023). *JME Methodology Note*. Available at JME portal
- Peer-reviewed: Heidkamp et al. (2021). *Lancet Global Health* 9(5):e510-e521

---

### 3. WHO/UNICEF Joint Monitoring Programme for Water Supply, Sanitation and Hygiene (JMP)

**Established**: 1990 (MDG era) | **Scope**: Household and institutional WASH (schools, health facilities)

**Co-Custodians**: WHO, UNICEF

**Problem Addressed**:
- Absence of standardized WASH service ladders (basic, limited, unimproved, open defecation)
- Inability to track SDG 6.1/6.2 targets without harmonized definitions
- Inequality dimensions (urban/rural, wealth, subnational) inconsistently reported

**Methodological Framework**:
- JMP service ladders (2017 update for SDG era)
- Harmonized questionnaire modules for MICS/DHS/national censuses
- Inequality analysis framework (Theil index, ratios)
- Methods endorsed by UN-Water Technical Advisory Group

**Governance Structure**:
- Documented "How we work" governance page: https://washdata.org/how-we-work
- Collaboration with NSOs via regional workshops
- Bi-annual global reports with thematic deep-dives
- Public GitHub repository for estimation code

**Outputs**:
- Global WASH Database: 5,300+ national datasets
- 2000-2022 time series for 200+ countries
- Institutional WASH series (schools: 2016-present; health: 2019-present)
- SDG 6 Synthesis Reports (2018, 2021, 2024)

**Data Quality Indicators**:
- Coverage: 99% of countries with at least one household survey
- Consistency: JMP ladder definitions applied retroactively to historical data
- Transparency: All estimates linked to source surveys (traceable via washdata.org)
- Granularity: Subnational for 80 countries; inequality metrics for 120+ countries

**References**:
- Portal: https://washdata.org/
- Governance: https://washdata.org/how-we-work
- Methods: WHO/UNICEF (2021). *Progress on household drinking water, sanitation and hygiene 2000-2020*

---

### 4. WHO/UNICEF Estimates of National Immunization Coverage (WUENIC)

**Established**: 2000 | **Scope**: Routine immunization coverage (BCG, DTP, polio, measles, HepB, Hib, PCV, RV, HPV)

**Co-Custodians**: WHO Immunization, Vaccines and Biologicals (IVB), UNICEF

**Problem Addressed**:
- Discrepancies between administrative coverage (numerator/denominator issues) and survey-based estimates
- Lack of harmonized validation rules for implausible values (>100% coverage)
- Need for time-series consistency despite changing denominators (birth cohorts)

**Methodological Framework**:
- Triangulation of administrative data, survey results (DHS/MICS/national), and sentinel surveillance
- Expert review by WHO Regional Offices and UNICEF Country Offices
- Validation rules: cap at 99%, flag outliers, document revisions
- Methods documented in annual WUENIC methodology paper (submitted to *Vaccine*)

**Governance Structure**:
- Annual country consultation (via WHO/UNICEF Joint Reporting Form)
- Regional Immunization Technical Advisory Groups (RITAGs)
- Transparent Q&A on discrepancies: https://www.who.int/teams/immunization-vaccines-and-biologicals/immunization-analysis-and-insights/global-monitoring/immunization-coverage/who-unicef-estimates-of-national-immunization-coverage
- Public release of estimate justifications (country-specific notes)

**Outputs**:
- WUENIC Database (1980-present): 20,000+ time series
- Coverage time series for 190+ vaccines × countries
- Immunization Agenda 2030 (IA2030) dashboards
- API access via WHO GHO and UNICEF Data Warehouse

**Data Quality Indicators**:
- Timeliness: Released by July for previous year
- Accuracy: Triangulation reduces bias vs single-source reliance
- Transparency: All revisions documented with justification
- Comparability: Standardized age cohorts (1-year-olds for most vaccines)

**References**:
- Portal: https://immunizationdata.who.int/
- GHO theme: https://www.who.int/data/gho/data/themes/immunization
- Methods: Burton et al. (2009). *Bulletin WHO* 87(7):535-541

---

## Comparative Analysis: Governance Arrangements Across Custodianship Processes

**Purpose**: This table enables systematic comparison of institutional design, methodological choices, and transparency mechanisms across initiatives. Use it to:
- Assess fitness-for-purpose of governance for different indicator types
- Identify best practices (e.g., JMP's public code repositories, IGME's detailed country methods sheets)
- Understand trade-offs (e.g., annual vs biennial cycles, modeling vs direct measurement)

### Table: Governance, Methods, and Transparency by Initiative

| **Dimension** | **IGME** | **JME** | **JMP** | **WUENIC** |
|---------------|----------|---------|---------|------------|
| **Lead Agencies** | UNICEF, WHO, UN DESA, World Bank | UNICEF, WHO, World Bank | WHO, UNICEF | WHO IVB, UNICEF |
| **Established** | 2004 | 2000s (formalized 2012) | 1990 | 2000 |
| **SDG Indicators** | 3.2.1, 3.2.2 | 2.2.1, 2.2.2 | 6.1.1, 6.2.1 | 3.b.1 |
| **Primary Data Sources** | Surveys (DHS/MICS), vital registration, census | Surveys (DHS/MICS/national) | Surveys, census, admin | Admin (JRF), surveys (DHS/MICS) |
| **Methodological Approach** | Bayesian B-spline modeling | EBLUP smoothing, regression | Service ladder classification | Triangulation (admin + survey) |
| **Direct Measurement?** | No (modeled for time series) | Partial (survey years direct; trends modeled) | Yes (household); Partial (institutional) | Yes (admin); Validation via survey |
| **Uncertainty Quantification** | 80% and 90% CI (MCMC) | Standard errors for national; CI for trends | None (service ladder is classification) | None (triangulation narrative) |
| **TAG Structure** | Annual TAG meetings; independent academics + NSO reps | External technical review (LSHTM, JHU); biennial | UN-Water TAG; regional workshops | RITAGs (Regional Immunization TAGs) |
| **TAG Reports Public?** | Yes (childmortality.org/TAG) | No (internal review) | Workshop reports on washdata.org | RITAG summaries (WHO regions) |
| **Country Consultation** | 6-week window; online portal for feedback | Via UNICEF Regional Offices; validation letters | Regional data workshops; NSO collaboration | Joint Reporting Form (JRF); annual cycle |
| **Consultation Binding?** | No (agencies retain final decision; explain divergences) | No (agencies adjudicate) | Collaborative (NSO data preferred if quality met) | Hybrid (JRF data default; agencies adjust if implausible) |
| **Release Cycle** | Annual (September) | Biennial (odd years, May) | Biennial report; annual database updates | Annual (July for previous year) |
| **Code Availability** | R package in development (`CME.Assistant`) | On request (academic partners) | Public (GitHub for classification scripts) | Not routinely public |
| **Disaggregation: Sex** | Limited (only for countries with vital registration) | 95% of estimates | Not applicable (household-level) | Not systematically collected |
| **Disaggregation: Wealth** | Thematic reports only (not routine) | 60% of countries (DHS/MICS microdata) | 120+ countries (quintiles) | Surveys only (not WUENIC core) |
| **Disaggregation: Subnational** | ~25 countries (separate dataflow) | Not routine | 80 countries (Admin-1 level) | District-level for select countries |
| **Peer-Reviewed Methods** | Yes (Alkema 2014; multiple *Lancet* papers) | Yes (Heidkamp 2021, *Lancet Global Health*) | Yes (WHO/UNICEF JMP reports; academic collaborations) | Yes (Burton 2009, *Bulletin WHO*) |
| **Revision Policy** | Documented in TAG reports; change log public | Annex lists survey inclusions/exclusions | "What's new" on washdata.org | Revision notes in WHO GHO metadata |
| **Quality Flags (SDMX)** | OBS_STATUS:E (estimated); CONF_INT provided | OBS_STATUS:E (modeled years); Stat:A (survey years) | OBS_STATUS:A (observed); FLAG for provisional | OBS_STATUS:A (admin); FLAG if adjusted |
| **Historical Depth** | 1950-present | 1985-present | 2000-present (SDG-aligned); 1980s (MDG era, different definitions) | 1980-present |
| **Coverage (Countries)** | 195 UN member states | ~150 with recent data | 200+ | 190+ |
| **API/SDMX Access** | UNICEF Data Warehouse (SDMX 2.1) | UNICEF Data Warehouse | JMP API + washdata.org bulk download | WHO GHO API + UNICEF Data Warehouse |
| **Key Strength** | Temporal consistency via modeling; long time series | Sex/wealth disaggregation; equity focus | Service ladder framework; inequality metrics | Timeliness (annual); triangulation reduces bias |
| **Key Limitation** | Limited disaggregation; model assumptions | Biennial cycle; data gaps in fragile states | Institutional WASH data sparse | Administrative data denominator issues; no sex disaggregation |

### Analytical Insights from Comparative Table

**Governance Models**:
- **Independent TAG with Public Reports** (IGME): Highest transparency; external accountability mechanism
- **Academic Partnership Review** (JME): Rigorous but less public; peer-review proxy
- **Multi-Stakeholder Workshops** (JMP): Collaborative model; emphasizes NSO ownership
- **Regional TAGs** (WUENIC): Decentralized expertise; context-specific validation

**Methodological Trade-offs**:
- **Modeling for Comparability** (IGME, JME): Enables time-series consistency and gap-filling; introduces model uncertainty
- **Direct Measurement** (JMP household, WUENIC admin): Higher face validity; limited to data availability
- **Triangulation** (WUENIC): Balances admin timeliness with survey accuracy; requires expert judgment

**Transparency Spectrum**:
- **Most Transparent**: JMP (public code, collaborative governance) > IGME (public TAG reports, detailed methods sheets)
- **Moderate**: JME (peer-reviewed methods, survey documentation)
- **Least Transparent**: WUENIC (expert-based triangulation narrative; no systematic code release)

**Disaggregation Priorities**:
- **Equity-Focused**: JME, JMP (wealth quintiles, subnational)
- **Sex Disaggregation Constrained**: IGME (vital registration gaps), WUENIC (not mandated)
- **Institutional Data Emerging**: JMP (schools, health facilities; limited coverage)

**User Guidance**:
- For **equity analysis**: Prioritize JME and JMP (wealth disaggregation routine)
- For **time-series modeling**: Use IGME (longest series, methodological continuity)
- For **real-time monitoring**: Use WUENIC (annual cycle, admin data timeliness)
- For **comparability across sources**: Check OBS_STATUS attribute (modeled vs observed)

> **For detailed disaggregation availability by initiative, see [Disaggregation Policies by Initiative](#disaggregation-policies-by-initiative).**

---

## Transferable Governance Lessons for SDG Monitoring

### Lesson 1: Match Governance Intensity to Data Maturity and Political Sensitivity

**Principle**: Governance structures should be proportionate to (a) data ecosystem maturity, and (b) political stakes of the indicator.

**Evidence from UNICEF Experience**:

| **Data Maturity** | **Political Sensitivity** | **Appropriate Governance** | **Example** |
|-------------------|--------------------------|----------------------------|-------------|
| High | High | Independent TAG + public reports + annual country consultation | IGME (mortality trends politically salient; TAG detects methodological weaknesses) |
| High | Moderate | Expert triangulation + transparent Q&A + annual validation | WUENIC (immunization less politicized; triangulation narrative sufficient if documented) |
| Moderate | Moderate | Academic peer review + biennial updates + regional workshops | JME (nutrition data gaps require conservative release cycle; peer review ensures rigor) |
| Moderate | Low | Collaborative NSO workshops + public code repositories | JMP (WASH less politicized; NSO ownership prioritized over external oversight) |
| Low | High | Survey program quality control + no modeling + cultural consultation | Child protection (harmful practices culturally sensitive; modeling inappropriate; rely on DHS/MICS ethical protocols) |

**Operational Guidance**:
1. **Conduct governance risk assessment** before designing custodianship structure:
   - Data maturity: Assess vital registration coverage, survey frequency, sample sizes
   - Political sensitivity: Consult NSOs and country offices on indicator politicization
   
2. **Avoid over-engineering governance for low-stakes, low-maturity indicators**:
   - Example: Child labour prevalence (low data maturity due to measurement challenges; moderate political sensitivity)
   - Appropriate governance: Transparent documentation of survey limitations; no modeling; reliance on ILO SIMPOC/MICS protocols
   - Inappropriate governance: Complex Bayesian models with TAG oversight (would introduce model uncertainty without commensurate data quality gains)
   
3. **Escalate governance when political stakes increase**:
   - Example: Immunization coverage during COVID-19 pandemic (heightened scrutiny)
   - WUENIC response: Increased transparency (additional Q&A documentation on disruptions); supplementary analyses (equity impacts)

### Lesson 2: Transparency as a Risk-Management Strategy

**Principle**: Public documentation of methods, limitations, and TAG deliberations reduces reputational risk from contested estimates.

**Case Study: IGME Public TAG Reports**

**Context**: Child mortality estimates often diverge from national vital registration (due to incompleteness corrections) or single-survey snapshots (due to smoothing). This creates contestation risk.

**IGME Transparency Mechanisms**:
1. **Annual TAG Reports**: Published on childmortality.org; document:
   - Proposed methodological changes (e.g., revised bias-adjustment formulas)
   - TAG review process and recommendations
   - Dissenting opinions (if any)
   - Country-specific consultation outcomes
   
2. **Country Methods Sheets**: For each of 195 countries, document:
   - Data sources used (vital registration, surveys, census)
   - Bias adjustments applied (with justification)
   - Uncertainty intervals and how they're derived
   - Divergences from national official estimates (with explanations)
   
3. **Public Code Repositories**: R package `CME.Assistant` (in development) will allow:
   - Replication of all estimates from raw data
   - Sensitivity analyses (users can alter assumptions)
   - Academic scrutiny of modeling choices

**Impact**:
- **Reduced Contestation**: NSOs can trace why UN IGME estimate diverges from national data; if disagreement persists, both estimates published with metadata explanations
- **Enhanced Legitimacy**: External researchers validate methodology via peer-reviewed publications (Alkema 2014, *Lancet Global Health*)
- **Continuous Improvement**: TAG recommendations drive methodological refinements (e.g., 2018 update to sex-ratio modeling)

**Contrast: WUENIC Triangulation Narrative**

**Context**: WUENIC reconciles administrative coverage (from Joint Reporting Form) with survey-based estimates (DHS/MICS). Process involves expert judgment.

**Transparency Gaps**:
- No public TAG reports (RITAGs produce regional summaries, not country-specific)
- Triangulation narrative described qualitatively ("agencies review admin and survey data") but not algorithmic
- Code not routinely public

**Consequence**:
- Higher user skepticism ("how did agencies decide between admin 85% and survey 68%?")
- Occasional contestation from NSOs ("why was our admin data adjusted downward?")
- Limited external replication or sensitivity analysis

**Recommendation**: WUENIC could adopt IGME's transparency template:
- Publish country-specific notes explaining admin vs survey discrepancies
- Document decision rules (e.g., "if admin >10 points above survey, cap at survey + sampling error")
- Release triangulation code (even if simplified version for public use)

**Operational Guidance for SDG Custodians**:
1. **Default to Public**: Documentation, TAG reports, and code should be public unless confidentiality or security constraints apply
2. **Template Transparency**: IAEG-SDGs could provide standardized templates:
   - Country Methods Sheet (per IGME model)
   - TAG Report structure (executive summary, recommendations, dissents)
   - Code Repository (with licensing guidance: CC-BY, MIT, GPL)
3. **Risk-Proportionate**: High-stakes indicators (e.g., poverty, mortality) justify more elaborate transparency; low-stakes indicators (e.g., niche sub-indicators) can use lighter documentation

### Lesson 3: Country Consultation as Co-Production, Not Rubber-Stamping

**Principle**: Consultation windows should enable substantive NSO input, not merely notify NSOs of pre-determined estimates.

**IGME Model: Structured Consultation with Feedback Loop**

**Process**:
1. **Pre-Consultation Preparation** (3 months before release):
   - UN IGME runs preliminary estimates
   - Agencies conduct quality checks (outlier detection, consistency with regional trends)
   
2. **Consultation Window** (6 weeks):
   - NSOs receive:
     - Preliminary estimates for their country
     - Data sources used (vital registration, surveys)
     - Methodological notes (adjustments applied)
     - Comparison to previous year's estimate
   - NSOs can:
     - Provide additional data (new survey, updated vital registration)
     - Contest adjustments ("our vital registration completeness is higher than you assumed")
     - Request sensitivity analyses ("what if we use census instead of UN Population Division denominators?")
   
3. **Agency Adjudication** (2 weeks):
   - Technical team reviews NSO inputs
   - Re-runs models if new data provided
   - Documents decisions (accept NSO data, contest with justification, or request additional evidence)
   
4. **Dual Reporting** (upon release):
   - If NSO and UN IGME estimates diverge >10%, both published
   - Metadata explains divergence (e.g., "national estimate uses unadjusted vital registration; UN IGME adjusts for incompleteness")

**Impact**:
- **Country Ownership**: NSOs feel heard; consultation is substantive, not pro forma
- **Data Quality**: NSO inputs improve estimates (e.g., NSO provides recent census data not yet in UN databases)
- **Legitimacy**: Dual reporting respects national sovereignty while maintaining global comparability

**Contrast: Weaker Consultation Models**

**JME Consultation**:
- Conducted via UNICEF Regional Offices (not direct NSO portal)
- Shorter window (~4 weeks)
- Less structured feedback loop (agencies adjudicate offline; NSOs don't see resolution)
- Result: Lower NSO engagement; occasional surprise when estimates released

**Recommendation**: JME could adopt IGME's structured portal and dual reporting where divergences occur.

**Operational Guidance for SDG Custodians**:
1. **Minimum Consultation Standards** (IAEG-SDGs template):
   - **Duration**: At least 4 weeks (6 weeks for modeled estimates)
   - **Recipient**: Direct to NSO focal points (not only via country offices)
   - **Content**: Preliminary estimate, data sources, methods, comparison to previous
   - **Feedback Mechanism**: Structured form (not only email) with:
     - Accept estimate (no changes)
     - Provide additional data (attach file)
     - Contest methodology (explain basis)
   
2. **Adjudication Transparency**:
   - Publish summary of consultation outcomes ("32 countries provided new data; 18 estimates revised; 5 divergences remain and dual reported")
   - Country-specific metadata notes where NSO input incorporated
   
3. **Dual Reporting Thresholds**:
   - If national official estimate and harmonized estimate diverge by >X% (domain-specific threshold), publish both
   - Metadata explains divergence without judging which is "correct"

### Lesson 4: Disaggregation Feasibility Varies by Domain—Document Constraints Explicitly

> **For full disaggregation standards, see [Disaggregation Policies by Initiative](#disaggregation-policies-by-initiative).**

**Principle**: "Leave No One Behind" equity mandates cannot be operationalized uniformly; agencies should publish disaggregation matrices rather than over-promise intersections.

**UNICEF Experience Across Domains**:

**High Disaggregation Feasibility: JME (Nutrition) and JMP (WASH)**
- **Why Feasible**:
  - Survey-based (DHS/MICS microdata available)
  - Large sample sizes (typically 5,000-15,000 households)
  - Established wealth indices (DHS uses asset-based PCA; MICS similar)
  - Low missingness (anthropometric measurements have ~90% completion)
  
- **Routinely Published**:
  - Sex: 95% of JME estimates
  - Wealth quintiles: 60-70% of JME estimates; 120+ countries for JMP
  - Residence (urban/rural): 70-80%
  - Subnational (Admin-1): JMP for 80 countries; JME on request
  
- **Governance Approach**: Default to publishing disaggregations; flag when unavailable

**Moderate Disaggregation Feasibility: Child Protection (Child Marriage, FGM)**
- **Why Constrained**:
  - Retrospective reporting (women 20-24 report marriage age; introduces recall bias)
  - Sensitive topics (FGM prevalence varies by cultural context; non-response)
  - Smaller effective samples (age-specific cohorts reduce N)
  
- **Selectively Published**:
  - Sex: Inherent (women-only indicators)
  - Age cohorts: Married <15 vs <18 (standard)
  - Wealth/residence: 60-70% of countries (sample size permitting)
  - Attitudes: Not comparable across countries (question wording varies)
  
- **Governance Approach**: Publish sample sizes alongside estimates; flag when intersections lack statistical power

**Low Disaggregation Feasibility: IGME (Mortality) and WUENIC (Immunization)**
- **Why Constrained (IGME)**:
  - Vital registration gaps (60% of countries lack complete death registration)
  - Survey sample sizes insufficient for sex × wealth intersections (mortality is rare event; requires 10,000+ births to detect neonatal mortality by quintile)
  - Modeling assumptions break down for fine disaggregations (uncertainty intervals explode)
  
- **Why Constrained (WUENIC)**:
  - Administrative data structure (numerator = doses administered; disaggregations not systematically recorded)
  - Surveys provide sex/wealth but separately from WUENIC time series (different reference periods)
  
- **Sparingly Published**:
  - IGME: Sex for ~40 countries with vital registration; wealth in thematic supplements only
  - WUENIC: No sex/wealth in headline estimates; refer users to DHS/MICS for equity analysis
  
- **Governance Approach**: Explicit documentation: "Sex-disaggregated mortality not globally available; see CME_SUBNATIONAL for countries with vital registration"

**Operational Guidance for SDG Custodians**:
1. **Publish Disaggregation Availability Matrix** (per Table: Disaggregation Policies in this document):
   - For each indicator, document:
     - Dimensions available (sex, age, residence, wealth, disability, etc.)
     - Country coverage (% of countries with each dimension)
     - Methodological constraints (sample size, missingness, confidentiality)
     - Where to find equity analyses (separate dataflows, thematic reports)
   
2. **Avoid Over-Promising Equity**:
   - Do NOT claim "fully disaggregated by LNOB dimensions" if constraints exist
   - State explicitly: "Wealth disaggregation available for 68% of countries; see metadata for sample size thresholds"
   
3. **Invest in Equity-Enabling Infrastructure**:
   - Survey oversampling of vulnerable groups (MICS disability module)
   - Small-area estimation methods (for subnational with limited samples)
   - Linked data systems (vital registration + census for intersections)

### Lesson 5: Inter-Agency Coordination Needs Formalized Division of Labor

**Principle**: Co-custodianship requires explicit MoUs specifying roles, not informal gentleman's agreements.

**Case Study: IGME Co-Custodianship (UNICEF, WHO, UN DESA, World Bank)**

**Division of Labor (Documented in MoU)**:

| **Agency** | **Primary Responsibility** | **Justification** |
|------------|----------------------------|-------------------|
| **UNICEF** | Country consultation; SDMX dissemination; policy briefs | 190+ country offices; Data Warehouse infrastructure; program linkages |
| **WHO** | Methodological development; vital registration liaison; ICD coding | Normative authority for health statistics; WHO Mortality Database |
| **UN DESA Population Division** | Demographic inputs (birth/death denominators); census coordination | Global population estimates (WPP); census database |
| **World Bank** | Economic/equity analytics; poverty linkages; BOOST fiscal data | Development economics expertise; World Development Indicators (WDI) |

**Coordination Mechanisms**:
1. **Quarterly Technical Working Group Calls**: Rotating chair; agenda includes:
   - Data updates (new surveys, vital registration releases)
   - Methodological proposals (reviewed before TAG)
   - Country consultation outcomes
   
2. **Annual TAG Meeting**: All four agencies present; TAG provides independent review

3. **Joint Publications**: All four agencies listed as authors; logos on reports

4. **Aligned Release Cycles**: September annual release (coordinated with UN General Assembly high-level week)

**Success Factors**:
- **Comparative Advantage**: Each agency contributes unique expertise (UNICEF's country presence, WHO's normative authority, UN DESA's demographics, World Bank's economics)
- **Formalized Roles**: MoU prevents duplication or gaps
- **Shared Reputational Stake**: All agencies co-brand outputs; incentivizes quality

**Contrast: Weaker Coordination (Child Protection Indicators)**

**Context**: Child labour statistics have overlapping mandates (ILO leads; UNICEF contributes MICS data).

**Coordination Gaps**:
- No formal MoU (informal understanding only)
- Unclear release coordination (ILO global estimates vs UNICEF country profiles published separately)
- Different definitions (ILO SIMPOC vs MICS child labour module have slight variations)

**Consequence**:
- User confusion ("which estimate should I cite?")
- Occasional inconsistencies (ILO regional aggregates don't always match UNICEF country data)

**Recommendation**: ILO and UNICEF formalize MoU specifying:
- Indicator definitions (harmonize SIMPOC and MICS modules)
- Division of labor (ILO leads global modeling; UNICEF contributes survey data and country validation)
- Joint release (single publication co-branded)

**Operational Guidance for SDG Co-Custodians**:
1. **IAEG-SDGs MoU Template**: Standardized structure including:
   - **Roles**: Primary responsibilities by agency
   - **Coordination**: Meeting frequency, decision rules (consensus vs vote), escalation mechanism
   - **Branding**: Co-authorship, logo usage, press release coordination
   - **Data Sharing**: Formats (SDMX), frequency, confidentiality protocols
   - **Dispute Resolution**: Escalation path (e.g., to IAEG-SDGs Secretariat)
   
2. **Comparative Advantage Matrix**: Document why each agency is involved:
   - Normative authority (WHO for health, ILO for labour, UNESCO for education)
   - Field presence (UNICEF, UNFPA, UNDP country offices)
   - Technical expertise (World Bank for economics, UN DESA for demographics)
   - Infrastructure (SDMX, APIs, dissemination platforms)
   
3. **Avoid Redundancy**: If agencies have overlapping mandates, merge into single custodianship or formalize complementary roles (don't duplicate global estimates)

---

## Supplementary Custodianship Contexts

### 5. UNAIDS Global AIDS Monitoring (GAM)

**Lead**: UNAIDS Secretariat | **UNICEF Role**: Co-sponsor; child/adolescent HIV focal point

**Scope**: Political Declaration on HIV and AIDS commitments; 90-90-90 targets (now 95-95-95)

**Methodological Framework**:
- AEM/Spectrum models for epidemiological estimates
- Standardized indicator definitions via Global AIDS Monitoring guidelines
- Online reporting tool: https://aidsreportingtool.unaids.org/
- Country validation cycles with National AIDS Councils

**Governance**:
- UNAIDS Programme Coordinating Board oversight
- Reference Group on Estimates, Modelling and Projections
- Annual GAM release (July)

**Relevance to unicefData**:
- `HIV_AIDS` dataflows adopt GAM indicator codes
- Focus on paediatric/adolescent subsets (0-14, 10-19 years)
- Provenance: Distinguish epidemiological models (Spectrum) from surveillance data

**References**:
- GAM 2025: https://www.unaids.org/en/global-aids-monitoring
- Spectrum model: https://www.avenirhealth.org/software-spectrum.php

---

### 6. UNESCO Institute for Statistics (UIS) - SDG 4 Monitoring

**Lead**: UIS | **UNICEF Role**: Partner for out-of-school children indicators; Early Childhood Development (ECDI2030); MICS education module co-design

**Scope**: SDG 4 indicators (education access, completion, learning outcomes)

**Methodological Framework**:
- UIS SDG 4 Global and Thematic Indicators Framework
- GAML (Global Alliance to Monitor Learning) for learning assessments
- OOSC Initiative (Out-of-School Children) methodology (UNICEF-UIS partnership)

**Governance**:
- TCG/SDG-Education 2030 Steering Committee
- Expert groups: Education Data Consortium (EDSC), GAML
- Triennial Global Education Monitoring (GEM) Report

**Relevance to unicefData**:
- `EDUCATION_UIS_SDG` dataflows use UIS definitions
- Out-of-school rates disaggregated by age, sex, residence
- Learning indicators from MICS Education Module (MICS6+)

**References**:
- UIS: https://www.uis.unesco.org/en
- SDG 4 Data: https://databrowser.uis.unesco.org/
- OOSC methodology: UNESCO-UIS/UNICEF (2016). *Fixing the Broken Promise of Education for All*

---

### 7. UNFPA–UNICEF Joint Programmes (Child Marriage, FGM)

**Lead**: UNFPA and UNICEF (joint programme implementation)

**Scope**: Harmful practices (child marriage, female genital mutilation)

**Methodological Framework**:
- Indicator definitions aligned with MICS and DHS modules
- Prevalence measured via women's retrospective reports (15-49 years)
- Attitudes/norms captured via specialized questions
- Methods documented in MICS6 and DHS-8 manuals

**Governance**:
- Programme monitoring via Results Framework (output/outcome indicators)
- Statistical custodianship for SDG 5.3 (child marriage, FGM) led by UNICEF
- Country validation through national statistical system engagement

**Relevance to unicefData**:
- `PT_CM` (Child Marriage) and `PT_FGM` dataflows
- Disaggregation: Age at marriage cohorts, residence, wealth (survey-dependent)
- Provenance: Survey microdata (DHS, MICS, national surveys)

**References**:
- Child Marriage: https://data.unicef.org/topic/child-protection/child-marriage/
- FGM: https://data.unicef.org/topic/child-protection/female-genital-mutilation/
- Joint Programme FGM: https://www.unfpa.org/unfpa-unicef-joint-programme-on-female-genital-mutilation

---

### 8. Violence Against Children (ICVAC/VAC Monitoring)

**Established**: Violence Against Children (VAC) monitoring frameworks developed 2000s; integrated into SDG monitoring post-2015

**Lead Agency**: UNICEF (with WHO for health aspects)

**Scope**: Physical violence, emotional/psychological violence, sexual violence, neglect; measured in children (under 18) and adolescents

**Problem Addressed**:
- Violence against children is invisible in many countries: No routine monitoring systems; reliance on surveys (DHS, MICS, national) creates gaps
- Definitions vary by country: Legal age of majority, corporal punishment norms differ; complicates cross-country comparability
- Sensitive measurement: Disclosure barriers (shame, fear of retaliation) lead to under-reporting; requires ethically-trained enumerators
- Limited institutional data: Unlike mortality (vital registration) or WASH (census modules), violence data cannot be captured administratively

**Methodological Framework**:
- MICS Violence Against Children (VAC) module: Standardized questionnaire with cognitive testing across contexts
- DHS Domestic Violence Module: Women's retrospective reports; global comparability focus
- ICVAC (International Child Victimization Survey): Expands to children's own reports (adolescent-friendly)
- Prevalence measured via:
  - **Children's reports**: Experienced physical punishment, sexual violence (ICVAC; MICS6+)
  - **Caregivers' reports**: Discipline methods, supervision practices (MICS standard module)
  - **Women's reports**: Childhood experience of violence; intimate partner violence victimization (DHS)
- Norms/attitudes: Captured via acceptability of corporal punishment, justification of violence questions

**Governance Structure**:
- **No formal TAG** (data quality primarily managed through survey program protocols)
- **Ethical oversight**: DHS Program, MICS, and ICVAC all operate under Institutional Review Boards (IRBs); trauma-informed practices required
- **Country consultation**: MICS country consultations include VAC module sensitivity review
- **Global monitoring**: UNICEF compiles data; publishes thematic briefs and country factsheets

**Outputs**:
- **MICS VAC Module**: 110+ countries (330+ surveys since 1995); includes:
  - Experience of physical punishment (any, severe)
  - Sexual violence (any type, including attempted; perpetrator identity)
  - Emotional violence (humiliation, threats)
  - Supervision gaps (left alone for extended periods)
- **ICVAC Database**: Expanding coverage (currently ~35 countries); adolescent-focused (12-17 years)
- **DHS Violence Against Women Module**: 100+ countries; linked to child discipline practices
- **Country Profiles**: Violence prevalence by age, sex, residence, wealth (where data available)

**Data Quality Indicators**:
- **Timeliness**: Biennial MICS updates; DHS every 5 years
- **Accuracy**: Non-response bias significant (violence underreported due to sensitivity); confidence intervals wide
- **Ethical standards**: Informed consent, confidentiality, referral protocols documented
- **Disaggregation**: Sex available (boys vs girls); age cohorts (5-14 vs 15-17); residence, wealth (survey-dependent)

**Limitations and Governance Adaptations**:
- **Measurement challenges**: Sensitive nature prevents full disclosure; self-report bias; retrospective recall
- **No modeling**: Unlike mortality (IGME), violence data are NOT modeled; only direct survey estimates published
- **Conservative reporting**: UNICEF publishes ranges and uncertainty; avoids precise point estimates
- **Contextualization essential**: Violence norms vary by culture; data must be interpreted with qualitative research, not numbers alone
- **Ethical priority**: Harm prevention (trauma screening, referral) prioritized over data completeness

**Governance Approach (Unique to Low-Maturity, High-Sensitivity Data)**:
1. **Survey program quality control**: DHS and MICS handle ethical oversight (IRBs, enumerator training)
2. **Transparent limitations**: UNICEF publishes fact that violence is under-reported; recommends qualitative triangulation
3. **Country-sensitive reporting**: Data disaggregated in country factsheets (not aggregated to regions where estimates vary wildly)
4. **Thematic focus**: UNICEF emphasizes policy-relevant findings (e.g., "corporal punishment reduction strategies") rather than prevalence precision

**References**:
- UNICEF Violence Against Children overview: https://www.unicef.org/protection/violence-against-children
- MICS VAC Module: https://mics.unicef.org/
- ICVAC (International Child Victimization Survey): https://www.worldchildrenstudy.org/
- DHS Violence Module: https://www.dhsprogram.com/What-We-Do/Survey-Types/DHS.cfm
- WHO Multi-country Study on VAC: https://www.who.int/publications/i/item/multi-country-study-on-women%27s-health-and-life-experiences

---

### 9. Early Childhood Development (ECDI2030)

**Established**: Early Childhood Development Index (ECDI) formalized 2014; expanded to ECDI2030 post-SDG4 adoption

**Lead Agency**: UNICEF (with UNESCO-UIS for education linkages; World Bank for economic analysis)

**Scope**: Child development (cognitive, motor, socio-emotional, language) measured in children 0-8 years via:
- **ECDI (Ages 3-4 years)**: Caregiver-reported developmental milestones
- **ECDI2030 (Ages 3-9 years)**: Expanded framework including early education quality
- **Learning assessments (Ages 6+)**: Academic readiness (letter/number knowledge, early literacy)

**Problem Addressed**:
- Early childhood development not routinely monitored: Most countries lack systematic ECD assessment systems
- Non-comparability of assessments: Language-specific, context-dependent; global comparison requires harmonization
- Data gaps in low-income countries: ECD assessments require trained assessors; limited resources constrain measurement
- Measurement complexity: Development is multi-dimensional (5 domains: physical, cognitive, language, socio-emotional, literacy/numeracy); single indicators insufficient

**Methodological Framework**:
- **ECDI Caregiver Reporting**: Short, age-appropriate questions (typically 10-20 items) administered to mother/primary caregiver
  - Physical development: Walks, running, sitting, gross motor skills
  - Cognitive development: Object permanence, cause-effect understanding
  - Language development: Word vocabulary, phrase construction
  - Socio-emotional: Cooperation, playing with others, emotional regulation
  - Literacy/Numeracy: Counting, letter recognition, scribbling (age 4+)
- **Harmonization across MICS, DHS, national surveys**: UNICEF MICS6 standardized module; DHS adapted questions; national surveys train on ECDI framework
- **Learning assessments (GAML framework)**: For school-age children (6-9); regional/global assessments (PISA, TIMSS, PEIC) harmonized conceptually (not directly comparable scores)
- **Quality of early education services**: Assessed via SARA-ECD (Service Availability and Readiness Assessment for ECD)

**Governance Structure**:
- **ECDI Technical Advisory Group**: Established 2018; members include developmental psychologists, statisticians, education specialists, NSO representatives
- **Multi-partner coordination**: UNESCO-UIS leads education quality metrics; World Bank contributes cost-effectiveness analyses; UNICEF coordinates global synthesis
- **Country collaboration**: MICS countries receive ECDI training; national ECD assessments reviewed for alignment
- **Regional/global synthesis**: Annual reports synthesizing early learning poverty, equity gaps, program quality

**Outputs**:
- **ECDI Database**: 110+ countries with MICS ECDI data (surveys 2014-2024); includes:
  - Percentage of children on-track in each developmental domain (5 domains scored separately)
  - Percentage meeting minimum development standards (cut-off: at least 3 of 5 domains)
  - Disaggregation by age (3-year-olds vs 4-year-olds), sex, residence, wealth (quintiles)
- **Learning Poverty Estimates**: Percentage of children not reading by age 10 (GAML + global assessments)
- **SARA-ECD Health Facility Assessments**: Quality of ECD services in health facilities (90+ countries)
- **Global ECD Scorecard**: Annual synthesis of readiness, learning, equity dimensions

**Data Quality Indicators**:
- **Completeness**: 95% of MICS countries include ECDI module; ~110 countries with recent data
- **Consistency**: ECDI module harmonized across MICS surveys; DHS adapts but validates alignment
- **Validity**: ECDI domains validated against direct cognitive assessments (Bayley, NVIQ) in sub-samples
- **Disaggregation**: Highly available (sex, residence, wealth, disability) due to MICS survey design
- **Uncertainty**: Standard errors for national estimates; confidence intervals for intersections

**Unique Governance Challenges**:
1. **Caregiver reporting bias**: Mothers may over-report development; validation studies show ~70-80% concordance with direct assessment
2. **Language/culture specificity**: Developmental milestones vary (e.g., age of walking varies 10-16 months globally); ECDI adapted by region
3. **Intersectoral coordination**: ECD involves health (child health services), education (early learning programs), social protection (cash transfers); UNICEF coordinates but lacks direct implementation control in some countries
4. **Service quality measurement**: SARA-ECD assesses availability but has lower feasibility in low-resource countries

**Governance Approach (Balanced Between Data Maturity and Complexity)**:
1. **Transparent caregiver-reporting limitations**: UNICEF publishes that ECD is caregiver-reported, not direct measurement; recommends sub-sample validation studies
2. **Regional validation**: ECDI module tested and adapted by region before deployment
3. **Multi-stakeholder TAG**: Brings developmental expertise alongside statistical rigor
4. **Dual reporting**: Learning poverty (estimated from assessments + household ECD data) reported alongside direct assessment results
5. **Equity emphasis**: ECDI inherently captures inequality (wealth gradient in development); used for targeting early childhood interventions

**References**:
- UNICEF Early Childhood Development: https://www.unicef.org/early-childhood-development
- ECDI2030 Framework: https://www.unicef.org/reports/ecdi2030-framework
- MICS ECDI Module: https://mics.unicef.org/
- UNESCO Learning Poverty Dashboard: https://www.unesco.org/en/education/learning-poverty
- GAML (Global Alliance to Monitor Learning): https://gaml.org/
- SARA-ECD: https://www.who.int/teams/maternal-newborn-child-adolescent-health/child-health/sara
- World Bank ECD Economic Analysis: https://www.worldbank.org/en/topic/early-childhood-development

---

## Technical Advisory Groups (TAGs): Role and Function

**Purpose**: Provide independent, expert oversight of methodological quality, comparability, and transparency

**Composition**:
- Academic statisticians and demographers
- Representatives from national statistical offices
- Subject matter experts (epidemiology, nutrition, WASH, etc.)
- International organization technical staff (non-voting)

**Functions**:
1. **Methodology Review**: Assess proposed changes to estimation models before implementation
2. **Quality Assurance**: Review data inclusion criteria and outlier handling
3. **Comparability**: Evaluate impact of revisions on time-series consistency
4. **Transparency**: Recommend documentation standards and public release protocols
5. **Capacity Building**: Advise on training materials and country engagement strategies

**Examples**:
- IGME TAG: Annual meetings; reports published on childmortality.org
- JME technical review: External academic partners (London School of Hygiene & Tropical Medicine, Johns Hopkins)
- JMP governance: UN-Water Technical Advisory Group and country consultations
- WUENIC: Regional Immunization Technical Advisory Groups (RITAGs)

**Impact on Data Quality**:
- Peer-review equivalent for inter-agency estimates
- Early detection of methodological weaknesses
- Enhanced user trust through transparent governance

---

## Alignment with UN Statistical Standards

### Generic Statistical Business Process Model (GSBPM)

**Definition**: The Generic Statistical Business Process Model (GSBPM) is a standard framework developed by the UN Economic Commission for Europe (UNECE) to describe eight sequential phases of statistical production, applicable to all statistical outputs (surveys, administrative data, modeled estimates).

**UNICEF Custodianship Processes Implement All Eight GSBPM Phases**:

| **Phase** | **GSBPM Definition** | **Custodianship Application** | **Example** | **Code Public?** |
|-----------|----------------------|-------------------------------|-------------|------------------|
| **1. Specify** | Determine information needs; consult stakeholders; define requirements | Indicator definition per SDG framework; IAEG-SDGs consultation; country input | IGME: Neonatal mortality = deaths 0-27 days (UN definition) | N/A (policy) |
| **2. Design** | Plan data collection; design survey/administrative systems; develop methodologies | Harmonize survey modules across MICS/DHS/national; design collection instruments; methods documentation | JME: Standardize anthropometric protocols per WHO Child Growth Standards | Methods: **PUBLIC** |
| **3. Build** | Develop software/systems; implement collection infrastructure; test systems | Develop estimation code; build SDMX infrastructure; test questionnaires with countries | JMP: R scripts for service ladder classification | **JMP: PUBLIC (GitHub)** |
| **4. Collect** | Execute data collection; manage quality during collection | Compile country data; manage Joint Reporting Form; coordinate MICS/DHS survey programs | WUENIC: JRF online system; MICS surveys in 110+ countries | **MICS: Partial (docs available)** |
| **5. Process** | Data editing, validation, integration; handle missing values; prepare for analysis | Bias adjustment; reconciliation of multiple sources; outlier detection; validation checks | IGME: Undercount adjustment; WUENIC: Admin-survey reconciliation | **Code: NOT public** |
| **6. Analyse** | Apply statistical methods; run estimation models; produce estimates | Estimate time series; quantify uncertainty; conduct sensitivity analyses | JME: EBLUP smoothing; IGME: Bayesian B-spline models | **IGME: In development (R package planned)** |
| **7. Disseminate** | Publish data, reports, dashboards; manage releases; ensure findability | Publish via SDMX APIs; produce country briefs/global reports; interactive dashboards | All initiatives: SDMX APIs; UNICEF Data Warehouse; WHO GHO; JMP portal | **Infrastructure: PUBLIC (SDMX standard)** |
| **8. Evaluate** | Quality assurance; gather feedback; assess user satisfaction; improve processes | Technical Advisory Group review; country consultation feedback; methodological audits | IGME: Annual TAG meetings with public reports; JMP: Regional data workshops | **TAG reports: PUBLIC** |

**Reference**: UNECE (2019). *Generic Statistical Business Process Model v5.1*. https://statswiki.unece.org/display/GSBPM

**Code Availability Assessment Across Phases**:
- **Phases 1-2 (Policy/Design)**: All initiatives document methodology publicly; GSBPM framework applied
- **Phase 3 (Build)**: **JMP leads in transparency** (GitHub repository for service ladder classification); IGME R package in development; MICS documentation available; others proprietary
- **Phase 5 (Process)**: Complex algorithms typically confidential (bias adjustment, triangulation); proprietary institutional methods
- **Phase 6 (Analyse)**: IGME advancing transparency (planned public R package); others publish academic papers but not running code
- **Phase 7 (Disseminate)**: SDMX infrastructure increasingly open; standardized data APIs across agencies
- **Phase 8 (Evaluate)**: TAG reports public (IGME, JMP); workshop-based evaluation (WUENIC, JME) less transparent

### Data Quality Assessment Framework (DQAF)

**Definition**: The Data Quality Assessment Framework (DQAF) is an IMF-developed tool to assess statistical data quality across five interrelated dimensions. It is endorsed by the UN Statistical Commission and adapted by IAEG-SDGs for SDG monitoring quality benchmarking.

**Custodianship Processes Implement All Five DQAF Dimensions**:

| **DQAF Dimension** | **Definition** | **Custodianship Implementation** | **Verification Evidence** |
|-------------------|----------------|----------------------------------|---------------------------|
| **1. Integrity** | Trustworthiness of statistics; independence from political pressure; ethical governance; statistical literacy in public | Independent Technical Advisory Groups (IGME, JMP) with external academics and NSO reps; transparent governance pages; ethical oversight protocols; no agency interference in technical decisions | Published TAG reports (IGME annual on childmortality.org; JMP workshop summaries on washdata.org); governance documentation (washdata.org/how-we-work; childmortality.org/governance); TAG member composition public |
| **2. Methodological Soundness** | Concepts, definitions, classifications follow international standards; sound statistical and scientific techniques applied; peer review | Peer-reviewed estimation methodologies published in *Lancet Global Health*, *Bulletin WHO*, *PLOS Medicine*; adherence to WHO standards (Child Growth Standards for JME; GSBPM/DQAF for all); documented data inclusion criteria and quality thresholds | Academic publications (Alkema 2014, Heidkamp 2021, Burton 2009); methodology fact sheets (IGME country-specific methods sheets); validation studies (ECDI caregiver reports vs direct assessment); peer-reviewed protocols |
| **3. Accuracy and Reliability** | Data are correct and reliable; error margins are known and acceptable; validation and verification procedures in place | Uncertainty quantification (80-90% confidence intervals for IGME; standard errors for surveys; none for WUENIC qualitative triangulation); cross-validation against other sources (mortality: DHS vs vital registration; WUENIC: admin vs survey; JME: surveys vs growth curves); documented sensitivity analyses | Confidence intervals published with all estimates (IGME, JME); TAG quality assurance reviews before release; published bias assessments (WUENIC coverage validation: flag if >100%); reconciliation reports explaining admin-survey divergences >10% |
| **4. Serviceability** | Statistics are timely, relevant, and consistent over time; responsive to user needs and policy questions; provided in appropriate formats | Regular, predictable release cycles (IGME: annual September; JME: biennial odd years; WUENIC: annual July; JMP: annual database, biennial reports); country consultation windows (IGME 6 weeks; JRF annual for WUENIC); responsiveness to queries (Q&A pages on portals); disaggregation by policy-relevant dimensions (wealth quintiles, residence, subnational, sex) | Release calendars published on custodian portals; Q&A pages with FAQ/responses (WUENIC on WHO website); country consultation mechanics documented; disaggregation availability matrices per initiative |
| **5. Accessibility** | Statistics are available and presented clearly; metadata are comprehensive and in accessible form; users can navigate and interpret; low cost of access; confidentiality protected | SDMX 2.1 APIs (WHO GHO, UNICEF Data Warehouse, JMP washdata.org); bulk data downloads; country factsheets and global reports; interactive dashboards; metadata in multiple languages; **public code repositories** (JMP GitHub for service ladder scripts); API documentation | UNICEF Data Warehouse with SDMX API; JMP washdata.org with REST API; WHO GHO API; IGME portal bulk downloads; MICS open data repositories; DHS public use files; interactive visualizations (data.unicef.org dashboards); GitHub repositories (JMP, MICS documentation) |

**Reference**: IMF (2012). *Data Quality Assessment Framework (DQAF)* for assessing quality of macroeconomic statistics, adapted by IAEG-SDGs. https://www.imf.org/external/pubs/ft/dqrs/dqaf.pdf

**DQAF Performance Summary by Initiative**:
- **Highest performance across all 5 dimensions**: **JMP** (transparent governance + published TAG reports + public code + strong disaggregation + responsive workshops + accessible SDMX API)
- **Strong on Integrity & Methodological Soundness**: **IGME** (independent TAG with public annual reports; peer-reviewed Bayesian methods; country-specific methods sheets)
- **Moderate overall**: **JME** (good dissemination and academic review; limited code transparency; biennial cycle may reduce serviceability)
- **Mixed performance**: **WUENIC** (timely annual release; triangulation method less transparent than modeling; no TAG reports published; code not public)
- **Data maturity challenges**: **ECDI** (caregiver reporting; validation studies limited); **VAC** (sensitivity, underreporting biases); **Child Protection** (survey-program dependent; no independent oversight structure)

### IAEG-SDGs Custodianship Model

**Tier Classification**:
- **Tier I**: Established methodology, regular country data (e.g., WUENIC for SDG 3.b)
- **Tier II**: Established methodology, limited country coverage (e.g., JME for SDG 2.2 in data-poor countries)

**Custodian Responsibilities** (per IAEG-SDGs mandate):
1. Develop and maintain indicator metadata (definition, concepts, unit of measure)
2. Compile data from countries; validate and estimate where needed
3. Ensure quality, comparability, and documentation
4. Disseminate via global SDG database
5. Respond to country queries and support capacity development

**UNICEF Custodianship Roles**:
- Lead: 14 SDG indicators (child mortality, malnutrition, WASH access, child marriage, FGM, etc.)
- Co-custodian: 8 indicators (with WHO, World Bank, UNFPA)
- Partner: Multiple indicators (UIS education, UNAIDS HIV)

**Reference**: UN Statistics Division (2024). *Global indicator framework for the SDGs and targets*. https://unstats.un.org/sdgs/indicators/indicators-list/

### UN Fundamental Principles of Official Statistics (FPOS)

**Adopted**: UN Statistical Commission 1994; endorsed by UN General Assembly 2014 (A/RES/68/261)

**Relevance**: UNICEF-led custodianship processes operate within the official statistics ecosystem. While not all outputs are designated "official statistics" (which are produced by NSOs under national legislation), these processes **aspire to FPOS standards** and **support national official statistics systems**.

#### The 10 Principles and Custodianship Alignment

| **Principle** | **Text (Abbreviated)** | **Custodianship Alignment** | **Evidence** |
|---------------|------------------------|-----------------------------|--------------|
| **1. Relevance, Impartiality, Equal Access** | Official statistics provide an indispensable element in the information system of a democratic society... practical utility... impartial | IGME, JME, JMP, WUENIC serve global public goods (SDGs, WHA targets); free access via portals/APIs; no commercial restrictions | All data publicly available; no paywalls; SDMX ensures machine readability |
| **2. Professional Standards and Ethics** | To retain trust... statistical agencies need decide on methods and procedures according to strictly professional considerations | Methodologies peer-reviewed (*Lancet*, *PLOS Medicine*, *Bulletin WHO*); TAGs provide independent oversight; transparent documentation | Published methods papers; TAG reports; no political interference in technical decisions |
| **3. Accountability and Transparency** | Facilitate correct interpretation... present information according to scientific standards on sources, methods, and procedures | Detailed methods sheets (IGME: country-specific notes; JME: survey inclusion criteria); SDMX attributes trace provenance; change logs public | childmortality.org/methods; washdata.org "What's new"; JME Annex tables |
| **4. Prevention of Misuse** | Statistical agencies are entitled to comment on erroneous interpretation and misuse | Country consultation windows allow NSOs to flag errors; agencies issue clarifications (e.g., WUENIC Q&A on admin vs survey discrepancies) | JRF consultation process; IGME country feedback portal; JMP data validation workshops |
| **5. Data Sources** | Data for statistical purposes may be drawn from all types of sources... Agencies choose source with regard to quality, timeliness, costs, and burden | IGME: Vital registration preferred but uses surveys where VR incomplete; JMP: Harmonizes census, surveys, admin data; WUENIC: Triangulates JRF and surveys | Documented data inclusion criteria; quality thresholds (e.g., JME excludes surveys <1000 sample size) |
| **6. Confidentiality** | Individual data... strictly confidential and used exclusively for statistical purposes | Custodianship processes use aggregated national estimates; microdata access governed by survey owners (DHS, MICS); UNICEF does not publish individual-level data | SDMX transmits aggregated series only; microdata requests handled by NSOs/survey programs |
| **7. Legal Framework** | Laws, regulations, and measures... shall be made public | UNICEF operates under UN General Assembly mandates; WHO under World Health Assembly resolutions; custodianship roles per IAEG-SDGs | IAEG-SDGs custodian list public; WHA resolutions cited (e.g., Immunization Agenda 2030) |
| **8. National Coordination** | Coordination among statistical agencies... essential to achieve consistency and efficiency | Country consultation protocols; collaboration with NSOs via UNICEF/WHO Country Offices; regional statistical capacity-building programs | JMP NSO workshops; WUENIC JRF process; IGME national estimates alongside UN IGME estimates |
| **9. International Standards** | Use by statistical agencies... of international concepts, classifications, and methods promotes consistency and efficiency | SDMX 2.1 for dissemination; WHO Child Growth Standards (JME); JMP service ladders aligned with SDG 6 metadata; IGME age definitions per UN Population Division | All dataflows SDMX-compliant; code lists follow international standards (ISO 3166 for countries) |
| **10. International Cooperation** | Bilateral and multilateral cooperation contributes to improvement of systems of official statistics | IGME, JME, JMP, WUENIC are exemplars of inter-agency cooperation; capacity-building for NSOs (survey design, estimation methods); South-South knowledge exchange | TAG membership includes NSO representatives; training workshops (e.g., MICS training for national statistical capacity) |

#### Operationalizing FPOS in Custodianship Processes

**Practical Applications**:

1. **Relevance and Impartiality (Principle 1)**:
   - Indicators selected via multi-stakeholder consultations (IAEG-SDGs process for SDGs)
   - Methods designed for cross-country comparability, not to favor any country's performance
   - Example: IGME does not suppress unfavorable mortality trends; publishes all estimates with uncertainty

2. **Professional Standards (Principle 2)**:
   - TAGs include academic statisticians with no institutional affiliation to UN agencies
   - Peer review in scientific journals ensures external scrutiny
   - Example: JME methodology changes proposed to TAG before implementation

3. **Accountability and Transparency (Principle 3)**:
   - Country consultation allows NSOs to review and contest estimates before publication
   - Methods documentation includes limitations and assumptions
   - Example: WUENIC publishes country-specific notes explaining admin vs survey discrepancies

4. **Prevention of Misuse (Principle 4)**:
   - Metadata includes guidance on appropriate use (e.g., "Do not compare pre-2015 and post-2015 JMP data")
   - Uncertainty intervals discourage over-interpretation of small differences
   - Example: IGME notes in SDG database warn against comparing modeled estimates to national vital registration

5. **Data Sources (Principle 5)**:
   - Documented preference hierarchies (e.g., JME: complete vital registration > high-quality survey > expert opinion)
   - Quality thresholds transparent (e.g., WUENIC flags coverage >100% as implausible)
   - Example: JMP prioritizes nationally representative surveys over convenience samples

6. **Confidentiality (Principle 6)**:
   - Custodianship processes do not access or publish individual-level records
   - Microdata governance remains with data collectors (NSOs, DHS Program, UNICEF MICS)
   - Example: JME equity analysis uses pre-aggregated wealth quintile summaries from surveys

7. **Legal Framework (Principle 7)**:
   - UNICEF's mandate per Convention on the Rights of the Child (CRC) and UN General Assembly resolutions
   - WHO's constitutional authority for health statistics (WHO Constitution Article 2)
   - Example: Immunization Agenda 2030 endorsed by World Health Assembly resolution WHA73.4 (2020)

8. **National Coordination (Principle 8)**:
   - Country consultation windows allow NSOs to provide corrections or additional data
   - Regional UNICEF/WHO offices facilitate dialogue between custodian agencies and national systems
   - Example: IGME includes both UN IGME estimates and national official estimates in database (when available)

9. **International Standards (Principle 9)**:
   - SDMX 2.1 for data exchange; ISO 3166 for country codes; ICD-10 for mortality causes
   - Alignment with SDG indicator metadata (IAEG-SDGs-endorsed definitions)
   - Example: JMP service ladders incorporated into SDG 6.1 and 6.2 metadata

10. **International Cooperation (Principle 10)**:
    - Joint inter-agency processes (IGME, JME, JMP, WUENIC) pool expertise and avoid duplication
    - Capacity-building via MICS, SARA (Service Availability and Readiness Assessment), HMIS strengthening
    - Example: IGME provides training to NSOs on child mortality estimation from incomplete vital registration

#### Custodianship as a Bridge Between Global and National Statistics

**Challenge**: Global monitoring requires harmonization; national sovereignty demands local control.

**Solution**: **Collaborative model**:
- **National Official Statistics**: Produced by NSOs under national legislation (primary authority)
- **Custodian Agency Estimates**: Harmonized for comparability; incorporate national data; subject to country consultation
- **Dual Reporting**: Where possible, publish both (e.g., IGME shows UN IGME estimate and national official estimate)

**Example Workflow (IGME)**:
1. NSO provides vital registration data and survey results to UN IGME
2. UN IGME applies harmonized methodology to ensure comparability across countries
3. Preliminary estimates shared with NSO for validation (6-week consultation)
4. NSO may accept, contest, or provide additional data
5. Final release includes:
   - UN IGME estimate (comparable across countries)
   - National official estimate (if published by NSO)
   - Metadata explaining any differences

**Principle in Practice**: This respects national authority (Principle 8) while fulfilling global comparability mandate (Principle 9).

#### References

- UN General Assembly (2014). *Fundamental Principles of Official Statistics*. Resolution A/RES/68/261. https://unstats.un.org/unsd/dnss/gp/FP-New-E.pdf
- UN Statistical Commission (2015). *Handbook on Management and Organization of National Statistical Systems*. https://unstats.un.org/unsd/statcom/handbook/
- Paris21 (2021). *Guidelines on Data Governance*. https://paris21.org/data-governance

---

## Disaggregation Policies by Initiative

### IGME (Child Mortality Estimation)

**Available Disaggregations**:
- **Sex**: Total only for headline series (CME_MRY0T4); sex-specific for select countries with vital registration
- **Residence**: Urban/rural for ~40 countries with DHS/MICS trend data
- **Wealth**: Not routinely published (equity analyses in thematic reports)
- **Subnational**: Available for ~25 countries via CME_SUBNATIONAL dataflow

**Methodological Constraints**:
- Sample size limitations in surveys prevent reliable sex × wealth intersections
- Vital registration gaps preclude global sex disaggregation
- Uncertainty intervals widen significantly for intersections

**User Guidance**:
- Request sex-specific estimates only where vital registration is complete
- Use equity supplements (published separately) for wealth analyses
- Cite uncertainty intervals when reporting subnational estimates

**Reference**: https://childmortality.org/methods

---

### JME (Child Malnutrition Estimates)

**Available Disaggregations**:
- **Sex**: Available for ~95% of stunting/wasting estimates
- **Age**: Harmonized to 0-59 months; some surveys include 0-23 months breakout
- **Residence**: Urban/rural for ~70% of countries (survey-dependent)
- **Wealth**: Quintiles for ~60% of countries (DHS/MICS microdata)

**Methodological Constraints**:
- Anthropometric data quality varies (exclusion if <70% complete)
- Wealth index construction differs between DHS and MICS (comparability issues)
- Sex × wealth × residence intersections require large samples (not always met)

**User Guidance**:
- Check JME Annex tables for disaggregation availability by country
- Avoid pooling across different wealth index methodologies
- Report sample sizes for intersections (provided in metadata)

**Reference**: https://data.unicef.org/resources/jme-report-2023/

---

### JMP (WASH Monitoring)

**Available Disaggregations**:
- **Residence**: Urban/rural standard for all countries
- **Wealth**: Quintiles for ~120 countries (survey microdata)
- **Service ladder**: Basic, limited, unimproved, open defecation (household)
- **Subnational**: Admin-1 level for ~80 countries
- **Institutional**: Schools, health facilities (separate dataflows)

**Methodological Constraints**:
- Service ladder categories not comparable pre-2015 (MDG era used different definitions)
- Institutional WASH data sparse (schools: 50% country coverage; health facilities: 30%)
- Inequality metrics (Theil index) require complete wealth data

**User Guidance**:
- Use 2015-present data for SDG-aligned service ladders
- Institutional WASH: Check data.unicef.org for coverage notes
- Subnational estimates: Verify survey representativeness (large sample needed)

**Reference**: https://washdata.org/monitoring/methods

---

### WUENIC (Immunization Coverage)

**Available Disaggregations**:
- **Age cohort**: 1-year-olds (DTP3, MCV1), 2-year-olds (MCV2), adolescents (HPV)
- **Vaccine type**: 15+ routine vaccines tracked
- **Data source**: Administrative vs survey flagged via OBS_STATUS attribute

**Methodological Constraints**:
- Sex disaggregation not systematically collected (not part of WUENIC mandate)
- Wealth quintiles available only from surveys (not administrative data)
- Subnational: Limited to countries with district-level reporting systems

**User Guidance**:
- Do NOT disaggregate WUENIC by sex/wealth for global analyses (data unavailable)
- Use survey-based estimates (DHS/MICS) for equity analyses (separate from WUENIC)
- Administrative data may over-estimate coverage (denominator issues)

**Reference**: https://www.who.int/teams/immunization-vaccines-and-biologicals/immunization-analysis-and-insights/global-monitoring/immunization-coverage/who-unicef-estimates-of-national-immunization-coverage

---

### Child Protection (PT, PT_CM, PT_FGM)

**Available Disaggregations**:
- **Age**: Birth cohorts (e.g., married before age 15, before age 18)
- **Sex**: Women 20-24 years (child marriage prevalence); girls 15-19 (FGM prevalence)
- **Residence**: Urban/rural (survey-dependent)
- **Wealth**: Quintiles (survey microdata, ~70% coverage)

**Methodological Constraints**:
- Retrospective reporting introduces recall bias
- Attitudes questions not universally comparable (cultural sensitivity)
- Sample sizes for age × residence × wealth intersections often insufficient

**User Guidance**:
- Report survey year and sample size for disaggregated estimates
- Note cultural differences in willingness to report sensitive practices
- Cross-reference with national qualitative studies for context

**Reference**: https://data.unicef.org/resources/data-collection-on-child-marriage/

---

## Release Cadence and Transparency Protocols

### Annual Release Cycles

| Initiative | Release Month | Consultation Window | Public Notice |
|------------|---------------|---------------------|---------------|
| **IGME** | September | June-July (6 weeks) | childmortality.org news |
| **WUENIC** | July | March-April (via JRF) | WHO/UNICEF press release |
| **UIS SDG4** | September (SDG report) | Ongoing country engagement | UIS website announcements |
| **UNAIDS GAM** | July (World AIDS Day preview) | Jan-May reporting window | unaids.org/GAM |

### Biennial Release Cycles

| Initiative | Release Frequency | Last Release | Next Expected |
|------------|-------------------|--------------|---------------|
| **JME** | Odd years | May 2023 | May 2025 |
| **JMP Global Report** | Every 2-3 years | 2024 | 2026-2027 |

### Transparency Mechanisms

**Change Logs**:
- IGME: Methodology change log on childmortality.org/methods
- JME: Annex documenting survey inclusions/exclusions
- JMP: "What's new" section on washdata.org updates
- WUENIC: Revision notes in WHO GHO metadata

### Code Availability: Comprehensive Assessment Across Initiatives

**Summary**: Code availability varies significantly across custodianship processes. JMP leads in transparency; IGME advancing; others proprietary or limited release.

| **Initiative** | **Code/Methods Public?** | **Repository/URL** | **Details** | **GSBPM Phase** |
|----------------|--------------------------|-------------------|------------|-----------------|
| **IGME (Mortality)** | **Partial/In Development** | R package `CME.Assistant` (not yet public; planned for 2026 release) | Bayesian B-spline code in development; academic methods papers published (Alkema 2014+); country methods sheets document adjustments | 6 (Analyse) |
| **JME (Nutrition)** | **Not Public** | Methods papers (academic journals); survey harmonization documented | EBLUP methodology in publications; code proprietary (agencies retain); academic partners have access on request | 6 (Analyse) |
| **JMP (WASH)** | **PUBLIC** | [GitHub: WHO/UNICEF JMP service ladder scripts](https://github.com/washdata) | **Most transparent**: Service ladder classification code public; documentation in English/French; actively updated; allows replication and extension | 3, 6, 7 (Build, Analyse, Disseminate) |
| **WUENIC (Immunization)** | **Not Public** | Triangulation methodology documented in papers (Burton 2009); Q&A on WHO website | Expert judgment-based; qualitative process not easily coded; code proprietary to agencies | 5, 6 (Process, Analyse) |
| **MICS (Survey Platform)** | **Partial/Open** | [MICS GitHub](https://github.com/unicef); [MICS documentation site](https://mics.unicef.org/) | Survey tools, questionnaires, SPSS syntax, sampling documentation available; analysis code on request; data dissemination standards public | 2, 3, 4, 7 (Design, Build, Collect, Disseminate) |
| **DHS (Survey Program)** | **Partial/Open** | [DHS GitHub (limited)](https://github.com/DHSProgram); [DHS documentation](https://www.dhsprogram.com/) | Questionnaire modules public; sampling documentation; Stata/SPSS analysis code available for DHS analysts; data access via DHS portal | 2, 3, 4, 7 (Design, Build, Collect, Disseminate) |
| **UIS SDG4 (Education)** | **On Request** | Methods available via UNESCO publications; code access by formal request to UIS | Methodology for OOSC (out-of-school) rates documented; education data standards public; modeling code proprietary | 6 (Analyse) |
| **UNAIDS GAM (HIV/AIDS)** | **Partial** | [Spectrum model documentation](https://www.avenirhealth.org/software-spectrum.php); AEM models documented | Spectrum epidemiological modeling software available for licensed users; methods public; full code not openly available | 6 (Analyse) |
| **UNFPA-UNICEF Child Marriage/FGM** | **Not Public** | Methods align with DHS/MICS (survey modules public); country program data proprietary | Survey-based measurement (code inherent to DHS/MICS); program monitoring uses standard M&E templates (not unique algorithms) | 4, 7 (Collect, Disseminate) |
| **ICVAC/VAC Monitoring** | **Survey Program Code** | [MICS VAC module](https://mics.unicef.org/) (public); [DHS Violence module](https://www.dhsprogram.com/) (documented) | Caregiver-reported questions available in MICS/DHS; analysis by research teams (not standardized custodian algorithm) | 2, 4, 7 (Design, Collect, Disseminate) |
| **ECDI2030 (Early Childhood)** | **Partial** | [MICS ECDI module](https://mics.unicef.org/) (public); validation studies in publications | Caregiver-reported development questions standardized; validation studies published; no proprietary analysis code (direct reporting) | 2, 4, 7 (Design, Collect, Disseminate) |

**Key Findings**:

1. **JMP Leads Transparency** (GitHub public repository for service ladder logic)
2. **Survey Infrastructure Increasingly Open** (MICS, DHS questionnaires, documentation available)
3. **Estimation Algorithms Remain Proprietary** (IGME, WUENIC, UIS models not fully public)
4. **IGME Moving Toward Transparency** (R package planned; methods papers comprehensive)
5. **Lowest Transparency**: WUENIC, JME (expert judgment-based; limited code release)
6. **Data Dissemination Infrastructure Open** (SDMX APIs, bulk downloads, UNICEF Data Warehouse standardized)

**Recommendation for IAEG-SDGs**:
- Template for code release policies (minimum: methods papers + pseudocode + sensitivity analysis scripts)
- Phased transparency roadmap (e.g., IGME R package launch; JME code release by 2027)
- GitHub guidelines for custodian agencies (licensing, documentation, maintenance standards)

**Country Consultation**:
- IGME: 6-week window; country-specific feedback portal
- JME: Consultation via UNICEF Regional Offices
- JMP: Data validation workshops (regional)
- WUENIC: Joint Reporting Form with built-in validation checks

---

## Provenance and Data Quality: SDMX Attribute Framework

### Mandatory Attributes (All Dataflows)

| Attribute | SDMX Code | Values | Interpretation | Example |
|-----------|-----------|--------|----------------|---------|
| **Data Source** | SOURCE (Src) | IGME, JME, DHS, MICS, ADMIN | Provenance of observation | `Src:IGME` = modelled estimate |
| **Observation Status** | OBS_STATUS (Stat) | A (normal), E (estimated), M (missing) | Data quality flag | `Stat:E` = model-based, not direct measure |
| **Confidence Interval** | CONF_INT (CI) | Lower, Upper bounds | Uncertainty quantification | 95% CI for mortality estimates |
| **Time Format** | TIME_FORMAT | P1Y, P1M, P1Q | Periodicity | P1Y = annual; P1M = monthly |
| **Unit of Measure** | UNIT_MEASURE | Per 1000 live births, % | Denominator/scale | Mortality: per 1000; malnutrition: % |

### Optional Attributes (Dataflow-Specific)

| Attribute | Used By | Purpose | Example |
|-----------|---------|---------|---------|
| **Reference Period** | WUENIC, UNAIDS | Sub-annual timing | Immunization campaign month |
| **Estimate Type** | IGME | Model variant | UN IGME vs national estimate |
| **Survey Round** | JME, JMP | Data vintage | DHS-7 (2018-2023) |
| **Flag** | All | Provisional data | FLAG:P = preliminary |

### Attribute Retention Rules

**Query-Time Filtering** (Dimensions):
- Sex, age, residence, wealth, indicator
- Use `unicefdata.get()` with dimension constraints

**Post-Query Annotation** (Attributes):
- Retain SOURCE, OBS_STATUS, CONF_INT in output
- Filter by `Stat:A` (observed) vs `Stat:E` (estimated) for sensitivity analysis
- Include CI in plots/tables for transparency

**Example Workflow**:
```r
# Query with dimension filter
data <- unicefdata.get(
  indicator = "CME_MRY0T4",
  sex = "Total",
  time_period = "2015-2022"
)

# Post-query attribute filtering
observed_only <- data[data$OBS_STATUS == "A", ]
modelled_only <- data[data$OBS_STATUS == "E", ]

# Uncertainty-aware analysis
if ("CONF_INT_LOWER" %in% colnames(data)) {
  plot_with_ci(data, y = "OBS_VALUE", lower = "CONF_INT_LOWER", upper = "CONF_INT_UPPER")
}
```

---


## Emerging Data Governance Challenges for SDG Monitoring

> **Context**: This section discusses policy-level challenges. For operational guidance on using governance metadata, see earlier sections on [Core Custodianship Processes](#core-custodianship-processes), [Disaggregation Policies](#disaggregation-policies-by-initiative), and [Using Governance Context](#using-governance-context-in-data-analysis).

*This section addresses current and anticipated challenges in SDG data governance, drawing on UN World Data Forum declarations, IAEG-SDGs working groups, and custodianship experiences. Intended for data users, government officials, and statistical practitioners navigating the evolving landscape of global monitoring.*

### Context: From Cape Town to Hangzhou — Evolution of SDG Data Governance

**The SDG data architecture has matured through successive UN World Data Forum commitments:**

1. **Cape Town Global Action Plan (2017)**: Established 6 strategic areas for strengthening national data systems for SDG monitoring (coordination, innovation, statistical activities, dissemination, partnerships, resources)
2. **Dubai Declaration (2018)**: Called for innovative funding mechanism under UN membership oversight to mobilize domestic and international funds; emphasized disaggregation "by income, sex, age, race, ethnicity, migration status, disability and geographic location"
3. **Bern Data Compact (2021)**: Vision "A World with Data We Trust"; 6 thematic action areas emphasizing partnerships (public-private-civil society), data literacy, trust-building, and COVID-19 response
4. **Hangzhou Declaration (2023)**: At SDG mid-point, streamlined CTGAP to 4 strategic areas (coordination, innovation/modernization, dissemination/use, partnerships); called for accelerated action and sustained investment given multiple crises
5. **Medellín Framework for Action (2024)**: Realigned CTGAP into 4 practical areas: (1) Innovation and modernization for inclusive data, (2) Use and value of data for decision-making, (3) Institutional leadership in trust/ethics, (4) Partnerships to mobilize resources; connected to Pact for the Future and Global Digital Compact

**PDFs available locally**: All five declarations/frameworks downloaded to `docs/references/` for offline reference.

**Key Governance Innovations Since 2017:**
- SDMX 2.1 standardization across custodian agencies (interoperability achieved)
- Tier classification refinement (105+ Tier I indicators; <10 Tier III remaining)
- Disaggregation workstream established (equity focus institutionalized)
- UN Data Commons launched (Google partnership for natural language data access)
- Citizen-generated data programs piloted (community accountability mechanisms)

---

### Challenge 1: Data Gaps in Fragile and Conflict-Affected States

**The Problem:**
- **25-30% of SDG data missing** from countries affected by protracted crises (Yemen, Syria, South Sudan, Afghanistan, Myanmar)
- Survey infrastructure disrupted: MICS/DHS postponed or suspended; vital registration systems collapsed
- Administrative data unreliable: Health facilities destroyed; school closures; migration undermines denominators
- Ethical constraints: Security risks prevent fieldwork; informed consent compromised in conflict zones

**Impact on Custodianship Processes:**
- **IGME**: Models mortality in data-scarce contexts but uncertainty intervals widen (±50% in some conflict zones); relies on outdated surveys (2010s data informing 2024 estimates)
- **JME**: Nutrition data from displacement camps not nationally representative; cannot model trends with <2 surveys per decade
- **WUENIC**: Administrative immunization data from fragile states flagged as "unreliable"; survey-based validation impossible
- **JMP**: WASH access in informal settlements and refugee camps not captured by standard household surveys

**Governance Responses (Documented in Hangzhou Declaration):**
1. **Rapid assessment protocols**: WHO/UNICEF piloted phone surveys in Yemen, Syria (limited geographic coverage; bias toward areas with mobile networks)
2. **Small-area estimation**: Statistical techniques extrapolate from neighboring regions (high model uncertainty; requires strong assumptions)
3. **Satellite/geospatial proxies**: JMP experiments with remote sensing for water point mapping (cannot assess service quality or household accessibility)
4. **Dual reporting with flags**: Data labeled "conflict-affected estimate" with extended uncertainty intervals; users warned against over-interpretation

**Recommendations for Data Users (Government Officials, Analysts):**
- **Check OBS_STATUS flags**: Values from conflict zones often marked "E" (estimated) with wider confidence intervals
- **Request subnational data**: National aggregates may mask sub-regional variation (e.g., stable vs. conflict-affected provinces)
- **Triangulate with qualitative evidence**: Administrative reports, humanitarian assessments, media documentation complement statistical gaps
- **Avoid spurious precision**: Do NOT report point estimates for fragile states without acknowledging data limitations

**References:**
- Hangzhou Declaration (2023), Paragraph 17: Calls for "sustained increase in investments in fragile states and low-income countries"
- IGME 2024 Report, Annex: Country-specific notes flag conflict-affected estimates
- OCHA Humanitarian Data Exchange (HDX): https://data.humdata.org/ — Complementary data from crisis zones

---

### Challenge 2: "Leave No One Behind" (LNOB) Disaggregation Feasibility

**The Problem:**
- SDG framework mandates disaggregation by "income, sex, age, race, ethnicity, migratory status, disability, geographic location" (GA Res 71/313, Para 74g)
- **Feasibility varies by domain**: Survey sample sizes insufficient for intersections (e.g., sex × wealth × disability × subnational); administrative data lack demographic variables; confidentiality rules prevent publication of small-cell counts
- **Intersectional equity analysis constrained**: Cannot assess compound marginalization (e.g., adolescent girls with disabilities in poorest wealth quintile in rural areas)

**Evidence from Custodianship Disaggregation Policies (documented in this report):**

| **Dimension** | **IGME (Mortality)** | **JME (Nutrition)** | **JMP (WASH)** | **WUENIC (Immunization)** |
|---------------|----------------------|---------------------|----------------|---------------------------|
| **Sex** | ~40 countries (vital registration only) | 95% of estimates | N/A (household-level) | Not systematically collected |
| **Wealth** | Thematic reports only | 60% of countries | 120+ countries | Not in headline estimates |
| **Subnational** | ~25 countries | Limited | 80 countries | District-level (select countries) |
| **Disability** | NOT available | NOT available | Pilot in 15 countries (MICS) | NOT available |
| **Migration status** | NOT available | NOT available | Pilot (IOM partnership) | NOT available |

**Why Disaggregation Constraints Persist:**
1. **Sample size limitations**: Rare event indicators (mortality) require 10,000+ births to detect wealth quintile differences; disability prevalence ~15% means small sub-samples
2. **Confidentiality thresholds**: Statistical disclosure control suppresses cells <25 observations (standard NSO practice)
3. **Administrative data structure**: WUENIC denominators (birth cohorts) not systematically disaggregated by sex/wealth in country reporting systems
4. **Cost-benefit trade-offs**: Oversampling vulnerable groups (e.g., persons with disabilities) expensive; most countries prioritize national representativeness

**Governance Innovations (IAEG-SDGs Disaggregation Workstream):**
- **Minimum reporting standards template**: IAEG-SDGs published matrix of expected disaggregations by indicator (e.g., "sex disaggregation mandatory for health indicators if data exist")
- **Explicit documentation of constraints**: Custodians now publish "Disaggregation Availability Matrices" (per Table in this document); avoids over-promising equity
- **Linked data pilots**: Vital registration × census linkage enables sex × education × residence for mortality (piloted in 12 countries; privacy-preserving methods required)
- **Small-area estimation**: Bayesian methods extrapolate survey data to smaller geographies (e.g., district-level nutrition from national survey); wider uncertainty intervals
- **Medellín Framework Priority 1.2 (Inclusion)**: Explicit commitment to adapt data ecosystem to users' evolving needs, providing timely, granular, and relevant data to leave no one behind

**Recommendations for Government Officials:**
- **Prioritize high-impact disaggregations**: If budget-constrained, focus on sex + wealth (captures majority of inequalities); add disability/migration status incrementally
- **Invest in administrative data linkage**: Birth/death registration linked to health insurance enrollment enables equity tracking without additional surveys
- **Use custodian matrices**: Check "Disaggregation Policies by Initiative" section in this document before requesting data; avoids impossible queries
- **Report sample sizes**: When publishing equity analyses, always include denominators (e.g., "stunting prevalence among poorest quintile girls: 35%, n=287 observations")

**References:**
- IAEG-SDGs Disaggregation Workstream: https://unstats.un.org/sdgs/iaeg-sdgs/disaggregation/
- Dubai Declaration (2018), Para 13: Specifies required disaggregation dimensions
- WHO (2016). *Health Inequality Monitoring: State of the Art and Future Directions*
- UNICEF (2022). *Seen, Counted, Included: Using Data to Shed Light on the Well-being of Children with Disabilities* — Documents disability data gaps

---

### Challenge 3: Real-Time Data vs. Statistical Rigor Trade-offs

**The Problem:**
- **Policy demand for nowcasting**: Governments need real-time SDG progress for adaptive management (e.g., "immunization coverage this month, not last year")
- **Traditional custodianship timelines slow**: IGME estimates released 12-18 months post-data collection; JME biennial; WUENIC annual with 6-month lag
- **"Data for Now" initiatives** prioritize timeliness over traditional quality controls (e.g., using mobile phone surveys, social media sentiment, satellite imagery)

**Tension: Speed vs. Accuracy**
- **Traditional approach (IGME, JME)**: Multi-year data pooling → bias adjustment → uncertainty quantification → TAG review → country consultation → release (18+ months)
- **Rapid approach (COVID-19 dashboards, humanitarian monitoring)**: Real-time data streams → minimal validation → immediate publication (days to weeks)

**Case Study: COVID-19 Disruptions to Routine Monitoring**
- **WUENIC 2020-2021 estimates**: Agencies faced incomplete administrative data (lockdowns disrupted reporting); surveys canceled (fieldwork impossible)
- **Response**: WUENIC published "provisional estimates" with FLAG:P attribute; noted "extrapolated from 2019 baseline + partial 2020 data"; wider uncertainty acknowledged
- **IGME 2020 mortality**: Vital registration gaps widened (overwhelmed health systems; under-reporting of non-COVID deaths); 80% CI intervals doubled for 40+ countries

**Emerging Governance Models (Bern Data Compact, Paragraph 5):**
1. **Dual release tracks**: "Preliminary estimates" (rapid, flagged as provisional) + "Final estimates" (fully validated, annual)
2. **Nowcasting with uncertainty**: Real-time dashboards include "prediction intervals" (e.g., "current immunization coverage estimated 75-85%, 95% CI")
3. **Transparent methodology notes**: "Data for Now" products explicitly state limitations (e.g., "mobile survey excludes households without phones; results may over-represent urban populations")
4. **Medellín Framework Priority 1.1 (Innovation)**: Promotes integration and use of different data sources from different producers and places; acknowledges "Data for Now" initiatives (Hangzhou, Para 7)

**Recommendations for Data Users:**
- **Check for provisional flags**: OBS_STATUS attribute "P" indicates preliminary data subject to revision
- **Do NOT mix time horizons**: Comparing nowcast (2024 real-time) to validated estimate (2022 final) introduces bias
- **Request revision policies**: Ask custodians when provisional data will be superseded by final estimates
- **Use for trend monitoring, not precision**: Nowcasts appropriate for "coverage increasing or decreasing?" questions; not for "coverage is 78.3% vs. 78.5%" comparisons

**References:**
- Bern Data Compact (2021), Thematic Action 1 (TA1): Develop data capacity through institutional strengthening and modernized systems
- Hangzhou Declaration (2023), Para 7: Acknowledges "Data for Now" initiatives and citizen-generated data expansion
- UN DESA (2021). *How COVID-19 is changing the world: a statistical perspective* — Documents data disruptions
- PARIS21 (2021). *Partner Report on Support to Statistics (PRESS) 2021* — Analysis of COVID-19 impacts on national statistical systems

---

### Challenge 4: Data Sovereignty vs. Global Comparability Tensions

**The Problem:**
- **National governments prioritize sovereignty**: "Official statistics are national prerogative" (FPOS Principle 1); custodian harmonization perceived as imposing external definitions
- **Global monitoring requires comparability**: SDG framework demands cross-country benchmarking; harmonized methodologies essential (e.g., JMP service ladders applied uniformly)
- **Divergent estimates create contestation**: When UN IGME estimate differs from national official estimate, governments may reject international data

**Documented Tensions:**
1. **IGME vs. National Vital Registration**: 15-20 countries publish official under-five mortality rates that diverge >10% from UN IGME (typically countries with incomplete vital registration; IGME applies completeness adjustments; NSOs contest adjustment magnitude)
2. **JMP service ladder reclassification**: Pre-2015 MDG definitions ("improved" vs. "unimproved") replaced by SDG "safely managed" ladder; some countries prefer reporting continuity over SDG alignment
3. **WUENIC admin vs. survey reconciliation**: Countries with high administrative coverage (>95%) sometimes object when WUENIC adjusts downward based on survey evidence

**Governance Solutions (IAEG-SDGs Guidance; FPOS Principle 8):**
1. **Dual reporting where divergences persist**: IGME publishes both UN IGME estimate AND national official estimate in metadata; explains methodological differences without judging correctness
2. **Country consultation windows**: 6-week consultation (IGME standard) allows NSOs to provide additional data or contest methodology; agencies document adjudication in TAG reports
3. **Metadata transparency**: Country-specific methods sheets explain adjustments (e.g., "UN IGME adjusts for 30% vital registration incompleteness based on census demographic analysis")
4. **MoU templates for co-custodianship**: IAEG-SDGs developed standardized Memoranda of Understanding specifying division of labor (e.g., "UNICEF conducts country consultation; WHO leads methodology; UN DESA provides demographic inputs")
5. **Medellín Framework Priority 4.1 (Coordination)**: Emphasizes improved coordination and cooperation mechanisms within data ecosystem to assure optimal conditions for data development

**Practical Example (IGME Consultation Process — Best Practice Model):**
1. NSO receives preliminary estimates + data sources used + adjustments applied
2. NSO can: (a) Accept estimates; (b) Provide new data (e.g., recent census, updated vital registration); (c) Contest adjustments with evidence
3. Agencies re-run models if new data credible; document decision if NSO input not incorporated
4. Final release includes both UN IGME and national official estimates where divergence >10%; metadata explains difference

**Recommendations for Government Officials:**
- **Engage in consultation windows**: Custodian portals publish consultation calendars; provide national data proactively (don't wait for estimates release)
- **Document methodological choices**: If national methodology differs from international harmonization, publish transparent methods justification
- **Use dual reporting**: Cite both estimates in policy briefs; explain divergence (e.g., "UN IGME accounts for under-registration; national estimate uses unadjusted vital registration")
- **Advocate for capacity building**: Request technical assistance to strengthen vital registration/administrative systems (reduces divergence over time)

**References:**
- FPOS Principle 1: "Official statistics provide an indispensable element in the information system of a democratic society... practical utility... impartiality"
- FPOS Principle 8: "Coordination among statistical agencies... essential to achieve consistency and efficiency"
- UN General Assembly Resolution 71/313 (2017): Endorses global indicator framework while respecting national sovereignty

---

### Challenge 5: Data Privacy, Ethics, and Responsible AI in Statistical Estimation

**The Problem:**
- **New data sources raise privacy risks**: Mobile phone data, social media scraping, satellite imagery of households → risk of re-identification even with anonymization
- **Algorithmic bias in modeling**: Machine learning methods (used experimentally for poverty mapping, disease surveillance) can perpetuate historical inequalities if training data biased
- **Consent challenges in secondary data use**: Survey respondents consented to specific use (e.g., "health survey"); using microdata for AI training raises ethical questions
- **Tension between transparency and privacy**: Bern Data Compact TA5 calls to "protect privacy and confidentiality while maintaining transparency and accessibility of data that is of public interest"

**Emerging Practices in Custodianship:**
1. **MICS/DHS data access protocols**: Three-tier system: (a) Public Use Files (PUF) with geographic anonymization; (b) Restricted-access microdata for researchers (IRB review required); (c) Fully identified data only for NSOs
2. **Differential privacy pilots**: UN DESA experimenting with noise injection in census microdata to prevent re-identification while preserving statistical validity
3. **Algorithmic transparency requirements**: IAEG-SDGs Task Team on Lessons Learned recommends custodians publish AI model cards (training data, performance metrics, known biases) if machine learning used

**Case Study: Poverty Mapping with Satellite Imagery + Machine Learning**
- **Method**: WorldPop/Meta use satellite images + machine learning to estimate poverty at 1km² resolution (finer than survey-based estimates)
- **Privacy risks**: Satellite images reveal household infrastructure (roof type, proximity to roads); combined with auxiliary data, could re-identify individuals
- **Bias risks**: Training data from high-income countries; models underperform in informal settlements, nomadic populations
- **Governance response**: World Bank Poverty & Equity Global Practice requires: (a) Open-source code; (b) Validation against ground-truth surveys; (c) Metadata flags where model accuracy <70%

**Recommendations for Government Officials:**
- **Establish national data ethics boards**: Review custodianship data use; assess privacy risks; approve AI applications in official statistics (aligned with Medellín Framework Priority 3.1 on ethical data)
- **Require algorithmic audits**: If custodians use machine learning, request bias assessments (e.g., "Does poverty map underestimate rural poverty?")
- **Strengthen consent language**: Update survey protocols to specify "data may be used for secondary research subject to ethics review"
- **Invest in statistical disclosure control**: Train NSO staff in k-anonymity, differential privacy, suppression rules (Medellín Framework Priority 3.2 on confidentiality and protection)
- **Apply Fundamental Principles throughout**: Medellín Framework Priority 3.3 calls to "find new and effective ways to apply and reimagine the Fundamental Principles of Official Statistics to strengthen trust"

**References:**
- Bern Data Compact (2021), TA5: Build trust in data through law, regulation, and common practices balancing privacy/confidentiality with transparency
- Medellín Framework (2024), Area 3: Institutional leadership in building trust, protection and ethics of data and statistics
- UN Global Pulse (2017). *Integrating Big Data into the Monitoring of Sustainable Development* — Ethical framework
- OECD (2019). *Recommendation on Artificial Intelligence* — Principles for trustworthy AI (transparency, accountability, fairness)
- Paris21 (2020). *Navigating the Storm: The COVID-19 Pandemic and National Statistical Systems* — Documents privacy trade-offs in emergency data collection

---

### Challenge 6: Financing Statistical Capacity Building — The $1 Billion Annual Gap

**The Problem:**
- **Global statistical capacity needs**: $1.0-1.5 billion/year required to close SDG data gaps (Cape Town Global Action Plan costing)
- **Current funding**: ~$600 million/year (2022 PARIS21 PRESS survey); 40% shortfall persists
- **Low-income countries most affected**: 60% of Tier I indicators not produced annually in 35+ low-income countries (lack of survey infrastructure, weak vital registration, insufficient analytical capacity)

**Fragmented Financing Landscape:**
- **Bilateral donors**: DFID/FCDO (UK), USAID, BMZ (Germany), DFAT (Australia), AFD (France) provide $300M/year; often project-based (MICS, census support); limited core NSO funding
- **Multilateral mechanisms**: World Bank Trust Fund for Statistical Capacity Building ($80M/year); Global Financing Facility ($30M data component); UN COVID-19 Response and Recovery Fund ($20M statistics)
- **Philanthropic**: Gates Foundation ($50M/year, health data focus); Hewlett, Packard foundations (smaller allocations)
- **Domestic budgets**: NSOs receive 0.1-0.3% of government budgets on average (below 1% threshold recommended by PARIS21)

**Dubai Declaration Innovation: Brokerage Platform**
- **Dubai Declaration (Para 17) Proposal**: "Establishment of an innovative funding mechanism, open to all stakeholders under UN membership oversight, that is able to respond in a fast and efficient manner to the priorities of national data and statistical systems"; mechanism to be "entirely demand-driven" under UN Statistical Commission mandate; serviced by Secretariat at international institution with global membership
- **Status (as of 2024)**: Pilot launched by UNSD with $50M initial capitalization; 12 countries receiving support (Tanzania, Bangladesh, Nepal, Senegal, etc.)
- **Early results**: Reduced project preparation time from 18 months → 6 months; increased coordination (fewer duplicate surveys)

**Innovative Financing Models (Hangzhou Declaration, Para 14-15):**
1. **Data Dividend Model**: Governments co-invest in statistical systems with expectation of policy returns (e.g., "improving poverty data enables better-targeted social programs, reducing leakage by 10-15%")
2. **Public-Private Partnerships**: Mobile network operators share call detail records for population mobility mapping (used for crisis response, urban planning); NSOs retain analytical control (Bern Data Compact TA2: Establish partnerships removing barriers to new data sources while respecting privacy)
3. **Results-Based Financing**: Donors pay upon delivery of statistical outputs (e.g., "census completion + microdata release within 2 years triggers payment tranche")
4. **Medellín Framework Priority 4.2**: Promote sustainable investment in data and statistical capacities, leveraging public-private partnerships; connected to Pact for the Future data governance commitments

**Recommendations for Government Officials:**
- **Increase domestic NSO budgets**: Target 0.5-1% of government expenditure for statistics (currently 0.1-0.3%)
- **Legislate statistical authority**: Laws mandating administrative data sharing with NSOs (health facilities, schools, tax authorities must provide data)
- **Request pooled donor support**: Prefer basket funds (multiple donors, one harmonized country plan) over fragmented bilateral projects
- **Publish statistical development strategies**: Multi-year plans clarify funding needs; enable donor alignment

**References:**
- Dubai Declaration (2018), Para 16-17: Mobilize financing at domestic/international levels; establish innovative funding mechanism under UN Statistical Commission
- Bern Data Compact (2021), TA6: Increase investments to address data gap; develop all data sources; close digital divide
- Hangzhou Declaration (2023), Para 14-15: Urgent and sustained increase in investment needed; marginal investments yield massive efficiency gains
- Medellín Framework (2024), Priority 4.2: Sustainable investment in data capacities
- PARIS21 (2023). *Partner Report on Support to Statistics 2023* — Comprehensive financing analysis; $600M annual flows documented
- World Bank (2021). *Statistical Capacity Indicator Dashboard* — Tracks capacity by country; identifies financing gaps

---

### Challenge 7: Interoperability and Data Ecosystem Fragmentation

**The Problem:**
- **Vertical data silos persist**: Health data (WHO GHO), education (UIS), poverty (World Bank), climate (IPCC) operate on separate platforms with incompatible schemas
- **SDMX adoption incomplete**: While custodian agencies adopted SDMX 2.1, many NSOs still disseminate via Excel/PDF; API coverage ~50% of countries
- **Geospatial-statistical integration limited**: JMP uses survey GPS coordinates for subnational disaggregation; but most custodianship processes don't systematically link to geospatial datasets (land cover, infrastructure, climate exposure)

**Impact on Users:**
- **Analysts waste time on data wrangling**: Harmonizing country codes, indicator definitions, temporal alignment across portals
- **Policy makers miss cross-sectoral insights**: Cannot easily analyze "overlap between poor WASH access, child malnutrition, and low learning outcomes" (data live in separate systems)

**Governance Solutions (UN Data Commons; SDMX Working Group):**
1. **UN Data Commons for SDGs** (launched 2024): Google-powered natural language search across custodian databases; single query retrieves data from multiple agencies
2. **SDMX Data Structure Definitions (DSDs)**: Standardized dimension/attribute schemas published by IAEG-SDGs; enables cross-agency queries
3. **Federated data architecture**: Custodians retain data sovereignty; UN Data Commons acts as metadata aggregator + query router (doesn't centralize data)

**Geospatial Integration Pilots:**
- **JMP-GRID3 Partnership**: Links WASH survey data to high-resolution population grids (1km²); enables infrastructure planning ("where to build water points?")
- **IGME-WorldPop**: Combines mortality estimates with gridded population to identify high-burden sub-districts
- **UNICEF GeoNode**: Publishes MICS survey geographic data under creative commons license; enables researcher mashups

**Recommendations for Data Users:**
- **Use federated search platforms**: UN Data Commons, HDX (Humanitarian Data Exchange), World Bank Data Catalog (reduce time searching across portals)
- **Request SDMX APIs**: If NSO provides only static files, advocate for API development (enables automated dashboards)
- **Link geospatial + statistical data**: Use survey GPS coordinates (anonymized to protect confidentiality) for spatial analysis
- **Contribute to schema harmonization**: Provide feedback to IAEG-SDGs SDMX Working Group on usability gaps

**References:**
- UN Data Commons: https://unstats.un.org/UNSDWebsite/undatacommons/sdgs
- IAEG-SDGs SDMX Working Group: https://unstats.un.org/sdgs/iaeg-sdgs/sdmx-working-group/
- UN-GGIM (Global Geospatial Information Management): https://ggim.un.org/ — Leads geospatial-statistical integration

---

### Governance Roadmap: Key Actions for Data Users and Government Officials

**For National Statistical Offices (NSOs):**
1. **Participate in custodianship consultation windows** (IGME, JME, JMP, WUENIC publish calendars; provide national data proactively)
2. **Adopt SDMX for dissemination** (enables interoperability; IAEG-SDGs provides templates and technical assistance)
3. **Publish disaggregation availability matrices** (document which intersections are feasible; avoid over-promising equity)
4. **Establish data ethics boards** (review AI use, privacy risks in administrative data linkage, secondary data use)
5. **Increase domestic statistical budgets** (target 0.5-1% of government expenditure; legislate mandatory administrative data sharing with NSO)

**For Data Users (Analysts, Researchers, Civil Society):**
1. **Check OBS_STATUS and SOURCE attributes** (distinguish observed vs. modeled data; trace provenance)
2. **Report uncertainty** (include confidence intervals where available; avoid spurious precision)
3. **Use custodian metadata repositories** (IAEG-SDGs, initiative portals document methodology changes, data gaps, revision policies)
4. **Advocate for transparency** (request public TAG reports, code repositories, country consultation summaries)
5. **Triangulate across sources** (compare custodian estimates to national official statistics; qualitative research; administrative records)

**For Donors and Development Partners:**
1. **Align funding with national statistical strategies** (prefer basket funds over fragmented bilateral projects)
2. **Support long-term core capacity** (NSO infrastructure, staff salaries) not only survey projects
3. **Require open data policies** (development-funded data collection must be publicly accessible; SDMX-compliant)
4. **Invest in interoperability** (SDMX infrastructure, API development, geospatial-statistical linkages)

---


## Using Governance Context in Data Analysis

### Pre-Analysis Checklist

**1. Verify Disaggregation Availability**
- Check initiative-specific policies (see Disaggregation Policies section)
- Use discovery commands: `unicefdata.list_dimensions(indicator)` or `unicefdata.info(indicator)`
- Do NOT assume sex × wealth intersections exist without verification

**2. Understand Provenance**
- Read SOURCE attribute: Survey data (Src:DHS, Src:MICS) vs modelled (Src:IGME, Src:JME)
- Check OBS_STATUS: Observed (Stat:A) vs Estimated (Stat:E)
- For modelled data, consult methodology sheets for assumptions

**3. Account for Uncertainty**
- Always report confidence intervals where available (IGME, JME)
- For survey-based estimates, note sample size and design effect
- Avoid spurious precision (e.g., reporting 34.78% from modelled estimate)

**4. Respect Temporal Comparability**
- JMP service ladders: Pre-2015 data not SDG-aligned
- WUENIC: Administrative data revisions common (check change log)
- IGME: Methodology updates may cause breaks in series (documented in TAG reports)

### Citation Requirements

**Format**:
> [Custodian Agency]. (Year). [Indicator Name]. [Database Name]. Retrieved [Date] from [URL].

**Examples**:
- UNICEF, WHO, UN DESA, World Bank (2023). Under-five mortality rate. UN IGME Child Mortality Estimates. Retrieved January 2026 from https://childmortality.org/
- UNICEF, WHO, World Bank (2023). Prevalence of stunting among children under 5 years. Joint Child Malnutrition Estimates. Retrieved January 2026 from https://data.unicef.org/resources/jme/
- WHO/UNICEF (2024). DTP3 immunization coverage. WHO/UNICEF Estimates of National Immunization Coverage (WUENIC). Retrieved January 2026 from https://immunizationdata.who.int/

**Methods Section Text**:
> Data were obtained from the [Initiative Name], which harmonizes [data sources] using [methodology]. Estimates are validated by a Technical Advisory Group and subject to country consultation. [For modelled data:] Uncertainty is quantified via [method] and presented as 95% confidence intervals.

### Reporting Standards

**Tables**:
- Include SOURCE column for mixed-provenance data
- Flag modelled estimates with superscript (e.g., ᵃ = IGME estimate)
- Report uncertainty intervals in parentheses or separate columns

**Figures**:
- Distinguish observed (solid line) vs modelled (dashed line) in time series
- Show confidence intervals as shaded regions or error bars
- Annotate breaks in series (e.g., JMP 2015 ladder revision)

**Narrative**:
- Specify custodian agency and release year
- Explain limitations (e.g., "Sex-disaggregated mortality not available globally due to vital registration gaps")
- Contextualize outliers (e.g., "Survey non-response may bias wealth quintile estimates")

---

## Why Data Governance Is Critical for Open Data and the UNICEF Data Warehouse

Understanding data governance is foundational to trustworthy Open Data and a reliable UNICEF Data Warehouse. Governance translates statistical principles into practical rules for how data are described, versioned, accessed, and safeguarded. Without it, Open Data becomes ambiguous, hard to reproduce, and risky to use.

### Why It Matters for Open Data
- **Findability & metadata**: Machine-readable SDMX structures (DSDs, codelists, attributes) make datasets discoverable and interpretable; they prevent mislabeling of indicators, units, and disaggregations. See [Provenance and Data Quality: SDMX Attribute Framework](#provenance-and-data-quality-sdmx-attribute-framework).
- **Provenance & versioning**: Clear SOURCE, OBS_STATUS, and release calendars enable reproducible research and transparent updates when methodologies change. See [Release Cadence and Transparency Protocols](#release-cadence-and-transparency-protocols).
- **Interoperability & access**: Consistent APIs and dimension filters allow integration across initiatives (IGME, JME, JMP, WUENIC) and with geospatial or survey microdata.
- **Licensing & citation**: Terms of use and citation norms protect openness while ensuring proper attribution; stable URLs and DOIs support long-term reuse.
- **Privacy & ethics**: De-identification rules, suppression policies, and disclosure control uphold the Fundamental Principles of Official Statistics while enabling equity analysis.
- **Quality & timeliness**: Published calendars, change logs, and TAG governance sustain user trust; corrections are documented and traceable.

### Why It Matters for the UNICEF Data Warehouse
- **Unified SDMX model**: Harmonized dimensions and attributes (`AGE`, `SEX`, `WEALTHQ`, `UNIT_MEASURE`, `OBS_STATUS`) ensure consistent queries across domains.
- **Comparable analytics**: Governance flags (observed vs estimated, quality notes) drive correct charting, aggregations, and caveats in dashboards.
- **Efficient operations**: Clear deprecation notices and migration guides reduce breakage when endpoints or structures evolve.
- **Cost-aware access**: Guidance on pagination, caching, and scoped queries prevents wasteful calls and improves performance for users and pipelines.
- **User guidance**: Governance-aligned helpers (e.g., `unicefdata.list_dimensions`, `unicefdata.info`) steer users toward valid disaggregations and citeable outputs.

### Practical Checklist for Warehouse/Open Data Workflows
- Confirm disaggregation availability before building dashboards (see [Disaggregation Policies by Initiative](#disaggregation-policies-by-initiative)).
- Include provenance and OBS_STATUS in tables and tooltips (see [Provenance and Data Quality: SDMX Attribute Framework](#provenance-and-data-quality-sdmx-attribute-framework)).
- Align releases with custodians’ calendars; log changes and note methodological updates (see [Release Cadence and Transparency Protocols](#release-cadence-and-transparency-protocols)).
- Apply ethical safeguards and respect suppression rules; document limitations (see [Guardrails Against Hallucination and Misuse](#guardrails-against-hallucination-and-misuse)).
- Follow the [Pre-Analysis Checklist](#pre-analysis-checklist) before publication.

---

## Guardrails Against Hallucination and Misuse

> **Note**: This section complements the [Pre-Analysis Checklist](#pre-analysis-checklist) at the end of this document.

### 1. Verify All Claims Against Primary Sources

**Do NOT**:
- State "UNICEF collects data directly" (UNICEF compiles; NSOs collect)
- Claim disaggregations exist without checking (e.g., "WUENIC provides sex-disaggregated coverage" is FALSE)
- Invent methodology details not in official documentation

**DO**:
- Link claims to URLs in References section
- Quote methodology sheets verbatim for technical details
- State "not documented" if information is unavailable

### 2. Respect Data Availability Constraints

**Do NOT**:
- Request sex × wealth intersections for IGME without verifying country-specific availability
- Assume institutional WASH data are complete (only 30-50% country coverage)
- Pool pre-2015 and post-2015 JMP data (ladder definitions changed)

**DO**:
- Check coverage notes on initiative portals
- Use `unicefdata.coverage(indicator)` to verify availability
- Report sample sizes for disaggregated estimates

### 3. Acknowledge Methodological Limitations

**Do NOT**:
- Present modelled estimates as observed data (check OBS_STATUS)
- Ignore uncertainty intervals (essential for IGME, JME)
- Compare across initiatives without noting methodological differences

**DO**:
- State "IGME estimates are model-based, not direct measurements"
- Report "JME uses EBLUP smoothing; single-year spikes may be survey artifacts"
- Note "WUENIC triangulates admin and survey data; neither is ground truth"

### 4. Trace Provenance Chain

**Minimum Disclosure**:
1. **Data Source**: Survey (DHS/MICS/national) or administrative system
2. **Compiler**: UNICEF, WHO, joint initiative
3. **Methodology**: Observed, modelled, or hybrid
4. **Validation**: Country consultation (yes/no)
5. **Uncertainty**: Confidence interval or standard error

**Example**:
> Under-five mortality estimates for Nigeria (2015-2022) were obtained from the UN IGME, which applies Bayesian B-spline models to DHS and MICS survey data. Estimates were validated via country consultation and include 95% confidence intervals (Source: childmortality.org, accessed Jan 2026).

### 5. Flag Provisional or Incomplete Data

**Indicators**:
- FLAG:P (provisional) = subject to revision
- OBS_STATUS:M (missing) = no data for this intersection
- CONF_INT missing = uncertainty not quantified (be cautious)

**Reporting**:
- "Estimates are provisional pending country validation" (if FLAG:P)
- "Data not available for [dimension]" (if Stat:M)
- "Confidence intervals not provided; interpret with caution" (if CI missing)

---

## Quick Reference: Key Custodianship Portals

### Inter-Agency Custodianship Portals

- **IGME**: https://childmortality.org/
  - Methods: https://childmortality.org/methods
  - 2023 TAG Report: https://childmortality.org/wp-content/uploads/2024/01/TAG-2023-Report.pdf
  
- **JME**: https://data.unicef.org/resources/jme/
  - 2023 Report: https://data.unicef.org/resources/jme-report-2023/
  
- **JMP**: https://washdata.org/
  - Governance: https://washdata.org/how-we-work
  - 2024 Report: https://washdata.org/report/jmp-2024-wash-in-households
  
- **WUENIC**: https://immunizationdata.who.int/
  - WHO GHO: https://www.who.int/data/gho/data/themes/immunization
  - Methods Q&A: https://www.who.int/teams/immunization-vaccines-and-biologicals/immunization-analysis-and-insights/global-monitoring/immunization-coverage/who-unicef-estimates-of-national-immunization-coverage

### Supplementary Initiatives

- **UNAIDS GAM**: https://www.unaids.org/en/global-aids-monitoring
  - ART Online: https://aidsreportingtool.unaids.org/
  
- **UIS SDG4**: https://www.uis.unesco.org/en
  - Data Browser: https://databrowser.uis.unesco.org/
  - SDG 4 Scorecard: https://www.unesco.org/en/sdg4scorecard-dashboard
  
- **UNFPA-UNICEF Child Marriage**: https://www.unicef.org/protection/child-marriage
  - Data: https://data.unicef.org/topic/child-protection/child-marriage/
  
- **UNFPA-UNICEF FGM**: https://www.unfpa.org/unfpa-unicef-joint-programme-on-female-genital-mutilation
  - Data: https://data.unicef.org/topic/child-protection/female-genital-mutilation/

### UN Statistical Standards

- **IAEG-SDGs**: https://unstats.un.org/sdgs/iaeg-sdgs/
  - Tier Classification: https://unstats.un.org/sdgs/iaeg-sdgs/tier-classification/
  
- **GSBPM v5.1**: https://statswiki.unece.org/display/GSBPM
  
- **DQAF**: https://www.imf.org/external/pubs/ft/dqrs/dqaf.pdf

### Peer-Reviewed Methods Literature

- **IGME Methodology**: Alkema et al. (2014). "National, regional, and global sex ratios of infant, child, and under-5 mortality and identification of countries with outlying ratios: a systematic assessment." *The Lancet Global Health* 2(9):e521-e530. https://doi.org/10.1016/S2214-109X(14)70280-7

- **JME Methodology**: Heidkamp et al. (2021). "Mobilising evidence, data, and resources to achieve global maternal and child undernutrition targets and the Sustainable Development Goals: an agenda for action." *The Lancet* 397(10282):1286-1294. https://doi.org/10.1016/S0140-6736(21)00568-7

- **JMP Methodology**: WHO/UNICEF (2021). *Progress on household drinking water, sanitation and hygiene 2000-2020: Five years into the SDGs*. ISBN: 978-92-4-001755-4

- **WUENIC Methodology**: Burton et al. (2009). "WHO and UNICEF estimates of national infant immunization coverage: methods and processes." *Bulletin of the World Health Organization* 87(7):535-541. https://doi.org/10.2471/BLT.08.053819

---


---

## Document Changelog

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | Nov 2024 | Initial draft covering IGME, JME, JMP, WUENIC | UNICEF Data Team |
| 2.0 | Jan 2026 | **MAJOR REVISION**: Transformed into comprehensive data governance primer. Added: (1) UNICEF multisectoral positioning section; (2) Comparative governance table (16 dimensions × 4 initiatives); (3) 5 transferable governance lessons for SDG monitoring; (4) UN FPOS (Fundamental Principles of Official Statistics) alignment; (5) GSBPM/DQAF mapping; (6) Expanded disaggregation policies; (7) Anti-hallucination guardrails; (8) Peer-reviewed methods citations | Governance focus; lessons from UNICEF experience |
| 2.1 | Jan 2026 | **STRUCTURAL IMPROVEMENTS**: (1) Removed 139 lines of duplicate content (summaries, policies, guidance already present in earlier sections); (2) Added 7 strategic cross-references for improved navigation; (3) Reorganized section order: moved "Emerging Challenges" earlier (policy context before operational guidance), moved "Document Changelog" to end (metadata at terminus); (4) Renamed "Cross-Links" → "Quick Reference: Key Custodianship Portals" for clarity; (5) Verified all internal links remain valid after reorganization | Document structure optimization; improved findability and flow |

---

**Document Scope**: This is both (1) **Data Governance Primer** for SDG monitoring (transferable frameworks), and (2) **Technical Reference** for `unicefData` package (provenance, quality, disaggregation context).

**Key Contributions**:
- **Comparative Analysis**: First systematic comparison of governance arrangements across IGME, JME, JMP, WUENIC (transparency, TAG structures, country consultation, disaggregation policies)
- **UNICEF's Unique Lens**: Demonstrates how multisectoral breadth (health, nutrition, WASH, education, protection, social protection) enables governance experimentation and cross-domain learning
- **Transferable Lessons**: 5 evidence-based lessons applicable to all SDG custodian agencies (governance intensity, transparency, country consultation, disaggregation feasibility, inter-agency coordination)
- **Operational Guidance**: Templates for MoUs, disaggregation matrices, country consultation protocols, TAG report structures

---

**End of Document**

*For questions or corrections, contact: UNICEF Data and Analytics Section | data@unicef.org*

---

### Summary: Navigating SDG Data Governance for Evidence-Based Policy

**Key Takeaways for Government Officials:**

1. **Data governance is evolving rapidly**: From Cape Town (2017) to Medellín (2024), emphasis shifted from capacity building → partnerships & innovation → sustained financing → practical implementation framework. Stay engaged with the UN World Data Forum process.

2. **"Leave No One Behind" is constrained by feasibility**: Dubai Declaration (2018) mandates disaggregation "by income, sex, age, race, ethnicity, migration status, disability and geographic location," but not all intersections are technically possible. Use custodian matrices in this document to plan realistic equity monitoring.

3. **Transparency builds trust**: Public TAG reports (IGME model), code repositories (JMP GitHub), country consultation (WUENIC JRF) reduce contestation and improve data quality.

4. **Invest domestically**: NSOs with <0.3% government budget cannot deliver SDG monitoring. Dubai Declaration (Para 16) calls to "mobilise financing at domestic and international levels"; increase allocations; legislate administrative data sharing; adopt SDMX.

5. **Privacy-utility trade-offs require governance**: Bern Data Compact (TA5) and Medellín Framework (Area 3) emphasize balancing privacy/confidentiality with transparency. Establish ethics boards and require algorithmic audits for AI in official statistics.

**References for Deep Dives:**

- **Cape Town Global Action Plan (2017)**: Foundational strategy for SDG data systems; 6 strategic areas (coordination, innovation, partnerships, LNOB, modernization, resources)
 **Dubai Declaration (2018)**: Innovative funding mechanism under UN Statistical Commission; disaggregation mandate; call for $1B/year increase
- **Bern Data Compact (2021)**: COVID-19 lessons; rapid data response; partnerships across public-private-civil society; data literacy
- **Hangzhou Declaration (2023)**: Mid-point stocktaking; renewed call for sustained investment; streamlined CTGAP strategic areas; data stewardship approach
 **Hangzhou Declaration (2023)**: Mid-point stocktaking; renewed CTGAP commitment; streamlined to 4 strategic areas; data stewardship approach; urgent call for investment
 - **Medellín Framework for Action (2024)**: Realigned CTGAP into 4 practical areas with 12 priorities; connected to Pact for the Future and Global Digital Compact; action-oriented implementation framework

**All PDFs downloaded locally**: Available in `docs/references/` folder for offline access and citation (Bern, Dubai, Hangzhou, Medellín).

---

### Primary Custodianship Initiative Portals & Reports

**Child Mortality (UN IGME)**
- **Portal & Data**: https://childmortality.org/ — Interactive database, country profiles, estimates for under-five mortality, neonatal mortality, stillbirths, and causes of death; includes 195 countries back to 1950
- **Methods Documentation**: https://childmortality.org/methods — Technical overview of Bayesian B-spline modeling, bias adjustment procedures, uncertainty quantification
- **Country-Specific Methodological Notes**: https://childmortality.org/wp-content/uploads/2024/03/UNIGME-2024-Methodology-Sheet.xlsx — Detailed methods sheets for each country; documents data sources, adjustments, convergence notes
- **2024 Annual TAG Report**: https://childmortality.org/wp-content/uploads/2025/03/UNIGME-2024-Child-Mortality-Report.pdf — Transparency on methodological changes, TAG recommendations, country consultation outcomes
- **2024 Stillbirth Report**: https://childmortality.org/wp-content/uploads/2025/03/UNIGME-Stillbirth-Report-2024.pdf — Dedicated stillbirth estimates and policy implications
- **UNICEF Data Warehouse**: https://data.unicef.org/ — SDMX 2.1-compliant API for programmatic access to IGME and other custodianship data

**Child Malnutrition (Joint Child Malnutrition Estimates)**
- **JME Portal & Reports**: https://data.unicef.org/resources/jme/ — Stunting, wasting, underweight, overweight estimates; 2023 report with latest data and equity breakdowns
- **2023 Full Report**: https://data.unicef.org/resources/jme-report-2023/ — Comprehensive analysis of nutritional status, trends, inequalities, and policy implications
- **Interactive Dashboards**: Available via data.unicef.org; enables filtering by country, indicator, year, and demographics (sex, wealth, residence)
- **EBLUP Methodology Papers**: Published in peer-reviewed journals (see Heidkamp et al. 2021 below)

**WASH Access (WHO/UNICEF Joint Monitoring Programme)**
- **JMP Portal**: https://washdata.org/ — Global WASH database with 5,300+ national datasets; 2025 report on household WASH with focus on inequalities
- **Interactive Data Portal**: https://washdata.org/data/household#!/ — User-friendly visualization and download platform for service ladder data (basic, limited, unimproved, open defecation)
- **Governance & Methods**: https://washdata.org/how-we-work — Describes TAG structure, country consultation processes, quality assurance mechanisms, and funding partnerships
- **2025 Household Report**: https://washdata.org/reports/jmp-2025-wash-households — Recent comprehensive analysis with focus on inequality (urban/rural, rich/poor, regional)
- **2024 Schools Report**: https://washdata.org/reports/jmp-2024-wash-schools — WASH in schools with thematic focus on menstrual health and period poverty
- **2024 Health Care Facilities Report**: https://washdata.org/reports/jmp-2024-wash-hcf — WASH in health facilities (limited coverage) with service readiness assessments

**Immunization Coverage (WHO/UNICEF Estimates of National Immunization Coverage)**
- **WUENIC Portal**: https://immunizationdata.who.int/ — Interactive dashboard with coverage estimates for 15+ routine vaccines; 1980-present time series; disease surveillance data; country profiles
- **WHO GHO (Global Health Observatory)**: https://www.who.int/data/gho/data/themes/immunization — SDMX-compliant API access to immunization data; embedded in UN SDG data platforms
- **Transparency Q&A**: https://www.who.int/teams/immunization-vaccines-and-biologicals/immunization-analysis-and-insights/global-monitoring/immunization-coverage/who-unicef-estimates-of-national-immunization-coverage — Frequently asked questions on methodology, data discrepancies, revision practices
- **Immunization Agenda 2030 (IA2030) Scorecard**: https://scorecard.immunizationagenda2030.org/ — Dashboard tracking progress toward IA2030 targets; includes coverage and program indicators
- **Joint Reporting Form (JRF)**: https://www.who.int/teams/immunization-vaccines-and-biologicals/immunization-analysis-and-insights/global-monitoring/immunization-coverage/data-collection-and-management — Annual country reporting system; input to WUENIC estimates
- **Regional Immunization Technical Advisory Group (RITAG) Structure**: Documented via WHO regional office pages; RITAGs provide country-level technical oversight

**Education (UNESCO Institute for Statistics - SDG 4 Monitoring)**
- **UIS Main Portal**: https://www.uis.unesco.org/en — Comprehensive education statistics covering access, completion, learning outcomes across SDG 4 indicators
- **UIS Data Browser**: https://databrowser.uis.unesco.org/ — Interactive data visualization tool for SDG 4 indicators; disaggregation by region, country, income level
- **SDG 4 Scorecard Dashboard**: https://www.unesco.org/en/sdg4scorecard-dashboard — Annual monitoring dashboard tracking progress toward SDG 4 targets
- **Out-of-School Children (OOSC) Initiative**: UNICEF-UIS partnership; methodology documented in "Fixing the Broken Promise of Education for All" (UNESCO-UIS/UNICEF, 2016)
- **Global Alliance to Monitor Learning (GAML)**: https://gaml.org/ — Coordinates learning assessment frameworks and global reporting on learning outcomes

**Survey Programmes & Infrastructure (MICS, DHS)**
- **MICS Programme**: https://mics.unicef.org/ — Portal for 120+ Multiple Indicator Cluster Surveys conducted in 110+ countries since 1995; tools, technical documentation, data access
- **MICS Tools**: Comprehensive guidance on survey design, questionnaire modules (child health, education, protection, WASH, nutrition), data processing, quality assurance
- **MICS Data Repository**: Access to anonymized microdata and survey-level estimates; harmonized across countries
- **DHS Program**: https://www.dhsprogram.com/ — Demographic and Health Surveys; 100+ countries; DHS data contributes to custodianship process estimates (IGME, JME, JMP, WUENIC)
- **DHS Methodology Reports**: Published per country survey; documents sampling, fieldwork procedures, data quality assessments

**HIV/AIDS Monitoring (UNAIDS Global AIDS Monitoring)**
- **GAM 2025 Portal**: https://www.unaids.org/en/global-aids-monitoring — Annual reporting framework for HIV/AIDS indicators aligned with Global Fund, PEPFAR, and SDG monitoring
- **ART Online Reporting Tool**: https://aidsreportingtool.unaids.org/ — Country data submission and progress tracking system
- **Spectrum Model Documentation**: https://www.avenirhealth.org/software-spectrum.php — Epidemiological modeling software used for estimates of HIV incidence, treatment coverage, and impact
- **UNAIDS Data**: https://www.unaids.org/en/datavisualization — Data visualizations and country-specific profiles for HIV/AIDS indicators
- **Reference Group on Estimates, Modelling and Projections**: UNAIDS technical oversight body; members include academic statisticians and epidemiologists

**Child Protection Initiatives**
- **UNICEF Child Marriage**: https://www.unicef.org/protection/child-marriage — Overview, evidence, programme context; linked to data portal https://data.unicef.org/topic/child-protection/child-marriage/
- **UNFPA-UNICEF Joint Programme on Elimination of Female Genital Mutilation**: https://www.unfpa.org/unfpa-unicef-joint-programme-on-female-genital-mutilation — Integrated programme combining advocacy, policy change, and service delivery; contributes to SDG 5.3 (harmful practices) monitoring
- **UNICEF FGM Overview**: https://www.unicef.org/protection/female-genital-mutilation — Evidence base, country profiles, data: https://data.unicef.org/topic/child-protection/female-genital-mutilation/
- **UNICEF Violence Against Children**: https://www.unicef.org/protection/violence-against-children — Evidence, interventions, monitoring framework; incorporates MICS and DHS data
- **International Child Victimization Survey (ICVAC)**: https://www.worldchildrenstudy.org/ — Expands VAC monitoring to adolescent-reported experiences; 35+ countries
- **UNICEF Child Labour**: https://www.unicef.org/protection/child-labour — Evidence base and monitoring via MICS/ILO partnerships
- **SARA-ECD (Service Availability and Readiness Assessment for Early Childhood Development)**: https://www.who.int/teams/maternal-newborn-child-adolescent-health/child-health/sara — Facility-based assessment tool for ECD service readiness; 90+ countries

**Early Childhood Development (ECDI2030)**
- **UNICEF ECD Overview**: https://www.unicef.org/early-childhood-development — Comprehensive evidence on early childhood development; programme context; links to data and research
- **ECDI2030 Framework**: https://www.unicef.org/reports/ecdi2030-framework — Technical specification of Early Childhood Development Index 2030; developmental domains, caregiver-reported items, validation studies
- **UNESCO Learning Poverty Dashboard**: https://www.unesco.org/en/education/learning-poverty — Complementary indicator on learning outcomes for school-age children
- **MICS ECDI Module**: https://mics.unicef.org/ — Standardized ECDI items in MICS surveys; 110+ countries with comparable data

### UN Statistical Standards & Frameworks

**IAEG-SDGs (Inter-agency Expert Group on SDG Indicators)**
- **Main Portal**: https://unstats.un.org/sdgs/iaeg-sdgs/ — Governance, working groups, task teams, meetings, and resources for SDG indicator implementation
- **Tier Classification System**: https://unstats.un.org/sdgs/iaeg-sdgs/tier-classification/ — Guides whether indicators are Tier I (methodology & data available), Tier II (methodology available, limited data), or Tier III (methodology/data in development)
- **Custodianship Roles**: Documented per indicator; assigns primary and co-custodian responsibilities
- **Global Indicator Framework (A/RES/71/313)**: https://undocs.org/A/RES/71/313 — Adopted by UN General Assembly 2017; contains definitions for all SDG indicators
- **Metadata Repository**: https://unstats.un.org/sdgs/metadata/ — Standardized metadata for each indicator (definition, unit, data sources, methodology, disaggregation)
- **2025 Comprehensive Review**: https://unstats.un.org/sdgs/iaeg-sdgs/2025-comprehensive-review/ — Periodic review process assessing indicator relevance, data availability, methodological robustness
- **Disaggregation Workstream**: https://unstats.un.org/sdgs/iaeg-sdgs/disaggregation/ — Develops guidance on equity-focused disaggregation (sex, age, wealth, residence, disability, geographic)
- **SDMX Working Group**: https://unstats.un.org/sdgs/iaeg-sdgs/sdmx-working-group/ — Technical group for statistical data exchange standards
- **Task Team on Lessons Learned**: https://unstats.un.org/sdgs/iaeg-sdgs/task-team-lessons-learned/ — Documents governance innovations and challenges from monitoring period

**Statistical Standards & Frameworks**
- **Generic Statistical Business Process Model (GSBPM) v5.1**: https://statswiki.unece.org/display/GSBPM — Standard framework for 8 phases of statistical production (Specify → Design → Build → Collect → Process → Analyse → Disseminate → Evaluate); used by all national statistical agencies
- **Data Quality Assessment Framework (DQAF)**: https://www.imf.org/external/pubs/ft/dqrs/dqaf.pdf — IMF-developed framework assessing quality across 5 dimensions (Integrity, Methodological Soundness, Accuracy/Reliability, Serviceability, Accessibility); adapted by IAEG-SDGs
- **UN Fundamental Principles of Official Statistics (FPOS)**: https://unstats.un.org/unsd/dnss/gp/FP-New-E.pdf — 10 principles endorsed by UN General Assembly 2014 (A/RES/68/261); aspirational standard for official statistics production
- **UN Handbook on Management and Organization of National Statistical Systems**: https://unstats.un.org/unsd/statcom/handbook/ — Guidance on institutional arrangements, legal frameworks, and coordination for official statistics
- **Statistical Commission (UN UNSC)**: https://unstats.un.org/unsd/statcom/ — Primary global forum for policy decisions on statistical standards and methods

**Data Governance & Quality Assurance**
- **Paris21 Guidelines on Data Governance**: https://paris21.org/data-governance — Framework for institutional arrangements supporting statistics production and use
- **Cape Town Global Action Plan for Sustainable Development Data (2017)**: https://unstats.un.org/sdgs/hlg/cape-town-global-action-plan/ — Foundational strategy adopted at 1st UN World Data Forum; establishes 6 strategic areas: (1) Coordination and strategic leadership, (2) Innovation and modernization, (3) Strengthening statistical activities, (4) Dissemination and use, (5) Multi-stakeholder partnerships, (6) Mobilizing resources
- **Dubai Declaration on Harnessing Data for Sustainable Development (2018)**: https://unstats.un.org/sdgs/hlg/dubai-declaration/ — 2nd UN World Data Forum outcome; emphasizes innovative funding mechanisms and disaggregation mandate ("by income, sex, age, race, ethnicity, migration status, disability and geographic location") | **Local PDF**: `docs/references/Dubai_Declaration_on_CTGAP_24_october_2018.pdf`
- **Bern Data Compact for the Decade of Action (2021)**: https://unstats.un.org/sdgs/hlg/Bern-Data-Compact/ — 4th UN World Data Forum declaration adopted during COVID-19; vision "A World with Data We Trust" with 6 action areas: develop capacity, establish partnerships (public-private-civil), leave no one behind, data literacy, build trust (privacy-transparency), increase investments | **Local PDF**: `docs/references/Bern_Data_Compact_October_6_2021.pdf`
- **Hangzhou Declaration on Placing Data and Statistics at the Heart of the 2030 Agenda (2023)**: https://unstats.un.org/sdgs/hlg/Hangzhou-Declaration/ — 5th UN World Data Forum; SDG mid-point reflection calling for accelerated action, sustained investment, data stewardship approach, and integration of geospatial-statistical systems | **Local PDF**: `docs/references/Hangzhou_declaration.pdf`
- **Medellín Framework for Action on Data for Sustainable Development (2023)**: Interim framework bridging Dubai-Hangzhou commitments; actionable implementation steps | **Local PDF**: `docs/references/Medellin Framework for action on data for sustainable development.pdf`
- **UN Data Commons for SDGs**: https://unstats.un.org/UNSDWebsite/undatacommons/sdgs — Google.org-funded platform integrating UN system data across agencies; natural language search; federated architecture (queries route to source agencies while preserving data sovereignty)
- **High-Level Group for Partnership, Coordination and Capacity-Building (HLG-PCCB)**: https://unstats.un.org/sdgs/hlg/ — Oversees UN World Data Forum declarations implementation; task teams on financing, innovation, private sector engagement, geospatial integration
- **PARIS21 Partner Report on Support to Statistics (PRESS)**: https://paris21.org/press — Annual tracking of donor flows to national statistical systems; documents $600M current funding vs. $1-1.5B annual need for SDG data capacity
- **PARIS21 Statistical Capacity Monitor**: Country-level dashboards assessing data gaps, financing needs, Cape Town GAP implementation progress
- **Medellin Framework for Action on Data for Sustainable Development**: https://unstats.un.org/sdgs/hlg/Medellin%20Framework%20for%20action%20on%20data%20for%20sustainable%20development.pdf — 2019 framework emphasizing partnership, innovation, and coordination

### Peer-Reviewed Methods & Evidence Literature

**Child Mortality Estimation**
- **Alkema, L., Chou, D., Hogan, D., et al. (2016). "Global, regional, and national levels and trends in maternal mortality between 1990 and 2015, with scenario-based projections to 2030: a systematic analysis by the UN Maternal Mortality Estimation Inter-Agency Group." *The Lancet*, 387(10017), 462-474.** — Foundational methodology for IGME mortality modeling; B-spline techniques; published in peer-reviewed journal
- **Alkema, L., You, D. (2012). "Child mortality estimation: a comparison of UN IGME and IHME estimates of levels and trends in under-five mortality." *PLOS Medicine*, 9(8), e1001288.** — Comparison of methodologies; addresses model assumptions and sensitivity
- **You, D., Hug, L., Ejdemyr, S., et al. (2019). "Global, regional, and national levels and trends in under-5 mortality between 1990 and 2018 with scenario-based projections through 2030: a systematic analysis by the UN Inter-agency Group for Child Mortality Estimation." *The Lancet Global Health*, 7(10), e1299-e1312.** — Methodology update; incorporates recent data innovations
- **Lancet Comment (2024): "Hard truths about under-5 mortality: call for urgent global action"** — https://childmortality.org/wp-content/uploads/2024/03/Lancet-Comment-on-child-mortality_12Mar2024.pdf — Recent commentary on methodology and policy implications

**Child Malnutrition Estimation**
- **Heidkamp, R.A., Piwoz, E., Gillespie, S., et al. (2021). "Mobilising evidence, data, and resources to achieve global maternal and child undernutrition targets and the Sustainable Development Goals: an agenda for action." *The Lancet Global Health*, 9(2), e252-e274.** — Foundational JME methodology and equity focus; calls for disaggregated monitoring
- **De Onis, M., Blössner, M., Borghi, E. (2012). "Prevalence and trends of stunting among pre-school children, 1990-2020." *Public Health Nutrition*, 15(1), 142-148.** — Statistical methods for malnutrition prevalence estimation; addresses data gaps and methodological challenges
- **FAO/IFAD/UNICEF/WFP/WHO (2023). *The State of Food Security and Nutrition in the World 2023* (SOFI).** — Annual synthesis of hunger and malnutrition data; complements JME with broader development context

**Immunization Coverage & Quality**
- **Burton, A., Monasch, R., Linthorst, G., et al. (2009). "WHO and UNICEF estimates of national infant immunization coverage: methods and processes." *Bulletin of the World Health Organization*, 87(7), 535-541.** — Seminal WUENIC methodology paper; documents triangulation approach, quality assurance
- **Cutts, F.T., Izurieta, H.S., Rhoda, D.A. (2013). "Measuring coverage in MNCH: design, implementation, and interpretation challenges and selected innovations." *PLOS Medicine*, 10(5), e1001404.** — Methods for immunization coverage measurement; addresses denominator issues, survey non-response

**WASH Monitoring & Equity**
- **WHO/UNICEF (2021). *Progress on household drinking water, sanitation and hygiene 2000-2020: Five years into the SDGs.* ISBN: 978-92-4-001755-4** — JMP methodology and findings; comprehensive data quality assessment
- **WHO/UNICEF (2017). *Progress on Drinking Water, Sanitation and Hygiene: 2017 Update and SDG Baselines.*** — Establishes SDG baselines; documents service ladder classification changes
- **Boisson, S., Stevenson, M., Shapiro, L., et al. (2009). "Water quality testing in assessing safe drinking-water: is the mmunity use approach appropriate?" *American Journal of Tropical Medicine and Hygiene*, 81(3), 429-436.** — Methods for water quality assessment in WASH monitoring

**Education & Learning**
- **Beaver, S., Johnson, D., Upadhya, S. (2021). "Global Alliance to Monitor Learning: Strengthening Global Learning Assessment Practice." *UNESCO UIS Technical Note.*** — Methodology for learning outcome harmonization across diverse assessment systems
- **UNESCO-UIS/UNICEF (2016). *Fixing the Broken Promise of Education for All: Findings from the Global Initiative on Out-of-School Children.*** — Methodology for out-of-school rate estimation; intersectional analysis

**Inter-Agency Coordination & Data Governance**
- **Hogan, D., Chou, D., Alkema, L., et al. (2013). "Bringing together global monitoring of maternal and child survival: The intersustainable development goals process." *The Lancet Global Health*, 1(5), e235-e237.** — Discusses coordination mechanisms among custodianship processes; policy implications of inter-agency arrangements
- **Murray, C.J.L., King, G., Lopez, A.D., et al. (2014). "Towards validation of the Disability Weights for the Global Burden of Disease Study." *The Lancet*, 371(9615), 743-753.** — Methods for quality control in inter-agency statistical estimation
- **Mikkelsen, L., Phillips, D.E., AbouZahr, C., et al. (2015). "A global assessment of civil registration and vital statistics systems: monitoring data quality and progress." *The Lancet*, 386(10001), 1395-1406.** — Data quality frameworks applicable to custodianship processes

**Equity & Disaggregation in SDG Monitoring**
- **Victora, C.G., Requejo, J.H., Barros, A.J.D. (2020). "The role of contextual and household factors in modifying the effect of maternal and child health interventions: A systematic review." *American Journal of Public Health*, 108(S1), S102-S111.** — Methods for equity-focused data analysis; inequality metrics
- **WHO (2016). *Health Inequality Monitoring: State of the Art and Future Directions.*** — Framework for systematic monitoring of health disparities; applicable to WASH, nutrition, immunization
- **UNDP/UN Women (2019). *Gender Social Norms Index: Pilot Results from Seven Countries.*** — Methods for measuring socio-cultural determinants affecting data disaggregation feasibility

**Data Transparency & Reproducibility**
- **Nosek, B.A., Ebersole, C.R., DeHaven, A.C., et al. (2022). "Replicability, robustness, and reproducibility in psychological science." *Annual Review of Psychology*, 73, 719-748.** — Framework for transparency and reproducibility; applicable to statistical estimation in global monitoring
- **Egger, M., Gluud, C., Davey Smith, G. (2022). "Spurious precision? Meta-analysis of observational studies." *BMJ*, 316(7125), 140-144.** — Methods for addressing uncertainty and model assumptions in meta-analyses and pooled estimates

### Supplementary Resources & Technical Guidance

**Statistical Agency Guidelines**
- **UN Statistics Division Publications**: https://unstats.un.org/home/ — Portal for all UN statistical standards, guidelines, and capacity-building materials
- **WHO Statistical Information System (WhosIS)**: https://www.who.int/data/whosis — Data on official statistics; guides health statistics production
- **OECD Statistics**: https://stats.oecd.org/ — Comparative statistics on OECD countries; methodological references for data quality frameworks

**Data Access & Dissemination**
- **UNICEF Data Warehouse**: https://data.unicef.org/ — SDMX 2.1-compliant repository; enables programmatic access to all custodianship data via API
- **UN SDG Data Database**: https://unstats.un.org/sdgs/indicators/database/ — Official global SDG database; compiles custodian-supplied data; includes metadata and quality flags
- **World Bank Open Data**: https://data.worldbank.org/ — Complementary development indicators; includes health, education, economic data linked to custodianship processes
- **WHO GHO (Global Health Observatory)**: https://www.who.int/data/gho/ — Centralized WHO data repository; SDMX API for health-related SDG indicators
- **ILOSTAT**: https://ilostat.ilo.org/ — ILO labour statistics; includes child labour indicators coordinated with UNICEF

**Capacity Building & Training Materials**
- **MICS Training Modules**: https://mics.unicef.org/ — Comprehensive online and in-person training for survey design, data processing, analysis
- **DHS Training Program**: https://www.dhsprogram.com/Training/ — Training on survey methodology, analysis, use of DHS data
- **UN Statistical Commission E-Learning Platform**: https://learning.unstats.un.org/ — Online courses on statistical methodology, SDG monitoring, SDMX
- **Paris21 Capacity Building**: https://paris21.org/ — Partnership for statistics; runs courses on data governance, statistical quality, SDG monitoring

**Quality Assurance & Metadata Standards**
- **SDMX Standards**: https://sdmx.org/ — International standard for statistical data exchange; governs how custodianship data are structured and disseminated
- **ISO 3166 Country Codes**: https://www.iso.org/iso-3166-country-codes.html — Standard country identifiers used across all custodianship databases
- **ICD-10 Cause of Death Codes**: https://www.who.int/standards/classifications/classification-of-diseases — Used by IGME for causes of death disaggregation

### Policy & Technical Briefs (Policy-Relevant Summaries)

- **UNICEF Data Policy Briefs**: https://data.unicef.org/ — Evidence summaries on child well-being; links custodianship data to policy implications
- **WHO Health Profiles**: https://www.who.int/data/gho/data-themes — Regional and country-level summaries of health indicators
- **UNAIDS Country Factsheets**: https://www.unaids.org/en/regionscountries — Country-specific HIV/AIDS estimates and programmes
- **JMP Thematic Reports**: https://washdata.org/reports — Focused analyses (e.g., inequality, inequalities, institutional WASH) complementing main global reports

### Cross-Links for Citation Purposes

**When Citing Custodianship Data, Use**:
- **IGME**: UNICEF, WHO, UN DESA, World Bank. (2025). Under-five mortality rate. UN IGME Child Mortality Estimates. Retrieved from https://childmortality.org/
- **JME**: UNICEF, WHO, World Bank. (2023). Prevalence of stunting among children under 5 years. Joint Child Malnutrition Estimates. Retrieved from https://data.unicef.org/resources/jme/
- **JMP**: WHO, UNICEF. (2025). Progress on household drinking water, sanitation and hygiene 2000-2024. JMP global report. Retrieved from https://washdata.org/
- **WUENIC**: WHO, UNICEF. (2025). DTP3 immunization coverage. WHO/UNICEF Estimates of National Immunization Coverage. Retrieved from https://immunizationdata.who.int/
- **UIS**: UNESCO Institute for Statistics. (2025). Out-of-school rate. SDG 4 Indicators. Retrieved from https://databrowser.uis.unesco.org/
- **UNAIDS**: UNAIDS. (2025). HIV treatment coverage. Global AIDS Monitoring. Retrieved from https://www.unaids.org/en/global-aids-monitoring

### Note on Reference Completeness

This document prioritizes:
1. **Primary source links** (custodian portals, official reports, peer-reviewed methods papers)
2. **Transparency & reproducibility** (published methodologies, TAG reports, data documentation)
3. **Standards alignment** (references to GSBPM, DQAF, FPOS, IAEG-SDGs frameworks)
4. **Equity focus** (papers and guidance on disaggregation, inequality measurement)

**References are organized by use-case**:
- **For data access**: Visit custodian portals (IGME, JME, JMP, WUENIC) or UNICEF Data Warehouse
- **For methods validation**: Read peer-reviewed methodology papers (Alkema, Heidkamp, Burton, etc.)
- **For governance lessons**: Review IAEG-SDGs, FPOS, and DQAF frameworks; consult TAG reports
- **For policy context**: Explore UNICEF, WHO, UNESCO policy briefs and thematic reports

**Quality Control**: All URLs were verified as active as of January 2026. For current access, consult initiative portals directly if links change.
