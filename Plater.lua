
-- todo check code with review tag --review

 if (true) then
	--return
	--but not today
end

--/run UIErrorsFrame:HookScript ("OnEnter", function() UIErrorsFrame:EnableMouse (false);Plater:Msg("UIErrorsFrame had MouseEnabled, its disabled now.") end)
--some WA or addon are enabling the mouse on the error frame making nameplates unclickable
if (UIErrorsFrame) then
	UIErrorsFrame:HookScript ("OnEnter", function()
		--safe disable the mouse on error frame avoiding mouse interactions and warn the user
		UIErrorsFrame:EnableMouse (false)
		Plater:Msg ("something enabled the mouse on UIErrorsFrame, Plater disabled.")
	end)
	UIErrorsFrame:EnableMouse (false)
end

--details! framework
local DF = _G ["DetailsFramework"]
if (not DF) then
	print ("|cFFFFAA00Plater: framework not found, if you just installed or updated the addon, please restart your client.|r")
	return
end

--blend nameplates with the worldframe
local AlphaBlending = ALPHA_BLEND_AMOUNT + 0.0654785

--locals
local unpack = unpack
local ipairs = ipairs
local pairs = pairs
local InCombatLockdown = InCombatLockdown
local UnitIsPlayer = UnitIsPlayer
local UnitClassification = UnitClassification
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local UnitAura = UnitAura
local UnitCanAttack = UnitCanAttack
local IsSpellInRange = IsSpellInRange
local abs = math.abs
local format = string.format
local GetSpellInfo = GetSpellInfo
local UnitIsUnit = UnitIsUnit
local type = type
local tonumber = tonumber
local select = select
local UnitGUID = UnitGUID
local strsplit = strsplit
local lower = string.lower
local floor = floor
local max = math.max
local min = math.min

local GameCooltip = GameCooltip2
local LibSharedMedia = LibStub:GetLibrary ("LibSharedMedia-3.0")

LibSharedMedia:Register ("statusbar", "DGround", [[Interface\AddOns\Plater\images\bar_background]])
LibSharedMedia:Register ("statusbar", "Details D'ictum", [[Interface\AddOns\Plater\images\bar4]])
LibSharedMedia:Register ("statusbar", "Details Vidro", [[Interface\AddOns\Plater\images\bar4_vidro]])
LibSharedMedia:Register ("statusbar", "Details D'ictum (reverse)", [[Interface\AddOns\Plater\images\bar4_reverse]])
LibSharedMedia:Register ("statusbar", "Details Serenity", [[Interface\AddOns\Plater\images\bar_serenity]])
LibSharedMedia:Register ("statusbar", "BantoBar", [[Interface\AddOns\Plater\images\BantoBar]])
LibSharedMedia:Register ("statusbar", "Skyline", [[Interface\AddOns\Plater\images\bar_skyline]])
LibSharedMedia:Register ("statusbar", "WorldState Score", [[Interface\WorldStateFrame\WORLDSTATEFINALSCORE-HIGHLIGHT]])
LibSharedMedia:Register ("statusbar", "Details Flat", [[Interface\AddOns\Plater\images\bar_background]])
LibSharedMedia:Register ("statusbar", "DGround", [[Interface\AddOns\Plater\images\bar_background]])
LibSharedMedia:Register ("statusbar", "PlaterBackground", [[Interface\AddOns\Plater\images\platebackground]])
LibSharedMedia:Register ("statusbar", "PlaterTexture", [[Interface\AddOns\Plater\images\platetexture]])
LibSharedMedia:Register ("statusbar", "PlaterHighlight", [[Interface\AddOns\Plater\images\plateselected]])
LibSharedMedia:Register ("statusbar", "PlaterFocus", [[Interface\AddOns\Plater\images\overlay_indicator_1]])
LibSharedMedia:Register ("statusbar", "PlaterHealth", [[Interface\AddOns\Plater\images\nameplate_health_texture]])
LibSharedMedia:Register ("statusbar", "testbar", [[Interface\AddOns\Plater\images\testbar.tga]])

LibSharedMedia:Register ("font", "Oswald", [[Interface\Addons\Plater\fonts\Oswald-Regular.otf]])
LibSharedMedia:Register ("font", "Nueva Std Cond", [[Interface\Addons\Plater\fonts\NuevaStd-Cond.otf]])
LibSharedMedia:Register ("font", "Accidental Presidency", [[Interface\Addons\Plater\fonts\Accidental Presidency.ttf]])
LibSharedMedia:Register ("font", "TrashHand", [[Interface\Addons\Plater\fonts\TrashHand.TTF]])
LibSharedMedia:Register ("font", "Harry P", [[Interface\Addons\Plater\fonts\HARRYP__.TTF]])
LibSharedMedia:Register ("font", "FORCED SQUARE", [[Interface\Addons\Plater\fonts\FORCED SQUARE.ttf]])

--font templates
DF:InstallTemplate ("font", "PLATER_SCRIPTS_NAME", {color = "orange", size = 10, font = "Friz Quadrata TT"})
DF:InstallTemplate ("font", "PLATER_SCRIPTS_TYPE", {color = "gray", size = 9, font = "Friz Quadrata TT"})
DF:InstallTemplate ("font", "PLATER_SCRIPTS_TRIGGER_SPELLID", {color = {0.501961, 0.501961, 0.501961, .5}, size = 9, font = "Friz Quadrata TT"})
DF:InstallTemplate ("font", "PLATER_BUTTON", {color = {1, .8, .2}, size = 10, font = "Friz Quadrata TT"})
DF:InstallTemplate ("font", "PLATER_BUTTON_DISABLED", {color = {1/3, .8/3, .2/3}, size = 10, font = "Friz Quadrata TT"})

--button templates
DF:InstallTemplate ("button", "PLATER_BUTTON_DISABLED", {backdropcolor = {.4, .4, .4, .3}, backdropbordercolor = {0, 0, 0, .5}}, "OPTIONS_BUTTON_TEMPLATE")

DF:NewColor ("PLATER_FRIEND", .71, 1, 1, 1)
DF:NewColor ("PLATER_GUILD", 0.498039, 1, .2, 1)

DF:NewColor ("PLATER_DEBUFF", 1, 0.7117, 0.7117, 1)
DF:NewColor ("PLATER_BUFF", 0.7117, 1, 0.7509, 1)
DF:NewColor ("PLATER_CAST", 0.7117, 0.7784, 1, 1)

--defining reaction constants here isnce they are used within the profile
local UNITREACTION_HOSTILE = 3
local UNITREACTION_NEUTRAL = 4
local UNITREACTION_FRIENDLY = 5

local _
local default_config = {
	
	profile = {
	
		--> save some cvars values so it can restore when a new character login using Plater
		saved_cvars = {},
	
		keybinds = {},
	
		click_space = {140, 28},
		click_space_friendly = {140, 28},
		click_space_always_show = false,
		hide_friendly_castbars = false,
		hide_enemy_castbars = false,
		
		plate_config  = {
			friendlyplayer = {
				enabled = true,
				plate_order = 3,
				only_damaged = true,
				only_thename = true,
				click_through = true,
				show_guild_name = false,
				
				health = {70, 2},
				health_incombat = {70, 2},
				cast = {80, 8},
				cast_incombat = {80, 12},
				mana = {100, 3},
				mana_incombat = {100, 3},
				buff_frame_y_offset = 10,
				
				actorname_text_spacing = 10,
				actorname_text_size = 10,
				actorname_text_font = "Arial Narrow",
				actorname_text_color = {1, 1, 1, 1},
				actorname_text_shadow = true,
				actorname_text_anchor = {side = 8, x = 0, y = 0},
				
				spellname_text_size = 10,
				spellname_text_font = "Arial Narrow",
				spellname_text_color = {1, 1, 1, 1},
				spellname_text_shadow = false,
				spellname_text_anchor = {side = 9, x = 0, y = 0},
				
				spellpercent_text_enabled = false,
				spellpercent_text_size = 10,
				spellpercent_text_font = "Arial Narrow",
				spellpercent_text_color = {1, 1, 1, 1},
				spellpercent_text_shadow = true,
				spellpercent_text_anchor = {side = 11, x = -2, y = 0},
				
				level_text_enabled = false,
				level_text_anchor = {side = 7, x = 0, y = 1},
				level_text_size = 10,
				level_text_font = "Arial Narrow",
				level_text_shadow = false,
				level_text_alpha = 0.3,
				
				percent_text_enabled = false,
				percent_text_ooc = false,
				percent_show_percent = true,
				percent_text_show_decimals = true,
				percent_show_health = false,
				percent_text_size = 9,
				percent_text_font = "Arial Narrow",
				percent_text_shadow = true,
				percent_text_color = {.9, .9, .9, 1},
				percent_text_anchor = {side = 9, x = 0, y = 0},
				percent_text_alpha = 1,
			},
			
			enemyplayer = {
				enabled = true,
				plate_order = 3,
				show_guild_name = false,
				
				use_playerclass_color = true,
				fixed_class_color = {1, .4, .1},
				
				health = {112, 12},
				health_incombat = {112, 12},
				cast = {134, 12},
				cast_incombat = {134, 12},
				mana = {100, 3},
				mana_incombat = {100, 3},
				buff_frame_y_offset = 0,
				
				actorname_text_spacing = 12,
				actorname_text_size = 12,
				actorname_text_font = "Arial Narrow",
				actorname_text_color = {1, 1, 1, 1},
				actorname_text_shadow = false,
				actorname_text_anchor = {side = 4, x = 0, y = 0},
				
				spellname_text_size = 10,
				spellname_text_font = "Arial Narrow",
				spellname_text_color = {1, 1, 1, 1},
				spellname_text_shadow = false,
				spellname_text_anchor = {side = 9, x = 0, y = 0},
				
				spellpercent_text_enabled = true,
				spellpercent_text_size = 10,
				spellpercent_text_font = "Arial Narrow",
				spellpercent_text_color = {1, 1, 1, 1},
				spellpercent_text_shadow = true,
				spellpercent_text_anchor = {side = 11, x = -2, y = 0},
				
				level_text_enabled = true,
				level_text_anchor = {side = 7, x = 0, y = 1},
				level_text_size = 10,
				level_text_font = "Arial Narrow",
				level_text_shadow = false,
				level_text_alpha = 0.3,
				
				percent_text_enabled = true,
				percent_text_ooc = true,
				percent_show_percent = true,
				percent_text_show_decimals = true,
				percent_show_health = true,
				percent_text_size = 9,
				percent_text_font = "Arial Narrow",
				percent_text_shadow = true,
				percent_text_color = {.9, .9, .9, 1},
				percent_text_anchor = {side = 9, x = 0, y = 0},
				percent_text_alpha = 1,
				
				big_actortitle_text_size = 11,
				big_actortitle_text_font = "Arial Narrow",
				big_actortitle_text_color = {1, .8, .0},
				big_actortitle_text_shadow = true,
				big_actorname_text_size = 9,
				big_actorname_text_font = "Arial Narrow",
				big_actorname_text_color = {.5, 1, .5},
				big_actorname_text_shadow = true,
			},

			friendlynpc = {
				only_names = true,
				all_names = false,
				relevance_state = 3,
				plate_order = 3,
				enabled = true,
				
				health = {100, 2},
				health_incombat = {100, 2},
				cast = {100, 12},
				cast_incombat = {100, 12},
				mana = {100, 3},
				mana_incombat = {100, 3},
				buff_frame_y_offset = 0,
				
				actorname_text_spacing = 10,
				actorname_text_size = 10,
				actorname_text_font = "Arial Narrow",
				actorname_text_color = {1, 1, 1, 1},
				actorname_text_shadow = false,
				actorname_text_anchor = {side = 8, x = 0, y = 0},
				
				spellname_text_size = 10,
				spellname_text_font = "Arial Narrow",
				spellname_text_color = {1, 1, 1, 1},
				spellname_text_shadow = false,
				spellname_text_anchor = {side = 9, x = 0, y = 0},
				
				spellpercent_text_enabled = false,
				spellpercent_text_size = 10,
				spellpercent_text_font = "Arial Narrow",
				spellpercent_text_color = {1, 1, 1, 1},
				spellpercent_text_shadow = true,
				spellpercent_text_anchor = {side = 11, x = -2, y = 0},
				
				level_text_enabled = false,
				level_text_anchor = {side = 7, x = 0, y = 1},
				level_text_size = 10,
				level_text_font = "Arial Narrow",
				level_text_shadow = false,
				level_text_alpha = 0.3,
				
				percent_text_enabled = false,
				percent_text_ooc = false,
				percent_show_percent = true,
				percent_text_show_decimals = true,
				percent_show_health = false,
				percent_text_size = 9,
				percent_text_font = "Arial Narrow",
				percent_text_shadow = true,
				percent_text_color = {.9, .9, .9, 1},
				percent_text_anchor = {side = 9, x = 0, y = 0},
				percent_text_alpha = 1,
				
				quest_enabled = true,
				quest_color = {.5, 1, 0},
				
				big_actortitle_text_size = 11,
				big_actortitle_text_font = "Arial Narrow",
				big_actortitle_text_color = {1, .8, .0},
				big_actortitle_text_shadow = true,
				
				big_actorname_text_size = 9,
				big_actorname_text_font = "Arial Narrow",
				big_actorname_text_color = {.5, 1, .5},
				big_actorname_text_shadow = true,
			},
			
			enemynpc = {
				enabled = true,
				plate_order = 3,
				all_names = true,
				
				health = {112, 10},
				health_incombat = {112, 11},
				cast = {124, 12},
				cast_incombat = {124, 12},
				mana = {100, 3},
				mana_incombat = {100, 3},
				buff_frame_y_offset = 0,
				
				actorname_text_spacing = 10,
				actorname_text_size = 11,
				actorname_text_font = "Arial Narrow",
				actorname_text_color = {1, 1, 1, 1},
				actorname_text_shadow = false,
				actorname_text_anchor = {side = 4, x = 0, y = 0},
				
				spellname_text_size = 12,
				spellname_text_font = "Arial Narrow",
				spellname_text_color = {1, 1, 1, 1},
				spellname_text_shadow = true,
				spellname_text_anchor = {side = 9, x = 0, y = 0},
				
				spellpercent_text_enabled = true,
				spellpercent_text_size = 11,
				spellpercent_text_font = "Arial Narrow",
				spellpercent_text_color = {1, 1, 1, 1},
				spellpercent_text_shadow = true,
				spellpercent_text_anchor = {side = 11, x = -2, y = 0},
				
				level_text_enabled = true,
				level_text_anchor = {side = 7, x = 0, y = 1},
				level_text_size = 8,
				level_text_font = "Arial Narrow",
				level_text_shadow = false,
				level_text_alpha = 0.3,
				
				percent_text_enabled = true,
				percent_text_ooc = false,
				percent_show_percent = true,
				percent_text_show_decimals = true,
				percent_show_health = true,
				percent_text_size = 9,
				percent_text_font = "Arial Narrow",
				percent_text_shadow = true,
				percent_text_color = {.9, .9, .9, 1},
				percent_text_anchor = {side = 9, x = 0, y = 0},
				percent_text_alpha = 1,
				
				quest_enabled = true,
				quest_color_enemy = {1, .369, 0},
				quest_color_neutral = {1, .65, 0},
				
				--no color / it'll auto colour by the reaction
				big_actortitle_text_size = 10,
				big_actortitle_text_font = "Arial Narrow",
				big_actortitle_text_shadow = true,
				--big_actortitle_text_color = {1, .8, .0},
				
				big_actorname_text_size = 10,
				big_actorname_text_font = "Arial Narrow",
				big_actorname_text_shadow = true,
				--big_actorname_text_color = {.5, 1, .5},
			},
	
			player = {
				enabled = true,
				click_through = false,
				plate_order = 3,
				health = {150, 12},
				health_incombat = {150, 12},
				cast = {140, 8},
				cast_incombat = {140, 12},
				mana = {150, 8},
				mana_incombat = {150, 8},
				buff_frame_y_offset = 0,
				y_position_offset = -50, --deprecated
				pvp_always_incombat = true,
				healthbar_color = {0.564706, 0.933333, 0.564706, 1},
				healthbar_color_by_hp = false,
				
				actorname_text_spacing = 10,
				actorname_text_size = 10,
				actorname_text_font = "Arial Narrow",
				actorname_text_color = {1, 1, 1, 1},
				actorname_text_shadow = false,
				actorname_text_anchor = {side = 8, x = 0, y = 0},
				
				spellname_text_size = 10,
				spellname_text_font = "Arial Narrow",
				spellname_text_color = {1, 1, 1, 1},
				spellname_text_shadow = false,
				spellname_text_anchor = {side = 9, x = 0, y = 0},
				
				level_text_enabled = false,
				level_text_anchor = {side = 7, x = 0, y = 1},
				level_text_size = 10,
				level_text_font = "Arial Narrow",
				level_text_shadow = false,
				level_text_alpha = 0.3,
				
				percent_text_enabled = true,
				percent_text_ooc = true,
				percent_show_percent = true,
				percent_text_show_decimals = true,
				percent_show_health = true,
				percent_text_size = 10,
				percent_text_font = "Arial Narrow",
				percent_text_shadow = true,
				percent_text_color = {.9, .9, .9, 1},
				percent_text_anchor = {side = 9, x = 0, y = 0},
				percent_text_alpha = 1,
				
				power_percent_text_enabled = true,
				power_percent_text_size = 9,
				power_percent_text_font = "Arial Narrow",
				power_percent_text_shadow = true,
				power_percent_text_color = {.9, .9, .9, 1},
				power_percent_text_anchor = {side = 9, x = 0, y = 0},
				power_percent_text_alpha = 1,
			},
		},
		
		last_news_time = 0,
		disable_omnicc_on_auras = false,
		
		resources = {
			scale = 1,
			y_offset = 0,
			y_offset_target = 28,
		},
		
		--> special unit
		pet_width_scale = 0.7,
		pet_height_scale = 1,
		minor_width_scale = 0.7,
		minor_height_scale = 1,
		
		castbar_target_show = false,
		castbar_target_anchor = {side = 5, x = 0, y = 0},
		castbar_target_text_size = 10,
		castbar_target_shadow = true,
		castbar_target_color = {0.968627, 0.992156, 1, 1},
		castbar_target_font = "Arial Narrow",
		
		--> store spells from the latest event the player has been into
		captured_spells = {},

		--script tab
		script_data = {},
		script_data_trash = {}, --deleted scripts are placed here, they can be restored in 30 days
		script_auto_imported = {}, --store the name and revision of scripts imported from the Plater script library
		script_banned_user = {}, --players banned from sending scripts to this player
		
		--hooking tab
		hook_data = {},
		hook_data_trash = {}, --deleted scripts are placed here, they can be restored in 30 days
		hook_auto_imported = {}, --store the name and revision of scripts imported from the Plater script library
		
		patch_version = 0,
		
		health_cutoff = true,
		health_cutoff_extra_glow = false,
		health_cutoff_hide_divisor = false,
		
		update_throttle = 0.25,
		culling_distance = 100,
		use_playerclass_color = true, --friendly player
		
		use_health_animation = false,
		health_animation_time_dilatation = 2.615321,
		
		use_color_lerp = false,
		color_lerp_speed = 12,
		
		height_animation = false,
		height_animation_speed = 15,
		
		healthbar_framelevel = 0,
		castbar_framelevel = 0,
		
		aura_enabled = true,
		aura_show_tooltip = false,
		aura_width = 26,
		aura_height = 16,
		
		--> aura frame 1
		aura_x_offset = 0,
		aura_y_offset = 0,
		aura_grow_direction = 2, --> center
		
		--> aura frame 2
		buffs_on_aura2 = false,
		aura2_x_offset = 0,
		aura2_y_offset = 0,
		aura2_grow_direction = 2, --> center
		
		aura_alpha = 0.85,
		aura_custom = {},
		
		--use blizzard aura tracking
		aura_use_default = false,
		
		aura_timer = true,
		aura_timer_text_size = 15,
		aura_timer_text_font = "Arial Narrow",
		aura_timer_text_anchor = {side = 9, x = 0, y = 0},
		aura_timer_text_shadow = true,
		aura_timer_text_color = {1, 1, 1, 1},

		aura_stack_anchor = {side = 8, x = 0, y = 0},
		aura_stack_size = 10,
		aura_stack_font = "Arial Narrow",
		aura_stack_shadow = true,
		aura_stack_color = {1, 1, 1, 1},
		
		extra_icon_anchor = {side = 6, x = -4, y = 4},
		extra_icon_show_timer = true,
		extra_icon_width = 30,
		extra_icon_height = 18,
		extra_icon_wide_icon = true,
		extra_icon_caster_name = true,
		extra_icon_backdrop_color = {0, 0, 0, 0.612853},
		extra_icon_border_color = {0, 0, 0, 1},
		
		debuff_show_cc = true, --extra frame show cc
		debuff_show_cc_border = {.3, .2, .2, 1},
		extra_icon_show_purge = false, --extra frame show purge
		extra_icon_show_purge_border = {0, .925, 1, 1},
		
		extra_icon_auras = {}, --auras for buff special tab
		extra_icon_auras_mine = {}, --auras in the buff special that are only cast by the player
		
		aura_width_personal = 32,
		aura_height_personal = 20,
		aura_show_buffs_personal = true,
		aura_show_debuffs_personal = true,
		
		aura_show_important = true,
		aura_show_dispellable = true,
		aura_show_aura_by_the_player = true,
		aura_show_buff_by_the_unit = true,
		
		aura_border_colors = {
			steal_or_purge = {0, .5, .98, 1},
			is_buff = {0, .65, .1, 1},
			is_show_all = {.7, .1, .1, 1},
		},
		
		--store a table with spell name keys and with a value of a table with all spell IDs that has that exact name
		aura_cache_by_name = {
			["banner of the horde"] = {
				61574,
			},
			["challenger's might"] = {
				206150,
			},
			["banner of the alliance"] = {
				61573,
			},		
		},		
		
		aura_tracker = {
			buff = {},
			debuff = {},
			buff_ban_percharacter = {},
			debuff_ban_percharacter = {},
			options = {},
			track_method = 0x1,
			buff_banned = { 
				--banner of alliance and horde on training dummies
				[61574] = true, 
				[61573] = true,
				--challenger's might on mythic+
				[206150] = true, 
			},
			debuff_banned = {},
			buff_tracked = {},
			debuff_tracked = {},
		},
		
		not_affecting_combat_enabled = false,
		not_affecting_combat_alpha = 0.799999,
		range_check_enabled = true,
		range_check_alpha = 0.5,
		target_highlight = true,
		target_highlight_alpha = 0.7,
		
		target_shady_alpha = 0.6,
		target_shady_enabled = true,
		target_shady_combat_only = true,
		
		hover_highlight = true,
		highlight_on_hover_unit_model = false,
		hover_highlight_alpha = .30,
		
		auto_toggle_friendly_enabled = false,
		auto_toggle_friendly = {
			["party"] = false,
			["raid"] = false,
			["arena"] = false,
			["world"] =  true,
			["cities"] = true,
		},
		
		stacking_nameplates_enabled = true,
		
		auto_toggle_stacking_enabled = false,
		auto_toggle_stacking = {
			["party"] = true,
			["raid"] = true,
			["arena"] = true,
			["world"] =  true,
			["cities"] = false,
		},
		
		spell_animations = true,
		spell_animations_scale = 1.25,
		
		spell_animation_list = {
		
			--chaos bolt
			[116858] = {
				{
					enabled = true,
					duration = 0.075, --seconds
					animation_type = "scale",
					cooldown = 0.75, --seconds
					scale_upX = 1.075,
					scale_upY = 1.075,
					scale_downX = 0.915,
					scale_downY = 0.915,
				},
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = 0.1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.15,
					amplitude = 2,
					frequency = 60,
					fade_in = 0.05,
					fade_out = 0.10,
					cooldown = 0.25,
				},
				info = {
					time = 0,
					desc = "",
					class = "WARLOCK",
					spellid = 116858,
				}
			},
		
			--seed of corruption
			[27285] = {
				{
					enabled = true,
					duration = 0.075, --seconds
					animation_type = "scale",
					cooldown = 0.75, --seconds
					scale_upX = 1.1,
					scale_upY = 1.1,
					scale_downX = 0.9,
					scale_downY = 0.9,
				},
				info = {
					time = 0,
					desc = "",
					class = "WARLOCK",
					spellid = 27285,
				}
			},
			
			--hand of guldan
			[86040] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = 0.1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.15,
					amplitude = 2,
					frequency = 20,
					fade_in = 0.05,
					fade_out = 0.10,
					cooldown = 0.25,
				},
				info = {
					time = 0,
					desc = "",
					class = "WARLOCK",
					spellid = 86040,
				}
			},
			
			--demonbolt
			[264178] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .2,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.15,
					amplitude = 3,
					frequency = 25,
					fade_in = 0.01,
					fade_out = 0.08,
					cooldown = 0.25,
				},
				info = {
					time = 0,
					desc = "",
					class = "WARLOCK",
					spellid = 264178,
				}				
			},
			
			--implosion
			[196278] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .2,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.05,
					amplitude = 0.75,
					frequency = 200,
					fade_in = 0.01,
					fade_out = 0.01,
					cooldown = 0.0,
				},
				info = {
					time = 0,
					desc = "",
					class = "WARLOCK",
					spellid = 196278,
				}			
			},
			
			--Secret Technique (Rogue)
			[280720] = {
			   [1] = {
			      ["enabled"] = true,
			      ["fade_out"] = 0.089999996125698,
			      ["absolute_sineX"] = false,
			      ["duration"] = 0.19999998807907,
			      ["absolute_sineY"] = false,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 0.1,
			      ["amplitude"] = 0.89999997615814,
			      ["critical_scale"] = 1.05,
			      ["fade_in"] = 0.0099999997764826,
			      ["scaleY"] = 1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 200,
			   },
			   ["info"] = {
			      ["time"] = 1539292087,
			      ["class"] = "ROGUE",
			      ["spellid"] = 280720,
			      ["desc"] = "",
			   },
			},
			
			--Shadowstrike (Rogue)
			[185438] = {
			   [1] = {
			      ["enabled"] = true,
			      ["fade_out"] = 0.19999998807907,
			      ["duration"] = 0.099999994039536,
			      ["absolute_sineX"] = false,
			      ["absolute_sineY"] = true,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 0.099998474121094,
			      ["critical_scale"] = 1.05,
			      ["amplitude"] = 6.460000038147,
			      ["fade_in"] = 0,
			      ["scaleY"] = -1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 25,
			   },
			   [2] = {
			      ["enabled"] = true,
			      ["scale_upX"] = 1.0299999713898,
			      ["scale_upY"] = 1.0299999713898,
			      ["cooldown"] = 0.75,
			      ["duration"] = 0.05,
			      ["scale_downY"] = 0.96999996900559,
			      ["scale_downX"] = 0.96999996900559,
			      ["animation_type"] = "scale",
			   },
			   ["info"] = {
			      ["time"] = 1539204014,
			      ["class"] = "ROGUE",
			      ["spellid"] = 185438,
			      ["desc"] = "",
			   },
			},
			
			--sinister strike (outlaw)
			[197834] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.12,
					amplitude = 1,
					frequency = 25,
					fade_in = 0.01,
					fade_out = 0.02,
					cooldown = 0.5,
				},
				info = {
					time = 0,
					desc = "",
					class = "ROGUE",
					spellid = 197834,
				}				
			},
			
			--Eviscerate (Rogue)
			[196819] = {
			   [1] = {
			      ["animation_type"] = "scale",
			      ["scale_upX"] = 1.1999999284744,
			      ["enabled"] = true,
			      ["scale_downX"] = 0.89999997615814,
			      ["scale_downY"] = 0.89999997615814,
			      ["duration"] = 0.04,
			      ["cooldown"] = 0.75,
			      ["scale_upY"] = 1.2999999523163,
			   },
			   [2] = {
			      ["enabled"] = true,
			      ["fade_out"] = 0.1799999922514,
			      ["absolute_sineX"] = false,
			      ["absolute_sineY"] = true,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 1,
			      ["duration"] = 0.21999999880791,
			      ["amplitude"] = 5,
			      ["fade_in"] = 0.0099999997764826,
			      ["scaleY"] = 1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 3.3099999427795,
			   },
			   ["info"] = {
			      ["spellid"] = 196819,
			      ["class"] = "ROGUE",
			      ["time"] = 0,
			      ["desc"] = "",
			   },
			},

			--Pistol Shot (Rogue)
			[185763] =  {
			   [1] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.25999999046326,
			      ["absolute_sineX"] = false,
			      ["duration"] = 0.15999999642372,
			      ["absolute_sineY"] = true,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 0.099998474121094,
			      ["amplitude"] = 3.6583230495453,
			      ["critical_scale"] = 1.05,
			      ["fade_in"] = 0.0099999997764826,
			      ["scaleY"] = 1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 23.525663375854,
			   },
			   [2] =  {
			      ["animation_type"] = "scale",
			      ["scale_upX"] = 1.0299999713898,
			      ["enabled"] = true,
			      ["scale_downX"] = 0.96999996900559,
			      ["scale_downY"] = 0.96999996900559,
			      ["duration"] = 0.05,
			      ["cooldown"] = 0.75,
			      ["scale_upY"] = 1.0299999713898,
			   },
			   ["info"] =  {
			      ["time"] = 1539275610,
			      ["class"] = "ROGUE",
			      ["spellid"] = 185763,
			      ["desc"] = "",
			   },
			},

			--Dispatch (Rogue)
			[2098] =  {
			   [1] =  {
			      ["scale_upY"] = 1.1999999284744,
			      ["scale_upX"] = 1.1000000238419,
			      ["enabled"] = true,
			      ["scale_downX"] = 0.89999997615814,
			      ["scale_downY"] = 0.89999997615814,
			      ["duration"] = 0.04,
			      ["cooldown"] = 0.75,
			      ["animation_type"] = "scale",
			   },
			   [2] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.079999998211861,
			      ["absolute_sineX"] = false,
			      ["absolute_sineY"] = true,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 1,
			      ["duration"] = 0.21999999880791,
			      ["amplitude"] = 1.5,
			      ["fade_in"] = 0,
			      ["scaleY"] = 1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 2.710000038147,
			   },
			   ["info"] =  {
			      ["time"] = 1539293610,
			      ["class"] = "ROGUE",
			      ["spellid"] = 2098,
			      ["desc"] = "",
			   },
			},

			--Envenom (Rogue)
			[32645] =  {
			   [1] =  {
			      ["animation_type"] = "scale",
			      ["scale_upX"] = 1.1000000238419,
			      ["enabled"] = true,
			      ["scale_downX"] = 0.89999997615814,
			      ["scale_downY"] = 0.89999997615814,
			      ["duration"] = 0.04,
			      ["cooldown"] = 0.75,
			      ["scale_upY"] = 1.1999999284744,
			   },
			   [2] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.1799999922514,
			      ["absolute_sineX"] = false,
			      ["absolute_sineY"] = true,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 1,
			      ["duration"] = 0.12000000476837,
			      ["amplitude"] = 4.0999999046326,
			      ["fade_in"] = 0.0099999997764826,
			      ["scaleY"] = 1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 2.6099998950958,
			   },
			   ["info"] =  {
			      ["spellid"] = 32645,
			      ["class"] = "ROGUE",
			      ["time"] = 0,
			      ["desc"] = "",
			   },
			},

			
			--Between the Eyes (Rogue)
			[199804] =  {
			   [1] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.09,
			      ["absolute_sineX"] = false,
			      ["duration"] = 0.19999998807907,
			      ["absolute_sineY"] = true,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 1,
			      ["amplitude"] = 1.1699999570847,
			      ["critical_scale"] = 1.05,
			      ["fade_in"] = 0.0099999997764826,
			      ["scaleY"] = 0.88999938964844,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 23.525676727295,
			   },
			   [2] =  {
			      ["enabled"] = true,
			      ["scale_upX"] = 1.0499999523163,
			      ["animation_type"] = "scale",
			      ["cooldown"] = 0.75,
			      ["duration"] = 0.050000000745058,
			      ["scale_downY"] = 1,
			      ["scale_downX"] = 1,
			      ["scale_upY"] = 1.0499999523163,
			   },
			   ["info"] =  {
			      ["time"] = 1539293872,
			      ["class"] = "ROGUE",
			      ["spellid"] = 199804,
			      ["desc"] = "",
			   },
			},

			
			--mutilate (assassination)
			[5374] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.12,
					amplitude = 1,
					frequency = 25,
					fade_in = 0.01,
					fade_out = 0.02,
					cooldown = 0.5,
				},
				info = {
					time = 0,
					desc = "",
					class = "ROGUE",
					spellid = 5374,
				}
			},
			
			--envenom (assassination)
			[32645] = {
				{
					enabled = true,
					duration = 0.04, --seconds
					animation_type = "scale",
					cooldown = 0.75, --seconds
					scale_upX = 1.1,
					scale_upY = 1.1,
					scale_downX = 0.9,
					scale_downY = 0.9,
				},
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = 1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = true,
					duration = 0.08,
					amplitude = 10,
					frequency = 4.1,
					fade_in = 0.01,
					fade_out = 0.18,
					cooldown = 0.5,
				},
				info = {
					time = 0,
					desc = "",
					class = "ROGUE",
					spellid = 32645,
				}
			},
			
			--toxic blade (assassination)
			[245388] = {
				{
					enabled = true,
					duration = 0.03, --seconds
					animation_type = "scale",
					cooldown = 0.75, --seconds
					scale_upX = 1.1,
					scale_upY = 1.1,
					scale_downX = 0.9,
					scale_downY = 0.9,
				},
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = 1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.06,
					amplitude = 5,
					frequency = 2,
					fade_in = 0.01,
					fade_out = 0.01,
					cooldown = 0.5,
				},
				info = {
					time = 0,
					desc = "",
					class = "ROGUE",
					spellid = 245388,
				}
			},
			
			--arcane blast (mage)
			[30451] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.12,
					amplitude = 1,
					frequency = 25,
					fade_in = 0.01,
					fade_out = 0.02,
					cooldown = 0.5,
				},
				info = {
					time = 0,
					desc = "",
					class = "MAGE",
					spellid = 30451,
				}
			},
			
			--arcane missiles (mage)
			[7268] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .2,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.1,
					amplitude = 0.75,
					frequency = 200,
					fade_in = 0.01,
					fade_out = 0.01,
					cooldown = 0.0,
				},
				info = {
					time = 0,
					desc = "",
					class = "MAGE",
					spellid = 7268,
				}
			},
			
			--arcane barrage (mage)
			[44425] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.12,
					amplitude = 1,
					frequency = 25,
					fade_in = 0.01,
					fade_out = 0.02,
					cooldown = 0.5,
				},
				info = {
					time = 0,
					desc = "",
					class = "MAGE",
					spellid = 44425,
				}
			},
			
			--glacial spike (frost mage)
			[228600] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = true,
					duration = 0.1,
					amplitude = 10,
					frequency = 1,
					fade_in = 0.01,
					fade_out = 0.09,
					cooldown = 0.5,
					critical_scale = 1.2,
				},
				info = {
					time = 0,
					desc = "",
					class = "MAGE",
					spellid = 228600,
				}
			},
			
			--flurry (frost mage)
			[228354] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.12,
					amplitude = 1,
					frequency = 25,
					fade_in = 0.01,
					fade_out = 0.02,
					cooldown = 0.5,
				},
				info = {
					time = 0,
					desc = "",
					class = "MAGE",
					spellid = 228354,
				}
			},
			
			--ice lance (frost mage)
			[228598] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.12,
					amplitude = 2,
					frequency = 25,
					fade_in = 0.01,
					fade_out = 0.02,
					cooldown = 0.5,
				},
				info = {
					time = 0,
					desc = "",
					class = "MAGE",
					spellid = 228598,
				}
			},
			
			--pyro (fire mage)
			[11366] = {
				{
					enabled = true,
					duration = 0.05, --seconds
					animation_type = "scale",
					cooldown = 0.75, --seconds
					scale_upX = 1.15,
					scale_upY = 1.15,
					scale_downX = 0.8,
					scale_downY = 0.8,
				},
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = true,
					duration = 0.1,
					amplitude = 10,
					frequency = 1,
					fade_in = 0.01,
					fade_out = 0.09,
					cooldown = 0.5,
					critical_scale = 1.2,
				},
				info = {
					time = 0,
					desc = "",
					class = "MAGE",
					spellid = 11366,
				}
			},
			
			--dragon's breath (fire mage)
			[31661] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .2,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.1,
					amplitude = 0.75,
					frequency = 200,
					fade_in = 0.01,
					fade_out = 0.01,
					cooldown = 0.0,
				},
				info = {
					time = 0,
					desc = "",
					class = "MAGE",
					spellid = 31661,
				}
			},
			
			--fire blast (fire mage)
			[108853] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.12,
					amplitude = 1,
					frequency = 25,
					fade_in = 0.01,
					fade_out = 0.02,
					cooldown = 0.5,
				},
				info = {
					time = 0,
					desc = "",
					class = "MAGE",
					spellid = 108853,
				}
			},
			
			--Blade of Justice (paladin)
			[184575] = {
				{
					enabled = true,
					duration = 0.05, --seconds
					animation_type = "scale",
					cooldown = 0.75, --seconds
					scale_upX = 1.05,
					scale_upY = 1.05,
					scale_downX = 0.95,
					scale_downY = 0.95,
				},
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = true,
					duration = 0.1,
					amplitude = 2,
					frequency = 1,
					fade_in = 0.01,
					fade_out = 0.09,
					cooldown = 0.5,
					critical_scale = 1.2,
				},
				info = {
					time = 0,
					desc = "",
					class = "PALADIN",
					spellid = 184575,
				}
			},
			
			--Hammer of the Righteous (paladin)
			[53595] = {
				{
					enabled = true,
					duration = 0.05, --seconds
					animation_type = "scale",
					cooldown = 0.75, --seconds
					scale_upX = 1.03,
					scale_upY = 1.03,
					scale_downX = 0.97,
					scale_downY = 0.97,
				},
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = true,
					duration = 0.1,
					amplitude = 3,
					frequency = 1,
					fade_in = 0.01,
					fade_out = 0.09,
					cooldown = 0.5,
					critical_scale = 1.05,
				},
				info = {
					time = 0,
					desc = "",
					class = "PALADIN",
					spellid = 53595,
				}
			},
			
			--Crusader Strike (paladin)
			[35395] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.12,
					amplitude = 1,
					frequency = 25,
					fade_in = 0.01,
					fade_out = 0.02,
					cooldown = 0.5,
				},
				info = {
					time = 0,
					desc = "",
					class = "PALADIN",
					spellid = 35395,
				}
			}, 
			
			--Avenger's Shield (paladin)
			[31935] = {
				{
					enabled = true,
					duration = 0.05, --seconds
					animation_type = "scale",
					cooldown = 0.75, --seconds
					scale_upX = 1.03,
					scale_upY = 1.03,
					scale_downX = 0.97,
					scale_downY = 0.97,
				},
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = 1,
					scaleY = 1,
					absolute_sineX = true,
					absolute_sineY = false,
					duration = 0.1,
					amplitude = 6,
					frequency = 1,
					fade_in = 0.01,
					fade_out = 0.09,
					cooldown = 0.5,
					critical_scale = 1.05,
				},
				info = {
					time = 0,
					desc = "",
					class = "PALADIN",
					spellid = 31935,
				}
			},
			
			--Judgment (paladin)
			[275779] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = -1, --absolute sine * -1 makes the shake always go down
					absolute_sineX = false,
					absolute_sineY = true,
					duration = 0.12,
					amplitude = 1,
					frequency = 25,
					fade_in = 0.01,
					fade_out = 0.02,
					cooldown = 0.5,
				},
				info = {
					time = 0,
					desc = "",
					class = "PALADIN",
					spellid = 275779,
				}
			},
			
			--Thunder Clap (warrior)
			[6343] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .2,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.12,
					amplitude = 0.95,
					frequency = 200,
					fade_in = 0.01,
					fade_out = 0.01,
					cooldown = 0.1,
				},
				info = {
					time = 0,
					desc = "",
					class = "WARRIOR",
					spellid = 6343,
				}
			},
			
			--Heroic Leap (warrior)
			[52174] = {
				{
					enabled = true,
					duration = 0.075, --seconds
					animation_type = "scale",
					cooldown = 0.75, --seconds
					scale_upX = 1.15,
					scale_upY = 1.15,
					scale_downX = 0.8,
					scale_downY = 0.8,
				},
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .15,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.3,
					amplitude = 6,
					frequency = 50,
					fade_in = 0.01,
					fade_out = 0.2,
					cooldown = 0.5,
					critical_scale = 1.2,
				},
				info = {
					time = 0,
					desc = "",
					class = "WARRIOR",
					spellid = 52174,
				}
			}, 
			
			--Devastate (warrior)
			[20243] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.12,
					amplitude = 1,
					frequency = 25,
					fade_in = 0.01,
					fade_out = 0.02,
					cooldown = 0.5,
				},
				info = {
					time = 0,
					desc = "",
					class = "WARRIOR",
					spellid = 20243,
				}
			}, 
			
			--Shockwave (warrior)
			[46968] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.10,
					amplitude = 0.95,
					frequency = 120,
					fade_in = 0.01,
					fade_out = 0.01,
					cooldown = 0.1,
				},
				info = {
					time = 0,
					desc = "",
					class = "WARRIOR",
					spellid = 46968,
				}
			}, 
			
			--Death Strike (dk)
			[49998] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.13,
					amplitude = 1.8,
					frequency = 25,
					fade_in = 0.01,
					fade_out = 0.02,
					cooldown = 0.5,
				},
				info = {
					time = 0,
					desc = "",
					class = "DEATHKNIGHT",
					spellid = 49998,
				}
			}, 
			
			--Frost Strike (dk)
			[222026] = {
				{
					enabled = true,
					duration = 0.04, --seconds
					animation_type = "scale",
					cooldown = 0.75, --seconds
					scale_upX = 1.1,
					scale_upY = 1.1,
					scale_downX = 0.9,
					scale_downY = 0.9,
				},
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = 1,
					scaleY = -1,
					absolute_sineX = false,
					absolute_sineY = true,
					duration = 0.08,
					amplitude = 10,
					frequency = 3.1,
					fade_in = 0.01,
					fade_out = 0.18,
					cooldown = 0.5,
				},
				info = {
					time = 0,
					desc = "",
					class = "DEATHKNIGHT",
					spellid = 222026,
				}
			}, 
			
			--breath of sindragosa
			[155166] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .2,
					scaleY = .6,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.2,
					amplitude = 0.45,
					frequency = 200,
					fade_in = 0.01,
					fade_out = 0.01,
					cooldown = 0.0,
				},
				info = {
					time = 0,
					desc = "",
					class = "DEATHKNIGHT",
					spellid = 155166,
				}
			},
			
			--Obliterate (dk)
			[222024] = {
				{
					enabled = true,
					duration = 0.035, --seconds
					animation_type = "scale",
					cooldown = 0.75, --seconds
					scale_upX = 1.1,
					scale_upY = 1.1,
					scale_downX = 0.9,
					scale_downY = 0.9,
				},
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = 1,
					scaleY = -1,
					absolute_sineX = true,
					absolute_sineY = true,
					duration = 0.075,
					amplitude = 1.8,
					frequency = 50,
					fade_in = 0.01,
					fade_out = 0.02,
					cooldown = 0.5,
					critical_scale = 2,
				},
				info = {
					time = 0,
					desc = "",
					class = "DEATHKNIGHT",
					spellid = 222024,
				}
			},
			
			--Scourge Strike (dk)
			[55090] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = 1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = true,
					duration = 0.08,
					amplitude = 10,
					frequency = 4.1,
					fade_in = 0.01,
					fade_out = 0.18,
					cooldown = 0.5,
				},
				info = {
					time = 0,
					desc = "",
					class = "DEATHKNIGHT",
					spellid = 55090,
				}
			}, 
			
			--Festering Strike (dk)
			[85948] = {
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = .1,
					scaleY = 1,
					absolute_sineX = false,
					absolute_sineY = false,
					duration = 0.12,
					amplitude = 1,
					frequency = 25,
					fade_in = 0.01,
					fade_out = 0.02,
					cooldown = 0.5,
				},
				info = {
					time = 0,
					desc = "",
					class = "DEATHKNIGHT",
					spellid = 85948,
				}
			}, 
			
			--Heart Strike (dk)
			[206930] = {
				{
					enabled = true,
					duration = 0.035, --seconds
					animation_type = "scale",
					cooldown = 0.75, --seconds
					scale_upX = 1.1,
					scale_upY = 1.1,
					scale_downX = 0.9,
					scale_downY = 0.9,
				},
				{
					enabled = true,
					animation_type = "frameshake",
					scaleX = -1,
					scaleY = 1,
					absolute_sineX = true,
					absolute_sineY = true,
					duration = 0.075,
					amplitude = 1.8,
					frequency = 50,
					fade_in = 0.01,
					fade_out = 0.02,
					cooldown = 0.5,
					critical_scale = 2,
				},
				info = {
					time = 0,
					desc = "",
					class = "DEATHKNIGHT",
					spellid = 206930,
				}
			}, 
			
			--Chi Burst (Monk)
			[148135] =  {
			   [1] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.09,
			      ["absolute_sineX"] = false,
			      ["duration"] = 0.099999994039536,
			      ["absolute_sineY"] = false,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 1,
			      ["amplitude"] = 1.75,
			      ["critical_scale"] = 1.05,
			      ["fade_in"] = 0.01,
			      ["scaleY"] = 1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 60.874122619629,
			   },
			   ["info"] =  {
			      ["time"] = 1539295958,
			      ["class"] = "MONK",
			      ["spellid"] = 148135,
			      ["desc"] = "",
			   },
			},

			--Blackout Strike (Monk)
			[205523] =  {
			   [1] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.09,
			      ["absolute_sineX"] = false,
			      ["duration"] = 0.099999994039536,
			      ["absolute_sineY"] = false,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 0.099998474121094,
			      ["amplitude"] = 3,
			      ["critical_scale"] = 1.05,
			      ["fade_in"] = 0.01,
			      ["scaleY"] = 1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 1,
			   },
			   ["info"] =  {
			      ["time"] = 1539295885,
			      ["class"] = "MONK",
			      ["spellid"] = 205523,
			      ["desc"] = "",
			   },
			},

			--Tiger Palm (Monk)
			[100780] =  {
			   [1] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.09,
			      ["absolute_sineX"] = false,
			      ["duration"] = 0.099999994039536,
			      ["absolute_sineY"] = false,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 0.1,
			      ["amplitude"] = 1,
			      ["critical_scale"] = 1.05,
			      ["fade_in"] = 0.01,
			      ["scaleY"] = 1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 1,
			   },
			   ["info"] =  {
			      ["time"] = 1539295910,
			      ["class"] = "MONK",
			      ["spellid"] = 100780,
			      ["desc"] = "",
			   },
			},
			
			--Blackout Kick (Monk)
			[100784] =  {
			   [1] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.09,
			      ["absolute_sineX"] = false,
			      ["duration"] = 0.099999994039536,
			      ["absolute_sineY"] = false,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 1,
			      ["amplitude"] = 3,
			      ["critical_scale"] = 1.05,
			      ["fade_in"] = 0.01,
			      ["scaleY"] = 1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 1,
			   },
			   ["info"] =  {
			      ["time"] = 1539296312,
			      ["class"] = "MONK",
			      ["spellid"] = 100784,
			      ["desc"] = "",
			   },
			},

			--Spinning Crane Kick (Monk)
			[107270] =  {
			   [1] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.089999996125698,
			      ["duration"] = 0.1499999910593,
			      ["absolute_sineX"] = false,
			      ["absolute_sineY"] = false,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 0.099998474121094,
			      ["amplitude"] = 0.1499999910593,
			      ["critical_scale"] = 1.05,
			      ["fade_in"] = 0.0099999997764826,
			      ["scaleY"] = 1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 200,
			   },
			   ["info"] =  {
			      ["spellid"] = 107270,
			      ["class"] = "MONK",
			      ["time"] = 1539296490,
			      ["desc"] = "",
			   },
			},


			--Fists of Fury (Monk)
			[117418] =  {
			   [1] =  {
			      ["scaleY"] = 1,
			      ["fade_out"] = 0.1499999910593,
			      ["absolute_sineX"] = false,
			      ["duration"] = 0.1799999922514,
			      ["absolute_sineY"] = false,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 0.099998474121094,
			      ["enabled"] = true,
			      ["amplitude"] = 0.1499999910593,
			      ["fade_in"] = 0.0099999997764826,
			      ["critical_scale"] = 1.05,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 116.00999450684,
			   },
			   ["info"] =  {
			      ["time"] = 1539296387,
			      ["class"] = "MONK",
			      ["spellid"] = 117418,
			      ["desc"] = "",
			   },
			},

			
			--Rising Sun Kick (Monk)
			[185099] =  {
			   [1] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.18999999761581,
			      ["absolute_sineX"] = false,
			      ["duration"] = 0.19999998807907,
			      ["absolute_sineY"] = true,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 0,
			      ["amplitude"] = 3,
			      ["critical_scale"] = 1.05,
			      ["fade_in"] = 0,
			      ["scaleY"] = 0.84999847412109,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 1,
			   },
			   ["info"] =  {
			      ["time"] = 1539712435,
			      ["class"] = "MONK",
			      ["spellid"] = 185099,
			      ["desc"] = "",
			   },
			},
			
			--Blade Dance (Demon Hunter)
			[199552] =  {
			   [1] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.099999994039536,
			      ["duration"] = 0.099999994039536,
			      ["absolute_sineX"] = true,
			      ["absolute_sineY"] = false,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 0.20000076293945,
			      ["critical_scale"] = 1.05,
			      ["amplitude"] = 2.5,
			      ["fade_in"] = 0,
			      ["scaleY"] = 0.79999923706055,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 1,
			   },
			   [2] =  {
			      ["enabled"] = true,
			      ["scale_upX"] = 1.0299999713898,
			      ["animation_type"] = "scale",
			      ["scale_downX"] = 0.96999996900559,
			      ["scale_downY"] = 0.96999996900559,
			      ["duration"] = 0.05,
			      ["cooldown"] = 0.75,
			      ["scale_upY"] = 1.0299999713898,
			   },
			   ["info"] =  {
			      ["spellid"] = 199552,
			      ["class"] = "DEMONHUNTER",
			      ["time"] = 1539717392,
			      ["desc"] = "",
			   },
			},
			--Chaos Strike (Demon Hunter)
			[199547] =  {
			   [1] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.089999996125698,
			      ["absolute_sineX"] = false,
			      ["duration"] = 0.1,
			      ["absolute_sineY"] = true,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 0.59999847412109,
			      ["amplitude"] = 3,
			      ["critical_scale"] = 1.05,
			      ["fade_in"] = 0.0099999997764826,
			      ["scaleY"] = 1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 1,
			   },
			   [2] =  {
			      ["enabled"] = true,
			      ["scale_upX"] = 1.039999961853,
			      ["animation_type"] = "scale",
			      ["cooldown"] = 0.75,
			      ["duration"] = 0.05,
			      ["scale_downY"] = 0.96999996900558,
			      ["scale_downX"] = 0.96999996900558,
			      ["scale_upY"] = 1.039999961853,
			   },
			   ["info"] =  {
			      ["time"] = 1539717795,
			      ["class"] = "DEMONHUNTER",
			      ["spellid"] = 199547,
			      ["desc"] = "",
			   },
			},
			--Demon's Bite (Demon Hunter)
			[162243] =  {
			   [1] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.089999996125698,
			      ["duration"] = 0.099999994039535,
			      ["absolute_sineX"] = false,
			      ["absolute_sineY"] = true,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 0.099998474121094,
			      ["critical_scale"] = 1.05,
			      ["amplitude"] = 1,
			      ["fade_in"] = 0.0099999997764826,
			      ["scaleY"] = 1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 1,
			   },
			   ["info"] =  {
			      ["spellid"] = 162243,
			      ["class"] = "DEMONHUNTER",
			      ["time"] = 1539717356,
			      ["desc"] = "",
			   },
			},
			--Eye Beam (Demon Hunter)
			[198030] =  {
			   [1] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.089999996125698,
			      ["duration"] = 0.31999999284744,
			      ["absolute_sineX"] = false,
			      ["absolute_sineY"] = false,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 0.099998474121094,
			      ["critical_scale"] = 1.05,
			      ["amplitude"] = 0.5,
			      ["fade_in"] = 0.0099999997764826,
			      ["scaleY"] = 1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 200,
			   },
			   ["info"] =  {
			      ["spellid"] = 198030,
			      ["class"] = "DEMONHUNTER",
			      ["time"] = 1539717136,
			      ["desc"] = "",
			   },
			},
			--Infernal Strike (Demon Hunter)
			[189112] =  {
			   [1] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.34999999403954,
			      ["duration"] = 0.40000000596046,
			      ["absolute_sineX"] = true,
			      ["absolute_sineY"] = true,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 0,
			      ["amplitude"] = 1.8799999952316,
			      ["critical_scale"] = 1.05,
			      ["fade_in"] = 0,
			      ["scaleY"] = 1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 51.979999542236,
			   },
			   ["info"] =  {
			      ["time"] = 1539715467,
			      ["class"] = "DEMONHUNTER",
			      ["spellid"] = 189112,
			      ["desc"] = "",
			   },
			},
			--Shear (Demon Hunter)
			[203782] =  {
			   [1] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.089999996125698,
			      ["duration"] = 0.099999994039536,
			      ["absolute_sineX"] = true,
			      ["absolute_sineY"] = false,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 0,
			      ["critical_scale"] = 1.05,
			      ["amplitude"] = 1.5,
			      ["fade_in"] = 0.0099999997764826,
			      ["scaleY"] = -1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 1,
			   },
			   ["info"] =  {
			      ["spellid"] = 203782,
			      ["class"] = "DEMONHUNTER",
			      ["time"] = 1539716639,
			      ["desc"] = "",
			   },
			},
			--Soul Cleave (Demon Hunter)
			[228478] =  {
			   [1] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.099999994039536,
			      ["duration"] = 0.099999994039535,
			      ["absolute_sineX"] = true,
			      ["absolute_sineY"] = false,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 0.20000076293945,
			      ["critical_scale"] = 1.05,
			      ["amplitude"] = 2.5,
			      ["fade_in"] = 0,
			      ["scaleY"] = 0.79999923706055,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 1,
			   },
			   [2] =  {
			      ["animation_type"] = "scale",
			      ["scale_upX"] = 1.0299999713898,
			      ["scale_upY"] = 1.0299999713898,
			      ["scale_downX"] = 0.96999996900559,
			      ["scale_downY"] = 0.96999996900559,
			      ["duration"] = 0.05,
			      ["cooldown"] = 0.75,
			      ["enabled"] = true,
			   },
			   ["info"] =  {
			      ["spellid"] = 228478,
			      ["class"] = "DEMONHUNTER",
			      ["time"] = 1539716636,
			      ["desc"] = "",
			   },
			},
			--Throw Glaive (Demon Hunter)
			[204157] =  {
			   [1] =  {
			      ["enabled"] = true,
			      ["fade_out"] = 0.089999996125698,
			      ["duration"] = 0.1,
			      ["absolute_sineX"] = false,
			      ["absolute_sineY"] = true,
			      ["animation_type"] = "frameshake",
			      ["scaleX"] = 1,
			      ["critical_scale"] = 1.05,
			      ["amplitude"] = 6,
			      ["fade_in"] = 0.0099999997764826,
			      ["scaleY"] = 1,
			      ["cooldown"] = 0.5,
			      ["frequency"] = 1,
			   },
			   [2] =  {
			      ["animation_type"] = "scale",
			      ["scale_upX"] = 1.03,
			      ["scale_upY"] = 1.03,
			      ["scale_downX"] = 0.97,
			      ["scale_downY"] = 0.97,
			      ["duration"] = 0.05,
			      ["cooldown"] = 0.75,
			      ["enabled"] = true,
			   },
			   ["info"] =  {
			      ["spellid"] = 204157,
			      ["class"] = "DEMONHUNTER",
			      ["time"] = 1539716637,
			      ["desc"] = "",
			   },
			},

			
			
			
			

		},
		
		--health_statusbar_texture = "PlaterHealth",
		health_statusbar_texture = "Details Flat",
		health_selection_overlay = "Details Flat",
		health_statusbar_bgtexture = "Details Flat",
		health_statusbar_bgcolor = {0.0431372, 0.0431372, 0.0431372, 0.657664},
		health_statusbar_bgalpha = 1,
		
		cast_statusbar_texture = "Details Flat",
		cast_statusbar_bgtexture = "Details Serenity",
		cast_statusbar_bgcolor = {0, 0, 0, 0.797810},
		cast_statusbar_color = {1, .7, 0, 0.96},
		cast_statusbar_color_nointerrupt = {.5, .5, .5, 0.96},
		
		indicator_faction = true,
		indicator_spec = true,
		indicator_elite = true,
		indicator_rare = true,
		indicator_quest = true,
		indicator_enemyclass = false,
		indicator_anchor = {side = 2, x = -2, y = 0},
		
		indicator_extra_raidmark = true,
		indicator_raidmark_scale = 1,
		indicator_raidmark_anchor = {side = 2, x = -1, y = 4},
		
		target_indicator = "Silver",
		
		color_override = false,
		color_override_colors = {
			[UNITREACTION_HOSTILE] = {0.9176470, 0.2784313, 0.2078431},
			[UNITREACTION_FRIENDLY] = {0.9254901, 0.8, 0.2666666},
			[UNITREACTION_NEUTRAL] = {0.5215686, 0, 0.4509803},
		},
		
		border_color = {0, 0, 0, .36},
		border_thickness = 3,
		
		focus_indicator_enabled = true,
		focus_color = {0, 0, 0, 0.5},
		focus_texture = "PlaterFocus",
		
		tap_denied_color = {.9, .9, .9},
		
		aggro_modifies = {
			health_bar_color = true,
			border_color = false,
			actor_name_color = false,
		},
		
		tank = {
			colors = {
				aggro = {.5, .5, 1},
				noaggro = {1, 0, 0},
				pulling = {1, 1, 0},
				nocombat = {0.505, 0.003, 0},
				anothertank = {0.729, 0.917, 1},
			},
		},
		
		dps = {
			colors = {
				aggro = {1, 0.109803, 0},
				noaggro = {.5, .5, 1},
				pulling = {1, .8, 0},
			},
		},
		
		news_frame = {},
		first_run2 = false,
	}
}

local Plater = DF:CreateAddOn ("Plater", "PlaterDB", default_config, { --options table
	name = "Plater Nameplates",
	type = "group",
	args = {
		
	}
})

-- ~compress ~zip ~export ~import ~deflate ~serialize
function Plater.CompressData (data, dataType)
	local LibDeflate = LibStub:GetLibrary ("LibDeflate")
	local LibAceSerializer = LibStub:GetLibrary ("AceSerializer-3.0")
	
	if (LibDeflate and LibAceSerializer) then
		local dataSerialized = LibAceSerializer:Serialize (data)
		if (dataSerialized) then
			local dataCompressed = LibDeflate:CompressDeflate (dataSerialized, {level = 9})
			if (dataCompressed) then
				if (dataType == "print") then
					local dataEncoded = LibDeflate:EncodeForPrint (dataCompressed)
					return dataEncoded
					
				elseif (dataType == "comm") then
					local dataEncoded = LibDeflate:EncodeForWoWAddonChannel (dataCompressed)
					return dataEncoded
				end
			end
		end
	end
end

function Plater.DecompressData (data, dataType)
	local LibDeflate = LibStub:GetLibrary ("LibDeflate")
	local LibAceSerializer = LibStub:GetLibrary ("AceSerializer-3.0")
	
	if (LibDeflate and LibAceSerializer) then
		
		local dataCompressed
		
		if (dataType == "print") then
			dataCompressed = LibDeflate:DecodeForPrint (data)
			if (not dataCompressed) then
				Plater:Msg ("couldn't decode the data.")
				return false
			end

		elseif (dataType == "comm") then
			dataCompressed = LibDeflate:DecodeForWoWAddonChannel (data)
			if (not dataCompressed) then
				Plater:Msg ("couldn't decode the data.")
				return false
			end
		end
		
		local dataSerialized = LibDeflate:DecompressDeflate (dataCompressed)
		if (not dataSerialized) then
			Plater:Msg ("couldn't uncompress the data.")
			return false
		end
		
		local okay, data = LibAceSerializer:Deserialize (dataSerialized)
		if (not okay) then
			Plater:Msg ("couldn't unserialize the data.")
			return false
		end
		
		return data
	end
end

function Plater.ExportProfileToString()
	local profile = Plater.db.profile
	local data = Plater.CompressData (profile, "print")
	if (data) then
		return data
	else
		Plater:Msg ("failed to compress the profile")
	end
end

--> if a widget has a RefreshID lower than the addon, it triggers a refresh on it
local PLATER_REFRESH_ID = 1
function Plater.IncreaseRefreshID()
	PLATER_REFRESH_ID = PLATER_REFRESH_ID + 1
end

Plater.FriendsCache = {}
Plater.QuestCache = {}
Plater.DriverFuncNames = {
	["OnNameUpdate"] = "UpdateName",
	["OnUpdateBuffs"] = "UpdateBuffs",
	["OnUpdateHealth"] = "UpdateHealth",
	["OnUpdateAnchor"] = "UpdateAnchor",
	["OnBorderUpdate"] = "SetVertexColor",
	["OnChangeHealthConfig"] = "UpdateHealthColor",
	["OnSelectionUpdate"] = "UpdateSelectionHighlight",
	["OnAuraUpdate"] = "OnUnitAuraUpdate",
	["OnResourceUpdate"] = "SetupClassNameplateBar",
	["OnOptionsUpdate"] = "UpdateNamePlateOptions",
	["OnManaBarOptionsUpdate"] = "OnOptionsUpdated",
	["OnCastBarEvent"] = "OnEvent",
	["OnCastBarShow"] = "OnShow",
	["OnTick"] = "OnUpdate",
	["OnRaidTargetUpdate"] = "OnRaidTargetUpdate",
}
Plater.DriverConfigType = {
	["FRIENDLY"] = "Friendly", 
	["ENEMY"] = "Enemy", 
	["PLAYER"] = "Player",
}
Plater.DriverConfigMembers = {
	["UseClassColors"] = "useClassColors",
	["UseRangeCheck"] = "fadeOutOfRange",
	["UseAlwaysHostile"] = "considerSelectionInCombatAsHostile",
	["CanShowUnitName"] = "displayName",
	["HideCastBar"] = "hideCastbar",
}

--this file are using this names at will to reduce overhead and amount of local variables
Plater.CodeTypeNames = {
	[1] = "UpdateCode",
	[2] = "ConstructorCode",
	[3] = "OnHideCode",
	[4] = "OnShowCode",
}

--hook options
--this file are using this names at will to reduce overhead and amount of local variables
Plater.HookScripts = {
	"Constructor",
	"Nameplate Created",
	"Nameplate Added",
	"Nameplate Removed",
	"Nameplate Updated",
	"Cast Start",
	"Cast Update",
	"Cast Stop",
	"Target Changed",
	"Raid Target",
	"Enter Combat",
	"Leave Combat",
}

--|cFFFFFF22 |r
Plater.HookScriptsDesc = {
	["Constructor"] = "Executed once when the nameplate run the hook for the first time.\n\nUse to initialize configs in the environment.\n\nAlways receive unitFrame in 'self' parameter.",
	["Nameplate Created"] = "Executed when a nameplate is created.\n\nRequires a |cFFFFFF22/reload|r after changing the code.",
	["Nameplate Added"] = "Run after a nameplate is added to the screen.",
	["Nameplate Removed"] = "Run when the nameplate is removed from the screen.",
	["Nameplate Updated"] = "Run after the nameplate gets an updated from Plater.\n\n|cFFFFFF22Important:|r doesn't run every frame.",
	
	["Cast Start"] = "When the unit starts to cast a spell.\n\n|cFFFFFF22self|r is unitFrame.castBar",
	["Cast Update"] = "When the cast bar receives an update from Plater.\n\n|cFFFFFF22Important:|r doesn't run every frame.\n\n|cFFFFFF22self|r is unitFrame.castBar",
	["Cast Stop"] = "When the cast is finished for any reason or the nameplate has been removed from the screen.\n\n|cFFFFFF22self|r is unitFrame.castBar",
	
	["Target Changed"] = "Run after the player selects a new target.\n\n|cFF44FF44Run on all nameplates shown in the screen|r.",
	["Raid Target"] = "A raid target mark has added, modified or removed (skull, cross, etc).\n\n|cFF44FF44Run on all nameplates shown in the screen|r.",
	["Enter Combat"] = "Executed shortly after the player enter combat.\n\n|cFF44FF44Run on all nameplates shown in the screen|r.",
	["Leave Combat"] = "Executed shortly after the player leave combat.\n\n|cFF44FF44Run on all nameplates shown in the screen|r.",
}

--const
local CVAR_RESOURCEONTARGET = "nameplateResourceOnTarget"
local CVAR_CULLINGDISTANCE = "nameplateMaxDistance"
local CVAR_CEILING = "nameplateOtherTopInset"
local CVAR_AGGROFLASH = "ShowNamePlateLoseAggroFlash"
local CVAR_MOVEMENT_SPEED = "nameplateMotionSpeed"
local CVAR_MIN_ALPHA = "nameplateMinAlpha"
local CVAR_MIN_ALPHA_DIST = "nameplateMinAlphaDistance"
local CVAR_SHOWALL = "nameplateShowAll"
local CVAR_ENEMY_ALL = "nameplateShowEnemies"
local CVAR_ENEMY_MINIONS = "nameplateShowEnemyMinions"
local CVAR_ENEMY_MINUS = "nameplateShowEnemyMinus"
local CVAR_PLATEMOTION = "nameplateMotion"
local CVAR_FRIENDLY_ALL = "nameplateShowFriends"
local CVAR_FRIENDLY_GUARDIAN = "nameplateShowFriendlyGuardians"
local CVAR_FRIENDLY_PETS = "nameplateShowFriendlyPets"
local CVAR_FRIENDLY_TOTEMS = "nameplateShowFriendlyTotems"
local CVAR_FRIENDLY_MINIONS = "nameplateShowFriendlyMinions"
local CVAR_CLASSCOLOR = "ShowClassColorInNameplate"
local CVAR_SCALE_HORIZONTAL = "NamePlateHorizontalScale"
local CVAR_SCALE_VERTICAL = "NamePlateVerticalScale"

--comm
local COMM_PLATER_PREFIX = "PLT"
local COMM_SCRIPT_GROUP_EXPORTED = "GE"

--store aura names to manually track
local MANUAL_TRACKING_BUFFS = {}
local MANUAL_TRACKING_DEBUFFS = {}
local AUTO_TRACKING_EXTRA_BUFFS = {}
local AUTO_TRACKING_EXTRA_DEBUFFS = {}
--if automatic aura tracking and there's auras to manually track
local CAN_TRACK_EXTRA_BUFFS = false
local CAN_TRACK_EXTRA_DEBUFFS = false

--spell animations - store a table with information about animation for spells
local SPELL_WITH_ANIMATIONS = {}
--cache this inside plater object to access it from the animation editor
Plater.SPELL_WITH_ANIMATIONS = SPELL_WITH_ANIMATIONS

--store players which have the tank role in the group
local TANK_CACHE = {}

--store pets
local PET_CACHE = {}

--store if the player is in combat (not reliable, toggled at regen switch)
local PLAYER_IN_COMBAT

--store if the player is not inside an instance
local IS_IN_OPEN_WORLD = true

--if true, the animation will update its settings before play
local IS_EDITING_SPELL_ANIMATIONS = false

local BUFF_MAX_DISPLAY = BUFF_MAX_DISPLAY
local CooldownFrame_Set = CooldownFrame_Set

 --cvars
local CVAR_ENABLED = "1"
local CVAR_DISABLED = "0"

--members
local MEMBER_UNITID = "namePlateUnitToken"
local MEMBER_GUID = "namePlateUnitGUID"
local MEMBER_NPCID = "namePlateNpcId"
local MEMBER_QUEST = "namePlateIsQuestObjective"
local MEMBER_REACTION = "namePlateUnitReaction"
local MEMBER_ALPHA = "namePlateAlpha"
local MEMBER_RANGE = "namePlateInRange"
local MEMBER_NOCOMBAT = "namePlateNoCombat"
local MEMBER_NAME = "namePlateUnitName"
local MEMBER_NAMELOWER = "namePlateUnitNameLower"
local MEMBER_TARGET = "namePlateIsTarget"
local MEMBER_CLASSIFICATION = "namePlateClassification"

Plater.UnitFrameKeys = {
	MEMBER_GUID,
	MEMBER_NAME,
	MEMBER_NAMELOWER,
	MEMBER_CLASSIFICATION,
	MEMBER_REACTION,
	MEMBER_NPCID,
	MEMBER_TARGET,
	MEMBER_RANGE,
	MEMBER_QUEST,
}

--icon texcoords
Plater.WideIconCoords = {.1, .9, .1, .6}
Plater.BorderLessIconCoords = {.1, .9, .1, .9}

local CAN_USE_AURATIMER = true
Plater.CanLoadFactionStrings = true

local CONST_USE_HEALTHCUTOFF = false
local CONST_HEALTHCUTOFF_AT = 20

-- ~execute
function Plater.GetHealthCutoffValue()

	CONST_USE_HEALTHCUTOFF = false
	
	if (not Plater.db.profile.health_cutoff) then
		return
	end
	
	local classLoc, class = UnitClass ("player")
	local spec = GetSpecialization()
	if (spec and class) then
	
		if (class == "PRIEST") then
			--playing as shadow?
			local specID = GetSpecializationInfo (spec)
			if (specID and specID ~= 0) then
				if (specID == 258) then --shadow
					local _, _, _, using_SWDeath = GetTalentInfo (5, 2, 1)
					if (using_SWDeath) then
						CONST_USE_HEALTHCUTOFF = true
						CONST_HEALTHCUTOFF_AT = 0.20
					end
				end
			end
			
		elseif (class == "MAGE") then
			--playing fire mage?
			local specID = GetSpecializationInfo (spec)
			if (specID and specID ~= 0) then
				if (specID == 63) then --fire
					local _, _, _, using_SearingTouch = GetTalentInfo (1, 3, 1)
					if (using_SearingTouch) then
						CONST_USE_HEALTHCUTOFF = true
						CONST_HEALTHCUTOFF_AT = 0.30
					end
				end
			end
			
			
		elseif (class == "WARRIOR") then
			--is playing as a Arms warrior?
			local specID = GetSpecializationInfo (spec)
			if (specID and specID ~= 0) then
				if (specID == 71 or specID == 72) then --arms or fury
					CONST_USE_HEALTHCUTOFF = true
					CONST_HEALTHCUTOFF_AT = 0.20
					
					if (specID == 71) then --arms
						local _, _, _, using_Massacre = GetTalentInfo (3, 1, 1)
						if (using_Massacre) then
							--if using massacre, execute can be used at 35% health in Arms spec
							CONST_HEALTHCUTOFF_AT = 0.35
						end
					end
				end
			end
			
		elseif (class == "HUNTER") then
			local specID = GetSpecializationInfo (spec)
			if (specID and specID ~= 0) then
				if (specID == 253) then --beast mastery
					--> is using killer instinct?
					local _, _, _, using_KillerInstinct = GetTalentInfo (1, 1, 1)
					if (using_KillerInstinct) then
						CONST_USE_HEALTHCUTOFF = true
						CONST_HEALTHCUTOFF_AT = 0.35
					end
				end
			end
		end
	end
end

--> copied from blizzard code
local function IsPlayerEffectivelyTank()
	local assignedRole = UnitGroupRolesAssigned ("player");
	if ( assignedRole == "NONE" ) then
		local spec = GetSpecialization();
		return spec and GetSpecializationRole(spec) == "TANK";
	end
	return assignedRole == "TANK";
end

local function IsUnitEffectivelyTank (unit)
	local assignedRole = UnitGroupRolesAssigned (unit);
	return assignedRole == "TANK";
end


--copied from blizzard code
local function IsTapDenied (unit)
	return unit and not UnitPlayerControlled (unit) and UnitIsTapDenied (unit)
end

function Plater.GetDriverSubObjectName (driverName, funcName, isChildMember)
	if (isChildMember) then
		return driverName [funcName]
	else
		return driverName .. "_" .. funcName
	end
end

function Plater.GetDriverGlobalObject (driverName)
	return _G [driverName]
end
function Plater.Execute (driverName, funcName, ...)
	local subObject = Plater.GetDriverSubObjectName (driverName, funcName, false)
	if (subObject) then
		return _G [subObject] and _G [subObject] (...)
	end
end

local InstallHook = hooksecurefunc
local InstallOverride = function (driverName, funcName, newFunction)
	if (not funcName) then
		_G [driverName] = newFunction
	else
		_G [driverName] [funcName] = newFunction
	end
end

function Plater.GetHashKey (inCombat)
	if (inCombat) then
		return "cast_incombat", "health_incombat", "actorname_text_spacing", "mana_incombat"
	else
		return "cast", "health", "actorname_text_spacing", "mana"
	end
end

local ACTORTYPE_FRIENDLY_PLAYER = "friendlyplayer"
local ACTORTYPE_FRIENDLY_NPC = "friendlynpc"
local ACTORTYPE_ENEMY_PLAYER = "enemyplayer"
local ACTORTYPE_ENEMY_NPC = "enemynpc"
local ACTORTYPE_PLAYER = "player"

local actorTypes = {ACTORTYPE_FRIENDLY_PLAYER, ACTORTYPE_ENEMY_PLAYER, ACTORTYPE_FRIENDLY_NPC, ACTORTYPE_ENEMY_NPC, ACTORTYPE_PLAYER}
function Plater.GetActorTypeByIndex (index)
	return actorTypes [index] or error ("Invalid actor type")
end

function Plater.SetShowActorType (actorType, value)
	Plater.db.profile.plate_config [actorType].enabled = value
end

do
	function Plater.InjectOnDefaultOptions (driverName, configType, configName, value)
		_G ["Default" .. driverName .. configType .. "FrameOptions"][configName] = value
	end
end

function Plater.IsShowingResourcesOnTarget()
	return GetCVar ("nameplateShowSelf") == CVAR_ENABLED and GetCVar (CVAR_RESOURCEONTARGET) == CVAR_ENABLED
end

Plater.TargetIndicators = {
	["NONE"] = {
		path = [[Interface\ACHIEVEMENTFRAME\UI-Achievement-WoodBorder-Corner]],
		coords = {{.9, 1, .9, 1}, {.9, 1, .9, 1}, {.9, 1, .9, 1}, {.9, 1, .9, 1}},
		desaturated = false,
		width = 10,
		height = 10,
		x = 1,
		y = 1,
	},
	
	["Magneto"] = {
		path = [[Interface\Artifacts\RelicIconFrame]],
		coords = {{0, .5, 0, .5}, {0, .5, .5, 1}, {.5, 1, .5, 1}, {.5, 1, 0, .5}},
		desaturated = false,
		width = 8,
		height = 10,
		x = 1,
		y = 1,
	},
	
	["Gray Bold"] = {
		path = [[Interface\ContainerFrame\UI-Icon-QuestBorder]],
		coords = {{0, .5, 0, .5}, {0, .5, .5, 1}, {.5, 1, .5, 1}, {.5, 1, 0, .5}},
		desaturated = true,
		width = 10,
		height = 10,
		x = 2,
		y = 2,
	},
	
	["Pins"] = {
		path = [[Interface\ITEMSOCKETINGFRAME\UI-ItemSockets]],
		coords = {{145/256, 161/256, 3/256, 19/256}, {145/256, 161/256, 19/256, 3/256}, {161/256, 145/256, 19/256, 3/256}, {161/256, 145/256, 3/256, 19/256}},
		desaturated = 1,
		width = 4,
		height = 4,
		x = 2,
		y = 2,
	},

	["Silver"] = {
		path = [[Interface\PETBATTLES\PETBATTLEHUD]],
		coords = {
			{848/1024, 868/1024, 454/512, 474/512}, 
			{848/1024, 868/1024, 474/512, 495/512}, 
			{868/1024, 889/1024, 474/512, 495/512}, 
			{868/1024, 889/1024, 454/512, 474/512}
		}, --848 889 454 495
		desaturated = false,
		width = 6,
		height = 6,
		x = 1,
		y = 1,
	},
	
	["Ornament"] = {
		path = [[Interface\PETBATTLES\PETJOURNAL]],
		coords = {
			{124/512, 161/512, 71/1024, 99/1024}, 
			{119/512, 156/512, 29/1024, 57/1024}
		},
		desaturated = false,
		width = 18,
		height = 12,
		x = 12,
		y = 0,
	},
	
	["Golden"] = {
		path = [[Interface\Artifacts\Artifacts]],
		coords = {
			{137/1024, (137+29)/1024, 920/1024, 978/1024},
			{(137+30)/1024, 195/1024, 920/1024, 978/1024},
		},
		desaturated = false,
		width = 8,
		height = 12,
		x = 0,
		y = 0,
	},
	
	["Ornament Gray"] = {
		path = [[Interface\Challenges\challenges-besttime-bg]],
		coords = {
			{89/512, 123/512, 0, 1},
			{123/512, 89/512, 0, 1},
		},
		desaturated = false,
		width = 8,
		height = 12,
		alpha = 0.7,
		x = 0,
		y = 0,
		color = "red",
	},

	["Epic"] = {
		path = [[Interface\UNITPOWERBARALT\WowUI_Horizontal_Frame]],
		coords = {
			{30/256, 40/256, 15/64, 49/64},
			{40/256, 30/256, 15/64, 49/64}, 
		},
		desaturated = false,
		width = 6,
		height = 12,
		x = 3,
		y = 0,
		blend = "ADD",
	},
}

--> general values

local DB_TICK_THROTTLE
local DB_LERP_COLOR
local DB_LERP_COLOR_SPEED
local DB_PLATE_CONFIG
local DB_HOVER_HIGHLIGHT
local DB_BUFF_BANNED
local DB_DEBUFF_BANNED
local DB_AURA_ENABLED
local DB_AURA_ALPHA
local DB_AURA_X_OFFSET
local DB_AURA_Y_OFFSET

local DB_AURA_SEPARATE_BUFFS

local DB_AURA_SHOW_IMPORTANT
local DB_AURA_SHOW_DISPELLABLE
local DB_AURA_SHOW_BYPLAYER
local DB_AURA_SHOW_BYUNIT

local DB_AURA_GROW_DIRECTION --> main aura frame
local DB_AURA_GROW_DIRECTION2 --> secondary aura frame is adding buffs in a different frame

local IS_USING_DETAILS_INTEGRATION
local DB_UPDATE_FRAMELEVEL

local DB_TRACK_METHOD
local DB_BORDER_COLOR_R
local DB_BORDER_COLOR_G
local DB_BORDER_COLOR_B
local DB_BORDER_COLOR_A
local DB_BORDER_THICKNESS
local DB_AGGRO_CHANGE_HEALTHBAR_COLOR
local DB_AGGRO_CHANGE_NAME_COLOR
local DB_AGGRO_CHANGE_BORDER_COLOR
local DB_TARGET_SHADY_ENABLED
local DB_TARGET_SHADY_ALPHA
local DB_TARGET_SHADY_COMBATONLY

local DB_NAME_NPCENEMY_ANCHOR
local DB_NAME_NPCFRIENDLY_ANCHOR
local DB_NAME_PLAYERENEMY_ANCHOR
local DB_NAME_PLAYERFRIENDLY_ANCHOR

local DB_DO_ANIMATIONS
local DB_ANIMATION_TIME_DILATATION

local DB_USE_RANGE_CHECK

local DB_TEXTURE_CASTBAR
local DB_TEXTURE_CASTBAR_BG
local DB_TEXTURE_HEALTHBAR
local DB_TEXTURE_HEALTHBAR_BG

local DB_CASTBAR_HIDE_ENEMIES
local DB_CASTBAR_HIDE_FRIENDLY

local DB_CAPTURED_SPELLS = {}

local DB_SHOW_PURGE_IN_EXTRA_ICONS

--store the aggro color table for tanks and dps
local DB_AGGRO_TANK_COLORS
local DB_AGGRO_DPS_COLORS

--store if the no combat alpha is enabled
local DB_NOT_COMBAT_ALPHA_ENABLED

local SCRIPT_AURA = {}
local SCRIPT_CASTBAR = {}
local SCRIPT_UNIT = {}

-- 192
-- ~hook
local HOOK_NAMEPLATE_ADDED = {ScriptAmount = 0}
local HOOK_NAMEPLATE_CREATED = {ScriptAmount = 0}
local HOOK_NAMEPLATE_REMOVED = {ScriptAmount = 0}
local HOOK_NAMEPLATE_UPDATED = {ScriptAmount = 0}
local HOOK_TARGET_CHANGED = {ScriptAmount = 0}
local HOOK_CAST_START = {ScriptAmount = 0}
local HOOK_CAST_UPDATE = {ScriptAmount = 0}
local HOOK_CAST_STOP = {ScriptAmount = 0}
local HOOK_RAID_TARGET = {ScriptAmount = 0}
local HOOK_COMBAT_ENTER = {ScriptAmount = 0}
local HOOK_COMBAT_LEAVE = {ScriptAmount = 0}
local HOOK_NAMEPLATE_CONSTRUCTOR = {ScriptAmount = 0}

local SPECIAL_AURA_NAMES = {}
local SPECIAL_AURA_NAMES_MINE = {}
local CROWDCONTROL_AURA_NAMES = {}

Plater.ScriptMetaFunctions = {
	--get the table which stores all script information for the widget
	--self is the affected widget, e.g. icon frame, unitframe, castbar progressbar
	ScriptGetContainer = function (self)
		local infoTable = self.ScriptInfoTable
		if (not infoTable) then
			self.ScriptInfoTable = {}
			return self.ScriptInfoTable
		else
			return infoTable
		end
	end,
	
	--get the table which stores the information for a single script
	ScriptGetInfo = function (self, globalScriptObject, widgetScriptContainer)
		widgetScriptContainer = widgetScriptContainer or self:GetScriptContainer()
		
		--using the memory address of the original scriptObject from db.profile as the map key
		local scriptInfo = widgetScriptContainer [globalScriptObject.DBScriptObject]
		if (not scriptInfo or scriptInfo.GlobalScriptObject.NeedHotReload) then
			scriptInfo = {
				GlobalScriptObject = globalScriptObject, 
				HotReload = -1, 
				Env = {}, 
				IsActive = false
			}
			
			if (globalScriptObject.HasConstructor and not scriptInfo.Initialized) then
				local okay, errortext = pcall (globalScriptObject.Constructor, self, self.displayedUnit or self.unit or self:GetParent()[MEMBER_UNITID], self, scriptInfo.Env)
				if (not okay) then
					Plater:Msg ("Script |cFFAAAA22" .. scriptInfo.GlobalScriptObject.DBScriptObject.Name .. "|r Constructor error: " .. errortext)
				end
				scriptInfo.Initialized = true
			end
			
			widgetScriptContainer [globalScriptObject.DBScriptObject] = scriptInfo
		end
		
		return scriptInfo
	end,
	
	--if the global script had an update or if the first time running this script on this widget, run the constructor
	ScriptHotReload = function (self, scriptInfo)
		--dispatch constructor if necessary
		if (scriptInfo.HotReload < scriptInfo.GlobalScriptObject.HotReload) then
			--update the hotreload state
			scriptInfo.HotReload = scriptInfo.GlobalScriptObject.HotReload

			--dispatch the constructor
			local unitFrame = self.UnitFrame or self
			local okay, errortext = pcall (scriptInfo.GlobalScriptObject ["ConstructorCode"], self, unitFrame.displayedUnit or unitFrame.unit or unitFrame:GetParent()[MEMBER_UNITID], unitFrame, scriptInfo.Env)
			if (not okay) then
				Plater:Msg ("Script |cFFAAAA22" .. scriptInfo.GlobalScriptObject.DBScriptObject.Name .. "|r Constructor error: " .. errortext)
			end
		end
	end,
	
	--run the update script
	ScriptRunOnUpdate = function (self, scriptInfo)
		if (not scriptInfo.IsActive) then
			--run constructor
			self:ScriptHotReload (scriptInfo)
			--run on show
			self:ScriptRunOnShow (scriptInfo)
		end
		
		--dispatch the runtime script
		local unitFrame = self.UnitFrame or self
		local okay, errortext = pcall (scriptInfo.GlobalScriptObject ["UpdateCode"], self, unitFrame.displayedUnit or unitFrame.unit or unitFrame:GetParent()[MEMBER_UNITID], unitFrame, scriptInfo.Env)
		if (not okay) then
			Plater:Msg ("Script |cFFAAAA22" .. scriptInfo.GlobalScriptObject.DBScriptObject.Name .. "|r OnUpdate error: " .. errortext)
		end
	end,
	
	--run the OnShow script
	ScriptRunOnShow = function (self, scriptInfo)
		--dispatch the on show script
		local unitFrame = self.UnitFrame or self
		local okay, errortext = pcall (scriptInfo.GlobalScriptObject ["OnShowCode"], self, unitFrame.displayedUnit or unitFrame.unit or unitFrame:GetParent()[MEMBER_UNITID], unitFrame, scriptInfo.Env)
		if (not okay) then
			Plater:Msg ("Script |cFFAAAA22" .. scriptInfo.GlobalScriptObject.DBScriptObject.Name .. "|r OnShow error: " .. errortext)
		end
		
		scriptInfo.IsActive = true
		self.ScriptKey = scriptInfo.GlobalScriptObject.ScriptKey
	end,
	
	--run the OnHide script
	ScriptRunOnHide = function (self, scriptInfo)
		--dispatch the on hide script
		local unitFrame = self.UnitFrame or self
		local okay, errortext = pcall (scriptInfo.GlobalScriptObject ["OnHideCode"], self, unitFrame.displayedUnit or unitFrame.unit or unitFrame:GetParent()[MEMBER_UNITID], unitFrame, scriptInfo.Env)
		if (not okay) then
			Plater:Msg ("Script |cFFAAAA22" .. scriptInfo.GlobalScriptObject.DBScriptObject.Name .. "|r OnHide error: " .. errortext)
		end
		
		scriptInfo.IsActive = false
		self.ScriptKey = nil
	end,
	
	ScriptRunHook = function (self, scriptInfo, hookName, frame)
		--dispatch a hook for the script
		--at the moment, self is always the unit frame
		local okay, errortext = pcall (scriptInfo.GlobalScriptObject [hookName], frame or self, self.displayedUnit, self, scriptInfo.Env)
		if (not okay) then
			Plater:Msg ("Hook |cFFAAAA22" .. scriptInfo.GlobalScriptObject.DBScriptObject.Name .. "|r " .. hookName .. " error: " .. errortext)
		end
	end,
	
	--run when the widget hides
	OnHideWidget = function (self)
		--> check if can quickly quit (if there's no script container for the nameplate)
		if (self.ScriptInfoTable) then
			local mainScriptTable
			
			if (self.IsAuraIcon) then
				mainScriptTable = SCRIPT_AURA
			elseif (self.IsCastBar) then
				mainScriptTable = SCRIPT_CASTBAR
			elseif (self.IsUnitNameplate) then
				mainScriptTable = SCRIPT_UNIT				
			end

			--> ScriptKey holds the trigger of the script currently running
			local globalScriptObject = mainScriptTable [self.ScriptKey]
			
			--does the aura has a custom script?
			if (globalScriptObject) then
				--does the aura icon has a table with script information?
				local scriptContainer = self:ScriptGetContainer()
				if (scriptContainer) then
					local scriptInfo = self:ScriptGetInfo (globalScriptObject, scriptContainer)
					if (scriptInfo and scriptInfo.IsActive) then
						self:ScriptRunOnHide (scriptInfo)
					end
				end
			end
		end

		--> hooks, check which kind of widget this is and then run the appropriate hook
		if (self.IsCastBar) then
			if (HOOK_CAST_STOP.ScriptAmount > 0) then
				for i = 1, HOOK_CAST_STOP.ScriptAmount do
					local globalScriptObject = HOOK_CAST_STOP [i]
					local unitFrame = self:GetParent()
					local scriptContainer = unitFrame:ScriptGetContainer()
					local scriptInfo = unitFrame:ScriptGetInfo (globalScriptObject, scriptContainer)
					--run
					unitFrame:ScriptRunHook (scriptInfo, "Cast Stop", self)
				end
			end
		end
		
	end,
	
	--stop a running script by the trigger ID
	--this is used when deleting a script or disabling it
	KillScript = function (self, triggerID)
		local mainScriptTable
		
		if (self.IsAuraIcon) then
			mainScriptTable = SCRIPT_AURA
			triggerID = GetSpellInfo (triggerID)
			
		elseif (self.IsCastBar) then
			mainScriptTable = SCRIPT_CASTBAR
			triggerID = GetSpellInfo (triggerID)
			
		elseif (self.IsUnitNameplate) then
			mainScriptTable = SCRIPT_UNIT				
		end
		
		if (self.ScriptKey and self.ScriptKey == triggerID) then
			local globalScriptObject = mainScriptTable [triggerID]
			if (globalScriptObject) then
				local scriptContainer = self:ScriptGetContainer()
				if (scriptContainer) then
					local scriptInfo = self:ScriptGetInfo (globalScriptObject, scriptContainer)
					if (scriptInfo and scriptInfo.IsActive) then
						self:ScriptRunOnHide (scriptInfo)
					end
				end
			end
		end
	end
}
 
function Plater.GetAllScripts (scriptType)
	if (scriptType == "script") then
		return Plater.db.profile.script_data
	elseif (scriptType == "hook") then
		return Plater.db.profile.hook_data
	end
end
 
--compile all scripts
function Plater.CompileAllScripts (scriptType)
	if (scriptType == "script") then
		for scriptId, scriptObject in ipairs (Plater.GetAllScripts ("script")) do
			if (scriptObject.Enabled) then
				Plater.CompileScript (scriptObject)
			end
		end
	elseif (scriptType == "hook") then
		for scriptId, scriptObject in ipairs (Plater.GetAllScripts ("hook")) do
			if (scriptObject.Enabled) then
				Plater.CompileHook (scriptObject)
			end
		end
	end
end

--when a script object get disabled, need to clear all compiled scripts in the cache and recompile than again
--this other scripts that uses the same trigger name get activated
-- ~scripts

Plater.CoreVersion = 1

function Plater.WipeAndRecompileAllScripts (scriptType)
	if (scriptType == "script") then
		table.wipe (SCRIPT_AURA)
		table.wipe (SCRIPT_CASTBAR)
		table.wipe (SCRIPT_UNIT)
		Plater.CompileAllScripts (scriptType)
		
	elseif (scriptType == "hook") then
		Plater.WipeHookContainers()
		Plater.CompileAllScripts (scriptType)
	end
end

Plater.AllHookGlobalContainers = {
	HOOK_NAMEPLATE_CREATED,
	HOOK_NAMEPLATE_ADDED,
	HOOK_NAMEPLATE_REMOVED,
	HOOK_NAMEPLATE_UPDATED,
	HOOK_TARGET_CHANGED,
	HOOK_CAST_START,
	HOOK_CAST_UPDATE,
	HOOK_CAST_STOP,
	HOOK_RAID_TARGET,
	HOOK_COMBAT_ENTER,
	HOOK_COMBAT_LEAVE,
	HOOK_NAMEPLATE_CONSTRUCTOR,
}

function Plater.WipeHookContainers()
	for _, container in ipairs (Plater.AllHookGlobalContainers) do
		for _, globalScriptObject in ipairs (container) do
			globalScriptObject.NeedHotReload = true
		end
		table.wipe (container)
		container.ScriptAmount = 0
	end
end

function Plater.GetContainerForHook (hookName)
	if (hookName == "Constructor") then
		return HOOK_NAMEPLATE_CONSTRUCTOR
	elseif (hookName == "Nameplate Created") then
		return HOOK_NAMEPLATE_CREATED
	elseif (hookName == "Nameplate Added") then
		return HOOK_NAMEPLATE_ADDED
	elseif (hookName == "Nameplate Removed") then
		return HOOK_NAMEPLATE_REMOVED
	elseif (hookName == "Nameplate Updated") then
		return HOOK_NAMEPLATE_UPDATED	
	elseif (hookName == "Target Changed") then
		return HOOK_TARGET_CHANGED
	elseif (hookName == "Cast Start") then
		return HOOK_CAST_START
	elseif (hookName == "Cast Update") then
		return HOOK_CAST_UPDATE
	elseif (hookName == "Cast Stop") then
		return HOOK_CAST_STOP
	elseif (hookName == "Raid Target") then
		return HOOK_RAID_TARGET
	elseif (hookName == "Enter Combat") then
		return HOOK_COMBAT_ENTER
	elseif (hookName == "Leave Combat") then
		return HOOK_COMBAT_LEAVE
	else
		Plater:Msg ("Unknown hook: " .. (hookName or "Invalid Hook Name"))
	end
end

--compile scripts from the Hooking tab
function Plater.CompileHook (scriptObject)
	
	--check if the script is valid and if is enabled
	if (not scriptObject) then
		return
	elseif (not scriptObject.Enabled) then
		return
	end
	
	--check if can load this hook
	if (not DF:PassLoadFilters (scriptObject.LoadConditions, Plater.EncounterID)) then
		return
	end
	
	--store the scripts to be compiled
	local scriptCode = {}
	
	--get scripts from the object
	for hookName, code in pairs (scriptObject.Hooks) do
		scriptCode [hookName] = "return " .. code
	end
	
	--get or create the global script object
	local globalScriptObject = {
		HotReload = -1,
		DBScriptObject = scriptObject,
	}
	
	--compile
	for hookName, code in pairs (scriptCode) do
		local compiledScript, errortext = loadstring (code, "Compiling " .. hookName .. " for " .. scriptObject.Name)
		if (not compiledScript) then
			Plater:Msg ("failed to compile " .. hookName .. " for script " .. scriptObject.Name .. ": " .. errortext)
		else
			--store the function to execute
			globalScriptObject [hookName] = compiledScript()
			
			--insert the script in the global script container, no need to check if already exists, hook containers cache are cleaned before script compile
			local globalScriptContainer = Plater.GetContainerForHook (hookName)
			tinsert (globalScriptContainer, globalScriptObject)
			globalScriptContainer.ScriptAmount = globalScriptContainer.ScriptAmount + 1
			
			if (hookName == "Constructor") then
				globalScriptObject.HasConstructor = true
			end
		end
	end
	
end

--compile scripts from the Scripting tab
function Plater.CompileScript (scriptObject, ...)
	
	--check if the script is valid and if is enabled
	if (not scriptObject) then
		return
	elseif (not scriptObject.Enabled) then
		return
	end
	
	--store the scripts to be compiled
	local scriptCode, scriptFunctions = {}, {}
	
	--get scripts passed to
	for i = 1, select ("#",...) do
		scriptCode [Plater.CodeTypeNames [i]] = "return " .. select (i, ...)
	end
	
	--get scripts which wasn't passed
	for i = 1, #Plater.CodeTypeNames do
		local scriptType = Plater.CodeTypeNames [i]
		if (not scriptCode [scriptType]) then
			scriptCode [scriptType] = "return " .. scriptObject [scriptType]
		end
	end

	--compile
	for scriptType, code in pairs (scriptCode) do
		local compiledScript, errortext = loadstring (code, "Compiling " .. scriptType .. " for " .. scriptObject.Name)
		if (not compiledScript) then
			Plater:Msg ("failed to compile " .. scriptType .. " for script " .. scriptObject.Name .. ": " .. errortext)
		else
			--get the function to execute
			scriptFunctions [scriptType] = compiledScript()
		end
	end
	
	--trigger container is the table with spellIds for auras or spellcast
	--triggerId is the spellId then converted to spellName or the unitName in case is a Unit script
	local triggerContainer, triggerId
	if (scriptObject.ScriptType == 1 or scriptObject.ScriptType == 2) then --aura or castbar
		triggerContainer = "SpellIds"
	elseif (scriptObject.ScriptType == 3) then --unit plate
		triggerContainer = "NpcNames"
	end
	
	for i = 1, #scriptObject [triggerContainer] do
		local triggerId = scriptObject [triggerContainer] [i]
		
		--> if the trigger is using spellId, check if the spell exists
		if (scriptObject.ScriptType == 1 or scriptObject.ScriptType == 2) then
			if (type (triggerId) == "number") then
				triggerId = GetSpellInfo (triggerId)
				if (not triggerId) then
					Plater:Msg ("failed to get the spell name for spellId: " .. (scriptObject [triggerContainer] [i] or "invalid spellId"))
				end
			end
		
		--> if is a unit name, make it be in lower case	
		elseif (scriptObject.ScriptType == 3) then
			--> cast the string to number to see if it's a npcId
			triggerId = tonumber (triggerId) or triggerId
			
			--> the user may have inserted the npcId
			if (type (triggerId) == "string") then
				triggerId = lower (triggerId)
			end
		end

		if (triggerId) then
			--get the global script object table
			local mainScriptTable
			
			if (scriptObject.ScriptType == 1) then
				mainScriptTable = SCRIPT_AURA
			elseif (scriptObject.ScriptType == 2) then
				mainScriptTable = SCRIPT_CASTBAR
			elseif (scriptObject.ScriptType == 3) then
				mainScriptTable = SCRIPT_UNIT
			end
			
			local globalScriptObject = mainScriptTable [triggerId]
			
			if (not globalScriptObject) then
				--first time compiled, create the global script object
				--this table controls the hot reload state, holds the original object from the database and has the compiled functions
				globalScriptObject = {
					DBScriptObject = scriptObject,
					--whenever the script is applied or saved the hot reload increases making it run again when the script is triggered
					HotReload = 1,
					--script key is set in the widget so it can lookup for a script using the key when the widget is hidding
					ScriptKey = triggerId,
				}
				mainScriptTable [triggerId] = globalScriptObject
				
			else --hot reload
				globalScriptObject.HotReload = globalScriptObject.HotReload + 1
				
			end
			
			--add the script functions to the global object table
			for scriptType, func in pairs (scriptFunctions) do
				globalScriptObject [scriptType] = func
			end
		end
	end
	
end

--check all triggers of all scripts for overlaps
--where a same spellId, npcName or npcId is being used by two or more scripts
--return a table with the triggerId with a index table of all scripts using that trigger
function Plater.CheckScriptTriggerOverlap()
	--store all triggers of all scripts in the format [triggerId] = {scripts using this trigger}
	local allTriggers = {
		Auras = {},
		Casts = {},
		Npcs = {},
	}
	
	--build the table containinf all scripts and what scripts they trigger
	for index, scriptObject in ipairs (Plater.GetAllScripts ("script")) do
		if (scriptObject.Enabled) then
			for _, spellId in ipairs (scriptObject.SpellIds) do
				
				if (scriptObject.ScriptType == 1) then
					--> triggers auras
					local triggerTable = allTriggers.Auras [spellId]
					if (not triggerTable) then
						allTriggers.Auras [spellId] = {scriptObject}
					else
						tinsert (triggerTable, scriptObject)
					end
				
				elseif (scriptObject.ScriptType == 2) then
					--> triggers cast
					local triggerTable = allTriggers.Casts [spellId]
					if (not triggerTable) then
						allTriggers.Casts [spellId] = {scriptObject}
					else
						tinsert (triggerTable, scriptObject)
					end

				end
			end
			
			for _, NpcId in ipairs (scriptObject.NpcNames) do
				local triggerTable = allTriggers.Npcs [NpcId]
				if (not triggerTable) then
					allTriggers.Npcs [NpcId] = {scriptObject}
				else
					tinsert (triggerTable, scriptObject)
				end
			end
		end
	end
	
	--> store scripts with overlap
	local scriptsWithOverlap = {
		Auras = {},
		Casts = {},
		Npcs = {},
	}
	
	local amount = 0
	
	--> check if there's more than 1 script for each trigger
	for triggerId, scriptsTable in pairs (allTriggers.Auras) do
		if (#scriptsTable > 1) then
			--overlap found
			scriptsWithOverlap.Auras [triggerId] = scriptsTable
			amount = amount + 1
		end
	end
	for triggerId, scriptsTable in pairs (allTriggers.Casts) do
		if (#scriptsTable > 1) then
			--overlap found
			scriptsWithOverlap.Casts [triggerId] = scriptsTable
			amount = amount + 1
		end
	end
	for triggerId, scriptsTable in pairs (allTriggers.Npcs) do
		if (#scriptsTable > 1) then
			--overlap found
			scriptsWithOverlap.Npcs [triggerId] = scriptsTable
			amount = amount + 1
		end
	end
	
	return scriptsWithOverlap, amount
end

--retrive the script object for a selected scriptId
function Plater.GetScriptObject (scriptID, scriptType)
	if (scriptType == "script") then
		local script = Plater.db.profile.script_data [scriptID]
		if (script) then
			return script
		end
		
	elseif (scriptType == "hook") then
		local script = Plater.db.profile.hook_data [scriptID]
		if (script) then
			return script
		end

	end
end

--return the main db table for the script type
function Plater.GetScriptDB (scriptType)
	if (scriptType == "script") then
		return Plater.db.profile.script_data
		
	elseif (scriptType == "hook") then
		return Plater.db.profile.hook_data
	end
end

--if the type of a scriptObject is unknown
function Plater.GetScriptType (scriptObject)
	if (scriptObject.Hooks) then
		return "hook"
	elseif (scriptObject.SpellIds) then
		return "script"
	end
end

--an indexScriptTable is a table decoded from an imported string, Plater uses this table to build an scriptObject
--check the type of indexes in the indexScriptTable to determine which type of script is this
--this is done to avoid sending an extra index just to tell which type of script is the string
function Plater.GetDecodedScriptType (indexScriptTable)
	if (type (indexScriptTable [9]) == "table") then --hook
		return "hook"
	elseif (type (indexScriptTable [9]) == "number") then --script
		return "script"
	end
end

--import scripts from the library
--autoImportScript is a table holding the revision number, the string to import and the type of script
function Plater.ImportScriptsFromLibrary()
	if (PlaterScriptLibrary) then
		for name, autoImportScript in pairs (PlaterScriptLibrary) do
			local importedDB
			
			if (autoImportScript.ScriptType == "script") then
				importedDB = Plater.db.profile.script_auto_imported
				
			elseif (autoImportScript.ScriptType == "hook") then
				importedDB = Plater.db.profile.hook_auto_imported
			end
			
			if ((importedDB [name] or 0) < autoImportScript.Revision) then
				importedDB [name] = autoImportScript.Revision

				local encodedString = autoImportScript.String
				if (encodedString) then
					local success, scriptAdded = Plater.ImportScriptString (encodedString, true, false, false)
					if (success) then
						if (autoImportScript.Revision == 1) then
							Plater:Msg ("New Script Installed: " .. name)
						else
							Plater:Msg ("Applied Update to Script: " .. name)
						end
						
						--all scripts imported are enabled by default, if the import object has a enabled member, probably its value is false
						if (type (autoImportScript.Enabled) == "boolean") then
							scriptAdded.Enabled = autoImportScript.Enabled
						end
					end
				end
			end
		end
		
		--can't wipe because it need to be reused when a new profile is created
		--table.wipe (PlaterScriptLibrary)
	end
end

--import a string from any source with more options than the convencional importer
--this is used when importing scripts from the library and when the user inserted the wrong script type in the import box at hook or script, e.g. imported a hook in the script import box
--guarantee to always receive a 'print' type of encode
function Plater.ImportScriptString (text, ignoreRevision, overrideTriggers, showDebug)
	if (not text or type (text) ~= "string") then
		return
	end
	
	local errortext, objectAdded
	
	local indexScriptTable = Plater.DecompressData (text, "print")
	if (indexScriptTable and type (indexScriptTable) == "table") then

		--get the script type, if is a hook or regular script
		local scriptType = Plater.GetDecodedScriptType (indexScriptTable)
		local newScript = Plater.BuildScriptObjectFromIndexTable (indexScriptTable, scriptType)
		
		if (newScript) then
		
			if (scriptType == "script") then
				local scriptName = newScript.Name
				local alreadyExists = false
				local scriptDB = Plater.GetScriptDB (scriptType)
				
				for i = 1, #Plater.db.profile.script_data do
					local scriptObject = scriptDB [i]
					if (scriptObject.Name == scriptName) then
						--the script already exists
						if (not ignoreRevision) then
							if (scriptObject.Revision >= newScript.Revision) then
								if (showDebug) then
									Plater:Msg ("Your version of this script is newer or is the same version.")
									return false
								end
							end
						end
						
						--add to the new script object, triggers that the current script has, since the user might have added some
						if (not overrideTriggers) then
							if (newScript.ScriptType == 0x1 or newScript.ScriptType == 0x2) then
								--aura or cast trigger
								for index, trigger in ipairs (scriptObject.SpellIds) do
									DF.table.addunique (newScript.SpellIds, trigger)
								end
							else
								--npc trigger
								for index, trigger in ipairs (scriptObject.NpcNames) do
									DF.table.addunique (newScript.SpellIds, trigger)
								end
							end
						end
						
						--keep the enabled state
						newScript.Enabled = scriptObject.Enabled
						
						--replace the old script with the new one
						tremove (scriptDB, i)
						tinsert (scriptDB, i, newScript)
						objectAdded = newScript
						
						if (showDebug) then
							Plater:Msg ("Script replaced by a newer one.")
						end
						
						alreadyExists = true
						break
					end
				end
				
				if (not alreadyExists) then
					tinsert (scriptDB, newScript)
					objectAdded = newScript
					if (showDebug) then
						Plater:Msg ("Script added.")
					end
				end
				
			elseif (scriptType == "hook") then
				
				local scriptName = newScript.Name
				local alreadyExists = false
				local scriptDB = Plater.GetScriptDB (scriptType)
				
				for i = 1, #Plater.db.profile.hook_data do
					local scriptObject = scriptDB [i]
					if (scriptObject.Name == scriptName) then
						--the script already exists
						if (not ignoreRevision) then
							if (scriptObject.Revision >= newScript.Revision) then
								if (showDebug) then
									Plater:Msg ("Your version of this script is newer or is the same version.")
									return false
								end
							end
						end
						
						--keep the enabled state
						newScript.Enabled = scriptObject.Enabled
						
						--replace the old script with the new one
						tremove (scriptDB, i)
						tinsert (scriptDB, i, newScript)
						objectAdded = newScript
						
						if (showDebug) then
							Plater:Msg ("Script replaced by a newer one.")
						end
						
						alreadyExists = true
						break
					end
				end
				
				if (not alreadyExists) then
					tinsert (scriptDB, newScript)
					objectAdded = newScript
					if (showDebug) then
						Plater:Msg ("Script added.")
					end
				end

			end
		else
			errortext = "Cannot import: data imported is invalid"
		end
	else
		errortext = "Cannot import: data imported is invalid"
	end
	
	if (errortext and showDebug) then
		Plater:Msg (errortext)
		return false
	end
	
	return true, objectAdded
end

--add a scriptObject to the script db
--if noOverwrite is passed, it won't replace if a script with the same name already exists
function Plater.AddScript (scriptObjectToAdd, noOverwrite)
	if (scriptObjectToAdd) then
		local indexToReplace
		local scriptType = Plater.GetScriptType (scriptObjectToAdd)
		local scriptDB = Plater.GetScriptDB (scriptType)
		
		--check if already exists
		for i = 1, #scriptDB do
			local scriptObject = scriptDB [i]
			if (scriptObject.Name == scriptObjectToAdd.Name) then
				--the script already exists
				if (noOverwrite) then
					return
				else
					indexToReplace = i
					break
				end
			end
		end
		
		if (indexToReplace) then
			--remove the old script and add the new one
			tremove (scriptDB, indexToReplace)
			tinsert (scriptDB, indexToReplace, scriptObjectToAdd)
		else
			--add the new script to the end of the table
			tinsert (scriptDB, scriptObjectToAdd)
		end
	end
end

--get a index table from an imported string and build a scriptObject from it
function Plater.BuildScriptObjectFromIndexTable (indexTable, scriptType)
	
	if (scriptType == "hook") then
		local scriptObject = {}
		scriptObject.Enabled 		= true --imported scripts are always enabled
		scriptObject.Name		= indexTable [1]
		scriptObject.Icon			= indexTable [2]
		scriptObject.Desc		= indexTable [3]
		scriptObject.Author		= indexTable [4]
		scriptObject.Time			= indexTable [5]
		scriptObject.Revision		= indexTable [6]
		scriptObject.PlaterCore		= indexTable [7]
		scriptObject.LoadConditions	= indexTable [8]

		scriptObject.Hooks = {}
		scriptObject.HooksTemp = {}
		scriptObject.LastHookEdited = ""
		
		for hookName, hookCode in pairs (indexTable [9]) do
			scriptObject.Hooks [hookName] = hookCode
		end
		
		return scriptObject
		
	elseif (scriptType == "script") then
		local scriptObject = {}
		
		scriptObject.Enabled 		= true --imported scripts are always enabled
		scriptObject.ScriptType 	= indexTable [1]
		scriptObject.Name  		= indexTable [2]
		scriptObject.SpellIds  		= indexTable [3]
		scriptObject.NpcNames  	= indexTable [4]
		scriptObject.Icon  		= indexTable [5]
		scriptObject.Desc  		= indexTable [6]
		scriptObject.Author  		= indexTable [7]
		scriptObject.Time  		= indexTable [8]
		scriptObject.Revision  		= indexTable [9]
		scriptObject.PlaterCore  	= indexTable [10]
		
		for i = 1, #Plater.CodeTypeNames do
			local memberName = Plater.CodeTypeNames [i]
			scriptObject [memberName] = indexTable [10 + i]
		end
		
		return scriptObject
	end
end

--transform the string into a indexScriptTable and then transform it into a scriptObject
function Plater.DecodeImportedString (str)
	local LibAceSerializer = LibStub:GetLibrary ("AceSerializer-3.0")
	if (LibAceSerializer) then
		-- ~zip
		local decoded = DF.DecodeString (str)
		if (decoded) then
			local unSerializedOkay, indexScriptTable = LibAceSerializer:Deserialize (decoded)
			if (unSerializedOkay and type (indexScriptTable) == "table") then
				local scriptObject = Plater.BuildScriptObjectFromIndexTable (indexScriptTable, Plater.GetDecodedScriptType (indexScriptTable))
				if (scriptObject) then
					return scriptObject
				end
			end
		end
	end
end

--make an indexScriptTable for the script object using indexes instead of key to decrease the size of the string to be exported
function Plater.PrepareTableToExport (scriptObject)
	
	if (scriptObject.Hooks) then
		--script for hooks
		local t = {}
		
		t [1] = scriptObject.Name
		t [2] = scriptObject.Icon
		t [3] = scriptObject.Desc
		t [4] = scriptObject.Author
		t [5] = scriptObject.Time
		t [6] = scriptObject.Revision
		t [7] = scriptObject.PlaterCore
		t [8] = scriptObject.LoadConditions
		t [9] = {}

		for hookName, hookCode in pairs (scriptObject.Hooks) do
			t [9] [hookName] = hookCode
		end
		
		return t
	else
		--regular script for aura cast or unitID
		local t = {}
		
		t [1] = scriptObject.ScriptType
		t [2] = scriptObject.Name
		t [3] = scriptObject.SpellIds
		t [4] = scriptObject.NpcNames
		t [5] = scriptObject.Icon
		t [6] = scriptObject.Desc
		t [7] = scriptObject.Author
		t [8] = scriptObject.Time
		t [9] = scriptObject.Revision
		t [10] = scriptObject.PlaterCore
		
		for i = 1, #Plater.CodeTypeNames do
			local memberName = Plater.CodeTypeNames [i]
			t [#t + 1] = scriptObject [memberName]
		end
		
		return t
	end
end

function Plater.ScriptReceivedFromGroup (prefix, playerName, playerRealm, playerGUID, importedString)
	if (not Plater.db.profile.script_banned_user [playerGUID]) then
		
		local indexScriptTable = Plater.DecompressData (importedString, "comm")
		if (indexScriptTable and type (indexScriptTable) == "table") then
		
			local importedScriptObject = Plater.BuildScriptObjectFromIndexTable (indexScriptTable, Plater.GetDecodedScriptType (indexScriptTable))
			if (not importedScriptObject) then
				return
			end

			local scriptName = importedScriptObject.Name
			local alreadyExists = false
			local alreadyExistsVersion = 0
			
			local scriptType = Plater.GetScriptType (importedScriptObject)
			local scriptDB = Plater.GetScriptDB (scriptType)

			for i = 1, #scriptDB do
				local scriptObject = scriptDB [i]
				if (scriptObject.Name == scriptName) then
					alreadyExists = true
					alreadyExistsVersion = scriptObject.Revision
					break
				end
			end

			--add the script to the queue
			Plater.ScriptsWaitingApproval = Plater.ScriptsWaitingApproval or {}
			tinsert (Plater.ScriptsWaitingApproval, {importedScriptObject, playerName, playerRealm, playerGUID, alreadyExists, alreadyExistsVersion})
			
			Plater.ShowImportScriptConfirmation()
		end
	end
end

function Plater.ExportScriptToGroup (scriptId, scriptType)
	local scriptToSend = Plater.GetScriptObject (scriptId, scriptType)
	
	if (not scriptToSend) then
		Plater:Msg ("script not found", scriptId)
		return
	end
	
	--convert hash table to index table for smaller size
	local indexedScriptTable = Plater.PrepareTableToExport (scriptToSend)
	--compress the indexed table for WoWAddonChannel
	local encodedString = Plater.CompressData (indexedScriptTable, "comm")
	
	if (encodedString) then
		
		local LibAceSerializer = LibStub:GetLibrary ("AceSerializer-3.0")
		
		if (IsInRaid (LE_PARTY_CATEGORY_HOME)) then
			Plater:SendCommMessage (COMM_PLATER_PREFIX, LibAceSerializer:Serialize (COMM_SCRIPT_GROUP_EXPORTED, UnitName ("player"), GetRealmName(), UnitGUID ("player"), encodedString), "RAID")
			
		elseif (IsInGroup (LE_PARTY_CATEGORY_HOME)) then
			Plater:SendCommMessage (COMM_PLATER_PREFIX, LibAceSerializer:Serialize (COMM_SCRIPT_GROUP_EXPORTED, UnitName ("player"), GetRealmName(), UnitGUID ("player"), encodedString), "PARTY")
			
		else
			Plater:Msg ("Failed to send the script: your group isn't home group.")
		end
	else
		Plater:Msg ("Fail to encode scriptId", scriptId)
	end
end

function Plater.ShowImportScriptConfirmation()

	if (not Plater.ImportConfirm) then
		Plater.ImportConfirm = DF:CreateSimplePanel (UIParent, 380, 130, "Plater Nameplates: Script Importer", "PlaterImportScriptConfirmation")
		Plater.ImportConfirm:Hide()
		DF:ApplyStandardBackdrop (Plater.ImportConfirm)
		
		Plater.ImportConfirm.AcceptText = Plater:CreateLabel (Plater.ImportConfirm, "", Plater:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		Plater.ImportConfirm.AcceptText:SetPoint (16, -26)
		
		Plater.ImportConfirm.ScriptName = Plater:CreateLabel (Plater.ImportConfirm, "", Plater:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		Plater.ImportConfirm.ScriptName:SetPoint (16, -41)
		
		Plater.ImportConfirm.ScriptVersion = Plater:CreateLabel (Plater.ImportConfirm, "", Plater:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		Plater.ImportConfirm.ScriptVersion:SetPoint (16, -56)
		
		local accept_aura = function (self, button, scriptObject)
			Plater.AddScript (scriptObject)
			Plater.ImportConfirm:Hide()
			Plater.ShowImportScriptConfirmation()
		end
		
		local decline_aura = function (self, button, scriptObject, senderGUID)
			if (Plater.ImportConfirm.AlwaysIgnoreCheckBox.value) then
				Plater.db.profile.script_banned_user [senderGUID] = true
				Plater:Msg ("the user won't send more scripts to you.")
			end
			Plater.ImportConfirm:Hide()
			Plater.ShowImportScriptConfirmation()
		end
		
		Plater.ImportConfirm.AcceptButton = Plater:CreateButton (Plater.ImportConfirm, accept_aura, 125, 20, "Accept", -1, nil, nil, nil, nil, nil, Plater:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"))
		Plater.ImportConfirm.DeclineButton = Plater:CreateButton (Plater.ImportConfirm, decline_aura, 125, 20, "Decline", -1, nil, nil, nil, nil, nil, Plater:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"))
		
		Plater.ImportConfirm.AcceptButton:SetPoint ("bottomright", Plater.ImportConfirm, "bottomright", -14, 31)
		Plater.ImportConfirm.DeclineButton:SetPoint ("bottomleft", Plater.ImportConfirm, "bottomleft", 14, 31)
		
		Plater.ImportConfirm.AlwaysIgnoreCheckBox = DF:CreateSwitch (Plater.ImportConfirm, function()end, false, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, DF:GetTemplate ("switch", "OPTIONS_CHECKBOX_BRIGHT_TEMPLATE"))
		Plater.ImportConfirm.AlwaysIgnoreCheckBox:SetAsCheckBox()
		Plater.ImportConfirm.AlwaysIgnoreLabel = Plater:CreateLabel (Plater.ImportConfirm, "Always decline this user", Plater:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE"))
		Plater.ImportConfirm.AlwaysIgnoreCheckBox:SetPoint ("topleft", Plater.ImportConfirm.DeclineButton, "bottomleft", 0, -4)
		Plater.ImportConfirm.AlwaysIgnoreLabel:SetPoint ("left", Plater.ImportConfirm.AlwaysIgnoreCheckBox, "right", 2, 0)
		
		Plater.ImportConfirm.Flash = Plater.CreateFlash (Plater.ImportConfirm)
	end
	
	if (Plater.ImportConfirm:IsShown()) then
		Plater.ImportConfirm.Title:SetText ("Plater Nameplates: Script Importer (" .. #Plater.ScriptsWaitingApproval + 1 .. ")")
		return
	else
		Plater.ImportConfirm.Title:SetText ("Plater Nameplates: Script Importer (" .. #Plater.ScriptsWaitingApproval .. ")")
	end
	
	local nextScriptToApprove = tremove (Plater.ScriptsWaitingApproval)
	
	if (nextScriptToApprove) then
		local scriptObject = nextScriptToApprove [1]
		local senderGUID = nextScriptToApprove [4]
	
		rawset (Plater.ImportConfirm.AcceptButton, "param1", scriptObject)
		rawset (Plater.ImportConfirm.AcceptButton, "param2", senderGUID)
		rawset (Plater.ImportConfirm.DeclineButton, "param1", scriptObject)
		rawset (Plater.ImportConfirm.DeclineButton, "param2", senderGUID)
		
		Plater.ImportConfirm.AcceptText.text = "The user |cFFFFAA00" .. nextScriptToApprove [2] .. "|r sent the script: |cFFFFAA00" .. scriptObject.Name .. "|r"
		Plater.ImportConfirm.ScriptName.text = "Script Version: |cFFFFAA00" .. scriptObject.Revision .. "|r"
		Plater.ImportConfirm.ScriptVersion.text = nextScriptToApprove [5] and "|cFFFFAA33You already have this script on version:|r " .. nextScriptToApprove [6] or "|cFF33DD33You don't have this script yet!"
		
		Plater.ImportConfirm:SetPoint ("center", UIParent, "center", 0, 150)
		Plater.ImportConfirm.AlwaysIgnoreCheckBox:SetValue (false)
		Plater.ImportConfirm.Flash:Play()
		Plater.ImportConfirm:Show()
		
		--play audio: IgPlayerInvite or igPlayerInviteDecline
	else
		Plater.ImportConfirm:Hide()
	end
	
end

--override colors
--function to set in the installhook for the default UI color change
function Plater.ColorOverrider (unitFrame)
	--is a namepalte and can override the color
	if (unitFrame.isNamePlate and Plater.CanOverrideColor) then
		--not in combat or aggro isn't changing the healthbar color
		if (not InCombatLockdown() or not DB_AGGRO_CHANGE_HEALTHBAR_COLOR) then
			--isn't a quest
			if (not unitFrame:GetParent() [MEMBER_QUEST]) then
				local reaction = unitFrame [MEMBER_REACTION]
				--is has a valid reaction
				if (reaction) then
					local r, g, b = unpack (Plater.db.profile.color_override_colors [reaction])
					Plater.ForceChangeHealthBarColor (unitFrame.healthBar, r, g, b, true)
				end
			end
		end
	end
end

--when the default unit frame refreshes the nameplate color, check if is in combat and if can use aggro to refresh the color by aggro
function Plater.OnHealthColorChange_Hook (unitFrame)
	if (unitFrame.isNamePlate and PLAYER_IN_COMBAT and unitFrame.CanCheckAggro) then
		if (unitFrame:GetParent() [MEMBER_REACTION] <= 4) then
			if (DB_AGGRO_CHANGE_HEALTHBAR_COLOR) then
				local healthBar = unitFrame.healthBar
				Plater.ForceChangeHealthBarColor (healthBar, healthBar.R, healthBar.G, healthBar.B)
			end
		end
	else
		if (unitFrame:GetParent().actorType == ACTORTYPE_PLAYER) then
			unitFrame.healthBar.barTexture:SetVertexColor (unitFrame.healthBar.R, unitFrame.healthBar.G, unitFrame.healthBar.B)
		end
	end
end
InstallHook ("CompactUnitFrame_UpdateHealthColor", Plater.OnHealthColorChange_Hook)

--refresh the use of the color overrider
function Plater.RefreshColorOverride()
	if (Plater.db.profile.color_override) then
		InstallHook ("CompactUnitFrame_UpdateHealthColor", Plater.ColorOverrider)
		Plater.CanOverrideColor = true
	else
		Plater.CanOverrideColor = false
	end
	
	Plater.UpdateAllNameplateColors()
end

-- ~profile
function Plater:RefreshConfig()
	Plater.IncreaseRefreshID()

	Plater.RefreshDBUpvalues()
	
	Plater.UpdateAllPlates()
	
	if (PlaterOptionsPanelFrame) then
		PlaterOptionsPanelFrame.RefreshOptionsFrame()
	end
	
	Plater.UpdateUseCastBar()
	Plater.UpdateUseClassColors()
end

function Plater.SaveConsoleVariables()
	local cvarTable = Plater.db.profile.saved_cvars
	
	if (not cvarTable) then
		return
	end
	
	--> personal and resources
	cvarTable ["nameplateShowSelf"] = GetCVar ("nameplateShowSelf")
	cvarTable [CVAR_RESOURCEONTARGET] = GetCVar (CVAR_RESOURCEONTARGET)
	cvarTable ["nameplatePersonalShowAlways"] = GetCVar ("nameplatePersonalShowAlways")
	cvarTable ["nameplatePersonalShowWithTarget"] = GetCVar ("nameplatePersonalShowWithTarget")
	cvarTable ["nameplatePersonalShowInCombat"] = GetCVar ("nameplatePersonalShowInCombat")
	cvarTable ["nameplateSelfAlpha"] = GetCVar ("nameplateSelfAlpha")
	cvarTable ["nameplateSelfScale"] = GetCVar ("nameplateSelfScale")
	
	--> which nameplates to show
	cvarTable [CVAR_SHOWALL] = GetCVar (CVAR_SHOWALL)
	cvarTable [CVAR_AGGROFLASH] = GetCVar (CVAR_AGGROFLASH)
	cvarTable [CVAR_ENEMY_MINIONS] = GetCVar (CVAR_ENEMY_MINIONS)
	cvarTable [CVAR_ENEMY_MINUS] = GetCVar (CVAR_ENEMY_MINUS)
	cvarTable [CVAR_FRIENDLY_GUARDIAN] = GetCVar (CVAR_FRIENDLY_GUARDIAN)
	cvarTable [CVAR_FRIENDLY_PETS] = GetCVar (CVAR_FRIENDLY_PETS)
	cvarTable [CVAR_FRIENDLY_TOTEMS] = GetCVar (CVAR_FRIENDLY_TOTEMS)
	cvarTable [CVAR_FRIENDLY_MINIONS] = GetCVar (CVAR_FRIENDLY_MINIONS)
	
	--> make it show the class color of players
	cvarTable [CVAR_CLASSCOLOR] = GetCVar (CVAR_CLASSCOLOR)
	
	--> just reset to default the clamp from the top side
	cvarTable [CVAR_CEILING] = GetCVar (CVAR_CEILING)
	
	--> reset the horizontal and vertical scale
	cvarTable [CVAR_SCALE_HORIZONTAL] = GetCVar (CVAR_SCALE_HORIZONTAL)
	cvarTable [CVAR_SCALE_VERTICAL] = GetCVar (CVAR_SCALE_VERTICAL)
	
	--> stacking nameplates
	cvarTable [CVAR_PLATEMOTION] = GetCVar (CVAR_PLATEMOTION)
	
	--> make the selection be a little bigger
	cvarTable ["nameplateSelectedScale"] = GetCVar ("nameplateSelectedScale")
	cvarTable ["nameplateMinScale"] = GetCVar ("nameplateMinScale")
	cvarTable ["nameplateGlobalScale"] = GetCVar ("nameplateGlobalScale")
	
	--> distance between each nameplate when using stacking
	cvarTable ["nameplateOverlapV"] = GetCVar ("nameplateOverlapV")
	
	--> movement speed of nameplates when using stacking, going above this isn't recommended
	cvarTable [CVAR_MOVEMENT_SPEED] = GetCVar (CVAR_MOVEMENT_SPEED)
	--> this must be 1 for bug reasons on the game client
	cvarTable ["nameplateOccludedAlphaMult"] = GetCVar ("nameplateOccludedAlphaMult")
	--> don't show friendly npcs
	cvarTable ["nameplateShowFriendlyNPCs"] = GetCVar ("nameplateShowFriendlyNPCs")
	--> make the personal bar hide very fast
	cvarTable ["nameplatePersonalHideDelaySeconds"] = GetCVar ("nameplatePersonalHideDelaySeconds")
	
	--> location of the personagem bar
	cvarTable ["nameplateSelfBottomInset"] = GetCVar ("nameplateSelfBottomInset")
	cvarTable ["nameplateSelfTopInset"] = GetCVar ("nameplateSelfTopInset")
	
	--> view distance
	cvarTable [CVAR_CULLINGDISTANCE] = GetCVar (CVAR_CULLINGDISTANCE)
	
end

--refresh call back will run all functions in its table when Plater refreshes the dynamic upvales for the file
Plater.DBRefreshCallback = {}
function Plater.RegisterRefreshDBCallback (func)
	DF.table.addunique (Plater.DBRefreshCallback, func)
end
function Plater.FireRefreshDBCallback()
	for _, func in ipairs (Plater.DBRefreshCallback) do
		DF:Dispatch (func)
	end
end

--place most used data into local upvalues to save process time
function Plater.RefreshDBUpvalues()
	local profile = Plater.db.profile

	DB_TICK_THROTTLE = profile.update_throttle
	DB_LERP_COLOR = profile.use_color_lerp
	DB_LERP_COLOR_SPEED = profile.color_lerp_speed
	DB_PLATE_CONFIG = profile.plate_config
	DB_TRACK_METHOD = profile.aura_tracker.track_method
	
	DB_DO_ANIMATIONS = profile.use_health_animation
	DB_ANIMATION_TIME_DILATATION = profile.health_animation_time_dilatation
	
	DB_HOVER_HIGHLIGHT = profile.hover_highlight
	DB_USE_RANGE_CHECK = profile.range_check_enabled
	
	--> load spells filtered out, use the spellname instead of the spellId
		if (not DB_BUFF_BANNED) then
			DB_BUFF_BANNED = {}
			DB_DEBUFF_BANNED = {}
		else
			wipe (DB_BUFF_BANNED)
			wipe (DB_DEBUFF_BANNED)
		end
	
		for spellId, state in pairs (profile.aura_tracker.buff_banned) do
			local spellName = GetSpellInfo (spellId)
			if (spellName) then
				DB_BUFF_BANNED [spellName] = true
			end
		end
		
		for spellId, state in pairs (profile.aura_tracker.debuff_banned) do
			local spellName = GetSpellInfo (spellId)
			if (spellName) then
				DB_DEBUFF_BANNED [spellName] = true
			end
		end
	
	DB_AURA_ENABLED = profile.aura_enabled
	DB_AURA_ALPHA = profile.aura_alpha
	DB_AURA_X_OFFSET = profile.aura_x_offset
	DB_AURA_Y_OFFSET = profile.aura_y_offset
	
	DB_AURA_SEPARATE_BUFFS = Plater.db.profile.buffs_on_aura2

	DB_AURA_SHOW_IMPORTANT = profile.aura_show_important
	DB_AURA_SHOW_DISPELLABLE = profile.aura_show_dispellable
	DB_AURA_SHOW_BYPLAYER = profile.aura_show_aura_by_the_player
	DB_AURA_SHOW_BYUNIT = profile.aura_show_buff_by_the_unit

	DB_AURA_GROW_DIRECTION = profile.aura_grow_direction
	DB_AURA_GROW_DIRECTION2 = profile.aura2_grow_direction
	
	DB_BORDER_COLOR_R = profile.border_color [1]
	DB_BORDER_COLOR_G = profile.border_color [2]
	DB_BORDER_COLOR_B = profile.border_color [3]
	DB_BORDER_COLOR_A = profile.border_color [4]
	DB_BORDER_THICKNESS = profile.border_thickness
	DB_AGGRO_CHANGE_HEALTHBAR_COLOR = profile.aggro_modifies.health_bar_color
	DB_AGGRO_CHANGE_BORDER_COLOR = profile.aggro_modifies.border_color
	DB_AGGRO_CHANGE_NAME_COLOR = profile.aggro_modifies.actor_name_color
	
	DB_AGGRO_TANK_COLORS = profile.tank.colors
	DB_AGGRO_DPS_COLORS = profile.dps.colors
	
	DB_NOT_COMBAT_ALPHA_ENABLED = profile.not_affecting_combat_enabled
	
	DB_TARGET_SHADY_ENABLED = profile.target_shady_enabled
	DB_TARGET_SHADY_ALPHA = profile.target_shady_alpha
	DB_TARGET_SHADY_COMBATONLY = profile.target_shady_combat_only
	
	DB_NAME_NPCENEMY_ANCHOR = profile.plate_config.enemynpc.actorname_text_anchor.side
	DB_NAME_NPCFRIENDLY_ANCHOR = profile.plate_config.friendlynpc.actorname_text_anchor.side
	DB_NAME_PLAYERENEMY_ANCHOR = profile.plate_config.enemyplayer.actorname_text_anchor.side
	DB_NAME_PLAYERFRIENDLY_ANCHOR = profile.plate_config.friendlyplayer.actorname_text_anchor.side
	
	DB_TEXTURE_CASTBAR = LibSharedMedia:Fetch ("statusbar", profile.cast_statusbar_texture)
	DB_TEXTURE_CASTBAR_BG = LibSharedMedia:Fetch ("statusbar", profile.cast_statusbar_bgtexture)
	DB_TEXTURE_HEALTHBAR = LibSharedMedia:Fetch ("statusbar", profile.health_statusbar_texture)
	DB_TEXTURE_HEALTHBAR_BG = LibSharedMedia:Fetch ("statusbar", profile.health_statusbar_bgtexture)	
	
	DB_CASTBAR_HIDE_ENEMIES = profile.hide_enemy_castbars
	DB_CASTBAR_HIDE_FRIENDLY = profile.hide_friendly_castbars
	
	DB_CAPTURED_SPELLS = profile.captured_spells
	
	DB_SHOW_PURGE_IN_EXTRA_ICONS = profile.extra_icon_show_purge
	
	if (Plater.db.profile.healthbar_framelevel ~= 0 or Plater.db.profile.castbar_framelevel ~= 0) then
		DB_UPDATE_FRAMELEVEL = true
	else
		DB_UPDATE_FRAMELEVEL = false
	end
	
	--
	Plater.RefreshDBLists()
end

function Plater.RefreshDBLists()

	local profile = Plater.db.profile

	wipe (SPELL_WITH_ANIMATIONS)
	
	if (profile.spell_animations) then
		--for spellId, spellOptions in pairs (profile.spell_animation_list) do
		for spellId, animations in pairs (profile.spell_animation_list) do
			local frameAnimations = {}
			local spellName = GetSpellInfo (spellId)
			if (spellName) then
				for animationIndex, animationOptions in ipairs (animations) do
					if (animationOptions.enabled) then
						local data = DF.table.deploy ({}, animationOptions)
						data.animationCooldown = {} --store nameplate references with [nameplateRef] = GetTime() + cooldown
						tinsert (frameAnimations, data)
					end
				end
			end
			
			SPELL_WITH_ANIMATIONS [spellName] = frameAnimations
		end
	end
	
	wipe (SPECIAL_AURA_NAMES)
	wipe (SPECIAL_AURA_NAMES_MINE)
	wipe (CROWDCONTROL_AURA_NAMES)
	
	IS_USING_DETAILS_INTEGRATION = false
	
	--details integration
	if (Details and Details.plater) then
		local detailsPlaterConfig = Details.plater
		if (detailsPlaterConfig.realtime_dps_enabled) then
			IS_USING_DETAILS_INTEGRATION = true
		elseif (detailsPlaterConfig.realtime_dps_player_enabled) then
			IS_USING_DETAILS_INTEGRATION = true
		elseif (detailsPlaterConfig.damage_taken_enabled) then
			IS_USING_DETAILS_INTEGRATION = true
		end
	end	
	
	--build the crowd control list
	if (profile.debuff_show_cc) then
		for spellId, _ in pairs (DF.CrowdControlSpells) do
			local spellName = GetSpellInfo (spellId)
			if (spellName) then
				SPECIAL_AURA_NAMES [spellName] = true
				CROWDCONTROL_AURA_NAMES [spellName] = true
			end
		end
	end
	
	--> add auras added by the player into the special aura container
	for index, spellId in ipairs (profile.extra_icon_auras) do
		local spellName = GetSpellInfo (spellId)
		if (spellName) then
			SPECIAL_AURA_NAMES [spellName] = true
		end
	end
	
	for index, spellId in ipairs (profile.extra_icon_auras_mine) do
		local spellName = GetSpellInfo (spellId)
		if (spellName) then
			SPECIAL_AURA_NAMES_MINE [spellName] = true
		end
	end
	
	Plater.UpdateAuraCache()
	Plater.IncreaseRefreshID()
	
	Plater.FireRefreshDBCallback()
end

function Plater.ApplyPatches()
	if (PlaterPatchLibrary) then
		local currentPatch = Plater.db.profile.patch_version
		for i = currentPatch+1, #PlaterPatchLibrary do
		
			local patch = PlaterPatchLibrary [i]
			Plater:Msg ("Applied Patch #" .. i .. ":")
			
			for o = 1, #patch.Notes do
				print (patch.Notes [o])
			end
			
			DF:Dispatch (patch.Func)
			
			Plater.db.profile.patch_version = i
		end
		
		--do not clear patch library, when creating a new profile it'll need to re-apply patches
		--PlaterPatchLibrary = nil
	end
end

function Plater.OnInit()
	Plater.RefreshDBUpvalues()
	
	Plater.CombatTime = GetTime()

	PLAYER_IN_COMBAT = false
	if (InCombatLockdown()) then
		PLAYER_IN_COMBAT = true
	end
	
	--configura��o do personagem
	PlaterDBChr = PlaterDBChr or {first_run2 = {}}
	PlaterDBChr.first_run2 = PlaterDBChr.first_run2 or {}
	
	PlaterDBChr.debuffsBanned = PlaterDBChr.debuffsBanned or {}
	PlaterDBChr.buffsBanned = PlaterDBChr.buffsBanned or {}
	PlaterDBChr.spellRangeCheck = PlaterDBChr.spellRangeCheck or {}
	
	for specID, _ in pairs (Plater.SpecList [select (2, UnitClass ("player"))]) do
		if (PlaterDBChr.spellRangeCheck [specID] == nil) then
			PlaterDBChr.spellRangeCheck [specID] = GetSpellInfo (Plater.DefaultSpellRangeList [specID])
		end
	end
	Plater.SpellForRangeCheck = ""
	Plater.PlayerGUID = UnitGUID ("player")
	Plater.PlayerClass = select (2, UnitClass ("player"))
	
	Plater.ImportScriptsFromLibrary()
	Plater.ApplyPatches()
	
	Plater.CompileAllScripts ("script")
	Plater.CompileAllScripts ("hook")
	
	local Masque = LibStub ("Masque", true)
	if (Masque) then
		Plater.Masque = {}
		Plater.Masque.AuraFrame1 = Masque:Group ("Plater Nameplates", "Aura Frame 1")
		Plater.Masque.AuraFrame2 = Masque:Group ("Plater Nameplates", "Aura Frame 2")
		Plater.Masque.BuffSpecial = Masque:Group ("Plater Nameplates", "Buff Special")
	end
	
	local re_ForceCVars = function()
		Plater.ForceCVars()
	end
	function Plater.ForceCVars()
		if (InCombatLockdown()) then
			return C_Timer.After (1, re_ForceCVars)
		end
		SetCVar (CVAR_MIN_ALPHA, 0.90135484)
		SetCVar (CVAR_MIN_ALPHA_DIST, -10^5.2)
	end
	
	C_Timer.After (0.1, Plater.UpdatePlateClickSpace)
	C_Timer.After (1, Plater.GetSpellForRangeCheck)
	C_Timer.After (4, Plater.GetHealthCutoffValue)
	C_Timer.After (4.2, Plater.ForceCVars)
	
	function Plater.HookLoadCallback (encounterID)
		Plater.EncounterID = encounterID
		Plater.WipeAndRecompileAllScripts ("hook")
	end
	DF:CreateLoadFilterParser (Plater.HookLoadCallback)
	
	Plater.RefreshColorOverride()
	Plater.UpdateMaxCastbarTextLength()
	
	local _, zoneType = GetInstanceInfo()
	Plater.ZoneInstanceType = zoneType
	
	--> check if is the first time Plater is running in the account or in the character
	local check_first_run = function()
		if (not UnitGUID ("player")) then
			C_Timer.After (1, Plater.CheckFirstRun)
			return
		end
		
		if (not Plater.db.profile.first_run2) then
			C_Timer.After (15, Plater.SetCVarsOnFirstRun)
			
		elseif (not PlaterDBChr.first_run2 [UnitGUID ("player")]) then
			--do not run cvars for individual characters
			C_Timer.After (15, Plater.SetCVarsOnFirstRun)
		else
			Plater.ShutdownInterfaceOptionsPanel()
		end
	end
	
	function Plater.CheckFirstRun()
		check_first_run()
	end
	Plater.CheckFirstRun()
	
	Plater:RegisterEvent ("NAME_PLATE_CREATED")
	Plater:RegisterEvent ("NAME_PLATE_UNIT_ADDED")
	Plater:RegisterEvent ("NAME_PLATE_UNIT_REMOVED")
	
	Plater:RegisterEvent ("PLAYER_TARGET_CHANGED")
	Plater:RegisterEvent ("PLAYER_FOCUS_CHANGED")
	
	Plater:RegisterEvent ("PLAYER_REGEN_DISABLED")
	Plater:RegisterEvent ("PLAYER_REGEN_ENABLED")
	
	Plater:RegisterEvent ("ZONE_CHANGED_NEW_AREA")
	Plater:RegisterEvent ("ZONE_CHANGED_INDOORS")
	Plater:RegisterEvent ("ZONE_CHANGED")
	Plater:RegisterEvent ("FRIENDLIST_UPDATE")
	Plater:RegisterEvent ("PLAYER_LOGOUT")
	Plater:RegisterEvent ("PLAYER_UPDATE_RESTING")
	Plater:RegisterEvent ("RAID_TARGET_UPDATE")
	
	Plater:RegisterEvent ("QUEST_ACCEPTED")
	Plater:RegisterEvent ("QUEST_REMOVED")
	Plater:RegisterEvent ("QUEST_ACCEPT_CONFIRM")
	Plater:RegisterEvent ("QUEST_COMPLETE")
	Plater:RegisterEvent ("QUEST_POI_UPDATE")
	Plater:RegisterEvent ("QUEST_DETAIL")
	Plater:RegisterEvent ("QUEST_FINISHED")
	Plater:RegisterEvent ("QUEST_GREETING")
	Plater:RegisterEvent ("QUEST_LOG_UPDATE")
	Plater:RegisterEvent ("UNIT_QUEST_LOG_CHANGED")
	Plater:RegisterEvent ("PLAYER_SPECIALIZATION_CHANGED")
	Plater:RegisterEvent ("PLAYER_TALENT_UPDATE")
	
	Plater:RegisterEvent ("ENCOUNTER_START")
	Plater:RegisterEvent ("ENCOUNTER_END")
	Plater:RegisterEvent ("CHALLENGE_MODE_START")

	function Plater.RunScheduledUpdate (timerObject)
		local plateFrame = timerObject.plateFrame
		local unitGUID = timerObject.GUID
		
		--checking the serial of the unit is the same in case this nameplate is being used on another unit
		if (plateFrame:IsShown() and unitGUID == plateFrame [MEMBER_GUID]) then
			Plater ["NAME_PLATE_UNIT_ADDED"] (Plater, "NAME_PLATE_UNIT_ADDED", plateFrame [MEMBER_UNITID])
		end
	end
	
	function Plater.ScheduleUpdateForNameplate (plateFrame)
		--check if there's already an update scheduled for this unit
		if (plateFrame.HasUpdateScheduled and not plateFrame.HasUpdateScheduled._cancelled) then
			return
		else
			plateFrame.HasUpdateScheduled = C_Timer.NewTimer (0.75, Plater.RunScheduledUpdate)
			plateFrame.HasUpdateScheduled.plateFrame = plateFrame
			plateFrame.HasUpdateScheduled.GUID = plateFrame [MEMBER_GUID]
		end
	end
	
	--when a unit from unatackable change its state, this event triggers several times, a schedule is used to only update once
	function Plater:UNIT_FLAGS (event, unit)
		if (unit == "player") then
			return
		end
		
		local plateFrame = C_NamePlate.GetNamePlateForUnit (unit, issecure())
		if (plateFrame) then
			--rules if can schedule an update for unit flag event:
			
			--nameplate is from a npc which the player cannot attack and now the player can attack
			local playerCannotAttack = plateFrame.PlayerCannotAttack
			--the player is in open world, dungeons and raids does trigger unit flag event but won't need a full refresh
			local playerInOpenWorld = IS_IN_OPEN_WORLD
			
			if (playerCannotAttack or playerInOpenWorld) then
				--print ("UNIT_FLAG", plateFrame, issecure(), unit, unit and UnitName (unit))
				Plater.ScheduleUpdateForNameplate (plateFrame)
			end
		end
	end
	
	function Plater:UNIT_FACTION (event, unit)
		if (unit == "player" or not UnitIsPlayer (unit)) then
			return
		end
		
		--fires when somebody changes faction near the player
		local plateFrame = C_NamePlate.GetNamePlateForUnit (unit, issecure())
		if (plateFrame) then
			Plater.ScheduleUpdateForNameplate (plateFrame)
		end
	end
	
	Plater:RegisterEvent ("UNIT_FLAGS")
	Plater:RegisterEvent ("UNIT_FACTION")
	
	--addon comm
	Plater.CommHandler = {
		[COMM_SCRIPT_GROUP_EXPORTED] = Plater.ScriptReceivedFromGroup,
	}
	
	function Plater:CommReceived (_, dataReceived)
		local LibAceSerializer = LibStub:GetLibrary ("AceSerializer-3.0")
		if (LibAceSerializer) then
			local prefix =  select (2, LibAceSerializer:Deserialize (dataReceived))
			local func = Plater.CommHandler [prefix]
			if (func) then
				local values = {LibAceSerializer:Deserialize (dataReceived)}
				if (values [1]) then
					tremove (values, 1) --remove the Deserialize state
					func (unpack (values))
				end
			end
		end
	end
	Plater:RegisterComm (COMM_PLATER_PREFIX, "CommReceived")
	
	--seta o nome do jogador na barra dele --ajuda a evitar os 'desconhecidos' pelo cliente do jogo (frame da unidade)
	InstallHook (Plater.GetDriverSubObjectName ("CompactUnitFrame", Plater.DriverFuncNames.OnNameUpdate), function (self)
		if (self.healthBar.actorName) then
			local plateFrame = self.PlateFrame
			plateFrame [MEMBER_NAME] = UnitName (self.unit)
			
			if (plateFrame.isSelf) then
				--name isn't shown in the personal bar
				plateFrame.UnitFrame.healthBar.actorName:SetText ("")
				self.name:SetText ("")
				return
			end
			
			if (plateFrame.actorType == ACTORTYPE_FRIENDLY_PLAYER) then
				plateFrame.playerGuildName = GetGuildInfo (plateFrame [MEMBER_UNITID])
				Plater.UpdatePlateText (plateFrame, DB_PLATE_CONFIG [plateFrame.actorType], false)
			end
			
			Plater.UpdateUnitName (plateFrame)
			self.name:SetText ("")
		end
	end)
	
	--quando trocar de target, da overwrite na textura de overlay do selected target (frame da unidade) --review
	InstallHook (Plater.GetDriverSubObjectName ("CompactUnitFrame", Plater.DriverFuncNames.OnSelectionUpdate), function (self)
		if (self.isNamePlate) then
			if (self.selectionHighlight:IsShown()) then
				local targetedOverlayTexture = LibSharedMedia:Fetch ("statusbar", Plater.db.profile.health_selection_overlay)
				self.selectionHighlight:SetTexture (targetedOverlayTexture)
			end
			Plater.UpdatePlateBorders()
		end
	end)

	InstallHook (Plater.GetDriverGlobalObject ("NamePlateBorderTemplateMixin"), Plater.DriverFuncNames.OnBorderUpdate, function (self)
		Plater.UpdatePlateBorders (self.plateFrame)
	end)
	
	--sobrep�e a fun��o que atualiza as auras
	local Override_UNIT_AURA_EVENT = function (self, unit)
		local nameplate = C_NamePlate.GetNamePlateForUnit (unit)
		if (nameplate) then
			local filter;
			if (UnitIsUnit ("player", unit)) then
				filter = "HELPFUL|INCLUDE_NAME_PLATE_ONLY|PLAYER";
			else
				local reaction = UnitReaction ("player", unit);
				if (reaction and reaction <= 4) then
					filter = "HARMFUL|PLAYER"; --"HARMFUL|INCLUDE_NAME_PLATE_ONLY|PLAYER"
				elseif (reaction and reaction > 4) then
					filter = "HELPFUL|PLAYER";
				else
					filter = "NONE";
				end
			end
			
			nameplate.UnitFrame.BuffFrame:UpdateBuffs (unit, filter);
		end
	end

	if (not Plater.db.profile.aura_use_default) then
		InstallHook (_G ["NamePlateDriverFrame"], Plater.DriverFuncNames.OnAuraUpdate, Override_UNIT_AURA_EVENT)
	end

	local BUFF_MAX_DISPLAY = BUFF_MAX_DISPLAY
	local CooldownFrame_Set = CooldownFrame_Set
	
	function Plater.Override_UpdateBuffs (self, unit, filter, showAll)
		if (not self [MEMBER_REACTION]) then
			--parece que nao esta colocando reaction em barras de jogadores
			return
		end

		--> shutdown the aura update from blizzard interface
		self.isActive = false
		self.BuffsAnchor.isActive = false
	end
	
	if (not Plater.db.profile.aura_use_default) then
		InstallHook (_G ["NameplateBuffContainerMixin"], Plater.DriverFuncNames.OnUpdateBuffs, Plater.Override_UpdateBuffs)
	end
	
	--sobrep�e a fun��o, economiza processamento uma vez que o resultado da fun��o original n�o � usado
	local Override_UNIT_AURA_ANCHORUPDATE = function (self)
		if (self.Point1) then
			self:SetPoint (self.Point1, self.Anchor, self.Point2, self.X, self.Y)
		end
	end
	
	if (not Plater.db.profile.aura_use_default) then
		InstallHook (_G ["NameplateBuffContainerMixin"], Plater.DriverFuncNames.OnUpdateAnchor, Override_UNIT_AURA_ANCHORUPDATE)
	end
	
	--tamanho dos �cones dos debuffs sobre a nameplate
	function Plater.UpdateAuraIcons (self, unit, filter)
	
		if (not self [MEMBER_REACTION]) then
			--parece que nao esta colocando reaction em barras de jogadores
			return
		end

		local amtDebuffs = 0
		for _, auraIconFrame in ipairs (self.PlaterBuffList) do
			if (auraIconFrame:IsShown()) then
			
				if (auraIconFrame.IsPersonal) then
					local auraWidth = Plater.db.profile.aura_width_personal
					local auraHeight = Plater.db.profile.aura_height_personal
					auraIconFrame:SetSize (auraWidth, auraHeight)
					auraIconFrame.Icon:SetSize (auraWidth-2, auraHeight-2)
				else
					local auraWidth = Plater.db.profile.aura_width
					local auraHeight = Plater.db.profile.aura_height
					auraIconFrame:SetSize (auraWidth, auraHeight)
					auraIconFrame.Icon:SetSize (auraWidth-2, auraHeight-2)
				end

				amtDebuffs = amtDebuffs + 1
			end
		end

		for _, auraIconFrame in ipairs (self.BuffsAnchor.PlaterBuffList) do
			if (auraIconFrame:IsShown()) then
			
				if (auraIconFrame.IsPersonal) then
					local auraWidth = Plater.db.profile.aura_width_personal
					local auraHeight = Plater.db.profile.aura_height_personal
					auraIconFrame:SetSize (auraWidth, auraHeight)
					auraIconFrame.Icon:SetSize (auraWidth-2, auraHeight-2)
				else
					local auraWidth = Plater.db.profile.aura_width
					local auraHeight = Plater.db.profile.aura_height
					auraIconFrame:SetSize (auraWidth, auraHeight)
					auraIconFrame.Icon:SetSize (auraWidth-2, auraHeight-2)
				end

				amtDebuffs = amtDebuffs + 1
			end
		end		
		
		self.amtDebuffs = amtDebuffs
		
		Plater.UpdateBuffContainer (self:GetParent():GetParent())
	end
	
	if (not Plater.db.profile.aura_use_default) then
		InstallHook (Plater.GetDriverGlobalObject ("NameplateBuffContainerMixin"), Plater.DriverFuncNames.OnUpdateBuffs, Plater.UpdateAuraIcons)
	end
	
	function Plater.RefreshAuras()
		for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do 
			Plater.UpdateAuraIcons (plateFrame.UnitFrame.BuffFrame, plateFrame [MEMBER_UNITID])
		end
	end
	
	function Plater.PlateShowingDebuffFrame (plateFrame)
		if (plateFrame.order == 3 and Plater.IsShowingResourcesOnTarget() and UnitIsUnit (plateFrame [MEMBER_UNITID], "target")) then --3 castbar, health, buffs
			--puxa os resources pra cima
			local SizeOf_healthBar_Height = plateFrame.UnitFrame.healthBar:GetHeight()
			NamePlateTargetResourceFrame:SetPoint ("BOTTOM", plateFrame.UnitFrame.name, "TOP", 0, -4 + SizeOf_healthBar_Height + (Plater.db.profile.aura_height))
		end
	end
	
	function Plater.PlateNotShowingDebuffFrame (plateFrame) 
		if (plateFrame.order == 3 and Plater.IsShowingResourcesOnTarget() and UnitIsUnit (plateFrame [MEMBER_UNITID], "target")) then --3 castbar, health, buffs
			--puxa os resources pra baixo
			local SizeOf_healthBar_Height = plateFrame.UnitFrame.healthBar:GetHeight()
			NamePlateTargetResourceFrame:SetPoint ("BOTTOM", plateFrame.UnitFrame.name, "TOP", 0, -4 + SizeOf_healthBar_Height)
		end
	end
	
	--> realign buff auras
	InstallHook (LayoutMixin, "Layout", function (self) 
		--> grow directions are: 2 Center 1 Left 3 Right
		if (self.isNameplate) then
			--> main buff container
			if (self.Name == "Main") then
				if (DB_AURA_GROW_DIRECTION ~= 2) then
					--> format the buffFrame size to 1, 1 so the custom grow direction can be effective
					self:SetSize (1, 1)
				end
			
			--> secondary buff container in case buffs are placed in a separated frame
			elseif (self.Name == "Secondary") then
				if (DB_AURA_GROW_DIRECTION2 ~= 2) then
					--> format the buffFrame size to 1, 1 so the custom grow direction can be effective
					self:SetSize (1, 1)
				end
			end
		end
	end)
	
	InstallHook (HorizontalLayoutMixin, "LayoutChildren", function (self, children, ignored, expandToHeight) 
		if (self.isNameplate) then
			local growDirection
			
			--> get the grow direction for the buff frame
			if (self.Name == "Main") then
				growDirection = DB_AURA_GROW_DIRECTION
			elseif (self.Name == "Secondary") then
				growDirection = DB_AURA_GROW_DIRECTION2
			end
			
			if (growDirection ~= 2) then
				local padding = 1
				local firstChild = children[1]
				local anchorPoint = firstChild and firstChild:GetParent() --> get the buffContainer
				
				if (anchorPoint) then
					--> set the point of the first child (the other children will follow the position)
					firstChild:ClearAllPoints()
					firstChild:SetPoint ("center", anchorPoint, "center", 0, 5)
				
					--> left to right
					if (growDirection == 3) then
						--> iterate among all children
						for i = 2, #children do
							local child = children [i]
							child:ClearAllPoints()
							child:SetPoint ("topleft", children [i-1], "topright", padding, 0)
						end

					--> right to left
					elseif (growDirection == 1) then
						--> iterate among all children
						for i = 2, #children do
							local child = children [i]
							child:ClearAllPoints()
							child:SetPoint ("topright", children [i-1], "topleft", -padding, 0)
						end
					end
				end
			end
		end
	end)
	
	--1 debuff, health, castbar
	--2 health, buffs, castbar
	--3 castbar, health, buffs
	
	function Plater.UpdateBuffContainer (plateFrame) 
		if ((plateFrame.UnitFrame.BuffFrame.amtDebuffs or 0) > 0) then
			--esta plate possui debuffs sendo mostrados
			Plater.PlateShowingDebuffFrame (plateFrame)
		else
			--esta plate n�o tem debuffs
			Plater.PlateNotShowingDebuffFrame (plateFrame)
		end
	end

	function Plater.UpdateResourceAnchor()
		local namePlateTarget = C_NamePlate.GetNamePlateForUnit ("target", issecure())
		if (namePlateTarget) then
		
			local classResourceBar
			local _, class = UnitClass ("player")
			
			if (class == "MONK") then
				classResourceBar = ClassNameplateBrewmasterBarFrame
				classResourceBar:ClearAllPoints()
				classResourceBar:SetPoint ("bottom", namePlateTarget.UnitFrame.healthBar, "bottom", 0, 2 + Plater.db.profile.resources.y_offset_target)
				classResourceBar:SetScale (Plater.db.profile.resources.scale)
				
				classResourceBar = ClassNameplateBarWindwalkerMonkFrame
				classResourceBar:ClearAllPoints()
				classResourceBar:SetPoint ("bottom", namePlateTarget.UnitFrame.healthBar, "bottom", 0, 2 + Plater.db.profile.resources.y_offset_target)
				classResourceBar:SetScale (Plater.db.profile.resources.scale)
				return
				
			elseif (class == "MAGE") then
				classResourceBar = ClassNameplateBarMageFrame
			elseif (class == "DEATHKNIGHT") then
				classResourceBar = DeathKnightResourceOverlayFrame
			elseif (class == "PALADIN") then
				classResourceBar = ClassNameplateBarPaladinFrame
			elseif (class == "ROGUE" or class == "DRUID") then
				classResourceBar = ClassNameplateBarRogueDruidFrame
			elseif (class == "WARLOCK") then
				classResourceBar = ClassNameplateBarWarlockFrame
			end
			
			classResourceBar:ClearAllPoints()
			classResourceBar:SetPoint ("bottom", namePlateTarget.UnitFrame.healthBar, "bottom", 0, 2 + Plater.db.profile.resources.y_offset_target)
			classResourceBar:SetScale (Plater.db.profile.resources.scale)
		end
	end
	
	InstallHook (Plater.GetDriverGlobalObject ("NamePlateDriverFrame"), Plater.DriverFuncNames.OnResourceUpdate, function (self, onTarget, resourceFrame)
	--original name: SetupClassNameplateBar
		
		if (not resourceFrame) then
			return
		end
		
		local showSelf = GetCVar ("nameplateShowSelf")
		if (showSelf == "0") then
			return
		end
		
		if (resourceFrame ~= ClassNameplateManaBarFrame and onTarget) then
			Plater.UpdateResourceAnchor()
			
			--[=[
			local namePlateTarget = C_NamePlate.GetNamePlateForUnit ("target", issecure())
			if (namePlateTarget) then
				resourceFrame:ClearAllPoints()
				resourceFrame:SetPoint ("bottom", namePlateTarget.UnitFrame.healthBar, "bottom", 0, 2 + Plater.db.profile.resources.y_offset)
				resourceFrame:SetScale (Plater.db.profile.resources.scale)
				for i = 1, resourceFrame:GetNumPoints() do
					local myPoint, frame, relativePoint, xOffset, yOffset = resourceFrame:GetPoint (i)
					if (myPoint == "BOTTOM" or myPoint == "TOP") then
						resourceFrame:SetPoint (myPoint, frame, relativePoint, xOffset, yOffset + Plater.db.profile.resources.y_offset)
					end
				end
			end
			--]=]
			
		elseif (resourceFrame == ClassNameplateManaBarFrame and not onTarget) then
		
			local classResourceBar
			local _, class = UnitClass ("player")
			
			if (class == "MONK") then
				classResourceBar = ClassNameplateBrewmasterBarFrame
			elseif (class == "MAGE") then
				classResourceBar = ClassNameplateBarMageFrame
			elseif (class == "DEATHKNIGHT") then
				classResourceBar = DeathKnightResourceOverlayFrame
			elseif (class == "PALADIN") then
				classResourceBar = ClassNameplateBarPaladinFrame
			elseif (class == "ROGUE" or class == "DRUID") then
				classResourceBar = ClassNameplateBarRogueDruidFrame
			elseif (class == "WARLOCK") then
				classResourceBar = ClassNameplateBarWarlockFrame
			end
			
			if (classResourceBar) then
				for i = 1, classResourceBar:GetNumPoints() do
					local myPoint, frame, relativePoint, xOffset, yOffset = classResourceBar:GetPoint (i)
					if (myPoint == "BOTTOM" or myPoint == "TOP") then
						classResourceBar:SetPoint (myPoint, frame, relativePoint, xOffset, yOffset + Plater.db.profile.resources.y_offset)
						classResourceBar:SetScale (Plater.db.profile.resources.scale)
					end
				end
			end
		end
	end)

	InstallHook (Plater.GetDriverSubObjectName ("CastingBarFrame", Plater.DriverFuncNames.OnCastBarShow), function (self)
		local plateFrame = C_NamePlate.GetNamePlateForUnit (self.unit or "")
		if (plateFrame) then
			if (plateFrame:GetAlpha() < 0.55) then
				plateFrame.UnitFrame.castBar.extraBackground:Show()
			else
				plateFrame.UnitFrame.castBar.extraBackground:Hide()
			end
		end
	end)
	
	function Plater.UpdateCastbarTargetText (castBar)
		local profile = Plater.db.profile
		
		if (profile.castbar_target_show) then
			local textString = castBar.FrameOverlay.TargetName
			textString:Show()
			
			DF:SetFontSize (textString, profile.castbar_target_text_size)
			DF:SetFontOutline (textString, profile.castbar_target_shadow)
			DF:SetFontColor (textString, profile.castbar_target_color)
			DF:SetFontFace (textString, profile.castbar_target_font)
			
			Plater.SetAnchor (textString, profile.castbar_target_anchor)
		else
			castBar.FrameOverlay.TargetName:Hide()
		end
	end
	
	-- ~cast
	local CastBarOnEventHook = function (self, event, ...)
	
		local unit = ...
		
		if (event == "PLAYER_ENTERING_WORLD") then
			if (not self.isNamePlate) then
				return
			end
			
			unit = self.unit
			
			local castname = UnitCastingInfo (unit)
			local channelname = UnitChannelInfo (unit)
			if (castname) then
				event = "UNIT_SPELLCAST_START"
			elseif (channelname) then
				event = "UNIT_SPELLCAST_CHANNEL_START"
			else
				return
			end
		end
		
		if (self.percentText) then
			
			local shouldRunCastStartHook = false
			
			if (event == "UNIT_SPELLCAST_START") then
				local unitCast = unit
				if (unitCast ~= self.unit or not self.isNamePlate) then
					return
				end
				
				local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo (unitCast) --nameSubtext, 
				self.SpellName = name
				self.SpellID = spellId
				self.SpellTexture = texture
				self.SpellStartTime = startTime/1000
				self.SpellEndTime = endTime/1000
				
				self.IsInterrupted = false
				
				self.Icon:SetTexture (texture)
				self.Icon:Show()
				self.Icon:SetDrawLayer ("OVERLAY", 5)
				if (notInterruptible) then
					self.BorderShield:ClearAllPoints()
					self.BorderShield:SetPoint ("center", self.Icon, "center")
					self.BorderShield:SetDrawLayer ("OVERLAY", 6)
					self.BorderShield:Show()
				else
					self.BorderShield:Hide()
				end

				if (notInterruptible) then
					self:SetStatusBarColor (unpack (Plater.db.profile.cast_statusbar_color_nointerrupt))
					self.CanInterrupt = false
				else
					self:SetStatusBarColor (unpack (Plater.db.profile.cast_statusbar_color))
					self.CanInterrupt = true
				end
				
				self.ReUpdateNextTick = true
				self.ThrottleUpdate = -1
				
				self.FrameOverlay:SetBackdropBorderColor (0, 0, 0, 0)
				
				local textLenght = self.Text:GetStringWidth()
				if (textLenght > Plater.MaxCastBarTextLength) then
					Plater.UpdateSpellNameSize (self.Text)
				end
				
				Plater.UpdateCastbarTargetText (self)
				shouldRunCastStartHook = true
				
				--self.Text:ClearAllPoints()
				--self.Text:SetPoint ("left", self.Icon, "right", 4, 0)
				
			elseif (event == "UNIT_SPELLCAST_CHANNEL_START") then
				local unitCast = unit
				if (unitCast ~= self.unit or not self.isNamePlate) then
					return
				end
				
				local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellId = UnitChannelInfo (unitCast) --nameSubtext, 
				self.SpellName = name
				self.SpellID = spellId
				self.SpellTexture = texture
				self.SpellStartTime = startTime/1000
				self.SpellEndTime = endTime/1000
				
				self.IsInterrupted = false
				
				self.Icon:SetTexture (texture)
				self.Icon:Show()
				self.Icon:SetDrawLayer ("OVERLAY", 5)
				if (notInterruptible) then
					self.BorderShield:ClearAllPoints()
					self.BorderShield:SetPoint ("center", self.Icon, "center")
					self.BorderShield:SetDrawLayer ("OVERLAY", 6)
					self.BorderShield:Show()
				else
					self.BorderShield:Hide()
				end
				
				if (notInterruptible) then
					self:SetStatusBarColor (unpack (Plater.db.profile.cast_statusbar_color_nointerrupt))
					self.CanInterrupt = false
				else
					self:SetStatusBarColor (unpack (Plater.db.profile.cast_statusbar_color))
					self.CanInterrupt = true
				end
				
				self.ReUpdateNextTick = true
				self.ThrottleUpdate = -1
				
				self.FrameOverlay:SetBackdropBorderColor (0, 0, 0, 0)
				
				local textLenght = self.Text:GetStringWidth()
				if (textLenght > Plater.MaxCastBarTextLength) then
					Plater.UpdateSpellNameSize (self.Text)
				end
				
				Plater.UpdateCastbarTargetText (self)
				shouldRunCastStartHook = true
				
				--self.Text:ClearAllPoints()
				--self.Text:SetPoint ("left", self.Icon, "right", 4, 0)
			
			elseif (event == "UNIT_SPELLCAST_INTERRUPTED") then
				local unitCast = unit
				if (unitCast ~= self.unit or not self.isNamePlate) then
					return
				end
				
				self:OnHideWidget()
				self.IsInterrupted = true

			elseif (event == "UNIT_SPELLCAST_STOP") then
				local unitCast = unit
				if (unitCast ~= self.unit or not self.isNamePlate) then
					return
				end
				
				self:OnHideWidget()
				self.IsInterrupted = true
				
			end
			
			--hooks
			if (shouldRunCastStartHook) then
				if (HOOK_CAST_START.ScriptAmount > 0) then
					for i = 1, HOOK_CAST_START.ScriptAmount do
						local globalScriptObject = HOOK_CAST_START [i]
						local unitFrame = self:GetParent()
						local scriptContainer = unitFrame:ScriptGetContainer()
						local scriptInfo = unitFrame:ScriptGetInfo (globalScriptObject, scriptContainer)
						--update envTable
						local scriptEnv = scriptInfo.Env
						scriptEnv._SpellID = self.SpellID
						scriptEnv._UnitID = self.unit
						scriptEnv._SpellName = self.SpellName
						scriptEnv._Texture = self.SpellTexture
						scriptEnv._Caster = self.unit
						scriptEnv._Duration = self.SpellEndTime - self.SpellStartTime
						scriptEnv._StartTime = self.SpellStartTime
						scriptEnv._CanInterrupt = self.CanInterrupt
						scriptEnv._EndTime = self.SpellEndTime
						scriptEnv._RemainingTime = max (self.SpellEndTime - GetTime(), 0)
						--run
						unitFrame:ScriptRunHook (scriptInfo, "Cast Start", self)
					end
				end
			end
			
		end
	end
	InstallHook (Plater.GetDriverSubObjectName ("CastingBarFrame", Plater.DriverFuncNames.OnCastBarEvent), CastBarOnEventHook)
	
	local CastBarOnTickHook = function (self, deltaTime)
		if (self.percentText) then --� uma castbar do plater?
		
			self.ThrottleUpdate = self.ThrottleUpdate - deltaTime
			
			if (self.ThrottleUpdate < 0) then
				if (self.casting) then
					self.percentText:SetText (format ("%.1f", abs (self.value - self.maxValue)))
					
				elseif (self.channeling) then
					--self.percentText:SetText (format ("%.1f", abs (self.value - self.maxValue))) --elapsed
					local remainingTime = abs (self.value) -- remaining -- thanks nnogga
					if (remainingTime > 999) then
						self.percentText:SetText ("")
					else
						self.percentText:SetText (format ("%.1f", remainingTime))
					end
				else
					self.percentText:SetText ("")
				end
				
				if (self.ReUpdateNextTick) then
					self.BorderShield:ClearAllPoints()
					self.BorderShield:SetPoint ("center", self.Icon, "center")
					self.ReUpdateNextTick = nil
				end

				--get the script object of the aura which will be showing in this icon frame
				local globalScriptObject = SCRIPT_CASTBAR [self.SpellName]
				
				if (self.unit and Plater.db.profile.castbar_target_show) then
					local targetName = UnitName (self.unit .. "target")
					if (targetName) then
						local _, class = UnitClass (self.unit .. "target")
						if (class) then 
							self.FrameOverlay.TargetName:SetText (targetName)
							self.FrameOverlay.TargetName:SetTextColor (DF:ParseColors (class))
						else
							self.FrameOverlay.TargetName:SetText (targetName)
							DF:SetFontColor (self.FrameOverlay.TargetName, Plater.db.profile.castbar_target_color)
						end
					else
						self.FrameOverlay.TargetName:SetText ("")
					end
				else
					self.FrameOverlay.TargetName:SetText ("")
				end
				
				--plateFrame.UnitFrame.castBar.FrameOverlay.TargetName
				
				self.ThrottleUpdate = DB_TICK_THROTTLE

				--check if this aura has a custom script
				if (globalScriptObject and self.SpellEndTime and GetTime() < self.SpellEndTime and (self.casting or self.channeling) and not self.IsInterrupted) then
					--stored information about scripts
					local scriptContainer = self:ScriptGetContainer()
					--get the info about this particularly script
					local scriptInfo = self:ScriptGetInfo (globalScriptObject, scriptContainer)
					
					local scriptEnv = scriptInfo.Env
					scriptEnv._SpellID = self.SpellID
					scriptEnv._UnitID = self.unit
					scriptEnv._SpellName = self.SpellName
					scriptEnv._Texture = self.SpellTexture
					scriptEnv._Caster = self.unit
					scriptEnv._Duration = self.SpellEndTime - self.SpellStartTime
					scriptEnv._StartTime = self.SpellStartTime
					scriptEnv._CanInterrupt = self.CanInterrupt
					scriptEnv._EndTime = self.SpellEndTime
					scriptEnv._RemainingTime = max (self.SpellEndTime - GetTime(), 0)
					
					if (self.casting) then
						scriptEnv._CastPercent = self.value / self.maxValue * 100
					elseif (self.channeling) then
						scriptEnv._CastPercent = abs (self.value - self.maxValue) / self.maxValue * 100
					end
				
					--run onupdate script
					self:ScriptRunOnUpdate (scriptInfo)
				end
				
				--hooks
				if (HOOK_CAST_UPDATE.ScriptAmount > 0) then
					for i = 1, HOOK_CAST_UPDATE.ScriptAmount do
						local globalScriptObject = HOOK_CAST_UPDATE [i]
						local unitFrame = self:GetParent()
						local scriptContainer = unitFrame:ScriptGetContainer()
						local scriptInfo = unitFrame:ScriptGetInfo (globalScriptObject, scriptContainer)
						
						--update envTable
						local scriptEnv = scriptInfo.Env
						scriptEnv._SpellID = self.SpellID
						scriptEnv._UnitID = self.unit
						scriptEnv._SpellName = self.SpellName
						scriptEnv._Texture = self.SpellTexture
						scriptEnv._Caster = self.unit
						scriptEnv._Duration = self.SpellEndTime - self.SpellStartTime
						scriptEnv._StartTime = self.SpellStartTime
						scriptEnv._CanInterrupt = self.CanInterrupt
						scriptEnv._EndTime = self.SpellEndTime
						scriptEnv._RemainingTime = max (self.SpellEndTime - GetTime(), 0)
						
						--run
						unitFrame:ScriptRunHook (scriptInfo, "Cast Update", self)
					end
				end
				
			end
		end
	end
	
	InstallHook (Plater.GetDriverSubObjectName ("CastingBarFrame", Plater.DriverFuncNames.OnTick), CastBarOnTickHook)
	
	function Plater.DriverOnUpdateHealth (self)

		if (not self [MEMBER_REACTION]) then
			--parece que nao esta colocando reaction em barras de jogadores
			return
		end
		
		local plateFrame = self:GetParent()
		
		if (plateFrame.isNamePlate) then
			if (plateFrame.isSelf) then
				local healthBar = self.healthBar
				local min, max = healthBar:GetMinMaxValues()
				
				--> flash if low health
				if (healthBar:GetValue() / max < 0.27) then
					if (not healthBar.PlayHealthFlash) then
						Plater.CreateHealthFlashFrame (plateFrame)
					end
					healthBar.PlayHealthFlash()
				else
					if (healthBar.PlayHealthFlash) then
						if (healthBar:GetValue() / max > 0.5) then
							healthBar.canHealthFlash = true
						end
					end
				end
				
				local unitHealth = UnitHealth (plateFrame [MEMBER_UNITID])
				local unitHealthMax = UnitHealthMax (plateFrame [MEMBER_UNITID])
				
				healthBar.CurrentHealth = unitHealth
				healthBar.CurrentHealthMax = unitHealthMax
				
				if (plateFrame.PlateConfig.healthbar_color_by_hp) then
					local originalColor = plateFrame.PlateConfig.healthbar_color
					local r, g, b = DF:LerpLinearColor (abs (unitHealth / unitHealthMax - 1), 1, originalColor[1], originalColor[2], originalColor[3], 1, .4, 0)
					Plater.ForceChangeHealthBarColor (healthBar, r, g, b, true)
				end
				
				-- is out of combat, reposition the health bar since the player health bar automatically change place when showing out of combat
				--it shows out of combat when the health had a decrease in value
				--[=[
				if (PLAYER_IN_COMBAT and not InCombatLockdown()) then
					local value = tonumber (GetCVar ("nameplateSelfBottomInset"))
					SetCVar ("nameplateSelfBottomInset", value)
					SetCVar ("nameplateSelfTopInset", abs (value - 99))
				end
				--]=]
			else
				if (DB_DO_ANIMATIONS) then
					--do healthbar animation ~animation ~healthbar ~health
					self.healthBar.CurrentHealthMax = UnitHealthMax (plateFrame [MEMBER_UNITID])
					self.healthBar.AnimationStart = self.healthBar.CurrentHealth
					self.healthBar.AnimationEnd = self.healthBar:GetValue()
					self.healthBar:SetValue (self.healthBar.CurrentHealth)
					self.healthBar.IsAnimating = true
					
					if (self.healthBar.AnimationEnd > self.healthBar.AnimationStart) then
						self.healthBar.AnimateFunc = Plater.AnimateRightWithAccel
					else
						self.healthBar.AnimateFunc = Plater.AnimateLeftWithAccel
					end
				else
					local unitHealth = UnitHealth (plateFrame [MEMBER_UNITID])
					local unitHealthMax = UnitHealthMax (plateFrame [MEMBER_UNITID])
					self.healthBar:SetValue (unitHealth)
					
					self.healthBar.CurrentHealth = unitHealth
					self.healthBar.CurrentHealthMax = unitHealthMax
				end
				
				if (plateFrame.actorType == ACTORTYPE_FRIENDLY_PLAYER) then
					Plater.ParseHealthSettingForPlayer (plateFrame)
					Plater.UpdatePlateText (plateFrame, DB_PLATE_CONFIG [ACTORTYPE_FRIENDLY_PLAYER], false)
				end
				
			end
		end
	end
	
	InstallHook (Plater.GetDriverSubObjectName ("CompactUnitFrame", Plater.DriverFuncNames.OnUpdateHealth), Plater.DriverOnUpdateHealth)

	local powerPercent = ClassNameplateManaBarFrame:CreateFontString (nil, "overlay", "GameFontNormal")
	ClassNameplateManaBarFrame.powerPercent = powerPercent
	powerPercent:SetPoint ("center")
	powerPercent:SetText ("100%")

	ClassNameplateManaBarFrame:HookScript ("OnValueChanged", function (self)
		ClassNameplateManaBarFrame.powerPercent:SetText (floor (self:GetValue()/select (2, self:GetMinMaxValues()) * 100) .. "%")
	end)

--	removed since default ui triggers this when any nameplate is added, we registered our own raid marker event for performance
--	this can be removed in a future code cleanup
--	InstallHook (Plater.GetDriverGlobalObject ("NamePlateDriverFrame"), Plater.DriverFuncNames.OnRaidTargetUpdate, function (self)
--		Plater.UpdateRaidMarkersOnAllNameplates()
--	end)
	
	InstallHook (Plater.GetDriverGlobalObject ("NamePlateDriverFrame"), Plater.DriverFuncNames.OnOptionsUpdate, function()
		Plater.UpdateSelfPlate()
	end)
	
	InstallHook (Plater.GetDriverGlobalObject ("ClassNameplateManaBarFrame"), Plater.DriverFuncNames.OnManaBarOptionsUpdate, function()
		ClassNameplateManaBarFrame:SetSize (unpack (DB_PLATE_CONFIG.player.mana))
	end)
	
--]=]
	--> ~db
	Plater.db.RegisterCallback (Plater, "OnProfileChanged", "RefreshConfig")
	Plater.db.RegisterCallback (Plater, "OnProfileCopied", "RefreshConfig")
	Plater.db.RegisterCallback (Plater, "OnProfileReset", "RefreshConfig")
	Plater.db.RegisterCallback (Plater, "OnDatabaseShutdown", "SaveConsoleVariables")
	
	function Plater.OnProfileCreated()
		C_Timer.After (1, function()
			Plater:Msg ("new profile created, applying patches and adding default scripts.")
			Plater.ImportScriptsFromLibrary()
			Plater.ApplyPatches()
			Plater.CompileAllScripts ("script")
			Plater.CompileAllScripts ("hook")
		end)
	end
	
	Plater.db.RegisterCallback (Plater, "OnNewProfile", "OnProfileCreated")

	--saved_cvars
	Plater.UpdateSelfPlate()
	Plater.UpdateUseClassColors()
	
	C_Timer.After (4.1, Plater.QuestLogUpdated)
	--C_Timer.After (4.5, function() Plater.RefreshOmniCCGroup (true) end)
	C_Timer.After (5.1, function() Plater.IncreaseRefreshID(); Plater.UpdateAllPlates() end)
	
	for i = 1, 3 do
		C_Timer.After (i, Plater.RefreshDBUpvalues)
	end
	
end

function Plater.UpdateMaxCastbarTextLength()
	local barWidth = Plater.db.profile.plate_config.enemynpc.cast_incombat
	Plater.MaxCastBarTextLength = Plater.db.profile.plate_config.enemynpc.cast_incombat[1] - 40
end
--> set a default value here to be safe
Plater.MaxCastBarTextLength = 200

function Plater.UpdateAllNames()
	for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
		if (plateFrame.actorType == ACTORTYPE_PLAYER) then
			plateFrame.NameAnchor = 0
			
		elseif (plateFrame.actorType == UNITREACTION_FRIENDLY) then
			plateFrame.NameAnchor = DB_NAME_PLAYERFRIENDLY_ANCHOR
			
		elseif (plateFrame.actorType == ACTORTYPE_ENEMY_PLAYER) then
			plateFrame.NameAnchor = DB_NAME_PLAYERENEMY_ANCHOR
			
		elseif (plateFrame.actorType == ACTORTYPE_FRIENDLY_NPC) then
			plateFrame.NameAnchor = DB_NAME_NPCFRIENDLY_ANCHOR
			
		elseif (plateFrame.actorType == ACTORTYPE_ENEMY_NPC) then
			plateFrame.NameAnchor = DB_NAME_NPCENEMY_ANCHOR
			
		end
	
		Plater.UpdateUnitName (plateFrame)
	end
end

function Plater.UpdateSpellNameSize (nameString)
	local spellName = nameString:GetText()
	
	while (nameString:GetStringWidth() > Plater.MaxCastBarTextLength) do
		spellName = strsub (spellName, 1, #spellName - 1)
		nameString:SetText (spellName)
		if (string.len (spellName) <= 1) then
			break
		end
	end	
end

function Plater.UpdateTextSize (plateFrame, nameString)
	local stringSize = max (plateFrame.UnitFrame.healthBar:GetWidth() - 6, 44)
	local name = plateFrame [MEMBER_NAME]
	
	nameString:SetText (name)
	
	while (nameString:GetStringWidth() > stringSize) do
		name = strsub (name, 1, #name-1)
		nameString:SetText (name)
		if (string.len (name) <= 1) then
			break
		end
	end
end

function Plater.AddGuildNameToPlayerName (plateFrame)
	local currentText = plateFrame.CurrentUnitNameString:GetText()
	if (not currentText:find ("<")) then
		plateFrame.CurrentUnitNameString:SetText (currentText .. "\n" .. "<" .. plateFrame.playerGuildName .. ">")
	end
end

function Plater.UpdateUnitName (plateFrame, nameFontString)

	local nameString = plateFrame.CurrentUnitNameString

	if (plateFrame.NameAnchor >= 9) then
		--remove some character from the unit name if the name is placed inside the nameplate
		local stringSize = max (plateFrame.UnitFrame.healthBar:GetWidth() - 6, 44)
		local name = plateFrame [MEMBER_NAME]
		
		nameString:SetText (name)
		local stringWidth = nameString:GetStringWidth()
		
		if (stringWidth > stringSize and nameString == plateFrame.actorName) then 
			plateFrame:TickUpdate (true)
		else
			Plater.UpdateTextSize (plateFrame, nameString)
		end
	else
		nameString:SetText (plateFrame [MEMBER_NAME])
	end
	
	--check if the player has a guild, this check is done when the nameplate is added
	if (plateFrame.playerGuildName) then
		if (plateFrame.PlateConfig.show_guild_name) then
			Plater.AddGuildNameToPlayerName (plateFrame)
		end
	end
	
end

local tick_update = function (self)
	if (self.UpdateActorNameSize) then
		Plater.UpdateTextSize (self:GetParent(), self:GetParent().actorName)
	end
	
	self.UpdateActorNameSize = nil
	self:SetScript ("OnUpdate", nil)
end

function Plater.TickUpdate (plateFrame, UpdateActorNameSize)
	plateFrame.OnNextTickUpdate.UpdateActorNameSize = UpdateActorNameSize
	plateFrame.OnNextTickUpdate:SetScript ("OnUpdate", tick_update)
end



local re_update_self_plate = function()
	Plater.UpdateSelfPlate()
end

function Plater.UpdateSelfPlate()
	if (InCombatLockdown()) then
		return C_Timer.After (.3, re_update_self_plate)
	end
	C_NamePlate.SetNamePlateSelfClickThrough (DB_PLATE_CONFIG.player.click_through)
	
	--disabled due to modifying the player personal nameplate makes it be a little offset in the Y anchor making it to be in front of the player
--	C_NamePlate.SetNamePlateSelfSize (unpack (DB_PLATE_CONFIG.player.health))
	ClassNameplateManaBarFrame:SetSize (unpack (DB_PLATE_CONFIG.player.mana))
end

-- se o jogador estiver em combate, colorir a barra de acordo com o aggro do jogador ~aggro �ggro
local set_aggro_color = function (self, r, g, b) --self.actorName
	if (DB_AGGRO_CHANGE_HEALTHBAR_COLOR) then
		Plater.ForceChangeHealthBarColor (self, r, g, b)
	end
	if (DB_AGGRO_CHANGE_BORDER_COLOR) then
		Plater.ForceChangeBorderColor (self, r, g, b)
	end
	if (DB_AGGRO_CHANGE_NAME_COLOR) then
		self.actorName:SetTextColor (r, g, b)
	end
end

function Plater.UpdateNameplateThread (self) --self = UnitFrame

	--make sure there's a unitID in the unit frame
	if (not self.displayedUnit) then
		return
	end
	
	local isTanking, threatStatus, threatpct = UnitDetailedThreatSituation ("player", self.displayedUnit)
	self.namePlateThreatPercent = threatpct or 0
	-- (3 = securely tanking, 2 = insecurely tanking, 1 = not tanking but higher threat than tank, 0 = not tanking and lower threat than tank)

	self.aggroGlowUpper:Hide()
	self.aggroGlowLower:Hide()
	
	if (Plater.PlayerIsTank) then
		--se o jogador � TANK

		if (not isTanking) then
		
			if (UnitAffectingCombat (self.displayedUnit)) then
			
				if (IsInRaid()) then
					--check is the mob is tanked by another tank in the raid
					local unitTarget = UnitName (self.displayedUnit .. "target")
					if (TANK_CACHE [unitTarget]) then
						--n�o h� aggro neste mob mas ele esta participando do combate
						Plater.ForceChangeHealthBarColor (self.healthBar, unpack (DB_AGGRO_TANK_COLORS.anothertank))
					else
						--n�o h� aggro neste mob mas ele esta participando do combate
						Plater.ForceChangeHealthBarColor (self.healthBar, unpack (DB_AGGRO_TANK_COLORS.noaggro))
					end
					
					if (self.PlateFrame [MEMBER_NOCOMBAT]) then
						self.PlateFrame [MEMBER_NOCOMBAT] = nil
						Plater.CheckRange (self.PlateFrame, true)
					end
				else
					--n�o h� aggro neste mob mas ele esta participando do combate
					Plater.ForceChangeHealthBarColor (self.healthBar, unpack (DB_AGGRO_TANK_COLORS.noaggro))
					
					if (self.PlateFrame [MEMBER_NOCOMBAT]) then
						self.PlateFrame [MEMBER_NOCOMBAT] = nil
						Plater.CheckRange (self.PlateFrame, true)
					end
				end
			else
				--if isn't a quest mob
				if (not self.PlateFrame [MEMBER_QUEST]) then
					--n�o ha aggro e ele n�o esta participando do combate
					if (self [MEMBER_REACTION] == 4) then
						--o mob � um npc neutro, apenas colorir com a cor neutra
						set_aggro_color (self.healthBar, 1, 1, 0) --ticket #185
					else
						set_aggro_color (self.healthBar, unpack (DB_AGGRO_TANK_COLORS.nocombat))
					end
					
					if (DB_NOT_COMBAT_ALPHA_ENABLED) then
						self.PlateFrame [MEMBER_NOCOMBAT] = true
						self:SetAlpha (Plater.db.profile.not_affecting_combat_alpha)
					end
				end
			end
		else
			--o jogador esta tankando e:
			if (threatStatus == 3) then --esta tankando com seguran�a
				set_aggro_color (self.healthBar, unpack (DB_AGGRO_TANK_COLORS.aggro))
				
			elseif (threatStatus == 2) then --esta tankando sem seguran�a
				set_aggro_color (self.healthBar, unpack (DB_AGGRO_TANK_COLORS.pulling))
				self.aggroGlowUpper:Show()
				self.aggroGlowLower:Show()
				
			else --n�o esta tankando
				set_aggro_color (self.healthBar, unpack (DB_AGGRO_TANK_COLORS.noaggro))

			end
			if (self.PlateFrame [MEMBER_NOCOMBAT]) then
				self.PlateFrame [MEMBER_NOCOMBAT] = nil
				Plater.CheckRange (self.PlateFrame, true)

			end
		end
	else

		--dps
		if (isTanking) then
			--o jogador esta tankando como dps
			set_aggro_color (self.healthBar, unpack (DB_AGGRO_DPS_COLORS.aggro))
			if (not self.PlateFrame.playerHasAggro) then
				self.PlateFrame.PlayBodyFlash ("-AGGRO-")
				
			end
			self.PlateFrame.playerHasAggro = true
			
			if (self.PlateFrame [MEMBER_NOCOMBAT]) then
				self.PlateFrame [MEMBER_NOCOMBAT] = nil
				Plater.CheckRange (self.PlateFrame, true)
			end
		else 	
			if (threatStatus == nil) then
				self.PlateFrame.playerHasAggro = false
				
				if (UnitAffectingCombat (self.displayedUnit)) then
					set_aggro_color (self.healthBar, unpack (DB_AGGRO_DPS_COLORS.noaggro))
					self.PlateFrame.playerHasAggro = false
					
					if (self.PlateFrame [MEMBER_NOCOMBAT]) then
						self.PlateFrame [MEMBER_NOCOMBAT] = nil
						Plater.CheckRange (self.PlateFrame, true)
					end
				else
					--if isn't a quest mob
					if (not self.PlateFrame [MEMBER_QUEST]) then
						--n�o ha aggro e ele n�o esta participando do combate
						if (self [MEMBER_REACTION] == 4) then --ticket #185
							--o mob � um npc neutro, apenas colorir com a cor neutra
							set_aggro_color (self.healthBar, 1, 1, 0)
						else
							set_aggro_color (self.healthBar, unpack (DB_AGGRO_TANK_COLORS.nocombat))
						end
						
						if (Plater.db.profile.not_affecting_combat_enabled) then --not self.PlateFrame [MEMBER_NOCOMBAT] and 
							self.PlateFrame [MEMBER_NOCOMBAT] = true
							self:SetAlpha (Plater.db.profile.not_affecting_combat_alpha)
						end
					end
					
				end
			else
				if (threatStatus == 3) then --o jogador esta tankando como dps
					set_aggro_color (self.healthBar, unpack (DB_AGGRO_DPS_COLORS.aggro))
					if (not self.PlateFrame.playerHasAggro) then
						self.PlateFrame.PlayBodyFlash ("-AGGRO-")
					end
					self.PlateFrame.playerHasAggro = true
					
				elseif (threatStatus == 2) then --esta tankando com pouco aggro
					set_aggro_color (self.healthBar, unpack (DB_AGGRO_DPS_COLORS.aggro))
					
					self.PlateFrame.playerHasAggro = true
				elseif (threatStatus == 1) then --esta quase puxando o aggro
					set_aggro_color (self.healthBar, unpack (DB_AGGRO_DPS_COLORS.pulling))
					
					self.PlateFrame.playerHasAggro = false
					self.aggroGlowUpper:Show()
					self.aggroGlowLower:Show()
				elseif (threatStatus == 0) then --n�o esta tankando
					set_aggro_color (self.healthBar, unpack (DB_AGGRO_DPS_COLORS.noaggro))
					self.PlateFrame.playerHasAggro = false
					
				end
				
				if (self.PlateFrame [MEMBER_NOCOMBAT]) then
					self.PlateFrame [MEMBER_NOCOMBAT] = nil
					Plater.CheckRange (self.PlateFrame, true)
				end
			end
		end
	end
end

Plater.OnAuraIconHide = function (self)
	local globalScriptObject = SCRIPT_AURA [self.SpellName]
	--does the aura has a custom script?
	if (globalScriptObject) then
		--does the aura icon has a table with script information?
		local scriptContainer = self:ScriptGetContainer()
		if (scriptContainer) then
			local scriptInfo = self:ScriptGetInfo (globalScriptObject, scriptContainer)
			if (scriptInfo and scriptInfo.IsActive) then
				self:ScriptRunOnHide (scriptInfo)
			end
		end
	end
end

--an aura is about to be added in the nameplate, need to get an icon for it ~geticonaura
function Plater.GetAuraIcon (self, isBuff)
	--self parent = NamePlate_X_UnitFrame
	--self = BuffFrame
	
	if (isBuff and DB_AURA_SEPARATE_BUFFS) then
		self = self.BuffsAnchor
	end
	
	local i = self.NextAuraIcon
	
	if (not self.PlaterBuffList[i]) then
		local newFrameIcon = CreateFrame ("Frame", self:GetParent():GetName() .. "Plater" .. self.Name .. "AuraIcon" .. i, self, "NameplateBuffButtonTemplate")
		newFrameIcon:Hide()
		newFrameIcon.UnitFrame = self:GetParent()
		newFrameIcon.spellId = 0
		newFrameIcon.ID = i
		newFrameIcon.RefreshID = 0
		newFrameIcon.IsPersonal = -1 --place holder
		
		self.PlaterBuffList[i] = newFrameIcon
		
		newFrameIcon:SetMouseClickEnabled (false)
		newFrameIcon:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
		
		local timer = newFrameIcon.Cooldown:CreateFontString (nil, "overlay", "NumberFontNormal")
		newFrameIcon.Cooldown.Timer = timer
		timer:SetPoint ("center")
		
		local auraWidth = Plater.db.profile.aura_width
		local auraHeight = Plater.db.profile.aura_height
		newFrameIcon:SetSize (auraWidth, auraHeight)
		newFrameIcon.Icon:SetSize (auraWidth-2, auraHeight-2)
		
		--mixin the meta functions for scripts
		DF:Mixin (newFrameIcon, Plater.ScriptMetaFunctions)
		newFrameIcon.IsAuraIcon = true
		newFrameIcon:HookScript ("OnHide", newFrameIcon.OnHideWidget)
		
		local iconShowInAnimation = DF:CreateAnimationHub (newFrameIcon)
		DF:CreateAnimation (iconShowInAnimation, "Scale", 1, .05, .7, .7, 1.1, 1.1)
		DF:CreateAnimation (iconShowInAnimation, "Scale", 2, .05, 1.1, 1.1, 1, 1)
		newFrameIcon.ShowAnimation = iconShowInAnimation
		
		--masque support
		if (Plater.Masque) then
			if (self.Name == "Main") then
				local t = {
					FloatingBG = false,
					Icon = newFrameIcon.Icon,
					Cooldown = newFrameIcon.Cooldown,
					Flash = false,
					Pushed = false,
					Normal = false,
					Disabled = false,
					Checked = false,
					Border = newFrameIcon.Border,
					AutoCastable = false,
					Highlight = false,
					HotKey = false,
					Count = false,
					Name = false,
					Duration = false,
					Shine = false,
				}
				Plater.Masque.AuraFrame1:AddButton (newFrameIcon, t)
				Plater.Masque.AuraFrame1:ReSkin()
				
			elseif (self.Name == "Secondary") then
				local t = {
					FloatingBG = false,
					Icon = newFrameIcon.Icon,
					Cooldown = newFrameIcon.Cooldown,
					Flash = false,
					Pushed = false,
					Normal = false,
					Disabled = false,
					Checked = false,
					Border = newFrameIcon.Border,
					AutoCastable = false,
					Highlight = false,
					HotKey = false,
					Count = false,
					Name = false,
					Duration = false,
					Shine = false,
				}
				Plater.Masque.AuraFrame2:AddButton (newFrameIcon, t)
				Plater.Masque.AuraFrame2:ReSkin()
				
			end
		end
	end
	
	local auraIconFrame = self.PlaterBuffList [i]
	self.NextAuraIcon = self.NextAuraIcon + 1
	return auraIconFrame
end

function Plater.FormatTime (time)
	if (time >= 3600) then
		return floor (time / 3600) .. "h"
	elseif (time >= 60) then
		return floor (time / 60) .. "m"
	else
		return floor (time)
	end
end

--> show the tooltip in the aura icon
hooksecurefunc (NameplateBuffButtonTemplateMixin, "OnEnter", function (iconFrame)
	NamePlateTooltip:SetOwner (iconFrame, "ANCHOR_LEFT")
	NamePlateTooltip:SetUnitAura (iconFrame:GetParent().unit, iconFrame:GetID(), iconFrame.filter)

	iconFrame.UpdateTooltip = NameplateBuffButtonTemplateMixin.OnEnter
end)

--update the aura icon, this icon is getted with GetAuraIcon
function Plater.AddAura (auraIconFrame, i, spellName, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId, isBuff, isShowAll, isDebuff, isPersonal)
	auraIconFrame:SetID (i)

	--> check if the icon is showing a different aura
	if (auraIconFrame.spellId ~= spellId) then
		if (not isBuff and not auraIconFrame:IsShown() or auraIconFrame.IsShowingBuff) then
			auraIconFrame.ShowAnimation:Play()
		end

		--> update the texture
		auraIconFrame.Icon:SetTexture (texture)
		
		--> update members
		auraIconFrame.spellId = spellId
		auraIconFrame.layoutIndex = auraIconFrame.ID
		auraIconFrame.IsShowingBuff = false

		if (debuffType == "DEBUFF") then
			auraIconFrame.filter = "HARMFUL"
			auraIconFrame:GetParent().HasDebuff = true
			
		elseif (debuffType == "BUFF") then
			auraIconFrame.filter = "HELPFUL"
			auraIconFrame:GetParent().HasBuff = true
			
		else
			auraIconFrame.filter = ""
		end
	end
	
	--> caching the profile for performance
	local profile = Plater.db.profile
	
	--> check if a full refresh is required
	if (auraIconFrame.RefreshID < PLATER_REFRESH_ID) then
		--if tooltip enabled
		auraIconFrame:EnableMouse (profile.aura_show_tooltip)
		
		--stack counter
		local stackLabel = auraIconFrame.CountFrame.Count
		DF:SetFontSize (stackLabel, profile.aura_stack_size)
		DF:SetFontOutline (stackLabel, profile.aura_stack_shadow)
		DF:SetFontColor (stackLabel, profile.aura_stack_color)
		DF:SetFontFace (stackLabel, profile.aura_stack_font)
		Plater.SetAnchor (stackLabel, profile.aura_stack_anchor)
		
		--timer
		local timerLabel = auraIconFrame.Cooldown.Timer
		DF:SetFontSize (timerLabel, profile.aura_timer_text_size)
		DF:SetFontOutline (timerLabel, profile.aura_timer_text_shadow)
		DF:SetFontFace (timerLabel, profile.aura_timer_text_font)
		DF:SetFontColor (timerLabel, profile.aura_timer_text_color)
		Plater.SetAnchor (timerLabel, profile.aura_timer_text_anchor)
		
		auraIconFrame.RefreshID = PLATER_REFRESH_ID
	end

	--> update the icon size depending on where it is shown
	if (auraIconFrame.IsPersonal ~= isPersonal) then
		if (isPersonal) then
			local auraWidth = profile.aura_width_personal
			local auraHeight = profile.aura_height_personal
			auraIconFrame:SetSize (auraWidth, auraHeight)
			auraIconFrame.Icon:SetSize (auraWidth-2, auraHeight-2)
		else
			local auraWidth = profile.aura_width
			local auraHeight = profile.aura_height
			auraIconFrame:SetSize (auraWidth, auraHeight)
			auraIconFrame.Icon:SetSize (auraWidth-2, auraHeight-2)
		end
	end
	auraIconFrame.IsPersonal = isPersonal

	if (count > 1) then
		local stackLabel = auraIconFrame.CountFrame.Count
		stackLabel:SetText (count)
		stackLabel:Show()
	else
		auraIconFrame.CountFrame.Count:Hide()
	end
	
	--border colors
	if (canStealOrPurge) then
		auraIconFrame:SetBackdropBorderColor (unpack (profile.aura_border_colors.steal_or_purge))
	
	elseif (isBuff) then
		auraIconFrame:SetBackdropBorderColor (unpack (profile.aura_border_colors.is_buff))
		auraIconFrame.IsShowingBuff = true
	
	elseif (isShowAll) then
		auraIconFrame:SetBackdropBorderColor (unpack (profile.aura_border_colors.is_show_all))
		
	elseif (isDebuff) then
		--> for debuffs on the player for the personal bar
		auraIconFrame:SetBackdropBorderColor (1, 0, 0, 1)
	
	else	
		auraIconFrame:SetBackdropBorderColor (0, 0, 0, 0)
	end
	
	CooldownFrame_Set (auraIconFrame.Cooldown, expirationTime - duration, duration, duration > 0, true)
	local timeLeft = expirationTime-GetTime()
	
	if (profile.aura_timer and timeLeft > 0) then
		--> update the aura timer
		local timerLabel = auraIconFrame.Cooldown.Timer
	
		timerLabel:SetText (Plater.FormatTime (timeLeft))
		timerLabel:Show()
	else
		auraIconFrame.Cooldown.Timer:Hide()
	end
	
	--check if the aura icon frame is already shown
	if (auraIconFrame:IsShown()) then
		--is was showing a different aura, simulate a OnHide()
		if (auraIconFrame.SpellName ~= spellName) then
			auraIconFrame:OnHideWidget()
		end
	end
	
	--> spell name must be update here and cannot be cached due to scripts
	auraIconFrame.SpellName = spellName
	auraIconFrame.InUse = true
	auraIconFrame:Show()
	
	--get the script object of the aura which will be showing in this icon frame
	local globalScriptObject = SCRIPT_AURA [spellName]
	
	--check if this aura has a custom script
	if (globalScriptObject) then
		--stored information about scripts
		local scriptContainer = auraIconFrame:ScriptGetContainer()
		
		--get the info about this particularly script
		local scriptInfo = auraIconFrame:ScriptGetInfo (globalScriptObject, scriptContainer)
		
		--set the aura information on the script env
		local scriptEnv = scriptInfo.Env
		scriptEnv._SpellID = spellId
		scriptEnv._UnitID = caster
		scriptEnv._SpellName = spellName
		scriptEnv._Texture = texture
		scriptEnv._Caster = caster
		scriptEnv._StackCount = count
		scriptEnv._Duration = duration
		scriptEnv._StartTime = expirationTime - duration
		scriptEnv._EndTime = expirationTime
		scriptEnv._RemainingTime = max (expirationTime - GetTime(), 0)
		
		--run onupdate script
		auraIconFrame:ScriptRunOnUpdate (scriptInfo)
	end	
	
	--Plater.Masque.AuraFrame1:ReSkin()
	
	
	--auraIconFrame.Icon:Hide()
	--auraIconFrame.Cooldown:SetBackdrop (nil)
	--print (auraIconFrame.Border:GetObjectType())
	--print (auraIconFrame.Icon:GetAlpha())

	return true
end

local hide_non_used_auraFrames = function (self)
	--> regular buff frame
	local nextAuraIndex = self.NextAuraIcon
	for i = nextAuraIndex, #self.PlaterBuffList do
		local icon = self.PlaterBuffList [i]
		if (icon) then
			icon:Hide()
			icon.InUse = false
		end
	end
	
	--> if using a second buff frame to separate buffs, update it
	if (DB_AURA_SEPARATE_BUFFS) then
		--> secondary buff frame
		self = self.BuffsAnchor
		local nextAuraIndex = self.NextAuraIcon
		
		for i = nextAuraIndex, #self.PlaterBuffList do
			local icon = self.PlaterBuffList [i]
			if (icon) then
				icon:Hide()
				icon.InUse = false
			end
		end

		--> weird adding the Layout() call inside the hide function, but saves on performance
		--> update icon anchors
		self:Layout()
	end
end
Plater.HideNonUsedAuraFrames = hide_non_used_auraFrames

function Plater.AddExtraIcon (self, spellName, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId)
	local _, casterClass = UnitClass (caster or "")
	local casterName
	if (casterClass and UnitPlayerControlled (caster)) then
		--adding only the name for players in case the player used a stun
		casterName = UnitName (caster)
	end
	
	local borderColor
	
	if (canStealOrPurge) then
		borderColor = Plater.db.profile.extra_icon_show_purge_border
		
	elseif (CROWDCONTROL_AURA_NAMES [spellName]) then
		borderColor = Plater.db.profile.debuff_show_cc_border
	
	else
		borderColor = Plater.db.profile.extra_icon_border_color
	end
	
	--spellId, borderColor, startTime, duration, forceTexture, descText
	local iconFrame = self.ExtraIconFrame:SetIcon (spellId, borderColor, expirationTime - duration, duration, false, casterName and {text = casterName, text_color = casterClass} or false)
	if (Plater.Masque and not iconFrame.Masqued) then
		local t = {
			FloatingBG = false,
			Icon = iconFrame.Texture,
			Cooldown = iconFrame.Cooldown,
			Flash = false,
			Pushed = false,
			Normal = false,
			Disabled = false,
			Checked = false,
			Border = iconFrame.Border,
			AutoCastable = false,
			Highlight = false,
			HotKey = false,
			Count = false,
			Name = false,
			Duration = false,
			Shine = false,
		}
		Plater.Masque.BuffSpecial:AddButton (iconFrame, t)
		Plater.Masque.BuffSpecial:ReSkin()
		iconFrame.Masqued = true
	end
end

-- ~auras �ura
function Plater.TrackSpecificAuras (self, unit, isBuff, aurasToCheck, isPersonal, noSpecial)

	if (isBuff) then
		--> buffs
		for i = 1, BUFF_MAX_DISPLAY do
			local name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId = UnitBuff (unit, i)
			if (not name) then
				break
			else
				debuffType = "BUFF"
				if (aurasToCheck [name]) then
					local auraIconFrame = Plater.GetAuraIcon (self, true)
					Plater.AddAura (auraIconFrame, i, name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId, true, false, false, isPersonal)
				end
				
				--> check if is a special aura
				if (not SPECIAL_AURA_NAMES_MINE [name] or (caster and (UnitIsUnit (caster, "player") or UnitIsUnit (caster, "pet")))) then
					if (not noSpecial and (SPECIAL_AURA_NAMES [name] or DB_SHOW_PURGE_IN_EXTRA_ICONS and canStealOrPurge)) then
						Plater.AddExtraIcon (self, name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId)
					end
				end
			end
		end
	else
		--> debuffs
		for i = 1, BUFF_MAX_DISPLAY do
			--using the PLAYER filter it'll avoid special auras to be scan
			--local name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId = UnitDebuff (unit, i, "HARMFUL|PLAYER")
			local name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId = UnitDebuff (unit, i)
			if (not name) then
				break
			else
				debuffType = "DEBUFF"
				--checking here if the debuff is placed by the player
				--if (caster and aurasToCheck [name] and UnitIsUnit (caster, "player")) then --this doesn't track the pet, so auras like freeze from mage frost elemental won't show
				if (caster and aurasToCheck [name] and (UnitIsUnit (caster, "player") or UnitIsUnit (caster, "pet"))) then
				--if (aurasToCheck [name]) then
					local auraIconFrame = Plater.GetAuraIcon (self)
					Plater.AddAura (auraIconFrame, i, name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId, false, false, false, isPersonal)
				end
				
				--> check if is a special aura
				if (not SPECIAL_AURA_NAMES_MINE [name] or (caster and (UnitIsUnit (caster, "player") or UnitIsUnit (caster, "pet")))) then
					if (not noSpecial and (SPECIAL_AURA_NAMES [name] or DB_SHOW_PURGE_IN_EXTRA_ICONS and canStealOrPurge)) then
						Plater.AddExtraIcon (self, name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId)
					end
				end
			end
		end
	end
	
	return true
end

function Plater.UpdateAuras_Manual (self, unit, isPersonal)

	self.ExtraIconFrame:ClearIcons()

	--> reset next aura icon to use
	self.NextAuraIcon = 1
	self.BuffsAnchor.NextAuraIcon = 1
	self.HasBuff = false
	self.HasDebuff = false
	self.BuffsAnchor.HasBuff = false --secondary buff anchor
	self.BuffsAnchor.HasDebuff = false --secondary buff anchor
	
	Plater.TrackSpecificAuras (self, unit, false, MANUAL_TRACKING_DEBUFFS, isPersonal)
	Plater.TrackSpecificAuras (self, unit, true, MANUAL_TRACKING_BUFFS, isPersonal)

	--> hide not used aura frames
	hide_non_used_auraFrames (self)
end

function Plater.UpdateAuras_Automatic (self, unit)

	--> reset next aura icon to use
	self.NextAuraIcon = 1
	self.BuffsAnchor.NextAuraIcon = 1
	self.HasBuff = false
	self.HasDebuff = false
	self.BuffsAnchor.HasBuff = false --secondary buff anchor
	self.BuffsAnchor.HasDebuff = false --secondary buff anchor
	
	self.ExtraIconFrame:ClearIcons()
	
	--> debuffs
		for i = 1, BUFF_MAX_DISPLAY do
		
			local spellName, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll = UnitDebuff (unit, i)
			--start as false, during the checks can be changed to true, if is true this debuff is added on the nameplate
			local can_show_this_debuff
			debuffType = "DEBUFF"
			
			if (not spellName) then
				break
			
			--check if the debuff isn't filtered out
			elseif (not DB_DEBUFF_BANNED [spellName]) then
		
				--> important aura' 
				if (DB_AURA_SHOW_IMPORTANT and (nameplateShowAll or isBossDebuff)) then
					can_show_this_debuff = true
				
				--> is casted by the player
				elseif (DB_AURA_SHOW_BYPLAYER and caster and UnitIsUnit (caster, "player")) then
					can_show_this_debuff = true
				end
				
				if (not SPECIAL_AURA_NAMES_MINE [spellName] or (caster and (UnitIsUnit (caster, "player") or UnitIsUnit (caster, "pet")))) then
					if (SPECIAL_AURA_NAMES [spellName] or DB_SHOW_PURGE_IN_EXTRA_ICONS and canStealOrPurge) then
						Plater.AddExtraIcon (self, spellName, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId)
					end
				end
			end
			
			if (can_show_this_debuff) then
				--get the icon to be used by this aura
				local auraIconFrame = Plater.GetAuraIcon (self)
				Plater.AddAura (auraIconFrame, i, spellName, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId)
			end
			
		end
	
	--> buffs
		for i = 1, BUFF_MAX_DISPLAY do
			local name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll = UnitBuff (unit, i)
			debuffType = "BUFF"
			
			if (not name) then
				break
			
			elseif (not DB_BUFF_BANNED [name]) then

				--> important aura
				if (DB_AURA_SHOW_IMPORTANT and (nameplateShowAll or isBossDebuff)) then
					local auraIconFrame = Plater.GetAuraIcon (self, true)
					Plater.AddAura (auraIconFrame, i, name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId, false, true)
				
				--> is dispellable or can be steal
				elseif (DB_AURA_SHOW_DISPELLABLE and canStealOrPurge) then
					local auraIconFrame = Plater.GetAuraIcon (self, true)
					Plater.AddAura (auraIconFrame, i, name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId)
				
				--> is casted by the player
				elseif (DB_AURA_SHOW_BYPLAYER and caster and UnitIsUnit (caster, "player")) then
					local auraIconFrame = Plater.GetAuraIcon (self, true)
					Plater.AddAura (auraIconFrame, i, name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId)
				
				--> is casted by the unit it self
				elseif (DB_AURA_SHOW_BYUNIT and caster and UnitIsUnit (caster, unit) and not isCastByPlayer) then
					local auraIconFrame = Plater.GetAuraIcon (self, true)
					Plater.AddAura (auraIconFrame, i, name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId, true)
				
				end
				
				--> is a special aura?
				if (not SPECIAL_AURA_NAMES_MINE [name] or (caster and (UnitIsUnit (caster, "player") or UnitIsUnit (caster, "pet")))) then
					if (SPECIAL_AURA_NAMES [name] or DB_SHOW_PURGE_IN_EXTRA_ICONS and canStealOrPurge) then
						Plater.AddExtraIcon (self, name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId)
					end
				end
			end
		end

	--track extra auras
		if (CAN_TRACK_EXTRA_BUFFS) then
			Plater.TrackSpecificAuras (self, unit, true, AUTO_TRACKING_EXTRA_BUFFS, false, true)
		end
		
		if (CAN_TRACK_EXTRA_DEBUFFS) then
			Plater.TrackSpecificAuras (self, unit, false, AUTO_TRACKING_EXTRA_DEBUFFS, false, true)
		end
	
	--hide non used icons
		hide_non_used_auraFrames (self)
end

function Plater.UpdateAuras_Self_Automatic (self)

	--> reset next aura icon to use
	self.NextAuraIcon = 1
	self.BuffsAnchor.NextAuraIcon = 1
	
	self.ExtraIconFrame:ClearIcons()
	
	--> debuffs
	if (Plater.db.profile.aura_show_debuffs_personal) then
		for i = 1, BUFF_MAX_DISPLAY do
			local name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId = UnitDebuff ("player", i)
			debuffType = "DEBUFF"
			
			if (not name) then
				break
				
			elseif (not DB_DEBUFF_BANNED [name]) then
				local auraIconFrame = Plater.GetAuraIcon (self)
				Plater.AddAura (auraIconFrame, i, name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId, false, false, true, true)
				
				if (not SPECIAL_AURA_NAMES_MINE [name] or (caster and (UnitIsUnit (caster, "player") or UnitIsUnit (caster, "pet")))) then
					if (SPECIAL_AURA_NAMES [name] or DB_SHOW_PURGE_IN_EXTRA_ICONS and canStealOrPurge) then
						Plater.AddExtraIcon (self, name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId)
					end
				end
			end
		end
	end
	
	--> buffs
	if (Plater.db.profile.aura_show_buffs_personal) then
		for i = 1, BUFF_MAX_DISPLAY do
			local name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId = UnitBuff ("player", i, nil, "PLAYER")
			debuffType = "BUFF"
			
			if (not name) then
				break
				
			elseif (not DB_BUFF_BANNED [name] and (duration and (duration > 0 and duration < 91)) and (caster and UnitIsUnit (caster, "player"))) then
				local auraIconFrame = Plater.GetAuraIcon (self, true)
				Plater.AddAura (auraIconFrame, i, name, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId, false, false, false, true)
			end
		end
	end	
	
	--> hide not used aura frames
	hide_non_used_auraFrames (self)
end

--debug animations

function Plater.DebugHealthAnimation()
	if (Plater.DebugHealthAnimation_Timer) then
		return
	end

	Plater.DebugHealthAnimation_Timer = C_Timer.NewTicker (1.5, function() --~animationtest
		for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
			local self = plateFrame.UnitFrame
			
			if (self.healthBar.CurrentHealth == 0) then
				self.healthBar.AnimationStart = 0
				self.healthBar.AnimationEnd = UnitHealthMax (plateFrame [MEMBER_UNITID])
			else
				self.healthBar.AnimationStart = UnitHealthMax (plateFrame [MEMBER_UNITID])
				self.healthBar.AnimationEnd = 0
			end
			
			self.healthBar:SetValue (self.healthBar.CurrentHealth)
			self.healthBar.CurrentHealthMax = UnitHealthMax (plateFrame [MEMBER_UNITID])
			
			self.healthBar.IsAnimating = true
			
			if (self.healthBar.AnimationEnd > self.healthBar.AnimationStart) then
				self.healthBar.AnimateFunc = Plater.AnimateRightWithAccel
			else
				self.healthBar.AnimateFunc = Plater.AnimateLeftWithAccel
			end
		
		end
	end)
	
	C_Timer.After (10, function()
		if (Plater.DebugHealthAnimation_Timer) then
			Plater.DebugHealthAnimation_Timer:Cancel()
			Plater.DebugHealthAnimation_Timer = nil
			Plater:Msg ("stopped the animation test.")
			Plater.UpdateAllPlates()
		end
	end)
	
	Plater:Msg ("is now animating nameplates in your screen for test purposes.")
end

function Plater.DebugColorAnimation()
	if (Plater.DebugColorAnimation_Timer) then
		return
	end

	Plater.DebugColorAnimation_Timer = C_Timer.NewTicker (0.5, function() --~animationtest
		for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
			--make the bar jump from green to pink - pink to green
			Plater.ForceChangeHealthBarColor (plateFrame.UnitFrame.healthBar, math.abs (math.sin (GetTime())), math.abs (math.cos (GetTime())), math.abs (math.sin (GetTime())))
		end
	end)

	C_Timer.After (10, function()
		if (Plater.DebugColorAnimation_Timer) then
			Plater.DebugColorAnimation_Timer:Cancel()
			Plater.DebugColorAnimation_Timer = nil
			Plater:Msg ("stopped the animation test.")
			Plater.UpdateAllPlates()
		end
	end)
	
	Plater:Msg ("is now animating color nameplates in your screen for test purposes.")
end

--> animation with acceleration ~animation
function Plater.AnimateLeftWithAccel (self, deltaTime)
	local distance = (self.AnimationStart - self.AnimationEnd) / self.CurrentHealthMax * 100	--scale 1 - 100
	local minTravel = min (distance / 10, 3) -- 10 = trigger distance to max speed 3 = speed scale on max travel
	local maxTravel = max (minTravel, 0.45) -- 0.45 = min scale speed on low travel speed
	local calcAnimationSpeed = (self.CurrentHealthMax * (deltaTime * DB_ANIMATION_TIME_DILATATION)) * maxTravel --re-scale back to unit health, scale with delta time and scale with the travel speed
	
	self.AnimationStart = self.AnimationStart - (calcAnimationSpeed)
	self:SetValue (self.AnimationStart)
	self.CurrentHealth = self.AnimationStart
	
	if (self.AnimationStart-1 <= self.AnimationEnd) then
		self:SetValue (self.AnimationEnd)
		self.CurrentHealth = self.AnimationEnd
		self.IsAnimating = false
	end
end

function Plater.AnimateRightWithAccel (self, deltaTime)
	local distance = (self.AnimationEnd - self.AnimationStart) / self.CurrentHealthMax * 100	--scale 1 - 100 basis
	local minTravel = math.min (distance / 10, 3) -- 10 = trigger distance to max speed 3 = speed scale on max travel
	local maxTravel = math.max (minTravel, 0.45) -- 0.45 = min scale speed on low travel speed
	local calcAnimationSpeed = (self.CurrentHealthMax * (deltaTime * DB_ANIMATION_TIME_DILATATION)) * maxTravel --re-scale back to unit health, scale with delta time and scale with the travel speed
	
	self.AnimationStart = self.AnimationStart + (calcAnimationSpeed)
	self:SetValue (self.AnimationStart)
	self.CurrentHealth = self.AnimationStart
	
	if (self.AnimationStart+1 >= self.AnimationEnd) then
		self:SetValue (self.AnimationEnd)
		self.CurrentHealth = self.AnimationEnd
		self.IsAnimating = false
	end
end

-- ~ontick ~onupdate ~tick �nupdate �ntick 
local EventTickFunction = function (tickFrame, deltaTime)

	tickFrame.ThrottleUpdate = tickFrame.ThrottleUpdate - deltaTime
	local unitFrame = tickFrame.UnitFrame
	local healthBar = unitFrame.healthBar
	
	--throttle updates, things on this block update with the interval set in the advanced tab
	if (tickFrame.ThrottleUpdate < 0) then
		--make the db path smaller for performance
		local actorTypeDBConfig = DB_PLATE_CONFIG [tickFrame.actorType]
		
		--perform a range check
		Plater.CheckRange (tickFrame.PlateFrame)
		
		--health cutoff (execute range)
		if (CONST_USE_HEALTHCUTOFF) then
			local healthPercent = UnitHealth (tickFrame.unit) / UnitHealthMax (tickFrame.unit)
			if (healthPercent < CONST_HEALTHCUTOFF_AT) then
				if (not healthBar.healthCutOff:IsShown()) then
					healthBar.healthCutOff:SetHeight (healthBar:GetHeight())
					healthBar.healthCutOff:SetPoint ("left", healthBar, "left", healthBar:GetWidth() * CONST_HEALTHCUTOFF_AT, 0)
					
					if (not Plater.db.profile.health_cutoff_hide_divisor) then
						healthBar.healthCutOff:Show()
						healthBar.healthCutOff.ShowAnimation:Play()
					else
						healthBar.healthCutOff:Show()
						healthBar.healthCutOff:SetAlpha (0)
					end

					healthBar.executeRange:Show()
					healthBar.executeRange:SetTexCoord (0, CONST_HEALTHCUTOFF_AT, 0, 1)
					healthBar.executeRange:SetAlpha (0.2)
					healthBar.executeRange:SetVertexColor (.3, .3, .3)
					healthBar.executeRange:SetHeight (healthBar:GetHeight())
					healthBar.executeRange:SetPoint ("right", healthBar.healthCutOff, "left")
					
					if (Plater.db.profile.health_cutoff_extra_glow) then
						healthBar.ExecuteGlowUp.ShowAnimation:Play()
						healthBar.ExecuteGlowDown.ShowAnimation:Play()
					end
				end
			else
				healthBar.healthCutOff:Hide()
				healthBar.executeRange:Hide()
				healthBar.ExecuteGlowUp:Hide()
				healthBar.ExecuteGlowDown:Hide()
			end
		end
		
		--if the unit tapped? (gray color)
		if (IsTapDenied (tickFrame.unit)) then
			Plater.ForceChangeHealthBarColor (healthBar, unpack (Plater.db.profile.tap_denied_color))
		
		--check aggro if is in combat
		elseif (PLAYER_IN_COMBAT) then
			if (unitFrame.CanCheckAggro) then
				Plater.UpdateNameplateThread (unitFrame)
			end
			
			if (actorTypeDBConfig.percent_text_enabled) then
				Plater.UpdateLifePercentText (healthBar, unitFrame.unit, actorTypeDBConfig.percent_show_health, actorTypeDBConfig.percent_show_percent, actorTypeDBConfig.percent_text_show_decimals)
			end
		else
			--if not in combat, check if can show the percent health out of combat
			if (actorTypeDBConfig.percent_text_enabled and actorTypeDBConfig.percent_text_ooc) then
				Plater.UpdateLifePercentText (healthBar, unitFrame.unit, actorTypeDBConfig.percent_show_health, actorTypeDBConfig.percent_show_percent, actorTypeDBConfig.percent_text_show_decimals)
				healthBar.lifePercent:Show()
			end
		end

		--update buffs and debuffs
		if (DB_AURA_ENABLED) then
			tickFrame.BuffFrame:UpdateAnchor()
			if (DB_TRACK_METHOD == 0x1) then --automatic
				if (tickFrame.actorType == ACTORTYPE_PLAYER) then
					--update auras on the personal bar
					Plater.UpdateAuras_Self_Automatic (tickFrame.BuffFrame)
				else
					Plater.UpdateAuras_Automatic (tickFrame.BuffFrame, tickFrame.unit)
				end
			else
				--manual aura track
				Plater.UpdateAuras_Manual (tickFrame.BuffFrame, tickFrame.unit, tickFrame.actorType == ACTORTYPE_PLAYER)
			end
			
			--update the buff layout and alpha
			tickFrame.BuffFrame.unit = tickFrame.unit
			tickFrame.BuffFrame:Layout()
			tickFrame.BuffFrame:SetAlpha (DB_AURA_ALPHA)
		end
		
		--set the delay to perform another update
		tickFrame.ThrottleUpdate = DB_TICK_THROTTLE

		--check if the unit name or unit npcID has a script
		local globalScriptObject = SCRIPT_UNIT [tickFrame.PlateFrame [MEMBER_NAMELOWER]] or SCRIPT_UNIT [tickFrame.PlateFrame [MEMBER_NPCID]]
		--check if this aura has a custom script
		if (globalScriptObject) then
			--stored information about scripts
			local scriptContainer = unitFrame:ScriptGetContainer()
			--get the info about this particularly script
			local scriptInfo = unitFrame:ScriptGetInfo (globalScriptObject, scriptContainer)
			
			local scriptEnv = scriptInfo.Env
			scriptEnv._UnitID = tickFrame.PlateFrame [MEMBER_UNITID]
			scriptEnv._NpcID = tickFrame.PlateFrame [MEMBER_NPCID]
			scriptEnv._UnitName = tickFrame.PlateFrame [MEMBER_NAME]
			scriptEnv._UnitGUID = tickFrame.PlateFrame [MEMBER_GUID]
			scriptEnv._HealthPercent = healthBar.CurrentHealth / healthBar.CurrentHealthMax * 100
	
			--run onupdate script
			unitFrame:ScriptRunOnUpdate (scriptInfo)
		end
		
		--hooks
		if (HOOK_NAMEPLATE_UPDATED.ScriptAmount > 0) then
			for i = 1, HOOK_NAMEPLATE_UPDATED.ScriptAmount do
				local globalScriptObject = HOOK_NAMEPLATE_UPDATED [i]
				local scriptContainer = unitFrame:ScriptGetContainer()
				local scriptInfo = unitFrame:ScriptGetInfo (globalScriptObject, scriptContainer)
				
				local scriptEnv = scriptInfo.Env
				scriptEnv._HealthPercent = healthBar.CurrentHealth / healthBar.CurrentHealthMax * 100
				
				--run
				unitFrame:ScriptRunHook (scriptInfo, "Nameplate Updated")
			end
		end
		
		--details! integration
		if (IS_USING_DETAILS_INTEGRATION and not tickFrame.PlateFrame.isSelf and PLAYER_IN_COMBAT) then
			local detailsPlaterConfig = Details.plater

			--> current damage taken from all sources
			if (detailsPlaterConfig.realtime_dps_enabled) then
				local unitDamageTable = DetailsPlaterFrame.DamageTaken [tickFrame.PlateFrame [MEMBER_GUID]]
				if (unitDamageTable) then
					local damage = unitDamageTable.CurrentDamage or 0
					
					local textString = healthBar.DetailsRealTime
					textString:SetText (DF.FormatNumber (damage / PLATER_DPS_SAMPLE_SIZE))
				else
					local textString = healthBar.DetailsRealTime
					textString:SetText ("")
				end
			end
			
			if (detailsPlaterConfig.realtime_dps_player_enabled) then
				local unitDamageTable = DetailsPlaterFrame.DamageTaken [tickFrame.PlateFrame [MEMBER_GUID]]
				if (unitDamageTable) then
					local damage = unitDamageTable.CurrentDamageFromPlayer or 0
					
					local textString = healthBar.DetailsRealTimeFromPlayer
					textString:SetText (DF.FormatNumber (damage / PLATER_DPS_SAMPLE_SIZE))
				else
					local textString = healthBar.DetailsRealTimeFromPlayer
					textString:SetText ("")
				end

			end
			
			if (detailsPlaterConfig.damage_taken_enabled) then
				local unitDamageTable = DetailsPlaterFrame.DamageTaken [tickFrame.PlateFrame [MEMBER_GUID]]
				if (unitDamageTable) then
					local damage = unitDamageTable.TotalDamageTaken or 0
					
					local textString = healthBar.DetailsDamageTaken
					textString:SetText (DF.FormatNumber (damage))
				else
					local textString = healthBar.DetailsDamageTaken
					textString:SetText ("")
				end
			end
		end
		
		--end of throttled updates
	end

	--OnTick updates
		--smooth color transition ~lerpcolor
		if (DB_LERP_COLOR) then
			local currentR, currentG, currentB = healthBar.barTexture:GetVertexColor()
			local r, g, b = DF:LerpLinearColor (deltaTime, DB_LERP_COLOR_SPEED, currentR, currentG, currentB, healthBar.R, healthBar.G, healthBar.B)
			healthBar.barTexture:SetVertexColor (r, g, b)
		end
		
		--animate health bar ~animation
		if (DB_DO_ANIMATIONS) then
			if (healthBar.IsAnimating) then
				healthBar.AnimateFunc (healthBar, deltaTime)
			end
		end
		
		--height animation transition
		if (healthBar.HAVE_HEIGHT_ANIMATION) then
			if (healthBar.HAVE_HEIGHT_ANIMATION == "up") then
				local increment = deltaTime * Plater.db.profile.height_animation_speed * healthBar.ToIncreace
				local size = healthBar:GetHeight() + increment
				if (size + 0.0001 >= healthBar.TargetHeight) then
					healthBar:SetHeight (healthBar.TargetHeight)
					healthBar.HAVE_HEIGHT_ANIMATION = nil
					Plater.UpdateTarget (tickFrame.PlateFrame)
				else
					healthBar:SetHeight (size)
				end			
				
			elseif (healthBar.HAVE_HEIGHT_ANIMATION == "down") then
				local decrease = deltaTime * Plater.db.profile.height_animation_speed * healthBar.ToDecrease
				local size = healthBar:GetHeight() - decrease
				if (size - 0.0001 <= healthBar.TargetHeight) then
					healthBar:SetHeight (healthBar.TargetHeight)
					healthBar.HAVE_HEIGHT_ANIMATION = nil
					Plater.UpdateTarget (tickFrame.PlateFrame)
				else
					healthBar:SetHeight (size)
				end			
				
			end
		end
end

--for�a a default UI a trocar a cor das barras
function Plater.UpdateAllNameplateColors()
	if (Plater.CanOverrideColor) then
		for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
			CompactUnitFrame_UpdateHealthColor (plateFrame.UnitFrame)
		end
	else
		for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
			if (not plateFrame.isSelf) then
				local healthBar = plateFrame.UnitFrame.healthBar
				Plater.ForceChangeHealthBarColor (healthBar, healthBar.r, healthBar.g, healthBar.b)
			end
		end
	end
end

function Plater.SetPlateBackground (plateFrame)
	plateFrame:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
	plateFrame:SetBackdropColor (0, 0, 0, 0.5)
	plateFrame:SetBackdropBorderColor (0, 0, 0, 1)
end

local shutdown_platesize_debug = function (timer)
	for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
		if (Plater.db.profile.click_space_always_show) then
			Plater.SetPlateBackground (plateFrame)
		else
			plateFrame:SetBackdrop (nil)
		end
	end
	
	Plater.PlateSizeDebugTimer = nil
end

local re_UpdatePlateClickSpace = function()
	Plater.UpdatePlateClickSpace()
end

-- ~platesize
function Plater.UpdatePlateClickSpace (needReorder, isDebug)
	if (not Plater.CanChangePlateSize()) then
		return C_Timer.After (1, re_UpdatePlateClickSpace)
	end
	
	local width, height = Plater.db.profile.click_space_friendly[1], Plater.db.profile.click_space_friendly[2]
	C_NamePlate.SetNamePlateFriendlySize (width, height)
	
	local width, height = Plater.db.profile.click_space[1], Plater.db.profile.click_space[2]
	C_NamePlate.SetNamePlateEnemySize (width, height)
	
	C_NamePlate.SetNamePlateFriendlyClickThrough (Plater.db.profile.plate_config.friendlyplayer.click_through) 
	
	if (isDebug and not Plater.db.profile.click_space_always_show) then
		for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
			plateFrame:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
			if (Plater.PlateSizeDebugTimer and not Plater.PlateSizeDebugTimer._cancelled) then
				Plater.PlateSizeDebugTimer:Cancel()
			end
		end
		if (not Plater.PlateSizeDebugTimer) then
			Plater:Msg ("showing the clickable area for test purposes.")
		end
		Plater.PlateSizeDebugTimer = C_Timer.NewTimer (3, shutdown_platesize_debug)
	end
	
	if (needReorder) then
		for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
			Plater.UpdatePlateFrame (plateFrame, plateFrame.actorType)
		end
	end
end

function Plater.UpdateAllPlates (forceUpdate, justAdded)
	for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
		Plater.UpdatePlateFrame (plateFrame, nil, forceUpdate, justAdded)
	end
end

function Plater.FullRefreshAllPlates()
	for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
		Plater ["NAME_PLATE_UNIT_ADDED"] (Plater, "NAME_PLATE_UNIT_ADDED", plateFrame [MEMBER_UNITID])
	end
end

function Plater.GetAllShownPlates()
	--return C_NamePlate.GetNamePlates()
	return C_NamePlate.GetNamePlates (issecure())
end

-- ~events
function Plater:PLAYER_SPECIALIZATION_CHANGED()
	C_Timer.After (2, Plater.GetSpellForRangeCheck)
	C_Timer.After (2, Plater.GetHealthCutoffValue)
end

function Plater:PLAYER_TALENT_UPDATE()
	C_Timer.After (2, Plater.GetSpellForRangeCheck)
	C_Timer.After (2, Plater.GetHealthCutoffValue)
end

function Plater.UpdateAuraCache()
	
	--manual tracking has an indexed table to store what to track
	--the extra auras for automatic tracking has a hash table with spellIds
	
	--manual aura tracking
		local manualBuffsToTrack = Plater.db.profile.aura_tracker.buff
		local manualDebuffsToTrack = Plater.db.profile.aura_tracker.debuff

		wipe (MANUAL_TRACKING_DEBUFFS)
		wipe (MANUAL_TRACKING_BUFFS)
		
		for i = 1, #manualDebuffsToTrack do
			local spellName = GetSpellInfo (manualDebuffsToTrack [i])
			if (spellName) then
				MANUAL_TRACKING_DEBUFFS [spellName] = true
			else
				--add the entry in case there's a spell name instead of a spellId in the list (for back compatibility)
				MANUAL_TRACKING_DEBUFFS [manualDebuffsToTrack [i]] = true
			end
		end

		for i = 1, #manualBuffsToTrack do
			local spellName = GetSpellInfo (manualBuffsToTrack [i])
			if (spellName) then
				MANUAL_TRACKING_BUFFS [spellName] = true
			else
				--add the entry in case there's a spell name instead of a spellId in the list (for back compatibility)
				MANUAL_TRACKING_BUFFS [manualBuffsToTrack [i]]= true
			end
		end

	--extra auras to track on automatic aura tracking
		local extraBuffsToTrack = Plater.db.profile.aura_tracker.buff_tracked
		local extraDebuffsToTrack = Plater.db.profile.aura_tracker.debuff_tracked
		
		wipe (AUTO_TRACKING_EXTRA_BUFFS)
		wipe (AUTO_TRACKING_EXTRA_DEBUFFS)
		
		CAN_TRACK_EXTRA_BUFFS = false
		CAN_TRACK_EXTRA_DEBUFFS = false

		for spellId, _ in pairs (extraBuffsToTrack) do
			local spellName = GetSpellInfo (spellId)
			if (spellName) then
				AUTO_TRACKING_EXTRA_BUFFS [spellName] = true
				CAN_TRACK_EXTRA_BUFFS = true
			end
		end
		
		for spellId, _ in pairs (extraDebuffsToTrack) do
			local spellName = GetSpellInfo (spellId)
			if (spellName) then
				AUTO_TRACKING_EXTRA_DEBUFFS [spellName] = true
				CAN_TRACK_EXTRA_DEBUFFS = true
			end
		end

end

function Plater.ScheduleHookForCombat (timerObject)
	if (timerObject.Event == "Enter Combat") then
		if (HOOK_COMBAT_ENTER.ScriptAmount > 0) then
			for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
				for i = 1, HOOK_COMBAT_ENTER.ScriptAmount do
					local globalScriptObject = HOOK_COMBAT_ENTER [i]
					local unitFrame = plateFrame.UnitFrame
					local scriptContainer = unitFrame:ScriptGetContainer()
					local scriptInfo = unitFrame:ScriptGetInfo (globalScriptObject, scriptContainer)
					--run
					unitFrame:ScriptRunHook (scriptInfo, "Enter Combat")
				end
			end
		end
		
	elseif (timerObject.Event == "Leave Combat") then
		if (HOOK_COMBAT_LEAVE.ScriptAmount > 0) then
			for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
				for i = 1, HOOK_COMBAT_LEAVE.ScriptAmount do
					local globalScriptObject = HOOK_COMBAT_LEAVE [i]
					local unitFrame = plateFrame.UnitFrame
					local scriptContainer = unitFrame:ScriptGetContainer()
					local scriptInfo = unitFrame:ScriptGetInfo (globalScriptObject, scriptContainer)
					--run
					unitFrame:ScriptRunHook (scriptInfo, "Leave Combat")
				end
			end
		end
	end
end

function Plater:PLAYER_REGEN_DISABLED()

	PLAYER_IN_COMBAT = true

	--> refresh tank cache
		Plater.PlayerIsTank = false
	
		wipe (TANK_CACHE)
		
		--add the player to the tank pool if the player is a tank
		if (IsPlayerEffectivelyTank()) then
			TANK_CACHE [UnitName ("player")] = true
			Plater.PlayerIsTank = true
		end
		
		--search for tanks in the raid
		if (IsInRaid()) then
			for i = 1, GetNumGroupMembers() do
				if (IsUnitEffectivelyTank ("raid" .. i)) then
					if (not UnitIsUnit ("raid" .. i, "player")) then
						TANK_CACHE [UnitName ("raid" .. i)] = true
					end
				end
			end
		end
	
	Plater.UpdateAuraCache()
	
	C_Timer.After (0.5, Plater.UpdateAllPlates)
	
	--check if can run combat enter hook and schedule it true
	if (HOOK_COMBAT_ENTER.ScriptAmount > 0) then
		local hookTimer = C_Timer.NewTimer (0.6, Plater.ScheduleHookForCombat)
		hookTimer.Event = "Enter Combat"
	end
	
	Plater.CombatTime = GetTime()
end

function Plater:PLAYER_REGEN_ENABLED()

	PLAYER_IN_COMBAT = false
	
	for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
		plateFrame [MEMBER_NOCOMBAT] = nil
	end
	
	--check if can run combat enter hook and schedule it true
	if (HOOK_COMBAT_LEAVE.ScriptAmount > 0) then
		local hookTimer = C_Timer.NewTimer (0.6, Plater.ScheduleHookForCombat)
		hookTimer.Event = "Leave Combat"
	end
	
	C_Timer.After (0.41, Plater.UpdateAllNameplateColors) --schedule to avoid taint issues
	C_Timer.After (0.51, Plater.UpdateAllPlates)
end

function Plater.FRIENDLIST_UPDATE()
	wipe (Plater.FriendsCache)
	for i = 1, GetNumFriends() do
		local toonName, level, class, area, connected, status, note = GetFriendInfo (i)
		if (connected and toonName) then
			Plater.FriendsCache [toonName] = true
			Plater.FriendsCache [DF:RemoveRealmName (toonName)] = true
		end
	end
	for i = 1, BNGetNumFriends() do 
		local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText, isRIDFriend, broadcastTime, canSoR = BNGetFriendInfo (i)
		if (isOnline and toonName) then
			Plater.FriendsCache [toonName] = true
		end
	end
	
	--let's not trigger a full update on all plates because a friend is now online
	--Plater.UpdateAllPlates()
end

function Plater:RAID_TARGET_UPDATE()
	Plater.UpdateRaidMarkersOnAllNameplates()
end

function Plater:QUEST_REMOVED()
	Plater.QuestLogUpdated()
end
function Plater:QUEST_ACCEPTED()
	Plater.QuestLogUpdated()
end
function Plater:QUEST_ACCEPT_CONFIRM()
	Plater.QuestLogUpdated()
end
function Plater:QUEST_COMPLETE()
	Plater.QuestLogUpdated()
end
function Plater:QUEST_POI_UPDATE()
	Plater.QuestLogUpdated()
end
function Plater:QUEST_QUERY_COMPLETE()
	Plater.QuestLogUpdated()
end
function Plater:QUEST_DETAIL()
	Plater.QuestLogUpdated()
end
function Plater:QUEST_FINISHED()
	Plater.QuestLogUpdated()
end
function Plater:QUEST_GREETING()
	Plater.QuestLogUpdated()
end
function Plater:QUEST_LOG_UPDATE()
	Plater.QuestLogUpdated()
end
function Plater:UNIT_QUEST_LOG_CHANGED()
	Plater.QuestLogUpdated()
end

function Plater:PLAYER_FOCUS_CHANGED()
	Plater.OnPlayerTargetChanged()
end
function Plater:PLAYER_TARGET_CHANGED()
	Plater.OnPlayerTargetChanged()
end

local wait_for_leave_combat = function()
	Plater:ZONE_CHANGED_NEW_AREA()
end

local re_RefreshAutoToggle = function()
	return Plater.RefreshAutoToggle()
end

function Plater.RefreshAutoToggle()

	if (InCombatLockdown()) then
		C_Timer.After (0.5, re_RefreshAutoToggle)
		return
	end
	
	local zoneName, zoneType = GetInstanceInfo()

	--friendly nameplate toggle
	if (Plater.db.profile.auto_toggle_friendly_enabled) then
		--discover which is the map type the player is in
		if (zoneType == "party") then
			SetCVar ("nameplateShowFriends", Plater.db.profile.auto_toggle_friendly ["party"] and CVAR_ENABLED or CVAR_DISABLED)
			
		elseif (zoneType == "raid") then
			SetCVar ("nameplateShowFriends", Plater.db.profile.auto_toggle_friendly ["raid"] and CVAR_ENABLED or CVAR_DISABLED)
			
		elseif (zoneType == "arena") then
			SetCVar ("nameplateShowFriends", Plater.db.profile.auto_toggle_friendly ["arena"] and CVAR_ENABLED or CVAR_DISABLED)
			
		else
			--if the player is resting, consider inside a major city
			if (IsResting()) then
				SetCVar ("nameplateShowFriends", Plater.db.profile.auto_toggle_friendly ["cities"] and CVAR_ENABLED or CVAR_DISABLED)
			else
				SetCVar ("nameplateShowFriends", Plater.db.profile.auto_toggle_friendly ["world"] and CVAR_ENABLED or CVAR_DISABLED)
			end
		end
	end
	
	--stacking toggle
	if (Plater.db.profile.auto_toggle_stacking_enabled and Plater.db.profile.stacking_nameplates_enabled) then
		--discover which is the map type the player is in
		if (zoneType == "party") then
			SetCVar (CVAR_PLATEMOTION, Plater.db.profile.auto_toggle_stacking ["party"] and CVAR_ENABLED or CVAR_DISABLED)
			
		elseif (zoneType == "raid") then
			SetCVar (CVAR_PLATEMOTION, Plater.db.profile.auto_toggle_stacking ["raid"] and CVAR_ENABLED or CVAR_DISABLED)
			
		elseif (zoneType == "arena") then
			SetCVar (CVAR_PLATEMOTION, Plater.db.profile.auto_toggle_stacking ["arena"] and CVAR_ENABLED or CVAR_DISABLED)
			
		else
			--if the player is resting, consider inside a major city
			if (IsResting()) then
				SetCVar (CVAR_PLATEMOTION, Plater.db.profile.auto_toggle_stacking ["cities"] and CVAR_ENABLED or CVAR_DISABLED)
			else
				SetCVar (CVAR_PLATEMOTION, Plater.db.profile.auto_toggle_stacking ["world"] and CVAR_ENABLED or CVAR_DISABLED)
			end
		end
	end
end

function Plater:PLAYER_UPDATE_RESTING()
	Plater.RefreshAutoToggle()
end

function Plater:ENCOUNTER_END()
	Plater.CurrentEncounterID = nil
	Plater.LatestEncounter = time()
end

function Plater:ENCOUNTER_START (_, encounterID)
	Plater.CurrentEncounterID = encounterID
	
	local _, zoneType = GetInstanceInfo()
	if (zoneType == "raid") then
		table.wipe (DB_CAPTURED_SPELLS)
	end
end

function Plater:CHALLENGE_MODE_START()
	table.wipe (DB_CAPTURED_SPELLS)
end

function Plater:ZONE_CHANGED_NEW_AREA()
	if (InCombatLockdown()) then
		C_Timer.After (1, wait_for_leave_combat)
		return
	end
	
	Plater.CurrentEncounterID = nil
	
	local pvpType, isFFA, faction = GetZonePVPInfo()
	Plater.ZonePvpType = pvpType
	
	local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize = GetInstanceInfo()
	
	--reset when entering in a battleground
	if (instanceType == "pvp") then
		table.wipe (DB_CAPTURED_SPELLS)
	end
	Plater.ZoneInstanceType = instanceType
	
	IS_IN_OPEN_WORLD = Plater.ZoneInstanceType == "none"
	
	Plater.UpdateAllPlates()
	Plater.RefreshAutoToggle()
end

function Plater:ZONE_CHANGED_INDOORS()
	return Plater:ZONE_CHANGED_NEW_AREA()
end

function Plater:ZONE_CHANGED()
	return Plater:ZONE_CHANGED_NEW_AREA()
end

local delayed_guildname_check = function()
	Plater.PlayerGuildName = GetGuildInfo ("player")
	if (not Plater.PlayerGuildName or Plater.PlayerGuildName == "") then
		Plater.PlayerGuildName = "ThePlayerHasNoGuildName/30Char"
	end
	
	--print ("delayind guild check:", Plater.PlayerGuildName)
end

function Plater:PLAYER_ENTERING_WORLD()
	C_Timer.After (1, Plater.ZONE_CHANGED_NEW_AREA)
	C_Timer.After (1, Plater.FRIENDLIST_UPDATE)
	Plater.PlayerGuildName = GetGuildInfo ("player")
	if (not Plater.PlayerGuildName or Plater.PlayerGuildName == "") then
		Plater.PlayerGuildName = "ThePlayerHasNoGuildName/30Char"
		
		--somethimes guild information isn't available at the login
		C_Timer.After (10, delayed_guildname_check)
	end
	
	local pvpType, isFFA, faction = GetZonePVPInfo()
	Plater.ZonePvpType = pvpType
	
	local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize = GetInstanceInfo()
	Plater.ZoneInstanceType = instanceType
	
end
Plater:RegisterEvent ("PLAYER_ENTERING_WORLD")

--called when the player targets a new unit, when focus changed or when a unit isn't in the screen any more
function Plater.OnPlayerTargetChanged()
	Plater.PlayerCurrentTargetGUID = UnitGUID ("target")
	
	for index, plateFrame in ipairs (Plater.GetAllShownPlates()) do
		Plater.UpdateTarget (plateFrame)
		
		--hooks
		if (HOOK_TARGET_CHANGED.ScriptAmount > 0) then
			for i = 1, HOOK_TARGET_CHANGED.ScriptAmount do
				local globalScriptObject = HOOK_TARGET_CHANGED [i]
				local unitFrame = plateFrame.UnitFrame
				local scriptContainer = unitFrame:ScriptGetContainer()
				local scriptInfo = unitFrame:ScriptGetInfo (globalScriptObject, scriptContainer)
				--run
				unitFrame:ScriptRunHook (scriptInfo, "Target Changed")
			end
		end
	end
end

-- ~target
function Plater.UpdateTarget (plateFrame)

	if (UnitIsUnit (plateFrame [MEMBER_UNITID], "focus") and Plater.db.profile.focus_indicator_enabled) then
		--this is a rare call, no need to cache these values
		local texture = LibSharedMedia:Fetch ("statusbar", Plater.db.profile.focus_texture)
		plateFrame.FocusIndicator:SetTexture (texture)
		plateFrame.FocusIndicator:SetVertexColor (unpack (Plater.db.profile.focus_color))
		plateFrame.FocusIndicator:Show()
	else
		plateFrame.FocusIndicator:Hide()
	end

	if (UnitIsUnit (plateFrame [MEMBER_UNITID], "target")) then
		plateFrame [MEMBER_TARGET] = true
		plateFrame.UnitFrame [MEMBER_TARGET] = true
	
		--hide obscured texture
		plateFrame.Obscured:Hide()
		
		--target indicator
		Plater.UpdateTargetIndicator (plateFrame)
		
		--target highlight
		if (Plater.db.profile.target_highlight) then
			if (plateFrame.actorType ~= ACTORTYPE_FRIENDLY_PLAYER and plateFrame.actorType ~= ACTORTYPE_FRIENDLY_NPC and not plateFrame.PlayerCannotAttack) then
				plateFrame.TargetNeonUp:Show()
				plateFrame.TargetNeonDown:Show()
			else
				plateFrame.TargetNeonUp:Hide()
				plateFrame.TargetNeonDown:Hide()
			end
			Plater.UpdateTargetPoints (plateFrame) --neon
		end
	else
		plateFrame.TargetNeonUp:Hide()
		plateFrame.TargetNeonDown:Hide()
		
		plateFrame [MEMBER_TARGET] = nil
		plateFrame.UnitFrame [MEMBER_TARGET] = nil
		
		if (plateFrame.UnitFrame.IsTarget or plateFrame.UnitFrame.TargetTextures2Sides [1]:IsShown() or plateFrame.UnitFrame.TargetTextures4Sides [1]:IsShown()) then
			for i = 1, 2 do
				plateFrame.UnitFrame.TargetTextures2Sides [i]:Hide()
			end
			for i = 1, 4 do
				plateFrame.UnitFrame.TargetTextures4Sides [i]:Hide()
			end
			
			plateFrame.UnitFrame.IsTarget = false
		end
		
		if (DB_TARGET_SHADY_ENABLED and (not DB_TARGET_SHADY_COMBATONLY or PLAYER_IN_COMBAT)) then
			plateFrame.Obscured:Show()
			plateFrame.Obscured:SetAlpha (DB_TARGET_SHADY_ALPHA)
		else
			plateFrame.Obscured:Hide()
		end
	end
	
	--Plater.CheckRange (plateFrame, true) --disabled on 09-10-2018
end

function Plater.UpdateTargetPoints (plateFrame)
	local healthBar = plateFrame.UnitFrame.healthBar
	local width = healthBar:GetWidth()
	local x = width/14
	local alpha = Plater.db.profile.target_highlight_alpha
	plateFrame.TargetNeonUp:SetAlpha (alpha)
	plateFrame.TargetNeonUp:SetPoint ("topleft", healthBar, "bottomleft", -x, 0)
	plateFrame.TargetNeonUp:SetPoint ("topright", healthBar, "bottomright", x, 0)
	plateFrame.TargetNeonDown:SetAlpha (alpha)
	plateFrame.TargetNeonDown:SetPoint ("bottomleft", healthBar, "topleft", -x, 0)
	plateFrame.TargetNeonDown:SetPoint ("bottomright", healthBar, "topright", x, 0)
end

function Plater.UpdateTargetIndicator (plateFrame)

	local healthBarHeight = plateFrame.UnitFrame.healthBar:GetHeight()
	
	--if the height is lower than 4, just hide all indicators
	if (healthBarHeight < 4) then
		for i = 1, 2 do
			plateFrame.UnitFrame.TargetTextures2Sides [i]:Hide()
		end
		for i = 1, 4 do
			plateFrame.UnitFrame.TargetTextures4Sides [i]:Hide()
		end
		
		return
	end

	local preset = Plater.TargetIndicators [Plater.db.profile.target_indicator]
	
	local width, height = preset.width, preset.height
	local x, y = preset.x, preset.y
	local desaturated = preset.desaturated
	local coords = preset.coords
	local path = preset.path
	local blend = preset.blend or "BLEND"
	local alpha = preset.alpha or 1
	local overlayColorR, overlayColorG, overlayColorB = DF:ParseColors (preset.color or "white")
	
	local scale = healthBarHeight / 10
	
	--four parts (textures)
	if (#coords == 4) then
		for i = 1, 4 do
			local texture = plateFrame.UnitFrame.TargetTextures4Sides [i]
			texture:Show()
			texture:SetTexture (path)
			texture:SetTexCoord (unpack (coords [i]))
			texture:SetSize (width * scale, height * scale)
			texture:SetAlpha (alpha)
			texture:SetVertexColor (overlayColorR, overlayColorG, overlayColorB)
			texture:SetDesaturated (desaturated)
			
			if (i == 1) then
				texture:SetPoint ("topleft", plateFrame.UnitFrame.healthBar, "topleft", -x, y)
				
			elseif (i == 2) then
				texture:SetPoint ("bottomleft", plateFrame.UnitFrame.healthBar, "bottomleft", -x, -y)
				
			elseif (i == 3) then
				texture:SetPoint ("bottomright", plateFrame.UnitFrame.healthBar, "bottomright", x, -y)
				
			elseif (i == 4) then
				texture:SetPoint ("topright", plateFrame.UnitFrame.healthBar, "topright", x, y)
				
			end
		end
		
		for i = 1, 2 do
			plateFrame.UnitFrame.TargetTextures2Sides [i]:Hide()
		end
	else
		for i = 1, 2 do
			local texture = plateFrame.UnitFrame.TargetTextures2Sides [i]
			texture:Show()
			texture:SetTexture (path)
			texture:SetBlendMode (blend)
			texture:SetTexCoord (unpack (coords [i]))
			texture:SetSize (width * scale, height * scale)
			texture:SetDesaturated (desaturated)
			texture:SetAlpha (alpha)
			texture:SetVertexColor (overlayColorR, overlayColorG, overlayColorB)
			
			if (i == 1) then
				texture:SetPoint ("left", plateFrame.UnitFrame.healthBar, "left", -x, y)
				
			elseif (i == 2) then
				texture:SetPoint ("right", plateFrame.UnitFrame.healthBar, "right", x, -y)
			end
		end
		for i = 1, 4 do
			plateFrame.UnitFrame.TargetTextures4Sides [i]:Hide()
		end
	end
	
	plateFrame.UnitFrame.IsTarget = true
end

function Plater.CreateHealthFlashFrame (plateFrame)
	local f_anim = CreateFrame ("frame", nil, plateFrame.UnitFrame.healthBar)
	f_anim:SetFrameLevel (plateFrame.UnitFrame.healthBar:GetFrameLevel()-1)
	f_anim:SetPoint ("topleft", plateFrame.UnitFrame.healthBar, "topleft", -2, 2)
	f_anim:SetPoint ("bottomright", plateFrame.UnitFrame.healthBar, "bottomright", 2, -2)
	plateFrame.UnitFrame.healthBar.canHealthFlash = true
	
	local t = f_anim:CreateTexture (nil, "artwork")
	t:SetColorTexture (1, 1, 1, 1)
	t:SetAllPoints()
	t:SetBlendMode ("ADD")
	
	local animation = t:CreateAnimationGroup()
	local anim1 = animation:CreateAnimation ("Alpha")
	local anim2 = animation:CreateAnimation ("Alpha")
	local anim3 = animation:CreateAnimation ("Alpha")
	anim1:SetOrder (1)
	anim1:SetFromAlpha (0)
	anim1:SetToAlpha (1)
	anim1:SetDuration (0.1)
	anim2:SetOrder (2)
	anim2:SetFromAlpha (1)
	anim2:SetToAlpha (0)
	anim2:SetDuration (0.1)
	anim3:SetOrder (3)
	anim3:SetFromAlpha (0)
	anim3:SetToAlpha (1)
	anim3:SetDuration (0.1)

	animation:SetScript ("OnFinished", function (self)
		f_anim:Hide()
	end)
	animation:SetScript ("OnPlay", function (self)
		f_anim:Show()
	end)

	local do_flash_anim = function (duration)
		if (not plateFrame.UnitFrame.healthBar.canHealthFlash) then
			return
		end
		plateFrame.UnitFrame.healthBar.canHealthFlash = false
		
		duration = duration or 0.1
		
		anim1:SetDuration (duration)
		anim2:SetDuration (duration)
		anim3:SetDuration (duration)
		
		f_anim:Show()
		animation:Play()
	end
	
	f_anim:Hide()
	plateFrame.UnitFrame.healthBar.PlayHealthFlash = do_flash_anim
end

function Plater.CreateAggroFlashFrame (plateFrame)

	--local f_anim = CreateFrame ("frame", nil, plateFrame.UnitFrame.healthBar)
	local f_anim = CreateFrame ("frame", nil, plateFrame)
	f_anim:SetFrameLevel (plateFrame.UnitFrame.healthBar:GetFrameLevel()+3)
	f_anim:SetPoint ("topleft", plateFrame.UnitFrame.healthBar, "topleft")
	f_anim:SetPoint ("bottomright", plateFrame.UnitFrame.healthBar, "bottomright")
	
	local t = f_anim:CreateTexture (nil, "artwork")
	--t:SetTexCoord (0, 0.78125, 0, 0.66796875)
	--t:SetTexture ([[Interface\AchievementFrame\UI-Achievement-Alert-Glow]])
	t:SetColorTexture (1, 1, 1, 1)
	t:SetAllPoints()
	t:SetBlendMode ("ADD")
	local s = f_anim:CreateFontString (nil, "overlay", "GameFontNormal")
	s:SetText ("-AGGRO-")
	s:SetTextColor (.70, .70, .70)
	s:SetPoint ("center", t, "center")
	
	local animation = t:CreateAnimationGroup()
	local anim1 = animation:CreateAnimation ("Alpha")
	local anim2 = animation:CreateAnimation ("Alpha")
	anim1:SetOrder (1)
	anim1:SetFromAlpha (0)
	anim1:SetToAlpha (1)
	anim1:SetDuration (0.2)
	anim2:SetOrder (2)
	anim2:SetFromAlpha (1)
	anim2:SetToAlpha (0)
	anim2:SetDuration (0.2)
	
	animation:SetScript ("OnFinished", function (self)
		f_anim:Hide()
	end)
	animation:SetScript ("OnPlay", function (self)
		f_anim:Show()
	end)

	local do_flash_anim = function (text, duration)
		if (Plater.CombatTime+5 > GetTime()) then
			return
		end
		
		text = text or ""
		duration = duration or 0.2
		
		anim1:SetDuration (duration)
		anim2:SetDuration (duration)
		
		s:SetText (text)
		f_anim:Show()
		animation:Play()
	end
	
	f_anim:Hide()
	plateFrame.PlayBodyFlash = do_flash_anim
end

function Plater.CanChangePlateSize()
	return not InCombatLockdown()
end

local default_level_color = {r = 1.0, g = 0.82, b = 0.0}
local get_level_color = function (unitId, unitLevel)
	if (UnitCanAttack ("player", unitId)) then
		local playerLevel = UnitLevel ("player")
		local color = GetRelativeDifficultyColor (playerLevel, unitLevel)
		return color
	end
	return default_level_color
end

function Plater.UpdateLevelTextAndColor (plateFrame, unitId)
	local level = UnitLevel (unitId)
	if (not level) then
		plateFrame:SetText ("")
	elseif (level == -1) then
		plateFrame:SetText ("??")
	else
		plateFrame:SetText (level)
	end
	
	local color = get_level_color (unitId, level)
	plateFrame:SetTextColor (color.r, color.g, color.b)
end

local anchor_functions = {
	function (widget, config)--1
		widget:ClearAllPoints()
		widget:SetPoint ("bottomleft", widget:GetParent(), "topleft", config.x, config.y)
	end,
	function (widget, config)--2
		widget:ClearAllPoints()
		widget:SetPoint ("right", widget:GetParent(), "left", config.x, config.y)
	end,
	function (widget, config)--3
		widget:ClearAllPoints()
		widget:SetPoint ("topleft", widget:GetParent(), "bottomleft", config.x, config.y)
	end,
	function (widget, config)--4
		widget:ClearAllPoints()
		widget:SetPoint ("top", widget:GetParent(), "bottom", config.x, config.y)
	end,
	function (widget, config)--5
		widget:ClearAllPoints()
		widget:SetPoint ("topright", widget:GetParent(), "bottomright", config.x, config.y)
	end,
	function (widget, config)--6
		widget:ClearAllPoints()
		widget:SetPoint ("left", widget:GetParent(), "right", config.x, config.y)
	end,
	function (widget, config)--7
		widget:ClearAllPoints()
		widget:SetPoint ("bottomright", widget:GetParent(), "topright", config.x, config.y)
	end,
	function (widget, config)--8
		widget:ClearAllPoints()
		widget:SetPoint ("bottom", widget:GetParent(), "top", config.x, config.y)
	end,
	function (widget, config)--9
		widget:ClearAllPoints()
		widget:SetPoint ("center", widget:GetParent(), "center", config.x, config.y)
	end,
	function (widget, config)--10
		widget:ClearAllPoints()
		widget:SetPoint ("left", widget:GetParent(), "left", config.x, config.y)
	end,
	function (widget, config)--11
		widget:ClearAllPoints()
		widget:SetPoint ("right", widget:GetParent(), "right", config.x, config.y)
	end,
	function (widget, config)--12
		widget:ClearAllPoints()
		widget:SetPoint ("top", widget:GetParent(), "top", config.x, config.y)
	end,
	function (widget, config)--13
		widget:ClearAllPoints()
		widget:SetPoint ("bottom", widget:GetParent(), "bottom", config.x, config.y)
	end
}

function Plater.SetAnchor (widget, config)
	anchor_functions [config.side] (widget, config)
end

--PlaterScanTooltip:SetOwner (WorldFrame, "ANCHOR_NONE")
local GameTooltipFrame = CreateFrame ("GameTooltip", "PlaterScanTooltip", nil, "GameTooltipTemplate")
local GameTooltipFrameTextLeft2 = _G ["PlaterScanTooltipTextLeft2"]
function Plater.GetActorSubName (plateFrame)
	GameTooltipFrame:SetOwner (WorldFrame, "ANCHOR_NONE")
	GameTooltipFrame:SetHyperlink ("unit:" .. (plateFrame [MEMBER_GUID] or ''))
	return GameTooltipFrameTextLeft2:GetText()
end

local GameTooltipScanQuest = CreateFrame ("GameTooltip", "PlaterScanQuestTooltip", nil, "GameTooltipTemplate")
local ScanQuestTextCache = {}
for i = 1, 8 do
	ScanQuestTextCache [i] = _G ["PlaterScanQuestTooltipTextLeft" .. i]
end

function Plater.IsQuestObjective (plateFrame)
	if (not plateFrame [MEMBER_GUID]) then
		return
	end
	GameTooltipScanQuest:SetOwner (WorldFrame, "ANCHOR_NONE")
	GameTooltipScanQuest:SetHyperlink ("unit:" .. plateFrame [MEMBER_GUID])
	
	for i = 1, 8 do
		local text = ScanQuestTextCache [i]:GetText()
		if (Plater.QuestCache [text]) then
			--este npc percente a uma quest
			if (not IsInGroup() and i < 8) then
				--verifica se j� fechou a quantidade necess�ria pra esse npc
				local nextLineText = ScanQuestTextCache [i+1]:GetText()
				if (nextLineText) then
					local p1, p2 = nextLineText:match ("(%d%d)/(%d%d)") --^ - 
					if (not p1) then
						p1, p2 = nextLineText:match ("(%d)/(%d%d)")
						if (not p1) then
							p1, p2 = nextLineText:match ("(%d)/(%d)")
						end
					end
					if (p1 and p2 and p1 == p2) then
						return
					end
				end
			end

			plateFrame [MEMBER_QUEST] = true
			return true
		end
	end
end

local update_quest_cache = function()

	--clear the quest cache
	wipe (Plater.QuestCache)

	--do not update if is inside an instance
	local isInInstance = IsInInstance()
	if (isInInstance) then
		return
	end
	
	--update the quest cache
	local numEntries, numQuests = GetNumQuestLogEntries()
	for questId = 1, numEntries do
		local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questId, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle (questId)
		if (type (questId) == "number" and questId > 0) then -- and not isComplete
			Plater.QuestCache [title] = true
		end
	end
	
	local mapId = C_Map.GetBestMapForUnit ("player")
	if (mapId) then
		local worldQuests = C_TaskQuest.GetQuestsForPlayerByMapID (mapId)
		if (type (worldQuests) == "table") then
			for i, questTable in ipairs (worldQuests) do
				local x, y, floor, numObjectives, questId, inProgress = questTable.x, questTable.y, questTable.floor, questTable.numObjectives, questTable.questId, questTable.inProgress
				if (type (questId) == "number" and questId > 0) then
					local questName = C_TaskQuest.GetQuestInfoByQuestID (questId)
					if (questName) then
						Plater.QuestCache [questName] = true
					end
				end
			end
		end
	end
	
	Plater.UpdateAllPlates()
end

function Plater.QuestLogUpdated()
	if (Plater.UpdateQuestCacheThrottle and not Plater.UpdateQuestCacheThrottle._cancelled) then
		Plater.UpdateQuestCacheThrottle:Cancel()
	end
	Plater.UpdateQuestCacheThrottle = C_Timer.NewTimer (2, update_quest_cache)
end

-- ~updatetext - called only from UpdatePlateFrame()
-- update all texts in the nameplate, settings can variate from different unit types
-- needReset is true when the previous unit type shown on this place is different from the current unit
function Plater.UpdatePlateText (plateFrame, plateConfigs, needReset)
	
	if (plateFrame.isSelf) then

		--update the power percent text
		if (plateConfigs.power_percent_text_enabled) then
			local powerString = ClassNameplateManaBarFrame.powerPercent
			if (needReset) then
				DF:SetFontSize (powerString, plateConfigs.power_percent_text_size)
				DF:SetFontFace (powerString, plateConfigs.power_percent_text_font)
				DF:SetFontOutline (powerString, plateConfigs.power_percent_text_shadow)
				DF:SetFontColor (powerString, plateConfigs.power_percent_text_color)
				Plater.SetAnchor (powerString, plateConfigs.power_percent_text_anchor)
				powerString:SetAlpha (plateConfigs.power_percent_text_alpha)
			end
			powerString:Show()
		else
			ClassNameplateManaBarFrame.powerPercent:Hide()
		end
		
		--return
		--needReset = true
		
	elseif (plateFrame.IsFriendlyPlayerWithoutHealthBar) then --not critical code
		--when the option to show only the player name is enabled
		--special string to show the player name
		local nameFontString = plateFrame.ActorNameSpecial
		nameFontString:Show()
		
		--set the name in the string
		plateFrame.CurrentUnitNameString = nameFontString
		Plater.UpdateUnitName (plateFrame, nameFontString)
		
		DF:SetFontSize (nameFontString, plateConfigs.actorname_text_size)
		DF:SetFontFace (nameFontString, plateConfigs.actorname_text_font)
		DF:SetFontOutline (nameFontString, plateConfigs.actorname_text_shadow)
		
		--check if the player has a guild, this check is done when the nameplate is added
		if (plateFrame.playerGuildName) then
			if (plateConfigs.show_guild_name) then
				Plater.AddGuildNameToPlayerName (plateFrame)
			end
		end
		
		--set the point of the name and guild texts
		nameFontString:ClearAllPoints()
		plateFrame.ActorNameSpecial:SetPoint ("center", plateFrame, "center", 0, 10)
		
		--format the color if is the same guild, a friend from friends list or color by player class
		if (plateFrame.playerGuildName == Plater.PlayerGuildName) then
			--is a guild friend?
			DF:SetFontColor (nameFontString, "PLATER_GUILD")
			plateFrame.isFriend = true
			
		elseif (Plater.FriendsCache [plateFrame [MEMBER_NAME]]) then
			--is regular friend
			DF:SetFontColor (nameFontString, "PLATER_FRIEND")
			DF:SetFontOutline (nameFontString, plateConfigs.actorname_text_shadow)
			plateFrame.isFriend = true
			
		else
			--isn't friend, check if is showing only the name and if is showing class colors
			if (Plater.db.profile.use_playerclass_color) then
				local _, unitClass = UnitClass (plateFrame [MEMBER_UNITID])
				if (unitClass) then
					local color = RAID_CLASS_COLORS [unitClass]
					DF:SetFontColor (nameFontString, color.r, color.g, color.b)
				else
					DF:SetFontColor (nameFontString, plateConfigs.actorname_text_color)
				end
			else
				DF:SetFontColor (nameFontString, plateConfigs.actorname_text_color)
			end

			plateFrame.isFriend = nil
		end
		
		return
	
	elseif (plateFrame.IsNpcWithoutHealthBar) then --not critical code
	
		--reset points for special units
		plateFrame.ActorNameSpecial:ClearAllPoints()
		plateFrame.ActorTitleSpecial:ClearAllPoints()
		plateFrame.ActorNameSpecial:SetPoint ("center", plateFrame, "center", 0, 10)
		plateFrame.ActorTitleSpecial:SetPoint ("top", plateFrame.ActorNameSpecial, "bottom", 0, -2)
	
		--there's two ways of showing this for friendly npcs (selected from the options panel): show all names or only npcs with profession names
		--enemy npcs always show all
		if (plateConfigs.all_names) then
			plateFrame.ActorNameSpecial:Show()
			plateFrame.CurrentUnitNameString = plateFrame.ActorNameSpecial
			Plater.UpdateUnitName (plateFrame, plateFrame.ActorNameSpecial)
			
			--if this is an enemy or neutral npc
			if (plateFrame [MEMBER_REACTION] <= 4) then
			
				local r, g, b, a
				
				--get the quest color if this npcs is a quest npc
				if (plateFrame [MEMBER_QUEST]) then
					if (plateFrame [MEMBER_REACTION] == UNITREACTION_NEUTRAL) then
						r, g, b, a = unpack (plateConfigs.quest_color_neutral)
					else
						r, g, b, a = unpack (plateConfigs.quest_color_enemy)
						g = g + 0.1
						b = b + 0.1
					end
				else
					r, g, b, a = 1, 1, 0, 1 --neutral
					if (plateFrame [MEMBER_REACTION] <= 3) then
						r, g, b, a = 1, .05, .05, 1
					end
				end
				
				plateFrame.ActorNameSpecial:SetTextColor (r, g, b, a)
				DF:SetFontSize (plateFrame.ActorNameSpecial, plateConfigs.big_actorname_text_size)
				DF:SetFontFace (plateFrame.ActorNameSpecial, plateConfigs.big_actorname_text_font)
				DF:SetFontOutline (plateFrame.ActorNameSpecial, plateConfigs.big_actorname_text_shadow)
				
				--npc title
				local subTitle = Plater.GetActorSubName (plateFrame)
				if (subTitle and subTitle ~= "" and not subTitle:match ("%d")) then
					plateFrame.ActorTitleSpecial:Show()
					subTitle = DF:RemoveRealmName (subTitle)
					plateFrame.ActorTitleSpecial:SetText ("<" .. subTitle .. ">")
					plateFrame.ActorTitleSpecial:ClearAllPoints()
					plateFrame.ActorTitleSpecial:SetPoint ("top", plateFrame.ActorNameSpecial, "bottom", 0, -2)
					
					plateFrame.ActorTitleSpecial:SetTextColor (r, g, b, a)
					DF:SetFontSize (plateFrame.ActorTitleSpecial, plateConfigs.big_actortitle_text_size)
					DF:SetFontFace (plateFrame.ActorTitleSpecial, plateConfigs.big_actortitle_text_font)
					DF:SetFontOutline (plateFrame.ActorTitleSpecial, plateConfigs.big_actortitle_text_shadow)
				else
					plateFrame.ActorTitleSpecial:Hide()
				end
				
			else
				--it's a friendly npc
				plateFrame.ActorNameSpecial:SetTextColor (unpack (plateConfigs.big_actorname_text_color))
				DF:SetFontSize (plateFrame.ActorNameSpecial, plateConfigs.big_actorname_text_size)
				DF:SetFontFace (plateFrame.ActorNameSpecial, plateConfigs.big_actorname_text_font)
				DF:SetFontOutline (plateFrame.ActorNameSpecial, plateConfigs.big_actorname_text_shadow)
				
				--profession (title)
				local subTitle = Plater.GetActorSubName (plateFrame)
				if (subTitle and subTitle ~= "" and not subTitle:match ("%d")) then
					plateFrame.ActorTitleSpecial:Show()
					subTitle = DF:RemoveRealmName (subTitle)
					plateFrame.ActorTitleSpecial:SetText ("<" .. subTitle .. ">")
					plateFrame.ActorTitleSpecial:ClearAllPoints()
					plateFrame.ActorTitleSpecial:SetPoint ("top", plateFrame.ActorNameSpecial, "bottom", 0, -2)
					
					plateFrame.ActorTitleSpecial:SetTextColor (unpack (plateConfigs.big_actortitle_text_color))
					DF:SetFontSize (plateFrame.ActorTitleSpecial, plateConfigs.big_actortitle_text_size)
					DF:SetFontFace (plateFrame.ActorTitleSpecial, plateConfigs.big_actortitle_text_font)
					DF:SetFontOutline (plateFrame.ActorTitleSpecial, plateConfigs.big_actortitle_text_shadow)
				end
			end
		else
			--scan tooltip to check if there's an title for this npc
			local subTitle = Plater.GetActorSubName (plateFrame)
			if (subTitle and subTitle ~= "" and not Plater.IsIgnored (plateFrame, true)) then
				if (not subTitle:match ("%d")) then --isn't level

					plateFrame.ActorTitleSpecial:Show()
					subTitle = DF:RemoveRealmName (subTitle)
					plateFrame.ActorTitleSpecial:SetText ("<" .. subTitle .. ">")
					plateFrame.ActorTitleSpecial:ClearAllPoints()
					plateFrame.ActorTitleSpecial:SetPoint ("top", plateFrame.ActorNameSpecial, "bottom", 0, -2)
					
					plateFrame.ActorTitleSpecial:SetTextColor (unpack (plateConfigs.big_actortitle_text_color))
					plateFrame.ActorNameSpecial:SetTextColor (unpack (plateConfigs.big_actorname_text_color))
					
					DF:SetFontSize (plateFrame.ActorTitleSpecial, plateConfigs.big_actortitle_text_size)
					DF:SetFontFace (plateFrame.ActorTitleSpecial, plateConfigs.big_actortitle_text_font)
					DF:SetFontOutline (plateFrame.ActorTitleSpecial, plateConfigs.big_actortitle_text_shadow)
					
					--npc name
					plateFrame.ActorNameSpecial:Show()

					plateFrame.CurrentUnitNameString = plateFrame.ActorNameSpecial
					Plater.UpdateUnitName (plateFrame, plateFrame.ActorNameSpecial)

					DF:SetFontSize (plateFrame.ActorNameSpecial, plateConfigs.big_actorname_text_size)
					DF:SetFontFace (plateFrame.ActorNameSpecial, plateConfigs.big_actorname_text_font)
					DF:SetFontOutline (plateFrame.ActorNameSpecial, plateConfigs.big_actorname_text_shadow)
				end
			end
		end
		
		return
	end
	
	--critical code
	--the nameplate is showing the health bar
	--cache the strings for performance
	local spellnameString = plateFrame.UnitFrame.castBar.Text
	local spellPercentString = plateFrame.UnitFrame.castBar.percentText
	local nameString = plateFrame.UnitFrame.healthBar.actorName	
	local guildString = plateFrame.ActorTitleSpecial
	local levelString = plateFrame.UnitFrame.healthBar.actorLevel
	local lifeString = plateFrame.UnitFrame.healthBar.lifePercent
	
	--update the unit name
	plateFrame.CurrentUnitNameString = nameString
	Plater.UpdateUnitName (plateFrame)
	
	--update the unit name text settings if required
	if (needReset) then
		DF:SetFontSize (nameString, plateConfigs.actorname_text_size)
		DF:SetFontFace (nameString, plateConfigs.actorname_text_font)
		DF:SetFontOutline (nameString, plateConfigs.actorname_text_shadow)
	end
	Plater.SetAnchor (nameString, plateConfigs.actorname_text_anchor)
	
	if (plateFrame.playerGuildName) then
		if (plateConfigs.show_guild_name) then
			Plater.AddGuildNameToPlayerName (plateFrame)
		end
	end
	
	if (plateFrame.playerGuildName == Plater.PlayerGuildName) then
		--is a guild friend?
		DF:SetFontColor (nameString, "PLATER_GUILD")
		DF:SetFontColor (guildString, "PLATER_GUILD")
		plateFrame.isFriend = true
	
	elseif (Plater.FriendsCache [plateFrame [MEMBER_NAME]]) then
		--is regular friend
		DF:SetFontColor (nameString, "PLATER_FRIEND")
		DF:SetFontColor (guildString, "PLATER_FRIEND")
		plateFrame.isFriend = true		

	else
		DF:SetFontColor (nameString, plateConfigs.actorname_text_color)
		plateFrame.isFriend = nil
	end

	--atualiza o texto da cast bar
	if (needReset) then
		DF:SetFontColor (spellnameString, plateConfigs.spellname_text_color)
		DF:SetFontOutline (spellnameString, plateConfigs.spellname_text_shadow)
		DF:SetFontFace (spellnameString, plateConfigs.spellname_text_font)
	end
	--looks like the game reset the size when the cast bar is show
	DF:SetFontSize (spellnameString, plateConfigs.spellname_text_size)
	
	--atualiza o texto da porcentagem do cast
	if (plateConfigs.spellpercent_text_enabled) then
		spellPercentString:Show()
		if (needReset) then
			DF:SetFontColor (spellPercentString, plateConfigs.spellpercent_text_color)
			DF:SetFontSize (spellPercentString, plateConfigs.spellpercent_text_size)
			DF:SetFontOutline (spellPercentString, plateConfigs.spellpercent_text_shadow)
			DF:SetFontFace (spellPercentString, plateConfigs.spellpercent_text_font)
			Plater.SetAnchor (spellPercentString, plateConfigs.spellpercent_text_anchor)
		end
	else
		spellPercentString:Hide()
	end

	Plater.SetAnchor (spellnameString, plateConfigs.spellname_text_anchor)
	
	--atualiza o texto do level ??
	if (plateConfigs.level_text_enabled) then
		levelString:Show()
		if (needReset) then
			DF:SetFontSize (levelString, plateConfigs.level_text_size)
			DF:SetFontFace (levelString, plateConfigs.level_text_font)
			DF:SetFontOutline (levelString, plateConfigs.level_text_shadow)
			Plater.SetAnchor (levelString, plateConfigs.level_text_anchor)
			Plater.UpdateLevelTextAndColor (levelString, plateFrame.namePlateUnitToken)
			levelString:SetAlpha (plateConfigs.level_text_alpha)
		end
	else
		levelString:Hide()
	end

	--atualiza o texto da porcentagem da vida
	if (plateConfigs.percent_text_enabled) then
		lifeString:Show()
		
		--apenas mostrar durante o combate
		if (PLAYER_IN_COMBAT or plateConfigs.percent_text_ooc) then
			lifeString:Show()
		else
			lifeString:Hide()
		end
		
		if (needReset) then
			DF:SetFontSize (lifeString, plateConfigs.percent_text_size)
			DF:SetFontFace (lifeString, plateConfigs.percent_text_font)
			DF:SetFontOutline (lifeString, plateConfigs.percent_text_shadow)
			DF:SetFontColor (lifeString, plateConfigs.percent_text_color)
			Plater.SetAnchor (lifeString, plateConfigs.percent_text_anchor)
			lifeString:SetAlpha (plateConfigs.percent_text_alpha)
		end
		
		Plater.UpdateLifePercentText (plateFrame.UnitFrame.healthBar, plateFrame.namePlateUnitToken, plateConfigs.percent_show_health, plateConfigs.percent_show_percent, plateConfigs.percent_text_show_decimals)
	else
		lifeString:Hide()
	end
	
	if (plateFrame.isSelf) then
		--name isn't shown in the personal bar
		plateFrame.UnitFrame.healthBar.actorName:SetText ("")
	end
	
end

function Plater.UpdateLifePercentText (healthBar, unitId, showHealthAmount, showPercentAmount, showDecimals)
	--get the cached health amount for performance
	local currentHealth, maxHealth = healthBar.CurrentHealth, healthBar.CurrentHealthMax
	
	if (showHealthAmount and showPercentAmount) then
		local percent = currentHealth / maxHealth * 100
		
		if (showDecimals) then
			if (percent < 10) then
				healthBar.lifePercent:SetText (DF.FormatNumber (currentHealth) .. " (" .. format ("%.2f", percent) .. "%)")
				
			elseif (percent < 99.9) then
				healthBar.lifePercent:SetText (DF.FormatNumber (currentHealth) .. " (" .. format ("%.1f", percent) .. "%)")
			else
				healthBar.lifePercent:SetText (DF.FormatNumber (currentHealth) .. " (100%)")
			end
		else
			healthBar.lifePercent:SetText (DF.FormatNumber (currentHealth) .. " (" .. floor (percent) .. "%)")
		end
		
	elseif (showHealthAmount) then
		healthBar.lifePercent:SetText (DF.FormatNumber (currentHealth))
	
	elseif (showPercentAmount) then
		local percent = currentHealth / maxHealth * 100
		
		if (showDecimals) then
			if (percent < 10) then
				healthBar.lifePercent:SetText (format ("%.2f", percent) .. "%")
				
			elseif (percent < 99.9) then
				healthBar.lifePercent:SetText (format ("%.1f", percent) .. "%")
			else
				healthBar.lifePercent:SetText ("100%")
			end
		else
			healthBar.lifePercent:SetText (floor (percent) .. "%")
		end
	
	else
		healthBar.lifePercent:SetText ("")
	end
end

-- ~raidmarker ~raidtarget
function Plater.UpdatePlateRaidMarker (plateFrame)
	local index = GetRaidTargetIndex (plateFrame.namePlateUnitToken)

	if (index and not plateFrame.isSelf) then
		local icon = plateFrame.UnitFrame.PlaterRaidTargetFrame.RaidTargetIcon
		SetRaidTargetIconTexture (icon, index)
		icon:Show()
		
		if (not icon.IsShowning) then
			--play animations
			icon.IsShowning = true
			icon.ShowAnimation:Play()
		end
		
		--adjust scale and anchor
		plateFrame.UnitFrame.PlaterRaidTargetFrame:SetScale (Plater.db.profile.indicator_raidmark_scale)
		Plater.SetAnchor (plateFrame.UnitFrame.PlaterRaidTargetFrame, Plater.db.profile.indicator_raidmark_anchor)
		
		--mini mark inside the nameplate
		if (Plater.db.profile.indicator_extra_raidmark) then
			plateFrame.RaidTarget:Show()
			plateFrame.RaidTarget:SetTexture (icon:GetTexture())
			plateFrame.RaidTarget:SetTexCoord (icon:GetTexCoord())
			
			local height = plateFrame.UnitFrame.healthBar:GetHeight() - 2
			plateFrame.RaidTarget:SetSize (height, height)
			plateFrame.RaidTarget:SetAlpha (.4)
		end
	else
		plateFrame.UnitFrame.PlaterRaidTargetFrame.RaidTargetIcon.IsShowning = nil
		plateFrame.UnitFrame.PlaterRaidTargetFrame.RaidTargetIcon:Hide()
		--hide the extra raid target inside the nameplate
		plateFrame.RaidTarget:Hide()
	end
end

--iterate among all nameplates and update the raid target icon
function Plater.UpdateRaidMarkersOnAllNameplates()
	for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
		Plater.UpdatePlateRaidMarker (plateFrame)
		
		--hooks
		if (HOOK_RAID_TARGET.ScriptAmount > 0) then
			for i = 1, HOOK_RAID_TARGET.ScriptAmount do
				local globalScriptObject = HOOK_RAID_TARGET [i]
				local unitFrame = plateFrame.UnitFrame
				local scriptContainer = unitFrame:ScriptGetContainer()
				local scriptInfo = unitFrame:ScriptGetInfo (globalScriptObject, scriptContainer)
				--run
				unitFrame:ScriptRunHook (scriptInfo, "Raid Target")
			end
		end
	end
end

--return which raid mark the namepalte has
function Plater.GetRaidMark (unitFrame)
	local plateFrame = unitFrame:GetParent()
	if (plateFrame.isSelf) then
		return false
	end
	return GetRaidTargetIndex (plateFrame.namePlateUnitToken)
end

-- ~size
function Plater.UpdatePlateSize (plateFrame, justAdded)
	if (not plateFrame.actorType) then
		return
	end

	local actorType = plateFrame.actorType
	local order = plateFrame.order

	local plateConfigs = DB_PLATE_CONFIG [actorType]
	local plateWidth = plateFrame:GetWidth()

	local unitFrame = plateFrame.UnitFrame
	local healthFrame = unitFrame.healthBar
	local castFrame = unitFrame.castBar
	local buffFrame = unitFrame.BuffFrame
	local nameFrame = unitFrame.healthBar.actorName
	
	local unitType = Plater.GetUnitType (plateFrame)
	local isInCombat = PLAYER_IN_COMBAT

	--sempre usar barras grandes quando estiver em pvp
	if (plateFrame.actorType == ACTORTYPE_ENEMY_PLAYER) then
		if ((Plater.ZoneInstanceType == "pvp" or Plater.ZoneInstanceType == "arena") and DB_PLATE_CONFIG.player.pvp_always_incombat) then
			isInCombat = true
		end
	end
	
	if (order == 1) then
		--debuff, health, castbar
		
		local castKey, heathKey, textKey = Plater.GetHashKey (isInCombat)
		local SizeOf_healthBar_Width = plateConfigs [heathKey][1]
		local SizeOf_castBar_Width = plateConfigs [castKey][1]
		local SizeOf_healthBar_Height = plateConfigs [heathKey][2]
		local SizeOf_castBar_Height = plateConfigs [castKey][2]
		local SizeOf_text = plateConfigs [textKey]
		
		local height_offset = 0
		
		--pegar o tamanho da barra de debuff para colocar a cast bar em cima dela
		local buffFrameSize = Plater.db.profile.aura_height
		
		local scalarValue = SizeOf_castBar_Width > plateWidth and -((SizeOf_castBar_Width - plateWidth) / 2) or ((plateWidth - SizeOf_castBar_Width) / 2)
		if (unitType == "pet") then
			scalarValue = scalarValue + (SizeOf_castBar_Width/5)
		elseif (unitType == "minus") then
			scalarValue = scalarValue + (SizeOf_castBar_Width/5)
		end
		
		castFrame:SetPoint ("BOTTOMLEFT", unitFrame, "BOTTOMLEFT", scalarValue, buffFrameSize + SizeOf_healthBar_Height + 2 + height_offset);
		castFrame:SetPoint ("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", -scalarValue, buffFrameSize + SizeOf_healthBar_Height + 2 + height_offset);
		castFrame:SetHeight (SizeOf_castBar_Height)
		castFrame.Icon:SetSize (SizeOf_castBar_Height, SizeOf_castBar_Height)
		castFrame.BorderShield:SetSize (SizeOf_castBar_Height*1.4, SizeOf_castBar_Height*1.4)
		
		local scalarValue
		if (Plater.ZonePvpType ~= "sanctuary") then
			scalarValue = SizeOf_healthBar_Width > SizeOf_castBar_Width and -((SizeOf_healthBar_Width - SizeOf_castBar_Width) / 2) or ((SizeOf_castBar_Width - SizeOf_healthBar_Width) / 2)
		else
			--scalarValue = 80 > SizeOf_castBar_Width and -((80 - SizeOf_castBar_Width) / 2) or ((SizeOf_castBar_Width - 80) / 2)
			scalarValue = SizeOf_healthBar_Width > SizeOf_castBar_Width and -((SizeOf_healthBar_Width - SizeOf_castBar_Width) / 2) or ((SizeOf_castBar_Width - SizeOf_healthBar_Width) / 2)
		end

		healthFrame:ClearAllPoints()
		healthFrame:SetPoint ("BOTTOMLEFT", castFrame, "TOPLEFT", scalarValue,  (-SizeOf_healthBar_Height) + (-SizeOf_castBar_Height) - 4);
		healthFrame:SetPoint ("BOTTOMRIGHT", castFrame, "TOPRIGHT", -scalarValue,  (-SizeOf_healthBar_Height) + (-SizeOf_castBar_Height) - 4);
		
		local targetHeight = SizeOf_healthBar_Height / (isMinus and 2 or 1)
		local currentHeight = healthFrame:GetHeight()
		
		if (justAdded or not Plater.db.profile.height_animation) then
			healthFrame:SetHeight (targetHeight)
		else
			if (currentHeight < targetHeight) then
				if (not healthFrame.IsIncreasingHeight) then
					healthFrame.IsDecreasingHeight = nil
					healthFrame.TargetHeight = targetHeight
					healthFrame.ToIncreace = targetHeight - currentHeight
					healthFrame.HAVE_HEIGHT_ANIMATION = "up"
				end
			elseif (currentHeight > targetHeight) then
				if (not healthFrame.IsDecreasingHeight) then
					healthFrame.IsIncreasingHeight = nil
					healthFrame.TargetHeight = targetHeight
					healthFrame.ToDecrease = currentHeight - targetHeight
					healthFrame.HAVE_HEIGHT_ANIMATION = "down"
				end
			end
		end
		
		buffFrame.Point1 = "top"
		buffFrame.Point2 = "bottom"
		buffFrame.Anchor = healthFrame
		buffFrame.X = DB_AURA_X_OFFSET
		buffFrame.Y = -11 + plateConfigs.buff_frame_y_offset + DB_AURA_Y_OFFSET
		
		buffFrame:ClearAllPoints()
		buffFrame:SetPoint (buffFrame.Point1, buffFrame.Anchor, buffFrame.Point2, buffFrame.X, buffFrame.Y)

		--> second aura frame
		if (DB_AURA_SEPARATE_BUFFS) then
			unitFrame.BuffFrame2.X = Plater.db.profile.aura2_x_offset
			unitFrame.BuffFrame2.Y = -11 + plateConfigs.buff_frame_y_offset + Plater.db.profile.aura2_y_offset
			unitFrame.BuffFrame2:ClearAllPoints()
			unitFrame.BuffFrame2:SetPoint (buffFrame.Point1, buffFrame.Anchor, buffFrame.Point2, unitFrame.BuffFrame2.X, unitFrame.BuffFrame2.Y)
		end
		
		--player
		if (plateFrame.isSelf) then
			Plater.UpdateManaAndResourcesBar()
			if (not plateConfigs.healthbar_color_by_hp) then
				Plater.ForceChangeHealthBarColor (healthFrame, unpack (plateConfigs.healthbar_color))
			end
		end
		
	elseif (order == 2) then
		--health, buffs, castbar
		
		local castKey, heathKey, textKey = Plater.GetHashKey (isInCombat)
		local SizeOf_healthBar_Width = plateConfigs [heathKey][1]
		local SizeOf_castBar_Width = plateConfigs [castKey][1]
		local SizeOf_healthBar_Height = plateConfigs [heathKey][2]
		local SizeOf_castBar_Height = plateConfigs [castKey][2]
		local SizeOf_text = plateConfigs [textKey]
		
		local height_offset = 0

		--pegar o tamanho da barra de debuff para colocar a cast bar em cima dela
		local buffFrameSize = Plater.db.profile.aura_height
		
		local scalarValue = SizeOf_castBar_Width > plateWidth and -((SizeOf_castBar_Width - plateWidth) / 2) or ((plateWidth - SizeOf_castBar_Width) / 2)
		if (isMinus) then
			scalarValue = scalarValue + (SizeOf_castBar_Width/5)
		end
		castFrame:SetPoint ("BOTTOMLEFT", unitFrame, "BOTTOMLEFT", scalarValue, buffFrameSize + SizeOf_healthBar_Height + 2 + height_offset);
		castFrame:SetPoint ("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", -scalarValue, buffFrameSize + SizeOf_healthBar_Height + 2 + height_offset);
		castFrame:SetHeight (SizeOf_castBar_Height)
		castFrame.Icon:SetSize (SizeOf_castBar_Height, SizeOf_castBar_Height)
		castFrame.BorderShield:SetSize (SizeOf_castBar_Height*1.4, SizeOf_castBar_Height*1.4)
		
		local scalarValue
		if (Plater.ZonePvpType ~= "sanctuary") then
			scalarValue = SizeOf_healthBar_Width > SizeOf_castBar_Width and -((SizeOf_healthBar_Width - SizeOf_castBar_Width) / 2) or ((SizeOf_castBar_Width - SizeOf_healthBar_Width) / 2)
		else
			scalarValue = 70 > SizeOf_castBar_Width and -((70 - SizeOf_castBar_Width) / 2) or ((SizeOf_castBar_Width - 70) / 2)
		end
		
		healthFrame:ClearAllPoints()
		healthFrame:SetPoint ("BOTTOMLEFT", castFrame, "TOPLEFT", scalarValue,  (-SizeOf_healthBar_Height) + (-SizeOf_castBar_Height) + (-buffFrameSize) - 4);
		healthFrame:SetPoint ("BOTTOMRIGHT", castFrame, "TOPRIGHT", -scalarValue,  (-SizeOf_healthBar_Height) + (-SizeOf_castBar_Height) + (-buffFrameSize) - 4);
		
		local targetHeight = SizeOf_healthBar_Height / (isMinus and 2 or 1)
		local currentHeight = healthFrame:GetHeight()
		
		if (justAdded or not Plater.db.profile.height_animation) then
			healthFrame:SetHeight (targetHeight)
		else
			if (currentHeight < targetHeight) then
				if (not healthFrame.IsIncreasingHeight) then
					healthFrame.IsDecreasingHeight = nil
					healthFrame.TargetHeight = targetHeight
					healthFrame.ToIncreace = targetHeight - currentHeight
					--print ("!", healthFrame.ToIncreace, 2886)
					healthFrame.HAVE_HEIGHT_ANIMATION = "up"
				end
			elseif (currentHeight > targetHeight) then
				if (not healthFrame.IsDecreasingHeight) then
					healthFrame.IsIncreasingHeight = nil
					healthFrame.TargetHeight = targetHeight
					healthFrame.ToDecrease = currentHeight - targetHeight
					healthFrame.HAVE_HEIGHT_ANIMATION = "down"
				end
			end
		end
		
		buffFrame.Point1 = "top"
		buffFrame.Point2 = "bottom"
		buffFrame.Anchor = castFrame
		buffFrame.X = DB_AURA_X_OFFSET
		buffFrame.Y = -1 + plateConfigs.buff_frame_y_offset + DB_AURA_Y_OFFSET
		
		buffFrame:ClearAllPoints()
		buffFrame:SetPoint (buffFrame.Point1, buffFrame.Anchor, buffFrame.Point2, buffFrame.X, buffFrame.Y)
		
		--> second aura frame
		if (DB_AURA_SEPARATE_BUFFS) then
			unitFrame.BuffFrame2.X = Plater.db.profile.aura2_x_offset
			unitFrame.BuffFrame2.Y = -1 + plateConfigs.buff_frame_y_offset + Plater.db.profile.aura2_y_offset
			unitFrame.BuffFrame2:ClearAllPoints()
			unitFrame.BuffFrame2:SetPoint (buffFrame.Point1, buffFrame.Anchor, buffFrame.Point2, unitFrame.BuffFrame2.X, unitFrame.BuffFrame2.Y)
		end
		
		--player
		if (plateFrame.isSelf) then
			Plater.UpdateManaAndResourcesBar()
			if (not plateConfigs.healthbar_color_by_hp) then
				Plater.ForceChangeHealthBarColor (healthFrame, unpack (plateConfigs.healthbar_color))
			end
		end
		
	elseif (order == 3) then --~order
		--castbar, health, buffs
		
		local castKey, heathKey, textKey = Plater.GetHashKey (isInCombat)
		local SizeOf_healthBar_Width = plateConfigs [heathKey][1]
		local SizeOf_castBar_Width = plateConfigs [castKey][1]
		local SizeOf_healthBar_Height = plateConfigs [heathKey][2]
		local SizeOf_castBar_Height = plateConfigs [castKey][2]
		local SizeOf_text = plateConfigs [textKey]
		local buffFrameSize = Plater.db.profile.aura_height
		local height_offset = 0
		
		--> cast bar
			local scalarValue = SizeOf_castBar_Width > plateWidth and -((SizeOf_castBar_Width - plateWidth) / 2) or ((plateWidth - SizeOf_castBar_Width) / 2)
			
			if (unitType == "pet") then
				scalarValue = abs (Plater.db.profile.pet_width_scale - 2) * scalarValue
			elseif (unitType == "minus") then
				scalarValue = abs (Plater.db.profile.minor_width_scale - 2) * scalarValue
			end
			
			castFrame:SetPoint ("BOTTOMLEFT", unitFrame, "BOTTOMLEFT", scalarValue, height_offset) ---SizeOf_healthBar_Height + (-SizeOf_castBar_Height + 2)
			castFrame:SetPoint ("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", -scalarValue, height_offset)
			
			--10/03/2018: cast frame affecting the position of the player health bar when leaving combat
			if (not plateFrame.isSelf) then
				if (unitType == "pet") then
					SizeOf_castBar_Height = SizeOf_castBar_Height * Plater.db.profile.pet_height_scale
					castFrame:SetHeight (SizeOf_castBar_Height)
					
				elseif (unitType == "minus") then
					SizeOf_castBar_Height = SizeOf_castBar_Height * Plater.db.profile.minor_height_scale
					castFrame:SetHeight (SizeOf_castBar_Height)
					
				else
					castFrame:SetHeight (SizeOf_castBar_Height)
				end
			end
			
			castFrame.Icon:SetSize (SizeOf_castBar_Height, SizeOf_castBar_Height)
			castFrame.BorderShield:SetSize (SizeOf_castBar_Height*1.4, SizeOf_castBar_Height*1.4)

		--> health bar
			local scalarValue
			if (plateFrame [MEMBER_REACTION] <= 4) then --> enemy and neutral
				scalarValue = SizeOf_healthBar_Width > SizeOf_castBar_Width and -((SizeOf_healthBar_Width - SizeOf_castBar_Width) / 2) or ((SizeOf_castBar_Width - SizeOf_healthBar_Width) / 2)
			else
				if (plateFrame.isSelf) then
					scalarValue = SizeOf_healthBar_Width > SizeOf_castBar_Width and -((SizeOf_healthBar_Width - SizeOf_castBar_Width) / 2) or ((SizeOf_castBar_Width - SizeOf_healthBar_Width) / 2)
				else
					--> friendly
					scalarValue = SizeOf_healthBar_Width > SizeOf_castBar_Width and -((SizeOf_healthBar_Width - SizeOf_castBar_Width) / 2) or ((SizeOf_castBar_Width - SizeOf_healthBar_Width) / 2)
				end
			end

			--health
			healthFrame:ClearAllPoints()
			healthFrame:SetPoint ("BOTTOMLEFT", castFrame, "TOPLEFT", scalarValue,  1)
			healthFrame:SetPoint ("BOTTOMRIGHT", castFrame, "TOPRIGHT", -scalarValue,  1)
			
			local targetHeight = SizeOf_healthBar_Height
			if (unitType == "pet") then
				targetHeight = targetHeight * Plater.db.profile.pet_height_scale
			elseif (unitType == "minus") then
				targetHeight = targetHeight * Plater.db.profile.minor_height_scale
			end

			local currentHeight = healthFrame:GetHeight()
			
			if (justAdded or not Plater.db.profile.height_animation) then
				healthFrame:SetHeight (targetHeight)
			else
				if (currentHeight < targetHeight) then
					if (not healthFrame.IsIncreasingHeight) then
						healthFrame.IsDecreasingHeight = nil
						healthFrame.TargetHeight = targetHeight
						healthFrame.ToIncreace = targetHeight - currentHeight
						healthFrame.HAVE_HEIGHT_ANIMATION = "up"
					end
				elseif (currentHeight > targetHeight) then
					if (not healthFrame.IsDecreasingHeight) then
						healthFrame.IsIncreasingHeight = nil
						healthFrame.TargetHeight = targetHeight
						healthFrame.ToDecrease = currentHeight - targetHeight
						healthFrame.HAVE_HEIGHT_ANIMATION = "down"
					end
				end
			end
		
		--> buff frame
			buffFrame.Point1 = "bottom"
			buffFrame.Point2 = "top"
			buffFrame.Anchor = healthFrame
			buffFrame.X = DB_AURA_X_OFFSET
			buffFrame.Y = (buffFrameSize / 3) + 1 + plateConfigs.buff_frame_y_offset + DB_AURA_Y_OFFSET
			
			buffFrame:ClearAllPoints()
			buffFrame:SetPoint (buffFrame.Point1, buffFrame.Anchor, buffFrame.Point2, buffFrame.X, buffFrame.Y)
			
			--> second aura frame
			if (DB_AURA_SEPARATE_BUFFS) then
				unitFrame.BuffFrame2.X = Plater.db.profile.aura2_x_offset
				unitFrame.BuffFrame2.Y = (buffFrameSize / 3) + 1 + plateConfigs.buff_frame_y_offset + Plater.db.profile.aura2_y_offset
				unitFrame.BuffFrame2:ClearAllPoints()
				unitFrame.BuffFrame2:SetPoint (buffFrame.Point1, buffFrame.Anchor, buffFrame.Point2, unitFrame.BuffFrame2.X, unitFrame.BuffFrame2.Y)
			end
			
			--personal player bar
			if (plateFrame.isSelf) then
				Plater.UpdateManaAndResourcesBar()
				if (not plateConfigs.healthbar_color_by_hp) then
					Plater.ForceChangeHealthBarColor (healthFrame, unpack (plateConfigs.healthbar_color))
				end
			end
	end
end

function Plater.UpdateManaAndResourcesBar()
	if (not InCombatLockdown()) then
		if (ClassNameplateManaBarFrame) then
			if (ClassNameplateManaBarFrame.Border) then
				ClassNameplateManaBarFrame.Border:Hide()
			end
			if (not ClassNameplateManaBarFrame.SoftShadow) then
				DF:CreateBorderWithSpread (ClassNameplateManaBarFrame, .4, .2, .05, 1, 0.5)
				ClassNameplateManaBarFrame.SoftShadow = true
			end
		end
		NamePlateDriverFrame:SetupClassNameplateBars()
	end
end

function Plater.GetUnitType (plateFrame)
	if (PET_CACHE [plateFrame [MEMBER_GUID]]) then
		return "pet"
		
	elseif (plateFrame [MEMBER_CLASSIFICATION] == "minus") then
		return "minus"
	end
	
	return "normal"
end

-- ~color
function Plater.ForceChangeHealthBarColor (healthBar, r, g, b, forceNoLerp)
	--if (r ~= healthBar.R or g ~= healthBar.G or b ~= healthBar.B) then
		healthBar.R, healthBar.G, healthBar.B = r, g, b
		if (not DB_LERP_COLOR or forceNoLerp) then -- ~lerpcolor
			healthBar.barTexture:SetVertexColor (r, g, b)
		end
	--end
end

--[=[
v7.3.5.072
function Plater.ForceChangeHealthBarColor (healthBar, r, g, b)
	if (r ~= healthBar.R or g ~= healthBar.G or b ~= healthBar.B) then
		--healthBar.r, healthBar.g, healthBar.b = r, g, b
		healthBar.R, healthBar.G, healthBar.B = r, g, b
		healthBar.barTexture:SetVertexColor (r, g, b)
	end
end

r43-release
function Plater.ForceChangeHealthBarColor (healthBar, r, g, b)
	if (r ~= healthBar.r or g ~= healthBar.g or b ~= healthBar.b) then
		healthBar.r, healthBar.g, healthBar.b = r, g, b
		healthBar.barTexture:SetVertexColor (r, g, b)
	end
end
--]=]

--test if still tainted... nop still taited
--healthBar.r = r
--healthBar.g = g
--healthBar.b = b
--healthBar:SetStatusBarColor (r, g, b)

--plater ~API �pi

function Plater.CreateIconGlow (frame, color)
	local f = Plater:CreateGlowOverlay (frame, color, color)
	return f
end

function Plater.CreateNameplateGlow (frame, color, left, right, top, bottom)
	local antTable = {
		Throttle = 0.025,
		AmountParts = 15,
		TexturePartsWidth = 167.4,
		TexturePartsHeight = 83.6,
		TextureWidth = 512,
		TextureHeight = 512,
		BlendMode = "ADD",
		Color = color,
		Texture = [[Interface\AddOns\Plater\images\ants_rectangle]],
	}

	--> ants
	local f = DF:CreateAnts (frame, antTable, -27 + (left or 0), 25 + (right or 0), 5 + (top or 0), -7 + (bottom or 0))
	f:SetFrameLevel (frame:GetFrameLevel() + 1)
	f:SetAlpha (ALPHA_BLEND_AMOUNT - 0.249845)
	
	--> glow
	local glow = f:CreateTexture (nil, "background")
	glow:SetTexture ([[Interface\AddOns\Plater\images\nameplate_glow]])
	glow:SetPoint ("center", frame, "center", 0, 0)
	glow:SetSize (frame:GetWidth() + frame:GetWidth()/2.3, 36)
	glow:SetBlendMode ("ADD")
	glow:SetVertexColor (DF:ParseColors (color or "white"))
	glow:SetAlpha (ALPHA_BLEND_AMOUNT)
	glow.GlowTexture = glow
	
	return f
end

function Plater.OnPlayCustomFlashAnimation (animationHub)
	animationHub:GetParent():Show()
	animationHub.Texture:Show()
	--animationHub.Texture:Show()
end
function Plater.OnStopCustomFlashAnimation (animationHub)
	animationHub:GetParent():Hide()
	animationHub.Texture:Hide()
end
function Plater.UpdateCustomFlashAnimation (animationHub, duration, r, g, b)
	for i = 1, #animationHub.AllAnimations do
		if (duration) then
			animationHub.AllAnimations [i]:SetDuration (duration)
		end
		if (r) then
			r, g, b = DF:ParseColors (r, g, b)
			animationHub.Texture:SetColorTexture (r, g, b)
		end
	end
end

function Plater.CreateFlash (frame, duration, amount, r, g, b)
	--defaults
	duration = duration or 0.25
	amount = amount or 1
	
	if (not r) then
		r, g, b = 1, 1, 1
	else
		r, g, b = DF:ParseColors (r, g, b)
	end

	--create the flash frame
	local f = CreateFrame ("frame", "PlaterFlashAnimationFrame".. math.random (1, 100000000), frame)
	f:SetFrameLevel (frame:GetFrameLevel()+1)
	f:SetAllPoints()
	f:Hide()
	
	--create the flash texture
	local t = f:CreateTexture ("PlaterFlashAnimationTexture".. math.random (1, 100000000), "artwork")
	t:SetColorTexture (r, g, b)
	t:SetAllPoints()
	t:SetBlendMode ("ADD")
	t:Hide()
	
	--create the flash animation
	local animationHub = DF:CreateAnimationHub (f, Plater.OnPlayCustomFlashAnimation, Plater.OnStopCustomFlashAnimation)
	animationHub.AllAnimations = {}
	animationHub.Parent = f
	animationHub.Texture = t
	animationHub.Amount = amount
	animationHub.UpdateDurationAndColor = Plater.UpdateCustomFlashAnimation
	
	for i = 1, amount * 2, 2 do
		local fadeIn = DF:CreateAnimation (animationHub, "ALPHA", i, duration, 0, 1)
		local fadeOut = DF:CreateAnimation (animationHub, "ALPHA", i + 1, duration, 1, 0)
		tinsert (animationHub.AllAnimations, fadeIn)
		tinsert (animationHub.AllAnimations, fadeOut)
	end
	
	return animationHub
end

function Plater.RefreshNameplateColor (unitFrame)
	if (unitFrame.unit) then
		if (IsTapDenied (unitFrame.unit)) then
			Plater.ForceChangeHealthBarColor (unitFrame.healthBar, unpack (Plater.db.profile.tap_denied_color))
		else
			if (InCombatLockdown()) then
				if (unitFrame:GetParent() [MEMBER_REACTION] <= 4) then
					Plater.UpdateNameplateThread (unitFrame)
				else
					CompactUnitFrame_UpdateHealthColor (unitFrame)
				end
			else
				CompactUnitFrame_UpdateHealthColor (unitFrame)
			end
		end
	end
end

function Plater.SetNameplateColor (unitFrame, r, g, b)
	if (unitFrame.unit) then
		if (not r) then
			Plater.RefreshNameplateColor (unitFrame)
		else
			r, g, b = DF:ParseColors (r, g, b)
			return Plater.ForceChangeHealthBarColor (unitFrame.healthBar, r, g, b)
		end
	end
end

function Plater.FlashNameplateBorder (unitFrame, duration)
	if (not unitFrame.healthBar.PlayHealthFlash) then
		Plater.CreateHealthFlashFrame (unitFrame:GetParent())
	end
	unitFrame.healthBar.canHealthFlash = true
	unitFrame.healthBar.PlayHealthFlash (duration)
end

function Plater.FlashNameplateBody (unitFrame, text, duration)
	unitFrame:GetParent().PlayBodyFlash (text, duration)
end

--return if the player is in combat
function Plater.IsInCombat()
	return InCombatLockdown() or PLAYER_IN_COMBAT
end

--check the role and the role of the specialization to return if the player is in a tank role
function Plater.IsPlayerTank()
	return IsPlayerEffectivelyTank()
end

function Plater.SetCastBarBorderColor (castBar, r, g, b, a)
	--check if the frame passed was the unitFrame instead of the castbar it self
	if (castBar.castBar) then
		castBar = castBar.castBar
	end
	
	r, g, b, a = DF:ParseColors (r, g, b, a)
	castBar.FrameOverlay:SetBackdropBorderColor (r, g, b, a)
end

function Plater.ShowHealthBar (unitFrame)
	unitFrame.healthBar:Show()
	unitFrame.BuffFrame:Show()
	unitFrame.BuffFrame2:Show()
	unitFrame.healthBar.actorName:Show()
	
	unitFrame:GetParent().IsFriendlyPlayerWithoutHealthBar = false
	
	unitFrame.ActorNameSpecial:Hide()
	unitFrame.ActorTitleSpecial:Hide()
end

function Plater.HideHealthBar (unitFrame, showPlayerName, showNameNpc)
	unitFrame.healthBar:Hide()
	unitFrame.BuffFrame:Hide()
	unitFrame.BuffFrame2:Hide()
	unitFrame.healthBar.actorName:Hide()
	
	unitFrame:GetParent().IsFriendlyPlayerWithoutHealthBar = showPlayerName
	unitFrame:GetParent().IsNpcWithoutHealthBar = showNameNpc
	
	if (showPlayerName) then
		Plater.UpdatePlateText (unitFrame:GetParent(), DB_PLATE_CONFIG [ACTORTYPE_FRIENDLY_PLAYER], false)
		
	elseif (showNameNpc) then
		Plater.UpdatePlateText (unitFrame:GetParent(), DB_PLATE_CONFIG [ACTORTYPE_ENEMY_NPC], false)
	end
end

--check the setting 'only_damaged' and 'only_thename' for player characters. not critical code, can run slow
function Plater.ParseHealthSettingForPlayer (plateFrame)

	plateFrame.IsFriendlyPlayerWithoutHealthBar = false

	if (DB_PLATE_CONFIG [ACTORTYPE_FRIENDLY_PLAYER].only_damaged) then
		if (UnitHealth (plateFrame [MEMBER_UNITID]) < UnitHealthMax (plateFrame [MEMBER_UNITID])) then
			Plater.ShowHealthBar (plateFrame.UnitFrame)
		else
			Plater.HideHealthBar (plateFrame.UnitFrame)
			
			if (DB_PLATE_CONFIG [ACTORTYPE_FRIENDLY_PLAYER].only_thename) then
				plateFrame.IsFriendlyPlayerWithoutHealthBar = true
			end
		end
		
	elseif (DB_PLATE_CONFIG [ACTORTYPE_FRIENDLY_PLAYER].only_thename) then
		Plater.HideHealthBar (plateFrame.UnitFrame)
		plateFrame.IsFriendlyPlayerWithoutHealthBar = true
		
	else
		Plater.ShowHealthBar (plateFrame.UnitFrame)
	end
end

-- ~update
function Plater.UpdatePlateFrame (plateFrame, actorType, forceUpdate, justAdded)
	actorType = actorType or plateFrame.actorType
	
	local order = DB_PLATE_CONFIG [actorType].plate_order
	
	local unitFrame = plateFrame.UnitFrame --setallpoints
	local healthFrame = unitFrame.healthBar
	local castFrame = unitFrame.castBar
	local buffFrame = unitFrame.BuffFrame
	local nameFrame = unitFrame.healthBar.actorName
	
	plateFrame.actorType = actorType
	plateFrame.order = order
	
	local shouldForceRefresh = false
	if (plateFrame.IsNpcWithoutHealthBar or plateFrame.IsFriendlyPlayerWithoutHealthBar) then
		shouldForceRefresh = true
		plateFrame.IsNpcWithoutHealthBar = false
		plateFrame.IsFriendlyPlayerWithoutHealthBar = false
	end

	healthFrame.BorderIsAggroIndicator = nil
	
	local wasQuestPlate = plateFrame [MEMBER_QUEST]
	plateFrame [MEMBER_QUEST] = false
	
	plateFrame.ActorNameSpecial:Hide()
	plateFrame.ActorTitleSpecial:Hide()
	plateFrame.Top3DFrame:Hide()
	plateFrame.RaidTarget:Hide()
	
	--clear aggro glow
	unitFrame.aggroGlowUpper:Hide()
	unitFrame.aggroGlowLower:Hide()
	
	--check for quest color
	if (IS_IN_OPEN_WORLD and actorType == ACTORTYPE_ENEMY_NPC and DB_PLATE_CONFIG [actorType].quest_enabled) then --actorType == ACTORTYPE_FRIENDLY_NPC or 
		local isQuestMob = Plater.IsQuestObjective (plateFrame)
		if (isQuestMob and not IsTapDenied (plateFrame.UnitFrame.unit)) then
			if (plateFrame [MEMBER_REACTION] == UNITREACTION_NEUTRAL) then
				Plater.ForceChangeHealthBarColor (healthFrame, unpack (DB_PLATE_CONFIG [actorType].quest_color_neutral))
				plateFrame [MEMBER_QUEST] = true
			else
				Plater.ForceChangeHealthBarColor (healthFrame, unpack (DB_PLATE_CONFIG [actorType].quest_color_enemy))
				plateFrame [MEMBER_QUEST] = true
			end
		else
			if (wasQuestPlate) then
				CompactUnitFrame_UpdateHealthColor (unitFrame)
			end
		end
	else
		if (wasQuestPlate) then
			CompactUnitFrame_UpdateHealthColor (unitFrame)
		end
	end
	
	--se a plate for de npc amigo
	if (actorType == ACTORTYPE_FRIENDLY_NPC) then
	
		if (IS_IN_OPEN_WORLD and DB_PLATE_CONFIG [actorType].quest_enabled and Plater.IsQuestObjective (plateFrame)) then
			Plater.ForceChangeHealthBarColor (healthFrame, unpack (DB_PLATE_CONFIG [actorType].quest_color))

			healthFrame:Show()
			buffFrame:Show()
			nameFrame:Show()
			
			plateFrame [MEMBER_QUEST] = true
		
		elseif (DB_PLATE_CONFIG [actorType].only_names or DB_PLATE_CONFIG [actorType].all_names) then
			--show only the npc name without the health bar

			healthFrame:Hide()
			buffFrame:Hide()
			nameFrame:Hide()
			plateFrame.IsNpcWithoutHealthBar = true
			
		else
			healthFrame:Show()
			buffFrame:Show()
			nameFrame:Show()

		end

	elseif (actorType == ACTORTYPE_FRIENDLY_PLAYER) then
		Plater.ParseHealthSettingForPlayer (plateFrame)
		
		if (not plateFrame.IsFriendlyPlayerWithoutHealthBar) then
			--change the player health bar color (no class color uses hardcoded white color)
			if (not Plater.db.profile.use_playerclass_color) then
				Plater.ForceChangeHealthBarColor (healthFrame, 1, 1, 1)
			else
				local _, class = UnitClass (plateFrame [MEMBER_UNITID])
				if (class) then		
					local color = RAID_CLASS_COLORS [class]
					Plater.ForceChangeHealthBarColor (healthFrame, color.r, color.g, color.b)
				else
					Plater.ForceChangeHealthBarColor (healthFrame, 1, 1, 1)
				end
			end
		end
		
	else
		--> enemy npc or enemy player pass throught here
		--check if this is an enemy npc but the player cannot attack it
		if (plateFrame.PlayerCannotAttack) then
			healthFrame:Hide()
			buffFrame:Hide()
			nameFrame:Hide()
			plateFrame.IsNpcWithoutHealthBar = true
			
		else
			healthFrame:Show()
			buffFrame:Show()
			nameFrame:Show()
			
			--> check for enemy player class color
			if (actorType == ACTORTYPE_ENEMY_PLAYER) then
				if (DB_PLATE_CONFIG [actorType].use_playerclass_color) then
					local _, class = UnitClass (plateFrame [MEMBER_UNITID])
					if (class) then		
						local color = RAID_CLASS_COLORS [class]
						Plater.ForceChangeHealthBarColor (healthFrame, color.r, color.g, color.b)
					else
						Plater.ForceChangeHealthBarColor (healthFrame, unpack (DB_PLATE_CONFIG [actorType].fixed_class_color))
					end
				else
					Plater.ForceChangeHealthBarColor (healthFrame, unpack (DB_PLATE_CONFIG [actorType].fixed_class_color))
				end
			end
		end

	end
	
	buffFrame:ClearAllPoints()
	nameFrame:ClearAllPoints()
	
	castFrame:SetStatusBarTexture (DB_TEXTURE_CASTBAR)
	
	--update all texts in the nameplate
	Plater.UpdatePlateText (plateFrame, DB_PLATE_CONFIG [actorType], shouldForceRefresh or plateFrame.PreviousUnitType ~= actorType or unitFrame.RefreshID < PLATER_REFRESH_ID)

	if (unitFrame.RefreshID < PLATER_REFRESH_ID) then
		unitFrame.RefreshID = PLATER_REFRESH_ID

		--update highlight texture
		unitFrame.HighlightFrame.HighlightTexture:SetTexture (DB_TEXTURE_HEALTHBAR)
		unitFrame.HighlightFrame.HighlightTexture:SetBlendMode ("ADD")
		unitFrame.HighlightFrame.HighlightTexture:SetAlpha (Plater.db.profile.hover_highlight_alpha)
		
		--click area is shown?
		if (Plater.db.profile.click_space_always_show) then
			Plater.SetPlateBackground (plateFrame)
		else
			plateFrame:SetBackdrop (nil)
		end
		
		--setup the cast bar
		castFrame.background:SetTexture (DB_TEXTURE_CASTBAR_BG)
		castFrame.background:SetVertexColor (unpack (Plater.db.profile.cast_statusbar_bgcolor))
		castFrame.Flash:SetTexture (DB_TEXTURE_CASTBAR)
		castFrame.Icon:SetTexCoord (0.078125, 0.921875, 0.078125, 0.921875)
		
		--setup the health bar
		healthFrame.barTexture:SetTexture (DB_TEXTURE_HEALTHBAR)
		healthFrame.background:SetTexture (DB_TEXTURE_HEALTHBAR_BG)
		healthFrame.background:SetVertexColor (unpack (Plater.db.profile.health_statusbar_bgcolor))

		--update the energy bar on the personal bar
		ClassNameplateManaBarFrame.Texture:SetTexture (DB_TEXTURE_HEALTHBAR)
		
		--update border
		Plater.UpdatePlateBorders (plateFrame)
	end
	
	if (unitFrame.selectionHighlight:IsShown()) then
		local targetedOverlayTexture = LibSharedMedia:Fetch ("statusbar", Plater.db.profile.health_selection_overlay)
		unitFrame.selectionHighlight:SetTexture (targetedOverlayTexture)
	end
	
	--update the plate size for this unit
	Plater.UpdatePlateSize (plateFrame, justAdded)
	
	--raid marker
	Plater.UpdatePlateRaidMarker (plateFrame)
	
	--indicators for the unit
	Plater.UpdateIndicators (plateFrame, actorType)
	
	--aura container
	Plater.UpdateBuffContainer (plateFrame)
	
	--target indicator
	Plater.UpdateTarget (plateFrame)
	
	--update the frame level
	if (DB_UPDATE_FRAMELEVEL) then
		if (Plater.db.profile.healthbar_framelevel ~= 0) then
			healthFrame:SetFrameLevel (healthFrame.DefaultFrameLevel + Plater.db.profile.healthbar_framelevel)
		end
		if (Plater.db.profile.castbar_framelevel ~= 0) then
			castFrame:SetFrameLevel (castFrame.DefaultFrameLevel + Plater.db.profile.castbar_framelevel)
		end
	end
	
	--update options in the extra icons row frame
	if (unitFrame.ExtraIconFrame.RefreshID < PLATER_REFRESH_ID) then
		Plater.SetAnchor (unitFrame.ExtraIconFrame, Plater.db.profile.extra_icon_anchor)
		unitFrame.ExtraIconFrame:SetOption ("show_text", Plater.db.profile.extra_icon_show_timer)
		unitFrame.ExtraIconFrame:SetOption ("grow_direction", unitFrame.ExtraIconFrame:GetIconGrowDirection())
		unitFrame.ExtraIconFrame:SetOption ("icon_width", Plater.db.profile.extra_icon_width)
		unitFrame.ExtraIconFrame:SetOption ("icon_height", Plater.db.profile.extra_icon_height)
		unitFrame.ExtraIconFrame:SetOption ("texcoord", Plater.db.profile.extra_icon_wide_icon and Plater.WideIconCoords or Plater.BorderLessIconCoords)
		unitFrame.ExtraIconFrame:SetOption ("desc_text", Plater.db.profile.extra_icon_caster_name)
		
		--> update refresh ID
		unitFrame.ExtraIconFrame.RefreshID = PLATER_REFRESH_ID
	end
	
	--> details! integration
	if (IS_USING_DETAILS_INTEGRATION) then
		local detailsPlaterConfig = Details.plater

		if (detailsPlaterConfig.realtime_dps_enabled) then
			local textString = healthFrame.DetailsRealTime
			Plater.SetAnchor (textString, detailsPlaterConfig.realtime_dps_anchor)
			DF:SetFontSize (textString, detailsPlaterConfig.realtime_dps_size)
			DF:SetFontOutline (textString, detailsPlaterConfig.realtime_dps_shadow)
			DF:SetFontColor (textString, detailsPlaterConfig.realtime_dps_color)
		end
		
		if (detailsPlaterConfig.realtime_dps_player_enabled) then
			local textString = healthFrame.DetailsRealTimeFromPlayer
			Plater.SetAnchor (textString, detailsPlaterConfig.realtime_dps_player_anchor)
			DF:SetFontSize (textString, detailsPlaterConfig.realtime_dps_player_size)
			DF:SetFontOutline (textString, detailsPlaterConfig.realtime_dps_player_shadow)
			DF:SetFontColor (textString, detailsPlaterConfig.realtime_dps_player_color)
		end
		
		if (detailsPlaterConfig.damage_taken_enabled) then
			local textString = healthFrame.DetailsDamageTaken
			Plater.SetAnchor (textString, detailsPlaterConfig.damage_taken_anchor)
			DF:SetFontSize (textString, detailsPlaterConfig.damage_taken_size)
			DF:SetFontOutline (textString, detailsPlaterConfig.damage_taken_shadow)
			DF:SetFontColor (textString, detailsPlaterConfig.damage_taken_color)
		end
		
		--reset all labels used by details!
		healthFrame.DetailsRealTime:SetText ("")
		healthFrame.DetailsRealTimeFromPlayer:SetText ("")
		healthFrame.DetailsDamageTaken:SetText ("")
	end
end

-- ~indicators
function Plater.UpdateIndicators (plateFrame, actorType)
	--limpa os indicadores
	Plater.ClearIndicators (plateFrame)
	local config = Plater.db.profile
	
	if (actorType == ACTORTYPE_ENEMY_PLAYER) then
		if (config.indicator_faction) then
			Plater.AddIndicator (plateFrame, UnitFactionGroup (plateFrame [MEMBER_UNITID]))
		end
		if (config.indicator_enemyclass) then
			Plater.AddIndicator (plateFrame, "classicon")
		end
		if (config.indicator_spec) then 
			--> check if the user is using details
			if (Details and Details.realversion >= 134) then
				local spec = Details:GetSpecByGUID (plateFrame [MEMBER_GUID])
				if (spec) then
					local texture, L, R, T, B = Details:GetSpecIcon (spec)
					Plater.AddIndicator (plateFrame, "specicon", texture, L, R, T, B)
				end
			end
		end
		
	elseif (actorType == ACTORTYPE_ENEMY_NPC) then
	
		--is a pet
		if (PET_CACHE [plateFrame [MEMBER_GUID]]) then
			Plater.AddIndicator (plateFrame, "pet")
		end

		--classification
		local unitClassification = UnitClassification (plateFrame.namePlateUnitToken) --elite minus normal rare rareelite worldboss
		if (unitClassification == "worldboss") then
			Plater.AddIndicator (plateFrame, "worldboss")
			
		elseif (unitClassification == "rareelite" and (config.indicator_rare or config.indicator_elite)) then
			Plater.AddIndicator (plateFrame, "elite")
			Plater.AddIndicator (plateFrame, "rare")
		else
			if (unitClassification == "elite" and config.indicator_elite) then
				Plater.AddIndicator (plateFrame, "elite")
			end
			if (unitClassification == "rare" and config.indicator_rare) then
				Plater.AddIndicator (plateFrame, "rare")
			end
		end
		
		--quest boss
		local isQuestBoss = UnitIsQuestBoss (plateFrame.namePlateUnitToken) --true false
		if (isQuestBoss and config.indicator_quest) then
			Plater.AddIndicator (plateFrame, "quest")
		end
	
	elseif (actorType == ACTORTYPE_FRIENDLY_NPC) then
		if (plateFrame [MEMBER_QUEST]) then
			Plater.AddIndicator (plateFrame, "quest")
		end
	end
end

function Plater.AddIndicator (plateFrame, indicator, ...)

	local thisIndicator = plateFrame.IconIndicators [plateFrame.IconIndicators.Next]
	
	if (not thisIndicator) then
		local newIndicator = plateFrame.UnitFrame.healthBar:CreateTexture (nil, "overlay")
		newIndicator:SetSize (10, 10)
		tinsert (plateFrame.IconIndicators, newIndicator)
		thisIndicator = newIndicator
	end

	thisIndicator:Show()
	thisIndicator:SetTexCoord (0, 1, 0, 1)
	thisIndicator:SetVertexColor (1, 1, 1)
	thisIndicator:SetDesaturated (false)
	thisIndicator:SetSize (10, 10)
	
	--esconde o icone default do jogo
	plateFrame.UnitFrame.ClassificationFrame:Hide()
	
	-- ~icons
	if (indicator == "pet") then
		thisIndicator:SetTexture ([[Interface\AddOns\Plater\images\peticon]])
		
	elseif (indicator == "Horde") then
		thisIndicator:SetTexture ([[Interface\PVPFrame\PVP-Currency-Horde]])
		thisIndicator:SetSize (12, 12)

	elseif (indicator == "Alliance") then
		thisIndicator:SetTexture ([[Interface\PVPFrame\PVP-Currency-Alliance]])
		thisIndicator:SetTexCoord (4/32, 29/32, 2/32, 30/32)
		thisIndicator:SetSize (12, 12)
		
	elseif (indicator == "elite") then
		thisIndicator:SetTexture ([[Interface\GLUES\CharacterSelect\Glues-AddOn-Icons]])
		thisIndicator:SetTexCoord (0.75, 1, 0, 1)
		thisIndicator:SetVertexColor (1, .8, 0)
		thisIndicator:SetSize (12, 12)
		
	elseif (indicator == "rare") then
		thisIndicator:SetTexture ([[Interface\GLUES\CharacterSelect\Glues-AddOn-Icons]])
		thisIndicator:SetTexCoord (0.75, 1, 0, 1)
		thisIndicator:SetSize (12, 12)
		thisIndicator:SetDesaturated (true)
		
	elseif (indicator == "quest") then
		thisIndicator:SetTexture ([[Interface\TARGETINGFRAME\PortraitQuestBadge]])
		thisIndicator:SetTexCoord (2/32, 26/32, 1/32, 31/32)
		
	elseif (indicator == "classicon") then
		local _, class = UnitClass (plateFrame [MEMBER_UNITID])
		if (class) then
			thisIndicator:SetTexture ([[Interface\GLUES\CHARACTERCREATE\UI-CharacterCreate-Classes]])
			thisIndicator:SetTexCoord (unpack (CLASS_ICON_TCOORDS [class]))
		end
	
	elseif (indicator == "specicon") then
		local texture, L, R, T, B = ...
		thisIndicator:SetTexture (texture)
		thisIndicator:SetTexCoord (L, R, T, B)
	
	elseif (indicator == "worldboss") then
		thisIndicator:SetTexture ([[Interface\Scenarios\ScenarioIcon-Boss]])
		
	end
	
	if (plateFrame.IconIndicators.Next == 1) then
		Plater.SetAnchor (thisIndicator, Plater.db.profile.indicator_anchor)
	else
		local attachTo = plateFrame.IconIndicators [plateFrame.IconIndicators.Next - 1]
		--se for menor que 4 ele deve crescer para o lado da esquerda, nos outros casos vai para a direita
		if (Plater.db.profile.indicator_anchor.side < 4) then
			thisIndicator:SetPoint ("right", attachTo, "left", -2, 0)
		else
			thisIndicator:SetPoint ("left", attachTo, "right", 1, 0)
		end
	end
	
	plateFrame.IconIndicators.Next = plateFrame.IconIndicators.Next + 1
end

function Plater.ClearIndicators (plateFrame)
	for _, indicator in ipairs (plateFrame.IconIndicators) do
		indicator:Hide()
		indicator:ClearAllPoints()
	end
	plateFrame.IconIndicators.Next = 1
end

function Plater.ForceChangeBorderColor (self, r, g, b) --self = healthBar
	self:SetBorderColor (r, g, b)
	self.BorderIsAggroIndicator = true
end

-- ~border
function Plater.UpdatePlateBorders (plateFrame)
	--bordas
	if (not plateFrame) then
		for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
			Plater.UpdatePlateBorders (plateFrame)
		end
		return
	end
	
	if (plateFrame.UnitFrame.healthBar.BorderIsAggroIndicator) then
		return
	end
	
	for index, texture in ipairs (plateFrame.UnitFrame.healthBar.border.Textures) do
		texture:Hide()
	end
	
	plateFrame.UnitFrame.healthBar:SetBorderAlpha (DB_BORDER_COLOR_A, DB_BORDER_COLOR_A/3, DB_BORDER_COLOR_A/6)
	plateFrame.UnitFrame.healthBar:SetBorderColor (DB_BORDER_COLOR_R, DB_BORDER_COLOR_G, DB_BORDER_COLOR_B)
	
	Plater.UpdatePlateBorderThickness (plateFrame)
end

function Plater.UpdatePlateBorderThickness (plateFrame)
	if (not plateFrame) then
		for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
			Plater.UpdatePlateBorderThickness (plateFrame)
		end
		return
	end
	
	plateFrame.UnitFrame.healthBar:SetLayerVisibility (true, DB_BORDER_THICKNESS >= 2, DB_BORDER_THICKNESS >= 3)
end

function Plater.GetPlateAlpha (plateFrame)
	if (UnitIsUnit (plateFrame [MEMBER_UNITID], "target")) then
		return 1
	else
		return AlphaBlending
	end
end

-- ~range

--this function is exposed to scripting and hooks
--it forces the range check regardless of the user options and only changes the member_range flag, no alpha changes
function Plater.NameplateInRange (unitFrame)
	if (Plater.SpellBookForRangeCheck) then
		if (IsSpellInRange (Plater.SpellForRangeCheck, Plater.SpellBookForRangeCheck, unitFrame [MEMBER_UNITID]) == 1) then
			unitFrame [MEMBER_RANGE] = true
			return true
		else
			unitFrame [MEMBER_RANGE] = false
			return false
		end
	else
		if (IsSpellInRange (Plater.SpellForRangeCheck, unitFrame [MEMBER_UNITID]) == 1) then
			unitFrame [MEMBER_RANGE] = true
			return true
		else
			unitFrame [MEMBER_RANGE] = false
			return false
		end
	end
end

--internal range check, do all the regular stuff
function Plater.CheckRange (plateFrame, onAdded)

	if (plateFrame [MEMBER_NOCOMBAT]) then
		return
		
	elseif (not DB_USE_RANGE_CHECK or plateFrame [MEMBER_REACTION] >= 5) then
		plateFrame.UnitFrame:SetAlpha (AlphaBlending)
		plateFrame [MEMBER_ALPHA] = AlphaBlending
		plateFrame [MEMBER_RANGE] = true
		plateFrame.UnitFrame [MEMBER_RANGE] = true
		return
	end
	
	if (onAdded) then
		--range check when the nameplate is added
	
		--debug
		--demon hunter Torment isn't working for range check
		--print (Plater.SpellForRangeCheck, IsSpellInRange (Plater.SpellForRangeCheck, plateFrame [MEMBER_UNITID]), plateFrame [MEMBER_UNITID])
		--IsSpellInRange (FindSpellBookSlotBySpellID (185245), "spell", plateFrame [MEMBER_UNITID]) 
		--if (IsSpellInRange (FindSpellBookSlotBySpellID (185245), "spell", plateFrame [MEMBER_UNITID]) == 1) then
		
		if (Plater.SpellBookForRangeCheck) then
			if (IsSpellInRange (Plater.SpellForRangeCheck, Plater.SpellBookForRangeCheck, plateFrame [MEMBER_UNITID]) == 1) then
				plateFrame.FadedIn = true
				local alpha = Plater.GetPlateAlpha (plateFrame)
				plateFrame.UnitFrame:SetAlpha (alpha)
				plateFrame [MEMBER_ALPHA] = alpha
				plateFrame [MEMBER_RANGE] = true
				plateFrame.UnitFrame [MEMBER_RANGE] = true
			else
				plateFrame.FadedIn = nil
				local alpha = Plater.db.profile.range_check_alpha
				plateFrame.UnitFrame:SetAlpha (alpha)
				plateFrame [MEMBER_ALPHA] = alpha
				plateFrame [MEMBER_RANGE] = false
				plateFrame.UnitFrame [MEMBER_RANGE] = false
			end
		else
			if (IsSpellInRange (Plater.SpellForRangeCheck, plateFrame [MEMBER_UNITID]) == 1) then
				plateFrame.FadedIn = true
				local alpha = Plater.GetPlateAlpha (plateFrame)
				plateFrame.UnitFrame:SetAlpha (alpha)
				plateFrame [MEMBER_ALPHA] = alpha
				plateFrame [MEMBER_RANGE] = true
				plateFrame.UnitFrame [MEMBER_RANGE] = true
			else
				plateFrame.FadedIn = nil
				local alpha = Plater.db.profile.range_check_alpha
				plateFrame.UnitFrame:SetAlpha (alpha)
				plateFrame [MEMBER_ALPHA] = alpha
				plateFrame [MEMBER_RANGE] = false
				plateFrame.UnitFrame [MEMBER_RANGE] = false
			end
		end
	else
		--test performance with druid guardian
		--/run local f=CreateFrame("frame") f.Run=1 f:SetScript("OnUpdate", function(_,t) if (f.Run) then for i = 1, 1000000 do IsSpellInRange(25,"SPELL","target") end f.Run=nil else f:SetScript("OnUpdate",nil);print(t) end end)
		--/run local f=CreateFrame("frame") f.Run=1 f:SetScript("OnUpdate", function(_,t) if (f.Run) then for i = 1, 1000000 do IsSpellInRange("Growl","target") end f.Run=nil else f:SetScript("OnUpdate",nil);print(t) end end)

		--regular range check during throttled tick
		if (Plater.SpellBookForRangeCheck) then
			if (IsSpellInRange (Plater.SpellForRangeCheck, Plater.SpellBookForRangeCheck, plateFrame [MEMBER_UNITID]) == 1) then
				if (not plateFrame.FadedIn and not plateFrame.UnitFrame.FadeIn.playing) then
					plateFrame:RangeFadeIn()
				end
			else
				if (plateFrame.FadedIn and not plateFrame.UnitFrame.FadeOut.playing) then
					plateFrame:RangeFadeOut()
				end
			end
		else
			if (IsSpellInRange (Plater.SpellForRangeCheck, plateFrame [MEMBER_UNITID]) == 1) then
				if (not plateFrame.FadedIn and not plateFrame.UnitFrame.FadeIn.playing) then
					plateFrame:RangeFadeIn()
				end
			else
				if (plateFrame.FadedIn and not plateFrame.UnitFrame.FadeOut.playing) then
					plateFrame:RangeFadeOut()
				end
			end
		end
	end
end

local on_fade_in_play = function (animation)
	animation.playing = true
end
local on_fade_out_play = function (animation)
	animation.playing = true
end
local on_fade_in_finished = function (animation)
	animation.playing = nil
	animation:GetParent():GetParent().FadedIn = true
	animation:GetParent():SetAlpha (AlphaBlending)
	animation:GetParent():GetParent() [MEMBER_ALPHA] = AlphaBlending
end
local on_fade_out_finished = function (animation)
	animation.playing = nil
	animation:GetParent():GetParent().FadedIn = false
	local alpha = Plater.db.profile.range_check_alpha
	animation:GetParent():SetAlpha (alpha)
	animation:GetParent():GetParent() [MEMBER_ALPHA] = alpha
end
local plate_fade_in = function (plateFrame)
	plateFrame.UnitFrame.FadeIn.Animation:SetFromAlpha (plateFrame.UnitFrame:GetAlpha())
	plateFrame.UnitFrame.FadeIn.Animation:SetToAlpha (AlphaBlending)
	plateFrame.UnitFrame.FadeIn:Play()
end
local plate_fade_out = function (plateFrame)
	plateFrame.UnitFrame.FadeOut.Animation:SetFromAlpha (plateFrame.UnitFrame:GetAlpha())
	plateFrame.UnitFrame.FadeOut.Animation:SetToAlpha (Plater.db.profile.range_check_alpha)
	plateFrame.UnitFrame.FadeOut:Play()
end
local create_alpha_animations = function (plateFrame)
	local unitFrame = plateFrame.UnitFrame
	
	unitFrame.FadeIn = plateFrame.UnitFrame:CreateAnimationGroup()
	unitFrame.FadeOut = plateFrame.UnitFrame:CreateAnimationGroup()
	
	unitFrame.FadeIn:SetScript ("OnPlay", on_fade_in_play)
	unitFrame.FadeOut:SetScript ("OnPlay", on_fade_out_play)
	unitFrame.FadeIn:SetScript ("OnFinished", on_fade_in_finished)
	unitFrame.FadeOut:SetScript ("OnFinished", on_fade_out_finished)
	
	unitFrame.FadeIn.Animation = unitFrame.FadeIn:CreateAnimation ("Alpha")
	unitFrame.FadeOut.Animation = unitFrame.FadeOut:CreateAnimation ("Alpha")
	
	unitFrame.FadeIn.Animation:SetOrder (1)
	unitFrame.FadeOut.Animation:SetOrder (1)
	unitFrame.FadeIn.Animation:SetDuration (0.2)
	unitFrame.FadeOut.Animation:SetDuration (0.2)
	
	plateFrame.RangeFadeIn = plate_fade_in
	plateFrame.RangeFadeOut = plate_fade_out
	
	plateFrame.FadedIn = true
end

function Plater.GetHealthBar (unitFrame)
	return unitFrame.healthBar, unitFrame.healthBar.actorName
end

function Plater.GetCastBar (unitFrame)
	return unitFrame.castBar, unitFrame.castBar.Text
end

function Plater.CheckHighlight (self)
	if (UnitIsUnit ("mouseover", self.unit)) then
		self.HighlightTexture:Show()
	else
		self.HighlightTexture:Hide()
	end
end

function Plater.CreateHighlightNameplate (plateFrame)
	local highlightOverlay = CreateFrame ("frame", "$parentHighlightOverlay", UIParent)
	highlightOverlay:EnableMouse (false)
	highlightOverlay:SetFrameStrata ("TOOLTIP")
	highlightOverlay:SetAllPoints (plateFrame.UnitFrame.healthBar)
	highlightOverlay:SetScript ("OnUpdate", Plater.CheckHighlight)
	
	highlightOverlay.HighlightTexture = highlightOverlay:CreateTexture (nil, "overlay")
	highlightOverlay.HighlightTexture:SetAllPoints()
	highlightOverlay.HighlightTexture:SetColorTexture (1, 1, 1, 1)
	highlightOverlay.HighlightTexture:SetAlpha (1)
	highlightOverlay:Hide()
	
	plateFrame.UnitFrame.HighlightFrame = highlightOverlay
end

function Plater.CreateScaleAnimation (plateFrame)

	--animation table
	plateFrame.SpellAnimations = {}
	
	--scale animation
	local duration = 0.05
	local animationHub = DF:CreateAnimationHub (plateFrame.UnitFrame)
	animationHub.ScaleUp = DF:CreateAnimation (animationHub, "scale", 1, duration,	1, 	1, 	1.2, 	1.2)
	animationHub.ScaleDown = DF:CreateAnimation (animationHub, "scale", 2, duration,	1, 	1, 	0.8, 	0.8)
	
	plateFrame.SpellAnimations ["scale"] = animationHub

--debug
--	C_Timer.NewTicker (2, function()
--		animationHub:Play()
--	end)
	
end

Plater ["NAME_PLATE_CREATED"] = function (self, event, plateFrame) -- ~created ~events
	--isto � uma nameplate
	plateFrame.UnitFrame.PlateFrame = plateFrame
	plateFrame.isNamePlate = true
	plateFrame.UnitFrame.isNamePlate = true
	plateFrame.UnitFrame.BuffFrame.amtDebuffs = 0
	plateFrame.UnitFrame.BuffFrame.PlaterBuffList = {}
	plateFrame.UnitFrame.BuffFrame.isNameplate = true
	
	--> this technically should be causing taint
	plateFrame.UnitFrame.BuffFrame.UpdateAnchor = function()end
	plateFrame.UnitFrame.healthBar.border.plateFrame = plateFrame
	
	plateFrame.UnitFrame.RefreshID = 0
	
	--> second buff frame
	plateFrame.UnitFrame.BuffFrame2 = CreateFrame ("frame", nil, plateFrame.UnitFrame, "HorizontalLayoutFrame")
	Mixin (plateFrame.UnitFrame.BuffFrame2, NameplateBuffContainerMixin)
	plateFrame.UnitFrame.BuffFrame2.UpdateAnchor = function()end
	
	plateFrame.UnitFrame.BuffFrame2:SetPoint ("RIGHT", plateFrame.UnitFrame.healthBar, 0, 0)
	plateFrame.UnitFrame.BuffFrame2.spacing = 4
	plateFrame.UnitFrame.BuffFrame2.fixedHeight = 14
	plateFrame.UnitFrame.BuffFrame2:OnLoad()
	plateFrame.UnitFrame.BuffFrame2:SetScript ("OnEvent", plateFrame.UnitFrame.BuffFrame2.OnEvent)
	plateFrame.UnitFrame.BuffFrame2.amtDebuffs = 0
	plateFrame.UnitFrame.BuffFrame2.PlaterBuffList = {}
	plateFrame.UnitFrame.BuffFrame2.isNameplate = true
	
	--> buff frame doesn't has a name, make a name here to know which frame is being updated on :Layout() and to give names for icon frames
	plateFrame.UnitFrame.BuffFrame.Name = "Main"
	plateFrame.UnitFrame.BuffFrame2.Name = "Secondary"
	
--	"PlaterMainAuraIcon"
--	"PlaterSecondaryAuraIcon"
	
	--> store the secondary anchor inside the regular buff container for speed
	plateFrame.UnitFrame.BuffFrame.BuffsAnchor = plateFrame.UnitFrame.BuffFrame2
	
	local healthBar = plateFrame.UnitFrame.healthBar
	plateFrame.NameAnchor = 0
	
	Plater.CreateScaleAnimation (plateFrame)
	
	plateFrame.UnitFrame.healthBar.DefaultFrameLevel = plateFrame.UnitFrame.healthBar:GetFrameLevel()
	plateFrame.UnitFrame.castBar.DefaultFrameLevel = plateFrame.UnitFrame.castBar:GetFrameLevel()
	
	--target indicators stored inside the UnitFrame but their parent is the healthBar
	plateFrame.UnitFrame.TargetTextures2Sides = {}
	plateFrame.UnitFrame.TargetTextures4Sides = {}
	for i = 1, 2 do
		local targetTexture = plateFrame.UnitFrame.healthBar:CreateTexture (nil, "overlay")
		targetTexture:SetDrawLayer ("overlay", 7)
		tinsert (plateFrame.UnitFrame.TargetTextures2Sides, targetTexture)
	end
	for i = 1, 4 do
		local targetTexture = plateFrame.UnitFrame.healthBar:CreateTexture (nil, "overlay")
		targetTexture:SetDrawLayer ("overlay", 7)
		tinsert (plateFrame.UnitFrame.TargetTextures4Sides, targetTexture)
	end
	
	local TargetNeonUp = plateFrame.UnitFrame:CreateTexture (nil, "overlay")
	TargetNeonUp:SetDrawLayer ("overlay", 7)
	TargetNeonUp:SetPoint ("topleft", healthBar, "bottomleft", 0, 0)
	TargetNeonUp:SetPoint ("topright", healthBar, "bottomright", 0, 0)
	TargetNeonUp:SetTexture ([[Interface\BUTTONS\UI-Panel-Button-Glow]])
	TargetNeonUp:SetTexCoord (1/128, 95/128, 30/64, 38/64)
	TargetNeonUp:SetDesaturated (true)
	TargetNeonUp:SetBlendMode ("ADD")
	TargetNeonUp:SetHeight (8)
	TargetNeonUp:Hide()
	plateFrame.TargetNeonUp = TargetNeonUp
	plateFrame.UnitFrame.TargetNeonUp = TargetNeonUp
	
	local TargetNeonDown = plateFrame.UnitFrame:CreateTexture (nil, "overlay")
	TargetNeonDown:SetDrawLayer ("overlay", 7)
	TargetNeonDown:SetPoint ("bottomleft", healthBar, "topleft", 0, 0)
	TargetNeonDown:SetPoint ("bottomright", healthBar, "topright", 0, 0)
	TargetNeonDown:SetTexture ([[Interface\BUTTONS\UI-Panel-Button-Glow]])
	TargetNeonDown:SetTexCoord (1/128, 95/128, 38/64, 30/64) --0, 95/128
	TargetNeonDown:SetDesaturated (true)
	TargetNeonDown:SetBlendMode ("ADD")
	TargetNeonDown:SetHeight (8)
	TargetNeonDown:Hide()
	plateFrame.TargetNeonDown = TargetNeonDown
	plateFrame.UnitFrame.TargetNeonDown = TargetNeonDown
	
	Plater.CreateHighlightNameplate (plateFrame)

	--health cutoff - execute range
	local healthCutOff = healthBar:CreateTexture (nil, "overlay")
	healthCutOff:SetTexture ([[Interface\AddOns\Plater\images\health_bypass_indicator]])
	healthCutOff:SetPoint ("left", healthBar, "left")
	healthCutOff:SetSize (16, 25)
	healthCutOff:SetBlendMode ("ADD")
	healthCutOff:SetDrawLayer ("overlay", 7)
	healthCutOff:Hide()
	healthBar.healthCutOff = healthCutOff
	healthBar.ExecuteRangeHealthCutOff = healthCutOff --alias for scripting
	
	local cutoffAnimationOnPlay = function()
		healthCutOff:Show()
	end
	local cutoffAnimationOnStop = function()
		healthCutOff:SetAlpha (.5)
	end
	
	local executeRange = healthBar:CreateTexture (nil, "border")
	executeRange:SetTexture ([[Interface\AddOns\Plater\images\execute_bar]])
	executeRange:SetPoint ("left", healthBar, "left")
	healthBar.executeRange = executeRange
	healthBar.ExecuteRangeBar = executeRange --alias for scripting
	executeRange:Hide()

	local healthCutOffShowAnimation = DF:CreateAnimationHub (healthCutOff, cutoffAnimationOnPlay, cutoffAnimationOnStop)
	DF:CreateAnimation (healthCutOffShowAnimation, "Scale", 1, .2, .3, .3, 1.2, 1.2)
	DF:CreateAnimation (healthCutOffShowAnimation, "Scale", 2, .2, 1.2, 1.2, 1, 1)
	DF:CreateAnimation (healthCutOffShowAnimation, "Alpha", 1, .2, .2, 1)
	DF:CreateAnimation (healthCutOffShowAnimation, "Alpha", 2, .2, 1, .5)
	healthCutOff.ShowAnimation = healthCutOffShowAnimation
	
	local executeGlowUp = healthBar:CreateTexture (nil, "overlay")
	local executeGlowDown = healthBar:CreateTexture (nil, "overlay")
	executeGlowUp:SetTexture ([[Interface\AddOns\Plater\images\blue_neon]])
	executeGlowUp:SetTexCoord (0, 1, 0, 0.5)
	executeGlowUp:SetHeight (32)
	executeGlowUp:SetPoint ("bottom", healthBar, "top")
	executeGlowUp:SetBlendMode ("ADD")
	executeGlowDown:SetTexture ([[Interface\AddOns\Plater\images\blue_neon]])
	executeGlowDown:SetTexCoord (0, 1, 0.5, 1)
	executeGlowDown:SetHeight (30)
	executeGlowDown:SetPoint ("top", healthBar, "bottom")
	executeGlowDown:SetBlendMode ("ADD")
	
	local executeGlowAnimationOnPlay = function (self)
		self:GetParent():Show()
	end
	local executeGlowAnimationOnStop = function()
		
	end
	
	executeGlowUp.ShowAnimation = DF:CreateAnimationHub (executeGlowUp, executeGlowAnimationOnPlay, executeGlowAnimationOnStop)
	DF:CreateAnimation (executeGlowUp.ShowAnimation, "Scale", 1, .2, 1, .1, 1, 1.2, "bottom", 0, 0)
	DF:CreateAnimation (executeGlowUp.ShowAnimation, "Scale", 1, .2, 1, 1, 1, 1)
	
	executeGlowDown.ShowAnimation = DF:CreateAnimationHub (executeGlowDown, executeGlowAnimationOnPlay, executeGlowAnimationOnStop)
	DF:CreateAnimation (executeGlowDown.ShowAnimation, "Scale", 1, .2, 1, .1, 1, 1.2, "top", 0, 0)
	DF:CreateAnimation (executeGlowDown.ShowAnimation, "Scale", 1, .2, 1, 1.1, 1, 1)

	executeGlowUp:Hide()
	executeGlowDown:Hide()
	
	healthBar.ExecuteGlowUp = executeGlowUp
	healthBar.ExecuteGlowDown = executeGlowDown
	
	--raid target
	local raidTarget = healthBar:CreateTexture (nil, "overlay")
	raidTarget:SetPoint ("right", -2, 0)
	plateFrame.RaidTarget = raidTarget
	healthBar.ExtraRaidMark = raidTarget --alias for scripting
	
	--raidtarget frame
	plateFrame.UnitFrame.RaidTargetFrame:Hide() --disable blizzard raid target frame
	
	--create our custom raid target frame
	plateFrame.UnitFrame.PlaterRaidTargetFrame = CreateFrame ("frame", nil, plateFrame.UnitFrame)
	local targetFrame = plateFrame.UnitFrame.PlaterRaidTargetFrame
	targetFrame:SetSize (22, 22)
	targetFrame:SetPoint ("right", healthBar, "left", -15, 0)
	targetFrame.RaidTargetIcon = targetFrame:CreateTexture (nil, "artwork")
	targetFrame.RaidTargetIcon:SetAllPoints()
	targetFrame.RaidTargetIcon:SetTexture ([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
	
	local raidMarkAnimation = DF:CreateAnimationHub (targetFrame.RaidTargetIcon)
	DF:CreateAnimation (raidMarkAnimation, "Scale", 1, .075, .1, .1, 1.2, 1.2)
	DF:CreateAnimation (raidMarkAnimation, "Scale", 2, .075, 1.2, 1.2, 1, 1)
	targetFrame.RaidTargetIcon.ShowAnimation = raidMarkAnimation
	
	plateFrame [MEMBER_ALPHA] = 1
	
	create_alpha_animations (plateFrame)
	
	--> create details! integration strings
	healthBar.DetailsRealTime = healthBar:CreateFontString (nil, "overlay", "GameFontNormal")
	healthBar.DetailsRealTimeFromPlayer = healthBar:CreateFontString (nil, "overlay", "GameFontNormal")
	healthBar.DetailsDamageTaken = healthBar:CreateFontString (nil, "overlay", "GameFontNormal")
	
	local onTickFrame = CreateFrame ("frame", nil, plateFrame)
	plateFrame.OnTickFrame = onTickFrame
	onTickFrame.unit = plateFrame [MEMBER_UNITID]
	onTickFrame.HealthBar = healthBar
	onTickFrame.PlateFrame = plateFrame
	onTickFrame.UnitFrame = plateFrame.UnitFrame
	onTickFrame.BuffFrame = plateFrame.UnitFrame.BuffFrame
	onTickFrame.BuffFrame2 = plateFrame.UnitFrame.BuffFrame2
	
	local onNextTickUpdate = CreateFrame ("frame", nil, plateFrame)
	plateFrame.OnNextTickUpdate = onNextTickUpdate
	onNextTickUpdate.unit = plateFrame [MEMBER_UNITID]
	onNextTickUpdate.HealthBar = healthBar
	onNextTickUpdate.PlateFrame = plateFrame
	onNextTickUpdate.UnitFrame = plateFrame.UnitFrame
	onNextTickUpdate.BuffFrame = plateFrame.UnitFrame.BuffFrame
	plateFrame.TickUpdate = Plater.TickUpdate
	
	--regular name
	local actorName = healthBar:CreateFontString (nil, "artwork", "GameFontNormal")
	healthBar.actorName = actorName
	plateFrame.actorName = actorName --shortcut
	plateFrame.CurrentUnitNameString = actorName
	
	--special name and title
	local ActorNameSpecial = plateFrame:CreateFontString (nil, "artwork", "GameFontNormal")
	plateFrame.ActorNameSpecial = ActorNameSpecial
	plateFrame.ActorNameSpecial:SetPoint ("center", plateFrame, "center")
	plateFrame.ActorNameSpecial:Hide()
	local ActorTitleSpecial = plateFrame:CreateFontString (nil, "artwork", "GameFontNormal")
	plateFrame.ActorTitleSpecial = ActorTitleSpecial
	plateFrame.ActorTitleSpecial:SetPoint ("top", ActorNameSpecial, "bottom", 0, -2)
	plateFrame.ActorTitleSpecial:Hide()
	
	plateFrame.UnitFrame.ActorNameSpecial = ActorNameSpecial --alias for scripts
	plateFrame.UnitFrame.ActorTitleSpecial = ActorTitleSpecial --alias for scripts

	plateFrame.UnitFrame.name:ClearAllPoints()
	plateFrame.UnitFrame.name:SetPoint ("bottom", healthBar.actorName, "bottom")
	
	--level customizado
	local actorLevel = healthBar:CreateFontString (nil, "overlay", "GameFontNormal")
	healthBar.actorLevel = actorLevel
	
	--porcentagem de vida
	local lifePercent = healthBar:CreateFontString (nil, "overlay", "GameFontNormal")
	lifePercent:SetDrawLayer ("ARTWORK", 0)
	healthBar.lifePercent = lifePercent
	
	local obscuredTexture = healthBar:CreateTexture (nil, "overlay")
	obscuredTexture:SetAllPoints()
	obscuredTexture:SetTexture ("Interface\\Tooltips\\UI-Tooltip-Background")
	obscuredTexture:SetVertexColor (0, 0, 0, 1)
	plateFrame.Obscured = obscuredTexture
	
	lifePercent:SetDrawLayer ("overlay", 5)
	obscuredTexture:SetDrawLayer ("overlay", 6)

	--> create the extra icon frame
	local options = {
		icon_width = 20, 
		icon_height = 20, 
		texcoord = {.1, .9, .1, .9},
		show_text = true,
	}
	
	plateFrame.UnitFrame.ExtraIconFrame = DF:CreateIconRow (plateFrame.UnitFrame, "$parentExtraIconRow", options)
	plateFrame.UnitFrame.ExtraIconFrame:ClearIcons()
	--> initialize the refresh ID
	plateFrame.UnitFrame.ExtraIconFrame.RefreshID = 0
	--> cache the extra icon frame inside the buff frame for speed
	plateFrame.UnitFrame.BuffFrame.ExtraIconFrame = plateFrame.UnitFrame.ExtraIconFrame
	
	--icone tr�s dimens�es
	plateFrame.Top3DFrame = CreateFrame ("playermodel", plateFrame:GetName() .. "3DFrame", plateFrame, "ModelWithControlsTemplate")
	plateFrame.Top3DFrame:SetPoint ("bottom", plateFrame, "top", 0, -100)
	plateFrame.Top3DFrame:SetSize (200, 250)
	plateFrame.Top3DFrame:EnableMouse (false)
	plateFrame.Top3DFrame:EnableMouseWheel (false)
	plateFrame.Top3DFrame:Hide()
	plateFrame.UnitFrame.Top3DFrame = plateFrame.Top3DFrame
	
	--castbar
	--castbar background
	local castBarDefaultBackground = plateFrame.UnitFrame.castBar:CreateTexture (nil, "background")
	castBarDefaultBackground:SetAllPoints()
	castBarDefaultBackground:SetColorTexture (0, 0, 0, 0.5)
	
	local extraBackground = plateFrame.UnitFrame.castBar:CreateTexture (nil, "background")
	extraBackground:SetAllPoints()
	extraBackground:SetColorTexture (0, 0, 0, 1)
	plateFrame.UnitFrame.castBar.extraBackground = extraBackground
	extraBackground:SetDrawLayer ("background", -3)
	extraBackground:Hide()
	
	--set a UnitFrame member so scripts can get a quick reference of the unit frame from the castbar without calling for GetParent()
	plateFrame.UnitFrame.castBar.UnitFrame = plateFrame.UnitFrame
	
	plateFrame.UnitFrame.IsUnitNameplate = true
	DF:Mixin (plateFrame.UnitFrame, Plater.ScriptMetaFunctions)
	plateFrame.UnitFrame:HookScript ("OnHide", plateFrame.UnitFrame.OnHideWidget)
	
	plateFrame.UnitFrame.castBar.IsCastBar = true
	DF:Mixin (plateFrame.UnitFrame.castBar, Plater.ScriptMetaFunctions)
	plateFrame.UnitFrame.castBar:HookScript ("OnHide", plateFrame.UnitFrame.castBar.OnHideWidget)

	--> overlay for cast bar border
	plateFrame.UnitFrame.castBar.FrameOverlay = CreateFrame ("frame", "$parentOverlayFrame", plateFrame.UnitFrame.castBar)
	plateFrame.UnitFrame.castBar.FrameOverlay:SetAllPoints()
	plateFrame.UnitFrame.castBar.FrameOverlay:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
	plateFrame.UnitFrame.castBar.FrameOverlay:SetBackdropBorderColor (1, 1, 1, 0)
	
	plateFrame.UnitFrame.castBar.FrameOverlay.TargetName = plateFrame.UnitFrame.castBar.FrameOverlay:CreateFontString (nil, "overlay", "GameFontNormal")
	plateFrame.UnitFrame.castBar.TargetName = plateFrame.UnitFrame.castBar.FrameOverlay.TargetName --alias for scripts
	
	--castbar percent, now anchored on the frame overlay so it'll be above the spell name and the cast bar it self
	local percentText = plateFrame.UnitFrame.castBar.FrameOverlay:CreateFontString (nil, "overlay", "GameFontNormal")
	percentText:SetPoint ("right", plateFrame.UnitFrame.castBar, "right")
	plateFrame.UnitFrame.castBar.percentText = percentText
	
	--non interruptible cast shield
	plateFrame.UnitFrame.castBar.BorderShield:SetTexture ([[Interface\ACHIEVEMENTFRAME\UI-Achievement-Progressive-IconBorder]])
	plateFrame.UnitFrame.castBar.BorderShield:SetTexCoord (5/64, 37/64, 1/64, 36/64)
	plateFrame.UnitFrame.castBar.isNamePlate = true
	plateFrame.UnitFrame.castBar.ThrottleUpdate = 0

	--indicators
	plateFrame.IconIndicators = {}
	
	--default string to show the name
	plateFrame.UnitFrame.name:ClearAllPoints()
	plateFrame.UnitFrame.name:SetPoint ("top", plateFrame.UnitFrame.healthBar, "bottom", 0, 0)
	plateFrame.UnitFrame.name:SetPoint ("center", plateFrame.UnitFrame.healthBar, "center")
	
	--flash aggro
	Plater.CreateAggroFlashFrame (plateFrame)
	plateFrame.playerHasAggro = false
	
	--border frame
	DF:CreateBorderWithSpread (plateFrame.UnitFrame.healthBar, .4, .2, .05, 1, 0.5)
	
	--focus
	local focusIndicator = healthBar:CreateTexture (nil, "overlay")
	focusIndicator:SetPoint ("topleft", healthBar, "topleft", 0, 0)
	focusIndicator:SetPoint ("bottomright", healthBar, "bottomright", 0, 0)
	focusIndicator:Hide()
	healthBar.FocusIndicator = focusIndicator
	plateFrame.FocusIndicator = focusIndicator
	plateFrame.UnitFrame.FocusIndicator = focusIndicator
	
	--low aggro warning
	plateFrame.UnitFrame.aggroGlowUpper = plateFrame:CreateTexture (nil, "background", -4)
	plateFrame.UnitFrame.aggroGlowUpper:SetPoint ("bottomleft", plateFrame.UnitFrame.healthBar, "topleft", -3, 0)
	plateFrame.UnitFrame.aggroGlowUpper:SetPoint ("bottomright", plateFrame.UnitFrame.healthBar, "topright", 3, 0)
	plateFrame.UnitFrame.aggroGlowUpper:SetTexture ([[Interface\BUTTONS\UI-Panel-Button-Glow]])
	plateFrame.UnitFrame.aggroGlowUpper:SetTexCoord (0, 95/128, 0, 9/64)
	plateFrame.UnitFrame.aggroGlowUpper:SetBlendMode ("ADD")
	plateFrame.UnitFrame.aggroGlowUpper:SetHeight (4)
	plateFrame.UnitFrame.aggroGlowUpper:Hide()
	
	plateFrame.UnitFrame.aggroGlowLower = plateFrame:CreateTexture (nil, "background", -4)
	plateFrame.UnitFrame.aggroGlowLower:SetPoint ("topleft", plateFrame.UnitFrame.healthBar, "bottomleft", -3, 0)
	plateFrame.UnitFrame.aggroGlowLower:SetPoint ("topright", plateFrame.UnitFrame.healthBar, "bottomright", 3, 0)
	plateFrame.UnitFrame.aggroGlowLower:SetTexture ([[Interface\BUTTONS\UI-Panel-Button-Glow]])
	plateFrame.UnitFrame.aggroGlowLower:SetTexCoord (0, 95/128, 30/64, 38/64)
	plateFrame.UnitFrame.aggroGlowLower:SetBlendMode ("ADD")
	plateFrame.UnitFrame.aggroGlowLower:SetHeight (4)
	plateFrame.UnitFrame.aggroGlowLower:Hide()
	
	--hooks
	if (HOOK_NAMEPLATE_CREATED.ScriptAmount > 0) then
		for i = 1, HOOK_NAMEPLATE_CREATED.ScriptAmount do
			local globalScriptObject = HOOK_NAMEPLATE_CREATED [i]
			local scriptContainer = plateFrame.UnitFrame:ScriptGetContainer()
			local scriptInfo = plateFrame.UnitFrame:ScriptGetInfo (globalScriptObject, scriptContainer)
	
			--run
			plateFrame.UnitFrame:ScriptRunHook (scriptInfo, "Nameplate Created")
		end
	end
	
end

function Plater.CanShowPlateFor (actorType)
	return DB_PLATE_CONFIG [actorType].enabled
end

Plater ["NAME_PLATE_UNIT_ADDED"] = function (self, event, unitBarId) -- ~added �dded
	--pega a nameplate deste jogador
	
	local plateFrame = C_NamePlate.GetNamePlateForUnit (unitBarId)
	if (not plateFrame) then
		return
	end
	
	--save the last unit type shown in this plate
	plateFrame.PreviousUnitType = plateFrame.actorType
	
	--caching frames
	local unitFrame = plateFrame.UnitFrame
	local castBar = unitFrame.castBar
	local healthBar = unitFrame.healthBar
	
	--use our own classification icons
	unitFrame.ClassificationFrame:Hide()

	--clear values
	plateFrame.CurrentUnitNameString = plateFrame.actorName
	plateFrame.isSelf = nil
	plateFrame.PlayerCannotAttack = nil
	plateFrame.playerGuildName = nil
	plateFrame [MEMBER_NOCOMBAT] = nil
	
	plateFrame [MEMBER_TARGET] = nil
	plateFrame [MEMBER_NPCID] = nil
	unitFrame [MEMBER_TARGET] = nil
	unitFrame [MEMBER_NPCID] = nil
	
	--check if this nameplate has an update scheduled
	if (plateFrame.HasUpdateScheduled) then
		if (not plateFrame.HasUpdateScheduled._cancelled) then
			plateFrame.HasUpdateScheduled:Cancel()
		end
		plateFrame.HasUpdateScheduled = nil
	end
	
	--cache values
	plateFrame [MEMBER_GUID] = UnitGUID (unitBarId) or ""
	plateFrame [MEMBER_NAME] = UnitName (unitBarId) or ""
	plateFrame [MEMBER_NAMELOWER] = lower (plateFrame [MEMBER_NAME])
	plateFrame [MEMBER_CLASSIFICATION] = UnitClassification (plateFrame [unitBarId])
	
	--cache values into the unitFrame as well to reduce the overhead on scripts and hooks
	unitFrame [MEMBER_NAME] = plateFrame [MEMBER_NAME]
	unitFrame [MEMBER_NAMELOWER] = plateFrame [MEMBER_NAMELOWER]
	unitFrame [MEMBER_GUID] = plateFrame [MEMBER_GUID]
	unitFrame [MEMBER_CLASSIFICATION] = plateFrame [MEMBER_CLASSIFICATION]
	unitFrame [MEMBER_UNITID] = unitBarId
	unitFrame.namePlateThreatPercent = 0
	
	--get and format the reaction to always be the value of the constants, then cache the reaction in some widgets for performance
	local reaction = UnitReaction (unitBarId, "player") or 1
	reaction = reaction <= UNITREACTION_HOSTILE and UNITREACTION_HOSTILE or reaction >= UNITREACTION_FRIENDLY and UNITREACTION_FRIENDLY or UNITREACTION_NEUTRAL
	
	plateFrame [MEMBER_REACTION] = reaction
	unitFrame [MEMBER_REACTION] = reaction
	unitFrame.BuffFrame [MEMBER_REACTION] = reaction
	unitFrame.BuffFrame2 [MEMBER_REACTION] = reaction
	unitFrame.BuffFrame2.unit = unitBarId
	
	if (Plater.CanOverrideColor) then
		Plater.ColorOverrider (unitFrame)
	else
		--reset the nameplate color to default
		healthBar.R, healthBar.G, healthBar.B = healthBar.r, healthBar.g, healthBar.b
		healthBar.barTexture:SetVertexColor (healthBar.R, healthBar.G, healthBar.B)
	end
	
	--health amount
	healthBar.CurrentHealth = UnitHealth (unitBarId)
	healthBar.CurrentHealthMax = UnitHealthMax (unitBarId)
	healthBar.IsAnimating = false
	healthBar:SetValue (healthBar.CurrentHealth)
	
	if (not CONST_USE_HEALTHCUTOFF) then
		healthBar.healthCutOff:Hide()
		healthBar.executeRange:Hide()
		healthBar.ExecuteGlowUp:Hide()
		healthBar.ExecuteGlowDown:Hide()
	end
	
	local actorType
	
	if (unitFrame.unit) then
		if (UnitIsUnit (unitBarId, "player")) then
			plateFrame.isSelf = true
			actorType = ACTORTYPE_PLAYER
			plateFrame.NameAnchor = 0
			plateFrame.PlateConfig = DB_PLATE_CONFIG.player
			Plater.UpdatePlateFrame (plateFrame, ACTORTYPE_PLAYER, nil, true)
			Plater.DriverOnUpdateHealth (unitFrame)
		else
			if (UnitIsPlayer (unitBarId)) then
				--unit is a player
				plateFrame.playerGuildName = GetGuildInfo (unitBarId)
				
				if (reaction >= UNITREACTION_FRIENDLY) then
					plateFrame.NameAnchor = DB_NAME_PLAYERFRIENDLY_ANCHOR
					plateFrame.PlateConfig = DB_PLATE_CONFIG.friendlyplayer
					Plater.UpdatePlateFrame (plateFrame, ACTORTYPE_FRIENDLY_PLAYER, nil, true)
					actorType = ACTORTYPE_FRIENDLY_PLAYER
					if (DB_CASTBAR_HIDE_FRIENDLY) then
						CastingBarFrame_SetUnit (castBar, nil, nil, nil)
					end
				else
					plateFrame.NameAnchor = DB_NAME_PLAYERENEMY_ANCHOR
					plateFrame.PlateConfig = DB_PLATE_CONFIG.enemyplayer
					Plater.UpdatePlateFrame (plateFrame, ACTORTYPE_ENEMY_PLAYER, nil, true)
					actorType = ACTORTYPE_ENEMY_PLAYER
					if (DB_CASTBAR_HIDE_ENEMIES) then
						CastingBarFrame_SetUnit (castBar, nil, nil, nil)
					end
				end
			else
				--the unit is a npc
				Plater.GetNpcID (plateFrame)	
				
				if (reaction >= UNITREACTION_FRIENDLY) then
					plateFrame.NameAnchor = DB_NAME_NPCFRIENDLY_ANCHOR
					plateFrame.PlateConfig = DB_PLATE_CONFIG.friendlynpc
					Plater.UpdatePlateFrame (plateFrame, ACTORTYPE_FRIENDLY_NPC, nil, true)
					actorType = ACTORTYPE_FRIENDLY_NPC
					if (DB_CASTBAR_HIDE_FRIENDLY) then
						CastingBarFrame_SetUnit (castBar, nil, nil, nil)
					end
				else
					--includes neutral npcs
					plateFrame.PlayerCannotAttack = not UnitCanAttack ("player", unitBarId)
					plateFrame.NameAnchor = DB_NAME_NPCENEMY_ANCHOR
					plateFrame.PlateConfig = DB_PLATE_CONFIG.enemynpc
					Plater.UpdatePlateFrame (plateFrame, ACTORTYPE_ENEMY_NPC, nil, true)
					actorType = ACTORTYPE_ENEMY_NPC
					if (DB_CASTBAR_HIDE_ENEMIES) then
						CastingBarFrame_SetUnit (castBar, nil, nil, nil)
					end
				end
			end
		end
	end
	
	--icone da cast bar
	castBar.Icon:ClearAllPoints()
	castBar.Icon:SetPoint ("left", castBar, "left", 0, 0)
	castBar.BorderShield:ClearAllPoints()
	castBar.BorderShield:SetPoint ("left", castBar, "left", 0, 0)
	
	--esconde os glow de aggro
	unitFrame.aggroGlowUpper:Hide()
	unitFrame.aggroGlowLower:Hide()
	
	--can check aggro
	-- or PET_CACHE [self:GetParent() [MEMBER_GUID]] or self.displayedUnit:match ("pet%d$")
	unitFrame.CanCheckAggro = unitFrame.displayedUnit == unitBarId and actorType == ACTORTYPE_ENEMY_NPC
	
	--tick
	plateFrame.OnTickFrame.ThrottleUpdate = DB_TICK_THROTTLE
	plateFrame.OnTickFrame.actorType = actorType
	plateFrame.OnTickFrame.unit = plateFrame [MEMBER_UNITID]
	plateFrame.OnTickFrame:SetScript ("OnUpdate", EventTickFunction)
	EventTickFunction (plateFrame.OnTickFrame, 10)
	
	--one tick update
	plateFrame.OnNextTickUpdate.actorType = actorType
	plateFrame.OnNextTickUpdate.unit = plateFrame [MEMBER_UNITID]
	
	--highlight check
	if (DB_HOVER_HIGHLIGHT and not plateFrame.PlayerCannotAttack and (actorType ~= ACTORTYPE_FRIENDLY_PLAYER and actorType ~= ACTORTYPE_FRIENDLY_NPC and not plateFrame.isSelf)) then
		unitFrame.HighlightFrame:Show()
		unitFrame.HighlightFrame.unit = plateFrame [MEMBER_UNITID]
		unitFrame.HighlightFrame:SetScript ("OnUpdate", Plater.CheckHighlight)
	else
		unitFrame.HighlightFrame:SetScript ("OnUpdate", nil)
		unitFrame.HighlightFrame:Hide()
	end
	
	--range
	Plater.CheckRange (plateFrame, true)
	
	--hooks
	if (HOOK_NAMEPLATE_ADDED.ScriptAmount > 0) then
		for i = 1, HOOK_NAMEPLATE_ADDED.ScriptAmount do
			local globalScriptObject = HOOK_NAMEPLATE_ADDED [i]
			local scriptContainer = unitFrame:ScriptGetContainer()
			local scriptInfo = unitFrame:ScriptGetInfo (globalScriptObject, scriptContainer)
			--run
			unitFrame:ScriptRunHook (scriptInfo, "Nameplate Added")
		end
	end
end

function Plater.UpdateUseClassColors()
	for index, plateFrame in ipairs (Plater.GetAllShownPlates()) do
		Plater.Execute ("CompactUnitFrame", Plater.DriverFuncNames ["OnChangeHealthConfig"], plateFrame.UnitFrame)
	end
end

function Plater.UpdateUseCastBar()
	Plater.RefreshDBUpvalues()
end

-- ~removed
Plater ["NAME_PLATE_UNIT_REMOVED"] = function (self, event, unitBarId)
	local plateFrame = C_NamePlate.GetNamePlateForUnit (unitBarId)
	
	--hooks
	if (HOOK_NAMEPLATE_REMOVED.ScriptAmount > 0) then
		for i = 1, HOOK_NAMEPLATE_REMOVED.ScriptAmount do
			local globalScriptObject = HOOK_NAMEPLATE_REMOVED [i]
			local unitFrame = plateFrame.UnitFrame
			local scriptContainer = unitFrame:ScriptGetContainer()
			local scriptInfo = unitFrame:ScriptGetInfo (globalScriptObject, scriptContainer)
			--run
			plateFrame.UnitFrame:ScriptRunHook (scriptInfo, "Nameplate Removed")
		end
	end
	
	plateFrame.OnTickFrame:SetScript ("OnUpdate", nil)
	plateFrame.UnitFrame.HighlightFrame:SetScript ("OnUpdate", nil)
	
	plateFrame [MEMBER_QUEST] = false
	plateFrame [MEMBER_TARGET] = nil
	
	local healthFrame = plateFrame.UnitFrame.healthBar
	if (healthFrame.TargetHeight) then
		healthFrame:SetHeight (healthFrame.TargetHeight)
	end
	healthFrame.IsIncreasingHeight = nil
	healthFrame.IsDecreasingHeight = nil
	
	--hide the highlight
	--is mouse over ~highlight ~mouseover
	plateFrame.UnitFrame.HighlightFrame:Hide()
	plateFrame.UnitFrame.HighlightFrame.Shown = false
	
	--> check if is running any script
	plateFrame.UnitFrame:OnHideWidget()
	plateFrame.UnitFrame.castBar:OnHideWidget()
	for _, auraIconFrame in ipairs (plateFrame.UnitFrame.BuffFrame.PlaterBuffList) do
		auraIconFrame:OnHideWidget()
	end
	for _, auraIconFrame in ipairs (plateFrame.UnitFrame.BuffFrame2.PlaterBuffList) do
		auraIconFrame:OnHideWidget()
	end
end

function Plater.DoNameplateAnimation (plateFrame, frameAnimations, spellName, isCritical)
	for animationIndex, animationTable in ipairs (frameAnimations) do
		if ((animationTable.animationCooldown [plateFrame] or 0) < GetTime()) then
			--animation "scale" is pre constructed when the nameplate frame is created
			if (animationTable.animation_type == "scale") then
				--get the animation
				local animationHub = plateFrame.SpellAnimations ["scale"]

				--duration
				animationHub.ScaleUp:SetDuration (animationTable.duration)
				animationHub.ScaleDown:SetDuration (animationTable.duration)
				
				local scaleUpX, scaleUpY = animationTable.scale_upX, animationTable.scale_upY
				local scaleDownX, scaleDownY = animationTable.scale_downX, animationTable.scale_downY
				
				animationHub.ScaleUp:SetFromScale (1, 1)
				animationHub.ScaleUp:SetToScale (scaleUpX, scaleUpY)
				animationHub.ScaleDown:SetFromScale (1, 1)
				animationHub.ScaleDown:SetToScale (scaleDownX, scaleDownY)
				
				--play it
				animationHub:Play()
				animationTable.animationCooldown [plateFrame] = GetTime() + animationTable.cooldown
				
			elseif (animationTable.animation_type == "frameshake") then
				--get the animation
				local frameShake = plateFrame.SpellAnimations ["frameshake" .. spellName]
				local shakeTargetFrame = plateFrame.UnitFrame
				
				if (not frameShake) then
					local points = {}
		
					for i = 1, shakeTargetFrame:GetNumPoints() do
						local p1, p2, p3, p4, p5 = shakeTargetFrame:GetPoint (i)
						points [#points+1] = {p1, p2, p3, p4, p5}
					end
				
					frameShake = DF:CreateFrameShake (shakeTargetFrame, animationTable.duration, animationTable.amplitude, animationTable.frequency, animationTable.absolute_sineX, animationTable.absolute_sineY, animationTable.scaleX, animationTable.scaleY, animationTable.fade_in, animationTable.fade_out, points)
					plateFrame.SpellAnimations ["frameshake" .. spellName] = frameShake
				end
				
				local animationScale = Plater.db.profile.spell_animations_scale
				
				if (IS_EDITING_SPELL_ANIMATIONS) then
					shakeTargetFrame:SetFrameShakeSettings (frameShake, animationTable.duration, animationTable.amplitude, animationTable.frequency, animationTable.absolute_sineX, animationTable.absolute_sineY, animationTable.scaleX, animationTable.scaleY, animationTable.fade_in, animationTable.fade_out)
				end
				
				if (isCritical and animationTable.critical_scale) then
					animationScale = animationScale * animationTable.critical_scale
					shakeTargetFrame:PlayFrameShake (frameShake, animationScale, animationScale, animationScale, DF:Clamp (0.75, 1.75, animationScale)) --, animationScale
				else
					--scaleDirection, scaleAmplitude, scaleFrequency, scaleDuration
					shakeTargetFrame:PlayFrameShake (frameShake, animationScale, animationScale, animationScale, DF:Clamp (0.75, 1.75, animationScale)) --, animationScale
				end
				
				animationTable.animationCooldown [plateFrame] = GetTime() + animationTable.cooldown
			end
		end
	end
end

local PlaterCLEUParser = CreateFrame ("frame", "PlaterCLEUParserFrame", UIParent)

local parserFunctions = {
	SPELL_DAMAGE = function (time, token, hidding, sourceGUID, sourceName, sourceFlag, sourceFlag2, targetGUID, targetName, targetFlag, targetFlag2, spellID, spellName, spellType, amount, overKill, school, resisted, blocked, absorbed, isCritical)
		if (SPELL_WITH_ANIMATIONS [spellName] and sourceGUID == Plater.PlayerGUID) then
			for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
				if (plateFrame [MEMBER_GUID] == targetGUID) then
					Plater.DoNameplateAnimation (plateFrame, SPELL_WITH_ANIMATIONS [spellName], spellName, isCritical)
				end
			end
		end
	end,
	
	SPELL_SUMMON = function (time, token, hidding, sourceGUID, sourceName, sourceFlag, sourceFlag2, targetGUID, targetName, targetFlag, targetFlag2, spellID, spellName, spellType, amount, overKill, school, resisted, blocked, absorbed, isCritical)
		if (sourceFlag and bit.band (sourceFlag, 0x00003000) ~= 0) then
			PET_CACHE [sourceGUID] = time
			
		elseif (targetFlag and bit.band (targetFlag, 0x00003000) ~= 0) then
			PET_CACHE [targetGUID] = time
		end
	end,
	
	SPELL_INTERRUPT = function (time, token, hidding, sourceGUID, sourceName, sourceFlag, sourceFlag2, targetGUID, targetName, targetFlag, targetFlag2, spellID, spellName, spellType, amount, overKill, school, resisted, blocked, absorbed, isCritical)
		for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
			if (plateFrame.UnitFrame.castBar:IsShown()) then
				if (plateFrame.UnitFrame.castBar.Text:GetText() == INTERRUPTED) then
					if (plateFrame [MEMBER_GUID] == targetGUID) then
						plateFrame.UnitFrame.castBar.Text:SetText (INTERRUPTED .. " [" .. Plater.SetTextColorByClass (sourceName, sourceName) .. "]")
						plateFrame.UnitFrame.castBar.IsInterrupted = true
						--> check and stop the casting script if any
						plateFrame.UnitFrame.castBar:OnHideWidget()
					end
				end
			end
		end
	end,
	
	SPELL_CAST_SUCCESS = function (time, token, hidding, sourceGUID, sourceName, sourceFlag, sourceFlag2, targetGUID, targetName, targetFlag, targetFlag2, spellID, spellName, spellType, amount, overKill, school, resisted, blocked, absorbed, isCritical)
		if (not DB_CAPTURED_SPELLS [spellID]) then
			DB_CAPTURED_SPELLS [spellID] = {event = token, source = sourceName, npcID = Plater:GetNpcIdFromGuid (sourceGUID or ""), encounterID = Plater.CurrentEncounterID}
		end
	end,

	SPELL_AURA_APPLIED = function (time, token, hidding, sourceGUID, sourceName, sourceFlag, sourceFlag2, targetGUID, targetName, targetFlag, targetFlag2, spellID, spellName, spellType, amount, overKill, school, resisted, blocked, absorbed, isCritical)
		if (not DB_CAPTURED_SPELLS [spellID]) then
			local auraType = amount
			DB_CAPTURED_SPELLS [spellID] = {event = token, source = sourceName, type = auraType, npcID = Plater:GetNpcIdFromGuid (sourceGUID or ""), encounterID = Plater.CurrentEncounterID}
		end
	end,
}

PlaterCLEUParser.Parser = function (self)
	local time, token, hidding, sourceGUID, sourceName, sourceFlag, sourceFlag2, targetGUID, targetName, targetFlag, targetFlag2, spellID, spellName, spellType, amount, overKill, school, resisted, blocked, absorbed, isCritical = CombatLogGetCurrentEventInfo()
	local func = parserFunctions [token]
	if (func) then
		return func (time, token, hidding, sourceGUID, sourceName, sourceFlag, sourceFlag2, targetGUID, targetName, targetFlag, targetFlag2, spellID, spellName, spellType, amount, overKill, school, resisted, blocked, absorbed, isCritical)
	end
end

PlaterCLEUParser:SetScript ("OnEvent", PlaterCLEUParser.Parser)
PlaterCLEUParser:RegisterEvent ("COMBAT_LOG_EVENT_UNFILTERED")

C_Timer.NewTicker (180, function()
	local now = time()
	for guid, time in pairs (PET_CACHE) do
		if (time+180 < now) then
			PET_CACHE [guid] = nil
		end
	end
end)

function Plater.ShutdownInterfaceOptionsPanel()
	local frames = {
		InterfaceOptionsNamesPanelUnitNameplates,
		InterfaceOptionsNamesPanelUnitNameplatesFriendsText,
		InterfaceOptionsNamesPanelUnitNameplatesEnemies,
		InterfaceOptionsNamesPanelUnitNameplatesPersonalResource,
		InterfaceOptionsNamesPanelUnitNameplatesPersonalResourceOnEnemy,
		InterfaceOptionsNamesPanelUnitNameplatesMakeLarger,
		InterfaceOptionsNamesPanelUnitNameplatesShowAll,
		InterfaceOptionsNamesPanelUnitNameplatesAggroFlash,
		InterfaceOptionsNamesPanelUnitNameplatesFriendlyMinions,
		InterfaceOptionsNamesPanelUnitNameplatesEnemyMinions,
		InterfaceOptionsNamesPanelUnitNameplatesEnemyMinus,
		InterfaceOptionsNamesPanelUnitNameplatesMotionDropDown,
	}

	for _, frame in ipairs (frames) do
		frame:Hide()
	end
	
	InterfaceOptionsNamesPanelUnitNameplatesMakeLarger.setFunc = function() end
	
	local f = CreateFrame ("frame", nil, InterfaceOptionsNamesPanel)
	f:SetSize (300, 200)
	f:SetPoint ("topleft", InterfaceOptionsNamesPanel, "topleft", 10, -240)
	
	local open_options = function()
		InterfaceOptionsFrame:Hide()
		--GameMenuFrame:Hide()
		Plater.OpenOptionsPanel()
	end
	
	local Button = DF:CreateButton (f, open_options, 100, 20, "", -1, nil, nil, nil, nil, nil, DF:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"))
	Button:SetPoint ("topleft", f, "topleft", 10, 0)
	Button:SetText ("Open Plater Options")
	Button:SetIcon ([[Interface\BUTTONS\UI-OptionsButton]], 18, 18, "overlay", {0, 1, 0, 1})
	
	local Label = DF:CreateLabel (f, "Where are the Nameplate options?\n- Open Plater options, they are at the top left.")
	Label:SetPoint ("bottomleft", Button, "topleft", 0, 2)
end

--elseof
local run_SetCVarsOnFirstRun = function()
	Plater.SetCVarsOnFirstRun()
end
function Plater.SetCVarsOnFirstRun()

	if (InCombatLockdown()) then
		C_Timer.After (1, run_SetCVarsOnFirstRun)
		return
	end

	--> these are the cvars set for each character when they logon
	
	--disabled:
		--SetCVar ("nameplateShowSelf", CVAR_DISABLED)
		--SetCVar (CVAR_RESOURCEONTARGET, CVAR_DISABLED)
		--SetCVar (CVAR_FRIENDLY_ALL, CVAR_ENABLED)
	--> location of the personal bar
	--	SetCVar ("nameplateSelfBottomInset", 20 / 100)
	--	SetCVar ("nameplateSelfTopInset", abs (20 - 99) / 100)
	
	--> set the stacking to true
	SetCVar (CVAR_PLATEMOTION, CVAR_ENABLED)
	
	--> make nameplates always shown and down't show minions
	SetCVar (CVAR_SHOWALL, CVAR_ENABLED)
	SetCVar (CVAR_AGGROFLASH, CVAR_ENABLED)
	SetCVar (CVAR_ENEMY_MINIONS, CVAR_ENABLED)
	SetCVar (CVAR_ENEMY_MINUS, CVAR_ENABLED)
	SetCVar (CVAR_FRIENDLY_GUARDIAN, CVAR_DISABLED)
	SetCVar (CVAR_FRIENDLY_PETS, CVAR_DISABLED)
	SetCVar (CVAR_FRIENDLY_TOTEMS, CVAR_DISABLED)
	SetCVar (CVAR_FRIENDLY_MINIONS, CVAR_DISABLED)
	
	--> make it show the class color of players
	SetCVar (CVAR_CLASSCOLOR, CVAR_ENABLED)
	
	--> just reset to default the clamp from the top side
	SetCVar (CVAR_CEILING, 0.075)

	--> reset the horizontal and vertical scale
	SetCVar (CVAR_SCALE_HORIZONTAL, CVAR_ENABLED)
	SetCVar (CVAR_SCALE_VERTICAL, CVAR_ENABLED)
	
	--> make the selection be a little bigger
	SetCVar ("nameplateSelectedScale", 1.15)
	
	--> distance between each nameplate when using stacking
	SetCVar ("nameplateOverlapV", 1.25)
	
	--> movement speed of nameplates when using stacking, going above this isn't recommended
	SetCVar (CVAR_MOVEMENT_SPEED, 0.05)
	--> this must be 1 for bug reasons on the game client
	SetCVar ("nameplateOccludedAlphaMult", 1)
	--> don't show friendly npcs
	SetCVar ("nameplateShowFriendlyNPCs", 0)
	--> make the personal bar hide very fast
	SetCVar ("nameplatePersonalHideDelaySeconds", 0.2)
	


	--> view distance
	SetCVar (CVAR_CULLINGDISTANCE, 100)
	
	--> try to restore cvars from the profile
	local savedCVars = Plater.db and Plater.db.profile and Plater.db.profile.saved_cvars
	if (savedCVars) then
		for CVarName, CVarValue in pairs (savedCVars) do
			SetCVar (CVarName, CVarValue)
		end
		if (PlaterOptionsPanelFrame) then
			PlaterOptionsPanelFrame.RefreshOptionsFrame()
		end
	end
	
	PlaterDBChr.first_run2 [UnitGUID ("player")] = true
	Plater.db.profile.first_run2 = true
	
	Plater:ZONE_CHANGED_NEW_AREA()
	
	InterfaceOptionsNamesPanelUnitNameplatesMakeLarger:Click()
	InterfaceOptionsNamesPanelUnitNameplatesPersonalResource:Click()
	InterfaceOptionsNamesPanelUnitNameplatesPersonalResource:Click()
	Plater.ShutdownInterfaceOptionsPanel()

	--[=[
		--> override settings based on the class
		local _, unitClass = UnitClass ("player")
		
		if (unitClass == "WARRIOR") then
			--warrior doesn't have good spells to chech the range
			--settings the view distance of nameplates to 40 and the alpha for range change is always 100%
			SetCVar (CVAR_CULLINGDISTANCE, 40)
			Plater.db.profile.range_check_alpha = 100
			
			print ("Plater Debug - Special Settings for Warrior Applied")
		end	
	--]=]

	--Plater:Msg ("has installed custom CVars values, it is ready to work!")
end

function Plater:PLAYER_LOGOUT()
	--be safe, don't break shit
	--SetCVar (CVAR_CULLINGDISTANCE, 60)
end

function Plater.OpenFeedbackWindow()
	if (not Plater.report_window) then
		local w = CreateFrame ("frame", "PlaterBugReportWindow", UIParent)
		w:SetFrameStrata ("TOOLTIP")
		w:SetSize (300, 50)
		w:SetPoint ("center", UIParent, "center")
		tinsert (UISpecialFrames, "PlaterBugReportWindow")
		Plater.report_window = w
		
		local editbox = DF:CreateTextEntry (w, function()end, 280, 20)
		w.editbox = editbox
		editbox:SetPoint ("center", w, "center")
		editbox:SetAutoFocus (false)
		
		editbox:SetHook ("OnEditFocusGained", function() 
			editbox.text = "http://us.battle.net/wow/en/forum/topic/20744134351#1"
			editbox:HighlightText()
		end)
		editbox:SetHook ("OnEditFocusLost", function() 
			w:Hide()
		end)
		editbox:SetHook ("OnChar", function() 
			editbox.text = "http://us.battle.net/wow/en/forum/topic/20744134351#1"
			editbox:HighlightText()
		end)
		editbox.text = "http://us.battle.net/wow/en/forum/topic/20744134351#1"
		
		function Plater:ReportWindowSetFocus()
			if (PlaterBugReportWindow:IsShown()) then
				PlaterBugReportWindow:Show()
				PlaterBugReportWindow.editbox:SetFocus()
				PlaterBugReportWindow.editbox:HighlightText()
			end
		end
	end
	
	PlaterBugReportWindow:Show()
	C_Timer.After (1, Plater.ReportWindowSetFocus)
end

function Plater.RefreshIsEditingAnimations (state)
	IS_EDITING_SPELL_ANIMATIONS = state
end

function Plater.OpenSpellEditor()
	local f = PlaterSpellEditor
	
	if (not f) then
		f = DF:CreateSimplePanel (UIParent, 480, 330, "Plater Nameplates: Spell Editor", "PlaterSpellEditor")
		f.CurrentAnimation = false
		f.CurrentIndex = 1
		IS_EDITING_SPELL_ANIMATIONS = true
		
		f:SetScript ("OnShow", function()
			IS_EDITING_SPELL_ANIMATIONS = true
		end)
		f:SetScript ("OnHide", function()
			IS_EDITING_SPELL_ANIMATIONS = false
		end)
		
		local data = Plater.db.profile.spell_animation_list
		
		function f:HideAllConfigFrames()
			for _, frame in pairs (f.AllConfigFrames) do
				frame:Hide()
			end
		end
		
								--effect dropdown
								local onSelectEffect = function (self, fixedParameter, effectIndex)
									f.CurrentIndex = effectIndex
									f:HideAllConfigFrames()
									
									local animationData = f.CurrentAnimation [f.CurrentIndex]
									
									local configFrame = f.AllConfigFrames [animationData.animation_type]
									configFrame.Data = animationData
									configFrame:RefreshOptions()
									configFrame:Show()
								end
								
								local buildEffectList = function()
									local t = {}
									if (f.CurrentAnimation) then
										for animationIndex, animationTable in ipairs (f.CurrentAnimation) do
											tinsert (t, {label = animationTable.animation_type .. " #" .. animationIndex, value = animationIndex, onclick = onSelectEffect})
										end
									end
									return t
								end
		
								local effectSelectionLabel = DF:CreateLabel (f, "Effect:", DF:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
								local effectSelectionDropdown = DF:CreateDropDown (f, buildEffectList, 1, 160, 20, "EffectSelectionDropdown", _, DF:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
								effectSelectionLabel:SetPoint (280, -40)
								effectSelectionDropdown:SetPoint ("left", effectSelectionLabel, "right", 2, 0)
								
								--animation dropdown
								local onSelectSpellAnimation = function (self, fixedParameter, spellID)
									f.CurrentAnimation = data [spellID]
									f.EffectSelectionDropdown:Refresh()
									f.EffectSelectionDropdown:Select (1, true)
									onSelectEffect (_, _, 1)
								end
								
								local buildSpellList = function()
									local t = {}
									for spellID, spellAnimationTable in pairs (data) do
										local spellName, _, spellIcon = GetSpellInfo (spellID)
										tinsert (t, {label = spellName, value = spellID, onclick = onSelectSpellAnimation, icon = spellIcon})
									end
									return t
								end
								
								local spellSelectionLabel = DF:CreateLabel (f, "Select Spell:", DF:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
								local spellSelectionDropdown = DF:CreateDropDown (f, buildSpellList, 1, 160, 20, "SpellSelectionDropdown", _, DF:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
								spellSelectionLabel:SetPoint (10, -40)
								spellSelectionDropdown:SetPoint ("left", spellSelectionLabel, "right", 2, 0)
		
		f.AllConfigFrames = {}
		local scaleOptionsFrame = CreateFrame ("frame", "$parentScaleFrame", f)
		f.AllConfigFrames ["scale"] = scaleOptionsFrame
		local shakeOptionsFrame = CreateFrame ("frame", "$parentShakeFrame", f)
		f.AllConfigFrames ["frameshake"] = shakeOptionsFrame
		
		for _, frame in pairs (f.AllConfigFrames) do
			frame:SetSize (460, 250)
			frame:SetPoint ("topleft", f, "topleft", 10, -60)
			frame:Hide()
			frame.Data = {}
		end
		
		--build a regular options table from the framewwork
		local scaleOptionsTable = {
			{
				type = "toggle",
				get = function() return scaleOptionsFrame.Data.enabled end,
				set = function (self, fixedparam, value) 
					scaleOptionsFrame.Data.enabled = value
				end,
				name = "Enabled",
			},
			{
				type = "range",
				get = function() return scaleOptionsFrame.Data.cooldown end,
				set = function (self, fixedparam, value) 
					scaleOptionsFrame.Data.cooldown = value
				end,
				min = 0,
				max = 20,
				step = 0.05,
				usedecimals = true,
				name = "Cooldown",
			},
			{
				type = "range",
				get = function() return scaleOptionsFrame.Data.duration end,
				set = function (self, fixedparam, value) 
					scaleOptionsFrame.Data.duration = value
				end,
				min = 0.05,
				max = 1,
				step = 0.05,
				usedecimals = true,
				name = "Duration",
			},
			
			{
				type = "range",
				get = function() return scaleOptionsFrame.Data.scale_upX end,
				set = function (self, fixedparam, value) 
					scaleOptionsFrame.Data.scale_upX = value
				end,
				min = 0,
				max = 20,
				step = 0.05,
				usedecimals = true,
				name = "Scale Up X",
			},
			{
				type = "range",
				get = function() return scaleOptionsFrame.Data.scale_upY end,
				set = function (self, fixedparam, value) 
					scaleOptionsFrame.Data.scale_upY = value
				end,
				min = 0,
				max = 20,
				step = 0.05,
				usedecimals = true,
				name = "Scale Up Y",
			},
			{
				type = "range",
				get = function() return scaleOptionsFrame.Data.scale_downX end,
				set = function (self, fixedparam, value) 
					scaleOptionsFrame.Data.scale_downX = value
				end,
				min = 0,
				max = 20,
				step = 0.05,
				usedecimals = true,
				name = "Scale Down X",
			},
			{
				type = "range",
				get = function() return scaleOptionsFrame.Data.scale_downY end,
				set = function (self, fixedparam, value) 
					scaleOptionsFrame.Data.scale_downY = value
				end,
				min = 0,
				max = 20,
				step = 0.05,
				usedecimals = true,
				name = "Scale Down Y",
			},
		}
		
		local shakeOptionsTable = {
			{
				type = "toggle",
				get = function() return shakeOptionsFrame.Data.enabled end,
				set = function (self, fixedparam, value) 
					shakeOptionsFrame.Data.enabled = value
				end,
				name = "Enabled",
			},
			{
				type = "range",
				get = function() return shakeOptionsFrame.Data.cooldown end,
				set = function (self, fixedparam, value) 
					shakeOptionsFrame.Data.cooldown = value
				end,
				min = 0,
				max = 20,
				step = 0.05,
				usedecimals = true,
				name = "Cooldown",
			},
			{
				type = "range",
				get = function() return shakeOptionsFrame.Data.duration end,
				set = function (self, fixedparam, value) 
					shakeOptionsFrame.Data.duration = value
				end,
				min = 0.05,
				max = 1,
				step = 0.05,
				usedecimals = true,
				name = "Duration",
			},
			
			{
				type = "range",
				get = function() return shakeOptionsFrame.Data.scaleX end,
				set = function (self, fixedparam, value) 
					shakeOptionsFrame.Data.scaleX = value
				end,
				min = -50,
				max = 50,
				step = 0.05,
				usedecimals = true,
				name = "Scale X",
			},
			{
				type = "range",
				get = function() return shakeOptionsFrame.Data.scaleY end,
				set = function (self, fixedparam, value) 
					shakeOptionsFrame.Data.scaleY = value
				end,
				min = -50,
				max = 50,
				step = 0.05,
				usedecimals = true,
				name = "Scale Y",
			},
			
			{
				type = "toggle",
				get = function() return shakeOptionsFrame.Data.absolute_sineX end,
				set = function (self, fixedparam, value) 
					shakeOptionsFrame.Data.absolute_sineX = value
				end,
				name = "Absolute Sine X",
			},
			{
				type = "toggle",
				get = function() return shakeOptionsFrame.Data.absolute_sineY end,
				set = function (self, fixedparam, value) 
					shakeOptionsFrame.Data.absolute_sineY = value
				end,
				name = "Absolute Sine Y",
			},
			
			{
				type = "range",
				get = function() return shakeOptionsFrame.Data.amplitude end,
				set = function (self, fixedparam, value) 
					shakeOptionsFrame.Data.amplitude = value
				end,
				min = 0,
				max = 50,
				step = 0.05,
				usedecimals = true,
				name = "Amplitude",
			},
			{
				type = "range",
				get = function() return shakeOptionsFrame.Data.frequency end,
				set = function (self, fixedparam, value) 
					shakeOptionsFrame.Data.frequency = value
				end,
				min = 0,
				max = 200,
				step = 0.05,
				usedecimals = true,
				name = "Frequency",
			},
			{
				type = "range",
				get = function() return shakeOptionsFrame.Data.fade_in end,
				set = function (self, fixedparam, value) 
					shakeOptionsFrame.Data.fade_in = value
				end,
				min = 0,
				max = 2,
				step = 0.05,
				usedecimals = true,
				name = "Fade In Time",
			},
			{
				type = "range",
				get = function() return shakeOptionsFrame.Data.fade_out end,
				set = function (self, fixedparam, value) 
					shakeOptionsFrame.Data.fade_out = value
				end,
				min = 0,
				max = 2,
				step = 0.05,
				usedecimals = true,
				name = "Fade Out Time",
			},
		}
		
		local options_text_template = DF:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE")
		local options_dropdown_template = DF:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
		local options_switch_template = DF:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE")
		local options_slider_template = DF:GetTemplate ("slider", "OPTIONS_SLIDER_TEMPLATE")
		local options_button_template = DF:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE")
		
		function f.OnDataChange()
			Plater.RefreshDBLists()
		end
		
		DF:BuildMenu (scaleOptionsFrame, scaleOptionsTable, 0, -20, 330, true, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template, f.OnDataChange)
		DF:BuildMenu (shakeOptionsFrame, shakeOptionsTable, 0, -20, 330, true, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template, f.OnDataChange)

	end
	
	f:Show()
end


SLASH_PLATER1 = "/plater"
SLASH_PLATER2 = "/nameplate"
SLASH_PLATER3 = "/nameplates"

-- ~cvar
local cvarDiagList = {
	"nameplateMaxDistance",
	"nameplateOtherTopInset",
	"nameplateOtherAtBase",
	"nameplateMinAlpha",
	"nameplateMinAlphaDistance",
	"nameplateShowAll",
	"nameplateShowEnemies",
	"nameplateShowEnemyMinions",
	"nameplateShowEnemyMinus",
	"nameplateShowFriends",
	"nameplateShowFriendlyGuardians",
	"nameplateShowFriendlyPets",
	"nameplateShowFriendlyTotems",
	"nameplateShowFriendlyMinions",
	"NamePlateHorizontalScale",
	"NamePlateVerticalScale",
}
function SlashCmdList.PLATER (msg, editbox)
	if (msg == "dignostico" or msg == "diag" or msg == "debug") then
		
		print ("Plater Diagnostic:")
		for i = 1, #cvarDiagList do
			local cvar = cvarDiagList [i]
			print ("|cFFC0C0C0" .. cvar, "|r->", GetCVar (cvar))
		end
		
		local alphaPlateFrame = "there's no nameplate in the screen"
		local alphaUnitFrame = ""
		local alphaHealthFrame = ""
		local testPlate
		
		for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do
			if (plateFrame [MEMBER_REACTION] < 4) then
				testPlate = plateFrame
				alphaPlateFrame = plateFrame:GetAlpha()
				alphaUnitFrame = plateFrame.UnitFrame:GetAlpha()
				alphaHealthFrame = plateFrame.UnitFrame.healthBar:GetAlpha()
				break
			end
		end
		
		print ("|cFFC0C0C0Alpha|r", "->", alphaPlateFrame, "-", alphaUnitFrame, "-", alphaHealthFrame)
		
		if (testPlate) then
			local w, h = testPlate:GetSize()
			print ("|cFFC0C0C0Size|r", "->", w, h, "-", testPlate.UnitFrame.healthBar:GetSize())
			
			local point1, anchorFrame, point2, x, y = testPlate:GetPoint (1)
			print ("|cFFC0C0C0Point|r", "->", point1, anchorFrame:GetName(), point2, x, y)
			
			local plateIsShown = testPlate:IsShown() and "yes" or "no"
			local unitFrameIsShown = testPlate.UnitFrame:IsShown() and "yes" or "no"
			local healthBarIsShown = testPlate.UnitFrame.healthBar:IsShown() and "yes" or "no"
			print ("|cFFC0C0C0ShownStatus|r", "->", plateIsShown, "-", unitFrameIsShown, "-", healthBarIsShown)
		else
			print ("|cFFC0C0C0Size|r", "-> there's no nameplate in the screen")
			print ("|cFFC0C0C0Point|r", "-> there's no nameplate in the screen")
			print ("|cFFC0C0C0ShownStatus|r", "-> there's no nameplate in the screen")
		end
		
		return
		
	elseif (msg == "spellanimation" or msg == "sa") then
		Plater.OpenSpellEditor()
		return
	end
	
	Plater.OpenOptionsPanel()
end

--black list npcs to not show when showing friendly npcs
local ignored_npcs_when_profession = {
	[32751] = true, --warp huntress pet - Dalaran
	[110571] = 1, --delas mooonfang - Dalaran
	[113199] = true, --delas's pet - Dalaran
	[110018] = 1, --gazrix gearlock - Dalaran
	[107622] = true, --glutonia - Dalaran
	[106263] = 1, --earthen ring shaman - Dalaran
	[106262] = 1, --earthen ring shaman - Dalaran
	[97141] = true, --koraud - Dalaran
}

function Plater.IsIgnored (plateFrame, onlyProfession)
	if (onlyProfession) then
		local npcId = plateFrame [MEMBER_NPCID]
		if (not npcId) then
			return
		end
		if (ignored_npcs_when_profession [npcId]) then
			return true
		end
	end
end

function Plater.GetNpcIDFromGUID (guid)
	local npcID = select (6, strsplit ("-", guid))
	return tonumber (npcID or "0") or 0
end

function Plater.GetNpcID (plateFrame)
	local npcId = plateFrame [MEMBER_GUID]
	if (npcId and npcId ~= "") then
		npcId = select (6, strsplit ("-", npcId))
		if (npcId) then
			npcId = tonumber (npcId)
		else
			return
		end
	else
		return
	end
	
	if (not npcId) then
		return
	end
	
	plateFrame [MEMBER_NPCID] = npcId
	plateFrame.UnitFrame [MEMBER_NPCID] = npcId
end

function Plater.SetTextColorByClass (unit, text)
	local _, class = UnitClass (unit)
	if (class) then
		local color = RAID_CLASS_COLORS [class]
		if (color) then
			text = "|c" .. color.colorStr .. DF:RemoveRealName (text) .. "|r"
		end
	else
		text = DF:RemoveRealName (text)
	end
	return text
end

Plater.SpecList = {
	["DEMONHUNTER"] = {
		[577] = true, 
		[581] = true,
	},
	["DEATHKNIGHT"] = {
		[250] = true,
		[251] = true,
		[252] = true,
	},
	["WARRIOR"] = {
		[71] = true,
		[72] = true,
		[73] = true,
	},
	["MAGE"] = {
		[62] = true,
		[63] = true,
		[64] = true,
	},
	["ROGUE"] = {
		[259] = true,
		[260] = true,		
		[261] = true,
	},
	["DRUID"] = {
		[102] = true,
		[103] = true,
		[104] = true,
		[105] = true,
	},
	["HUNTER"] = {
		[253] = true,
		[254] = true,		
		[255] = true,
	},
	["SHAMAN"] = {
		[262] = true,
		[263] = true,
		[264] = true,
	},
	["PRIEST"] = {
		[256] = true,
		[257] = true,
		[258] = true,
	},
	["WARLOCK"] = {
		[265] = true,
		[266] = true,
		[267] = true,
	},
	["PALADIN"] = {
		[65] = true,
		[66] = true,
		[70] = true,
	},
	["MONK"] = {
		[268] = true, 
		[269] = true, 
		[270] = true, 
	},
}

local re_GetSpellForRangeCheck = function()
	Plater.GetSpellForRangeCheck()
end

function Plater.GetSpellForRangeCheck()

	Plater.SpellBookForRangeCheck = nil

	local specIndex = GetSpecialization()
	if (specIndex) then
		local specID = GetSpecializationInfo (specIndex)
		if (specID and specID ~= 0) then
			Plater.SpellForRangeCheck = PlaterDBChr.spellRangeCheck [specID]
			
			--getting the spell slot from the spellbook doesn't fix the problem with the demonhunter taunt ability
			if true then return end
			
			--attempt ot get the spellbook slot for this spell
			for i = 1, GetNumSpellTabs() do
				local name, texture, offset, numEntries, isGuild, offspecID = GetSpellTabInfo (i)
				
				--is the tab enabled?
				if (offspecID == 0) then
					for slotIndex = offset, offset + numEntries - 1 do
						local skillType, spellID = GetSpellBookItemInfo (slotIndex, BOOKTYPE_SPELL)
						if (skillType == "SPELL" or skillType == "FUTURESPELL") then
							local spellName = GetSpellInfo (spellID)
							if (spellName == Plater.SpellForRangeCheck) then
								Plater.SpellForRangeCheck = FindSpellBookSlotBySpellID (spellID)
								Plater.SpellBookForRangeCheck = skillType
								break
							end
						end
					end
				end
			end
		else
			C_Timer.After (5, re_GetSpellForRangeCheck)
		end
	else
		C_Timer.After (5, re_GetSpellForRangeCheck)
	end

end

-- ~range
Plater.DefaultSpellRangeList = {
	-- 185245 spellID for Torment, it is always failing to check range with IsSpellInRange()
	[577] = 278326, --> havoc demon hunter - Consume Magic
	[581] = 278326, --> vengeance demon hunter - Consume Magic

	[250] = 56222, --> blood dk - dark command
	[251] = 56222, --> frost dk - dark command
	[252] = 56222, --> unholy dk - dark command
	
	[102] = 8921, -->  druid balance - Moonfire (45 yards)
	[103] = 8921, -->  druid feral - Moonfire (40 yards)
	[104] = 6795, -->  druid guardian - Growl
	[105] = 8921, -->  druid resto - Moonfire (40 yards)

	[253] = 193455, -->  hunter bm - Cobra Shot
	[254] = 19434, --> hunter marks - Aimed Shot
	[255] = 271788, --> hunter survivor - Serpent Sting
	
	[62] = 227170, --> mage arcane - arcane blast
	[63] = 133, --> mage fire - fireball
	[64] = 228597, --> mage frost - frostbolt
	
	[268] = 115546 , --> monk bm - Provoke
	[269] = 117952, --> monk ww - Crackling Jade Lightning (40 yards)
	[270] = 117952, --> monk mw - Crackling Jade Lightning (40 yards)
	
	[65] = 20473, --> paladin holy - Holy Shock (40 yards)
	[66] = 62124, --> paladin protect - Hand of Reckoning
	[70] = 62124, --> paladin ret - Hand of Reckoning
	
	[256] = 585, --> priest disc - Smite
	[257] = 585, --> priest holy - Smite
	[258] = 8092, --> priest shadow - Mind Blast
	
	[259] = 185565, --> rogue assassination - Poisoned Knife (30 yards)
	[260] = 185763, --> rogue outlaw - Pistol Shot (20 yards)
	[261] = 114014, --> rogue sub - Shuriken Toss (30 yards)

	[262] = 188196, --> shaman elemental - Lightning Bolt
	[263] = 187837, --> shaman enhancement - Lightning Bolt (instance cast)
	[264] = 403, --> shaman resto - Lightning Bolt

	[265] = 980, --> warlock aff - Agony
	[266] = 686, --> warlock demo - Shadow Bolt
	[267] = 116858, --> warlock destro - Chaos Bolt
	
	[71] = 355, --> warrior arms - Taunt
	[72] = 355, --> warrior fury - Taunt
	[73] = 355, --> warrior protect - Taunt
}

function Plater.RefreshOmniCCGroup (fromInit)
	if (OmniCC) then
		local OmniCCDB = OmniCC4Config
		if (OmniCCDB) then
		
			--being extra careful
			local OmniCCGroupSettings = OmniCCDB.groupSettings
			local OmniCCAllGroups = OmniCCDB.groups
			
			local platerGroupName = "PlaterNameplates Blacklist"
			
			--check if the settings exists
			if (OmniCCGroupSettings and OmniCCAllGroups) then
				--attempt to get the plater group
				local platerGroup
				for groupIndex, groupTable in ipairs (OmniCCAllGroups) do
					if (groupTable.id == platerGroupName) then
						platerGroup = groupTable
						break
					end
				end
				
				--check if the plater group exists, this doesn't but the call is from Initialization or Profile Refresh, just quit
				if (not platerGroup and fromInit) then
					return
				end
				
				--if doesn't exists and isn't from init (the call came from the options panel by the user clicking in the checkbox)
				if (not platerGroup) then
					platerGroup = {
						id = platerGroupName,
						rules = {},
						enabled = true,
					}
					tinsert (OmniCCAllGroups, platerGroup)
				end
				
				--get the plater settings table
				local settingsGroup = OmniCCGroupSettings [platerGroupName]
				if (not settingsGroup) then
					settingsGroup = {
						enabled = false,
						minDuration = 2,
						styles = {
							minutes = {
							},
							soon = {
							},
							seconds = {
							},
							hours = {
							},
							charging = {
							},
							controlled = {
							},
						},
						tenthsDuration = 0,
						minSize = 0.5,
						minEffectDuration = 30,
						enabled = true,
						mmSSDuration = 0,
					}
					OmniCCGroupSettings [platerGroupName] = settingsGroup
				end
				
				if (Plater.db.profile.disable_omnicc_on_auras) then
					DF.table.addunique (platerGroup.rules, "PlaterMainAuraIcon")
					DF.table.addunique (platerGroup.rules, "PlaterSecondaryAuraIcon")
					settingsGroup.enabled = false
				else
					wipe (platerGroup.rules)
					settingsGroup.enabled = false
				end
			end
		end
	end
end

function Plater.CreateAuraTesting()

	local auraOptionsFrame = PlaterOptionsPanelContainer.AllFrames [9]

	auraOptionsFrame.OnUpdateFunc = function (self, deltaTime)
		
		auraOptionsFrame.NextTime = auraOptionsFrame.NextTime - deltaTime
		DB_AURA_ENABLED = false
		
		if (auraOptionsFrame.NextTime <= 0) then
			auraOptionsFrame.NextTime = 0.016
			
			for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do

				local buffFrame = plateFrame.UnitFrame.BuffFrame
				local buffFrame2 = plateFrame.UnitFrame.BuffFrame2
				
				buffFrame:SetAlpha (DB_AURA_ALPHA)
				
				--> reset next aura icon to use
				buffFrame.NextAuraIcon = 1
				buffFrame2.NextAuraIcon = 1
			
				if (not DB_AURA_SEPARATE_BUFFS) then
					for index, auraTable in ipairs (auraOptionsFrame.AuraTesting.DEBUFF) do
						local auraIconFrame = Plater.GetAuraIcon (buffFrame)
						if (not auraTable.ApplyTime or auraTable.ApplyTime+auraTable.Duration < GetTime()) then
							auraTable.ApplyTime = GetTime() + math.random (3, 12)
						end
						
						if (not UnitIsUnit (plateFrame [MEMBER_UNITID], "player")) then
							Plater.AddAura (auraIconFrame, index, auraTable.SpellName, auraTable.SpellTexture, auraTable.Count, "DEBUFF", auraTable.Duration, auraTable.ApplyTime+auraTable.Duration, "player", false, false, auraTable.SpellID)
						else
							Plater.AddAura (auraIconFrame, index, auraTable.SpellName, auraTable.SpellTexture, auraTable.Count, "DEBUFF", auraTable.Duration, auraTable.ApplyTime+auraTable.Duration, "player", false, false, auraTable.SpellID, false, false, true, true)
						end
					end
					
					for index, auraTable in ipairs (auraOptionsFrame.AuraTesting.BUFF) do
						local auraIconFrame = Plater.GetAuraIcon (buffFrame)
						if (not auraTable.ApplyTime or auraTable.ApplyTime+auraTable.Duration < GetTime()) then
							auraTable.ApplyTime = GetTime() + math.random (3, 12)
						end
						
						if (not UnitIsUnit (plateFrame [MEMBER_UNITID], "player")) then
							Plater.AddAura (auraIconFrame, index, auraTable.SpellName, auraTable.SpellTexture, auraTable.Count, "DEBUFF", auraTable.Duration, auraTable.ApplyTime+auraTable.Duration, "player", false, false, auraTable.SpellID, true)
						else
							Plater.AddAura (auraIconFrame, index, auraTable.SpellName, auraTable.SpellTexture, auraTable.Count, "DEBUFF", auraTable.Duration, auraTable.ApplyTime+auraTable.Duration, "player", false, false, auraTable.SpellID, false, false, false, true)
						end
					end
		
					--hide icons on the second buff frame
					for i = 1, #buffFrame2.PlaterBuffList do
						local icon = buffFrame2.PlaterBuffList [i]
						if (icon) then
							icon:Hide()
							icon.InUse = false
						end
					end
				end
			
				if (DB_AURA_SEPARATE_BUFFS) then
					for index, auraTable in ipairs (auraOptionsFrame.AuraTesting.DEBUFF) do
						local auraIconFrame = Plater.GetAuraIcon (buffFrame)
						if (not auraTable.ApplyTime or auraTable.ApplyTime+auraTable.Duration < GetTime()) then
							auraTable.ApplyTime = GetTime() + math.random (3, 12)
						end
						
						if (not UnitIsUnit (plateFrame [MEMBER_UNITID], "player")) then
							Plater.AddAura (auraIconFrame, index, auraTable.SpellName, auraTable.SpellTexture, auraTable.Count, "DEBUFF", auraTable.Duration, auraTable.ApplyTime+auraTable.Duration, "player", false, false, auraTable.SpellID)
						else
							Plater.AddAura (auraIconFrame, index, auraTable.SpellName, auraTable.SpellTexture, auraTable.Count, "DEBUFF", auraTable.Duration, auraTable.ApplyTime+auraTable.Duration, "player", false, false, auraTable.SpellID, false, false, true, true)
						end
					end
				
					for index, auraTable in ipairs (auraOptionsFrame.AuraTesting.BUFF) do
						local auraIconFrame = Plater.GetAuraIcon (buffFrame, true)
						if (not auraTable.ApplyTime or auraTable.ApplyTime+auraTable.Duration < GetTime()) then
							auraTable.ApplyTime = GetTime() + math.random (3, 12)
						end
						
						if (not UnitIsUnit (plateFrame [MEMBER_UNITID], "player")) then
							Plater.AddAura (auraIconFrame, index, auraTable.SpellName, auraTable.SpellTexture, auraTable.Count, "BUFF", auraTable.Duration, auraTable.ApplyTime+auraTable.Duration, "player", false, false, auraTable.SpellID, true)
						else
							Plater.AddAura (auraIconFrame, index, auraTable.SpellName, auraTable.SpellTexture, auraTable.Count, "BUFF", auraTable.Duration, auraTable.ApplyTime+auraTable.Duration, "player", false, false, auraTable.SpellID, false, false, false, true)
						end
					end
				end
				
				Plater.HideNonUsedAuraFrames (buffFrame)
				buffFrame:Layout()
			
			end
			
		end
		
	end

	auraOptionsFrame.EnableAuraTest = function()
		DB_AURA_ENABLED = false
		auraOptionsFrame.NextTime = 0.2
		auraOptionsFrame:SetScript ("OnUpdate", auraOptionsFrame.OnUpdateFunc)
	end
	auraOptionsFrame.DisableAuraTest = function()
		Plater.RefreshDBUpvalues()
		auraOptionsFrame:SetScript ("OnUpdate", nil)
	end

	auraOptionsFrame:SetScript ("OnShow", function()
		if (not Plater.DisableAuraTest) then
			auraOptionsFrame.EnableAuraTest()
		end
	end)

	auraOptionsFrame:SetScript ("OnHide", function()
		auraOptionsFrame.DisableAuraTest()
	end)
end



--update class color
function Plater.UpdateUnitColor (self, unit)
	
end


--functiona enda
