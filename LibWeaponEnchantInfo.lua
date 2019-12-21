WEAPON_ENCHANT_INFO = {}

-- Enchant IDs for all ranks of Windfury Totem and Flametongue Totem
WINDFURY_ID = {
	[1783] = true, -- Rank 1
	[563] = true, -- Rank 2
	[564] = true -- Rank 3
}

FLAMETONGUE_ID = {
	[124] = true, -- Rank 1
	[285] = true, -- Rank 2
	[543] = true, -- Rank 3
	[1683] = true -- Rank 4
}

WINDFURY_ICON = 136114
FLAMETONGUE_ICON = 136040

-- Addon Message Prefixes
WEI_ENCHANT_APPLIED = "WEI_EnchantApplied"
WEI_ENCHANT_REMOVED = "WEI_EnchantRemoved"

function LibWeaponEnchantInfo_OnLoad(self, ...)
	self:RegisterEvent("ADDON_LOADED");
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
end

function LibWeaponEnchantInfo_OnEvent(self, event, ...)
	if(event == "ADDON_LOADED" and select(1,...) == "LibWeaponEnchantInfo") then
		C_ChatInfo.RegisterAddonMessagePrefix(WEI_ENCHANT_APPLIED)
		C_ChatInfo.RegisterAddonMessagePrefix(WEI_ENCHANT_REMOVED)
	elseif event == "UNIT_INVENTORY_CHANGED" and select(1,...) == "player" then
		-- Our own weapon enchant was updated, broadcast the new status to the party
		local name = UnitName("player")
		local weaponEnchantInfo = {GetWeaponEnchantInfo()}
		local enchantID = weaponEnchantInfo[4]

		if WINDFURY_ID[enchantID] or FLAMETONGUE_ID[enchantID] then
			-- We have Windfury/Flametongue on our weapon

			-- Expiration Time
			-- At the time that UNIT_INVENTORY_CHANGED gets triggered, GetWeaponEnchantInfo does not yet have
			-- updated information about the new enchant that was applied. Since totem enchants last 10 seconds and
			-- are reapplied every 5 seconds, we can make an educated guess about when the new enchant will expire.
			-- Our guess should only be inaccurate when the player weapon swaps, and will be corrected at the next 5 second interval.
			--
			-- We use Server Time so that it's synced when sending it to our party.
			local expiration = GetServerTime() + 10

			local icon = nil
			if WINDFURY_ID[enchantID] then
				icon = WINDFURY_ICON
			else
				icon = FLAMETONGUE_ICON
			end

			-- Tell our party to update their table
			C_ChatInfo.SendAddonMessage(WEI_ENCHANT_APPLIED, name..","..expiration..","..icon,"PARTY")

			-- Update ourselves in our local table
			WEAPON_ENCHANT_INFO[name] = {}
			WEAPON_ENCHANT_INFO[name].expiration = expiration
			WEAPON_ENCHANT_INFO[name].icon = icon
		else
			-- The weapon might have a new enchant but if it's not Windfury or Flametongue, pretend it has none

			-- Tell our party to update their table
			C_ChatInfo.SendAddonMessage(WEI_ENCHANT_REMOVED, UnitName("player"))

			-- Update ourselves in our local table
			WEAPON_ENCHANT_INFO[name] = nil
		end
	elseif event == "CHAT_MSG_ADDON" then
		local prefix = select(1,...)
		if prefix == WEI_ENCHANT_APPLIED then
			local name, expiration, icon = select(2,...):match(("([^,]*)[,]?"):rep(3))

			WEAPON_ENCHANT_INFO[name] = {}

			WEAPON_ENCHANT_INFO[name].expiration = expiration
			WEAPON_ENCHANT_INFO[name].icon = icon

		elseif prefix == WEI_ENCHANT_REMOVED then
			local name = select(2,...)
			WEAPON_ENCHANT_INFO[name] = nil
		end
	end
end

-- Returns:
--   boolean hasMainHandEnchant
--   string expiration (Local Time, in seconds)
--   string icon
function GetPartyWeaponEnchantInfo(name)
	if WEAPON_ENCHANT_INFO[name] then
		-- Convert from Server Time to local PC time
		local localExpiration = (WEAPON_ENCHANT_INFO[name].expiration - GetServerTime()) + GetTime()
		return true, localExpiration, WEAPON_ENCHANT_INFO[name].icon
	else
		return false
	end
end
