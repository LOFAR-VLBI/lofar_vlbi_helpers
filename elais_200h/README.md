# DATA REDUCTION FOR ELAIS-N1 200hrs

Step 1) Download LOFAR data from the LTA. \
Step 2) Run `run_linc.sh` for pre-calibration.\
Step 3) Run `run_ddf.sh` for obtaining initial Dutch solutions.\
Step 4) Run `run_delaycal.sh` for preparing DI calibration.\
Step 5) Run `run_dical.sh` for running DI calibration.\
Step 6) Run `run_ddcal.sh` for running DD calibration. \
Step 8) Run `1asec_imaging.sh` for creating 1.2" wide-field image. \
Step 9) Run `run_subtract_facets.sh` to split out datasets for each facet.\
Step 10) Run `extra_selfcal.sh` to perform additional calibration on subtracted facets.\
Step 11) Run `sva.sh` to apply sidereal visibility averaging on the data.

For details, see: \
de Jong et al. 2025a (https://ui.adsabs.harvard.edu/abs/2025A%26A...694A..98D/abstract) \
de Jong et al. 2025b (https://ui.adsabs.harvard.edu/abs/2025MNRAS.542.3253D/abstract) \
de Jong et al. in prep.