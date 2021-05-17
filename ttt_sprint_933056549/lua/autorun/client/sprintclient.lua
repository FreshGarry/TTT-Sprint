-- Please ask me if you want to use parts of this code!
-- FG Addon Heading
local Version = "3.4"

-- Table with Addons
if not TTTFGAddons then
	TTTFGAddons = {}
end

-- global accessable variables
TTTSprint = {}
TTTSprint.percent = 100
TTTSprint.sprinting = false

table.insert(TTTFGAddons, "TTT Sprint")

-- ConVar for disabling
local ChatMessage = CreateClientConVar("ttt_fgaddons_textmessage", "1", true, false, "Enables or disables the message in the chat. Def:1")

-- Hook for printing
hook.Add("TTTBeginRound", "TTTBeginRound4TTTFGAddons", function()
	local String = ""
	local names = TTTFGAddons

	for i = 1, #names do
		if String == "" then
			String = names[i]
		else
			String = String..", "..names[i]
		end
	end

	if ChatMessage:GetBool() then
		chat.AddText("TTT FG Addons: ", Color(255, 255, 255), "You are running "..String..".")
		chat.AddText("TTT FG Addons: ", Color(255, 255, 255), "Be sure to check out the Settings in the ", Color(255, 0, 0), "F1", Color(255, 255, 255), " menu.")
		chat.AddText("TTT FG Addons: ", Color(255, 255, 255), "You can disable this message in the Settings (", Color(255, 0, 0), "F1", Color(255, 255, 255), ").")
	end
end)

-- Request ConVars (SERVER)
local function ConVars()
	net.Start("SprintGetConVars")
	net.SendToServer()
end

-- Set default Values
local Multiplikator = 0.5
local Crosshair = 1
local Regenerate = 5
local Consumption = 1
local KeySelected = ""
local KeySelected2 = ""
local Key_box2 = 0
local lastReleased = -1000
local DoubleTapActivated = false
local CrosshairSize = 1
local TimerCon = CurTime()
local TimerReg = CurTime()
local surface = surface
local ply = LocalPlayer()

if not TTT2 then
	TTT2 = false
end

-- Receive ConVars (SERVER)
net.Receive("SprintGetConVars", function()
	local Table = net.ReadTable()

	Multiplikator = Table[1]
	Crosshair = Table[2]
	Regenerate = Table[3]
	Consumption = Table[4]
end)

-- Client ConVars
local xPos = CreateClientConVar("ttt_sprint_hud_offset_x", "275", true, false, "The x offset of the HUD. Def: 275")
local yPos = CreateClientConVar("ttt_sprint_hud_offset_y", "60", true, false, "The y offset of the HUD. Def: 60")
local allignment = CreateClientConVar("ttt_sprint_hud_allignment", "0", true, false, "The allignment of the hud. (0 = bottom, left; 1 = top, left; 2 = top, right; 3 = bottom, right) Def: 0")
local ActivateKey = CreateClientConVar("ttt_sprint_activate_key", "0", true, false, "The key used to sprint. (0 = Use; 1 = Shift; 2 = Control; 3 = Custom; 4 = Double tap) Def:1")
local CustomActivateKey = CreateClientConVar("ttt_sprint_activate_key_custom", "32", true, false, "The custom key used to sprint if ttt_sprint_activate_key = 3. It has to be a Number. (Example: 32 = V Key) Def: 32 Key Numbers: https://wiki.garrysmod.com/page/Enums/KEY")
local DoubleTapTime = CreateClientConVar("ttt_sprint_doubletaptime", "0.25", true, false, "The time you have for double tapping if ttt_sprint_activate_key = 4. (0.001-1) Def:0.25")
local CrosshairDebugSize = CreateClientConVar("ttt_sprint_crosshairdebugsize", "1", true, false, "The size of the crosshair used to prevent no crosshair while not sprinting. (Disabled = 0) Def:1")

-- Requesting ConVars first time
ConVars()

-- Crating font
surface.CreateFont("HUDFont", {font = "Trebuchet24", size = 24, weight = 750})

-- The HUD function (inspired by Health Bar in TTT)
local function HUD(name, xPos2, yPos2, allignment2, ColorA, ColorB, value, maximum)
	if LocalPlayer():Alive() and LocalPlayer():IsTerror() and (not LocalPlayer():IsSpec()) then

		-- Number or String?
		local valueNumber = value
		local number = true

		if maximum == 0 then
			valueNumber = 1
			maximum = 1
			number = false
		end

		-- Convert to numbers
		xPos2 = xPos2:GetFloat()
		yPos2 = yPos2:GetFloat()
		allignment2 = allignment2:GetFloat()

		-- Get real X and Y (Allignment)
		local x = 0
		local y = 0

		if allignment2 == 1 then
			x = xPos2
			y = yPos2
		elseif allignment2 == 2 then
			x = ScrW() - xPos2
			y = yPos2
		elseif allignment2 == 3 then
			x = ScrW() - xPos2
			y = ScrH() - yPos2
		else
			x = xPos2
			y = ScrH() - yPos2
		end

		-- Drawing
		local length = 230
    
		if TTT2 and GetConVar( "ttt2_base_hud_width" ) then
			length = 250 + GetConVar( "ttt2_base_hud_width" ):GetFloat()
		end

		draw.RoundedBox(8, x - 5, y - 10, length + 20, 60, Color(0, 0, 0, 200))
		draw.RoundedBox(8, x + 4, y + 4, length + 2, 27, ColorB)

		surface.SetDrawColor(ColorA)

		if length / maximum * valueNumber > 0 then
			surface.DrawRect(x + 12, y + 5, length / maximum * valueNumber - 14, 25)
			surface.DrawRect(x + 5, y + 13, 8, 25 - 8 * 2)
			surface.SetTexture(surface.GetTextureID("gui/corner8"))
			surface.DrawTexturedRectRotated(x + 5 + 8 / 2, y + 5 + 8 / 2, 8, 8, 0)
			surface.DrawTexturedRectRotated(x + 5 + 8 / 2, y + 5 + 25 - 8 / 2, 8, 8, 90)

			if length / maximum * valueNumber > 13 then
				surface.DrawRect(x + 5 + length / maximum * valueNumber - 8, y + 13, 8, 25 - 8 * 2)
				surface.DrawTexturedRectRotated(x + 5 + length / maximum * valueNumber - 8 / 2, y + 5 + 8 / 2, 8, 8, 270)
				surface.DrawTexturedRectRotated(x + 5 + length / maximum * valueNumber - 8 / 2, y + 5 + 25 - 8 / 2, 8, 8, 180)
			else
				surface.DrawRect(x + 5 + math.max(length / maximum * valueNumber - 8, 8), y + 5, 8 / 2, 25)
			end
		end

		-- Texts with shaddow
		if number then
			draw.SimpleText(math.floor(value), "HUDFont", x + length - 15, y + 7, Color(0, 0, 0), TEXT_ALIGN_RIGHT)
			draw.SimpleText(math.floor(value), "HUDFont", x + length - 17, y + 5, Color(255, 255, 255), TEXT_ALIGN_RIGHT)
		else
			draw.SimpleText(value, "HUDFont", x + length - 15, y + 7, Color(0, 0, 0), TEXT_ALIGN_RIGHT)
			draw.SimpleText(value, "HUDFont", x + length - 17, y + 5, Color(255, 255, 255), TEXT_ALIGN_RIGHT)
		end

		draw.SimpleText(name, "TabLarge", x + length - 46, y - 17, Color(255, 255, 255))
	end
end

-- Painting of the HUD
hook.Add("HUDPaint", "SprintHUD", function()
	if not TEAM_SPEC then
		return
	end -- not ttt

	HUD("STAMINA", xPos, yPos, allignment, Color(0, 0, 255, 255), Color(0, 0, 100, 255), TTTSprint.percent, 100)
end)

-- Change the Speed
local function SpeedChange(Bool)
	net.Start("SprintSpeedset")

	if Bool then
		net.WriteFloat(math.min(math.max(Multiplikator, 0.1), 2))

		ply.mult = 1 + math.min(math.max(Multiplikator, 0.1), 2)
	else
		net.WriteFloat(0)

		ply.mult = nil
	end

	net.SendToServer()

	if Crosshair then -- Disable Crosshair
		if Bool then
			local tmp = GetConVar("ttt_crosshair_size")

			CrosshairSize = tmp and tmp:GetString() or 1

			RunConsoleCommand("ttt_crosshair_size", "0")
		else
			if CrosshairSize == "0" then
				CrosshairSize = CrosshairDebugSize:GetFloat()
			end

			RunConsoleCommand("ttt_crosshair_size", CrosshairSize)
		end
	end
end

-- returns the selected sprint key
function SprintKey()
	if ActivateKey:GetFloat() == 0 then
		return LocalPlayer():KeyDown(IN_USE)
	elseif ActivateKey:GetFloat() == 1 then
		return input.IsKeyDown(KEY_LSHIFT)
	elseif ActivateKey:GetFloat() == 2 then
		return input.IsKeyDown(KEY_LCONTROL)
	elseif ActivateKey:GetFloat() == 3 then
		return input.IsKeyDown(CustomActivateKey:GetFloat())
	end

	return false
end

-- Sprint activated (sprint if there is stamina)
local function SprintFunction()
	if TTTSprint.percent > 0 then
		if not TTTSprint.sprinting then
			SpeedChange(true)

			TTTSprint.sprinting = true
			TimerCon = CurTime()
		end

		TTTSprint.percent = TTTSprint.percent - (CurTime() - TimerCon) * (math.min(math.max(Consumption, 0.1), 5) * 250)
		TimerCon = CurTime()
	else
		if TTTSprint.sprinting then
			SpeedChange(false)

			TTTSprint.sprinting = false
		end
	end
end

-- listen for sprinting
hook.Add("TTTPrepareRound", "TTTSprint4TTTPrepareRound", function()
	-- reset every round
	TTTSprint.percent = 100

	ConVars()

	-- listen for activation
	hook.Add("Think", "TTTSprint4Think", function()
		if LocalPlayer():KeyReleased(IN_FORWARD) and ActivateKey:GetFloat() == 4 then -- Double tap
			lastReleased = CurTime()
		end

		if ActivateKey:GetFloat() == 4 and LocalPlayer():KeyDown(IN_FORWARD) and (lastReleased + math.min(math.max(DoubleTapTime:GetFloat(), 0.001), 1) >= CurTime() or DoubleTapActivated) then
			SprintFunction()

			DoubleTapActivated = true
			TimerReg = CurTime()
		elseif LocalPlayer():KeyDown(IN_FORWARD) and SprintKey() then -- forward + selected key
			SprintFunction()

			DoubleTapActivated = false
			TimerReg = CurTime()
		else
			if TTTSprint.sprinting then -- not sprinting
				SpeedChange(false)
				TTTSprint.sprinting = false
				DoubleTapActivated = false
				TimerReg = CurTime()
			end

			TTTSprint.percent = TTTSprint.percent + (CurTime() - TimerReg) * (math.min(math.max(Regenerate, 0.01), 2) * 250)
			TimerReg = CurTime()
			DoubleTapActivated = false
		end

		if TTTSprint.percent < 0 then -- prevent bugs
			TTTSprint.percent = 0
			SpeedChange(false)
			TTTSprint.sprinting = false
			DoubleTapActivated = false
			TimerReg = CurTime()
		elseif TTTSprint.percent > 100 then
			TTTSprint.percent = 100
		end
	end)
end)

-- Settings
-- Presets
local function DefaultI()
	RunConsoleCommand("ttt_sprint_hud_allignment", "0")
	RunConsoleCommand("ttt_sprint_hud_offset_x", "15")
	RunConsoleCommand("ttt_sprint_hud_offset_y", "180")

	Key_box2:SetValue("Bottom, left")
end

local function DefaultII()
	RunConsoleCommand("ttt_sprint_hud_allignment", "0")
	RunConsoleCommand("ttt_sprint_hud_offset_x", tostring(ScrW() / 2 - 125))
	RunConsoleCommand("ttt_sprint_hud_offset_y", "60")

	Key_box2:SetValue("Bottom, left")
end

local function DefaultIII()
	RunConsoleCommand("ttt_sprint_hud_allignment", "3")
	RunConsoleCommand("ttt_sprint_hud_offset_x", "255")
	RunConsoleCommand("ttt_sprint_hud_offset_y", "60")

	Key_box2:SetValue("Bottom, right")
end

local function DefaultIV()
	RunConsoleCommand("ttt_sprint_hud_allignment", "0")
	RunConsoleCommand("ttt_sprint_hud_offset_x", "275")
	RunConsoleCommand("ttt_sprint_hud_offset_y", "60")

	Key_box2:SetValue("Bottom, left")
end

local function DefaultV()
	RunConsoleCommand("ttt_sprint_hud_allignment", "0")
	RunConsoleCommand("ttt_sprint_hud_offset_x", "275")
	RunConsoleCommand("ttt_sprint_hud_offset_y", "120")

	Key_box2:SetValue("Bottom, left")
end

local function DefaultVI()
	RunConsoleCommand("ttt_sprint_hud_allignment", "0")
	RunConsoleCommand("ttt_sprint_hud_offset_x", "275")
	RunConsoleCommand("ttt_sprint_hud_offset_y", "180")

	Key_box2:SetValue("Bottom, left")
end

local function DefaultIIa()
	local tmp = GetConVar("ttt2_base_hud_width")
	tmp = tmp and tmp:GetFloat() or 0

	RunConsoleCommand("ttt_sprint_hud_allignment", "0")
	RunConsoleCommand("ttt_sprint_hud_offset_x", tostring(ScrW() / 2 - (250 + tmp) / 2))
	RunConsoleCommand("ttt_sprint_hud_offset_y", "60")

	Key_box2:SetValue("Bottom, left")
end

local function DefaultIIIa()
	local tmp = GetConVar("ttt2_base_hud_width")
	tmp = tmp and tmp:GetFloat() or 0

	RunConsoleCommand("ttt_sprint_hud_allignment", "3")
	RunConsoleCommand("ttt_sprint_hud_offset_x", tostring(275 + tmp))
	RunConsoleCommand("ttt_sprint_hud_offset_y", "60")

	Key_box2:SetValue("Bottom, right")
end

local function DefaultIVa()
	local tmp = GetConVar("ttt2_base_hud_width")
	tmp = tmp and tmp:GetFloat() or 0

	RunConsoleCommand("ttt_sprint_hud_allignment", "0")
	RunConsoleCommand("ttt_sprint_hud_offset_x", tostring(300 + tmp))
	RunConsoleCommand("ttt_sprint_hud_offset_y", "60")

	Key_box2:SetValue("Bottom, left")
end

local function DefaultVa()
	local tmp = GetConVar("ttt2_base_hud_width")
	tmp = tmp and tmp:GetFloat() or 0

	RunConsoleCommand("ttt_sprint_hud_allignment", "0")
	RunConsoleCommand("ttt_sprint_hud_offset_x", tostring(300 + tmp))
	RunConsoleCommand("ttt_sprint_hud_offset_y", "120")

	Key_box2:SetValue("Bottom, left")
end

local function DefaultVIa()
	local tmp = GetConVar("ttt2_base_hud_width")
	tmp = tmp and tmp:GetFloat() or 0

	RunConsoleCommand("ttt_sprint_hud_allignment", "0")
	RunConsoleCommand("ttt_sprint_hud_offset_x", tostring(300 + tmp))
	RunConsoleCommand("ttt_sprint_hud_offset_y", "180")

	Key_box2:SetValue("Bottom, left")
end

-- Settings Hook
hook.Add("TTTSettingsTabs", "TTTSprint4TTTSettingsTabs", function(dtabs)
	local settings_panel = vgui.Create("DPanelList", dtabs)
	settings_panel:StretchToParent(0, 0, dtabs:GetPadding() * 2, 0)
	settings_panel:EnableVerticalScrollbar(true)
	settings_panel:SetPadding(10)
	settings_panel:SetSpacing(10)

	dtabs:AddSheet("Sprint", settings_panel, "icon16/arrow_up.png", false, false, "The sprint settings")

	local AddonList = vgui.Create("DIconLayout", settings_panel)
	AddonList:SetSpaceX(5)
	AddonList:SetSpaceY(5)
	AddonList:Dock(FILL)
	AddonList:DockMargin(5, 5, 5, 5)
	AddonList:DockPadding(10, 10, 10, 10)

	-- General Settings
	local General_Settings = vgui.Create("DForm")
	General_Settings:SetSpacing(10)
	General_Settings:SetName("General settings")
	General_Settings:SetWide(settings_panel:GetWide() - 30)

	settings_panel:AddItem(General_Settings)

	General_Settings:CheckBox("Print chat message at the beginning of the round (TTT FG Addons)", "ttt_fgaddons_textmessage")
	General_Settings:NumSlider("Crosshair debug size (0 = off)", "ttt_sprint_crosshairdebugsize", 0, 3, 1)

	-- Controls (Activation Method)
	local settings_sprint_tabII = vgui.Create("DForm")
	settings_sprint_tabII:SetSpacing(10)
	settings_sprint_tabII:SetName("Controls")
	settings_sprint_tabII:SetWide(settings_panel:GetWide() - 30)
	settings_panel:AddItem(settings_sprint_tabII)

	local Settings_text = vgui.Create("DLabel", General_Settings)
	Settings_text:SetText("Activation method:")
	Settings_text:SetColor(Color(0, 0, 0))
	settings_sprint_tabII:AddItem(Settings_text)

	-- Selection
	local Key_box = vgui.Create("DComboBox")

	local function Auswahl()
		if ActivateKey:GetFloat() == 0 then
			KeySelected = "Use Key"
		elseif ActivateKey:GetFloat() == 1 then
			KeySelected = "Shift Key"
		elseif ActivateKey:GetFloat() == 2 then
			KeySelected = "Control Key"
		elseif ActivateKey:GetFloat() == 3 then
			KeySelected = "Custom Key"
		elseif ActivateKey:GetFloat() == 4 then
			KeySelected = "Double tap"
		else
			KeySelected = " "
		end
	end

	-- Extra Options/Information
	local function KeySettingExtra()
		if KeySelected == "Custom Key" then
			settings_sprint_tabII:TextEntry("Key Number:", "ttt_sprint_activate_key_custom")

			local Link = vgui.Create("DLabelURL")
			Link:SetText("Key Numbers: https://wiki.garrysmod.com/page/Enums/KEY")
			Link:SetURL("https://wiki.garrysmod.com/page/Enums/KEY")

			settings_sprint_tabII:AddItem(Link)
		elseif KeySelected == "Double tap" then
			settings_sprint_tabII:NumSlider("Double tap time", "ttt_sprint_doubletaptime", 0.001, 1, 2)
		end
	end

	-- functions to refresh more easy
	local function ComboBox()
		settings_sprint_tabII:AddItem(Settings_text)

		Key_box:Clear()
		Key_box:SetValue(KeySelected)
		Key_box:AddChoice("Use Key")
		Key_box:AddChoice("Shift Key")
		Key_box:AddChoice("Control Key")
		Key_box:AddChoice("Custom Key")
		Key_box:AddChoice("Double tap")

		settings_sprint_tabII:AddItem(Key_box)
	end

	function Key_box:OnSelect(table_key_box, Ausgewaehlt, data_key_box)
		if Ausgewaehlt == "Use Key" then
			RunConsoleCommand("ttt_sprint_activate_key", "0")
		elseif Ausgewaehlt == "Shift Key" then
			RunConsoleCommand("ttt_sprint_activate_key", "1")
		elseif Ausgewaehlt == "Control Key" then
			RunConsoleCommand("ttt_sprint_activate_key", "2")
		elseif Ausgewaehlt == "Custom Key" then
			RunConsoleCommand("ttt_sprint_activate_key", "3")
		elseif Ausgewaehlt == "Double tap" then
			RunConsoleCommand("ttt_sprint_activate_key", "4")
		end

		settings_sprint_tabII:Clear()

		KeySelected = Ausgewaehlt

		ComboBox()
		KeySettingExtra()
	end

	Auswahl()
	ComboBox()
	KeySettingExtra()

	-- HUD Positioning
	local settings_sprint_tab = vgui.Create("DForm")
	settings_sprint_tab:SetSpacing(10)
	settings_sprint_tab:SetName("HUD Positioning")
	settings_sprint_tab:SetWide(settings_panel:GetWide() - 30)
	settings_panel:AddItem(settings_sprint_tab)

	local Settings_text2 = vgui.Create("DLabel", settings_sprint_tab)
	Settings_text2:SetText("Allignment:")
	Settings_text2:SetColor(Color(0, 0, 0))
	settings_sprint_tab:AddItem(Settings_text2)
	Key_box2 = vgui.Create("DComboBox")

	if allignment == 1 then
		KeySelected2 = "Top, left"
	elseif allignment == 2 then
		KeySelected2 = "Top, right"
	elseif allignment == 3 then
		KeySelected2 = "Bottom, right"
	else
		KeySelected2 = "Bottom, left"
	end

	Key_box2:Clear()
	Key_box2:SetValue(KeySelected2)
	Key_box2:AddChoice("Bottom, left")
	Key_box2:AddChoice("Top, left")
	Key_box2:AddChoice("Top, right")
	Key_box2:AddChoice("Bottom, right")

	settings_sprint_tab:AddItem(Key_box2)

	function Key_box2:OnSelect(table_key_box, Ausgewaehlt, data_key_box)
		if Ausgewaehlt == "Bottom, left" then
			RunConsoleCommand("ttt_sprint_hud_allignment", "0")
		elseif Ausgewaehlt == "Top, left" then
			RunConsoleCommand("ttt_sprint_hud_allignment", "1")
		elseif Ausgewaehlt == "Top, right" then
			RunConsoleCommand("ttt_sprint_hud_allignment", "2")
		elseif Ausgewaehlt == "Bottom, right" then
			RunConsoleCommand("ttt_sprint_hud_allignment", "3")
		end

		KeySelected2 = Ausgewaehlt
	end

	settings_sprint_tab:NumSlider("X Offset", "ttt_sprint_hud_offset_x", 0, ScrW(), 0)
	settings_sprint_tab:NumSlider("Y Offset", "ttt_sprint_hud_offset_y", 0, ScrH(), 0)

	if not TTT2 then
		local Settings_text_1 = vgui.Create("DLabel", General_Settings)
		Settings_text_1:SetText("Presets:")
		Settings_text_1:SetColor(Color(0, 0, 0))
		settings_sprint_tab:AddItem(Settings_text_1)

		local DefaultI_button = vgui.Create("DButton")
		DefaultI_button:SetText("On top of role")
		DefaultI_button.DoClick = DefaultI
		settings_sprint_tab:AddItem(DefaultI_button)

		local DefaultII_button = vgui.Create("DButton")
		DefaultII_button:SetText("Lower middle")
		DefaultII_button.DoClick = DefaultII
		settings_sprint_tab:AddItem(DefaultII_button)

		local DefaultIII_button = vgui.Create("DButton")
		DefaultIII_button:SetText("Lower right corner")
		DefaultIII_button.DoClick = DefaultIII
		settings_sprint_tab:AddItem(DefaultIII_button)

		local DefaultIV_button = vgui.Create("DButton")
		DefaultIV_button:SetText("Next to role")
		DefaultIV_button.DoClick = DefaultIV
		settings_sprint_tab:AddItem(DefaultIV_button)

		local DefaultV_button = vgui.Create("DButton")
		DefaultV_button:SetText("Next to role 2")
		DefaultV_button.DoClick = DefaultV
		settings_sprint_tab:AddItem(DefaultV_button)

		local DefaultVI_button = vgui.Create("DButton")
		DefaultVI_button:SetText("Next to role 3")
		DefaultVI_button.DoClick = DefaultVI
		settings_sprint_tab:AddItem(DefaultVI_button)
	else
		local Settings_text_1 = vgui.Create("DLabel", General_Settings)
		Settings_text_1:SetText("Presets (TTT2 Compatible):")
		Settings_text_1:SetColor(Color(0, 0, 0))
		settings_sprint_tab:AddItem(Settings_text_1)

		local DefaultI_button = vgui.Create("DButton")
		DefaultI_button:SetText("On top of role")
		DefaultI_button.DoClick = DefaultI
		settings_sprint_tab:AddItem(DefaultI_button)

		local DefaultII_button = vgui.Create("DButton")
		DefaultII_button:SetText("Lower middle")
		DefaultII_button.DoClick = DefaultIIa
		settings_sprint_tab:AddItem(DefaultII_button)

		local DefaultIII_button = vgui.Create("DButton")
		DefaultIII_button:SetText("Lower right corner")
		DefaultIII_button.DoClick = DefaultIIIa
		settings_sprint_tab:AddItem(DefaultIII_button)

		local DefaultIV_button = vgui.Create("DButton")
		DefaultIV_button:SetText("Next to role")
		DefaultIV_button.DoClick = DefaultIVa
		settings_sprint_tab:AddItem(DefaultIV_button)

		local DefaultV_button = vgui.Create("DButton")
		DefaultV_button:SetText("Next to role 2")
		DefaultV_button.DoClick = DefaultVa
		settings_sprint_tab:AddItem(DefaultV_button)

		local DefaultVI_button = vgui.Create("DButton")
		DefaultVI_button:SetText("Next to role 3")
		DefaultVI_button.DoClick = DefaultVIa
		settings_sprint_tab:AddItem(DefaultVI_button)
	end

	settings_sprint_tab:SizeToContents()

	local Version_text = vgui.Create("DLabel", General_Settings)
	Version_text:SetText("Version: " .. Version .. " by Fresh Garry")
	Version_text:SetColor(Color(100, 100, 100))

	settings_panel:AddItem(Version_text)
end)

-- Set Sprint Speed
hook.Add("TTTPlayerSpeedModifier", "TTTSprint4TTTPlayerSpeed", function(pl, _, _, noLag)
	if noLag then -- noLag is just supported by TTT2
		noLag[1] = noLag[1] * (pl.mult or 1)
	else
		return pl.mult
	end
end)
