#version 440
// a scrolling column that fades out at its top and bottom edges, as the
// immersive lyrics and queue do, over whatever is behind them.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    // how far in from each edge the fade reaches, as a fraction of the height
    float edge;
};

layout(binding = 1) uniform sampler2D source;

void main()
{
    float y = qt_TexCoord0.y;
    float fade = clamp(y / edge, 0.0, 1.0) * clamp((1.0 - y) / edge, 0.0, 1.0);
    fragColor = texture(source, qt_TexCoord0) * (fade * qt_Opacity);
}
