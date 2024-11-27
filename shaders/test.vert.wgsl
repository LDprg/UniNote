struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) colors: vec4<f32>,
}

@vertex 
fn main(@location(0) positions: vec2<f32>, 
        @location(1) colors: vec4<f32>) -> VertexOutput {
    var output: VertexOutput;
    output.position = vec4<f32>(positions.x, positions.y, 0.0, 1.0);
    output.colors = colors;
    return output;
}
