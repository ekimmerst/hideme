local addonName = ...
local events = CreateFrame("Frame")
local hookedFrames = {}
local healthAlphaCurve
if UnitHealthPercent and C_CurveUtil and C_CurveUtil.CreateCurve
    and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step then
    healthAlphaCurve = C_CurveUtil.CreateCurve()
    healthAlphaCurve:SetType(Enum.LuaCurveType.Step)
    healthAlphaCurve:AddPoint(0, 1)
    healthAlphaCurve:AddPoint(1, 0)
end
local targets = {
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
}

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffHideMe:|r " .. message)
end

local function PrintHelp()
    Print("Available commands (on: enable hiding, off: disable hiding):")
    Print("/hideme bag-bar on - Hide the bag bar.")
    Print("/hideme bag-bar off - Show the bag bar.")
    Print("/hideme micro-menu on - Hide the micro menu.")
    Print("/hideme micro-menu off - Show the micro menu.")
    Print("/hideme player-frame on - Show with a target, in combat, or below full health.")
    Print("/hideme player-frame off - Always show the player frame.")
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

local function ApplyTarget(target)
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
events:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "ADDON_LOADED" then
        if loadedAddon == addonName then
            if type(HideMeDB) ~= "table" then
                HideMeDB = {}
            end
            for _, target in pairs(targets) do
                HideMeDB[target.setting] = HideMeDB[target.setting] == true
            end
        else
            ApplyTargets(true)
        end
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_TARGET_CHANGED"
        or event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        if HideMeDB and (event ~= "UNIT_HEALTH" and event ~= "UNIT_MAXHEALTH"
            or loadedAddon == "player") then
            ApplyTarget(targets["player-frame"])
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
    end
    if InCombatLockdown() then
        Print(target.label .. " will be " .. action .. " The change will take effect after combat.")
    elseif not found then
        Print(target.label .. " is not loaded yet. The setting has been saved.")
    else
        Print(target.label .. " is " .. action)
    end
end
