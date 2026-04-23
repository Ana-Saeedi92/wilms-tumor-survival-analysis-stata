*********************************************************************
*  NWTS relapse dataset prep              
 *Identifying Prognostic Factors for Event-Free and Overall Survival in Relapsed Wilms Tumor Patients Using Cox Regression Analysis                     
--

*-----------------------------------------------------------
*—1.working folder
cd "C:\Users\saeeda1\OneDrive - UMass Chan Medical School\Documents\Comp project"

*—2.
import excel using "NWTS RELAPSE DATABASE.xlsx", ///
        sheet("sample_cleaned") cellrange(A1:CH198) firstrow clear


describe, full
codebook *, compact      
misstable summarize

keep if inlist(RELAPSESTRATUM, "Stratum B", "Stratum C")

tab RELAPSESTRATUM,m
replace PAPERB = "NO" if missing(PAPERB)
replace PAPERC = "NO" if missing(PAPERC)
keep if PAPERB == "YES" | PAPERC == "YES"
tab RELAPSESTRATUM,missing
tab RELAPSESTRATUM OriginalHistology
*startumB: 70: 4 were not evaluable:one due to insufficient data and three due to major protocol violation, 5 bilateral Wilms tumor at diagnosis, 3 who developed a contralateral relapse, 1 persistent disease : 4+5+3+1=13 so 70-13=57
*stratum C: 101: 11 were not evaluable:6 due to insufficient data, 4 due to major protocol violations, and 1 for refusal of therapy,14 with stage V WT, 1 with contralateral relapse, and 16 who did not achieve a CR to the initial three-drug chemotherapy so: 11+14+1+16
tab  EVALUAB RELAPSESTRATUM
tab DIAGFSTG RELAPSESTRATUM


*------------------------------------------------------------------
* A.  KEEP Strata B & C
*------------------------------------------------------------------
keep if inlist(RELAPSESTRATUM, "Stratum B", "Stratum C")
keep if inlist(OriginalHistology,"FAVOR")
*------------------------------------------------------------------
* B.  AGE at initial diagnosis  (yrs)
*------------------------------------------------------------------
gen age_diag = (D_CDIAG_ORIGINAL - DOB) / 365.25

drop if missing(age_diag) |age_diag >= 16
local n_drop_age = r(N_drop)

*------------------------------------------------------------------
* C.  FLAG bilateral disease  (overall Stage V)
*------------------------------------------------------------------
* 1. Flag overall-stage-V (bilateral) cases
generate byte DIAGFSTG == "V"

* 2. Flag contralateral-kidney metachronous tumours
generate byte clkid = 0
replace  clkid = 1 if inlist(Relapse_11_1A,"CL KIDNEY") | inlist(Relapse_11_1B,"CL KID")

label define yesno 0 "No" 1 "Yes"

label values clkid  yesno

* 3. Two-way table of overlap (easy visual check)
tabulate clkid, missing

* 4. Capture the numbers for your CONSORT / PRISMA flow chart
quietly {
    count if stageV==1 & clkid==0
    local n_stageV_only = r(N)

    count if stageV==0 & clkid==1
    local n_clkid_only  = r(N)

    count if stageV==1 & clkid==1
    local n_overlap     = r(N)

    count if stageV==0 & clkid==0
    local n_neither     = r(N)
}

display "Stage V only      : n_stageV_only'"
display "CL kidney only    : n_clkid_only'"
display "Both exclusions   : n_overlap'"
display "Neither exclusion : n_neither'"

drop if DIAG_FSTG == "V"
*primary site of first relapse episode
*primary site of second relapse episode
drop if Relapse_11_1A == "CL KIDNEY" | Relapse_22_1A == "CL KID"



* J.  Histology flag  (retain all)
*------------------------------------------------------------------
gen byte unfav = inlist(Original_Histology,"DIFANA","FOCANA","CCSK","RTK")
label define hist 0 "Favourable" 1 "Unfavourable"
label values unfav hist
tab unfav
*------------------------------------------------------------------



* Age-at-diagnosis categories for Table 1
*------------------------------------------------------------------
gen age_rel_yr = (D_REL1 - DOB) / 365.25

gen int age_rel_mo = round(( D_REL1 - DOB) / 30.4375)
recode age_rel_mo (0/23=1)(24/47=2)(48/max=3), gen(age_rel_cat)
label define agecat 1 "0–23 mo" 2 "24–47 mo" 3 "≥48 mo"
label values age_rel_cat agecat
tab age_rel_cat

//table1
***********************************************
* 1. Overall survival (months)

describe D_REL1 D_DEATH D_LASTFOLLOWUP

format D_REL1 D_LASTFOLLOWUP %td

* remove any leading/trailing blanks in the string column
replace D_DEATH = trim(D_DEATH)

* convert M/D/Y strings → numeric Stata date
gen int death_td = date(D_DEATH,"MDY")   if D_DEATH!=""

format death_td %td
list D_DEATH death_td in 1/10

* 1.  Event indicator                                            *
*****************************************************************/
gen byte died = !missing(death_td)      // 1 = died, 0 = censored

/*****************************************************************
* 2.  Survival time                                              *
*     • If died  → use death date                                *
*     • If alive → use last-follow-up date                       *
*****************************************************************/
gen int  surv_days = cond(died, death_td, D_LASTFOLLOWUP) - D_REL1
assert surv_days >= 0 | missing(surv_days)

gen double surv_months = surv_days / 30.4375        // fractional months
format surv_months %9.2f
gen double surv_years = surv_days / 365.25    // fractional years
format surv_years %9.2f

/*****************************************************************
* 3.  Declare survival data                                      *
*****************************************************************/
stset surv_months, failure(died)
summarize surv_months,d
stdescribe                      // should now show events > 0

*km curves (stratified)
stset surv_years, failure(died)
* 1.  Encode string → numeric
encode RELAPSESTRATUM, gen(stratum)   // Stratum B=1, Stratum C=2

* 2.  Give readable value labels
label define relstr_lbl 1 "Stratum B" 2 "Stratum C"
label values  stratum relstr_lbl

* 3.  KM curve stratified by stratum
* Kaplan–Meier by treatment stratum (numeric version)
sts graph, by(stratum)              ///  <- just the varname
    title("Overall Survival by Initial Treatment Intensity") ///
    xtitle("Years since first relapse") ///
    ytitle("Survival probability") ///
    risktable                            ///
    legend(order(1 "Stratum B" 2 "Stratum C") cols(2))

encode SEX, gen(sex)
label define sexlbl 1 "Female" 2 "Male"
label values sex sexlbl



* Log-rank test (sex)
sts test sex, logrank

* Retrieve chi-square and df
local chi = r(chi2)
local df  = r(df)

* Compute p-value
local p   = chiprob(`df', `chi')

* Format string
local pstring = cond(`p' < .001, "p < 0.001", ///
                     "p = " + string(`p', "%6.3f"))

* KM curve with p-value in subtitle
sts graph, by(sex) ///
    title("Overall Survival by Sex") ///
    subtitle("Log–rank `pstring'") ///          //  <- add this line
    xtitle("Years since first relapse") ///
    ytitle("Survival probability") ///
    risktable ///
    legend(order(1 "Female" 2 "Male") cols(2))



	
	* log-rank test
sts test stratum, logrank     // or SEX, etc.

* retrieve the chi-square and degrees of freedom
local chi = r(chi2)
local df  = r(df)

* compute the p-value
local p   = chiprob(`df', `chi')      // chiprob = right-tail prob

* format nicely
local pstring = cond(`p' < .001, "p < 0.001", ///
                     "p = " + string(`p', "%6.3f"))

*------------------------------------------------------------------
* 2.  Redraw the KM curve and insert the p-value
*------------------------------------------------------------------
sts graph, by(stratum) ///
    title("Overall Survival by Initial Treatment Intensity") ///
    subtitle("Log–rank `pstring'") ///
    xtitle("Years since first relapse") ///
    ytitle("Survival probability") ///
    risktable ///
    legend(order(1 "Stratum B" 2 "Stratum C") cols(2))




*2. Initial-treatment intensity
tab RELAPSESTRATUM
*3SEX
 tab SEX

* 3. Time from diagnosis to relapse (months)

gen time_to_relapse_days = D_REL_1 - D_CDIAG_ORIGINAL
gen time_to_relapse_mo = time_to_relapse_days / 30.44
summarize time_to_relapse_mo, detail
gen relapse_early = time_to_relapse_mo < 12 if !missing(time_to_relapse_mo)
replace relapse_early = 0 if time_to_relapse_mo >= 12
label define early_lbl 1 "Early (<12 months)" 0 "Late (≥12 months)"
label values relapse_early early_lbl
tab relapse_early
*******the ph assumption did not hold for this so we are trying an alternative
describe dzfreeinterval, full
destring dzfreeinterval, gen(time_to_relapse_mo) ignore("M")
label var time_to_relapse_mo "Time diagnosis→relapse (months)"
summarize time_to_relapse_mo, detail
gen byte ttr_cat = .                    

replace ttr_cat = 1 if time_to_relapse_mo <= 6
replace ttr_cat = 2 if time_to_relapse_mo > 6  & time_to_relapse_mo <= 12
replace ttr_cat = 3 if time_to_relapse_mo > 12

label define ttrlbl 1 "0–6 mo" 2 "7–12 mo" 3 ">12 mo"
label values ttr_cat ttrlbl
label variable ttr_cat "Time to relapse (categorical)"
tab ttr_cat, missing




*4. Anatomical site of first relapse
* Create binary indicators for lung involvement in each site
gen lung_siteA = (Relapse_11_1A == "LUNG")
gen lung_siteB = (Relapse_11_1B == "LUNG")

* Now define site_relapse categories
gen site_relapse = .

* Pulmonary-only: LUNG in A and not in B (or B is missing)
replace site_relapse = 1 if lung_siteA == 1 & (missing(Relapse_11_1B) | lung_siteB != 1)

* Extrapulmonary or multisite: LUNG in B, or other organs in A or B
replace site_relapse = 2 if lung_siteB == 1 | (lung_siteA == 1 & lung_siteB == 1) | (lung_siteA == 0)

* Label and tabulate
label define site_lbl 1 "Pulmonary-only" 2 "Extrapulmonary or multisite"
label values site_relapse site_lbl
tab site_relapse





*site of second relapse
/*****************************************************************
*  Create 3-level relapse site variable: relapse_cat3            *
*****************************************************************/

gen byte relapse_cat3 = .

/* 1) LUNG mentioned in either column --------------------------- */
replace relapse_cat3 = 1 if ///
     regexm(upper(Relapse_22_1A), "LUNG") | ///
     regexm(upper(Relapse_22_1B), "LUNG")

/* 2) Other site(s) recorded but NO lung ------------------------ */
replace relapse_cat3 = 2 if relapse_cat3 == . & ///
     ( !missing(Relapse_22_1A) | !missing(Relapse_22_1B) )

/* 0) Both columns missing/blank --------------------------------
   (leave as 0 to flag "no relapse info")                        */
replace relapse_cat3 = 0 if relapse_cat3 == .

/*  Label and inspect ------------------------------------------- */
label define relapse_cat3_lbl 1 "Lung relapse" ///
                              2 "Non-lung relapse" ///
                              0 "No relapse recorded"
label values relapse_cat3 relapse_cat3_lbl

tabulate relapse_cat3, missing     // quick frequency table


/*****************************************************************
* 3. (Optional) Drop helper columns once you're satisfied        *
*****************************************************************/
* drop Relapse_22_1A_uc Relapse_22_1B_uc

*5. Number of relapse sites
* Start with 0
gen n_sites = 0

* Add 1 if site A is not missing
replace n_sites = n_sites + 1 if !missing(Relapse_11_1A)

* Add 1 if site B is not missing
replace n_sites = n_sites + 1 if !missing(Relapse_11_1B)

* Create indicator for multisite
gen multisite = (n_sites >= 2)

* Label and tabulate
label define multi_lbl 0 "Single site" 1 "≥2 sites"
label values multisite multi_lbl
tab multisite


*6 Gross total resection at relapse

* collapse "yes" variants first
replace Sx_11_GTRSITEB = "YES" if lower(Sx_11_GTRSITEB) == "yes"

* treat NQ as missing
replace Sx_11_GTRSITEB = ""    if Sx_11_GTRSITEB == "NQ"

* quick check
tab Sx_11_GTRSITEB, missing

tab Sx_11_GTRSITEA
gen str10 ANYSx_11_clean = trim(upper(ANYSx_11))
replace Sx_11_GTRSITEA = upper(trim(Sx_11_GTRSITEA))
tab Sx_11_GTRSITEA
tab ANYSx_11_clean
tab Sx_11_GTRSITEB

*------------------------------------------------------------
* 0 = No surgery
* 1 = Complete GTR at every operated site
* 2 = Incomplete / partial resection
*------------------------------------------------------------
gen byte gtr_relapse = .

* No surgery
replace gtr_relapse = 0 if ANYSx_11_clean == "NO"

* Complete GTR  (Site A = YES  AND  Site B = YES or NA)
replace gtr_relapse = 1 if ///
      ANYSx_11_clean == "YES"  & ///
      Sx_11_GTRSITEA == "YES"  & ///
      inlist(Sx_11_GTRSITEB,"YES","NA")

* Incomplete/partial  (all other YES-surgery cases)
replace gtr_relapse = 2 if ///
      ANYSx_11_clean == "YES"  & gtr_relapse == .

label define gtr_lbl 0 "No surgery" ///
                     1 "Complete GTR" ///
                     2 "Incomplete/partial"
label values gtr_relapse gtr_lbl

tab gtr_relapse, missing







*6 initial overall stage
tab DIAGFSTG
tab DIAGFSTG RELAPSESTRATUM



*Prior radiotherapy during initial treatment
tab XRTGIVENDIAG


************
*RT_infield_22 tells us where the second relapse occurred (inside vs outside the prior RT field).

*At the moment you start the survival clock (date of first relapse), that information does not exist yet. If you treat it like a baseline variable you will:

*give every patient who eventually has a second relapse an automatic "survival guarantee" up to that second relapse (immortal-time bias);

*misclassify every patient who never has a second relapse as "missing."
*Relapse inside prior radiation field
tab RT_infield_22 

gen str20 RT_infield22_clean = trim(upper(RT_infield_22))


gen byte infield = .
replace infield = 1 if strpos(RT_infield22_clean,"YES") > 0
replace infield = 0 if strpos(RT_infield22_clean,"NO")  > 0
* everything else (NA, "") stays missing

label define infield_lbl 0 "Out-field relapse" 1 "In-field relapse"
label values infield infield_lbl

tab infield, missing          // check result



*relpase stage( too many missing)


***************************
*COX regression

*outcome: surv_time,surv_time_mo
*covariates: RELAPSE_STRATUM SEX relapse_early site_relapse multisite sx_gtr_binary relapse_tx_intensity DIAG_FSTG RTGIVEN_DIAG

* 0.  VERIFY survival setup                                        *
*     • surv_months  = time from first relapse to event/censor (mo)
*     • died         = 1 if dead, 0 if censored
*******************************************************************/
stset surv_months, failure(died)


*Kaplan–Meier curve for the whole data
sts graph , survival                                   ///
    xlabel(0(24)266 , labsize(small) angle(0) grid)   ///
    ylabel(0(.2)1 , labsize(small) grid)               ///
    xscale(range(0 168))                               ///
    xtitle("Time from first relapse (months)")         ///
    ytitle("Survival probability")                     ///
    title("K–M Curve for Overall Survival")            ///
    risktable risktable(, size(*.75))

*we need to check ph assumptions first 

*------------------------------------------------------------------
*   Univariate Cox models
*------------------------------------------------------------------

* 1) Prior-therapy stratum (B vs C)
encode RELAPSESTRATUM , gen(stratum)
stcox i.stratum
estat concordance
estat phtest
* 2) Sex
encode SEX , gen(sex)
stcox i.sex
estat concordance
estat phtest
* 3) Age at diagnosis
stcox age_rel_cat
estat concordance
estat phtest

* 3) Early vs late relapse (<12 mo)
///////////////////////////////////////////////////////asumption fails
*stcox i.relapse_early
*estat concordance
*estat phtest
*trying alternative 
stcox time_to_relapse_mo
estat phtest
stcox i.ttr_cat
estat phtest
//ph assumption holds
* 4) Relapse site (pulmonary-only vs other)
stcox ib2.site_relapse
estat concordance
estat phtest
* 5) Multisite relapse (yes / no)
stcox i.multisite
estat concordance
estat phtest

* 7) Initial overall stage (I, II, III, IV)
encode DIAGFSTG, gen(initial_stage)
stcox i.initial_stage
estat concordance
estat phtest
* 8) Radiation given with original therapy (yes / no)
encode XRTGIVENDIAG, gen(prior_radiation)
stcox i.prior_radiation
estat concordance
estat phtest

*9)extent of resction
stcox i.gtr_relapse
estat concordance
estat phtest


* recode the missing category in infield variable
gen byte infield3 = .

replace infield3 = 1 if strpos(RT_infield22_clean,"YES") > 0
replace infield3 = 0 if strpos(RT_infield22_clean,"NO")  > 0
replace infield3 = 2 if missing(RT_infield22_clean) | ///
                       (!strpos(RT_infield22_clean,"YES") & ///
                        !strpos(RT_infield22_clean,"NO"))

label define infield3_lbl 0 "Out-field relapse" ///
                          1 "In-field relapse" ///
                          2 "Unavailable"
label values infield3 infield3_lbl

tab infield3, missing


*  multivariable Cox models
stset surv_months, failure(died)

* Clinically Important & Statistically Suggestive Variables
*Based on  univariable results and typical clinical significance, I recommend including:

*Sex (significant univariate, HR = 2.26)

*Initial treatment intensity (HR = 4.61)

*Prior radiotherapy (HR = 4.21)

*Relapse inside prior radiation field (HR = 13.46)

* Age at relapse 
misstable summarize sex stratum prior_radiation infield ttr_cat site_relapse


stcox  i.sex i.stratum ib2.site_relapse  i.ttr_cat i.age_rel_cat  i.multisite i.gtr_relapse 
estat ic


stcox  i.sex i.stratum ib2.site_relapse  i.ttr_cat       i.multisite i.gtr_relapse 
estat ic





*forest plot
ssc install coefplot, replace
which coefplot     // should now say 1.10.x or later, 2023-xx-xx


* Fit the model (robust SEs optional)
stcox  i.sex i.stratum ib2.site_relapse i.gtr_relapse    i.ttr_cat i.multisite , vce(robust)

* Store the results so coefplot can read them
estimates store CoxModel

coefplot CoxModel, eform drop(_cons)                       ///
  keep( 2.sex  2.stratum  1.site_relapse                    ///
          2.ttr_cat  3.ttr_cat 1.multisite                     ///
          1.gtr_relapse 2.gtr_relapse )                       ///
    /* reader‑friendly row labels --------------------------- */ ///
    rename( 2.sex          = "Male vs female"                 ///
            2.stratum      = "Stratum C vs B"                ///
            1.site_relapse = "Pulmonary‑only vs other"       ///
            2.ttr_cat      = "7–12 mo vs 0–6 mo"   ///
            3.ttr_cat      = "> 12 mo vs 0–6 mo"    ///
            1.multisite    = "≥ 2 sites vs single"           ///
            1.gtr_relapse  = "Complete GTR vs no surgery"    ///
            2.gtr_relapse  = "Incomplete GTR vs no surgery") ///                                  ///
    /* 2. axes, CIs, markers ----------------------------- */ ///
    xscale(log range(0.1 10)) xline(1, lpattern(dash)) xlabel(0.1 0.2 0.5 1 2 5 10 20)     ///
    ciopts(recast(rcap)) msymbol(D) msize(*1.3) legend(off) ///
    /* 3. numeric labels --------------------------------- */ ///
    mlabel(@b)              /*  (the HR)   */ ///
    mlabformat(%4.2f)       /* how to format the number  */ ///
    mlabpos(12) mlabgap(*.3) mlabcolor(black) mlabsize(small) ///
    /* 4. cosmetics -------------------------------------- */ ///
    plotregion(margin(r+2))                                ///
    title()

	
*trying a few parametric models
*Weibull model

stset surv_months, failure(died)


streg i.stratum, dist(weibull) vce(robust)
streg i.sex, dist(weibull) vce(robust)
streg i.age_rel_cat, dist(weibull) vce(robust)
streg i.ttr_cat, dist(weibull) vce(robust)
streg ib2.site_relapse, dist(weibull) vce(robust)
streg i.multisite, dist(weibull) vce(robust)
streg i.initial_stage, dist(weibull) vce(robust)
streg i.prior_radiation, dist(weibull) vce(robust)
streg i.gtr_relapse, dist(weibull) vce(robust)



stset surv_months, failure(died)
local covars i.sex i.stratum i.age_rel_cat i.ttr_cat ///
           ib2.site_relapse  i.multisite i.gtr_relapse      // <- 7 substantive predictors

streg `covars', dist(weibull) vce(robust)      // PH parameterisation
estat ic                                        // AIC, BIC


streg `covars', dist(exponential) vce(robust)
estat ic


* Log-normal
streg `covars', dist(lognormal) vce(robust)

* Log-logistic
streg `covars', dist(loglogistic) vce(robust)

* Generalised gamma (most flexible of the built-ins)
streg `covars', dist(gengamma) vce(robust)

* Compare models
estimates stats _all, n(116)         // if you stored each model beforehand



ssc install stpm2


* (A) Macro version
local covars i.sex i.stratum ib2.site_relapse i.ttr_cat i.multisite i.gtr_relapse
stpm2 `covars', scale(hazard) df(4) vce(robust) eform   // single clean run

* (B) Explicit version
stpm2 i.sex i.stratum ib2.site_relapse i.ttr_cat ///
      i.multisite i.gtr_relapse, ///
      scale(hazard) df(4) vce(robust) eform


estat ic
estimates store RPmodel

*--------------------------------------------------------------*
*  Forest plot – flexible Royston‑Parmar model (HR, 95% CI)
*--------------------------------------------------------------*
coefplot  RPmodel,  eform  drop(_cons)                        ///
    /* keep only the covariate coefficients we care about ---- */ ///
    keep( 2.sex  2.stratum  1.site_relapse                    ///
          2.ttr_cat 3.ttr_cat 1.multisite                     ///
          1.gtr_relapse 2.gtr_relapse )                       ///
    /* reader‑friendly row labels --------------------------- */ ///
    rename( 2.sex          = "Male vs female"                 ///
            2.stratum      = "Stratum C vs B"                ///
            1.site_relapse = "Pulmonary-only vs other"       ///
            2.ttr_cat      = "7–12 mo vs 0–6 mo"             ///
            3.ttr_cat      = "> 12 mo vs 0–6 mo"             ///
            1.multisite    = "≥ 2 sites vs single"           ///
            1.gtr_relapse  = "Complete GTR vs no surgery"    ///
            2.gtr_relapse  = "Incomplete GTR vs no surgery") ///
    /* axes, CIs, markers ---------------------------------- */ ///
     xscale(log range(0.1 10)) xline(1, lpattern(dash)) xlabel(0.1 0.2 0.5 1 2 5 10 20)     ///
    ciopts(recast(rcap)) msymbol(D) msize(*1.3) legend(off) ///
    /* numeric HR labels next to markers ------------------- */ ///
    mlabel(@b)  mlabformat(%4.2f)  mlabpos(12)  mlabgap(*.3)  ///
    mlabcolor(black)  mlabsize(small)                         ///
    /* cosmetics ------------------------------------------- */ ///
    plotregion(margin(r+2))                                   ///
    title()
