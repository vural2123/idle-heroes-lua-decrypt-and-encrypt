-- shaders

local shaders = {}

require "common.const"

shaders[SHADER_GRAY] =
"#ifdef GL_ES\n\
precision lowp float;\n\
#endif\n\
varying vec4 v_fragmentColor;\n\
varying vec2 v_texCoord;\n\
uniform sampler2D CC_Texture0;\n\
void main() {\n\
    gl_FragColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);\n\
    float grey = dot(gl_FragColor.rgb, vec3(0.299, 0.587, 0.114));\n\
    gl_FragColor.rgb = vec3(grey ,grey ,grey);\n\
}"

shaders[SHADER_HIGHLIGHT] =
"#ifdef GL_ES\n\
precision lowp float;\n\
#endif\n\
varying vec4 v_fragmentColor;\n\
varying vec2 v_texCoord;\n\
uniform sampler2D CC_Texture0;\n\
void main() {\n\
    gl_FragColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);\n\
    if(gl_FragColor.a > 0.0) {\n\
        gl_FragColor.rgb *= 1.5;\n\
    }\n\
}"

shaders[SHADER_MENUITEM] =
"#ifdef GL_ES\n\
precision lowp float;\n\
#endif\n\
varying vec4 v_fragmentColor;\n\
varying vec2 v_texCoord;\n\
uniform sampler2D CC_Texture0;\n\
void main() {\n\
    gl_FragColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);\n\
    if(gl_FragColor.a > 0.0) {\n\
        gl_FragColor.rgb *= 1.5;\n\
    }\n\
}"

shaders[SHADER_ICE] =
"#ifdef GL_ES\n\
precision lowp float;\n\
#endif\n\
varying vec4 v_fragmentColor;\n\
varying vec2 v_texCoord;\n\
uniform sampler2D CC_Texture0;\n\
void main() {\n\
    gl_FragColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);\n\
    if(gl_FragColor.a > 0.0) {\n\
        gl_FragColor.b *= 2.5;\n\
        gl_FragColor.g *= 1.5;\n\
    }\n\
}"

shaders[SHADER_INJURED] =
"#ifdef GL_ES\n\
precision lowp float;\n\
#endif\n\
varying vec4 v_fragmentColor;\n\
varying vec2 v_texCoord;\n\
uniform sampler2D CC_Texture0;\n\
void main() {\n\
    gl_FragColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);\n\
    if(gl_FragColor.a > 0.0) {\n\
        gl_FragColor.r *= 2.5;\n\
    }\n\
}"

shaders[SHADER_DARK] =
"#ifdef GL_ES\n\
precision lowp float;\n\
#endif\n\
varying vec4 v_fragmentColor;\n\
varying vec2 v_texCoord;\n\
uniform sampler2D CC_Texture0;\n\
void main() {\n\
    gl_FragColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);\n\
    if(gl_FragColor.a > 0.0) {\n\
        gl_FragColor.rgb *= 0.5;\n\
    }\n\
}"

--新增 柔光叠加
-- shaders[SHADER_SOFT_LIGHT_1] =
-- "#ifdef GL_ES\n\
-- precision lowp float;\n\
-- #endif\n\
-- varying vec4 v_fragmentColor;\n\
-- varying vec2 v_texCoord;\n\
-- uniform sampler2D CC_Texture0;\n\
-- void main() {\n\
--     float r = 132.0;\n\
--     float g = 102.0;\n\
--     float b = 149.0;\n\
--     gl_FragColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);\n\
--     if(gl_FragColor.a > 0.0) {\n\
--         gl_FragColor.rgb *= 255.0;\n\
--         if (r < 128.0) {\n\
--             gl_FragColor.r = (2.0 * (( gl_FragColor.r / 2.0) + 64.0)) * (r / 255.0);\n\
--         }\n\
--         else {\n\
--             gl_FragColor.r = (255.0 - ( 2.0 * (255.0 - ( gl_FragColor.r / 2.0 + 64.0 ) ) * ( 255.0 - r ) / 255.0 ));\n\
--         }\n\
--         if (g < 128.0) {\n\
--             gl_FragColor.g = (2.0 * (( gl_FragColor.g / 2.0) + 64.0)) * (g / 255.0);\n\
--         }\n\
--         else {\n\
--             gl_FragColor.g = (255.0 - ( 2.0 * (255.0 - ( gl_FragColor.g / 2.0 + 64.0 ) ) * ( 255.0 - g ) / 255.0 ));\n\
--         }\n\
--         if (b < 128.0) {\n\
--             gl_FragColor.b = (2.0 * (( gl_FragColor.b / 2.0) + 64.0)) * (b / 255.0);\n\
--         }\n\
--         else {\n\
--             gl_FragColor.b = (255.0 - ( 2.0 * (255.0 - ( gl_FragColor.b / 2.0 + 64.0 ) ) * ( 255.0 - b ) / 255.0 ));\n\
--         }\n\
--         gl_FragColor.rgb /= 255.0;\n\
--         gl_FragColor.rgb *= gl_FragColor.a;\n\
--     }\n\
-- }"

local solfLightPrev = 
"#ifdef GL_ES\n\
precision lowp float;\n\
#endif\n\
varying vec4 v_fragmentColor;\n\
varying vec2 v_texCoord;\n\
uniform sampler2D CC_Texture0;\n\
void main() {\n\
"

local solfLightNext = 
"gl_FragColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);\n\
    if(gl_FragColor.a > 0.0) {\n\
        r /= 255.0;\n\
        g /= 255.0;\n\
        b /= 255.0;\n\
        if (r < 0.5) {\n\
            gl_FragColor.r = (2.0 * r - 1.0) * (gl_FragColor.r - gl_FragColor.r * gl_FragColor.r) + gl_FragColor.r;\n\
        }\n\
        else {\n\
            gl_FragColor.r = (2.0 * r - 1.0) * (sqrt(gl_FragColor.r) - gl_FragColor.r) + gl_FragColor.r;\n\
        }\n\
        if (g < 0.5) {\n\
            gl_FragColor.g = (2.0 * g - 1.0) * (gl_FragColor.g - gl_FragColor.g * gl_FragColor.g) + gl_FragColor.g;\n\
        }\n\
        else {\n\
            gl_FragColor.g = (2.0 * g - 1.0) * (sqrt(gl_FragColor.g) - gl_FragColor.g) + gl_FragColor.g;\n\
        }\n\
        if (b < 0.5) {\n\
            gl_FragColor.b = (2.0 * b - 1.0) * (gl_FragColor.b - gl_FragColor.b * gl_FragColor.b) + gl_FragColor.b;\n\
        }\n\
        else {\n\
            gl_FragColor.b = (2.0 * b - 1.0) * (sqrt(gl_FragColor.b) - gl_FragColor.b) + gl_FragColor.b;\n\
        }\n\
    }\n\
}"

local fort_slcolor = {
    normal = {              -- 前8个据点
        "   float r = 142.0;\n\    float g = 142.0;\n\    float b = 142.0;\n\   ",
        "   float r = 142.0;\n\    float g = 148.0;\n\    float b = 145.0;\n\   ",
        "   float r = 144.0;\n\    float g = 126.0;\n\    float b = 160.0;\n\   ",
        "   float r = 146.0;\n\    float g = 128.0;\n\    float b = 156.0;\n\   ",
        "   float r = 121.0;\n\    float g = 166.0;\n\    float b = 177.0;\n\   ",
        "   float r = 164.0;\n\    float g = 143.0;\n\    float b = 131.0;\n\   ",
        "   float r = 154.0;\n\    float g = 135.0;\n\    float b = 162.0;\n\   ",
        "   float r = 169.0;\n\    float g = 159.0;\n\    float b = 140.0;\n\   ",
    },
    difficult = {              -- 前9个据点
        "   float r = 109.0;\n\    float g = 137.0;\n\    float b = 196.0;\n\   ",
        "   float r = 97.0;\n\    float g = 104.0;\n\    float b = 156.0;\n\   ",
        "   float r = 114.0;\n\    float g = 124.0;\n\    float b = 179.0;\n\   ",
        "   float r = 112.0;\n\    float g = 115.0;\n\    float b = 160.0;\n\   ",
        "   float r = 119.0;\n\    float g = 142.0;\n\    float b = 174.0;\n\   ",
        "   float r = 123.0;\n\    float g = 110.0;\n\    float b = 170.0;\n\   ",
        "   float r = 127.0;\n\    float g = 122.0;\n\    float b = 148.0;\n\   ",
        "   float r = 126.0;\n\    float g = 127.0;\n\    float b = 184.0;\n\   ",
        "   float r = 115.0;\n\    float g = 118.0;\n\    float b = 161.0;\n\   ",
    },
    dungeon = {              -- 前11个据点
        "   float r = 132.0;\n\    float g = 102.0;\n\    float b = 149.0;\n\   ",
        "   float r = 117.0;\n\    float g =  94.0;\n\    float b = 148.0;\n\   ",
        "   float r = 147.0;\n\    float g = 103.0;\n\    float b = 156.0;\n\   ",
        "   float r = 134.0;\n\    float g = 118.0;\n\    float b = 156.0;\n\   ",
        "   float r = 146.0;\n\    float g = 137.0;\n\    float b = 181.0;\n\   ",
        "   float r = 123.0;\n\    float g = 110.0;\n\    float b = 170.0;\n\   ",
        "   float r = 151.0;\n\    float g = 130.0;\n\    float b = 156.0;\n\   ",
        "   float r = 147.0;\n\    float g = 112.0;\n\    float b = 169.0;\n\   ",
        "   float r = 132.0;\n\    float g = 102.0;\n\    float b = 153.0;\n\   ",
        "   float r = 153.0;\n\    float g = 120.0;\n\    float b = 175.0;\n\   ",
        "   float r = 149.0;\n\    float g = 115.0;\n\    float b = 156.0;\n\   ",
    }
}

for ii=1,#fort_slcolor.normal do
    shaders[SHADER_SOFT_LIGHT_NORMAL+ii-1] = solfLightPrev..
    fort_slcolor.normal[ii]
    ..solfLightNext
end
for ii=1,#fort_slcolor.difficult do
    shaders[SHADER_SOFT_LIGHT_DIFFICULT+ii-1] = solfLightPrev..
    fort_slcolor.difficult[ii]
    ..solfLightNext
end
for ii=1,#fort_slcolor.dungeon do
    shaders[SHADER_SOFT_LIGHT_DUNGEON+ii-1] = solfLightPrev..
    fort_slcolor.dungeon[ii]
    ..solfLightNext
end

return shaders


