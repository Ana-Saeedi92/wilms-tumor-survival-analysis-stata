# Wilms Tumor Survival Analysis in Stata

## Overview
This repository contains a Stata workflow for survival analysis in relapsed Wilms tumor patients, based on a real analytical project. The code covers cohort restriction, survival-time setup, Kaplan–Meier estimation, Cox proportional hazards modeling, proportional hazards checks, forest plots, and selected parametric and flexible parametric survival models.

## Important note on data
The original analysis used a private Excel dataset that is **not included** in this repository. To protect confidentiality and preserve the real analytical workflow, the code is kept close to the original project and expects you to place the source dataset locally before running.

Before running the code:
1. Put the source Excel file in the `data/` folder, or update the path in `code/00_setup.do`.
2. Review variable names and sheet names to ensure they match your local file.
3. Install any required Stata packages noted in the scripts.

## Repository structure
```text
wilms-tumor-survival-analysis-stata/
├── README.md
├── .gitignore
├── code/
│   ├── 00_setup.do
│   ├── 01_data_cleaning.do
│   ├── 02_survival_setup_km.do
│   ├── 03_cox_models.do
│   ├── 04_forest_plot_and_parametric.do
│   ├── run_all.do
│   └── original_full_workflow.do
├── data/
└── results/
    ├── figures/
    └── tables/
```

## Main methods
- Cohort restriction to eligible relapse strata
- Construction of relapse timing and relapse-site variables
- Overall survival setup with `stset`
- Kaplan–Meier curves and log-rank tests
- Univariable and multivariable Cox proportional hazards models
- PH assumption checks with `estat phtest`
- Forest plots using `coefplot`
- Parametric survival models with `streg`
- Flexible parametric survival modeling with `stpm2`

## Suggested GitHub description
Reproducible Stata workflow for survival analysis in relapsed Wilms tumor patients using Kaplan–Meier, Cox regression, and parametric survival models.

## Skills demonstrated
- Survival analysis in Stata
- Clinical oncology data cleaning
- Prognostic factor modeling
- Model diagnostics and assumption checking
- Forest plot visualization

## How to run
Open Stata in the project folder and run:

```stata
do code/run_all.do
```

## Author
PhD Candidate in Biostatistics
