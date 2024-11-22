cwlVersion: v1.2
class: CommandLineTool
id: make_dd_config
label: Make Dutch DD config file
doc: Return config file as input for facetselfcal Dutch DD solve

baseCommand:
    - make_config_dutch.py

inputs:
    - id: lotss_catalogue
      type: File
      doc: LoTSS 6" catalogue
      inputBinding:
        position: 2
        prefix: "--catalogue"
        itemSeparator: " "
        separate: true

    - id: phasediff_output
      type: File
      doc: Phasediff scoring output csv
      inputBinding:
        prefix: "--phasediff_output"
        position: 3
        itemSeparator: " "
        separate: true

outputs:
    - id: dd_config_dutch
      type: File
      doc: config file for facetselfcal
      outputBinding:
        glob: "dutch_config.txt"
    - id: directions
      type: File
      doc: direction file for facetselfcal
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