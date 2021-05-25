-- common used funcs

require "common.const"
local quickjson = json -- json encode和decode
local view = require "common.view"
local cfgbuff = require "config.buff"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local cfghero = require "config.hero"
local cfglimitgift = require "config.limitgift"
local helper = require "common.helper"

local director = CCDirector:sharedDirector()
local actionManager = director:getActionManager()
local scheduler = director:getScheduler()

function cclog(...)
    print(string.format(...))
end

function scalex(x)
    return x * view.minScale + view.minX
end

function scaley(y)
    return y * view.minScale + view.minY
end

function scalep(x, y)
    return ccp(scalex(x), scaley(y))
end

function floateq(a, b)
    return math.abs(a - b) < 0.000001
end

function between(n, min, max)
    return n >= min and n <= max
end

function op3(condition, value1, value2)
    if condition then
        return value1
    else
        return value2
    end
end

function degree(x, y)
    return math.atan2(y, x) * 57.29577951
end

function tablelen(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

function tablekeys(t)
    local keys = {}
    for k, v in pairs(t) do
        keys[#keys + 1] = k
    end
    return keys
end

function tablevalues(t)
    local values = {}
    for k, v in pairs(t) do
        values[#values + 1] = v
    end
    return values
end

function tablecp(t)
    local tt = {}
    for k,v in pairs(t) do
        if type(v) == "table" then
            tt[k] = tablecp(v)
        else
            tt[k] = v
        end
    end
    return tt
end

function tablePrint(t,name,tag)
    print("-"," ")
    name = name or "main"
    tag = tag or ""
    print("-",tag.."["..name.."]".."=")
    print("-",tag.."{")
    for k,v in pairs(t) do
        if type(v) == "table" then
            tablePrint(v,k,tag.."    ")
        elseif type(v) == "function" then
            print("-",tag..k.." = function")
        else
            print("-"..tag..k.." = ",v)
        end
    end
    print("-",tag.."}")
end

function arraycp(t)
    local rt = {}
    for _, e in ipairs(t) do
        rt[#rt+1] = e
    end
    return rt
end

-- only merge array
function arraymerge(...)
    local arg = {...}
    local tt = {}
    for _, t in ipairs(arg) do
        for _, v in ipairs(t) do
            tt[#tt+1] = v
        end
    end
    return tt
end

-- clear array
function arrayclear(t)
    for i, _ in ipairs(t) do
        t[i] = nil
    end
end

-- Modify array item by key 
function arrayModifyByKV(t, key1, value1, key2, value2)
    local len = #t
    local i = 1
    while i <= len do
        if t[i][key1] == value1 then
            t[i][key2] = value2
            break
        end
        i = i + 1
    end
end

-- del array item by key 
function arrayDelByKV(t, key, value)
    local len = #t
    local i = 1
    while i <= len do
        if t[i][key] == value then
            break
        end
        i = i + 1
    end
    if i<= len then
        table.remove(t, i)
    end
end

-- rm the element when func(e) return false
function arrayfilter(t, func)                                                                    
    local len = #t                                                                                     
    local i = 1                                                                                        
    while i <= len do                                                                                  
        if not func(t[i]) then                                                                         
            table.remove(t, i)                                                                         
            len = len - 1                                                                              
        else                                                                                           
            i = i + 1                                                                                  
        end                                                                                            
    end                                                                                                
end 

-- 数组arr是否包含元素e
function arraycontains(arr, e)
    if arr then
        for _, ee in ipairs(arr) do
            if ee == e then
                return true
            end
        end
    end
    return false
end

function arrayequal(a, b)
    if a and b and #a == #b then
        for i, _ in ipairs(a) do
            if a[i] ~= b[i] then
                return false
            end
        end
        return true
    end
    return false
end

-- 判断是否是第三方渠道包
function isChannel()
    if not APP_CHANNEL or APP_CHANNEL == "" then
        return false
    elseif APP_CHANNEL == "IAS" then
        return false
    end
    return true
end

function isAmazon()
    if not APP_CHANNEL or APP_CHANNEL == "" then
        return false
    elseif APP_CHANNEL == "AMAZON" then
        return true
    end
    return false
end

function isOnestore()
    if not APP_CHANNEL or APP_CHANNEL == "" then
        return false
    elseif APP_CHANNEL == "ONESTORE" then
        return true
    end
    return false
end

-- 判断字符串是不是以prefix开头
function string.beginwith(str, prefix)
    return #str >= #prefix and str:sub(1, #prefix) == prefix
end

-- 判断字符串是不是以suffix结尾
function string.endwith(str, suffix)
    return #str >= #suffix and str:sub(-#suffix, -1) == suffix 
end

-- 是不是合法的字符，非法字符目前仅包括emoji表情(在android下)
-- 参数是一个lua字符串，它代表一个utf8字符
function isValidChar(char)
    local utf8 = require "common.utf8"
    if CCApplication:sharedApplication():getTargetPlatform() ~= kTargetAndroid then
        -- 只有安卓下才考虑emoji
        return true
    end
    return not utf8.isEmoji(char)
end

-- 是否包含非法字符，参见isValidChar(char)
-- 参数str为一个lua字符串
function containsInvalidChar(str)
    local utf8 = require "common.utf8"
    local chars = utf8.chars(str)
    if chars == nil then
        return true
    end
    for _, char in ipairs(chars) do
        if not isValidChar(char) then
            return true
        end
    end
    return false
end

-- 将lua字符串str中的非法字符替换为*后返回新的字符串
-- 若不是有效的utf8字符串则直接返回str
function replaceInvalidChars(str)
    local utf8 = require "common.utf8"
    local chars = utf8.chars(str)
    if chars == nil then
        return str 
    end
    for i = 1, #chars do
        if not isValidChar(chars[i]) then
            chars[i] = "*"
        end
    end
    return table.concat(chars, "")
end

-- time2string 00:00:00 
function time2string(num)
    local h = math.floor(num/3600)
    local m = math.floor(num/60) - h * 60
    local s = math.ceil(num%60)
    return string.format("%02d:%02d:%02d",h,m,s)
end

-- 遮边，挡住由于分辨率适配留出来的黑边
local function addBorderForScene(scene)
    local dark1 = CCLayerColor:create(ccc4(0, 0, 0, 255))
    local dark2 = CCLayerColor:create(ccc4(0, 0, 0, 255))
    dark2:ignoreAnchorPointForPosition(false)
    dark2:setAnchorPoint(ccp(1, 1))
    dark2:setPosition(view.physical.w, view.physical.h)
    if floateq(view.minX, 0) then
        dark1:setContentSize(CCSize(view.physical.w, view.minY))
        dark2:setContentSize(CCSize(view.physical.w, view.minY))
    else
        dark1:setContentSize(CCSize(view.minX, view.physical.h))
        dark2:setContentSize(CCSize(view.minX, view.physical.h))
    end
    scene:addChild(dark1, 1000)
    scene:addChild(dark2, 1000)

    --local img = require "res.img"
    --local border1 = img.createLogin9Sprite(img.login.screen_border)
    --local border2 = img.createLogin9Sprite(img.login.screen_border)
    --border2:setPosition(view.physical.w, view.physical.h)
    --if floateq(view.minX, 0) then
    --    border1:setAnchorPoint(ccp(0, 0))
    --    border2:setAnchorPoint(ccp(0, 0))
    --    border1:setPreferredSize(CCSize(view.physical.w, math.ceil(view.minY)))
    --    border2:setPreferredSize(CCSize(view.physical.w, math.ceil(view.minY)))
    --    border2:setRotation(180)
    --else
    --    border1:setAnchorPoint(ccp(1, 0))
    --    border2:setAnchorPoint(ccp(1, 0))
    --    border1:setPreferredSize(CCSize(view.physical.h, math.ceil(view.minX)))
    --    border2:setPreferredSize(CCSize(view.physical.h, math.ceil(view.minX)))
    --    border1:setRotation(90)
    --    border2:setRotation(-90)
    --end
    --scene:addChild(border1, 1000)
    --scene:addChild(border2, 1000)

    local img = require "res.img"
    local border1 = img.createLoginSprite(img.login.screen_border)
    local border2 = img.createLoginSprite(img.login.screen_border)
    border1:setAnchorPoint(ccp(0.5, 1))
    border2:setAnchorPoint(ccp(0.5, 1))
    local size = border1:getContentSize()
    local w, h = size.width, size.height
    if floateq(view.minX, 0) then
        local s = math.max(view.minScale, view.minY/h)
        border1:setScaleX(view.physical.w/w)
        border2:setScaleX(view.physical.w/w)
        border1:setScaleY(s)
        border2:setScaleY(s)
        border1:setPosition(view.midX, view.minY)
        border2:setPosition(view.midX, view.maxY)
        border2:setRotation(180)
    else
        local s = math.max(view.minScale, view.minX/h)
        border1:setScaleX(view.physical.h/w)
        border2:setScaleX(view.physical.h/w)
        border1:setScaleY(s)
        border2:setScaleY(s)
        border1:setPosition(view.minX, view.midY)
        border2:setPosition(view.maxX, view.midY)
        border1:setRotation(90)
        border2:setRotation(-90)
    end
    scene:addChild(border1, 200000)
    scene:addChild(border2, 200000)
end

local function addResumeBtn(scene)
    local is_resume = director:getRunningScene():getChildByTag(TAG_RESUME_BTN)
    if is_resume then return end
    local img = require "res.img"
    local json = require "res.json"
    local layer = CCLayer:create()
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)

    local textureCache = CCTextureCache:sharedTextureCache()
    local spriteframeCache = CCSpriteFrameCache:sharedSpriteFrameCache()
    local prename = "images/ui_no_compress"
    spriteframeCache:addSpriteFramesWithFile(prename..".plist")

    local btn_resume0 = CCSprite:createWithSpriteFrameName("ui/btn_resume.png")
    local btn_resume = CCMenuItemSprite:create(btn_resume0, nil)
    btn_resume:setScale(view.minScale)
    btn_resume:setPosition(CCPoint(view.midX, view.midY))
    local btn_resume_menu = CCMenu:createWithItem(btn_resume)
    btn_resume_menu:setPosition(CCPoint(0, 0))
    layer:addChild(btn_resume_menu)
    local function backEvent()
        layer:removeFromParentAndCleanup(true)
        resumeSchedulerAndActions(scene)
        require("res.audio").resumeBackgroundMusic()
    end
    btn_resume:registerScriptTapHandler(function()
        backEvent()
    end)
    layer.resumeBtn = true
    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)
    addBackEvent(layer)
    function layer.onAndroidBack()
        backEvent()
    end
    layer:setTag(TAG_RESUME_BTN)
    scene:addChild(layer, 10000000000)
end

-- 游戏切回前台时，如果已断网则要进行重连，对这个事件进行监听
local function foregroundListener()
    local _disconnected = nil
    local NetClient = require "net.netClient"
    NetClient:registForegroundListener(function()
        NetClient:unregistForegroundListener()
        if not NetClient:isConnected() then
            _disconnected = true
            replaceScene(require("ui.login.update").create())
        end
    end)
    director:getRunningScene():runAction(CCSequence:createWithTwoActions(
        CCDelayTime:create(1),
        CCCallFunc:create(function()
            NetClient:unregistForegroundListener()
        end)
    ))
    --if _disconnected then return end
    --if not package.loaded["res.img"] then return end -- 库未加载
    --if require("data.tutorial").exists() then
    --    --认为有教程进行中
    --    return
    --end
    --if APP_CHANNEL and APP_CHANNEL ~= "" then return end
    --if device.platform == "android" then -- gp
    --    require("res.audio").pauseBackgroundMusic()
    --    addResumeBtn(director:getRunningScene())
    --end
end

local function backgroundListener()
    if not package.loaded["res.img"] then return end  -- 库未加载
    if require("data.tutorial").exists() then
        --认为有教程进行中
        return
    end
    if APP_CHANNEL and APP_CHANNEL ~= "" then return end
    if device.platform == "android" then -- gp
        pauseSchedulerAndActions(director:getRunningScene())
    end
end

-- 游戏切回前台时，如果已断网则要进行重连，对这个事件进行监听
local function addForegroundListner(scene)
    local nc = CCNotificationCenter:sharedNotificationCenter()
    nc:unregisterScriptObserver(director:getRunningScene(), "APP_ENTER_FOREGROUND_EVENT")
    nc:registerScriptObserver(scene, foregroundListener, "APP_ENTER_FOREGROUND_EVENT")
end

-- 游戏切到后台时，对这个事件进行监听
local function addBackgroundListner(scene)
    local nc = CCNotificationCenter:sharedNotificationCenter()
    nc:unregisterScriptObserver(director:getRunningScene(), "APP_ENTER_BACKGROUND_EVENT")
    nc:registerScriptObserver(scene, backgroundListener, "APP_ENTER_BACKGROUND_EVENT")
end

function replaceScene(layer)
    if layer == nil then
        return
    end

    helper.checkMemory()

    -- 构建新的scene
    local scene = CCScene:create()
    scene:addChild(layer)
    -- 分辨率适配的留下的黑边
    -- addBorderForScene(scene)
    -- app从后台切前台的监听
    addForegroundListner(scene)
    --addBackgroundListner(scene)
    -- 阻止旧的scene的用户输入
    local ban = CCLayer:create()
    ban:setTouchEnabled(true)
    ban:setTouchSwallowEnabled(true)
    director:getRunningScene():addChild(ban, 1000000)
    -- 替换成新的scene
    director:replaceScene(scene)

    local droidhangComponents = require("dhcomponents.DroidhangComponents")
    droidhangComponents:onSceneInit(scene)
end

function isNetAvailable()
    --return CCNetwork:isInternetConnectionAvailable()
    return true
end

function absscale(node)
    local n = node
    local s = 1
    while n do
        s = s * n:getScale()
        n = n:getParent()
    end
    return s
end

-- callback: timeout callback, can be nil
-- time: timeout duration, can be nil, default NET_TIMEOUT
function addWaitNet(callback, time)
    local scene = director:getRunningScene()
    local w = scene:getChildByTag(TAG_WAIT_NET)
    if not w then
        local waitnet = require "ui.waitnet"
        w = waitnet.create(callback, time)
        w:setTag(TAG_WAIT_NET)
        scene:addChild(w, 1000000)
    end
    return w
end

function delWaitNet()
    local scene = director:getRunningScene()
    local w = scene:getChildByTag(TAG_WAIT_NET)
    if w then
        scene:removeChild(w, true)
    end
end

function showToast(text)
    local toast = require "ui.toast"
    local t = toast.create(text)
    director:getRunningScene():addChild(t, 1000000)
end

-- 装备比较函数
function compareEquip(a, b)
    -- 已穿戴的排在前面
    if a.owner and not b.owner then
        return true
    elseif not a.owner and b.owner then
        return false
    end
	
	local acomp, bcomp = cfgequip[a.id].sortShow or 0, cfgequip[b.id].sortShow or 0
	return bcomp < acomp

    --[[-- 品质高的排在前面
    local qlt1, qlt2 = cfgequip[a.id].qlt, cfgequip[b.id].qlt
    if qlt1 > qlt2 then
        return true
    elseif qlt1 < qlt2 then
        return false
    end

    -- 星级高的排在前面
    local star1, star2 = cfgequip[a.id].star, cfgequip[b.id].star
    if star1 > star2 then
        return true
    elseif star1 < star2 then
        return false
    end

    -- 穿戴部位小的排在前面
    local pos1, pos2 = cfgequip[a.id].pos, cfgequip[b.id].pos
    if pos1 < pos2 then
        return true
    elseif pos1 > pos2 then
        return false
    end

    -- id高的排在前面
    return a.id > b.id--]]
end

function compareEquipReverse(a, b)
	return compareEquip(b, a)
end

-- 是不是万能碎片
function isUniversalPiece(id)
    return id == ITEM_ID_PIECE_Q5 or id == ITEM_ID_PIECE_Q4 or id == ITEM_ID_PIECE_Q3 or id == ITEM_ID_EXQ_LIGHT_Q5 or id == ITEM_ID_EXQ_DARK_Q5 or id == ITEM_ID_EXQ_Q5
           or between(id - ITEM_ID_PIECE_GROUP_Q5, 1, 10)
           or between(id - ITEM_ID_PIECE_GROUP_Q4, 1, 10)
           or between(id - ITEM_ID_PIECE_GROUP_Q3, 1, 10)
end

-- 详细信息
function getHeroDetailInfo(id)
    local universal, qlt, group, icon
    if id == HERO_ID_ANY_Q3 then
        universal, qlt = true, 3
    elseif id == HERO_ID_ANY_Q4 then
        universal, qlt = true, 4
    elseif id == HERO_ID_ANY_Q5 then
        universal, qlt = true, 5
    elseif id == HERO_ID_EXQ_Q5 then
        universal, qlt, icon = true, 5, ICON_ID_HERO_EXQ_Q5
    elseif id == HERO_ID_EXQ_LIGHT_Q5 then
        universal, qlt, icon = true, 5, ICON_ID_HERO_EXQ_LIGHT_AND_DARK_Q5
    elseif id == HERO_ID_EXQ_DARK_Q5 then
        universal, qlt, icon = true, 5, ICON_ID_HERO_EXQ_LIGHT_AND_DARK_Q5
    elseif id == HERO_ID_ANY_Q6 then
        universal, qlt = true, 6
    elseif id % 100 == 99 then
        universal, qlt, group = true, math.floor(id/1000), math.floor((id%1000)/100)
    else
        universal, qlt, group, icon = false, cfghero[id].qlt, cfghero[id].group, cfghero[id].heroCard
    end
    if universal and not icon then
        if qlt == 3 then icon = ICON_ID_HERO_Q3
        elseif qlt == 4 then icon = ICON_ID_HERO_Q4
        elseif qlt == 5 then icon = ICON_ID_HERO_Q5
        elseif qlt == 6 then icon = ICON_ID_HERO_Q6 
        elseif qlt == 9 then icon = ICON_ID_HERO_Q6 
        elseif qlt == 10 then icon = ICON_ID_HERO_Q6 end
    end
    return { universal = universal, qlt = qlt, group = group, icon = icon }
end

-- 获取英雄皮肤，如果没有返回nil
-- visit: true 查看隐藏皮肤
function getHeroSkin(hid, visit)
    local herosdata = require "data.heros"
    local hero = herosdata.find(hid)
    if not hero or not hero.equips then return nil end
    if visit == nil then
        if hero.visit == true then return nil end
    end
    for ii=1,#hero.equips do
        if cfgequip[hero.equips[ii]] and cfgequip[hero.equips[ii]].pos == 7 then
            return hero.equips[ii]
        end
    end
    return nil
end

-- 物品比较函数
function compareItem(a, b)
	local acomp, bcomp = cfgitem[a.id].sortShow or 0, cfgitem[b.id].sortShow or 0
	return bcomp < acomp

    -- quality
    --[[local quality1, quality2 = cfgitem[a.id].qlt, cfgitem[b.id].qlt
    if quality1 > quality2 then
        return true
    elseif quality1 < quality2 then
        return false
    end

    -- id
    return a.id > b.id--]]
end

-- 英雄碎片比较函数
function compareHeroPiece(a, b)
    --[[if cfgitem[a.id].type ~= cfgitem[b.id].type then
        return cfgitem[a.id].type > cfgitem[b.id].type
    end

    if cfgitem[a.id].type == ITEM_KIND_TREASURE_PIECE then
        local quality1, quality2 = cfgitem[a.id].qlt, cfgitem[b.id].qlt
        if quality1 > quality2 then
            return true
        elseif quality1 < quality2 then
            return false
        end
        return a.id < b.id
    end

    -- 万能碎片始终放前面
    local isUPiece1 = isUniversalPiece(a.id)
    local isUPiece2 = isUniversalPiece(b.id)
    if isUPiece1 and not isUPiece2 then
        return true
    elseif not isUPiece1 and isUPiece2 then
        return false
    elseif isUPiece1 and isUPiece2 then
        local quality1, quality2 = cfgitem[a.id].qlt, cfgitem[b.id].qlt
        if quality1 > quality2 then
            return true
        elseif quality1 < quality2 then
            return false
        end
        return a.id < b.id
    end

    -- 普通碎片能召唤的排前面
    local summonable1 = (a.num / cfgitem[a.id].heroCost.count) >= 1
    local summonable2 = (b.num / cfgitem[b.id].heroCost.count) >= 1
    if summonable1 and not summonable2 then
        return true
    elseif not summonable1 and summonable2 then
        return false
    end--]]

    -- 其他就按物品排序
    return compareItem(a, b)
end

-- 卷轴碎片合成
function compareScrollPiece(a, b)
    -- 能合成的排前面
    --[[local summonable1 = (a.num / cfgitem[a.id].itemCost.count) >= 1
    local summonable2 = (b.num / cfgitem[b.id].itemCost.count) >= 1
    if summonable1 and not summonable2 then
        return true
    elseif not summonable1 and summonable2 then
        return false
    end--]]

    -- 其他就按物品排序
    return compareItem(a, b)
end

-- 英雄比较函数
function compareHero(a, b)
    -- 品质高的排在前面
    local locka = ((a.flag or 0) / 2) % 2
    local lockb = ((b.flag or 0) / 2) % 2
    if locka > lockb then
        return true
    elseif lockb > locka then
        return false
    end
    local quality1, quality2 = cfghero[a.id].maxStar, cfghero[b.id].maxStar
    if quality1 > quality2 then
        return true
    elseif quality1 < quality2 then
        return false
    end

    -- 星级高的排在前面
    if a.star > b.star then
        return true
    elseif a.star < b.star then
        return false
    end

    -- 等级高的排在前面
    if a.lv > b.lv then
        return true
    elseif a.lv < b.lv then
        return false
    end

    -- id高的排在前面
    if a.id > b.id then
        return true
    elseif a.id < b.id then
        return false
    end

    -- hid小的排在前面
    return a.hid < b.hid
end

-- _list 超出200部分只加载等级大于1的
function herolistless(_list, whitelist)
    --if true then return _list end
    whitelist = whitelist or {}
    if not _list or #_list <= 200 then
        return _list
    end
    local count = 0
    local tlist = {}
    for ii=1,#_list do
        if count > 200 then
            if _list[ii].lv > 1 then
                tlist[#tlist+1] = _list[ii]
            else
                for jj=1,#whitelist do
                    if _list[ii].hid and _list[ii].hid == whitelist[jj] then
                        tlist[#tlist+1] = _list[ii]
                        break
                    end
                end
            end
        else
            tlist[#tlist+1] = _list[ii]
        end
        count = count + 1
    end
    return tlist
end

function tbl2string(obj, prefix)
    prefix = prefix or "|"
    for k,v in pairs(obj) do
        if type(v) == "table" then
            print(prefix .. ">" ..  k .. ": table")
            local tmp_prefix = prefix .. ">" .. k
            tbl2string(v, tmp_prefix)
        end
        if type(v) ~= "function" and type(v) ~= "table" and type(v) ~= "userdata" then
            print(prefix .. ">" .. k .. ":" .. tostring(v))
        end
    end
end

if HHUtils:isCryptoEnabled() then
    tbl2string = function(...)
    end
    print = function(...)
    end
end

function getBundleId()
    local gname = require("ui.login.update").getPackageName()
    gname = gname or ""
    return "gameAD_" .. gname
end

function getEnvInfo()
    local info = {}
    info["platform"] = device.platform
    info["bundle_id"] = getBundleId()
    info["app_version"] = VERSION_CODE
    info["locale_language"] = CCApplication:sharedApplication():getCurrentLanguage()
    if APP_CHANNEL and APP_CHANNEL ~= "" then
        local devInfoStr = HHUtils:getDeviceInfo()
        local cjson = json
        local devInfo = cjson.decode(devInfoStr)
        if devInfo then
            info["os_version"] = devInfo["osversion"]
            --info["network_type"] = devInfo["networkType"]
            info["network_type"] =  CCNetwork:getInternetConnectionStatus()
            info["device_name"] = devInfo["model"]
        end
    end
    return info
end

function getDIDS()
    local ids = {}
    ids["idfa"] = HHUtils:getAdvertisingId()
    ids["keychain"] = HHUtils:getUniqKC()
    ids["idfv"] = HHUtils:getUniqFv()
    ids["appsflyer_id"] = HHUtils:getAppsFlyerId()
    if APP_CHANNEL and APP_CHANNEL ~= "" then
        local devInfoStr = HHUtils:getDeviceInfo()
        local cjson = json
        local devInfo = cjson.decode(devInfoStr)
        if devInfo then
            ids["device_id"] = devInfo["deviceId"]
            ids["android_id"] = devInfo["androidid"]
        end
    end
    return ids
end

function reportInstall() end

-- Only use this in debug, because there is memory leak in fetchPoints()
-- container: will be the parent of CCDrawNode
-- n: a CCNode, draw boundingBox for n
-- borderColor: ccc4f
function drawBoundingbox(container, n, borderColor)
    borderColor = borderColor or ccc4f(0, 1, 0, 1)
    local dn = CCDrawNode:create()
    local fillColor = ccc4f(0, 1, 0, 0)
    local x0 = n:boundingBox():getMinX()
    local x1 = n:boundingBox():getMaxX()
    local y0 = n:boundingBox():getMinY()
    local y1 = n:boundingBox():getMaxY()
    local verts = {
        container:convertToNodeSpace(n:getParent():convertToWorldSpace(CCPoint(x0,y0))),
        container:convertToNodeSpace(n:getParent():convertToWorldSpace(CCPoint(x1,y0))),
        container:convertToNodeSpace(n:getParent():convertToWorldSpace(CCPoint(x1,y1))),
        container:convertToNodeSpace(n:getParent():convertToWorldSpace(CCPoint(x0,y1))),
    }
    local points = {
        { verts[1].x, verts[1].y },
        { verts[2].x, verts[2].y },
        { verts[3].x, verts[3].y },
        { verts[4].x, verts[4].y },
    }
    dn:drawPolygon(points, { fillColor = fillColor, borderColor = borderColor, borderWidth = 1 })
    container:addChild(dn, 1000)
end

function pauseSchedulerAndActions(node)
    actionManager:pauseTarget(node)
    scheduler:pauseTarget(node)
    local children = node:getChildren()
    if children then
        for i = 0, children:count()-1 do
            local child = tolua.cast(children:objectAtIndex(i), "CCNode")
            pauseSchedulerAndActions(child)
        end
    end
end

function resumeSchedulerAndActions(node)
    actionManager:resumeTarget(node)
    scheduler:resumeTarget(node)
    local children = node:getChildren()
    if children then
        for i = 0, children:count()-1 do
            local child = tolua.cast(children:objectAtIndex(i), "CCNode")
            resumeSchedulerAndActions(child)
        end
    end
end

-- node: a CCNode
-- shader: SHADER_GRAY|SHADER_HIGHLIGHT (refer to SHADER_* in "common/const")
-- recursively: recursively setShader to its children
-- eg: setShader(n, SHADER_GRAY, true)
function setShader(node, shader, recursively)
    node:setShaderProgram(ShaderManager:getInstance():getShader(shader))
    if recursively then
        local children = node:getChildren()
        if children then
            for i = 0, children:count()-1 do
                local child = tolua.cast(children:objectAtIndex(i), "CCNode")
                setShader(child, shader, true)
            end
        end
    end
end

function clearShader(node, recursively)
    local p = CCShaderCache:sharedShaderCache():programForKey("ShaderPositionTextureColor")
    node:setShaderProgram(p)
    if recursively then
        local children = node:getChildren()
        if children then
            for i = 0, children:count()-1 do
                local child = tolua.cast(children:objectAtIndex(i), "CCNode")
                clearShader(child, true)
            end
        end
    end
end

-- reverse buff
-- rbuff[name] = id
local rbuff = {}
for k, v in pairs(cfgbuff) do
    rbuff[v.name] = k
end

function buffname2id(name)
    return rbuff[name]
end

function buffString(name, value)
    local id = buffname2id(name)
    local i18n = require "res.i18n" 
    local nameString = i18n.buff[id].nameString
    local valueString    
    if value then
        local factor = cfgbuff[id].factor
        if factor then
            value = value / factor
        end
        if cfgbuff[id].showPercent then
            valueString = string.format("%.1f%%", value*100)
        else
            valueString = tostring(math.floor(value))
        end
    end
    return nameString, valueString
end 

function energizeString(name, value)
    local id = buffname2id(name)
    local i18n = require "res.i18n" 
    local nameString = i18n.buff[id].nameString
    local valueString    
    if value then
        local factor = cfgbuff[id].factor
        if factor then
            value = value / factor
        end
        if cfgbuff[id].showPercent then
            valueString = string.format("%.1f%%", value*100)
        else
            valueString = tostring(math.floor(value))
        end
    end
    return nameString, valueString
end

function hid2id(hid)
    local herosdata = require "data.heros"
    local hero = herosdata.find(hid)
    if hero then
        return hero.id
    end
end

function findEnchantConfig(position, lv, quality)
    if quality == ITEM_QUALITY_WHITE then
        return nil
    end
    local cfgenchant = require "config.enchant"
    for _, cfg in pairs(cfgenchant) do
        if position == cfg.position and lv >= cfg.lvRange[1]
            and lv <= cfg.lvRange[2] and quality == cfg.quality then
            return cfg 
        end
    end
end

-- align labels vertically
-- labels = {
--     {
--         label = lbl.create(),
--         str = "My NB suit",
--         anchor = ccp(0, 1),
--         x = 20,
--         offsetY = 10, 
--     },
--     {
--     },
--     ...
-- }
-- return the container and current y (note: y < 0)
-- container, currentY can be nil
function alignLabels(labels, container, currentY)
    container = container or CCLayer:create()
    currentY = currentY or 0
    for i, l in ipairs(labels) do
        local label = l.label
        if l.str then
            label:setString(l.str)
        end
        if l.anchor then
            label:setAnchorPoint(l.anchor)
        else
            label:setAnchorPoint(ccp(0, 1))
        end
        label:setPosition(l.x, currentY-l.offsetY)
        container:addChild(label)
        currentY = label:boundingBox():getMinY()
    end
    return container, currentY
end

function createProgressBar(sprite)
    local p = CCProgressTimer:create(sprite)
    p:setType(kCCProgressTimerTypeBar)
    p:setMidpoint(ccp(0, 0))
    p:setBarChangeRate(ccp(1, 0))
    return p
end

function createProgressVerticalBar(sprite)
    local p = CCProgressTimer:create(sprite)
    p:setType(kCCProgressTimerTypeBar)
    p:setMidpoint(ccp(0, 0))
    p:setBarChangeRate(ccp(0, 1))
    return p
end

-- actions: a table of CCAction
function createSequence(actions)
    local arr = CCArray:create()
    for _, o in ipairs(actions) do
        arr:addObject(o)
    end
    return CCSequence:create(arr)
end

function popReconnectDialog(text, handler)
    local i18n = require "res.i18n"
    local scene = director:getRunningScene()
    local old = scene:getChildByTag(TAG_RECONNECT_DIALOG)
    if old then
        return old 
    end
    text = text or i18n.global.error_network_timeout.string
    local params = {
        title = "",
        body = text,
        btn_count = 1,
        btn_text = {
            [1] = i18n.global.dialog_button_confirm.string,
        },
        selected_btn = 0,
        callback = function(data)
            scene:removeChildByTag(TAG_RECONNECT_DIALOG)
            if data.selected_btn == 1 then
                data.button:setEnabled(false)
                if handler then
                    handler()
                else
                    replaceScene(require("ui.login.update").create())
                end
            end
        end,
    }
    local dialog = require "ui.dialog"
    local d = dialog.create(params)
    scene:addChild(d, 10000000, TAG_RECONNECT_DIALOG)

    function d.onAndroidBack()
        -- disable android back
    end

    return d
end

function getMilliSecond()
    local socket = require "socket"
    return math.floor(socket.gettime() * 1000)
end

function isToday(t)
    return os.date("%x", os.time()) == os.date("%x", t) 
end

-- 获取、设置 竞技场跳过战斗
function arenaSkip(val)
    local userdata = require "data.userdata"
    if val and val == "enable" then
        userdata.setString(userdata.keys.arena_skip, val)
    elseif val and val == "disable" then
        userdata.setString(userdata.keys.arena_skip, val)
    elseif val then  -- wrong call, nothing todo
    else
        return userdata.getString(userdata.keys.arena_skip, "disable")
    end
end

-- 返回version, userVersion, codeVersion, compare
function getVersionDetail()
    require "version"
    local userdata = require "data.userdata"
    local userVersion = string.trim(userdata.getString(userdata.keys.version, ""))
    local codeVersion = VERSION_CODE
    local uv = string.split(userVersion, ".")
    local cv = string.split(codeVersion, ".")
    if #uv == 3 then
        local u1, u2, u3 = tonumber(uv[1], 10), tonumber(uv[2], 10), tonumber(uv[3], 10)
        local c1, c2, c3 = tonumber(cv[1], 10), tonumber(cv[2], 10), tonumber(cv[3], 10)
        if u1 and u2 and u3 then
            if u1 > c1 or (u1 == c1 and (u2 > c2 or (u2 == c2 and u3 > c3))) then
                return userVersion, userVersion, codeVersion, 1
            elseif u1 < c1 or (u1 == c1 and (u2 < c2 or (u2 == c2 and u3 < c3))) then
                return codeVersion, userVersion, codeVersion, -1
            end
        end
    end
    return codeVersion, codeVersion, codeVersion, 0
end

function getVersion()
    local v = getVersionDetail()
    return v
end

function compareVersion(version1, version2)
    local a = string.split(string.trim(version1), ".")
    local b = string.split(string.trim(version2), ".")
    assert(#a == 3 and #b == 3)
    local a1, a2, a3 = tonumber(a[1], 10), tonumber(a[2], 10), tonumber(a[3], 10)
    local b1, b2, b3 = tonumber(b[1], 10), tonumber(b[2], 10), tonumber(b[3], 10)
    assert(a1 and a2 and a3 and b1 and b2 and b3)
    if a1 > b1 or (a1 == b1 and (a2 > b2 or (a2 == b2 and a3 > b3))) then
        return 1
    elseif a1 < b1 or (a1 == b1 and (a2 < b2 or (a2 == b2 and a3 < b3))) then
        return -1
    end
    return 0
end

function isEmail(str)
    if not str then return false end
    if str == "" then return false end
    --p1,p2 = string.find(str, "[a-zA-Z0-9%._]+@[a-zA-Z0-9]+%.[a-zA-Z0-9]+")
    p1,p2 = string.find(str, "[a-zA-Z0-9%._-]+@[a-zA-Z0-9_-]+%.[a-zA-Z0-9_-%.]+")
    --print("p1,p2,len:",p1,p2, string.len(str))
    if p1 == 1 and p2 == string.len(str) then
        return true
    end
    return false
end

-- 创建一个输入框背景图带lable
function createEditLbl(w, h)
    local img = require "res.img"
    local lbl = require "res.lbl"
    local edit0 = img.createLogin9Sprite(img.login.input_border)
    edit0:setPreferredSize(CCSizeMake(w, h))
    local lbl0 = lbl.createFont1(20, "", ccc3(0x94, 0x62, 0x42))
    lbl0:setPosition(CCPoint(edit0:getContentSize().width/2, edit0:getContentSize().height/2))
    edit0:addChild(lbl0)
    edit0.lbl = lbl0
    return edit0
end

-- 在一个精灵上添加红点
function addRedDot(obj, params, scale)
    if not obj or tolua.isnull(obj) then return end
    local o_dot = obj:getChildByTag(TAG_RED_DOT)
    if not o_dot then
        if not params then params = {} end
        params.ax = params.ax or 0.5
        params.ay = params.ay or 0.5
        params.px = params.px or obj:getContentSize().width
        params.py = params.py or obj:getContentSize().height
        local img = require "res.img"
        local dot = img.createUISprite(img.ui.main_red_dot)
        if scale then
            dot:setScale(scale)
        end
        dot:setAnchorPoint(CCPoint(params.ax, params.ay))
        dot:setPosition(CCPoint(params.px, params.py))
        obj:addChild(dot, 1000000, TAG_RED_DOT)
        dot:setVisible(true)
    else
        o_dot:setVisible(true)
    end
end

function delRedDot(obj)
    if not obj or tolua.isnull(obj) then return end
    local o_dot = obj:getChildByTag(TAG_RED_DOT)
    if not o_dot then
        return
    else
        o_dot:setVisible(false)
    end
end

function gSubmitRoleData(params)
    local sdkcfg = require"common.sdkcfg"
    if sdkcfg[APP_CHANNEL] and sdkcfg[APP_CHANNEL].submitRoleData then
        local player = require "data.player"
        local userdata = require "data.userdata"
        params.roleId = player.uid or "empty"
        params.roleName = player.name or "empty"
        params.roleLevel = params.roleLevel or 1
        params.roleCTime = userdata.createTs or 0
        params.zoneId = player.sid
        params.zoneName = "S" .. player.sid
        sdkcfg[APP_CHANNEL].submitRoleData(params)
    end
end

-- 玩家加经验使等级提升时，调用此函数
-- pre_level：添加经验前玩家等级
-- level：添加经验后玩家等级
function showLevelUp(pre_level, level, callback)
    local scene = director:getRunningScene()
    local o = scene:getChildByTag(TAG_LEVEL_UP)
    if o then
        scene:removeChildByTag(TAG_LEVEL_UP)
    end
    local leveluplayer = require "ui.levelUplayer"
    o = leveluplayer.create(pre_level, level, callback)
    o:setTag(TAG_LEVEL_UP)
    scene:addChild(o, 100000)
    
    -- track level
    if HHUtils:isReleaseMode() and (not APP_CHANNEL or APP_CHANNEL == "") then
        for _, lv in ipairs({7, 10, 12, 14, 15, 16, 19, 25, 32, 40}) do
            if pre_level < lv and lv <= level then
                HHUtils:trackDHAppsFlyer("level_" .. lv, "1", "1")
            end
        end
    elseif isAmazon() then
        for _, lv in ipairs({7, 10, 12, 14, 15, 16, 19, 25, 32, 40}) do
            if pre_level < lv and lv <= level then
                HHUtils:trackDHAppsFlyer("level_" .. lv, "1", "1")
            end
        end
    end
    --if HHUtils.trackLevelAppsFlyer and HHUtils:isReleaseMode() then
    --    for _, lv in ipairs({7, 10, 12, 14, 15, 16, 19, 25}) do
    --        if pre_level < lv and lv <= level then
    --            HHUtils:trackLevelAppsFlyer(lv)
    --        end
    --    end
    --end

    gSubmitRoleData({roleLevel=level, stype="levelUp"})

    return o
end

-- 达到某种条件后使得开放某项功能
-- which：参照unlockFunclayer里定义
function showUnlockFunc(which, callback)
    local scene = director:getRunningScene()
    local o = scene:getChildByTag(TAG_UNLOCK_FUNC)
    if not o then
        local unlockFunclayer = require "ui.unlockFunclayer"
        o = unlockFunclayer.create(which, callback)
        o:setTag(TAG_UNLOCK_FUNC)
        scene:addChild(o, 100000)
    end
    return o
end

-- 检查是否触发玩家等级提升
-- exp：为当次添加的玩家经验
function checkLevelUp1(bagdata)
    if not bagdata or not bagdata.items then return 0 end
    local iobj = bagdata.items.find(ITEM_ID_PLAYER_EXP)
    if not iobj then iobj = { num = 0 } end
    return iobj.num
end
function checkLevelUp2(bagdata, oldxp)
    local newxp = checkLevelUp1(bagdata)
    if newxp > oldxp then checkLevelUp(newxp - oldxp) end
end
function checkLevelUp(exp, callback)
    local player = require "data.player"
    local pre_level = player.lv(player.exp() - exp)
    local level = player.lv()
    if level > pre_level then
        print("culevel = ", level)
        showLevelUp(pre_level, level, callback)
        local activitylimitData = require "data.activitylimit"
        local level24 = cfglimitgift[activitylimitData.IDS.GRADE_24.ID].parameter
        local level32 = cfglimitgift[activitylimitData.IDS.GRADE_32.ID].parameter
        local level48 = cfglimitgift[activitylimitData.IDS.GRADE_48.ID].parameter
        local level58 = cfglimitgift[activitylimitData.IDS.GRADE_58.ID].parameter
        local level78 = cfglimitgift[activitylimitData.IDS.GRADE_78.ID].parameter
        if pre_level < level24  then
            if level >= level24 and level < level32 then
                activitylimitData.GradeNotice(level24)
            end
            if level >= level32 and level < level48 then
                activitylimitData.GradeNotice(level24)
                activitylimitData.GradeNotice(level32)
            end
            if level >= level48 and level < level58 then
                activitylimitData.GradeNotice(level24)
                activitylimitData.GradeNotice(level32)
                activitylimitData.GradeNotice(level48)
            end
            if level >= level58 and level < level78 then
                activitylimitData.GradeNotice(level24)
                activitylimitData.GradeNotice(level32)
                activitylimitData.GradeNotice(level48)
                activitylimitData.GradeNotice(level58)
            end
            if level >= level78 then
                activitylimitData.GradeNotice(level24)
                activitylimitData.GradeNotice(level32)
                activitylimitData.GradeNotice(level48)
                activitylimitData.GradeNotice(level58)
                activitylimitData.GradeNotice(level78)
            end
        end
        if pre_level >= level24 and pre_level < level32 then
            if level >= level32 and level < level48 then
                activitylimitData.GradeNotice(level32)
            end
            if level >= level48 and level < level58 then
                activitylimitData.GradeNotice(level32)
                activitylimitData.GradeNotice(level48)
            end
            if level >= level58 and level < level78 then
                activitylimitData.GradeNotice(level32)
                activitylimitData.GradeNotice(level48)
                activitylimitData.GradeNotice(level58)
            end
            if level >= level78 then
                activitylimitData.GradeNotice(level32)
                activitylimitData.GradeNotice(level48)
                activitylimitData.GradeNotice(level58)
                activitylimitData.GradeNotice(level78)
            end
        end
        if pre_level >= level32 and pre_level < level48 then
            if level >= level48 then
                activitylimitData.GradeNotice(level48)
            end
            if level >= level58 and level < level78 then
                activitylimitData.GradeNotice(level48)
                activitylimitData.GradeNotice(level58)
            end
            if level >= level78 then
                activitylimitData.GradeNotice(level48)
                activitylimitData.GradeNotice(level58)
                activitylimitData.GradeNotice(level78)
            end
        
        end
        if pre_level >= level48 and pre_level < level58 then
            if level >= level58 and level < level78 then
                activitylimitData.GradeNotice(level58)
            end
            if level >= level78 then
                activitylimitData.GradeNotice(level58)
                activitylimitData.GradeNotice(level78)
            end
        end
        if pre_level >= level58 and pre_level < level78 then
            if level >= level78 then
                activitylimitData.GradeNotice(level78)
            end 
        end
    end
end

function gotoAppStore(ver)
    delWaitNet()
    local i18n = require "res.i18n"
    local dialog = require "ui.dialog"
    local function process_dialog(data)
        if data.selected_btn == 1 then
            if APP_CHANNEL and APP_CHANNEL == "IAS" then
                local ver = ver
                if not ver then
                    local cv = string.split(VERSION_CODE, ".")
                    local c1, c2, c3 = tonumber(cv[1], 10), tonumber(cv[2], 10), tonumber(cv[3], 10)
                    ver = c1 .. "." .. (c2+1) .. ".0"
                end
                local URL_ADTT = "https://clifile.dhgames.cn/ad.addh.v" .. ver ..".apk"
                device.openURL(URL_ADTT)
            elseif APP_CHANNEL and APP_CHANNEL == "GAMES63" then
                local ver = ver
                if not ver then
                    local cv = string.split(VERSION_CODE, ".")
                    local c1, c2, c3 = tonumber(cv[1], 10), tonumber(cv[2], 10), tonumber(cv[3], 10)
                    ver = c1 .. "." .. (c2+1) .. ".0"
                end
                local URL_ADTT = "https://clifile.dhgames.cn/ad.games63.v" .. ver ..".apk"
                device.openURL(URL_ADTT)
            elseif isOnestore() then
                local URL_ONESTORE = "http://onesto.re/0000721940"
                device.openURL(URL_ONESTORE)
            elseif isChannel() then
            elseif device.platform == "android" then
                device.openURL(URL_GOOGLE_PLAY_ANDROID)
            elseif device.platform == "ios" then
                device.openURL(URL_APP_STORE_IOS)
            else
                device.openURL(URL_APP_STORE_IOS)
            end
        end
    end
    local dialog_params = {
        title = "",
        body = i18n.global.update_need_appstore.string,
        btn_count = 1,
        btn_color = {
            [1] = dialog.COLOR_GOLD,
        },
        btn_text = {
            [1] = i18n.global.dialog_button_confirm.string,
        },
        selected_btn = 0,
        callback = process_dialog,
    }
    local dialog_ins = dialog.create(dialog_params)
    local scene = director:getRunningScene()
    dialog_ins:setTag(dialog.TAG)
    scene:addChild(dialog_ins, 100000)
end

--[[
--  obj 被作用的节点，响应back按键事件
--  callback 按back按钮响应事件, 没有则响应remove自己
--]]
function addBackEvent(obj, callback)
    if obj._back_event then
        return
    end
    obj._back_event = true
    obj.lock_state = 1
    obj:setKeypadEnabled(true)
    obj:addNodeEventListener(cc.KEYPAD_EVENT, function(event)
        if event.key == "back" then
            local is_resume = director:getRunningScene():getChildByTag(TAG_RESUME_BTN)
            if is_resume and not obj.resumeBtn then return end
            if require("data.tutorial").exists() then
                --认为有教程进行中
                return
            end
            -- 有网络请求
            local scene = director:getRunningScene()
            local w = scene:getChildByTag(TAG_WAIT_NET)
            if w then
                return
            end
            if obj.lock_state > 0 then
                if callback then
                    callback()
                else
                    --obj:removeFromParentAndCleanup(true)
                    obj.onAndroidBack()
                end
            end
        end
    end)
    function obj.notifyParentLock()
        local parent_obj = obj:getParent()
        if (not parent_obj) or (not parent_obj._back_event) then
            return
        end
        parent_obj.lock_state = parent_obj.lock_state - 1
        parent_obj.notifyParentLock()
    end
    function obj.notifyParentUnlock()
        local parent_obj = obj:getParent()
        if (not parent_obj) or (not parent_obj._back_event) then
            return
        end
        parent_obj.lock_state = parent_obj.lock_state + 1
        parent_obj.notifyParentUnlock()
    end
end

-- 使能或禁止back按键
function setBackEventEnable(obj, _enable)
    obj:setKeypadEnabled(_enable)
end

-- 上报lua堆栈
local lastReportTime
local lastReportData
function reportException(title, detail)
    if isChannel() then return end
    if lastReportData == detail then return end
    lastReportData = detail
end

function reportRIpException()
    local NetClient = require "net.netClient"
    local r_ip = NetClient:getRIp()
    if not r_ip then return end
    local content = device.platform .. " cannot connect to ip " .. r_ip
    reportException(content, content)
end

-- schedule(node, seconds, func) 几秒后执行
-- schedule(node, func) 下一帧执行
function schedule(node, param1, param2)
    if type(param1) == "function" then
        node:runAction(CCCallFunc:create(param1))
    else
        node:runAction(createSequence({
            CCDelayTime:create(param1),
            CCCallFunc:create(param2),
        }))
    end
end

-- 暂时使按钮不能使用，1s后可以使用
function delayBtnEnable(btnObj)
    if not btnObj or tolua.isnull(btnObj) then
        return
    end
    btnObj:setEnabled(false)
    schedule(btnObj, 1, function()
        if tolua.isnull(btnObj) then return end
        btnObj:setEnabled(true)
    end)
end

function convertItemNum(num)
    if num >= 10000000 then
        return math.floor(num / 1000000) .. "M"
    elseif num >= 10000 then
        return math.floor(num / 1000) .. "K"
    else
        return tostring(num)
    end
end

-- 最大水晶星数
local maxJadeStars 
function isJadeUpgradable(id)
    if not maxJadeStars then
        maxJadeStars = {}
        for _, cfg in pairs(cfgequip) do
            if cfg.pos == EQUIP_POS_JADE 
                and (not maxJadeStars[cfg.qlt] or maxJadeStars[cfg.qlt] < cfg.star) then
                maxJadeStars[cfg.qlt] = cfg.star
            end
        end
    end
    return cfgequip[id].qlt < #maxJadeStars or cfgequip[id].star < maxJadeStars[#maxJadeStars]
end

function checkHeroLockStatus(hid)
    local userdata = require "data.userdata"
    local arenaData = require "data.arena"
    --local arena3v3Data = require "data.arena3v3"
    local arenaTL1v1Data = require "data.arenaTimelimit1v1"
    local guildData = require "data.guild"
    local guildwarData = require "data.guildwar"
    local trainData = require "data.trains"
    local hookData = require "data.hook"
    local herotaskData = require "data.heroTask"
    local herosData = require "data.heros"
    local i18n = require "res.i18n"

    local st = {
        isLocked = false,
        detail = {
            isHook = false,
            isDef = false,
            isTrain = false,
            isGuildWar = false,
            isGuildBoss = false,
            isHeroTask = false,
            isManualLocked = false,
        },
        message = ""
    }
 
    local _,hero = herosData.find(hid)
    if hero and hero.isLocked then
        st.isLocked = true
        st.detail.isManualLocked = true
    end
    
    for i=1,#trainData do
        if trainData[i].hid == hid then
            st.isLocked = true
            st.detail.isTrain = true
        end
    end

    local teams = guildwarData.getSelfTeams()
    for i=1,#teams do
        for j=1,#teams[i].team do
            if teams[i].team[j].hid == hid then
                st.isLocked = true
                st.detail.isGuildWar = true
            end
        end
    end

    if hookData.status ~= hookData.STATUS_NORMAL then
        local hooking = userdata.getSquadHook()
        for i=1,6 do
            if hid == hooking[i] then
                st.isLocked = true
                st.detail.isHook = true
            end
        end
    end

    local guildPreTeam = guildData.getBossTeam()
    for i=1,6 do
        if hid == guildPreTeam[i] then
            st.isLocked = true
            st.detail.isGuildBoss = true
        end
    end

    for i=1,#herotaskData do
        if herotaskData[i].hids then
            for j=1,#herotaskData[i].hids do
                if hid == herotaskData[i].hids[j] then
                    st.isLocked = true
                    st.detail.isHeroTask = true
                end
            end
        end
    end

    local campIds = userdata.getSquadCampId()
    local arenaDef1 = userdata.getSquadArenaDef(campIds[4])
    local arenaDef2 = userdata.getSquadArenaTLDef(campIds[6])

    for i=1, 6 do
        if hid == arenaDef1[i] then
            st.isLocked = true
            st.detail.isDef = true
        end

        if arenaTL1v1Data and arenaTL1v1Data.endtime then
            if arenaTL1v1Data.endtime > os.time() then
                if hid == arenaDef2[i] then
                    st.isLocked = true
                    st.detail.isDef = true
                end
            end
        end
    end

    if arena3v3Data and arena3v3Data.endtime then
        if arena3v3Data.endtime > os.time() then
            local team = arena3v3Data.getTeam()
            for i=1, 3 do
                for j=1, 6 do
                    if team[i][j] == hid then
                        st.isLocked = true
                        st.detail.isDef = true
                    end
                end
            end
        end
    end

    if st.detail.isDef then
        st.message = i18n.global.devour_in_arena.string
    elseif st.detail.isTrain then
        st.message = i18n.global.devour_in_train.string
    elseif st.detail.isGuildWar then
        st.message = i18n.global.devour_is_guildwar.string
    elseif st.detail.isGuildBoss then
        st.message = i18n.global.devour_on_guildboss.string
    elseif st.detail.isHeroTask then
        st.message = i18n.global.devour_hero_herotask.string
    elseif st.detail.isManualLocked then
        st.message = i18n.global.devour_is_locked.string
    elseif st.detail.isHook then
        st.message = i18n.global.devour_in_hook.string
    end
    
    return st
end

function conquset2items(data)
    local res = {}
    if data.items then
        for i, v in ipairs(data.items) do
            res[#res + 1] = {
                type = 1,
                id = v.id,
                num = v.num,
            }
        end
    end

    if data.equips then
        for i, v in ipairs(data.equips) do
            res[#res + 1] = {
                type = 2,
                id = v.id,
                num = v.num,
            }
        end
    end
    return res
end

-- 模拟按钮按下的动画， obj--按钮
function playAnimTouchBegin(obj, callback)
    local ani_scale_factor = obj._scale or 1.0
    local arr = CCArray:create()
    arr:addObject(CCScaleTo:create(4/60, 0.8*ani_scale_factor, 0.8*ani_scale_factor))
    arr:addObject(CCDelayTime:create(4/60))
    if callback then
        arr:addObject(CCCallFunc:create(function()
            callback()
        end))
    end
    obj:runAction(CCSequence:create(arr))
end

-- 模拟按钮释放的动画， obj--按钮
function playAnimTouchEnd(obj)
    local ani_scale_factor = obj._scale or 1.0
    local arr = CCArray:create()
    arr:addObject(CCScaleTo:create(3/60, 1.1*ani_scale_factor, 1.1*ani_scale_factor))
    arr:addObject(CCDelayTime:create(3/60))
    arr:addObject(CCScaleTo:create(2/60, 0.9*ani_scale_factor, 0.9*ani_scale_factor))
    arr:addObject(CCDelayTime:create(2/60))
    arr:addObject(CCScaleTo:create(3/60, 1.0*ani_scale_factor, 1.0*ani_scale_factor))
    arr:addObject(CCDelayTime:create(3/60))
    if callback then
        arr:addObject(CCCallFunc:create(function()
            callback()
        end))
    end
    obj:runAction(CCSequence:create(arr))
end

-- return coin, player_exp, hero_exp from a pbbagObj
function coinAndExp(pbbagObj, _remove)
    if not pbbagObj or not pbbagObj.items then return 0, 0, 0 end
    local coin, pexp, hexp = 0, 0, 0
    local tmp_items = pbbagObj.items
    for ii=#tmp_items, 1, -1 do
        local _remove_flag = false
        if tmp_items[ii].id == ITEM_ID_COIN then
            coin = tmp_items[ii].num
            _remove_flag = true
        elseif tmp_items[ii].id == ITEM_ID_PLAYER_EXP then
            pexp = tmp_items[ii].num
            _remove_flag = true
        elseif tmp_items[ii].id == ITEM_ID_HERO_EXP then
            hexp = tmp_items[ii].num
            _remove_flag = true
        end
        if _remove and _remove_flag then
            table.remove(tmp_items, ii)
        end
    end
    return coin, pexp, hexp
end

function getHeadBox(final_rank)
    local _tbl = { "headbox_1", 
                   "headbox_2",
                   "headbox_3", "headbox_3", 
                   "headbox_4", "headbox_4", "headbox_4", "headbox_4", 
                   "headbox_5", "headbox_5", "headbox_5", "headbox_5", "headbox_5", "headbox_5", "headbox_5", "headbox_5", "headbox_5", "headbox_5", }
    return _tbl[final_rank]
end

function addHeadBox(node, rank, zorder)
    zorder = zorder or 1
    local img = require "res.img"
    local rank_img = getHeadBox(rank)
    if not rank_img then return end
    local box = img.createUISprite(img.ui[rank_img])
    box:setPosition(CCPoint(node:getContentSize().width/2, node:getContentSize().height/2))
    node:addChild(box, zorder)
end

function processSpecialHead(items)
    if not items or #items <= 0 then return end
    local headdata = require "data.head"
    for ii=1,#items do
        local head_id = headdata.getHeadIdByItemId(items[ii].id)
        if head_id then
            if headdata[head_id] then
                headdata[head_id].isNew = true
            end
        end
        --if items[ii].id == ITEM_ID_SP_FIGHT then
        --    local headdata = require "data.head"
        --    if headdata[51] then
        --        headdata[51].isNew = true
        --    end
        --    return
        --end
    end
end

function getCampBuff(camp)
    if not camp or #camp < 6 then return -1 end
    local ids =  {}
    for ii=1,#camp do
        ids[ii] = camp[ii].heroId
    end
    return (require"ui.selecthero.campLayer").checkUpdateForHeroids(ids)
end

function num2KM(_num)
    if _num > 10000000 then
        _num = math.floor(_num/1000000) .. "M"
    elseif _num > 10000 then
        _num = math.floor(_num/1000) .. "K"
    else
        return math.floor(_num)
    end
    return _num
end

-- {[type, id, num]} -- > pbbag
function reward2Pbbag(reward)
    local _pbbag = {
        items = {},
        equips = {}
    }
    if not reward or #reward<= 0 then return _pbbag end
    for ii=1,#reward do
        local p_tbl = nil
        if reward[ii].type ==  1 then  -- item
            p_tbl = _pbbag.items
        elseif reward[ii].type ==  2 then  -- equip 
            p_tbl = _pbbag.equips
        end
        if p_tbl then
            local tmp_item = clone(reward[ii])
            tmp_item.num = tmp_item.num or tmp_item.count or 0
            p_tbl[#p_tbl+1] = tmp_item 
        end
    end
    return _pbbag
end

function pbbag2reward(_pbbag)
    local reward = {}
    if not _pbbag then return reward end
    if _pbbag.equips and #_pbbag.equips > 0 then
        local _tbl = _pbbag.equips
        for ii=1, #_tbl do
            reward[#reward+1] = {
                type = 2,
                id = _tbl[ii].id,
                num = _tbl[ii].num,
            }
        end
    end
    if _pbbag.items and #_pbbag.items > 0 then
        local _tbl = _pbbag.items
        for ii=1, #_tbl do
            reward[#reward+1] = {
                type = 1,
                id = _tbl[ii].id,
                num = _tbl[ii].num,
            }
        end
    end
    return reward
end

function disableObjAWhile(obj, seconds)
    seconds = seconds or 3
    if obj and not tolua.isnull(obj) then
        obj:runAction(createSequence({
            CCCallFunc:create(function()
                obj:setEnabled(false)
            end),
            CCDelayTime:create(seconds),
            CCCallFunc:create(function()
                obj:setEnabled(true)
            end),
        }))
    end
end

function getBanlist()
    local cfg
    if isOnestore() then
        cfg = require "config.krword"
    else
        cfg = require "config.word"
    end
    local list = {}
    for k,_ in pairs(cfg) do
        list[#list+1] = k
    end
    return list
end
local banlist = getBanlist()

function findBan(_w)
    local _l = banlist or {}
    for _idx in ipairs(_l) do
        if string.find(_w, _l[_idx]) then return true end
    end
    return false
end

function isBanWord(_w)
    if true or APP_CHANNEL and APP_CHANNEL ~= "" then
        _w = _w or ""
        _w = string.gsub(_w, "%s+", "")
        _w = string.trim(_w)
        if findBan(_w) then
            showToast("含有非法词汇")
            return true
        end
    end
    return false
end

function pushScene(layer)
    if layer == nil then
        return
    end
    -- 构建新的scene
    local scene = CCScene:create()
    scene:addChild(layer)
    
    -- 压入新的scene
    director:pushScene(scene)

    local droidhangComponents = require("dhcomponents.DroidhangComponents")
    droidhangComponents:onSceneInit(scene)
end

function popsScene()
    director:popScene()
end

-- 服务器名字
function getSidname(sid)
    if sid > 20000 then
        return "C" .. sid-20000
    end
    return "S" .. sid
end

-- 处理战宠站位问题，从本地拿数据
function processPetPosAtk1(video)
    -- atk
    if video and video.atk and video.atk.camp then
        for ii=1,#video.atk.camp do
            if video.atk.camp[ii].pos == 7 then
                local petid = video.atk.camp[ii].id
                local petData = require "data.pet"
                local petInfo = petData.getData(petid)
                video.atk.pet = petInfo
                video.atk.camp[ii] = nil
                break
            end
        end
    end
end

-- 处理战宠站位问题，从serer拿数据
function processPetPosAtk2(video)
    -- atk
    if video and video.atk and video.atk.camp then
        for ii=1,#video.atk.camp do
            if video.atk.camp[ii].pos == 7 then
                video.atk.pet = clone(video.atk.camp[ii])
                video.atk.camp[ii] = nil
                break
            end
        end
    end
end

-- 处理战宠站位问题，从serer拿数据
function processPetPosDef2(video)
    -- def
    if video and video.def and video.def.camp then
        for ii=1,#video.def.camp do
            if video.def.camp[ii].pos == 7 then
                video.def.pet = clone(video.def.camp[ii])
                video.def.camp[ii] = nil
                break
            end
        end
    end
end

-- 获取本地的目标语言
local targetLgg = {
    [kLanguageEnglish] = "en",
    [kLanguageRussian] = "ru",
    [kLanguageGerman] = "de",
    [kLanguageFrench] = "fr",
    [kLanguageSpanish] = "es",
    [kLanguagePortuguese] = "pt",
    [kLanguageChineseTW] = "zh-TW",
    [kLanguageJapanese] = "ja",
    [kLanguageKorean] = "ko",
    [kLanguageTurkish] = "tr",
    [kLanguageChinese] = "zh-CN",
    [kLanguageItalian] = "it",
    [kLanguageThai] = "th",
}
function getTargetLgg()
    local i18n = require "res.i18n"
    local curLgg = i18n.getCurrentLanguage()
    local target = targetLgg[curLgg] or "en"
    return target
end

function doExit()
    if not APP_CHANNEL or APP_CHANNEL == "" then
        director:endToLua()
        return
    end
    local cfg = require"common.sdkcfg"
    if cfg[APP_CHANNEL] and cfg[APP_CHANNEL].exit then
        cfg[APP_CHANNEL].exit("", function()
            director:endToLua()
        end)
    else
        director:endToLua()
    end
end

function exitGame(parentObj)
    local pnode = parentObj
    if not pnode then
        pnode = director:getRunningScene()
    end
    if isChannel() then
        local cfg = require"common.sdkcfg"
        if cfg[APP_CHANNEL] and cfg[APP_CHANNEL].exit then
            doExit()
            return
        end
    end
    local i18n = require "res.i18n" 
    local dialog = require "ui.dialog"
    local function process_dialog(__data)
        pnode:removeChildByTag(dialog.TAG)
        if __data.selected_btn == 2 then
            -- button confirm
            doExit()
        elseif __data.selected_btn == 1 then
            -- button Cancel
            pnode._exit_flag = nil
        end
    end
    local dialog_params = {
        title = "",
        body = i18n.global.exit_game_tips.string,
        btn_count = 2,
        btn_color = {
            [1] = dialog.COLOR_BLUE,
            [2] = dialog.COLOR_GOLD,
        },
        btn_text = {
            [1] = i18n.global.dialog_button_cancel.string,
            [2] = i18n.global.dialog_button_confirm.string,
        },
        selected_btn = 0,
        callback = process_dialog,
    }
    local dialog_ins = dialog.create(dialog_params)
    pnode:addChild(dialog_ins, 1000, dialog.TAG)
end

function shiftTop(node)
    local parent = node:getParent()
    if parent then
        local world = parent:convertToWorldSpace(CCPoint(node:getPosition()))
        local newY = world.y + view.minY
        local newPos = parent:convertToNodeSpace(CCPoint(world.x, newY))
        node:setPosition(newPos)
    end
end

function shiftBottom(node)
    local parent = node:getParent()
    if parent then
        local world = parent:convertToWorldSpace(CCPoint(node:getPosition()))
        local newY = world.y - view.minY
        local newPos = parent:convertToNodeSpace(CCPoint(world.x, newY))
        node:setPosition(newPos)
    end
end

function shiftLeft(node, ignoreIX)
    local parent = node:getParent()
    if parent then
        local world = parent:convertToWorldSpace(CCPoint(node:getPosition()))
        local newX = world.x - view.minX + view.safeOffset
        if ignoreIX then
            newX = newX - view.safeOffset
        end
        local newPos = parent:convertToNodeSpace(CCPoint(newX, world.y))
        node:setPosition(newPos)
    end
end

function shiftRight(node, ignoreIX)
    local parent = node:getParent()
    if parent then
        local world = parent:convertToWorldSpace(CCPoint(node:getPosition()))
        local newX = world.x + view.minX - view.safeOffset
        if ignoreIX then
            newX = newX + view.safeOffset
        end
        local newPos = parent:convertToNodeSpace(CCPoint(newX, world.y))
        node:setPosition(newPos)
    end
end

function autoLayoutShift(node, top, bottom, left, right, ignoreIX)
    local size = node:getContentSize()
    local world_bl = node:convertToWorldSpace(CCPoint(0, 0))
    local world_tr = node:convertToWorldSpace(CCPoint(size.width, size.height))

    local offset = 100 * view.minScale
    if left or ((world_bl.x - view.minX) <= offset and left == nil) then
        shiftLeft(node, ignoreIX)
    elseif right or ((view.maxX - world_tr.x) <= offset and right == nil) then
        shiftRight(node, ignoreIX)
    end
    if bottom or ((world_bl.y - view.minY) <= offset and bottom == nil)  then
        shiftBottom(node)
    elseif top or ((view.maxY - world_tr.y) <= offset and top == nil) then
        shiftTop(node)
    end

    return node:getPosition()
end

function getAutoLayoutShiftPos(node, point, top, bottom, left, right)
    local orgX, orgY = node:getPosition()
    node:setPosition(point)

    local x, y = autoLayoutShift(node, top, bottom, left, right)

    node:setPosition(orgX, orgY)

    return ccp(x, y)
end
