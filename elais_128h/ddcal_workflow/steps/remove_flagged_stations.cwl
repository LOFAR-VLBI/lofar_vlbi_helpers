cwlVersion: v1.2
class: CommandLineTool

baseCommand:
  - python3

inputs:
  ms:
    type: Directory
    inputBinding:
      position: 3
  lofar_helpers:
    type: Directory

outputs:
  cleaned_ms:
    type: Directory
    outputBinding:
      glob: $(inputs.ms.basename)

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(inputs.ms)
        writable: true

arguments:
  - $( inputs.lofar_helpers.path + '/ms_helpers/remove_flagged_stations.py' )
  - --overwrite

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl
  - class: ResourceRequirement
    coresMin: 2