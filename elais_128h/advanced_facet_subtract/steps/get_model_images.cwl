class: CommandLineTool
cwlVersion: v1.2
id: get_model_images
label: Select model images matching with MS
doc: Select the model images that match with the input MeasurementSet

baseCommand:
  - get_model_image.py

inputs:
    - id: msin
      type: Directory
      doc: All input MS directions
      inputBinding:
        prefix: "--ms"
        position: 1
        separate: true
    - id: model_images
      type: Directory
      doc: Model images
      inputBinding:
        prefix: "--model_images"
        position: 2

outputs:
    - id: output_model_images
      type: File[]
      doc: Matching model images
      outputBinding:
        glob: "*_best.ms"
    - id: logfile
      type: File[]
      doc: Log files from model selection
      outputBinding:
        glob: model_selection*.log

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl

stdout: model_selection.log
stderr: model_selection_err.log

