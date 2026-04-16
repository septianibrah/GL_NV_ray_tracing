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
