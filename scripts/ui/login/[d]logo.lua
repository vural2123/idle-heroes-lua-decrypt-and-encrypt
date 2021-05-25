-- 启动logo界面

local ui = {}

require "common.const"
local view = require "common.view"

local function getVideoImgs()
    local imgs = {}
    for ii=1,52 do
        imgs[ii] = string.format("DHImages/DH_logo_%02d.png", ii)
    end
    imgs[#imgs+1] = "DHImages/glow.png"
    return imgs
end

local function loadImgs(imgs)
    local textureCache = CCTextureCache:sharedTextureCache()
    local spriteframeCache = CCSpriteFrameCache:sharedSpriteFrameCache()
    for ii=1,#imgs do
        local key = imgs[ii]
        if not spriteframeCache:spriteFrameByName(key) then
            local tex = textureCache:addImage(key)
            local size = tex:getContentSize()
            local rect = CCRect(0, 0, size.width, size.height)
            local frame = CCSpriteFrame:createWithTexture(tex, rect)
            spriteframeCache:addSpriteFrame(frame, key)
        end
    end
end

local function unLoadImgs(imgs)
    local textureCache = CCTextureCache:sharedTextureCache()
    local spriteframeCache = CCSpriteFrameCache:sharedSpriteFrameCache()
    for ii=1,#imgs do
        local key = imgs[ii]
        local tex = textureCache:textureForKey(key)
        if tex then
            spriteframeCache:removeSpriteFramesFromTexture(tex)
            textureCache:removeTextureForKey(key)
        end
    end
end

local function createSpine(key)
    local cache = DHSkeletonDataCache:getInstance()
    if not cache:getSkeletonData(key) then
        cache:loadSkeletonData(key, key)
    end
    local anim = DHSkeletonAnimation:createWithKey(key)
    anim:scheduleUpdateLua()
    return anim
end

local function unloadSpine(key)
    local cache = DHSkeletonDataCache:getInstance()
    cache:removeSkeletonData(key)
end

function ui.createVideo()
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, 255))
    layer:addChild(darkbg)

    local logo_audio = "music/logo.mp3"
    local engine = SimpleAudioEngine:sharedEngine()
    engine:preloadEffect(logo_audio)
    local imgs = getVideoImgs()
    loadImgs(imgs)

    local svideo = createSpine("DHImages/DH_Logo.json")
    svideo:setScale(view.yScale*576/1080)
    svideo:setPosition(CCPoint(view.midX, view.midY))
    layer:addChild(svideo)
    svideo:playAnimation("animation")
    local effectEnabled = CCUserDefault:sharedUserDefault():getStringForKey("aaMusicFX", "1")
    if effectEnabled and effectEnabled == "1" then
        engine:playEffect(logo_audio)
    end
    svideo:setCascadeOpacityEnabled(true)
    layer.animal = svideo

    return layer
end

function ui.create()
    local layer = CCLayer:create()
    
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(255, 255, 255, 255))
    layer:addChild(darkbg)

    local video = ui.createVideo()
    layer:addChild(video)

    local textureCache = CCTextureCache:sharedTextureCache()
    local spriteframeCache = CCSpriteFrameCache:sharedSpriteFrameCache()
    local prename = "images/login_logo"
    spriteframeCache:addSpriteFramesWithFile(prename..".plist")

    --local logo = CCSprite:createWithSpriteFrameName("login/login_logo.png")
    --logo:setRotation(-90)
    --logo:setScale(view.minScale)
    --logo:setPosition(view.physical.w * 0.5, view.physical.h * 0.5)
    --layer:addChild(logo, 2000)
	
    local arr = CCArray:create()

    if APP_CHANNEL and APP_CHANNEL == "ONESTORE" then
    elseif APP_CHANNEL and APP_CHANNEL == "AMAZON" then
    elseif APP_CHANNEL and APP_CHANNEL ~= "" then
        arr:addObject(CCCallFunc:create(function()
            local warning = CCSprite:createWithSpriteFrameName("login/login_warning_sentence.png")
            warning:setOpacity(0)
            warning:setScale(view.minScale)
            warning:setPosition(view.physical.w * 0.5, 65 * view.minScale)
            layer:addChild(warning, 2001)
            warning:runAction(CCSequence:createWithTwoActions(
                CCDelayTime:create(1.0),
                CCFadeIn:create(1.0)))
        end))
    elseif CCApplication:sharedApplication():getCurrentLanguage() == kLanguageChinese then
        arr:addObject(CCCallFunc:create(function()
            local warning = CCSprite:createWithSpriteFrameName("login/login_warning_sentence.png")
            warning:setOpacity(0)
            warning:setScale(view.minScale)
            warning:setPosition(view.physical.w * 0.5, 65 * view.minScale)
            layer:addChild(warning, 2001)
            warning:runAction(CCSequence:createWithTwoActions(
                CCDelayTime:create(1.0),
                CCFadeIn:create(1.0)))
        end))
    end

    arr:addObject(CCDelayTime:create(2.0))
    arr:addObject(CCCallFunc:create(function ()
        --加载lua文件，需要耗费很多时间
        require "common.func"
        require "config"
        require "framework.init"
        local img = require "res.img"

        local arr2 = CCArray:create()
        --arr2:addObject(CCDelayTime:create(1.0))
        arr2:addObject(CCCallFunc:create(function ( ... )
            -- 卸载video资源
            unloadSpine("DHImages/DH_Logo.json")
            unLoadImgs(getVideoImgs())
            -- 健康游戏忠告
            local tWarning = 0.0
            if APP_CHANNEL and APP_CHANNEL ~= "" then
                local sdkcfg = require"common.sdkcfg"
                if sdkcfg[APP_CHANNEL] and sdkcfg[APP_CHANNEL].fpage then
                    layer:addChild((require"ui.login.warning").create(), 3000)
                    tWarning = 3.0

                    video:runAction(createSequence({
                        CCDelayTime:create(0.1),
                        CCFadeOut:create(0.3),
                    }))
                end
            end
            --video.animal:runAction(CCFadeOut:create(2.0))
            --video.animal:runAction(createSequence({
            --    CCDelayTime:create(0.5),
            --    CCFadeOut:create(2.0),
            --}))
            
            schedule(layer, tWarning, function()
                local tex = textureCache:textureForKey(prename .. ".png")
                if tex then
                    spriteframeCache:removeSpriteFramesFromFile(prename .. ".plist")
                    textureCache:removeTextureForKey(prename .. ".png")
                end

                replaceScene(require("ui.login.home").create())
            end)
        end))

        layer:runAction(CCSequence:create(arr2))
    end))
    layer:runAction(CCSequence:create(arr))

    return layer
end

return ui
