# DESCRIPTION - GL_NV_ray_tracing OpenGL Extension

**Extension Name**: GL_NV_ray_tracing
**Vendor**: NVIDIA Corporation
**Category**: OpenGL Extension (Proprietary)
**Release Year**: 2018
**Current Status**: DEPRECATED → Replaced by GL_EXT_ray_tracing
**Official Link**: <https://registry.khronos.org/OpenGL/extensions/NV/NV_ray_tracing.txt>

## WHAT IS GL_NV_ray_tracing?

GL_NV_ray_tracing is an exclusive NVIDIA OpenGL extension, first introduced alongside the launch of the NVIDIA RTX 20-series (Turing) GPUs in 2018. This extension brings hardware-accelerated ray tracing capabilities into the OpenGL pipeline—a technology that was previously only achievable via software (which is slow) or through new APIs like DirectX 12 Ultimate (DXR).

Simply put: this extension allows OpenGL programs to shoot "virtual light rays" directly using the hardware RT Cores on NVIDIA GPUs, producing vastly more realistic lighting, shadows, and reflections compared to traditional rasterization.

## SUPPORTED HARDWARE & SOFTWARE

**Supported GPUs:**
* ✅ NVIDIA RTX 20-series (Turing) — RTX 2060, 2070, 2080, etc.
* ✅ NVIDIA RTX 30-series (Ampere) — RTX 3060, 3070, 3080, etc.
* ✅ NVIDIA RTX 40-series (Ada) — RTX 4060, 4070, 4080, 4090, etc.
* ✅ NVIDIA Quadro RTX
* ❌ GTX series (Pascal/Turing without RT Cores) — NOT supported.
* ❌ AMD GPUs — NOT supported (use EXT).
* ❌ Intel GPUs — NOT supported (use EXT).

**Minimum Driver:**
NVIDIA Driver version 415.xx or newer.

**API:**
OpenGL 4.6 + this extension.

## NEW SHADER STAGES

This extension introduces 5 new shader stages that aren't present in standard OpenGL:

1. **Ray Generation Shader (.rgen)**
   → The starting point of ray tracing. This is where rays are initially spawned and cast into the scene.

2. **Closest Hit Shader (.rchit)**
   → Invoked when a ray intersects the surface CLOSEST to the ray's origin. Used for computing color, lighting, materials, etc.

3. **Any Hit Shader (.rahit)**
   → Invoked for EVERY intersection point, not just the closest one. Useful for alpha transparency and shadow rays.

4. **Miss Shader (.rmiss)**
   → Invoked when the ray hits NOTHING. Typically used for sky color or environment mapping.

5. **Intersection Shader (.rint)**
   → Used for non-triangle geometry (custom primitives like spheres, curves, voxels, etc.).

## MAIN FUNCTION IN GLSL

```glsl
traceNV(
    accelerationStructureNV topLevel,  // BVH acceleration structure
    uint rayFlags,                     // flags (OPAQUE, SKIP, etc.)
    uint cullMask,                     // mask for specific instances
    uint sbtRecordOffset,              // shader binding table offset
    uint sbtRecordStride,
    uint missIndex,
    vec3 origin,                       // ray origin
    float tMin,                        // minimum distance
    vec3 direction,                    // ray direction
    float tMax,                        // maximum distance
    int payload                        // payload index (output data)
);
```

## ACCELERATION STRUCTURE

For hardware ray tracing, geometry must be organized into a two-level BVH (Bounding Volume Hierarchy) acceleration structure:

**BLAS (Bottom-Level Acceleration Structure)**
* Stores raw geometry (vertices, triangles).
* Created per mesh/object.

**TLAS (Top-Level Acceleration Structure)**
* Stores instances of the BLAS.
* Can apply transformations, masks, and SBT offsets per instance.
* This is what is passed to `traceNV()`.

## DIFFERENCES FROM PREVIOUS/LATER VERSIONS

| Feature | GL_NV_ray_tracing | GL_EXT_ray_tracing |
|---------|-------------------|--------------------|
| Vendor | NVIDIA only | Multi-vendor |
| Trace Function | `traceNV()` | `traceRayEXT()` |
| Status | Deprecated | Active / Recommended |
| Vulkan Equivalent | `VK_NV_ray_tracing` | `VK_KHR_ray_tracing` |
| AMD Support | ❌ | ✅ |
| Intel Support | ❌ | ✅ |
