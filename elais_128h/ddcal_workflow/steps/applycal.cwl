cwlVersion: v1.2
class: CommandLineTool

baseCommand:
  - python3

inputs:
  ms:
    type: Directory
    inputBinding:
      position: 3
  h5:
    type: File
    inputBinding:
      prefix: "--h5"
      position: 2
      itemSeparator: " "
      separate: true
  lofar_helpers:
    type: Directory

outputs:
  ms_out:
    type: Directory
    outputBinding:
      glob: "applied_*"

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(inputs.ms)
        writable: true

arguments:
  - $( inputs.lofar_helpers.path + '/ms_helpers/applycal.py' )
  - --msout $( 'applied_' + inputs.ms.basename )

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl
  - class: ResourceRequirement
    coresMin: 4