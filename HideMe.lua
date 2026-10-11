local addonName = ...
local events = CreateFrame("Frame")
local hookedFrames = {}
local updatingExperienceAlpha = {}
local healthAlphaCurve
if UnitHealthPercent and C_CurveUtil and C_CurveUtil.CreateCurve
    and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step then
    healthAlphaCurve = C_CurveUtil.CreateCurve()
    healthAlphaCurve:SetType(Enum.LuaCurveType.Step)
    healthAlphaCurve:AddPoint(0, 1)
    healthAlphaCurve:AddPoint(1, 0)
end
local targets = {
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
    Print("/hideme bag-bar on - Hide the bag bar.")
    Print("/hideme bag-bar off - Show the bag bar.")
    Print("/hideme exp-bar on - Show all status bars and borders for 2 seconds after XP changes.")
    Print("/hideme exp-bar off - Always show available status bars and borders.")
    Print("/hideme micro-menu on - Hide the micro menu.")
    Print("/hideme micro-menu off - Show the micro menu.")
    Print("/hideme player-frame on - Show with a target, in combat, or below full health.")
    Print("/hideme player-frame off - Always show the player frame.")
    Print("/hideme toolbars on - Show active action bars only with a target or in combat.")
    Print("/hideme toolbars off - Always show active action bars.")
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
        if target.pending then
            if InCombatLockdown() then
                state = state .. " - Pending until combat ends"
            else
                state = state .. " - Pending: UI element not loaded yet"
            end
        end
        Print(name .. " - " .. target.label .. ": " .. state)
    end
end

local function PlayerNeedsFrame()
    return InCombatLockdown() or UnitExists("target")
end

local function ShouldHide(target)
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
    local hidden = target.appliedHiding and not PlayerNeedsFrame()
    frame:SetAlpha(hidden and 0 or 1)
end

local function ApplyToolbars(target)
    local combat = InCombatLockdown()
    if not combat then
        target.appliedHiding = HideMeDB[target.setting]
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
    local visible = not target.appliedHiding
        or (target.expUntil and GetTime() < target.expUntil)
    updatingExperienceAlpha[frame] = true
    frame:SetAlpha(visible and 1 or 0)
    updatingExperienceAlpha[frame] = nil
end

local function ApplyExperience(target)
    local combat = InCombatLockdown()
    if not combat and target.appliedHiding ~= HideMeDB[target.setting] then
        target.appliedHiding = HideMeDB[target.setting]
        target.expUntil = nil
        if target.expTimer then
            target.expTimer:Cancel()
            target.expTimer = nil
        end
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

local function ApplyTarget(target)
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
    for _, frameName in ipairs(target.frames) do
        local frame = _G[frameName]
        if frame then
            found = true
            if not hookedFrames[frame] then
                hooksecurefunc(frame, "Show", function(self)
                    if target.conditional and healthAlphaCurve then
                        UpdatePlayerAlpha(self, target)
                    elseif ShouldHide(target) then
                        if InCombatLockdown() then
                            target.pending = true
                        else
                            self:Hide()
                        end
                    end
                end)
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
            elseif ShouldHide(target) then
                frame:Hide()
            else
                frame:Show()
            end
        end
    end
    target.pending = not found
    return found
end

local function ApplyTargets(pendingOnly)
    if not HideMeDB then return end
    for _, target in pairs(targets) do
        if not pendingOnly or target.pending then
            ApplyTarget(target)
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
events:RegisterEvent("PLAYER_XP_UPDATE")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" then
        if not HideMeDB or (event == "PLAYER_XP_UPDATE" and loadedAddon ~= "player") then
            return
        end
        local target = targets["exp-bar"]
        ApplyTarget(target)
        if target.appliedHiding then
            if target.expTimer then target.expTimer:Cancel() end
            target.expUntil = GetTime() + 2
            ApplyTarget(target)
            target.expTimer = C_Timer.NewTimer(2, function()
                target.expTimer = nil
                target.expUntil = nil
                ApplyTarget(target)
            end)
        end
    elseif event == "ADDON_LOADED" then
        if loadedAddon == addonName then
            if type(HideMeDB) ~= "table" then
                HideMeDB = {}
            end
            for _, target in pairs(targets) do
                HideMeDB[target.setting] = HideMeDB[target.setting] == true
            end
        else
            ApplyTargets(true)
            -- Optional action bars may be loaded after the main UI.
            if HideMeDB then ApplyTarget(targets["toolbars"]) end
            if HideMeDB then ApplyTarget(targets["exp-bar"]) end
        end
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_TARGET_CHANGED"
        or event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        if HideMeDB and (event ~= "UNIT_HEALTH" and event ~= "UNIT_MAXHEALTH"
            or loadedAddon == "player") then
            ApplyTarget(targets["player-frame"])
            if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_TARGET_CHANGED" then
                ApplyTarget(targets["toolbars"])
            end
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

    local name, mode = message:match("^%s*(%S+)%s+(%S+)%s*$")
    local target = targets[name]
    if not target or (mode ~= "on" and mode ~= "off") then
        Print("Invalid command. For usage and available parameters, type /hideme help")
        return
    end

    HideMeDB[target.setting] = mode == "on"
    local found = ApplyTarget(target)
    local action = HideMeDB[target.setting] and "hidden." or "shown."
    if target.conditional then
        action = HideMeDB[target.setting]
            and (healthAlphaCurve and "shown with a target, in combat, or below full health."
                or "shown only with a target or in combat (health API unavailable).")
            or "always shown."
    elseif target.toolbars then
        action = HideMeDB[target.setting]
            and "shown only with a target or in combat."
            or "always shown when active."
    elseif target.experience then
        action = HideMeDB[target.setting]
            and "shown for 2 seconds after each XP change."
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
