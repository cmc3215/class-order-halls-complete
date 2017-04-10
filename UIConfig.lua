--------------------------------------------------------------------------------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------------------------------------------------------------------------------
local NS = select( 2, ... );
local L = NS.localization;
--------------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------------------------------------------------------------------
NS.UI.cfg = {
	--
	mainFrame = {
		width		= 733,
		height		= 548,
		portrait	= true,
		frameStrata	= "MEDIUM",
		frameLevel	= "TOP",
		Init		= function( MainFrame )
			MainFrame:SetHeight( NS.UI.cfg.mainFrame.height + ( ( NS.db["monitorRows"] - 8 ) * 50 ) );
			MainFrame.portrait:SetTexture( "Interface\\TargetingFrame\\UI-Classes-Circles" );
			MainFrame.portrait:SetTexCoord( unpack( CLASS_ICON_TCOORDS[strupper( NS.currentCharacter.class )] ) );
		end,
		OnShow		= function( MainFrame )
			MainFrame:Reposition();
			PlaySound( "UI_Garrison_GarrisonReport_Open" );
		end,
		OnHide		= function( MainFrame )
			StaticPopup_Hide( "COHC_CHARACTER_DELETE" );
			StaticPopup_Hide( "COHC_CHARACTER_ORDER" );
			StaticPopup_Hide( "COHC_MONITOR_COLUMN" );
			PlaySound( "UI_Garrison_GarrisonReport_Close" );
			local point, relativeTo, relativePoint, xOffset, yOffset = MainFrame:GetPoint( 1 );
			NS.db["dragPosition"] = ( point and point == relativePoint and xOffset and yOffset ) and { point, xOffset, yOffset } or nil;
		end,
		Reposition = function( MainFrame )
			MainFrame:ClearAllPoints();
			local pos = ( NS.db["forgetDragPosition"] or not NS.db["dragPosition"] ) and { "TOPLEFT", 45, -120 } or NS.db["dragPosition"];
			MainFrame:SetPoint( unpack( pos ) );
		end,
	},
	--
	subFrameTabs = {
		{
			-- Monitor
			mainFrameTitle	= NS.title,
			tabText			= L["Monitor"],
			Init			= function( SubFrame )
				NS.Button( "NameColumnHeaderButton", SubFrame, NAME, {
					template = "COHCColumnHeaderButtonTemplate",
					size = { ( 152 + 8 ), 19 },
					setPoint = { "TOPLEFT", "$parent", "TOPLEFT", -2, 0 },
				} );
				NS.Button( "ButtonsColumnHeaderButton", SubFrame, "" .. L["Missions, Class Hall Upgrades, Work Orders"], {
					template = "COHCColumnHeaderButtonTemplate",
					size = { 530, 19 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
				} );
				NS.Button( "RefreshButton", SubFrame, L["Refresh"], {
					size = { 96, 20 },
					setPoint = { "BOTTOMRIGHT", "#sibling", "TOPRIGHT", 2, 7 },
					fontObject = "GameFontNormalSmall",
					OnClick = function()
						SubFrame:Refresh();
						NS.Print( "Refreshed" );
					end,
				} );
				NS.TextFrame( "MessageShipmentConfirms", SubFrame, L["Confirming character data, one moment..."], {
					size = { 236, 16 },
					setPoint = { "RIGHT", "#sibling", "LEFT", -8, 0 },
					fontObject = "GameFontRedSmall",
					justifyH = "CENTER",
				} );
				NS.ScrollFrame( "ScrollFrame", SubFrame, {
					size = { 686, ( 50 * NS.db["monitorRows"] - 5 ) },
					setPoint = { "TOPLEFT", "$parentNameColumnHeaderButton", "BOTTOMLEFT", 1, -3 },
					buttonTemplate = "COHCMonitorTabScrollFrameButtonTemplate",
					udpate = {
						numToDisplay = NS.db["monitorRows"],
						buttonHeight = 50,
						alwaysShowScrollBar = true,
						UpdateFunction = function( sf )
							local monitorMax = 10; -- Number of monitor buttons in XML template
							local currentTime = time(); -- Time used in status calculation
							--------------------------------------------------------------------------------------------------------------------------------------------
							-- Add characters monitoring at least one into items for ScrollFrame
							--------------------------------------------------------------------------------------------------------------------------------------------
							local items = {};
							for _,char in ipairs( NS.db["characters"] ) do
								local monitoring = 0; -- Init monitoring count
								for _,monitor in pairs( char["monitor"] ) do
									if monitor then
										monitoring = monitoring + 1;
									end
								end
								-- Monitoring?
								if monitoring > 0 then
									if NS.db["currentCharacterFirst"] and char["name"] == NS.currentCharacter.name then
										-- Force current character to beginning of items
										local t = { char };
										for i = 1, #items do
											t[#t + 1] = items[i];
										end
										items = t;
									else
										table.insert( items, char );
									end
								end
							end
							--------------------------------------------------------------------------------------------------------------------------------------------
							local numItems = #items;
							local sfn = SubFrame:GetName();
							FauxScrollFrame_Update( sf, numItems, sf.numToDisplay, sf.buttonHeight, nil, nil, nil, nil, nil, nil, sf.alwaysShowScrollBar );
							local offset = FauxScrollFrame_GetOffset( sf );
							for num = 1, sf.numToDisplay do
								local bn = sf.buttonName .. num; -- button name
								local b = _G[bn]; -- button
								local k = offset + num; -- key
								b:UnlockHighlight();
								--
								if k <= numItems then
									-- Functions
									local MonitorButton_OnEnter = function( self, text, lines )
										GameTooltip:SetOwner( self, "ANCHOR_RIGHT" );
										GameTooltip:SetText( text );
										if type( lines ) == "table" then
											for i = 1, #lines do
												if type( lines[i] ) == "table" then
													GameTooltip:AddLine( lines[i][1], lines[i][2], lines[i][3],  lines[i][4], lines[i][5] );
												else
													GameTooltip:AddLine( lines[i] );
												end
											end
										elseif lines then
											GameTooltip:AddLine( lines );
										end
										GameTooltip:Show();
										b:LockHighlight();
									end
									--
									local SealButton_OnEnter = function( self, text, lines )
										GameTooltip:SetOwner( self, "ANCHOR_RIGHT" );
										GameTooltip:SetText( text );
										GameTooltip:AddLine( lines );
										GameTooltip:Show();
										b:LockHighlight();
									end
									--
									local OnLeave = function( self )
										GameTooltip_Hide();
										b:UnlockHighlight();
									end
									--
									local OnClick = function()
										NS.selectedCharacterKey = NS.FindKeyByField( NS.db["characters"], "name", items[k]["name"] ); -- Set clicked character to selected
										NS.UI.MainFrame:ShowTab( 2 ); -- Characters Tab
									end
									--
									b:SetScript( "OnClick", OnClick );
									--------------------------------------------------------------------------------------------------------------------------------------------
									-- Character
									--------------------------------------------------------------------------------------------------------------------------------------------
									_G[bn .. "CharacterText"]:SetText( "|c" .. RAID_CLASS_COLORS[items[k]["class"]].colorStr .. ( NS.db["showCharacterRealms"] and items[k]["name"] or strsplit( "-", items[k]["name"], 2 ) ) .. FONT_COLOR_CODE_CLOSE );
									_G[bn .. "Character"]:SetScript( "OnClick", OnClick );
									_G[bn .. "Character"]:SetScript( "OnEnter", function() b:LockHighlight(); end );
									_G[bn .. "Character"]:SetScript( "OnLeave", OnLeave );
									--------------------------------------------------------------------------------------------------------------------------------------------
									-- Order Resources & Seal of Broken Fate
									--------------------------------------------------------------------------------------------------------------------------------------------
									_G[bn .. "CurrencyOrderResourcesText"]:SetText( items[k]["orderResources"] .. "|T" .. 1397630 .. ":16:16:3:0|t" );
									_G[bn .. "CurrencyOrderResources"]:SetScript( "OnClick", OnClick );
									_G[bn .. "CurrencyOrderResources"]:SetScript( "OnEnter", function() b:LockHighlight(); end );
									_G[bn .. "CurrencyOrderResources"]:SetScript( "OnLeave", OnLeave );
									--------------------------------------------------------------------------------------------------------------------------------------------
									local seals = NS.allCharacters.seals[items[k]["name"]];
									if seals.sealOfBrokenFate then
										_G[bn .. "CurrencySealOfBrokenFateText"]:SetText( items[k]["sealOfBrokenFate"] .. "|T" .. 1604167 .. ":16:16:3:0|t" );
										_G[bn .. "CurrencySealOfBrokenFate"]:SetScript( "OnClick", OnClick );
										_G[bn .. "CurrencySealOfBrokenFate"]:SetScript( "OnEnter", function( self ) SealButton_OnEnter( self, seals.sealOfBrokenFate.text, seals.sealOfBrokenFate.lines ); end );
										_G[bn .. "CurrencySealOfBrokenFate"]:SetScript( "OnLeave", OnLeave );
										_G[bn .. "CurrencySealOfBrokenFate"]:Show();
									else
										_G[bn .. "CurrencySealOfBrokenFate"]:Hide();
									end
									--------------------------------------------------------------------------------------------------------------------------------------------
									local monitorNum = 0;
									local passedTime = currentTime - items[k]["updateTime"]; -- Time passed since character's last update
									for monitorNum = ( monitorNum + 1 ), monitorMax do
										_G[bn .. "Monitor" .. monitorNum]:Hide(); -- Hide monitor buttons up to max
									end
									--------------------------------------------------------------------------------------------------------------------------------------------
									-- Missions
									--------------------------------------------------------------------------------------------------------------------------------------------
									local missions = NS.allCharacters.missions[items[k]["name"]];
									if next( missions ) then
										monitorNum = NS.FindKeyByValue( NS.db["monitorColumn"], "missions" );
										_G[bn .. "Monitor" .. monitorNum]:SetNormalTexture( missions.texture );
										_G[bn .. "Monitor" .. monitorNum]:SetScript( "OnEnter", function( self ) MonitorButton_OnEnter( self, missions.text, missions.lines ); end );
										_G[bn .. "Monitor" .. monitorNum]:SetScript( "OnLeave", OnLeave );
										_G[bn .. "Monitor" .. monitorNum .. "TopRightText"]:SetText( "" );
										local color = ( missions.total == 0 and "Gray" ) or ( missions.incomplete == missions.total and "Red" ) or ( missions.incomplete > 0 and "Yellow" ) or "Green";
										_G[bn .. "Monitor" .. monitorNum .. "CenterText"]:SetText( ( color == "Gray" and "" ) or ( ( missions.total - missions.incomplete ) .. "/" .. missions.total ) );
										_G[bn .. "Monitor" .. monitorNum .. "Indicator"]:SetTexture( "Interface\\COMMON\\Indicator-" .. color );
										if color == "Green" then
											_G[bn .. "Monitor" .. monitorNum]:GetNormalTexture():SetVertexColor( 0.1, 1.0, 0.1 );
										else
											_G[bn .. "Monitor" .. monitorNum]:GetNormalTexture():SetVertexColor( 1.0, 1.0, 1.0 );
										end
										_G[bn .. "Monitor" .. monitorNum]:Show();
									end
									--------------------------------------------------------------------------------------------------------------------------------------------
									-- Advancement
									--------------------------------------------------------------------------------------------------------------------------------------------
									local advancement = NS.allCharacters.advancement[items[k]["name"]];
									if next( advancement ) then
										monitorNum = NS.FindKeyByValue( NS.db["monitorColumn"], "advancement" );
										_G[bn .. "Monitor" .. monitorNum]:SetNormalTexture( advancement.texture );
										_G[bn .. "Monitor" .. monitorNum]:SetScript( "OnEnter", function( self ) MonitorButton_OnEnter( self, advancement.text, advancement.lines ); end );
										_G[bn .. "Monitor" .. monitorNum]:SetScript( "OnLeave", OnLeave );
										_G[bn .. "Monitor" .. monitorNum .. "TopRightText"]:SetText( "" );
										local color = ( ( advancement.status == "available" or advancement.status == "maxed" ) and "Gray" ) or ( advancement.seconds > 0 and "Red" ) or "Green";
										_G[bn .. "Monitor" .. monitorNum .. "CenterText"]:SetText( ( color == "Red" and SecondsToTime( advancement.seconds, false, false, 1 ) ) or "" );
										_G[bn .. "Monitor" .. monitorNum .. "Indicator"]:SetTexture( "Interface\\COMMON\\Indicator-" .. color );
										if color == "Green" then
											_G[bn .. "Monitor" .. monitorNum]:GetNormalTexture():SetVertexColor( 0.1, 1.0, 0.1 );
										else
											_G[bn .. "Monitor" .. monitorNum]:GetNormalTexture():SetVertexColor( 1.0, 1.0, 1.0 );
										end
										_G[bn .. "Monitor" .. monitorNum]:Show();
									end
									--------------------------------------------------------------------------------------------------------------------------------------------
									-- Work Orders
									--------------------------------------------------------------------------------------------------------------------------------------------
									local orders = NS.allCharacters.orders[items[k]["name"]];
									for i = 1, #orders do
										monitorNum = NS.FindKeyByValue( NS.db["monitorColumn"], orders[i].monitorColumn );
										if not monitorNum then
											NS.Print( "Unexpected work order, please report to addon author on Curse: " .. orders[i].text .. " - " .. orders[i].texture );
										else
											_G[bn .. "Monitor" .. monitorNum]:SetNormalTexture( orders[i].texture );
											_G[bn .. "Monitor" .. monitorNum]:SetScript( "OnEnter", function( self ) MonitorButton_OnEnter( self, orders[i].text, orders[i].lines ); end );
											_G[bn .. "Monitor" .. monitorNum]:SetScript( "OnLeave", OnLeave );
											_G[bn .. "Monitor" .. monitorNum .. "TopRightText"]:SetText( orders[i].troopCount and orders[i].troopCount or "" );
											local color = ( orders[i].total == 0 and "Gray" ) or ( orders[i].readyForPickup == 0 and "Red" ) or ( orders[i].readyForPickup < orders[i].total and "Yellow" ) or "Green";
											_G[bn .. "Monitor" .. monitorNum .. "CenterText"]:SetText( ( color == "Gray" and "" ) or ( orders[i].readyForPickup .. "/" .. orders[i].total ) );
											_G[bn .. "Monitor" .. monitorNum .. "Indicator"]:SetTexture( "Interface\\COMMON\\Indicator-" .. color );
											if color == "Green" then
												_G[bn .. "Monitor" .. monitorNum]:GetNormalTexture():SetVertexColor( 0.1, 1.0, 0.1 );
											else
												_G[bn .. "Monitor" .. monitorNum]:GetNormalTexture():SetVertexColor( 1.0, 1.0, 1.0 );
											end
											_G[bn .. "Monitor" .. monitorNum]:Show();
										end
									end
									--------------------------------------------------------------------------------------------------------------------------------------------
									b:Show();
								else
									b:Hide();
								end
							end
							-- Message When Empty
							if numItems == 0 then
								_G[SubFrame:GetName() .. "MessageWhenEmptyText"]:Show();
							else
								_G[SubFrame:GetName() .. "MessageWhenEmptyText"]:Hide();
							end
						end
					},
				} );
				NS.TextFrame( "MessageWhenEmpty", SubFrame, L["There are no Class Order Halls being monitored.\n\nSelect the Characters tab to choose what you monitor."], {
					setPoint = {
						{ "TOPLEFT", "$parentScrollFrame", "TOPLEFT", 0, 0 },
						{ "BOTTOMRIGHT", "$parentScrollFrame", "BOTTOMRIGHT", 0, 100 },
					},
					fontObject = "GameFontNormalLarge",
					justifyH = "CENTER",
					justifyV = "CENTER",
				} );
				local FooterFrame = NS.Frame( "Footer", SubFrame, {
					size = { 714, 60 },
					setPoint = { "BOTTOM", "$parent", "BOTTOM", 0, 0 },
					bg = { "Interface\\Garrison\\GarrisonMissionUIInfoBoxBackgroundTile", true, true },
					bgSetAllPoints = true,
				} );
				--
				local MissionsReportFrame = NS.Frame( "MissionsReport", FooterFrame, {
					size = { 227, 44 },
					setPoint = { "TOPLEFT", "$parent", "TOPLEFT", 8, -8 },
				} );
				local AdvancementsReportFrame = NS.Frame( "AdvancementsReport", FooterFrame, {
					size = { 227, 44 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 8, 0 },
				} );
				local WorkOrdersReportFrame = NS.Frame( "WorkOrdersReport", FooterFrame, {
					size = { 227, 44 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 9, 0 },
				} );
				--
				local MissionsReportButton = NS.Button( "Button", MissionsReportFrame, nil, {
					template = false,
					size = { 44, 44 },
					setPoint = { "LEFT", "$parent", "LEFT", 0, 0 },
					normalTexture = 1044517,
				} );
				local AdvancementsReportButton = NS.Button( "Button", AdvancementsReportFrame, nil, {
					template = false,
					size = { 44, 44 },
					setPoint = { "LEFT", "$parent", "LEFT", 0, 0 },
					normalTexture = 133743,
				} );
				local WorkOrdersReportButton = NS.Button( "Button", WorkOrdersReportFrame, nil, {
					template = false,
					size = { 44, 44 },
					setPoint = { "LEFT", "$parent", "LEFT", 0, 0 },
					normalTexture = 133459,
				} );
				--
				NS.TextFrame( "Center", MissionsReportButton, "", {
					layer = "OVERLAY",
					setAllPoints = true,
					justifyH = "CENTER",
					fontObject = "NumberFontNormal",
				} );
				NS.TextFrame( "Center", AdvancementsReportButton, "", {
					layer = "OVERLAY",
					setAllPoints = true,
					justifyH = "CENTER",
					fontObject = "NumberFontNormal",
				} );
				NS.TextFrame( "Center", WorkOrdersReportButton, "", {
					layer = "OVERLAY",
					setAllPoints = true,
					justifyH = "CENTER",
					fontObject = "NumberFontNormal",
				} );
				--
				local MissionsReportIndicator = MissionsReportButton:CreateTexture( "$parentIndicator", "OVERLAY" );
				MissionsReportIndicator:SetSize( 20, 20 );
				MissionsReportIndicator:SetPoint( "BOTTOMRIGHT", 4.5, -4.5 );
				local AdvancementsReportIndicator = AdvancementsReportButton:CreateTexture( "$parentIndicator", "OVERLAY" );
				AdvancementsReportIndicator:SetSize( 20, 20 );
				AdvancementsReportIndicator:SetPoint( "BOTTOMRIGHT", 4.5, -4.5 );
				local WorkOrdersReportIndicator = WorkOrdersReportButton:CreateTexture( "$parentIndicator", "OVERLAY" );
				WorkOrdersReportIndicator:SetSize( 20, 20 );
				WorkOrdersReportIndicator:SetPoint( "BOTTOMRIGHT", 4.5, -4.5 );
				--
				NS.TextFrame( "Right", MissionsReportFrame, "", {
					size = { 179, 44 },
					setPoint = { "LEFT", "$parent", "LEFT", 48, 0 },
					justifyH = "LEFT",
				} );
				NS.TextFrame( "Right", AdvancementsReportFrame, "", {
					size = { 179, 44 },
					setPoint = { "LEFT", "$parent", "LEFT", 48, 0 },
					justifyH = "LEFT",
				} );
				NS.TextFrame( "Right", WorkOrdersReportFrame, "", {
					size = { 179, 44 },
					setPoint = { "LEFT", "$parent", "LEFT", 48, 0 },
					justifyH = "LEFT",
				} );
			end,
			Refresh			= function( SubFrame )
				local sfn = SubFrame:GetName();
				--
				_G[sfn .. "ScrollFrame"]:Reset();
				-- Missions
				local mbn = "FooterMissionsReportButton";
				local missionsCenterText,missionsRightText,missionsColor;
				if NS.allCharacters.missionsTotal == 0 then
					missionsCenterText = "";
					missionsColor = "Gray";
					missionsRightText = HIGHLIGHT_FONT_COLOR_CODE .. L["None in progress"] .. FONT_COLOR_CODE_CLOSE;
				elseif NS.allCharacters.missionsComplete == NS.allCharacters.missionsTotal then
					missionsCenterText = HIGHLIGHT_FONT_COLOR_CODE .. NS.allCharacters.missionsComplete .. "/" .. NS.allCharacters.missionsTotal .. FONT_COLOR_CODE_CLOSE;
					missionsColor = "Green";
					missionsRightText = GREEN_FONT_COLOR_CODE .. COMPLETE .. FONT_COLOR_CODE_CLOSE;
				else
					missionsCenterText = HIGHLIGHT_FONT_COLOR_CODE .. NS.allCharacters.missionsComplete .. "/" .. NS.allCharacters.missionsTotal .. FONT_COLOR_CODE_CLOSE;
					missionsColor = NS.allCharacters.missionsComplete > 0 and "Yellow" or "Red";
					missionsRightText = HIGHLIGHT_FONT_COLOR_CODE .. string.format( L["(Next: %s)"], SecondsToTime( NS.allCharacters.nextMissionTimeRemaining ) ) .. FONT_COLOR_CODE_CLOSE;
				end
				-- Advancement
				local abn = "FooterAdvancementsReportButton";
				local advancementsCenterText,advancementsRightText,advancementsColor;
				if NS.allCharacters.advancementsTotal == 0 then
					advancementsCenterText = "";
					advancementsColor = "Gray";
					advancementsRightText = HIGHLIGHT_FONT_COLOR_CODE .. L["None in progress"] .. FONT_COLOR_CODE_CLOSE;
				elseif NS.allCharacters.advancementsComplete == NS.allCharacters.advancementsTotal then
					advancementsCenterText = HIGHLIGHT_FONT_COLOR_CODE .. NS.allCharacters.advancementsComplete .. "/" .. NS.allCharacters.advancementsTotal .. FONT_COLOR_CODE_CLOSE;
					advancementsColor = "Green";
					advancementsRightText = GREEN_FONT_COLOR_CODE .. COMPLETE .. FONT_COLOR_CODE_CLOSE;
				else
					advancementsCenterText = HIGHLIGHT_FONT_COLOR_CODE .. NS.allCharacters.advancementsComplete .. "/" .. NS.allCharacters.advancementsTotal .. FONT_COLOR_CODE_CLOSE;
					advancementsColor = NS.allCharacters.advancementsComplete > 0 and "Yellow" or "Red";
					advancementsRightText = HIGHLIGHT_FONT_COLOR_CODE .. string.format( L["(Next: %s)"], SecondsToTime( NS.allCharacters.nextAdvancementTimeRemaining ) ) .. FONT_COLOR_CODE_CLOSE;
				end
				-- Work Orders
				local wbn = "FooterWorkOrdersReportButton";
				local workOrdersCenterText,workOrdersRightText,workOrdersColor;
				if NS.allCharacters.workOrdersTotal == 0 then
					workOrdersCenterText = "";
					workOrdersColor = "Gray";
					workOrdersRightText = HIGHLIGHT_FONT_COLOR_CODE .. L["None in progress"] .. FONT_COLOR_CODE_CLOSE;
				elseif NS.allCharacters.workOrdersReady == NS.allCharacters.workOrdersTotal then
					workOrdersCenterText = HIGHLIGHT_FONT_COLOR_CODE .. NS.allCharacters.workOrdersReady .. "/" .. NS.allCharacters.workOrdersTotal .. FONT_COLOR_CODE_CLOSE;
					workOrdersColor = "Green";
					workOrdersRightText = GREEN_FONT_COLOR_CODE .. L["Ready for pickup"] .. FONT_COLOR_CODE_CLOSE;
				else
					workOrdersCenterText = HIGHLIGHT_FONT_COLOR_CODE .. NS.allCharacters.workOrdersReady .. "/" .. NS.allCharacters.workOrdersTotal .. FONT_COLOR_CODE_CLOSE;
					workOrdersColor = NS.allCharacters.workOrdersReady > 0 and "Yellow" or "Red";
					workOrdersRightText = HIGHLIGHT_FONT_COLOR_CODE .. string.format( L["(Next: %s)"], SecondsToTime( NS.allCharacters.nextWorkOrderTimeRemaining ) ) .. FONT_COLOR_CODE_CLOSE;
				end
				--
				_G[sfn .. mbn .. "CenterText"]:SetText( missionsCenterText );
				_G[sfn .. abn .. "CenterText"]:SetText( advancementsCenterText );
				_G[sfn .. wbn .. "CenterText"]:SetText( workOrdersCenterText );
				--
				_G[sfn .. mbn .. "Indicator"]:SetTexture( "Interface\\COMMON\\Indicator-" .. missionsColor );
				_G[sfn .. abn .. "Indicator"]:SetTexture( "Interface\\COMMON\\Indicator-" .. advancementsColor );
				_G[sfn .. wbn .. "Indicator"]:SetTexture( "Interface\\COMMON\\Indicator-" .. workOrdersColor );
				--
				if missionsColor == "Green" then
					_G[sfn .. mbn]:GetNormalTexture():SetVertexColor( 0.1, 1.0, 0.1 );
				else
					_G[sfn .. mbn]:GetNormalTexture():SetVertexColor( 1.0, 1.0, 1.0 );
				end
				if advancementsColor == "Green" then
					_G[sfn .. abn]:GetNormalTexture():SetVertexColor( 0.1, 1.0, 0.1 );
				else
					_G[sfn .. abn]:GetNormalTexture():SetVertexColor( 1.0, 1.0, 1.0 );
				end
				if workOrdersColor == "Green" then
					_G[sfn .. wbn]:GetNormalTexture():SetVertexColor( 0.1, 1.0, 0.1 );
				else
					_G[sfn .. wbn]:GetNormalTexture():SetVertexColor( 1.0, 1.0, 1.0 );
				end
				--
				_G[sfn .. "FooterMissionsReportRightText"]:SetText( L["Missions"] .. "\n" .. missionsRightText );
				_G[sfn .. "FooterAdvancementsReportRightText"]:SetText( L["Class Hall Upgrades"] .. "\n" .. advancementsRightText );
				_G[sfn .. "FooterWorkOrdersReportRightText"]:SetText( L["Work Orders"] .. "\n" .. workOrdersRightText );
			end,
		},
		{
			-- Characters
			mainFrameTitle	= NS.title,
			tabText			= L["Characters"],
			Init			= function( SubFrame )
				NS.TextFrame( "Character", SubFrame, L["Character:"], {
					size = { 67, 16 },
					setPoint = { "TOPLEFT", "$parent", "TOPLEFT", 8, -8 },
				} );
				NS.DropDownMenu( "CharacterDropDownMenu", SubFrame, {
					setPoint = { "LEFT", "#sibling", "RIGHT", -12, -1 },
					buttons = function()
						local t = {};
						local maxOrderPosition = #NS.db["characters"];
						for ck,c in ipairs( NS.db["characters"] ) do
							local cn = NS.db["showCharacterRealms"] and c["name"] or strsplit( "-", c["name"], 2 );
							tinsert( t, { ( ( c["order"] < 10 and maxOrderPosition > 9 ) and ( "0" .. c["order"] ) or c["order"] ) .. ". " .. cn, ck } );
						end
						return t;
					end,
					OnClick = function( info )
						NS.selectedCharacterKey = info.value;
						SubFrame:Refresh();
					end,
					width = 190,
				} );
				NS.CheckButton( "OrderAutomaticallyCheckButton", SubFrame, L["Order Automatically"], {
					setPoint = { "LEFT", "#sibling", "RIGHT", 0, 0 },
					tooltip = L["Order characters automatically by realm > name.\nUncheck to order characters manually by number."],
					OnClick = function( checked )
						NS.SortCharacters( "automatic" );
						NS.ResetCharactersOrderPositions();
						NS.UpdateAll( "forceUpdate" );
						SubFrame:Refresh();
						-- Prevent Automatic/Manual conflict
						StaticPopup_Hide( "COHC_CHARACTER_ORDER" );
					end,
					db = "orderCharactersAutomatically",
				} );
				NS.TextFrame( "MonitoredNum", SubFrame, "", {
					size = { 386, 20 },
					setPoint = { "LEFT", "$parentCharacterDropDownMenu", "RIGHT", -6, 0 },
					fontObject = "GameFontHighlight",
					justifyH = "RIGHT",
				} );
				local function CharactersTabNumMonitored()
					local numMonitored,numTotal = 0,0;
					for i = 1, #NS.charactersTabItems do
						if NS.db["characters"][NS.selectedCharacterKey]["monitor"][NS.charactersTabItems[i].key] then
							numMonitored = numMonitored + 1;
						end
						numTotal = numTotal + 1;
					end
					return numMonitored,numTotal;
				end
				NS.ScrollFrame( "ScrollFrame", SubFrame, {
					size = { 686, ( 40 * 10 - 5 ) },
					setPoint = { "TOPLEFT", "$parent", "TOPLEFT", -1, -37 },
					buttonTemplate = "COHCCharactersTabScrollFrameButtonTemplate",
					udpate = {
						numToDisplay = 10,
						buttonHeight = 40,
						alwaysShowScrollBar = true,
						UpdateFunction = function( sf )
							local items = NS.charactersTabItems;
							local numItems = #items;
							FauxScrollFrame_Update( sf, numItems, sf.numToDisplay, sf.buttonHeight, nil, nil, nil, nil, nil, nil, sf.alwaysShowScrollBar );
							local offset = FauxScrollFrame_GetOffset( sf );
							local numMonitored = CharactersTabNumMonitored();
							for num = 1, sf.numToDisplay do
								local k = offset + num; -- key
								local bn = sf.buttonName .. num; -- button name
								local b = _G[bn]; -- button
								local c = _G[bn .. "_Check"]; -- check
								b:UnlockHighlight();
								if k <= numItems then
									b:SetScript( "OnClick", function() c:Click(); end );
									_G[bn .. "_IconTexture"]:SetNormalTexture( items[k].icon );
									_G[bn .. "_IconTexture"]:SetScript( "OnClick", function() c:Click(); end );
									_G[bn .. "_IconTexture"]:SetScript( "OnEnter", function() b:LockHighlight(); end );
									_G[bn .. "_IconTexture"]:SetScript( "OnLeave", function() b:UnlockHighlight(); end );
									_G[bn .. "_NameText"]:SetText( items[k].name );
									c:SetChecked( NS.db["characters"][NS.selectedCharacterKey]["monitor"][items[k].key] );
									c:SetScript( "OnClick", function()
										NS.db["characters"][NS.selectedCharacterKey]["monitor"][items[k].key] = c:GetChecked();
										_G[SubFrame:GetName() .. "ScrollFrame"]:Update();
										NS.UpdateAll( "forceUpdate" );
									end );
									--
									b:Show();
								else
									b:Hide();
								end
							end
							-- Monitored: %d+/%d+
							_G[SubFrame:GetName() .. "MonitoredNumText"]:SetText( NORMAL_FONT_COLOR_CODE .. L["Monitored"] .. ": " .. FONT_COLOR_CODE_CLOSE .. numMonitored .. "/" .. numItems );
							-- Message When Empty
							if numItems == 0 then
								_G[SubFrame:GetName() .. "MessageWhenEmptyText"]:Show();
							else
								_G[SubFrame:GetName() .. "MessageWhenEmptyText"]:Hide();
							end
						end
					},
				} );
				local function MonitorSetChecks( checked )
					for key in pairs( NS.db["characters"][NS.selectedCharacterKey]["monitor"] ) do
						NS.db["characters"][NS.selectedCharacterKey]["monitor"][key] = checked;
					end
					NS.UpdateAll( "forceUpdate" );
				end
				NS.TextFrame( "MessageWhenEmpty", SubFrame, L["This character has no Missions, Class Hall Upgrades, or Work Orders.\n\nAs you progress they will be monitored automatically.\n\nYou can then uncheck any you don't want to monitor."], {
					setPoint = {
						{ "TOPLEFT", "$parentScrollFrame", "TOPLEFT", 0, 0 },
						{ "BOTTOMRIGHT", "$parentScrollFrame", "BOTTOMRIGHT", 0, 100 },
					},
					fontObject = "GameFontNormalLarge",
					justifyH = "CENTER",
					justifyV = "CENTER",
				} );
				NS.Button( "OrderButton", SubFrame, L["Order"], {
					size = { 110, 22 },
					setPoint = { "BOTTOMLEFT", "$parent", "BOTTOMLEFT", 8, 8 },
					OnClick = function()
						local cname = NS.db["characters"][NS.selectedCharacterKey]["name"];
						cname = NS.db["showCharacterRealms"] and cname or strsplit( "-", cname, 2 );
						StaticPopup_Show( "COHC_CHARACTER_ORDER", NS.selectedCharacterKey .. ". " .. cname, nil, { ["ck"] = NS.selectedCharacterKey, ["name"] = cname } );
					end,
				} );
				NS.Button( "DeleteCharacterButton", SubFrame, L["Delete"], {
					size = { 110, 22 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 10, 0 },
					OnClick = function()
						local cname = NS.db["characters"][NS.selectedCharacterKey]["name"];
						cname = NS.db["showCharacterRealms"] and cname or strsplit( "-", cname, 2 );
						StaticPopup_Show( "COHC_CHARACTER_DELETE", cname, nil, { ["ck"] = NS.selectedCharacterKey, ["name"] = cname } );
					end,
				} );
				NS.Button( "UncheckAllButton", SubFrame, L["Uncheck All"], {
					size = { 110, 22 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 10, 0 },
					OnClick = function()
						MonitorSetChecks( false );
						_G[SubFrame:GetName() .. "ScrollFrame"]:Update();
					end,
				} );
				NS.Button( "CheckAllButton", SubFrame, L["Check All"], {
					size = { 110, 22 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 10, 0 },
					OnClick = function()
						MonitorSetChecks( true );
						_G[SubFrame:GetName() .. "ScrollFrame"]:Update();
					end,
				} );
				NS.CheckButton( "CurrentCharacterFirstCheckButton", SubFrame, L["Current Character First"], {
					template = "InterfaceOptionsSmallCheckButtonTemplate",
					setPoint = { "LEFT", "#sibling", "RIGHT", 45, -1 },
					tooltip = L["Show current character first on the\nMonitor tab, regardless of order."],
					db = "currentCharacterFirst",
				} );
				StaticPopupDialogs["COHC_CHARACTER_ORDER"] = {
					text = L["\n%s\n\n|cffffd200Order|r\n|cff82c5ffNumber|r"],
					button1 = L["Change"],
					button2 = CANCEL,
					hasEditBox = 1,
					maxLetters = 2,
					OnAccept = function ( self, data )
						local order = self.editBox:GetNumber();
						if order > 0 then
							local char = NS.db["characters"][data["ck"]];
							local maxOrderPosition = #NS.db["characters"];
							order = order > maxOrderPosition and maxOrderPosition or order;
							if char and char["order"] ~= order then
								NS.SortCharacters( "manual", { ["ck"] = data["ck"], ["order"] = order } );
								NS.UpdateAll( "forceUpdate" );
								SubFrame:Refresh();
								NS.Print( string.format( L["Order changed: %d. %s"], order, data["name"] ) );
							end
						else
							NS.Print( RED_FONT_COLOR_CODE .. L["Order must be greater than zero."] .. FONT_COLOR_CODE_CLOSE );
						end
					end,
					OnCancel = function ( self ) end,
					OnShow = function ( self )
						self.editBox:SetNumeric( true );
						self.editBox:SetFocus();
					end,
					OnHide = function ( self )
						self.editBox:SetText( "" );
					end,
					EditBoxOnEnterPressed = function ( self )
						local parent = self:GetParent();
						local OnAccept = StaticPopupDialogs[parent.which].OnAccept;
						OnAccept( parent, parent.data );
						parent:Hide();
					end,
					EditBoxOnEscapePressed = function( self )
						self:GetParent():Hide();
					end,
					hideOnEscape = 1,
					timeout = 0,
					exclusive = 1,
					whileDead = 1,
				};
				StaticPopupDialogs["COHC_CHARACTER_DELETE"] = {
					text = L["Delete character? %s"];
					button1 = YES,
					button2 = NO,
					OnAccept = function ( self, data )
						if data["ck"] == NS.currentCharacter.key then return end
						-- Delete
						table.remove( NS.db["characters"], data["ck"] );
						NS.Print( RED_FONT_COLOR_CODE .. string.format( L["%s deleted"], data["name"] ) .. FONT_COLOR_CODE_CLOSE );
						-- Reset keys (Exactly like initialize)
						NS.currentCharacter.key = NS.FindKeyByField( NS.db["characters"], "name", NS.currentCharacter.name ); -- Must be reset when a character is deleted because the keys shift up one
						NS.selectedCharacterKey = NS.currentCharacter.key; -- Sets selected character to current character
						-- Reset Order Positions and Refresh
						NS.ResetCharactersOrderPositions();
						SubFrame:Refresh();
					end,
					OnCancel = function ( self ) end,
					OnShow = function ( self, data )
						if data["name"] == NS.currentCharacter.name then
							NS.Print( RED_FONT_COLOR_CODE .. L["You cannot delete the current character"] .. FONT_COLOR_CODE_CLOSE );
							self:Hide();
						end
					end,
					showAlert = 1,
					hideOnEscape = 1,
					timeout = 0,
					exclusive = 1,
					whileDead = 1,
				};
			end,
			Refresh			= function( SubFrame )
				local sfn = SubFrame:GetName();
				_G[sfn .. "CharacterDropDownMenu"]:Reset( NS.selectedCharacterKey );
				_G[sfn .. "OrderAutomaticallyCheckButton"]:SetChecked( NS.db["orderCharactersAutomatically"] );
				if NS.db["orderCharactersAutomatically"] then
					_G[sfn .. "OrderButton"]:Disable();
				else
					_G[sfn .. "OrderButton"]:Enable();
				end
				_G[sfn .. "CurrentCharacterFirstCheckButton"]:SetChecked( NS.db["currentCharacterFirst"] );
				-- Merge Missions, Research, Work Orders into items for ScrollFrame
				wipe( NS.charactersTabItems );
				local char = NS.db["characters"][NS.selectedCharacterKey];
				-- Missions
				if char["monitor"]["missions"] ~= nil then
					table.insert( NS.charactersTabItems, { key = "missions", name = L["Missions In Progress"], icon = 1044517 } );
				end
				-- Advancement
				if char["monitor"]["advancement"] ~= nil then
					table.insert( NS.charactersTabItems, { key = "advancement", name = L["Class Hall Upgrades"], icon = 133743 } );
				end
				-- Work Orders
				for i = 1, #char["orders"] do
					table.insert( NS.charactersTabItems, { key = ( char["orders"][i].troop and char["orders"][i].troop or char["orders"][i].texture ), name = ( char["orders"][i].texture == 134939 and L["Legion Cooking Recipes"] or char["orders"][i].name ), icon = char["orders"][i].texture } );
				end
				--
				_G[sfn .. "ScrollFrame"]:Reset();
			end,
		},
		{
			-- Options
			mainFrameTitle	= NS.title,
			tabText			= OPTIONS,
			Init			= function( SubFrame )
				NS.TextFrame( "MiscLabel", SubFrame, L["Miscellaneous"], {
					setPoint = {
						{ "TOPLEFT", "$parent", "TOPLEFT", 8, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.CheckButton( "ShowMinimapButtonCheckButton", SubFrame, L["Show Minimap Button"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 3, -1 },
					tooltip = L["Show or hide the\nbutton on the Minimap\n\n(Character Specific)"],
					OnClick = function( checked )
						if not checked then
							COHCMinimapButton:Hide();
						else
							COHCMinimapButton:Show();
						end
						NS.UpdateAll( "forceUpdate" );
					end,
					dbpc = "showMinimapButton",
				} );
				NS.CheckButton( "DockMinimapButtonCheckButton", SubFrame, L["Dock Minimap Button"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Docks Minimap button\nto drag around Minimap,\nundock to drag anywhere\n\n(Character Specific)"],
					OnClick = function( checked )
						NS.dbpc[COHCMinimapButton.dbpc] = checked and NS.DefaultSavedVariablesPerCharacter()["minimapButtonPosition"] or { "CENTER", 0, 150 };
						COHCMinimapButton.docked = checked;
						COHCMinimapButton:UpdatePos();
					end,
					dbpc = "dockMinimapButton",
				} );
				NS.CheckButton( "LargeMinimapButtonCheckButton", SubFrame, L["Large Minimap Button"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Enables larger Minimap button\nsimilar to Class Hall Report\n\n(Character Specific)"],
					OnClick = function( checked )
						COHCMinimapButton:UpdateSize( NS.dbpc["largeMinimapButton"] );
						COHCMinimapButton:UpdatePos();
					end,
					dbpc = "largeMinimapButton",
				} );
				NS.CheckButton( "ShowClassHallReportMinimapButtonCheckButton", SubFrame, L["Show Class Hall Report Minimap Button"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Show or hide the\nClass Hall Report\nbutton on the Minimap\n\n(Character Specific)"],
					OnClick = function( checked )
						if not C_Garrison.HasGarrison( LE_GARRISON_TYPE_7_0 ) or not GarrisonLandingPageMinimapButton.title then return end
						GarrisonLandingPageMinimapButton:Hide();
						GarrisonLandingPageMinimapButton:Show();
					end,
					dbpc = "showClassHallReportMinimapButton",
				} );
				NS.CheckButton( "ShowCharacterRealmsCheckButton", SubFrame, L["Show Character Realms"], {
					setPoint = { "LEFT", "$parentShowMinimapButtonCheckButton", "LEFT", ( ( NS.UI.cfg.mainFrame.width - 11 ) / 2 ), 0 },
					tooltip = L["Show or hide\ncharacter realms"],
					db = "showCharacterRealms",
				} );
				NS.CheckButton( "ForgetDragPositionCheckButton", SubFrame, L["Forget Drag Position"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Forget drag position of\nthis frame when closed"],
					db = "forgetDragPosition",
					OnClick = function()
						SubFrame:Refresh();
					end,
				} );
				NS.Button( "CenterButton", SubFrame, L["Center"], {
					size = { 80, 20 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 145, 0 },
					fontObject = "GameFontNormalSmall",
					OnClick = function()
						NS.UI.MainFrame:ClearAllPoints();
						NS.UI.MainFrame:SetPoint( "CENTER", 0, 0 );
					end,
				} );
				NS.DropDownMenu( "MonitorRowsDropDownMenu", SubFrame, {
					setPoint = { "TOPLEFT", "$parentForgetDragPositionCheckButton", "BOTTOMLEFT", -13, -1 },
					tooltip = L["The maximum number of\ncharacters visible at once."] .. "\n" .. RED_FONT_COLOR_CODE .. L["Requires Reload"] .. FONT_COLOR_CODE_CLOSE,
					buttons = {
						{ L["08 Monitor Rows"], 8 },
						{ L["09 Monitor Rows"], 9 },
						{ L["10 Monitor Rows"], 10 },
						{ L["11 Monitor Rows"], 11 },
						{ L["12 Monitor Rows"], 12 },
					},
					OnClick = function( info )
						NS.db["monitorRows"] = info.value;
						--
						local currentHeight = NS.UI.MainFrame:GetHeight();
						local newHeight = NS.UI.cfg.mainFrame.height + ( ( info.value - 8 ) * 50 );
						if currentHeight ~= newHeight then
							_G[SubFrame:GetName() .. "ReloadUIButton"]:Show();
						else
							_G[SubFrame:GetName() .. "ReloadUIButton"]:Hide();
						end
					end,
					width = 133,
				} );
				NS.Button( "ReloadUIButton", SubFrame, L["Reload UI"], {
					hidden = true,
					size = { 80, 20 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 1, 0 },
					fontObject = "GameFontNormalSmall",
					OnClick = function()
						ReloadUI();
					end,
				} );
				local columnNames = {
					["missions"] = L["Missions"],
					["advancement"] = L["Class Hall Upgrades"],
					["artifact-research-notes"] = L["Artifact Research Notes"],
					["cooking-recipes"] = L["Legion Cooking Recipes"],
					["troop1"] = L["Troop #1"],
					["troop2"] = L["Troop #2"],
					["champion-armaments"] = L["Champion Armaments"],
					["world-quest-complete/blessing-order/bonus-roll"] = L["Instant World Quest Complete / Blessing of the Order / Seal of Broken Fate"],
					["troop3"] = L["Troop #3"],
					["troop4"] = L["Troop #4"],
				};
				NS.DropDownMenu( "MonitorColumnsDropDownMenu", SubFrame, {
					setPoint = { "TOPLEFT", "$parentMonitorRowsDropDownMenu", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Column numbers for\nicons on the Monitor tab."],
					buttons = function()
						local t = {};
						for ck,cslug in ipairs( NS.db["monitorColumn"] ) do
							tinsert( t, { ( ck < 10 and ( "0" .. ck ) or ck ) .. ". " .. columnNames[cslug], ck } );
						end
						return t;
					end,
					width = 133,
				} );
				NS.Button( "ColumnButton", SubFrame, L["Column"], {
					size = { 80, 20 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 1, 0 },
					fontObject = "GameFontNormalSmall",
					OnClick = function()
						local ck = UIDropDownMenu_GetSelectedValue( _G[SubFrame:GetName() .. "MonitorColumnsDropDownMenu"] );
						local cname = columnNames[NS.db["monitorColumn"][ck]];
						StaticPopup_Show( "COHC_MONITOR_COLUMN", ck .. ". " .. cname, nil, { ["ck"] = ck, ["name"] = cname } );
					end,
				} );
				NS.Button( "ResetButton", SubFrame, L["Reset"], {
					size = { 80, 20 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 4, 0 },
					fontObject = "GameFontNormalSmall",
					OnClick = function()
						NS.db["monitorColumn"] = NS.DefaultSavedVariables()["monitorColumn"];
						SubFrame:Refresh();
						NS.Print( L["Monitor columns reset"] );
					end,
				} );
				NS.TextFrame( "AlertLabel", SubFrame, L["Alert - Flashes Minimap button when an indicator is |TInterface\\COMMON\\Indicator-Green:20:20|t"], {
					setPoint = {
						{ "TOPLEFT", "$parentShowClassHallReportMinimapButtonCheckButton", "BOTTOMLEFT", -3, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.DropDownMenu( "AlertDropDownMenu", SubFrame, {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", -12, -1 },
					buttons = {
						{ L["Current Character"], "current" },
						{ L["Any Character"], "any" },
						{ L["Disabled"], "disabled" },
					},
					OnClick = function( info )
						NS.db["alert"] = info.value;
						NS.UpdateAll( "forceUpdate" );
					end,
					width = 116,
				} );
				NS.CheckButton( "AlertMissionsCheckButton", SubFrame, L["Missions"], {
					setPoint = { "TOPLEFT", "$parentAlertDropDownMenu", "BOTTOMLEFT", 15, -1 },
					tooltip = L["|cffffffffEnable Alert|r\nMissions In Progress"],
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "alertMissions",
				} );
				NS.CheckButton( "AlertClassHallUpgradesCheckButton", SubFrame, L["Class Hall Upgrades"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["|cffffffffEnable Alert|r\nClass Hall Upgrade Research"],
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "alertClassHallUpgrades",
				} );
				NS.CheckButton( "AlertTroopsCheckButton", SubFrame, L["Troops"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["|cffffffffEnable Alert|r\nTroop Work Orders"],
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "alertTroops",
				} );
				NS.CheckButton( "AlertArtifactResearchNotesCheckButton", SubFrame, L["Artifact Research Notes"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["|cffffffffEnable Alert|r\nArtifact Research Notes Work Orders"],
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "alertArtifactResearchNotes",
				} );
				NS.CheckButton( "AlertAnyArtifactResearchNotesCheckButton", SubFrame, string.format( L["Include 1/2 |T237446:20:20|t %sArtifact Research Notes|r ready for pickup"], ITEM_QUALITY_COLORS[6].hex ), {
					template = "InterfaceOptionsSmallCheckButtonTemplate",
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 24, -1 },
					OnClick = function()
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "alertAnyArtifactResearchNotes",
				} );
				NS.CheckButton( "AlertChampionArmamentsCheckButton", SubFrame, L["Champion Armaments"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", -24, -1 },
					tooltip = L["|cffffffffEnable Alert|r\nChampion Armaments Work Orders"],
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "alertChampionArmaments",
				} );
				NS.CheckButton( "AlertLegionCookingRecipesCheckButton", SubFrame, L["Legion Cooking Recipes"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["|cffffffffEnable Alert|r\nLegion Cooking Recipe Work Orders"],
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "alertLegionCookingRecipes",
				} );
				NS.CheckButton( "AlertInstantCompleteWorldQuestCheckButton", SubFrame, L["Instant Complete World Quest"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["|cffffffffEnable Alert|r\nInstant Complete World Quest\n(e.g. Focusing Crystal) Work Order"],
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "alertInstantCompleteWorldQuest",
				} );
				NS.CheckButton( "AlertBlessingOfTheOrderCheckButton", SubFrame, L["Blessing of the Order"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["|cffffffffEnable Alert|r\nBlessing of the Order\nPriest Work Order"],
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "alertBlessingOfTheOrder",
				} );
				NS.CheckButton( "AlertBonusRollTokenCheckButton", SubFrame, L["Seal of Broken Fate"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["|cffffffffEnable Alert|r\nSeal of Broken Fate Work Order"],
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "alertBonusRollToken",
				} );
				NS.CheckButton( "AlertDisableInInstancesCheckButton", SubFrame, L["Disable in Instances"], {
					setPoint = { "LEFT", "$parentAlertMissionsCheckButton", "LEFT", ( ( NS.UI.cfg.mainFrame.width - 11 ) / 2 ), 0 },
					tooltip = L["|cffffffffDisable Alert|r\nIn Arenas, Dungeons,\nBattlegrounds, and Raids"],
					OnClick = function( checked )
						NS.UpdateAll( "forceUpdate" );
					end,
					db = "alertDisableInInstances",
				} );
				StaticPopupDialogs["COHC_MONITOR_COLUMN"] = {
					text = L["\n%s\n\n|cffffd200Column|r\n|cff82c5ffNumber|r"],
					button1 = L["Change"],
					button2 = CANCEL,
					hasEditBox = 1,
					maxLetters = 2,
					OnAccept = function ( self, data )
						local column = self.editBox:GetNumber();
						if column > 0 then
							local mc = NS.db["monitorColumn"][data["ck"]];
							local maxColumn = #NS.db["monitorColumn"];
							column = column > maxColumn and maxColumn or column;
							if mc and mc ~= NS.FindKeyByValue( NS.db["monitorColumn"], mc ) then
								NS.ChangeColumns( data["ck"], column );
								SubFrame:Refresh();
								NS.Print( string.format( L["Column changed: %d. %s"], column, data["name"] ) );
							end
						else
							NS.Print( RED_FONT_COLOR_CODE .. L["Column must be greater than zero."] .. FONT_COLOR_CODE_CLOSE );
						end
					end,
					OnCancel = function ( self ) end,
					OnShow = function ( self )
						self.editBox:SetNumeric( true );
						self.editBox:SetFocus();
					end,
					OnHide = function ( self )
						self.editBox:SetText( "" );
					end,
					EditBoxOnEnterPressed = function ( self )
						local parent = self:GetParent();
						local OnAccept = StaticPopupDialogs[parent.which].OnAccept;
						OnAccept( parent, parent.data );
						parent:Hide();
					end,
					EditBoxOnEscapePressed = function( self )
						self:GetParent():Hide();
					end,
					hideOnEscape = 1,
					timeout = 0,
					exclusive = 1,
					whileDead = 1,
				};
			end,
			Refresh			= function( SubFrame )
				local sfn = SubFrame:GetName();
				_G[sfn .. "ShowMinimapButtonCheckButton"]:SetChecked( NS.dbpc["showMinimapButton"] );
				_G[sfn .. "DockMinimapButtonCheckButton"]:SetChecked( NS.dbpc["dockMinimapButton"] );
				_G[sfn .. "LargeMinimapButtonCheckButton"]:SetChecked( NS.dbpc["largeMinimapButton"] );
				_G[sfn .. "ShowClassHallReportMinimapButtonCheckButton"]:SetChecked( NS.dbpc["showClassHallReportMinimapButton"] );
				_G[sfn .. "ShowCharacterRealmsCheckButton"]:SetChecked( NS.db["showCharacterRealms"] );
				_G[sfn .. "ForgetDragPositionCheckButton"]:SetChecked( NS.db["forgetDragPosition"] );
				if NS.db["forgetDragPosition"] then
					_G[sfn .. "CenterButton"]:Disable();
				else
					_G[sfn .. "CenterButton"]:Enable();
				end
				_G[sfn .. "MonitorRowsDropDownMenu"]:Reset( NS.db["monitorRows"] );
				_G[sfn .. "MonitorColumnsDropDownMenu"]:Reset( 1 );
				_G[sfn .. "AlertDropDownMenu"]:Reset( NS.db["alert"] );
				_G[sfn .. "AlertMissionsCheckButton"]:SetChecked( NS.db["alertMissions"] );
				_G[sfn .. "AlertClassHallUpgradesCheckButton"]:SetChecked( NS.db["alertClassHallUpgrades"] );
				_G[sfn .. "AlertTroopsCheckButton"]:SetChecked( NS.db["alertTroops"] );
				_G[sfn .. "AlertArtifactResearchNotesCheckButton"]:SetChecked( NS.db["alertArtifactResearchNotes"] );
				_G[sfn .. "AlertAnyArtifactResearchNotesCheckButton"]:SetChecked( NS.db["alertAnyArtifactResearchNotes"] );
				_G[sfn .. "AlertChampionArmamentsCheckButton"]:SetChecked( NS.db["alertChampionArmaments"] );
				_G[sfn .. "AlertLegionCookingRecipesCheckButton"]:SetChecked( NS.db["alertLegionCookingRecipes"] );
				_G[sfn .. "AlertInstantCompleteWorldQuestCheckButton"]:SetChecked( NS.db["alertInstantCompleteWorldQuest"] );
				_G[sfn .. "AlertBlessingOfTheOrderCheckButton"]:SetChecked( NS.db["alertBlessingOfTheOrder"] );
				_G[sfn .. "AlertBonusRollTokenCheckButton"]:SetChecked( NS.db["alertBonusRollToken"] );
				_G[sfn .. "AlertDisableInInstancesCheckButton"]:SetChecked( NS.db["alertDisableInInstances"] );
			end,
		},
		{
			-- Help
			mainFrameTitle	= NS.title,
			tabText			= HELP_LABEL,
			Init			= function( SubFrame )
				NS.TextFrame( "Description", SubFrame, string.format( L["%s version %s"], NS.title, NS.versionString ), {
					setPoint = {
						{ "TOPLEFT", "$parent", "TOPLEFT", 8, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontRedSmall",
				} );
				NS.TextFrame( "SlashCommandsHeader", SubFrame, string.format( L["%sSlash Commands|r"], BATTLENET_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -18 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.TextFrame( "SlashCommands", SubFrame, string.format( L["%s/cohc|r - Open and close this frame"], NORMAL_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "IndicatorsHeader", SubFrame, string.format( L["%sIndicators|r"], BATTLENET_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -18 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.TextFrame( "IndicatorsGray", SubFrame, L["|TInterface\\COMMON\\Indicator-Gray:20:20|t None in progress"], {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "IndicatorsRed", SubFrame, L["|TInterface\\COMMON\\Indicator-Red:20:20|t All incomplete"], {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, 0 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "IndicatorsYellow", SubFrame,	L["|TInterface\\COMMON\\Indicator-Yellow:20:20|t Some complete"], {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, 0 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "IndicatorsGreen", SubFrame, L["|TInterface\\COMMON\\Indicator-Green:20:20|t All complete"], {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, 0 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "GettingStartedHeader", SubFrame, string.format( L["%sGetting Started|r"], BATTLENET_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -18 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.TextFrame( "GettingStarted", SubFrame, string.format(
						L["%s1.|r Log into a character you want to monitor.\n" ..
						"%s2.|r Select Characters tab and uncheck what you don't want to monitor.\n" ..
						"%s3.|r Repeat 1-2 for all characters you want included in this addon."],
						NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE
					), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "NeedMoreHelpHeader", SubFrame, string.format( L["%sNeed More Help?|r"], BATTLENET_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -18 },
						{ "RIGHT", 0 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.TextFrame( "NeedMoreHelp", SubFrame, string.format(
						L["%sQuestions, comments, and suggestions can be made on Curse.\nPlease submit bug reports on CurseForge.|r\n\n" ..
						"https://mods.curse.com/addons/wow/254300-class-order-halls-complete\n" ..
						"https://wow.curseforge.com/projects/class-order-halls-complete/issues"],
						NORMAL_FONT_COLOR_CODE
					), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
			end,
			Refresh			= function( SubFrame ) return end,
		},
	},
};
