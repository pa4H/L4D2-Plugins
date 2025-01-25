#include <sourcemod>
#include <sdktools>
#include <colors>

char txtBufer[256];
char txtTime[32];
char slovoA[64];
char slovoB[64];

int scoreA;
int scoreB;
int canFill;

#include "ScavengeHelper/chat.sp"

public Plugin myinfo = 
{
	name = "Scavenge Helper", 
	author = "pa4H", 
	description = "", 
	version = "2.0", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_test", debb, "");
	RegConsoleCmd("sm_time", showTime, "");
	
	HookEvent("scavenge_round_halftime", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_finished", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("scavenge_match_finished", RoundEnd, EventHookMode_PostNoCopy);
	
	HookEvent("gascan_pour_completed", Event_PourCompleted);
	
	LoadTranslations("pa4H-ScavengeHelper");
}

stock Action debb(int client, int args) // DEBUG
{
	GetTimer(2); // Получаем время на таймере у противоположки (так как она в пред. раунде играла за людей)
	CPrintToChat(client, "2: %t", "ShowTime", txtTime);
	return Plugin_Handled;
}

public Action showTime(int client, int args) // Время прошлого раунда
{
	if (GameRules_GetProp("m_bInSecondHalfOfRound") == 1) // Если половинка раунда
	{
		GetTimer(3); // Получаем время на таймере у противоположки (так как она в пред. раунде играла за людей)
		CPrintToChat(client, "%t", "ShowTime", txtTime);
	}
	else // Если половинка раунда не прошла
	{
		CPrintToChat(client, "%t\n", "smTimeNo");
	}
	return Plugin_Handled;
}

void learnSlovoA()
{
	if ((scoreA == 0) || (scoreA >= 5 && scoreA <= 20)) // Ноль канистр. Двадцать канистр
	{
		FormatEx(slovoA, sizeof(slovoA), "%t", "Kanistr");
	}
	else if (scoreA == 1) // Одну канистру
	{
		FormatEx(slovoA, sizeof(slovoA), "%t", "Kanistru");
	}
	else if (scoreA >= 2 && scoreA <= 4) // Четыре канистры
	{
		FormatEx(slovoA, sizeof(slovoA), "%t", "Kanistry");
	}
	else if (scoreA == 21) // Двадцать одну канистру
	{
		FormatEx(slovoA, sizeof(slovoA), "%t", "21Kanistru");
	}
}
void learnSlovoB()
{
	if ((scoreB == 0) || (scoreB >= 5 && scoreB <= 20)) // Ноль канистр. Двадцать канистр
	{
		FormatEx(slovoB, sizeof(slovoB), "%t", "Kanistr");
	}
	else if (scoreB == 1) // Одну канистру
	{
		FormatEx(slovoB, sizeof(slovoB), "%t", "Kanistru");
	}
	else if (scoreB >= 2 && scoreB <= 4) // Четыре канистры
	{
		FormatEx(slovoB, sizeof(slovoB), "%t", "Kanistry");
	}
	else if (scoreB == 21) // Двадцать одну канистру
	{
		FormatEx(slovoB, sizeof(slovoB), "%t", "21Kanistru");
	}
}

void GetTimer(int team) // На выходе переменная char txtTime
{
	float rSeconds = (90.0 - GameRules_GetRoundDuration(team)) + (float(canFill) * 20.0);
	int min = RoundToFloor(rSeconds) / 60;
	rSeconds -= 60 * min;
	if (rSeconds < 10) {
		FormatEx(txtTime, sizeof(txtTime), "%i:0%.0f", min, rSeconds);
	}
	else {
		FormatEx(txtTime, sizeof(txtTime), "%i:%.0f", min, rSeconds);
	}
}

stock float GameRules_GetRoundDuration(int team)
{
	float flRoundStartTime = GameRules_GetPropFloat("m_flRoundStartTime");
	
	if (team == 2 && flRoundStartTime != 0.0 && GameRules_GetPropFloat("m_flRoundEndTime") == 0.0)
	{
		return GetGameTime() - flRoundStartTime;
	}
	
	team = L4D2_TeamNumberToTeamIndex(team);
	
	if (team == -1)
	{
		return -1.0;
	}
	
	return GameRules_GetPropFloat("m_flRoundDuration", team);
}


stock int GameRules_GetScavengeTeamScore(int team, int round = -1)
{
	team = L4D2_TeamNumberToTeamIndex(team);
	
	if (team == -1)
	{
		return -1;
	}
	
	if (round <= 0 || round > 5)
	{
		round = GameRules_GetProp("m_nRoundNumber");
	}
	
	--round;
	
	return GameRules_GetProp("m_iScavengeTeamScore", _, (2 * round) + team);
}

stock int L4D2_TeamNumberToTeamIndex(int team)
{
	if (team != 2 && team != 3)
	{
		return -1;
	}
	
	bool flipped = view_as<bool>(GameRules_GetProp("m_bAreTeamsFlipped", 1));
	
	if (flipped)
	{
		++team;
	}
	
	return team % 2;
}
public void Event_PourCompleted(Event event, const char[] name, bool dontBroadcast)
{
	if (GameRules_GetProp("m_bInSecondHalfOfRound") == 0) { canFill++; }
}
stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}
