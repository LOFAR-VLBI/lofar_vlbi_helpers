cwlVersion: v1.2
class: CommandLineTool

baseCommand: make_config.py

inputs:
  ms:
    type: Directory
    inputBinding:
      position: 1
      prefix: "--ms"
      itemSeparator: " "
      separate: true
  phasediff_output:
    type: File
    inputBinding:
      prefix: "--phasediff_output"
      position: 2
      itemSeparator: " "
      separate: true

outputs:
  dd_config:
    type: File
    outputBinding:
      glob: "*.config.txt"

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl