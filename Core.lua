-- Name: BreakTime!
-- Author: Akarficus (Hekita) of Dawnbringer
-- Desc: This addon outputs a message to remind a user when to take a break. Also, it can play a selection of sound files when the event is fired
--		 and it allows users to set a custom message to be displayed following the default break message.

local secs = 0
local mins = 0
local hrs = 0

BreakTime = LibStub("AceAddon-3.0"):NewAddon("BreakTime", "AceConsole-3.0", "AceTimer-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BreakTime", true)

-- changed fire time to a dropdown box
local options = {
    name = "Breaktime",
    handler = BreakTime,
    type = "group",
    args = {
        --msg = {
            --type = "input",
            --name = "Message",
            --desc = "The message to be displayed when the timer goes off.",
            --usage = "<Your message>",
            --get = function(info) return BreakTime.message end,
            --set = function(info, newValue) BreakTime.message = newValue end,
        --},
		showInChat = {
				type = "toggle",
				name = L["Show in Chat"],
				desc = L["Toggles the display of the message in the chat window."],
				get = "IsShowInChat",
				set = "ToggleShowInChat",
			},
		showOnScreen = {
				type = "toggle",
				name = L["Show on Screen"],
				desc = L["Toggles the display of the message on the screen."],
				get = "IsShowOnScreen",
				set = "ToggleShowOnScreen"
			},
		fireTime = {
			type = "select",
			name = L["Fire Time"],
			desc = L["How often the message is displayed."],
			order = 0,
			style = "dropdown",
			values = {
				["A300"] = "5" .. L[" minutes"],
				["B600"] = "10" .. L[" minutes"],
				["C900"] = "15" .. L[" minutes"],
				["D1800"] = "30" .. L[" minutes"],
				["E2700"] = "45" .. L[" minutes"],
				["F3600"] = "1" .. L[" hour"],
				["G7200"] = "2" .. L[" hours"],
			},
			get = "GetFireTime",
			set = "SetFireTime",
		},
		customMessage = {
			type = "input",
			name = L["Custom Message"],
			desc = L["Change the default message here."],
			usage = L["Special Characters: @hr = hours and @min = minutes"],
			width = "full",
			get = "GetCustomMessage",
			set = "SetCustomMessage",
		},
		soundOptions = {
			type = "select",
			name = L["Sound Options"],
			desc = L["Choose what sound (if any) that will play when the message fires"],
			order = 0,
			style = "dropdown",
			values = {
				-- None is named "!None" to put it at the top of the list
				-- Using special characters helps to group the options that are relavant to each other
				["!None"] = L["None"],
				["#8463"] = L["Battlegrounds Ready"],
				["#619"] = L["Quest Complete"],
				["#8959"] = L["Raid Warning"],
				["#8960"] = L["Ready Check"],
				["#124"] = L["Level up"],
				["#11466"] = L["You Are Not Prepared!"],
				["#14808"] = L["APOCALYPSE!"],
				["@540697"] = L["Human Male Roar"],
				["@540497"] = L["Gnome Male Roar"],
				["@540087"] = L["Dwarf Male Roar"],
				["@541132"] = L["Night Elf Male Roar"],
				["@541398"] = L["Orc Male Roar"],
				["@543062"] = L["Tauren Male Roar"],
				["@543311"] = L["Troll Male Roar"],
				["@542740"] = L["Undead Male Roar"],
				["@541635"] = L["Gilnean Male Roar"],
				["@541876"] = L["Goblin Male Roar"],
				["@564571"] = L["Worgen Male Roar"],
				["@539230"] = L["Blood Elf Male Roar"],
				["@539502"] = L["Draenei Male Roar"],
				["$95680"] = L["Void Elf Male Roar"],
				["$96262"] = L["Lightforged Draenei Male Roar"],
				["$101971"] = L["Dark Iron Dwarf Male Roar"],
				["$127140"] = L["Kul Tiran Male Roar"],
				["$143901"] = L["Mechagnome Male Roar"],
				["$96398"] = L["Nightborne Male Roar"],
				["$95828"] = L["Highmountain Tauren Male Roar"],
				["$110408"] = L["Mag'har Orc Male Roar"],
				["$127327"] = L["Zandalari Troll Male Roar"],
				["$144120"] = L["Vulpera Male Roar"],
				["@543016"] = L["Tauren Female Roar"],
				["@541347"] = L["Orc Female Roar"],
				["@542680"] = L["Undead Female Roar"],
				["@539992"] = L["Dwarf Female Roar"],
				["@540457"] = L["Gnome Female Roar"],
				["@540615"] = L["Human Female Roar"],
				["@541072"] = L["Night Elf Female Roar"],
				["@539269"] = L["Blood Elf Female Roar"],
				["@539693"] = L["Draenei Female Roar"],
				["@543226"] = L["Troll Female Roar"],
				["@564397"] = L["Worgen Female Roar"],
				["@541485"] = L["Gilnean Female Roar"],
				["@541811"] = L["Goblin Female Roar"],
				["$95884"] = L["Void Elf Female Roar"],
				["$96194"] = L["Lightforged Draenei Female Roar"],
				["$101897"] = L["Dark Iron Dwarf Female Roar"],
				["$127046"] = L["Kul Tiran Female Roar"],
				["$144284"] = L["Mechagnome Female Roar"],
				["$96330"] = L["Nightborne Female Roar"],
				["$95558"] = L["Highmountain Tauren Female Roar"],
				["$110333"] = L["Mag'har Orc Female Roar"],
				["$126953"] = L["Zandalari Troll Female Roar"],
				["$144028"] = L["Vulpera Female Roar"],
			},
			get = "GetSoundChoice",
			set = "SetSoundChoice",
		},
		resetTimer = {
			type = "execute",
			name = L["Reset Timer"],
			desc = L["This will reset the timer"],
			order = -1,
			func = "ResetTimer",
		},
    },
}

local defaults = {
    profile = {
		fireTime = "F3600",
		customMessage = "You have been playing for @hr and @min. Please take a break.",
		soundOptions = "!None",
        showInChat = true,
        showOnScreen = false,
    },
}

-- Contains the reference to the option frame displayed in Blizzard's options panel
local optionsFrame

function BreakTime:OnInitialize()
    -- Called when the addon is loaded
    self.db = LibStub("AceDB-3.0"):New("BreakTimeDB", defaults, "Default")
    
    LibStub("AceConfig-3.0"):RegisterOptionsTable("BreakTime", options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BreakTime", "BreakTime")
    self:RegisterChatCommand("breaktime", "ChatCommand")
    self:RegisterChatCommand("bkt", "ChatCommand")
end

function BreakTime:OnEnable()
    -- Called when the addon is enabled
	-- Schedules a timer to call the "CheckBreakEvent" function every second
    self:ScheduleRepeatingTimer("CheckBreakEvent", 1)
end

function BreakTime:OnDisable()
    -- Called when the addon is disabled
	-- Stops timers and resets the second counter
    self:CancelAllTimers()
    self:ResetTimer()
end

function BreakTime:GetSoundChoice(info)
	return self.db.profile.soundOptions
end

function BreakTime:SetSoundChoice(info, key)
	self.db.profile.soundOptions = key
	-- check to see if the sound needs to use either "PlaySound" or "PlaySoundFile" to play it properly
	if strsub(key, 1, 1) == "#" or strsub(key, 1, 1) == "$" then
		PlaySound(strsub(key, 2))
	elseif strsub(key, 1, 1) == "@" then
		PlaySoundFile(strsub(key, 2))
	end
end

function BreakTime:GetCustomMessage(info)
    return self.db.profile.customMessage
end

function BreakTime:SetCustomMessage(info, value)
    self.db.profile.customMessage = value
end

function BreakTime:GetFireTime(info)
    return self.db.profile.fireTime
end

function BreakTime:SetFireTime(info, newValue)
    self.db.profile.fireTime = newValue
    secs = 0
end

function BreakTime:IsShowInChat(info)
    return self.db.profile.showInChat
end

function BreakTime:ToggleShowInChat(info, value)
    self.db.profile.showInChat = value
end

function BreakTime:IsShowOnScreen(info)
    return self.db.profile.showOnScreen
end

function BreakTime:ToggleShowOnScreen(info, value)
    self.db.profile.showOnScreen = value
end

function BreakTime:ChatCommand(input)
    if not input or input:trim() == "" then
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
	elseif input == "help" then
		self:Print(L["The commands are help, resetTimer, gui, showInChat, showOnScreen, fireTime, customMessage, and soundOptions"])
	elseif input == "gui" then
		LibStub("AceConfigDialog-3.0"):Open("BreakTime")
    else
        LibStub("AceConfigCmd-3.0").HandleCommand(BreakTime, "bkt", "BreakTime", input)
    end
end

function BreakTime:ResetTimer()
	secs = 0
	mins = 0
	hrs = 0
	self:Print(L["Timer has been reset"])
end

-- Function to create and show the custom widget
function BreakTime:ShowBreakWidget(message)
    if not BreakTimeFrame then
        -- If the frame is not created, show an error or handle it
        self:Print("BreakTimeFrame not found!")
        return
    end

    -- Set the message and show the frame
    BreakTimeFrameText:SetText(message)
    BreakTimeFrame:Show()

    -- Hide the frame after a certain time (e.g., 10 seconds)
    C_Timer.After(10, function() BreakTimeFrame:Hide() end)
end

--This is assciated with a timer that fires every sec. When the seconds counter reaches the fireTime, it sends a message to the user.
function BreakTime:CheckBreakEvent()
	-- increment seconds counter by one
	secs = secs + 1
	if secs % string.format("%i", strsub(self.db.profile.fireTime, 2)) == 0 then
		-- convert seconds counter to hours
		newhrs = secs / 60 / 60
		hrs = math.floor(newhrs)
		-- convert seconds counter to minutes
		newmins = secs / 60
		mins = math.floor(newmins)
		
		-- converts the minutes counter to show the correct amount of minutes
		-- ex. 75 minutes - 60 minutes = 15 minutes
		if mins >= 60 then
			mins = mins - (hrs * 60)
		end
		
		-- replace "@hr" with the calculated hours from above
		if hrs == 1 then
			tmpStr = string.gsub(self.db.profile.customMessage, "@hr", hrs .. L[" hour"])
		else
			tmpStr = string.gsub(self.db.profile.customMessage, "@hr", hrs .. L[" hours"])
		end
		
		-- replace "@min" with the calculated minutes found above
		if mins == 1 then
			tmpStr = string.gsub(tmpStr, "@min", mins .. L[" minute"])
		else
			tmpStr = string.gsub(tmpStr, "@min", mins .. L[" minutes"])
		end
		-- display the break message in the chat if it is enabled
		if self.db.profile.showInChat then
			self:Print(tmpStr)
		end
		-- display the break message on the screen on the UIErrorsFrame. Who would have thunk it?
		if self.db.profile.showOnScreen then
			self:ShowBreakWidget(tmpStr)
		end
		-- Using special characters helps to group the options that are relavant to each other
		if strsub(self.db.profile.soundOptions, 1, 1) == "#" or strsub(self.db.profile.soundOptions, 1, 1) == "$"then
			PlaySound(strsub(self.db.profile.soundOptions, 2))
		elseif strsub(self.db.profile.soundOptions, 1, 1) == "@" then
			PlaySoundFile(strsub(self.db.profile.soundOptions, 2))
		end
	end
end

