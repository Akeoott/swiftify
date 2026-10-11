#version 440
// material 3 expressive's wavy line, the seek line's wave drawn the whole way
// across (wavy_progress.frag with nothing left to play): coverage by the
// distance to the sine, its ends round

layout(location = 0) in vec2 vLocal;
layout(location = 1) flat in vec4 vWave;
layout(location = 2) flat in vec4 vColor;
layout(location = 3) flat in float vThickness;

layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
};

const float TAU = 6.28318530718;

void main()
{
    float half_ = 0.5 * vThickness;
    float length_ = vWave.x;
    float amplitude = vWave.y;
    float wavelength = vWave.z;
    float x = clamp(vLocal.x, half_, length_);
    float angle = TAU * x / wavelength + vWave.w;
    float y = amplitude * sin(angle);
    float slope = amplitude * TAU / wavelength * cos(angle);
    vec2 offset = vec2(vLocal.x - x, (vLocal.y - y) / sqrt(1.0 + slope * slope));
    float coverage = length_ > half_ ? clamp(half_ + 0.5 - length(offset), 0.0, 1.0) : 0.0;
    fragColor = vColor * (coverage * qt_Opacity);
}
