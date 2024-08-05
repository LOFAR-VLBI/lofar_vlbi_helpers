### VLBI data reduction for wide-field imaging

Input starting point: list of html files from the LTA with staged calibrator and target links.

#### Scripts:

1) ```cwl_widefield_imaging/download_lta.sh calibrator.html target.html```
2) ```cwl_widefield_imaging/run_linc.sh``` \
3) ```cwl_widefield_imaging/run_ddf.sh <TARGET_RESULTS_FOLDER>``` (example: target/L769421_LINC_target/results_LINC_target/results) \
4) ```cwl_widefield_imaging/run_delaycal.sh``` \
5) ```cwl_widefield_imaging/run_splitdir.sh ```

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