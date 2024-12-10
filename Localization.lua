local addOnName, env = ...

env.Strings = {
    Beast = "Beast",
    Critter = "Critter",
    Dragonkin = "Dragonkin",
    Elemental = "Elemental",
    Giant = "Giant",
    Humanoid = "Humanoid",
    Mechanical = "Mechanical",
    MindControlAbilties = "%s Abilities",
    Attack = "Attack",
    MindControlImmune = "%s Immune",
    CastMindControl = "Cast %s",
    Spells = "Spells",
    OtherSpells = "Other Spells",
    Abilities = "Abilities",
    OtherAbilities = "Other Abilities",
    PotentialBuff = "Potential buff cast by",
    Description = "Description",
}

local locale = GetLocale()

if (locale == "koKR") then

    env.Strings.Beast = "야수"
    env.Strings.Critter = "동물"
    env.Strings.Dragonkin = "용족"
    env.Strings.Elemental = "정령"
    env.Strings.Giant = "거인"
    env.Strings.Humanoid = "인간형"
    env.Strings.Mechanical = "기계"

elseif (locale == "frFR") then

    env.Strings.Beast = "Bête"
    env.Strings.Critter = "Bestiole"
    env.Strings.Dragonkin = "Draconien"
    env.Strings.Elemental = "Élémentaire"
    env.Strings.Giant = "Géant"
    env.Strings.Humanoid = "Humanoïde"
    env.Strings.Mechanical = "Machine"

elseif (locale == "deDE") then

    env.Strings.Beast = "Wildtier"
    env.Strings.Critter = "Kleintier"
    env.Strings.Dragonkin = "Drachkin"
    env.Strings.Elemental = "Elementar"
    env.Strings.Giant = "Riese"
    env.Strings.Humanoid = "Humanoid"
    env.Strings.Mechanical = "Mechanisch"
    
elseif (locale == "zhCN") then

    env.Strings.Beast = "野兽"
    env.Strings.Critter = "小动物"
    env.Strings.Dragonkin = "龙类"
    env.Strings.Elemental = "元素生物"
    env.Strings.Giant = "巨人"
    env.Strings.Humanoid = "人型生物"
    env.Strings.Mechanical = "机械"
    
elseif (locale == "esES") then

    env.Strings.Beast = "Bestia"
    env.Strings.Critter = "Alma"
    env.Strings.Dragonkin = "Dragon"
    env.Strings.Elemental = "Elemental"
    env.Strings.Giant = "Gigante"
    env.Strings.Humanoid = "Humanoide"
    env.Strings.Mechanical = "Mecánico"
    
elseif (locale == "zhTW") then

    env.Strings.Beast = "野獸"
    env.Strings.Critter = "小動物"
    env.Strings.Dragonkin = "龍類"
    env.Strings.Elemental = "元素生物"
    env.Strings.Giant = "巨人"
    env.Strings.Humanoid = "人型生物"
    env.Strings.Mechanical = "機械"
    
elseif (locale == "esMX") then

    env.Strings.Beast = "Bestia"
    env.Strings.Critter = "Alma"
    env.Strings.Dragonkin = "Dragón"
    env.Strings.Elemental = "Elemental"
    env.Strings.Giant = "Gigante"
    env.Strings.Humanoid = "Humanoide"
    env.Strings.Mechanical = "Mecánico"
    
elseif (locale == "ruRU") then

    env.Strings.Beast = "Животное"
    env.Strings.Critter = "Существо"
    env.Strings.Dragonkin = "Дракон"
    env.Strings.Elemental = "Элементаль"
    env.Strings.Giant = "Великан"
    env.Strings.Humanoid = "Гуманоид"
    env.Strings.Mechanical = "Механизм"
    
elseif (locale == "ptBR") then

    env.Strings.Beast = "Fera"
    env.Strings.Critter = "Bicho"
    env.Strings.Dragonkin = "Dracônico"
    env.Strings.Elemental = "Elemental"
    env.Strings.Giant = "Gigante"
    env.Strings.Humanoid = "Humanoide"
    env.Strings.Mechanical = "Mecânico"
    
elseif (locale == "itIT") then

    env.Strings.Beast = "Bestia"
    env.Strings.Critter = "Animale"
    env.Strings.Dragonkin = "Dragoide"
    env.Strings.Elemental = "Elementale"
    env.Strings.Giant = "Gigante"
    env.Strings.Humanoid = "Umanoide"
    env.Strings.Mechanical = "Meccanico"
    
end