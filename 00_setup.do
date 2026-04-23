********************************************************************************
* 00_setup.do
* Project setup for Wilms tumor survival analysis
********************************************************************************

clear all
set more off

* --- Project root ---
* Edit this if needed. Assumes Stata is opened in the repository root.
global PROJECT_ROOT "`c(pwd)'"

* --- Data path ---
* Place your source Excel file inside data/ or edit the filename below.
global RAW_DATA "$PROJECT_ROOT/data/NWTS RELAPSE DATABASE.xlsx"

* --- Output folders ---
global FIG_DIR   "$PROJECT_ROOT/results/figures"
global TABLE_DIR "$PROJECT_ROOT/results/tables"

capture mkdir "$PROJECT_ROOT/results"
capture mkdir "$FIG_DIR"
capture mkdir "$TABLE_DIR"

display "Project root: $PROJECT_ROOT"
display "Expected data file: $RAW_DATA"
