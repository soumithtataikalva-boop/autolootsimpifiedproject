/***********************************************************************/
/** 	AHDAutoLootConfig.ws
/** 	by AeroHD
/**		Original AutoLoot code by JupiterTheGod
/**		mod: AutoLoot Advanced Settings (AutoLoot +A.S.) by jerry18
/***********************************************************************/



class CAHDAutoLootConfig
{
	private var UserSettings : CInGameConfigWrapper;
	private var actions : CAHDAutoLootActions;
	private var features : CAHDAutoLootFeatureManager;
	private var filters : CAHDAutoLootFilters;
	private var notifications : CAHDAutoLootNotificationManager;
	private	var shortcuts : AutoLootShortcuts;
	
	private const var 	currentModVersion : int;
				
				default currentModVersion = 5001; //besides here, this is also used in AHDAutoLootConfig.xml file
	
	private var		modEnabled,
					useNoAccidentalStealing,
					disableStealing,
					useIsCorpse,
					useIsDropped,
					useQuantity,
					useFilters,
					useIsHerb,
					useIsArmor,
					useIsWeapon,
					useIsIngredient,
					useIsJunk,
					useIsReadable,
					useIsAlreadyRead,
					useIsMoney,
					useIsFood,
					useIsUpgrade,
					useIsHorse,
					useIsTrophy,
					useIsTool,
					useIsOther,
					useIsFormula,
					useIsMask,
					useIsKey : bool;
					
	
	private var		DestroyWhiteWALogic,
					chosenHerbQuantity,
					chosenArmorQuality,
					chosenArmorValue,
					chosenWeaponQuality,
					chosenWeaponValue,
					chosenIngredientQuality,
					chosenIngredientValue,
					chosenIngredientQuantity,
					chosenJunkQuality,
					chosenJunkValue,
					chosenJunkQuantity,
					chosenBookQuantity,
					chosenCurrencyQuantity,
					chosenFoodValue,
					chosenFoodQuantity,
					chosenUpgradeValue,
					chosenHorseValue,
					chosenTrophyValue,
					chosenToolValue,
					chosenOtherValue,
					
					quantityAmount,
					quantityLogic : int;
	
	private const var 	AHDAL_COMPARE_LESS,
						AHDAL_COMPARE_EQUAL,
						AHDAL_COMPARE_GREATER	: int;
				
				default AHDAL_COMPARE_LESS = 0;
				default AHDAL_COMPARE_EQUAL = 1;
				default AHDAL_COMPARE_GREATER = 2;
	
	private var		modInitalized,
					modLoaded_base				: bool;
			
			default modInitalized = false;
			default modLoaded_base = false;
	
	//Initializes all parts of the mod, with listeners and some error checking
	public function Init() : void
	{
		var displayMsg : bool;
		
		displayMsg = false;
		UserSettings = theGame.GetInGameConfigWrapper();
		
		actions = new CAHDAutoLootActions in this;
		actions.Init();
		features = new CAHDAutoLootFeatureManager in this;
		features.Init();
		filters = new CAHDAutoLootFilters in this;
		filters.Init();
		notifications = new CAHDAutoLootNotificationManager in this;
		notifications.Init();
		notifications.Reset();
		shortcuts = new AutoLootShortcuts in this;
		shortcuts.Init();
		shortcuts.InitRange();
		
		TryFullReset();
		
		//AutoLoot mod resets to default setting if the mod was updated
		if( ModVersionSettings() != currentModVersion )
		{
			LoadDefaultSettings();
			displayMsg = true;
		}
		
		GetAutoLootSettings();
		NormalizeRadiusShortcuts();
		
		modInitalized = true;
		
		if( displayMsg )
			DisplayWelcomeMsg();
		
		GetWitcherPlayer().UpdateEncumbrance();
	}
	
	//Map legacy shortcut choices to the remaining radius-only options.
	private function NormalizeRadiusShortcuts() : void
	{
		var threshold : int;
		threshold = GetSettingAsInt( 'AutoLoot_shortcuts', 'disableShortcutsThreshold' );
		if( threshold == 2 || threshold == 3 )
		{
			UserSettings.SetVarValue( 'AutoLoot_shortcuts', 'disableShortcutsThreshold', threshold - 2 );
			theGame.SaveUserSettings();
		}
	}
	
	//Determines if the menu settings were saved, and that it matches the current version
	public function IsModLoaded() : bool
	{
		if( ModVersionSettings() == currentModVersion )
			modLoaded_base = true;
		//else
		//	modLoaded_base = false; //no need since it is default value
		
		return ( modInitalized && modLoaded_base );
	}
	
	//Displays the appropriate welcome (or error) message when the mod is loaded/reset
	private function DisplayWelcomeMsg()
	{
		if( !IsModLoaded() )
		{
			GetWitcherPlayer().DisplayHudMessage( GetLocStringByKeyExt("ahdal_menuErrorMsg") );
			theGame.GetGuiManager().ShowNotification(( GetLocStringByKeyExt("ahdal_menuErrorMsg") ), 15000);
		}
		else
		{
			GetWitcherPlayer().DisplayHudMessage( GetLocStringByKeyExt("ahdal_defaultLoadedMsg") );
			//theGame.GetGuiManager().ShowNotification(( GetLocStringByKeyExt("ahdal_defaultLoadedMsg") ), 3000);
		}
	}
	
	//Sets all default values in user.settings and saves it
	private function LoadDefaultSettings()
	{
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useAutoLoot', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useNoAccidentalStealing', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'disableStealing', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'enableOnKillLoot', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'questItemWarningMsg', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'forceQuestLoot', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'fullReset', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'modVersionUserSettings', currentModVersion );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_filters_global', 'noWitcherSchematics', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters_global', 'noSpecialContainers', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters_global', 'noTrophies', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters_global', 'noHerbsCorvoBianco', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters_global', 'noBeehives', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters_global', 'noDropItems', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters_global', 'noHorseLoot', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters_global', 'DestroyWhiteLogicWA', 0 );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useIsCorpse', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useIsDropped', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useQuantity', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'quantityAmount', 15 );
		UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'Virtual_quantityLogic', 0 );
		
		UserSettings.SetVarValue( 'InteractionKey', 'interactionKey_lootLogic', 0 );
		UserSettings.SetVarValue( 'InteractionKey', 'interactionKeyMaxDistance', 5 );
		UserSettings.SetVarValue( 'InteractionKey', 'interactionKeyMaxDistanceHerbs', 15 );
		UserSettings.SetVarValue( 'InteractionKey', 'interactionKeyMaxContainers', 25 );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useFilters', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsHerb', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenHerbQuantity', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsArmor', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenArmorQuality', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenArmorValue', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsWeapon', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenWeaponQuality', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenWeaponValue', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsIngredient', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenIngredientQuality', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenIngredientValue', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenIngredientQuantity', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsJunk', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenJunkQuality', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenJunkValue', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenJunkQuantity', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsReadable', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsAlreadyRead', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenBookQuantity', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsMoney', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenCurrencyQuantity', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFood', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenFoodQuantity', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenFoodValue', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsUpgrade', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenUpgradeValue', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsHorse', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenHorseValue', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsTrophy', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenTrophyValue', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsTool', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenToolValue', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsOther', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'chosenOtherValue', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFormula', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsMask', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsKey', "false" );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_radius', 'radiusLootIgnoreFilters', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_radius', 'enableRadiusLootCombat', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_radius', 'radiusLootMaxDistance', 10 );
		UserSettings.SetVarValue( 'AHDAutoLoot_radius', 'radiusMaxContainers', 25 );
		
		
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'enableNotification', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'DEFpopupBlack', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'AASpopupBlack', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'PopupOpacity', 50 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'textOutline', 3 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'notificationFontSize', 23 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'PopupPosX', 100 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'PopupPosY', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'AASpopupWidthMax', 175 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'BookPopupPosX', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'BookPopupPosY', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'multiColor', 18 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'commonColor', 7 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'masterColor', 1 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'magicColor', 1 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'relicColor', 1 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'witcherColor', 1 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'useNewNotification', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'useNotificationDesc', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'useNotificationItemCounts', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'lootPopupMaxItems', 30 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'useNotificationQuantity', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'enableLootSound', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'enableColors', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'useNotificationImage', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'hideNotificationCombat', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'showLootAL', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'notificationTime', 5 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'notificationTimeAddPerItem', 150 );
		
		UserSettings.SetVarValue( 'AutoLoot_shortcuts', 'disableShortcutsThreshold', 0 );
		UserSettings.SetVarValue( 'AutoLoot_shortcuts', 'radiusShortcutsStep', 2 );
		UserSettings.SetVarValue( 'AutoLoot_shortcuts', 'altShortcuts', "false" );
		UserSettings.SetVarValue( 'AutoLoot_shortcuts', 'radiusLootDistanceOne', 5 );
		UserSettings.SetVarValue( 'AutoLoot_shortcuts', 'radiusLootDistanceTwo', 10 );
		UserSettings.SetVarValue( 'AutoLoot_shortcuts', 'radiusLootDistanceThree', 30 );
		
		UserSettings.SetVarValue( 'AutoLoot_popups', 'SP_E_key_Logic', 1 );
		UserSettings.SetVarValue( 'AutoLoot_popups', 'NoPopH', "false" );
		UserSettings.SetVarValue( 'AutoLoot_popups', 'NoPopI', "true" );
		UserSettings.SetVarValue( 'AutoLoot_popups', 'IngredientQualitySPLogic', 0 );
		UserSettings.SetVarValue( 'AutoLoot_popups', 'NoPopR', "false" );
		UserSettings.SetVarValue( 'AutoLoot_popups', 'NoPopF', "false" );
		UserSettings.SetVarValue( 'AutoLoot_popups', 'NoPopJ', "false" );
		UserSettings.SetVarValue( 'AutoLoot_popups', 'priceJunk', 150 );
		UserSettings.SetVarValue( 'AutoLoot_popups', 'NoPopC', "false" );
		UserSettings.SetVarValue( 'AutoLoot_popups', 'quantityCurrency', 100 );
		UserSettings.SetVarValue( 'AutoLoot_popups', 'NoPopA', "true" );
		UserSettings.SetVarValue( 'AutoLoot_popups', 'AQualitySPLogic', 0 );
		UserSettings.SetVarValue( 'AutoLoot_popups', 'NoPopW', "true" );
		UserSettings.SetVarValue( 'AutoLoot_popups', 'WQualitySPLogic', 0 );
		
		theGame.SaveUserSettings();
	}
	
	//Does a full reset of all settings if the option is enabled (from closing the menu)
	public function TryFullReset() : void
	{
		if( EnableFullReset() )
		{
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'fullReset', "false" );
			
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'modVersionUserSettings', 0 );
			
			theGame.SaveUserSettings();
			
			thePlayer.AddTimer('InitAHDAutoLoot', 1.0);
		}
	}
	
	//Checks if we can loot the container based on stealing options
	private function GetStealingLogic(container : W3Container) : bool
	{
		if( disableStealing )			{ return true; }
		if( useNoAccidentalStealing )	{ return filters.IsNotStealing(container); }
		
		return true;
	}
	
	//Checks what type the container is and if we can loot it
	private function GetContainerLogic(container : W3Container) : bool
	{
		var temp1, temp2 : bool;
		temp1 = false;
		temp2 = false;
		
		if( useIsCorpse )	{ temp1 = filters.IsCorpse(container); }
		if( useIsDropped ) 	{ temp2 = filters.IsDropped(container); }
		
		if( !useIsCorpse && !useIsDropped )
			return true;
		
		return ( temp1 || temp2 );
	}
	
	//Checks how many items are in the container with the selected menu options
	public function GetQuantityLogic(count : int) : bool
	{
		if( useQuantity )
		{
			if( quantityLogic == AHDAL_COMPARE_LESS )		{ return ( count <= quantityAmount ); }
			if( quantityLogic == AHDAL_COMPARE_EQUAL )		{ return ( count == quantityAmount ); }
			if( quantityLogic == AHDAL_COMPARE_GREATER )	{ return ( count >= quantityAmount ); }
		}
		
		return false;
	}
	
	//Returns if the specified item can be looted from the container based on menu configuration
	public function AutoLootLogic(container : W3Container, itemID : SItemUniqueId, count : int) : bool
	{
		var itemName : name;
		var actionRadiusHold : SInputAction;
		
		itemName = container.GetInventory().GetItemName(itemID);
		actionRadiusHold.value = theInput.GetActionValue('AutoLootRadiusHold');
		actionRadiusHold.lastFrameValue = 0;
		
		GetAutoLootSettings();
		
		if( modEnabled )
		{
			//Added new option to hide=destroy white quality Weapons/Armors (EXPERIMENTAL!)
			if( DestroyWhiteWALogic == 1 || DestroyWhiteWALogic == 2 )
			{
				if( (container.GetInventory().IsItemWeapon(itemID) || container.GetInventory().IsItemAnyArmor(itemID)) &&
					(container.GetInventory().GetItemQuality(itemID) == 1)
					//Below are FIXED white Weapons/Armors excluded from "Destroy..." function
					&& !StrContains(NameToString(itemName), "Witcher Silver Sword") //Starting silver sword (Witcher Silver Sword)
					&& !StrContains(NameToString(itemName), "Starting Armor") //Starting Armor (Kaer Morhen armor)
					&& !StrContains(NameToString(itemName), "Geralt Shirt") //Shirt (part of crafting recipes)
					&& !StrContains(NameToString(itemName), "Casual") ) //this line should be (only?) story related white Weapons/Armors items
				{
				//A) "Destroy..." function = ON with exceptions (Optional white Weapons/Armors are excluded from "Destroy..." function)
					if( DestroyWhiteWALogic == 1)
					{
						if( !container.GetInventory().ItemHasTag(itemID, 'crossbow') ) //Crossbows (OPTIONAL)
							container.GetInventory().AddItemTag(itemID, theGame.params.TAG_DONT_SHOW);
					}
				//B) "Destroy..." function = ON (Optional white Weapons/Armors are destroyed too by "Destroy..." function)
					else //no need: if( DestroyWhiteWALogic == 2)
					{
						container.GetInventory().AddItemTag(itemID, theGame.params.TAG_DONT_SHOW);
					}
				}
			}
			
			if( useFilters && (!RadiusLootIgnoreFilters() || !IsPressed(actionRadiusHold)) 
				&& GetFeatureManager().GetInteractionKeyContainerType() <= 0 ) //excludes Filters when E is pressed
			{
				if( ( !useIsCorpse || !filters.IsCorpse(container) )
					&& ( !useIsDropped || !filters.IsDropped(container) )
					&& !useQuantity )
				{
					return ( (( filters.IsHerbQt(container, itemID) && useIsHerb )
						|| ( filters.IsArmorQV(container, itemID) && useIsArmor )
						|| ( filters.IsWeaponQV(container, itemID) && useIsWeapon )
						|| ( filters.IsIngredientQVQt(container, itemID) && useIsIngredient )
						|| ( filters.IsJunkQVQt(container, itemID) && useIsJunk )
						|| ( filters.IsBookQt(container, itemID) && (useIsReadable || useIsAlreadyRead) )
						|| ( filters.IsCurrencyQt(container, itemID) && useIsMoney )
						|| ( filters.IsFoodVQt(container, itemID) && useIsFood )
						|| ( filters.IsUpgradeV(container, itemID) && useIsUpgrade )
						|| ( filters.IsHorseV(container, itemID) && useIsHorse )
						|| ( filters.IsTrophyV(container, itemID) && useIsTrophy )
						|| ( filters.IsToolV(container, itemID) && useIsTool )
						|| ( filters.IsOtherV(container, itemID) && useIsOther )
						|| ( filters.IsFormula(container, itemID) && useIsFormula )
						|| ( filters.IsMask(container, itemID) && useIsMask )
						|| ( filters.IsKey(container, itemID) && useIsKey ))
						&& GetStealingLogic(container) );
				}
				else if( (( useIsCorpse && filters.IsCorpse(container) )
					|| ( useIsDropped && filters.IsDropped(container) ))
					&& !useQuantity )
				{
					return ( ( GetContainerLogic(container)
						|| ( filters.IsHerbQt(container, itemID) && useIsHerb )
						|| ( filters.IsArmorQV(container, itemID) && useIsArmor )
						|| ( filters.IsWeaponQV(container, itemID) && useIsWeapon )
						|| ( filters.IsIngredientQVQt(container, itemID) && useIsIngredient )
						|| ( filters.IsJunkQVQt(container, itemID) && useIsJunk )
						|| ( filters.IsBookQt(container, itemID) && (useIsReadable || useIsAlreadyRead) )
						|| ( filters.IsCurrencyQt(container, itemID) && useIsMoney )
						|| ( filters.IsFoodVQt(container, itemID) && useIsFood )
						|| ( filters.IsUpgradeV(container, itemID) && useIsUpgrade )
						|| ( filters.IsHorseV(container, itemID) && useIsHorse )
						|| ( filters.IsTrophyV(container, itemID) && useIsTrophy )
						|| ( filters.IsToolV(container, itemID) && useIsTool )
						|| ( filters.IsOtherV(container, itemID) && useIsOther )
						|| ( filters.IsFormula(container, itemID) && useIsFormula )
						|| ( filters.IsMask(container, itemID) && useIsMask )
						|| ( filters.IsKey(container, itemID) && useIsKey ))
						&& GetStealingLogic(container) );
				}
				else if( ( (useIsCorpse && filters.IsCorpse(container) )
					|| ( useIsDropped && filters.IsDropped(container) ))
					&& useQuantity )
				{
					return ( ( GetContainerLogic(container)
						|| GetQuantityLogic(count)
						|| ( filters.IsHerbQt(container, itemID) && useIsHerb )
						|| ( filters.IsArmorQV(container, itemID) && useIsArmor )
						|| ( filters.IsWeaponQV(container, itemID) && useIsWeapon )
						|| ( filters.IsIngredientQVQt(container, itemID) && useIsIngredient )
						|| ( filters.IsJunkQVQt(container, itemID) && useIsJunk )
						|| ( filters.IsBookQt(container, itemID) && (useIsReadable || useIsAlreadyRead) )
						|| ( filters.IsCurrencyQt(container, itemID) && useIsMoney )
						|| ( filters.IsFoodVQt(container, itemID) && useIsFood )
						|| ( filters.IsUpgradeV(container, itemID) && useIsUpgrade )
						|| ( filters.IsHorseV(container, itemID) && useIsHorse )
						|| ( filters.IsTrophyV(container, itemID) && useIsTrophy )
						|| ( filters.IsToolV(container, itemID) && useIsTool )
						|| ( filters.IsOtherV(container, itemID) && useIsOther )
						|| ( filters.IsFormula(container, itemID) && useIsFormula )
						|| ( filters.IsMask(container, itemID) && useIsMask )
						|| ( filters.IsKey(container, itemID) && useIsKey ))
						&& GetStealingLogic(container) );
				}
				else if( ( !useIsCorpse || !filters.IsCorpse(container) )
					&& ( !useIsDropped || !filters.IsDropped(container) )
					&& useQuantity )
				{
					return ( ( GetQuantityLogic(count)
						|| ( filters.IsHerbQt(container, itemID) && useIsHerb )
						|| ( filters.IsArmorQV(container, itemID) && useIsArmor )
						|| ( filters.IsWeaponQV(container, itemID) && useIsWeapon )
						|| ( filters.IsIngredientQVQt(container, itemID) && useIsIngredient )
						|| ( filters.IsJunkQVQt(container, itemID) && useIsJunk )
						|| ( filters.IsBookQt(container, itemID) && (useIsReadable || useIsAlreadyRead) )
						|| ( filters.IsCurrencyQt(container, itemID) && useIsMoney )
						|| ( filters.IsFoodVQt(container, itemID) && useIsFood )
						|| ( filters.IsUpgradeV(container, itemID) && useIsUpgrade )
						|| ( filters.IsHorseV(container, itemID) && useIsHorse )
						|| ( filters.IsTrophyV(container, itemID) && useIsTrophy )
						|| ( filters.IsToolV(container, itemID) && useIsTool )
						|| ( filters.IsOtherV(container, itemID) && useIsOther )
						|| ( filters.IsFormula(container, itemID) && useIsFormula )
						|| ( filters.IsMask(container, itemID) && useIsMask )
						|| ( filters.IsKey(container, itemID) && useIsKey ))
						&& GetStealingLogic(container) );
				}
				
				return false;
			}
			
			return GetStealingLogic(container);
		}
		
		return false;
	}
	
	//Loads all relevant menu settings into local variables
	private function GetAutoLootSettings()
	{
		modEnabled					= UserSettings.GetVarValue( 'AHDAutoLoot_settings', 'useAutoLoot' );
		useNoAccidentalStealing		= UserSettings.GetVarValue( 'AHDAutoLoot_settings', 'useNoAccidentalStealing' );
		disableStealing				= UserSettings.GetVarValue( 'AHDAutoLoot_settings', 'disableStealing' );
		
		DestroyWhiteWALogic			= StringToInt(UserSettings.GetVarValue( 'AHDAutoLoot_filters_global', 'DestroyWhiteLogicWA' ));
		
		useIsCorpse					= UserSettings.GetVarValue( 'AHDAutoLoot_containers', 'useIsCorpse' );
		useIsDropped				= UserSettings.GetVarValue( 'AHDAutoLoot_containers', 'useIsDropped' );
		useQuantity					= UserSettings.GetVarValue( 'AHDAutoLoot_containers', 'useQuantity' );
		quantityLogic				= StringToInt(UserSettings.GetVarValue( 'AHDAutoLoot_containers', 'Virtual_quantityLogic' ));
		quantityAmount				= StringToInt(UserSettings.GetVarValue( 'AHDAutoLoot_containers', 'quantityAmount' ));
		
		useFilters					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useFilters' );
		useIsHerb					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsHerb' );
		useIsArmor					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsArmor' );
		useIsWeapon					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsWeapon' );
		useIsIngredient				= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsIngredient' );
		useIsJunk					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsJunk' );
		useIsReadable				= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsReadable' );
		useIsAlreadyRead			= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsAlreadyRead' );
		useIsMoney					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsMoney' );
		useIsFood					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsFood' );
		useIsUpgrade				= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsUpgrade' );
		useIsHorse					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsHorse' );
		useIsTrophy					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsTrophy' );
		useIsTool					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsTool' );
		useIsOther					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsOther' );
		useIsFormula				= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsFormula' );
		useIsMask					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsMask' );
		useIsKey					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsKey' );
		
	}
	
	public function GetFeatureManager() : CAHDAutoLootFeatureManager { return features; }
	public function GetFilters() : CAHDAutoLootFilters { return filters; }
	public function GetActions() : CAHDAutoLootActions { return actions; }
	public function GetNotifications() : CAHDAutoLootNotificationManager { return notifications; }
	//public function GetShortcuts() : AutoLootShortcuts { return shortcuts; }
	
	public function ModEnabled() : bool { return SettingEnabled( 'AHDAutoLoot_settings', 'useAutoLoot' ); }
	public function NoAccidentalStealingEnabled() : bool { if( SettingEnabled( 'AHDAutoLoot_settings', 'disableStealing' ) ) return false; return SettingEnabled( 'AHDAutoLoot_settings', 'useNoAccidentalStealing' ); }
	public function StealingDisabled() : bool { return SettingEnabled( 'AHDAutoLoot_settings', 'disableStealing' ); }
	public function LootOnKillEnabled() : bool { return SettingEnabled( 'AHDAutoLoot_settings', 'enableOnKillLoot' ); }
	public function QuestItemWarningMsg() : bool { return SettingEnabled( 'AHDAutoLoot_settings', 'questItemWarningMsg' ); }
	public function ForceQuestLoot() : bool { return SettingEnabled( 'AHDAutoLoot_settings', 'forceQuestLoot' ); }
	public function EnableFullReset() : bool { return SettingEnabled( 'AHDAutoLoot_settings', 'fullReset' ); }
	public function ModVersionSettings() : int { return GetSettingAsInt( 'AHDAutoLoot_settings', 'modVersionUserSettings' ); }
	
	public function ProtectWitcherSchematics() : bool { return SettingEnabled( 'AHDAutoLoot_filters_global', 'noWitcherSchematics' ); }
	public function ProtectSpecialContainers() : bool { return SettingEnabled( 'AHDAutoLoot_filters_global', 'noSpecialContainers' ); }
	public function ProtectTrophies() : bool { return SettingEnabled( 'AHDAutoLoot_filters_global', 'noTrophies' ); }
	public function ProtectHerbsCorvoBianco() : bool { return SettingEnabled( 'AHDAutoLoot_filters_global', 'noHerbsCorvoBianco' ); }
	public function ProtectBeehives() : bool { return SettingEnabled( 'AHDAutoLoot_filters_global', 'noBeehives' ); }
	public function ProtectDroppedItems() : bool { return SettingEnabled( 'AHDAutoLoot_filters_global', 'noDropItems' ); }
	public function NoHorseLooting() : bool { return SettingEnabled( 'AHDAutoLoot_filters_global', 'noHorseLoot' ); }
	//public function GetWhiteWADestructionLogic() : int { return GetSettingAsInt( 'AHDAutoLoot_filters_global', 'DestroyWhiteLogicWA' ); }
	
	public function UseCorpseFilter() : bool { return SettingEnabled( 'AHDAutoLoot_containers', 'useIsCorpse' ); }
	public function UseDroppedFilter() : bool { return SettingEnabled( 'AHDAutoLoot_containers', 'useIsDropped' ); }
	public function UseQuantityFilter() : bool { return SettingEnabled( 'AHDAutoLoot_containers', 'useQuantity' ); }
	public function ChosenQuantity() : int { return GetSettingAsInt( 'AHDAutoLoot_containers', 'quantityAmount' ); }
	public function ChosenQuantityLogic() : int { return GetSettingAsInt( 'AHDAutoLoot_containers', 'Virtual_quantityLogic' ); }
	
	public function GetEkeyLogic() : int { return GetSettingAsInt( 'InteractionKey', 'interactionKey_lootLogic' ); }
	public function GetInteractionKeyDistance() : float { return GetSettingAsFloat( 'InteractionKey', 'interactionKeyMaxDistance' ); }
	public function GetInteractionKeyDistanceHerbs() : float { return GetSettingAsFloat( 'InteractionKey', 'interactionKeyMaxDistanceHerbs' ); }
	public function GetInteractionKeyMaxContainers() : int { return GetSettingAsInt( 'InteractionKey', 'interactionKeyMaxContainers' ); }
	
	public function FiltersEnabled() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useFilters' ); }
	public function UseHerbFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsHerb' ); }
	public function ChosenHerbQuantity() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenHerbQuantity' ); }
	public function UseArmorFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsArmor' ); }
	public function ChosenArmorQuality() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenArmorQuality' ); }
	public function ChosenArmorValue() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenArmorValue' ); }
	public function UseWeaponFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsWeapon' ); }
	public function ChosenWeaponQuality() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenWeaponQuality' ); }
	public function ChosenWeaponValue() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenWeaponValue' ); }
	public function UseIngredientFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsIngredient' ); }
	public function ChosenIngredientQuality() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenIngredientQuality' ); }
	public function ChosenIngredientValue() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenIngredientValue' ); }
	public function ChosenIngredientQuantity() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenIngredientQuantity' ); }
	public function UseJunkFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsJunk' ); }
	public function ChosenJunkQuality() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenJunkQuality' ); }
	public function ChosenJunkValue() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenJunkValue' ); }
	public function ChosenJunkQuantity() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenJunkQuantity' ); }
	public function ChosenBookQuantity() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenBookQuantity' ); }
	public function UseReadableFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsReadable' ); }
	public function UseAlreadyReadFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsAlreadyRead' ); }
	public function UseCurrencyFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsMoney' ); }
	public function ChosenCurrencyQuantity() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenCurrencyQuantity' ); }
	public function UseFoodFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsFood' ); }
	public function ChosenFoodValue() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenFoodValue' ); }
	public function ChosenFoodQuantity() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenFoodQuantity' ); }
	public function UseUpgradeFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsUpgrade' ); }
	public function ChosenUpgradeValue() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenUpgradeValue' ); }
	public function UseHorseFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsHorse' ); }
	public function ChosenHorseValue() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenHorseValue' ); }
	public function UseTrophyFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsTrophy' ); }
	public function ChosenTrophyValue() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenTrophyValue' ); }
	public function UseToolFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsTool' ); }
	public function ChosenToolValue() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenToolValue' ); }
	public function UseOtherFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsOther' ); }
	public function ChosenOtherValue() : int { return GetSettingAsInt( 'AHDAutoLoot_filters', 'chosenOtherValue' ); }
	public function UseFormulaFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsFormula' ); }
	public function UseMaskFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsMask' ); }
	public function UseKeyFilter() : bool { return SettingEnabled( 'AHDAutoLoot_filters', 'useIsKey' ); }
	
	public function RadiusLootIgnoreFilters() : bool { return SettingEnabled( 'AHDAutoLoot_radius', 'radiusLootIgnoreFilters' ); }
	public function RadiusLootInCombat() : bool { return SettingEnabled( 'AHDAutoLoot_radius', 'enableRadiusLootCombat' ); }
	public function GetRadiusLootDistance() : float { return GetSettingAsFloat( 'AHDAutoLoot_radius', 'radiusLootMaxDistance' ); }
	public function GetRadiusLootMaxContainers() : int { return GetSettingAsInt( 'AHDAutoLoot_radius', 'radiusMaxContainers' ); }
	
	public function NotificationsEnabled() : bool { return SettingEnabled( 'AHDAutoLoot_notifications', 'enableNotification' ); }
	public function GetPopupOpacity() : int { return GetSettingAsInt( 'AHDAutoLoot_notifications', 'PopupOpacity' ); }
	public function GetTextOutline() : int { return GetSettingAsInt( 'AHDAutoLoot_notifications', 'textOutline' ); }
	public function GetNotificationFS() : int { return GetSettingAsInt( 'AHDAutoLoot_notifications', 'notificationFontSize' ); }
	public function GetPopupPosX() : int { return GetSettingAsInt( 'AHDAutoLoot_notifications', 'PopupPosX' ); }
	public function GetPopupPosY() : int { return GetSettingAsInt( 'AHDAutoLoot_notifications', 'PopupPosY' ); }
	public function GetMultiColor() : int { return GetSettingAsInt( 'AHDAutoLoot_notifications', 'multiColor' ); }
	public function GetCommonColor() : int { return GetSettingAsInt( 'AHDAutoLoot_notifications', 'commonColor' ); }
	public function GetMasterColor() : int { return GetSettingAsInt( 'AHDAutoLoot_notifications', 'masterColor' ); }
	public function GetMagicColor() : int { return GetSettingAsInt( 'AHDAutoLoot_notifications', 'magicColor' ); }
	public function GetRelicColor() : int { return GetSettingAsInt( 'AHDAutoLoot_notifications', 'relicColor' ); }
	public function GetWitcherColor() : int { return GetSettingAsInt( 'AHDAutoLoot_notifications', 'witcherColor' ); }
	public function UseNewNotification() : bool { return SettingEnabled( 'AHDAutoLoot_notifications', 'useNewNotification' ); }
	public function EnableNotificationDescription() : bool { return SettingEnabled( 'AHDAutoLoot_notifications', 'useNotificationDesc' ); }
	public function EnableNotificationItemCounts() : bool { return SettingEnabled( 'AHDAutoLoot_notifications', 'useNotificationItemCounts' ); }
	public function GetLootPopupMaxItems() : int { return GetSettingAsInt( 'AHDAutoLoot_notifications', 'lootPopupMaxItems' ); }
	public function EnableNotificationQuantity() : bool { return SettingEnabled( 'AHDAutoLoot_notifications', 'useNotificationQuantity' ); }
	public function EnableLootSound() : bool { return SettingEnabled( 'AHDAutoLoot_notifications', 'enableLootSound' ); }
	public function EnableColors() : bool { return SettingEnabled( 'AHDAutoLoot_notifications', 'enableColors' ); }
	public function EnableNotificationImage() : bool { return SettingEnabled( 'AHDAutoLoot_notifications', 'useNotificationImage' ); }
	public function HideNotificationInCombat() : bool { return SettingEnabled( 'AHDAutoLoot_notifications', 'hideNotificationCombat' ); }
	public function ActionLogNotificationsEnabled() : bool { return SettingEnabled( 'AHDAutoLoot_notifications', 'showLootAL' ); }
	public function GetNotificationT() : float { return GetSettingAsFloat( 'AHDAutoLoot_notifications', 'notificationTime' ) * 1000.f; }
	public function GetNotificationTApI() : float { return GetSettingAsFloat( 'AHDAutoLoot_notifications', 'notificationTimeAddPerItem' ); }
	
	public function GetSP_Ekey_Logic() : int { return GetSettingAsInt( 'AutoLoot_popups', 'SP_E_key_Logic' ); }
	public function GetJPrice() : int { return GetSettingAsInt( 'AutoLoot_popups', 'priceJunk' ); }
	public function GetCQuantity() : int { return GetSettingAsInt( 'AutoLoot_popups', 'quantityCurrency' ); }
	public function GetIQuality() : int { return GetSettingAsInt( 'AutoLoot_popups', 'IngredientQualitySPLogic' ); }
	public function GetAQuality() : int { return GetSettingAsInt( 'AutoLoot_popups', 'AQualitySPLogic' ); }
	public function GetWQuality() : int { return GetSettingAsInt( 'AutoLoot_popups', 'WQualitySPLogic' ); }
	public function HideH() : bool { return SettingEnabled( 'AutoLoot_popups', 'NoPopH' ); }
	public function HideR() : bool { return SettingEnabled( 'AutoLoot_popups', 'NoPopR' ); }
	public function HideF() : bool { return SettingEnabled( 'AutoLoot_popups', 'NoPopF' ); }
	public function HideJ() : bool { return SettingEnabled( 'AutoLoot_popups', 'NoPopJ' ); }
	public function HideC() : bool { return SettingEnabled( 'AutoLoot_popups', 'NoPopC' ); }
	public function HideI() : bool { return SettingEnabled( 'AutoLoot_popups', 'NoPopI' ); }
	public function HideA() : bool { return SettingEnabled( 'AutoLoot_popups', 'NoPopA' ); }
	public function HideW() : bool { return SettingEnabled( 'AutoLoot_popups', 'NoPopW' ); }
	
	//Returns if the specified setting is enabled (helper function)
	public function SettingEnabled(group : name, setting : name) : bool
	{
		return UserSettings.GetVarValue(group, setting);
	}
	
	//Returns the specified setting as a float (helper function)
	private function GetSettingAsFloat(group : name, setting : name) : float
	{
		return StringToFloat( UserSettings.GetVarValue(group, setting) );
	}
	
	//Returns the specified setting as an int (helper function)
	private function GetSettingAsInt(group : name, setting : name) : int
	{
		return StringToInt( UserSettings.GetVarValue(group, setting) );
	}
}