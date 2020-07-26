/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/*
const bool colortex2MipmapEnabled = true;
const float centerDepthSmoothHalflife = 4.0;
*/

/* DRAWBUFFERS:02 */
layout (location = 0) out vec3 colorOut;
layout (location = 1) out vec3 bloomOut;

// Inputs from vertex shader
in vec2 texcoord;

// Uniforms
uniform sampler2D colortex0;
uniform sampler2D colortex2;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;

uniform float viewWidth;
uniform float viewHeight;
uniform float centerDepthSmooth;

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;

    #ifdef DOF

    float currentDepth = texture2D(depthtex1, texcoord).r;

    if (currentDepth >= texture2D(depthtex2, texcoord).r || currentDepth != texture2D(depthtex0, texcoord).r) {
        vec2 oneTexel = 1.0 / vec2(viewWidth, viewHeight);

        if (currentDepth >= centerDepthSmooth) {
            // distance blur
            vec3 blurred = vec3(0.0);
            float blurSize = clamp((currentDepth-centerDepthSmooth)*(256.0*APERTURE), 0.0, (12.0*APERTURE));
            for (int i = 0; i <= 8; i++) {
                vec2 offset = vogelDiskSample(i, 8, interleavedGradientNoise(gl_FragCoord.xy))*oneTexel*blurSize;
                #ifdef CHROM_ABB
                float g = texture2D(colortex0, texcoord + (offset*0.5)).g;
                vec2 rb = texture2D(colortex0, texcoord + offset).rb;
                blurred += vec3(rb.x, g, rb.y);
                #else
                blurred += texture2D(colortex0, texcoord+offset).rgb;
                #endif
            }
            color = blurred / 8.0;
        } else if (currentDepth <= centerDepthSmooth) {
            // close up blur
            vec3 blurred = vec3(0.0);
            float blurSize = clamp((centerDepthSmooth-currentDepth)*(256.0*APERTURE), 0.0, (12.0*APERTURE));
            for (int i = 0; i <= 8; i++) {
                vec2 offset = vogelDiskSample(i, 8, interleavedGradientNoise(gl_FragCoord.xy))*oneTexel*blurSize;
                #ifdef CHROM_ABB
                float b = texture2D(colortex0, texcoord + (offset*0.5)).b;
                vec2 rg = texture2D(colortex0, texcoord + offset).rg;
                blurred += vec3(rg, b);
                #else
                blurred += texture2D(colortex0, texcoord+offset).rgb;
                #endif
            }
            color = blurred / 8.0;
        }
    }

    #endif

    colorOut = color;

    #ifdef BLOOM
    vec3 bloomSample = color.rgb * clamp01(pow(luma(color.rgb), 4.0));
    bloomOut = bloomSample;
    #endif
}

#endif

// VERTEX SHADER //

#ifdef VSH

out vec2 texcoord;

uniform float sunAngle;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif