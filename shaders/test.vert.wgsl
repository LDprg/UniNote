struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) colors: vec4<f32>,
}

const positions = array<vec2<f32>, 3>(
    vec2<f32>( 0.0, -0.5), 
    vec2<f32>( 0.5,  0.5), 
    vec2<f32>(-0.5,  0.5)
);
const colors = array<vec4<f32>, 3>(
    vec4<f32>(1.0, 0.0, 0.0, 1.0), 
    vec4<f32>(0.0, 1.0, 0.0, 1.0), 
    vec4<f32>(0.0, 0.0, 1.0, 1.0)
);

@vertex 
fn main(@builtin(vertex_index) vertex_index: u32) -> VertexOutput {
    var output: VertexOutput;
    output.position = vec4<f32>(positions[vertex_index].x, positions[vertex_index].y, 0.0, 1.0);
    output.colors = colors[vertex_index];
    return output;
}
