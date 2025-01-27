cwlVersion: v1.2
class: Workflow
id: ddcal_int
label: DD calibration international stations
doc: Performing DD calibration for international stations only (follows after DD calibration for Dutch stations)

inputs:
  - id: msin
    type: Directory[]
    doc: Input MeasurementSets of directions
  - id: dutch_multidir_h5
    type: File
    doc: h5parm with Dutch DD solutions
  - id: dd_selection_csv
    type: File?
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
        - merged_h5
        - images
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
              h5parm: dutch_multidir_h5
              ms: msin
              lofar_helpers: lofar_helpers
            out:
              - closest_h5

          - id: addCS
            run: steps/addCS.cwl
            in:
              ms: remove_flagged_stations/cleaned_ms
              h5parm: find_closest_h5/closest_h5
              selfcal: selfcal
            out:
              - preapply_h5

          - id: applycal
            run: steps/applycal.cwl
            in:
              ms: remove_flagged_stations/cleaned_ms
              h5parm: addCS/preapply_h5
              lofar_helpers: lofar_helpers
            out:
              - ms_out

          - id: make_dd_config
            run: steps/make_dd_config_int_dutch_resets.cwl
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
              configfile: make_dd_config/dd_config
            out:
              - h5_facetselfcal
              - images
              - fits_images

          - id: merge_all_in_one
            run: steps/merge_in_one_dir.cwl
            label: Merge preapplied h5parm and output h5parm in one h5parm
            in:
              first_h5: find_closest_h5/closest_h5
              second_h5: facetselfcal/h5_facetselfcal
              selfcal: selfcal
            out:
              - merged_h5

        outputs:
          merged_h5:
            type: File
            outputSource: merge_all_in_one/merged_h5
          images:
            type: File[]
            outputSource: facetselfcal/images

        # end ddcal for each ms

    - id: multidir_merge
      label: Merge multiple directions into one h5
      in:
        - id: h5parms
          source: ddcal/merged_h5
        - id: selfcal
          source: selfcal
      out:
        - multidir_h5
      run: steps/multidir_merger.cwl

    - id: flatten_images
      label: Flatten image array of arrays
      in:
        - id: nestedarray
          source: ddcal/images
      out:
        - flattenedarray
      run: steps/flatten.cwl

requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement

outputs:
  - id: final_merged_h5
    type: File
    outputSource: multidir_merge/multidir_h5
    doc: Final merged h5parm with multiple directions
  - id: selfcal_images
    type: File[]
    outputSource: flatten_images/flattenedarray
    doc: Selfcal images for inspection