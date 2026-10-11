#version 440
// an icon's coverage, read from the plane of the symbol atlas it was filled
// into (MaterialSymbolItem): four planes share each texel, one a channel

layout(location = 0) in vec2 vAtlasPoint;
layout(location = 1) flat in vec4 vPlane;
layout(location = 2) flat in vec4 vColor;

layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 modelView;
    mat4 projection;
    float opacity;
    float dpr;
};

layout(binding = 1) uniform sampler2D atlas;

void main()
{
    fragColor = vColor * (dot(texture(atlas, vAtlasPoint), vPlane) * opacity);
}
