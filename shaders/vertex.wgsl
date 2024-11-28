struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) colors: vec4<f32>,
}

struct UniformInput {
    scale: vec2<f32>,
}

@binding(0) @group(0) var<uniform> UBO: UniformInput;

@vertex
fn main(@location(0) positions: vec2<f32>, 
        @location(1) colors: vec4<f32>) -> VertexOutput {
    var output: VertexOutput;
    output.position = vec4<f32>((2.0*positions.x/UBO.scale.x)-1.0, (2.0*positions.y/UBO.scale.y)-1.0, 0.0, 1.0);
    output.colors = colors;
    return output;
}
