class: CommandLineTool
cwlVersion: v1.2
id: predict_facet
label: Predict with WSClean
doc: This step subtracts all sources using WSClean.

baseCommand: python

inputs:
  - id: subtracted_ms
    type: Directory
    doc: The measurement set file used for source prediction in subtracted data.

  - id: model_image_folder
    type: Directory
    doc: The folder containing the model images.

  - id: polygon_regions
    type: File
    doc: The DS9 region file that defines the facets for prediction.

  - id: h5parm
    type: File
    doc: The HDF5 file containing the solutions for prediction.

  - id: lofar_helpers
    type: Directory
    doc: The HDF5 file containing the solutions for prediction.

  - id: polygon_info
    type: File
    doc: csv with polygon information.

outputs:
  - id: logfile
    type: File
    doc: Log files from subtraction fov.
    outputBinding:
      glob: subtract_fov*.log
  - id: facet_ms
    type: Directory
    doc: MS subtracted data
    outputBinding:
      glob: sub1.2*.ms


arguments:
  - valueFrom: $( inputs.lofar_helpers.path + '/subtract/subtract_with_wsclean.py' )
  - valueFrom: --mslist $(inputs.msin.path)
  - valueFrom: --model_image_folder $(inputs.model_image_folder.path)
  - valueFrom: --h5parm_predict $(inputs.h5parm.path)
  - valueFrom: --region $(inputs.polygon_regions.path) \
  - valueFrom: --applybeam
  - valueFrom: --applycal
  - valueFrom: --forwidefield
  - valueFrom: --inverse

requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(inputs.subtracted_ms)
      - entry: $(inputs.model_image_folder)
      - entry: $(inputs.polygon_regions)
      - entry: $(inputs.h5parm)
      - entry: $(inputs.polygon_info)

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl
  - class: ResourceRequirement
    coresMin: 10

stdout: subtract_fov.log
stderr: subtract_fov_err.log