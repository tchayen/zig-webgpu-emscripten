const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const zgpu = @import("zgpu");
const wgpu = zgpu.wgpu;
const zm = @import("zmath");
const utils = @import("utils.zig");
const alignSize = utils.alignSize;
const getShaderModule = utils.getShaderModule;

const shader_source = @embedFile("shader.wgsl");

const Vertex = struct {
    position: [3]f32,
    color: [3]f32,
};

const vertex_data = [_]Vertex{
    .{ .position = [3]f32{ 0.0, 0.5, 0.0 }, .color = [3]f32{ 1.0, 0.0, 0.0 } },
    .{ .position = [3]f32{ -0.5, -0.5, 0.0 }, .color = [3]f32{ 0.0, 1.0, 0.0 } },
    .{ .position = [3]f32{ 0.5, -0.5, 0.0 }, .color = [3]f32{ 0.0, 0.0, 1.0 } },
};

const index_data = [_]u32{ 0, 1, 2 };

pub const Renderer = struct {
    allocator: Allocator,
    gctx: *zgpu.GraphicsContext,
    pipeline_layout: wgpu.PipelineLayout,
    pipeline: wgpu.RenderPipeline,
    vertex_buffer: wgpu.Buffer,
    index_buffer: wgpu.Buffer,

    pub fn init(allocator: Allocator, gctx: *zgpu.GraphicsContext) !Renderer {
        const device = gctx.device;
        const queue = gctx.queue;

        const shader = getShaderModule(device, shader_source);
        defer shader.release();

        const geometry_buffers = [_]wgpu.VertexBufferLayout{
            .{
                .array_stride = 6 * @sizeOf(f32),
                .attributes = &[_]wgpu.VertexAttribute{
                    .{
                        .format = .float32x3,
                        .offset = 0,
                        .shader_location = 0,
                    },
                    .{
                        .format = .float32x3,
                        .offset = 3 * @sizeOf(f32),
                        .shader_location = 1,
                    },
                },
                .attribute_count = 2,
            },
        };

        const pipeline_layout = device.createPipelineLayout(.{
            .bind_group_layouts = &[_]wgpu.BindGroupLayout{},
            .bind_group_layout_count = 0,
        });

        const pipeline = wgpu.RenderPipelineDescriptor{
            .label = "simple pipeline",
            .layout = pipeline_layout,
            .vertex = .{
                .module = shader,
                .entry_point = "vertex_main",
                .buffers = &geometry_buffers,
                .buffer_count = geometry_buffers.len,
            },
            .fragment = &.{
                .module = shader,
                .entry_point = "fragment_main",
                .targets = &[_]wgpu.ColorTargetState{
                    .{ .format = zgpu.GraphicsContext.swapchain_format },
                },
                .target_count = 1,
            },
            .primitive = .{ .cull_mode = .back },
        };

        // Buffers

        const vertex_buffer = device.createBuffer(.{
            .size = alignSize(@sizeOf(Vertex) * vertex_data.len),
            .usage = .{
                .vertex = true,
                .copy_dst = true,
            },
        });
        queue.writeBuffer(vertex_buffer, 0, Vertex, &vertex_data);

        const index_buffer = device.createBuffer(.{
            .size = alignSize(@sizeOf(u32) * index_data.len),
            .usage = .{
                .index = true,
                .copy_dst = true,
            },
        });
        queue.writeBuffer(index_buffer, 0, u32, &index_data);

        return Renderer{
            .allocator = allocator,
            .gctx = gctx,
            .pipeline_layout = pipeline_layout,
            .pipeline = device.createRenderPipeline(pipeline),
            .vertex_buffer = vertex_buffer,
            .index_buffer = index_buffer,
        };
    }

    pub fn render(
        self: *Renderer,
        encoder: wgpu.CommandEncoder,
        framebuffer_view: wgpu.TextureView,
    ) !void {
        const pass = encoder.beginRenderPass(.{
            .color_attachments = &[_]wgpu.RenderPassColorAttachment{
                .{
                    .view = framebuffer_view,
                    .load_op = .clear,
                    .store_op = .store,
                    .clear_value = .{ .r = 0.05, .g = 0.5, .b = 0.8, .a = 1 },
                },
            },
            .color_attachment_count = 1,
        });

        pass.setPipeline(self.pipeline);
        pass.setVertexBuffer(0, self.vertex_buffer, 0, alignSize(@sizeOf(Vertex) * vertex_data.len));
        pass.setIndexBuffer(self.index_buffer, .uint32, 0, alignSize(@sizeOf(u32) * index_data.len));

        pass.drawIndexed(index_data.len, 1, 0, 0, 0);

        pass.end();
        pass.release();
    }

    pub fn deinit(self: *Renderer) void {
        self.index_buffer.release();
        self.vertex_buffer.release();
        self.pipeline_layout.release();
        self.pipeline.release();
    }
};
