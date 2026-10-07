/***********************************************************************/
/** 	AHDAutoLootFilters.ws
/** 	by AeroHD
/**		Original AutoLoot code by JupiterTheGod
/**		mod: AutoLoot Advanced Settings (AutoLoot +A.S.) by jerry18
/***********************************************************************/



class CAHDAutoLootFilters
{
	private var AutoLootConfig : CAHDAutoLootConfig;
	private var itemName, itemCategory : name;
	
	public function Init() : void
	{
		AutoLootConfig = GetWitcherPlayer().GetAutoLootConfig();
	}
	
	//Checks if the container shouldn't be interacted with by AutoLoot
	public function IsContainerProtected(container : W3Container) : bool
	{
		var cInv : CInventoryComponent;
		var invItemList : array< SItemUniqueId >;
		var i, E_KEY_Logic : int;
		
		cInv = container.GetInventory();
		cInv.GetAllItems( invItemList );
		
		
		E_KEY_Logic = AutoLootConfig.GetEkeyLogic();
		
		for( i = 0; i < invItemList.Size(); i += 1 )
		{
			itemName = cInv.GetItemName(invItemList[i]);
			
			//exclude looting during dialogs/cutscene playing/starting, etc.
			if( theInput.GetContext() == 'Scene'
				|| theGame.IsPaused()
				|| theGame.IsDialogOrCutscenePlaying()
				|| theGame.IsCurrentlyPlayingNonGameplayScene()
				|| theGame.IsBlackscreen()
				|| theGame.IsFading()
				|| theGame.IsBlackscreenOrFading()
				|| theGame.GetPhotomodeEnabled() //this is Next Gen only!
				|| thePlayer.IsInCutsceneIntro() //this is Next Gen only!
				|| !thePlayer.IsAlive() )
				return true;
			
			//exclude looting when Vanilla container loot popup window is opened
			if( theGame.GetGuiManager().GetPopup('LootPopup') )
				return true;
			
			//exclude looting when Vanilla container loot popup window (not Gathered Herb) is opened by pressing Interaction key
			if( !((W3Herb)container) )
			{
				if( (E_KEY_Logic == 0 && AutoLootConfig.GetFeatureManager().WasInteractionKeyPressed()) 
					|| (E_KEY_Logic == 1 && AutoLootConfig.GetFeatureManager().GetInteractionKeyContainerType() == 3) )
				{
					return true;
				}
			}
			
			//exclude quickslot items (besides masks and torches) from Autoloot check to eliminate stutter (AHDAutoLootActions.ws file = no loot quickslot items)
			//Optional: 4x torch from "Possession" quest, but not needed (at least in NG) since even with no torch in the inventory you can still placed them
			//if( StrFindFirst((string)container,"quests\part_1\quest_files\q203_him\entities\q203_crate_torches.w2ent")>=0 )
			//	return true;
			//else
			if( cInv.ItemHasTag(invItemList[i], 'QuickSlot') && !cInv.ItemHasTag(invItemList[i], 'UI_Torch') && !cInv.IsItemMask(invItemList[i]) )
				continue; //if "return true;" is here: then other items in a container wouldn't be looted (in dependancy of which item was dropped first because the drop order matters)
			
			//exclude Potion from Tir ná Lia ("Content Expansion - Time of the Sword and Axe" DLC mod) because you can have just one piece in your inventory
			if( itemName == 'Tirnalia potion' )
				continue;
			
			//exclude unwanted items from Autoloot check to eliminate stutter
			if( !cInv.ItemHasTag(invItemList[i],'Lootable')
				&& (cInv.ItemHasTag(invItemList[i],theGame.params.TAG_DONT_SHOW) || cInv.ItemHasTag(invItemList[i],'NoDrop')) )
				continue;
			
			//locked containers or disable looting enabled or other unwanted containers
			if( container.lockedByKey || container.disableLooting || !container.CanShowFocusInteractionIcon() )
				return true;
			
			//containers with no loot icon
			if( container.GetComponent('Loot').IsEnabled() == false && !IsCorpse(container) )
			{
				if( StrFindFirst((string)container,"\beehive")>=0 || StrFindFirst((string)container,"\bee_hive")>=0 )
				{
					if( AutoLootConfig.ProtectBeehives() )
						return true;
					else
						return false;
				}
				else
					return true;
			}
			
			//stealing settings
			if( !container.disableStealing && AutoLootConfig.NoAccidentalStealingEnabled() )
				return true;
			
			//exclude items on stands (Corvo Bianco) or other decorations
			if( (W3HouseDecorationBase)container
				|| (W3HouseGenericDecoration)container
				|| (W3ArmorStand)container
				|| (W3SwordStand)container )
				return true;
			
			//exclude white armors during "Imperial Audience" quest in Vizima (3x Nilfgaardian Casual Pants/Shoes/Suit)
			if( StrFindFirst((string)container,"quest_files\q002_emhyr\entities\q001_clothes_rack")>=0 )
				return true;
			
			//exclude Grandmaster Manticore Gear chests (BaW) ...rather here to not allowed to loot even when "Force Quest..." option is enabled
			if( StrFindFirst((string)container,"quests\minor_quests\quest_files\th700_red_wolf\entities\th700_prison_loose_brick.w2ent")>=0
				|| StrFindFirst((string)container,"quests\minor_quests\quest_files\th700_red_wolf\entities\th700_crypt_chest.w2ent")>=0
				|| StrFindFirst((string)container,"quests\minor_quests\quest_files\th700_red_wolf\entities\th700_vault_chest.w2ent")>=0
				|| StrFindFirst((string)container,"quests\minor_quests\quest_files\th700_red_wolf\entities\th700_troll_chapel_chest.w2ent")>=0
				|| StrFindFirst((string)container,"quests\minor_quests\quest_files\th700_red_wolf\entities\th700_lake_chest.w2ent")>=0 )
				return true;
			
			//check for individual filters (excludes not used filters from Autoloot check to eliminate stutter)
			if( AutoLootConfig.FiltersEnabled()
				&& (AutoLootConfig.GetFeatureManager().GetInteractionKeyContainerType() <= 0 || E_KEY_Logic == 2) //Match item filtering: mode 2 applies filters during interaction looting.
				&& ( !AutoLootConfig.UseCorpseFilter() || !IsCorpse(container) )
				&& ( !AutoLootConfig.UseDroppedFilter() || !IsDropped(container) )
				&& ( !AutoLootConfig.UseQuantityFilter()
					|| (( AutoLootConfig.ChosenQuantityLogic() == 0 && invItemList.Size() > AutoLootConfig.ChosenQuantity())
					|| ( AutoLootConfig.ChosenQuantityLogic() == 1 && invItemList.Size() != AutoLootConfig.ChosenQuantity())
					|| ( AutoLootConfig.ChosenQuantityLogic() == 2 && invItemList.Size() < AutoLootConfig.ChosenQuantity() )) ) )
			{
				if( ( IsHerb(container, invItemList[i]) && !AutoLootConfig.UseHerbFilter() )
					|| ( IsArmor(container, invItemList[i]) && !AutoLootConfig.UseArmorFilter() )
					|| ( IsWeapon(container, invItemList[i]) && !AutoLootConfig.UseWeaponFilter() )
					|| ( IsIngredient(container, invItemList[i]) && !AutoLootConfig.UseIngredientFilter() )
					|| ( IsJunk(container, invItemList[i]) && !AutoLootConfig.UseJunkFilter() )
					|| ( IsReadable(container, invItemList[i]) && !AutoLootConfig.UseReadableFilter() )
					|| ( IsAlreadyRead(container, invItemList[i]) && !AutoLootConfig.UseAlreadyReadFilter() )
					|| ( IsCurrency(container, invItemList[i]) && !AutoLootConfig.UseCurrencyFilter() )
					|| ( IsFood(container, invItemList[i]) && !AutoLootConfig.UseFoodFilter() )
					|| ( IsUpgrade(container, invItemList[i]) && !AutoLootConfig.UseUpgradeFilter() )
					|| ( IsHorse(container, invItemList[i]) && !AutoLootConfig.UseHorseFilter() )
					|| ( IsTrophy(container, invItemList[i]) && !AutoLootConfig.UseTrophyFilter() )
					|| ( IsTool(container, invItemList[i]) && !AutoLootConfig.UseToolFilter() )
					|| ( IsOther(container, invItemList[i]) && !AutoLootConfig.UseOtherFilter() )
					|| ( IsFormula(container, invItemList[i]) && !AutoLootConfig.UseFormulaFilter() )
					|| ( IsMask(container, invItemList[i]) && !AutoLootConfig.UseMaskFilter() )
					|| ( IsKey(container, invItemList[i]) && !AutoLootConfig.UseKeyFilter() ) )
					continue;
				
				if( IsArmor(container, invItemList[i]) && AutoLootConfig.UseArmorFilter() )
				{
					if( AutoLootConfig.ChosenArmorQuality() >= 1 && AutoLootConfig.ChosenArmorValue() == 0 )
					{
						if( ( AutoLootConfig.ChosenArmorQuality() <= 5 && cInv.GetItemQuality(invItemList[i]) != AutoLootConfig.ChosenArmorQuality() )
							|| ( AutoLootConfig.ChosenArmorQuality() == 6 && cInv.GetItemQuality(invItemList[i]) > 2 )
							|| ( AutoLootConfig.ChosenArmorQuality() == 7 && cInv.GetItemQuality(invItemList[i]) > 3 )
							|| ( AutoLootConfig.ChosenArmorQuality() == 8 && cInv.GetItemQuality(invItemList[i]) > 4 )
							|| ( AutoLootConfig.ChosenArmorQuality() == 9 && cInv.GetItemQuality(invItemList[i]) < 2 )
							|| ( AutoLootConfig.ChosenArmorQuality() == 10 && cInv.GetItemQuality(invItemList[i]) < 3 )
							|| ( AutoLootConfig.ChosenArmorQuality() == 11 && cInv.GetItemQuality(invItemList[i]) < 4 ) )
							continue;
					}
					else if( AutoLootConfig.ChosenArmorQuality() == 0 && AutoLootConfig.ChosenArmorValue() >= 1 )
					{
						if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenArmorValue() )
							continue;
					}
					else if( AutoLootConfig.ChosenArmorQuality() >= 1 && AutoLootConfig.ChosenArmorValue() >= 1 )
					{
						if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenArmorValue() )
							continue;
						else if( ( AutoLootConfig.ChosenArmorQuality() <= 5 && cInv.GetItemQuality(invItemList[i]) != AutoLootConfig.ChosenArmorQuality() )
							|| ( AutoLootConfig.ChosenArmorQuality() == 6 && cInv.GetItemQuality(invItemList[i]) > 2 )
							|| ( AutoLootConfig.ChosenArmorQuality() == 7 && cInv.GetItemQuality(invItemList[i]) > 3 )
							|| ( AutoLootConfig.ChosenArmorQuality() == 8 && cInv.GetItemQuality(invItemList[i]) > 4 )
							|| ( AutoLootConfig.ChosenArmorQuality() == 9 && cInv.GetItemQuality(invItemList[i]) < 2 )
							|| ( AutoLootConfig.ChosenArmorQuality() == 10 && cInv.GetItemQuality(invItemList[i]) < 3 )
							|| ( AutoLootConfig.ChosenArmorQuality() == 11 && cInv.GetItemQuality(invItemList[i]) < 4 ) )
							continue;
					}
				}
				
				if( IsWeapon(container, invItemList[i]) && AutoLootConfig.UseWeaponFilter() )
				{
					if( AutoLootConfig.ChosenWeaponQuality() >= 1 && AutoLootConfig.ChosenWeaponValue() == 0 )
					{
						if( ( AutoLootConfig.ChosenWeaponQuality() <= 5 && cInv.GetItemQuality(invItemList[i]) != AutoLootConfig.ChosenWeaponQuality() )
							|| ( AutoLootConfig.ChosenWeaponQuality() == 6 && cInv.GetItemQuality(invItemList[i]) > 2 )
							|| ( AutoLootConfig.ChosenWeaponQuality() == 7 && cInv.GetItemQuality(invItemList[i]) > 3 )
							|| ( AutoLootConfig.ChosenWeaponQuality() == 8 && cInv.GetItemQuality(invItemList[i]) > 4 )
							|| ( AutoLootConfig.ChosenWeaponQuality() == 9 && cInv.GetItemQuality(invItemList[i]) < 2 )
							|| ( AutoLootConfig.ChosenWeaponQuality() == 10 && cInv.GetItemQuality(invItemList[i]) < 3 )
							|| ( AutoLootConfig.ChosenWeaponQuality() == 11 && cInv.GetItemQuality(invItemList[i]) < 4 ) )
							continue;
					}
					else if( AutoLootConfig.ChosenWeaponQuality() == 0 && AutoLootConfig.ChosenWeaponValue() >= 1 )
					{
						if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenWeaponValue() )
							continue;
					}
					else if( AutoLootConfig.ChosenWeaponQuality() >= 1 && AutoLootConfig.ChosenWeaponValue() >= 1 )
					{
						if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenWeaponValue() )
							continue;
						else if( ( AutoLootConfig.ChosenWeaponQuality() <= 5 && cInv.GetItemQuality(invItemList[i]) != AutoLootConfig.ChosenWeaponQuality() )
							|| ( AutoLootConfig.ChosenWeaponQuality() == 6 && cInv.GetItemQuality(invItemList[i]) > 2 )
							|| ( AutoLootConfig.ChosenWeaponQuality() == 7 && cInv.GetItemQuality(invItemList[i]) > 3 )
							|| ( AutoLootConfig.ChosenWeaponQuality() == 8 && cInv.GetItemQuality(invItemList[i]) > 4 )
							|| ( AutoLootConfig.ChosenWeaponQuality() == 9 && cInv.GetItemQuality(invItemList[i]) < 2 )
							|| ( AutoLootConfig.ChosenWeaponQuality() == 10 && cInv.GetItemQuality(invItemList[i]) < 3 )
							|| ( AutoLootConfig.ChosenWeaponQuality() == 11 && cInv.GetItemQuality(invItemList[i]) < 4 ) )
							continue;
					}
				}
				
				if( IsIngredient(container, invItemList[i]) && AutoLootConfig.UseIngredientFilter() )
				{
					if( AutoLootConfig.ChosenIngredientQuality() >= 1 && AutoLootConfig.ChosenIngredientValue() == 0 && AutoLootConfig.ChosenIngredientQuantity() == 0 )
					{
						if( ( AutoLootConfig.ChosenIngredientQuality() <= 4 && cInv.GetItemQuality(invItemList[i]) != AutoLootConfig.ChosenIngredientQuality() )
							|| ( AutoLootConfig.ChosenIngredientQuality() == 5 && cInv.GetItemQuality(invItemList[i]) > 2 )
							|| ( AutoLootConfig.ChosenIngredientQuality() == 6 && cInv.GetItemQuality(invItemList[i]) > 3 )
							|| ( AutoLootConfig.ChosenIngredientQuality() == 7 && cInv.GetItemQuality(invItemList[i]) < 2 )
							|| ( AutoLootConfig.ChosenIngredientQuality() == 8 && cInv.GetItemQuality(invItemList[i]) < 3 ) )
							continue;
					}
					else if( AutoLootConfig.ChosenIngredientQuality() == 0 && AutoLootConfig.ChosenIngredientValue() >= 1 && AutoLootConfig.ChosenIngredientQuantity() == 0 )
					{
						if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenIngredientValue() )
							continue;
					}
					else if( AutoLootConfig.ChosenIngredientQuality() == 0 && AutoLootConfig.ChosenIngredientValue() == 0 && AutoLootConfig.ChosenIngredientQuantity() >= 1 )
					{
						if( (thePlayer.GetInventory().GetItemQuantityByName(itemName) + cInv.GetItemQuantity(invItemList[i])) > AutoLootConfig.ChosenIngredientQuantity() )
							continue;
					}
					else if( AutoLootConfig.ChosenIngredientQuality() >= 1 && AutoLootConfig.ChosenIngredientValue() >= 1 && AutoLootConfig.ChosenIngredientQuantity() == 0 )
					{
						if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenIngredientValue() )
							continue;
						else if( ( AutoLootConfig.ChosenIngredientQuality() <= 4 && cInv.GetItemQuality(invItemList[i]) != AutoLootConfig.ChosenIngredientQuality() )
							|| ( AutoLootConfig.ChosenIngredientQuality() == 5 && cInv.GetItemQuality(invItemList[i]) > 2 )
							|| ( AutoLootConfig.ChosenIngredientQuality() == 6 && cInv.GetItemQuality(invItemList[i]) > 3 )
							|| ( AutoLootConfig.ChosenIngredientQuality() == 7 && cInv.GetItemQuality(invItemList[i]) < 2 )
							|| ( AutoLootConfig.ChosenIngredientQuality() == 8 && cInv.GetItemQuality(invItemList[i]) < 3 ) )
							continue;
					}
					else if( AutoLootConfig.ChosenIngredientQuality() >= 1 && AutoLootConfig.ChosenIngredientValue() == 0 && AutoLootConfig.ChosenIngredientQuantity() >= 1 )
					{
						if( (thePlayer.GetInventory().GetItemQuantityByName(itemName) + cInv.GetItemQuantity(invItemList[i])) > AutoLootConfig.ChosenIngredientQuantity() )
							continue;
						else if( ( AutoLootConfig.ChosenIngredientQuality() <= 4 && cInv.GetItemQuality(invItemList[i]) != AutoLootConfig.ChosenIngredientQuality() )
							|| ( AutoLootConfig.ChosenIngredientQuality() == 5 && cInv.GetItemQuality(invItemList[i]) > 2 )
							|| ( AutoLootConfig.ChosenIngredientQuality() == 6 && cInv.GetItemQuality(invItemList[i]) > 3 )
							|| ( AutoLootConfig.ChosenIngredientQuality() == 7 && cInv.GetItemQuality(invItemList[i]) < 2 )
							|| ( AutoLootConfig.ChosenIngredientQuality() == 8 && cInv.GetItemQuality(invItemList[i]) < 3 ) )
							continue;
					}
					else if( AutoLootConfig.ChosenIngredientQuality() == 0 && AutoLootConfig.ChosenIngredientValue() >= 1 && AutoLootConfig.ChosenIngredientQuantity() >= 1 )
					{
						if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenIngredientValue() )
							continue;
						else if( (thePlayer.GetInventory().GetItemQuantityByName(itemName) + cInv.GetItemQuantity(invItemList[i])) > AutoLootConfig.ChosenIngredientQuantity() )
							continue;
					}
					else if( AutoLootConfig.ChosenIngredientQuality() >= 1 && AutoLootConfig.ChosenIngredientValue() >= 1 && AutoLootConfig.ChosenIngredientQuantity() >= 1 )
					{
						if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenIngredientValue() )
							continue;
						else if( (thePlayer.GetInventory().GetItemQuantityByName(itemName) + cInv.GetItemQuantity(invItemList[i])) > AutoLootConfig.ChosenIngredientQuantity() )
							continue;
						else if( ( AutoLootConfig.ChosenIngredientQuality() <= 4 && cInv.GetItemQuality(invItemList[i]) != AutoLootConfig.ChosenIngredientQuality() )
							|| ( AutoLootConfig.ChosenIngredientQuality() == 5 && cInv.GetItemQuality(invItemList[i]) > 2 )
							|| ( AutoLootConfig.ChosenIngredientQuality() == 6 && cInv.GetItemQuality(invItemList[i]) > 3 )
							|| ( AutoLootConfig.ChosenIngredientQuality() == 7 && cInv.GetItemQuality(invItemList[i]) < 2 )
							|| ( AutoLootConfig.ChosenIngredientQuality() == 8 && cInv.GetItemQuality(invItemList[i]) < 3 ) )
							continue;		
					}
				}
				
				if( IsJunk(container, invItemList[i]) && AutoLootConfig.UseJunkFilter() )
				{
					if( AutoLootConfig.ChosenJunkQuality() >= 1 && AutoLootConfig.ChosenJunkValue() == 0 && AutoLootConfig.ChosenJunkQuantity() == 0 )
					{
						if( ( AutoLootConfig.ChosenJunkQuality() <= 4 && cInv.GetItemQuality(invItemList[i]) != AutoLootConfig.ChosenJunkQuality() )
							|| ( AutoLootConfig.ChosenJunkQuality() == 5 && cInv.GetItemQuality(invItemList[i]) > 2 )
							|| ( AutoLootConfig.ChosenJunkQuality() == 6 && cInv.GetItemQuality(invItemList[i]) > 3 )
							|| ( AutoLootConfig.ChosenJunkQuality() == 7 && cInv.GetItemQuality(invItemList[i]) < 2 )
							|| ( AutoLootConfig.ChosenJunkQuality() == 8 && cInv.GetItemQuality(invItemList[i]) < 3 ) )
							continue;
					}
					else if( AutoLootConfig.ChosenJunkQuality() == 0 && AutoLootConfig.ChosenJunkValue() >= 1 && AutoLootConfig.ChosenJunkQuantity() == 0 )
					{
						if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenJunkValue() )
							continue;
					}
					else if( AutoLootConfig.ChosenJunkQuality() == 0 && AutoLootConfig.ChosenJunkValue() == 0 && AutoLootConfig.ChosenJunkQuantity() >= 1 )
					{
						if( (thePlayer.GetInventory().GetItemQuantityByName(itemName) + cInv.GetItemQuantity(invItemList[i])) > AutoLootConfig.ChosenJunkQuantity() )
							continue;
					}
					else if( AutoLootConfig.ChosenJunkQuality() >= 1 && AutoLootConfig.ChosenJunkValue() >= 1 && AutoLootConfig.ChosenJunkQuantity() == 0 )
					{
						if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenJunkValue() )
							continue;
						else if( ( AutoLootConfig.ChosenJunkQuality() <= 4 && cInv.GetItemQuality(invItemList[i]) != AutoLootConfig.ChosenJunkQuality() )
							|| ( AutoLootConfig.ChosenJunkQuality() == 5 && cInv.GetItemQuality(invItemList[i]) > 2 )
							|| ( AutoLootConfig.ChosenJunkQuality() == 6 && cInv.GetItemQuality(invItemList[i]) > 3 )
							|| ( AutoLootConfig.ChosenJunkQuality() == 7 && cInv.GetItemQuality(invItemList[i]) < 2 )
							|| ( AutoLootConfig.ChosenJunkQuality() == 8 && cInv.GetItemQuality(invItemList[i]) < 3 ) )
							continue;
					}
					else if( AutoLootConfig.ChosenJunkQuality() >= 1 && AutoLootConfig.ChosenJunkValue() == 0 && AutoLootConfig.ChosenJunkQuantity() >= 1 )
					{
						if( (thePlayer.GetInventory().GetItemQuantityByName(itemName) + cInv.GetItemQuantity(invItemList[i])) > AutoLootConfig.ChosenJunkQuantity() )
							continue;
						else if( ( AutoLootConfig.ChosenJunkQuality() <= 4 && cInv.GetItemQuality(invItemList[i]) != AutoLootConfig.ChosenJunkQuality() )
							|| ( AutoLootConfig.ChosenJunkQuality() == 5 && cInv.GetItemQuality(invItemList[i]) > 2 )
							|| ( AutoLootConfig.ChosenJunkQuality() == 6 && cInv.GetItemQuality(invItemList[i]) > 3 )
							|| ( AutoLootConfig.ChosenJunkQuality() == 7 && cInv.GetItemQuality(invItemList[i]) < 2 )
							|| ( AutoLootConfig.ChosenJunkQuality() == 8 && cInv.GetItemQuality(invItemList[i]) < 3 ) )
							continue;
					}
					else if( AutoLootConfig.ChosenJunkQuality() == 0 && AutoLootConfig.ChosenJunkValue() >= 1 && AutoLootConfig.ChosenJunkQuantity() >= 1 )
					{
						if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenJunkValue() )
							continue;
						else if( (thePlayer.GetInventory().GetItemQuantityByName(itemName) + cInv.GetItemQuantity(invItemList[i])) > AutoLootConfig.ChosenJunkQuantity() )
							continue;
					}
					else if( AutoLootConfig.ChosenJunkQuality() >= 1 && AutoLootConfig.ChosenJunkValue() >= 1 && AutoLootConfig.ChosenJunkQuantity() >= 1 )
					{
						if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenJunkValue() )
							continue;
						else if( (thePlayer.GetInventory().GetItemQuantityByName(itemName) + cInv.GetItemQuantity(invItemList[i])) > AutoLootConfig.ChosenJunkQuantity() )
							continue;
						else if( ( AutoLootConfig.ChosenJunkQuality() <= 4 && cInv.GetItemQuality(invItemList[i]) != AutoLootConfig.ChosenJunkQuality() )
							|| ( AutoLootConfig.ChosenJunkQuality() == 5 && cInv.GetItemQuality(invItemList[i]) > 2 )
							|| ( AutoLootConfig.ChosenJunkQuality() == 6 && cInv.GetItemQuality(invItemList[i]) > 3 )
							|| ( AutoLootConfig.ChosenJunkQuality() == 7 && cInv.GetItemQuality(invItemList[i]) < 2 )
							|| ( AutoLootConfig.ChosenJunkQuality() == 8 && cInv.GetItemQuality(invItemList[i]) < 3 ) )
							continue;		
					}
				}
				
				if( IsHerb(container, invItemList[i]) && AutoLootConfig.UseHerbFilter() && AutoLootConfig.ChosenHerbQuantity() >= 1 )
				{
					if( (thePlayer.GetInventory().GetItemQuantityByName(itemName) + cInv.GetItemQuantity(invItemList[i])) > AutoLootConfig.ChosenHerbQuantity() )
						continue;
				}
				
				if( AutoLootConfig.UseReadableFilter() || AutoLootConfig.UseAlreadyReadFilter() )
				{
					if( (IsReadable(container, invItemList[i]) || IsAlreadyRead(container, invItemList[i])) && AutoLootConfig.ChosenBookQuantity() >= 1
						&& thePlayer.GetInventory().GetItemQuantityByName(itemName) != 0 )
					{
						if( (thePlayer.GetInventory().GetItemQuantityByName(itemName) + cInv.GetItemQuantity(invItemList[i])) > AutoLootConfig.ChosenBookQuantity() )
							continue;
					}
				}
				
				if( IsCurrency(container, invItemList[i]) && AutoLootConfig.UseCurrencyFilter() && AutoLootConfig.ChosenCurrencyQuantity() >= 1 )
				{
					if( cInv.GetItemQuantity(invItemList[i]) < AutoLootConfig.ChosenCurrencyQuantity() )
						continue;
				}
				
				if( IsFood(container, invItemList[i]) )
				{
					if( AutoLootConfig.ChosenFoodValue() >= 1 && AutoLootConfig.ChosenFoodQuantity() == 0 )
					{
						if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenFoodValue() )
							continue;
					}
					else if( AutoLootConfig.ChosenFoodValue() == 0 && AutoLootConfig.ChosenFoodQuantity() >= 1 )
					{
						if( (thePlayer.GetInventory().GetItemQuantityByName(itemName) + cInv.GetItemQuantity(invItemList[i])) > AutoLootConfig.ChosenFoodQuantity() )
							continue;
					}
					else if( AutoLootConfig.ChosenFoodValue() >= 1 && AutoLootConfig.ChosenFoodQuantity() >= 1 )
					{
						if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenFoodValue()
						&& ((thePlayer.GetInventory().GetItemQuantityByName(itemName) + cInv.GetItemQuantity(invItemList[i])) > AutoLootConfig.ChosenFoodQuantity()) )
							continue;
					}
				}
				
				if( IsUpgrade(container, invItemList[i]) && AutoLootConfig.UseUpgradeFilter() && AutoLootConfig.ChosenUpgradeValue() >= 1 )
				{
					if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenUpgradeValue() )
						continue;
				}
				
				if( IsHorse(container, invItemList[i]) && AutoLootConfig.UseHorseFilter() && AutoLootConfig.ChosenHorseValue() >= 1 )
				{
					if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenHorseValue() )
						continue;
				}
				
				if( IsTrophy(container, invItemList[i]) && AutoLootConfig.UseTrophyFilter() && AutoLootConfig.ChosenTrophyValue() >= 1 )
				{
					if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenTrophyValue() )
						continue;
				}
				
				if( IsTool(container, invItemList[i]) && AutoLootConfig.UseToolFilter() && AutoLootConfig.ChosenToolValue() >= 1 )
				{
					if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenToolValue() )
						continue;
				}
				
				if( IsOther(container, invItemList[i]) && AutoLootConfig.UseOtherFilter() && AutoLootConfig.ChosenOtherValue() >= 1 )
				{
					if( cInv.GetItemPrice(invItemList[i]) < AutoLootConfig.ChosenOtherValue() )
						continue;
				}
			}
			
			//containers with trophies
			if( AutoLootConfig.ProtectTrophies() )
			{
				if( ((W3ActorRemains)container).HasTrophyItems() )
					return true;
			}
			
			//quest containers - note: if e.g. trophies (or stands etc.) protection (see "if's" above this) would be below this function...
			//...then trophies could be looted even if they were protected while "Force Quest..." option was enabled
			if( isQuestContainer(container) || cInv.ItemHasTag(invItemList[i], 'GwintCard') )
			{
				if( AutoLootConfig.ForceQuestLoot() )
					return false;
				else
					return true;
			}
			
			//special containers with facts/clues (Bandit camp/Guarded treasure/Hidden treasure/Smugglers' cache/Spoils of war)
			if( AutoLootConfig.ProtectSpecialContainers() )
			{
				if( container.factOnContainerOpened != "" || container.focusModeHighlight == FMV_Clue )
				{
					if( AutoLootConfig.ForceQuestLoot() )
						return false;
					else
						return true;
				}
			}
			
			//containers with GREEN(witcher) schematics (like Scavenger Hunt missions) - optional but RECOMMENDED! option
			//...the line below(=the origin "if") discarded (no need for NG): FIX when diagrams weren't looted with AutoLoot (Filters=ON/Formula filter=OFF) but a quest was marked as "completed"
			//if( (AutoLootConfig.FiltersEnabled() && !AutoLootConfig.UseFormulaFilter()) || AutoLootConfig.ProtectWitcherSchematics() )
			if( AutoLootConfig.ProtectWitcherSchematics() )
			{
				/* //discarded: the origin way with Viper Gear Expanded (VGE) mod support (www.nexusmods.com/witcher3/mods/3828)
				if( (W3treasureHuntContainer)container )
					return true;
				else if( StrFindFirst((string)container,"Viper")>=0 )
				{
					if( StrFindFirst((string)container,"1")>=0
						|| StrFindFirst((string)container,"2")>=0
						|| StrFindFirst((string)container,"3")>=0 )
						return true;
				}
				*/
				if( IsFormula(container, invItemList[i]) && cInv.GetItemQuality(invItemList[i]) == 5 )
					return true;
			}
			
			//herbs in the garden in Corvo Bianco
			if( AutoLootConfig.ProtectHerbsCorvoBianco() )
			{
				if( StrFindFirst((string)container,"quests\minor_quests\mq7024_home\entities\garden")>=0 && IsHerb(container, invItemList[i]) )
					return true;
			}
			
			//bee hives
			if( AutoLootConfig.ProtectBeehives() )
			{
				if( StrFindFirst((string)container,"\beehive")>=0 || StrFindFirst((string)container,"\bee_hive")>=0 )
					return true;
			}
			
			//dropped loot by the player
			if( AutoLootConfig.ProtectDroppedItems() )
			{
				if( ((W3ActorRemains)container).HasTag('lootbag') )
					return true;
			}
			
			//looting if you ride a horse
			if( AutoLootConfig.NoHorseLooting() )
			{
				if( thePlayer.IsUsingHorse() )
					return true;
			}
			
			return false;
		}
		
		return true;
	}
	
	//Check if container has a quest item
	public function isQuestContainer(container : W3Container) : bool
	{
		if( container.HasQuestItem()
		//a) quest-like items
			|| StrFindFirst((string)container,"q001_beggining\entities\q001_geralt_items_container")>=0 //Witcher Steel/Silver swords in Kaer Morhen (not possible to loot until range edited > 30)
			|| StrFindFirst((string)container,"custom_events\prologue\wyzima_castle\lw_hidden_loot.w2ent")>=0 //chest in secret room in Royal Palace
			|| StrFindFirst((string)container,"quests\part_1\quest_files\q401_konsylium\entities\q401_troll_stump")>=0 //"The Final Trial" quest - no loot for your weapons in Kaer Morhen if you 'temporarily' leave them to trolls
			|| StrFindFirst((string)container,"quests\part_3\quest_files\q111_imlerith\entities\q111_imlerith_body.w2ent")>=0 //"Bald Mountain" quest - Magic acorn (food that grants 2 Ability Points)
			|| StrFindFirst((string)container,"quests\main_quests\quest_files\q701_wine_festival\entities\q701_beast_pictures.w2ent")>=0 //"Envoys, Wineboys" quest - 3x drawings
			|| StrFindFirst((string)container,"quests\minor_quests\quest_files\mq7024_home\entities\wine_wars_bottles_container.w2ent")>=0 //Geralt's wine in the cellar in Corvo Bianco
			|| StrFindFirst((string)container,"quests\main_quests\quest_files\q701_wine_festival\entities\q701_gardens_lost_ring.w2ent")>=0 //Lost ring (just a small side quest in Toussaint)
			|| StrFindFirst((string)container,"quests\sansretour_marsh\poi_san_a_01\poi_san_a_01_treasure.w2ent")>=0 //"Applied Escapology" quest - a chest which should be locked and opened by the key
			|| StrFindFirst((string)container,"quests\main_quests\quest_files\q702_hunt\entities\q702_marlena_dowry.w2ent")>=0 //"The Hunger Game" quest (the house from "La Cage au Fou" quest) - barrel with the reward
			|| StrFindFirst((string)container,"quests\main_quests\quest_files\q703_all_for_one\entities\q703_note_napkin_love_letter_container.w2ent")>=0 //"The Man from Cintra" quest - love letter
			|| StrFindFirst((string)container,"quest_items\q703\q703_heart_of_toussaint_container.w2ent")>=0 //"The Man from Cintra" quest - valuable jewel
			|| StrFindFirst((string)container,"quests\main_quests\quest_files\q704_truth\entities\q704_dropped_")>=0 //"What Lies Unseen" quest - dropped items
			|| StrFindFirst((string)container,"quests\caroberta_woods\poi_car_a_11\poi_car_a_11_treasure.w2ent")>=0 //"Spoontaneous Profits!" quest - a chest with the final loot
			|| StrFindFirst((string)container,"dlcqueststrangephenomenon\data\entities\papers_")>=0 //"New Quest - Strange things" DLC mod - quest items
		//b) items with forced loot animation/cutscene
			|| StrFindFirst((string)container,"quests\minor_quests\quest_files\mq7001_rest_in_peace\entities\mq7001_gwent_book.w2ent")>=0 //Ode to Gwent book in Toussaint (The Gran'place)
			|| StrFindFirst((string)container,"quests\minor_quests\quest_files\mq7011_wheres_my_money\entities\mq7011_flier")>=0 //books in Toussaint's bank (The Gran'place)
			|| StrFindFirst((string)container,"quests\minor_quests\quest_files\mq7011_wheres_my_money\entities\mq7011_book")>=0 //books in Toussaint's bank (The Gran'place)
			|| StrFindFirst((string)container,"quests\minor_quests\quest_files\mq7017_talking_horse\entities\mq7017_potato_sack.w2ent")>=0 //potatoes near Pinastri in Toussaint (Equine Phantoms quest)
			|| StrFindFirst((string)container,"quests\minor_quests\quest_files\mq7004_bleeding_tree\entities\mq7004_container_witch_notes_0")>=0 //"A Knight's Tales" quest - 3x books
			|| StrFindFirst((string)container,"quests\main_quests\quest_files\q702_hunt\entities\q702_spoon_key.w2ent")>=0 //"La Cage au Fou"/"Spoontaneous Profits!" quests - Spoon key
			|| StrFindFirst((string)container,"quests\main_quests\quest_files\q702_hunt\entities\q702_wight_diary.w2ent")>=0 //"La Cage au Fou"/"Spoontaneous Profits!" quests - Stained diary book
			|| StrFindFirst((string)container,"quests\main_quests\quest_files\q702_hunt\entities\q702_wight_green_mutagen.w2ent")>=0 //"La Cage au Fou"/"Spoontaneous Profits!" quests - Green mutagen
			|| StrFindFirst((string)container,"quests\main_quests\quest_files\q702_hunt\entities\q702_victims_names.w2ent")>=0 //"Where Children Toil, Toys Waste Away" quest - a letter which starts in-game cutscene
			|| StrFindFirst((string)container,"quests\main_quests\quest_files\q702_hunt\entities\q702_blackmail_letter.w2ent")>=0 //"Where Children Toil, Toys Waste Away" quest - a letter which starts in-game cutscene
		//c) relic/witcher items
			|| StrFindFirst((string)container,"quests\minor_quests\no_mans_land\quest_files\mq1060_devils_pit\entities\mq1060_nilfgaardian_armor_loot.w2ent")>=0 //chest with Nilfgaardian armor + gloves
			|| StrFindFirst((string)container,"quests\quest_files\entities\mq1058_lynx_chest.w2ent")>=0 //"Take What You Want" quest - Teigr steel witcher sword (scales with your level when found)
			|| StrFindFirst((string)container,"container_definitions\autogen\chest_open_q603_ofir_crossbow_relic")>=0 //Ofieri crossbow in Oxenfurt - you will get it during "Open Sesame!" (HoS)
			|| StrFindFirst((string)container,"quests\quest_files\q604_mansion\entites\q604_shovel.w2ent")>=0 //"Scenes From a Marriage" quest - The Caretaker's spade (secondary weapon from HoS)
			|| StrFindFirst((string)container,"container_definitions\ep2_loot_sword_silver_2.w2ent")>=0 //Casus Foederis silver sword (Toussaint)
			|| StrFindFirst((string)container,"container_definitions\ep2_loot_q702_vampire_")>=0 //Tesham Mutna armor set (Toussaint)
			|| StrFindFirst((string)container,"container_definitions\ep2_loot_q704_vampire_")>=0 //Hen Gaidth armor set (Toussaint)
			|| StrFindFirst((string)container,"quests\minor_quests\quest_files\mq7006_the_paths_of_destiny\entities\mq7006_aerondight_cont.w2ent")>=0 //Aerondight silver sword (Toussaint)
			|| StrFindFirst((string)container,"quests\main_quests\quest_files\q704_truth\entities\q704_vampire_sword_container.w2ent")>=0 //"What Lies Unseen" quest - Cantata silver sword
			|| StrFindFirst((string)container,"quests\main_quests\quest_files\q704b_fairy_tale\entities\q704_ft_knight_loot")>=0 //"Beyond Hill and Dale..." quest - Toussaint set + Vitis steel sword
			|| StrFindFirst((string)container,"quests\main_quests\quest_files\q704b_fairy_tale\entities\q704_ft_bonfire_loot.w2ent")>=0 //"Beyond Hill and Dale..." quest - Gesheft (Stigsel) silver sword
		//d) trophies (BaW)
			|| StrFindFirst((string)container,"quests\main_quests\quest_files\q702_hunt\entities\remains__monster_trophy_q702_wight.w2ent")>=0 //"La Cage au Fou" quest - Wight trophy
			|| StrFindFirst((string)container,"quests\minor_quests\quest_files\mq7009_painter\entities\mq7009_gryphon_corpse.w2ent")>=0 //"A Portrait of the Witcher as an Old Man" quest - Griffin trophy
			|| StrFindFirst((string)container,"items\remains\remains__monster_01\remains__monster_trophy_cockatrice_01.w2ent")>=0 //"Mutual of Beauclair's Wild Kingdom - Silver basilisk trophy
			|| (StrFindFirst((string)container,"items\remains\remains__monster_01\remains__monster_01.w2ent")>=0 && container.GetInventory().GetItemQuantityByName('mq7002_spriggan_trophy') > 0) //"Feet as Cold as Ice" quest - Grottore trophy
		/* e) another quest related container packs/or just items (currently not used):
			|| StrFindFirst((string)container,"quests\part_2\quest_files")>=0
			|| StrFindFirst((string)container,"quests\part_3\quest_files")>=0
			|| StrFindFirst((string)container,"quests\quest_files")>=0
			|| StrFindFirst((string)container,"quests\generic_quests")>=0
			|| StrFindFirst((string)container,"quests\sidequests")>=0
			|| StrFindFirst((string)container,"quests\minor_quests\mq3016_wandering_bards\mq3016_equ_container.w2l")>=0 //"Novigrad Hospitality" quest (no loot for your temporarily stolen items) ...no need anymore
			|| StrFindFirst((string)container,"container_definitions\autogen\stone_coffin_q603_ofir_sword.w2ent")>=0 //Ofieri Kilij - steel sword (HoS) ...first location
			|| StrFindFirst((string)container,"chest_wooden_container_q604_ofir_sabre_1.w2ent")>=0 //Ofieri Kilij - steel sword (HoS) ...second location
			|| StrFindFirst((string)container,"quests\main_quests\quest_files\q701_wine_festival\entities\q701_victim_personal_items_loot.w2ent")>=0 //"The Beast of Toussaint" quest - handkerchief
		*/
			)
			return true;
		
		return false;
	}
	
	//Checks if looting the container would be considered stealing
	public function IsNotStealing(container : W3Container) : bool
	{
		if( container.disableStealing )
			return true;
		
		return false;
	}
	
	//Checks if the container is a corpse
	public function IsCorpse(container : W3Container) : bool
	{
		if( (W3ActorRemains)container && !(((W3ActorRemains)container).HasTag('lootbag')) )
			return true;
		
		return false;
	}
	
	//Checks if the container is dropped loot by the player
	public function IsDropped(container : W3Container) : bool
	{
		if( ((W3ActorRemains)container).HasTag('lootbag') )
			return true;
		
		return false;
	}
	
	//Checks if the container is a plant, or if the item in the container is a plant
	public function IsHerb(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( (W3Herb)container )
			return true;
		
		if( container.GetInventory().GetItemName(itemID) == 'Buckthorn' )
			return true;
		
		if( container.GetInventory().ItemHasTag(itemID, 'HerbGameplay') )
			return true;
		
		return false;
	}
	
	//Checks if the container is a plant, or if the item in the container is a plant (with Quantity setting)
	public function IsHerbQt(container : W3Container, itemID : SItemUniqueId) : bool
	{
		itemName = container.GetInventory().GetItemName(itemID);
		
		if( IsHerb(container, itemID) )
		{
			if( AutoLootConfig.ChosenHerbQuantity() == 0 )
				return true;
			else if( AutoLootConfig.ChosenHerbQuantity() >= 1 )
				return (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenHerbQuantity();
		}
		
		return false;
	}
	
	//Checks if the item is armor
	public function IsArmor(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( container.GetInventory().IsItemAnyArmor(itemID) && !container.GetInventory().IsItemQuickslotItem(itemID) )
			return true;
		
		return false;
	}
	
	//Checks if the item is an armor (with Quality and Value setting)
	public function IsArmorQV(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( IsArmor(container, itemID) )
		{
			if( AutoLootConfig.ChosenArmorQuality() == 0 && AutoLootConfig.ChosenArmorValue() == 0 )
				return true;
			else if( AutoLootConfig.ChosenArmorQuality() == 0 )
				return container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenArmorValue();
			else if( AutoLootConfig.ChosenArmorQuality() >= 1 && AutoLootConfig.ChosenArmorQuality() <= 5 )
				return container.GetInventory().GetItemQuality(itemID) == AutoLootConfig.ChosenArmorQuality()
					&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenArmorValue();
			else if( AutoLootConfig.ChosenArmorQuality() == 6 )
				return container.GetInventory().GetItemQuality(itemID) <= 2
					&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenArmorValue();
			else if( AutoLootConfig.ChosenArmorQuality() == 7 )
				return container.GetInventory().GetItemQuality(itemID) <= 3
					&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenArmorValue();
			else if( AutoLootConfig.ChosenArmorQuality() == 8 )
				return container.GetInventory().GetItemQuality(itemID) <= 4
					&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenArmorValue();
			else if( AutoLootConfig.ChosenArmorQuality() == 9 )
				return container.GetInventory().GetItemQuality(itemID) >= 2
					&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenArmorValue();
			else if( AutoLootConfig.ChosenArmorQuality() == 10 )
				return container.GetInventory().GetItemQuality(itemID) >= 3
					&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenArmorValue();
			else if( AutoLootConfig.ChosenArmorQuality() == 11 )
				return container.GetInventory().GetItemQuality(itemID) >= 4
					&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenArmorValue();
		}
		
		return false;
	}
	
	//Checks if the item is a weapon or torch
	public function IsWeapon(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( container.GetInventory().IsItemWeapon(itemID) || container.GetInventory().ItemHasTag(itemID, 'UI_Torch') )
			return true;
		
		return false;
	}
	
	//Checks if the item is a weapon (with Quality and Value setting)
	public function IsWeaponQV(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( IsWeapon(container, itemID) )
		{
			if( AutoLootConfig.ChosenWeaponQuality() == 0 && AutoLootConfig.ChosenWeaponValue() == 0 )
				return true;
			else if( AutoLootConfig.ChosenWeaponQuality() == 0 )
				return container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenWeaponValue();
			else if( AutoLootConfig.ChosenWeaponQuality() >= 1 && AutoLootConfig.ChosenWeaponQuality() <= 5 )
				return container.GetInventory().GetItemQuality(itemID) == AutoLootConfig.ChosenWeaponQuality()
					&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenWeaponValue();
			else if( AutoLootConfig.ChosenWeaponQuality() == 6 )
				return container.GetInventory().GetItemQuality(itemID) <= 2
					&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenWeaponValue();
			else if( AutoLootConfig.ChosenWeaponQuality() == 7 )
				return container.GetInventory().GetItemQuality(itemID) <= 3
					&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenWeaponValue();
			else if( AutoLootConfig.ChosenWeaponQuality() == 8 )
				return container.GetInventory().GetItemQuality(itemID) <= 4
					&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenWeaponValue();
			else if( AutoLootConfig.ChosenWeaponQuality() == 9 )
				return container.GetInventory().GetItemQuality(itemID) >= 2
					&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenWeaponValue();
			else if( AutoLootConfig.ChosenWeaponQuality() == 10 )
				return container.GetInventory().GetItemQuality(itemID) >= 3
					&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenWeaponValue();
			else if( AutoLootConfig.ChosenWeaponQuality() == 11 )
				return container.GetInventory().GetItemQuality(itemID) >= 4
					&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenWeaponValue();
		}
		
		return false;
	}
	
	//Checks if the item is an ingredient/Dye/"Bottomless carafe" (also excludes Herbs)
	public function IsIngredient(container : W3Container, itemID : SItemUniqueId) : bool
	{
		//excluding mutagens
		if( container.GetInventory().ItemHasTag(itemID, 'MutagenIngredient') )
			return false;
		
		//excluding herbs
		if( (W3Herb)container
			|| container.GetInventory().ItemHasTag(itemID, 'HerbGameplay')
			|| container.GetInventory().GetItemName(itemID) == 'Buckthorn' )
			return false;
		
		if( container.GetInventory().IsItemIngredient(itemID) )
			return true;
		
		//"Bottomless carafe" item = an exception labeled as an alchemy ingredient but placed in "Other" tab
		if( container.GetInventory().GetItemName(itemID) == 'Soltis Vodka' )
			return true;
		
		return false;
	}
	
	//Checks if the item is an ingredient (with Quality / Value / Quantity setting)
	public function IsIngredientQVQt(container : W3Container, itemID : SItemUniqueId) : bool
	{
		itemName = container.GetInventory().GetItemName(itemID);
		
		if( IsIngredient(container, itemID) )
		{
			if( AutoLootConfig.ChosenIngredientQuality() == 0 && AutoLootConfig.ChosenIngredientValue() == 0 && AutoLootConfig.ChosenIngredientQuantity() == 0 )
				return true;
			else if( AutoLootConfig.ChosenIngredientQuality() >= 1 && AutoLootConfig.ChosenIngredientValue() == 0 && AutoLootConfig.ChosenIngredientQuantity() == 0 )
			{
				if( AutoLootConfig.ChosenIngredientQuality() <= 4 )
					return container.GetInventory().GetItemQuality(itemID) == AutoLootConfig.ChosenIngredientQuality();
				else if( AutoLootConfig.ChosenIngredientQuality() == 5 )
					return container.GetInventory().GetItemQuality(itemID) <= 2;
				else if( AutoLootConfig.ChosenIngredientQuality() == 6 )
					return container.GetInventory().GetItemQuality(itemID) <= 3;
				else if( AutoLootConfig.ChosenIngredientQuality() == 7 )
					return container.GetInventory().GetItemQuality(itemID) >= 2;
				else if( AutoLootConfig.ChosenIngredientQuality() == 8 )
					return container.GetInventory().GetItemQuality(itemID) >= 3;
			}
			else if( AutoLootConfig.ChosenIngredientQuality() == 0 && AutoLootConfig.ChosenIngredientValue() >= 1 && AutoLootConfig.ChosenIngredientQuantity() == 0 )
				return container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenIngredientValue();
			else if( AutoLootConfig.ChosenIngredientQuality() == 0 && AutoLootConfig.ChosenIngredientValue() == 0 && AutoLootConfig.ChosenIngredientQuantity() >= 1 )
				return (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenIngredientQuantity();
			else if( AutoLootConfig.ChosenIngredientQuality() >= 1 && AutoLootConfig.ChosenIngredientValue() >= 1 && AutoLootConfig.ChosenIngredientQuantity() == 0 )
			{
				if( AutoLootConfig.ChosenIngredientQuality() <= 4 )
					return container.GetInventory().GetItemQuality(itemID) == AutoLootConfig.ChosenIngredientQuality()
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenIngredientValue();
				else if( AutoLootConfig.ChosenIngredientQuality() == 5 )
					return container.GetInventory().GetItemQuality(itemID) <= 2
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenIngredientValue();
				else if( AutoLootConfig.ChosenIngredientQuality() == 6 )
					return container.GetInventory().GetItemQuality(itemID) <= 3
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenIngredientValue();
				else if( AutoLootConfig.ChosenIngredientQuality() == 7 )
					return container.GetInventory().GetItemQuality(itemID) >= 2
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenIngredientValue();
				else if( AutoLootConfig.ChosenIngredientQuality() == 8 )
					return container.GetInventory().GetItemQuality(itemID) >= 3
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenIngredientValue();
			}
			else if( AutoLootConfig.ChosenIngredientQuality() >= 1 && AutoLootConfig.ChosenIngredientValue() == 0 && AutoLootConfig.ChosenIngredientQuantity() >= 1 )
			{
				if( AutoLootConfig.ChosenIngredientQuality() <= 4 )
					return container.GetInventory().GetItemQuality(itemID) == AutoLootConfig.ChosenIngredientQuality()
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenIngredientQuantity();
				else if( AutoLootConfig.ChosenIngredientQuality() == 5 )
					return container.GetInventory().GetItemQuality(itemID) <= 2
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenIngredientQuantity();
				else if( AutoLootConfig.ChosenIngredientQuality() == 6 )
					return container.GetInventory().GetItemQuality(itemID) <= 3
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenIngredientQuantity();
				else if( AutoLootConfig.ChosenIngredientQuality() == 7 )
					return container.GetInventory().GetItemQuality(itemID) >= 2
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenIngredientQuantity();
				else if( AutoLootConfig.ChosenIngredientQuality() == 8 )
					return container.GetInventory().GetItemQuality(itemID) >= 3
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenIngredientQuantity();
			}
			else if( AutoLootConfig.ChosenIngredientQuality() == 0 && AutoLootConfig.ChosenIngredientValue() >= 1 && AutoLootConfig.ChosenIngredientQuantity() >= 1 )
			{
				return container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenIngredientValue()
					&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenIngredientQuantity();
			}
			else if( AutoLootConfig.ChosenIngredientQuality() >= 1 && AutoLootConfig.ChosenIngredientValue() >= 1 && AutoLootConfig.ChosenIngredientQuantity() >= 1 )
			{
				if( AutoLootConfig.ChosenIngredientQuality() <= 4 )
					return container.GetInventory().GetItemQuality(itemID) == AutoLootConfig.ChosenIngredientQuality()
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenIngredientValue()
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenIngredientQuantity();
				else if( AutoLootConfig.ChosenIngredientQuality() == 5 )
					return container.GetInventory().GetItemQuality(itemID) <= 2
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenIngredientValue()
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenIngredientQuantity();
				else if( AutoLootConfig.ChosenIngredientQuality() == 6 )
					return container.GetInventory().GetItemQuality(itemID) <= 3
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenIngredientValue()
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenIngredientQuantity();
				else if( AutoLootConfig.ChosenIngredientQuality() == 7 )
					return container.GetInventory().GetItemQuality(itemID) >= 2
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenIngredientValue()
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenIngredientQuantity();
				else if( AutoLootConfig.ChosenIngredientQuality() == 8 )
					return container.GetInventory().GetItemQuality(itemID) >= 3
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenIngredientValue()
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenIngredientQuantity();
			}
		}
		
		return false;
	}
	
	//Checks if the item is a junk ONLY
	public function IsJunk(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( container.GetInventory().IsItemJunk(itemID) )
			return true;
		
		return false;
	}
	
	//Checks if the item is a junk (with Quality / Value / Quantity setting)
	public function IsJunkQVQt(container : W3Container, itemID : SItemUniqueId) : bool
	{
		itemName = container.GetInventory().GetItemName(itemID);
		
		if( IsJunk(container, itemID) )
		{
			if( AutoLootConfig.ChosenJunkQuality() == 0 && AutoLootConfig.ChosenJunkValue() == 0 && AutoLootConfig.ChosenJunkQuantity() == 0 )
				return true;
			else if( AutoLootConfig.ChosenJunkQuality() >= 1 && AutoLootConfig.ChosenJunkValue() == 0 && AutoLootConfig.ChosenJunkQuantity() == 0 )
			{
				if( AutoLootConfig.ChosenJunkQuality() <= 4 )
					return container.GetInventory().GetItemQuality(itemID) == AutoLootConfig.ChosenJunkQuality();
				else if( AutoLootConfig.ChosenJunkQuality() == 5 )
					return container.GetInventory().GetItemQuality(itemID) <= 2;
				else if( AutoLootConfig.ChosenJunkQuality() == 6 )
					return container.GetInventory().GetItemQuality(itemID) <= 3;
				else if( AutoLootConfig.ChosenJunkQuality() == 7 )
					return container.GetInventory().GetItemQuality(itemID) >= 2;
				else if( AutoLootConfig.ChosenJunkQuality() == 8 )
					return container.GetInventory().GetItemQuality(itemID) >= 3;
			}
			else if( AutoLootConfig.ChosenJunkQuality() == 0 && AutoLootConfig.ChosenJunkValue() >= 1 && AutoLootConfig.ChosenJunkQuantity() == 0 )
				return container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenJunkValue();
			else if( AutoLootConfig.ChosenJunkQuality() == 0 && AutoLootConfig.ChosenJunkValue() == 0 && AutoLootConfig.ChosenJunkQuantity() >= 1 )
				return (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenJunkQuantity();
			else if( AutoLootConfig.ChosenJunkQuality() >= 1 && AutoLootConfig.ChosenJunkValue() >= 1 && AutoLootConfig.ChosenJunkQuantity() == 0 )
			{
				if( AutoLootConfig.ChosenJunkQuality() <= 4 )
					return container.GetInventory().GetItemQuality(itemID) == AutoLootConfig.ChosenJunkQuality()
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenJunkValue();
				else if( AutoLootConfig.ChosenJunkQuality() == 5 )
					return container.GetInventory().GetItemQuality(itemID) <= 2
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenJunkValue();
				else if( AutoLootConfig.ChosenJunkQuality() == 6 )
					return container.GetInventory().GetItemQuality(itemID) <= 3
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenJunkValue();
				else if( AutoLootConfig.ChosenJunkQuality() == 7 )
					return container.GetInventory().GetItemQuality(itemID) >= 2
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenJunkValue();
				else if( AutoLootConfig.ChosenJunkQuality() == 8 )
					return container.GetInventory().GetItemQuality(itemID) >= 3
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenJunkValue();
			}
			else if( AutoLootConfig.ChosenJunkQuality() >= 1 && AutoLootConfig.ChosenJunkValue() == 0 && AutoLootConfig.ChosenJunkQuantity() >= 1 )
			{
				if( AutoLootConfig.ChosenJunkQuality() <= 4 )
					return container.GetInventory().GetItemQuality(itemID) == AutoLootConfig.ChosenJunkQuality()
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenJunkQuantity();
				else if( AutoLootConfig.ChosenJunkQuality() == 5 )
					return container.GetInventory().GetItemQuality(itemID) <= 2
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenJunkQuantity();
				else if( AutoLootConfig.ChosenJunkQuality() == 6 )
					return container.GetInventory().GetItemQuality(itemID) <= 3
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenJunkQuantity();
				else if( AutoLootConfig.ChosenJunkQuality() == 7 )
					return container.GetInventory().GetItemQuality(itemID) >= 2
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenJunkQuantity();
				else if( AutoLootConfig.ChosenJunkQuality() == 8 )
					return container.GetInventory().GetItemQuality(itemID) >= 3
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenJunkQuantity();
			}
			else if( AutoLootConfig.ChosenJunkQuality() == 0 && AutoLootConfig.ChosenJunkValue() >= 1 && AutoLootConfig.ChosenJunkQuantity() >= 1 )
			{
				return container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenJunkValue()
					&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenJunkQuantity();
			}
			else if( AutoLootConfig.ChosenJunkQuality() >= 1 && AutoLootConfig.ChosenJunkValue() >= 1 && AutoLootConfig.ChosenJunkQuantity() >= 1 )
			{
				if( AutoLootConfig.ChosenJunkQuality() <= 4 )
					return container.GetInventory().GetItemQuality(itemID) == AutoLootConfig.ChosenJunkQuality()
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenJunkValue()
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenJunkQuantity();
				else if( AutoLootConfig.ChosenJunkQuality() == 5 )
					return container.GetInventory().GetItemQuality(itemID) <= 2
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenJunkValue()
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenJunkQuantity();
				else if( AutoLootConfig.ChosenJunkQuality() == 6 )
					return container.GetInventory().GetItemQuality(itemID) <= 3
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenJunkValue()
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenJunkQuantity();
				else if( AutoLootConfig.ChosenJunkQuality() == 7 )
					return container.GetInventory().GetItemQuality(itemID) >= 2
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenJunkValue()
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenJunkQuantity();
				else if( AutoLootConfig.ChosenJunkQuality() == 8 )
					return container.GetInventory().GetItemQuality(itemID) >= 3
						&& container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenJunkValue()
						&& (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenJunkQuantity();
			}
		}
		
		return false;
	}
	
	//Checks if the item can be read (books, maps, etc.) - UNREAD texts only
	public function IsReadable(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( container.GetInventory().IsRecipeOrSchematic(itemID)
			|| container.GetInventory().IsBookRead(itemID) )
			return false;
		
		if( container.GetInventory().IsItemReadable(itemID) )
			return true;
		
		if( container.GetInventory().ItemHasTag(itemID, 'Painting') )
			return true;
		
		return false;
	}
	
	//Checks if the item can be read (books, maps, etc.) - ALREADY READ texts only
	public function IsAlreadyRead(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( container.GetInventory().IsRecipeOrSchematic(itemID) )
			return false;
		
		if( (container.GetInventory().IsItemReadable(itemID) || container.GetInventory().ItemHasTag(itemID, 'Painting')) && container.GetInventory().IsBookRead(itemID) )
			return true;
		
		return false;
	}
	
	//Checks if the item can be read (UNREAD and READ with Quantity setting)
	public function IsBookQt(container : W3Container, itemID : SItemUniqueId) : bool
	{
		itemName = container.GetInventory().GetItemName(itemID);
		
		if( (IsReadable(container, itemID) && AutoLootConfig.UseReadableFilter()) || (IsAlreadyRead(container, itemID) && AutoLootConfig.UseAlreadyReadFilter()) )
		{
			if( AutoLootConfig.ChosenBookQuantity() == 0 || thePlayer.GetInventory().GetItemQuantityByName(itemName) == 0 )
				return true;
			else if( AutoLootConfig.ChosenBookQuantity() >= 1 )
				return (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenBookQuantity();
		}
		
		return false;
	}
	
	//Checks if the item is a form of currency
	public function IsCurrency(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( container.GetInventory().GetItemName(itemID) == 'Crowns' )
			return true;
		
		if( container.GetInventory().GetItemName(itemID) == 'Florens' )
			return true;
		
		if( container.GetInventory().GetItemName(itemID) == 'Orens' )
			return true;
		
		return false;
	}
	
	//Checks if the item is a form of currency (with Quantity setting)
	public function IsCurrencyQt(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( IsCurrency(container, itemID) )
		{
			if( AutoLootConfig.ChosenCurrencyQuantity() == 0 )
				return true;
			else if( AutoLootConfig.ChosenCurrencyQuantity() >= 1 )
				return container.GetInventory().GetItemQuantity(itemID) >= AutoLootConfig.ChosenCurrencyQuantity();
		}
		
		return false;
	}
	
	//Checks if the item is food/drink
	public function IsFood(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( container.GetInventory().IsItemFood(itemID) )
			return true;
		
		return false;
	}
	
	//Checks if the item is a food/drink (with Value / Quantity setting)
	public function IsFoodVQt(container : W3Container, itemID : SItemUniqueId) : bool
	{
		itemName = container.GetInventory().GetItemName(itemID);
		
		if( IsFood(container, itemID) )
		{
			if( AutoLootConfig.ChosenFoodValue() == 0 && AutoLootConfig.ChosenFoodQuantity() == 0 )
				return true;
			else if( AutoLootConfig.ChosenFoodValue() >= 1 && AutoLootConfig.ChosenFoodQuantity() == 0 )
				return container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenFoodValue();
			else if( AutoLootConfig.ChosenFoodValue() == 0 && AutoLootConfig.ChosenFoodQuantity() >= 1 )
				return (thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenFoodQuantity();
			else if( AutoLootConfig.ChosenFoodValue() >= 1 && AutoLootConfig.ChosenFoodQuantity() >= 1 )
				return container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenFoodValue()
					&& ((thePlayer.GetInventory().GetItemQuantityByName(itemName) + container.GetInventory().GetItemQuantity(itemID)) <= AutoLootConfig.ChosenFoodQuantity());
		}
		
		return false;
	}
	
	//Checks if the item is a glyph/runestone/mutagen
	public function IsUpgrade(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( container.GetInventory().IsItemUpgrade(itemID) )
			return true;
		
		if( container.GetInventory().ItemHasTag(itemID, 'MutagenIngredient') )
			return true;
		
		return false;
	}
	
	//Checks if the item is a glyph/runestone/mutagen (with Value setting)
	public function IsUpgradeV(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( IsUpgrade(container, itemID) )
		{
			if( AutoLootConfig.ChosenUpgradeValue() == 0 )
				return true;
			else if( AutoLootConfig.ChosenUpgradeValue() >= 1 )
				return container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenUpgradeValue();
		}
		
		return false;
	}
	
	//Checks if the item is horse equipment (Blinders, Saddles, Saddlebags)
	public function IsHorse(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( container.GetInventory().IsItemBlinders(itemID) )
			return true;
		
		if( container.GetInventory().IsItemHorseBag(itemID) )
			return true;
		
		if( container.GetInventory().IsItemSaddle(itemID) )
			return true;
		
		return false;
	}
	
	//Checks if the item is horse equipment (Blinders, Saddles, Saddlebags) ...(with Value setting)
	public function IsHorseV(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( IsHorse(container, itemID) )
		{
			if( AutoLootConfig.ChosenHorseValue() == 0 )
				return true;
			else if( AutoLootConfig.ChosenHorseValue() >= 1 )
				return container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenHorseValue();
		}
		
		return false;
	}
	
	//Checks if the item is a trophy
	public function IsTrophy(container : W3Container, itemID : SItemUniqueId) : bool
	{
		//Note: "((W3ActorRemains)container).HasTrophyItems()" command loots everything from container if there is a trophy
		if( container.GetInventory().IsItemTrophy(itemID) )
			return true;
		
		return false;
	}
	
	//Checks if the item is a trophy (with Value setting)
	public function IsTrophyV(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( IsTrophy(container, itemID) )
		{
			if( AutoLootConfig.ChosenTrophyValue() == 0 )
				return true;
			else if( AutoLootConfig.ChosenTrophyValue() >= 1 )
				return container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenTrophyValue();
		}
		
		return false;
	}
	
	//Checks if the item is a tool (Repair Kit)
	public function IsTool(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( container.GetInventory().IsItemTool(itemID) )
			return true;
		
		return false;
	}
	
	//Checks if the item is a tool (Repair Kit) ...(with Value setting)
	public function IsToolV(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( IsTool(container, itemID) )
		{
			if( AutoLootConfig.ChosenToolValue() == 0 )
				return true;
			else if( AutoLootConfig.ChosenToolValue() >= 1 )
				return container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenToolValue();
		}
		
		return false;
	}
	
	//Checks if the item is "Other" category = "Quest Items/Other" tab (not "Other" category in the "Weapons/Armor" inventory tab)
	public function IsOther(container : W3Container, itemID : SItemUniqueId) : bool
	{
		itemName = container.GetInventory().GetItemName(itemID);
		itemCategory = container.GetInventory().GetItemCategory(itemID);
		
		//excluding Readable
		if( container.GetInventory().IsRecipeOrSchematic(itemID)
			|| container.GetInventory().IsItemReadable(itemID)
			|| container.GetInventory().ItemHasTag(itemID, 'Painting') )
			return false;
		
		if( itemCategory == 'misc'
			&& !StrContains(NameToString(itemName), "key") //excluding Keys
			&& !StrContains(NameToString(itemName), "mh107_fiend_dung") ) //excluding Fiend dung (an alchemy ingredient but labeled as an "Other" type)
			return true;
		
		return false;
	}
	
	//Checks if the item is "Other" category = "Quest Items/Other" tab (with Value setting)
	public function IsOtherV(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( IsOther(container, itemID) )
		{
			if( AutoLootConfig.ChosenOtherValue() == 0 )
				return true;
			else if( AutoLootConfig.ChosenOtherValue() >= 1 )
				return container.GetInventory().GetItemPrice(itemID) >= AutoLootConfig.ChosenOtherValue();
		}
		
		return false;
	}
	
	//Checks if the item is a recipe or schematic
	public function IsFormula(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( container.GetInventory().IsRecipeOrSchematic(itemID) )
			return true;
		
		return false;
	}
	
	//Checks if the item is a mask
	public function IsMask(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if( container.GetInventory().IsItemMask(itemID) )
			return true;
		
		return false;
	}
	
	//Checks if the item is a Key ...(keys can be "Other" or "Key" category)
	public function IsKey(container : W3Container, itemID : SItemUniqueId) : bool
	{
		itemName = container.GetInventory().GetItemName(itemID);
		itemCategory = container.GetInventory().GetItemCategory(itemID);
		
		if( container.GetInventory().IsRecipeOrSchematic(itemID)
			|| container.GetInventory().IsItemReadable(itemID)
			|| container.GetInventory().ItemHasTag(itemID, 'Painting') )
			return false;
		
		if( itemCategory == 'key' )
			return true;
		
		if( itemCategory == 'misc' && StrContains(NameToString(itemName), "key") )
			return true;
		
		return false;
	}
}