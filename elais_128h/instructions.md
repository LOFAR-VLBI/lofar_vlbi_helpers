### VLBI data reduction for wide-field imaging

Input starting point: list of html files from the LTA with staged calibrator and target links.

#### Scripts:

1) ```cwl_widefield_imaging/download_lta.sh calibrator.html target.html```
2) ```cwl_widefield_imaging/run_linc.sh``` \
3) ```cwl_widefield_imaging/run_ddf.sh``` \
4) ```cwl_widefield_imaging/run_delaycal.sh``` \
5) ```cwl_widefield_imaging/run_splitdir_chunked.sh <CSV>``` (CSV should include ID, RA, DEC of candidates)

Important supporting repositories: \
https://github.com/tikk3r/flocs \
https://git.astron.nl/RD/VLBI-cwl \
https://github.com/jurjen93/lofar_helpers
