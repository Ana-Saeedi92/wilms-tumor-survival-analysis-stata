********************************************************************************
* 02_survival_setup_km.do
* Survival declaration, KM curves, and log-rank tests
********************************************************************************

do code/00_setup.do
use "$PROJECT_ROOT/data/analysis_working.dta", clear

* Survival setup
stset surv_months, failure(died)
summarize surv_months, detail
stdescribe

* Overall Kaplan–Meier curve
sts graph, survival ///
    xlabel(0(24)266, labsize(small) angle(0) grid) ///
    ylabel(0(.2)1, labsize(small) grid) ///
    xscale(range(0 168)) ///
    xtitle("Time from first relapse (months)") ///
    ytitle("Survival probability") ///
    title("K–M Curve for Overall Survival") ///
    risktable risktable(, size(*.75))
graph export "$FIG_DIR/km_overall_survival.png", replace

* Re-declare in years for presentation-friendly KM plots
stset surv_years, failure(died)

* KM by stratum
sts test stratum, logrank
local chi = r(chi2)
local df  = r(df)
local p   = chiprob(`df', `chi')
local pstring = cond(`p' < .001, "p < 0.001", "p = " + string(`p', "%6.3f"))

sts graph, by(stratum) ///
    title("Overall Survival by Initial Treatment Intensity") ///
    subtitle("Log-rank `pstring'") ///
    xtitle("Years since first relapse") ///
    ytitle("Survival probability") ///
    risktable ///
    legend(order(1 "Stratum B" 2 "Stratum C") cols(2))
graph export "$FIG_DIR/km_by_stratum.png", replace

* KM by sex
sts test sex, logrank
local chi = r(chi2)
local df  = r(df)
local p   = chiprob(`df', `chi')
local pstring = cond(`p' < .001, "p < 0.001", "p = " + string(`p', "%6.3f"))

sts graph, by(sex) ///
    title("Overall Survival by Sex") ///
    subtitle("Log-rank `pstring'") ///
    xtitle("Years since first relapse") ///
    ytitle("Survival probability") ///
    risktable ///
    legend(order(1 "Female" 2 "Male") cols(2))
graph export "$FIG_DIR/km_by_sex.png", replace
