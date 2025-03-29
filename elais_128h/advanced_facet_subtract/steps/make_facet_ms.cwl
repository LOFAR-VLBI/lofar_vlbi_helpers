class: CommandLineTool
cwlVersion: v1.2
id: make_facet_ms
label: Make averaged subtracted facet MS
doc: Make a MeasurementSet that has subtracted everything outside its facet

baseCommand:
  - make_facet_ms.py

inputs:
    - id: avg_ms
      type: Directory
      doc: Averaged MS to lower resolution
      inputBinding:
        prefix: "--from_ms"
        position: 1
        separate: true
    - id: full_ms
      type: Directory
      doc: Full MS without averaging
      inputBinding:
        prefix: "--to_ms"
        position: 2
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
    - id: polygon_info
      type: File
      doc: CSV with polygon information for averaging and names
      inputBinding:
        prefix: "--polygon_info"
        position: 5
        separate: true
    - id: ncpu
      type: int?
      doc: Number of cores to use during predict and subtract.
      default: 24
    - id: copy_to_local_scratch
      type: boolean?
      default: false
      inputBinding:
        prefix: "--copy_to_local_scratch"
        position: 5
        separate: false
      doc: Whether you want this step to copy data to local scratch space when running on a cluster without shared scratch.


outputs:
    - id: facet_ms
      type: Directory
      doc: Predicted and subtracted MeasurementSet
      outputBinding:
        glob: "facet*.ms"

    - id: logfile
      type: File[]
      doc: Log files from model selection
      outputBinding:
        glob: facet_ms*.log

arguments:
    - --cleanup
    - --ncpu=$(inputs.ncpu)

hints:
    - class: DockerRequirement
      dockerPull: vlbi-cwl
    - class: ResourceRequirement
      coresMin: $(inputs.ncpu)

requirements:
    - class: InitialWorkDirRequirement
      listing:
        - entry: $(inputs.full_ms)
          writable: true
        - entry: $(inputs.avg_ms)
        - entry: $(inputs.h5parm)
        - entry: $(inputs.polygons)
        - entry: $(inputs.polygon_info)


stdout: facet_ms.log
stderr: facet_ms_err.log
