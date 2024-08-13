class: CommandLineTool
cwlVersion: v1.2
id: taql_update_data
label: TaQL Update Data
doc: This step uses TaQL to update the DATA column in a measurement set by adding MODEL_DATA to SUBTRACT_DATA.

baseCommand: [taql, update]

inputs:
  - id: msin
    type: Directory
    doc: The measurement set file to be updated.


outputs:
  - id: msout
    type: Directory
    doc: The updated measurement set.
    outputBinding:
      glob: $(inputs.msin.path)
  - id: logfile
    type: File[]
    doc: log files from taql
    outputBinding:
      glob: taql_update*.log


arguments:
  - valueFrom: $(inputs.msin.path) set DATA=SUBTRACT_DATA+MODEL_DATA

requirements:
  - class: StepInputExpressionRequirement
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(inputs.msin)

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl
  - class: ResourceRequirement
    coresMin: 10

stdout: taql_update.log
stderr: taql_update_err.log