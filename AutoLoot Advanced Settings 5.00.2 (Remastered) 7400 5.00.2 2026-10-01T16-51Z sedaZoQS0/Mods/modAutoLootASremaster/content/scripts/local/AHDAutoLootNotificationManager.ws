/***********************************************************************/
/** 	AHDAutoLootNotificationManager.ws
/** 	by AeroHD
/**		Original AutoLoot code by JupiterTheGod
/**		mod: AutoLoot Advanced Settings (AutoLoot +A.S.) by jerry18
/***********************************************************************/



class CAHDAutoLootNotificationManager
{
	private var AutoLootConfig : CAHDAutoLootConfig;
	private var UserSettings : CInGameConfigWrapper;
	private var itemNames, itemIcons, itemDescriptions : array<string>;
	private var itemCounts : array<int>;
	private var soundCategories : array<name>;
	private var totalSize, helperSecond, E_KEY_Logic, totalItemsProcessed : int;
	private var currentTime, lastNotificationTime, timeDelay : float;
	private var AHDAL_READ_SUFFIX, AHDAL_KNOWN_SUFFIX : string;
	private var setComColStr, setMasColStr, setMagColStr, setRelColStr, setWitchColStr, setMulColStr : string;
	
	public function Init() : void
	{
		AutoLootConfig = GetWitcherPlayer().GetAutoLootConfig();
	}
	
	//Resets all local values, initializes static strings
	public function Reset()
	{
		itemNames.Clear();
		itemCounts.Clear();
		itemIcons.Clear();
		itemDescriptions.Clear();
		soundCategories.Clear();
		helperSecond = 0;
		totalSize = 0;
		totalItemsProcessed = 0;
		AHDAL_READ_SUFFIX = GetLocStringByKeyExt( "ahdal_readTag" );
		AHDAL_KNOWN_SUFFIX = GetLocStringByKeyExt( "ahdal_knownTag" );
	}
	
	//Returns the index of the first occurence of the specified item (string), -1 if not found
	private function GetIndexByString(itemName : string) : int
	{
		var i : int;
		
		for (i=0; i<itemNames.Size(); i+=1 )
		{
			if( StrReplace(itemName, AHDAL_READ_SUFFIX, "") == itemNames[i]
				|| StrReplace(itemName, AHDAL_KNOWN_SUFFIX, "") == itemNames[i] )
				return i;
		}
		
		return -1;
	}
	
	//Excludes item categories for Silent Popup options
	//HERB
	public function silentH(container : W3Container, itemID : SItemUniqueId) : bool
	{
		return ( AutoLootConfig.HideH() && AutoLootConfig.GetFilters().IsHerb(container, itemID) );
	}
	
	//READ Text (read text only ...unread Text + all Schematics "Read/Unread" still have popup+sound)
	public function silentR(container : W3Container, itemID : SItemUniqueId) : bool
	{
		return ( AutoLootConfig.HideR() && AutoLootConfig.GetFilters().IsAlreadyRead(container, itemID) );
	}
	
	//FOOD and DRINK
	public function silentF(container : W3Container, itemID : SItemUniqueId) : bool
	{
		return ( AutoLootConfig.HideF() && AutoLootConfig.GetFilters().IsFood(container, itemID) );
	}
	
	//JUNK (shows J with the selected price and "Sea shell" = contains Black pearl) ...price=1 -> hides everything (except "Sea shell")
	public function silentJ(container : W3Container, itemID : SItemUniqueId) : bool
	{
		return ( AutoLootConfig.HideJ() && AutoLootConfig.GetFilters().IsJunk(container, itemID)
			&& container.GetInventory().GetItemName(itemID) != 'Seashell'
			&& (container.GetInventory().GetItemPrice(itemID) < AutoLootConfig.GetJPrice() || AutoLootConfig.GetJPrice() == 1) );
	}
	
	//CURRENCY (shows C with the selected price; price=1 -> hides everything)
	public function silentC(container : W3Container, itemID : SItemUniqueId) : bool
	{
		return ( AutoLootConfig.HideC() && AutoLootConfig.GetFilters().IsCurrency(container, itemID)
			&& (container.GetInventory().GetItemQuantity(itemID) < AutoLootConfig.GetCQuantity() || AutoLootConfig.GetCQuantity() == 1) );
	}
	
	//INGREDIENT (hides I with the selected quality and Bottomless carafe (endless supply of strong alcohol))
	public function silentI(container : W3Container, itemID : SItemUniqueId) : bool
	{
		return ( AutoLootConfig.HideI() && AutoLootConfig.GetFilters().IsIngredient(container, itemID)
			&& container.GetInventory().GetItemName(itemID) != 'Soltis Vodka'
			&& container.GetInventory().GetItemQuality(itemID) <= AutoLootConfig.GetIQuality() );
	}
	
	//ARMOR (hides A with the selected quality)
	public function silentA( container : W3Container, itemID : SItemUniqueId ) : bool
	{
		return ( AutoLootConfig.HideA() && AutoLootConfig.GetFilters().IsArmor(container, itemID)
			&& container.GetInventory().GetItemQuality(itemID) <= AutoLootConfig.GetAQuality() ); //hide chosen quality (=RELIC choice already hides everything)
	}
	
	//WEAPON (hides W with the selected quality)
	public function silentW( container : W3Container, itemID : SItemUniqueId ) : bool
	{
		return ( AutoLootConfig.HideW() && AutoLootConfig.GetFilters().IsWeapon(container, itemID)
			&& container.GetInventory().GetItemQuality(itemID) <= AutoLootConfig.GetWQuality() ); //hide chosen quality (=RELIC choice already hides everything)
	}
	
	//Adds an item to the list and updates all related values (the item name is stored as a formatted string)
	public function AddItem(container : W3Container, itemID : SItemUniqueId) : void
	{
		var itemIndex, count : int;
		var itemName : string;
		var soundName : name;
		
		//FIX for rare occasions where empty loot window (or its part) could appear and also hides popups with white items destroyed by Destroy function (which rather shouldn't be used at all)
		if( container.GetInventory().ItemHasTag(itemID, 'Lootable' )
			|| !container.GetInventory().ItemHasTag(itemID, 'NoDrop')
			&& !container.GetInventory().ItemHasTag(itemID, theGame.params.TAG_DONT_SHOW) )
		{
			itemName = FormatItem(container, itemID);
			count = container.GetInventory().GetItemQuantity(itemID);
			itemIndex = GetIndexByString(itemName);
			
			if( itemIndex > -1 )
			{
				itemCounts[itemIndex] += count;
			}
			else
			{
				itemNames.PushBack( itemName );
				itemCounts.PushBack( count );
				itemIcons.PushBack(container.GetInventory().GetItemIconPathByUniqueID(itemID));
				itemDescriptions.PushBack(GetLocStringByKeyExt(container.GetInventory().GetItemLocalizedDescriptionByUniqueID(itemID)));
				totalSize += 1;
			}
			
			if( AutoLootConfig.GetFilters().IsHerb(container, itemID) )
				soundName = 'herb';
			else
				soundName = container.GetInventory().GetItemCategory(itemID);
			
			if( soundCategories.FindFirst(soundName) == -1 )
				soundCategories.PushBack( soundName );
		}
	}
	
	//Returns the item name, formatted with all appropriate rarity color formatting (if applicable) and suffixes
	private function FormatItem(container : W3Container, itemID : SItemUniqueId) : string
	{
		var itemStr, rarityStr : string;
		var itemQuality, fontSize : int;
		
		itemStr = container.GetInventory().GetItemLocalizedNameByUniqueID(itemID);
		itemStr = GetLocStringByKeyExt(itemStr);
		
		if( itemStr == "" )
			itemStr = " ";
		
		itemQuality = container.GetInventory().GetItemQuality(itemID);
		rarityStr = FormatItemRarirty(itemStr, itemQuality);
		
		if( container.GetInventory().IsBookRead(itemID) )
		{
			if( AutoLootConfig.EnableColors() )
			{
				SelectMultiColor();
			
				if( container.GetInventory().IsRecipeOrSchematic(itemID) )
					rarityStr += setMulColStr + AHDAL_KNOWN_SUFFIX + "</font>";
				else if( container.GetInventory().IsItemReadable(itemID) )
					rarityStr += setMulColStr + AHDAL_READ_SUFFIX + "</font>";
			}
			else
			{
				if( container.GetInventory().IsRecipeOrSchematic(itemID) )
					rarityStr += AHDAL_KNOWN_SUFFIX;
				else if( container.GetInventory().IsItemReadable(itemID) )
					rarityStr += AHDAL_READ_SUFFIX;
			}
		}
		
		return rarityStr;
	}
	
	//Returns colored Quantity of looted items (+ popup's header + " (Known)"/" (Read)" suffix)
	public function SelectMultiColor() : string
	{
		var multiColor : int;
		
		multiColor = AutoLootConfig.GetMultiColor();
		
		switch(multiColor)
		{
			case 0: return setMulColStr = "<font color='#FFFFFF'>"; //White
			case 1: return setMulColStr = "<font color='#D8D8D8'>"; //Light Silver
			case 2: return setMulColStr = "<font color='#FFF8D1'>"; //Lemon Chiffon
			case 3: return setMulColStr = "<font color='#D5FFF2'>"; //Water
			case 4: return setMulColStr = "<font color='#95FFDB'>"; //Aquamarine
			case 5: return setMulColStr = "<font color='#FFCDBD'>"; //Apricot
			case 6: return setMulColStr = "<font color='#FBD9FB'>"; //Pink Lace
			case 7: return setMulColStr = "<font color='#BBE5FF'>"; //white-blue
			case 8: return setMulColStr = "<font color='#B0B000'>"; //Diamond
			case 9: return setMulColStr = "<font color='#FFFF00'>"; //Yellow
			case 10: return setMulColStr = "<font color='#FF9F24'>"; //Bright Yellow (Crayola)
			case 11: return setMulColStr = "<font color='#FF4500'>"; //Red-Orange (X11)
			case 12: return setMulColStr = "<font color='#FF008E'>"; //Magenta (Process)
			case 13: return setMulColStr = "<font color='#FEA9FE'>"; //Rich Brilliant Lavender
			case 14: return setMulColStr = "<font color='#7E61FF'>"; //Violets Are Blue
			case 15: return setMulColStr = "<font color='#5F29FE'>"; //Han Purple
			case 16: return setMulColStr = "<font color='#C800FF'>"; //Vivid Orchid
			case 17: return setMulColStr = "<font color='#00FFE7'>"; //Turquoise Blue
			case 18: return setMulColStr = "<font color='#64F387'>"; //Very Light Malachite Green
			case 19: return setMulColStr = "<font color='#00FF0C'>"; //Electric Green
			case 20: return setMulColStr = "<font color='#17CAFF'>"; //Capri
			case 21: return setMulColStr = "<font color='#4682B4'>"; //Steel Blue
			case 22: return setMulColStr = "<font color='#006D6C'>"; //Skobeloff
			case 23: return setMulColStr = "<font color='#A1A1A1'>"; //Quick Silver
			case 24: return setMulColStr = "<font color='#666666'>"; //Granite Gray
			case 25: return setMulColStr = "<font color='#000000'>"; //Black
		}
	}
	
	//Returns colored Common quality items (+ description)
	public function SelectCommonColor() : string
	{
		var commonColor : int;
		
		commonColor = AutoLootConfig.GetCommonColor();
		
		switch(commonColor)
		{
			case 0: return setComColStr = "<font color='#FFFFFF'>"; //White
			case 1: return setComColStr = "<font color='#D8D8D8'>"; //Light Silver
			case 2: return setComColStr = "<font color='#FFF8D1'>"; //Lemon Chiffon
			case 3: return setComColStr = "<font color='#D5FFF2'>"; //Water
			case 4: return setComColStr = "<font color='#95FFDB'>"; //Aquamarine
			case 5: return setComColStr = "<font color='#FFCDBD'>"; //Apricot
			case 6: return setComColStr = "<font color='#FBD9FB'>"; //Pink Lace
			case 7: return setComColStr = "<font color='#BBE5FF'>"; //white-blue
			case 8: return setComColStr = "<font color='#B0B000'>"; //Diamond
			case 9: return setComColStr = "<font color='#FFFF00'>"; //Yellow
			case 10: return setComColStr = "<font color='#FF9F24'>"; //Bright Yellow (Crayola)
			case 11: return setComColStr = "<font color='#FF4500'>"; //Red-Orange (X11)
			case 12: return setComColStr = "<font color='#FF008E'>"; //Magenta (Process)
			case 13: return setComColStr = "<font color='#FEA9FE'>"; //Rich Brilliant Lavender
			case 14: return setComColStr = "<font color='#7E61FF'>"; //Violets Are Blue
			case 15: return setComColStr = "<font color='#5F29FE'>"; //Han Purple
			case 16: return setComColStr = "<font color='#C800FF'>"; //Vivid Orchid
			case 17: return setComColStr = "<font color='#00FFE7'>"; //Turquoise Blue
			case 18: return setComColStr = "<font color='#64F387'>"; //Very Light Malachite Green
			case 19: return setComColStr = "<font color='#00FF0C'>"; //Electric Green
			case 20: return setComColStr = "<font color='#17CAFF'>"; //Capri
			case 21: return setComColStr = "<font color='#4682B4'>"; //Steel Blue
			case 22: return setComColStr = "<font color='#006D6C'>"; //Skobeloff
			case 23: return setComColStr = "<font color='#A1A1A1'>"; //Quick Silver
			case 24: return setComColStr = "<font color='#666666'>"; //Granite Gray
			case 25: return setComColStr = "<font color='#000000'>"; //Black
		}
	}
	
	//Returns colored Master quality items (BLUE)
	public function SelectMasterColor() : string
	{
		var masterColor : int;
		
		masterColor = AutoLootConfig.GetMasterColor();
		
		switch(masterColor)
		{
			case 0: return setMasColStr = "<font color='#3661dc'>"; //blue (Vanilla's default)
			case 1: return setMasColStr = "<font color='#367CDC'>"; //alt. 1
			case 2: return setMasColStr = "<font color='#00BFFF'>"; //alt. 2
		}
	}
	
	//Returns colored Magic quality items (YELLOW)
	public function SelectMagicColor() : string
	{
		var magicColor : int;
		
		magicColor = AutoLootConfig.GetMagicColor();
		
		switch(magicColor)
		{
			case 0: return setMagColStr = "<font color='#909000'>"; //yellow (Vanilla's default)
			case 1: return setMagColStr = "<font color='#C4C92D'>"; //alt. 1
			case 2: return setMagColStr = "<font color='#D8F135'>"; //alt. 2
		}
	}
	
	//Returns colored Relic quality items (ORANGE)
	public function SelectRelicColor() : string
	{
		var relicColor : int;
		
		relicColor = AutoLootConfig.GetRelicColor();
		
		switch(relicColor)
		{
			case 0: return setRelColStr = "<font color='#934913'>"; //orange (Vanilla's default)
			case 1: return setRelColStr = "<font color='#B25817'>"; //alt. 1
			case 2: return setRelColStr = "<font color='#FF7510'>"; //alt. 2
		}
	}
	
	//Returns colored Witcher quality items (GREEN)
	public function SelectWitcherColor() : string
	{
		var witcherColor : int;
		
		witcherColor = AutoLootConfig.GetWitcherColor();
		
		switch(witcherColor)
		{
			case 0: return setWitchColStr = "<font color='#197319'>"; //green (Vanilla's default)
			case 1: return setWitchColStr = "<font color='#019A01'>"; //alt. 1
			case 2: return setWitchColStr = "<font color='#00AA00'>"; //alt. 2
		}
	}
	
	//Returns the string formatted with the specified rarity color
	private function FormatItemRarirty(itemStr : string, quality : int) : string
	{
		if( AutoLootConfig.EnableColors() )
		{
			switch(quality)
			{
				case 1: SelectCommonColor(); return setComColStr + itemStr + "</font>"; //def.: color 0 (black): #000000
				case 2: SelectMasterColor(); return setMasColStr + itemStr + "</font>"; //def. color 1 (blue): #3661dc
				case 3: SelectMagicColor(); return setMagColStr + itemStr + "</font>"; //def. color 2 (yellow): #909000
				case 4: SelectRelicColor(); return setRelColStr + itemStr + "</font>"; //def. color 3 (orange): #934913
				case 5: SelectWitcherColor(); return setWitchColStr + itemStr + "</font>"; //def. color 4 (green): #197319
				default: return itemStr;
			}
		}
		
		return itemStr;
	}
	
	//Returns the formatted array with font size and quantities based on user.settings
	private function FormatItemList(countToProcess : int) : array<string>
	{
		var temp : array<string>;
		var i : int;
		
		for ( i=0; i<countToProcess; i+=1 )
		{
			if( AutoLootConfig.EnableNotificationQuantity() )
			{
				if( itemCounts[i] > 1 )
				{
					if( AutoLootConfig.EnableColors() )
					{
						SelectMultiColor();
						temp.PushBack("<font size='" + GetNotificationFontSize() + "'>" + itemNames[i] + setMulColStr + " x" + itemCounts[i] + "</font>");
					}
					else
					{
						temp.PushBack("<font size='" + GetNotificationFontSize() + "'>" + itemNames[i] + " x" + itemCounts[i] + "</font>");
					}
				}
				else
					temp.PushBack("<font size='" + GetNotificationFontSize() + "'>" + itemNames[i] + "</font>");
			}
			else
			{
				temp.PushBack("<font size='" + GetNotificationFontSize() + "'>" + itemNames[i] + "</font>");
			}
		}
		
		return temp;
	}
	
	//Returns the formatted image for the specified item index
	private function FormatLootIcon(index : int) : string
	{
		var temp : string;
		temp = "";
		
		if( AutoLootConfig.EnableNotificationImage() )
			temp += "<img src='img://" + itemIcons[index] + "' height='" + GetNotificationFontSize() + "' width='" + GetNotificationFontSize() + "' vspace='-10' />&nbsp;";
		
		return temp;
	}
	
	//Returns the item description for the specified index
	private function GetLootDesc(index : int) : string
	{
		var temp : string;
		temp = "";
		
		if( AutoLootConfig.EnableNotificationDescription() && (itemDescriptions[index] != "" || itemDescriptions[index] != " ") )
		{
			if( AutoLootConfig.EnableColors() )
			{
				SelectCommonColor();
				
				temp += "<br/><font size='" + (GetNotificationFontSize()-6) + "'>" + setComColStr + itemDescriptions[index] + "</font>";
			}
			else
			{
				temp += "<br/><font size='" + (GetNotificationFontSize()-6) + "'>" + itemDescriptions[index] + "</font>";
			}
		}
		
		return temp;
	}
	
	//Returns the formatted notification message based on all items and appropriate user.settings options, removes displayed items from array front
	private function FormatNotification(combat : bool, out processedCount : int) : string
	{
		var itemList : array<string>;
		var i, limit : int;
		var msg : string;
		
		msg = "";
		processedCount = 0;
		
		if( !AutoLootConfig.IsModLoaded() )
			return GetLocStringByKeyExt("ahdal_menuErrorMsg");
		
		if( GetNotificationFontSize() < 1 )
			return GetLocStringByKeyExt("ahdal_fontErrorMsg");
		
		if( itemNames.Size() <= 0 )
			return msg;
		
		limit = AutoLootConfig.GetLootPopupMaxItems();
		if( limit <= 0 )
			limit = 30;
			
		if( itemNames.Size() < limit )
			processedCount = itemNames.Size();
		else
			processedCount = limit;
		
		itemList = FormatItemList(processedCount);
		
		msg += "<font size='" + GetNotificationFontSize() + "'>" + GetNotificationHeader(combat) + "</font>";
		
		for ( i=0; i<processedCount; i+=1 )
		{
			if( AutoLootConfig.EnableNotificationItemCounts() )
				msg += "<font color='#666666'><font size='" + GetNotificationFontSize() + "'>" + (totalItemsProcessed + i + 1) + ". " + FormatLootIcon(i) + itemList[i] + "</font>";
			else
				msg += FormatLootIcon(i) + itemList[i];
			
			msg += GetLootDesc(i);
			
			if( i+1 < processedCount )
				msg += "<br/>";
		}
		
		//Enhanced TEST message for autoloot popup
		/*
		if( totalSize <= limit  )
			msg = "<font color='#666666'>" + ">> Items (1-" + processedCount + ")" + "<br/>" + msg + "</font>";
		else if( helperSecond == 0 && HasMoreItemsInQueue() )
			msg = "<font color='#B0B000'>" + ">> Split popup: Items (1-" + processedCount + " of " + totalSize + ")" + "<br/>" + msg + "</font>";
		else if( SecondPageInProgress() ) //same as: helperSecond == 1 && HasMoreItemsInQueue()
			msg = "<font color='#FF4500'>" + ">> Split popup: Items (" + (totalItemsProcessed + 1) + "-" + (totalItemsProcessed + processedCount) + " of " + totalSize + ")" + "<br/>" + msg + "</font>";
		*/
		
		//Erase processed items from memory
		for ( i=0; i<processedCount; i+=1 )
		{
			itemNames.Erase(0);
			itemCounts.Erase(0);
			itemIcons.Erase(0);
			itemDescriptions.Erase(0);
		}
		
		totalItemsProcessed += processedCount;
		
		return msg;
	}
	
	//Plays the appropriate sound based on what items have been looted
	private function PlayAutoLootSound() : void
	{
		if( AutoLootConfig.EnableLootSound() )
		{
			if( soundCategories.Size() > 0 )
			{
				if( soundCategories.Size() == 1 )
					PlayItemEquipSound(soundCategories[0]);
				else
					PlayItemEquipSound('generic');
			}
		}
	}
	
	//Checks if the time delay from the last loot popup has passed
	private function IsLastNotificationDelayOver() : bool
	{
		currentTime = theGame.GetEngineTimeAsSeconds();
		
		return currentTime >= (lastNotificationTime + timeDelay);
	}
	
	//Checks if more items remain to be displayed in subsequent loot popup windows
	private function HasMoreItemsInQueue() : bool
	{
		return itemNames.Size() > 0;
	}
	
	//Checks if sequential loot popup queue is currently active
	public function SecondPageInProgress() : bool
	{
		return HasMoreItemsInQueue() && helperSecond == 1;
	}
	
	//Shows subsequent loot popups in queue after set delay time if you looted more items than is set in 'Maximum Items in Each Loot Popup Window' option
	public function ShowSecondPopupDelayed() : void
	{
		var chunkMsg : string;
		var countDisplayed : int;
		
		//Enforce time delay check before displaying subsequent popup chunk
		if( SecondPageInProgress() && IsLastNotificationDelayOver() )
		{
			chunkMsg = FormatNotification(false, countDisplayed);
			
			if( chunkMsg != "" )
			{
				theGame.GetGuiManager().ShowAASNotification( chunkMsg, GetTotalNotificationTimeForCount(countDisplayed) );
				lastNotificationTime = currentTime;
				PlayAutoLootSound();
			}
			
			//If overflow items accumulated in the queue, schedule next delayed popup cycle
			if( HasMoreItemsInQueue() )
			{
				GetWitcherPlayer().AddTimer('AutoLootShowSecondPopupTimer', timeDelay, false);
			}
			else
			{
				Reset();
			}
		}
	}
	
	//Returns the total time to display the loot notification based on user.settings
	private function GetTotalNotificationTimeForCount(count : int) : float 
	{ 
		return GetNotificationTime() + (GetNotificationTimeAddPerItem() * count); 
	}
	
	//Displays the loot notification if applicable; resets once full queue is processed
	public function ShowNotification(optional combat : bool) : void
	{
		var actionRadius, actionRadiusHold : SInputAction;
		var chunkMsg : string;
		var countDisplayed : int;
		var isManualTrigger : bool;
		
		actionRadius.value = theInput.GetActionValue('AutoLootRadius');
		actionRadius.lastFrameValue = 0;
		actionRadiusHold.value = theInput.GetActionValue('AutoLootRadiusHold');
		actionRadiusHold.lastFrameValue = 0;
		
		if( ( !thePlayer.IsInCombat() || (thePlayer.IsInCombat() && !AutoLootConfig.HideNotificationInCombat()) )
			&& itemNames.Size() > 0 )
		{
			if( AutoLootConfig.NotificationsEnabled() )
			{
				E_KEY_Logic = AutoLootConfig.GetEkeyLogic();
				
				//Manual press detection (Radius/E key) overriding the time delay
				isManualTrigger = IsPressed(actionRadius) || IsPressed(actionRadiusHold) || (AutoLootConfig.GetFeatureManager().GetInteractionKeyContainerType() > 0);
				
				//Manual looting can bypass the previous popup delay; queued notifications retain the delay.
				if( isManualTrigger || IsLastNotificationDelayOver() )
				{
					if( helperSecond == 0 )
					{
						timeDelay = 4.0f; //time delay between Autoloot popups for Interaction key ('E') or Radius Looting key is fixed to 4s
						
						chunkMsg = FormatNotification(combat, countDisplayed);
						theGame.GetGuiManager().ShowAASNotification( chunkMsg, GetTotalNotificationTimeForCount(countDisplayed) );
						
						lastNotificationTime = theGame.GetEngineTimeAsSeconds();
						PlayAutoLootSound();
						
						if( HasMoreItemsInQueue() )
						{
							helperSecond = 1;
							GetWitcherPlayer().AddTimer('AutoLootShowSecondPopupTimer', timeDelay, false); //trigger timer for next loot popup
						}
						else
						{
							helperSecond = 0;
							totalSize = 0;
							totalItemsProcessed = 0;
						}
					}
					else
					{
						ShowSecondPopupDelayed();
					}
				}
			}
		}
	}
	
	//Returns font size from menu settings (with error checking)
	private function GetNotificationFontSize() : int
	{
		var fontSize : int;
		
		fontSize = AutoLootConfig.GetNotificationFS();
		
		if( fontSize < 14 || fontSize > 34 )
			return -1;
		
		return fontSize;
	}
	
	//Returns how long to display loot notifications (in ms)
	private function GetNotificationTime() : float
	{
		return AutoLootConfig.GetNotificationT();
	}
	
	//Returns extra amount of time to display the notification per item looted (in ms)
	private function GetNotificationTimeAddPerItem() : float
	{
		if( AutoLootConfig.EnableNotificationDescription() )
			return AutoLootConfig.GetNotificationTApI() * 2;
		
		return AutoLootConfig.GetNotificationTApI();
	}
	
	//Returns the notification header for loot messages
	private function GetNotificationHeader(combat : bool) : string
	{
		if( AutoLootConfig.UseNewNotification() )
		{
			if( AutoLootConfig.EnableColors() )
			{
				SelectMultiColor();
				
				if( combat )
					return setMulColStr + GetLocStringByKeyExt("ahdal_lootHeaderCombat") + "</font>" + "<br/>";
				else
					return setMulColStr+ GetLocStringByKeyExt("ahdal_lootHeader") + "</font>" + "<br/>";
			}
			else
			{
				if( combat )
					return GetLocStringByKeyExt("ahdal_lootHeaderCombat") + "<br/>";
				else
					return GetLocStringByKeyExt("ahdal_lootHeader") + "<br/>";
			}
		}
		
		return "";
	}
	
	//Returns all values prior to being reset; used by console command
	public function DebugReset() : array<float>
	{
		var temp : array<float>;
		
		temp.PushBack(itemNames.Size());
		temp.PushBack(itemCounts.Size());
		temp.PushBack(itemIcons.Size());
		temp.PushBack(itemDescriptions.Size());
		temp.PushBack(soundCategories.Size());
		temp.PushBack(totalSize);
		temp.PushBack(helperSecond);
		
		Reset();
		
		return temp;
	}
}