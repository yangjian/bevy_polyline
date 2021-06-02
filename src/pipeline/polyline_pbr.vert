#version 450

layout(location = 0) in vec3 I_Point0;
layout(location = 1) in vec3 I_Point1;

layout(location = 0) out vec3 v_WorldPosition;
layout(location = 1) out vec3 v_WorldNormal;
layout(location = 2) out vec2 v_Uv;

layout(set = 0, binding = 0) uniform CameraViewProj {
    mat4 ViewProj;
};

#ifdef STANDARDMATERIAL_NORMAL_MAP
layout(location = 3) out vec4 v_WorldTangent;
#endif

layout(set = 2, binding = 0) uniform Transform {
    mat4 Model;
};

layout(set = 1, binding = 1) uniform GlobalResources_resolution {
    vec2 resolution;
};

layout(set = 3, binding = 15) uniform PolylinePbrMaterial_width {
    float width;
};

void main() {
    vec3[] positions = {
        { 0.0, -0.5, 0.0 },
        { 0.0, -0.5, 1.0 },
        { 0.0, 0.5, 1.0 },
        { 0.0, -0.5, 0.0 },
        { 0.0, 0.5, 1.0 },
        { 0.0, 0.5, 0.0 }
    };

    vec3 position = positions[gl_VertexIndex];

    // algorithm based on https://wwwtyro.net/2019/11/18/instanced-lines.html
    vec4 clip0 = ViewProj * Model * vec4(I_Point0, 1);
    vec4 clip1 = ViewProj * Model * vec4(I_Point1, 1);
    vec4 clip = mix(clip0, clip1, position.z);

    vec2 screen0 = resolution * (0.5 * clip0.xy / clip0.w + 0.5);
    vec2 screen1 = resolution * (0.5 * clip1.xy / clip1.w + 0.5);

    vec2 xBasis = normalize(screen1 - screen0);
    vec2 yBasis = vec2(-xBasis.y, xBasis.x);

#ifdef POLYLINEMATERIAL_PERSPECTIVE
    float width = width / clip.w;
    // Line thinness fade from https://acegikmo.com/shapes/docs/#anti-aliasing
    if (width < 1.0) {
        width = 1.0;
    }
#endif

    vec2 pt0 = screen0 + width * (position.x * xBasis + position.y * yBasis);
    vec2 pt1 = screen1 + width * (position.x * xBasis + position.y * yBasis);
    vec2 pt = mix(pt0, pt1, position.z);

    gl_Position = vec4(clip.w * ((2.0 * pt) / resolution - 1.0), clip.z, clip.w);
    // Vertex_Color = color;
    v_WorldPosition = (inverse(ViewProj) * gl_Position).xyz;
    float normal_y = sqrt(1 - v_Uv.x);
    v_WorldNormal = mat3(Model) * vec3(position.y, normal_y, 0.0);
    v_Uv = vec2(position.y + 0.5, position.z);
}