/* 
    Melon Shaders by June
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:05 */
layout (location = 0) out vec4 colorOut;
layout (location = 1) out vec4 reflectionsOut;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex5;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform sampler2D noisetex;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform vec3 previousCameraPosition;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;

uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform float far;
uniform float near;
uniform float sunAngle;
uniform float frameTimeCounter;
uniform int frameCounter;
uniform int isEyeInWater;
uniform float rainStrength;
uniform float centerDepthSmooth;
uniform ivec2 eyeBrightnessSmooth;

uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform vec3 fogColor;

in vec2 texcoord;
in vec3 ambientColor;
in vec3 lightColor;

in vec4 times;

#define linear(x) (2.0 * near * far / (far + near - (2.0 * x - 1.0) * (far - near)))

#include "/lib/distort.glsl"
#include "/lib/fragmentUtil.glsl"
#include "/lib/noise.glsl"
#include "/lib/labpbr.glsl"
#include "/lib/poisson.glsl"
#include "/lib/shading.glsl"
#include "/lib/atmosphere.glsl"

#include "/lib/raytrace.glsl"
#include "/lib/reflection.glsl"

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;

    float depth0 = texture2D(depthtex0, texcoord).r;

    vec4 screenPos = vec4(texcoord, depth0, 1.0) * 2.0 - 1.0;
    vec4 viewPos = gbufferProjectionInverse * screenPos;
    viewPos /= viewPos.w;
    vec4 worldPos = gbufferModelViewInverse * viewPos;
    
    // if not sky check for translucents
    if (depth0 != 1.0) {
        Fragment frag = getFragment(texcoord);
        PBRData pbr = getPBRData(frag.specular);

        // 2 is translucents tag
        if (frag.matMask == 2) {

            vec4 shadowPos = shadowModelView * worldPos;
            shadowPos = shadowProjection * shadowPos;
            shadowPos /= shadowPos.w;

            color = calculateTranslucentShading(frag, pbr, normalize(viewPos.xyz), shadowPos.xyz, clamp01(decodeLightmaps(texture2D(colortex1, texcoord).z).y));

            if (isEyeInWater == 0) applyFog(viewPos.xyz, worldPos.xyz, depth0, color);

        } else if (frag.matMask == 3) {
            // render water fog
            float ldepth0 = linear(depth0);
            float ldepth1 = linear(texture2D(depthtex1, texcoord).r);

            float depthcomp = (ldepth1-ldepth0);
            // set color to color without water in it
            vec3 oldcolor = color;
            color = texture2D(colortex5, texcoord).rgb;
            // if eye is not in water, render above-water fog and render sky reflection
            if (isEyeInWater == 0) {
                // calculate transmittance
                vec3 transmittance = exp(-vec3(1.0, 0.2, 0.1) * depthcomp);
                color = color * transmittance;
                // colorize water fog based on biome color
                color *= oldcolor;

                // calculate water foam/lines color
                vec3 foamBrightness = ambientColor;

                if (eyeBrightnessSmooth.y <= 64 && eyeBrightnessSmooth.y > 8) {
                    foamBrightness *= clamp01(((eyeBrightnessSmooth.y-9)/55.0)+0.25);
                } else if (eyeBrightnessSmooth.y <= 8) {
                    foamBrightness *= 0.25;
                }

                foamBrightness *= WAVE_BRIGHTNESS;

                // water foam
                #ifdef WAVE_FOAM
                if (depthcomp <= 0.15) {
		    	    color += vec3(0.75) * foamBrightness;
		        } 
                #endif

                #ifdef WAVE_LINES
                vec3 worldPosCamera = worldPos.xyz + cameraPosition;

                worldPosCamera.z += int((frameTimeCounter*(WAVE_SPEED*0.175))*16.0)/16.0;

                color += vec3(texture2D(depthtex2, worldPosCamera.xz).r) * 0.75 * foamBrightness;
                #endif

                #ifdef WAVE_CAUSTICS
                vec3 CworldPosCamera = worldPos.xyz + cameraPosition;

                #ifdef WAVE_PIXEL
                CworldPosCamera = vec3(ivec3(CworldPosCamera*WAVE_PIXEL_R)/WAVE_PIXEL_R);
                #endif

                CworldPosCamera.y += frameTimeCounter*WAVE_SPEED;
                color += vec3(pow(cellular(CworldPosCamera), 8.0)) * 0.75 * foamBrightness;
                #endif
            }
        }
    }

    // apply fog

    if (isEyeInWater != 0) applyFog(viewPos.xyz, worldPos.xyz, depth0, color);

    colorOut = vec4(color, 1.0);
    reflectionsOut = vec4(color, 1.0);
}

#endif

// VERTEX SHADER //

#ifdef VERT

out vec2 texcoord;
out vec3 ambientColor;
out vec3 lightColor;
out vec4 times;

uniform float sunAngle;
uniform float rainStrength;

uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    calcLightingColor(sunAngle, rainStrength, sunPosition, shadowLightPosition, ambientColor, lightColor, times);
}

#endif