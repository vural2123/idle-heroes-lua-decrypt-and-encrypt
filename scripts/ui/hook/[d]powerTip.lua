local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local cfgitem = require "config.item"
local cfgequip = require "config.equip"
local player = require "data.player"
local bagdata = require "data.bag"
local hookdata = require "data.hook"
local i18n = require "res.i18n"

local Type = {
    Power = 1,
    Pve = 2,
    Lv = 3,
}

-- kind: 1,power; 2,pve
function ui.create(kind, stage_id)
    local layer = CCLayer:create()

    local function backEvent()
        audio.play(audio.button)
        layer:removeFromParentAndCleanup(true)
    end
    -- board_bg
    local board_bg = img.createUI9Sprite(img.ui.tips_bg)
    board_bg:setPreferredSize(CCSizeMake(297, 255))
    board_bg:setScale(view.minScale)
    board_bg:setPosition(view.midX-25*view.minScale, view.midY)
    layer:addChild(board_bg)
    local board_bg_w = board_bg:getContentSize().width
    local board_bg_h = board_bg:getContentSize().height

    local titles = {
        [Type.Power] = i18n.global.hook_require_power.string,
        [Type.Pve] = i18n.global.hook_require_pve.string,
    }
    local contents = {
        [Type.Power] = string.format(i18n.global.hook_power_tip.string, hookdata.stage_power(stage_id)),
        [Type.Pve] = i18n.global.hook_pve_tip.string,
    }

    -- title
    local lbl_title = lbl.createFont1(20, titles[kind], ccc3(0xff, 0xe4, 0x9c))
    lbl_title:setAnchorPoint(CCPoint(0, 0.5))
    lbl_title:setPosition(CCPoint(17, board_bg_h-34))
    board_bg:addChild(lbl_title)
    local tips_line = img.createUI9Sprite(img.ui.hero_tips_fgline)
    tips_line:setPreferredSize(CCSizeMake(263, 1))
    tips_line:setPosition(CCPoint(board_bg_w/2, board_bg_h-59))
    board_bg:addChild(tips_line)

    local cont_str = string.format(i18n.global.func_need_lv.string, hookdata.getStageLv(stage_id))
    local lbl_content3 = lbl.create({font=1, size=16, text=cont_str, color=ccc3(0xff, 0xfb, 0xec),
                                    width=263, align=kCCTextAlignmentLeft, jp={kind="ttf"}})
    lbl_content3:setAnchorPoint(CCPoint(0, 1))
    lbl_content3:setPosition(CCPoint(17, board_bg_h-70))
    board_bg:addChild(lbl_content3)

    local lbl_content = lbl.create({font=1, size=16, text=contents[Type.Power], color=ccc3(0xff, 0xfb, 0xec),
                                    width=263, align=kCCTextAlignmentLeft, jp={kind="ttf"}})
    lbl_content:setAnchorPoint(CCPoint(0, 1))
    lbl_content:setPosition(CCPoint(17, board_bg_h-70- lbl_content3:boundingBox().size.height-10))
    board_bg:addChild(lbl_content)

    local lbl_content2 = lbl.create({font=1, size=16, text=contents[Type.Pve], color=ccc3(0xff, 0xfb, 0xec),
                                    width=263, align=kCCTextAlignmentLeft, jp={kind="ttf"}})
    lbl_content2:setAnchorPoint(CCPoint(0, 1))
    lbl_content2:setPosition(CCPoint(17, board_bg_h-70 - lbl_content3:boundingBox().size.height-10 - lbl_content:boundingBox().size.height-10))
    board_bg:addChild(lbl_content2)

    if player.lv() < hookdata.getStageLv(stage_id) then
        lbl_content3:setColor(ccc3(0xfa, 0x35, 0x35))
    end
    if hookdata.getAllPower() < hookdata.stage_power(stage_id) then  -- need power
        lbl_content:setColor(ccc3(0xfa, 0x35, 0x35))
    end
    if stage_id > hookdata.getPveStageId() then  -- unlock
        lbl_content2:setColor(ccc3(0xfa, 0x35, 0x35))
    end

    function layer.setTipPos(ax, ay, px, py)
        board_bg:setAnchorPoint(CCPoint(ax, ay))
        board_bg:setPosition(CCPoint(px, py))
    end

    function layer.adaptPos(p0)
        print("p0.x:" .. p0.x)
        if p0.x < view.logical.w/2 then
            layer.setTipPos(0, 0, view.minX+(p0.x+30)*view.minScale, view.minY+(p0.y+30)*view.minScale)
        else
            layer.setTipPos(1, 0, view.minX+(p0.x-10)*view.minScale, view.minY+(p0.y+30)*view.minScale)
        end
    end

    -- touch event
    local touchbeginx, touchbeginy
    local isclick
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        return true
    end
    local function onTouchMoved(x, y)
    end
    local function onTouchEnded(x, y)
        local p0 = layer:convertToNodeSpace(ccp(x, y))
        if not board_bg:boundingBox():containsPoint(p0) then
            backEvent()
        end
    end
    local function onTouch(eventType, x, y)
        if eventType == "began" then   
            return onTouchBegan(x, y)
        elseif eventType == "moved" then
            return onTouchMoved(x, y)
        else
            return onTouchEnded(x, y)
        end
    end
    layer:registerScriptTouchHandler(onTouch , false , -128 , false)
    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    addBackEvent(layer)
    function layer.onAndroidBack()
        backEvent()
    end
    local function onEnter()
        print("onEnter")
        layer.notifyParentLock()
    end
    local function onExit()
        layer.notifyParentUnlock()
    end
    layer:registerScriptHandler(function(event)
        if event == "enter" then
            onEnter()
        elseif event == "exit" then
            onExit()
        end
    end)

    return layer
end

return ui
