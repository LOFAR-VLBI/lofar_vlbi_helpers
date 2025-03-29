class: CommandLineTool
cwlVersion: v1.2
id: split_polygons
label: Split Polygon Facets
doc: This step splits a multi-facet region file into individual facet region files.

baseCommand: python3

inputs:
  - id: h5parm
    type: File
    doc: Multi-directional HDF5 file.
    inputBinding:
      prefix: "--h5"
      position: 1

  - id: facet_regions
    type: File
    doc: The DS9 region file that defines the facets.
    inputBinding:
      prefix: "--reg"
      position: 2

  - id: lofar_helpers
    type: Directory
    doc: The lofar_helpers directory.

outputs:
  - id: polygon_regions
    type: File[]
    doc: The facet regions.
    outputBinding:
      glob: "poly*.reg"
  - id: polygon_info
    type: File
    doc: Polygon CSV file.
    outputBinding:
      glob: "*.csv"
  - id: logfile
    type: File[]
    doc: Log files from current step.
    outputBinding:
      glob: split_polygons*.log

arguments:
  - $(inputs.lofar_helpers.path)/ds9_helpers/split_polygon_facets.py
  - --extra_boundary=0.01

requirements:
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
