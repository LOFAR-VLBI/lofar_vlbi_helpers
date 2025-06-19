class: Workflow
cwlVersion: v1.2
id: facet_subtract_per_subband
doc: Predict and subtract model data per subband and facet

inputs:
    - id: msin
      type: Directory
      doc: MeasurementSets
    - id: model_image_folder
      type: Directory
      doc: Directory with 1.2" model images
    - id: h5parm
      type: File
      doc: Multi-directional h5parms
    - id: polygons
      type: File[]
      doc: Facet polygons
    - id: polygon_info
      type: File
      doc: Polygon CSV file.
    - id: ncpu
      type: int?
      doc: Number of cores to use during predict and subtract
      default: 12
    - id: tmpdir
      type: string?
      doc: Temporary directory to run I/O heavy jobs

steps:

    - id: average_subband
      in:
         - id: msin
           source: msin
      out:
         - ms_avg
      run: ../../steps/prediction_avg.cwl

    - id: get_model_images_for_sb
      in:
         - id: msin
           source: msin
         - id: model_images
           source: model_image_folder
      out:
         - output_model_images
      run: ../../steps/get_model_images_for_sb.cwl

    - id: predict_facets
      in:
         - id: msin
           source: average_subband/ms_avg
         - id: h5parm
           source: h5parm
         - id: polygons
           source: polygons
         - id: model_images
           source: get_model_images_for_sb/output_model_images
         - id: ncpu
           source: ncpu
         - id: tmpdir
           source: tmpdir
      out:
         - predicted_ms
      run: ../../steps/predict_facets.cwl

    - id: make_facet_ms
      in:
         - id: avg_ms
           source: predict_facets/predicted_ms
         - id: full_ms
           source: msin
         - id: h5parm
           source: h5parm
         - id: polygons
           source: polygons
         - id: polygon_info
           source: polygon_info
         - id: ncpu
           source: ncpu
         - id: tmpdir
           source: tmpdir
      out:
         - facet_ms
      run: ../../steps/make_facet_ms.cwl
      scatter: polygons


requirements:
  - class: MultipleInputFeatureRequirement
  - class: ScatterFeatureRequirement

outputs:
    - id: subtracted_facet_ms
      type: Directory[]
      outputSource: make_facet_ms/facet_ms
