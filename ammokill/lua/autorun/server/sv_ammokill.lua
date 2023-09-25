function string:startswith(start) return self:sub(1, #start) == start end

hook.Add("PlayerSpawn", "AmmoOnKill", function(player)
    timer.Simple(0.1, function()    -- timer ensures player has fully loaded before giving smg grenades
        if IsValid(player) and GetConVar("ammo_start_with_smg_grenades"):GetInt() == 1 then
            player:SetAmmo(3, "smg1_grenade", true)
        end
    end)
end)

local projectileAmmoTypes = {
    ["prop_combine_ball"] = 2,
    ["rpg_missile"] = 8,
    ["grenade_ar2"] = 9,
    ["npc_satchel"] = 11,
    ["npc_tripmine"] = 11,
    ["npc_grenade_frag"] = 10,
    ["improved_crossbowbolt"] = 6
}
local headshot = false
hook.Add("ScaleNPCDamage", "Headshot", function(npc, hitgroup, dmginfo)
    if GetConVar("ammokill_enabled"):GetBool() and GetConVar("ammokill_headshots_only"):GetBool() then
        if hitgroup == HITGROUP_HEAD or (GetConVar("ammokill_overkills_are_headshots"):GetBool() and (npc:GetMaxHealth() - dmginfo:GetDamage() <= 0)) then
            headshot = true
        end
    end
end)

hook.Add("OnNPCKilled", "AmmoOnKill", function( npc, attacker, inflictor)
    if GetConVar("ammokill_enabled"):GetBool() and GetConVar("ammokill_headshots_only"):GetBool() then
        if (GetConVar("ammokill_overkills_are_headshots"):GetBool() and inflictor:GetClass() == 'prop_combine_ball') then
            headshot = true            
        end
    end
    if GetConVar("ammokill_enabled"):GetInt() == 1 then
        if IsValid(attacker) and attacker:IsPlayer() then
            if GetConVar("ammokill_headshots_only"):GetBool() and !headshot then
                headshot = false
                return -- exit hook
            end
            headshot = false
            if 100 * math.random() < GetConVar("ammokill_chance"):GetFloat() then -- math.random() * 100 gives number between 0 and 100
                local weapon = attacker:GetActiveWeapon()
                if IsValid(weapon) and inflictor ~= NULL then
                    local inflictorClass = tostring(inflictor:GetClass())
                    local primaryAmmoType = weapon:GetPrimaryAmmoType()
                    local secondaryAmmoType = weapon:GetSecondaryAmmoType()

                    if tostring(weapon:GetClass()):startswith("arccw") then
                        if primaryAmmoType ~= -1 then ReplenishPrimary(weapon, attacker, primaryAmmoType, 1) end
                        if secondaryAmmoType ~= -1 then ReplenishSecondary(weapon, attacker, secondaryAmmoType, 1) end
                    elseif inflictor:IsPlayer() or projectileAmmoTypes[inflictorClass] == nil then -- if hitscan or projectile is not supported
                        if primaryAmmoType ~= -1 and secondaryAmmoType == -1 then   -- if kill involved primary ammo and no secondary ammo
                            ReplenishPrimary(weapon, attacker, primaryAmmoType, 1)     -- replenish primary
                        elseif secondaryAmmoType ~= -1 then                         -- if kill involved secondary ammo
                            if projectileAmmoTypes[inflictor:GetClass()] ~= nil then
                                ReplenishSecondary(weapon, attacker, secondaryAmmoType, 1) -- replenish secondary
                            elseif primaryAmmoType ~= -1 then
                                ReplenishPrimary(weapon, attacker, primaryAmmoType, 1)     -- replenish primary
                            end
                        end
                    else -- for projectiles
                        ReplenishSecondary(weapon, attacker, projectileAmmoTypes[inflictorClass], 1)
                    end
                end
            end
        end
    end
end)

hook.Add("PlayerDeath", "AmmoOnKill", function( victim, inflictor, attacker)
    if GetConVar("ammokill_enabled"):GetBool() and GetConVar("ammokill_headshots_only"):GetBool() then
        if (GetConVar("ammokill_overkills_are_headshots"):GetBool() and inflictor:GetClass() == 'prop_combine_ball') then
            headshot = true            
        end
    end
    if GetConVar("ammokill_enabled"):GetInt() == 1 then
        if IsValid(attacker) and attacker:IsPlayer() then
            if GetConVar("ammokill_headshots_only"):GetBool() and !headshot then
                headshot = false
                return -- exit hook
            end
            headshot = false

            if 100 * math.random() < GetConVar("ammokill_chance"):GetFloat() then -- math.random() * 100 gives number between 0 and 100
                local weapon = attacker:GetActiveWeapon()
                if IsValid(weapon) and inflictor ~= NULL then
                    local inflictorClass = tostring(inflictor:GetClass())
                    local primaryAmmoType = weapon:GetPrimaryAmmoType()
                    local secondaryAmmoType = weapon:GetSecondaryAmmoType()

                    if tostring(weapon:GetClass()):startswith("arccw") then
                        if primaryAmmoType ~= -1 then ReplenishPrimary(weapon, attacker, primaryAmmoType, 1) end
                        if secondaryAmmoType ~= -1 then ReplenishSecondary(weapon, attacker, secondaryAmmoType, 1) end
                    elseif inflictor:IsPlayer() or projectileAmmoTypes[inflictorClass] == nil then -- if hitscan or projectile is not supported
                        if primaryAmmoType ~= -1 and secondaryAmmoType == -1 then   -- if kill involved primary ammo and no secondary ammo
                            ReplenishPrimary(weapon, attacker, primaryAmmoType, 1)     -- replenish primary
                        elseif secondaryAmmoType ~= -1 then                         -- if kill involved secondary ammo
                            if projectileAmmoTypes[inflictor:GetClass()] ~= nil then
                                ReplenishSecondary(weapon, attacker, secondaryAmmoType, 1) -- replenish secondary
                            elseif primaryAmmoType ~= -1 then
                                ReplenishPrimary(weapon, attacker, primaryAmmoType, 1)     -- replenish primary
                            end
                        end
                    else -- for projectiles
                        ReplenishSecondary(weapon, attacker, projectileAmmoTypes[inflictorClass], 1)
                    end
                end
            end
        end
    end
end)

function ReplenishPrimary(weapon, attacker, primaryAmmoType, multiplier)
    -- load relevant cvars
    local max_primary_replenish = GetConVar("ammokill_primarymax"):GetInt()
    local primary_replenish_multiplier = GetConVar("ammokill_primary_multiplier"):GetInt()

    -- if primary max clip = -1 or 1, just give 1 ammo * mult for the kill, within max
    if (weapon:GetMaxClip1() == -1 and (attacker:GetAmmoCount(primaryAmmoType) < max_primary_replenish)) or (weapon:GetMaxClip1() == 1 and (attacker:GetAmmoCount(primaryAmmoType) < 4*max_primary_replenish)) then
        GiveAmmo(attacker, primary_replenish_multiplier * multiplier, primaryAmmoType)
    elseif attacker:GetAmmoCount(primaryAmmoType) / weapon:GetMaxClip1() < max_primary_replenish then -- otherwise, give mult * clip to the player, within max
        if GetConVar("ammokill_balanced"):GetBool() then
            local replenish_lower_limit = GetConVar("ammokill_lower_limit_percent"):GetFloat() / 100
            local replenish = math.floor(math.random(replenish_lower_limit*weapon:GetMaxClip1(), weapon:GetMaxClip1()))
            GiveAmmo(attacker, replenish * primary_replenish_multiplier * multiplier, primaryAmmoType)
        else
            GiveAmmo(attacker, weapon:GetMaxClip1() * primary_replenish_multiplier * multiplier, primaryAmmoType)
        end
    end
end


function ReplenishSecondary(weapon, attacker, secondaryAmmoType, multiplier)
    -- load relevant cvars
    local max_secondary_replenish = GetConVar("ammokill_secondarymax"):GetInt()
    local secondary_replenish_multiplier = GetConVar("ammokill_secondary_multiplier"):GetInt()

    if attacker:GetAmmoCount(secondaryAmmoType) < max_secondary_replenish then
        GiveAmmo(attacker, secondary_replenish_multiplier * multiplier, secondaryAmmoType)
    end
end

function GiveAmmo(attacker, amount, ammoType)
    if GetConVar("ammokill_hidden"):GetInt() == 0 then
        attacker:GiveAmmo(amount, ammoType, false)  -- false = not hidden
    else
        attacker:GiveAmmo(amount, ammoType, true)   -- true = hidden
    end
end