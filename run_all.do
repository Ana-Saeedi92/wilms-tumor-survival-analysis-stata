********************************************************************************
* run_all.do
* Master script
********************************************************************************

do code/00_setup.do
do code/01_data_cleaning.do
do code/02_survival_setup_km.do
do code/03_cox_models.do
do code/04_forest_plot_and_parametric.do
display "All scripts completed."
