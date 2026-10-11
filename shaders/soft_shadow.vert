#version 440
// a soft shadow's quad (SoftShadowItem). what tells one shadow from another
// rides in the vertices, so the scene graph can draw many at once.

layout(location = 0) in vec4 position;
// from the rectangle's centre
layout(location = 1) in vec2 fromCentre;
// the solid core's half width and height, its corner radius, and how far
// past it the shadow fades
layout(location = 2) in vec4 box;
// premultiplied
layout(location = 3) in vec4 color;

layout(location = 0) out vec2 vFromCentre;
layout(location = 1) flat out vec4 vBox;
layout(location = 2) flat out vec4 vColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
};

void main()
{
    vFromCentre = fromCentre;
    vBox = box;
    vColor = color;
    gl_Position = qt_Matrix * position;
}
