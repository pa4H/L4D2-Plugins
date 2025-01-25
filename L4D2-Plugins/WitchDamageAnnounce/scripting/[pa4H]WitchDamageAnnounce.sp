#include <sourcemod>
#include <sdktools>    
#include <left4dhooks>
#include <colors>

#define L4D_TEAM_SPECTATOR 1
#define L4D_TEAM_SURVIVOR 2
#define L4D_TEAM_INFECTED 3

int witchDamage[MAXPLAYERS + 1];
int maxHP; // Фактические ХП Ведьмы
int sortedClients[MAXPLAYERS + 1]; // Нужно для корректного вывода отсортированного урона
int clientCount = 0;

public Plugin myinfo = 
{
	name = "WitchDamageAnnounce", 
	author = "pa4H", 
	description = "", 
	version = "2.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", test);
	HookEvent("infected_hurt", WitchHurt_Event, EventHookMode_Post);
	HookEvent("witch_killed", WitchDeath_Event, EventHookMode_Post);
	
	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
	
	LoadTranslations("pa4H-TankAndWitchDamageAnnounce.phrases");
}

stock Action test(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

void PrintDamage()
{
	CPrintToChatAll("%t", "WitchKilled");
	for (int i = 0; i < clientCount; i++)
	{
		if (IsValidClientB(sortedClients[i]) && witchDamage[sortedClients[i]] > 0) {
			CPrintToChatAll("  {olive}%i {default}[{green}%i%%{default}]: {lightgreen}%N", witchDamage[sortedClients[i]], map(witchDamage[sortedClients[i]], 0, maxHP, 0, 100), sortedClients[i]); // 1024 [100%]: Nickname
		}
	}
	ClearWitchDamage();
}

public void RoundEnd_Event(Event event, const char[] name, bool dontBroadcast)
{
	ClearWitchDamage();
}

public void OnMapEnd() // Требуется, поскольку принудительная смена карты не вызывает событие "round_end"
{
	ClearWitchDamage();
}
public WitchHurt_Event(Handle event, const char[] name, bool dontBroadcast)
{
	int ent = GetEventInt(event, "entityid");
	if (IsWitch(ent))
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		
		if (attacker != 0 && IsClientConnected(attacker) && GetClientTeam(attacker) == L4D_TEAM_SURVIVOR)
		{
			witchDamage[attacker] += GetEventInt(event, "amount");
		}
	}
}
public WitchDeath_Event(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) { if (IsValidClientB(i)) { maxHP += witchDamage[i]; } } // Получаем фактические ХП Ведьмы
	
	for (int i = 1; i <= MaxClients; i++) // Сортировка урона
	{
		if (witchDamage[i] != 0)
		{
			sortedClients[clientCount] = i;
			clientCount++;
		}
	}
	SortIndicesByValue(witchDamage, sortedClients, clientCount);
	
	PrintDamage();
	ClearWitchDamage();
}
void ClearWitchDamage()
{
	for (int i = 1; i <= MaxClients; i++) { sortedClients[i] = 0; witchDamage[i] = 0; }
	maxHP = 0;
	clientCount = 0;
}
stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}
stock bool IsValidClientB(int client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client)) {
		return true;
	}
	return false;
}
stock bool IsWitch(iEntity)
{
	if (iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		char strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}
public int map(int x, int in_min, int in_max, int out_min, int out_max) // Пропорция
{
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

public void SortIndicesByValue(int[] damage, int[] indices, int size) // Сортировка методом выбора
{
	for (int i = 0; i < size - 1; i++)
	{
		for (int j = i + 1; j < size; j++)
		{
			// Если значение в witchDamage для индекса больше, меняем местами индексы
			if (damage[indices[i]] < damage[indices[j]])
			{
				int temp = indices[i];
				indices[i] = indices[j];
				indices[j] = temp;
			}
		}
	}
} 