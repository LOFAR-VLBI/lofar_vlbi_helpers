cwlVersion: v1.2
class: CommandLineTool
id: multidir_h5_merger
label: Merge multiple h5parm files
doc: Using h5_merger we merge multiple h5parms from different directions into one multi-directional h5parm

baseCommand:
  - python3

inputs:
  - id: h5parms
    type: File[]
    doc: Input h5parms
    inputBinding:
      prefix: "-in"
      position: 1
      itemSeparator: " "
      separate: true
  - id: selfcal
    type: Directory
    doc: facetselfcal directory

outputs:
    - id: multidir_h5
      type: File
      doc: Multi-directional h5parm
      outputBinding:
        glob: merged.h5
    - id: logfile
      type: File[]
      doc: Log files corresponding to this step
      outputBinding:
        glob: multidir_h5_merger*.log

arguments:
  - $( inputs.selfcal.path + '/submods/h5_merger.py' )
  - --h5_out=merged.h5

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entry: $( inputs.h5parms )
        writable: true

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl

stdout: multidir_h5_merger.log
stderr: multidir_h5_merger_err.log