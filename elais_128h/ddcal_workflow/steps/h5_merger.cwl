cwlVersion: v1.2
class: CommandLineTool

baseCommand:
  - python3

inputs:
  ms:
    type: Directory
    inputBinding:
      position: 2
      prefix: "-ms"
      itemSeparator: " "
      separate: true
  h5:
    type: File
    inputBinding:
      prefix: "-in"
      position: 3
      itemSeparator: " "
      separate: true
  lofar_helpers:
    type: Directory

outputs:
  preapply_h5:
    type: File
    outputBinding:
      glob: preapply.h5

arguments:
  - $( inputs.lofar_helpers.path + '/h5_merger.py' )
  - --h5_out preapply.h5
  - --propagate_flags

requirements:
  - class: InlineJavascriptRequirement

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl