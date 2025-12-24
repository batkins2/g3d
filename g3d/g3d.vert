// written by groverbuger for g3d
// september 2021
// MIT license

// Optimized vertex shader for g3d

// layout (std430, binding = 0) readonly buffer JointMatrixBlock {
//     mat4 jointMatrix[];
// };
 
uniform mat4 projectionMatrix;
uniform bool isCanvasEnabled;

uniform vec3 lightDirection;
uniform vec3 lightColor;
uniform vec3 ambientColor;
uniform float lightIntensity;
uniform mat4 lightSpaceMatrix;
uniform mat4 viewMatrix;

layout (push_constant) uniform constants {
    vec4 jointInfo; // x = jointCount, y = jointOffset    
};

attribute vec3 VertexNormal;
attribute vec4 VertexWeight;
attribute vec4 VertexJoint;

varying vec4 worldPosition;
varying vec4 viewPosition;
varying vec4 screenPosition;
varying vec3 vertexNormal;
varying vec4 vertexColor;
varying vec3 lighting;
varying vec4 fragPosLightSpace;
varying vec2 vTexCoord;

uniform mat4 modelMatrix[100];
uniform mat4 jointMatrix[10000];

// layout(set = 0, binding = 4) readonly buffer OutputBuffer {
//     mat4 jointMatrix[];
// };

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    // float totalWeight = VertexWeight[0] + VertexWeight[1] + VertexWeight[2] + VertexWeight[3];
    
    // if (totalWeight <= 0.0 || jointInfo.x == 0) {
    if (jointInfo.x == 0) {
        // Fast path: no skinning
        int i = int(jointInfo[2]);
        vec4 transformedPosition = modelMatrix[i] * vec4(vertexPosition.xyz, 1.0);
        vec3 transformedNormal = normalize(mat3(modelMatrix[i]) * VertexNormal);

        // --- Outputs for fragment shader ---
        worldPosition = transformedPosition;
        viewPosition = viewMatrix * worldPosition;
        screenPosition = projectionMatrix * viewPosition;
        vertexNormal = transformedNormal;
        vertexColor = VertexColor;

        // --- Lighting ---
        vec3 norm = normalize(transformedNormal);
        vec3 lightDir = normalize(lightDirection);
        float diff = max(dot(norm, lightDir), 0.0);
        lighting = diff * lightColor * lightIntensity + ambientColor;

        // --- Shadow mapping ---
        fragPosLightSpace = lightSpaceMatrix * transformedPosition;

        // --- Canvas Y-flip ---
        #ifdef GL_ES
        if (isCanvasEnabled) {
            screenPosition.y = -screenPosition.y;
        }
        #endif

        // --- Texture coordinates (screen-space mapping for effects) ---
        vTexCoord = screenPosition.xy / screenPosition.w * 0.5 + 0.5;

        return screenPosition;
    } else {
        // Skinning path: use only top 2-3 weights for speed
        vec4 skinnedPosition = vec4(0.0);
        vec3 skinnedNormal = vec3(0.0);

        float w0 = VertexWeight[0];
        float w1 = VertexWeight[1];
        float w2 = VertexWeight[2];
        float w3 = VertexWeight[3];
        // If no weights, use original position/normal
        if (w0 + w1 + w2 + w3 == 0.0 || jointInfo.x == 0) {
            skinnedPosition = vec4(vertexPosition.xyz, 1.0);
            skinnedNormal = VertexNormal;
        } else {

            // Unroll loop for up to 4 weights, skip zero weights
            
            if (w0 > 0.0) {
                int j0 = int(VertexJoint[0]) + int(jointInfo.y);
                mat4 jm0 = jointMatrix[j0];
                skinnedPosition += w0 * (jm0 * vec4(vertexPosition.xyz, 1.0));
                skinnedNormal   += w0 * (mat3(jm0) * VertexNormal);
            }
            if (w1 > 0.0) {
                int j1 = int(VertexJoint[1]) + int(jointInfo.y);
                mat4 jm1 = jointMatrix[j1];
                skinnedPosition += w1 * (jm1 * vec4(vertexPosition.xyz, 1.0));
                skinnedNormal   += w1 * (mat3(jm1) * VertexNormal);
            }
            if (w2 > 0.0) {
                int j2 = int(VertexJoint[2]) + int(jointInfo.y);
                mat4 jm2 = jointMatrix[j2];
                skinnedPosition += w2 * (jm2 * vec4(vertexPosition.xyz, 1.0));
                skinnedNormal   += w2 * (mat3(jm2) * VertexNormal);
            }
            if (w3 > 0.0) {
                int j3 = int(VertexJoint[3]) + int(jointInfo.y);
                mat4 jm3 = jointMatrix[j3];
                skinnedPosition += w3 * (jm3 * vec4(vertexPosition.xyz, 1.0));
                skinnedNormal   += w3 * (mat3(jm3) * VertexNormal);
            }
        }

        // --- Transformations ---
        vec4 transformedPosition = modelMatrix[int(jointInfo.z)] * skinnedPosition;
        vec3 transformedNormal = normalize(mat3(modelMatrix[int(jointInfo.z)]) * skinnedNormal);

        // --- Outputs for fragment shader ---
        worldPosition = transformedPosition;
        viewPosition = viewMatrix * worldPosition;
        screenPosition = projectionMatrix * viewPosition;
        vertexNormal = transformedNormal;
        vertexColor = VertexColor;

        // --- Lighting ---
        vec3 norm = normalize(transformedNormal);
        vec3 lightDir = normalize(lightDirection);
        float diff = max(dot(norm, lightDir), 0.0);
        lighting = diff * lightColor * lightIntensity + ambientColor;

        // --- Shadow mapping ---
        fragPosLightSpace = lightSpaceMatrix * transformedPosition;

        // --- Canvas Y-flip ---
        #ifdef GL_ES
        if (isCanvasEnabled) {
            screenPosition.y = -screenPosition.y;
        }
        #endif

        // --- Texture coordinates (screen-space mapping for effects) ---
        vTexCoord = screenPosition.xy / screenPosition.w * 0.5 + 0.5;

        return screenPosition;
    }
}