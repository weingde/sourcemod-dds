/************************************************************************
 * Dynamic Dollar Shop - [Option] StartUp Model Fix (Sourcemod)
 * 
 * Copyright (C) 2012-2015 Eakgnarok
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 * 
 ***********************************************************************/
#include <sourcemod>
#include <sdktools>
#include <dds>

#define DDS_ADD_NAME			"Dynamic Dollar Shop :: [Option] StartUp Model Fix"

/*******************************************************
 * V A R I A B L E S
*******************************************************/
// 게임 식별
char dds_sGameIdentity[32];
bool dds_bGameCheck;

/*******************************************************
 * P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = DDS_ADD_NAME,
	author = DDS_ENV_CORE_AUTHOR,
	description = "This can help clients to use several internal model entity by changing model to some special model.",
	version = DDS_ENV_CORE_VERSION,
	url = DDS_ENV_CORE_HOMEPAGE
};

/*******************************************************
 * F O R W A R D   F U N C T I O N S
*******************************************************/
/**
 * 플러그인 시작 시
 */
public void OnPluginStart()
{
	// Event Hook 연결
	HookEvent("player_spawn", Event_OnPlayerSpawn);
}

/**
 * 설정이 로드되고 난 후
 */
public void OnConfigsExecuted()
{
	// 플러그인이 꺼져 있을 때는 동작 안함
	if (!DDS_IsPluginOn())	return;

	// 게임 식별
	GetGameFolderName(dds_sGameIdentity, sizeof(dds_sGameIdentity));

	// 프리캐시 시작
	System_PrecacheModel(dds_sGameIdentity);
}

/*******************************************************
 * G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * System :: 게임 별 준비된 모델 프리캐시 준비
 *
 * @param gamename					게임 이름
 */
public void System_PrecacheModel(const char[] gamename)
{
	if (StrEqual(gamename, "cstrike", false))
	{
		/********************************************
		 * '카운터 스트라이크: 소스'
		*********************************************/
		// 모델 프리캐시
		PrecacheModel("models/player/ct_urban.mdl", true);

		// 게임 식별 완료
		dds_bGameCheck = true;
	}
	else if (StrEqual(gamename, "csgo", false))
	{
		/********************************************
		 * '카운터 스트라이크: 글로벌 오펜시브'
		*********************************************/

		// 게임 식별 완료
		dds_bGameCheck = true;
	}
}


/*******************************************************
 * C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 이벤트 :: 플레이어가 생성될 때
 *
 * @param event					이벤트 핸들
 * @param name					이벤트 이름 문자열
 * @param dontbroadcast			이벤트 브로드캐스트 차단 여부
 */
public Action Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	// 플러그인이 꺼져 있을 때는 동작 안함
	if (!DDS_IsPluginOn())	return Plugin_Continue;

	// 게임이 식별되지 않은 경우에는 동작 안함
	if (!dds_bGameCheck)	return Plugin_Continue;

	// 이벤트 핸들을 통해 클라이언트 식별
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// 클라이언트가 게임 내에 없다면 통과
	if (!IsClientInGame(client))	return Plugin_Continue;

	// 클라이언트가 인증을 받지 못했다면 통과
	if (!IsClientAuthorized(client))	return Plugin_Continue;

	// 클라이언트가 살아있지 않다면 통과
	if (!IsPlayerAlive(client))	return Plugin_Continue;

	// 클라이언트가 봇이라면 통과
	if (IsFakeClient(client))	return Plugin_Continue;

	// 현재 적용된 모델 추출
	char sCurModel[128];
	GetClientModel(client, sCurModel, sizeof(sCurModel));

	// 게임 구분에 따른 처리
	if (StrEqual(dds_sGameIdentity, "cstrike", false))
	{
		// 모델 내부 정보 값이 좀 더 많은 것으로 대체
		if (StrEqual(sCurModel, "models/player/ct_gsg9.mdl", false) || StrEqual(sCurModel, "models/player/ct_sas.mdl", false))
			SetEntityModel(client, "models/player/ct_urban.mdl");
	}

	return Plugin_Continue;
}