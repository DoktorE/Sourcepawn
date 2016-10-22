#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <adminmenu>

#define PLUGIN_VERSION "3.12.3"

#pragma newdecls required

//=============================================================================
// Global Array
//=============================================================================

/*
Ideas:
	store client indexes in an array and repopulate the list everytime somebody connects/disconnects (note for this, might want to put a timer so the plugin doesn't crash the server after map change)
	when time comes to mute query, send the SteamID of a client index (GetClientAuthID) to the database
	for unmute, match the SteamID's against the table of SteamID's (or something like that)
*/
// FindTarget() SteamID
int g_iClientIndexList[MAXPLAYERS + 1];
char g_sLocalSteamidList[MAXPLAYERS + 1][896]; // stores MAXPLAYERS SteamIDs up to 25 chars in length
Handle g_hDbCon = null; // Db connection

public Plugin myinfo = 
{
	name = "Self-Mute",
	author = "Otokiru, edited by Locomotiver and Doktor",
	description = "Self Mute Player Voice",
	version = PLUGIN_VERSION,
	url = "www.xose.net"
}

//====================================================================================================
//==== CREDITS: Otokiru (Idea+Source) // TF2MOTDBackpack (PlayerList Menu) 
//==== Database Integration: Locomotiver 
//==== Idea by Roy 
//====================================================================================================

public void OnPluginStart() 
{	
    LoadTranslations("common.phrases");
    CreateConVar("sm_selfmute_version", PLUGIN_VERSION, "Version of Self-Mute", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
    RegAdminCmd("sm_sm", selfMute, 0, "Mute player by typing !selfmute [playername]");
    RegAdminCmd("sm_selfmute", selfMute, 0, "Mute player by typing !sm [playername]");
    RegAdminCmd("sm_su", selfUnmute, 0, "Unmute player by typing !su [playername]");
    RegAdminCmd("sm_selfunmute", selfUnmute, 0, "Unmute player by typing !selfunmute [playername]");
    RegAdminCmd("sm_cm", checkmute, 0, "Check who you have self-muted");
    RegAdminCmd("sm_checkmute", checkmute, 0, "Check who you have self-muted");
	
    Connect_Database();
}

//====================================================================================================

public void OnClientPutInServer(int iClient)
{
	char sClientUID3[64];
	
	GetClientAuthId(iClient, AuthId_Steam3, sClientUID3, sizeof(sClientUID3));
	FetchClientInfo(iClient, sClientUID3);
	
	for (int id = 1; id <= MAXPLAYERS ; id++)
	{
        if (id != iClient && IsClientInGame(id))
        {
        	GetClientAuthId(id, AuthId_Steam3, g_sLocalSteamidList, sizeof(g_sLocalSteamidList));
			muteTargetedPlayer(iClient, id);
        }
    }
}

public void OnClientDisconnect(int iClient)
{
	for (int id = 1; id < MAXPLAYERS; id++) 
	{ 
		if (id != iClient && IsClientInGame(id)) 
		{
			GetClientAuthId(id, AuthId_Steam3, g_sLocalSteamidList, sizeof(g_sLocalSteamidList));
		}
	}
}

//====================================================================================================

public Action selfMute(int iClient, int iArgs)
{
    if (iClient == 0)
	{
		PrintToChat(iClient, "\x04[SM] Cannot use command from RCON");
		
		return Plugin_Handled;
	}
	
    if (iArgs == 0)
	{
		DisplayMuteMenu(iClient);
		
		return Plugin_Handled;
	}
	
	// Gets target client
    int iTarget;
    char argString[128];
    GetCmdArgString(argString, sizeof(argString));
    iTarget = FindTarget(iClient, argString, true, false);
	
    if (iTarget == -1) 
    {
        DisplayMuteMenu(iClient);
        
        return Plugin_Handled;
    }
    
    char sClientUID3[64];
    
    // send SteamID of target to databse
    GetClientAuthId(iClient, AuthId_Steam3, sClientUID3, sizeof(sClientUID3));
    UpdateClient(iClient,sClientUID3);
    
    muteTargetedPlayer(iClient, iTarget);
    
    return Plugin_Handled;
}

void DisplayMuteMenu(int iClient)
{
	Menu menu = CreateMenu(MenuHandler_MuteMenu);
	SetMenuTitle(menu, "Choose a player to mute");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_NO_BOTS);
	
	DisplayMenu(menu, iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_MuteMenu(Menu menu, MenuAction action, int iClient, int item)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			char info[32];
			int iTarget;
			
			GetMenuItem(menu, item, info, sizeof(info));
			int userid = StringToInt(info);

			if ((iTarget = GetClientOfUserId(userid)) == 0)
			{
				PrintToChat(iClient, "\x04[SM] Player no longer available");
			}
			else
			{
				muteTargetedPlayer(iClient, iTarget);
			}
		}
	}
}

public void muteTargetedPlayer(int iClient, int iTarget)
{	
    SetListenOverride(iClient, iTarget, Listen_No);
    
    char targetNick[MAX_NAME_LENGTH];
    GetClientName(iTarget, targetNick, sizeof(targetNick));
    
    PrintToChat(iClient, "\x04[Self-Mute]\x01 You have self-muted:\x04 %s", targetNick);
}

//====================================================================================================

public Action selfUnmute(int iClient, int iArgs)
{
    if (iClient == 0)
	{
		PrintToChat(iClient, "\x04[SM] Cannot use command from RCON");
		
		return Plugin_Handled;
	}
    if (iArgs == 0)
    {
        DisplayUnMuteMenu(iClient);
        
        return Plugin_Handled;
    }
	
	// Gets target client
    int iTarget;
    char argString[128];
    GetCmdArgString(argString, sizeof(argString));
    iTarget = FindTarget(iClient, argString, true, false);
	
    if (iTarget == -1) 
    {
        DisplayUnMuteMenu(iClient);
        
        return Plugin_Handled;
    }
    
    unMuteTargetedPlayer(iClient, iTarget);
    
    return Plugin_Handled;
}

void DisplayUnMuteMenu(int iClient)
{
	Menu menu = new Menu(MenuHandler_UnMuteMenu);
	
	SetMenuTitle(menu, "Choose a player to unmute");
	SetMenuExitBackButton(menu, true);
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_NO_BOTS);
	
	DisplayMenu(menu, iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_UnMuteMenu(Menu menu, MenuAction action, int iClient, int item)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			char info[32];
			int iTarget;
			
			GetMenuItem(menu, item, info, sizeof(info));
			int userid = StringToInt(info);

			if ((iTarget = GetClientOfUserId(userid)) == 0)
			{
				PrintToChat(iClient, "\x04[SM] Player no longer available");
			}
			else
			{
				unMuteTargetedPlayer(iClient, iTarget);
			}
		}
	}
}

public void unMuteTargetedPlayer(int iClient, int iTarget)
{
    SetListenOverride(iClient, iTarget, Listen_Yes);
    
    // update local buffer
    
    
    char targetNick[256];
    
    GetClientName(iTarget, targetNick, sizeof(targetNick));
    PrintToChat(iClient, "\x04[Self-Mute]\x01 You have self-unmuted:\x04 %s", targetNick);
}

//====================================================================================================

public Action checkmute(int iClient, int iArgs)
{
    if (iClient == 0)
	{
		PrintToChat(iClient, "\x04[SM] Cannot use command from RCON");

		return Plugin_Handled;
	}

    char nickNames[9216];
    Format(nickNames, sizeof(nickNames), "No players found.");
    bool firstNick = true;
    
    for (int id = 1; id <= MAXPLAYERS; id++)
    {
        if (id != iClient && IsClientInGame(id))
        {
            ListenOverride override = GetListenOverride(iClient, id);
            if(override == Listen_No)
            {
                if(firstNick)
                {
                    firstNick = false;
                    Format(nickNames, sizeof(nickNames), "");
                } 
                else 
                {
                	Format(nickNames, sizeof(nickNames), "%s, ", nickNames); 
                }
                
                char targetNick[256];
                GetClientName(id, targetNick, sizeof(targetNick));
                Format(nickNames, sizeof(nickNames), "%s%s", nickNames, targetNick);
            }
        }
    }
    
    PrintToChat(iClient, "\x04[Self-Mute]\x01 List of self-muted:\x04 %s", nickNames);
    Format(nickNames, sizeof(nickNames), "");

    // PrintToChat(client, "%i", GetListenOverride(client, GetClientOfUserId(218)));

    return Plugin_Handled;
}

void Connect_Database()
{
	Handle hKeyV = CreateKeyValues("");
	
	char sDbCon_Path[PLATFORM_MAX_PATH];
	char sBuffer_Temp[20];
	char sDbKey_name[20] = ""; // Please Key Value name of DB to connect
	char sDb_Error[255];

	
	// Close DB handle before starting
	if (g_hDbCon != INVALID_HANDLE)
	{
		CloseHandle(g_hDbCon);
		g_hDbCon = INVALID_HANDLE;
	}
	
	// Handle is closed
	if (g_hDbCon == INVALID_HANDLE)
	{
		// Prepare to Read the file from (addons\sourcemod\configs\database.cfg)
		StrCat(sDbCon_Path,sizeof(sDbCon_Path), "addons/sourcemod/configs/database.cfg");
		FileToKeyValues(hKeyV, sDbCon_Path);
		LogMessage("Fetching Database Info from %s", sDbCon_Path);
		
		if(KvJumpToKey(hKeyV, sDbKey_name,false))
		{
			// Get the config values
			KvGetString(hKeyV,"host", sBuffer_Temp, sizeof(sBuffer_Temp));
			KvGetString(hKeyV,"port", sBuffer_Temp, sizeof(sBuffer_Temp));
			KvGetString(hKeyV,"database", sBuffer_Temp, sizeof(sBuffer_Temp));
			KvGetString(hKeyV,"user", sBuffer_Temp, sizeof(sBuffer_Temp));
			KvGetString(hKeyV,"pass", sBuffer_Temp, sizeof(sBuffer_Temp));
			
			g_hDbCon = SQL_ConnectCustom(hKeyV, sDb_Error, sizeof(sDb_Error),true);
			CloseHandle(hKeyV);
			
			if (g_hDbCon == INVALID_HANDLE)
			{
				LogError("[DB] Fail to connect to the database! Contact Administrator %n Error Report: %s", sDb_Error);
			}
			else
			{
				LogMessage("[DB] Successfully connected to the database");
			}
		}
		else
		{
			LogError("Error during fetching the database information. Contact the administrator. %n Detailed Error Reason - %s Wrong or Invalid Key name" , sDbKey_name);
		}
	}
}

void AddClientInfo(int iClient)
{
	char sQuery[255];

	Format(sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO *TABLENAME*(ClientSID) VALUES ('%s')");
	
	// this gives a compiler error for some reason
	SQL_TQuery(g_hDbCon, SQL_ErrorCheckonAdd, sQuery, iClient);
}

public void SQL_ErrorCheckonAdd(Handle owner, Handle hndl, const char[] sError, any aClient)
{
	char sSteamId[32] = "";
	
	if (hndl == INVALID_HANDLE)
	{
		GetClientAuthId(aClient, AuthId_Steam3, sSteamId, sizeof(sSteamId));
		//SetFailState("Add Query Failed! %s", sError);
		LogMessage("Add query Failed on user (%s). %s", sSteamId, sError); 
	}
}

void UpdateClient(int iClient, char[] sTargetSID)
{
	char sQuery[255];
	Format(strQuery, sizeof(strQuery), "UPDATE players SET name = '%s' WHERE steamid = '%s'", Name, Id);
	char sClientSID[64];
	
	GetClientAuthId(intClient, AuthId_Steam3, sClientSID, sizeof(sClientSID));

	Format(strQuery, sizeof(strQuery), "UPDATE *TABLENAME* SET TargetSID = '%s' WHERE ClientSID = '%s'", sClientSID, sTargetSID);
	
	// Send our query to the function
	SQL_TQuery(db, SQL_ErrorCheckCallBack, strQuery);
}

void FetchClientInfo(const int iClient, const char[] sClientUID3)
{
	char sQuery[896];

	LogMessage("Fetching client info of %N", iClient); 
	// replace tablename with actual table
	Format(sQuery, sizeof(sQuery), "SELECT TargetSID FROM *TABLENAME* WHERE ClientSID = '%s'", iClient);
	SQL_TQuery(g_hDbCon, SQL_ReadClientInfo, sQuery, iClient);
}

public void SQL_ReadClientInfo(Handle hOwner, Handle hndl, const char[] error, int iClient)
{	
	if (SQL_GetFieldCount(hndl) != 0)
	{		
		char sBuffer[896];
		
		SQL_FetchString(hndl, 1, sBuffer, sizeof(sBuffer));
	}
	else
	{
		AddClientInfo(iClient);
	}
}