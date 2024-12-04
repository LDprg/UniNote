struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) colors: vec4<f32>,
}

struct UniformInput {
    model: mat4x4<f32>,
    view: mat4x4<f32>,
}

@binding(0) @group(0) var<uniform> UBO: UniformInput;

@vertex
fn main(@location(0) positions: vec2<f32>,
        @location(1) colors: vec4<f32>) -> VertexOutput {
    var output: VertexOutput;
    output.position = UBO.view * UBO.model * vec4<f32>(positions, 0.0, 1.0);
    output.colors = colors;
    return output;
}
