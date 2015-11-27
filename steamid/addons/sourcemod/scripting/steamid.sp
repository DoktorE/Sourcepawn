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
	version = "2",
	url = ""
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegConsoleCmd("sm_steamid", Command_SteamId, "Displays SteamID of target in chat");
}

public Action Command_SteamId(int iClient, int iArgs) {
	char targetName[MAX_NAME_LENGTH];
	
	GetCmdArg(1, targetName, sizeof(targetName));
	PrintToConsole(iClient, "%s", targetName);
	
	if (iArgs < 1) {
		char authId[64];
		
		GetClientAuthId(iClient, AuthId_Steam2, authId, sizeof(authId));
		
		ReplyToCommand(iClient, "[SM] Success! Go to console to copy your SteamID!");
		PrintToConsole(iClient, "[SM] Your SteamID: %s", authId);
		
		return Plugin_Handled;
	} 
	else if (iArgs == 1) {
		int target = FindTarget(iClient, targetName);
		
		if (target == -1) {
			return Plugin_Handled;
		}
		
		char authId[64];
		GetClientAuthId(target, AuthId_Steam2, authId, sizeof(authId));
		
		ReplyToCommand(iClient, "[SM] Success! Go to console to copy %N's SteamID!", target);
		PrintToConsole(iClient, "[SM] %N's SteamID: %s", target, authId);
			
		return Plugin_Handled;
	}
	else {
		PrintToChat(iClient, "[SM] Usage: sm_steamid <target> (leave blank for your own SteamID)");
	}
	
	return Plugin_Handled;
}