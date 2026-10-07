/***********************************************************************/
/** 	AHDAutoLootActions.ws
/** 	by AeroHD
/**		Original AutoLoot code by JupiterTheGod
/**		mod: AutoLoot Advanced Settings (AutoLoot +A.S.) by jerry18
/***********************************************************************/



class CAHDAutoLootActions
{
	private var AutoLootConfig : CAHDAutoLootConfig;
	private var cInv : CInventoryComponent;
	private var invItemList : array<SItemUniqueId>;
	
	public function Init() : void
	{
		AutoLootConfig = GetWitcherPlayer().GetAutoLootConfig();
	}
	
	//Initializes/resets variables used in various functions
	private function InitAndCleanContainer(container : W3Container) : void
	{
		cInv = container.GetInventory();
		invItemList.Clear();
		cInv.GetAllItems( invItemList );
	}
	
	//Determines if the container's inventory component is empty
	private function IsInvEmpty(inventory : CInventoryComponent) : bool { return inventory.GetAllItemsQuantity() <= 0; }
	
	//Determines if the container should be looted. Returns if loot was taken from the container
	public function ProcessContainer(container : W3Container) : bool
	{
		var wasLooted : bool;
		
		InitAndCleanContainer(container);
		
		if( IsInvEmpty(cInv) )
			return false;
		
		if( !AutoLootConfig.ModEnabled() || AutoLootConfig.GetFilters().IsContainerProtected(container) )
			return true;
		
		wasLooted = LootContainer(container);
		
		if( !container.mergeNotification )
		{
			//let TryAreaLooting handle popup creation/merging when 'E' is pressed - needed (at least) for herbs and common containers ("Take" ones) due to engine behavior alternating with each game launch
			if( !AutoLootConfig.GetFeatureManager().WasInteractionKeyPressed() || AutoLootConfig.GetFeatureManager().GetInteractionKeyContainerType() == 3 )
				AutoLootConfig.GetNotifications().ShowNotification();
		}
		
		CleanAndFix(container, wasLooted);
		
		return !IsInvEmpty(cInv);
	}
	
	//Tries to take items from the container in accordance with the user's filters
	private function LootContainer(container : W3Container) : bool
	{
		var totalItems, i : int;
		var looted : bool;
		
		totalItems = invItemList.Size();
		looted = false;
		
		GetWitcherPlayer().StartInvUpdateTransaction();
		
		for( i = 0; i < totalItems; i += 1 )
		{
			if( cInv.ItemHasTag(invItemList[i], 'QuickSlot') && !cInv.ItemHasTag(invItemList[i], 'UI_Torch') && !cInv.IsItemMask(invItemList[i]) )
				continue;
			
			if( AutoLootConfig.ProtectWitcherSchematics() && AutoLootConfig.GetFilters().IsFormula(container, invItemList[i]) && cInv.GetItemQuality(invItemList[i]) == 5 )
				continue;
			
			//exclude Potion from Tir ná Lia ("Content Expansion - Time of the Sword and Axe" DLC mod) because you can have just one piece in your inventory
			if( cInv.GetItemName(invItemList[i]) == 'Tirnalia potion' )
				continue;
			
			if( AutoLootConfig.AutoLootLogic(container, invItemList[i], totalItems) )
			{
				//if( AutoLootConfig.NotificationsEnabled() ) //Disabled: no loot sound if this is On while Notification setting is Off
				//adds Autoloot popups notifications for everything but SP options (with exception if Quest container is looted)
				if( !skipNotificationSP(container, invItemList[i]) || AutoLootConfig.GetFilters().isQuestContainer(container) || cInv.ItemHasTag(invItemList[i], 'GwintCard') )
					AutoLootConfig.GetNotifications().AddItem( container, invItemList[i] );
				
				if( AutoLootConfig.QuestItemWarningMsg() )
				{
					if( AutoLootConfig.GetFilters().isQuestContainer(container) || cInv.ItemHasTag(invItemList[i], 'GwintCard') )
					{
						GetWitcherPlayer().DisplayHudMessage( GetLocStringByKeyExt("ahdal_questItemMsg") );
						theSound.SoundEvent( 'gui_enchanting_socket_add' );
					}
				}
				
				LootItem( container, invItemList[i] );
				looted = true;
			}
		}
		GetWitcherPlayer().FinishInvUpdateTransaction();
		
		return looted;
	}
	
	//Takes the specified item from the container and gives it to the player
	private function LootItem(container : W3Container, itemID : SItemUniqueId) : void
	{
		var quantity : int;
		
		quantity = container.GetInventory().GetItemQuantity(itemID);
		
		if( container.GetInventory().ItemHasTag(itemID, 'Lootable' ) ||
			!container.GetInventory().ItemHasTag(itemID, 'NoDrop') &&
			!container.GetInventory().ItemHasTag(itemID, theGame.params.TAG_DONT_SHOW) )
		{
			container.GetInventory().NotifyItemLooted(itemID);
			container.GetInventory().GiveItemTo( GetWitcherPlayer().inv, itemID, quantity, true, false, true );
		}
		
		if( container.GetInventory().ItemHasTag(itemID, 'GwintCard') )
			GetWitcherPlayer().AddGwentCard(container.GetInventory().GetItemName(itemID), quantity);
		
		container.InformClueStash();
	}
	
	//Silent Popup options (SP_E_KeyLogic -> options to still enable autoloot popup for selected items in Silent Popup menu if you autoloot them with "E" key)
	private function skipNotificationSP(container : W3Container, itemID : SItemUniqueId) : bool
	{
		var containerType : int;
		
		containerType = AutoLootConfig.GetFeatureManager().GetInteractionKeyContainerType();
		
		if( containerType == 3 )
			return false;
		
		if( AutoLootConfig.GetSP_Ekey_Logic() == 1 )
		{
			return ( AutoLootConfig.GetNotifications().silentH(container, itemID) && containerType != 2 )
				|| ( AutoLootConfig.GetNotifications().silentI(container, itemID) )
				|| ( AutoLootConfig.GetNotifications().silentR(container, itemID) )
				|| ( AutoLootConfig.GetNotifications().silentF(container, itemID) )
				|| ( AutoLootConfig.GetNotifications().silentJ(container, itemID) )
				|| ( AutoLootConfig.GetNotifications().silentC(container, itemID) )
				|| ( AutoLootConfig.GetNotifications().silentA(container, itemID) )
				|| ( AutoLootConfig.GetNotifications().silentW(container, itemID) );
		}
		else if( AutoLootConfig.GetSP_Ekey_Logic() == 2 )
		{
			if( containerType <= 0 ) //E wasn't pressed
			{
				return ( AutoLootConfig.GetNotifications().silentH(container, itemID) )
					|| ( AutoLootConfig.GetNotifications().silentI(container, itemID) )
					|| ( AutoLootConfig.GetNotifications().silentR(container, itemID) )
					|| ( AutoLootConfig.GetNotifications().silentF(container, itemID) )
					|| ( AutoLootConfig.GetNotifications().silentJ(container, itemID) )
					|| ( AutoLootConfig.GetNotifications().silentC(container, itemID) )
					|| ( AutoLootConfig.GetNotifications().silentA(container, itemID) )
					|| ( AutoLootConfig.GetNotifications().silentW(container, itemID) );
			}
		}
		else
		{
			return ( AutoLootConfig.GetNotifications().silentH(container, itemID) )
				|| ( AutoLootConfig.GetNotifications().silentI(container, itemID) )
				|| ( AutoLootConfig.GetNotifications().silentR(container, itemID) )
				|| ( AutoLootConfig.GetNotifications().silentF(container, itemID) )
				|| ( AutoLootConfig.GetNotifications().silentJ(container, itemID) )
				|| ( AutoLootConfig.GetNotifications().silentC(container, itemID) )
				|| ( AutoLootConfig.GetNotifications().silentA(container, itemID) )
				|| ( AutoLootConfig.GetNotifications().silentW(container, itemID) );
		}
		
		return false;
	}
	
	//Cleans the updated inventory list and applies various bug fixes
	private function CleanAndFix(container : W3Container, shouldClean : bool)
	{
		var i : int;
		
		cInv.GetAllItems( invItemList );
		
		for( i = invItemList.Size() - 1; i >= 0; i -= 1 )
		{
			if( (cInv.ItemHasTag(invItemList[i],theGame.params.TAG_DONT_SHOW) || cInv.ItemHasTag(invItemList[i],'NoDrop')) &&
				!cInv.ItemHasTag(invItemList[i], 'Lootable') )
				invItemList.Erase(i);
		}
		
		if( shouldClean || IsInvEmpty(cInv) )
			container.AutoLootCleanup();
		
		if( (W3treasureHuntContainer)container )
			((W3treasureHuntContainer)container).ProcessOnLootedEvents();
	}
}