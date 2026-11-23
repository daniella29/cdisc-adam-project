# Program:  02_adsl.R
# Purpose:  Derive ADSL variables from SDTM (started with TRTSDT) and QC against CDISC ADSL
# Input:    data/sdtm/ex.xpt, data/sdtm/dm.xpt, data/adam/adsl.xpt
# Output:   console checks (datasets saved later)
# Author:   Daniella Parthipan
# Created:  2026-11-19

library(haven)
library(dplyr)

ex   <- read_xpt("data/sdtm/ex.xpt")
dm   <- read_xpt("data/sdtm/dm.xpt")
adsl <- read_xpt("data/adam/adsl.xpt")   # CDISC reference, used for QC only
adae <- read_xpt("data/adam/adae.xpt")   # CDISC reference, QC only

# Convert character dates (ISO 8601) to R dates
ex <- ex %>% mutate(EXSTDT = as.Date(EXSTDTC), EXENDT = as.Date(EXENDTC))

# TRTSDT: first dose date per subject
trt_dates <- ex %>%
  group_by(USUBJID) %>%
  summarise(TRTSDT = min(EXSTDT), .groups = "drop")

# QC against the CDISC reference ADSL
official <- adsl %>% select(USUBJID, TRTSDT_ref = TRTSDT)
check <- trt_dates %>% left_join(official, by = "USUBJID")
sum(check$TRTSDT != check$TRTSDT_ref, na.rm = TRUE)   # expect 0

# Looking at dose rows with a blank end date (early leavers)
ex %>%
  filter(is.na(EXENDT)) %>%
  select(USUBJID, EXSTDTC, EXENDTC) %>%
  left_join(dm %>% select(USUBJID, RFENDTC), by = "USUBJID")

# TRTEDT: last treatment end date per subject
# Rule: use EXENDT; if blank (early leaver), use RFENDT from DM
ex <- ex %>%
  left_join(dm %>% select(USUBJID, RFENDTC), by = "USUBJID") %>%
  mutate(RFENDT     = as.Date(RFENDTC),
         EXENDT_FIN = coalesce(EXENDT, RFENDT))

trt_end <- ex %>%
  group_by(USUBJID) %>%
  summarise(TRTEDT = max(EXENDT_FIN), .groups = "drop")

# QC against the CDISC reference ADSL
official_end <- adsl %>% select(USUBJID, TRTEDT_ref = TRTEDT)
check_end <- trt_end %>% left_join(official_end, by = "USUBJID")
sum(check_end$TRTEDT != check_end$TRTEDT_ref, na.rm = TRUE)   # expect 0


# TRTDUR: treatment duration in days (frist and last day both count, so +1)
trt_all <- trt_dates %>% 
  left_join(trt_end, by = "USUBJID") %>% 
  mutate(TRTDUR = as.numeric(TRTEDT - TRTSDT) + 1)

# QC against the CDISC reference ADSL
official_dur <- adsl %>% select(USUBJID, TRTDUR_ref = TRTDUR)
check_dur <- trt_all %>%  left_join(official_dur, by = "USUBJID")
sum(check_dur$TRTDUR != check_dur$TRTDUR_ref, na.rm = TRUE)


# TRT01P / TRT01A from DM
trt_arms <- dm %>% select(USUBJID, TRT01P = ARM, TRT01A = ACTARM)

check_arm <- trt_all %>% 
  left_join(trt_arms, by = "USUBJID") %>% 
  left_join(adsl %>% select(USUBJID, TRT01P_ref = TRT01P, TRT01A_ref = TRT01A),
            by = "USUBJID")

sum(check_arm$TRT01P != check_arm$TRT01P_ref, na.rm = TRUE)
sum(check_arm$TRT01A != check_arm$TRT01A_ref, na.rm = TRUE)
sum(is.na(check_arm$TRT01P_ref))


# ---- SAFFL: Safety Population Flag -------------------------------------
# Rule: "Y" if the subject has at least one exposure record with a start date.
# Note: placebo subjects have EXDOSE = 0 but ARE treated (placebo), so the
# rule "any EXDOSE > 0" is wrong: it wrongly flags 86 placebo subjects "N".
# Safety analysis needs placebo subjects to compare adverse events.

saffl <- ex %>%
  group_by(USUBJID) %>%
  summarise(SAFFL = if_else(is.na(min(EXSTDT)), "N", "Y"), .groups = "drop")

# QC against the CDISC reference ADSL (.x = reference, .y = mine)
qc_saffl <- adsl %>%
  left_join(saffl, by = "USUBJID") %>%
  summarise(
    n_match    = sum(SAFFL.x == SAFFL.y),                  # expect 254
    n_differ   = sum(SAFFL.x != SAFFL.y),                  # expect 0
    n_missing  = sum(is.na(SAFFL.y))                       # expect 0
  )

qc_saffl

# Creating ITTFL
# This is intent to treat flag
# Anyone who passes screening = Y and fails screening = N
# Screening is found in dm$ARM

ittfl_test <- dm %>% 
  mutate(ITTFL = if_else(ARM == "Screen Failure", "N", "Y"))

# QC comparing to ADSL
ittfl_qc <- adsl %>%
  rename(ITTFL_ref = ITTFL) %>% 
  select(USUBJID, ITTFL_ref) %>% 
  left_join(ittfl_test, by = "USUBJID") %>% 
  summarise(
    n_match = sum(ITTFL == ITTFL_ref),
    n_differ = sum(ITTFL != ITTFL_ref),
    n_missing = sum(is.na(ITTFL))
  )
  

# Moving onto AE data set:
# Looking at creating TRTEMFL

# Convert AESTDTC to AESTDT
ae <- ae %>% mutate(AESTDT = as.Date(AESTDTC)) 
# Checking if conversion worked properly
ae %>% 
  summarise(n_missing_stdt = sum(is.na(AESTDT)))
# 26 are missing
# Looking at which rows are missing
ae %>% filter(is.na(AESTDT)) %>% 
  select(AESTDTC)
unique(ae$AESTDTC)

# ---- TRTEMFL: Treatment-Emergent Flag (ADAE) -----------------------------
# Rule: "Y" if the AE started on or after the first dose (TRTSDT), else "N".
# AESTDTC can be partial (YYYY or YYYY-MM), so cut TRTSDT down to the same
# length as the AE date and compare as text (ISO dates sort correctly).
# If they are equal at that precision we can't tell, so flag "Y"
# (conservative for a safety analysis).

adae_try <- ae %>%
  left_join(trt_dates %>% select(USUBJID, TRTSDT), by = "USUBJID") %>%
  mutate(
    trtsdt_cut = substr(format(TRTSDT, "%Y-%m-%d"), 1, nchar(AESTDTC)),
    TRTEMFL    = if_else(AESTDTC >= trtsdt_cut, "Y", "N")
  )

# QC against the CDISC reference ADAE (key = subject + AE sequence number)
adae_qc <- adae %>%
  select(USUBJID, AESEQ, TRTEMFL_ref = TRTEMFL) %>%
  left_join(adae_try %>% select(USUBJID, AESEQ, TRTEMFL),
            by = c("USUBJID", "AESEQ")) %>%
  summarise(
    n_match   = sum(TRTEMFL == TRTEMFL_ref),
    n_differ  = sum(TRTEMFL != TRTEMFL_ref),
    n_missing = sum(is.na(TRTEMFL))
  )
adae_qc

