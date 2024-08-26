class: CommandLineTool
cwlVersion: v1.2
id: subtract_with_wsclean
label: Subtract with WSClean
doc: This step subtracts all sources using WSClean.

baseCommand: python

inputs:
  - id: msin
    type: Directory
    doc: The measurement set file used for source subtraction.
    inputBinding:
      prefix: "--mslist"
      position: 1

  - id: model_image_folder
    type: Directory
    doc: The folder containing the model images.
    inputBinding:
      prefix: "--model_image_folder"
      position: 2

  - id: facet_regions
    type: File
    doc: The DS9 region file that defines the facets for prediction.
    inputBinding:
      prefix: "--facets_predict"
      position: 3

  - id: h5parm
    type: File
    doc: The HDF5 file containing the solutions for prediction.
    inputBinding:
      prefix: "--h5parm_predict"
      position: 4

  - id: lofar_helpers
    type: Directory
    doc: The HDF5 file containing the solutions for prediction.

outputs:
  - id: logfile
    type: File[]
    doc: Log files from subtraction fov.
    outputBinding:
      glob: subtract_fov*.log
  - id: subtracted_ms
    type: Directory
    doc: MS subtracted data
    outputBinding:
      glob: $(inputs.msin.path)


arguments:
  - valueFrom: $( inputs.lofar_helpers.path + '/subtract/subtract_with_wsclean.py' )

requirements:
  - class: StepInputExpressionRequirement
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(inputs.msin)
        writable: true
      - entry: $(inputs.model_image_folder)
        writable: true
      - entry: $(inputs.facet_regions)
      - entry: $(inputs.h5parm)

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl
  - class: ResourceRequirement
    coresMin: 15

stdout: subtract_fov.log
stderr: subtract_fov_err.log