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