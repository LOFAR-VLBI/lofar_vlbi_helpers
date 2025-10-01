class: CommandLineTool
cwlVersion: v1.2
id: makeparsets
label: Make concat parsets
doc: Generate parsets for MeasurementSet concatenation.

baseCommand:
  - concat_with_dummies

inputs:
  - id: msin
    type: Directory[]
    inputBinding:
        prefix: "--msin"
        position: 1
        separate: true
    doc: Input data in MeasurementSet format.
  - id: dysco_bitrate
    type: int?
    doc: Number of bits per float used for columns containing visibilities.
    default: 8
    inputBinding:
        prefix: "--bitrate"
        position: 2
        separate: true

outputs:
  - id: concat_parsets
    doc: Parsets for concatenation of input MeasurementSets
    type: File[]
    outputBinding:
      glob: '*.parset'

  - id: logfile
    doc: The files containing the stdout and stderr from the step.
    type: File[]
    outputBinding:
      glob: python_concat*.log

arguments:
  - --make_only_parset
  - --remove_flagged_station
  - --only_basename

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(inputs.msin)
        writable: false

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl

stdout: python_concat.log
stderr: python_concat_err.log
