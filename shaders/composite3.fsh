#version 120

// composite pass 3: bloom pass 2

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D gdepth;
uniform sampler2D gnormal;
uniform sampler2D colortex3;

uniform float viewWidth;
uniform float viewHeight;

varying vec4 texcoord;

#include "/lib/settings.glsl"

const float weight[21] = float[] (0,	0,	0,0,0,0.000003,	0.000229,	0.005977,	0.060598,	0.24173,	0.382925,	0.24173,	0.060598,	0.005977,	0.000229,	0.000003,	0,	0,	0,	0,	0);

void main() {

    #ifdef BLOOM
    vec2 tex_offset = 1.0 / vec2(viewWidth, viewHeight); // gets size of single texel
    vec3 result = texture2D(colortex4, texcoord.st).rgb * weight[0]; // current fragment's contribution
    for(int i = 1; i < 21; ++i)
    {
        result += texture2D(colortex4, texcoord.st + vec2(0.0, tex_offset.y * i)).rgb * weight[i];
        result += texture2D(colortex4, texcoord.st - vec2(0.0, tex_offset.y * i)).rgb * weight[i];
    }
    #endif
    vec4 color = texture2D(colortex0, texcoord.st);

    /* DRAWBUFFERS:012 */
    #ifdef BLOOM
    gl_FragData[0] = color + vec4(result,1);
    #else
    gl_FragData[0] = color;
    #endif
    gl_FragData[1] = texture2D(gdepth, texcoord.st);
    gl_FragData[2] = texture2D(gnormal, texcoord.st);
}