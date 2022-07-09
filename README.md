## prefactor_helpers

Most scripts written by Roland Timmerman with additional changes made by Jurjen de Jong.

Step 0) run download_lta/make_folder_layout.sh to setup layout of folders\
Step 1) move html_calibrator.txt and html_target.txt (from LTA) to Target folder
Step 2) run download_lta/sbatch_download_series.sh to download the data that you have staged with by giving html.txt \
Step 3) run helper_scripts/findmissingdata.py to check the data\
Step 4) run prefactor_pipeline/run_PFC.sh to calibrate for the calibrator from the calibrator folder\
Step 5) run prefactor_pipeline/run_PFT.sh to calibrate the target from the target folder\

Also see --> de Gasperin et al 2019: https://www.aanda.org/articles/aa/pdf/2019/02/aa33867-18.pdf
