/***********************************************************************/
/** 	AHDAutoLootFeatureManager.ws
/** 	by AeroHD
/**		Original AutoLoot code by JupiterTheGod
/**		mod: AutoLoot Advanced Settings (AutoLoot +A.S.) by jerry18
/***********************************************************************/



class CAHDAutoLootFeatureManager
{
	private var isInitialized : bool;
	private var AutoLootConfig : CAHDAutoLootConfig;
	private var currentLootTriggerType : int; //0 = Auto/Silent, 1 = Container, 2 = GatherHerbs, 3 = Unique Container (Quest/(Un)Locked etc)
	
				
	
	//Registers the keybinding listeners
	public function Init() : void
	{
		AutoLootConfig = GetWitcherPlayer().GetAutoLootConfig();
		
		theInput.RegisterListener( this, 'OnDefaultInteractKey', 'Container' );
		
		isInitialized = true;
	}
	
	//Returns true if player pressed Interaction Key ('E' on PC)
	//NOTE: e.g. 'Container' can be probably replaced by any action bound to 'E' (like 'Use') and it still works (so maybe only e.g. 'Container' is enough)
	public final function WasInteractionKeyPressed() : bool
	{
		//If we are currently inside an 'E' key looting sequence, return true
		if( currentLootTriggerType > 0 )
		{
			return true;
		}
		
		//Fallback for the exact frame when the key is pressed
		if( theInput.IsActionJustPressed('Container')
			|| theInput.IsActionJustPressed('GatherHerbs')
			|| theInput.IsActionJustPressed('Unlock')
			|| theInput.IsActionJustPressed('Take')
			|| theInput.IsActionJustPressed('Loot')
			)
		{
			return true;
		}
		
		return false;
	}
	
	//Sets the current loot trigger type at the start of the 'E' key looting sequence
	public function SetCurrentLootTriggerType(type : int) : void
	{
		currentLootTriggerType = type;
	}
	
	//Resets the loot trigger type back to default once looting is completed
	public function ResetLootTriggerType() : void
	{
		currentLootTriggerType = 0;
	}
	
	//Returns the container type of the targeted container
	public final function GetInteractionKeyContainerType() : int
	{
		var displayTarget : CGameplayEntity;
		var targetContainer : W3Container;
		var targetHerb : W3Herb;
		
		//If a loot trigger state is stored for the current loot cycle, return it
		if( currentLootTriggerType > 0 )
		{
			return currentLootTriggerType;
		}
		
		//Fallback check if the stored variable wasn't explicitly set
		if( WasInteractionKeyPressed() )
		{
			displayTarget = (CGameplayEntity)GetWitcherPlayer().GetDisplayTarget();
			
			if( displayTarget )
			{
				targetContainer = (W3Container)displayTarget;
				targetHerb = (W3Herb)displayTarget;
				
				if( targetContainer )
				{
					if( targetHerb )
					{
						//GetWitcherPlayer().DisplayHudMessage("'E' pressed to loot Herb; (Type=2)");
						return 2; //Gathered Herb
					}
					
					//1) Quest/(Un)Locked containers
					if( AutoLootConfig.GetFilters().isQuestContainer(targetContainer)	//quest containers
						|| (W3treasureHuntContainer)targetContainer						//containers with witcher_(green) schematics (Scavenger Hunt missions)
						|| IsNameValid(targetContainer.GetKeyName())					//(Un)locked containers
						|| targetContainer.IsLocked() || targetContainer.lockedByKey	//alt. to GetKeyName(): probably doesn't work though
						)
					{
						//GetWitcherPlayer().DisplayHudMessage("'E' pressed on Unique container (Quest/(Un)Locked)/Witcher shematics; (Type=3)");
						return 3;
					}
					
					//2) Special containers (Bandit camp/Guarded treasure/Hidden treasure/Smugglers' cache/Spoils of war)
					if( AutoLootConfig.ProtectSpecialContainers() )
					{
						if( targetContainer.factOnContainerOpened != "" || targetContainer.focusModeHighlight == FMV_Clue )
						{
							if( !AutoLootConfig.ForceQuestLoot() )
							{
								//GetWitcherPlayer().DisplayHudMessage("'E' pressed on Unique container (cache, treasure etc); (Type=3)");
								return 3;
							}
						}
					}
					
					//3) Containers with trophies
					if( AutoLootConfig.ProtectTrophies() )
					{
						if( ((W3ActorRemains)targetContainer).HasTrophyItems() )
						{
							//GetWitcherPlayer().DisplayHudMessage("'E' pressed on Unique container (with Trophy); (Type=3)");
							return 3;
						}
					}
					
					//4) Bee hives
					if( AutoLootConfig.ProtectBeehives() )
					{
						if( StrFindFirst((string)targetContainer,"\beehive")>=0 || StrFindFirst((string)targetContainer,"\bee_hive")>=0 )
						{
							//GetWitcherPlayer().DisplayHudMessage("'E' pressed on Unique container (bee hive); (Type=3)");
							return 3;
						}
					}
					
					//5) Dropped loot by the player
					if( AutoLootConfig.ProtectDroppedItems() )
					{
						if( ((W3ActorRemains)targetContainer).HasTag('lootbag') )
						{
							//GetWitcherPlayer().DisplayHudMessage("'E' pressed on Unique container (dropped); (Type=3)");
							return 3;
						}
					}
					
					//GetWitcherPlayer().DisplayHudMessage("'E' pressed on Common container; (Type=1)");
					return 1; //Common container
				}
			}
		}
		
		return 0;
	}
	
	//Interaction looting processes only the displayed target; it never scans nearby entities.
	public final function OnDefaultInteractKey(action : SInputAction) : void
	{
		var containerType, E_KEY_Logic : int;
		var targetContainer : W3Container;

		if( !isInitialized || !AutoLootConfig.ModEnabled() || !IsPressed(action) )
			return;

		targetContainer = (W3Container)thePlayer.GetDisplayTarget();
		containerType = GetInteractionKeyContainerType();
		if( !targetContainer || containerType == 0 )
			return;

		E_KEY_Logic = AutoLootConfig.GetEkeyLogic();
		//Leave special containers to normal game handling in modes 0 and 1.
		if( containerType == 3 && (E_KEY_Logic == 0 || E_KEY_Logic == 1) )
		{
			ResetLootTriggerType();
			return;
		}

		SetCurrentLootTriggerType(containerType);
		TryTargetLooting(targetContainer);
		ResetLootTriggerType();
	}

	//Use the captured interaction target for both containers and herbs.
	//Protections and item rules are still enforced by the existing processing path.
	private function TryTargetLooting(container : W3Container) : void
	{
		var actualActionName : string;
		if( !container || container.IsEmpty() || AutoLootConfig.GetFilters().IsContainerProtected(container) )
			return;

		if( (W3Herb)container )
			actualActionName = "GatherHerbs";
		else
			actualActionName = "Container";

		//Merge this target's notification without opening additional container interactions.
		container.mergeNotification = true;
		container.OnInteraction(actualActionName, thePlayer);
		container.mergeNotification = false;
		AutoLootConfig.GetNotifications().ShowNotification();
	}
}