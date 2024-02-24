### VLBI data reduction for wide-field imaging

Input starting point: list of html files from the LTA with staged calibrator and target links.

#### Scripts:

1) ```cwl_pipeline_scripts/download_lta.sh calibrator.html target.html```
2) ```cwl_pipeline_scripts/run_linc.sh``` \
TODO: INSERT VALIDATION STEP?
3) ```cwl_pipeline_scripts/run_ddf.sh <TARGET_RESULTS_FOLDER>``` (example: target/L769421_LINC_target/results_LINC_target/results) \
TODO: INSERT VALIDATION STEP?
4) ```cwl_pipeline_scripts/run_delaycal.sh```

#### Folder structure:

Corresponding to the number of scripts to run:

1) After downloading:
- L*/calibrator
- L*/target
2) After running LINC
- L*/calibrator/L*_LINC_calibrator 
- L*/calibrator/L*_LINC_target
3) After running DDF
- L*/ddf
4) After running delay-calibration
- ...


Important repositories: \
https://github.com/tikk3r/flocs \
https://git.astron.nl/RD/VLBI-cwl \
https://github.com/jurjen93/lofar_helpers