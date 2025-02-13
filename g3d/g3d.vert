// written by groverbuger for g3d
// september 2021
// MIT license

// this vertex shader is what projects 3d vertices in models onto your 2d screen

uniform mat4 projectionMatrix; // handled by the camera
uniform mat4 viewMatrix;       // handled by the camera
uniform mat4 modelMatrix;      // models send their own model matrices when drawn
uniform bool isCanvasEnabled;  // detect when this model is being rendered to a canvas

uniform mat4 jointMatrix[100]; // array of joint matrices
uniform int flip;               // flip the y-axis for canvas rendering
uniform int joints[100];        // array of joint indices
uniform int jointCount;         // number of joints

uniform vec3 lightDirection; // Direction of the directional light
uniform vec3 lightColor;     // Color of the directional light
uniform vec3 ambientColor;   // Ambient light color
uniform float lightIntensity; // Intensity of the directional light
uniform mat4 lightSpaceMatrix; // Light space matrix

attribute vec3 VertexNormal;
attribute vec4 VertexWeight;
attribute vec4 VertexJoint;

// define some varying vectors that are useful for writing custom fragment shaders
varying vec4 worldPosition;
varying vec4 viewPosition;
varying vec4 screenPosition;
varying vec3 vertexNormal;
varying vec4 vertexColor;
varying vec4 vertexWeight;
varying vec4 vertexJoint;
varying vec3 lighting;
varying vec4 fragPosLightSpace;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    // Initialize skinned position and normal
    vec4 skinnedPosition = vec4(0.0);
    vec3 skinnedNormal = vec3(0.0);
    bool hasWeights = false;
    
    if (jointCount > 0) {        
        hasWeights = true;
        // Apply skinning transformation using joint matrices and weights
        for (int i = 0; i < 4; i++) {
            int jointIndex = int(VertexJoint[i]);
            int joint = joints[jointIndex];
            float weight = VertexWeight[i];
            mat4 jointMat = jointMatrix[jointIndex];
            skinnedPosition += weight * (jointMat * vec4(vertexPosition.xyz, 1.0));
            skinnedNormal += weight * (mat3(jointMat) * VertexNormal);            
        }
    } 
    
    if (!hasWeights) {
        // If no weights are present, use the original vertex position and normal
        skinnedPosition = vec4(vertexPosition.xyz, 1.0);
        skinnedNormal = VertexNormal;
    }

    // Transform the skinned position and normal by the model matrix
    vec4 transformedPosition = modelMatrix * skinnedPosition;
    vec3 transformedNormal = normalize(mat3(modelMatrix) * skinnedNormal);

    // Calculate the final positions
    worldPosition = transformedPosition;
    viewPosition = viewMatrix * worldPosition;
    screenPosition = projectionMatrix * viewPosition;

    // Save some data from this vertex for use in fragment shaders
    vertexNormal = transformedNormal;
    vertexColor = VertexColor;

    // Calculate directional lighting
    vec3 norm = normalize(transformedNormal);
    vec3 lightDir = normalize(lightDirection);
    float diff = max(dot(norm, lightDir), 0.0);
    float li = lightIntensity;
    vec3 diffuse = diff * lightColor * li;
    vec3 ambient = ambientColor;
    lighting = diffuse + ambient;

    // Transform the vertex position to light space
    fragPosLightSpace = lightSpaceMatrix * transformedPosition;
    
    if (flip == 1) {
        // Flip the y-axis for canvas rendering
        screenPosition.y = -screenPosition.y;
    }
    return screenPosition;
}
