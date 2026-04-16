# TECHNICAL EXPLANATION - GL_NV_ray_tracing

This document explains the underlying mechanics, activation steps, and GLSL code examples using GL_NV_ray_tracing for shader developers and OpenGL applications.

## PART 1 — HOW HARDWARE RAY TRACING WORKS

Unlike rasterization (the traditional OpenGL rendering method), ray tracing physically simulates the behavior of light:

**RASTERIZATION (Traditional):**
3D Objects → Projection → Fragment Shader → Screen
Fast, but the lighting is not physically accurate.

**RAY TRACING (Hardware):**
For every pixel → Cast a ray → Check for intersections against the scene
→ Calculate color based on material + lighting + reflections.
Slower, but yields highly realistic lighting.

**GL_NV_ray_tracing hardware pipeline:**
1. CPU uploads geometry to VRAM.
2. GPU builds a BVH (acceleration structure).
3. Ray Generation Shader spawns rays per pixel.
4. RT Core hardware traverses the BVH extremely fast.
5. Hit/Miss shaders are invoked based on the intersection results.
6. Results are written to an image/buffer.
7. Composited into the final framebuffer.

## PART 2 — ENABLING THE EXTENSION

**In C++ (using OpenGL):**

```cpp
// 1. Check if the extension is available
if (!GLEW_NV_ray_tracing) {
    printf("GL_NV_ray_tracing is not supported!\n");
    return;
}

// 2. The extension is automatically active if hardware supports it.
//    No special glEnable() call is required.
```

**In the GLSL Shader:**

```glsl
// Must be written at the very top of the shader file
#extension GL_NV_ray_tracing : require
// or if optional:
#extension GL_NV_ray_tracing : enable
```

## PART 3 — GLSL CODE EXAMPLES

### Ray Generation Shader (main.rgen)

```glsl
#version 460
#extension GL_NV_ray_tracing : require

layout(binding = 0, set = 0) uniform accelerationStructureNV topLevelAS;
layout(binding = 1, set = 0, rgba8) uniform image2D outputImage;

layout(location = 0) rayPayloadNV vec3 hitColor;

void main() {
    // Current pixel coordinates
    ivec2 pixelCoord = ivec2(gl_LaunchIDNV.xy);
    ivec2 imageSize  = ivec2(gl_LaunchSizeNV.xy);

    // Calculate ray direction from the camera
    vec2 uv = (vec2(pixelCoord) + 0.5) / vec2(imageSize);
    vec3 rayOrigin    = vec3(0.0, 0.0, -2.0);
    vec3 rayDirection = normalize(vec3(uv * 2.0 - 1.0, 1.0));

    // Shoot the ray!
    traceNV(
        topLevelAS,          // acceleration structure
        gl_RayFlagsOpaqueNV, // flags
        0xFF,                // cull mask (all instances)
        0, 1, 0,             // sbt offsets
        rayOrigin,           // ray origin
        0.001,               // tMin
        rayDirection,        // ray direction
        1000.0,              // tMax
        0                    // payload location
    );

    // Write the resulting color to the output image
    imageStore(outputImage, pixelCoord, vec4(hitColor, 1.0));
}
```

### Closest Hit Shader (main.rchit)

```glsl
#version 460
#extension GL_NV_ray_tracing : require

layout(location = 0) rayPayloadInNV vec3 hitColor;

hitAttributeNV vec3 attribs;

void main() {
    // Barycentric coordinates of the hit point
    vec3 bary = vec3(
        1.0 - attribs.x - attribs.y,
        attribs.x,
        attribs.y
    );
    // Color based on barycentric position (visual debugging)
    hitColor = bary;
}
```

### Miss Shader (main.rmiss)

```glsl
#version 460
#extension GL_NV_ray_tracing : require

layout(location = 0) rayPayloadInNV vec3 hitColor;

void main() {
    // The ray didn't hit anything → sky color
    hitColor = vec3(0.2, 0.5, 0.8);
}
```

## PART 4 — BUILDING THE ACCELERATION STRUCTURE (C++)

```cpp
// === BLAS (Bottom-Level) ===
VkAccelerationStructureCreateInfoNV blasInfo = {};
blasInfo.sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_CREATE_INFO_NV;
blasInfo.info.type = VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_NV;
blasInfo.info.geometryCount = 1;
blasInfo.info.pGeometries   = &geometry;  // triangle geometry

vkCreateAccelerationStructureNV(device, &blasInfo, nullptr, &blas);

// === TLAS (Top-Level) ===
VkAccelerationStructureCreateInfoNV tlasInfo = {};
tlasInfo.sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_CREATE_INFO_NV;
tlasInfo.info.type = VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_NV;
tlasInfo.info.instanceCount = 1;

vkCreateAccelerationStructureNV(device, &tlasInfo, nullptr, &tlas);

// Note: The example above uses Vulkan because pure OpenGL 
// does not directly expose acceleration structure building APIs.
// For OpenGL, use GLEW + helper extensions or Vulkan-OpenGL interop.
```

## PART 5 — AVAILABLE RAY FLAGS

* `gl_RayFlagsNoneNV` — No flags.
* `gl_RayFlagsOpaqueNV` — Treat all geometry as opaque.
* `gl_RayFlagsNoOpaqueNV` — Treat all geometry as non-opaque.
* `gl_RayFlagsTerminateOnFirstHitNV` — Stop at the first hit (useful for shadow rays).
* `gl_RayFlagsSkipClosestHitShaderNV` — Skip the closest hit shader.
* `gl_RayFlagsCullBackFacingTrianglesNV` — Cull back faces.
* `gl_RayFlagsCullFrontFacingTrianglesNV` — Cull front faces.

Example usage for a shadow ray:

```glsl
traceNV(tlas,
    gl_RayFlagsOpaqueNV | gl_RayFlagsTerminateOnFirstHitNV,
    0xFF, 0, 1, 0, origin, 0.001, lightDir, lightDist, 0);
```

## PART 6 — RELATIONSHIP TO INBADIUM PRT (MINECRAFT SHADER)

The Inbadium PRT v2.0.4 shader pack utilizes SOFTWARE ray tracing, not hardware GL_NV_ray_tracing. Its implementation relies on:

* Octree structures (`octree.glsl`) for manual BVH traversal on the GPU.
* `rtfunc.glsl` as the core ray intersection function.
* All calculations are done using standard compute/fragment shaders.

**Advantages of the software approach:**
* ✅ Compatible with all GPUs (AMD, Intel, older NVIDIA models).
* ✅ Runs in Minecraft via OptiFine/Iris without specialized APIs.
* ✅ Does not require RTX hardware.

**Disadvantages vs hardware GL_NV_ray_tracing:**
* ❌ Much slower than hardware RT Cores.
* ❌ Number of light bounces is severely limited.
* ❌ Denoising quality is restricted.

If you were to integrate `GL_NV_ray_tracing`:
→ It would require a total rewrite of the tracing system.
→ Octree traversal would need to be replaced with TLAS/BLAS.
→ Introduction of `.rgen`, `.rchit`, `.rmiss` shader stages.
→ Would only run on NVIDIA RTX GPUs.

## PART 7 — REFERENCES & LINKS

**Official Specification:**
<https://registry.khronos.org/OpenGL/extensions/NV/NV_ray_tracing.txt>

**Vulkan Version (Recommended for new projects):**
<https://registry.khronos.org/vulkan/specs/latest/man/html/VK_KHR_ray_tracing_pipeline.html>

**EXT Version (Multi-vendor, NV replacement):**
<https://registry.khronos.org/OpenGL/extensions/EXT/EXT_ray_tracing.txt>

**NVIDIA Developer Blog — Ray Tracing in OpenGL:**
<https://developer.nvidia.com/blog/introduction-nvidia-rtx-directx-ray-tracing/>

**GLSL Extension Specification:**
<https://github.com/KhronosGroup/GLSL/blob/master/extensions/nv/GLSL_NV_ray_tracing.txt>

---
*Created for developer reference. GL_NV_ray_tracing © NVIDIA Corporation 2018*
