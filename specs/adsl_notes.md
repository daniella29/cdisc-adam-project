# ADSL / ADAE derivation notes

Source: CDISC pilot study SDTM data (not stored in this repo). Derived in R (`programs/02_adsl.R`) and QC'd against the CDISC reference ADaM datasets.

| Variable | Label | Source | Derivation | QC result |
|---|---|---|---|---|
| TRTSDT | Treatment Start Date | EX.EXSTDTC | Convert EXSTDTC to a date; take the earliest date per subject | 0 differences (254 subjects) |
| TRTEDT | Treatment End Date | EX.EXENDTC, DM.RFENDTC | Convert EXENDTC to a date; if blank (early leaver), use DM.RFENDTC; take the latest date per subject | 0 differences (254 subjects) |
| TRTDUR | Treatment Duration (days) | TRTSDT, TRTEDT | TRTEDT - TRTSDT + 1 | 0 differences (254 subjects) |
| TRT01P | Planned Treatment | DM.ARM | Copied from DM.ARM | 0 differences (254 subjects) |
| TRT01A | Actual Treatment | DM.ACTARM | Copied from DM.ACTARM | 12 differences (see note 1) |
| SAFFL | Safety Population Flag | EX.EXSTDTC | "Y" if the subject has at least one EX record with a start date, else "N" | 0 differences (254 subjects) |
| ITTFL | Intent-to-Treat Flag | DM.ARM | "N" if ARM = "Screen Failure", else "Y" | 0 differences (254 subjects) |
| TRTEMFL | Treatment-Emergent Flag (ADAE) | AE.AESTDTC, TRTSDT | "Y" if AESTDTC >= TRTSDT, compared at the precision of AESTDTC (see note 2), else "N" | 0 differences (1191 AEs) |

## Notes

1. **TRT01A:** 12 subjects were planned for High Dose but DM.ACTARM says Low Dose. The CDISC reference ADSL sets TRT01A equal to TRT01P for all subjects. Documented, not changed.
2. **Partial AE dates:** AESTDTC is sometimes year only or year-month only. TRTSDT is cut to the same length and compared as text. If they are equal at that precision, the start cannot be determined, so the flag is "Y" (conservative for safety analysis).
3. **Screen failures:** the 52 screen failures are not in the reference ADSL, so no ITTFL "N" values appear.