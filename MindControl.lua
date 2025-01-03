local _, env = ...

local DEVELOPMENT_ONLY
do
    local name, realm = UnitFullName("player")
    DEVELOPMENT_ONLY = (name == "Zebrina") and (realm == "Ragnaros" or realm == "Golemagg" or realm == "LivingFlame")
end

local IS_RETAIL = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local IS_VANILLA = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local IS_TBC = (WOW_PROJECT_ID == WOW_PROJECT_TBC_CLASSIC)
local IS_WRATH = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
local IS_CATACLYSM = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)
local IS_PRE_CATACLYSM = IS_VANILLA or IS_TBC or IS_WRATH
local IS_POST_WRATH = not IS_PRE_CATACLYSM
local IS_PRE_WRATH = IS_VANILLA or IS_TBC

local MIND_CONTROL_SPELLID = 605
local MIND_CONTROL_ICON = 136206 -- spell_shadow_shadowworddominate
local DOMINATE_MIND_SPELLID = 205364
local DOMINATE_MIND_ICON = 1386549 -- spell_priest_void-flay
local SUBJUGATE_DEMON_SPELLID = {
    NumRanks = (IS_POST_WRATH and 1) or (IS_WRATH and 4) or 3,
    [1] = {  -- Rank 1
        SpellID = 1098,
        MaxLevel = 45,
    },
    [2] = { -- Rank 2
        SpellID = 11725,
        MaxLevel = 59,
    },
    [3] = { -- Rank 3
        SpellID = 11726,
        MaxLevel = IS_VANILLA and 64 or 74, -- Increased to 74 in TBC.
    },
    [4] = { -- Rank 4 (Wrath)
        SpellID = 61191,
        MaxLevel = 84,
    },
}

local PLAYER_CLASS = select(2, UnitClass("player"))

local SUBJUGATE_DEMON_ICON = 136154
local CONTROL_UNDEAD_SPELLID = 111673
local CONTROL_UNDEAD_ICON = 237273 -- inv_misc_bone_skull_01
local PET_ATTACK_ICON = 132152
local OTHER_SPELLS_ICON = 136116 -- spell_nature_wispsplode
--local GNOMISH_UNIVERSAL_REMOTE_SPELLID = 9269
--local GNOMISH_UNIVERSAL_REMOTE_ICON = 134376
--local CONTROL_MACHINE_SPELLID = 8345


local ALLOWED_CREATURE_TYPES = {}
do
    if (PLAYER_CLASS == "PRIEST") then
        ALLOWED_CREATURE_TYPES[env.Strings.Humanoid] = true
        if (IS_RETAIL) then
            -- Additional creature types allowed in retail.
            -- In retail the only creature types that can't be
            -- mind controlled are: "Demon", "Undead" and "Mechanical"
            -- Can even mind control critters! But not wild pets that can be battled.
            ALLOWED_CREATURE_TYPES[env.Strings.Beast] = true
            ALLOWED_CREATURE_TYPES[env.Strings.Critter] = true
            ALLOWED_CREATURE_TYPES[env.Strings.Dragonkin] = true
            ALLOWED_CREATURE_TYPES[env.Strings.Elemental] = true
            ALLOWED_CREATURE_TYPES[env.Strings.Giant] = true
        end
    elseif (PLAYER_CLASS == "WARLOCK") then
        ALLOWED_CREATURE_TYPES[env.Strings.Demon] = true
    elseif (PLAYER_CLASS == "DEATHKNIGHT") then
        ALLOWED_CREATURE_TYPES[env.Strings.Undead] = true
    end
end

local ActionButtons
if (IS_PRE_CATACLYSM) then
    ActionButtons = {}
    for i = 1, (NUM_PET_ACTION_SLOTS - 2) do
        table.insert(ActionButtons, _G["ActionButton"..i])
    end
end

local PetActionButtons
if (IS_PRE_CATACLYSM) then
    -- Button 1 is always the 'Attack' action.
    PetActionButtons = { PetActionButton1 }
    -- Button 2 and 3 are always empty.
    -- First spell or ability is on button 4.
    for i = 4, NUM_PET_ACTION_SLOTS do
        table.insert(PetActionButtons, _G["PetActionButton"..i])
    end
end

local GetSpellInfo = _G.GetSpellInfo or C_Spell.GetSpellInfo
if (IS_RETAIL) then
    -- Wrapper for GetSpellInfo to make it behave in retail as it does in classic.
    -- name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(spellOrIndex, bookType)
    GetSpellInfo = function(spellOrIndex, bookType)
        local spellInfo = C_Spell.GetSpellInfo(spellOrIndex, bookType)
		if (spellInfo == nil) then
			return nil
		end
        return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange,
               spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
    end
end

local GetSpellTexture = _G.GetSpellTexture or C_Spell.GetSpellTexture

local function ReturnStaticValue(value)
    return function() return value end
end
local function ReturnFalse()
    return false
end

local MindControlSpellTable = {
    SpellRankPresets = {
        ["PRIEST"] = {
            NumRanks = IS_PRE_WRATH and 3 or 1,
            [1] = { -- Rank 1
                GetSpellID = function()
                    return IsPlayerSpell(DOMINATE_MIND_SPELLID) and DOMINATE_MIND_SPELLID or MIND_CONTROL_SPELLID
                end,
                GetMaxLevel = function()
                    if (IS_PRE_WRATH) then
                        return 44
                    end
                    local playerLevel = UnitLevel("player")
                    if (IS_RETAIL) then
                        return playerLevel + 1
                    elseif (IS_WRATH) then
                        return playerLevel + 2
                    end
                    -- Cataclysm and probably Mists of Pandaria as well.
                    return playerLevel + 3
                end,
                IsFullControl = function(self)
                    return self:GetSpellID() ~= DOMINATE_MIND_SPELLID
                end,
            },
            [2] = { -- Rank 2
                GetSpellID = ReturnStaticValue(10911),
                GetMaxLevel = ReturnStaticValue(59),
                IsFullControl = ReturnFalse,
            },
            [3] = { -- Rank 3
                GetSpellID = ReturnStaticValue(10912),
                GetMaxLevel = ReturnStaticValue(IS_VANILLA and 64 or 74), -- Increased to 74 in TBC.
                IsFullControl = ReturnFalse,
            },
        },

        ["WARLOCK"] = {
            NumRanks = (IS_PRE_WRATH and 3) or (IS_WRATH and 4) or 1,
            [1] = {  -- Rank 1
                GetSpellID = ReturnStaticValue(1098),
                GetMaxLevel = function()
                    if (IS_PRE_CATACLYSM) then
                        return 45
                    end
                    local playerLevel = UnitLevel("player")
                    if (IS_RETAIL) then
                        return playerLevel + 1
                    end
                    -- Cataclysm and probably Mists of Pandaria as well.
                    return playerLevel + 3 -- TODO: Verify this. Wowhead spell description does not say!
                end,
                IsFullControl = ReturnFalse,
            },
            [2] = { -- Rank 2
                GetSpellID = ReturnStaticValue(11725),
                GetMaxLevel = ReturnStaticValue(59),
                IsFullControl = ReturnFalse,
            },
            [3] = { -- Rank 3
                GetSpellID = ReturnStaticValue(11726),
                GetMaxLevel = ReturnStaticValue(IS_VANILLA and 64 or 74), -- Increased to 74 in TBC.
                IsFullControl = ReturnFalse,
            },
            [4] = { -- Rank 4 (Wrath)
                GetSpellID = ReturnStaticValue(61191),
                GetMaxLevel = ReturnStaticValue(84),
                IsFullControl = ReturnFalse,
            },
        },

        ["DEATHKNIGHT"] = {
            NumRanks = IS_RETAIL and 1 or 0,
            [1] = {
                GetSpellID = ReturnStaticValue(111673),
                GetMaxLevel = function()
                    return UnitLevel("player") + 1
                end,
                IsFullControl = ReturnFalse,
            }
        },
    },
}

function MindControlSpellTable:Initialize()
    self.SpellRanks = self.SpellRankPresets[PLAYER_CLASS]
end
MindControlSpellTable:Initialize()

function MindControlSpellTable:GetSpellRank()
    local spellRanks = self.SpellRanks
    if (spellRanks == nil) then
        return nil
    end
    for i = spellRanks.NumRanks, 1, -1 do
        local rankTable = spellRanks[i]
        if (IsPlayerSpell(rankTable:GetSpellID())) then
            return rankTable
        end
    end
    return nil
end

function MindControlSpellTable:GetSpellInfo()
    local spellRank = self:GetSpellRank()
    if (spellRank) then
        return GetSpellInfo(spellRank:GetSpellID())
    end
    return nil
end

function MindControlSpellTable:GetSpellID()
    local spellRank = self:GetSpellRank()
    return spellRank and spellRank:GetSpellID() or nil
end

function MindControlSpellTable:GetMaxLevel()
    local spellRank = self:GetSpellRank()
    return spellRank and spellRank:GetMaxLevel() or -999
end

function MindControlSpellTable:IsFullControl()
    local spellRank = self:GetSpellRank()
    return spellRank and spellRank:IsFullControl() or nil
end

local function UnitShouldBeMindControlled(unit)
    if (unit == nil) then
        return false
    end
    local unitLevel = UnitLevel(unit)
    return unitLevel >= 1 and ALLOWED_CREATURE_TYPES[UnitCreatureType(unit)] and not UnitIsPlayer(unit) and
           UnitCanAttack("player", unit) and not UnitIsPossessed(unit) and not UnitIsCharmed(unit) and
           not UnitIsDead(unit) and UnitClassification(unit) ~= "worldboss" and
           unitLevel <= MindControlSpellTable:GetMaxLevel() and
           (UnitIsCivilian == nil or not UnitIsCivilian(unit)) -- UnitIsCivilian is removed in TBC along with the honor system.
end

local function UnitIsCritter(unit)
    return UnitCreatureType(unit) == env.Strings.Critter
end

local function UnitInfoFromGUID(guid)
    if (guid) then
        local type, _, serverId, instanceId, zoneUId, npcID, spawnUId = string.split("-", guid)
        return type, serverId, instanceId, zoneUId, npcID, spawnUId
    end
    return nil
end
local function UnitInfoFromTarget(unit)
    return UnitInfoFromGUID(UnitGUID(unit))
end

local function GetPriestClassColorRGB()
    if (IS_RETAIL) then
        return C_ClassColor.GetClassColor("PRIEST"):GetRGB()
    end
    return GetClassColor("PRIEST")
end

local function FormatIcon(texture)
    local iconSize = 16
    return (texture and "|T"..texture..":"..iconSize.."|t ") or ""
end

local function FormatBindingKey(command, leadingSpace, trailingSpace)
    local key = GetBindingKey(command)
    if (key) then
        return (leadingSpace and " " or "").."["..GetBindingText(key, false).."]"..(trailingSpace and " " or "")
    end
    return ""
end

local function FormatSpellCastTime(castTime)
    return (castTime < 0 and "Attack speed") or (castTime > 0 and ((castTime / 1000).." sec cast"))
end
local function FormatSpellRange(minRange, maxRange)
    return ((minRange ~= maxRange and minRange.."-") or "")..maxRange.." yd range"
end
local function FormatSpellCooldown(spellID)
    local cooldown = GetSpellBaseCooldown(spellID)
    return cooldown > 0 and ", "..(cooldown / 1000).." sec cd"
end

local function FormatSpellInfo(data, spellID)
    local showCastTime, showRange, showCooldown = 1, nil, 1
    local spellName, _, _, spellCastTime, spellMinRange, spellMaxRange = GetSpellInfo(spellID)

    local spellText = spellName
    local infoText = nil

    local function AppendInfoText(text)
        infoText = infoText and infoText..", "..text or text
    end

    if (data and data:IsSpellBuff(spellID)) then
        AppendInfoText("buff")
    elseif (SpellIsSelfBuff(spellID)) then
        AppendInfoText("self cast")
    end

    if (showCastTime and spellCastTime ~= 0) then
        AppendInfoText(FormatSpellCastTime(spellCastTime))
    end

    if (showCooldown) then
        local spellCooldown = GetSpellBaseCooldown(spellID)
        if (spellCooldown > 0) then
            AppendInfoText((spellCooldown / 1000).." sec cd")
        end
    end

    return spellText..((infoText and " ("..infoText..")") or "")
end

local MindControlFrame = CreateFrame("Frame")
MindControlFrame.Events = {}

local db

function MindControlFrame.Events:ADDON_LOADED(addOnName)
    if (addOnName == "MindControl") then
        db = env.GetDatabaseWrapper()

        MindControlConfig = MindControlConfig or {}

        local function onTooltipSetUnitFunction(self)
            local _, unit = self:GetUnit()
            if (unit == nil) then
                return
            end

            local type, _, _, _, npcID = UnitInfoFromTarget(unit)
            if (type ~= "Creature") then
                return
            end

            local data = db:GetData(npcID)
            local name, _, icon = MindControlSpellTable:GetSpellInfo()
            local canMindControl = (name ~= nil)

            if (canMindControl and (data == nil or not data:HasBeenMindControlled()) and
                UnitShouldBeMindControlled(unit) and not UnitIsCritter(unit)) then

                self:AddLine(FormatIcon(icon)..string.format(env.Strings.CastMindControl, name), GRAY_FONT_COLOR:GetRGB())
            end
            
            if (data == nil) then
                return
            end

            local mindControlSpells = nil

            if (data:IsImmune()) then
                self:AddLine(FormatIcon(icon)..env.Strings.Immune, RED_FONT_COLOR:GetRGB())
            elseif (data:IsInvalidTarget()) then
                self:AddLine(FormatIcon(icon)..env.Strings.InvalidTarget, ORANGE_FONT_COLOR:GetRGB())
            elseif (canMindControl) then
                mindControlSpells = data:GetMindControlSpells()
                if (mindControlSpells) then
                    local headerAdded = false
                    local isFullControl = MindControlSpellTable:IsFullControl()

                    for i = 2, NUM_PET_ACTION_SLOTS do
                        local spellID = mindControlSpells[i]
                        if (spellID) then
                            if (not headerAdded) then
                                headerAdded = true

                                self:AddLine(string.format(env.Strings.MindControlSpells, name)..FormatIcon(icon), WHITE_FONT_COLOR:GetRGB())

                                if (MindControlConfig.TooltipShowAttack) then
                                    local key = GetBindingKey("ACTIONBUTTON1")
                                    self:AddLine(FormatIcon(PET_ATTACK_ICON)..env.Strings.Attack..(key and " ["..GetBindingText(key, false).."]"))
                                end
                            end

                            if (isFullControl) then
                                self:AddLine(FormatIcon(GetSpellTexture(spellID))..FormatBindingKey("ACTIONBUTTON"..(IS_RETAIL and i or (i - 2)), false, true)..FormatSpellInfo(data, spellID))
                            else
                                -- If we don't have full control (moving, jumping etc.) show pet keybinds.
                                self:AddLine(FormatIcon(GetSpellTexture(spellID))..FormatBindingKey("BONUSACTIONBUTTON"..i, false, true)..FormatSpellInfo(data, spellID))
                            end
                        end
                    end
                end
            end

            local spells = data:GetSpells()
            if (spells) then
                local headerAdded = false

                for spellID, spell in pairs(spells) do
                    if (not data:IsSpellAvailableDuringMindControl(spellID)) then
                        if (not headerAdded) then
                            headerAdded = true

                            if (mindControlSpells) then
                                self:AddLine(env.Strings.OtherSpells..FormatIcon(OTHER_SPELLS_ICON), WHITE_FONT_COLOR:GetRGB())
                            else
                                self:AddLine(env.Strings.Spells..FormatIcon(OTHER_SPELLS_ICON), WHITE_FONT_COLOR:GetRGB())
                            end
                        end

                        self:AddLine(FormatIcon(GetSpellTexture(spellID))..FormatSpellInfo(data, spellID))
                    end
                end
            end
        end

        if (IS_RETAIL) then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, onTooltipSetUnitFunction)
        else
            GameTooltip:HookScript("OnTooltipSetUnit", onTooltipSetUnitFunction)
        end

        self:UnregisterEvent("ADDON_LOADED")

        DEFAULT_CHAT_FRAME:AddMessage(FormatIcon(MIND_CONTROL_ICON).."MindControl loaded.", YELLOW_FONT_COLOR:GetRGB())
        if (DEVELOPMENT_ONLY) then
            local npcCount, immuneCount, invalidTargetCount, spellCount, mindControlSpellCount = db:GetStatistics()
            DEFAULT_CHAT_FRAME:AddMessage(npcCount.." npcs recorded, "..immuneCount.." immune, and "..invalidTargetCount.." invalid target(s).", YELLOW_FONT_COLOR:GetRGB())
            DEFAULT_CHAT_FRAME:AddMessage(spellCount.." spells recorded. "..mindControlSpellCount.." spells recorded during Mind Control.", YELLOW_FONT_COLOR:GetRGB())
        end
    end
end

function MindControlFrame:HandleMindControlledUnitData()
    local _, _, _, _, npcID = UnitInfoFromTarget("pet")
    -- Sometimes getting info from GUID fails.
    if (not npcID) then
        -- Try again after a short period.
        -- But only until we no longer have a pet.
        -- We don't want infinite recursion.
        if (GetPetActionsUsable() == true) then
            C_Timer.NewTimer(0.1, function() MindControlFrame:HandleMindControlledUnitData() end)
        end
        return
    end

    local data = db:GetOrCreateData(npcID)
    data:MarkAsMindControlled()

    local isFullControl = MindControlSpellTable:IsFullControl()

    for i = 2, NUM_PET_ACTION_SLOTS do
        local spellID = select(7, GetPetActionInfo(i))
        if (spellID) then
            data:AddMindControlSpell(i, spellID)
        end
    end
end

function MindControlFrame:UpdatePetActionBarHotkeys(enabled)
    if (IS_PRE_CATACLYSM) then
        if (enabled) then
            for i = 1, (NUM_PET_ACTION_SLOTS - 2) do
                local key1, key2 = GetBindingKey("ACTIONBUTTON"..i)

                -- Show the keybind for action button 1-8
                -- on pet action button 1,4-10
                local petActionButtonIndex = (i == 1) and 1 or (i + 2)
                local binding = GetBindingText(key1, true)
                local hotkey = PetActionButtons[i].HotKey
                if (binding == "") then
                    hotkey:SetText(RANGE_INDICATOR)
		            hotkey:Hide()
                else
                    hotkey:SetText(binding)
		            hotkey:Show()
                end

                -- If the action button has a second keybind
                -- show that one instead.
                binding = GetBindingText(key2, true)
                hotkey = ActionButtons[i].HotKey
                if (binding == "") then
                    hotkey:SetText(RANGE_INDICATOR)
		            hotkey:Hide()
                else
                    hotkey:SetText(binding)
		            hotkey:Show()
                end
            end
        else
            -- Restore all keys to default.
            for i = 1, (NUM_PET_ACTION_SLOTS - 2) do
                local actionButton = ActionButtons[i]
                ActionButton_UpdateHotkeys(actionButton, actionButton.buttonType)
                PetActionButton_SetHotkeys(PetActionButtons[i])
            end
        end
    end
end

function MindControlFrame.Events:UNIT_PET(unitTarget)
    if (unitTarget == "player" and GetPetActionsUsable() == true and UnitIsPlayer("pet") ~= true) then
        MindControlFrame.isMindControlling = true
        MindControlFrame:UpdatePetActionBarHotkeys(true)
        MindControlFrame:HandleMindControlledUnitData()
    elseif (MindControlFrame.isMindControlling) then
        MindControlFrame.isMindControlling = nil
        MindControlFrame:UpdatePetActionBarHotkeys(false)
    end
end

function MindControlFrame.Events:COMBAT_LOG_EVENT_UNFILTERED()
    local _, event, _, casterGUID, _, _, _, targetGUID, _, _, _, spellID, spellName, _, info = CombatLogGetCurrentEventInfo()

    if (event == "SPELL_MISSED") then
        if (not (info == "IMMUNE" and spellName == MindControlSpellTable:GetSpellInfo())) then
            return
        end

        local _, _, _, _, npcID = UnitInfoFromGUID(targetGUID)
        if (npcID == nil) then
            return
        end

        local data = db:GetOrCreateData(npcID)
        data:MarkAsImmune()
    elseif (event == "SPELL_CAST_SUCCESS") then
        local _, _, _, _, npcID = UnitInfoFromGUID(casterGUID)
        if (npcID == nil) then
            return
        end

        local data = db:GetOrCreateData(npcID)
        data:AddSpell(spellID)
    elseif (event == "SPELL_AURA_APPLIED") then
        if (not (info == "BUFF" and casterGUID ~= targetGUID)) then
            return
        end

        local _, _, _, _, npcID = UnitInfoFromGUID(casterGUID)
        if (npcID == nil) then
            return
        end

        local data = db:GetOrCreateData(npcID)
        data:AddSpell(spellID)
        data:MarkSpellAsBuff(spellID)

        if (IS_RETAIL and not data:IsSpellBuffAnnounced(spellID)) then
            local unitToken = UnitTokenFromGUID(casterGUID)
            if (MindControlSpellTable:GetSpellInfo() and UnitShouldBeMindControlled(unitToken)) then
                -- Might not be a good idea to rely on
                -- unitToken refering to the same unit
                -- after the spell query.
                local unitName = UnitName(unitToken)

                local queriedSpell = Spell:CreateFromSpellID(spellID)
                queriedSpell:ContinueOnSpellLoad(function()
                    if (data:IsSpellBuffAnnounced(spellID)) then
                        return
                    end

                    data:MarkSpellBuffAnnounced()

                    DEFAULT_CHAT_FRAME:AddMessage(FormatIcon(MIND_CONTROL_ICON)..env.Strings.PotentialBuff.." "..unitName, YELLOW_FONT_COLOR:GetRGB())
                    local name, _, icon = GetSpellInfo(spellID)
                    --DEFAULT_CHAT_FRAME:AddMessage(FormatIcon(GetSpellTexture(spellID))..FormatSpellInfo(data, spellID), YELLOW_FONT_COLOR:GetRGB())
                    DEFAULT_CHAT_FRAME:AddMessage(FormatIcon(icon)..name..": "..queriedSpell:GetSpellDescription(), YELLOW_FONT_COLOR:GetRGB())
                end)
            end
        end
    end
end

function MindControlFrame.Events:UNIT_SPELLCAST_SENT(unit, targetName, castGUID, spellID)
    if (unit ~= "player") then
        return
    end

    if (spellID ~= MindControlSpellTable:GetSpellID()) then
        return
    end

    local target = (UnitName("target") == targetName and "target") or
                   (UnitName("mouseover") == targetName and "mouseover") or
                   (UnitName("focus") == targetName and "focus") or nil

    if (target) then
        local type, _, _, _, npcID = UnitInfoFromTarget(target)
        if (type == "Creature") then
            self.lastMindControlTarget = npcID
        end
    end
end

function MindControlFrame.Events:UNIT_SPELLCAST_START(unitTarget, castGUID, spellID)
    if (unitTarget ~= "player") then
        return
    end

    self.lastMindControlTarget = nil
end

function MindControlFrame.Events:UNIT_SPELLCAST_FAILED(unitTarget, castGUID, spellID)
    if (unitTarget ~= "player") then
        return
    end

    if (spellID ~= MindControlSpellTable:GetSpellID()) then
        return
    end

-- TODO: Check cast guid?
    -- Scarshield Quartmaster castGUID: Cast-3-3769-0-125-605-??????????
    --print("UNIT_SPELLCAST_FAILED", unitTarget, castGUID, spellID, self.attemptMindControl)

    if (self.lastMindControlTarget) then
        local data = db:GetOrCreateData(self.lastMindControlTarget)
        data:MarkAsInvalidTarget()
        self.lastMindControlTarget = nil
        print("marked as invalid target")
    end
end

function MindControlFrame.Events:PLAYER_TARGET_CHANGED()
end

function MindControlFrame.Events:NAME_PLATE_UNIT_ADDED(unitToken)
end

MindControlStateFrame = CreateFrame("Frame", nil, nil, "SecureHandlerStateTemplate")

function MindControlFrame.Events:UPDATE_BINDINGS()
    local bindings = {
        ["SHIFT-SPACE,CTRL-SPACE"] = "TARGETSELF",
    }

    if (IS_PRE_CATACLYSM) then
        for i = 1, (NUM_PET_ACTION_SLOTS - 2) do
            local key = GetBindingKey("ACTIONBUTTON"..i)
            if (key) then
                bindings[key] = "CLICK "..PetActionButtons[i]:GetName()..":LeftButton"
            end
        end
    end

    local bindingsBlock = ""
    for keys, command in pairs(bindings) do
        for _, key in pairs({ string.split(",", keys) }) do
            bindingsBlock = bindingsBlock..string.format([[
                self:SetBinding(true, "%s", "%s");
            ]], key, command)
        end
    end

    local setPointBlock = ""
    local restorePointBlock = ""
    if (IS_PRE_CATACLYSM) then
        local point2, relativeTo2, relativePoint2, offsetX2, offsetY2 = PetActionButton2:GetPoint()
        local relativeTo2Name = relativeTo2:GetName()
        local point4, relativeTo4, relativePoint4, offsetX4, offsetY4 = PetActionButton4:GetPoint()
        local relativeTo4Name = relativeTo4:GetName()

        MindControlStateFrame:SetFrameRef(relativeTo2Name, relativeTo2)
        MindControlStateFrame:SetFrameRef(relativeTo4Name, relativeTo4)

        MindControlStateFrame:SetFrameRef("PetActionButton2", PetActionButton2)
        MindControlStateFrame:SetFrameRef("PetActionButton3", PetActionButton3)
        MindControlStateFrame:SetFrameRef("PetActionButton4", PetActionButton4)
        
        setPointBlock = string.format([[
            local %s = self:GetFrameRef("%s");
            local PetActionButton2 = self:GetFrameRef("PetActionButton2");
            local PetActionButton3 = self:GetFrameRef("PetActionButton3");
            local PetActionButton4 = self:GetFrameRef("PetActionButton4");

            PetActionButton4:ClearAllPoints();
            PetActionButton4:SetPoint("%s", %s, "%s", %f, %f);

            PetActionButton2:Hide();
            PetActionButton3:Hide();
        ]], relativeTo2Name, relativeTo2Name, point2, relativeTo2Name, relativePoint2, offsetX2, offsetY2)

        restorePointBlock = string.format([[
            local %s = self:GetFrameRef("%s");
            local PetActionButton2 = self:GetFrameRef("PetActionButton2");
            local PetActionButton3 = self:GetFrameRef("PetActionButton3");
            local PetActionButton4 = self:GetFrameRef("PetActionButton4");

            PetActionButton4:ClearAllPoints();
            PetActionButton4:SetPoint("%s", %s, "%s", %f, %f);

            PetActionButton2:Show();
            PetActionButton3:Show();
        ]], relativeTo4Name, relativeTo4Name, point4, relativeTo4Name, relativePoint4, offsetX4, offsetY4)
    end

    local body = string.format([[
        if (newstate == "mcbegin") then
            do %s end;
            do %s end;
        elseif (newstate == "mcend") then
            self:ClearBindings();
            do %s end;
        end
    ]], bindingsBlock, setPointBlock, restorePointBlock)

    body = string.gsub(body, "%s+", " ")

    MindControlStateFrame:SetAttribute("_onstate-mindcontrolbinds", body)
end

RegisterStateDriver(MindControlStateFrame, "mindcontrolbinds", "[pet,channeling:Mind Control][pet,channeling:Control Machine] mcbegin; mcend")

-- Event handler setup.
local events = MindControlFrame.Events
MindControlFrame:SetScript("OnEvent", function(self, event, ...)
    events[event](self, ...)
end)
for event in pairs(events) do
    MindControlFrame:RegisterEvent(event)
end