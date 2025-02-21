class: Workflow
cwlVersion: v1.2
id: facet_subtract_per_subband
label: Facet subtraction per subband
doc: Use WSClean to predict and subtract model data per subband and facet

inputs:
    - id: msin
      type: Directory
      doc: Unaveraged MeasurementSets with coverage of the target directions.
    - id: model_image_folder
      type: Directory
      doc: Folder with 1.2" model images.
    - id: h5parm
      type: File
      doc: Merged h5parms
    - id: polygons
      type: File[]
      doc: Facet polygons
    - id: polygon_info
      type: File
      doc: Polygon CSV file.

steps:

    - id: average_subband
      label: Average subband to lower time/freq resolution for fast prediction
      in:
         - id: msin
           source: msin
      out:
         - ms_avg
      run: ../../steps/prediction_avg.cwl

    - id: get_model_images
      label: Get corresponding model images
      in:
         - id: msin
           source: msin
         - id: model_images
           source: model_image_folder
      out:
         - output_model_images
      run: ../../steps/get_model_images.cwl

    - id: predict_facets
      label: Predict facet masks for subtraction
      in:
         - id: msin
           source: average_subband/ms_avg
         - id: h5parm
           source: h5parm
         - id: polygons
           source: polygons
         - id: model_images
           source: get_model_images/output_model_images
      out:
         - predicted_ms
      run: ../../steps/predict_facet_masks.cwl

    - id: make_facet_ms
      label: Interpolate facet masks from low to high resolution and subtract
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
