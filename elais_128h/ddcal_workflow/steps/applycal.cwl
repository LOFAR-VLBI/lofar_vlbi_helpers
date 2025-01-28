cwlVersion: v1.2
class: CommandLineTool
id: applycal
label: Apply calibration solutions
doc: Apply calibration solutions from h5parm on MeasurementSet

baseCommand:
  - python3

inputs:
    - id: ms
      type: Directory
      doc: Input MeasurementSet
      inputBinding:
        position: 5
    - id: h5parm
      type: File
      doc: Input h5parm
      inputBinding:
        prefix: "--h5"
        position: 4
        itemSeparator: " "
        separate: true
    - id: lofar_helpers
      type: Directory
      doc: lofar helpers directory

outputs:
    - id: ms_out
      type: Directory
      doc: Output MeasurementSet with applied solutions from h5parm
      outputBinding:
        glob: "applied_*"
    - id: logfile
      type: File[]
      doc: Log files corresponding to this step
      outputBinding:
        glob: applycal*.log

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(inputs.ms)
        writable: true
      - entry: $(inputs.h5parm)

arguments:
  - $( inputs.lofar_helpers.path + '/ms_helpers/applycal.py' )
  - --msout
  - $( 'applied_' + inputs.ms.basename )

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl
  - class: ResourceRequirement
    coresMin: 4

stdout: applycal.log
stderr: applycal_err.log