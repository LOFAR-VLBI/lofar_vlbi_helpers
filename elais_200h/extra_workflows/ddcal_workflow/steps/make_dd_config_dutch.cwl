cwlVersion: v1.2
class: CommandLineTool
id: make_dd_config
label: Make Dutch DD config file
doc: Return configuration files as input for facetselfcal Dutch direction-dependent solve in facet-mode.

baseCommand:
    - make_config_dutch.py

inputs:
    - id: source_catalogue
      type: File
      doc: LoTSS 6" catalogue
      inputBinding:
        position: 1
        prefix: "--catalogue"
        itemSeparator: " "
        separate: true
    - id: ms
      type: Directory
      doc: MeasurementSet
      inputBinding:
        prefix: "--ms"
        position: 2
        itemSeparator: " "
        separate: true

outputs:
    - id: dd_config_dutch
      type: File
      doc: Parameter configuration file for facetselfcal
      outputBinding:
        glob: "dutch_config.txt"
    - id: directions
      type: File
      doc: Direction file with information about averaging settings for each calibrator source
      outputBinding:
        glob: "directions.txt"
    - id: logfile
      type: File[]
      doc: Log files corresponding to this step
      outputBinding:
        glob: make_dd_config*.log

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl

stdout: make_dd_config_dutch.log
stderr: make_dd_config_dutch_err.log