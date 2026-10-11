#version 440
// an antialiased arc with round caps, for the circular progress indicator.
// angles are in turns, clockwise from the top.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    float thickness;
    float startTurn;
    float sweepTurn;
    vec4 color;
    vec4 trackColor;
};

const float TAU = 6.28318530718;

float arcDistance(vec2 point, float radius, float start, float sweep)
{
    float angle = atan(point.x, -point.y) / TAU;
    angle = fract(angle - start);
    if (angle <= sweep) {
        return abs(length(point) - radius);
    }
    // nearest cap
    vec2 capStart = radius * vec2(sin(start * TAU), -cos(start * TAU));
    vec2 capEnd = radius * vec2(sin((start + sweep) * TAU), -cos((start + sweep) * TAU));
    return min(length(point - capStart), length(point - capEnd));
}

void main()
{
    vec2 point = (qt_TexCoord0 - 0.5) * itemSize;
    float radius = 0.5 * min(itemSize.x, itemSize.y) - 0.5 * thickness - 0.5;
    float track = clamp(0.5 * thickness + 0.5 - abs(length(point) - radius), 0.0, 1.0);
    float arc = clamp(0.5 * thickness + 0.5 - arcDistance(point, radius, startTurn, max(sweepTurn, 0.0001)), 0.0, 1.0);
    vec4 result = trackColor * track * (1.0 - arc) + color * arc;
    fragColor = result * qt_Opacity;
}
