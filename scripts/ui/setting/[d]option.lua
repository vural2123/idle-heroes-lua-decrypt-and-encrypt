local ui = {}
local cjson = json

require "common.func"
require "common.const"
local view = require "common.view"
local img = require "res.img"
local i18n = require "res.i18n"
local lbl = require "res.lbl"
local json = require "res.json"
local audio = require "res.audio"
local player = require "data.player"
local userdata = require "data.userdata"

function ui.create(_anim)
    local boardlayer = require "ui.setting.board"
    local layer = boardlayer.create(boardlayer.TAB.OPTION, _anim)
    local board = layer.inner_board
    local board_w = board:getContentSize().width
    local board_h = board:getContentSize().height

    layer.setTitle(i18n.global.setting_title_option.string)

    --[[-- email
    --local lbl_email = lbl.createFont1(16, "Email: idleheroes.feedback@gmail.com", ccc3(0x56, 0x2c, 0x19))
    local lbl_email
    if isOnestore() then
        lbl_email = lbl.createFont1(16, "Email: idle@withusgame.com", ccc3(0x56, 0x2c, 0x19))
    else
        lbl_email = img.createUISprite(img.ui.setting_email_link)
    end
    lbl_email:setPosition(CCPoint(192, 37))
    board:addChild(lbl_email)

    local fb_link = img.createUISprite(img.ui.setting_btn_fb)
    local btn_fb_link = CCMenuItemSprite:create(fb_link, nil)
    btn_fb_link:setScale(0.8)
    btn_fb_link:setPosition(CCPoint(442, 39))
    local btn_fb_link_menu = CCMenu:createWithItem(btn_fb_link)
    btn_fb_link_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_fb_link_menu)
    btn_fb_link:registerScriptTapHandler(function()
        audio.play(audio.button)
        --device.openURL("http://ih.dhgames.cn")
        if i18n.getCurrentLanguage() == kLanguageJapanese then
            device.openURL("https://www.facebook.com/IdleHeroesJP")
        elseif not HHUtils:isFacebookInstalled() then
            device.openURL(URL_FACEBOOK_WEB)
        elseif CCApplication:sharedApplication():getTargetPlatform() == kTargetAndroid then
            device.openURL(URL_FACEBOOK_ANDROID)
        else -- ios
            device.openURL(URL_FACEBOOK_IOS)
        end
    end)

    local tt_link = img.createUISprite(img.ui.setting_btn_tt)
    local btn_tt_link = CCMenuItemSprite:create(tt_link, nil)
    btn_tt_link:setScale(0.8)
    btn_tt_link:setPosition(CCPoint(608, 39))
    local btn_tt_link_menu = CCMenu:createWithItem(btn_tt_link)
    btn_tt_link_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_tt_link_menu)
    btn_tt_link:registerScriptTapHandler(function()
        audio.play(audio.button)
        if isOnestore() then
            device.openURL("https://twitter.com/IdleheroesKr")
        elseif i18n.getCurrentLanguage() == kLanguageJapanese then
            device.openURL(URL_TWITTER_WEB_JP)
        elseif i18n.getCurrentLanguage() == kLanguageKorean then
            device.openURL("https://twitter.com/IdleheroesKr")
        else
            device.openURL(URL_TWITTER_WEB)
        end
    end)

    local wx_link = img.createUISprite(img.ui.setting_btn_wx)
    local btn_wx_link = CCMenuItemSprite:create(wx_link, nil)
    --btn_wx_link:setScale(0.8)
    btn_wx_link:setPosition(CCPoint(429, 38))
    local btn_wx_link_menu = CCMenu:createWithItem(btn_wx_link)
    btn_wx_link_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_wx_link_menu)
    btn_wx_link:registerScriptTapHandler(function()
        --audio.play(audio.button)
        ----device.openURL(URL_WEIBO_WEB)
        --showToast("关注公众号:放置奇兵")
    end)

    local wb_link = img.createUISprite(img.ui.setting_btn_weibo)
    local btn_wb_link = CCMenuItemSprite:create(wb_link, nil)
    btn_wb_link:setScale(0.8)
    btn_wb_link:setPosition(CCPoint(608, 39))
    local btn_wb_link_menu = CCMenu:createWithItem(btn_wb_link)
    btn_wb_link_menu:setPosition(CCPoint(0, 0))
    board:addChild(btn_wb_link_menu)
    btn_wb_link:registerScriptTapHandler(function()
        audio.play(audio.button)
        device.openURL(URL_WEIBO_WEB)
    end)

    --]]-- sys_board
    local sys_board = img.createUI9Sprite(img.ui.botton_fram_2)
    sys_board:setPreferredSize(CCSizeMake(680, 176))
    sys_board:setAnchorPoint(CCPoint(0.5, 0))
    sys_board:setPosition(CCPoint(board_w/2, 222))
    board:addChild(sys_board)
    local sys_board_w = sys_board:getContentSize().width
    local sys_board_h = sys_board:getContentSize().height

    local lbl_sys_title = lbl.createFont1(18, i18n.global.setting_lbl_sys.string, ccc3(0x94, 0x62, 0x42))
    lbl_sys_title:setPosition(CCPoint(sys_board_w/2, 152))
    sys_board:addChild(lbl_sys_title)
    local split_l1 = img.createUISprite(img.ui.hook_title_split)
    split_l1:setAnchorPoint(CCPoint(1, 0.5))
    split_l1:setPosition(CCPoint(sys_board_w/2-62, 152))
    sys_board:addChild(split_l1)
    local split_r1 = img.createUISprite(img.ui.hook_title_split)
    split_r1:setFlipX(true)
    split_r1:setAnchorPoint(CCPoint(0, 0.5))
    split_r1:setPosition(CCPoint(sys_board_w/2+62, 152))
    sys_board:addChild(split_r1)

    -- acc_board
    local acc_board = img.createUI9Sprite(img.ui.botton_fram_2)
    acc_board:setPreferredSize(CCSizeMake(680, 190))
    acc_board:setAnchorPoint(CCPoint(0.5, 0))
    acc_board:setPosition(CCPoint(board_w/2, 26))
    board:addChild(acc_board)
    local acc_board_w = acc_board:getContentSize().width
    local acc_board_h = acc_board:getContentSize().height

    local lbl_acc_title = lbl.createFont1(18, i18n.global.setting_lbl_account.string, ccc3(0x94, 0x62, 0x42))
    lbl_acc_title:setPosition(CCPoint(acc_board_w/2, 168))
    acc_board:addChild(lbl_acc_title)
    local split_l1 = img.createUISprite(img.ui.hook_title_split)
    split_l1:setAnchorPoint(CCPoint(1, 0.5))
    split_l1:setPosition(CCPoint(acc_board_w/2-62, 168))
    acc_board:addChild(split_l1)
    local split_r1 = img.createUISprite(img.ui.hook_title_split)
    split_r1:setFlipX(true)
    split_r1:setAnchorPoint(CCPoint(0, 0.5))
    split_r1:setPosition(CCPoint(acc_board_w/2+62, 168))
    acc_board:addChild(split_r1)

    -- music
    local mtx_msc_bg = img.createUI9Sprite(img.ui.select_hero_buff_bg)
    mtx_msc_bg:setPreferredSize(CCSizeMake(136, 114))
    mtx_msc_bg:setPosition(CCPoint(100, 74))
    sys_board:addChild(mtx_msc_bg)
    local lbl_msc = lbl.createFont1(16, i18n.global.setting_lbl_music.string, ccc3(0x61, 0x34, 0x2a))
    lbl_msc:setPosition(CCPoint(68, 94))
    mtx_msc_bg:addChild(lbl_msc)
    local btn_msc0 = img.createUISprite(img.ui.setting_msc_on)
    local btn_msc_off = img.createUISprite(img.ui.setting_msc_off)
    btn_msc_off:setPosition(CCPoint(btn_msc0:getContentSize().width/2, btn_msc0:getContentSize().height/2))
    btn_msc0:addChild(btn_msc_off)
    local btn_msc = SpineMenuItem:create(json.ui.button, btn_msc0)
    btn_msc:setPosition(CCPoint(68, 47))
    local btn_msc_menu = CCMenu:createWithItem(btn_msc)
    btn_msc_menu:setPosition(CCPoint(0, 0))
    mtx_msc_bg:addChild(btn_msc_menu)
    if audio.isBackgroundMusicEnabled() then
        btn_msc_off:setVisible(false)
    else
        btn_msc_off:setVisible(true)
    end
    btn_msc:registerScriptTapHandler(function()
        audio.play(audio.button)
        if audio.isBackgroundMusicEnabled() then
            audio.setBackgroundMusicEnabled(false)
            btn_msc_off:setVisible(true)
        else
            audio.setBackgroundMusicEnabled(true)
            btn_msc_off:setVisible(false)
        end
    end)
    -- sound
    local mtx_snd_bg = img.createUI9Sprite(img.ui.select_hero_buff_bg)
    mtx_snd_bg:setPreferredSize(CCSizeMake(136, 114))
    mtx_snd_bg:setPosition(CCPoint(261, 74))
    sys_board:addChild(mtx_snd_bg)
    local lbl_snd = lbl.createFont1(16, i18n.global.setting_lbl_snd.string, ccc3(0x61, 0x34, 0x2a))
    lbl_snd:setPosition(CCPoint(68, 94))
    mtx_snd_bg:addChild(lbl_snd)
    local btn_snd0 = img.createUISprite(img.ui.setting_aud_on)
    local btn_snd_off = img.createUISprite(img.ui.setting_aud_off)
    btn_snd_off:setPosition(CCPoint(btn_snd0:getContentSize().width/2, btn_snd0:getContentSize().height/2))
    btn_snd0:addChild(btn_snd_off)
    local btn_snd = SpineMenuItem:create(json.ui.button, btn_snd0)
    btn_snd:setPosition(CCPoint(68, 47))
    local btn_snd_menu = CCMenu:createWithItem(btn_snd)
    btn_snd_menu:setPosition(CCPoint(0, 0))
    mtx_snd_bg:addChild(btn_snd_menu)
    if audio.isEffectEnabled() then
        btn_snd_off:setVisible(false)
    else
        btn_snd_off:setVisible(true)
    end
    btn_snd:registerScriptTapHandler(function()
        audio.play(audio.button)
        if audio.isEffectEnabled() then
            audio.setEffectEnabled(false)
            btn_snd_off:setVisible(true)
        else
            audio.setEffectEnabled(true)
            btn_snd_off:setVisible(false)
        end
    end)
    -- language
    local mtx_lgg_bg = img.createUI9Sprite(img.ui.select_hero_buff_bg)
    mtx_lgg_bg:setPreferredSize(CCSizeMake(136, 114))
    mtx_lgg_bg:setPosition(CCPoint(422, 74))
    sys_board:addChild(mtx_lgg_bg)
    local lbl_lgg = lbl.createFont1(16, i18n.global.setting_lbl_lgg.string, ccc3(0x61, 0x34, 0x2a))
    lbl_lgg:setPosition(CCPoint(68, 94))
    mtx_lgg_bg:addChild(lbl_lgg)
    local short_name = i18n.getLanguageShortName()
    if short_name == "us" then
        short_name = "en"
    elseif short_name == "tw" then
        short_name = "hk"
    end
    --local btn_lgg0 = img.createUISprite(img.ui["setting_lgg_" .. short_name])
    local btn_lgg0 = img.createUISprite(img.ui["setting_lgg_world"])
    local btn_lgg = SpineMenuItem:create(json.ui.button, btn_lgg0)
    btn_lgg:setPosition(CCPoint(68, 47))
    local btn_lgg_menu = CCMenu:createWithItem(btn_lgg)
    btn_lgg_menu:setPosition(CCPoint(0, 0))
    mtx_lgg_bg:addChild(btn_lgg_menu)
    btn_lgg:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.setting.language").create(), 100)
    end)
    --[[-- facebook
    local mtx_fb_bg = img.createUI9Sprite(img.ui.select_hero_buff_bg)
    mtx_fb_bg:setPreferredSize(CCSizeMake(136, 114))
    mtx_fb_bg:setPosition(CCPoint(583, 74))
    sys_board:addChild(mtx_fb_bg)
    local lbl_fb = lbl.createFont1(16, "Facebook", ccc3(0x61, 0x34, 0x2a))
    lbl_fb:setPosition(CCPoint(68, 94))
    mtx_fb_bg:addChild(lbl_fb)
    local btn_fb0 = img.createUISprite(img.ui.setting_icon_fb)
    local btn_fb = SpineMenuItem:create(json.ui.button, btn_fb0)
    btn_fb:setPosition(CCPoint(68, 47))
    local btn_fb_menu = CCMenu:createWithItem(btn_fb)
    btn_fb_menu:setPosition(CCPoint(0, 0))
    mtx_fb_bg:addChild(btn_fb_menu)
    if APP_CHANNEL and APP_CHANNEL ~= "" then
        mtx_fb_bg:setVisible(false)
    end
    btn_fb:registerScriptTapHandler(function()
        audio.play(audio.button)
        HHUtils:shareFacebook(
            i18n.global.facebook_share_name.string, 
            i18n.global.facebook_share_caption.string, 
            i18n.global.facebook_share_description.string, 
            "http://linkfiles.droidhang.com/prompt/hh/ad_facebook.png",
            URL_GOOGLE_PLAY_WEB
        )  
    end)--]]

    -- head
    local head = img.createPlayerHead(player.logo, player.lv())
    head:setScale(0.8)
    head:setPosition(CCPoint(67, 105)) 
    acc_board:addChild(head)
    -- nick
    local acct = userdata.getString(userdata.keys.account)
    local nick = player.name
    local isFormal = userdata.getBool(userdata.keys.accountFormal)
    if not isFormal and not isChannel() then
        acct = ""
        nick = i18n.global.visitor_account_name.string
    end
    local lbl_nick = lbl.createFontTTF(18, nick, ccc3(0x94, 0x62, 0x42))
    lbl_nick:setAnchorPoint(CCPoint(0, 0))
    lbl_nick:setPosition(CCPoint(115, 108))
    acc_board:addChild(lbl_nick)
    -- mail
    local lbl_mail = lbl.createFontTTF(18, acct or "", ccc3(0x94, 0x62, 0x42))
    lbl_mail:setAnchorPoint(CCPoint(0, 0))
    lbl_mail:setPosition(CCPoint(115, 75))
    acc_board:addChild(lbl_mail)

    -- btn_reg
    local btn_reg0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_reg0:setPreferredSize(CCSizeMake(160, 52))
    local lbl_reg = lbl.createFont1(16, i18n.global.setting_btn_reg.string, ccc3(0x73, 0x3b, 0x05))
    lbl_reg:setPosition(CCPoint(btn_reg0:getContentSize().width/2, btn_reg0:getContentSize().height/2))
    btn_reg0:addChild(lbl_reg)
    local btn_reg = SpineMenuItem:create(json.ui.button, btn_reg0)
    btn_reg:setPosition(CCPoint(404, 104))
    local btn_reg_menu = CCMenu:createWithItem(btn_reg)
    btn_reg_menu:setPosition(CCPoint(0, 0))
    acc_board:addChild(btn_reg_menu)
    local btn_change0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_change0:setPreferredSize(CCSizeMake(160, 52))
    local lbl_change = lbl.createFont1(16, i18n.global.setting_btn_change.string, ccc3(0x73, 0x3b, 0x05))
    lbl_change:setPosition(CCPoint(btn_change0:getContentSize().width/2, btn_change0:getContentSize().height/2))
    btn_change0:addChild(lbl_change)
    local btn_change = SpineMenuItem:create(json.ui.button, btn_change0)
    btn_change:setPosition(CCPoint(404, 104))
    local btn_change_menu = CCMenu:createWithItem(btn_change)
    btn_change_menu:setPosition(CCPoint(0, 0))
    acc_board:addChild(btn_change_menu)
    if isFormal then
        btn_change:setVisible(true)
        btn_reg:setVisible(false)
    else
        btn_change:setVisible(false)
        btn_reg:setVisible(true)
    end
    -- btn_switch
    local btn_switch0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_switch0:setPreferredSize(CCSizeMake(160, 52))
    local lbl_switch = lbl.createFont1(16, i18n.global.setting_btn_switch.string, ccc3(0x73, 0x3b, 0x05))
    lbl_switch:setPosition(CCPoint(btn_switch0:getContentSize().width/2, btn_switch0:getContentSize().height/2))
    btn_switch0:addChild(lbl_switch)
    local btn_switch = SpineMenuItem:create(json.ui.button, btn_switch0)
    btn_switch:setPosition(CCPoint(580, 104))
    local btn_switch_menu = CCMenu:createWithItem(btn_switch)
    btn_switch_menu:setPosition(CCPoint(0, 0))
    acc_board:addChild(btn_switch_menu)
    -- btn_code
    local btn_code0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_code0:setPreferredSize(CCSizeMake(160, 52))
    local lbl_code = lbl.createFont1(16, i18n.global.midas_get.string, ccc3(0x73, 0x3b, 0x05))
    lbl_code:setPosition(CCPoint(btn_code0:getContentSize().width/2, btn_code0:getContentSize().height/2))
    btn_code0:addChild(lbl_code)
    local btn_code = SpineMenuItem:create(json.ui.button, btn_code0)
    btn_code:setPosition(CCPoint(580, 40))
    local btn_code_menu = CCMenu:createWithItem(btn_code)
    btn_code_menu:setPosition(CCPoint(0, 0))
    acc_board:addChild(btn_code_menu)
    
    if player.sid == 1 and player.lv() <= 99 and (not player.code or player.code == 0) then btn_code:setVisible(true) else btn_code:setVisible(false) end
    
    btn_code:registerScriptTapHandler(function()
        audio.play(audio.button)
        local parentObj = layer:getParent()
        layer:removeFromParentAndCleanup(true)
        parentObj:addChild((require"ui.setting.code").create(), 1000)
    end)

    btn_reg:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.setting.register").create(), 1000)
    end)
    btn_change:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.setting.change").create(), 1000)
    end)
    btn_switch:registerScriptTapHandler(function()
        audio.play(audio.button)
        layer:addChild((require"ui.setting.switch").create(), 1000)
    end)

    local btn_logout0 = img.createLogin9Sprite(img.login.button_9_small_gold)
    btn_logout0:setPreferredSize(CCSizeMake(80, 48))
    local lbl_logout = lbl.createMixFont1(18, "注销", ccc3(0x83, 0x41, 0x1d))
    lbl_logout:setPosition(CCPoint(40, 24))
    btn_logout0:addChild(lbl_logout)
    local btn_logout = SpineMenuItem:create(json.ui.button, btn_logout0)
    btn_logout:setPosition(CCPoint(580, 64))
    local btn_logout_menu = CCMenu:createWithItem(btn_logout)
    btn_logout_menu:setPosition(CCPoint(0, 0))
    acc_board:addChild(btn_logout_menu)
    btn_logout:setVisible(false)
    btn_logout:registerScriptTapHandler(function()
        audio.play(audio.button)
        player.uid = nil
        player.sid = nil
        local lparams = {
            which = "logout",
        }
        local lparamStr = cjson.encode(lparams)
        SDKHelper:getInstance():login(lparamStr, function(data)
            print("msdk option logout data:", data)
            local director = CCDirector:sharedDirector()
            schedule(director:getRunningScene(), function()
                replaceScene(require("ui.login.home").create())
            end)
        end)
    end)

    if APP_CHANNEL and APP_CHANNEL == "MSDK" then
        btn_logout:setVisible(true)
    else
        btn_logout:setVisible(false)
    end

    --[[if isAmazon() then
        btn_fb_link:setVisible(true)
        btn_tt_link:setVisible(true)
        btn_wx_link:setVisible(false)
        btn_wb_link:setVisible(false)
        btn_reg:setVisible(false)
        btn_change:setVisible(false)
        btn_switch:setVisible(false)
    elseif isOnestore() then
        btn_fb_link:setVisible(true)
        btn_tt_link:setVisible(true)
        btn_wx_link:setVisible(false)
        btn_wb_link:setVisible(false)
        --btn_reg:setVisible(true)
        --btn_change:setVisible(true)
        btn_switch:setVisible(true)
    elseif isChannel() then
        btn_reg:setVisible(false)
        btn_change:setVisible(false)
        btn_switch:setVisible(false)
        btn_fb_link:setVisible(false)
        btn_tt_link:setVisible(false)
        btn_wx_link:setVisible(false)
        btn_wb_link:setVisible(false)
        mtx_lgg_bg:setVisible(false)
        mtx_fb_bg:setVisible(false)
    elseif APP_CHANNEL and APP_CHANNEL ~= "" then
        btn_fb_link:setVisible(false)
        btn_tt_link:setVisible(false)
        btn_wx_link:setVisible(true)
        btn_wb_link:setVisible(true)
    else
        btn_fb_link:setVisible(true)
        btn_tt_link:setVisible(true)
        btn_wx_link:setVisible(false)
        btn_wb_link:setVisible(false)
    end--]]

    return layer
end

return ui
