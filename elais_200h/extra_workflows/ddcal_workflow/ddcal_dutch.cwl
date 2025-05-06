cwlVersion: v1.2
class: Workflow
id: ddcal_dutch
label: DD calibration Dutch stations
doc: Performing wide-field DD calibration with facetselfcal for Dutch stations only.

inputs:
    - id: msin
      type: Directory[]
      doc: Input unaveraged MeasurementSets

    - id: source_catalogue
      type: File
      doc: LoTSS 6" catalogue

    - id: facetselfcal
      type: Directory
      doc: facetselfcal directory

    - id: lofar_helpers
      type: Directory
      doc: LOFAR helpers directory

steps:
    - id: average_6asec
      label: Average frequency sub-bands to 6" data resolution
      in:
        - id: msin
          source: msin
      out:
        - ms_avg
      run: ../../steps/dutch_avg.cwl
      scatter: msin

    - id: concat
      label: Concatenate averaged frequency sub-bands
      in:
        - id: msin
          source: average_6asec/ms_avg
        - id: lofar_helpers
          source: lofar_helpers
      out:
        - ms_concat
      run: ../../steps/concat_with_dummies.cwl

    - id: make_dd_config
      label: Make configuration file for direction-dependent calibration
      in:
        - id: source_catalogue
          source: source_catalogue
        - id: ms
          source: concat/ms_concat
      out:
        - dd_config_dutch
        - directions
      run: ../../steps/make_dd_config_dutch.cwl

    - id: run_facetselfcal
      label: Run facetselfcal
      in:
        - id: msin
          source: concat/ms_concat
        - id: facetselfcal
          source: facetselfcal
        - id: configfile
          source: make_dd_config/dd_config_dutch
        - id: dde_directions
          source: make_dd_config/directions
      out:
        - h5parm
        - images
        - fits_images
      run: ../../steps/facet_selfcal_dutch_only.cwl

requirements:
  - class: ScatterFeatureRequirement

outputs:
  - id: merged_h5
    type: File
    outputSource: run_facetselfcal/h5parm
    doc: Final merged h5parm with multiple directions

  - id: selfcal_widefield_images
    type: File[]
    outputSource: run_facetselfcal/images
    doc: Selfcal images for inspection
