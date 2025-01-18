// written by groverbuger for g3d
// september 2021
// MIT license

// this vertex shader is what projects 3d vertices in models onto your 2d screen

uniform mat4 projectionMatrix; // handled by the camera
uniform mat4 viewMatrix;       // handled by the camera
uniform mat4 modelMatrix;      // models send their own model matrices when drawn
uniform bool isCanvasEnabled;  // detect when this model is being rendered to a canvas

uniform mat4 jointMatrix[100]; // array of joint matrices

attribute vec3 VertexNormal;

// define some varying vectors that are useful for writing custom fragment shaders
varying vec4 worldPosition;
varying vec4 viewPosition;
varying vec4 screenPosition;
varying vec3 vertexNormal;
varying vec4 vertexColor;
varying vec4 weight;
varying vec4 joint;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    // calculate the positions of the transformed coordinates on the screen
    // save each step of the process, as these are often useful when writing custom fragment shaders
    // Apply skinning transformation
    vec4 skinnedPosition = vec4(0.0);
    vec3 skinnedNormal = vec3(0.0);

    for (int i = 0; i < 4; i++) {
        int jointIndex = int(joint[i]);
        mat4 jointMat = jointMatrix[jointIndex];
        skinnedPosition += weight[i] * (jointMat * vec4(vertexPosition.xyz, 1.0));
        skinnedNormal += weight[i] * (mat3(jointMat) * vertexNormal);
    }

    // Transform the skinned position and normal
    vec4 transformedPosition = modelMatrix * skinnedPosition;
    vec3 transformedNormal = normalize(mat3(modelMatrix) * skinnedNormal);

    worldPosition = transformedPosition;
    viewPosition = viewMatrix * worldPosition;
    screenPosition = projectionMatrix * viewPosition;

    // save some data from this vertex for use in fragment shaders
    vertexNormal = transformedNormal;
    vertexColor = VertexColor;

    return screenPosition;
}
