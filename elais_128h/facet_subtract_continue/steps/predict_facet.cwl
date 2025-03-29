class: CommandLineTool
cwlVersion: v1.2
id: predict_facet
label: Predict with WSClean
doc: Uses WSClean to predict sources within a facet and adds the predicted visibilities to the input data.


baseCommand: python3

inputs:
  - id: subtracted_ms
    type: Directory
    doc: Input data in MeasurementSet format.
    inputBinding:
      prefix: "--mslist"
      position: 1

  - id: model_image_folder
    type: Directory
    doc: Folder containing 1.2" model images.
    inputBinding:
      prefix: "--model_image_folder"
      position: 2

  - id: polygon_region
    type: File
    doc: DS9 region file with facets for prediction.
    inputBinding:
      prefix: "--region"
      position: 3

  - id: h5parm
    type: File
    doc: HDF5 file containing the solutions for prediction.
    inputBinding:
      prefix: "--h5parm_predict"
      position: 4

  - id: lofar_helpers
    type: Directory
    doc: LOFAR helpers directory.

  - id: polygon_info
    type: File
    doc: CSV file with polygon information (RA/DEC of calibrator and facet centers and averaging factor)

  - id: copy_to_local_scratch
    type: boolean?
    default: false
    inputBinding:
      prefix: "--copy_to_local_scratch"
      position: 5
      separate: false
    doc: Whether you want the subtract step to copy data to local scratch space from your running node.

  - id: ncpu
    type: int?
    doc: Number of cores to use during the subtract.
    default: 16

outputs:
  - id: logfile
    type: File[]
    doc: Log files from current step.
    outputBinding:
      glob: predict_facet*.log
  - id: facet_ms
    type: Directory
    doc: MeasurementSet after predicting back facet model visibilities
    outputBinding:
      glob: facet*.ms


arguments:
  - $( inputs.lofar_helpers.path + '/subtract/subtract_with_wsclean.py' )
  - --applybeam
  - --applycal
  - --forwidefield
  - --inverse
  - --speedup_facet_subtract
  - --cleanup_input_ms

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing: >
      ${
        // Set 'writable' on the "subtracted_ms" entry only if copy_to_local_scratch is true.
        let stagedListing = [
          { entry: inputs.subtracted_ms },
          { entry: inputs.model_image_folder },
          { entry: inputs.polygon_region },
          { entry: inputs.h5parm },
          { entry: inputs.polygon_info }
        ];
        if (!inputs.copy_to_local_scratch) {
          stagedListing[0].writable = true;
        }
        return stagedListing;
      }


hints:
  - class: DockerRequirement
    dockerPull: vlbi-cwl
  - class: ResourceRequirement
    coresMin: $(inputs.ncpu)

stdout: predict_facet.log
stderr: predict_facet_err.log