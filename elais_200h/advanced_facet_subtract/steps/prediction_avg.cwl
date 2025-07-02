class: CommandLineTool
cwlVersion: v1.2
id: dp3_avg_for_prediction
label: DP3 averaging for prediction
doc: Average MeasurementSet in time and frequency for fast prediction.

baseCommand:
  - DP3

inputs:
  - id: msin
    type: Directory
    doc: Input MeasurementSet
    inputBinding:
      position: 0
      prefix: msin=
      separate: false

outputs:
  - id: ms_avg
    doc: MeasurementSet at 1.2" time/freq resolution
    type: Directory
    outputBinding:
      glob: "*ms.avg.ms"

  - id: logfile
    type: File[]
    outputBinding:
      glob: 1asec_avg*.log
    doc: |
        The files containing the stdout
        and stderr from the step.

arguments:
  - steps=[avg]
  - avg.type=averager
  - avg.timeresolution=4
  - avg.freqresolution='48.84kHz'
  - msout.storagemanager='dysco'
  - msout=$( inputs.msin.basename + '.avg.ms')

requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(inputs.msin)
        writable: false
  - class: ResourceRequirement
    coresMin: 4

stdout: 1asec_avg.log
stderr: 1asec_err.log

