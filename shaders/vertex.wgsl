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
        @location(10) model1: vec4<f32>,
        @location(11) model2: vec4<f32>,
        @location(12) model3: vec4<f32>,
        @location(13) model4: vec4<f32>,
        @location(15) colors: vec4<f32>
        ) -> VertexOutput {
    var model = mat4x4<f32>(model1, model2, model3, model4);

    var output: VertexOutput;
    output.position = UBO.view * model * positions;
    output.colors = colors;
    return output;
}
