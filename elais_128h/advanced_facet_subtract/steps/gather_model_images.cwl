class: CommandLineTool
cwlVersion: v1.2
id: gatherdis2
doc: Gather the correct WSClean model images from model_image_folder

baseCommand:
  - gather_model_images.sh

inputs:
  - id: model_image_folder
    type: Directory
    doc: Directory with model images
    inputBinding:
      position: 1

outputs:
  - id: filtered_model_image_folder
    type: Directory
    doc: Directory with filtered WSClean model images
    outputBinding:
      glob: output_images

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl
