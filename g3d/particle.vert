layout(location = 0) in vec3 aPosition;   // Particle position (x, y, z)
layout(location = 1) in vec2 aTexCoord;   // Texture coordinate (u, v)
layout(location = 2) in vec4 aColor;      // Particle color (r, g, b, a)

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec2 vTexCoord;
out vec4 vColor;

void vertexmain() {
    // Transform particle position
    love_Position = projection * view * model * vec4(aPosition, 1.0);
    vTexCoord = aTexCoord;
    vColor = aColor;
}