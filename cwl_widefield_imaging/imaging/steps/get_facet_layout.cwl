class: CommandLineTool
cwlVersion: v1.2
id: get_facet_layout
label: DS9 Facet Generator
doc: This step generates DS9 facet layout using a specified HDF5 file and MS.

baseCommand: python

inputs:
  - id: msin
    type: Directory
    doc: The measurement set file.

  - id: h5parm
    type: File
    doc: The HDF5 file containing the facet information.

  - id: imsize
    type: int
    doc: Image size in pixels.
    default: 22500

  - id: pixelscale
    type: float
    doc: Pixel scale in arcseconds per pixel.
    default: 0.4

  - id: regionfile
    type: string
    doc: The name of the output DS9 region file.
    default: "facets.reg"

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


arguments:
  - valueFrom: ../scripts/make_facets.py
  - valueFrom: --h5 $(inputs.h5parm.path)
  - valueFrom: --DS9regionout $(inputs.regionfile)
  - valueFrom: --imsize $(inputs.imsize)
  - valueFrom: --ms $(inputs.msin.path)
  - valueFrom: --pixelscale $(inputs.pixelscale)

requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(inputs.h5parm)
      - entry: $(inputs.msin)
  - class: StepInputExpressionRequirement

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl
  - class: ResourceRequirement
    coresMin: 1

stdout: get_facet_layout.log
stderr: get_facet_layout_err.log
