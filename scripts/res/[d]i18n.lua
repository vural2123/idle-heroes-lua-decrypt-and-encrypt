-- 所有strings的管理，屏蔽了多语言的细节，如，要访问id=1101的英雄的名字，
-- 中文时完整路径是config.strings.cn.hero[1101].heroName, 
-- 英文时完整路径是config.strings.us.hero[1101].heroName, 
-- 这里只需：i18n.hero[1101].heroName

local i18n = {}

-- 多语言的文件夹
local dirs = {
    [kLanguageEnglish] = "us",
    [kLanguageRussian] = "ru",
    [kLanguageGerman] = "de",
    [kLanguageFrench] = "fr",
    [kLanguageSpanish] = "es",
    [kLanguagePortuguese] = "pt",
    [kLanguageChineseTW] = "tw",
    [kLanguageJapanese] = "jp",
    [kLanguageKorean] = "kr",
    [kLanguageTurkish] = "tr",
    [kLanguageChinese] = "cn",
    [kLanguageItalian] = "it",
    [kLanguageThai] = "th",
    --[kLanguageArabic] = "ar",
}
if not APP_CHANNEL or APP_CHANNEL == "" or APP_CHANNEL == "AMAZON" then
    dirs[kLanguageMalay] = "ms"
    dirs[kLanguageVietnamese] = "vi"
end

-- 多语言化的具体的文件, config.strings.us下的文件都罗列出来
local files = {
    "global", "buff", "hero", "equip", "item", "help", "faq", "achievement", 
    "fort", "arena", "vipdes", "skill", "mail", "loadingtips", "dailytask",
    "guildskill","brave", "herotaskname","petskill","spkdrug", "itemgetways",
}

-- 当前语言
local current

-- 返回kLanguageEnglish, kLanguageChinese等，具体参见cocos2d-x的语言类型定义
function i18n.getCurrentLanguage()
    return current
end

-- 返回语言的文件夹, 参数language可为nil
function i18n.getLanguageShortName(language)
    language = language or current
    return dirs[language]
end

-- 初始化语言，规则如下：
-- 取存档中记录的语言项，有效则使用之；否则
-- 取系统语言，有对应的多语言字符串则使用之；否则
-- 使用默认英语
function i18n.init()
    local userdata = require "data.userdata"
    current = userdata.getInt(userdata.keys.language, -1)
    if isAmazon() then
    elseif isOnestore() then
    elseif isChannel() then
        current = kLanguageChinese
    end
    if current == -1 or dirs[current] == nil then
        current = CCApplication:sharedApplication():getCurrentLanguage()
        if dirs[current] == nil then
            current = kLanguageEnglish
        end
    end
    print("current language", current)
    for _, f in ipairs(files) do
        i18n[f] = require(string.format("config.strings.%s.%s", dirs[current], f))
    end
end

-- 切换语言，调用该函数会使字符串资源进行相应的切换
-- 参数为kLanguageEnglish, kLanguageChinese等，具体参见cocos2d-x的语言类型定义
function i18n.switchLanguage(language)
    if language == current or dirs[language] == nil then
        return
    end
    current = language
    local userdata = require "data.userdata"
    userdata.setInt(userdata.keys.language, language)
    print("current language", current)
    for _, f in ipairs(files) do
        i18n[f] = require(string.format("config.strings.%s.%s", dirs[language], f))
    end
end

-- 进行初始化
i18n.init()

return i18n
