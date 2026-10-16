local addonName = ...
local events = CreateFrame("Frame")
local hookedFrames = {}
local hookedChatFunctions = {}
local combatLogFrames = {}
local updatingCombatLogAlpha = {}
local hidingCombatLog = false
local updatingExperienceAlpha = {}
local auraFrames = {}
local updatingAuraAlpha = {}
local hookedAuraFunctions = {}
local hookedBobberTooltips = {}
local healthAlphaCurve
-- Numbers match the action bars in Blizzard's settings, not action pages.
local toolbarNames = { "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight",
    "MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7" }
if UnitHealthPercent and C_CurveUtil and C_CurveUtil.CreateCurve
    and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step then
    healthAlphaCurve = C_CurveUtil.CreateCurve()
    healthAlphaCurve:SetType(Enum.LuaCurveType.Step)
    healthAlphaCurve:AddPoint(0, 1)
    healthAlphaCurve:AddPoint(1, 0)
end
local targets = {
    ["fishing-bobber-tooltip"] = {
        setting = "hideFishingBobberTooltip",
        label = "Fishing bobber tooltip",
        frames = {},
        fishingBobberTooltip = true,
    },
    ["day-night-indicator"] = {
        setting = "hideDayNightIndicator",
        label = "Day-night indicator",
        frames = {},
        dayNightIndicator = true,
        enforceSetShown = true,
    },
    ["targetauras"] = {
        setting = "hideTargetAuras",
        label = "Target auras",
        frames = {},
        targetAuras = true,
    },
    ["addons-icon"] = {
        setting = "hideAddonsIcon",
        label = "Addons icon",
        frames = { "AddonCompartmentFrame" },
        enforceSetShown = true,
    },
    ["calendar-icon"] = {
        setting = "hideCalendarIcon",
        label = "Calendar icon",
        frames = { "GameTimeFrame" },
    },
    ["chat-bar"] = {
        setting = "hideChatInput",
        label = "Chat input",
        frames = {},
        chatInput = true,
    },
    ["chat-tabs"] = {
        setting = "hideChatTabs",
        label = "Chat tabs",
        frames = {},
        chatTabs = true,
    },
    ["chat-buttons"] = {
        setting = "hideChatButtons",
        label = "Chat buttons",
        frames = {},
        chatButtons = true,
    },
    ["exp-bar"] = {
        setting = "hideExpBar",
        label = "Status bars",
        frames = { "MainMenuExpBar", "ReputationWatchBar", "MainMenuBarMaxLevelBar" },
        experience = true,
    },
    ["bag-bar"] = {
        setting = "hideBagBar",
        label = "Bag bar",
        frames = { "BagsBar" },
    },
    ["micro-menu"] = {
        setting = "hideMicroMenu",
        label = "Micro menu",
        frames = { "MicroMenuContainer", "MicroMenu" },
    },
    ["player-frame"] = {
        setting = "hidePlayerFrame",
        label = "Player frame",
        frames = { "PlayerFrame" },
        conditional = true,
    },
    ["toolbars"] = {
        setting = "hideToolbars",
        label = "Toolbars",
        frames = {
            "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight",
            "MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7",
            "PetActionBar", "StanceBar", "PossessActionBar", "OverrideActionBar",
        },
        toolbars = true,
    },
}

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffHideMe:|r " .. message)
end

local function PrintHelp()
    Print("Available commands (on: enable hiding, off: disable hiding):")
    Print("/hideme all on - Set all supported hiding settings to on.")
    Print("/hideme all off - Set all supported hiding settings to off.")
    Print("/hideme addons-icon on - Hide the minimap addon compartment icon.")
    Print("/hideme addons-icon off - Show the minimap addon compartment icon.")
    Print("/hideme bag-bar on - Hide the bag bar.")
    Print("/hideme bag-bar off - Show the bag bar.")
    Print("/hideme calendar-icon on - Hide the minimap calendar icon.")
    Print("/hideme calendar-icon off - Show the minimap calendar icon.")
    Print("/hideme chat-bar on - Show chat input only while typing (press Return to start).")
    Print("/hideme chat-bar off - Always show the General chat input without taking focus.")
    Print("/hideme chat-buttons on - Hide standard chat buttons in all chat windows.")
    Print("/hideme chat-buttons off - Show standard chat buttons.")
    Print("/hideme chat-tabs on - Hide all standard chat tabs.")
    Print("/hideme chat-tabs off - Show only the General tab.")
    Print("/hideme day-night-indicator on - Hide the minimap day-night indicator.")
    Print("/hideme day-night-indicator off - Show the minimap day-night indicator.")
    Print("/hideme exp-bar on - Hide all status bars and borders permanently.")
    Print("/hideme exp-bar off - Always show available status bars and borders.")
    Print("/hideme fishing-bobber-tooltip on - Hide the fishing bobber tooltip.")
    Print("/hideme fishing-bobber-tooltip off - Show the fishing bobber tooltip normally.")
    Print("/hideme micro-menu on - Hide the micro menu.")
    Print("/hideme micro-menu off - Show the micro menu.")
    Print("/hideme player-frame on - Show with a target, in combat, or below full health.")
    Print("/hideme player-frame off - Always show the player frame.")
    Print("/hideme targetauras on - Hide target buffs and debuffs.")
    Print("/hideme targetauras off - Show available target buffs and debuffs.")
    Print("/hideme toolbars on - Show active action bars only with a target or in combat.")
    Print("/hideme toolbars off - Always show active action bars.")
    Print("/hideme except toolbar <1-8> - Also show this active bar below full health.")
    Print("/hideme except toolbar <1-8> off - Remove this exception.")
    Print("/hideme status - Show saved settings for all supported elements.")
    Print("/hideme help - Show this help.")
end

local function PrintStatus()
    Print("Current settings (on: enable hiding, off: disable hiding):")
    local names = {}
    for name in pairs(targets) do
        names[#names + 1] = name
    end
    table.sort(names)

    for _, name in ipairs(names) do
        local target = targets[name]
        local hidden = HideMeDB and HideMeDB[target.setting] == true
        local state = hidden and "on (hiding enabled)" or "off (hiding disabled)"
        if target.chatTabs then
            state = hidden and "on (all tabs hidden)" or "off (General tab only)"
        end
        if target.pending then
            if InCombatLockdown() then
                state = state .. " - Pending until combat ends"
            else
                state = state .. " - Pending: UI element not loaded yet"
            end
        end
        Print(name .. " - " .. target.label .. ": " .. state)
    end
    for number = 1, #toolbarNames do
        if HideMeDB and HideMeDB.toolbarExceptions and HideMeDB.toolbarExceptions[number] then
            Print("except toolbar " .. number .. " - Also visible below full health"
                .. (targets.toolbars.pending and " - Pending toolbar update" or ""))
        end
    end
end

local function PlayerNeedsFrame()
    return InCombatLockdown() or UnitExists("target")
end

local function ShouldHide(target, frame)
    if target.chatTabs then
        -- Identify the default General window without relying on localized names.
        local generalTab = _G.ChatFrame1Tab or (_G.ChatFrame1 and _G.ChatFrame1.tab)
        return HideMeDB and (HideMeDB[target.setting] or frame ~= generalTab)
    end
    return HideMeDB and HideMeDB[target.setting]
        and (not target.conditional or not PlayerNeedsFrame())
end

local function UpdatePlayerAlpha(frame, target)
    if not healthAlphaCurve then return end
    if not target.appliedHiding or PlayerNeedsFrame() then
        frame:SetAlpha(1)
    else
        -- Pass the engine-evaluated result directly; never inspect secret health.
        frame:SetAlpha(UnitHealthPercent("player", false, healthAlphaCurve))
    end
end

local function UpdateToolbarAlpha(frame, target)
    for number, name in ipairs(toolbarNames) do
        if frame == _G[name] and target.appliedExceptions and target.appliedExceptions[number] then
            if healthAlphaCurve then
                UpdatePlayerAlpha(frame, target)
                return
            end
            break
        end
    end
    local hidden = target.appliedHiding and not PlayerNeedsFrame()
    frame:SetAlpha(hidden and 0 or 1)
end

local function ApplyToolbars(target)
    local combat = InCombatLockdown()
    if not combat then
        target.appliedHiding = HideMeDB[target.setting]
        target.appliedExceptions = {}
        for number = 1, #toolbarNames do
            target.appliedExceptions[number] = HideMeDB.toolbarExceptions
                and HideMeDB.toolbarExceptions[number] == true or false
        end
    end
    local found = false
    for _, frameName in ipairs(target.frames) do
        local frame = _G[frameName]
        if frame then
            found = true
            -- Preserve Blizzard's activation, paging and special-bar visibility.
            UpdateToolbarAlpha(frame, target)
            if not hookedFrames[frame] and not combat then
                hooksecurefunc(frame, "Show", function(self)
                    UpdateToolbarAlpha(self, target)
                end)
                hookedFrames[frame] = true
            end
        end
    end
    target.pending = combat or not found
    return found
end

local function GetExperienceFrames(target)
    -- Gate the complete manager so borders and every status-bar type disappear.
    if _G.StatusTrackingBarManager then
        return { _G.StatusTrackingBarManager }
    end
    local frames, seen = {}, {}
    local function Add(frame)
        if frame and not seen[frame] then
            frames[#frames + 1] = frame
            seen[frame] = true
        end
    end
    for _, name in ipairs(target.frames) do Add(_G[name]) end
    return frames
end

local function UpdateExperienceAlpha(frame, target)
    updatingExperienceAlpha[frame] = true
    frame:SetAlpha(target.appliedHiding and 0 or 1)
    updatingExperienceAlpha[frame] = nil
end

local function ApplyExperience(target)
    local combat = InCombatLockdown()
    if not combat then
        target.appliedHiding = HideMeDB[target.setting]
    end
    local frames = GetExperienceFrames(target)
    for _, frame in ipairs(frames) do
        UpdateExperienceAlpha(frame, target)
        if not hookedFrames[frame] and not combat then
            hooksecurefunc(frame, "Show", function(self)
                UpdateExperienceAlpha(self, target)
            end)
            hooksecurefunc(frame, "SetAlpha", function(self)
                if target.appliedHiding and not updatingExperienceAlpha[self] then
                    UpdateExperienceAlpha(self, target)
                end
            end)
            hookedFrames[frame] = true
        end
    end
    target.pending = combat or #frames == 0
    return #frames > 0
end

local function GetTargetFrames(target)
    local frames, seen = {}, {}
    local function Add(frame)
        if frame and not seen[frame] then
            frames[#frames + 1] = frame
            seen[frame] = true
        end
    end
    for _, name in ipairs(target.frames) do Add(_G[name]) end
    if target.dayNightIndicator then
        Add(_G.MinimapCluster and _G.MinimapCluster.DielFrame)
    end
    if target.chatButtons then
        for _, name in ipairs({ "ChatFrameMenuButton", "ChatFrameChannelButton",
            "QuickJoinToastButton", "ChatFrameToggleVoiceDeafenButton",
            "ChatFrameToggleVoiceMuteButton" }) do
            Add(_G[name])
        end
    end
    if target.chatButtons or target.chatTabs or target.chatInput then
        local names = {}
        for i = 1, NUM_CHAT_WINDOWS or 10 do names[#names + 1] = "ChatFrame" .. i end
        for _, name in ipairs(CHAT_FRAMES or {}) do names[#names + 1] = name end
        for _, name in ipairs(names) do
            if target.chatInput then
                Add(_G[name .. "EditBox"])
                local chat = _G[name]
                if chat then Add(chat.editBox) end
            elseif target.chatTabs then
                Add(_G[name .. "Tab"])
                local chat = _G[name]
                if chat then Add(chat.tab) end
            else
                Add(_G[name .. "ButtonFrame"])
                Add(_G[name .. "ScrollToBottomButton"])
                Add(_G[name .. "MinimizeButton"])
                local chat = _G[name]
                if chat then
                    Add(chat.buttonFrame)
                    Add(chat.ScrollBar)
                    Add(chat.ScrollToBottomButton)
                end
            end
        end
    end
    return frames
end

local function ApplyChatInput(target)
    if InCombatLockdown() then
        target.pending = true
        return
    end
    local frames = GetTargetFrames(target)
    local primary = _G.ChatFrame1EditBox or (_G.ChatFrame1 and _G.ChatFrame1.editBox)
    for _, frame in ipairs(frames) do
        if not hookedFrames[frame] then
            -- Never hide from a Show hook: Blizzard shows the box before focusing it.
            frame:HookScript("OnEditFocusLost", function(self)
                if not HideMeDB then return end
                if InCombatLockdown() then
                    target.pending = true
                elseif HideMeDB[target.setting] then
                    self:Hide()
                end
            end)
            hooksecurefunc(frame, "Hide", function(self)
                local general = _G.ChatFrame1EditBox or (_G.ChatFrame1 and _G.ChatFrame1.editBox)
                if HideMeDB and not HideMeDB[target.setting] and self == general then
                    if InCombatLockdown() then
                        target.pending = true
                    else
                        -- Show does not activate chat or capture keyboard focus.
                        self:Show()
                    end
                end
            end)
            hookedFrames[frame] = true
        end
        if not frame:HasFocus() then
            if not HideMeDB[target.setting] and frame == primary then
                frame:Show()
            else
                frame:Hide()
            end
        end
    end
    target.pending = #frames == 0
    return #frames > 0
end

local function ApplyTargetAuras(target)
    local combat = InCombatLockdown()
    if not combat then target.appliedHiding = HideMeDB[target.setting] end
    local found = false
    local function Update(frame)
        updatingAuraAlpha[frame] = true
        frame:SetAlpha(target.appliedHiding and 0 or 1)
        updatingAuraAlpha[frame] = nil
    end
    local function Add(frame)
        if not frame then return end
        found = true
        Update(frame)
        if not auraFrames[frame] and not combat then
            hooksecurefunc(frame, "Show", function(self) Update(self) end)
            hooksecurefunc(frame, "SetAlpha", function(self)
                if target.appliedHiding and not updatingAuraAlpha[self] then Update(self) end
            end)
            auraFrames[frame] = true
        end
    end
    for frame in pairs(auraFrames) do Update(frame) end
    -- Change alpha only: never reveal unused buttons or inspect aura data.
    for i = 1, MAX_TARGET_BUFFS or 32 do Add(_G["TargetFrameBuff" .. i]) end
    for i = 1, MAX_TARGET_DEBUFFS or 32 do Add(_G["TargetFrameDebuff" .. i]) end
    local frame = _G.TargetFrame
    -- Forever renders both aura types inside one container, not named buttons.
    if frame then
        local content = frame.TargetFrameContent
        local contextual = content and content.TargetFrameContentContextual
        Add(contextual and contextual.Auras)
    end
    if frame and frame.auraPools then
        for aura in frame.auraPools:EnumerateActive() do Add(aura) end
    end
    if not combat then
        if type(_G.TargetFrame_UpdateAuras) == "function" and not hookedAuraFunctions.legacy then
            hooksecurefunc("TargetFrame_UpdateAuras", function(self)
                if self == _G.TargetFrame and HideMeDB then ApplyTargetAuras(target) end
            end)
            hookedAuraFunctions.legacy = true
        end
        if frame then
            hookedAuraFunctions[frame] = hookedAuraFunctions[frame] or {}
            for _, method in ipairs({ "UpdateAuras", "UpdateAuraFrames", "ConfigureAuraContainer" }) do
                if type(frame[method]) == "function" and not hookedAuraFunctions[frame][method] then
                    -- Classic creates named buttons inside UpdateAuras, after our event may run.
                    hooksecurefunc(frame, method, function()
                        if HideMeDB then ApplyTargetAuras(target) end
                    end)
                    hookedAuraFunctions[frame][method] = true
                end
            end
        end
    end
    target.pending = combat or not found
    return found
end

-- World-object tooltips use the first line for their localized object name.
local function HideFishingBobberTooltip(tooltip, target)
    if not target.appliedHiding then return end
    if tooltip:GetOwner() ~= _G.UIParent then return end
    local line = _G.GameTooltipTextLeft1
    local text = line and line:GetText()
    if issecretvalue and issecretvalue(text) then return end
    if type(text) ~= "string" then return end
    local name = _G.FISHING_BOBBER
    if issecretvalue and issecretvalue(name) then name = nil end
    if text == "Fishing Bobber" or text == "Angelschwimmer"
        or (type(name) == "string" and text == name) then
        tooltip:Hide()
    end
end

local function ApplyFishingBobberTooltip(target)
    if InCombatLockdown() then
        target.pending = true
        return
    end
    local tooltip = _G.GameTooltip
    if not tooltip then
        target.pending = true
        return false
    end
    target.appliedHiding = HideMeDB[target.setting]
    if not hookedBobberTooltips[tooltip] then
        -- OnUpdate also catches content changes while the tooltip stays shown.
        tooltip:HookScript("OnShow", function(self) HideFishingBobberTooltip(self, target) end)
        tooltip:HookScript("OnUpdate", function(self) HideFishingBobberTooltip(self, target) end)
        hookedBobberTooltips[tooltip] = true
    end
    -- Off leaves normal mouseover handling in charge; never show stale content.
    if tooltip:IsShown() then HideFishingBobberTooltip(tooltip, target) end
    target.pending = false
    return true
end

local function ApplyTarget(target)
    if target.fishingBobberTooltip then return ApplyFishingBobberTooltip(target) end
    if target.targetAuras then return ApplyTargetAuras(target) end
    if target.chatInput then
        return ApplyChatInput(target)
    end
    if target.experience then
        return ApplyExperience(target)
    end
    if target.toolbars then
        return ApplyToolbars(target)
    end
    if InCombatLockdown() then
        if target.conditional and _G.PlayerFrame then
            UpdatePlayerAlpha(_G.PlayerFrame, target)
        end
        target.pending = true
        return
    end

    local found = false
    for _, frame in ipairs(GetTargetFrames(target)) do
        if frame then
            found = true
            if not hookedFrames[frame] then
                hooksecurefunc(frame, "Show", function(self)
                    if target.conditional and healthAlphaCurve then
                        UpdatePlayerAlpha(self, target)
                    elseif ShouldHide(target, self) then
                        if InCombatLockdown() then
                            target.pending = true
                        else
                            self:Hide()
                        end
                    end
                end)
                if target.enforceSetShown then
                    hooksecurefunc(frame, "SetShown", function(self)
                        if ShouldHide(target, self) then
                            if InCombatLockdown() then
                                target.pending = true
                            else
                                self:Hide()
                            end
                        end
                    end)
                end
                hookedFrames[frame] = true
            end

            if target.conditional then
                target.appliedHiding = HideMeDB[target.setting]
                -- The secure driver shows the protected frame during combat as well.
                local driver = not healthAlphaCurve and HideMeDB[target.setting]
                    and "[combat] show; [@target,exists] show; hide" or "show"
                RegisterStateDriver(frame, "visibility", driver)
            end

            if target.conditional and healthAlphaCurve then
                UpdatePlayerAlpha(frame, target)
                frame:Show()
            elseif ShouldHide(target, frame) then
                frame:Hide()
            else
                frame:Show()
            end
        end
    end
    target.pending = not found
    return found
end

local function HideCombatLog()
    if hidingCombatLog then return end
    hidingCombatLog = true
    local log = _G.ChatFrame2
    if log and not InCombatLockdown() and _G.ChatFrame1 then
        if (SELECTED_CHAT_FRAME == log or SELECTED_DOCK_FRAME == log)
            and type(FCF_SelectDockFrame) == "function" then
            FCF_SelectDockFrame(_G.ChatFrame1)
            if SELECTED_CHAT_FRAME == log then SELECTED_CHAT_FRAME = _G.ChatFrame1 end
        end
    end
    local frames = {
        log, _G.ChatFrame2Tab, _G.CombatLogQuickButtonFrame_Custom,
        _G.ChatFrame2EditBox, _G.ChatFrame2ButtonFrame,
    }
    -- Explicit indices also handle optional frames missing in the middle.
    for i = 1, 5 do
        local frame = frames[i]
        if frame then
            updatingCombatLogAlpha[frame] = true
            frame:SetAlpha(0)
            updatingCombatLogAlpha[frame] = nil
            if not InCombatLockdown() then
                if not combatLogFrames[frame] then
                    hooksecurefunc(frame, "Show", HideCombatLog)
                    hooksecurefunc(frame, "SetAlpha", function(self)
                        if not updatingCombatLogAlpha[self] then HideCombatLog() end
                    end)
                    combatLogFrames[frame] = true
                end
                frame:Hide()
            end
        end
    end
    hidingCombatLog = false
end

local function ApplyTargets(pendingOnly)
    if not HideMeDB then return end
    for _, target in pairs(targets) do
        if not pendingOnly or target.pending then
            ApplyTarget(target)
        end
    end
    HideCombatLog()
    if not InCombatLockdown() then
        for _, name in ipairs({ "FCF_OpenNewWindow", "FCF_OpenTemporaryWindow" }) do
            if type(_G[name]) == "function" and not hookedChatFunctions[name] then
                hooksecurefunc(name, function()
                    if HideMeDB then
                        ApplyTarget(targets["chat-buttons"])
                        ApplyTarget(targets["chat-tabs"])
                        ApplyTarget(targets["chat-bar"])
                        HideCombatLog()
                    end
                end)
                hookedChatFunctions[name] = true
            end
        end
    end
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("UNIT_HEALTH")
events:RegisterEvent("UNIT_MAXHEALTH")
events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("UPDATE_CHAT_WINDOWS")
events:RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS")
events:SetScript("OnEvent", function(_, event, loadedAddon)
    HideCombatLog()
    if event == "ADDON_LOADED" then
        if loadedAddon == addonName then
            if type(HideMeDB) ~= "table" then
                HideMeDB = {}
            end
            for _, target in pairs(targets) do
                HideMeDB[target.setting] = HideMeDB[target.setting] == true
            end
            local saved = HideMeDB.toolbarExceptions
            HideMeDB.toolbarExceptions = {}
            for number = 1, #toolbarNames do
                HideMeDB.toolbarExceptions[number] = type(saved) == "table" and saved[number] == true
            end
        else
            ApplyTargets(true)
            -- Optional action bars may be loaded after the main UI.
            if HideMeDB then ApplyTarget(targets["toolbars"]) end
            if HideMeDB then ApplyTarget(targets["exp-bar"]) end
            if HideMeDB then ApplyTarget(targets["chat-buttons"]) end
            if HideMeDB then ApplyTarget(targets["chat-tabs"]) end
            if HideMeDB then ApplyTarget(targets["chat-bar"]) end
            if HideMeDB then ApplyTarget(targets.targetauras) end
        end
    elseif event == "UNIT_AURA" then
        if loadedAddon == "target" and HideMeDB then ApplyTargetAuras(targets.targetauras) end
    elseif event == "UPDATE_CHAT_WINDOWS" or event == "UPDATE_FLOATING_CHAT_WINDOWS" then
        if HideMeDB then
            ApplyTarget(targets["chat-buttons"])
            ApplyTarget(targets["chat-tabs"])
            ApplyTarget(targets["chat-bar"])
            HideCombatLog()
        end
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_TARGET_CHANGED"
        or event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        if HideMeDB and (event ~= "UNIT_HEALTH" and event ~= "UNIT_MAXHEALTH"
            or loadedAddon == "player") then
            ApplyTarget(targets["player-frame"])
            ApplyTarget(targets["toolbars"])
            if event == "PLAYER_TARGET_CHANGED" then ApplyTargetAuras(targets.targetauras) end
        end
    else
        ApplyTargets(event == "PLAYER_REGEN_ENABLED")
        if event == "PLAYER_REGEN_ENABLED" and HideMeDB then
            ApplyTarget(targets["player-frame"])
        end
    end
end)

SLASH_HIDEME1 = "/hideme"
SlashCmdList.HIDEME = function(message)
    message = message:lower():match("^%s*(.-)%s*$")
    if message == "help" or message == "" then
        PrintHelp()
        return
    end

    if message == "status" then
        PrintStatus()
        return
    end

    if message:match("^except%s") or message == "except" then
        local number, mode = message:match("^except%s+toolbar%s+([1-8])%s+(%S+)$")
        if not number then
            number = message:match("^except%s+toolbar%s+([1-8])$")
            mode = ""
        end
        if not number or (mode ~= "" and mode ~= "off") then
            Print("Invalid command. Use /hideme except toolbar <1-8> [off].")
            return
        end
        number = tonumber(number)
        HideMeDB.toolbarExceptions = HideMeDB.toolbarExceptions or {}
        HideMeDB.toolbarExceptions[number] = mode ~= "off"
        ApplyToolbars(targets.toolbars)
        local text = "Toolbar " .. number .. " health exception " .. (mode == "off" and "removed." or "saved.")
        if InCombatLockdown() then
            text = text .. " The change will take effect after combat."
        elseif not _G[toolbarNames[number]] then
            text = text .. " The toolbar is not loaded yet."
        end
        if mode ~= "off" then
            text = text .. " Applies while toolbar hiding is on."
            if not healthAlphaCurve then text = text .. " Health API unavailable; target/combat visibility only." end
        end
        Print(text)
        return
    end

    local name, mode = message:match("^%s*(%S+)%s+(%S+)%s*$")
    local target = targets[name]
    if (not target and name ~= "all") or (mode ~= "on" and mode ~= "off") then
        Print("Invalid command. For usage and available parameters, type /hideme help")
        return
    end

    if name == "all" then
        -- Save every mode before applying frames so hooks see consistent settings.
        for _, entry in pairs(targets) do
            HideMeDB[entry.setting] = mode == "on"
        end
        ApplyTargets()
        local pending = false
        for _, entry in pairs(targets) do
            pending = pending or entry.pending
        end
        local message = "All supported hiding settings are set to " .. mode .. "."
        if InCombatLockdown() then
            message = message .. " Changes will take effect after combat."
        elseif pending then
            message = message .. " Unloaded UI elements will be updated when available."
        end
        Print(message)
        return
    end

    HideMeDB[target.setting] = mode == "on"
    local found = ApplyTarget(target)
    HideCombatLog()
    local action = HideMeDB[target.setting] and "hidden." or "shown."
    if target.conditional then
        action = HideMeDB[target.setting]
            and (healthAlphaCurve and "shown with a target, in combat, or below full health."
                or "shown only with a target or in combat (health API unavailable).")
            or "always shown."
    elseif target.chatInput then
        action = HideMeDB[target.setting]
            and "shown only while typing (press Return to start)."
            or "always shown for the General window without taking focus."
    elseif target.chatTabs then
        action = HideMeDB[target.setting] and "all hidden." or "shown only for the General window."
    elseif target.toolbars then
        action = HideMeDB[target.setting]
            and "shown only with a target or in combat."
            or "always shown when active."
    elseif target.experience then
        action = HideMeDB[target.setting]
            and "hidden permanently."
            or "always shown when available."
    end
    if InCombatLockdown() then
        Print(target.label .. " will be " .. action .. " The change will take effect after combat.")
    elseif not found then
        Print(target.label .. " is not loaded yet. The setting has been saved.")
    else
        Print(target.label .. " is " .. action)
    end
end
