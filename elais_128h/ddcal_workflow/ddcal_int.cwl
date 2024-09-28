cwlVersion: v1.2
class: Workflow


inputs:
  ms: Directory
  h5: File
  dd_selection_csv: File
  lofar_helpers: Directory
  selfcal: Directory


steps:
  remove_flagged_stations_step:
    run: steps/remove_flagged_stations.cwl
    in:
      ms: ms
      lofar_helpers: lofar_helpers
    out:
      - cleaned_ms

  find_closest_h5_step:
    run: steps/find_closest_h5.cwl
    in:
      h5: h5
      ms: remove_flagged_stations_step/cleaned_ms
      lofar_helpers: lofar_helpers
    out:
      - closest_h5

  h5_merger_step:
    run: steps/h5_merger.cwl
    in:
      ms: remove_flagged_stations_step/cleaned_ms
      h5: find_closest_h5_step/closest_h5
      lofar_helpers: lofar_helpers
    out:
      - preapply_h5

  applycal_step:
    run: steps/applycal.cwl
    in:
      ms: remove_flagged_stations_step/cleaned_ms
      h5: h5_merger_step/preapply_h5
      lofar_helpers: lofar_helpers
    out:
      - ms_out

  make_dd_config:
    run: steps/make_dd_config.cwl
    in:
      phasediff_output: dd_selection_csv
      ms: ms
    out:
      - dd_config


outputs:
  calibrated_ms:
    type: Directory
    outputSource: applycal_step/ms_out
  dd_config:
    type: File
    outputSource: make_dd_config/dd_config
