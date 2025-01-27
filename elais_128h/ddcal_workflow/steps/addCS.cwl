cwlVersion: v1.2
class: CommandLineTool
id: addCS
label: Add core stations to h5parm
doc: Using h5_merger we add back the core stations to the h5parm, which had been replaced by ST001 (super station)

baseCommand:
  - python3

inputs:
  - id: ms
    type: Directory
    doc: Input MeasurementSet
    inputBinding:
      position: 2
      prefix: "-ms"
      itemSeparator: " "
      separate: true
  - id: h5parm
    type: File
    doc: Input h5parm
    inputBinding:
      prefix: "-in"
      position: 3
      itemSeparator: " "
      separate: true
  - id: selfcal
    type: Directory
    doc: facetselfcal directory

outputs:
    - id: preapply_h5
      type: File
      doc: h5parm with preapplied solutions and core stations
      outputBinding:
        glob: preapply_addCS.h5
    - id: logfile
      type: File[]
      doc: Log files corresponding to this step
      outputBinding:
        glob: h5_merger_dd*.log


arguments:
  - $( inputs.selfcal.path + '/submods/h5_merger.py' )
  - --h5_out=preapply_addCS.h5
  - --add_ms_stations

requirements:
  - class: InlineJavascriptRequirement

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl

stdout: h5_merger_dd.log
stderr: h5_merger_dd_err.log