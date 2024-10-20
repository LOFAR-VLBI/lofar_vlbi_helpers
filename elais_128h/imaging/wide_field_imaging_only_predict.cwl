class: Workflow
cwlVersion: v1.2
id: wide-field-imaging
label: Wide Field Imaging
doc: |
  This workflow employs wsclean by splitting all facets into separate measurement sets.
  Note that it is highly recommended to run this with toil-cwl-runner and to use the scratch option (see documentation below).

requirements:
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: InlineJavascriptRequirement

inputs:
    - id: msin
      type: Directory[]
      doc: The input MS. This should have coverage of the target directions.
    - id: model_image_folder
      type: Directory
      doc: Folder with 1.2" model images
    - id: h5parm
      type: File
      doc: Fully merged h5parms
    - id: lofar_helpers
      type: Directory
      doc: The lofar_helpers directory.
    - id: scratch
      type: boolean?
      default: true
      doc: |
        Whether you are running the final predict on scratch. This is crucial for running sub-arcsecond imaging on clusters.
        If 'scratch' is set to 'true' (the default and recommended setting), ensure that there is sufficient scratch storage
        space on the running nodes (at least ~400 GB per 15 cores). Alternatively, if 'scratch' set to 'false', you must limit the number
        of parallel predict jobs to prevent excessive use of intermediate storage disk space. However, this approach
        may increase the overall wall-time.

steps:
    - id: get_facet_layout
      label: Target Phaseup
      in:
        - id: msin
          source: msin
          valueFrom: $(inputs.msin[0])
        - id: h5parm
          source: h5parm
      out:
        - id: facet_regions
      run: steps/get_facet_layout.cwl

    - id: subtract_fov
      label: Subtract complete FoV
      in:
         - id: msin
           source: msin
         - id: h5parm
           source: h5parm
         - id: facet_regions
           source: get_facet_layout/facet_regions
         - id: model_image_folder
           source: model_image_folder
         - id: lofar_helpers
           source: lofar_helpers
      out:
         - subtracted_ms
      run: steps/subtract_fov.cwl
      scatter: msin

    - id: split_polygons
      label: Split polygon file
      in:
         - id: facet_regions
           source: get_facet_layout/facet_regions
         - id: h5parm
           source: h5parm
         - id: lofar_helpers
           source: lofar_helpers
      out:
         - id: polygon_info
         - id: polygon_regions
      run: steps/split_polygons.cwl

    - id: predict_facet
      label: Predict a polygon back in empty MS
      in:
         - id: subtracted_ms
           source: subtract_fov/subtracted_ms
         - id: polygon_region
           source: split_polygons/polygon_regions
         - id: h5parm
           source: h5parm
         - id: polygon_info
           source: split_polygons/polygon_info
         - id: model_image_folder
           source: model_image_folder
         - id: lofar_helpers
           source: lofar_helpers
         - id: scratch
           source: scratch
      out:
         - facet_ms
      run: steps/predict_facet.cwl
      scatter: [polygon_region, subtracted_ms]
      scatterMethod: flat_crossproduct


outputs:
    - id: sav_facet_ms
      type: Directory[]
      outputSource: predict_facet/facet_ms
    - id: polygon_info
      type: File
      outputSource: split_polygons/polygon_info
    - id: polygon_regions
      type: File[]
      outputSource: split_polygons/polygon_regions
