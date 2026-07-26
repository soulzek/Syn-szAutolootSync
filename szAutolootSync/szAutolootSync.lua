-- addon metadata
local ADDONNAME = ...
local Version = GetAddOnMetadata(ADDONNAME, "Version");
-- saved variables
local ACCESS_SETTINGS_GLOBAL;
local ACCESS_SETTINGS_CHARACTER;

local function Settings_GetEnabled()
    return ACCESS_SETTINGS_CHARACTER.Enabled;
end
local function Settings_SetEnabled(_bEnabled)
    ACCESS_SETTINGS_CHARACTER.Enabled = _bEnabled;
end
local function Settings_GetHash()
    return ACCESS_SETTINGS_GLOBAL.Hash;
end
local function Settings_SetHash(_szHash)
    ACCESS_SETTINGS_GLOBAL.Hash = _szHash;
end

local function OnAddonLoaded()
    SETTINGS_GLOBAL = SETTINGS_GLOBAL or {};
    SETTINGS_CHARACTER = SETTINGS_CHARACTER or {};
    ACCESS_SETTINGS_GLOBAL = SETTINGS_GLOBAL;
    ACCESS_SETTINGS_CHARACTER = SETTINGS_CHARACTER;
    -- defaults saved variables
    if (Settings_GetEnabled() == nil) then
        Settings_SetEnabled(true);
    end
    -- szAutolootSync.Enabled = szAutolootSync.Enabled or true; -- ok fuck lua i cant with this nil/false shit
    -- szAutolootSync.Hash = szAutolootSync.Hash or "";
    if (Settings_GetHash() == nil) then
        Settings_SetHash("");
    end

    -- interface options
    --------------------------------------------------
    -- Create options panel
    --------------------------------------------------
    local OPTIONS_SPACING_X = 8;
    local OPTIONS_SPACING_Y = -8;
    local optionsPanel = CreateFrame("Frame");
    optionsPanel.name = ADDONNAME;
    optionsPanel:SetHeight(500);
    --------------------------------------------------
    -- Title
    --------------------------------------------------
    local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(ADDONNAME.." |cffffffff"..Version);
    --------------------------------------------------
    -- Checkbox
    --------------------------------------------------
    local checkbox = CreateFrame("CheckButton", ADDONNAME.."EnableCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate");
    checkbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", OPTIONS_SPACING_X, OPTIONS_SPACING_Y);
    local playerName = UnitName("player");
    getglobal(checkbox:GetName().."Text"):SetText("Enabled This Character ("..playerName..")");
    checkbox:SetChecked(Settings_GetEnabled());
    checkbox:SetScript("OnClick", function(self)
        if (self:GetChecked()) then
            Settings_SetEnabled(true);
        else
            Settings_SetEnabled(false);
        end
    end)
    --------------------------------------------------
    -- EditBox label
    --------------------------------------------------
    local editLabel2 = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    editLabel2:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 0, OPTIONS_SPACING_Y);
    editLabel2:SetText("CHANGES REQUIRE RELOG");
    local editLabel = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    editLabel:SetPoint("TOPLEFT", editLabel2, "BOTTOMLEFT", 0, OPTIONS_SPACING_Y);
    editLabel:SetText("Paste Autoloot Export Hash Here:")
    --------------------------------------------------
    -- EditBox this is modified chatgpt because editboxes are fucking awful
    --------------------------------------------------
    local editBackdrop = CreateFrame("Frame", nil, optionsPanel)
    editBackdrop:SetSize(375, 300)
    editBackdrop:SetPoint("TOPLEFT", editLabel, "BOTTOMLEFT", 0, OPTIONS_SPACING_Y)
    editBackdrop:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
    })
    editBackdrop:SetBackdropColor(0, 0, 0, 0.5)
    local editBox = CreateFrame("EditBox", "MyAddonEditBox", editBackdrop)
    editBox:SetAllPoints(editBackdrop)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    --editBox:SetFontObject(ChatFontNormal)
    editBox:SetFont(STANDARD_TEXT_FONT, 8, "")
    editBox:SetTextInsets(5, 5, 5, 5)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    editBox:SetScript("OnTextChanged", function(self, userInput)
        -- Only process changes caused by actual user input
        if userInput then
            Settings_SetHash(self:GetText());
        end
    end)
    editBox:SetText(Settings_GetHash());
    --------------------------------------------------
    -- Register options panel
    --------------------------------------------------
    InterfaceOptions_AddCategory(optionsPanel);
end

local function RunAfterDelay(seconds, callback)
    local frame = CreateFrame("Frame")
    frame.elapsed = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= seconds then
            self:SetScript("OnUpdate", nil)
            callback()
        end
    end)
end

local function localprint(_szText)
    --local YELLOW = "|cffffff00"
    --local WHITE  = "|cffffffff"
    --local RED    = "|cffff0000"
    --local GREEN  = "|cff00ff00"
    --local BLUE   = "|cff00aaff"
    -- print(YELLOW .. "Hello" .. "|r " .. WHITE .. "World" .. "|r")
    print("|cffffff00"..ADDONNAME.." ("..Version.."): |cffffffff".._szText);
end

local function dosync()
    if (not Settings_GetEnabled()) then
        return;
    end

    if (not LFilterFrame) then
        localprint("LFilterFrame not found. Are you playing on Synastria?");
        return;
    end

    local szHash = Settings_GetHash();
    if (szHash == "") then
        return;
    end

    LFilterFrame:Show();
    local btnImport = _G["LFilterFrame-Imp"];
    btnImport:Click(); -- click import
    LFilterFrameImportFrameEdit:SetText(szHash);
    local btnImportOk = _G["LFilterFrameImportFrame-Ok"];
    btnImportOk:Click(); -- confirm import text
    local btnAccept = _G["LFilterFrame-App"];
    btnAccept:Click(); -- accept changes
    local btnClose = _G["LFilterFrame-Close"];
    btnClose:Click(); -- ~fin

    localprint("Sync complete"); -- print complete here in case of failures
end

-- loading frame
local g_Frame = CreateFrame("Frame");
g_Frame:RegisterEvent("PLAYER_ENTERING_WORLD");
g_Frame:RegisterEvent("ADDON_LOADED");
g_Frame:SetScript("OnEvent", function(self, event, ...)
    if (event == "ADDON_LOADED") then
        local szAddonName = ...;
        if (szAddonName == ADDONNAME) then
            OnAddonLoaded();
            g_Frame:UnregisterEvent("ADDON_LOADED");
        end
    elseif (event == "PLAYER_ENTERING_WORLD") then
        local szMsg;
        if (Settings_GetEnabled()) then
            szMsg = "|cff00ff00enabled|cffffffff";
        else
            szMsg = "|cffff0000disabled|cffffffff";
        end
        localprint("is "..szMsg..". Access options with /szals");
        RunAfterDelay(1.0, dosync);
        g_Frame:UnregisterEvent("PLAYER_ENTERING_WORLD");
    end
    -- self:UnregisterAllEvents();
end)

SlashCmdList["SZALS"] = function(_args)
    InterfaceOptionsFrame_OpenToCategory(ADDONNAME);
end
SLASH_SZALS1 = "/szals";
SLASH_SZALS2 = "/szautolootsync";