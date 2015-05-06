/************************************************************************
 * Dynamic Dollar Shop - [Module] Trail (Sourcemod)
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

#define DDS_ADD_NAME			"Dynamic Dollar Shop :: [Module] Trail"
#define DDS_ITEMCG_TRAIL_ID		1

/*******************************************************
 * V A R I A B L E S
*******************************************************/
// 게임 식별
char dds_sGameIdentity[32];
bool dds_bGameCheck;

// 유저 별 트레일 엔티티 번호
int dds_iUserTrailEntIdx[MAXPLAYERS + 1];

/*******************************************************
 * P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = DDS_ADD_NAME,
	author = DDS_ENV_CORE_AUTHOR,
	description = "This can allow clients to use trail function.",
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
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("player_team", Event_OnPlayerTeam);
}

/**
 * 설정이 로드되고 난 후
 */
public void OnConfigsExecuted()
{
	// 플러그인이 꺼져 있을 때는 동작 안함
	if (!DDS_IsPluginOn())	return;

	// 유저 엔티티 데이터 초기화
	Init_UserEntData(0, 1);

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
		// '트레일' 아이템 종류 생성
		DDS_CreateItemCategory(DDS_ITEMCG_TRAIL_ID);
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
		if (StringToInt(sItem_Code) != DDS_ITEMCG_TRAIL_ID)	continue;

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

/**
 * 클라이언트가 접속하면서 스팀 고유번호를 받았을 때
 *
 * @param client			클라이언트 인덱스
 * @param auth				클라이언트 고유 번호(타입 2)
 */
public void OnClientAuthorized(int client, const char[] auth)
{
	// 플러그인이 꺼져 있을 때는 동작 안함
	if (!DDS_IsPluginOn())	return;

	// 봇은 제외
	if (IsFakeClient(client))	return;

	// 서버는 제외
	if (client == 0)	return;

	// 엔티티 초기화
	dds_iUserTrailEntIdx[client] = -1;
}

/**
 * 클라이언트가 서버로부터 나가고 있을 때
 *
 * @param client			클라이언트 인덱스
 */
public void OnClientDisconnect(int client)
{
	// 게임에 없으면 통과
	if (!IsClientInGame(client))	return;

	// 봇은 제외
	if (IsFakeClient(client))	return;

	// 엔티티 초기화
	dds_iUserTrailEntIdx[client] = -1;
}


/*******************************************************
 * G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 초기화 :: 유저 엔티티 데이터
 *
 * @param client			클라이언트 인덱스
 * @param mode				처리 모드(1 - 전체 초기화, 2 - 특정 클라이언트 초기화)
 */
public void Init_UserEntData(int client, int mode)
{
	switch (mode)
	{
		case 1:
		{
			for (int i = 0; i <= MAXPLAYERS; i++)
			{
				// 트레일 엔티티 초기화
				dds_iUserTrailEntIdx[i] = -1;
			}
		}
		case 2:
		{
			// 트레일 엔티티 초기화
			dds_iUserTrailEntIdx[client] = -1;
		}
	}
}


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
		// 프리징 엔드에 연결
		HookEvent("round_freeze_end", Event_OnRoundStart);

		// 게임 식별 완료
		dds_bGameCheck = true;
	}
	else if (StrEqual(gamename, "csgo", false))
	{
		/********************************************
		 * '카운터 스트라이크: 글로벌 오펜시브'
		*********************************************/
		// 프리징 엔드에 연결
		HookEvent("round_freeze_end", Event_OnRoundStart);

		// 게임 식별 완료
		dds_bGameCheck = true;
	}
	else if (StrEqual(gamename, "tf", false))
	{
		/********************************************
		 * 팀 포트리스
		*********************************************/
		// 아레나, 팀플래이 라운드 시작에 연결
		HookEvent("arena_round_start", Event_OnRoundStart);
		HookEvent("teamplay_round_start", Event_OnRoundStart);

		// 게임 식별 완료
		dds_bGameCheck = true;
	}
}


/**
 * Entity :: 트레일 생성
 *
 * @param client				클라이언트 인덱스
 *
 * @ref 'env_spritetrail' - https://developer.valvesoftware.com/wiki/Env_spritetrail
 * @ref 'SpriteTrail.cpp' - https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/shared/SpriteTrail.cpp
 */
public void Entity_CreateTrail(int client)
{
	/**************************************
	 * 준비
	***************************************/
	// 해당 아이템 환경변수 로드
	char sItemEnv[DDS_ENV_VAR_ENV_SIZE];
	DDS_GetItemInfo(DDS_GetClientAppliedItem(client, DDS_ITEMCG_TRAIL_ID), ItemInfo_ENV, sItemEnv);

	// 현재 클라이언트의 위치 파악
	float fClient_Pos[3];
	GetClientAbsOrigin(client, fClient_Pos);

	// z값 수정
	fClient_Pos[2] += 10.0;

	// 위치값을 문자열 파라메터로 변환
	char sClient_PosSet[128];
	Format(sClient_PosSet, sizeof(sClient_PosSet), "%f %f %f", fClient_Pos[0], fClient_Pos[1], fClient_Pos[2]);

	// 모델 정보 로드
	char sTrail_ModelSet[128];
	SelectedStuffToString(sItemEnv, "ENV_DDS_INFO_ADRS", "||", ":", sTrail_ModelSet, sizeof(sTrail_ModelSet));

	// 색상 정보 로드
	char sTrail_ColorSet[32];
	SelectedStuffToString(sItemEnv, "ENV_DDS_INFO_COLOR", "||", ":", sTrail_ColorSet, sizeof(sTrail_ColorSet));

	// 로드했을 때 값이 유효하지 않을 경우 직접 치환
	if (strlen(sTrail_ColorSet) <= 0)	Format(sTrail_ColorSet, sizeof(sTrail_ColorSet), "255 255 255 255");

	/**************************************
	 * 엔티티 생성
	***************************************/
	// 엔티티 부여
	dds_iUserTrailEntIdx[client] = CreateEntityByName("env_spritetrail");

	// 엔티티 기본 정보 설정
	DispatchKeyValue(dds_iUserTrailEntIdx[client], "Origin", sClient_PosSet);
	DispatchKeyValue(dds_iUserTrailEntIdx[client], "lifetime", "2.5");
	DispatchKeyValue(dds_iUserTrailEntIdx[client], "startwidth", "16.0");
	DispatchKeyValue(dds_iUserTrailEntIdx[client], "endwidth", "8.0");
	DispatchKeyValue(dds_iUserTrailEntIdx[client], "spritename", sTrail_ModelSet);
	DispatchKeyValue(dds_iUserTrailEntIdx[client], "renderamt", "255");
	DispatchKeyValue(dds_iUserTrailEntIdx[client], "rendercolor", sTrail_ColorSet);
	DispatchKeyValue(dds_iUserTrailEntIdx[client], "rendermode", "5");

	// 엔티티 생성
	DispatchSpawn(dds_iUserTrailEntIdx[client]);

	// 엔티티 속성 설정
	SetEntPropFloat(dds_iUserTrailEntIdx[client], Prop_Send, "m_flTextureRes", 0.05);
	SetEntPropFloat(dds_iUserTrailEntIdx[client], Prop_Data, "m_flSkyboxScale", 1.0); // 클라이언트쪽에서 지정해도 상관없음

	// 클라이언트에게 부착
	SetVariantString("!activator"); // https://developer.valvesoftware.com/wiki/Targetname
	AcceptEntityInput(dds_iUserTrailEntIdx[client], "SetParent", client);
}

/**
 * Entity :: 트레일 제거
 *
 * @param client				클라이언트 인덱스
 */
public void Entity_RemoveTrail(int client)
{
	if (IsValidEntity(dds_iUserTrailEntIdx[client]) && (dds_iUserTrailEntIdx[client] != -1))
	{
		AcceptEntityInput(dds_iUserTrailEntIdx[client], "Kill");
	}
	dds_iUserTrailEntIdx[client] = -1;
}


/*******************************************************
 * C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 이벤트 :: 각종 조건으로 라운드가 시작될 경우
 *
 * @param event					이벤트 핸들
 * @param name					이벤트 이름 문자열
 * @param dontbroadcast			이벤트 브로드캐스트 차단 여부
 */
public Action Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// 플러그인이 꺼져 있을 때는 동작 안함
	if (!DDS_IsPluginOn())	return Plugin_Continue;

	// 게임이 식별되지 않은 경우에는 동작 안함
	if (!dds_bGameCheck)	return Plugin_Continue;

	for (int i = 0; i < MaxClients; i++)
	{
		// 서버는 통과
		if (i == 0)	continue;

		// 클라이언트가 게임 내에 없다면 통과
		if (!IsClientInGame(i))	return Plugin_Continue;

		// 클라이언트가 인증을 받지 못했다면 통과
		if (!IsClientAuthorized(i))	return Plugin_Continue;

		// 클라이언트가 살아있지 않다면 통과
		if (!IsPlayerAlive(i))	return Plugin_Continue;

		// 클라이언트가 봇이라면 통과
		if (IsFakeClient(i))	return Plugin_Continue;

		// 트레일 생성
		if (DDS_GetClientItemCategorySetting(i, DDS_ITEMCG_TRAIL_ID) && (DDS_GetClientAppliedItem(i, DDS_ITEMCG_TRAIL_ID) > 0)) {
			Entity_CreateTrail(i);
		}
	}

	return Plugin_Continue;
}

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

	// 클라이언트가 서버라면 통과
	if (client == 0)	return Plugin_Continue;

	// 트레일 생성
	if (DDS_GetClientItemCategorySetting(client, DDS_ITEMCG_TRAIL_ID) && (DDS_GetClientAppliedItem(client, DDS_ITEMCG_TRAIL_ID) > 0)) {
		Entity_CreateTrail(client);
	}

	return Plugin_Continue;
}

/**
 * 이벤트 :: 플레이어가 사살되었을 때
 *
 * @param event					이벤트 핸들
 * @param name					이벤트 이름 문자열
 * @param dontbroadcast			이벤트 브로드캐스트 차단 여부
 */
public Action Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// 플러그인이 꺼져 있을 때는 동작 안함
	if (!DDS_IsPluginOn())	return Plugin_Continue;

	// 게임이 식별되지 않은 경우에는 동작 안함
	if (!dds_bGameCheck)	return Plugin_Continue;

	// 이벤트 핸들을 통해 클라이언트 식별
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// 트레일 제거
	Entity_RemoveTrail(client);

	return Plugin_Continue;
}

/**
 * 이벤트 :: 플레이어가 팀을 변경했을 때
 *
 * @param event					이벤트 핸들
 * @param name					이벤트 이름 문자열
 * @param dontbroadcast			이벤트 브로드캐스트 차단 여부
 */
public Action Event_OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	// 플러그인이 꺼져 있을 때는 동작 안함
	if (!DDS_IsPluginOn())	return Plugin_Continue;

	// 게임이 식별되지 않은 경우에는 동작 안함
	if (!dds_bGameCheck)	return Plugin_Continue;

	// 이벤트 핸들을 통해 클라이언트 식별
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	//int afterteam = GetClientOfUserId(GetEventInt(event, "team"));

	// 트레일 제거
	Entity_RemoveTrail(client);

	return Plugin_Continue;
}