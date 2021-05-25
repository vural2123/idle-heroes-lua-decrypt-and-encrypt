local ui = {}

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local i18n = require "res.i18n"
local cfghelp = require "config.help"
local player = require "data.player"
local userdata = require "data.userdata"

function ui.create()
    local boardlayer = require "ui.setting.board"
    local layer = boardlayer.create(boardlayer.TAB.HELP)
    local board = layer.inner_board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height
    
    layer.setTitle(i18n.global.setting_title_help.string)

    -- btn_help
    local btn_help0 = img.createLogin9Sprite(img.login.button_9_small_mwhite)
    btn_help0:setPreferredSize(CCSizeMake(210, 42))
    local help_sel = img.createLogin9Sprite(img.login.button_9_small_gold)
    help_sel:setPreferredSize(CCSizeMake(210, 42))
    help_sel:setPosition(CCPoint(btn_help0:getContentSize().width/2, btn_help0:getContentSize().height/2))
    btn_help0:addChild(help_sel)
    local lbl_help = lbl.createFont1(18, i18n.global.setting_btn_help.string, ccc3(0x73, 0x3b, 0x05))
    lbl_help:setPosition(CCPoint(btn_help0:getContentSize().width/2, btn_help0:getContentSize().height/2+2))
    btn_help0:addChild(lbl_help)
    local btn_help = SpineMenuItem:create(json.ui.button, btn_help0)
    btn_help:setPosition(CCPoint(370-215, 380))
    local btn_help_menu = CCMenu:createWithItem(btn_help)
    btn_help_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_help_menu)
    btn_help:setEnabled(false)

    -- btn_faq
    local btn_faq0 = img.createLogin9Sprite(img.login.button_9_small_mwhite)
    btn_faq0:setPreferredSize(CCSizeMake(210, 42))
    local faq_sel = img.createLogin9Sprite(img.login.button_9_small_gold)
    faq_sel:setPreferredSize(CCSizeMake(210, 42))
    faq_sel:setPosition(CCPoint(btn_faq0:getContentSize().width/2, btn_faq0:getContentSize().height/2+2))
    btn_faq0:addChild(faq_sel)
    faq_sel:setVisible(false)
    local faq_str = "FAQ"
    if i18n.getCurrentLanguage() == kLanguageTurkish then
        faq_str = "SSS"
    end
    local lbl_faq = lbl.createFont1(18, faq_str, ccc3(0x94, 0x62, 0x42))
    lbl_faq:setPosition(CCPoint(btn_faq0:getContentSize().width/2, btn_faq0:getContentSize().height/2))
    btn_faq0:addChild(lbl_faq)
    local btn_faq = SpineMenuItem:create(json.ui.button, btn_faq0)
    btn_faq:setPosition(CCPoint(370, 380))
    local btn_faq_menu = CCMenu:createWithItem(btn_faq)
    btn_faq_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_faq_menu)
    btn_faq:registerScriptTapHandler(function()
        audio.play(audio.button)
        local parentObj = layer:getParent()
        layer:removeFromParentAndCleanup(true)
        parentObj:addChild((require"ui.setting.faq").create(), 1000)
    end)

    -- btn_notice
    local btn_notice0 = img.createLogin9Sprite(img.login.button_9_small_mwhite)
    btn_notice0:setPreferredSize(CCSizeMake(210, 42))
    local notice_sel = img.createLogin9Sprite(img.login.button_9_small_gold)
    notice_sel:setPreferredSize(CCSizeMake(210, 42))
    notice_sel:setPosition(CCPoint(btn_notice0:getContentSize().width/2, btn_notice0:getContentSize().height/2+2))
    btn_notice0:addChild(notice_sel)
    notice_sel:setVisible(false)
    local lbl_notice = lbl.createFont1(18, i18n.global.setting_title_notice.string, ccc3(0x73, 0x3b, 0x05))
    lbl_notice:setPosition(CCPoint(btn_notice0:getContentSize().width/2, btn_notice0:getContentSize().height/2))
    btn_notice0:addChild(lbl_notice)
    local btn_notice = SpineMenuItem:create(json.ui.button, btn_notice0)
    btn_notice:setPosition(CCPoint(370+215, 380))
    local btn_notice_menu = CCMenu:createWithItem(btn_notice)
    btn_notice_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_notice_menu)
    btn_notice:registerScriptTapHandler(function()
        audio.play(audio.button)
        --local parentObj = layer:getParent()
        --layer:removeFromParentAndCleanup(true)
        --parentObj:addChild((require"ui.setting.notice").create(), 1000)
        local param = { sid = player.sid, language = i18n.getCurrentLanguage(), vsn = 0 }
        local net = require "net.netClient"
        local pubs = require "data.pubs"
        addWaitNet()
        net:lpub(param, function(data)
            delWaitNet()
            if data.status < 0 then
                return
            end
            if data.status ~= 1 then
                pubs.save(data.language, data.vsn, data.pub)
            end
            pubs.print()
            local parentObj = layer:getParent()
            layer:removeFromParentAndCleanup(true)
            parentObj:addChild((require"ui.setting.notice").create(), 1000)
        end)
    end)

    ---- btn_feed
    --local btn_feed0 = img.createLogin9Sprite(img.login.button_9_small_green)
    --btn_feed0:setPreferredSize(CCSizeMake(198, 45))
    --local lbl_feed = lbl.createFont1(18, i18n.global.setting_btn_feedback.string, ccc3(0x20, 0x65, 0x05))
    --lbl_feed:setPosition(CCPoint(btn_feed0:getContentSize().width/2, btn_feed0:getContentSize().height/2))
    --btn_feed0:addChild(lbl_feed)
    --local btn_feed = SpineMenuItem:create(json.ui.button, btn_feed0)
    --btn_feed:setPosition(CCPoint(board_w/2, 46))
    --local btn_feed_menu = CCMenu:createWithItem(btn_feed)
    --btn_feed_menu:setPosition(CCPoint(0, 0))
    --board:addChild(btn_feed_menu)

    -- scroll_bg
    local scroll_bg = img.createUI9Sprite(img.ui.setting_dark_bg)
    scroll_bg:setPreferredSize(CCSizeMake(680, 330))
    scroll_bg:setAnchorPoint(CCPoint(0.5, 0))
    scroll_bg:setPosition(CCPoint(board_w/2, 23))
    board:addChild(scroll_bg)
    local container = CCSprite:create()
    container:setContentSize(CCSizeMake(680, 330))
    container:setAnchorPoint(CCPoint(0, 0))
    container:setPosition(CCPoint(0, 0))
    scroll_bg:addChild(container)
    local function createItem(itemObj)
        local item = img.createUI9Sprite(img.ui.select_tab_btn_unselect)
        item:setPreferredSize(CCSizeMake(664, 50))
        -- arr
        local icon_arr = img.createUISprite(img.ui.setting_icon_arrow)
        icon_arr:setPosition(CCPoint(25, 25))
        item:addChild(icon_arr)
        -- title
        local item_title = lbl.createMixFont1(18, itemObj.title, ccc3(0x94, 0x62, 0x42))
        item_title:setPosition(CCPoint(332, 25))
        item:addChild(item_title)
        return item
    end

    local function createScroll()
        local scroll_params = {
            width = 680,
            height = 319,
        }
        local lineScroll = require "ui.lineScroll"
        return lineScroll.create(scroll_params)
    end

    local list_items = {}
    local function showList()
        container:removeAllChildrenWithCleanup(true)
        arrayclear(list_items)
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(0, 7))
        container:addChild(scroll)
        container.scroll = scroll
        for ii=1,#i18n.help do
            local tmp_item = createItem(i18n.help[ii])
            tmp_item.ax = 0.5
            tmp_item.px = 340
            tmp_item.idx = ii
            tmp_item.obj = i18n.help[ii]
            list_items[#list_items+1] = tmp_item
            scroll.addItem(tmp_item)
            scroll.addSpace(1)
        end
        scroll.setOffsetBegin()
    end
    showList()

    local function showContent(helpObj)
        container.scroll = nil
        container:removeAllChildrenWithCleanup(true)
        arrayclear(list_items)
        local content = img.createUI9Sprite(img.ui.setting_help_content_bg)
        content:setPreferredSize(CCSizeMake(664, 319))
        content:setAnchorPoint(CCPoint(0.5, 0))
        content:setPosition(CCPoint(340, 7))
        container:addChild(content)
        local scroll = createScroll()
        scroll:setAnchorPoint(CCPoint(0, 0))
        scroll:setPosition(CCPoint(0, 0))
        content:addChild(scroll, 1)
        -- bar
        local bar0 = img.createUI9Sprite(img.ui.select_tab_btn_unselect)
        bar0:setPreferredSize(CCSizeMake(664, 50))
        local bar = HHMenuItem:createWithScale(bar0, 1)
        bar:setPosition(CCPoint(332, 294))
        local bar_menu = CCMenu:createWithItem(bar)
        bar_menu:setPosition(CCPoint(0, 0))
        content:addChild(bar_menu, 2)
        local icon_arr = img.createUISprite(img.ui.setting_icon_arrow)
        icon_arr:setRotation(90)
        icon_arr:setPosition(CCPoint(25, 25))
        bar:addChild(icon_arr)
        local item_title = lbl.createMixFont1(18, helpObj.title, ccc3(0x94, 0x62, 0x42))
        item_title:setPosition(CCPoint(332, 25))
        bar:addChild(item_title)
        -- content
        scroll.addSpace(55)
        for ii=1,#helpObj.describe do
            if helpObj.describe[ii].title then
                local item_title = lbl.createMix({font=1, size=18, text=helpObj.describe[ii].title, 
                            color=ccc3(0x94, 0x62, 0x42), width=644, align=kCCTextAlignmentLeft})
                item_title.height = item_title:getContentSize().height * item_title:getScaleY()
                item_title.ax = 0
                item_title.px = 10
                scroll.addItem(item_title)
            end
            if helpObj.describe[ii].content then
                local item_content = lbl.createMix({font=1, size=18, text=helpObj.describe[ii].content, 
                            color=ccc3(0x94, 0x62, 0x42), width=644, align=kCCTextAlignmentLeft})
                item_content.height = item_content:getContentSize().height * item_content:getScaleY()
                item_content.ax = 0
                item_content.px = 10
                scroll.addItem(item_content)
            end
            scroll.addSpace(15)
        end
        scroll.setOffsetBegin()
        bar:registerScriptTapHandler(function()
            audio.play(audio.button)
            showList()
        end)
    end

    local function onClickItem(itemObj)
        showContent(itemObj.obj)
    end

    -- touch event
    local touchbeginx, touchbeginy
    local isclick
    local last_touch_sprite = nil
    local function onTouchBegan(x, y)
        touchbeginx, touchbeginy = x, y
        isclick = true
        if not container.scroll or tolua.isnull(container.scroll) then
            isclick = false
            return false
        end
        local p0 = scroll_bg:convertToNodeSpace(ccp(x, y))
        if not container:boundingBox():containsPoint(p0) then
            isclick = false
            return false
        end
        local content_layer = container.scroll.content_layer
        local p1 = content_layer:convertToNodeSpace(ccp(x, y))
        for ii=1,#list_items do
            if list_items[ii]:boundingBox():containsPoint(p1) then
                --playAnimTouchBegin(list_items[ii])
                setShader(list_items[ii], SHADER_HIGHLIGHT, true)
                last_touch_sprite = list_items[ii]
                break
            end
        end
        return true
    end
    local function onTouchMoved(x, y)
        if isclick and (math.abs(touchbeginx-x) > 10 or math.abs(touchbeginy-y) > 10) then
            isclick = false
            if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
                --playAnimTouchEnd(last_touch_sprite)
                clearShader(last_touch_sprite, true)
                last_touch_sprite = nil
            end
        end
    end
    local function onTouchEnded(x, y)
        if last_touch_sprite and not tolua.isnull(last_touch_sprite) then
            --playAnimTouchEnd(last_touch_sprite)
            clearShader(last_touch_sprite, true)
            last_touch_sprite = nil
        end
        if not container.scroll or tolua.isnull(container.scroll) then
            return
        end
        if isclick then
            local content_layer = container.scroll.content_layer
            local p0 = content_layer:convertToNodeSpace(ccp(x, y))
            for ii=1,#list_items do
                if list_items[ii]:boundingBox():containsPoint(p0) then
                    audio.play(audio.button)
                    onClickItem(list_items[ii])
                    break
                end
            end
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

    return layer
end

return ui
