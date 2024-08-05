class: Workflow
cwlVersion: v1.2
id: wide-field-imaging
label: Wide Field Imaging
doc: |
  This workflow employs wsclean by splitting all facets into separate measurement sets.

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
    - id: h5merger
      type: Directory
      doc: The h5merger directory.
    - id: sidereal_visiblity_averaging
      type: boolean?
      default: false
      doc: Whether to apply sidereal visibility averaging


steps:
    - id: make_facet_layout
      label: Target Phaseup
      in:
        - id: msin
          source: msin
        - id: h5parm
          source: h5parm
      out:
        - id: regionfile
      run: steps/...
    - id: split_polygons
      label: Split polygon file
      in:
        - id: regionfile
          source: make_facet_layout/regionfile
        - id: h5parm
          source: h5parm
      out:
        - id: polygon_info
        - id: polygon_regions
        - id: polygon_h5parms # TODO: NEED UPDATE IN THIS SCRIPT TO SPLIT THIS OUT AS WELL
      run: steps/...
    - id: subtract_fov
      label: Subtract complete FoV
      in:
         - id: msin
           source: msin
         - id: h5parm
           source: h5parm
         - id: facets
           source: split_polygons/regionfile
         - id: model_image_folder
           source: model_image_folder
      out:
         - subtracted_ms
      run: steps/...
      scatter: msin
    - id: predict_polygon #TODO: Make python script to do this (or adapt subtract script)
      label: Predict a polygon back in empty MS
      in:
         - id: subtracted_ms
           source: subtract_fov/subtracted_ms
         - id: polygon_regions
           source: split_polygons/polygon_regions
         - id: polygon_info
           source: split_polygons/polygon_info
         - id: polygon_h5parms
           source: split_polygons/polygon_h5parms
      out:
         - facet_ms
      run: steps/...
      scatter: [polygon_h5parms, subtracted_ms]
      scatterMethod: #TODO: dotproduct?
    - id: sidereal_visibility_averaging
      label: Run Sidereal Visibility Averaging to reduce data volume for deep imaging
      in:
         - id: facet_ms
           source: predict_polygon/facet_ms
      out:
         - sav_facet_ms
    - id: imaging #TODO: Consider multi-res?
      label: Imaging of facets
      in:
         - id: msin
           source:
             - sidereal_visibility_averaging/sav_facet_ms
             - predict_polygon/subtracted_ms
           pickValue: first_non_null
      out:
         - id: facet_images
    - id: mosaicing #TODO: Consider multi-res?
      in:
         - id: images
           source: imaging/facet_images
      out:
         - id: fits_mosaic


outputs:
    - id: sav_facet_ms
      type: Directory[]
      outputSource:
        - sidereal_visibility_averaging/sav_facet_ms
        - predict_polygon/subtracted_ms
        pickValue: first_non_null
    - id: fits_images_facet
      type: Files[]
      outputSource:
        - imaging/facet_images
    - id: mosaic #TODO: Consider multi-res?
      type: File
      outputSource:
        - mosaicing/fits_mosaic
