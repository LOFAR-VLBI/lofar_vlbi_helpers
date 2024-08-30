class: CommandLineTool
cwlVersion: v1.2
id: split_polygons
label: Split Polygon Facets
doc: This step splits polygon facets using an HDF5 file and a DS9 region file.

baseCommand: python

inputs:
  - id: lofar_helpers
    type: Directory
    doc: The directory containing the split_polygon_facets.py script.

  - id: h5parm
    type: File
    doc: The HDF5 file used for splitting the polygon facets.
    inputBinding:
      prefix: "--h5"
      position: 1

  - id: facet_regions
    type: File
    doc: The DS9 region file that defines the facets.
    inputBinding:
      prefix: "--reg"
      position: 2

outputs:
  - id: polygon_regions
    type: File[]
    doc: The facet regions.
    outputBinding:
      glob: "poly*.reg"
  - id: polygon_info
    type: File
    doc: Polygon csv information file.
    outputBinding:
      glob: "*.csv"
  - id: logfile
    type: File[]
    doc: Log files from subtraction fov.
    outputBinding:
      glob: split_polygons*.log

arguments:
  - valueFrom: $(inputs.lofar_helpers.path)/ds9_helpers/split_polygon_facets.py

requirements:
  - class: StepInputExpressionRequirement
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(inputs.h5parm)
      - entry: $(inputs.facet_regions)

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl
  - class: ResourceRequirement
    coresMin: 1

stdout: split_polygons.log
stderr: split_polygons_err.log
