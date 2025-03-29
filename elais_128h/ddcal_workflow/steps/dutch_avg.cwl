class: CommandLineTool
cwlVersion: v1.2
id: dp3_avg_dutch
label: DP3 averaging for Dutch resolution calibration
doc: Average MeasurementSet in time and frequency for direction-dependent calibration with Dutch stations in DDE-mode.

baseCommand:
  - DP3

inputs:
  - id: msin
    type: Directory
    doc: Input MeasurementSet frequency bands.
    inputBinding:
      position: 0
      prefix: msin=
      separate: false

outputs:
  - id: ms_avg
    doc: Concatenated averaged MeasurementSet for 6" DDE calibration.
    type: Directory
    outputBinding:
      glob: "*ms.avg.ms"

  - id: logfile
    type: File[]
    outputBinding:
      glob: dp3_dutch_avg*.log
    doc: |
        The files containing the stdout
        and stderr from the step.

arguments:
  - steps=[avg]
  - avg.type=averager
  - avg.timeresolution=16
  - avg.freqresolution='195.312kHz'
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

stdout: dp3_dutch_avg.log
stderr: dp3_dutch_avg_err.log
