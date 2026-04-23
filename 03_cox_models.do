********************************************************************************
* 03_cox_models.do
* Univariable and multivariable Cox models
********************************************************************************

do code/00_setup.do
use "$PROJECT_ROOT/data/analysis_working.dta", clear

stset surv_months, failure(died)

* Univariable Cox models + PH tests
stcox i.stratum
estat concordance
estat phtest

stcox i.sex
estat concordance
estat phtest

stcox i.age_rel_cat
estat concordance
estat phtest

* Alternative handling for time to relapse
stcox time_to_relapse_mo
estat phtest

stcox i.ttr_cat
estat phtest

stcox ib2.site_relapse
estat concordance
estat phtest

stcox i.multisite
estat concordance
estat phtest

stcox i.initial_stage
estat concordance
estat phtest

stcox i.prior_radiation
estat concordance
estat phtest

stcox i.gtr_relapse
estat concordance
estat phtest

* Candidate multivariable models
misstable summarize sex stratum prior_radiation infield ttr_cat site_relapse

stcox i.sex i.stratum ib2.site_relapse i.ttr_cat i.age_rel_cat i.multisite i.gtr_relapse
estat ic
estimates store CoxModel_full

stcox i.sex i.stratum ib2.site_relapse i.ttr_cat i.multisite i.gtr_relapse
estat ic
estimates store CoxModel
