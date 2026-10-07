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
	
	private var AHDAL_INTERACT_LOOT,
				AHDAL_RADIUS_LOOT,
				AHDAL_TRUE_AUTOLOOT_MODE : string;
				
		default AHDAL_INTERACT_LOOT = "interact_loot";
		default AHDAL_RADIUS_LOOT = "radius_loot";
		default AHDAL_TRUE_AUTOLOOT_MODE = "true_autoloot_mode";
	
	//Registers the keybinding listeners
	public function Init() : void
	{
		AutoLootConfig = GetWitcherPlayer().GetAutoLootConfig();
		
		theInput.RegisterListener( this, 'OnAutoLootRadiusLoot', 'AutoLootRadius' );
		theInput.RegisterListener( this, 'OnAutoLootRadiusHold', 'AutoLootRadiusHold' );
		theInput.RegisterListener( this, 'OnTrueAutoLoot', 'ToggleTrueAutoLoot' );
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
	
	//Handling the default Interaction key ('E' on PC) for looting items
	public final function OnDefaultInteractKey(action : SInputAction) : void
	{
		var displayTarget : CGameplayEntity;
		var targetContainer : W3Container;
		var targetHerb : W3Herb;
		var E_KEY_Logic, containerType : int;
		var actualActionName : string;
		
		if( AutoLootConfig.ModEnabled() && IsPressed(action) )
		{
			containerType = GetInteractionKeyContainerType();
			E_KEY_Logic = AutoLootConfig.GetEkeyLogic();
			
			if( containerType == 0 )
				return;
			
			//Store the trigger type for the entire looting cycle
			SetCurrentLootTriggerType(containerType);
			
			if( containerType == 3 )
			{
				if( E_KEY_Logic == 0 || E_KEY_Logic == 1 )
				{
					ResetLootTriggerType(); //Reset state on early exit
					return;
				}
				
				if( E_KEY_Logic == 2 )
				{
					displayTarget = thePlayer.GetDisplayTarget();
					targetContainer = (W3Container)displayTarget;
					targetHerb = (W3Herb)displayTarget;
					
					if( targetContainer && !targetContainer.IsEmpty() )
					{
						if( targetHerb )
							actualActionName = "GatherHerbs";
						else
							actualActionName = "Container";
						
						targetContainer.mergeNotification = true;
						targetContainer.OnInteraction(actualActionName, thePlayer);
						targetContainer.mergeNotification = false;
						
						AutoLootConfig.GetNotifications().ShowNotification();
					}
					ResetLootTriggerType(); //Reset state on exit
					return;
				}
			}
			
			if( containerType == 2 )
			{
				TryAreaLooting( AHDAL_INTERACT_LOOT, containerType );
				return;
			}
			
			TryAreaLooting( AHDAL_INTERACT_LOOT, containerType );
		}
	}
	
	//Handles the Radius Loot keybinding
	public final function OnAutoLootRadiusLoot(action : SInputAction) : void
	{
		if( AutoLootConfig.ModEnabled() && IsPressed(action) )
			TryAreaLooting( AHDAL_RADIUS_LOOT );
	}
	
	//Handles the Radius Loot keybinding when holding the key (it is for ignoring Filters and looting everything)
	public final function OnAutoLootRadiusHold(action : SInputAction) : void
	{
		if( AutoLootConfig.ModEnabled() && IsPressed(action) )
			TryAreaLooting( AHDAL_RADIUS_LOOT );
	}
	
	//Handles the True AutoLoot Mode keybinding
	public final function OnTrueAutoLoot(action : SInputAction) : void
	{
		if( AutoLootConfig.ModEnabled() && IsPressed(action) )
		{
			if( !AutoLootConfig.TrueAutoLootEnabled() )
			{
				AutoLootConfig.ToggleTrueAutoLoot();
				TrueAutoLootStart();
			}
			else
			{
				AutoLootConfig.ToggleTrueAutoLoot();
				TrueAutoLootStop();
			}
		}
		
		if( AutoLootConfig.ModEnabled() && OnClosingMenuBugFix() ) //Bug Fix
			AutoLootConfig.ToggleTrueAutoLoot();
	}
	
	//Helper event for the Bug Fix above
	event OnClosingMenuBugFix()
	{
		AutoLootConfig.TryTrueAutoLoot();
	}
	
	//Activates True AutoLoot Mode
	public function TrueAutoLootStart()
	{
		if( AutoLootConfig.ModEnabled()
			&& !theGame.IsDialogOrCutscenePlaying()
			&& !theGame.IsCurrentlyPlayingNonGameplayScene()
			&& theInput.GetContext() != 'Scene' )
			theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("ahdal_trueAutoLootMsg") + ": " + "<font color =\"#197319\">" + GetLocStringByKeyExt("ahdal_enabled") + "</font>", 3000 );
		
		thePlayer.AddTimer('TrueAutoLootMode', 3.0 );
	}
	
	//Deactivates True AutoLoot Mode
	public function TrueAutoLootStop() : void
	{
		if( AutoLootConfig.ModEnabled()
			&& !theGame.IsDialogOrCutscenePlaying()
			&& !theGame.IsCurrentlyPlayingNonGameplayScene()
			&& theInput.GetContext() != 'Scene' )
			theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("ahdal_trueAutoLootMsg") + ": " + "<font color =\"#931313\">" + GetLocStringByKeyExt("ahdal_disabled") + "</font>" );
		
		thePlayer.RemoveTimer('TrueAutoLootMode');
	}
	
	//Tries to loot all containers in the area based on the specified mode
	public function TryAreaLooting(mode : string, optional contType : int) : void
	{
		var i, containerListSize, maxContainers : int;
		var distance : float;
		var enabled, allowInCombat : bool;
		var container, targetContainer : W3Container;
		var containerList : array<CGameplayEntity>;
		var actionRadius : SInputAction;
		var actualActionName : string;
		
		actionRadius.value = theInput.GetActionValue('AutoLootRadius');
		actionRadius.lastFrameValue = 0;
		
		if( !isInitialized || !AutoLootConfig.ModEnabled() )
			return;
		
		if( mode == AHDAL_INTERACT_LOOT && contType != 0 )
		{
			enabled = true;
			allowInCombat = true; //Force true here since Player can't loot containers in combat with Interaction key
			
			if( contType == 2 )
				distance = AutoLootConfig.GetInteractionKeyDistanceHerbs();
			else
				distance = AutoLootConfig.GetInteractionKeyDistance();
			
			maxContainers = AutoLootConfig.GetInteractionKeyMaxContainers();
		}
		else if( mode == AHDAL_RADIUS_LOOT && IsPressed(actionRadius) )
		{
			enabled = true;
			allowInCombat = AutoLootConfig.RadiusLootInCombat();
			distance = AutoLootConfig.GetRadiusLootDistance();
			maxContainers = AutoLootConfig.GetRadiusLootMaxContainers();
		}
		//"contType" here instead of "WasInteractionKeyPressed()" can cause problems e.g. when: Filters=On (none selected); TA=On (range=30); E=0; E_range=30; E_range_Herbs=1
		//...then spamming 'E' on containers (even Locked) can cause True Autoloot to gather Herbs
		else if( mode == AHDAL_TRUE_AUTOLOOT_MODE && !IsPressed(actionRadius) && !WasInteractionKeyPressed() )
		{
			enabled = AutoLootConfig.TrueAutoLootEnabled();
			allowInCombat = AutoLootConfig.TrueAutoLootInCombat();
			distance = AutoLootConfig.GetTrueAutoLootDistance();
			maxContainers = AutoLootConfig.GetTrueAutoLootMaxContainers();
		}
		else
			enabled = false;
		
		if( !enabled || (thePlayer.IsInCombat() && !allowInCombat) )
			return;
		
		FindGameplayEntitiesInRange( containerList, thePlayer, distance, maxContainers, , FLAG_ExcludePlayer, , 'W3Container' );
		
		//Fix: When pressing 'E' at 'Distance for Containers'=1-2 while player is too far (but within HUD text range)
		//(Vanilla popup could open instead of autoloot one, or targeted container items were missing from autoloot popup)
		if( mode == AHDAL_INTERACT_LOOT && contType != 0 )
		{
			targetContainer = (W3Container)thePlayer.GetDisplayTarget();
			if( targetContainer && !containerList.Contains(targetContainer) )
			{
				//Use only if issues occur: Only insert if target type matches currently looted type
				//if( (contType == 1 && !((W3Herb)targetContainer)) || (contType == 2 && (W3Herb)targetContainer) )
				//{
					containerList.Insert(0, targetContainer);
				//}
			}
		}
		
		containerListSize = containerList.Size();
		
		for( i = 0; i < containerListSize; i += 1 )
		{
			container = (W3Container) containerList[i];
			
			if( mode == AHDAL_INTERACT_LOOT )
			{
				//When pressed E on Container, loot only Containers in container-radius
				if( contType == 1 && (W3Herb)container )
					continue;
				
				//When pressed E on Herb, loot only Herbs in herb-radius
				if( contType == 2 && !((W3Herb)container) )
					continue;
			}
			
			if( !AutoLootConfig.GetFilters().IsContainerProtected(container) && !container.IsEmpty() )
			{
				if( (W3Herb)container )
					actualActionName = "GatherHerbs";
				else
					actualActionName = "Container";
				
				container.mergeNotification = true;
				container.OnInteraction(actualActionName, thePlayer);
				container.mergeNotification = false;
			}
		}
		
		AutoLootConfig.GetNotifications().ShowNotification();
		
		ResetLootTriggerType(); //Reset the stored trigger state after the full loop finishes
	}
}