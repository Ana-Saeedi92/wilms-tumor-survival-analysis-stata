********************************************************************************
* 01_data_cleaning.do
* Cohort import, restriction, and variable construction
********************************************************************************

do code/00_setup.do

import excel using "$RAW_DATA", ///
    sheet("sample_cleaned") cellrange(A1:CH198) firstrow clear

describe, full
codebook *, compact
misstable summarize

* Keep relapse strata of interest
keep if inlist(RELAPSESTRATUM, "Stratum B", "Stratum C")

tab RELAPSESTRATUM, missing
replace PAPERB = "NO" if missing(PAPERB)
replace PAPERC = "NO" if missing(PAPERC)
keep if PAPERB == "YES" | PAPERC == "YES"

* Restrict to favourable histology
keep if inlist(OriginalHistology, "FAVOR")

* Age at diagnosis
gen age_diag = (D_CDIAG_ORIGINAL - DOB) / 365.25
drop if missing(age_diag) | age_diag >= 16

* Bilateral disease and contralateral kidney flags
gen byte stageV = DIAGFSTG == "V"

gen byte clkid = 0
replace clkid = 1 if inlist(Relapse_11_1A, "CL KIDNEY") | inlist(Relapse_11_1B, "CL KID")

label define yesno 0 "No" 1 "Yes", replace
label values clkid yesno
tabulate clkid, missing

drop if DIAGFSTG == "V"
drop if Relapse_11_1A == "CL KIDNEY" | Relapse_22_1A == "CL KID"

* Histology flag
gen byte unfav = inlist(Original_Histology, "DIFANA", "FOCANA", "CCSK", "RTK")
label define hist 0 "Favourable" 1 "Unfavourable", replace
label values unfav hist
tab unfav

* Age at relapse
gen age_rel_yr = (D_REL1 - DOB) / 365.25
gen int age_rel_mo = round((D_REL1 - DOB) / 30.4375)
recode age_rel_mo (0/23=1) (24/47=2) (48/max=3), gen(age_rel_cat)
label define agecat 1 "0–23 mo" 2 "24–47 mo" 3 "≥48 mo", replace
label values age_rel_cat agecat
tab age_rel_cat

* Survival outcome setup inputs
format D_REL1 D_LASTFOLLOWUP %td
replace D_DEATH = trim(D_DEATH)
gen int death_td = date(D_DEATH, "MDY") if D_DEATH != ""
format death_td %td

gen byte died = !missing(death_td)
gen int surv_days = cond(died, death_td, D_LASTFOLLOWUP) - D_REL1
assert surv_days >= 0 | missing(surv_days)

gen double surv_months = surv_days / 30.4375
format surv_months %9.2f
gen double surv_years = surv_days / 365.25
format surv_years %9.2f

* Encoded variables commonly used later
capture encode RELAPSESTRATUM, gen(stratum)
label define relstr_lbl 1 "Stratum B" 2 "Stratum C", replace
label values stratum relstr_lbl

capture encode SEX, gen(sex)
label define sexlbl 1 "Female" 2 "Male", replace
label values sex sexlbl

* Time to relapse
capture drop time_to_relapse_days time_to_relapse_mo relapse_early ttr_cat
gen time_to_relapse_days = D_REL1 - D_CDIAG_ORIGINAL
gen time_to_relapse_mo = time_to_relapse_days / 30.44
gen relapse_early = time_to_relapse_mo < 12 if !missing(time_to_relapse_mo)
replace relapse_early = 0 if time_to_relapse_mo >= 12
label define early_lbl 1 "Early (<12 months)" 0 "Late (≥12 months)", replace
label values relapse_early early_lbl

destring dzfreeinterval, gen(time_to_relapse_mo_alt) ignore("M")
replace time_to_relapse_mo = time_to_relapse_mo_alt if missing(time_to_relapse_mo) & !missing(time_to_relapse_mo_alt)
drop time_to_relapse_mo_alt

gen byte ttr_cat = .
replace ttr_cat = 1 if time_to_relapse_mo <= 6
replace ttr_cat = 2 if time_to_relapse_mo > 6  & time_to_relapse_mo <= 12
replace ttr_cat = 3 if time_to_relapse_mo > 12
label define ttrlbl 1 "0–6 mo" 2 "7–12 mo" 3 ">12 mo", replace
label values ttr_cat ttrlbl
label variable ttr_cat "Time to relapse (categorical)"
tab ttr_cat, missing

* Site of first relapse
gen lung_siteA = (Relapse_11_1A == "LUNG")
gen lung_siteB = (Relapse_11_1B == "LUNG")

gen site_relapse = .
replace site_relapse = 1 if lung_siteA == 1 & (missing(Relapse_11_1B) | lung_siteB != 1)
replace site_relapse = 2 if lung_siteB == 1 | (lung_siteA == 1 & lung_siteB == 1) | (lung_siteA == 0)
label define site_lbl 1 "Pulmonary-only" 2 "Extrapulmonary or multisite", replace
label values site_relapse site_lbl
tab site_relapse

* Site of second relapse
gen byte relapse_cat3 = .
replace relapse_cat3 = 1 if regexm(upper(Relapse_22_1A), "LUNG") | regexm(upper(Relapse_22_1B), "LUNG")
replace relapse_cat3 = 2 if relapse_cat3 == . & ( !missing(Relapse_22_1A) | !missing(Relapse_22_1B) )
replace relapse_cat3 = 0 if relapse_cat3 == .
label define relapse_cat3_lbl 1 "Lung relapse" 2 "Non-lung relapse" 0 "No relapse recorded", replace
label values relapse_cat3 relapse_cat3_lbl
tabulate relapse_cat3, missing

* Number of relapse sites
gen n_sites = 0
replace n_sites = n_sites + 1 if !missing(Relapse_11_1A)
replace n_sites = n_sites + 1 if !missing(Relapse_11_1B)

gen multisite = (n_sites >= 2)
label define multi_lbl 0 "Single site" 1 "≥2 sites", replace
label values multisite multi_lbl
tab multisite

* Gross total resection at relapse
replace Sx_11_GTRSITEB = "YES" if lower(Sx_11_GTRSITEB) == "yes"
replace Sx_11_GTRSITEB = "" if Sx_11_GTRSITEB == "NQ"

gen str10 ANYSx_11_clean = trim(upper(ANYSx_11))
replace Sx_11_GTRSITEA = upper(trim(Sx_11_GTRSITEA))

gen byte gtr_relapse = .
replace gtr_relapse = 0 if ANYSx_11_clean == "NO"
replace gtr_relapse = 1 if ///
    ANYSx_11_clean == "YES" & ///
    Sx_11_GTRSITEA == "YES" & ///
    inlist(Sx_11_GTRSITEB, "YES", "NA")
replace gtr_relapse = 2 if ANYSx_11_clean == "YES" & gtr_relapse == .
label define gtr_lbl 0 "No surgery" 1 "Complete GTR" 2 "Incomplete/partial", replace
label values gtr_relapse gtr_lbl
tab gtr_relapse, missing

* Initial overall stage and prior radiation
capture encode DIAGFSTG, gen(initial_stage)
capture encode XRTGIVENDIAG, gen(prior_radiation)

* In-field relapse indicator
gen str20 RT_infield22_clean = trim(upper(RT_infield_22))

gen byte infield = .
replace infield = 1 if strpos(RT_infield22_clean, "YES") > 0
replace infield = 0 if strpos(RT_infield22_clean, "NO")  > 0
label define infield_lbl 0 "Out-field relapse" 1 "In-field relapse", replace
label values infield infield_lbl

gen byte infield3 = .
replace infield3 = 1 if strpos(RT_infield22_clean, "YES") > 0
replace infield3 = 0 if strpos(RT_infield22_clean, "NO")  > 0
replace infield3 = 2 if missing(RT_infield22_clean) | ///
    (!strpos(RT_infield22_clean, "YES") & !strpos(RT_infield22_clean, "NO"))
label define infield3_lbl 0 "Out-field relapse" 1 "In-field relapse" 2 "Unavailable", replace
label values infield3 infield3_lbl
tab infield3, missing

save "$PROJECT_ROOT/data/analysis_working.dta", replace
