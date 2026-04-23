********************************************************************************
* 04_forest_plot_and_parametric.do
* Forest plot, parametric survival models, and flexible parametric model
********************************************************************************

do code/00_setup.do
use "$PROJECT_ROOT/data/analysis_working.dta", clear

stset surv_months, failure(died)

* User-written packages
capture which coefplot
if _rc ssc install coefplot, replace

capture which stpm2
if _rc ssc install stpm2

* Forest plot from Cox model
stcox i.sex i.stratum ib2.site_relapse i.gtr_relapse i.ttr_cat i.multisite, vce(robust)
estimates store CoxModel

coefplot CoxModel, eform drop(_cons) ///
    keep(2.sex 2.stratum 1.site_relapse 2.ttr_cat 3.ttr_cat 1.multisite 1.gtr_relapse 2.gtr_relapse) ///
    rename(2.sex="Male vs female" ///
           2.stratum="Stratum C vs B" ///
           1.site_relapse="Pulmonary-only vs other" ///
           2.ttr_cat="7–12 mo vs 0–6 mo" ///
           3.ttr_cat=">12 mo vs 0–6 mo" ///
           1.multisite="≥2 sites vs single" ///
           1.gtr_relapse="Complete GTR vs no surgery" ///
           2.gtr_relapse="Incomplete GTR vs no surgery") ///
    xscale(log range(0.1 10)) xline(1, lpattern(dash)) xlabel(0.1 0.2 0.5 1 2 5 10 20) ///
    ciopts(recast(rcap)) msymbol(D) msize(*1.3) legend(off) ///
    mlabel(@b) mlabformat(%4.2f) mlabpos(12) mlabgap(*.3) mlabcolor(black) mlabsize(small) ///
    plotregion(margin(r+2)) ///
    title("")
graph export "$FIG_DIR/forestplot_coxmodel.png", replace

* Parametric models
local covars i.sex i.stratum i.age_rel_cat i.ttr_cat ib2.site_relapse i.multisite i.gtr_relapse

streg `covars', dist(weibull) vce(robust)
estat ic
estimates store weibull_model

streg `covars', dist(exponential) vce(robust)
estat ic
estimates store exponential_model

streg `covars', dist(lognormal) vce(robust)
estat ic
estimates store lognormal_model

streg `covars', dist(loglogistic) vce(robust)
estat ic
estimates store loglogistic_model

streg `covars', dist(gengamma) vce(robust)
estat ic
estimates store gengamma_model

estimates stats weibull_model exponential_model lognormal_model loglogistic_model gengamma_model

* Flexible parametric model
stpm2 i.sex i.stratum ib2.site_relapse i.ttr_cat i.multisite i.gtr_relapse, ///
    scale(hazard) df(4) vce(robust) eform
estat ic
estimates store RPmodel

coefplot RPmodel, eform drop(_cons) ///
    keep(2.sex 2.stratum 1.site_relapse 2.ttr_cat 3.ttr_cat 1.multisite 1.gtr_relapse 2.gtr_relapse) ///
    rename(2.sex="Male vs female" ///
           2.stratum="Stratum C vs B" ///
           1.site_relapse="Pulmonary-only vs other" ///
           2.ttr_cat="7–12 mo vs 0–6 mo" ///
           3.ttr_cat=">12 mo vs 0–6 mo" ///
           1.multisite="≥2 sites vs single" ///
           1.gtr_relapse="Complete GTR vs no surgery" ///
           2.gtr_relapse="Incomplete GTR vs no surgery") ///
    xscale(log range(0.1 10)) xline(1, lpattern(dash)) xlabel(0.1 0.2 0.5 1 2 5 10 20) ///
    ciopts(recast(rcap)) msymbol(D) msize(*1.3) legend(off) ///
    mlabel(@b) mlabformat(%4.2f) mlabpos(12) mlabgap(*.3) mlabcolor(black) mlabsize(small) ///
    plotregion(margin(r+2)) ///
    title("")
graph export "$FIG_DIR/forestplot_royston_parmar.png", replace
