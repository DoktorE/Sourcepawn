#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <devzones>

#pragma newdecls required

public Plugin myinfo = {
	name = "ZM Zones",
	author = "Doktor",
	description = "",
	version = "1.0.4",
	url = ""
};

public void OnPluginStart() {
	HookEvent("round_end", Event_RoundEnd);
}

public int Zone_OnClientEntry(int client, char[] zone) {
	if (StrContains(zone, "CZone", false) != -1 && GetClientTeam(client) == 3) {
		int knifeSlot = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);

		SetActiveWeaponSlot(client, knifeSlot);
		SDKHook(client, SDKHook_WeaponCanSwitchTo, Callback_BlockWeapon);

		PrintCenterText(client, "You have entered a crouch zone, your primary weapon has been restricted");
	}
}

public int Zone_OnClientLeave(int client, char[] zone) {
	if (StrContains(zone, "CZone", false) != -1 && GetClientTeam(client) == 3)  {
		SDKUnhook(client, SDKHook_WeaponCanSwitchTo, Callback_BlockWeapon);

		PrintCenterText(client, "You have left a crouch zone, your primary weapon has been unrestricted");
	}
}

public void SetActiveWeaponSlot(int client, int weapon) {
	SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", weapon);
	ChangeEdictState(client, FindDataMapOffs(client, "m_hActiveWeapon"));
}

public Action Callback_BlockWeapon(int client, int weapon) {
	int primarySlot = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);

	if (primarySlot == weapon) {
		PrintCenterText(client, "Your primary weapon is restricted, please leave the crouch zone");

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	for (int client = 0; client < MaxClients; client++) {
		if (IsPlayerAlive(client) && GetClientTeam(client) == 3) 
			SDKUnhook(client, SDKHook_WeaponCanSwitchTo, Callback_BlockWeapon);
	}
}