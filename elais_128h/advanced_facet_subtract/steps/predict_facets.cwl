class: CommandLineTool
cwlVersion: v1.2
id: get_model_image
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
      type: File[]
      doc: Model images
      inputBinding:
        prefix: "--model_images"
        position: 2
    - id: h5parm
      type: File
      doc: Multi-dir h5parm
      inputBinding:
        prefix: "--h5"
        position: 3
        separate: true
    - id: polygons
      type: File[]
      doc: Facet polygons
      inputBinding:
        prefix: "--polygons"
        position: 4
        separate: true

outputs:
    - id: predicted_ms
      type: Directory
      doc: Predicted MeasurementSet
      outputBinding:
        glob: "*.ms"

    - id: logfile
      type: File[]
      doc: Log files from model selection
      outputBinding:
        glob: predict_facet*.log

hints:
    - class: DockerRequirement
      dockerPull: vlbi-cwl
    - class: ResourceRequirement
      coresMin: 12

requirements:
    - class: InitialWorkDirRequirement
      listing:
        - entry: $(inputs.msin)
          writable: true


stdout: predict_facet.log
stderr: predict_facet_err.log
