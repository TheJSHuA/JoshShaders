
vec3 calcVolumetricLighting(in vec3 viewPos, in vec3 color, in float densityMult, in bool noonDensityDecrease) {
    float noon = ((clamp(sunAngle, 0.02, 0.15)-0.02) / 0.13   - (clamp(sunAngle, 0.35, 0.48)-0.35) / 0.13);

    vec4 startPos = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(0.0, 0.0, 0.0, 1.0);
    vec4 stepSize = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(viewPos, 1.0);
    stepSize /= VL_STEPS;
    stepSize *= fract(frameTimeCounter * 8.0 + bayer64(gl_FragCoord.xy));

    vec4 currentPos = startPos;

    float visibility = 0.0;

    for (int i = 0; i < VL_STEPS; i++) {
        vec3 currentPosShadow = distort(currentPos.xyz) * 0.5 + 0.5;

        bool intersection = texture2D(shadowtex1, currentPosShadow.xy).r < currentPosShadow.z;
        visibility += intersection ? 0.0 : 1.0;

        currentPos += stepSize;
    }

    visibility /= VL_STEPS;
    vec3 vlColor = mix(vec3(0.0), color*((VL_DENSITY/15.0)*densityMult), clamp01(visibility));
    if (noonDensityDecrease) vlColor *= mix(vec3(1.0), vec3(0.25), clamp01(noon));

    return vlColor;
}