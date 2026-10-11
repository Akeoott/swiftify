#version 440
// the halo or wave behind the bars: a vertex-coloured mesh, as qt's own
// vertex colour material draws it, with the item's own coordinates handed on
// for the cut along a round cover's squiggle.

layout(location = 0) in vec4 position;
layout(location = 1) in vec4 color;

layout(location = 0) out vec4 vColor;
layout(location = 1) out vec2 vItem;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 cut;
    vec4 wave;
};

void main()
{
    vColor = color;
    vItem = position.xy;
    gl_Position = qt_Matrix * position;
}
