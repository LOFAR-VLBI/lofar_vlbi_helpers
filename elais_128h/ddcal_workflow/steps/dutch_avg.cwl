class: CommandLineTool
cwlVersion: v1.2
id: dp3_avg_dutch
label: DP3 averaging for Dutch resolution calibration
doc: |
    Average MeasurementSet in time and frequency for direction-dependent calibration for Dutch stations in DDE-mode

baseCommand:
  - DP3

inputs:
  - id: msin
    type: Directory[]
    doc: Input MeasurementSet subbands.
    inputBinding:
      position: 0
      prefix: msin=
      separate: false
      itemSeparator: ','
      valueFrom: "[$(self.map(function(d) { return d.path || d.location; }).join(','))]"

outputs:
  - id: ms_avg
    doc: |
        The output data with corrected
        data in MeasurementSet format.
    type: Directory
    outputBinding:
      glob: concat_6asec.ms

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
  - avg.freqstep=16
  - msout.storagemanager='dysco'
  - msout=concat_6asec.ms

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
    coresMin: 6

stdout: dp3_dutch_avg.log
stderr: dp3_dutch_avg_err.log
