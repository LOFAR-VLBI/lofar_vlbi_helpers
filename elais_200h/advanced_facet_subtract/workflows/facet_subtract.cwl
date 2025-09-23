class: Workflow
cwlVersion: v1.2
id: facet_subtract
doc: Predict and subtract model data to split facets into separate MeasurementSets.

inputs:
    - id: msin
      type: Directory[]
      doc: MeasurementSets
    - id: model_image_folder
      type: Directory
      doc: Folder with 1.2" model images
    - id: h5parm
      type: File
      doc: Merged h5parms
    - id: dysco_bitrate
      type: int?
      doc: Number of bits per float used for columns containing visibilities
      default: 8
    - id: ncpu
      type: int?
      doc: Number of cores to use during predict and subtract
      default: 8
    - id: tmpdir
      type: string?
      doc: Temporary directory to run I/O heavy jobs

steps:
    - id: get_facet_layout
      in:
        - id: msin
          source: msin
          valueFrom: $(self[0])
        - id: h5parm
          source: h5parm
      out:
        - id: facet_regions
      run: ../steps/get_facet_layout.cwl

    - id: gather_all_model_images
      in:
        - id: model_image_folder
          source: model_image_folder
      out:
        - id: filtered_model_image_folder
      run: ../steps/gather_model_images.cwl

    - id: split_polygons
      in:
         - id: facet_regions
           source: get_facet_layout/facet_regions
         - id: h5parm
           source: h5parm
      out:
         - id: polygon_info
         - id: polygon_regions
      run: ../steps/split_polygons.cwl

    - id: predict_facets
      in:
         - id: msin
           source: msin
         - id: model_image_folder
           source: gather_all_model_images/filtered_model_image_folder
         - id: h5parm
           source: h5parm
         - id: polygons
           source: split_polygons/polygon_regions
         - id: polygon_info
           source: split_polygons/polygon_info
         - id: ncpu
           source: ncpu
         - id: tmpdir
           source: tmpdir
      out:
         - subtracted_facet_ms
      run: subworkflow/predict_subtract_facets.cwl
      scatter: msin

    - id: flatten_subtracte_ms
      in:
         - id: nestedarray
           source: predict_facets/subtracted_facet_ms
      out:
         - flattenedarray
      run: ../steps/flatten.cwl

    - id: make_concat_parset
      in:
         - id: msin
           source: flatten_subtracte_ms/flattenedarray
         - id: dysco_bitrate
           source: dysco_bitrate
      out:
         - id: concat_parsets
      run: ../steps/make_concat_parsets.cwl

    - id: concat_facets
      in:
        - id: msin
          source: flatten_subtracte_ms/flattenedarray
        - id: parset
          source: make_concat_parset/concat_parsets
      out:
        - id: msout
      run: ../steps/dp3_parset.cwl
      scatter: parset

requirements:
  - class: MultipleInputFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement

outputs:
    - id: facet_ms
      type: Directory[]
      outputSource: concat_facets/msout
    - id: polygon_info
      type: File
      outputSource: split_polygons/polygon_info
    - id: polygon_regions
      type: File[]
      outputSource: split_polygons/polygon_regions
