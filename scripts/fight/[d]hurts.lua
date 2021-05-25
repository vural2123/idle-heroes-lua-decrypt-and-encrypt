-- 伤害统计

local ui = {}

require "common.const"
require "common.func"
local view = require "common.view"
local i18n = require "res.i18n"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local cfghero = require "config.hero"
local cfgmons = require "config.monster"
local herosdata = require "data.heros"
local progressbar = require "ui.progressbar"
local cfgPet = require "config.pet"

local BG_W, BG_H = 712, 546

local progress = {}

function ui.create(atks,defs,hurts,video)
    --以下是特殊错误判断
    local atkPet = nil
    if video.atk ~= nil then
        atkPet = video.atk.pet
    end

    print("******")
    tbl2string(atks)
    local defPet = nil
    if video.def ~= nil then
        defPet = video.def.pet
    end
    
    local layer = CCLayer:create()

    --避免出错再次初始化
    progress = {}
    progress.dps = {}
    progress.heal = {}
    
    -- dark bg
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, 255))
    layer:addChild(darkbg)

    -- bg
    local bg = ui.createBg(atks,defs)
    bg:setScale(view.minScale / 10)
    bg:setPosition(view.midX, view.midY)
    bg:runAction(CCEaseBackOut:create(CCScaleTo:create(0.3, view.minScale)))
    layer:addChild(bg)

    -- close
    local closeBtn0 = img.createUISprite(img.ui.close)
    local closeBtn = SpineMenuItem:create(json.ui.button, closeBtn0)
    closeBtn:setPosition(BG_W-26, BG_H-26)
    local closeMenu = CCMenu:createWithItem(closeBtn)
    closeMenu:setPosition(0, 0)
    bg:addChild(closeMenu)
    closeBtn:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer.onAndroidBack()
    end)

    ----------------------------by youwei 新增用于统计加血，伤害的区分按钮 begin
    -- 按钮Dps
    local btn_unDps= img.createLogin9Sprite(img.login.button_9_small_mwhite)
    btn_unDps:setPreferredSize(CCSizeMake(142, 37))
    
    local doc = lbl.createFont1(18, i18n.global.hurts_dps.string, ccc3(0x60, 0x2c, 0x0f))
    doc:setPosition(142/2,37/2)
    btn_unDps:addChild(doc)

    local btn_seleDps = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_seleDps:setPreferredSize(CCSizeMake(142, 37))
    btn_seleDps:setPosition(BG_W/2-80, 62*7+28)

    local seleDoc = lbl.createFont1(18, i18n.global.hurts_dps.string, ccc3(0x60, 0x2c, 0x0f))
    seleDoc:setPosition(142/2,37/2)
    btn_seleDps:addChild(seleDoc)
    
    local btn_Dps = SpineMenuItem:create(json.ui.button, btn_unDps)
    btn_Dps:setPosition(CCPoint(BG_W/2-80, 62*7+28))
    local menu_Dps = CCMenu:createWithItem(btn_Dps)
    menu_Dps:setPosition(CCPoint(0, 0))
    menu_Dps:setVisible(false)
    
    bg:addChild(menu_Dps)
    bg:addChild(btn_seleDps)

    -- 按钮Heat
    local btn_unHeat= img.createLogin9Sprite(img.login.button_9_small_mwhite)
    btn_unHeat:setPreferredSize(CCSizeMake(142, 37))

    local doc = lbl.createFont1(18, i18n.global.hurts_heal.string, ccc3(0x60, 0x2c, 0x0f))
    doc:setPosition(142/2,37/2)
    btn_unHeat:addChild(doc)
    
    local btn_seleHeat= img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_seleHeat:setPreferredSize(CCSizeMake(142, 37))
    btn_seleHeat:setPosition(BG_W/2+80, 62*7+28)
    btn_seleHeat:setVisible(false)

    local seleDoc = lbl.createFont1(18, i18n.global.hurts_heal.string, ccc3(0x60, 0x2c, 0x0f))
    seleDoc:setPosition(142/2,37/2)
    btn_seleHeat:addChild(seleDoc)

    local btn_Heat = SpineMenuItem:create(json.ui.button, btn_unHeat)
    btn_Heat:setPosition(CCPoint(BG_W/2+80, 62*7+28))
    local menu_Heat = CCMenu:createWithItem(btn_Heat)
    menu_Heat:setPosition(CCPoint(0, 0))

    bg:addChild(menu_Heat)
    bg:addChild(btn_seleHeat)


    btn_Dps:registerScriptTapHandler(function()
        audio.play(audio.button)
        menu_Dps:setVisible(false)
        btn_seleDps:setVisible(true)
        menu_Heat:setVisible(true)
        btn_seleHeat:setVisible(false)

        for k,v in pairs(progress.heal) do
            v.pro:setVisible(false)
            v.lal:setVisible(false)
        end

        for k,v in pairs(progress.dps) do
            v.pro:setVisible(true)
            v.lal:setVisible(true)
        end
    end)

    btn_Heat:registerScriptTapHandler(function()
        audio.play(audio.button)
        menu_Dps:setVisible(true)
        btn_seleDps:setVisible(false)
        menu_Heat:setVisible(false)
        btn_seleHeat:setVisible(true)

        for k,v in pairs(progress.heal) do
            v.pro:setVisible(true)
            v.lal:setVisible(true)
        end

        for k,v in pairs(progress.dps) do
            v.pro:setVisible(false)
            v.lal:setVisible(false)
        end
    end)
    ----------------------------by youwei 新增用于统计加血，伤害的区分按钮 end

    --攻击方Dps
    local atkDps = ui.getHurtInfos("atk", atks, hurts, atkPet)
    --攻击方回血
    local atkHeal = ui.getHurtInfos("atk", atks, hurts, atkPet, true)
    --防御方Dps
    local defDps = ui.getHurtInfos("def", defs, hurts, defPet)
    --防御方回血
    local defHeal = ui.getHurtInfos("def", defs, hurts, defPet, true)

    local maxDps = ui.getMaxData(atkDps,defDps)
    local maxHeal = ui.getMaxData(atkHeal,defHeal)

    ui.drawHurtInfos("atk", bg, atkDps, atkHeal, maxDps, maxHeal)
    ui.drawHurtInfos("def", bg, defDps, defHeal, maxDps, maxHeal)

    addBackEvent(layer)

    function layer.onAndroidBack()
        layer:removeFromParent()
    end

    layer:registerScriptHandler(function(event)
        if event == "enter" then
            layer.notifyParentLock()
        elseif event == "exit" then
            layer.notifyParentUnlock()
        end
    end)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

function ui.createBg()
    local bg = img.createUI9Sprite(img.ui.tips_bg)
    bg:setPreferredSize(CCSize(BG_W, BG_H))

    -- 横条
    for i = 1, 2 do
        for j = 1, 7 do
            local banner = img.createUISprite(img.ui.fight_hurts_bg_1)
            if j % 2 == 0 then
                banner:setOpacity(0.7*255)
            end
            banner:setFlipX(i==2)
            banner:setAnchorPoint(ccp(op3(i==1, 1, 0), 1))
            banner:setPosition(op3(i==1, BG_W/2, BG_W/2), 66+(j-1)*62)
            bg:addChild(banner)
        end
    end

    -- 分隔线1
    local line = img.createUISprite(img.ui.fight_hurts_new_line)
    line:setScaleY(430/6)
    line:setPosition(BG_W/2, 62*7+3)
    line:setAnchorPoint(ccp(0.5, 1))
    bg:addChild(line)

    -- H分隔线2
    local Hline = img.createUISprite(img.ui.hero_tips_fgline)
    Hline:setScaleX((712-74)/3)
    Hline:setPosition(BG_W/2, 62*7+53)
    Hline:setAnchorPoint(ccp(0.5, 0.5))
    bg:addChild(Hline)

    -- vs
    local vs = img.createUISprite(img.ui.fight_pay_vs)
    vs:setScale(0.4)
    vs:setPosition(BG_W/2, 513)
    bg:addChild(vs)

    -- title
    local atkTitleStr = i18n.global.fight_hurt_atk_title.string
    local atkTitle = lbl.createMixFont1(22, atkTitleStr, ccc3(0x68, 0xaf, 0xff))
    atkTitle:setPosition(bg:getContentSize().width/2-172, 510)
    bg:addChild(atkTitle)
    local defTitleStr = i18n.global.fight_hurt_def_title.string
    local defTitle = lbl.createMixFont1(22, defTitleStr, ccc3(0xff, 0x59, 0x59))
    defTitle:setPosition(bg:getContentSize().width/2+172, 510)
    bg:addChild(defTitle)

    return bg
end

function ui.getMaxData(atkInfos,defInfos)
    local maxHurt = 0
    for _, info in ipairs(atkInfos) do
        if maxHurt == nil or info.hurt > maxHurt then
            maxHurt = info.hurt
        end
    end
    for _, info in ipairs(defInfos) do
        if maxHurt == nil or info.hurt > maxHurt then
            maxHurt = info.hurt
        end
    end

    --除数不能为0
    if maxHurt == 0 then
        maxHurt = 1
    end

    return maxHurt
end

function ui.drawPro(side, bg, k, info, maxHurt, png)
    -- body
    local x, y = op3(side == "atk", BG_W/2-266, BG_W/2+266), 382-(k-1)*62
    -- progress
    local progressBg = img.createUISprite(img.ui.fight_hurts_bar_bg)
    local progressFg = progressbar.create(img.createUISprite(png))
    if side == "atk" then
        progressFg:setScaleX(-1)
        progressBg:setAnchorPoint(ccp(0, 0.5))
        progressBg:setPosition(x+15, y+18)
        --progressFg:setMidpoint(ccp(0, 0))
        progressFg:setMidpoint(ccp(1, 0.5));
        progressFg:setBarChangeRate(ccp(1, 0));
    else
        progressBg:setAnchorPoint(ccp(1, 0.5))
        progressBg:setPosition(x-15, y+18)
        progressFg:setMidpoint(ccp(1, 0))
    end

    local progressBgRect = progressBg:boundingBox()
    progressFg:setPosition(progressBgRect:getMidX(), progressBgRect:getMidY() + 1)
    progressFg.setPercentageOnly(0)
    progressFg.scalePercentageOnly((info.hurt/maxHurt)*100)

    local progressNum = lbl.createFont2(14, "0", ccc3(0xf8, 0xf2, 0xe2))
    progressNum:setPosition(progressBgRect:getMidX(), progressBgRect:getMidY()+20)
 
    bg:addChild(progressBg,10)
    bg:addChild(progressFg,20)
    bg:addChild(progressNum,21)

    progressFg.setPercentageHandler(function(percentage)
        progressNum:setString(math.floor(maxHurt * percentage / 100))
    end)

    return progressFg,progressNum
end

-- side = "atk"|"def"
function ui.drawHurtInfos(side, bg, Dps, Heal, maxDps, maxHeal)

    --随意用一个创建关键所需要的部位，因为数据共有所以dps，heal都可以使用
    for i, info in ipairs(Dps) do
        -- head
        local x, y = op3(side == "atk", BG_W/2-266, BG_W/2+266), 382-(i-1)*62

        local head = nil
        if info.pos < 13 then
            --head = img.createHeroHead(info.id, info.lv, true, true, info.wake)
            local param = {
                id = info.id,
                lv = info.lv,
                showGroup = true,
                showStar = true,
                wake = info.wake,
                orangeFx = nil,
                hskills = info.hskills,
                petID = nil,
            }
            if side == "atk" and info.hid and info.skin == nil then
                param.hid = info.hid
            end
            if info.skin then
                param.skin = info.skin
            end
            head = img.createHeroHeadByParam(param)
        else
            head = img.createUISprite(img.ui.herolist_head_bg)
        
            local bgSize = head:getContentSize()

            local playerHead = img.createPlayerHeadById(info.id)
            playerHead:setPosition(bgSize.width/2, bgSize.height/2)
			img.fixOfficialScale(playerHead, "hero", info.id)
            head:addChild(playerHead)
            --加入宠物特效
            local petJson = json.create(json.ui.petHint)
            petJson:playAnimation("animation",-1)
            petJson:setPosition(bgSize.width/2, bgSize.height/2)
            head:addChild(petJson,10)
        end

        head:setScale(0.55)
        head:setAnchorPoint(op3(side == "atk", ccp(1, 0), ccp(0, 0)))
        head:setPosition(x, y)
        bg:addChild(head)
    end

    --创建dps特有的进度条，且保存起来
    for k,v in pairs(Dps) do
        local myDps,myDpslal = ui.drawPro(side, bg, k, v, maxDps, img.ui.fight_hurts_bar_fg_2)
        progress.dps[v.pos] = {}
        progress.dps[v.pos].pro = myDps
        progress.dps[v.pos].lal = myDpslal

    end

    --创建heal特有的进度条，且保存起来
    for k,v in pairs(Heal) do
        local myDps,myDpslal = ui.drawPro(side, bg, k, v, maxHeal, img.ui.fight_hurts_bar_fg_1)
        progress.heal[v.pos] = {}
        progress.heal[v.pos].pro = myDps
        progress.heal[v.pos].lal = myDpslal
        progress.heal[v.pos].pro:setVisible(false)
        progress.heal[v.pos].lal:setVisible(false)
    end
end

-- side = "atk"|"def"，最后一个参数确定是否是加血量
function ui.getHurtInfos(side, camp, hurts, pet, isHeal)
    local infos = {}
    for _, h in ipairs(camp) do
        local info
        if h.kind == "mons" then
            info = {
                id = cfgmons[h.id].heroLink,
                lv = h.lv or cfgmons[h.id].lvShow,
                star = h.star or cfgmons[h.id].star,
            }
        elseif h.hid then
            local hdata = herosdata.find(h.hid)
            info = {
                id = h.id or (hdata and hdata.id),
                lv = h.lv or (hdata and hdata.lv),
                star = h.star or (hdata and hdata.star),
                wake = h.wake or (hdata and hdata.wake),
                hid = h.hid or (hdata and hdata.hid),
                hskills = h.hskills or (hdata and hdata.hskills),
                skin = h.skin or (hdata and hdata.skin),
            }
        else
            info = {
                id = h.id,
                lv = h.lv,
                star = h.star,
                hskills = h.hskills,
                wake = h.wake,
                skin = h.skin
            }
        end
		
		if side == "atk" then
			if h.pos >= 7 then
				info.pos = h.pos - 6
			else
				info.pos = h.pos
			end
		else
			if h.pos <= 6 then
				info.pos = h.pos + 6
			else
				info.pos = h.pos
			end
		end

        info.hurt = ui.getHurtValue(info.pos, hurts, isHeal)
        info.name = i18n.hero[info.id].heroName
        infos[#infos+1] = info
    end

    --特殊加入战宠
    if pet ~= nil then
        local info = {}
        --与服务器约定的特殊位置标记
        info.pos = 13
        if side ~= "atk" then
            info.pos = 14
        end
        
        info.name = ""
        info.id = cfgPet[pet.id].petIcon[pet.star+1]
        print("战宠ID = ",info.id)
        info.lv = 1
        info.star = pet.star
        info.hurt = ui.getHurtValue(info.pos, hurts, isHeal)
        infos[#infos+1] = info
    end

    table.sort(infos, function(a, b)
        return a.pos < b.pos
    end)

    return infos
end

function ui.getHurtValue(pos, hurts, isHeal)
    for _, s in ipairs(hurts) do
        if s.pos == pos then
            if isHeal == nil then
                return s.value or 0
            else
                return s.heal or 0
            end
        end 
    end 
    return 0
end

return ui
