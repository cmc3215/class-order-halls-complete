--------------------------------------------------------------------------------------------------------------------------------------------
-- Initialize Variables
--------------------------------------------------------------------------------------------------------------------------------------------
local NS = select( 2, ... );
local L = NS.localization;
--
NS.initialized = false;
--
NS.lastTimeUpdateRequest = nil;
NS.lastTimeUpdateRequestSent = nil;
NS.lastTimeUpdateAll = nil;
--
NS.shipmentConfirmsRequired = 3; -- Bypassed for players without a Class Order Hall
NS.shipmentConfirmsCount = 0;
NS.shipmentConfirmsFlaggedComplete = false;
NS.refresh = false;
--
NS.minimapButtonFlash = nil;
NS.alertFlashing = false;
--
NS.selectedCharacterKey = nil;
NS.charactersTabItems = {};
--
NS.allCharacters = {
	seals = {},
	missions = {},
	advancement = {},
	orders = {},
	--
	missionsComplete = 0,
	missionsTotal = 0,
	nextMissionTimeRemaining = nil,
	allMissionsTimeRemaining = nil,
	--
	advancementsComplete = 0,
	advancementsTotal = 0,
	nextAdvancementTimeRemaining = nil,
	allAdvancementsTimeRemaining = nil,
	--
	workOrdersReady = 0,
	workOrdersTotal = 0,
	nextWorkOrderTimeRemaining = nil,
	allWorkOrdersTimeRemaining = nil,
	--
	alertCurrentCharacter = false,
	alertAnyCharacter = false,
};
NS.currentCharacter = {
	name = UnitName( "player" ) .. "-" .. GetRealmName(),
	class = select( 2, UnitClass( "player" ) ),		-- Permanent
	classID = select( 3, UnitClass( "player" ) ),	-- Permanent
	key = nil,										-- Set on initialize and reset after character deletion
	level = nil,									-- Reset in UpdateCharacter()
	troops = nil,									-- Set on events
};
--
NS.classRef = {
	--
	-- Class Reference
	--
	-- Quests or Talents that signify the character is capable of starting Research or Work Orders
	--
	-- advancement = "Order Advancement"										- questID
	-- artifact = "Artifact Research Notes"										- questID
	-- armaments = Champion Armaments or Equipment Work Orders Talent - Tier 3	- talent.id
	-- wqcomplete = World Quest Complete Work Order Talent - Tier 5				- talent.id, itemID, itemName
	-- bonusroll = Bonus Roll Work Order Talent - Tier 5						- talent.id
	-- missions = "Missions"													- questID
	--
	["WARRIOR"] = {
		advancement = 42611, 								-- Einar the Runecaster
		artifact = 43888, 									-- Hitting the Books
		armaments = 411, 									-- Heavenly Forge
		wqcomplete = { 410, 140157, L["Horn of War"] },		-- Val'kyr Call
		--bonusroll = 0,									-- N/A
		missions = 42598,									-- Champions of Skyhold
	},
	["DEATHKNIGHT"] = {
		advancement = 43268,								-- Tech It Up A Notch
		artifact = 43877,									-- Hitting the Books
		armaments = 433,									-- Brothers in Arms
		wqcomplete = { 432, 139888, L["Frost Crux"] },			-- Frost Wyrm
		--bonusroll = 0,									-- N/A
		missions = 43264,									-- Rise, Champions
	},
	["PALADIN"] = {
		advancement = 42850, 								-- Tech It Up A Notch
		artifact = 43883, 									-- Hitting the Books
		armaments =	400, 									-- Plowshares to Swords
		wqcomplete = { 399, 140155, L["Silver Hand Orders"] }, -- Grand Crusade
		bonusroll = 398, 									-- Holy Purpose
		missions = 42846,									-- The Blood Matriarch
	},
	["MONK"] = {
		advancement = 42191, 								-- Tech It Up A Notch
		artifact = 43881, 									-- Hitting the Books
		--armaments = 0, 									-- N/A
		--wqcomplete = { 0, 0 },							-- N/A
		bonusroll = 256, 									-- One with Destiny
		missions = 42187,									-- Rise, Champions
	},
	["PRIEST"] = {
		advancement = 43277, 								-- Tech It Up A Notch
		artifact = 43884, 									-- Hitting the Books
		armaments =	455, 									-- Armaments of Light
		--wqcomplete = { 0, 0 },							-- N/A
		bonusroll = 454, 									-- Blessed Seals
		missions = 43270,									-- Rise, Champions
	},
	["SHAMAN"] = {
		advancement = 41740, 								-- Tech It Up A Notch
		artifact = 43886, 									-- Speaking to the Wind
		--armaments = 0, 									-- N/A
		--wqcomplete = { 0, 0 },							-- N/A
		bonusroll = 49, 									-- Spirit Walk
		missions = 42383,									-- Rise, Champions
	},
	["DRUID"] = {
		advancement = 42588, 								-- Branching Out
		artifact = 43879, 									-- Hitting the Books
		--armaments = 0, 									-- N/A
		--wqcomplete = { 0, 0 },							-- N/A
		bonusroll = 355, 									-- Elune's Chosen
		missions = 42583,									-- Rise, Champions
	},
	["ROGUE"] = {
		advancement = 43015, 								-- What Winstone Suggests
		artifact = 43885, 									-- Hitting the Books
		armaments =	444, 									-- Weapons Smuggler
		--wqcomplete = { 0, 0 },							-- N/A
		bonusroll = 443, 									-- Plunder
		missions = 42139,									-- Rise, Champions
	},
	["MAGE"] = {
		advancement = 42696, 								-- Tech It Up A Notch
		artifact = 43749, 									-- Hitting the Books
		armaments =	389, 									-- Arcane Armaments
		wqcomplete = { 388, 140038, L["Focusing Crystal"] },	-- Might of Dalaran
		bonusroll = 387, 									-- Arcane Divination
		missions = 42663,									-- Rise, Champions
	},
	["WARLOCK"] = {
		advancement = 42601, 								-- Tech It Up A Notch
		artifact = 43887, 									-- Hitting the Books
		armaments =	364, 									-- Shadow Pact
		wqcomplete = { 367, 139892, L["Demonic Phylactery"] }, -- Unleash Infernal
		--bonusroll = 0, -- N/A
		missions = 42608,									-- Rise, Champions
	},
	["HUNTER"] = {
		advancement = 42526, 								-- Tech It Up A Notch
		artifact = 43880, 									-- Hitting the Books
		armaments = 378, 									-- Fletchery
		--wqcomplete = { 0, 0 },							-- N/A
		bonusroll = 377, 									-- Unseen Path
		missions = 42519,									-- Rise, Champions
	},
	["DEMONHUNTER"] = {
		advancement = 42683, 								-- Demonic Improvements
		artifact = 43878, 									-- Hitting the Books
		armaments =	422, 									-- Fel Armaments
		wqcomplete = { 421, 140158, L["Empowered Rift Core"] },-- Fel Hammer's Wrath
		bonusroll =	420, 									-- Focused War Effort
		missions = { 42670, 42671 },						-- Rise, Champions
	},
};
NS.sealOfBrokenFateQuests = { 43892, 43893, 43894, 43895, 43896, 43897 }; -- Sealing Fate quests in Dalaran
--------------------------------------------------------------------------------------------------------------------------------------------
-- SavedVariables(PerCharacter)
--------------------------------------------------------------------------------------------------------------------------------------------
NS.DefaultSavedVariables = function()
	return {
		["version"] = NS.version,
		["characters"] = {},
		["orderCharactersAutomatically"] = true,
		["currentCharacterFirst"] = true,
		["showCharacterRealms"] = true,
		["forgetDragPosition"] = true,
		["dragPosition"] = nil,
		["monitorRows"] = 8,
		["monitorColumn"] = {
			"missions",
			"advancement",
			"artifact-research-notes",
			"cooking-recipes",
			"troop1",
			"troop2",
			"champion-armaments",
			"world-quest-complete/bonus-roll",
			"troop3",
			"troop4",
		},
		["alert"] = "current",
		["alertMissions"] = true,
		["alertClassHallUpgrades"] = true,
		["alertTroops"] = true,
		["alertArtifactResearchNotes"] = true,
		["alertAnyArtifactResearchNotes"] = true,
		["alertChampionArmaments"] = true,
		["alertLegionCookingRecipes"] = true,
		["alertInstantCompleteWorldQuest"] = true,
		["alertBonusRollToken"] = true,
		["alertDisableInInstances"] = true,
	};
end
--
NS.DefaultSavedVariablesPerCharacter = function()
	return {
		["version"] = NS.version,
		["showMinimapButton"] = true,
		["largeMinimapButton"] = true,
		["dockMinimapButton"] = true,
		["minimapButtonPosition"] = 302.5,
		["showClassHallReportMinimapButton"] = true,
	};
end
--
NS.Upgrade = function()
	local vars = NS.DefaultSavedVariables();
	local version = NS.db["version"];
	-- 1.01
	if version < 1.01 then
		NS.db["alertMissions"] = vars["alertMissions"];
		NS.db["alertClassHallUpgrades"] = vars["alertClassHallUpgrades"];
		NS.db["alertTroops"] = vars["alertTroops"];
		NS.db["alertArtifactResearchNotes"] = vars["alertArtifactResearchNotes"];
		NS.db["alertAnyArtifactResearchNotes"] = vars["alertAnyArtifactResearchNotes"];
		NS.db["alertChampionArmaments"] = vars["alertChampionArmaments"];
		NS.db["alertLegionCookingRecipes"] = vars["alertLegionCookingRecipes"];
		NS.db["alertInstantCompleteWorldQuest"] = vars["alertInstantCompleteWorldQuest"];
		NS.db["alertBonusRollToken"] = vars["alertBonusRollToken"];
	end
	-- 1.02
	if version < 1.02 then
		NS.db["forgetDragPosition"] = vars["forgetDragPosition"];
	end
	-- 1.03
	if version < 1.03 then
		NS.db["orderCharactersAutomatically"] = vars["orderCharactersAutomatically"];
		NS.db["currentCharacterFirst"] = vars["currentCharacterFirst"];
		NS.db["monitorRows"] = vars["monitorRows"];
	end
	-- 1.05
	if version < 1.05 then
		NS.ResetCharactersOrderPositions(); -- Fixes missing field "order" in "characters" table introduced in v1.03
	end
	-- 1.06
	if version < 1.06 then
		NS.db["monitorColumn"] = vars["monitorColumn"];
	end
	--
	NS.db["version"] = NS.version;
end
--
NS.UpgradePerCharacter = function()
	local varspercharacter = NS.DefaultSavedVariablesPerCharacter();
	local version = NS.dbpc["version"];
	-- 1.05
	if version < 1.05 then
		NS.dbpc["dockMinimapButton"] = varspercharacter["dockMinimapButton"];
	end
	--
	NS.dbpc["version"] = NS.version;
end

--------------------------------------------------------------------------------------------------------------------------------------------
-- Misc
--------------------------------------------------------------------------------------------------------------------------------------------
NS.SortCharacters = function( order, move )
	local selectedCharacterName = NS.selectedCharacterKey and NS.db["characters"][NS.selectedCharacterKey]["name"] or NS.currentCharacter.name;
	--
	if order == "automatic" then
		table.sort ( NS.db["characters"],
			function ( char1, char2 )
				if char1["realm"] == char2["realm"] then
					return char1["name"] < char2["name"];
				else
					return char1["realm"] < char2["realm"];
				end
			end
		);
	elseif order == "manual" then
		for i = 1, #NS.db["characters"] do
			if i == move["ck"] then
				-- Order
				NS.db["characters"][i]["order"] = move["order"];
			elseif move["ck"] > move["order"] then
				-- Moving Up, Reorder Downward
				if i == move["order"] or ( i < move["ck"] and i > move["order"] ) then
					NS.db["characters"][i]["order"] = i + 1;
				end
			elseif move["ck"] < move["order"] then
				-- Moving Down, Reorder Upward
				if i == move["order"] or ( i > move["ck"] and i < move["order"] ) then
					NS.db["characters"][i]["order"] = i - 1;
				end
			end
		end
		NS.Sort( NS.db["characters"], "order", "ASC" );
	end
	--
	NS.currentCharacter.key = NS.FindKeyByField( NS.db["characters"], "name", NS.currentCharacter.name );
	NS.selectedCharacterKey = NS.FindKeyByField( NS.db["characters"], "name", selectedCharacterName );
end
--
NS.ChangeColumns = function( old, new )
	-- Create temp table for column slugs that require change
	local t = {};
	-- Write column slugs to temp table that require change
	for i = 1, #NS.db["monitorColumn"] do
		if i == old then
			-- New
			t[new] = NS.db["monitorColumn"][i];
		elseif old > new then
			-- Moving Up, Reorder Downward
			if i == new or ( i < old and i > new ) then
				t[i + 1] = NS.db["monitorColumn"][i];
			end
		elseif old < new then
			-- Moving Down, Reorder Upward
			if i == new or ( i > old and i < new ) then
				t[i - 1] = NS.db["monitorColumn"][i];
			end
		end
	end
	-- Copy changed column slugs to primary table
	for k,v in pairs( t ) do
		NS.db["monitorColumn"][k] = v;
	end
end
--
NS.ResetCharactersOrderPositions = function()
	for i = 1, #NS.db["characters"] do
		NS.db["characters"][i]["order"] = i;
	end
end
--
NS.OrdersReadyToPickup = function( ready, total, duration, nextSeconds, updateTime, currentTime )
	-- Calculate how many orders could have completed in the time past, which could not be larger than the
	-- amount of orders in progress ( i.e. total - ready ), then we just add the orders that were already ready
	if not total then return 0 end
	return math.min( math.floor( ( currentTime - updateTime + ( duration - nextSeconds ) ) / duration ), ( total - ready ) ) + ready;
end
--
NS.OrdersReadyToStart = function( capacity, total, troopCount )
	if troopCount == "?" then return 0 end
	total = total and total or 0;
	troopCount = troopCount and troopCount or 0;
	return ( capacity - ( total + troopCount ) );
end
--
NS.OrdersAllSeconds = function( duration, total, ready, nextSeconds, updateTime, currentTime )
	if not total then return 0 end
	local seconds = duration * ( total - ready ) - ( duration - ( nextSeconds - ( currentTime - updateTime ) ) );
	return seconds > 0 and seconds or 0;
end
--
NS.OrdersNextSeconds = function( allSeconds, duration )
	if allSeconds == 0 then return 0 end
	return allSeconds % duration;
end
--
NS.OrdersOrigNextSeconds = function( duration, creationTime, currentTime )
	if not creationTime then return 0 end
	return ( duration - ( currentTime - creationTime ) );
end
--
NS.ToggleAlert = function()
	if not NS.minimapButtonFlash then
		NS.minimapButtonFlash = COHCMinimapButton:CreateAnimationGroup();
		NS.minimapButtonFlash:SetLooping( "REPEAT" );
		local a1 = NS.minimapButtonFlash:CreateAnimation( "Alpha" );
		a1:SetDuration( 0.5 );
		a1:SetFromAlpha( 1 );
		a1:SetToAlpha( -1 );
		a1:SetOrder( 1 );
		local a2 = NS.minimapButtonFlash:CreateAnimation( "Alpha" );
		a2:SetDuration( 0.5 );
		a2:SetFromAlpha( -1 );
		a2:SetToAlpha( 1 );
		a2:SetOrder( 2 );
	end
	--
	if NS.dbpc["showMinimapButton"] and ( not NS.db["alertDisableInInstances"] or not IsInInstance() ) and (
			( NS.db["alert"] == "current" and NS.allCharacters.alertCurrentCharacter ) or ( NS.db["alert"] == "any" and NS.allCharacters.alertAnyCharacter )
		) then
		if not NS.alertFlashing then
			NS.alertFlashing = true;
			NS.minimapButtonFlash:Play();
		end
	else
		if NS.alertFlashing then
			NS.alertFlashing = false;
			NS.minimapButtonFlash:Stop();
		end
	end
end
--
NS.ShipmentConfirmsComplete = function()
	NS.shipmentConfirmsFlaggedComplete = true;
	_G[NS.UI.SubFrames[1]:GetName() .. "MessageShipmentConfirmsText"]:SetText( "" );
	if NS.UI.SubFrames[1]:IsShown() then
		NS.refresh = true;
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Updates
--------------------------------------------------------------------------------------------------------------------------------------------
NS.UpdateCharacter = function()
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Find/Add Character
	--------------------------------------------------------------------------------------------------------------------------------------------
	local newCharacter = false;
	local k = NS.FindKeyByField( NS.db["characters"], "name", NS.currentCharacter.name ) or #NS.db["characters"] + 1;
	if not NS.db["characters"][k] then
		newCharacter = true; -- Flag for sort
		NS.db["characters"][k] = {
			["name"] = NS.currentCharacter.name,						-- Permanent
			["realm"] = GetRealmName(),									-- Permanent
			["class"] = NS.currentCharacter.class,						-- Permanent
			["orderResources"] = 0,										-- Reset below every update
			["advancement"] = {},										-- Reset below every update
			["orders"] = {},											-- Reset below every update
			["troops"] = {},											-- Reset below every update if inOrderHall, otherwise reused
			["missions"] = {},											-- Reset below every update
			["seals"] = {},												-- Reset below every update
			["monitor"] = {},											-- Set below for each item when first added
		};
	end
	--------------------------------------------------------------------------------------------------------------------------------------------
	NS.currentCharacter.level = UnitLevel( "player" );
	NS.db["characters"][k]["orderResources"] = select( 2, GetCurrencyInfo( 1220 ) );
	NS.db["characters"][k]["sealOfBrokenFate"] = select( 2, GetCurrencyInfo( 1273 ) );
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Class Order Hall ?
	--------------------------------------------------------------------------------------------------------------------------------------------
	local hasOrderHall = C_Garrison.HasGarrison( LE_GARRISON_TYPE_7_0 );
	local inOrderHall = C_Garrison.IsPlayerInGarrison( LE_GARRISON_TYPE_7_0 );
	if hasOrderHall then
		--------------------------------------------------------------------------------------------------------------------------------------------
		-- Shipment Confirm: Avoids incomplete and inaccurate data being recorded following login, reloads, and pickups
		--------------------------------------------------------------------------------------------------------------------------------------------
		local shipmentsNum,shipmentsNumReady = 0,0;
		--
		local followerShipments = C_Garrison.GetFollowerShipments( LE_GARRISON_TYPE_7_0 );
		shipmentsNum = shipmentsNum + #followerShipments;
		for i = 1, #followerShipments do
			local name,texture,shipmentCapacity,shipmentsReady,shipmentsTotal,creationTime,duration,timeleftString = C_Garrison.GetLandingPageShipmentInfoByContainerID( followerShipments[i] );
			if name and texture and shipmentCapacity > 0 and shipmentsReady and shipmentsTotal > 0 then
				shipmentsNumReady = shipmentsNumReady + 1;
			end
		end
		--
		local looseShipments = C_Garrison.GetLooseShipments( LE_GARRISON_TYPE_7_0 );
		shipmentsNum = shipmentsNum + #looseShipments;
		for i = 1, #looseShipments do
			local name,texture,shipmentCapacity,shipmentsReady,shipmentsTotal,creationTime,duration,timeleftString = C_Garrison.GetLandingPageShipmentInfoByContainerID( looseShipments[i] );
			if name and texture and shipmentCapacity > 0 and shipmentsReady and shipmentsTotal > 0 then
				shipmentsNumReady = shipmentsNumReady + 1;
			end
		end
		--
		local shipmentConfirmed = false;
		if shipmentsNum == shipmentsNumReady then
			shipmentConfirmed = true;
			if not NS.shipmentConfirmsFlaggedComplete and NS.shipmentConfirmsCount < NS.shipmentConfirmsRequired then
				NS.shipmentConfirmsCount = NS.shipmentConfirmsCount + 1;
				if NS.shipmentConfirmsCount == NS.shipmentConfirmsRequired then
					NS.ShipmentConfirmsComplete();
				end
			end
		end
		--------------------------------------------------------------------------------------------------------------------------------------------
		-- Update Class Order Hall info the moment shipments are confirmed
		--------------------------------------------------------------------------------------------------------------------------------------------
		if NS.shipmentConfirmsFlaggedComplete and shipmentConfirmed then
			local monitorable = {};
			local currentTime = time();
			--------------------------------------------------------------------------------------------------------------------------------------------
			-- Order Advancement
			--------------------------------------------------------------------------------------------------------------------------------------------
			wipe( NS.db["characters"][k]["advancement"] ); -- Start fresh every update
			local talentTiers = {}; -- Selected talents by tier
			if IsQuestFlaggedCompleted( NS.classRef[NS.currentCharacter.class].advancement ) or GetQuestLogIndexByID( NS.classRef[NS.currentCharacter.class].advancement ) > 0 then
				if NS.db["characters"][k]["monitor"]["advancement"] == nil then
					NS.db["characters"][k]["monitor"]["advancement"] = true;
				end
				monitorable["advancement"] = true;
				--
				local talentTrees = C_Garrison.GetTalentTrees( LE_GARRISON_TYPE_7_0, NS.currentCharacter.classID );
				local completeTalentID = C_Garrison.GetCompleteTalent( LE_GARRISON_TYPE_7_0 );
				if talentTrees and #talentTrees[1] > 0 then -- Talent trees and talents available
					for _,talent in ipairs( talentTrees[1] ) do
						talent.tier = talent.tier + 1; -- Fix tiers starting at 0
						talent.uiOrder = talent.uiOrder + 1; -- Fix order starting at 0
						if talent.selected then
							talentTiers[talent.tier] = talent;
							if talent.isBeingResearched or talent.id == completeTalentID then
								NS.db["characters"][k]["advancement"]["talentBeingResearched"] = CopyTable( talent );
								--NS.Print( "|T" .. talent.icon .. ":16|t " .. talent.name .. " - isBeingResearched" ); -- DEBUG
							end
							--NS.Print( "|T" .. talent.icon .. ":16|t " .. talent.name ); -- DEBUG
						end
					end
					-- Talent Tier Available?
					if ( not NS.db["characters"][k]["advancement"]["talentBeingResearched"] and #talentTiers < 8 ) then
						if #talentTiers == 0 or ( #talentTiers == 1 and NS.currentCharacter.level >= 105 ) or NS.currentCharacter.level >= 110 then
							NS.db["characters"][k]["advancement"]["newTalentTier"] = {};
							local newTier = #talentTiers + 1;
							for _,talent in ipairs( talentTrees[1] ) do
								if talent.tier == newTier then
									NS.db["characters"][k]["advancement"]["newTalentTier"][talent.uiOrder] = CopyTable( talent );
								end
							end
							--NS.Print( "Talent tier available = " .. newTier ); -- DEBUG
						end
					end
				end
				--
				NS.db["characters"][k]["advancement"]["numTalents"] = #talentTiers;
			end
			--------------------------------------------------------------------------------------------------------------------------------------------
			-- Work Orders
			--------------------------------------------------------------------------------------------------------------------------------------------
			wipe( NS.db["characters"][k]["orders"] ); -- Start fresh every update
			-- Follower Shipments
			local followerShipments = C_Garrison.GetFollowerShipments( LE_GARRISON_TYPE_7_0 );
			for i = 1, #followerShipments do
				local name,texture,shipmentCapacity,shipmentsReady,shipmentsTotal,creationTime,duration,timeleftString = C_Garrison.GetLandingPageShipmentInfoByContainerID( followerShipments[i] );
				table.insert( NS.db["characters"][k]["orders"], {
					["name"] = name,
					["texture"] = texture,
					["capacity"] = shipmentCapacity,
					["ready"] = shipmentsReady,
					["total"] = shipmentsTotal,
					["duration"] = duration,
					["nextSeconds"] = NS.OrdersOrigNextSeconds( duration, creationTime, currentTime ),
					["troopCount"] = "?",
				} );
				if NS.db["characters"][k]["monitor"][texture] == nil then
					NS.db["characters"][k]["monitor"][texture] = true;
				end
				monitorable[texture] = true;
			end
			--------------------------------------------------------------------------------------------------------------------------------------------
			-- Troops => Follower Shipments
			--------------------------------------------------------------------------------------------------------------------------------------------
			if NS.currentCharacter.troops then
				NS.db["characters"][k]["troops"] = CopyTable( NS.currentCharacter.troops );
				NS.currentCharacter.troops = nil;
			end
			local troops = NS.db["characters"][k]["troops"];
			for i = 1, #troops do
				local ordersKey = NS.FindKeyByField( NS.db["characters"][k]["orders"], "texture", troops[i].icon ) or NS.FindKeyByField( NS.db["characters"][k]["orders"], "name", troops[i].name );
				local texture;
				if ordersKey then
					-- Fix orders texture to match troop icon, most will already match, this just catches the outliers.
					texture = NS.db["characters"][k]["orders"][ordersKey]["texture"];
					if troops[i].icon ~= texture then
						monitorable[texture] = nil; -- Removes old texture from monitor
						texture = troops[i].icon;
						NS.db["characters"][k]["orders"][ordersKey]["texture"] = texture;
					end
					--
					NS.db["characters"][k]["orders"][ordersKey]["capacity"] = troops[i].limit;
					NS.db["characters"][k]["orders"][ordersKey]["troopCount"] = troops[i].count;
				else
					texture = troops[i].icon;
					table.insert( NS.db["characters"][k]["orders"], {
						["name"] = troops[i].name,
						["texture"] = texture,
						["capacity"] = troops[i].limit,
						["troopCount"] = troops[i].count,
					} );
				end
				if NS.db["characters"][k]["monitor"][texture] == nil then
					NS.db["characters"][k]["monitor"][texture] = true;			-- Monitored by default
				end
				monitorable[texture] = true;
				--NS.Print( "|T" .. troops[i].icon .. ":16|t count = " .. troops[i].count ); -- DEBUG
			end
			NS.Sort( NS.db["characters"][k]["orders"], "capacity", "ASC" ); -- Order troops by capacity for a more consistent display
			-- Loose Shipments
			local looseShipments = C_Garrison.GetLooseShipments( LE_GARRISON_TYPE_7_0 );
			for i = 1, #looseShipments do
				local name,texture,shipmentCapacity,shipmentsReady,shipmentsTotal,creationTime,duration,timeleftString = C_Garrison.GetLandingPageShipmentInfoByContainerID( looseShipments[i] );
				table.insert( NS.db["characters"][k]["orders"], {
					["name"] = name,
					["texture"] = texture,
					["capacity"] = shipmentCapacity,
					["ready"] = shipmentsReady,
					["total"] = shipmentsTotal,
					["duration"] = duration,
					["nextSeconds"] = NS.OrdersOrigNextSeconds( duration, creationTime, currentTime ),
				} );
				if NS.db["characters"][k]["monitor"][texture] == nil then
					NS.db["characters"][k]["monitor"][texture] = true;
				end
				monitorable[texture] = true;
			end
			-- Artifact Research Notes
			if IsQuestFlaggedCompleted( NS.classRef[NS.currentCharacter.class].artifact ) then
				local texture = 237446;
				local capacity = 2;
				local ordersKey = NS.FindKeyByField( NS.db["characters"][k]["orders"], "texture", texture );
				local orders = ordersKey and NS.db["characters"][k]["orders"][ordersKey]["total"] or 0;
				if orders == 0 then
					table.insert( NS.db["characters"][k]["orders"], {
						["name"] = GetItemInfo( 139390 ) or L["Artifact Research Notes"],
						["texture"] = texture,
						["capacity"] = capacity,
					} );
					if NS.db["characters"][k]["monitor"][texture] == nil then
						NS.db["characters"][k]["monitor"][texture] = true;
					end
					monitorable[texture] = true;
				end
				--NS.Print( "|T" .. texture .. ":16|t orders available = " .. available ); -- DEBUG
			end
			-- Champion Armaments (Tier 3)
			if talentTiers[3] and not talentTiers[3].isBeingResearched and talentTiers[3].id == NS.classRef[NS.currentCharacter.class].armaments then
				local texture = 975736;
				local capacity = 4;
				local ordersKey = NS.FindKeyByField( NS.db["characters"][k]["orders"], "texture", texture );
				local orders = ordersKey and NS.db["characters"][k]["orders"][ordersKey]["total"] or 0;
				if orders == 0 then
					table.insert( NS.db["characters"][k]["orders"], {
						["name"] = GetItemInfo( 139308 ) or L["Champion Armaments"],
						["texture"] = texture,
						["capacity"] = capacity,
					} );
					if NS.db["characters"][k]["monitor"][texture] == nil then
						NS.db["characters"][k]["monitor"][texture] = true;
					end
					monitorable[texture] = true;
				end
				--NS.Print( "|T" .. texture .. ":16|t orders available = " .. available ); -- DEBUG
			end
			-- World Quest Complete (Tier 5)
			if NS.classRef[NS.currentCharacter.class].wqcomplete and talentTiers[5] and not talentTiers[5].isBeingResearched and talentTiers[5].id == NS.classRef[NS.currentCharacter.class].wqcomplete[1] then
				local texture = GetItemIcon( NS.classRef[NS.currentCharacter.class].wqcomplete[2] );
				local capacity = 1;
				local ordersKey = NS.FindKeyByField( NS.db["characters"][k]["orders"], "texture", texture );
				local orders = ordersKey and NS.db["characters"][k]["orders"][ordersKey]["total"] or 0;
				if orders == 0 then
					table.insert( NS.db["characters"][k]["orders"], {
						["name"] = GetItemInfo( NS.classRef[NS.currentCharacter.class].wqcomplete[2] ) or NS.classRef[NS.currentCharacter.class].wqcomplete[3],
						["texture"] = texture,
						["capacity"] = capacity,
					} );
					if NS.db["characters"][k]["monitor"][texture] == nil then
						NS.db["characters"][k]["monitor"][texture] = true;
					end
					monitorable[texture] = true;
				end
				--NS.Print( "|T" .. texture .. ":16|t orders available = " .. available ); -- DEBUG
			end
			-- Bonus Roll (Tier 5)
			if NS.classRef[NS.currentCharacter.class].bonusroll and talentTiers[5] and not talentTiers[5].isBeingResearched and talentTiers[5].id == NS.classRef[NS.currentCharacter.class].bonusroll then
				local texture = 1604167;
				local capacity = 1;
				local ordersKey = NS.FindKeyByField( NS.db["characters"][k]["orders"], "texture", texture );
				local orders = ordersKey and NS.db["characters"][k]["orders"][ordersKey]["total"] or 0;
				if orders == 0 then
					table.insert( NS.db["characters"][k]["orders"], {
						["name"] = GetItemInfo( 139460 ) or L["Seal of Broken Fate"],
						["texture"] = texture,
						["capacity"] = capacity,
					} );
					if NS.db["characters"][k]["monitor"][texture] == nil then
						NS.db["characters"][k]["monitor"][texture] = true;
					end
					monitorable[texture] = true;
				end
				--NS.Print( "|T" .. texture .. ":16|t orders available = " .. available ); -- DEBUG
			end
			-- Cooking Recipes
			if IsQuestFlaggedCompleted( 40991 ) then
				local texture = 134939;
				local capacity = 24;
				local ordersKey = NS.FindKeyByField( NS.db["characters"][k]["orders"], "texture", texture );
				local orders = ordersKey and NS.db["characters"][k]["orders"][ordersKey]["total"] or 0;
				if orders == 0 then
					table.insert( NS.db["characters"][k]["orders"], {
						["name"] = L["Legion Cooking Recipes"],
						["texture"] = texture,
						["capacity"] = capacity,
					} );
					if NS.db["characters"][k]["monitor"][texture] == nil then
						NS.db["characters"][k]["monitor"][texture] = true;
					end
					monitorable[texture] = true;
				end
				--NS.Print( "|T" .. texture .. ":16|t orders available = " .. available ); -- DEBUG
			end
			--------------------------------------------------------------------------------------------------------------------------------------------
			-- Missions
			--------------------------------------------------------------------------------------------------------------------------------------------
			wipe( NS.db["characters"][k]["missions"] );
			if ( NS.currentCharacter.class ~= "DEMONHUNTER" and IsQuestFlaggedCompleted( NS.classRef[NS.currentCharacter.class].missions ) ) or ( NS.currentCharacter.class == "DEMONHUNTER" and ( IsQuestFlaggedCompleted( NS.classRef[NS.currentCharacter.class].missions[1] ) or IsQuestFlaggedCompleted( NS.classRef[NS.currentCharacter.class].missions[2] ) ) ) then
				NS.db["characters"][k]["missions"] = C_Garrison.GetLandingPageItems( LE_GARRISON_TYPE_7_0 ); -- In Progress or Complete
				for i = 1, #NS.db["characters"][k]["missions"] do
					local mission = NS.db["characters"][k]["missions"][i];
					-- Success Chance
					mission.successChance = C_Garrison.GetMissionSuccessChance( mission.missionID );
					-- Rewards
					mission.rewardsList = {};
					for _,reward in pairs( mission.rewards ) do
						if reward.quality then
							mission.rewardsList[#mission.rewardsList + 1] = ITEM_QUALITY_COLORS[reward.quality + 1].hex .. reward.title .. FONT_COLOR_CODE_CLOSE;
						elseif reward.itemID then
							local itemName,_,itemRarity,_,_,_,_,_,_,itemTexture = GetItemInfo( reward.itemID );
							if not itemTexture then
								_,_,_,_,itemTexture = GetItemInfoInstant( reward.itemID );
							end
							if itemName then
								mission.rewardsList[#mission.rewardsList + 1] = "|T" .. itemTexture .. ":20:20:-2:0|t" .. ITEM_QUALITY_COLORS[itemRarity].hex .. itemName .. FONT_COLOR_CODE_CLOSE;
							else
								mission.rewardsList[#mission.rewardsList + 1] = "|T" .. itemTexture .. ":20:20:0:0|t";
							end
						elseif reward.followerXP then
							mission.rewardsList[#mission.rewardsList + 1] = HIGHLIGHT_FONT_COLOR_CODE .. reward.title .. FONT_COLOR_CODE_CLOSE;
						else
							mission.rewardsList[#mission.rewardsList + 1] = HIGHLIGHT_FONT_COLOR_CODE .. reward.title .. FONT_COLOR_CODE_CLOSE;
						end
					end
					-- Followers
					for x = 1, #mission.followers do
						mission.followers[x] = C_Garrison.GetFollowerName( mission.followers[x] ) or UNKNOWN;
					end
				end
				if NS.db["characters"][k]["monitor"]["missions"] == nil then
					NS.db["characters"][k]["monitor"]["missions"] = true;			-- Monitored by default
				end
				monitorable["missions"] = true;
			end
			--------------------------------------------------------------------------------------------------------------------------------------------
			-- Seals
			--------------------------------------------------------------------------------------------------------------------------------------------
			wipe( NS.db["characters"][k]["seals"] );
			if NS.currentCharacter.level >= 110 then
				-- Seal of Broken Fate
				local thisWeek = 0;
				for i = 1, #NS.sealOfBrokenFateQuests do
					if IsQuestFlaggedCompleted( NS.sealOfBrokenFateQuests[i] ) then -- Sealing Fate quests in Dalaran
						thisWeek = thisWeek + 1;
					end
				end
				NS.db["characters"][k]["seals"]["sealOfBrokenFate"] = thisWeek;
			end
			--------------------------------------------------------------------------------------------------------------------------------------------
			-- Update Time / Monitor Clean Up
			--------------------------------------------------------------------------------------------------------------------------------------------
			NS.db["characters"][k]["updateTime"] = currentTime;
			NS.db["characters"][k]["weeklyResetTime"] = NS.GetWeeklyQuestResetTime();
			if not newCharacter then
				-- Monitor Clean Up, only when NOT a new character
				for monitor in pairs( NS.db["characters"][k]["monitor"] ) do
					if not monitorable[monitor] then
						NS.db["characters"][k]["monitor"][monitor] = nil;
					end
				end
			end
		end
	elseif not NS.shipmentConfirmsFlaggedComplete then
		NS.ShipmentConfirmsComplete(); -- shipmentConfirms bypassed if no Class Order Hall
	end
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Sort Characters by realm and name, only when a new character was added
	--------------------------------------------------------------------------------------------------------------------------------------------
	if newCharacter then
		if NS.db["orderCharactersAutomatically"] then
			NS.SortCharacters( "automatic" );
			NS.ResetCharactersOrderPositions();
		else
			NS.db["characters"][k]["order"] = k;
		end
	end
end
--
NS.UpdateCharacters = function()
	-- All Characters
	local seals = {};
	local missions = {};
	local advancement = {};
	local orders = {};
	--
	local missionsComplete = 0;
	local missionsTotal = 0;
	local nextMissionTimeRemaining = 0; -- Lowest time remaining for a mission to complete.
	local allMissionsTimeRemaining = 0; -- Highest Time remaining for a mission to complete.
	--
	local advancementsComplete = 0;
	local advancementsTotal = 0;
	local nextAdvancementTimeRemaining = 0; -- Lowest time remaining for an order advancement to complete.
	local allAdvancementsTimeRemaining = 0; -- Highest time remaining for an order advancement to complete.
	--
	local workOrdersReady = 0;
	local workOrdersTotal = 0;
	local nextWorkOrderTimeRemaining = 0; -- Lowest time remaining for a work order to complete.
	local allWorkOrdersTimeRemaining = 0; -- Highest time remaining for a work order to complete.
	--
	local alertCurrentCharacter = false;
	local alertAnyCharacter = false;
	--
	-- Loop thru each character
	--
	local currentTime = time();
	for ck,char in ipairs( NS.db["characters"] ) do
		local passedTime = char["updateTime"] and ( currentTime - char["updateTime"] ) or nil; -- Characters without Class Order Hall info will not have an updateTime
		--
		-- Seals
		--
		seals[char["name"]] = {};
		if char["seals"]["sealOfBrokenFate"] then
			local s = seals[char["name"]];
			s.sealOfBrokenFate = {
				text = string.format( L["Seal of Broken Fate - %d/6"], char["sealOfBrokenFate"] ),
				thisWeek = currentTime > char["weeklyResetTime"] and 0 or char["seals"]["sealOfBrokenFate"],
			};
			if s.sealOfBrokenFate.thisWeek == 3 then
				s.sealOfBrokenFate.lines = string.format( L["%sTotal Weekly:|r %s3/3|r"], NORMAL_FONT_COLOR_CODE, RED_FONT_COLOR_CODE );
			elseif char["sealOfBrokenFate"] == 6 then
				s.sealOfBrokenFate.text = L["Seal of Broken Fate"];
				s.sealOfBrokenFate.lines = string.format( L["%sTotal Maximum:|r %s6/6|r"], NORMAL_FONT_COLOR_CODE, RED_FONT_COLOR_CODE );
			else
				s.sealOfBrokenFate.lines = HIGHLIGHT_FONT_COLOR_CODE .. string.format( L["%d/%d obtained from \"Sealing Fate\" quests in Dalaran"], s.sealOfBrokenFate.thisWeek, 3 ) .. FONT_COLOR_CODE_CLOSE;
			end
		end
		--
		-- Missions
		--
		missions[char["name"]] = {};
		if char["monitor"]["missions"] then
			local mip = missions[char["name"]];
			mip.texture = 1044517;
			mip.text = string.format( L["Missions In Progress - %d"], #char["missions"] );
			mip.lines = {};
			mip.total = #char["missions"];
			mip.incomplete = mip.total;
			missionsTotal = missionsTotal + mip.total; -- All characters
			for _,m in ipairs( char["missions"] ) do -- m is for mission, that's good enough for me
				mip.lines[#mip.lines + 1] = " ";
				mip.lines[#mip.lines + 1] = m.name;
				mip.lines[#mip.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. LEVEL .. " " .. m.level .. " (" .. m.iLevel .. ")" .. FONT_COLOR_CODE_CLOSE;
				mip.lines[#mip.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. ( m.successChance and string.format( GARRISON_MISSION_PERCENT_CHANCE, m.successChance ) or UNKNOWN ) .. FONT_COLOR_CODE_CLOSE;
				--
				mip.lines[#mip.lines + 1] = REWARDS;
				for i = 1, #m.rewardsList do
					mip.lines[#mip.lines + 1] = m.rewardsList[i];
				end
				--
				mip.lines[#mip.lines + 1] = L["Followers"];
				for i = 1, #m.followers do
					mip.lines[#mip.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. ( m.followers[i] or UNKNOWN ) .. FONT_COLOR_CODE_CLOSE;
				end
				--
				local timeLeftSeconds = ( m.timeLeftSeconds and m.timeLeftSeconds >= passedTime ) and ( m.timeLeftSeconds - passedTime ) or 0;
				if timeLeftSeconds == 0 then
					mip.lines[#mip.lines + 1] = GREEN_FONT_COLOR_CODE .. COMPLETE .. FONT_COLOR_CODE_CLOSE;
					mip.incomplete = mip.incomplete - 1;
					missionsComplete = missionsComplete + 1; -- All characters
				else
					mip.lines[#mip.lines + 1] = RED_FONT_COLOR_CODE .. SecondsToTime( timeLeftSeconds ) .. FONT_COLOR_CODE_CLOSE;
					nextMissionTimeRemaining = nextMissionTimeRemaining == 0 and timeLeftSeconds or math.min( nextMissionTimeRemaining, timeLeftSeconds ); -- All characters
					allMissionsTimeRemaining = allMissionsTimeRemaining == 0 and timeLeftSeconds or math.max( allMissionsTimeRemaining, timeLeftSeconds ); -- All characters
				end
			end
			if #mip.lines == 0 then
				mip.lines[#mip.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. GARRISON_EMPTY_IN_PROGRESS_LIST .. FONT_COLOR_CODE_CLOSE;
			elseif mip.incomplete == 0 then
				if NS.db["alertMissions"] then
					alertCurrentCharacter = ( not alertCurrentCharacter and char["name"] == NS.currentCharacter.name ) and true or alertCurrentCharacter; -- All characters
					alertAnyCharacter = true; -- All characters
				end
			end
		end
		--
		-- Advancement
		--
		advancement[char["name"]] = {};
		if char["monitor"]["advancement"] then
			local oa = advancement[char["name"]];
			if char["advancement"]["talentBeingResearched"] then
				advancementsTotal = advancementsTotal + 1; -- All characters
				local talent = char["advancement"]["talentBeingResearched"];
				oa.texture = talent.icon;
				oa.text = HIGHLIGHT_FONT_COLOR_CODE .. talent.name .. FONT_COLOR_CODE_CLOSE;
				oa.seconds = talent.researchTimeRemaining > passedTime and ( talent.researchTimeRemaining - passedTime ) or 0;
				oa.lines = {};
				oa.lines[#oa.lines + 1] = { talent.description, nil, nil, nil, true };
				oa.lines[#oa.lines + 1] = " ";
				if oa.seconds > 0 then
					oa.lines[#oa.lines + 1] = string.format( L["Time Remaining: %s"], HIGHLIGHT_FONT_COLOR_CODE .. SecondsToTime( oa.seconds ) ) .. FONT_COLOR_CODE_CLOSE;
					nextAdvancementTimeRemaining = nextAdvancementTimeRemaining == 0 and oa.seconds or math.min( nextAdvancementTimeRemaining, oa.seconds ); -- All characters
					allAdvancementsTimeRemaining = allAdvancementsTimeRemaining == 0 and oa.seconds or math.max( allAdvancementsTimeRemaining, oa.seconds ); -- All characters
				else
					advancementsComplete = advancementsComplete + 1; -- All characters
					oa.lines[#oa.lines + 1] = GREEN_FONT_COLOR_CODE .. COMPLETE .. FONT_COLOR_CODE_CLOSE;
					if NS.db["alertClassHallUpgrades"] then
						alertCurrentCharacter = ( not alertCurrentCharacter and char["name"] == NS.currentCharacter.name ) and true or alertCurrentCharacter; -- All characters
						alertAnyCharacter = true; -- All characters
					end
				end
				--oa.lines[#oa.lines + 1] = " ";
				--oa.lines[#oa.lines + 1] = string.format( L["Research Time: %s"], HIGHLIGHT_FONT_COLOR_CODE .. SecondsToTime( talent.researchDuration ) ) .. FONT_COLOR_CODE_CLOSE;
				--oa.lines[#oa.lines + 1] = string.format( L["Cost: %s"], HIGHLIGHT_FONT_COLOR_CODE .. BreakUpLargeNumbers( talent.researchCost ) .. FONT_COLOR_CODE_CLOSE .. "|T".. 1397630 ..":0:0:2:0|t" );
				--oa.lines[#oa.lines + 1] = string.format( L["Tier: %s"], HIGHLIGHT_FONT_COLOR_CODE .. talent.tier .. FONT_COLOR_CODE_CLOSE );
				oa.status = "researching";
			elseif char["advancement"]["newTalentTier"] then
				oa.texture = char["advancement"]["newTalentTier"][1].icon;
				oa.text = string.format( L["Class Hall Upgrades - Tier %d"], char["advancement"]["newTalentTier"][1].tier );
				oa.lines = {};
				for i = 1, #char["advancement"]["newTalentTier"] do
					local talent = char["advancement"]["newTalentTier"][i];
					oa.lines[#oa.lines + 1] = " ";
					oa.lines[#oa.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. talent.name .. FONT_COLOR_CODE_CLOSE;
					oa.lines[#oa.lines + 1] = { talent.description, nil, nil, nil, true };
					oa.lines[#oa.lines + 1] = " ";
					oa.lines[#oa.lines + 1] = string.format( L["Research Time: %s"], HIGHLIGHT_FONT_COLOR_CODE .. SecondsToTime( talent.researchDuration ) ) .. FONT_COLOR_CODE_CLOSE;
					oa.lines[#oa.lines + 1] = string.format( L["Cost: %s"], HIGHLIGHT_FONT_COLOR_CODE .. BreakUpLargeNumbers( talent.researchCost ) .. FONT_COLOR_CODE_CLOSE .. "|T".. 1397630 ..":0:0:2:0|t" );
				end
				oa.status = "available";
			elseif char["advancement"]["numTalents"] == 8 then
				oa.texture = 133743;
				oa.text = L["Class Hall Upgrades - 8/8"];
				oa.lines = HIGHLIGHT_FONT_COLOR_CODE .. L["There are no new tiers available,\nbegin research to switch talents."] .. FONT_COLOR_CODE_CLOSE;
				oa.status = "maxed";
			end
		end
		--
		-- Work Orders
		--
		orders[char["name"]] = {};
		local troopNum = 0; -- Used to increment troop monitor order
		for _,o in ipairs( char["orders"] ) do -- o is for order, that's good enough for me
			if char["monitor"][o["texture"]] then -- Orders use texture as the monitorIndex
				orders[char["name"]][#orders[char["name"]] + 1] = {};
				local wo = orders[char["name"]][#orders[char["name"]]];
				wo.texture = o.texture;
				wo.text = o.name;
				wo.troopCount = o.troopCount;
				wo.capacity = o.capacity;
				wo.total = o.total or 0; -- o.total is nil if no orders
				wo.readyToStart = NS.OrdersReadyToStart( o.capacity, o.total, o.troopCount );
				wo.readyForPickup = NS.OrdersReadyToPickup( o.ready, o.total, o.duration, o.nextSeconds, char["updateTime"], currentTime );
				wo.allSeconds = NS.OrdersAllSeconds( o.duration, o.total, o.ready, o.nextSeconds, char["updateTime"], currentTime );
				wo.nextSeconds = NS.OrdersNextSeconds( wo.allSeconds, o.duration );
				--
				workOrdersReady = workOrdersReady + wo.readyForPickup; -- All characters
				workOrdersTotal = workOrdersTotal + wo.total; -- All characters
				if wo.nextSeconds > 0 then
					nextWorkOrderTimeRemaining = nextWorkOrderTimeRemaining == 0 and wo.nextSeconds or math.min( nextWorkOrderTimeRemaining, wo.nextSeconds );
					allWorkOrdersTimeRemaining = allWorkOrdersTimeRemaining == 0 and wo.allSeconds or math.max( allWorkOrdersTimeRemaining, wo.allSeconds );
				end
				--
				wo.lines = {};
				if wo.troopCount then
					wo.text = wo.text .. " - " .. wo.troopCount .. "/" .. wo.capacity;
				end
				if wo.readyToStart > 0 then
					if wo.texture == 1604167 then -- Seal of Broken Fate
						wo.lines[#wo.lines + 1] = seals[char["name"]].sealOfBrokenFate.lines;
					else
						wo.lines[#wo.lines + 1] = GREEN_FONT_COLOR_CODE .. string.format( L["%d Ready to start"], wo.readyToStart ) .. FONT_COLOR_CODE_CLOSE;
					end
				end
				if o.total and wo.total > 0 then
					if wo.readyForPickup == wo.total then
						wo.lines[#wo.lines + 1] = GREEN_FONT_COLOR_CODE .. string.format( L["%d Ready for pickup"], wo.readyForPickup ) .. FONT_COLOR_CODE_CLOSE;
						if ( wo.troopCount and NS.db["alertTroops"] ) or
						   ( wo.texture == 237446 and NS.db["alertArtifactResearchNotes"] ) or
						   ( wo.texture == 975736 and NS.db["alertChampionArmaments"] ) or
						   ( wo.texture == 134939 and NS.db["alertLegionCookingRecipes"] ) or
						   ( ( wo.texture == 140157 or wo.texture == 139888 or wo.texture == 140155 or wo.texture == 140038 or wo.texture == 139892 or wo.texture == 140158 ) and NS.db["alertInstantCompleteWorldQuest"] ) or
						   ( wo.texture == 1604167 and NS.db["alertBonusRollToken"] ) then
							alertCurrentCharacter = ( not alertCurrentCharacter and char["name"] == NS.currentCharacter.name ) and true or alertCurrentCharacter; -- All characters
							alertAnyCharacter = true; -- All characters
						end
					else
						wo.lines[#wo.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. string.format( L["%d/%d Ready for pickup %s"], wo.readyForPickup, o.total, string.format( L["(Next: %s)"], SecondsToTime( wo.nextSeconds ) ) ) .. FONT_COLOR_CODE_CLOSE;
						-- Alert: Any Artifact Research Notes
						if wo.texture == 237446 and wo.readyForPickup > 0 and NS.db["alertArtifactResearchNotes"] and NS.db["alertAnyArtifactResearchNotes"] then
							alertCurrentCharacter = ( not alertCurrentCharacter and char["name"] == NS.currentCharacter.name ) and true or alertCurrentCharacter; -- All characters
							alertAnyCharacter = true; -- All characters
						end
					end
				end
				if wo.troopCount and #wo.lines == 0 then
					if wo.troopCount == wo.capacity then
						wo.lines[#wo.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. L["0 recruits remaining"] .. FONT_COLOR_CODE_CLOSE;
					else
						wo.lines[#wo.lines + 1] = HIGHLIGHT_FONT_COLOR_CODE .. L["Unable to detect troop counts"] .. FONT_COLOR_CODE_CLOSE;
					end
				end
				-- Monitor Column
				if wo.troopCount then
					troopNum = troopNum + 1;
					wo.monitorColumn = "troop" .. troopNum;
				elseif wo.texture == 237446 then
					wo.monitorColumn = "artifact-research-notes";
				elseif wo.texture == 975736 then
					wo.monitorColumn = "champion-armaments";
				elseif wo.texture == 134939 then
					wo.monitorColumn = "cooking-recipes";
				elseif ( wo.texture == 140157 or wo.texture == 139888 or wo.texture == 140155 or wo.texture == 140038 or wo.texture == 139892 or wo.texture == 140158 ) then
					wo.monitorColumn = "world-quest-complete/bonus-roll";
				elseif wo.texture == 1604167 then
					wo.monitorColumn = "world-quest-complete/bonus-roll";
				end
			end
		end
	end
	-- Save to namespace for use on Monitor tab
	wipe( NS.allCharacters );
	--
	NS.allCharacters.seals = CopyTable( seals );
	NS.allCharacters.missions = CopyTable( missions );
	NS.allCharacters.advancement = CopyTable( advancement );
	NS.allCharacters.orders = CopyTable( orders );
	--
	NS.allCharacters.missionsComplete = missionsComplete;
	NS.allCharacters.missionsTotal = missionsTotal;
	NS.allCharacters.nextMissionTimeRemaining = nextMissionTimeRemaining;
	NS.allCharacters.allMissionsTimeRemaining = allMissionsTimeRemaining;
	--
	NS.allCharacters.advancementsComplete = advancementsComplete;
	NS.allCharacters.advancementsTotal = advancementsTotal;
	NS.allCharacters.nextAdvancementTimeRemaining = nextAdvancementTimeRemaining;
	NS.allCharacters.allAdvancementsTimeRemaining = allAdvancementsTimeRemaining;
	--
	NS.allCharacters.workOrdersReady = workOrdersReady;
	NS.allCharacters.workOrdersTotal = workOrdersTotal;
	NS.allCharacters.nextWorkOrderTimeRemaining = nextWorkOrderTimeRemaining;
	NS.allCharacters.allWorkOrdersTimeRemaining = allWorkOrdersTimeRemaining;
	--
	NS.allCharacters.alertCurrentCharacter = alertCurrentCharacter;
	NS.allCharacters.alertAnyCharacter = alertAnyCharacter;
end
--
NS.UpdateAll = function( forceUpdate )
	-- Stop and delay attempted regular update if a forceUpdate has run recently
	if not forceUpdate then
		local lastSecondsUpdateAll = time() - NS.lastTimeUpdateAll;
		if lastSecondsUpdateAll < 10 then
			C_Timer.After( ( 10 - lastSecondsUpdateAll ), NS.UpdateAll );
			return; -- Stop function
		end
	end
	-- Updates
	NS.UpdateCharacter();
	NS.UpdateCharacters();
	NS.lastTimeUpdateAll = time();
	-- Schedule next regular update, repeats every 10 seconds
	if not forceUpdate or not NS.initialized then -- Initial call is forced, regular updates are not
		C_Timer.After( 10, NS.UpdateAll );
	end
	-- Initialize
	if not NS.initialized then
		NS.currentCharacter.key = NS.FindKeyByField( NS.db["characters"], "name", NS.currentCharacter.name ); -- Set key here after UpdateCharacter() because new characters will cause a characters sort
		NS.selectedCharacterKey = NS.currentCharacter.key; -- Sets selected character in Characters tab
		--
		COHCEventsFrame:RegisterEvent( "CHAT_MSG_CURRENCY" ); -- Fires when looting currency other than money
		COHCEventsFrame:RegisterEvent( "BONUS_ROLL_RESULT" ); -- Fires when bonus roll is used
		--
		NS.initialized = true;
	end
	-- Alert
	NS.ToggleAlert(); -- Always attempt to turn on/off alerts after updating
	-- Refresh
	if NS.refresh then
		NS.UI.SubFrames[1]:Refresh();
		NS.refresh = false;
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Minimap Button
--------------------------------------------------------------------------------------------------------------------------------------------
NS.MinimapButton( "COHCMinimapButton", "Interface\\TargetingFrame\\UI-Classes-Circles", {
	dbpc = "minimapButtonPosition",
	texCoord = CLASS_ICON_TCOORDS[strupper( NS.currentCharacter.class )],
	tooltip = function()
		GameTooltip:SetText( HIGHLIGHT_FONT_COLOR_CODE .. NS.title .. FONT_COLOR_CODE_CLOSE );
		GameTooltip:AddLine( L["Left-Click to open and close"] );
		GameTooltip:AddLine( L["Drag to move this button"] );
		GameTooltip:Show();
	end,
	OnLeftClick = function( self )
		NS.SlashCmdHandler();
	end,
} );
--------------------------------------------------------------------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------------------------------------------------------------------
NS.SlashCmdHandler = function( cmd )
	if not NS.initialized then return end
	--
	if NS.UI.MainFrame:IsShown() then
		NS.UI.MainFrame:Hide();
	elseif not cmd or cmd == "" or cmd == "monitor" then
		NS.UI.MainFrame:ShowTab( 1 );
	elseif cmd == "characters" then
		NS.UI.MainFrame:ShowTab( 2 );
	elseif cmd == "options" then
		NS.UI.MainFrame:ShowTab( 3 );
	elseif cmd == "help" then
		NS.UI.MainFrame:ShowTab( 4 );
	else
		NS.UI.MainFrame:ShowTab( 4 );
		NS.Print( L["Unknown command, opening Help"] );
	end
end
--
SLASH_CLASSORDERHALLSCOMPLETE1 = "/classorderhallscomplete";
SLASH_CLASSORDERHALLSCOMPLETE2 = "/cohc";
SlashCmdList["CLASSORDERHALLSCOMPLETE"] = function( msg ) NS.SlashCmdHandler( msg ) end;
--------------------------------------------------------------------------------------------------------------------------------------------
-- Event/Hook Handlers
--------------------------------------------------------------------------------------------------------------------------------------------
NS.OnAddonLoaded = function( event ) -- ADDON_LOADED
	if IsAddOnLoaded( NS.addon ) and not NS.db then
		COHCEventsFrame:UnregisterEvent( event );
		-- SavedVariables
		if not CLASSORDERHALLSCOMPLETE_SAVEDVARIABLES then
			CLASSORDERHALLSCOMPLETE_SAVEDVARIABLES = NS.DefaultSavedVariables();
		end
		-- SavedVariablesPerCharacter
		if not CLASSORDERHALLSCOMPLETE_SAVEDVARIABLESPERCHARACTER then
			CLASSORDERHALLSCOMPLETE_SAVEDVARIABLESPERCHARACTER = NS.DefaultSavedVariablesPerCharacter();
		end
		-- Localize SavedVariables
		NS.db = CLASSORDERHALLSCOMPLETE_SAVEDVARIABLES;
		NS.dbpc = CLASSORDERHALLSCOMPLETE_SAVEDVARIABLESPERCHARACTER;
		-- Upgrade db
		if NS.db["version"] < NS.version then
			NS.Upgrade();
		end
		-- Upgrade dbpc
		if NS.dbpc["version"] < NS.version then
			NS.UpgradePerCharacter();
		end
	end
end
--
NS.OnPlayerLogin = function( event ) -- PLAYER_LOGIN
	COHCEventsFrame:UnregisterEvent( event );
	SetMapToCurrentZone(); -- Force map to current zone because standing by Nomi in Dalaran (Legion) was returning mapID 1115 on login/reload, which is Karazhan
	NS.UpdateRequestHandler( event ); -- Initial update request
	NS.UpdateRequestHandler(); -- Start handler/ticker
	-- COHC Minimap Button
	COHCMinimapButton.docked = NS.dbpc["dockMinimapButton"];
	COHCMinimapButton:UpdateSize( NS.dbpc["largeMinimapButton"] );
	COHCMinimapButton:UpdatePos(); -- Reset to last drag position
	if not NS.dbpc["showMinimapButton"] then
		COHCMinimapButton:Hide(); -- Hide if unchecked in options
	end
	-- Class Hall Report Minimap Button
	GarrisonLandingPageMinimapButton:HookScript( "OnShow", function()
		if not NS.dbpc["showClassHallReportMinimapButton"] and C_Garrison.HasGarrison( LE_GARRISON_TYPE_7_0 ) then
			GarrisonLandingPageMinimapButton:Hide();
		end
	end );
end
--
NS.UpdateRequestHandler = function( event )
	local currentTime = time();
	-- Ticker
	if not event then
		local hasOrderHall = C_Garrison.HasGarrison( LE_GARRISON_TYPE_7_0 );
		local inOrderHall = C_Garrison.IsPlayerInGarrison( LE_GARRISON_TYPE_7_0 );
		local inDalaranLegion = ( GetCurrentMapAreaID() == 1014 );
		local inEventZoneOrPeriod = ( inOrderHall or inDalaranLegion or not NS.shipmentConfirmsFlaggedComplete );
		-- When INSIDE event zone or period, update requests are made automatically every 2 seconds
		-- When OUTSIDE event zone or period, update requests are only made 2 seconds after an event fires
		local updateRequestTimePast = NS.lastTimeUpdateRequest and ( currentTime - NS.lastTimeUpdateRequest ) or 0;
		local updateRequestSentTimePast = inEventZoneOrPeriod and NS.lastTimeUpdateRequestSent and ( currentTime - NS.lastTimeUpdateRequestSent ) or 0; -- Set to zero to ignore time past if OUTSIDE event zone or period
		--
		if math.max( updateRequestTimePast, updateRequestSentTimePast ) >= 2 then
			-- Send update request
			NS.lastTimeUpdateRequest = nil;
			NS.lastTimeUpdateRequestSent = currentTime;
			if hasOrderHall then
				-- Work Orders {REQUEST}
				COHCEventsFrame:RegisterEvent( "GARRISON_LANDINGPAGE_SHIPMENTS" );
				C_Garrison.RequestLandingPageShipmentInfo();
			else
				-- Bypass event, call update directly if player has no Class Order Hall
				NS.UpdateAll( "forceUpdate" );
			end
		end
		--
		C_Timer.After( 0.5, NS.UpdateRequestHandler ); -- Emulate ticker, handling update requests every half-second
	-- Events
	else
		NS.lastTimeUpdateRequest = currentTime;
	end
end
--
NS.OnChatMsgCurrency = function( event )
	NS.db["characters"][NS.currentCharacter.key]["orderResources"] = select( 2, GetCurrencyInfo( 1220 ) );
end
--
NS.OnBonusRollResult = function( event )
	NS.db["characters"][NS.currentCharacter.key]["sealOfBrokenFate"] = select( 2, GetCurrencyInfo( 1273 ) );
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- COHCEventsFrame
--------------------------------------------------------------------------------------------------------------------------------------------
NS.Frame( "COHCEventsFrame", UIParent, {
	topLevel = true,
	OnEvent = function ( self, event, ... )
		if		event == "GARRISON_LANDINGPAGE_SHIPMENTS"		then
			--------------------------------------------------------------------------------------------------------------------------------
			-- Work Orders {UPDATED}
			--------------------------------------------------------------------------------------------------------------------------------
			self:UnregisterEvent( event );
			NS.UpdateAll( "forceUpdate" );
			--------------------------------------------------------------------------------------------------------------------------------
		elseif	event == "GARRISON_FOLLOWER_CATEGORIES_UPDATED"	then
			--------------------------------------------------------------------------------------------------------------------------------
			-- Troops {UPDATED}
			--------------------------------------------------------------------------------------------------------------------------------
			local troops = C_Garrison.GetClassSpecCategoryInfo( LE_FOLLOWER_TYPE_GARRISON_7_0 );
			if troops and #troops > 0 then
				NS.currentCharacter.troops = troops;
				if NS.initialized then
					-- RequestLandingPageShipmentInfo() followed by NS.UpdateAll
					-- Only required and effective OUTSIDE event zone or period
					NS.UpdateRequestHandler( event );
				end
			end
			--------------------------------------------------------------------------------------------------------------------------------
		elseif	event == "CHAT_MSG_CURRENCY"					then	NS.OnChatMsgCurrency( event );
		elseif	event == "BONUS_ROLL_RESULT"					then	NS.OnBonusRollResult( event );
		elseif	event == "ADDON_LOADED"							then	NS.OnAddonLoaded( event );
		elseif	event == "PLAYER_LOGIN"							then	NS.OnPlayerLogin( event );
		else
			--------------------------------------------------------------------------------------------------------------------------------
			-- Troops {REQUEST}
			--------------------------------------------------------------------------------------------------------------------------------
			if C_Garrison.HasGarrison( LE_GARRISON_TYPE_7_0 ) then
				C_Garrison.RequestClassSpecCategoryInfo( LE_FOLLOWER_TYPE_GARRISON_7_0 );
			end
			--------------------------------------------------------------------------------------------------------------------------------
		end
	end,
	OnLoad = function( self )
		self:RegisterEvent( "ADDON_LOADED" );
		self:RegisterEvent( "PLAYER_LOGIN" );
		-- Troops
		self:RegisterEvent( "GARRISON_FOLLOWER_CATEGORIES_UPDATED" );
		self:RegisterEvent( "GARRISON_FOLLOWER_ADDED" );
		self:RegisterEvent( "GARRISON_FOLLOWER_REMOVED" );
		self:RegisterEvent( "GARRISON_TALENT_COMPLETE" );
		self:RegisterEvent( "GARRISON_TALENT_UPDATE" );
		self:RegisterEvent( "GARRISON_SHOW_LANDING_PAGE" );
	end,
} );
