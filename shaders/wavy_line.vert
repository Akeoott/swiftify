#version 440
// a wavy divider's quad (WavyLineItem). the wave's measures and colour ride
// in the vertices, so the scene graph draws many dividers at once.

layout(location = 0) in vec4 position;
// from the line's left end, across its middle, in pixels
layout(location = 1) in vec2 local;
// the line's length, the wave's amplitude, wavelength and phase
layout(location = 2) in vec4 wave;
// premultiplied
layout(location = 3) in vec4 color;
layout(location = 4) in float thickness;

layout(location = 0) out vec2 vLocal;
layout(location = 1) flat out vec4 vWave;
layout(location = 2) flat out vec4 vColor;
layout(location = 3) flat out float vThickness;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
};

void main()
{
    vLocal = local;
    vWave = wave;
    vColor = color;
    vThickness = thickness;
    gl_Position = qt_Matrix * position;
}
