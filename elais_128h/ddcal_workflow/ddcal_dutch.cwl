cwlVersion: v1.2
class: Workflow
id: ddcal_dutch
label: DD calibration Dutch stations
doc: Performing DD calibration for Dutch stations only

inputs:
    - id: msin
      type: Directory[]
      doc: Input unaveraged MeasurementSets
    - id: dd_selection_csv
      type: File
      doc: DD selection CSV (with phasediff scores)
    - id: lotss_catalogue
      type: File
      doc: LoTSS 6" catalogue
    - id: selfcal
      type: Directory
      doc: facetselfcal directory

steps:
    - id: average_6asec
      in:
        - id: msin
          source: msin
      out:
        - ms_avg
      run: steps/dutch_avg.cwl
    - id: make_dd_config
      in:
        - id: lotss_catalogue
          source: lotss_catalogue
        - id: ms
          source: average_6asec/ms_avg
      out:
        - dd_config_dutch
        - directions
      run: steps/make_dd_config_dutch.cwl
    - id: facetselfcal
      in:
        - id: msin
          source: average_6asec/ms_avg
        - id: selfcal
          source: selfcal
        - id: configfile
          source: make_dd_config/dd_config_dutch
        - id: dde_directions
          source: make_dd_config/directions
      out:
        - h5parm
        - images
        - fits_images
      run: steps/facet_selfcal_6asec.cwl


outputs:
  - id: merged_h5
    type: File
    outputSource: facetselfcal/h5parm
    doc: Final merged h5parm with multiple directions
  - id: selfcal_images
    type: File[]
    outputSource: facetselfcal/images
    doc: Selfcal images for inspection
