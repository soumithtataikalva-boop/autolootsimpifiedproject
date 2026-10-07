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
		
		
		theInput.RegisterListener(this, 'OnFilters0', 'FiltersInfoAutoLoot');	//3a) Press [Num -]: Filters [INFO]
		theInput.RegisterListener(this, 'OnFilters1', 'FiltersToggleAutoLoot');	//3b) Hold [Num -]: Filters [TOGGLE]
		
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