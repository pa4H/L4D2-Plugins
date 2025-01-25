#include <sourcemod>
#include <sdktools>    // Для GameRules_GetProp();
#include <left4dhooks> // https://forums.alliedmods.net/showthread.php?t=321696
#include <colors>

char mapName[64]; // Карта (c8m1_apartment)
// У каждой карты есть прогресс прохождения в процентах. От 0% до 100%

bool tankIsAlive = false; // Фикс бага с выводом сообщения о спауне Танка
Handle g_hVsBossBuffer; // Для корректного подсчета процента спауна Танка

char restrictedMaps[][32] =  {  // Запрещенные карты
	"c5m5_bridge", "c7m1_docks", "c7m3_port", "c6m3_port", "c4m5_milltown_escape", "c13m2_southpinestream"
};

public Plugin myinfo = 
{
	name = "Tank&Witch on every map and !boss", 
	author = "pa4H", 
	description = "", 
	version = "030824", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", testTank, "");
	
	RegConsoleCmd("sm_boss", getBossFlowsm, "");
	RegConsoleCmd("sm_tank", getBossFlowsm, "");
	RegConsoleCmd("sm_witch", getBossFlowsm, "");
	
	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy); // Сервер запустился
	HookEvent("tank_spawn", TankNotify, EventHookMode_PostNoCopy); // Событие уведомляющее о появлении Танка
	HookEvent("player_death", TankDead, EventHookMode_Pre);
	
	g_hVsBossBuffer = FindConVar("versus_boss_buffer"); // Для корректного подсчета процента спауна Танка
	
	LoadTranslations("pa4HTankSpawnNotify.phrases"); // translations/pa4HTankSpawnNotify.phrases.txt
}

stock Action testTank(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

public RoundStartEvent(Handle event, const char[] name, bool dontBroadcast) // Сервер запустился
{
	tankIsAlive = false; // Разрешаем выводить "Танк появился" в чат
	if (GameRules_GetProp("m_bInSecondHalfOfRound") == 0) { CreateTimer(0.4, AdjustBossFlow); } // После Round Start с задержкой задаём процент спауна Танка
	
}
public Action AdjustBossFlow(Handle timer)
{
	L4D2Direct_SetVSTankToSpawnThisRound(0, true); // Приказываем директору заспаунить Танка в 1 раунде
	L4D2Direct_SetVSTankToSpawnThisRound(1, true); // Приказываем во 2 раунде
	L4D2Direct_SetVSWitchToSpawnThisRound(0, true); // Вичка
	L4D2Direct_SetVSWitchToSpawnThisRound(1, true);
	
	GetCurrentMap(mapName, sizeof(mapName)); //PrintToChatAll(mapName); // Получаем карту
	for (int i = 0; i < sizeof(restrictedMaps); i++) // Перебираем список запрещенных карт
	{
		if (StrEqual(restrictedMaps[i], mapName)) // Если текущая карта есть в списке запрещенных
		{
			L4D2Direct_SetVSTankToSpawnThisRound(0, false); // Запрещаем спаун Танка
			L4D2Direct_SetVSTankToSpawnThisRound(1, false);
			break;
		}
	}
	
	if (L4D_IsMissionFinalMap() == true) // Если играют последную карту. Дело в том, что director не спаунит Танка на 1 и последней карте
	{
		randomSpawn(false); // Задаем проценты появления Танка и Вички БЕЗ рандома
	}
	else // Если играем любую другую карту
	{
		if (GameRules_GetProp("m_bInSecondHalfOfRound") == 0) // Если первая половина раунда
		{
			randomSpawn(true); // Задаем проценты появления Танка и Вички рандомно
		}
	}
	return Plugin_Stop;
}

public void randomSpawn(bool isRandom) // Функция задающая процент спауна Вички и Танка
{
	float rndFlowTank; // Процент на котором появится Танк
	float rndFlowWitch; // Процент на котором появится Ведьма
	
	if (isRandom) // Получаем рандомный процент. Если 0.9, значит будет 80%. Если 0.2, значит будет 10%
	{
		rndFlowTank = CalcFlow(GetRandomInt(50, 80));
		rndFlowWitch = CalcFlow(GetRandomInt(20, 45));
	}
	else
	{
		rndFlowTank = CalcFlow(10); // Фиксированный процент
		rndFlowWitch = CalcFlow(10);
	}
	
	// Что за 1 и 2 раунды? Одна карта делится на два раунда. Первая команда зашла в saferoom или сдохла — начинается 2 раунд и команды меняются местами
	L4D2Direct_SetVSWitchFlowPercent(0, rndFlowWitch); // Задаем процент прохождения карты на котором появится Ведьма для 1 раунда
	L4D2Direct_SetVSWitchFlowPercent(1, rndFlowWitch); // Для 2 раунда
	L4D2Direct_SetVSTankFlowPercent(0, rndFlowTank); // Танк
	L4D2Direct_SetVSTankFlowPercent(1, rndFlowTank);
}

public Action getBossFlowsm(int client, int args) // Считываем процент на котором заспаунится Танк\Вичка и выводим в чат
{
	int round = GameRules_GetProp("m_bInSecondHalfOfRound");
	if (L4D2Direct_GetVSTankToSpawnThisRound(0) || L4D2Direct_GetVSTankToSpawnThisRound(1))
	{
		PrintToChat(client, "\x01Tank spawn: [\x04%.0f%%\x01]", GetTankFlow(round) * 100); // Tank spawn: [49%]
	}
	else
	{
		PrintToChat(client, "\x01Tank spawn: [\x04None\x01]"); // Tank spawn: [None]
	}
	
	PrintToChat(client, "\x01Witch spawn: [\x04%.0f%%\x01]", GetWitchFlow(round) * 100); // Witch spawn: [49%]
	return Plugin_Handled;
}

public void TankNotify(Event event, const char[] name, bool dontBroadcast) // Танк появился!
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!tankIsAlive)
	{
		tankIsAlive = true; // Шоб сообщение не выводилось дважды
		PrecacheSound("ui/pickup_secret01.wav");
		EmitSoundToAll("ui/pickup_secret01.wav");
		if (IsFakeClient(client)) {
			CPrintToChatAll("%t", "TankIsHereBOT");
		}
		else {
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					if (i == client) {
						CPrintToChat(i, "%t", "PassTankNotify");
					}
					else {
						CPrintToChat(i, "%t", "TankIsHere", client);
					}
				}
			}
		}
	}
}
public void TankDead(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (victim != 0 && GetClientTeam(victim) == L4D_TEAM_INFECTED) // Infected is dead
	{
		int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass"); // Smoker 1, Boomer 2, Hunter 3, Spitter 4, Jockey 5, Charger 6, Witch 7, Tank 8
		if (zClass == 8) {  // Tank
			tankIsAlive = false;
		}
	}
}
float CalcFlow(int per)
{
	return ((float(per) + 0.01) / 100.0) + GetConVarFloat(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance();
}
float GetTankFlow(int round)
{
	return L4D2Direct_GetVSTankFlowPercent(round) - GetConVarFloat(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance();
}
float GetWitchFlow(int round)
{
	return L4D2Direct_GetVSWitchFlowPercent(round) - GetConVarFloat(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance();
}
stock float map(float x, float in_min, float in_max, float out_min, float out_max) // Пропорция
{
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}
stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}

// Редактируем vscript карты
public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal)
{
	int val = retVal;
	if (StrEqual(key, "ProhibitBosses")) {
		val = 0;
	}
	if (StrEqual(key, "DisallowThreatType")) {
		val = 0;
	}
	if (StrEqual(key, "TankLimit")) {
		val = 1;
	}
	if (StrEqual(key, "WitchLimit")) {
		val = 1;
	}
	
	if (val != retVal) {
		retVal = val;
		return Plugin_Handled;
	}
	return Plugin_Continue;
} 