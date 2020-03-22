#version 120

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 lightColor;
varying vec3 skyColor;
varying float isNight;
uniform int worldTime;

uniform sampler2D noisetex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;

uniform sampler2D colortex0;
uniform sampler2D colortex7;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform sampler2D gdepthtex;
uniform sampler2D gaux2;
uniform sampler2D shadow;
uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;

uniform vec3 cameraPosition;

uniform vec3 upPosition;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform float viewWidth;
uniform float viewHeight;

varying float isTransparent;
varying vec3 normal;

#include "/lib/settings.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/common.glsl"
#include "/lib/shadow.glsl"
#include "/lib/dither.glsl"
#include "/lib/reflection.glsl"
#include "/lib/noise.glsl"

/* DRAWBUFFERS:012 */

void main() {

    vec3 finalColor = texture2D(colortex0, texcoord.st).rgb;
    Fragment frag = getFragment(texcoord.st);
    Lightmap lightmap = getLightmapSample(texcoord.st);

    // calculate shadowmapped lighting for translucents (except for water)
    // 0.1 emission marks translucent
    if (frag.emission == 0.1) {
        finalColor = calculateBasicLighting(frag, lightmap);
    }
    // 0.5 emission marks water, calculate basic lighting so shadows aren't cast on water
    else if (frag.emission == 0.5) {
        finalColor = calculateBasicLighting(frag, lightmap);
    }

    // output
    gl_FragData[0] = vec4(finalColor, 1);
}