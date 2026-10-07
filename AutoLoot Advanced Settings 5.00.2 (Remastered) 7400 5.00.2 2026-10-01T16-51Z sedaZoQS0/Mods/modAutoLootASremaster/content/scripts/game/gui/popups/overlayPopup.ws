/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER© is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski. 
/***********************************************************************/
class W3NotificationData extends CObject
{
	public var messageText 	: string;
	public var duration    	: float;
	public var queue		: bool;
	
		default duration = 0;
		default queue = false;
}

class CR4OverlayPopup extends CR4PopupBase
{
	private var m_InitDataObject         : W3NotificationData;
	
	private var m_fxShowNotification       : CScriptedFlashFunction;
	private var m_fxHideNotification        : CScriptedFlashFunction;
	private var m_fxClearNotificationsQueue : CScriptedFlashFunction;
	
	private var m_fxShowLoadingIndicator : CScriptedFlashFunction;
	private var m_fxHideLoadingIndicator : CScriptedFlashFunction;
	private var m_fxShowSavingIndicator  : CScriptedFlashFunction;
	private var m_fxHideSavingIndicator  : CScriptedFlashFunction;
	
	private var m_fxAppendButton  		  : CScriptedFlashFunction;
	private var m_fxRemoveButton  		  : CScriptedFlashFunction;
	private var m_fxRemoveContextButtons  : CScriptedFlashFunction;
	private var m_fxUpdateButtons 		  : CScriptedFlashFunction;
	
	private var m_fxSetMouseCursorType 	   : CScriptedFlashFunction;
	private var m_fxShowMouseCursor  	   : CScriptedFlashFunction;
	private var m_fxShowSafeRect 		   : CScriptedFlashFunction;
	private var m_fxSetGamepadTypeOverlay  : CScriptedFlashFunction;
	private var m_fxSetGamepadTypeMenu	   : CScriptedFlashFunction;
	
	private var m_fxShowEP2Logo				: CScriptedFlashFunction;
	
	
	
	private var m_cursorRequested		   : int;
	private var m_cursorHidden			   : bool;
	
	//AutoLoot +A.S.--
	private var notificationModule				: CScriptedFlashSprite;
	private var notificationBackground			: CScriptedFlashSprite;
	private var notificationBackgroundBLACK		: CScriptedFlashSprite;
	private var notificationText				: CScriptedFlashSprite;
	private var notificationTextOutlineLIGHT	: CScriptedFlashSprite;
	private var notificationTextOutlineSTRONG	: CScriptedFlashSprite;
	private var notificationTextOutlineALT		: CScriptedFlashSprite;
	private var m_fxAASpopupWidth				: CScriptedFlashFunction;
	//--AutoLoot +A.S.
	
	event  OnConfigUI()
	{
		super.OnConfigUI();
		
		//AutoLoot +A.S.--
		notificationModule = m_flashModule.GetChildFlashSprite("notificationModule");
		notificationBackground = notificationModule.GetChildFlashSprite("mcBackground");
		notificationBackgroundBLACK = notificationModule.GetChildFlashSprite("mcBackgroundBLACK");
		notificationText = notificationModule.GetChildFlashSprite("tfMessage");
		notificationTextOutlineLIGHT = notificationModule.GetChildFlashSprite("tfMessageOutlineLIGHT");
		notificationTextOutlineSTRONG = notificationModule.GetChildFlashSprite("tfMessageOutlineSTRONG");
		notificationTextOutlineALT = notificationModule.GetChildFlashSprite("tfMessageOutlineALT");
		m_fxAASpopupWidth = notificationModule.GetMemberFlashFunction( "TEXT_WIDTH_MAX" );
		//--AutoLoot +A.S.
		
		m_fxShowNotification = m_flashModule.GetMemberFlashFunction( "showNotification" );
		m_fxHideNotification = m_flashModule.GetMemberFlashFunction( "hideNotification" );
		
		m_fxShowLoadingIndicator = m_flashModule.GetMemberFlashFunction( "showLoadIdicator" );
		m_fxHideLoadingIndicator = m_flashModule.GetMemberFlashFunction( "hideLoadIdicator" );
		m_fxShowSavingIndicator = m_flashModule.GetMemberFlashFunction( "showSaveIdicator" );
		m_fxHideSavingIndicator = m_flashModule.GetMemberFlashFunction( "hideSaveIdicator" );
		
		m_fxSetMouseCursorType = m_flashModule.GetMemberFlashFunction( "setMouseCursorType" );
		m_fxAppendButton = m_flashModule.GetMemberFlashFunction( "appendBinding" );
		m_fxRemoveButton = m_flashModule.GetMemberFlashFunction( "removeBinding" );
		m_fxRemoveContextButtons = m_flashModule.GetMemberFlashFunction( "removeAllContextBinding" );
		m_fxUpdateButtons = m_flashModule.GetMemberFlashFunction( "updateInputFeedback" );
		m_fxShowMouseCursor = m_flashModule.GetMemberFlashFunction( "showMouseCursor" );
		m_fxShowSafeRect = m_flashModule.GetMemberFlashFunction( "showSafeRect" );
		m_fxShowEP2Logo = m_flashModule.GetMemberFlashFunction( "showEP2Logo" );
		m_fxSetGamepadTypeOverlay = m_flashModule.GetMemberFlashFunction( "setGamepadType" );
		m_fxSetGamepadTypeMenu = m_guiManager.GetIngameMenu().GetMenuFlash().GetMemberFlashFunction( "setGamepadType" );
		
		m_fxClearNotificationsQueue = m_flashModule.GetMemberFlashFunction( "clearNotificationsQueue" );
		
		m_InitDataObject = (W3NotificationData)GetPopupInitData();
		
		if (m_InitDataObject)
		{
			ShowNotification(m_InitDataObject.messageText, m_InitDataObject.duration, m_InitDataObject.queue );
		}
		
		m_cursorRequested = theGame.GetGuiManager().mouseCursorRequestStack;
		if (m_cursorRequested > 0)
		{
			UpdateCursorVisibility();
		}
		
		UpdateInputDevice();
	}
	
	event  OnInputHandled(NavCode:string, KeyCode:int, ActionId:int)
	{
		
	}
	
	event  OnDispatchForeignInputEvent(type:string, keyCode:int, inputValue:string, navEquivalent:string)
	{
		
		var rootMenu : CR4MenuBase;
		rootMenu = (CR4MenuBase) m_guiManager.GetRootMenu();
		if (rootMenu)
		{
			rootMenu.DispatchForeignInputEvent(type, keyCode, inputValue, navEquivalent);
		}
	}
	
	public function SetMouseCursorType(value:int):void
	{		
		m_fxSetMouseCursorType.InvokeSelfOneArg( FlashArgInt( value ) );
	}
	
	public function RequestMouseCursor(value:bool):void
	{
		if (value)
		{
			m_cursorRequested+=1;
		}
		else
		if (m_cursorRequested > 0)
		{
			m_cursorRequested-=1;
		}
		
		UpdateCursorVisibility();
	}
	
	public function ForceHideMouseCursor(value:bool):void
	{
		m_cursorHidden = value;
		UpdateCursorVisibility();
	}
	
	public function UpdateInputDevice():void
	{
		var isGamepad:bool = theInput.LastUsedGamepad();
		
		SetControllerType(isGamepad);
		UpdateInputDeviceType();
		UpdateCursorVisibility();
	}
	
	protected function UpdateInputDeviceType():void
	{
		var deviceType : EInputDeviceType = theInput.GetLastUsedGamepadType();

		m_fxSetGamepadTypeOverlay = m_flashModule.GetMemberFlashFunction( "setGamepadType" );
		if (m_fxSetGamepadTypeOverlay)
		{
			m_fxSetGamepadTypeOverlay.InvokeSelfOneArg( FlashArgUInt(deviceType) );
		}

		m_fxSetGamepadTypeMenu = m_guiManager.GetIngameMenu().GetMenuFlash().GetMemberFlashFunction( "setGamepadType" );
		if (m_fxSetGamepadTypeMenu)
		{
			m_fxSetGamepadTypeMenu.InvokeSelfOneArg( FlashArgUInt(deviceType) );
		}
	}
	
	private function ShowSoftwareCursor()
	{
		m_fxShowMouseCursor.InvokeSelfOneArg( FlashArgBool( true ) );
	}
	
	private function HideSoftwareCursor()
	{
		m_fxShowMouseCursor.InvokeSelfOneArg( FlashArgBool( false ) );
	}
	
	private function ShowCursor()
	{
		if ( theGame.IsSoftwareCursor() )
		{
			ShowSoftwareCursor();
			theGame.HideHardwareCursor();
		}
		else
		{
			HideSoftwareCursor();
			theGame.ShowHardwareCursor();
		}
	}
	
	private function HideCursor()
	{
		HideSoftwareCursor();
		theGame.HideHardwareCursor();
	}
	
	private function UpdateCursorVisibility():void
	{
		var isGamepad : bool = theInput.LastUsedGamepad();
		var deviceType : EInputDeviceType = theInput.GetLastUsedGamepadType();
		
		if ((!isGamepad || deviceType == IDT_Switch2_Mouser) && !m_cursorHidden && m_cursorRequested > 0)
		{
			ShowCursor();
		}
		else
		{
			HideCursor();
		}
	}
	
	public function ShowSafeRect(value:bool):void
	{
		m_fxShowSafeRect.InvokeSelfOneArg( FlashArgBool(value) );
	}
	
	public function AppendButton(actionId:int, gpadCode:string, kbCode:int, label:string, optional contextId:name):void
	{
		m_fxAppendButton.InvokeSelfFiveArgs(FlashArgInt(actionId), FlashArgString(gpadCode), FlashArgInt(kbCode), FlashArgString(label), FlashArgUInt(NameToFlashUInt(contextId)));
	}
	
	public function RemoveButton(actionId:int, optional contextId:name):void
	{
		m_fxRemoveButton.InvokeSelfTwoArgs(FlashArgInt(actionId), FlashArgUInt(NameToFlashUInt(contextId)));
	}
	
	public function RemoveContextButtons(contextId:name):void
	{
		m_fxRemoveContextButtons.InvokeSelfOneArg(FlashArgUInt(NameToFlashUInt(contextId)));
	}
	
	public function UpdateButtons():void
	{
		m_fxUpdateButtons.InvokeSelf();		
	}
	
	//AutoLoot +A.S. default (Vanilla) popup - the base ShowNotification function edited--
	public function ShowNotification(messageText : string, optional duration : float, optional queue :  bool ) : void
	{
		var currentWidth, currentHeight, adjustY : int;
		var ratio : float;
		
		theGame.GetCurrentViewportResolution( currentWidth, currentHeight );
		ratio = ( (float)currentWidth ) / currentHeight;
		
		//Y-axis fix for several resolutions where def. loot popup window is off screen (from the bottom)
		if( AbsF(ratio - 5.0 / 4.0) < 0.01 ) //ratio 5:4 (=1.25) - e.g.: 1280/1024
			adjustY = 151;
		else if( AbsF(ratio - 4.0 / 3.0) < 0.01 ) //ratio 4:3 (=1.333333) - e.g.: 1600/1200; 1280/960; 1152/864(1152/870); 1024/768
			adjustY = 108;
		else
			adjustY = 0;
		
		notificationModule.SetVisible(false); //needs to be disabled otherwise another popup can be shown shortly when switching between common (behind "else") and adjustable popup
		
		//set default parameters for Vanilla popup
		notificationText.SetX(20);
		notificationText.SetY(11 + adjustY);
		
		notificationBackground.SetX(0);
		notificationBackground.SetY(0 + adjustY);
		notificationBackground.SetAlpha(100);
		
		notificationBackgroundBLACK.SetX(0);
		notificationBackgroundBLACK.SetY(0 + adjustY);
		notificationBackgroundBLACK.SetAlpha(100);
		
		notificationTextOutlineLIGHT.SetVisible(false);
		notificationTextOutlineSTRONG.SetVisible(false);
		notificationTextOutlineALT.SetVisible(false);
		
		notificationModule.SetMemberFlashNumber( "TEXT_WIDTH_MAX", 400 ); //400 is the Vanilla's default value (i.e. no change for Vanilla popup)
		
		//choose between black/light(=Vanilla) background popup if Autoloot is enabled
		if( GetWitcherPlayer().GetAutoLootConfig().ModEnabled() && theGame.GetInGameConfigWrapper().GetVarValue('AHDAutoLoot_notifications', 'DEFpopupBlack') )
		{
			notificationBackground.SetVisible(false);
			notificationBackgroundBLACK.SetVisible(true);
			
			m_fxShowNotification.InvokeSelfThreeArgs( FlashArgString("<font color='#E9E9E9'>" + messageText), FlashArgNumber(duration), FlashArgBool( queue ) ); //light text
		}
		else
		{
			notificationBackground.SetVisible(true);
			notificationBackgroundBLACK.SetVisible(false);
			
			m_fxShowNotification.InvokeSelfThreeArgs( FlashArgString(messageText), FlashArgNumber(duration), FlashArgBool( queue ) ); //black text
		}
	}
	//--AutoLoot +A.S.
	
	//AutoLoot +A.S. popup--
	public function ShowAASNotification(messageText : string, optional duration : float, optional queue :  bool ) : void
	{
		var PopupPosX, PopupPosY, AASpopupWidthMax, PopupOpacity, textOutline, currentWidth, currentHeight : int;
		var ratio, adjustX, adjustY : float;
		
		PopupPosX = StringToInt(theGame.GetInGameConfigWrapper().GetVarValue('AHDAutoLoot_notifications', 'PopupPosX'));
		PopupPosY = StringToInt(theGame.GetInGameConfigWrapper().GetVarValue('AHDAutoLoot_notifications', 'PopupPosY'));
		AASpopupWidthMax = 4 * (StringToInt(theGame.GetInGameConfigWrapper().GetVarValue('AHDAutoLoot_notifications', 'AASpopupWidthMax')));
		PopupOpacity = StringToInt(theGame.GetInGameConfigWrapper().GetVarValue('AHDAutoLoot_notifications', 'PopupOpacity'));
		textOutline = StringToInt(theGame.GetInGameConfigWrapper().GetVarValue('AHDAutoLoot_notifications', 'textOutline'));
		
		theGame.GetCurrentViewportResolution( currentWidth, currentHeight );
		ratio = ( (float)currentWidth ) / currentHeight;
		
		//X-axis adjustment (horizontal) - to be exactly the same for most of resolutions (i.e. starting approximately from "0" -> left side of the screen)
		//...X-axis max value which should be used depends on the resolution, "AASpopupWidthMax" setting and the item's name length (long-named items e.g.: "lore_toussaint_ecology" or "wine_wars_belgard_notice")
		//Note: I couldn't test some resolutions above 2560/1440 though (e.g.: 3840/1080, 3440/1440)
		if( ratio == 4.0 ) //tested: 1440/405(1440/360)_r=4.0
			adjustX = -1425; //-1440: calculated value according to the formula (at the end of the condition)
		else if( ratio >= 3.63 && ratio < 3.67 ) //ratio ~32:9 (~3.6xyz) - tested: 2488/700(2464/672)_r=3.666666
			adjustX = -1235; //-1240: calculated value according to the formula (at the end of the condition)
		else if( ratio > 3.62 && ratio < 3.63 ) //ratio ~32:9 (~3.62xyz) - tested: 2560/720(2552/704)_r=3.625
			adjustX = -1205; //-1215: calculated value according to the formula (at the end of the condition)
		else if( ratio == 3.6 ) //ratio ~32:9 (=3.6) - tested: 2528/711(2520/700)_r=3.6
			adjustX = -1195; //-1200: calculated value according to the formula (at the end of the condition)
		else if( ratio > 3.55 && ratio < 3.56 ) //ratio 32:9 (3.555555) - tested: 5120/1440(5120/1440)_r=3.555555
			adjustX = -1169; //-1173: calculated value according to the formula (at the end of the condition)
		//else if( ratio == 2.5) //ratio ~21:9 (=2.5) - tested: 1720/700(1720/688)_r=2.5
		//	adjustX = -540; //-540: calculated value according to the formula (at the end of the condition)
		//else if( ratio > 2.45 && ratio < 2.46 ) //ratio ~21:9 (~2.45xyz) - tested: 2494/1015(2484/1012)_r=2.454545
		//	adjustX = -514; //-512.72: calculated value according to the formula (at the end of the condition)
		//else if( ratio == 2.4 ) //ratio ~21:9 (=2.4) - tested: 2560/1080(2544/1060)_r=2.4
		//	adjustX = -480; //-480: calculated value according to the formula (at the end of the condition)
		else if( ratio >= 2.33 && ratio < 2.34 ) //tested: 2520/1080_r=2.333333
			adjustX = -445; //-440: calculated value according to the formula (at the end of the condition)
		else if( ratio > 1.8 && ratio < 1.84 ) //e.g.: 1760/990(1760/960)_r=1.833333
			adjustX = -145; //-140: calculated value according to the formula (at the end of the condition)
		else if( ratio == 1.8 ) //e.g.: 1600/900(1584/880)_r=1.8
			adjustX = -125; //-120: calculated value according to the formula (at the end of the condition)
		else if( ratio < 1.8 )
			adjustX = -110;
		else //if( ratio > 1.8 )
			adjustX = (1.6 - ratio) * 600; //this formula should approximately calculate the leftmost X-axis value
		
		//Y-axis adjustment (vertical) - to be exactly the same for most of resolutions (i.e. starting from "0" -> bottom side of the screen)
		if( AbsF(ratio - 5.0 / 4.0) < 0.01 ) //ratio 5:4 (=1.25) - e.g.: 1280/1024
			adjustY = 151 - 10;
		else if( AbsF(ratio - 4.0 / 3.0) < 0.01 ) //ratio 4:3 (=1.333333) - e.g.: 1600/1200; 1280/960; 1152/864(1152/870); 1024/768
			adjustY = 108 - 10;
		else if( AbsF(ratio - 16.0 / 10.0) < 0.01 ) //ratio 16:10 (=1.6) - e.g.: 1920/1200; 1440/900; 1280/800
			adjustY = 0 - 10;
		else if( ratio > 1.66 && ratio < 1.67 ) //ratio ~16:10 (~1.6xyz) - e.g.: 1680/1050(1680/1008)_r=1.666667
			adjustY = -22 - 10;
		else if( ratio == 1.75 ) //ratio ~16:9 (=1.75) - e.g.: 1366/768(1344/768)_r=1.75; 1280/720(1260/720)_r=1.75
			adjustY = -46 - 10;
		else
			adjustY = -54 - 10;
		
		notificationModule.SetVisible(false); //needs to be disabled otherwise another popup can be shown shortly when switching between common (behind "else") and adjustable popup
		
		if( textOutline == 0 )
		{
			notificationTextOutlineLIGHT.SetVisible(false);
			notificationTextOutlineSTRONG.SetVisible(false);
			notificationTextOutlineALT.SetVisible(false);
		}
		else if( textOutline == 1 )
		{
			notificationTextOutlineLIGHT.SetVisible(true);
			notificationTextOutlineSTRONG.SetVisible(false);
			notificationTextOutlineALT.SetVisible(false);
		}
		else if( textOutline == 2 )
		{
			notificationTextOutlineLIGHT.SetVisible(false);
			notificationTextOutlineSTRONG.SetVisible(true);
			notificationTextOutlineALT.SetVisible(false);
		}
		else if( textOutline == 3 )
		{
			notificationTextOutlineLIGHT.SetVisible(false);
			notificationTextOutlineSTRONG.SetVisible(false);
			notificationTextOutlineALT.SetVisible(true);
		}
		
		notificationBackground.SetX(PopupPosX + adjustX);
		notificationBackground.SetY(PopupPosY + adjustY);
		notificationBackground.SetAlpha(PopupOpacity);
		
		notificationBackgroundBLACK.SetX(PopupPosX + adjustX);
		notificationBackgroundBLACK.SetY(PopupPosY + adjustY);
		notificationBackgroundBLACK.SetAlpha(PopupOpacity);
		
		notificationText.SetX(PopupPosX + 20 + adjustX); //Text needs to be set with the X-offset like +20 (otherwise there is no space between the frame and the text)
		notificationText.SetY(PopupPosY + 11 + adjustY); //Text needs to be set with the Y-offset like +11 (otherwise there is no space between the frame and the text)
		
		notificationTextOutlineLIGHT.SetX(PopupPosX + 20 + adjustX);
		notificationTextOutlineLIGHT.SetY(PopupPosY + 11 + adjustY);
		notificationTextOutlineSTRONG.SetX(PopupPosX + 20 + adjustX);
		notificationTextOutlineSTRONG.SetY(PopupPosY + 11 + adjustY);
		notificationTextOutlineALT.SetX(PopupPosX + 20 + adjustX);
		notificationTextOutlineALT.SetY(PopupPosY + 11 + adjustY);
		
		//if( AASpopupWidthMax < 400 )
		//{
		//	theGame.GetInGameConfigWrapper().SetVarValue( 'AHDAutoLoot_notifications', 'AASpopupWidthMax', 700 );
		//}
		
		notificationModule.SetMemberFlashNumber( "TEXT_WIDTH_MAX", AASpopupWidthMax );
		
		if( theGame.GetInGameConfigWrapper().GetVarValue('AHDAutoLoot_notifications', 'AASpopupBlack') )
		{
			notificationBackground.SetVisible(false);
			notificationBackgroundBLACK.SetVisible(true);
		}
		else
		{
			notificationBackground.SetVisible(true);
			notificationBackgroundBLACK.SetVisible(false);
		}
		
		m_fxShowNotification.InvokeSelfThreeArgs( FlashArgString(messageText), FlashArgNumber(duration), FlashArgBool( queue ) );
	}
	//--AutoLoot +A.S.
	
	public function HideNotification() : void
	{
		m_fxHideNotification.InvokeSelf();
	}
	
	public function ClearNotificationsQueue() : void
	{
		m_fxClearNotificationsQueue.InvokeSelf();
	}
	
	public function ShowLoadingIndicator():void
	{
		m_fxShowLoadingIndicator.InvokeSelf();
	}
	
	
	public function HideLoadingIndicator(optional immediateHide : bool):void
	{
		m_fxHideLoadingIndicator.InvokeSelfOneArg(FlashArgBool(immediateHide));
	}
	
	public function ShowSavingIndicator():void
	{
		m_fxShowSavingIndicator.InvokeSelf();
	}
	
	
	public function HideSavingIndicator(optional immediateHide : bool):void
	{
		m_fxHideSavingIndicator.InvokeSelfOneArg(FlashArgBool(immediateHide));
	}

	public function ShowEP2Logo( show : bool, fadeInterval : float, x : int, y : int )
	{
		var audio, subtitles : string;
		var path : string;

		if ( show )
		{
			path = "img://logos/ep2/";

			theGame.GetGameLanguageName( audio, subtitles );
			switch ( subtitles )
			{
			case "PL":
				path += "ep2_pl.png";
				break;
			case "CZ":
				path += "ep2_cz.png";
				break;
			case "RU":
				path += "ep2_ru.png";
				break;
			case "ZH":
				path += "ep2_zh.png";
				break;
			case "EN":
			default:
				path += "ep2_en.png";
				break;
			}
		}

		m_fxShowEP2Logo.InvokeSelfFiveArgs( FlashArgBool( show ), FlashArgNumber( fadeInterval ), FlashArgInt( x ), FlashArgInt( y ), FlashArgString( path ) );
	}

	public function ShowEP3Logo( show : bool, fadeInterval : float, x : int, y : int )
	{
		var audio, subtitles : string;
		var path : string;

		if ( show )
		{
			path = "img://logos/ep3/";

			theGame.GetGameLanguageName( audio, subtitles );
			switch ( subtitles )
			{
			case "PL":
				path += "ep3_pl.png";
				break;
			case "CZ":
				path += "ep3_cz.png";
				break;
			case "RU":
				path += "ep3_ru.png";
				break;
			case "ZH":
				path += "ep3_zh.png";
				break;
			case "EN":
			default:
				path += "ep3_en.png";
				break;
			}
		}

		m_fxShowEP2Logo.InvokeSelfFiveArgs( FlashArgBool( show ), FlashArgNumber( fadeInterval ), FlashArgInt( x ), FlashArgInt( y ), FlashArgString( path ) );
	}	
}

exec function closeoverlay()
{
	theGame.ClosePopup( 'OverlayPopup' );
}