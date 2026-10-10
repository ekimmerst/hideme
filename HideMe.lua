local addonName = ...
local events = CreateFrame("Frame")
local hookedFrames = {}
local targets = {
    ["bag-bar"] = {
        setting = "hideBagBar",
        label = "Taschenleiste",
        frames = { "BagsBar" },
    },
    ["micro-menu"] = {
        setting = "hideMicroMenu",
        label = "Micro-Menü",
        frames = { "MicroMenuContainer", "MicroMenu" },
    },
}

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffHideMe:|r " .. message)
end

local function PrintHelp()
    Print("Verfügbare Befehle (on: ausblenden, off: einblenden):")
    Print("/hideme bag-bar on - Taschenleiste ausblenden.")
    Print("/hideme bag-bar off - Taschenleiste einblenden.")
    Print("/hideme micro-menu on - Micro-Menü ausblenden.")
    Print("/hideme micro-menu off - Micro-Menü einblenden.")
    Print("/hideme status - Status aller Ein- und Ausblendungen anzeigen.")
    Print("/hideme help - Diese Hilfe anzeigen.")
end

local function PrintStatus()
    Print("Aktuelle Einstellungen (on: ausblenden, off: einblenden):")
    local names = {}
    for name in pairs(targets) do
        names[#names + 1] = name
    end
    table.sort(names)

    for _, name in ipairs(names) do
        local target = targets[name]
        local hidden = HideMeDB and HideMeDB[target.setting] == true
        local state = hidden and "on (Ausblendung aktiviert)" or "off (Ausblendung deaktiviert)"
        if target.pending then
            if InCombatLockdown() then
                state = state .. " - Anwendung nach Kampfende ausstehend"
            else
                state = state .. " - Anwendung ausstehend: UI-Element noch nicht geladen"
            end
        end
        Print(name .. " - " .. target.label .. ": " .. state)
    end
end

local function ApplyTarget(target)
    if InCombatLockdown() then
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
                    if HideMeDB and HideMeDB[target.setting] then
                        if InCombatLockdown() then
                            target.pending = true
                        else
                            self:Hide()
                        end
                    end
                end)
                hookedFrames[frame] = true
            end

            if HideMeDB[target.setting] then
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
    else
        ApplyTargets(event == "PLAYER_REGEN_ENABLED")
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
        Print("Ungültiger Befehl. Verwendung und verfügbare Parameter: /hideme help")
        return
    end

    HideMeDB[target.setting] = mode == "on"
    local found = ApplyTarget(target)
    local action = HideMeDB[target.setting] and "ausgeblendet." or "eingeblendet."
    if InCombatLockdown() then
        Print(target.label .. " wird nach Kampfende " .. action)
    elseif not found then
        Print(target.label .. " ist noch nicht geladen. Die Einstellung wurde gespeichert.")
    else
        Print(target.label .. " " .. action)
    end
end
