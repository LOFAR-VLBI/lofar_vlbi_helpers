cwlVersion: v1.2
class: CommandLineTool
id: facet_selfcal_dutch
label: Facetselfcal Dutch full field-of-view
doc: |
       Performs direction dependent calibration of the Dutch antenna
       array with facetselfcal in DDE-mode on full field-of-view.

baseCommand:
    - python3

inputs:
    - id: msin
      type: Directory
      doc: Input MeasurementSet data with full field-of-view coverage at 6".
      inputBinding:
        position: 6

    - id: skymodel
      type: File?
      doc: The skymodel to be used in the first cycle in the self-calibration.
      inputBinding:
        prefix: "--skymodel"
        position: 2
        itemSeparator: " "
        separate: true

    - id: configfile
      type: File
      doc: A plain-text file containing configuration options for self-calibration.
      inputBinding:
        prefix: "--configpath"
        position: 3
        itemSeparator: " "
        separate: true

    - id: ncpu
      type: int?
      doc: Number of cores to use during facetselfcal.
      default: 24

    - id: dde_directions
      type: File?
      doc: A text file with directions for DDE calibration with facetselfcal
      inputBinding:
        prefix: "--facetdirection"
        position: 4
        itemSeparator: " "
        separate: true

    - id: facetselfcal
      type: Directory
      doc: External self-calibration script.

outputs:
    - id: h5parm
      type: File
      outputBinding:
        glob: merged*003*.h5
      doc: The merged calibration solution files generated in HDF5 format.

    - id: images
      type: File[]
      outputBinding:
        glob: ['*.png', plotlosoto*/*.png]
      doc: Selfcal PNG images.

    - id: fits_images
      type: File[]
      outputBinding:
        glob: '*MFS-image.fits'
      doc: Selfcal FITS images

    - id: logfile
      type: File[]
      outputBinding:
         glob: [facet_selfcal*.log, selfcal.log]
      doc: |
        The files containing the stdout
        and stderr from the step.

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(inputs.msin)
      - entry: $(inputs.configfile)
      - entry: $(inputs.dde_directions)

arguments:
  - $( inputs.facetselfcal.path + '/facetselfcal.py' )

hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl
  - class: ResourceRequirement
    coresMin: $(inputs.ncpu)

stdout: facet_selfcal.log
stderr: facet_selfcal_err.log
