const zgpu = @import("zgpu");
const wgpu = zgpu.wgpu;

pub fn alignSize(size: usize) usize {
    const alignment: usize = 16;
    return (size + alignment - 1) & ~(alignment - 1);
}

pub fn getShaderModule(device: wgpu.Device, source: [*:0]const u8) wgpu.ShaderModule {
    const wgsl_descriptor = wgpu.ShaderModuleWGSLDescriptor{
        .chain = .{ .next = null, .struct_type = .shader_module_wgsl_descriptor },
        .code = source,
    };
    const shader_descriptor = wgpu.ShaderModuleDescriptor{
        .next_in_chain = @ptrCast(&wgsl_descriptor),
    };
    return device.createShaderModule(shader_descriptor);
}
