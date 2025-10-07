class: CommandLineTool
cwlVersion: v1.2
id: predict_facets
doc: Predict facet with MeasurementSet

baseCommand:
    - predict_facet.py

inputs:
    - id: msin
      type: Directory
      doc: Input MeasurementSet
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
      type: File
      doc: Facet polygon
      inputBinding:
        prefix: "--polygon"
        position: 4
        separate: true
    - id: tmpdir
      type: string?
      doc: Temporary directory to run I/O heavy jobs
      inputBinding:
        prefix: "--tmp"
        position: 5
        separate: true
    - id: ncpu
      type: int?
      doc: Number of cores to use during predict and subtract.
      default: 6
      inputBinding:
        prefix: "--ncpu"
        position: 6
        separate: true

outputs:
    - id: model_data_npy
      type: File
      doc: Predicted MeasurementSet
      outputBinding:
        glob: "*.npy"

    - id: logfile
      type: File[]
      doc: Log files
      outputBinding:
        glob: predict_facet*.log

arguments:
    - --cleanup

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
