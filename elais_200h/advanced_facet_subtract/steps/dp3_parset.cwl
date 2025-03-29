cwlVersion: v1.2
class: CommandLineTool
id: dp3_parset
label: DP3 with parset
doc: Run DP3 with a parset

baseCommand: DP3

inputs:
  - id: parset
    type: File
    doc: Parset for DP3
    inputBinding:
      position: 0

outputs:
  - id: msout
    type: Directory
    doc: Output measurement set
    outputBinding:
      glob: "*.ms"
  - id: logfile
    type: File[]
    outputBinding:
      glob: dp3_parset*.log
    doc: |
        The files containing the stdout
        and stderr from the step.

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl
  - class: ResourceRequirement
    coresMin: 6

stdout: dp3_parset.log
stderr: dp3_parset_err.log
