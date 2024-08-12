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

  - id: model_image_folder
    type: Directory
    doc: The folder containing the model images.

  - id: facet_regions
    type: File
    doc: The DS9 region file that defines the facets for prediction.

  - id: h5parm
    type: File
    doc: The HDF5 file containing the solutions for prediction.

  - id: lofar_helpers
    type: Directory
    doc: The HDF5 file containing the solutions for prediction.

outputs:
  - id: logfile
    type: File
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
  - valueFrom: --mslist $(inputs.msin.path)
  - valueFrom: --model_image_folder $(inputs.model_image_folder.path)
  - valueFrom: --facets_predict $(inputs.facet_regions.path)
  - valueFrom: --h5parm_predict $(inputs.h5parm.path)

requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(inputs.msin)
      - entry: $(inputs.model_image_folder)
      - entry: $(inputs.facet_regions)
      - entry: $(inputs.h5parm)

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl
  - class: ResourceRequirement
    coresMin: 10

stdout: subtract_fov.log
stderr: subtract_fov_err.log