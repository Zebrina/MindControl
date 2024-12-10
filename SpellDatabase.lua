local _, env = ...

-- The database intentionally uses short keys to save memory.
--[[
MindControlDatabase = {
    [npcID] = {
        s = {
            [spellID] = {
                b = 1, -- 1 if buff, 2 if buff and announced.
            },
        },
        m = {
            [4] = 1000, -- Spell ID of spell in slot 4 is 1000.
            [5] = 2000,
        },
    },
    [npcID] = {
        m = 1, -- Immune to Mind Control!
    }
}
]]

local DatabasePrototype = {}
local DatabaseMetaTable = {
    __index = function(self, key)
        return DatabasePrototype[key]
    end
}
local DataPrototype = {}
local DataMetaTable = {
    __index = function(self, key)
        return DataPrototype[key]
    end
}

function env.GetDatabaseWrapper()
    MindControlDatabase = MindControlDatabase or {}

    setmetatable(MindControlDatabase, DatabaseMetaTable)

    return MindControlDatabase
end

function DatabasePrototype:GetStatistics()
    local npcCount = 0
    local immuneCount = 0
    local spellCount = 0
    local mindControlSpellCount = 0

    for _, data in pairs(self) do
        npcCount = npcCount + 1

        if (data.s) then
            for _ in pairs(data.s) do
                spellCount = spellCount + 1
            end
        end

        if (data.m == 1) then
            immuneCount = immuneCount + 1
        elseif (data.m) then
            for spell in pairs(data.m) do
                mindControlSpellCount = mindControlSpellCount + 1
            end
        end
    end

    return npcCount, immuneCount, spellCount, mindControlSpellCount
end

function DatabasePrototype:GetData(npcID)
    local data = self[npcID]
    if (data and getmetatable(data) == nil) then
        setmetatable(data, DataMetaTable)
    end
    return self[npcID]
end

function DatabasePrototype:GetOrCreateData(npcID)
    local data = self:GetData(npcID)
    if (data == nil) then
        data = {}
        setmetatable(data, DataMetaTable)
        self[npcID] = data
    end
    return data
end

function DataPrototype:HasBeenMindControlled()
    return self.m ~= nil
end

function DataPrototype:MarkAsMindControlled()
    if (self.m == nil or self:IsImmune()) then
        self.m = {}
    end
end

function DataPrototype:IsImmune()
    return self.m == 1
end

function DataPrototype:MarkAsImmune()
    if (self.m == nil) then
        self.m = 1
    end
end

function DataPrototype:GetSpells()
    return self.s
end

function DataPrototype:AddSpell(spellID)
    if (self.s == nil) then
        local spell = {}
        self.s = {
            [spellID] = spell
        }
        return spell
    end

    local spell = self.s[spellID]
    if (spell == nil) then
        spell = {}
        self.s[spellID] = spell
    end

    return spell
end

function DataPrototype:IsSpellBuff(spellID)
    local spell = self.s and self.s[spellID] or nil
    return spell and (spell.b == 1 or spell.b == 2)
end

function DataPrototype:MarkSpellAsBuff(spellID)
    local spell = self.s[spellID]
    if (spell) then
        spell.b = spell.b or 1
    end
end

function DataPrototype:IsSpellBuffAnnounced(spellID)
    local spell = self.s[spellID]
    return spell and spell.b == 2
end

function DataPrototype:MarkSpellBuffAnnounced(spellID)
    local spell = self.s[spellID]
    if (spell) then
        spell.b = 2
    end
end

function DataPrototype:GetMindControlSpells()
    if (self:IsImmune()) then
        return nil
    end
    return self.m
end

function DataPrototype:AddMindControlSpell(index, spellID)
    local mindControlSpells = self:GetMindControlSpells()
    if (mindControlSpells) then
        for savedIndex, savedSpellID in pairs(mindControlSpells) do
            if (savedSpellID == spellID) then
                mindControlSpells[savedIndex] = nil
                break
            end
        end
    else
        mindControlSpells = {}
        self.m = mindControlSpells
    end

    mindControlSpells[index] = spellID

    return self:AddSpell(spellID)
end

function DataPrototype:IsSpellAvailableDuringMindControl(spellID)
    local mindControlSpells = self:GetMindControlSpells()
    if (mindControlSpells) then
        for _, entrySpellID in pairs(mindControlSpells) do
            if (entrySpellID == spellID) then
                return true
            end
        end
    end
    return false
end