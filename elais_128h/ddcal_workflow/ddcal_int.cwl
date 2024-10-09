cwlVersion: v1.2
class: Workflow
id: ddcal_int
label: DD calibration international stations
doc: Performing DD calibration for international stations only (follows after DD calibration for Dutch stations)

inputs:
  - id: msin
    type: Directory[]
    doc: Input MeasurementSets
  - id: dutch_multidir_h5
    type: File
    doc: h5parm with Dutch DD solutions
  - id: dd_selection_csv
    type: File
    doc: DD selection CSV (with phasediff scores)
  - id: lofar_helpers
    type: Directory
    doc: lofar_helpers directory
  - id: selfcal
    type: Directory
    doc: facetselfcal directory

steps:
    - id: ddcal
      in:
        - id: msin
          source: msin
        - id: dutch_multidir_h5
          source: dutch_multidir_h5
        - id: dd_selection_csv
          source: dd_selection_csv
        - id: lofar_helpers
          source: lofar_helpers
        - id: selfcal
          source: selfcal
      out:
        - h5parm
      scatter: msin
      run:
        # start ddcal for each ms
        cwlVersion: v1.2
        class: Workflow

        inputs:
          msin: Directory
          dutch_multidir_h5: File
          dd_selection_csv: File
          lofar_helpers: Directory
          selfcal: Directory

        steps:
          - id: remove_flagged_stations
            run: steps/remove_flagged_stations.cwl
            in:
              ms: msin
              lofar_helpers: lofar_helpers
            out:
              - cleaned_ms

          - id: find_closest_h5
            run: steps/find_closest_h5.cwl
            in:
              h5: dutch_multidir_h5
              ms: msin
              lofar_helpers: lofar_helpers
            out:
              - closest_h5

          - id: addCS
            run: steps/addCS.cwl
            in:
              ms: remove_flagged_stations/cleaned_ms
              h5: find_closest_h5/closest_h5
              lofar_helpers: lofar_helpers
            out:
              - preapply_h5

          - id: applycal
            run: steps/applycal.cwl
            in:
              ms: remove_flagged_stations/cleaned_ms
              h5: addCS/preapply_h5
              lofar_helpers: lofar_helpers
            out:
              - ms_out

          - id: make_dd_config
            run: steps/make_dd_config.cwl
            in:
              phasediff_output: dd_selection_csv
              ms: msin
            out:
              - dd_config

          - id: facetselfcal
            run: steps/facet_selfcal.cwl
            in:
              msin: applycal/ms_out
              selfcal: selfcal
              h5merger: lofar_helpers
              configfile: make_dd_config/dd_config
            out:
              - h5parm
              - images
              - fits_images

        outputs:
          h5parm:
            type: File
            outputSource: facetselfcal/h5parm
          images:
            type: File[]

        # end ddcal for each ms

    - id: multidir_merge
      label: Merge multiple directions into one h5parm
      in:
        - id: h5parms
          source: ddcal/h5parm
        - id: lofar_helpers
          source: lofar_helpers
      out:
        - multidir_h5
      run: steps/multidir_h5_merger.cwl

requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement

outputs:
  - id: merged_h5
    type: File
    outputSource: multidir_merge/multidir_h5
    doc: Final merged h5parm with multiple directions