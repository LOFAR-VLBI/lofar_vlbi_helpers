class: CommandLineTool
cwlVersion: v1.2
id: get_facet_layout
label: DS9 Facet Generator
doc: Generates DS9 facet layout for direction-dependent facet imaging.

baseCommand: ds9facetgenerator

inputs:
  - id: msin
    type: Directory
    doc: MeasurementSet
    inputBinding:
      prefix: "--ms"
      position: 2

  - id: h5parm
    type: File
    doc: Multi-directional HDF5 file.
    inputBinding:
      prefix: "--h5"
      position: 3

  - id: imsize
    type: int
    doc: Image size in pixels (larger than image fov to help wsclean 1.2" imaging at boundaries).
    default: 25000
    inputBinding:
      prefix: "--imsize"
      position: 4

  - id: pixelscale
    type: float
    doc: Pixel scale in arcseconds per pixel.
    default: 0.4
    inputBinding:
      prefix: "--pixelscale"
      position: 5

  - id: regionfile
    type: string
    doc: Name of the output DS9 region file.
    default: "facets.reg"
    inputBinding:
      prefix: "--DS9regionout"
      position: 6

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
