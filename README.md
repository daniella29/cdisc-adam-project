# CDISC Pilot Study: SDTM to ADaM in R, with QC against the CDISC reference

## Aim
Build ADaM datasets (ADSL, then ADAE) from the CDISC pilot study SDTM data using R, then
check my datasets against the official CDISC ADaM datasets. Key parts are then repeated in SAS.

## Data
This project uses the public CDISC pilot study (`cdiscpilot01`) from the
[CDISC SDTM/ADaM pilot project](https://github.com/cdisc-org/sdtm-adam-pilot-project).
The data belongs to CDISC and is **not included in this repository**. See `data/README.md`
for how to download it. The data is used unmodified and with attribution to CDISC, under
their terms of use.

## Approach
1. Explore the SDTM and reference ADaM datasets
2. Write a short mapping spec (source SDTM variable -> ADaM variable, with the derivation rule)
3. Derive ADSL variables in R (treatment dates, population flags, age groups)
4. Derive ADAE variables in R (analysis dates, treatment-emergent flag)
5. Compare my datasets with the CDISC reference ADaM and document any differences
6. Repeat ADSL in SAS and compare with the R version
7. Produce a demographics table and an adverse event summary table

## Folder structure
```
data/        local copies of the CDISC data (not tracked by Git)
programs/    R and SAS programs, numbered in run order
specs/       mapping specifications
qc/          comparison and validation results
output/      derived datasets and tables
```

## Status
- [x] 1. Explore the data
- [ ] 2. ADSL mapping spec (in progress: `specs/adsl_notes.md` covers the variables derived so far)
- [ ] 3. ADSL in R (in progress: TRTSDT, TRTEDT, TRTDUR, TRT01P, TRT01A, SAFFL, ITTFL)
- [ ] 4. ADAE in R (in progress: TRTEMFL)
- [ ] 5. QC against CDISC reference (done for each derived variable so far; differences documented)
- [ ] 6. ADSL in SAS
- [ ] 7. Tables

## Tools
R (haven, dplyr), SAS, Git

## Limitations
Learning project. It uses an already-published study, so it does not cover mapping from raw
collected data to SDTM.
