@fragment 
fn main(@location(0) fragColor: vec3<f32>) -> @location(0) vec4<f32> {
    return vec4<f32>(fragColor.x, fragColor.y, fragColor.z, 1.0);
}
