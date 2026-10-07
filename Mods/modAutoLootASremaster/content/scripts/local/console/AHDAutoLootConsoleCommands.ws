exec function aas_version()
{
	theGame.GetGuiManager().ShowNotification( theGame.GetInGameConfigWrapper().GetVarValue( 'AHDAutoLoot_settings', 'modVersionUserSettings' ), 5000 );
}

exec function aas_reset()
{
	var UserSettings : CInGameConfigWrapper;
	
	UserSettings = theGame.GetInGameConfigWrapper();
	UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'modVersionUserSettings', 0 );
	theGame.SaveUserSettings();
	
	GetWitcherPlayer().GetAutoLootConfig().Init();
}

exec function aas_clearnotifications()
{
	var temp : array<float>;
	var msg : string;
	
	msg = "";
	temp = GetWitcherPlayer().GetAutoLootConfig().GetNotifications().DebugReset();
	
	msg += "AutoLoot DEBUG: Clearing notification manager...<br/>";
	msg += "- Names Cleared: " + FloatToString(temp[0]) + "<br/>";
	msg += "- Quantities Cleared: " + FloatToString(temp[1]) + "<br/>";
	msg += "- Icons Cleared: " + FloatToString(temp[2]) + "<br/>";
	msg += "- Descriptions Cleared: " + FloatToString(temp[3]) + "<br/>";
	msg += "- Sound Categories Cleared: " + FloatToString(temp[4]) + "<br/>";
	msg += "- Total Unique Items Before Reset: " + FloatToString(temp[5]) + "<br/>";
	msg += "- Popup Queue State Before Reset: " + FloatToString(temp[6]);
	
	theGame.GetGuiManager().ShowNotification( msg, 10000.0 );
}

exec function getplayerpos( optional mode : string, optional showTarget : bool, optional time : int )
{
	var coordType, msg : string;
	var vec1, vec2 : Vector;
	var newTime : float;
	
	if(mode == "local")
	{
		vec1 = thePlayer.GetLocalPosition();
		vec2 = theGame.GetInteractionsManager().GetActiveInteraction().GetEntity().GetLocalPosition();
		coordType = "local coords:<br/>";
	}
	else
	{
		vec1 = thePlayer.GetWorldPosition();
		vec2 = theGame.GetInteractionsManager().GetActiveInteraction().GetEntity().GetWorldPosition();
		coordType = "world coords:<br/>";
	}
	
	msg += "Player " + coordType;
	msg += "X: " + vec1.X + "<br/>";
	msg += "Y: " + vec1.Y + "<br/>";
	msg += "Z: " + vec1.Z;
	
	if(showTarget)
	{
		if( vec2.X == 0.0 && vec2.Y == 0.0 && vec2.Z == 0.0 )
		{
			msg += "<br/><br/>No target!";
		}
		else
		{
			msg += "<br/><br/>Target " + coordType;
			msg += "X: " + vec2.X + "<br/>";
			msg += "Y: " + vec2.Y + "<br/>";
			msg += "Z: " + vec2.Z;
		}
	}
	
	if(time)
		newTime = time * 1000.0;
	else
		newTime = 5000.0;
	
	theGame.GetGuiManager().ShowNotification( msg, newTime );
}

exec function gameRes()
{
	var currentWidth, currentHeight : int;
	var ratio : float;
	
	theGame.GetCurrentViewportResolution( currentWidth, currentHeight );
	ratio = ( (float)currentWidth ) / currentHeight;
	
	theGame.GetGuiManager().ShowNotification( currentWidth + "/" + currentHeight + "_(real resolution); ratio=" + FloatToString(ratio) );
}

exec function pop()
{
	var msg : string;
	
	msg += "01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 ";
	msg += "34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 ";
	msg += "67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100";
	
	theGame.GetGuiManager().ShowNotification( msg );
}
