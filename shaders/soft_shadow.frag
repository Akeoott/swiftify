#version 440
// a rounded rectangle's soft shadow, as qt quick effects' RectangularShadow
// draws it: solid over a core a little inside the rectangle, then fading as
// the square of a smoothstep out from the core's edge.

layout(location = 0) in vec2 vFromCentre;
layout(location = 1) flat in vec4 vBox;
layout(location = 2) flat in vec4 vColor;

layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
};

void main()
{
    float radius = vBox.z;
    float outside = length(max(abs(vFromCentre) - vBox.xy + vec2(radius), vec2(0.0))) - radius;
    float a = 1.0 - smoothstep(0.0, max(vBox.w, 0.0001), outside);
    fragColor = vColor * (qt_Opacity * a * a);
}
