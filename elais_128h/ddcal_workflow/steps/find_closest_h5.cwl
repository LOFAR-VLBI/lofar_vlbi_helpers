cwlVersion: v1.2
class: CommandLineTool

baseCommand:
  - python

inputs:
  h5:
    type: File
    inputBinding:
      prefix: "--h5_in"
      position: 2
      itemSeparator: " "
      separate: true
  ms:
    type: Directory
    inputBinding:
      prefix: "--msin"
      position: 3
      itemSeparator: " "
      separate: true
  lofar_helpers:
    type: Directory

outputs:
  closest_h5:
    type: File
    outputBinding:
      glob: output_h5s/source_0.h5

arguments:
  - $( inputs.lofar_helpers.path + '/h5_helpers/find_closest_h5.py' )

requirements:
  - class: InlineJavascriptRequirement

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl