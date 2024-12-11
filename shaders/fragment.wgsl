struct UniformInput {
    model: mat4x4<f32>,
    view: mat4x4<f32>,
}

@binding(0) @group(0) var<uniform> UBO: UniformInput;

@fragment
fn main(@builtin(position) position: vec4<f32>, @location(0) color: vec4<f32>) -> @location(0) vec4<f32> {
    // return vec4<f32>(color.r, color.g, color.b, color.a);
    var pos = vec2<f32>(position.x * UBO.view[0][0], position.y * UBO.view[1][1]) - vec2<f32>(1);
    var col = smoothstep(0.0, 0.0025, 1-length(pos));
    return vec4<f32>(color.rgb, col * color.a);
}
