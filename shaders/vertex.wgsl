struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) colors: vec4<f32>,
}

struct UniformInput {
    view: mat4x4<f32>,
}

@binding(0) @group(0) var<uniform> UBO: UniformInput;

@vertex
fn main(@location(0) positions: vec4<f32>,
        @location(1) colors: vec4<f32>
        ) -> VertexOutput {
    var output: VertexOutput;
    output.position = UBO.view * positions;
    output.colors = colors;
    return output;
}
