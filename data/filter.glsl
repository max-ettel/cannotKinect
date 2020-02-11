#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform sampler2D texture;
uniform sampler2D depthTexture;
uniform sampler2D movTexture;
varying vec4 vertTexCoord;

uniform float hori;
uniform float vert;
uniform float wheel;

const float scale = 1.0799996;
const float xoffset = -0.007174231;
const float yoffset = -0.07838542;

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float mirrored(float v) {
    float m = mod(v, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

void main(void) {
  vec2 p = vertTexCoord.st;
  p.x = 1.0 - p.x;

  p -= 0.5;
  p *= 0.85;
  p += 0.5;

  // Align depth and color
  vec2 pDepth = p * scale;
  pDepth += vec2(xoffset, yoffset);
	float depth = texture2D(depthTexture, pDepth).r;
  float mixer = 0;
  
  // Clamp, change range of depth
  if(depth > 0.52 && depth < 0.57) {
    mixer = 1.0;
  }

  // Get color and glitch
	vec3 color = texture2D(texture, p).rgb;
  color.rgb = rgb2hsv(color.rgb);
  color.y += sin(wheel) * 0.2;
  color.z -= 0.5;
  color.rgb = hsv2rgb(color.rgb);

  p.x = mirrored(p.x - hori);
  p.y = mirrored(p.y - vert);

	vec3 glitch = texture2D(movTexture, p).rgb;

  color = mix(color, glitch, mixer);

  gl_FragColor = vec4(color, 1.0);
}