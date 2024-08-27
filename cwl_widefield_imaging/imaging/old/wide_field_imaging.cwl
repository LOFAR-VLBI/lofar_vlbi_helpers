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
    - id: sidereal_visiblity_averaging
      type: boolean?
      default: false
      doc: Whether to apply sidereal visibility averaging
    - id: lofar_helpers
      type: Directory
      doc: The lofar_helpers directory.

steps:
    - id: get_facet_layout
      label: Target Phaseup
      in:
        - id: msin
          source: msin
          valueFrom: $(self[0].path)
        - id: h5parm
          source: h5parm
      out:
        - id: ds9_region_file
      run: steps/get_facet_layout.cwl
    - id: subtract_fov
      label: Subtract complete FoV
      in:
         - id: msin
           source: msin
         - id: h5parm
           source: h5parm
         - id: facet_h5parm
           source: get_facet_layout/ds9_region_file
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
         - id: regionfile
           source: make_facet_layout/regionfile
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
         - id: polygon_info
           source: split_polygons/polygon_info
         - id: h5parm
           source: h5parm
         - id: model_image_folder
           source: model_image_folder
         - id: lofar_helpers
           source: lofar_helpers
      out:
         - facet_ms
      run: steps/predict_facet.cwl
      scatter: [polygon_region, subtracted_ms]
      scatterMethod: crossproduct

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
