struct VertexOutput {
    @builtin(position) position: vec4f,
    @location(0) colors: vec4f,
}

struct UniformInput {
    scale: vec2f,
}

@binding(0) @group(0) var<uniform> UBO: UniformInput;

@vertex 
fn main(@location(0) positions: vec2f, 
        @location(1) colors: vec4f) -> VertexOutput {
    var position = positions* UBO.scale;

    var output: VertexOutput;
    output.position = vec4f(position.x, position.y, 0.0, 1.0);
    output.colors = colors;
    return output;
}
