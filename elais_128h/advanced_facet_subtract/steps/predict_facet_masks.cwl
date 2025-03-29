class: CommandLineTool
cwlVersion: v1.2
id: predict_facet_masks
label: Predict facets
doc: Predict facet masks for subtractions

baseCommand:
  - predict_facet_mask.py

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
        separate: true
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
    - id: ncpu
      type: int?
      doc: Number of cores to use during predict and subtract.
      default: 16
    - id: copy_to_local_scratch
      type: boolean?
      default: false
      inputBinding:
        prefix: "--copy_to_local_scratch"
        position: 5
        separate: false
      doc: Whether you want this step to copy data to local scratch space when running on a cluster without shared scratch.


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

arguments:
    - --ncpu=$(inputs.ncpu)

hints:
    - class: DockerRequirement
      dockerPull: vlbi-cwl
    - class: ResourceRequirement
      coresMin: $(inputs.ncpu)

requirements:
    - class: InitialWorkDirRequirement
      listing:
        - entry: $(inputs.msin)
          writable: true
        - entry: $(inputs.model_images)
        - entry: $(inputs.h5parm)
        - entry: $(inputs.polygons)

stdout: predict_facet.log
stderr: predict_facet_err.log
