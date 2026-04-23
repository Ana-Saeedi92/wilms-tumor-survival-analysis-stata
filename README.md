# Wilms Tumor Survival Analysis (Stata)

## Overview
This project presents a comprehensive survival analysis workflow for patients with relapsed Wilms tumor using Stata. The analysis follows a real-world clinical research pipeline, including cohort construction, time-to-event modeling, and prognostic factor evaluation.

## Objectives
- Evaluate overall survival following first relapse
- Compare survival across clinical subgroups and treatment strata
- Identify prognostic factors associated with survival outcomes
- Assess model assumptions and explore alternative survival models

## Methods

### Data Preparation
- Cohort restriction based on study eligibility criteria (Stratum B/C)
- Derivation of relapse timing and clinical variables
- Data cleaning and variable recoding

### Survival Analysis
- Kaplan–Meier estimation of overall survival
- Log-rank tests for group comparisons
- Survival-time declaration using `stset`

### Regression Modeling
- Univariable Cox proportional hazards models
- Multivariable Cox regression with model selection
- Assessment of proportional hazards assumptions

### Advanced Modeling
- Parametric survival models (Weibull, exponential, log-normal, log-logistic)
- Flexible parametric survival modeling
- Forest plot visualization of hazard ratios

## Project Structure
