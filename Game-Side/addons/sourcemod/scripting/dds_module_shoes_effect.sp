/************************************************************************
 * Dynamic Dollar Shop - [Module] Shoes effect (Sourcemod)
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

#define DDS_ADD_NAME			"Dynamic Dollar Shop :: [Module] Shoes Effect"
#define DDS_ITEMCG_SE_ID		4

/*******************************************************
 * E N U M S
*******************************************************/
enum Model
{
	IDX,
	VALUE
};

/*******************************************************
 * V A R I A B L E S
*******************************************************/
// Convar 변수
ConVar dds_hCV_RING_MIN;
ConVar dds_hCV_RING_MAX;
ConVar dds_hCV_RING_SPEED;

// 게임 식별
char dds_sGameIdentity[32];
bool dds_bGameCheck;

// 모델 프리캐시
int dds_iEffectModel;
int dds_iModelPrecache[DDS_ENV_ITEM_MAX + 1][Model];

/*******************************************************
 * P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = DDS_ADD_NAME,
	author = DDS_ENV_CORE_AUTHOR,
	description = "This can allow clients to use Shoes Effect function.",
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
	// Convar 등록
	dds_hCV_RING_MIN = 		CreateConVar("dds_se_ring_min", 	"10.0", 		"이펙트 슈즈를 장착했을 때 나타나는 원의 최소 반지름을 적어주세요.", FCVAR_PLUGIN);
	dds_hCV_RING_MAX = 		CreateConVar("dds_se_ring_max", 	"150.0", 		"이펙트 슈즈를 장착했을 때 나타나는 원의 최대 반지름을 적어주세요.", FCVAR_PLUGIN);
	dds_hCV_RING_SPEED = 	CreateConVar("dds_se_ring_speed", 	"5", 			"이펙트 슈즈를 장착했을 때 나타나는 원의 움직임 속도를 적어주세요.", FCVAR_PLUGIN);

	// Event Hook 연결
	HookEvent("player_footstep", Event_OnPlayerFootstep);
}

/**
 * 설정이 로드되고 난 후
 */
public void OnConfigsExecuted()
{
	// 플러그인이 꺼져 있을 때는 동작 안함
	if (!DDS_IsPluginOn())	return;

	// 초기화
	Init_NidData();

	// 게임 식별
	GetGameFolderName(dds_sGameIdentity, sizeof(dds_sGameIdentity));

	// 게임 별 이벤트 후킹
	System_SetHookEvent(dds_sGameIdentity);

	// 필요 모델 프리캐시
	dds_iEffectModel = PrecacheModel("materials/sprites/steam1.vmt", true);
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
		// '이펙트 슈즈' 아이템 종류 생성
		DDS_CreateItemCategory(DDS_ITEMCG_SE_ID);
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
		if (StringToInt(sItem_Code) != DDS_ITEMCG_SE_ID)	continue;

		// 아이템 정보 인덱스 획득
		char sItem_Idx[8];
		DDS_GetItemInfo(i, ItemInfo_INDEX, sItem_Idx);
		dds_iModelPrecache[i][IDX] = StringToInt(sItem_Idx);

		// 아이템 정보 모델 획득
		char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
		DDS_GetItemInfo(i, ItemInfo_ENV, sGetEnv);

		// 환경변수에서 모델 정보 로드
		char sModelStr[128];
		SelectedStuffToString(sGetEnv, "ENV_DDS_INFO_ADRS", "||", ":", sModelStr, sizeof(sModelStr));

		// 등록된 모델이 있을 경우 프리캐시
		if (strlen(sModelStr) > 0)
			dds_iModelPrecache[i][VALUE] = PrecacheModel(sModelStr, true);
	}
}


/*******************************************************
 * G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 초기화 :: 서버 필요 데이터
 */
public void Init_NidData()
{
	for (int i = 0; i < DDS_ENV_ITEM_MAX; i++)
	{
		dds_iModelPrecache[i][IDX] = 0;
		dds_iModelPrecache[i][VALUE] = 0;
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
 * 이벤트 :: 플레이어 발자국 이벤트
 *
 * @param event					이벤트 핸들
 * @param name					이벤트 이름 문자열
 * @param dontbroadcast			이벤트 브로드캐스트 차단 여부
 */
public Action Event_OnPlayerFootstep(Event event, const char[] name, bool dontBroadcast)
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

	// 이펙트 슈즈 생성
	if (DDS_GetClientItemCategorySetting(client, DDS_ITEMCG_SE_ID) && (DDS_GetClientAppliedItem(client, DDS_ITEMCG_SE_ID) > 0))
	{
		// 클라이언트의 위치를 구한 후 위치 조정
		float fClient_Pos[3];
		GetClientAbsOrigin(client, fClient_Pos);
		fClient_Pos[2] += 2.0;

		// 환경변수 로드
		char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
		DDS_GetItemInfo(DDS_GetClientAppliedItem(client, DDS_ITEMCG_SE_ID), ItemInfo_ENV, sGetEnv);

		// 환경변수에서 색깔 정보 로드
		char sColorStr[32];
		SelectedStuffToString(sGetEnv, "ENV_DDS_INFO_COLOR", "||", ":", sColorStr, sizeof(sColorStr));

		// 문자열로 된 색상 정보를 int형으로 변환
		int iSetColor[4];
		char sExpStr[4][8];
		ExplodeString(sColorStr, " ", sExpStr, sizeof(sExpStr), sizeof(sExpStr[]));
		for (int i = 0; i < 4; i++) {
			iSetColor[i] = StringToInt(sExpStr[i]);
		}

		// 출력
		TE_SetupBeamRingPoint(fClient_Pos, dds_hCV_RING_MAX.FloatValue, dds_hCV_RING_MIN.FloatValue, dds_iModelPrecache[DDS_GetClientAppliedItem(client, DDS_ITEMCG_SE_ID)][VALUE], dds_iEffectModel, 0, 15, 0.5, 5.0, 0.0, iSetColor, dds_hCV_RING_SPEED.IntValue, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(fClient_Pos, dds_hCV_RING_MIN.FloatValue, dds_hCV_RING_MAX.FloatValue, dds_iModelPrecache[DDS_GetClientAppliedItem(client, DDS_ITEMCG_SE_ID)][VALUE], dds_iEffectModel, 0, 10, 0.5, 10.0, 1.5, iSetColor, dds_hCV_RING_SPEED.IntValue, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(fClient_Pos, dds_hCV_RING_MAX.FloatValue, dds_hCV_RING_MIN.FloatValue, dds_iModelPrecache[DDS_GetClientAppliedItem(client, DDS_ITEMCG_SE_ID)][VALUE], dds_iEffectModel, 0, 10, 0.5, 10.0, 1.5, iSetColor, dds_hCV_RING_SPEED.IntValue, 0);
		TE_SendToAll();
	}

	return Plugin_Continue;
}