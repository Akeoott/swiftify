#version 440
// one quad per bar, built on the cpu around its foot and direction, with room
// at every side for the glow to fade out.

layout(location = 0) in vec4 position;
layout(location = 1) in vec2 local;
layout(location = 2) in vec4 color;
layout(location = 3) in vec4 shape;

layout(location = 0) out vec2 vLocal;
layout(location = 1) flat out vec4 vColor;
layout(location = 2) flat out vec4 vShape;
// where in the item, for the cut along a round cover's squiggle
layout(location = 3) out vec2 vItem;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float pixelsPerPoint;
    float glowSigma;
    float glowOpacity;
    vec4 cut;
    vec4 wave;
};

void main()
{
    vLocal = local;
    vItem = position.xy;
    vColor = color;
    vShape = shape;
    gl_Position = qt_Matrix * position;
}
