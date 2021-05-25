-- manage fonts and labels here

local lbl = {}

require "common.const"
require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"

-- 字体所在路径
local fontDir = "fonts/"

-- 所有字体字号和名字（不包含语言名字前缀）
local fontFileConfig = {
    [1]  = { size = 28, name = "font_1.fnt" }, 
    [2]  = { size = 28, name = "font_2.fnt" },
    [3]  = { size = 32, name = "font_3.fnt" },
}

-- 对应每种语言的字体配置
-- prefix为字体名字的前缀（与fontFileConfig中的项做拼接获得完整字体名字）
-- fonts为fontFileConfig中的索引，意味着该语言拥有的字体
local fontLanguageConfig = {
    us = { prefix = "us", fonts = { 1, 2, 3 } }, -- 英语
    es = { prefix = "us", fonts = { 1, 2, 3 } }, -- 西班牙
    pt = { prefix = "us", fonts = { 1, 2, 3 } }, -- 葡萄牙 
    fr = { prefix = "us", fonts = { 1, 2, 3 } }, -- 法语
    tr = { prefix = "us", fonts = { 1, 2, 3 } }, -- 土耳其
    de = { prefix = "us", fonts = { 1, 2, 3 } }, -- 德语
    it = { prefix = "us", fonts = { 1, 2, 3 } }, -- 意大利语
    ru = { prefix = "ru", fonts = { 1, 2, 3 } }, -- 俄语
    ms = { prefix = "us", fonts = { 1, 2, 3 } }, -- 马来西亚语
    cn = { prefix = "cn", fonts = { 1, 2, 3 } }, -- 简体中文
    tw = { prefix = "tw", fonts = { 1, 2, 3 } }, -- 繁体中文
    jp = { prefix = "jp", fonts = { 1, 2, 3 } }, -- 日本语
    kr = { prefix = "kr", fonts = { 1, 2, 3 } }, -- 韩语
    th = { prefix = "th", fonts = { 2  } }, -- 泰语
    vi = { prefix = "vi", fonts = { 1, 2, 3 } }, -- 越南语
    ar = { prefix = "ar", fonts = { 1, 2, 3} }, -- 阿拉伯语
}

-- 初始化完整的字体名字
-- fontNames形如：
-- fontNames = {
--     us = {
--         [1] = "fonts/us_caslon_24.fnt",
--         [2] = "fonts/us_caslon_24_border.fnt",
--         [4] = "fonts/us_titania_48.fnt",
--         ...
--     },
--     jp = {
--         ...
--     }
-- }
local fontNames = {}
local function initFontNames()
    for lang, langConfig in pairs(fontLanguageConfig) do
        fontNames[lang] = {}
        for _, font in ipairs(fontLanguageConfig[lang].fonts) do
            fontNames[lang][font] = string.format("%s%s_%s", fontDir, 
                                                             fontLanguageConfig[lang].prefix, 
                                                             fontFileConfig[font].name)
        end
    end
end
initFontNames()

-- 核心函数，用于创建CCLabel
-- config形如：
-- config = {
--     lang = "cn", 指定使用哪种语言的字体，无该项则默认使用当前语言
--     font = 1, 为fontFileConfig中的索引，无该项则默认为1
--     size = 20, 字号，无该项则默认为20
--     kind = "bmf"|"ttf", 无该项则默认优先尝试"bmf"，若没有对应BMFont字体，则使用TTF
--     minScale = true, 是否还要minScale，无该项则默认为false
--     text = "aa", 无该项则默认""
--     color = ccc3(), 可选项，可用于BMFont和TTF的颜色
--     bmfColor = ccc3(), 可选项，只用于BMFont的颜色，优先级高于color
--     ttfColor = ccc3(), 可选项，只用于TTF的颜色，优先级高于color
--     gray = true, 可选项，是否置成灰色SHADER
--     opacity = 200, 可选项，设置透明度
--     width = 100, 可选项，设置宽度
--     align = kCCTextAlignmentLeft, 可选项，水平对齐方式
--     us = { 可选项，语言特定设置，优先级高于通用设置
--         font = 2,
--         size = 21,
--         kind = "ttf",
--         ...
--     },
--     jp = { 
--         ...
--     },
-- }
function lbl.create(config)
    -- 各种参数
    local lang = config.lang or i18n.getLanguageShortName()
    local font = config.font or 1
    local size = config.size or 20
    local kind = config.kind or "bmf"
    local minScale = config.minScale
    local text = config.text or ""
    local color = config.color
    local bmfColor = config.bmfColor
    local ttfColor = config.ttfColor
    local gray = config.gray
    local opacity = config.opacity
    local width = config.width
    local align = config.align
    if config[lang] then
        if config[lang].font ~= nil then font = config[lang].font end
        if config[lang].size ~= nil then size = config[lang].size end
        if config[lang].kind ~= nil then kind = config[lang].kind end
        if config[lang].minScale ~= nil then minScale = config[lang].minScale end
        if config[lang].text ~= nil then text = config[lang].text end
        if config[lang].color ~= nil then color = config[lang].color end
        if config[lang].bmfColor ~= nil then bmfColor = config[lang].bmfColor end
        if config[lang].ttfColor ~= nil then ttfColor = config[lang].ttfColor end
        if config[lang].gray ~= nil then gray = config[lang].gray end
        if config[lang].opacity ~= nil then opacity = config[lang].opacity end
        if config[lang].width ~= nil then width = config[lang].width end
        if config[lang].align ~= nil then align = config[lang].align end
    end
    -- 虽然kind配置为bmf，但实际却没有这种美术字，仍然用ttf
    if kind == "bmf" and not arraycontains(fontLanguageConfig[lang].fonts, font) then
        kind = "ttf"
    end
    -- label
    local label
    if kind == "bmf" then
        label = CCLabelBMFont:create(text, fontNames[lang][font])
        label:setScale(size / fontFileConfig[font].size)
        if bmfColor or color then
            label:setColor(bmfColor or color)
        end
    else
        label = CCLabelTTF:create(text, "", size)
        if ttfColor or color then
            label:setColor(ttfColor or color)
        end
    end
    if minScale then
        label:setScale(label:getScale() * view.minScale)
    end
    if gray then
        setShader(label, SHADER_GRAY, true)
    end
    if opacity then
        label:setCascadeOpacityEnabled(true)
        label:setOpacity(opacity)
    end
    if width then
        if kind == "bmf" then
            if minScale then
                label:setWidth(width * view.minScale)
            else
                label:setWidth(width)
            end
        else
            label:setDimensions(CCSize(width, 0))
        end
    end
    if align then
        if kind == "bmf" then
            label:setAlignment(align)
        else
            label:setHorizontalAlignment(align)
        end
    end

    return label
end

function lbl.createFont1(size, text, color, minScale)
    return lbl.create({font = 1, size = size, text = text, color = color, minScale = minScale})
end

function lbl.createFont2(size, text, color, minScale)
    return lbl.create({font = 2, size = size, text = text, color = color, minScale = minScale})
end

function lbl.createFont3(size, text, color, minScale)
    return lbl.create({font = 3, size = size, text = text, color = color, minScale = minScale})
end

-- 混合字: 中日韩用系统字，其他语言用美术字
function lbl.createMix(config)
    for _, lang in ipairs({ "cn", "tw", "jp", "kr" }) do
        if not config[lang] then
            config[lang] = {}
        end
        if not config[lang].kind then
            config[lang].kind = "ttf"
        end
    end
    return lbl.create(config)
end

function lbl.createMixFont1(size, text, color, minScale)
    return lbl.createMix({font = 1, size = size, text = text, color = color, minScale = minScale})
end

function lbl.createMixFont2(size, text, color, minScale)
    return lbl.createMix({font = 2, size = size, text = text, color = color, minScale = minScale})
end

function lbl.createMixFont3(size, text, color, minScale)
    return lbl.createMix({font = 3, size = size, text = text, color = color, minScale = minScale})
end

-- 系统字
function lbl.createFontTTF(size, text, color, minScale)
    return lbl.create({ kind = "ttf", size = size, text = text, color = color, minScale = minScale })
end

-- 品质颜色
lbl.qualityColors = {
    [QUALITY_1] = ccc3(0x1a, 0x91, 0xff),
    [QUALITY_2] = ccc3(0xdc, 0xc2, 0x13),
    [QUALITY_3] = ccc3(0xdb, 0x3f, 0xff),
    [QUALITY_4] = ccc3(0x39, 0xe6, 0x3a),
    [QUALITY_5] = ccc3(0xff, 0x40, 0x40),
    [QUALITY_6] = ccc3(0xfa, 0x8e, 0x1a),
	[7] = ccc3(0x64, 0xe5, 0xc9),
}

-- 按钮颜色
lbl.buttonColor = ccc3(0x73, 0x3b, 0x05)

-- 通用白
lbl.whiteColor = ccc3(255, 246, 223)

return lbl 
