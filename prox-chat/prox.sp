#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

ConVar g_speakRange;

public Plugin myinfo = {
	name = "Proximity chat",
	author = "Doktor",
	description = "",
	version = "0.0.1",
	url = ""
};

public void OnPluginStart() {
    RegConsoleCmd("say", Command_Say);

    g_speakRange = CreateConVar("speak_range", "600", "Sets the speak range of proximity chat");
}

stock void PrintChat(int client, char[] message, int chatDistance) {
	float clientOrigin[3];
	GetClientAbsOrigin(client, clientOrigin);

	// cycle through connected clients
	for (int i = 0; i < MaxClients; i++) {
		if (i != client && IsClientConnected(i) && IsClientInGame(i)) {
			float distance;
			float playerOrigin[3];

			GetClientAbsOrigin(i, playerOrigin);
			distance = GetVectorDistance(clientOrigin, playerOrigin);

			if (distance <= chatDistance)
				PrintToChat(i, "%N: %s", client, message);
		}
	}
}

public Action Command_Say(int client, int args) {
    char message[255]; // Test message size

    if (client == 0) return Plugin_Handled;

    GetCmdArgString(message, sizeof(message));
    StripQuotes(message);
    TrimString(message);
    
    // avoid blocking commands
    if (message[0] == '/') return Plugin_Handled;

    PrintChat(client, message, g_speakRange);
    
    return Plugin_Handled;
}