#include <sourcemod>
#include <colors>
#include <left4dhooks>
#include <sdktools>
#include <sdkhooks>

bool rndEnd = false; // RoundEnd вызывается два раза. Это фикс

int witchBonus = 0; // 50
int medkitBonus = 0;
int incapBonus = 100;
bool incaped[8]; // 8 выживших. 0Namvet, 1Biker, 2Manager, 3Teen, | 4Gambler, 5Mechanic, 6Coach, 7Producer
int nodeadBonus = 100;
bool incapedByWitch = false; // Если true, то очки за ведьму не начисляются

public Plugin myinfo = 
{
	name = "BonusSystem", 
	author = "pa4H, vintik", 
	description = "", 
	version = "2.5", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_test", debb, "");
	RegConsoleCmd("sm_bonus", showBonus, "");
	
	HookEvent("witch_killed", WitchDeath_Event);
	HookEvent("player_incapacitated", PlayerIncapacitated_Event);
	HookEvent("player_death", Event_PlayerDeath);
	
	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
	
	LoadTranslations("pa4H-BonusSystem.phrases");
}
stock Action debb(int client, int args)
{
	return Plugin_Handled;
}

Action showBonus(int client, int args)
{
	int bonus = calcBonus();
	CPrintToChat(client, "%t", "ShowBonus", bonus, witchBonus, medkitBonus, incapBonus, nodeadBonus);
	return Plugin_Handled;
}

public WitchDeath_Event(Handle event, const char[] name, bool dontBroadcast)
{
	if (!incapedByWitch) {
		witchBonus = 50;
	}
}
public PlayerIncapacitated_Event(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	int witch = GetEventInt(event, "attackerentid");
	if (IsValidEntity(witch) && IsValidEdict(witch))
	{
		char class[32];
		GetEdictClassname(witch, class, sizeof(class));
		if (StrEqual(class, "witch")) {
			CPrintToChatAll("%t", "Incap", client);
			incapedByWitch = true;
		}
	}
	
	if (IsValidClientB(client) && GetClientTeam(client) == 2 && incapBonus != 0) {
		if (WhoIs(client, "Namvet") && !incaped[0]) {  // 0Namvet, 1Biker, 2Manager, 3Teen
			incapBonus -= 25;
			incaped[0] = true;
			return;
		}
		if (WhoIs(client, "Biker") && !incaped[1]) {
			incapBonus -= 25;
			incaped[1] = true;
			return;
		}
		if (WhoIs(client, "Manager") && !incaped[2]) {
			incapBonus -= 25;
			incaped[2] = true;
			return;
		}
		if (WhoIs(client, "Teen") && !incaped[3]) {
			incapBonus -= 25;
			incaped[3] = true;
			return;
		}
		if (WhoIs(client, "Gambler") && !incaped[4]) {  // 4Gambler, 5Mechanic, 6Coach, 7Producer
			incapBonus -= 25;
			incaped[4] = true;
			return;
		}
		if (WhoIs(client, "Mechanic") && !incaped[5]) {
			incapBonus -= 25;
			incaped[5] = true;
			return;
		}
		if (WhoIs(client, "Coach") && !incaped[6]) {
			incapBonus -= 25;
			incaped[6] = true;
			return;
		}
		if (WhoIs(client, "Producer") && !incaped[7]) {
			incapBonus -= 25;
			incaped[7] = true;
			return;
		}
	}
	
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	//int killer = GetClientOfUserId(event.GetInt("attacker"));
	
	if (!rndEnd && IsValidClientB(victim) && GetClientTeam(victim) == 2 && nodeadBonus != 0) {
		nodeadBonus -= 25;
	}
}

public void RoundEnd_Event(Event event, const char[] name, bool dontBroadcast)
{
	if (rndEnd) { return; }
	rndEnd = true;
	
	int bonus = calcBonus();
	
	CPrintToChatAll("%t", "RoundFinal", bonus);
	CPrintToChatAll("%t", "Bonuses", witchBonus, medkitBonus, incapBonus, nodeadBonus);
	
	bool bFlipped = !!GameRules_GetProp("m_bAreTeamsFlipped");
	int SurvivorTeamIndex = bFlipped ? 1 : 0;
	int InfectedTeamIndex = bFlipped ? 0 : 1;
	int surScore; int infScore;
	surScore = L4D2Direct_GetVSCampaignScore(SurvivorTeamIndex);
	infScore = L4D2Direct_GetVSCampaignScore(InfectedTeamIndex);
	
	surScore += bonus;
	
	SetScores(surScore, infScore);
	resetBonus();
}
public void RoundStart_Event(Event event, const char[] name, bool dontBroadcast)
{
	rndEnd = false;
}

public OnMapEnd()
{
	resetBonus();
}

int calcBonus()
{
	char medKit[32];
	medkitBonus = 0;
	for (int i = 1; i <= MaxClients; i++) {  // Считаем бонус за аптечку
		if (IsValidClientB(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !L4D_IsPlayerIncapacitated(i)) {
			int slotMedKit = GetPlayerWeaponSlot(i, 3);
			if (slotMedKit != -1) { GetEntityClassname(slotMedKit, medKit, sizeof(medKit)); } // Получаем имя предмета
			if (StrEqual(medKit, "weapon_first_aid_kit") == true) { medkitBonus += 25; medKit = ""; }
		}
	}
	return witchBonus + medkitBonus + incapBonus + nodeadBonus;
}

void resetBonus()
{
	witchBonus = 0; // max 50
	medkitBonus = 0; // max 100
	incapBonus = 100;
	nodeadBonus = 100;
	
	incapedByWitch = false;
	
	for (int i = 0; i < 8; i++) { incaped[i] = false; }
}

void SetScores(int surScore, int infScore)
{
	bool bFlipped = !!GameRules_GetProp("m_bAreTeamsFlipped");
	int newScores[2];
	newScores[0] = bFlipped ? infScore : surScore;
	newScores[1] = bFlipped ? surScore : infScore;
	L4D2_SetVersusCampaignScores(newScores);
}

stock bool Contains(const char[] one, const char[] two)
{
	if (StrContains(one, two, false) != -1) { return true; } else { return false; }
}
stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}

stock bool IsValidClientB(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client)) {
		return true;
	}
	return false;
}

bool WhoIs(int client, char[] playerName)
{
	char model[64];
	GetClientModel(client, model, sizeof(model));
	
	if (Contains(model, playerName)) {
		return true;
	}
	return false;
}

stock int GetCurFlow()
{
	int maxFlow = L4D_GetVersusMaxCompletionScore() / 4; // 800
	int maxSurFlow = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClientB(i) && GetClientTeam(i) == 2) {
			int buf = L4D2_GetVersusCompletionPlayer(i);
			if (maxSurFlow < buf) { maxSurFlow = buf; }
		}
	}
	return (maxSurFlow - 0) * (100 - 0) / (maxFlow - 0) + 0;
} 