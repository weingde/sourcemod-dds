/************************************************************************
 * Dynamic Dollar Shop - [Module] Player Skin (Sourcemod)
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

#define DDS_ADD_NAME			"Dynamic Dollar Shop :: [Module] Player Skin"
#define DDS_ITEMCG_PSKIN_R		2
#define DDS_ITEMCG_PSKIN_B		3

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
	description = "This can allow clients to apply specific player models.",
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

	// 게임 별 이벤트 후킹
	System_SetHookEvent(dds_sGameIdentity);
}

/**
 * 라이브러리가 추가될 때
 *
 * @param name					로드된 라이브러리 명
 */
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "dds_core", false))
	{
		// '스킨' 아이템 종류 생성
		DDS_CreateItemCategory(DDS_ITEMCG_PSKIN_R);
		DDS_CreateItemCategory(DDS_ITEMCG_PSKIN_B);
	}
}

/**
 * 코어에서 아이템을 모두 로드한 후에 발생
 */
public void DDS_OnLoadSQLItem()
{
	// 등록된 모델 프리캐시
	for (int i = 0; i < DDS_ENV_ITEM_MAX; i++)
	{
		// '전체'는 통과
		if (i == 0)	continue;

		// 아이템 종류 번호 획득
		char sItem_Code[8];
		DDS_GetItemInfo(i, ItemInfo_CATECODE, sItem_Code, true);

		// 현재의 아이템 종류 코드와 맞지 않으면 통과
		if ((StringToInt(sItem_Code) != DDS_ITEMCG_PSKIN_R) && (StringToInt(sItem_Code) != DDS_ITEMCG_PSKIN_B))	continue;

		// 아이템 정보 모델 획득
		char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
		DDS_GetItemInfo(i, ItemInfo_ENV, sGetEnv);

		// 환경변수에서 모델 정보 로드
		char sModelStr[128];
		SelectedStuffToString(sGetEnv, "ENV_DDS_INFO_ADRS", "||", ":", sModelStr, sizeof(sModelStr));

		// 프리캐시
		PrecacheModel(sModelStr, true);
	}
}


/*******************************************************
 * G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * System :: 게임 별 이벤트 연결
 *
 * @param gamename					게임 이름
 */
public void System_SetHookEvent(const char[] gamename)
{
	if (StrEqual(gamename, "cstrike", false))
	{
		/********************************************
		 * '카운터 스트라이크: 소스'
		*********************************************/
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
	else if (StrEqual(gamename, "tf", false))
	{
		/********************************************
		 * 팀 포트리스
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

	// 서버는 통과
	if (client == 0)	return Plugin_Continue;

	// 클라이언트가 게임 내에 없다면 통과
	if (!IsClientInGame(client))	return Plugin_Continue;

	// 클라이언트가 인증을 받지 못했다면 통과
	if (!IsClientAuthorized(client))	return Plugin_Continue;

	// 클라이언트가 살아있지 않다면 통과
	if (!IsPlayerAlive(client))	return Plugin_Continue;

	// 클라이언트가 봇이라면 통과
	if (IsFakeClient(client))	return Plugin_Continue;

	// 클라이언트 팀 파악
	int iClient_Team = GetClientTeam(client);

	// 팀 구분
	switch (iClient_Team)
	{
		case 2:
		{
			// 레드
			if (DDS_GetClientItemCategorySetting(client, DDS_ITEMCG_PSKIN_R) && (DDS_GetClientAppliedItem(client, DDS_ITEMCG_PSKIN_R) > 0))
			{
				/** 특정 아이템을 적용하고 있을 경우 **/
				// ENV 설정 로드
				char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
				DDS_GetItemInfo(DDS_GetClientAppliedItem(client, DDS_ITEMCG_PSKIN_R), ItemInfo_ENV, sGetEnv);

				// 필요 주소 파악
				char sItemAdrs[128];
				SelectedStuffToString(sGetEnv, "ENV_DDS_INFO_ADRS", "||", ":", sItemAdrs, sizeof(sItemAdrs));

				// 모델 적용
				SetEntityModel(client, sItemAdrs);
			}
			else
			{
				/** 게임 종류에 따른 기본 모델 설정 **/
				if (StrEqual(dds_sGameIdentity, "cstrike", false))
				{
					SetEntityModel(client, "models/player/t_guerilla.mdl");
				}
			}
		}
		case 3:
		{
			// 블루
			if (DDS_GetClientItemCategorySetting(client, DDS_ITEMCG_PSKIN_B) && (DDS_GetClientAppliedItem(client, DDS_ITEMCG_PSKIN_B) > 0))
			{
				/** 특정 아이템을 적용하고 있을 경우 **/
				// ENV 설정 로드
				char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
				DDS_GetItemInfo(DDS_GetClientAppliedItem(client, DDS_ITEMCG_PSKIN_B), ItemInfo_ENV, sGetEnv);

				// 필요 주소 파악
				char sItemAdrs[128];
				SelectedStuffToString(sGetEnv, "ENV_DDS_INFO_ADRS", "||", ":", sItemAdrs, sizeof(sItemAdrs));

				// 모델 적용
				SetEntityModel(client, sItemAdrs);
			}
			else
			{
				/** 게임 종류에 따른 기본 모델 설정 **/
				if (StrEqual(dds_sGameIdentity, "cstrike", false))
				{
					SetEntityModel(client, "models/player/ct_urban.mdl");
				}
			}
		}
	}

	return Plugin_Continue;
}