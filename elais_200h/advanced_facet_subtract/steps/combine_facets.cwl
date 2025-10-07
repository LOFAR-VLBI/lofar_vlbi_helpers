class: CommandLineTool
cwlVersion: v1.2
id: combine_facets
doc: Combine facets by summing them together to form a facet mask and insert in MeasurementSet as model data

baseCommand:
    - combine_facets.py

inputs:
    - id: msin
      type: Directory
      doc: Input MeasurementSet
      inputBinding:
        prefix: "--ms"
        position: 1
        separate: true
    - id: facet_model_data
      type: File[]
      doc: All model data npy files
      inputBinding:
        prefix: "--model_data_npy"
        position: 2
        separate: true
    - id: tmpdir
      type: string?
      doc: Temporary directory to run I/O heavy jobs
      inputBinding:
        prefix: "--tmp"
        position: 3
        separate: true
    - id: ncpu
      type: int?
      doc: Number of cores to use during predict and subtract.
      default: 8
      inputBinding:
        prefix: "--ncpu"
        position: 4
        separate: true

outputs:
    - id: ms_with_polygon_model
      type: Directory
      doc: MeasurementSets with predicted polygon model data
      outputBinding:
        glob: "*.ms"

    - id: logfile
      type: File[]
      doc: Log files
      outputBinding:
        glob: combine_facets*.log

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
        - entry: $(inputs.facet_model_data)

stdout: combine_facets.log
stderr: combine_facets_err.log
