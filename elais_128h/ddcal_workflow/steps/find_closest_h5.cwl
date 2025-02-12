cwlVersion: v1.2
class: CommandLineTool
id: find_closest_h5
label: Find nearest direction from multi-dir h5parm
doc: Return h5parm which correspond to the nearest direction from multi-dir h5parm

baseCommand:
  - python3

inputs:
  - id: ms
    type: Directory
    doc: Input MeasurementSet
    inputBinding:
      prefix: "--msin"
      position: 3
      itemSeparator: " "
      separate: true
  - id: h5parm
    type: File
    doc: Input h5parm
    inputBinding:
      prefix: "--h5_in"
      position: 2
      itemSeparator: " "
      separate: true
  - id: lofar_helpers
    type: Directory
    doc: lofar helpers directory


outputs:
    - id: closest_h5
      type: File
      doc: output h5parm
      outputBinding:
        glob: output_h5s/source_0.h5
    - id: logfile
      type: File[]
      doc: Log files corresponding to this step
      outputBinding:
        glob: applycal_dd*.log


arguments:
  - $( inputs.lofar_helpers.path + '/h5_helpers/find_closest_h5.py' )

requirements:
  - class: InlineJavascriptRequirement

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl

stdout: find_closest_h5.log
stderr: find_closest_h5_err.log