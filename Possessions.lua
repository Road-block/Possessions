--[[
Possessions: AddOn to keep track of all of your items.

License:
	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program (see GLP.txt); if not, write to the Free Software
	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
]]

local POSSESSIONS_VERSION = "2.0.2g";

local CHARACTER_NUM_ITEMS = 19;

local POSSESSIONS_ITEMS_TOSHOW = 15;
local POSSESSIONS_ITEMS_HEIGHT = 16;
					
local Possessions_INVENTORY_SLOT_LIST = {
	{ name = "HeadSlot" },
	{ name = "NeckSlot" },
	{ name = "ShoulderSlot" },
	{ name = "BackSlot" },
	{ name = "ChestSlot" },
	{ name = "ShirtSlot" },
	{ name = "TabardSlot" },
	{ name = "WristSlot" },
	{ name = "HandsSlot" },
	{ name = "WaistSlot" },
	{ name = "LegsSlot" },
	{ name = "FeetSlot" },
	{ name = "Finger0Slot" },
	{ name = "Finger1Slot" },
	{ name = "Trinket0Slot" },
	{ name = "Trinket1Slot" },
	{ name = "MainHandSlot" },
	{ name = "SecondaryHandSlot" },
	{ name = "RangedSlot" },
};

local realmName;
local playerName;
local playerFaction;

local searchString;
local searchChar = nil;
local searchLoc = nil;
local searchSlot = nil;

local characterTable = { };

local lastScan = 0;

local INDEX_LINK = 0;
local INDEX_NAME = 1;
local INDEX_ICON = 2;
local INDEX_QUANTITY = 3;
local INDEX_RARITY = 4;
local INDEX_LOCS = 5;

local INVENTORY_CONTAINER = 0;
local BANK_CONTAINER = -1;
local PLAYER_CONTAINER = -2;
local MAIL_CONTAINER = -3;
local KEYRING_CONTAINER = -4;

local origSendMail;
local OnePastEnd;
local hasEnteredOnce = false;

local possessionsLocationNames = {
		{container = KEYRING_CONTAINER, name = POSSESSIONS_TEXT_KEYRING},
		{container = PLAYER_CONTAINER, name = POSSESSIONS_TEXT_PLAYER},
		{container = BANK_CONTAINER, name = POSSESSIONS_TEXT_BANK},
		{container = INVENTORY_CONTAINER, name = POSSESSIONS_TEXT_INVENTORY},
		{container = MAIL_CONTAINER, name = POSSESSIONS_TEXT_INBOX}
};

local possessionsSlotNames = {
	{slot = INVTYPE_AMMO,				name = "INVTYPE_AMMO"},
	{slot = INVTYPE_HEAD, 				name = "INVTYPE_HEAD"},
	{slot = INVTYPE_NECK, 				name = "INVTYPE_NECK"},
	{slot = INVTYPE_SHOULDER, 			name = "INVTYPE_SHOULDER"},
	{slot = INVTYPE_BODY, 				name = "INVTYPE_BODY"},
	{slot = INVTYPE_CHEST, 				name = "INVTYPE_CHEST"},
	{slot = INVTYPE_ROBE, 				name = "INVTYPE_ROBE"},
	{slot = INVTYPE_WAIST, 				name = "INVTYPE_WAIST"},
	{slot = INVTYPE_LEGS, 				name = "INVTYPE_LEGS"},
	{slot = INVTYPE_FEET, 				name = "INVTYPE_FEET"},
	{slot = INVTYPE_WRIST, 				name = "INVTYPE_WRIST"},
	{slot = INVTYPE_HAND, 				name = "INVTYPE_HAND"},
	{slot = INVTYPE_FINGER, 			name = "INVTYPE_FINGER"},
	{slot = INVTYPE_TRINKET, 			name = "INVTYPE_TRINKET"},
	{slot = INVTYPE_CLOAK, 				name = "INVTYPE_CLOAK"},
	{slot = INVTYPE_WEAPON, 			name = "INVTYPE_WEAPON"},
	{slot = INVTYPE_SHIELD, 			name = "INVTYPE_SHIELD"},
	{slot = INVTYPE_2HWEAPON, 			name = "INVTYPE_2HWEAPON"},
	{slot = INVTYPE_WEAPONMAINHAND,		name = "INVTYPE_WEAPONMAINHAND"},
	{slot = INVTYPE_WEAPONOFFHAND,		name = "INVTYPE_WEAPONOFFHAND"},
	{slot = INVTYPE_HOLDABLE, 			name = "INVTYPE_HOLDABLE"},
	{slot = INVTYPE_RANGED, 			name = "INVTYPE_RANGED"},
	{slot = INVTYPE_THROWN, 			name = "INVTYPE_THROWN"},
	{slot = INVTYPE_RANGEDRIGHT, 			name = "INVTYPE_RANGEDRIGHT"},
	{slot = INVTYPE_RELIC, 				name = "INVTYPE_RELIC"},
	{slot = INVTYPE_TABARD, 			name = "INVTYPE_TABARD"},
	{slot = INVTYPE_BAG, 				name = "INVTYPE_BAG"}
};

local DisplayIndices = {}

function Possessions_SlotDropDown_OnClick()
	local id = this:GetID();
	UIDropDownMenu_SetSelectedID(Possessions_SlotDropDown, id);
	
	if( id > 1) then
		searchSlot = possessionsSlotNames[id-1].name;
	else
		searchSlot = nil;
	end
	
	Possessions_Update();
end

function Possessions_SlotDropDown_Initialize()
	local info;

	info = { };
	info.text = POSSESSIONS_TEXT_ALLSLOTS;
	info.func = Possessions_SlotDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	for i = 1, getn(possessionsSlotNames), 1 do
		info = { };
		if possessionsSlotNames[i].name == "INVTYPE_SHIELD" then
			info.text = "Shield";
		elseif possessionsSlotNames[i].name == "INVTYPE_RANGED" then
			info.text = "Bow";
		elseif possessionsSlotNames[i].name == "INVTYPE_RANGEDRIGHT" then
			info.text = "Wand/Gun/Crossbow";
		elseif possessionsSlotNames[i].name == "INVTYPE_ROBE" then
			info.text = "Robe";
		else
			info.text = possessionsSlotNames[i].slot;
		end
		info.func = Possessions_SlotDropDown_OnClick;
		UIDropDownMenu_AddButton(info);
	end
end

function Possessions_SlotDropDown_OnShow()
     UIDropDownMenu_Initialize(this, Possessions_SlotDropDown_Initialize);
     UIDropDownMenu_SetSelectedID(this, 1);
     UIDropDownMenu_SetWidth(90);
end

function Possessions_LocDropDown_OnClick()
	local id = this:GetID();
	UIDropDownMenu_SetSelectedID(Possessions_LocDropDown, id);
	
	if( id > 1) then
		searchLoc = possessionsLocationNames[id-1].container;
	else
		searchLoc = nil;
	end
	
	Possessions_Update();
end


function Possessions_LocDropDown_Initialize()
	local info;

	info = { };
	info.text = POSSESSIONS_TEXT_ALLLOCS;
	info.func = Possessions_LocDropDown_OnClick;
        UIDropDownMenu_AddButton(info);


	for i = 1, getn(possessionsLocationNames), 1 do
		info = { };
		info.text = possessionsLocationNames[i].name;
		info.func = Possessions_LocDropDown_OnClick;
		UIDropDownMenu_AddButton(info);
	end
end

function Possessions_LocDropDown_OnShow()
     UIDropDownMenu_Initialize(this, Possessions_LocDropDown_Initialize);
     UIDropDownMenu_SetSelectedID(this, 1);
     UIDropDownMenu_SetWidth(90);
end

function Possessions_CharDropDown_OnClick()
   local id = this:GetID();
   UIDropDownMenu_SetSelectedID(Possessions_CharDropDown, id);

   if( id > 1) then
      searchChar = characterTable[id-1];
   else
      searchChar = nil;
   end
   Possessions_Update();
end


function Possessions_CharDropDown_Initialize()
	local info;

	info = { };
	info.text = POSSESSIONS_TEXT_ALLCHARS;
	info.func = Possessions_CharDropDown_OnClick;
        UIDropDownMenu_AddButton(info);

	for i = 1, getn(characterTable), 1 do
		info = { };
		info.text = Possessions_Capitalize(characterTable[i]);
		info.func = Possessions_CharDropDown_OnClick;
		UIDropDownMenu_AddButton(info);
	end
       
end

function Possessions_CharDropDown_OnShow()
     UIDropDownMenu_Initialize(this, Possessions_CharDropDown_Initialize);
     UIDropDownMenu_SetSelectedID(this, 1);
     UIDropDownMenu_SetWidth(90);
end

function Possessions_StoreLink(bagnum, containerItemNum, link)
	local head,tail,item = string.find(link, ".*item:(%d+):%d+:%d+:%d+.*");
	local name,_,rarity
	if item then
		-- itemName, itemString, itemQuality, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture
		name, _, rarity = GetItemInfo(item);
	end
	if( item and name ) then
		PossessionsData[realmName][playerName].items[bagnum][containerItemNum] = {};
		PossessionsData[realmName][playerName].items[bagnum][containerItemNum][INDEX_LINK] = item;
		PossessionsData[realmName][playerName].items[bagnum][containerItemNum][INDEX_NAME] = name;
		PossessionsData[realmName][playerName].items[bagnum][containerItemNum][INDEX_RARITY] = rarity;	

		return true;
	end
	return false;
end


function Possessions_ReloadBag(bagnum)
	local link, icon, quantity, itemnum;
	local maxContainerItems = GetContainerNumSlots(bagnum);


	local storebagnum = bagnum;
	if ( bagnum == -2 ) then
		storebagnum = KEYRING_CONTAINER;
	end

	if ( maxContainerItems > 0) then
		PossessionsData[realmName][playerName].items[storebagnum] = { };

		for containerItemNum = 1, maxContainerItems do
			link = GetContainerItemLink(bagnum, containerItemNum);
			icon, quantity = GetContainerItemInfo(bagnum, containerItemNum);
			if( link ) then
				if( Possessions_StoreLink(storebagnum, containerItemNum, link) ) then
					PossessionsData[realmName][playerName].items[storebagnum][containerItemNum][INDEX_QUANTITY] = quantity;
					PossessionsData[realmName][playerName].items[storebagnum][containerItemNum][INDEX_ICON] = icon;
				end
			end
		end
	end

end

function Possessions_Hide()
   HideUIPanel(Possessions_Frame);
end

function Possessions_Toggle()
	if( Possessions_Frame:IsVisible() ) then
		Possessions_Hide();
	else
		Possessions_Show();
	end
end

function Possessions_Show()
	searchChar = nil;
	searchLoc = nil;
	searchSlot = nil;
	
	Possessions_Update();
	ShowUIPanel(Possessions_Frame);
end



function Possessions_SlashCommandHandler(msg)
	if( msg ) then
		Possessions_SearchBox:SetText(msg);
	end
	
	Possessions_Show();
end


function Possessions_Update()
	FauxScrollFrame_SetOffset(Possessions_IC_ScrollFrame, 0);
	getglobal("Possessions_IC_ScrollFrameScrollBar"):SetValue(0);	
	
	local msg = Possessions_SearchBox:GetText();
	
	if( msg and msg ~= "" ) then
		searchString = string.lower(msg);
	else
		searchString = nil;
	end
	
	Possessions_BuildDisplayIndices();
	Possessions_UpdateView();
end

function Possessions_BuildDisplayIndices()
	DisplayIndices = { };
	local iNew = 1;
	local link;
	local TempTable = { };
	local location;
	local slot = nil;
	local _;

	for index, value in pairs(PossessionsData[realmName]) do
		 if (not value.faction or value.faction == playerFaction) then
			for index2, value2 in pairs(value.items) do
				for index3, value3 in pairs(value2) do
					if (value3[INDEX_LINK]) then
						--itemName, itemString, itemQuality, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture
						_, _, _, _, _, _, _, slot = GetItemInfo("item:" .. value3[INDEX_LINK]);
					end

					if( value3[INDEX_NAME] and 
						(not searchString or (searchString and string.find(string.lower(value3[INDEX_NAME]), searchString)))
						and (not searchChar or searchChar == index)
						and (not searchLoc or searchLoc == Possessions_Bag2Loc(index2))
						and (not searchSlot or searchSlot == slot)
					  )  then

						link = value3[INDEX_NAME];

						if (not TempTable[link]) then
							TempTable[link] = { };
							TempTable[link][INDEX_LINK] = value3[INDEX_LINK];
							TempTable[link][INDEX_RARITY] = value3[INDEX_RARITY];
							TempTable[link][INDEX_ICON] = value3[INDEX_ICON];
							TempTable[link][INDEX_QUANTITY] = 0;
						elseif( TempTable[link][INDEX_RARITY] == -1 ) then
							TempTable[link][INDEX_RARITY] = value3[INDEX_RARITY];
						end

						if( not TempTable[link][INDEX_LINK] and value3[INDEX_LINK] ) then
							TempTable[link][INDEX_LINK] = value3[INDEX_LINK];
						end

						TempTable[link][INDEX_QUANTITY] = TempTable[link][INDEX_QUANTITY] + value3[INDEX_QUANTITY];

						if( not TempTable[link][INDEX_LOCS] ) then
							TempTable[link][INDEX_LOCS] = { };
						end

						if( not TempTable[link][INDEX_LOCS][index] ) then
							TempTable[link][INDEX_LOCS][index] = { };
						end

						location = Possessions_Bag2Loc(index2);

						if( not TempTable[link][INDEX_LOCS][index][location] ) then
							TempTable[link][INDEX_LOCS][index][location] = value3[INDEX_QUANTITY];
						else
							TempTable[link][INDEX_LOCS][index][location] = 
							TempTable[link][INDEX_LOCS][index][location] + value3[INDEX_QUANTITY];
						end
					end
				end
			end
		end
	end


	for index, value in pairs(TempTable) do
		DisplayIndices[iNew] = { };
		DisplayIndices[iNew][INDEX_LINK] = value[INDEX_LINK];
		DisplayIndices[iNew][INDEX_NAME] = index;
		DisplayIndices[iNew][INDEX_RARITY] = value[INDEX_RARITY];
		DisplayIndices[iNew][INDEX_QUANTITY] = value[INDEX_QUANTITY];
		DisplayIndices[iNew][INDEX_ICON] = value[INDEX_ICON];
		DisplayIndices[iNew][INDEX_LOCS] = value[INDEX_LOCS];
		iNew = iNew + 1;
	end

	TempTable =  nil;

	if( POSSESSIONS_Sort_Name == 1) then
		table.sort(DisplayIndices, Possessions_NameComparison);
	else
		table.sort(DisplayIndices, Possessions_RarityComparison);
	end
	DisplayIndices.OnePastEnd = iNew;
	Possessions_CountMoney();
end

function Possessions_Bag2Loc(bag)
  	if( bag == KEYRING_CONTAINER) then
     	return KEYRING_CONTAINER;
	elseif( bag == PLAYER_CONTAINER ) then
		return PLAYER_CONTAINER;
	elseif( bag >= 0 and bag <= NUM_BAG_SLOTS ) then
		return INVENTORY_CONTAINER;
	elseif( bag == MAIL_CONTAINER ) then
		return MAIL_CONTAINER;
	else
		return BANK_CONTAINER;
	end
 end


function Possessions_RarityComparison(elem1, elem2)
   if( elem1[INDEX_RARITY] == elem2[INDEX_RARITY] ) then
      return elem1[INDEX_NAME] < elem2[INDEX_NAME];
   else
      return elem1[INDEX_RARITY] > elem2[INDEX_RARITY];
   end
    
end


function Possessions_NameComparison(elem1, elem2)
   return elem1[INDEX_NAME] < elem2[INDEX_NAME];
end


function Possessions_OnHide()
   DisplayIndices = nil;
end


function Possessions_UpdateView()
	local item, itemIndex, possItem, possEntryName, possEntryCount, possEntryTexture, color;
	
	if( not DisplayIndices ) then
		return;
	end
	
	FauxScrollFrame_Update(Possessions_IC_ScrollFrame, DisplayIndices.OnePastEnd-1, 
		POSSESSIONS_ITEMS_TOSHOW, POSSESSIONS_ITEMS_HEIGHT);
	
	for iItem = 1, POSSESSIONS_ITEMS_TOSHOW, 1 do
		itemIndex = iItem + FauxScrollFrame_GetOffset(Possessions_IC_ScrollFrame);
	
		possItem         = getglobal("POSSESSIONS_BrowseButton" .. iItem);
		possEntryName    = getglobal("POSSESSIONS_BrowseButton" .. iItem .. "Name");
		possEntryCount   = getglobal("POSSESSIONS_BrowseButton" .. iItem .. "Quantity");	
		possEntryTexture = getglobal("POSSESSIONS_BrowseButton" .. iItem .. "ItemIconTexture");
	 
		if( itemIndex < DisplayIndices.OnePastEnd ) then
			item = DisplayIndices[itemIndex];
			
			if( item[INDEX_RARITY] ~= -1) then
				local _, _, _, color = GetItemQualityColor(item[INDEX_RARITY]);
				possEntryName:SetText(color .. item[INDEX_NAME]);
			else
				possEntryName:SetText(item[INDEX_NAME]);
			end
			
			possEntryCount:SetText(item[INDEX_QUANTITY]);
			possEntryTexture:SetTexture(item[INDEX_ICON]);
			
			possItem:Show();
			else
			possItem:Hide();
		end
	end
end

function Possessions_GetLink(item)
	local i;
	local _, _, _, color = GetItemQualityColor(item[INDEX_RARITY]);
	
	return color .."|Hitem:".. item[INDEX_LINK]  .. "|h["..item[INDEX_NAME].."]|h|r";
end


function Possessions_Click(button)
	local id = this:GetID();

	if(id == 0) then
		id = this:GetParent():GetID();
	end

	local offset = FauxScrollFrame_GetOffset(Possessions_IC_ScrollFrame);
	local item = DisplayIndices[id + offset];

	if (item[INDEX_LINK]) then
		if( button == "LeftButton" ) then
			local link = Possessions_GetLink(item);
		
			if( IsShiftKeyDown() and ChatFrameEditBox:IsVisible()) then
				ChatFrameEditBox:Insert(link);
			elseif (IsControlKeyDown()) then
				DressUpItemLink(link);
			end
		elseif( button == "RightButton" ) then
		GameTooltip:SetHyperlink("item:" .. item[INDEX_LINK]);
		end
	end
end


function Possessions_ItemButton_OnEnter()
	local id = this:GetID();
	local itemLink,itemStackCount,_;	
	itemLink = nil;
	itemStackCount = nil;
	
	if(id == 0) then
		id = this:GetParent():GetID();
	end
	
	local offset = FauxScrollFrame_GetOffset(Possessions_IC_ScrollFrame);
	local item = DisplayIndices[id + offset];
	
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");

	if( item[INDEX_LINK]) then
		-- itemName, itemString, itemQuality, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture
		_, itemLink, _, _, _, _, itemStackCount = GetItemInfo("item:" .. item[INDEX_LINK]);
	end
	
	if( itemLink ) then
		GameTooltip:SetHyperlink("item:" .. item[INDEX_LINK]);

		if (IsAddOnLoaded("RecipeBook")) then
			RecipeBook_DoHookedFunction(GameTooltip, "item:" .. item[INDEX_LINK]);
		end

		if (EnhTooltip) then
			EnhTooltip.ClearTooltip();
			EnhTooltip.TooltipCall(GameTooltip, item[INDEX_NAME], Possessions_GetLink(item), item[INDEX_RARITY], 1, 0);
			EnhTooltip.AddSeparator(false);
		end
	else
		if (EnhTooltip) then
			GameTooltip:SetText(item[INDEX_NAME]);
			EnhTooltip.TooltipCall(GameTooltip, item[INDEX_NAME]);
		else
			GameTooltip:AddLine(item[INDEX_NAME]);
		end
	end

	local location;
	local adj = " in ";
	
	if (not EnhTooltip) then
		GameTooltip:AddLine(" ");
	end
	
	for index, value in pairs(item[INDEX_LOCS]) do
		for index2, value2 in pairs(value) do
			if( index2 == BANK_CONTAINER ) then
				location = "bank";
		 	elseif( index2 == KEYRING_CONTAINER ) then
				location = "keyring";
			elseif( index2 == PLAYER_CONTAINER ) then
				location = "person";
				adj = " on ";
			elseif( index2 == INVENTORY_CONTAINER ) then
				location = "inventory";
			elseif( index2 == MAIL_CONTAINER ) then
				location = "Inbox";
			else
				location = "unknown";
			end

			local line = value2 .. adj .. Possessions_Capitalize(index) .. "'s " .. location;
			if (EnhTooltip) then
				EnhTooltip.AddLine(line);
			else
				GameTooltip:AddLine(line); 
			end
		end
	end

	if( itemStackCount ) then
		if (EnhTooltip) then
			EnhTooltip.AddLine("Stack Count: "..itemStackCount);
		else
			GameTooltip:AddLine("Stack Count: "..itemStackCount);
		end
	end
	
	if (EnhTooltip) then
		EnhTooltip.ShowTooltip(GameTooltip);
	else
		GameTooltip:Show();
	end

end

function Possessions_Capitalize(str)
	return string.upper(string.sub(str,1,1)) .. string.sub(str,2);
end

function Possessions_ItemButton_OnLeave()
	GameTooltip:Hide();

	if (EnhTooltip) then
		EnhTooltip.ClearTooltip();
	end
end

function Possessions_convertDB1to2()
	DEFAULT_CHAT_FRAME:AddMessage("Possessions: Updating data to new format");
	local tempTable = { };
	for item, value in PossessionsData do
		tempTable[item] = { };
		DEFAULT_CHAT_FRAME:AddMessage("Server: " .. item);
		for item2, value2 in value do
			tempTable[item][item2] = { };
			tempTable[item][item2].items = { };
			DEFAULT_CHAT_FRAME:AddMessage("Char: " .. item2);
			for item3, value3 in value2 do
				tempTable[item][item2].items[item3] = value3;
			end			
		end
	end
	PossessionsData = tempTable;
	
	for item, value in PossessionsData do
		for item2, value2 in value do
			for item3, value3 in value2.items do
				for item4, value4 in value3 do
					if (value4) then
						if (value4[INDEX_RARITY] == 5) then
							value4[INDEX_RARITY] = -1;
						elseif (value4[INDEX_RARITY] == 4) then
							value4[INDEX_RARITY] = 0;
						elseif (value4[INDEX_RARITY] == 0) then
							value4[INDEX_RARITY] = 4;
						elseif (value4[INDEX_RARITY] == 3) then
							value4[INDEX_RARITY] = 1;
						elseif (value4[INDEX_RARITY] == 1) then
							value4[INDEX_RARITY] = 3;
						end
					end
				end
			end
		end
	end

	PossessionsData.config = { };
	PossessionsData.config.version = 1;

end

function Possessions_VarsLoaded()
	realmName = GetCVar("realmname");
	playerName = string.lower(UnitName("player"));
	
	if (PossessionsData and not PossessionsData.config) then
		Possessions_convertDB1to2();
	end
	
	if( not PossessionsData ) then
		PossessionsData = { };
		PossessionsData.config = { };
		PossessionsData.config.version = 1;
	end
	
	if( not PossessionsData[realmName] ) then
		PossessionsData[realmName] = { };
	end
	
	if( not PossessionsData[realmName][playerName] ) then
		PossessionsData[realmName][playerName] = { };
		PossessionsData[realmName][playerName].items = { };
	end
	
	for index = 1, getn(Possessions_INVENTORY_SLOT_LIST), 1 do
		Possessions_INVENTORY_SLOT_LIST[index].id = GetInventorySlotInfo(Possessions_INVENTORY_SLOT_LIST[index].name);
	end
	
	if(myAddOnsFrame) then
		myAddOnsList.Possessions = {
			name = "Possessions",
			description = "AddOn to keep to keep track of all your items.",
			version = POSSESSIONS_VERSION,
			category = MYADDONS_CATEGORY_INVENTORY,
			frame = "Possessions_Frame"
		};
	end
	
	SLASH_POSSESSIONS1 = "/possessions";
	SLASH_POSSESSIONS2 = "/poss";
	
	SlashCmdList["POSSESSIONS"] = function(msg)
		Possessions_SlashCommandHandler(msg);
	end
	
	origSendMail = SendMail;
	SendMail = Possessions_SendMail;
	
	for index, value in pairs(PossessionsData[realmName]) do
		table.insert(characterTable, index);
	end
	
	Possessions_FrameTitle:SetText(POSSESSIONS_INV_TITLE_TEXT .. " v" .. POSSESSIONS_VERSION);

end

function Possessions_PlayerEnterWorld()
	if (not hasEnteredOnce) then
		Possessions_ScanMoney();
		playerFaction = UnitFactionGroup("player");
		PossessionsData[realmName][playerName].faction = playerFaction;
     	Possessions_Inspect();
		Possessions_ScanInv();
		hasEnteredOnce = true;
	end
	
	this:RegisterEvent("BAG_UPDATE");
	this:RegisterEvent("UNIT_INVENTORY_CHANGED");
	this:RegisterEvent("PLAYERBANKSLOTS_CHANGED");
	this:RegisterEvent("PLAYER_MONEY");
end

function Possessions_PlayerLeavingWorld()
	this:UnregisterEvent("BAG_UPDATE");
	this:UnregisterEvent("UNIT_INVENTORY_CHANGED");
	this:UnregisterEvent("PLAYERBANKSLOTS_CHANGED");
	this:UnregisterEvent("PLAYER_MONEY");
end


function Possessions_Inspect()
	local index, link, texture;

	PossessionsData[realmName][playerName].items[PLAYER_CONTAINER] = { };

	for index = 1, getn(Possessions_INVENTORY_SLOT_LIST), 1 do
	

		link = GetInventoryItemLink("player", Possessions_INVENTORY_SLOT_LIST[index].id);
		texture = GetInventoryItemTexture("player", Possessions_INVENTORY_SLOT_LIST[index].id);

		if( link ) then
		   if( Possessions_StoreLink(PLAYER_CONTAINER, index, link) ) then
		      PossessionsData[realmName][playerName].items[PLAYER_CONTAINER][index][INDEX_QUANTITY] = 1;
		      PossessionsData[realmName][playerName].items[PLAYER_CONTAINER][index][INDEX_ICON] = texture;
		   end
		end		
	end
end


function Possessions_ScanInv()
	--DEFAULT_CHAT_FRAME:AddMessage("Number of Bag Frames: "..NUM_BAG_FRAMES);
	for bagid=0,NUM_BAG_FRAMES,1 do
		Possessions_ReloadBag(bagid);
	end
	if ( HasKey() ) then
		--Keyring's ID is -2
		Possessions_ReloadBag(-2);
	end
end

function Possessions_ScanBank()
	Possessions_ReloadBag(BANK_CONTAINER);

	for bagid = NUM_BAG_SLOTS + 1, (NUM_BAG_SLOTS + NUM_BANKBAGSLOTS), 1 do
		Possessions_ReloadBag(bagid);
	end
end

function Possessions_ScanMail()
	local currTime = GetTime();
	if (currTime - lastScan < 1) then
		return;
	end
	lastScan = GetTime();
	
	local items = GetInboxNumItems();
	local name, icon, quantity, rarity;
	local iItem = 0;

	if( items > 0 ) then
		--DEFAULT_CHAT_FRAME:AddMessage("Possessions: Scanning mail, items " .. items .. ", time " .. GetTime());
		PossessionsData[realmName][playerName].items[MAIL_CONTAINER] = { };

		for index = 1, items, 1 do
			name, icon, quantity, rarity = GetInboxItem(index);
			if( name ) then
				PossessionsData[realmName][playerName].items[MAIL_CONTAINER][iItem] = { };
				PossessionsData[realmName][playerName].items[MAIL_CONTAINER][iItem][INDEX_NAME] = name;
				PossessionsData[realmName][playerName].items[MAIL_CONTAINER][iItem][INDEX_ICON] = icon;
				PossessionsData[realmName][playerName].items[MAIL_CONTAINER][iItem][INDEX_QUANTITY] = quantity;
				PossessionsData[realmName][playerName].items[MAIL_CONTAINER][iItem][INDEX_RARITY] = rarity;
				iItem = iItem + 1;
			end
		end
	end
end

function Possessions_HideMoneyTooltip()
	if (EnhTooltip) then
		EnhTooltip.HideTooltip();
	end
end

function Possessions_ShowMoneyTooltip()
	if (EnhTooltip) then
		GameTooltip:SetOwner(this, "ANCHOR_LEFT");
		EnhTooltip.ClearTooltip();

		for player, values in pairs(PossessionsData[realmName]) do
			if (values.money) then
				EnhTooltip.AddLine(Possessions_Capitalize(player), values.money);
			end
		end
		EnhTooltip.ShowTooltip(GameTooltip, true);
	end
end

function Possessions_CountMoney()
	local totalMoney = 0;

	if (EnhTooltip) then
		for players, values in pairs(PossessionsData[realmName]) do
	   		if (values.money) then
				totalMoney = totalMoney + values.money;
	   		end
		end
		--DEFAULT_CHAT_FRAME:AddMessage("Money: " .. totalMoney);		
		POSSESSIONS_MoneyField_Text:SetText(EnhTooltip.GetTextGSC(totalMoney, true));
	end
end

function Possessions_ScanMoney()
	PossessionsData[realmName][playerName].money = GetMoney();	
end

function Possessions_SendMail(name, subject, body)
	local itemName, itemTexture, stackCount = GetSendMailItem();
	local namelc;
	
	if( name ) then
		namelc = string.lower(name);
	end
	
	if( namelc and PossessionsData[realmName][namelc] ) then
		if( not PossessionsData[realmName][namelc].items[MAIL_CONTAINER] ) then
			PossessionsData[realmName][namelc].items[MAIL_CONTAINER] = { };
		end

		local n = 0;
		for index, value in pairs(PossessionsData[realmName][namelc].items[MAIL_CONTAINER]) do
			n = n + 1;
		end

		PossessionsData[realmName][namelc].items[MAIL_CONTAINER][n] = { };
		PossessionsData[realmName][namelc].items[MAIL_CONTAINER][n][INDEX_NAME] = itemName;
		PossessionsData[realmName][namelc].items[MAIL_CONTAINER][n][INDEX_ICON] = itemTexture;
		PossessionsData[realmName][namelc].items[MAIL_CONTAINER][n][INDEX_QUANTITY] = stackCount;
		PossessionsData[realmName][namelc].items[MAIL_CONTAINER][n][INDEX_RARITY] = -1;
	end
	
	origSendMail(name, subject, body);
end


function Possessions_OnLoad()	
	this:RegisterEvent("BANKFRAME_OPENED");
	this:RegisterEvent("MAIL_INBOX_UPDATE");
	this:RegisterEvent("VARIABLES_LOADED");
	this:RegisterEvent("PLAYER_ENTERING_WORLD");
	this:RegisterEvent("PLAYER_LEAVING_WORLD");
	table.insert(UISpecialFrames, "Possessions_Frame");
end


function Possessions_OnEvent(event)
	
	if( event == "BAG_UPDATE" ) then
		Possessions_ReloadBag(arg1);
	elseif ( event == "PLAYER_MONEY") then
		Possessions_ScanMoney();
	elseif( event == "PLAYERBANKSLOTS_CHANGED" ) then
		if( BankFrame:IsVisible() ) then
			Possessions_ScanBank();
		end
	elseif( event == "UNIT_INVENTORY_CHANGED" ) then
		if( arg1 == "player") then
			Possessions_ScanInv();
			Possessions_Inspect();
		end
	elseif( event == "BANKFRAME_OPENED" ) then
		Possessions_ScanBank();
	elseif( event == "MAIL_INBOX_UPDATE" ) then
		--DEFAULT_CHAT_FRAME:AddMessage("Possessions: Scanning mail");
		Possessions_ScanMail();
	elseif( event == "VARIABLES_LOADED" ) then
		Possessions_VarsLoaded();
	elseif( event == "PLAYER_ENTERING_WORLD" ) then
		Possessions_PlayerEnterWorld();
	elseif( event == "PLAYER_LEAVING_WORLD" ) then
		Possessions_PlayerLeavingWorld();
	end
end