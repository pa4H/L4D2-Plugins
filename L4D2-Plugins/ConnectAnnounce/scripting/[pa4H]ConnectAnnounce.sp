#include <sourcemod>
#include <geoip>
#include <colors>
#include <ripext> // Rest In Pawn. Либа для работы с http

char keyAPI[64]; // Ключ для Steam API
int steamPlayTime[MAXPLAYERS + 1]; // Наигранное время
Handle g_hSteamAPI_Key; // Для работы с sm_cvar SteamAPI_Key

public Plugin myinfo =  {
	name = "Connect Announce", 
	author = "pa4H", 
	description = "", 
	version = "2.0", 
	url = "https://t.me/pa4H232"
};

public OnPluginStart() {
	//RegAdminCmd("sm_test", hoursTest, ADMFLAG_BAN);
	
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
	g_hSteamAPI_Key = CreateConVar("SteamAPI_Key", "", "Your SteamAPI Key. Can get it on https://steamcommunity.com/dev/apikey", FCVAR_CHEAT);
	GetConVarString(g_hSteamAPI_Key, keyAPI, sizeof(keyAPI)); // И сразу его читаем
	HookConVarChange(g_hSteamAPI_Key, OnConVarChange);
	
	LoadTranslations("pa4HConAnnounce.phrases");
}

public OnConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetConVarString(g_hSteamAPI_Key, keyAPI, sizeof(keyAPI));
}

stock Action hoursTest(int client, int args) {
	//SteamAPI_GetHours("76561198037667913", client); // Для теста берём мой SteamID
	//SteamAPI_GetHours("76561198192540713", client);
	return Plugin_Handled;
}

public OnClientAuthorized(int client) // Когда игрок только-только подключился к серверу (Загружается)
{
	if (!IsFakeClient(client))
	{
		char nick[64]; char steamID64[32];
		
		GetClientName(client, nick, sizeof(nick));
		GetClientAuthId(client, AuthId_SteamID64, steamID64, sizeof(steamID64)); // Получаем SteamID64. Мой id: 76561198037667913 
		steamPlayTime[client] = 0; // Обнуляем количество часов клиента
		SteamAPI_GetHours(steamID64, client); // Получаем часы. Они будут храниться в массиве teamPlayTime
		
		CPrintToChatAll("%t", "PlayerLoading", nick);
	}
}

public Action PlayerDisconnect_Event(Handle event, const char[] name, bool dontBroadcast) // https://wiki.alliedmods.net/Generic_Source_Server_Events#player_disconnect
{
	char nick[64]; char reason[64];
	int client = GetClientOfUserId(GetEventInt(event, "userid")); // Получаем номер клиента
	
	if (IsValidClient(client)) {
		GetEventString(event, "name", nick, sizeof(nick)); // Получаем ник игрока
		GetEventString(event, "reason", reason, sizeof(reason)); // Получаем причину выхода
		ReplaceString(reason, sizeof(reason), ".", "")
		
		CPrintToChatAll("%t", "PlayerDisconnect", nick, reason);
	}
	return Plugin_Handled;
}

public OnClientPutInServer(int client) // Игрок загрузился
{
	if (!IsFakeClient(client)) {
		char Name[64]; char Country[4]; char IP[32]; char City[32]; char Hours[8];
		GetClientName(client, Name, sizeof(Name)); // Получаем имя игрока
		GetClientIP(client, IP, sizeof(IP), true); // Получаем IP игрока
		if (!GeoipCode3(IP, Country)) {  // Получаем RUS KAZ USA
			Country = "???"; // Если не удалось получить страну
		}
		if (!GeoipCity(IP, City, sizeof(City), -1)) {  // Получаем Barnaul Moscow
			City = "???";
		}
		
		if (steamPlayTime[client] == 0) {  // 0 - не удалось получить часы
			Hours = "?";
		} else {
			IntToString(steamPlayTime[client], Hours, sizeof(Hours)); // Переводим steamPlayTime в String
		}
		CPrintToChatAll("%t", "PlayerJoin", Name, Country, City, Hours); // {1} Игрок {2} ({3}, {4}) подключился! {5}ч
	}
}

public void SteamAPI_GetHours(char[] steamID, int client) {  // Формируем запрос: https://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v0001/?key=keyAPI&steamid=steamId&format=json
	HTTPRequest request = new HTTPRequest("https://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v0001");
	request.AppendQueryParam("key", "%s", keyAPI);
	request.AppendQueryParam("steamid", "%s", steamID);
	request.AppendQueryParam("format", "json");
	request.Get(OnTodosReceived, client); // Отправляем GET запрос
}

public void OnTodosReceived(HTTPResponse resp, any client) {  // Обработчик нашего запроса
	if (resp.Status != HTTPStatus_OK) {  // Проверка на ошибку запроса
		PrintToServer("SteamAPI GET Error");
		steamPlayTime[client] = 0; // Если не удалось получить часы, выдаём 0
		return;
	}
	
	JSONObject json_file = view_as<JSONObject>(resp.Data); // Сохраняем содержимое GET запроса
	JSONObject json_response = view_as<JSONObject>(json_file.Get("response")); // Получаем объект "response"
	if (json_response.Size >= 2) // Получаем количество объектов. Должно быть 2
	{
		JSONArray json_games = view_as<JSONArray>(json_response.Get("games")); // В объекте "response" получаем массив "games"		
		JSONObject todo; // Объект JSON'a с которым мы будем работать
		char gameName[32]; // Название игры
		
		for (int i = 0; i < json_games.Length; i++) // Проходим по всем объектам в массиве "games" // Количество объектов в массиве. Их будет 5
		{
			todo = view_as<JSONObject>(json_games.Get(i)); // Получаем объект под номером i
			todo.GetString("name", gameName, sizeof(gameName)); // Получаем ключ "name"
			
			if (StrContains(gameName, "Left 4 Dead", false) != -1) // Если "name": "Left 4 Dead 2", то...
			{
				steamPlayTime[client] = todo.GetInt("playtime_forever"); // Получаем параметр "playtime_forever"
				steamPlayTime[client] /= 60; // Делим полученные минуты на 60 и получаем ЧАСЫ
				PrintToServer("client: %i name: %s hours: %i", client, gameName, steamPlayTime[client]); // debug
				break; // Нашли что искали? Выходим из цикла
			}
		}
		
		delete json_games; // Чистим за собой
		delete todo;
	}
	else // У игрока скрытый профиль. 0 часов
	{
		steamPlayTime[client] = 0;
	}
	delete json_file; // Чисти
	delete json_response; // Чисти
}

bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
} 