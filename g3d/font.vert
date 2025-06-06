layout(location = 0) in vec2 aPosition;   // XYf
layout(location = 1) in vec2 aTexCoord;   // STus (should be normalized in CPU code)
layout(location = 2) in vec4 aColor; // RGBAub (should be normalized in CPU code)

uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;

varying vec2 vTexCoord;
varying vec4 vColor;


void vertexmain() {
    vTexCoord = aTexCoord;
    vColor = aColor;
    love_Position = projectionMatrix * viewMatrix * vec4(aPosition, 0.0f, 1.0);    
}