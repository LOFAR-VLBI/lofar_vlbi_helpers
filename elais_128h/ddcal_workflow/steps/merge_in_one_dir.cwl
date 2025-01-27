cwlVersion: v1.2
class: CommandLineTool
id: merge_all_in_one
label: Merge multiple h5parm into one direction
doc: Using h5_merger to merge multiple h5parms into one direction

baseCommand:
  - python3

inputs:
  - id: first_h5
    type: File
    doc: Input h5parm 1
  - id: second_h5
    type: File
    doc: Input h5parm 2
  - id: selfcal
    type: Directory
    doc: facetselfcal directory

outputs:
    - id: merged_h5
      type: File
      doc: Merged h5parm
      outputBinding:
        glob: merged_dir.h5
    - id: logfile
      type: File[]
      doc: Log files corresponding to this step
      outputBinding:
        glob: multidir_h5_all_in_one*.log

arguments:
  - $( inputs.selfcal.path + '/submods/h5_merger.py' )
  - $(['--h5_in=', inputs.first_h5.path, ' ', inputs.second_h5.path].join(''))
  - --h5_out=merged_dir.h5
  - --merge_all_in_one

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entry: $( inputs.first_h5 )
        writable: false
      - entry: $( inputs.second_h5 )
        writable: false

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl

stdout: multidir_h5_all_in_one.log
stderr: multidir_h5_all_in_one_err.log