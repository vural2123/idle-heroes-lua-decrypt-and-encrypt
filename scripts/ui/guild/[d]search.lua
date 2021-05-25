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
local gdata = require "data.guild"
local i18n = require "res.i18n"
local tipsequip = require "ui.tips.equip"
local tipsitem = require "ui.tips.item"
local dialog = require "ui.dialog"
local board1 = require "ui.guild.board1"
local NetClient = require "net.netClient"
local netClient = NetClient:getInstance()
local gitem = require "ui.guild.gitem"

local space_height = 6

local function search(word, callback)
    local params = {
        sid = player.sid,
        word = word,
    }
    addWaitNet()
    netClient:guild_search(params, function(__data)
        delWaitNet()
        tbl2string(__data)
        if callback then
            callback(__data.guilds or {})
        end
    end)
end

function ui.create(params)
    local layer = board1.create(board1.TAB.SEARCH)
    local board = layer.board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    local edit_name0 = img.createLogin9Sprite(img.login.input_border)
    local edit_name = CCEditBox:create(CCSizeMake(425*view.minScale, 40*view.minScale), edit_name0)
    edit_name:setInputFlag(kEditBoxInputFlagInitialCapsSentence)
    edit_name:setReturnType(kKeyboardReturnTypeDone)
    edit_name:setMaxLength(16)
    edit_name:setFont("", 16*view.minScale)
    edit_name:setFontColor(ccc3(0x49, 0x26, 0x04))
    --edit_name:setVisible(false)
    edit_name:setAnchorPoint(CCPoint(0, 0))
    edit_name:setPosition(scalep(192, 386))
    layer:addChild(edit_name)

    local btn_search0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_search0:setPreferredSize(CCSizeMake(140, 42))
    local lbl_search = lbl.createFont1(18, i18n.global.guild_btn_search.string, ccc3(0x73, 0x3b, 0x05))
    lbl_search:setPosition(CCPoint(btn_search0:getContentSize().width/2, btn_search0:getContentSize().height/2+2))
    btn_search0:addChild(lbl_search)
    local btn_search = SpineMenuItem:create(json.ui.button, btn_search0)
    btn_search:setPosition(CCPoint(538, 323))
    local btn_search_menu = CCMenu:createWithItem(btn_search)
    btn_search_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_search_menu)

    local container = CCSprite:create()
    container:setContentSize(CCSizeMake(640, 265))
    container:setAnchorPoint(CCPoint(0.5, 0))
    container:setPosition(CCPoint(board_w/2, 25))
    board:addChild(container)

    local function createScroll()
        local scroll_params = {
            width = 640,
            height = 265,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local function showList(listObj)
        container:removeAllChildrenWithCleanup(true)
        container.scroll = nil
        if not listObj or #listObj <= 0 then
            showToast(i18n.global.guild_search_none.string)
            return
        end
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(0, 0))
        container:addChild(scroll)
        container.scroll = scroll
        --drawBoundingbox(container, scroll)
        for ii=1,#listObj do
            local tmp_item = gitem.createItem(listObj[ii])
            tmp_item.guildObj = listObj[ii]
            tmp_item.ax = 0.5
            tmp_item.px = 320
            scroll.addItem(tmp_item)
            if ii ~= #listObj then
                scroll.addSpace(space_height)
            end
        end
        scroll.setOffsetBegin()
    end

    btn_search:registerScriptTapHandler(function()
        audio.play(audio.button)
        local tmp_word = edit_name:getText()
        tmp_word = string.trim(tmp_word)
        if tmp_word == "" then
            showToast(i18n.global.input_empty.string)
            return
        end
        search(tmp_word, showList)
    end)

    if params and params.word then
        edit_name:setText(params.word .. "")
        search(params.word .. "", showList)
    end

    layer:setTouchEnabled(true)
    layer:setTouchSwallowEnabled(true)

    return layer
end

return ui
