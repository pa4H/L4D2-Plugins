#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks> 

//char DropLP[PLATFORM_MAX_PATH]; // debug
Handle medkitTimer;

public Plugin myinfo = 
{
	name = "SetItemsCount", 
	author = "pa4H", 
	description = "", 
	version = "3.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_test", debb, "");
	RegAdminCmd("sm_itemcount", printItemCount, ADMFLAG_BAN);
	RegAdminCmd("sm_itemscount", printItemCount, ADMFLAG_BAN);
	RegAdminCmd("sm_countitems", printItemCount, ADMFLAG_BAN);
	RegAdminCmd("sm_showitems", printItemCount, ADMFLAG_BAN);
	RegAdminCmd("sm_itemsshow", printItemCount, ADMFLAG_BAN);
	RegAdminCmd("sm_itemshow", printItemCount, ADMFLAG_BAN);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_left_safe_area", Event_PlayerLeftSafeArea, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	//BuildPath(Path_SM, DropLP, sizeof(DropLP), "logs/SetItemCount.log"); // debug
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

stock float map(float x, float in_min, float in_max, float out_min, float out_max) // Пропорция
{
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

void Event_PlayerLeftSafeArea(Event eEvent, const char[] szName, bool bDontBroadcast) {  // Игрок вышел из saferoom
	if (!isVersus()) { return; }
	medkitTimer = null;
	delete medkitTimer;
	medkitTimer = CreateTimer(20.0, Timer_DeleteAllMedkits, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	medkitTimer = null;
	delete medkitTimer;
}

public Action Timer_DeleteAllMedkits(Handle timer)
{
	float curFlow = map(L4D2_GetFurthestSurvivorFlow(), 0.0, L4D2Direct_GetMapMaxFlowDistance(), 0.0, 100.0);
	if (curFlow >= 10.0) {  // Удаляем
		char eName[64];
		for (int i = 1; i <= GetEntityCount(); i++)
		{
			if (IsValidEntity(i) && IsValidEdict(i))
			{
				GetEntityClassname(i, eName, sizeof(eName));
				if (strcmp(eName, "weapon_first_aid_kit_spawn") == 0) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i); // Удаляем все аптеки
				}
			}
		}
		medkitTimer = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}


public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, Timer_ClearItems);
	return Plugin_Continue;
}

public Action Timer_ClearItems(Handle timer)
{
	clearEvent();
	return Plugin_Stop;
}

void clearEvent()
{
	if (!isVersus()) { return; }
	char eName[64];
	int pill, adr, pipe, molot, defib, vomit, ince, expl;
	for (int i = 1; i <= GetEntityCount(); i++)
	{
		if (IsValidEntity(i) && IsValidEdict(i))
		{
			GetEntityClassname(i, eName, sizeof(eName));
			if (strcmp(eName, "weapon_pain_pills_spawn") == 0) {
				pill++;
				if (pill > 2) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
				}
			}
			if (strcmp(eName, "weapon_adrenaline_spawn") == 0) {
				adr++;
				if (adr > 2) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
				}
			}
			if (strcmp(eName, "weapon_defibrillator_spawn") == 0) {
				defib++;
				if (defib > 1) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
				}
			}
			if (strcmp(eName, "weapon_vomitjar_spawn") == 0) {
				vomit++;
				if (vomit > 2) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
				}
			}
			if (strcmp(eName, "weapon_molotov_spawn") == 0) {
				molot++;
				if (molot > 1) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
				}
			}
			if (strcmp(eName, "weapon_pipe_bomb_spawn") == 0) {
				pipe++;
				if (pipe > 4) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
				}
			}
			
			if (strcmp(eName, "weapon_upgradepack_incendiary_spawn") == 0) {
				ince++;
				if (ince > 1) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
				}
			}
			if (strcmp(eName, "weapon_upgradepack_explosive_spawn") == 0) {
				expl++;
				if (expl > 1) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
				}
			}
		}
	}
}

stock bool isVersus()
{
	char CurrentGameMode[30];
	ConVar mp_gamemode = FindConVar("mp_gamemode");
	mp_gamemode.GetString(CurrentGameMode, sizeof(CurrentGameMode));
	delete mp_gamemode;
	if (strcmp(CurrentGameMode, "versus") == 0) {
		return true;
	}
	return false;
}

stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}

stock Action printItemCount(int client, int args)
{
	char eName[64];
	int pill, med, adr, pipe, molot, defib, vomit, ince, expl;
	for (int i = 1; i <= GetEntityCount(); i++)
	{
		if (IsValidEntity(i))
		{
			GetEntityClassname(i, eName, sizeof eName);
			if (strcmp(eName, "weapon_first_aid_kit_spawn") == 0) {
				med++;
			}
			if (strcmp(eName, "weapon_pain_pills_spawn") == 0) {
				pill++;
			}
			if (strcmp(eName, "weapon_adrenaline_spawn") == 0) {
				adr++;
			}
			if (strcmp(eName, "weapon_defibrillator_spawn") == 0) {
				defib++;
			}
			
			if (strcmp(eName, "weapon_vomitjar_spawn") == 0) {
				vomit++;
			}
			if (strcmp(eName, "weapon_molotov_spawn") == 0) {
				molot++;
			}
			if (strcmp(eName, "weapon_pipe_bomb_spawn") == 0) {
				pipe++;
			}
			
			if (strcmp(eName, "weapon_upgradepack_incendiary_spawn") == 0) {
				ince++;
			}
			if (strcmp(eName, "weapon_upgradepack_explosive_spawn") == 0) {
				expl++;
			}
		}
	}
	PrintToChat(client, "Incendiary: %i", ince); PrintToChat(client, "Explosive: %i", expl); PrintToChat(client, "Pipe: %i", pipe); PrintToChat(client, "Molotov: %i", molot); PrintToChat(client, "Vomit: %i", vomit); PrintToChat(client, "Pills: %i", pill); PrintToChat(client, "Adrenaline: %i", adr); PrintToChat(client, "Medkit: %i", med); PrintToChat(client, "Defib: %i", defib);
	return Plugin_Handled;
} 