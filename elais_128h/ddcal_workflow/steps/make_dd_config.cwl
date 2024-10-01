cwlVersion: v1.2
class: CommandLineTool

baseCommand:
    - python3
    - make_config.py

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

requirements:
  - class: InitialWorkDirRequirement
    listing:
      - entry: $( input.ms )
        entryname: $( input.ms.basename + '.config.txt' )
        writable: true

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl