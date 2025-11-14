// written by groverbuger for g3d
// september 2021
// MIT license

// Optimized vertex shader for g3d

uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelMatrix;
uniform bool isCanvasEnabled;

uniform vec3 lightDirection;
uniform vec3 lightColor;
uniform vec3 ambientColor;
uniform float lightIntensity;
uniform mat4 lightSpaceMatrix;

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

layout (std430, binding = 0) readonly buffer JointMatrixBuffer {
    mat4 jointMatrix[];
};

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    float totalWeight = VertexWeight[0] + VertexWeight[1] + VertexWeight[2] + VertexWeight[3];
    
    if (totalWeight <= 0.0) {
        // Fast path: no skinning
        vec4 transformedPosition = modelMatrix * vec4(vertexPosition.xyz, 1.0);
        vec3 transformedNormal = normalize(mat3(modelMatrix) * VertexNormal);

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

        // Unroll loop for up to 4 weights, skip zero weights
        float w0 = VertexWeight[0];
        if (w0 > 0.0) {
            int j0 = int(VertexJoint[0]);
            mat4 jm0 = jointMatrix[j0];
            skinnedPosition += w0 * (jm0 * vec4(vertexPosition.xyz, 1.0));
            skinnedNormal   += w0 * (mat3(jm0) * VertexNormal);
        }
        float w1 = VertexWeight[1];
        if (w1 > 0.0) {
            int j1 = int(VertexJoint[1]);
            mat4 jm1 = jointMatrix[j1];
            skinnedPosition += w1 * (jm1 * vec4(vertexPosition.xyz, 1.0));
            skinnedNormal   += w1 * (mat3(jm1) * VertexNormal);
        }
        float w2 = VertexWeight[2];
        if (w2 > 0.0) {
            int j2 = int(VertexJoint[2]);
            mat4 jm2 = jointMatrix[j2];
            skinnedPosition += w2 * (jm2 * vec4(vertexPosition.xyz, 1.0));
            skinnedNormal   += w2 * (mat3(jm2) * VertexNormal);
        }
        float w3 = VertexWeight[3];
        if (w3 > 0.0) {
            int j3 = int(VertexJoint[3]);
            mat4 jm3 = jointMatrix[j3];
            skinnedPosition += w3 * (jm3 * vec4(vertexPosition.xyz, 1.0));
            skinnedNormal   += w3 * (mat3(jm3) * VertexNormal);
        }

        // If no weights, use original position/normal
        if (w0 + w1 + w2 + w3 == 0.0) {
            skinnedPosition = vec4(vertexPosition.xyz, 1.0);
            skinnedNormal = VertexNormal;
        }

        // --- Transformations ---
        vec4 transformedPosition = modelMatrix * skinnedPosition;
        vec3 transformedNormal = normalize(mat3(modelMatrix) * skinnedNormal);

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