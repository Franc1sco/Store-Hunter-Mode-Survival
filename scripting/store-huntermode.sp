/*  [Store] Hunter Mode Survival
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdktools>
#include <store>

#undef REQUIRE_PLUGIN
#include <zombiereloaded>
#define REQUIRE_PLUGIN

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"



new Handle:g_Enabled = INVALID_HANDLE;

new Handle:g_Earn = INVALID_HANDLE;
new Handle:g_minimum = INVALID_HANDLE;

new Survived[MAXPLAYERS+1] = 0;

new bool:g_death[MAXPLAYERS+1];


public Plugin:myinfo = 
{
	name = "[Store] Hunter Mode Survival",
	author = "Franc1sco steam: franug",
	description = "Earn points depending how long you survived in a round.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/franug"
}

public OnPluginStart()
{
	LoadTranslations("store_survive.phrases");

	CreateConVar("sm_huntermode_version", PLUGIN_VERSION, "Version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	g_Enabled = CreateConVar("sm_huntermode_enabled", "1", "enable plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	g_Earn = CreateConVar("sm_huntermode_divisor", "60", "value that divide the seconds survived and the result is the credits that are given to the player");

	g_minimum = CreateConVar("sm_huntermode_minplayers", "6", "minimum players in game required to enable the plugin feature");

	HookEvent("round_end", EventRoundEnd);

	HookEvent("round_start", roundStart);
	
}

public OnMapStart()
{
	CreateTimer(1.0, Temporizador, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Temporizador(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++) 
		if(IsClientInGame(i) && IsPlayerAlive(i) && !g_death[i])
			++Survived[i];

}

public Action:roundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	for(new i = 1; i <= MaxClients; i++) 
	{
		Survived[i] = 0;
		g_death[i] = false;
	}
}

public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_Enabled))
		return;

	new count = 0;
	for(new i = 1; i <= MaxClients; i++) 
		if(IsClientInGame(i))
			++count;

	if(GetConVarInt(g_minimum) > count)
		return;


	new divide = GetConVarInt(g_Earn);

	for(new i = 1; i <= MaxClients; i++) 
		if(IsClientInGame(i) && Survived[i] > 0)
			Earn_Credits(i, divide);
}

Earn_Credits(client, divide)
{
	new iPTG = Survived[client]/divide;
	
	new accid = Store_GetClientAccountID(client);
	
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackCell(pack, iPTG);
	
	Store_GiveCredits(accid, iPTG, CreditsCallback, pack);
}

public CreditsCallback(accountId, any:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new iPTG = ReadPackCell(pack);
	CloseHandle(pack);
	
	PrintToChat(client, "\x04[Store]\x01 %t","survive message", iPTG, Survived[client]);
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_death[client] = true;
}

#if defined _zr_included

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	g_death[client] = true;
}

#endif
