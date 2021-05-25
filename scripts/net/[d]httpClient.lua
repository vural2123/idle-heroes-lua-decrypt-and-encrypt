local httpClient = {}

local cjson = json
local fileOpt = require "common.fileOpt"

--[[
params = {
    url,            -- 下载文件的链接
    method,         -- “GET” or “POST”
    out_filename,   -- 下载文件保存的路径  -- 放在外部逻辑
}
]]--
function httpClient.download(params, callback)
    local url = params.url
    local method = params.method or "GET"
    local out_filename = params.out_filename or ""

    local request = network.createHTTPRequest(
        function(event)
            local _request = event.request
            if event.name == "completed" then
                if _request:getResponseStatusCode() == 200 then
                    if callback then
                        callback({status=0, data=_request:getResponseData()})
                    end
                end
            end
        end,
        url,
        method
    )
    request:setTimeout(1000)
    request:start()
end

function httpClient.reportException(url, content)
    local request = network.createHTTPRequest(
        function(event)
        end,
        url,
        "POST"
    )
    request:addPOSTValue("data", content)
    request:setTimeout(1000)
    request:start()
end

local targetLgg = {
    [kLanguageEnglish] = "en",
    [kLanguageRussian] = "ru",
    [kLanguageGerman] = "de",
    [kLanguageFrench] = "fr",
    [kLanguageSpanish] = "es",
    [kLanguagePortuguese] = "pt",
    [kLanguageChineseTW] = "zh-TW",
    [kLanguageJapanese] = "ja",
    [kLanguageKorean] = "k0",
    [kLanguageTurkish] = "tr",
    [kLanguageChinese] = "zh-CN",
    [kLanguageItalian] = "it",
    [kLanguageThai] = "th",
}

function httpClient.trans(sentence, callback)
    local i18n = require "res.i18n"
    local curLgg = i18n.getCurrentLanguage()
    local key = "empty"
    local target = targetLgg[curLgg] or "en"
    local url = "https://www.googleapis.com/language/translate/v2?key="..key.."&target="..target.."&q="..string.urlencode(sentence)
    httpClient.download({url=url}, function( callbackData )
        if callbackData.status == 0 then
            local res = cjson.decode(callbackData.data)
            local translatedText = res.data.translations[1].translatedText
            if callback then
                callback(translatedText)
            end
        else
            --todo toast?
        end
    end)
end

return httpClient
