prefactor_helpers v1.1

Step 1) run download_lta/sbatch_download_series.sh to download the data that you have staged with html \
Step 2) run helper_scripts/findmissingdata.py to check the data\
Step 3) run prefactor_pipeline/run_PFC.sh to calibrate for the calibrator\
Step 4) run prefactor_pipeline/run_DC.sh \
Step 5) run prefactor_pipeline/run_PFT.sh \

Checkout --> de Gasperin et al 2019: https://www.aanda.org/articles/aa/pdf/2019/02/aa33867-18.pdf