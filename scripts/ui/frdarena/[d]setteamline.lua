local ui = {}

require "common.func"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local i18n = require "res.i18n"
local audio = require "res.audio"
local heros = require "data.heros"
local userdata = require "data.userdata"
local cfghero = require "config.hero"
local bag = require "data.bag"
local player = require "data.player"
local net = require "net.netClient"
local frdarena = require "data.frdarena"

function ui.create()
    local layer = CCLayer:create()
    local darkbg = CCLayerColor:create(ccc4(0, 0, 0, POPUP_DARK_OPACITY))
    layer:addChild(darkbg)
    
    local teamsInfo = frdarena.team 
    local params = clone(teamsInfo)
    tbl2string(params)

    local BG_WIDTH = 890
    local BG_HEIGHT = 554
    local board = img.createLogin9Sprite(img.login.dialog)
    board:setPreferredSize(CCSize(BG_WIDTH, BG_HEIGHT))
    --board:setAnchorPoint(ccp(0.5, 0))
    board:setScale(view.minScale)
    board:setPosition(view.midX, view.midY)
    layer:addChild(board)

    local title = lbl.createFont1(26, i18n.global.arena3v3_btn_setting.string, ccc3(0xe6, 0xd0, 0xae))
    title:setPosition(BG_WIDTH/2, BG_HEIGHT-27)
    board:addChild(title, 1)

    local titleShade = lbl.createFont1(26, i18n.global.arena3v3_btn_setting.string, ccc3(0x59, 0x30, 0x1b))
    titleShade:setPosition(BG_WIDTH/2, BG_HEIGHT-29)
    board:addChild(titleShade)

    local heroCampBg = img.createUI9Sprite(img.ui.bag_btn_inner_bg)
    heroCampBg:setPreferredSize(CCSize(842, 396))
    heroCampBg:setPosition(BG_WIDTH/2, 288)
    board:addChild(heroCampBg)

    local selectTeamBg = img.createUI9Sprite(img.ui.select_tab_tab_bg)
    selectTeamBg:setPreferredSize(CCSize(800, 37))
    selectTeamBg:setPosition(421, 358)
    heroCampBg:addChild(selectTeamBg)

    local showPowerBg = img.createUISprite(img.ui.select_hero_power_bg)
    showPowerBg:setAnchorPoint(ccp(0, 0.5))
    showPowerBg:setPosition(0, 19)
    selectTeamBg:addChild(showPowerBg)

    local powerIcon = img.createUISprite(img.ui.power_icon)
    powerIcon:setScale(0.46)
    powerIcon:setPosition(27, 21)
    showPowerBg:addChild(powerIcon)

    local showpower = lbl.createFont2(20, string.format("%d", params.power), ccc3(255, 246, 223))
    showpower:setAnchorPoint(ccp(0, 0.5))
    showpower:setPosition(powerIcon:boundingBox():getMaxX() + 15, powerIcon:boundingBox():getMidY())
    showPowerBg:addChild(showpower)

    local btnSettingSprite = img.createLogin9Sprite(img.login.button_9_small_gold)
    btnSettingSprite:setPreferredSize(CCSize(216, 44))
    local btnSettingLab = lbl.createFont1(16, i18n.global.guildFight_save_camp.string, ccc3(0x73, 0x3b, 0x05))
    btnSettingLab:setPosition(btnSettingSprite:getContentSize().width/2, btnSettingSprite:getContentSize().height/2)
    btnSettingSprite:addChild(btnSettingLab)

    local btnSetting = SpineMenuItem:create(json.ui.button, btnSettingSprite)
    btnSetting:setPosition(BG_WIDTH/2, 56)
    local menuSetting = CCMenu:createWithItem(btnSetting)
    menuSetting:setPosition(0, 0)
    board:addChild(menuSetting, 1)

    local teamslayer = nil
    local createteamlayer = nil

    btnSetting:registerScriptTapHandler(function()
        audio.play(audio.button)
        if frdarena.team.leader ~= player.uid then
            showToast(i18n.global.frdpvp_permission_denied.string)
            return
        end

        local teamsuid = {}
        for i=1,3 do
            teamsuid[i] = params.mbrs[i].uid 
        end
        local param = {
            sid = player.sid,
            team = teamsuid
        }
        tbl2string(param)
        addWaitNet()
        net:change_gpvpteam(param,function(__data)
            delWaitNet()
            tbl2string(__data)
            if __data.status < 0 then
                showToast("status:" .. __data.status)
                return
            end
            params.leader = frdarena.team.leader 
            frdarena.team = params
            replaceScene(require("ui.frdarena.main").create())
        end)
    end)

    local item = {}
    local baseHeroBlack = {}
    local function createItem(_idx)
        item[_idx] = img.createUI9Sprite(img.ui.botton_fram_2)
        item[_idx]:setPreferredSize(CCSizeMake(792, 100))
        local item_w = item[_idx]:getContentSize().width
        local item_h = item[_idx]:getContentSize().height
        
        local numlab = lbl.createFont1(16, _idx, ccc3(0x51, 0x27, 0x12))
        numlab:setPosition(40-3, item_h/2)
        item[_idx]:addChild(numlab)

        tbl2string(params.mbrs[_idx])
        local showHead = img.createPlayerHeadForArena(params.mbrs[_idx].logo, params.mbrs[_idx].lv)
        showHead:setScale(0.8)
        showHead:setPosition(102, item_h/2)
        item[_idx]:addChild(showHead)

        if params.mbrs[_idx].uid == params.leader then
            local teamIcon = img.createUISprite(img.ui.friend_pvp_captain)
            teamIcon:setAnchorPoint(0, 1)
            teamIcon:setPosition(0, showHead:getContentSize().height)
            showHead:addChild(teamIcon)
        end
        
        local namelab = lbl.createFontTTF(16, params.mbrs[_idx].name, ccc3(0x51, 0x27, 0x12))
        namelab:setAnchorPoint(0, 0.5)
        namelab:setPosition(150, 68)
        item[_idx]:addChild(namelab)
        local showPowerBg = img.createUI9Sprite(img.ui.arena_frame7)
        showPowerBg:setPreferredSize(CCSize(140, 28))
        showPowerBg:setAnchorPoint(ccp(0, 0.5))
        showPowerBg:setPosition(152, 36+2)
        item[_idx]:addChild(showPowerBg)
        local showPowerIcon = img.createUISprite(img.ui.power_icon)
        showPowerIcon:setScale(0.5)
        showPowerIcon:setPosition(10, showPowerBg:getContentSize().height/2)
        showPowerBg:addChild(showPowerIcon)
        local showPower = lbl.createFont2(16, params.mbrs[_idx].power)
        showPower:setPosition(showPowerBg:getContentSize().width/2, showPower:getContentSize().height/2 - 4)
        showPowerBg:addChild(showPower)

        local POSX = {
            [1] = 350, [2] = 326+85, [3] = 400+85, [4] = 462+85, [5] = 524+85, [6] = 586+85 
        }

        local hids = {}
        local pheroes = params.mbrs[_idx].camp or {}
        if pheroes then
            for i, v in ipairs(pheroes) do
                hids[v.pos] = v
            end
        end
        
        for i=1, 6 do
            local showHero
            local idx = (_idx - 1) * 6 + i
            if hids[i] then
                --showHero = img.createHeroHead(hids[i].id, hids[i].lv, true, true, hids[i].wake,nil,require("data.pet").getPetID(hids))
                local param = {
                    id = hids[i].id,
                    lv = hids[i].lv,
                    showGroup = true,
                    showStar = true,
                    wake = hids[i].wake,
                    orangeFx = nil,
                    petID = require("data.pet").getPetID(hids),
                    hid = nil,
                    hskills = hids[i].hskills,
                    skin = hids[i].skin
                }
                showHero = img.createHeroHeadByParam(param)
                showHero:setScale(0.6)
            else
                showHero = img.createUI9Sprite(img.ui.herolist_withouthero_bg)
                showHero:setPreferredSize(CCSize(59, 59))
            end
            showHero:setPosition(POSX[i]-3, item[_idx]:getContentSize().height/2)
            item[_idx]:addChild(showHero)
            
            baseHeroBlack[idx] = img.createUISprite(img.ui.hero_head_shade)
            baseHeroBlack[idx]:setScale(0.6)
            --baseHeroBlack[idx]:setScale(76/94)
            baseHeroBlack[idx]:setOpacity(120)
            baseHeroBlack[idx]:setPosition(POSX[i]-3, item[_idx]:getContentSize().height/2)
            item[_idx]:addChild(baseHeroBlack[idx], 10000)
            baseHeroBlack[idx]:setVisible(false)
        end

        return item[_idx]
    end

    local cfg = {
        [1] = { bg = img.login.button_9_small_gold, icon = img.ui.arena_new_switch },
        [2] = { bg = img.login.button_9_small_orange, icon = img.ui.arena_new_cancel_icon },
        [3] = { bg = img.login.button_9_small_green, icon = img.ui.arena_new_change_icon },
    }

    local function changepos(i, pos, setflag)
        if pos ~= i then
            --if i == 0 then
            --    table.insert(params.mbrs, params.mbrs[pos])
            --    table.remove(params.mbrs, pos)
            --else
                params.mbrs[i], params.mbrs[pos] = params.mbrs[pos], params.mbrs[i] 
            --end
            --if setflag then
            --    local aUidpos
            --    local bUidpos
            --    for j = 1,#teamsUid do
            --        if params.mbrs[i].uid == teamsUid[j] then 
            --            aUidpos = j 
            --        end
            --        if params.mbrs[pos].uid == teamsUid[j] then 
            --            bUidpos = j 
            --        end
            --    end
            --    teamsUid[aUidpos], teamsUid[bUidpos] = teamsUid[bUidpos], teamsUid[aUidpos] 
            --end
        end
        if teamslayer then
            teamslayer:removeFromParentAndCleanup()
            teamslayer = nil
            teamslayer = createteamlayer()
            board:addChild(teamslayer)
        end
    end
    local preSelect = 0
    local exchangeBtn = {}
    local function createExchangeBtn()
        
        for i=1,3 do
            exchangeBtn[i] = {}
            for j=1,3 do
                local exchangebg = img.createLogin9Sprite(cfg[j].bg)
                exchangebg:setPreferredSize(CCSize(54, 52))
                local exchange = img.createUISprite(cfg[j].icon)
                exchange:setScale(0.95)
                exchange:setPosition(exchangebg:getContentSize().width/2, exchangebg:getContentSize().height/2)
                exchangebg:addChild(exchange)
                exchangeBtn[i][j] = SpineMenuItem:create(json.ui.button, exchangebg)
                exchangeBtn[i][j]:setPosition(746, item[i]:getContentSize().height/2+2)
                local exchangemenu = CCMenu:createWithItem(exchangeBtn[i][j])
                exchangemenu:setPosition(0, 0)
                item[i]:addChild(exchangemenu)

                if j == 1 then
                    exchangeBtn[i][j]:registerScriptTapHandler(function()
                        preSelect = i
                        audio.play(audio.button)
                        --layer:addChild(createChangePos(_idx, #teamsUid, changepos))
                        for k = 1, 18 do
                            baseHeroBlack[k]:setVisible(true)
                        end
                        for k = 1, 6 do
                            baseHeroBlack[(i-1) * 6 + k]:setVisible(false)
                        end
                        for k = 1, 3 do
                            exchangeBtn[k][1]:setVisible(false)
                            if k == i then
                                exchangeBtn[k][2]:setVisible(true)
                            else
                                exchangeBtn[k][3]:setVisible(true)
                            end
                        end
                    end)
                elseif j == 2 then
                    exchangeBtn[i][j]:setVisible(false)
                    exchangeBtn[i][j]:registerScriptTapHandler(function()
                        audio.play(audio.button)
                        for k = 1, 18 do
                            baseHeroBlack[k]:setVisible(false)
                        end
                        for k = 1, 3 do
                            exchangeBtn[k][1]:setVisible(true)
                            exchangeBtn[k][2]:setVisible(false)
                            exchangeBtn[k][3]:setVisible(false)
                        end
                    end)
                elseif j == 3 then
                    exchangeBtn[i][j]:setVisible(false)
                    exchangeBtn[i][j]:registerScriptTapHandler(function()
                        audio.play(audio.button)
                        for k = 1, 18 do
                            baseHeroBlack[k]:setVisible(false)
                        end
                        for k = 1, 3 do
                            exchangeBtn[k][1]:setVisible(true)
                            exchangeBtn[k][2]:setVisible(false)
                            exchangeBtn[k][3]:setVisible(false)
                        end
                        changepos(preSelect, i)
                    end)

                end
            end
        end
    end

    function createteamlayer()
        local tlayer = CCLayer:create()

        local sx = 316
        local dx = 105
        for ii=1,3 do
            local tmp_item = createItem(ii)
            tmp_item:setPosition(BG_WIDTH/2, 366 - 105*(ii-1))
            tlayer:addChild(tmp_item)
        end
        createExchangeBtn()
        return tlayer
    end

    teamslayer = createteamlayer()
    board:addChild(teamslayer)

    local btnCloseSprite = img.createUISprite(img.ui.close)
    local btnClose = SpineMenuItem:create(json.ui.button, btnCloseSprite)
    btnClose:setPosition(BG_WIDTH-25, BG_HEIGHT-25)
    local menuClose = CCMenu:createWithItem(btnClose)
    menuClose:setPosition(0, 0)
    board:addChild(menuClose)
    btnClose:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup()
    end)

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return ui
