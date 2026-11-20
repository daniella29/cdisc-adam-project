# Program:  01_explore_data.R
# Purpose:  Read and explore the CDISC pilot SDTM and ADaM datasets
# Input:    data/sdtm/dm.xpt, data/sdtm/ae.xpt, data/adam/adsl.xpt, data/adam/adae.xpt
# Output:   console only (no datasets created)
# Author:   Daniella Parthipan
# Created:  2026-11-19

# install.packages(c("haven", "dplyr"))   # run once if needed
library(haven)
library(dplyr)

dm   <- read_xpt("data/sdtm/dm.xpt")
ae   <- read_xpt("data/sdtm/ae.xpt")
adsl <- read_xpt("data/adam/adsl.xpt")
adae <- read_xpt("data/adam/adae.xpt")

# Structure of each dataset
glimpse(dm)
glimpse(adsl)

# Questions to answer from the output (write the answers in your notes):
# 1. How many rows and columns does each dataset have?
dim(dm); dim(adsl); dim(ae); dim(adae)

# 2. What treatment arms are in DM, and how many subjects in each?
dm %>% count(ARM)

# 3. What treatment groups are in ADSL (TRT01A)? Why does ADSL have fewer subjects than DM?
adsl %>% count(TRT01A)

# 4. Which ADSL variables are NOT in DM? These are the ones you will need to derive.
setdiff(names(adsl), names(dm))

# 5. In ADAE, how many events are treatment-emergent (TRTEMFL)?
adae %>% count(TRTEMFL)

