#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <cstrike>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "SteamIDGrabberThingy",
	author = "Doktor",
	description = "Displays SteamID of target in chat",
	version = "1",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_steamid", Command_SteamId, "Displays SteamID of target in chat");
}

public Action Command_SteamId(int iClient, int iArgs) {
	char targetName[MAX_NAME_LENGTH];
	
	GetCmdArg(1, targetName, sizeof(targetName));
	PrintToConsole(iClient, "%s", targetName);
	
	if (iArgs < 1) {
		char authId[64];
		GetClientAuthId(iClient, AuthId_Steam2, authId, sizeof(authId));
		PrintToChat(iClient, "[SM] Success! Go to console to copy your SteamID!");
		PrintToConsole(iClient, "[SM] SteamID: %s", authId);
		
		return Plugin_Handled;
	} 
	else if (iArgs == 1) {

		for (int i = 1; i < MaxClients; i++) {
			char name[MAX_NAME_LENGTH];
			
			GetClientName(i, name, sizeof(name));
			
			if (StrEqual(name, targetName, false)) {
				char authId[64];
				GetClientAuthId(i, AuthId_Steam2, authId, sizeof(authId));
				
				PrintToChat(iClient, "[SM] Success! Go to console to copy the target's SteamID!");
				PrintToConsole(iClient, "[SM] SteamID: %s", authId);
				
				return Plugin_Handled;
			} else {
				PrintToChat(iClient, "[SM] Could not find player by the name of %s", targetName);
				
				return Plugin_Handled;
			}
		}
	}
	else {
		PrintToChat(iClient, "[SM] Usage: sm_steamid <target> (leave blank for your own SteamID)");
		
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}