cwlVersion: v1.2
class: ExpressionTool
id: flatten_array
label: Flatten Array
doc: "Flatten a nested array of 'Any' type into an array. Taken from https://github.com/common-workflow-library/cwl-patterns/tree/main"
requirements:
  InlineJavascriptRequirement: {}
inputs:
  nestedarray:
    type:
      type: array
      items:
        type: array
        items: ["null", Any]
outputs:
  flattenedarray:
    type:
      type: array
      items: Any
expression: |
  ${
    var flattenedarray = [];
    for (var i = 0; i < inputs.nestedarray.length; i++) {
      for (var j = 0; j < inputs.nestedarray[i].length; j++) {
        if (inputs.nestedarray[i][j] != null) {
          flattenedarray.push(inputs.nestedarray[i][j]);
        }
      }
    }
    return {"flattenedarray": flattenedarray};
  }