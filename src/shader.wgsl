struct VertexOut {
    @builtin(position) position_clip: vec4<f32>,
    @location(0) color: vec3<f32>,
}

@vertex fn vertex_main(@location(0) position: vec3<f32>, @location(1) color: vec3<f32>) -> VertexOut {
    var output: VertexOut;
    output.position_clip = vec4(position, 1.0);
    output.color = color;
    return output;
}

@fragment fn fragment_main(@location(0) color: vec3<f32>) -> @location(0) vec4<f32> {
    return vec4(color, 1.0);
}