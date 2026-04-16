#version 460
#extension GL_NV_ray_tracing : require

layout(location = 0) rayPayloadInNV vec3 hitColor;

void main() {
    // The ray didn't hit anything → sky color
    hitColor = vec3(0.2, 0.5, 0.8);
}
