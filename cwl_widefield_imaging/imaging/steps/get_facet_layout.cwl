class: CommandLineTool
cwlVersion: v1.2
id: get_facet_layout
label: DS9 Facet Generator
doc: This step generates DS9 facet layout using a specified HDF5 file and MS.

baseCommand: make_facets.py

inputs:
  - id: msin
    type: Directory
    doc: The measurement set file.
    inputBinding:
      prefix: "--ms"
      position: 0

  - id: h5parm
    type: File
    doc: The HDF5 file containing the facet information.
    inputBinding:
      prefix: "--h5"
      position: 1

  - id: imsize
    type: int
    doc: Image size in pixels.
    default: 22500
    inputBinding:
      prefix: "--imsize"
      position: 2

  - id: pixelscale
    type: float
    doc: Pixel scale in arcseconds per pixel.
    default: 0.4
    inputBinding:
      prefix: "--pixelscale"
      position: 3

  - id: regionfile
    type: string
    doc: The name of the output DS9 region file.
    default: "facets.reg"
    inputBinding:
      prefix: "--DS9regionout"
      position: 4

outputs:
  - id: facet_regions
    type: File
    doc: The output DS9 region file.
    outputBinding:
      glob: $(inputs.regionfile)
  - id: logfile
    type: File[]
    doc: log files from get_facet_layout
    outputBinding:
      glob: get_facet_layout*.log


requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(inputs.h5parm)
      - entry: $(inputs.msin)


hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl
  - class: ResourceRequirement
    coresMin: 1

stdout: get_facet_layout.log
stderr: get_facet_layout_err.log
