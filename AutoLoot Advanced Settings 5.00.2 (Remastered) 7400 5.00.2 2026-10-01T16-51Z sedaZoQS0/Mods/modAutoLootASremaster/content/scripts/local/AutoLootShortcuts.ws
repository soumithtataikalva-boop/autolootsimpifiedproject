/***********************************************************************/
/** 	AutoLootShortcuts.ws
/** 	mod: AutoLoot Advanced Settings (AutoLoot +A.S.) by jerry18
/***********************************************************************/

class AutoLootShortcuts extends CPlayer
{
	private var AutoLootConfig : CAHDAutoLootConfig;
	
	function Init() : void
	{
		AutoLootConfig = GetWitcherPlayer().GetAutoLootConfig();
	}
	
	function InitRange() : void
	//NOTE: All assigned keys can be changed in the "Key Bindings" menu (controls presented here are set by default)
	{
		
		theInput.RegisterListener(this, 'OnRadius0', 'RadiusRangeAutoLoot0');	//2a) Press [Num 7]: (-)Radius Shortcuts Step / ALT.: Radius Looting distance (1)*
		theInput.RegisterListener(this, 'OnRadius1', 'RadiusRangeAutoLoot1');	//2b) Press [Num 9]: (+)Radius Shortcuts Step / ALT.: Radius Looting distance (3)*
		theInput.RegisterListener(this, 'OnRadius2', 'RadiusRangeAutoLoot2');	//2c) Hold [Num 7]: Radius Looting distance = 1
		theInput.RegisterListener(this, 'OnRadius3', 'RadiusRangeAutoLoot3');	//2d) Hold [Num 9]: Radius Looting distance = 30
		theInput.RegisterListener(this, 'OnRadius4', 'RadiusRangeAutoLoot4');	//2e) Press [Num 8]: Radius Looting [INFO] / ALT.: Radius Looting distance (2)*
		theInput.RegisterListener(this, 'OnRadius5', 'RadiusRangeAutoLoot5');	//2f) Hold [Num 8]: Radius Looting distance = 15
		
		theInput.RegisterListener(this, 'OnFilters0', 'FiltersInfoAutoLoot');	//3a) Press [Num -]: Filters [INFO]
		theInput.RegisterListener(this, 'OnFilters1', 'FiltersToggleAutoLoot');	//3b) Hold [Num -]: Filters [TOGGLE]
		
	// *Alternative function of shortcuts (=ALT.) works only if alternative controls is enabled!
	}
	
	//Returns the specified setting as a float (helper function)
	function GetSettingAsFloat(group : name, setting : name) : float
	{
		return StringToFloat( theGame.GetInGameConfigWrapper().GetVarValue(group, setting) );
	}
	
	//Functions for Radius Looting
	function RadiusDistanceCurrent() : float { return GetSettingAsFloat( 'AHDAutoLoot_radius', 'radiusLootMaxDistance' ); }
	
	function RadiusShortcutsStep() : float { return GetSettingAsFloat( 'AutoLoot_shortcuts', 'radiusShortcutsStep' ); }
	
	//NOTE: Functions for alternative controls
	function AltShortcuts() : bool { return theGame.GetInGameConfigWrapper().GetVarValue( 'AutoLoot_shortcuts', 'altShortcuts' ); }
	function RadiusDistanceOne() : float { return GetSettingAsFloat( 'AutoLoot_shortcuts', 'radiusLootDistanceOne' ); }
	function RadiusDistanceTwo() : float { return GetSettingAsFloat( 'AutoLoot_shortcuts', 'radiusLootDistanceTwo' ); }
	function RadiusDistanceThree() : float { return GetSettingAsFloat( 'AutoLoot_shortcuts', 'radiusLootDistanceThree' ); }
	
	//Disable radius distance shortcuts: 0=enabled, 1=disabled. Legacy 3 also disables; legacy 2 leaves radius shortcuts enabled.
	function ShortcutsThreshold() : float { return GetSettingAsFloat( 'AutoLoot_shortcuts', 'disableShortcutsThreshold' ); }
	
	
//2) Radius Looting distance shortcuts
//************************************
	
//2a) Press [Num 7]: (-)Radius Shortcuts Step / ALT.: Radius Looting distance (1)
	event OnRadius0(action : SInputAction)
	{
		if( AutoLootConfig.ModEnabled() && IsPressed(action) && !(ShortcutsThreshold() == 1 || ShortcutsThreshold() == 3) )
		{
			if( (RadiusDistanceCurrent() - RadiusShortcutsStep()) >= 1 && !AltShortcuts() )
			{
				theGame.GetInGameConfigWrapper().SetVarValue( 'AHDAutoLoot_radius', 'radiusLootMaxDistance', FloatToString(RadiusDistanceCurrent() - RadiusShortcutsStep()) );
			}
			else if( !AltShortcuts() )
			{
				theGame.GetInGameConfigWrapper().SetVarValue( 'AHDAutoLoot_radius', 'radiusLootMaxDistance', 1 );
			}
			else
			{
				theGame.GetInGameConfigWrapper().SetVarValue( 'AHDAutoLoot_radius', 'radiusLootMaxDistance', FloatToString(RadiusDistanceOne()) );
			}
			
			theGame.SaveUserSettings();
			theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("ahdal_radiusDistanceSet") + ": " + FloatToString(RadiusDistanceCurrent()) );
		}
	}
		
//2b) Press [Num 9]: (+)Radius Shortcuts Step / ALT.: Radius Looting distance (3)
	event OnRadius1(action : SInputAction)
	{
		if( AutoLootConfig.ModEnabled() && IsPressed(action) && !(ShortcutsThreshold() == 1 || ShortcutsThreshold() == 3) )
		{
			if( (RadiusDistanceCurrent() + RadiusShortcutsStep()) <= 30 && !AltShortcuts() )
			{
				theGame.GetInGameConfigWrapper().SetVarValue( 'AHDAutoLoot_radius', 'radiusLootMaxDistance', FloatToString(RadiusDistanceCurrent() + RadiusShortcutsStep()) );
			}
			else if( !AltShortcuts() )
			{
				theGame.GetInGameConfigWrapper().SetVarValue( 'AHDAutoLoot_radius', 'radiusLootMaxDistance', 30 );
			}
			else
			{
				theGame.GetInGameConfigWrapper().SetVarValue( 'AHDAutoLoot_radius', 'radiusLootMaxDistance', FloatToString(RadiusDistanceThree()) );
			}
			
			theGame.SaveUserSettings();
			theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("ahdal_radiusDistanceSet") + ": " + FloatToString(RadiusDistanceCurrent()) );
		}
	}
	
//2c) Hold [Num 7]: Radius Looting distance = 1
	event OnRadius2(action : SInputAction)
	{
		if( AutoLootConfig.ModEnabled() && IsPressed(action) && !(ShortcutsThreshold() == 1 || ShortcutsThreshold() == 3) )
		{
			theGame.GetInGameConfigWrapper().SetVarValue( 'AHDAutoLoot_radius', 'radiusLootMaxDistance', 1 );
			theGame.SaveUserSettings();
			theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("ahdal_radiusDistanceSet") + ": " + FloatToString(RadiusDistanceCurrent()) );
		}
	}
	
//2d) Hold [Num 9]: Radius Looting distance = 30
	event OnRadius3(action : SInputAction)
	{
		if( AutoLootConfig.ModEnabled() && IsPressed(action) && !(ShortcutsThreshold() == 1 || ShortcutsThreshold() == 3) )
		{
			theGame.GetInGameConfigWrapper().SetVarValue( 'AHDAutoLoot_radius', 'radiusLootMaxDistance', 30 );
			theGame.SaveUserSettings();
			theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("ahdal_radiusDistanceSet") + ": " + FloatToString(RadiusDistanceCurrent()) );
		}
	}
	
//2e) Press [Num 8]: Radius Looting [INFO] / ALT.: Radius Looting distance (2)
	event OnRadius4(action : SInputAction)
	{
		if( AutoLootConfig.ModEnabled() && IsPressed(action) && !(ShortcutsThreshold() == 1 || ShortcutsThreshold() == 3) )
		{
			if( AltShortcuts() )
			{
				theGame.GetInGameConfigWrapper().SetVarValue( 'AHDAutoLoot_radius', 'radiusLootMaxDistance', FloatToString(RadiusDistanceTwo()) );
				theGame.SaveUserSettings();
				theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("ahdal_radiusDistanceSet") + ": " + FloatToString(RadiusDistanceCurrent()) );
			}
			else
			{
				theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("ahdal_radiusDistanceSet") + " [" + "<font color =\"#3661dc\">" + GetLocStringByKeyExt("ahdal_info") + "</font>" + "]: " + FloatToString(RadiusDistanceCurrent()) );
			}
		}
	}
	
//2f) Hold [Num 8]: Radius Looting distance = 15
	event OnRadius5(action : SInputAction)
	{
		if( AutoLootConfig.ModEnabled() && IsPressed(action) && !(ShortcutsThreshold() == 1 || ShortcutsThreshold() == 3) )
		{
			theGame.GetInGameConfigWrapper().SetVarValue( 'AHDAutoLoot_radius', 'radiusLootMaxDistance', 15 );
			theGame.SaveUserSettings();
			theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("ahdal_radiusDistanceSet") + ": " + FloatToString(RadiusDistanceCurrent()) );
		}
	}
	
	
//3) Filters [INFO]+[TOGGLE] shortcuts
//************************************
	
//3a) Press [Num -]: Filters [INFO]
	event OnFilters0(action : SInputAction)
	{
		if( AutoLootConfig.ModEnabled() && IsPressed(action) )
		{
			if( AutoLootConfig.FiltersEnabled() )
			{
				theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("ahdal_filters") + " [" + "<font color =\"#3661dc\">" + GetLocStringByKeyExt("ahdal_info") + "</font>" + "]: " + GetLocStringByKeyExt("ahdal_enabled"));
			}
			else
			{
				theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("ahdal_filters") + " [" + "<font color =\"#3661dc\">" + GetLocStringByKeyExt("ahdal_info") + "</font>" + "]: " + GetLocStringByKeyExt("ahdal_disabled"));
			}
		}
	}
	
//3b) Hold [Num -]: Filters [TOGGLE]
	event OnFilters1(action : SInputAction)
	{
		if( AutoLootConfig.ModEnabled() && IsPressed(action) )
		{
			if( AutoLootConfig.FiltersEnabled() )
			{
				theGame.GetInGameConfigWrapper().SetVarValue( 'AHDAutoLoot_filters', 'useFilters', "false" );
				theGame.SaveUserSettings();
				theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("ahdal_filters") + ": " + "<font color =\"#931313\">" + GetLocStringByKeyExt("ahdal_disabledFilters") + "</font>" );
			}
			else
			{
				theGame.GetInGameConfigWrapper().SetVarValue( 'AHDAutoLoot_filters', 'useFilters', "true" );
				theGame.SaveUserSettings();
				theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("ahdal_filters") + ": " + "<font color =\"#197319\">" + GetLocStringByKeyExt("ahdal_enabledFilters") + "</font>" );
			}
		}
	}
}