/************************************************************************
 * Dynamic Dollar Shop - CORE (Sourcemod)
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
#include <dds>

// ** 등급을 위한 연동 플러그인 **
#include "ucm/ucm_env_api.inc"

/*******************************************************
 * E N U M S
*******************************************************/
enum Apply
{
	DBIDX,
	ITEMIDX
}

enum SettingItem
{
	CATECODE,
	bool:VALUE
}

enum Item
{
	INDEX,
	String:NAME[DDS_ENV_VAR_GLONAME_SIZE],
	CATECODE,
	MONEY,
	HAVTIME,
	String:ENV[DDS_ENV_VAR_ENV_SIZE]
}

enum ItemCG
{
	String:NAME[DDS_ENV_VAR_GLONAME_SIZE],
	CODE,
	String:ENV[DDS_ENV_VAR_ENV_SIZE],
	bool:STATUS
}

enum EnvList
{
	INDEX,
	String:CATEGORY[20],
	String:NAME[64],
	String:VALUE[128]
}

/*******************************************************
 * V A R I A B L E S
*******************************************************/
// SQL 데이터베이스
Database dds_hSQLDatabase = null;
bool dds_bSQLStatus;

// 유저 SQL 확인
bool dds_bUserSQLStatus[MAXPLAYERS + 1];

// 로그 파일
char dds_sPluginLogFile[256];

// Convar 변수
ConVar dds_hCV_PluginSwitch;
ConVar dds_hCV_SwitchLogData;
ConVar dds_hCV_SwitchDisplayChat;
ConVar dds_hCV_SwitchQuickCmdN;
ConVar dds_hCV_SwitchQuickCmdF1;
ConVar dds_hCV_SwitchQuickCmdF2;
ConVar dds_hCV_SwitchGiftMoney;
ConVar dds_hCV_SwitchGiftItem;
ConVar dds_hCV_SwitchResellItem;
ConVar dds_hCV_ItemMoneyMultiply;
ConVar dds_hCV_ItemResellRatio;
ConVar dds_hCV_SecureUserMin;

// 포워드
Handle dds_hOnLoadSQLItemCategory;
Handle dds_hOnLoadSQLItem;
Handle dds_hOnDataProcess;
Handle dds_hOnLogProcessPre;
Handle dds_hOnLogProcessPost;

// 팀 채팅
bool dds_bTeamChat[MAXPLAYERS + 1];

// 아이템
int dds_iItemCount;
int dds_eItemList[DDS_ENV_ITEM_MAX + 1][Item];

// 아이템 종류
int dds_iItemCategoryCount;
int dds_eItemCategoryList[DDS_ENV_ITEMCG_MAX + 1][ItemCG];

// ENV 목록
int dds_iEnvCount;
int dds_eEnvList[DDS_ENV_USEENV_MAX][EnvList];

// 유저 소유
int dds_iUserMoney[MAXPLAYERS + 1];
int dds_iUserAppliedItem[MAXPLAYERS + 1][DDS_ENV_ITEMCG_MAX + 1][Apply];
bool dds_eUserItemCGStatus[MAXPLAYERS + 1][DDS_ENV_ITEMCG_MAX + 1][SettingItem];
char dds_sUserRefData[MAXPLAYERS + 1][256];

/*******************************************************
 * P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = DDS_ENV_CORE_NAME,
	author = DDS_ENV_CORE_AUTHOR,
	description = "This can allow clients to use shops that supports several items with virtual dollars.",
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
	// Version 등록
	CreateConVar("sm_dynamicdollarshop_version", DDS_ENV_CORE_VERSION, "Made By. Eakgnarok", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// Convar 등록
	dds_hCV_PluginSwitch = 			CreateConVar("dds_switch_plugin", 			"1", 		"본 플러그인의 작동 여부입니다. 작동을 원하지 않으시다면 0을, 원하신다면 1을 써주세요.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	dds_hCV_SwitchLogData = 		CreateConVar("dds_switch_log_data", 		"1", 		"데이터 로그 작성 여부입니다. 활성화를 권장합니다. 작동을 원하지 않으시다면 0을, 원하신다면 1을 써주세요.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	dds_hCV_SwitchDisplayChat = 	CreateConVar("dds_switch_chat", 			"0", 		"채팅을 할 때 메세지 출력 여부입니다. 작동을 원하지 않으시다면 0을, 원하신다면 1을 써주세요.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	dds_hCV_SwitchQuickCmdN = 		CreateConVar("dds_switch_quick_n", 			"1", 		"N키의 단축키 설정입니다. 0 - 작동 해제 / 1 - 메인 메뉴 / 2 - 인벤토리 메뉴", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	dds_hCV_SwitchQuickCmdF1 = 		CreateConVar("dds_switch_quick_f1", 		"0", 		"F1키의 단축키 설정입니다. 0 - 작동 해제 / 1 - 메인 메뉴 / 2 - 인벤토리 메뉴", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	dds_hCV_SwitchQuickCmdF2 = 		CreateConVar("dds_switch_quick_f2", 		"0", 		"F2키의 단축키 설정입니다. 0 - 작동 해제 / 1 - 메인 메뉴 / 2 - 인벤토리 메뉴", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	dds_hCV_SwitchGiftMoney = 		CreateConVar("dds_switch_gift_money", 		"1", 		"금액 선물 기능을 기본적으로 허용할 것인지의 여부입니다. 작동을 원하지 않으시다면 0을, 원하신다면 1을 써주세요.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	dds_hCV_SwitchGiftItem = 		CreateConVar("dds_switch_gift_item", 		"1", 		"아이템 선물 기능을 기본적으로 허용할 것인지의 여부입니다. 작동을 원하지 않으시다면 0을, 원하신다면 1을 써주세요.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	dds_hCV_SwitchResellItem = 		CreateConVar("dds_switch_item_resell", 		"0", 		"아이템 되팔기 기능을 기본적으로 허용할 것인지의 여부입니다. 작동을 원하지 않으시다면 0을, 원하신다면 1을 써주세요.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	dds_hCV_ItemMoneyMultiply = 	CreateConVar("dds_item_money_multiply", 	"1.0", 		"모든 아이템을 각 아이템 금액의 몇 배의 비율로 설정할 것인지 적어주세요. 처음 아이템 목록을 로드할 때 반영됩니다.", FCVAR_PLUGIN);
	dds_hCV_ItemResellRatio = 		CreateConVar("dds_item_resell_ratio", 		"0.2", 		"아이템 되팔기 기능을 사용할 때 해당 아이템 금액의 어느 정도의 비율로 설정할 것인지 적어주세요.", FCVAR_PLUGIN);
	dds_hCV_SecureUserMin = 		CreateConVar("dds_get_secure_user_min", 	"4", 		"작업 방지를 위한 최소한의 인원을 설정하는 곳입니다.", FCVAR_PLUGIN);

	// 플러그인 로그 작성 등록
	BuildPath(Path_SM, dds_sPluginLogFile, sizeof(dds_sPluginLogFile), "logs/dynamicdollarshop.log");

	// 번역 로드
	LoadTranslations("dynamicdollarshop.phrases");

	// 콘솔 커맨드 연결
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_TeamSay);
}

/**
 * API 등록
 */
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// 라이브러리 등록
	RegPluginLibrary("dds_core");

	// Native 함수 등록
	CreateNative("DDS_IsPluginOn", Native_DDS_IsPluginOn);
	CreateNative("DDS_GetServerSQLStatus", Native_DDS_GetServerSQLStatus);
	CreateNative("DDS_GetClientSQLStatus", Native_DDS_GetClientSQLStatus);
	CreateNative("DDS_CreateItemCategory", Native_DDS_CreateItemCategory);
	CreateNative("DDS_GetItemCategoryStatus", Native_DDS_GetItemCategoryStatus);
	CreateNative("DDS_GetItemInfo", Native_DDS_GetItemInfo);
	CreateNative("DDS_GetItemCount", Native_DDS_GetItemCount);
	CreateNative("DDS_GetItemCategoryInfo", Native_DDS_GetItemCategoryInfo);
	CreateNative("DDS_GetItemCategoryCount", Native_DDS_GetItemCategoryCount);
	CreateNative("DDS_GetClientMoney", Native_DDS_GetClientMoney);
	CreateNative("DDS_SetClientMoney", Native_DDS_SetClientMoney);
	CreateNative("DDS_GetClientAppliedDB", Native_DDS_GetClientAppliedDB);
	CreateNative("DDS_GetClientAppliedItem", Native_DDS_GetClientAppliedItem);
	CreateNative("DDS_GetClientItemCategorySetting", Native_DDS_GetClientItemCategorySetting);
	CreateNative("DDS_GetClientRefData", Native_DDS_GetClientRefData);
	CreateNative("DDS_UseDataProcess", Native_DDS_UseDataProcess);
	CreateNative("DDS_GetSecureUserMin", Native_DDS_GetSecureUserMin);

	// 포워드 함수 등록
	dds_hOnLoadSQLItemCategory = CreateGlobalForward("DDS_OnLoadSQLItemCategory", ET_Ignore);
	dds_hOnLoadSQLItem = CreateGlobalForward("DDS_OnLoadSQLItem", ET_Ignore);
	dds_hOnDataProcess = CreateGlobalForward("DDS_OnDataProcess", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	dds_hOnLogProcessPre = CreateGlobalForward("DDS_OnLogProcessPre", ET_Hook, Param_String, Param_String, Param_String, Param_Cell, Param_String);
	dds_hOnLogProcessPost = CreateGlobalForward("DDS_OnLogProcessPost", ET_Ignore, Param_String, Param_String, Param_String, Param_Cell, Param_String);

	return APLRes_Success;
}

/**
 * 설정이 로드되고 난 후
 */
public void OnConfigsExecuted()
{
	// 플러그인이 꺼져 있을 때는 동작 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	/** SQL 데이터베이스 연결 **/
	Database.Connect(SQL_GetDatabase, "dds");

	/** 단축키 연결 **/
	// N 키
	if (dds_hCV_SwitchQuickCmdN.IntValue == 1)	RegConsoleCmd("nightvision", Menu_Main);
	else if (dds_hCV_SwitchQuickCmdN.IntValue == 2)	RegConsoleCmd("nightvision", Menu_Inven);
	// F1키
	if (dds_hCV_SwitchQuickCmdF1.IntValue == 1)	RegConsoleCmd("autobuy", Menu_Main);
	else if (dds_hCV_SwitchQuickCmdF1.IntValue == 2)	RegConsoleCmd("autobuy", Menu_Inven);
	// F2키
	if (dds_hCV_SwitchQuickCmdF2.IntValue == 1)	RegConsoleCmd("rebuy", Menu_Main);
	else if (dds_hCV_SwitchQuickCmdF2.IntValue == 2)	RegConsoleCmd("rebuy", Menu_Inven);
}

/**
 * 맵이 종료된 후
 */
public void OnMapEnd()
{
	// SQL 데이터베이스 핸들 초기화
	if (dds_hSQLDatabase != null)
	{
		delete dds_hSQLDatabase;
	}
	dds_hSQLDatabase = null;

	// SQL 상태 초기화
	dds_bSQLStatus = false;
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
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	// 봇은 제외
	if (IsFakeClient(client))	return;

	// 유저 데이터 초기화
	Init_UserData(client, 2);

	// 유저 정보 확인
	CreateTimer(0.4, SQL_Timer_UserLoad, client);
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

	// 로그 작성
	Log_Data(client, "game-disconnect", "");

	// 클라이언트 고유 번호 추출
	char sUsrAuthId[20];
	GetClientAuthId(client, AuthId_SteamID64, sUsrAuthId, sizeof(sUsrAuthId));

	// 클라이언트 이름 추출 후 필터링
	char sUsrName[32];
	GetClientName(client, sUsrName, sizeof(sUsrName));
	SetPreventSQLInject(sUsrName, sUsrName, sizeof(sUsrName));

	// 오류 검출 생성
	ArrayList hMakeErr = CreateArray(8);
	hMakeErr.Push(client);
	hMakeErr.Push(1013);

	// 유저 정보 갱신
	char sSendQuery[256];

	Format(sSendQuery, sizeof(sSendQuery), "UPDATE `dds_user_profile` SET `nickname` = '%s', `ingame` = '0' WHERE `authid` = '%s'", sUsrName, sUsrAuthId);
	dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErr);

	// 유저 데이터 초기화
	Init_UserData(client, 2);

	#if defined _DEBUG_
	DDS_PrintToServer(":: DEBUG :: User Disconnect - Update (client: %N)", client);
	#endif
}

/**
 * 게임 프레임
 */
/*
public void OnGameFrame()
{
	// 플러그인이 꺼져 있을 때는 동작 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	for (int i = 1; i < MaxClients; i++)
	{
		// 게임에 없으면 통과
		if (!IsClientInGame(client))	continue;

		// 봇 제외
		if (IsFakeClient(client))	continue;

		for (int j = 0; j <= dds_iItemCount; j++)
		{
			// 0번 제외
			if (j == 0)	continue;

			if (dds_eItemList[j][HAVTIME] <= 0)	continue;

			int iBuyDate = StringToInt(sBuyDate); // 데이터베이스로? 변수로? 다른 케이스는?
			int iItmTime = dds_eItemList[j][HAVTIME];

			// 시간이 아직 남았다면 통과
			if (GetTime() <= (iBuyDate + iItmTime))	continue;

			// 아이템 삭제
		}
	}
}
*/

/*******************************************************
 * G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 초기화 :: 서버 데이터
 */
public void Init_ServerData()
{
	/** 아이템 **/
	// 아이템 갯수
	dds_iItemCount = 0;
	// 아이템 목록
	for (int i = 0; i <= DDS_ENV_ITEM_MAX; i++)
	{
		dds_eItemList[i][INDEX] = 0;
		Format(dds_eItemList[i][NAME], DDS_ENV_VAR_GLONAME_SIZE, "");
		dds_eItemList[i][CATECODE] = 0;
		dds_eItemList[i][MONEY] = 0;
		dds_eItemList[i][HAVTIME] = 0;
		Format(dds_eItemList[i][ENV], DDS_ENV_VAR_ENV_SIZE, "");
	}
	// 아이템 0번 'X' 설정
	Format(dds_eItemList[0][NAME], DDS_ENV_VAR_GLONAME_SIZE, "EN:X||KO:X");

	/** 아이템 종류 **/
	// 아이템 종류 갯수
	dds_iItemCategoryCount = 0;
	// 아이템 종류 목록
	for (int i = 0; i <= DDS_ENV_ITEMCG_MAX; i++)
	{
		Format(dds_eItemCategoryList[i][NAME], DDS_ENV_VAR_GLONAME_SIZE, "");
		dds_eItemCategoryList[i][CODE] = 0;
		Format(dds_eItemCategoryList[i][ENV], DDS_ENV_VAR_ENV_SIZE, "");
		dds_eItemCategoryList[i][STATUS] = false;
	}
	// 아이템 종류 0번 '전체' 설정
	Format(dds_eItemCategoryList[0][NAME], DDS_ENV_VAR_GLONAME_SIZE, "EN:Total||KO:전체");

	/** ENV **/
	// ENV 갯수
	dds_iEnvCount = 0;
	// ENV 목록
	for (int i = 0; i < DDS_ENV_USEENV_MAX; i++)
	{
		dds_eEnvList[i][INDEX] = 0;
		Format(dds_eEnvList[i][CATEGORY], 20, "");
		Format(dds_eEnvList[i][NAME], 64, "");
		Format(dds_eEnvList[i][VALUE], 128, "");
	}

	#if defined _DEBUG_
	DDS_PrintToServer(":: DEBUG :: Server Data Initialization Complete");
	#endif
}

/**
 * 초기화 :: 유저 데이터
 *
 * @param client			클라이언트 인덱스
 * @param mode				처리 모드(1 - 전체 초기화, 2 - 특정 클라이언트 초기화)
 */
public void Init_UserData(int client, int mode)
{
	switch (mode)
	{
		case 1:
		{
			/** 전체 초기화 **/
			for (int i = 0; i <= MAXPLAYERS; i++)
			{
				// SQL 데이터베이스 유저 상태
				dds_bUserSQLStatus[i] = false;

				// 팀 채팅
				dds_bTeamChat[i] = false;

				// 금액
				dds_iUserMoney[i] = 0;

				// 아이템 관련
				for (int k = 0; k <= DDS_ENV_ITEMCG_MAX; k++)
				{
					// 아이템 장착 상태
					dds_iUserAppliedItem[i][k][DBIDX] = 0;
					dds_iUserAppliedItem[i][k][ITEMIDX] = 0;

					// 아이템 종류 활성 상태
					dds_eUserItemCGStatus[i][k][CATECODE] = 0;
					dds_eUserItemCGStatus[i][k][VALUE] = false;
				}

				// 참고 데이터
				Format(dds_sUserRefData[i], 256, "");
			}
		}
		case 2:
		{
			/** 특정 클라이언트 초기화 **/
			// SQL 데이터베이스 유저 상태
			dds_bUserSQLStatus[client] = false;

			// 팀 채팅
			dds_bTeamChat[client] = false;

			// 금액
			dds_iUserMoney[client] = 0;

			// 아이템 관련
			for (int i = 0; i <= DDS_ENV_ITEMCG_MAX; i++)
			{
				// 아이템 장착 상태
				dds_iUserAppliedItem[client][i][DBIDX] = 0;
				dds_iUserAppliedItem[client][i][ITEMIDX] = 0;

				// 아이템 종류 활성 상태
				dds_eUserItemCGStatus[client][i][CATECODE] = 0;
				dds_eUserItemCGStatus[client][i][VALUE] = false;
			}

			// 참고 데이터
			Format(dds_sUserRefData[client], 256, "");
		}
	}

	#if defined _DEBUG_
	DDS_PrintToServer(":: DEBUG :: User Data Initialization Complete (client: %N, mode: %d)", client, mode);
	#endif
}

/**
 * System :: 연결 아이템 종류 플러그인 검증
 *
 * @param catecode			아이템 종류 코드
 */
public void System_ValidateItemCG(int catecode)
{
	for (int i = 0; i <= dds_iItemCategoryCount; i++)
	{
		// '전체'는 통과
		if (i == 0)	continue;

		// 이미 로드된 것은 따질 필요 없음
		if (dds_eItemCategoryList[i][STATUS])	continue;

		if (dds_eItemCategoryList[i][CODE] == catecode)
		{
			dds_eItemCategoryList[i][STATUS] = true;
			DDS_PrintToServer("Item Category %d (IDX %d) is now registered.", catecode, i);
			break;
		}
	}
}

/**
 * System :: 데이터 처리 시스템
 *
 * @param client			클라이언트 인덱스
 * @param process			행동 구별
 * @param data				추가 파라메터
 */
public void System_DataProcess(int client, const char[] process, const char[] data)
{
	/******************************************************************************
	 * A T T E N S I O N  / 주의
	 ******************************************************************************
	 *
	 * 중요 부분이니 함부로 건들지 말 것
	 * 데이터가지고 놀기 때문에 잘못하면 엄청나게 잘못될 수 있으므로 주의
	 *
	 * 데이터를 처리할 때는 행동별로 다양하고 동적인게 많으므로 배열로
	 * 처리하는 것보다는 문자열로 값을 하나하나 항목별로 전해주어
	 * 원하는 항목을 잘라 처리하는게 좋아 보여 'data' 파라메터를 만들어 
	 * 처리해야 하는 항목만 전달할 수 있도록 변경
	 * 
	*******************************************************************************/
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	// SQL 데이터베이스가 활성화되어 있지 않다면 작동 안함
	if (!dds_bSQLStatus)
	{
		DDS_PrintToChat(client, "%t", "error sqlstatus server");
		return;
	}

	// 유저의 SQL 데이터베이스 상태가 활성화되어 있지 않다면 작동 안함
	if (!dds_bUserSQLStatus[client])
	{
		DDS_PrintToChat(client, "%t", "error sqlstatus user");
		return;
	}

	/***** 클라이언트 정보 추출 *****/
	// 클라이언트의 이름 파악
	char sClient_Name[32];
	GetClientName(client, sClient_Name, sizeof(sClient_Name));

	// 클라이언트의 고유 번호 파악
	char sClient_AuthId[20];
	GetClientAuthId(client, AuthId_SteamID64, sClient_AuthId, sizeof(sClient_AuthId));

	/***** 준비 *****/
	// 쿼리 구문 준비
	char sSendQuery[512];

	// 버퍼 준비
	char sBuffer[128];

	// 로그 준비
	char sMakeLogParam[256];

	// enum 준비
	DataProcess iSimpleProc;

	/******************************************************************************
	 * -----------------------------------
	 * 'process' 파라메터 종류 별 나열
	 * -----------------------------------
	 *
	 * 'buy' - 아이템 구매
	 * 'inven-use' - 인벤토리에서의 아이템 사용하기
	 * 'inven-resell' - 인벤토리에서의 아이템 되팔기
	 * 'inven-gift' - 인벤토리에서의 아이템 선물하기
	 * 'inven-drop' - 인벤토리에서의 아이템 버리기
	 * 'curitem-cancel' - 내 장착 아이템에서의 장착 해제
	 * 'curitem-use' - 내 장착 아이템에서의 장착('inven-use'와 함께 사용)
	 *
	 * 'money-up' - 금액 증가
	 * 'money-down' - 금액 감소
	 * 'money-gift' - 금액 선물
	 * 'money-give' - 금액 주기
	 * 'money-takeaway' - 금액 뺏기
	 *
	 * 'item-gift' - 아이템 선물('inven-gift'와 함께 사용)
	 * 'item-give' - 아이템 주기
	 * 'item-takeaway' - 아이템 뺏기
	 *
	 * 'user-refdata' - 클라이언트 기타 참고 데이터 설정
	 *
	*******************************************************************************/
	if (StrEqual(process, "buy", false))
	{
		/*************************************************
		 *
		 * [아이템 구매]
		 *
		**************************************************/
		iSimpleProc = DataProc_BUY;

		/*************************
		 * 전달 파라메터 구분 준비
		 *
		 * [0] - 아이템 번호
		**************************/
		int iItemIdx = StringToInt(data);

		// 아이템 금액 확인
		int iItemMny = dds_eItemList[Find_GetItemListIndex(iItemIdx)][MONEY];

		/*************************
		 * 조건 및 환경 변수 확인
		**************************/
		/*** 환경 변수 준비 ***/
		char sGetEnv[DDS_ENV_VAR_ENV_SIZE];

		/** 환경 변수 확인(아이템 종류단) **/
		/* 접근 관련 */
		SelectedStuffToString(dds_eItemCategoryList[Find_GetItemCGListIndex(dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE])][ENV], "ENV_DDS_LIMIT_BUY_CLASS", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (StrEqual(sGetEnv, "none", false)) // 허용된 것이 아무것도 없음
		{
			DDS_PrintToChat(client, "%t", "error access");
			return;
		}
		else if (!StrEqual(sGetEnv, "all", false)) // 코드로 구분되어 졌을 경우
		{
			// 빈칸 모두 제거
			ReplaceString(sGetEnv, sizeof(sGetEnv), " ", "", false);

			// 허용 등급 추출
			char[][] sTempClStr = new char[UCM_GetClassCount() + 1][8];
			ExplodeString(sGetEnv, ",", sTempClStr, UCM_GetClassCount() + 1, 8);

			// 갯수 파악
			int count;

			// 검증
			for (int i = 0; i <= UCM_GetClassCount(); i++)
			{
				// 0은 생략
				if (i == 0)	continue;

				// 맞는 것이 없으면 패스
				if (StringToInt(sTempClStr[i]) != UCM_GetClientClass(client))	continue;

				count++;
			}
			
			// 없으면 차단
			if (count == 0)
			{
				DDS_PrintToChat(client, "%t", "error access");
				return;
			}
		}

		/** 환경 변수 확인(아이템 단) **/
		/* 접근 관련 */
		SelectedStuffToString(dds_eItemList[Find_GetItemListIndex(iItemIdx)][ENV], "ENV_DDS_LIMIT_BUY_CLASS", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (StrEqual(sGetEnv, "none", false)) // 허용된 것이 아무것도 없음
		{
			DDS_PrintToChat(client, "%t", "error access");
			return;
		}
		else if (!StrEqual(sGetEnv, "all", false)) // 코드로 구분되어 졌을 경우
		{
			// 빈칸 모두 제거
			ReplaceString(sGetEnv, sizeof(sGetEnv), " ", "", false);

			// 허용 등급 추출
			char[][] sTempClStr = new char[UCM_GetClassCount() + 1][8];
			ExplodeString(sGetEnv, ",", sTempClStr, UCM_GetClassCount() + 1, 8);

			// 갯수 파악
			int count;

			// 검증
			for (int i = 0; i <= UCM_GetClassCount(); i++)
			{
				// 0은 생략
				if (i == 0)	continue;

				// 맞는 것이 없으면 패스
				if (StringToInt(sTempClStr[i]) != UCM_GetClientClass(client))	continue;

				count++;
			}
			
			// 없으면 차단
			if (count == 0)
			{
				DDS_PrintToChat(client, "%t", "error access");
				return;
			}
		}

		/** 환경 변수 확인(유저단) **/
		// 금액 사용 관련
		UCM_GetClassInfo(UCM_GetClientClass(client), ClassInfo_Env, sGetEnv);
		SelectedStuffToString(sGetEnv, "ENV_DDS_USE_MONEY", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (!StringToInt(sGetEnv))
			iItemMny = 0;

		/** 조건 확인 **/
		// 돈 부족
		if ((dds_iUserMoney[client] - iItemMny) < 0)
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "error money nid", (iItemMny - dds_iUserMoney[client]), "global money");
			DDS_PrintToChat(client, sBuffer);
			return;
		}

		/*************************
		 * 아이템 정보 삽입
		**************************/
		// 오류 검출 생성
		ArrayList hMakeErrI = CreateArray(8);
		hMakeErrI.Push(client);
		hMakeErrI.Push(2010);

		// 쿼리 전송
		Format(sSendQuery, sizeof(sSendQuery), 
			"INSERT INTO `dds_user_item` (`idx`, `authid`, `ilidx`, `aplied`, `buydate`) VALUES (NULL, '%s', '%d', '0', '%d')", 
			sClient_AuthId, iItemIdx, GetTime());
		dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrI);

		/*************************
		 * 금액 정보 갱신
		**************************/
		char sSendParam[32];
		Format(sSendParam, sizeof(sSendParam), "%d||%d", 2011, iItemMny);
		System_DataProcess(client, "money-down", sSendParam);

		/*************************
		 * 화면 출력
		**************************/
		// 클라이언트 국가에 따른 아이템과 종류 이름 추출
		char sCGName[40];
		char sItemName[32];
		SelectedGeoNameToString(client, dds_eItemCategoryList[Find_GetItemCGListIndex(dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE])][NAME], sCGName, sizeof(sCGName));
		SelectedGeoNameToString(client, dds_eItemList[Find_GetItemListIndex(iItemIdx)][NAME], sItemName, sizeof(sItemName));

		Format(sBuffer, sizeof(sBuffer), "%t", "system user buy", sCGName, sItemName, "global item");
		DDS_PrintToChat(client, sBuffer);

		/*************************
		 * 로그 작성
		**************************/
		Format(sMakeLogParam, sizeof(sMakeLogParam), "%s||%s||%d||%d", sCGName, sItemName, iItemIdx, iItemMny);
		Log_Data(client, "item-buy", sMakeLogParam);
	}
	else if (StrEqual(process, "inven-use", false) || StrEqual(process, "curitem-use", false))
	{
		/*************************************************
		 *
		 * [인벤토리에서의 아이템 사용하기]
		 *
		**************************************************/
		if (StrEqual(process, "inven-use", false))
			iSimpleProc = DataProc_USE;
		else if (StrEqual(process, "curitem-use", false))
			iSimpleProc = DataProc_CURUSE;

		/*************************
		 * 전달 파라메터 구분
		 *
		 * [0] - 데이터베이스 번호
		 * [1] - 아이템 번호
		**************************/
		char sTempStr[2][16];
		ExplodeString(data, "||", sTempStr, sizeof(sTempStr), sizeof(sTempStr[]));

		int iDBIdx = StringToInt(sTempStr[0]);
		int iItemIdx = StringToInt(sTempStr[1]);

		/*************************
		 * 조건 및 환경 변수 확인
		**************************/
		/*** 환경 변수 준비 ***/
		char sGetEnv[DDS_ENV_VAR_ENV_SIZE];

		/** 환경 변수 확인(아이템 종류단) **/
		/* 접근 관련 */
		SelectedStuffToString(dds_eItemCategoryList[Find_GetItemCGListIndex(dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE])][ENV], "ENV_DDS_LIMIT_USE_CLASS", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (StrEqual(sGetEnv, "none", false)) // 허용된 것이 아무것도 없음
		{
			DDS_PrintToChat(client, "%t", "error access");
			return;
		}
		else if (!StrEqual(sGetEnv, "all", false)) // 코드로 구분되어 졌을 경우
		{
			// 빈칸 모두 제거
			ReplaceString(sGetEnv, sizeof(sGetEnv), " ", "", false);

			// 허용 등급 추출
			char[][] sTempClStr = new char[UCM_GetClassCount() + 1][8];
			ExplodeString(sGetEnv, ",", sTempClStr, UCM_GetClassCount() + 1, 8);

			// 갯수 파악
			int count;

			// 검증
			for (int i = 0; i <= UCM_GetClassCount(); i++)
			{
				// 0은 생략
				if (i == 0)	continue;

				// 맞는 것이 없으면 패스
				if (StringToInt(sTempClStr[i]) != UCM_GetClientClass(client))	continue;

				count++;
			}
			
			// 없으면 차단
			if (count == 0)
			{
				DDS_PrintToChat(client, "%t", "error access");
				return;
			}
		}

		/** 환경 변수 확인(아이템 단) **/
		/* 접근 관련 */
		SelectedStuffToString(dds_eItemList[Find_GetItemListIndex(iItemIdx)][ENV], "ENV_DDS_LIMIT_USE_CLASS", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (StrEqual(sGetEnv, "none", false)) // 허용된 것이 아무것도 없음
		{
			DDS_PrintToChat(client, "%t", "error access");
			return;
		}
		else if (!StrEqual(sGetEnv, "all", false)) // 코드로 구분되어 졌을 경우
		{
			// 빈칸 모두 제거
			ReplaceString(sGetEnv, sizeof(sGetEnv), " ", "", false);

			// 허용 등급 추출
			char[][] sTempClStr = new char[UCM_GetClassCount() + 1][8];
			ExplodeString(sGetEnv, ",", sTempClStr, UCM_GetClassCount() + 1, 8);

			// 갯수 파악
			int count;

			// 검증
			for (int i = 0; i <= UCM_GetClassCount(); i++)
			{
				// 0은 생략
				if (i == 0)	continue;

				// 맞는 것이 없으면 패스
				if (StringToInt(sTempClStr[i]) != UCM_GetClientClass(client))	continue;

				count++;
			}
			
			// 없으면 차단
			if (count == 0)
			{
				DDS_PrintToChat(client, "%t", "error access");
				return;
			}
		}

		/*************************
		 * 기존 아이템 정보 갱신
		**************************/
		int iPrevItemIdx;
		// 기존에 장착한 아이템이 있으면 장착 해제 처리
		if (dds_iUserAppliedItem[client][dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE]][ITEMIDX] > 0)
		{
			// 오류 검출 생성
			ArrayList hMakeErrIf = CreateArray(8);
			hMakeErrIf.Push(client);
			hMakeErrIf.Push(2012);

			// 쿼리 전송
			Format(sSendQuery, sizeof(sSendQuery), 
				"UPDATE `dds_user_item` SET `aplied` = '0' WHERE `idx` = '%d' and `authid` = '%s' and `ilidx` = '%d'", 
				dds_iUserAppliedItem[client][dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE]][DBIDX], sClient_AuthId, dds_iUserAppliedItem[client][dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE]][ITEMIDX]);
			dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrIf);

			// 초기화
			iPrevItemIdx = dds_iUserAppliedItem[client][dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE]][ITEMIDX];
			dds_iUserAppliedItem[client][dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE]][DBIDX] = 0;
			dds_iUserAppliedItem[client][dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE]][ITEMIDX] = 0;
		}

		/*************************
		 * 대상 아이템 정보 갱신
		**************************/
		// 오류 검출 생성
		ArrayList hMakeErrIt = CreateArray(8);
		hMakeErrIt.Push(client);
		hMakeErrIt.Push(2013);

		// 쿼리 전송
		Format(sSendQuery, sizeof(sSendQuery), 
			"UPDATE `dds_user_item` SET `aplied` = '1' WHERE `idx` = '%d' and `authid` = '%s' and `ilidx` = '%d'", 
			iDBIdx, sClient_AuthId, iItemIdx);
		dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrIt);

		// 정보 갱신
		dds_iUserAppliedItem[client][dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE]][DBIDX] = iDBIdx;
		dds_iUserAppliedItem[client][dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE]][ITEMIDX] = iItemIdx;

		/*************************
		 * 화면 출력
		**************************/
		// 클라이언트 국가에 따른 아이템과 종류 이름 추출
		char sCGName[40];
		char sItemName[32];

		// 기존 아이템 출력
		if (iPrevItemIdx > 0)
		{
			SelectedGeoNameToString(client, dds_eItemCategoryList[Find_GetItemCGListIndex(dds_eItemList[Find_GetItemListIndex(iPrevItemIdx)][CATECODE])][NAME], sCGName, sizeof(sCGName));
			SelectedGeoNameToString(client, dds_eItemList[Find_GetItemListIndex(iPrevItemIdx)][NAME], sItemName, sizeof(sItemName));

			Format(sBuffer, sizeof(sBuffer), "%t", "system user inven use prev", sCGName, sItemName, "global item");
			DDS_PrintToChat(client, sBuffer);

			// 로그 출력
			Format(sMakeLogParam, sizeof(sMakeLogParam), "%s||%s||%d", sCGName, sItemName, iPrevItemIdx);
			Log_Data(client, "item-cancel", sMakeLogParam);
		}

		// 대상 아이템 출력
		SelectedGeoNameToString(client, dds_eItemCategoryList[Find_GetItemCGListIndex(dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE])][NAME], sCGName, sizeof(sCGName));
		SelectedGeoNameToString(client, dds_eItemList[Find_GetItemListIndex(iItemIdx)][NAME], sItemName, sizeof(sItemName));

		Format(sBuffer, sizeof(sBuffer), "%t", "system user inven use after", sCGName, sItemName, "global item");
		DDS_PrintToChat(client, sBuffer);

		/*************************
		 * 로그 작성
		**************************/
		Format(sMakeLogParam, sizeof(sMakeLogParam), "%s||%s||%d", sCGName, sItemName, iItemIdx);
		Log_Data(client, "item-use", sMakeLogParam);
	}
	else if (StrEqual(process, "inven-resell", false))
	{
		/*************************************************
		 *
		 * [인벤토리에서의 아이템 되팔기]
		 *
		**************************************************/
		iSimpleProc = DataProc_RESELL;

		/*************************
		 * 전달 파라메터 구분
		 *
		 * [0] - 데이터베이스 번호
		 * [1] - 아이템 번호
		**************************/
		char sTempStr[2][16];
		ExplodeString(data, "||", sTempStr, sizeof(sTempStr), sizeof(sTempStr[]));

		int iDBIdx = StringToInt(sTempStr[0]);
		int iItemIdx = StringToInt(sTempStr[1]);

		// 합할 금액 갱신 조건 확인
		int iItemMny = RoundToFloor(dds_eItemList[Find_GetItemListIndex(iItemIdx)][MONEY] * dds_hCV_ItemResellRatio.FloatValue);

		/*************************
		 * 기능 사용 여부
		**************************/
		if (!dds_hCV_SwitchResellItem.BoolValue)
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "system user inven resell function");
			DDS_PrintToChat(client, sBuffer);
			return;
		}

		/*************************
		 * 조건 및 환경 변수 확인
		**************************/
		/** 환경 변수 확인(유저단) **/
		char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
		UCM_GetClassInfo(UCM_GetClientClass(client), ClassInfo_Env, sGetEnv);

		// 되판매 가능한지
		SelectedStuffToString(sGetEnv, "ENV_DDS_ACCESS_ITEM_RESELL", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (!StringToInt(sGetEnv))
		{
			DDS_PrintToChat(client, "%t", "error access");
			return;
		}

		/** 조건 확인 **/
		// int 변수 하나에 2147483647 을 넘길 수 없음
		if ((dds_iUserMoney[client] + iItemMny) > 2147400000)
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "error money sobig");
			DDS_PrintToChat(client, sBuffer);
			return;
		}

		/*************************
		 * 대상 아이템 정보 삭제
		**************************/
		// 오류 검출 생성
		ArrayList hMakeErrIf = CreateArray(8);
		hMakeErrIf.Push(client);
		hMakeErrIf.Push(2020);

		// 쿼리 전송
		Format(sSendQuery, sizeof(sSendQuery), 
			"DELETE FROM `dds_user_item` WHERE `idx` = '%d' and `authid` = '%s' and `ilidx` = '%d'", 
			iDBIdx, sClient_AuthId, iItemIdx);
		dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrIf);

		/*************************
		 * 금액 정보 갱신
		**************************/
		char sSendParam[32];
		Format(sSendParam, sizeof(sSendParam), "%d||%d", 2021, iItemMny);
		System_DataProcess(client, "money-up", sSendParam);

		/*************************
		 * 화면 출력
		**************************/
		// 클라이언트 국가에 따른 아이템과 종류 이름 추출
		char sCGName[40];
		char sItemName[32];
		SelectedGeoNameToString(client, dds_eItemCategoryList[Find_GetItemCGListIndex(dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE])][NAME], sCGName, sizeof(sCGName));
		SelectedGeoNameToString(client, dds_eItemList[Find_GetItemListIndex(iItemIdx)][NAME], sItemName, sizeof(sItemName));

		Format(sBuffer, sizeof(sBuffer), "%t", "system user inven resell", sCGName, sItemName, iItemMny, "global money", "global item");
		DDS_PrintToChat(client, sBuffer);

		/*************************
		 * 로그 작성
		**************************/
		Format(sMakeLogParam, sizeof(sMakeLogParam), "%s||%s||%d||%d", sCGName, sItemName, iItemIdx, iItemMny);
		Log_Data(client, "item-resell", sMakeLogParam);
	}
	else if (StrEqual(process, "inven-gift", false) || StrEqual(process, "item-gift", false))
	{
		/*************************************************
		 *
		 * [인벤토리에서의 아이템 선물하기]
		 *
		**************************************************/
		if (StrEqual(process, "inven-gift", false))
			iSimpleProc = DataProc_GIFT;
		else if (StrEqual(process, "item-gift", false))
			iSimpleProc = DataProc_ITEMGIFT;

		/*************************
		 * 전달 파라메터 구분
		 *
		 * [0] - 데이터베이스 번호
		 * [1] - 아이템 번호
		 * [2] - 대상 클라이언트 유저ID
		**************************/
		char sTempStr[3][20];
		ExplodeString(data, "||", sTempStr, sizeof(sTempStr), sizeof(sTempStr[]));

		int iDBIdx = StringToInt(sTempStr[0]);
		int iItemIdx = StringToInt(sTempStr[1]);
		int iTargetUid = StringToInt(sTempStr[2]);

		/*************************
		 * 조건 및 환경 변수 확인
		**************************/
		/** 환경 변수 확인(유저단) **/
		char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
		UCM_GetClassInfo(UCM_GetClientClass(client), ClassInfo_Env, sGetEnv);

		// 선물 가능한지
		SelectedStuffToString(sGetEnv, "ENV_DDS_ACCESS_ITEM_GIFT", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (!StringToInt(sGetEnv))
		{
			DDS_PrintToChat(client, "%t", "error access");
			return;
		}

		/*************************
		 * 기능 사용 여부
		**************************/
		if (!dds_hCV_SwitchGiftItem.BoolValue)
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "system user inven gift function");
			DDS_PrintToChat(client, sBuffer);
			return;
		}

		/*************************
		 * 대상 클라이언트 검증
		**************************/
		int iTarget = GetClientOfUserId(iTargetUid);
		if (!IsClientInGame(iTarget))
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "system user inven gift tarerr");
			DDS_PrintToChat(client, sBuffer);
			return;
		}

		/*************************
		 * 본인 아이템 정보 삭제
		**************************/
		// 오류 검출 생성
		ArrayList hMakeErrIf = CreateArray(8);
		hMakeErrIf.Push(client);
		hMakeErrIf.Push(2016);

		// 쿼리 전송
		Format(sSendQuery, sizeof(sSendQuery), 
			"DELETE FROM `dds_user_item` WHERE `idx` = '%d' and `authid` = '%s' and `ilidx` = '%d'", 
			iDBIdx, sClient_AuthId, iItemIdx);
		dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrIf);

		/*************************
		 * 대상 아이템 정보 등록
		**************************/
		// 대상 클라이언트 고유번호 추출
		char sTargetAuthId[20];
		GetClientAuthId(iTarget, AuthId_SteamID64, sTargetAuthId, sizeof(sTargetAuthId));

		// 오류 검출 생성
		ArrayList hMakeErrIt = CreateArray(8);
		hMakeErrIt.Push(iTarget);
		hMakeErrIt.Push(2017);

		// 쿼리 전송
		Format(sSendQuery, sizeof(sSendQuery), 
			"INSERT INTO `dds_user_item` (`idx`, `authid`, `ilidx`, `aplied`, `buydate`) VALUES (NULL, '%s', '%d', '0', '%d')", 
			sTargetAuthId, iItemIdx, GetTime());
		dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrIt);

		/*************************
		 * 화면 출력
		**************************/
		// 클라이언트 국가에 따른 아이템과 종류 이름 추출
		char sCGName[40];
		char sItemName[32];
		SelectedGeoNameToString(client, dds_eItemCategoryList[Find_GetItemCGListIndex(dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE])][NAME], sCGName, sizeof(sCGName));
		SelectedGeoNameToString(client, dds_eItemList[Find_GetItemListIndex(iItemIdx)][NAME], sItemName, sizeof(sItemName));

		// 클라이언트와 대상 클라이언트 이름 추출
		char sUsrName[2][32];
		GetClientName(client, sUsrName[0], 32);
		GetClientName(iTarget, sUsrName[1], 32);

		Format(sBuffer, sizeof(sBuffer), "%t", "system user inven gift send", sCGName, sItemName, sUsrName[1], "global item");
		DDS_PrintToChat(client, sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%t", "system user inven gift take", sCGName, sItemName, sUsrName[0], "global item");
		DDS_PrintToChat(iTarget, sBuffer);

		/*************************
		 * 로그 작성
		**************************/
		// 클라이언트 이름 추출 후 인젝션 필터
		char sTmpName[32];
		GetClientName(iTarget, sTmpName, sizeof(sTmpName));
		SetPreventSQLInject(sTmpName, sTmpName, sizeof(sTmpName));

		// 로그 출력
		Format(sMakeLogParam, sizeof(sMakeLogParam), "%s||%s||%s||%s||%d", sTmpName, sTargetAuthId, sCGName, sItemName, iItemIdx);
		Log_Data(client, "item-gift", sMakeLogParam);
	}
	else if (StrEqual(process, "inven-drop", false))
	{
		/*************************************************
		 *
		 * [인벤토리에서의 아이템 버리기]
		 *
		**************************************************/
		iSimpleProc = DataProc_DROP;

		/*************************
		 * 전달 파라메터 구분
		 *
		 * [0] - 데이터베이스 번호
		 * [1] - 아이템 번호
		**************************/
		char sTempStr[2][16];
		ExplodeString(data, "||", sTempStr, sizeof(sTempStr), sizeof(sTempStr[]));

		int iDBIdx = StringToInt(sTempStr[0]);
		int iItemIdx = StringToInt(sTempStr[1]);

		/*************************
		 * 대상 아이템 정보 삭제
		**************************/
		// 오류 검출 생성
		ArrayList hMakeErrIf = CreateArray(8);
		hMakeErrIf.Push(client);
		hMakeErrIf.Push(2015);

		// 쿼리 전송
		Format(sSendQuery, sizeof(sSendQuery), 
			"DELETE FROM `dds_user_item` WHERE `idx` = '%d' and `authid` = '%s' and `ilidx` = '%d'", 
			iDBIdx, sClient_AuthId, iItemIdx);
		dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrIf);

		/*************************
		 * 화면 출력
		**************************/
		// 클라이언트 국가에 따른 아이템과 종류 이름 추출
		char sCGName[40];
		char sItemName[32];
		SelectedGeoNameToString(client, dds_eItemCategoryList[Find_GetItemCGListIndex(dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE])][NAME], sCGName, sizeof(sCGName));
		SelectedGeoNameToString(client, dds_eItemList[Find_GetItemListIndex(iItemIdx)][NAME], sItemName, sizeof(sItemName));

		Format(sBuffer, sizeof(sBuffer), "%t", "system user inven drop", sCGName, sItemName, "global item");
		DDS_PrintToChat(client, sBuffer);

		/*************************
		 * 로그 작성
		**************************/
		Format(sMakeLogParam, sizeof(sMakeLogParam), "%s||%s||%d", sCGName, sItemName, iItemIdx);
		Log_Data(client, "item-drop", sMakeLogParam);
	}
	else if (StrEqual(process, "curitem-cancel", false))
	{
		/*************************************************
		 *
		 * [내 장착 아이템에서의 장착 해제]
		 *
		**************************************************/
		iSimpleProc = DataProc_CURCANCEL;

		/*************************
		 * 전달 파라메터 구분
		 *
		 * [0] - 아이템 종류 코드
		**************************/
		int iCGCode = StringToInt(data);

		/*************************
		 * 대상 아이템 정보 갱신
		**************************/
		// 오류 검출 생성
		ArrayList hMakeErrIf = CreateArray(8);
		hMakeErrIf.Push(client);
		hMakeErrIf.Push(2014);

		// 쿼리 전송
		Format(sSendQuery, sizeof(sSendQuery), 
			"UPDATE `dds_user_item` SET `aplied` = '0' WHERE `idx` = '%d' and `authid` = '%s' and `ilidx` = '%d'", 
			dds_iUserAppliedItem[client][iCGCode][DBIDX], sClient_AuthId, dds_iUserAppliedItem[client][iCGCode][ITEMIDX]);
		dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrIf);

		/*************************
		 * 일회용 아이템은 버리기 처리
		**************************/
		if (dds_eItemList[Find_GetItemListIndex(dds_iUserAppliedItem[client][iCGCode][ITEMIDX])][HAVTIME] == -1)
		{
			char sSendParam[32];
			Format(sSendParam, sizeof(sSendParam), "%d||%d", dds_iUserAppliedItem[client][iCGCode][DBIDX], dds_iUserAppliedItem[client][iCGCode][ITEMIDX]);
			System_DataProcess(client, "inven-drop", sSendParam);

			// 메시지 출력
			DDS_PrintToChat(client, "%t", "system user inven time once drop");
		}

		// 정보 갱신
		int iPrevItemIdx = dds_iUserAppliedItem[client][iCGCode][ITEMIDX];
		dds_iUserAppliedItem[client][iCGCode][DBIDX] = 0;
		dds_iUserAppliedItem[client][iCGCode][ITEMIDX] = 0;

		/*************************
		 * 화면 출력
		**************************/
		// 클라이언트 국가에 따른 아이템과 종류 이름 추출
		char sCGName[40];
		char sItemName[32];
		SelectedGeoNameToString(client, dds_eItemCategoryList[Find_GetItemCGListIndex(dds_eItemList[Find_GetItemListIndex(iPrevItemIdx)][CATECODE])][NAME], sCGName, sizeof(sCGName));
		SelectedGeoNameToString(client, dds_eItemList[Find_GetItemListIndex(iPrevItemIdx)][NAME], sItemName, sizeof(sItemName));

		Format(sBuffer, sizeof(sBuffer), "%t", "system user curitem cancel", sCGName, sItemName, "global item");
		DDS_PrintToChat(client, sBuffer);

		/*************************
		 * 로그 작성
		**************************/
		Format(sMakeLogParam, sizeof(sMakeLogParam), "%s||%s||%d", sCGName, sItemName, iPrevItemIdx);
		Log_Data(client, "item-cancel", sMakeLogParam);
	}
	else if (StrEqual(process, "money-up", false))
	{
		/*************************************************
		 *
		 * [금액 증가]
		 *
		 * - 화면 출력 없음
		 *
		**************************************************/
		iSimpleProc = DataProc_MONEYUP;

		/*************************
		 * 전달 파라메터 구분
		 *
		 * [0] - 오류 코드
		 * [1] - 증가할 금액
		**************************/
		char sTempStr[2][32];
		ExplodeString(data, "||", sTempStr, sizeof(sTempStr), sizeof(sTempStr[]));

		int iErrCode = StringToInt(sTempStr[0]);
		int iTarMoney = StringToInt(sTempStr[1]);

		/*************************
		 * 조건 및 환경 변수 확인
		**************************/
		/** 환경 변수 확인(유저단) **/

		/** 조건 확인 **/
		// int 변수 하나에 2147483647 을 넘길 수 없음
		if ((dds_iUserMoney[client] + iTarMoney) > 2147400000)
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "error money sobig");
			DDS_PrintToChat(client, sBuffer);
			return;
		}

		/*************************
		 * 금액 정보 갱신
		**************************/
		// 오류 검출 생성
		ArrayList hMakeErrIf = CreateArray(8);
		hMakeErrIf.Push(client);
		hMakeErrIf.Push(iErrCode);
		
		// 쿼리 전송
		Format(sSendQuery, sizeof(sSendQuery), 
			"UPDATE `dds_user_profile` SET `money` = `money` + '%d' WHERE `authid` = '%s'", 
			iTarMoney, sClient_AuthId);
		dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrIf);

		// 실제 금액 갱신
		dds_iUserMoney[client] += iTarMoney;

		/*************************
		 * 로그 작성
		**************************/
		Format(sMakeLogParam, sizeof(sMakeLogParam), "%d||%d", dds_iUserMoney[client], iTarMoney);
		Log_Data(client, "money-up", sMakeLogParam);
	}
	else if (StrEqual(process, "money-down", false))
	{
		/*************************************************
		 *
		 * [금액 감소]
		 *
		 * - 화면 출력 없음
		 *
		**************************************************/
		iSimpleProc = DataProc_MONEYDOWN;

		/*************************
		 * 전달 파라메터 구분
		 *
		 * [0] - 오류 코드
		 * [1] - 감소할 금액
		**************************/
		char sTempStr[2][32];
		ExplodeString(data, "||", sTempStr, sizeof(sTempStr), sizeof(sTempStr[]));

		int iErrCode = StringToInt(sTempStr[0]);
		int iTarMoney = StringToInt(sTempStr[1]);

		/*************************
		 * 조건 및 환경 변수 확인
		**************************/
		/** 환경 변수 확인(유저단) **/
		// 

		/** 조건 확인 **/
		// 돈 부족
		if ((dds_iUserMoney[client] - iTarMoney) < 0)
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "error money nid", (iTarMoney - dds_iUserMoney[client]), "global money");
			DDS_PrintToChat(client, sBuffer);
			return;
		}

		/*************************
		 * 금액 정보 갱신
		**************************/
		// 오류 검출 생성
		ArrayList hMakeErrIf = CreateArray(8);
		hMakeErrIf.Push(client);
		hMakeErrIf.Push(iErrCode);
		
		// 쿼리 전송
		Format(sSendQuery, sizeof(sSendQuery), 
			"UPDATE `dds_user_profile` SET `money` = `money` - '%d' WHERE `authid` = '%s'", 
			iTarMoney, sClient_AuthId);
		dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrIf);

		// 실제 금액 갱신
		dds_iUserMoney[client] -= iTarMoney;

		/*************************
		 * 로그 작성
		**************************/
		Format(sMakeLogParam, sizeof(sMakeLogParam), "%d||%d", dds_iUserMoney[client], iTarMoney);
		Log_Data(client, "money-down", sMakeLogParam);
	}
	else if (StrEqual(process, "money-gift", false))
	{
		/*************************************************
		 *
		 * [금액 선물]
		 *
		**************************************************/
		iSimpleProc = DataProc_MONEYGIFT;

		/*************************
		 * 전달 파라메터 구분
		 *
		 * [0] - 증가할 금액
		 * [1] - 대상 클라이언트 유저ID
		**************************/
		char sTempStr[2][30];
		ExplodeString(data, "||", sTempStr, sizeof(sTempStr), sizeof(sTempStr[]));

		int iTarMoney = StringToInt(sTempStr[0]);
		int iTargetUid = StringToInt(sTempStr[1]);

		/*************************
		 * 기능 사용 여부
		**************************/
		if (!dds_hCV_SwitchGiftMoney.BoolValue)
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "system user money gift function");
			DDS_PrintToChat(client, sBuffer);
			return;
		}

		/*************************
		 * 대상 클라이언트 검증
		**************************/
		int iTarget = GetClientOfUserId(iTargetUid);
		if (!IsClientInGame(iTarget))
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "system user money gift tarerr");
			DDS_PrintToChat(client, sBuffer);
			return;
		}

		/*************************
		 * 조건 및 환경 변수 확인
		**************************/
		/** 환경 변수 확인(유저단) **/
		/* 접근 관련 */
		char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
		UCM_GetClassInfo(UCM_GetClientClass(client), ClassInfo_Env, sGetEnv);

		SelectedStuffToString(sGetEnv, "ENV_DDS_ACCESS_MONEY_GIFT", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (!StringToInt(sGetEnv))
		{
			DDS_PrintToChat(client, "%t", "error access");
			return;
		}

		/** 조건 확인 **/
		// 본인 돈 부족
		if ((dds_iUserMoney[client] - iTarMoney) < 0)
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "error money nid", (iTarMoney - dds_iUserMoney[client]), "global money");
			DDS_PrintToChat(client, sBuffer);
			return;
		}

		// int 변수 하나에 2147483647 을 넘길 수 없음
		if ((dds_iUserMoney[iTarget] + iTarMoney) > 2147400000)
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "error money sobig");
			DDS_PrintToChat(client, sBuffer);
			return;
		}

		/*************************
		 * 본인 금액 정보 갱신
		**************************/
		char sSendParam[32];
		Format(sSendParam, sizeof(sSendParam), "%d||%d", 2018, iTarMoney);
		System_DataProcess(client, "money-down", sSendParam);

		/*************************
		 * 대상 금액 정보 갱신
		**************************/
		// 대상 클라이언트 고유번호 추출
		char sTargetAuthId[20];
		GetClientAuthId(iTarget, AuthId_SteamID64, sTargetAuthId, sizeof(sTargetAuthId));

		// 갱신
		Format(sSendParam, sizeof(sSendParam), "%d||%d", 2019, iTarMoney);
		System_DataProcess(iTarget, "money-up", sSendParam);

		/*************************
		 * 화면 출력
		**************************/
		// 클라이언트와 대상 클라이언트 이름 추출
		char sUsrName[2][32];
		GetClientName(client, sUsrName[0], 32);
		GetClientName(iTarget, sUsrName[1], 32);

		Format(sBuffer, sizeof(sBuffer), "%t", "system user money gift send", iTarMoney, "global money", sUsrName[1]);
		DDS_PrintToChat(client, sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%t", "system user money gift take", iTarMoney, "global money", sUsrName[0]);
		DDS_PrintToChat(iTarget, sBuffer);

		/*************************
		 * 로그 작성
		**************************/
		// 클라이언트 이름 추출 후 인젝션 필터
		char sTmpName[32];
		GetClientName(iTarget, sTmpName, sizeof(sTmpName));
		SetPreventSQLInject(sTmpName, sTmpName, sizeof(sTmpName));

		// 로그 출력
		Format(sMakeLogParam, sizeof(sMakeLogParam), "%s||%s||%d", sTmpName, sTargetAuthId, dds_iUserMoney[client]);
		Log_Data(client, "money-gift", sMakeLogParam);
	}
	else if (StrEqual(process, "money-give", false))
	{
		/*************************************************
		 *
		 * [금액 주기]
		 *
		**************************************************/
		iSimpleProc = DataProc_MONEYGIVE;

		/*************************
		 * 전달 파라메터 구분
		 *
		 * [0] - 금액 량
		 * [1] - 대상 클라이언트 유저ID
		**************************/
		char sTempStr[2][30];
		ExplodeString(data, "||", sTempStr, sizeof(sTempStr), sizeof(sTempStr[]));

		int iMoneyAmount = StringToInt(sTempStr[0]);
		int iTargetUid = StringToInt(sTempStr[1]);

		/*************************
		 * 조건 및 환경 변수 확인
		**************************/
		/** 환경 변수 확인(유저단) **/
		/* 접근 관련 */
		char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
		UCM_GetClassInfo(UCM_GetClientClass(client), ClassInfo_Env, sGetEnv);
		
		SelectedStuffToString(sGetEnv, "ENV_DDS_ACCESS_MONEY_GIVE", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (!StringToInt(sGetEnv))
		{
			DDS_PrintToChat(client, "%t", "error access");
			return;
		}

		/*************************
		 * 대상 클라이언트 검증
		**************************/
		int iTarget = GetClientOfUserId(iTargetUid);
		if (!IsClientInGame(iTarget))
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "system user money give tarerr");
			DDS_PrintToChat(client, sBuffer);
			return;
		}

		/*************************
		 * 대상 아이템 정보 등록
		**************************/
		// 대상 클라이언트 고유번호 추출
		char sTargetAuthId[20];
		GetClientAuthId(iTarget, AuthId_SteamID64, sTargetAuthId, sizeof(sTargetAuthId));

		// 오류 검출 생성
		ArrayList hMakeErrIt = CreateArray(8);
		hMakeErrIt.Push(iTarget);
		hMakeErrIt.Push(2029);

		// 쿼리 전송
		Format(sSendQuery, sizeof(sSendQuery), 
			"UPDATE `dds_user_profile` SET `money` = `money` + '%d' WHERE `authid` = '%s'", 
			iMoneyAmount, sTargetAuthId);
		dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrIt);

		/*************************
		 * 화면 출력
		**************************/
		// 클라이언트와 대상 클라이언트 이름 추출
		char sUsrName[2][32];
		GetClientName(client, sUsrName[0], 32);
		GetClientName(iTarget, sUsrName[1], 32);

		Format(sBuffer, sizeof(sBuffer), "%t", "system user money give send", sUsrName[1], iMoneyAmount, "global money");
		DDS_PrintToChat(client, sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%t", "system user money give take", sUsrName[0], iMoneyAmount, "global money");
		DDS_PrintToChat(iTarget, sBuffer);

		/*************************
		 * 로그 작성
		**************************/
		// 클라이언트 이름 추출 후 인젝션 필터
		char sTmpName[32];
		GetClientName(iTarget, sTmpName, sizeof(sTmpName));
		SetPreventSQLInject(sTmpName, sTmpName, sizeof(sTmpName));

		// 로그 출력
		Format(sMakeLogParam, sizeof(sMakeLogParam), "%s||%s||%d", sTmpName, sTargetAuthId, iMoneyAmount);
		Log_Data(client, "money-give", sMakeLogParam);
	}
	else if (StrEqual(process, "money-takeaway", false))
	{
		/*************************************************
		 *
		 * [금액 뺏기]
		 *
		**************************************************/
		iSimpleProc = DataProc_MONEYTAKEAWAY;

		/*************************
		 * 전달 파라메터 구분
		 *
		 * [0] - 금액 량
		 * [1] - 대상 클라이언트 유저ID
		**************************/
		char sTempStr[2][30];
		ExplodeString(data, "||", sTempStr, sizeof(sTempStr), sizeof(sTempStr[]));

		int iMoneyAmount = StringToInt(sTempStr[0]);
		int iTargetUid = StringToInt(sTempStr[1]);

		/*************************
		 * 조건 및 환경 변수 확인
		**************************/
		/** 환경 변수 확인(유저단) **/
		/* 접근 관련 */
		char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
		UCM_GetClassInfo(UCM_GetClientClass(client), ClassInfo_Env, sGetEnv);
		
		SelectedStuffToString(sGetEnv, "ENV_DDS_ACCESS_MONEY_TAKEAWAY", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (!StringToInt(sGetEnv))
		{
			DDS_PrintToChat(client, "%t", "error access");
			return;
		}

		/*************************
		 * 대상 클라이언트 검증
		**************************/
		int iTarget = GetClientOfUserId(iTargetUid);
		if (!IsClientInGame(iTarget))
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "system user money takeaway tarerr");
			DDS_PrintToChat(client, sBuffer);
			return;
		}

		/*************************
		 * 대상 아이템 정보 등록
		**************************/
		// 대상 클라이언트 고유번호 추출
		char sTargetAuthId[20];
		GetClientAuthId(iTarget, AuthId_SteamID64, sTargetAuthId, sizeof(sTargetAuthId));

		// 오류 검출 생성
		ArrayList hMakeErrIt = CreateArray(8);
		hMakeErrIt.Push(iTarget);
		hMakeErrIt.Push(2030);

		// 쿼리 전송
		Format(sSendQuery, sizeof(sSendQuery), 
			"UPDATE `dds_user_profile` SET `money` = `money` - '%d' WHERE `authid` = '%s'", 
			iMoneyAmount, sTargetAuthId);
		dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrIt);

		/*************************
		 * 화면 출력
		**************************/
		// 클라이언트 이름 추출 후 인젝션 필터
		char sTmpName[32];
		GetClientName(iTarget, sTmpName, sizeof(sTmpName));
		SetPreventSQLInject(sTmpName, sTmpName, sizeof(sTmpName));

		Format(sBuffer, sizeof(sBuffer), "%t", "system user money takeaway action", sTmpName, iMoneyAmount, "global money");
		DDS_PrintToChat(client, sBuffer);

		/*************************
		 * 로그 작성
		**************************/
		Format(sMakeLogParam, sizeof(sMakeLogParam), "%s||%s||%d", sTmpName, sTargetAuthId, iMoneyAmount);
		Log_Data(client, "money-takeaway", sMakeLogParam);
	}
	else if (StrEqual(process, "item-give", false))
	{
		/*************************************************
		 *
		 * [아이템 주기]
		 *
		**************************************************/
		iSimpleProc = DataProc_ITEMGIVE;

		/*************************
		 * 전달 파라메터 구분
		 *
		 * [0] - 아이템 번호
		 * [1] - 대상 클라이언트 유저ID
		**************************/
		char sTempStr[2][30];
		ExplodeString(data, "||", sTempStr, sizeof(sTempStr), sizeof(sTempStr[]));

		int iItemIdx = StringToInt(sTempStr[0]);
		int iTargetUid = StringToInt(sTempStr[1]);

		/*************************
		 * 조건 및 환경 변수 확인
		**************************/
		/** 환경 변수 확인(유저단) **/
		/* 접근 관련 */
		char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
		UCM_GetClassInfo(UCM_GetClientClass(client), ClassInfo_Env, sGetEnv);
		
		SelectedStuffToString(sGetEnv, "ENV_DDS_ACCESS_ITEM_GIVE", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (!StringToInt(sGetEnv))
		{
			DDS_PrintToChat(client, "%t", "error access");
			return;
		}

		/*************************
		 * 대상 클라이언트 검증
		**************************/
		int iTarget = GetClientOfUserId(iTargetUid);
		if (!IsClientInGame(iTarget))
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "system user item give tarerr");
			DDS_PrintToChat(client, sBuffer);
			return;
		}

		/*************************
		 * 대상 아이템 정보 등록
		**************************/
		// 대상 클라이언트 고유번호 추출
		char sTargetAuthId[20];
		GetClientAuthId(iTarget, AuthId_SteamID64, sTargetAuthId, sizeof(sTargetAuthId));

		// 오류 검출 생성
		ArrayList hMakeErrIt = CreateArray(8);
		hMakeErrIt.Push(iTarget);
		hMakeErrIt.Push(2025);

		// 쿼리 전송
		Format(sSendQuery, sizeof(sSendQuery), 
			"INSERT INTO `dds_user_item` (`idx`, `authid`, `ilidx`, `aplied`, `buydate`) VALUES (NULL, '%s', '%d', '0', '%d')", 
			sTargetAuthId, iItemIdx, GetTime());
		dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrIt);

		/*************************
		 * 화면 출력
		**************************/
		// 클라이언트 국가에 따른 아이템과 종류 이름 추출
		char sCGName[40];
		char sItemName[32];
		SelectedGeoNameToString(client, dds_eItemCategoryList[Find_GetItemCGListIndex(dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE])][NAME], sCGName, sizeof(sCGName));
		SelectedGeoNameToString(client, dds_eItemList[Find_GetItemListIndex(iItemIdx)][NAME], sItemName, sizeof(sItemName));

		// 클라이언트와 대상 클라이언트 이름 추출
		char sUsrName[2][32];
		GetClientName(client, sUsrName[0], 32);
		GetClientName(iTarget, sUsrName[1], 32);

		Format(sBuffer, sizeof(sBuffer), "%t", "system user item give send", sCGName, sItemName, sUsrName[1], "global item");
		DDS_PrintToChat(client, sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%t", "system user item give take", sCGName, sItemName, sUsrName[0], "global item");
		DDS_PrintToChat(iTarget, sBuffer);

		/*************************
		 * 로그 작성
		**************************/
		// 클라이언트 이름 추출 후 인젝션 필터
		char sTmpName[32];
		GetClientName(iTarget, sTmpName, sizeof(sTmpName));
		SetPreventSQLInject(sTmpName, sTmpName, sizeof(sTmpName));

		// 로그 출력
		Format(sMakeLogParam, sizeof(sMakeLogParam), "%s||%s||%s||%s||%d", sTmpName, sTargetAuthId, sCGName, sItemName, iItemIdx);
		Log_Data(client, "item-give", sMakeLogParam);
	}
	else if (StrEqual(process, "item-takeaway", false))
	{
		/*************************************************
		 *
		 * [아이템을 빼앗을 때]
		 *
		**************************************************/
		iSimpleProc = DataProc_ITEMTAKEAWAY;

		/*************************
		 * 전달 파라메터 구분
		 *
		 * [0] - 데이터베이스 번호
		 * [1] - 아이템 번호
		 * [2] - 대상 클라이언트 유저ID
		**************************/
		char sTempStr[3][20];
		ExplodeString(data, "||", sTempStr, sizeof(sTempStr), sizeof(sTempStr[]));

		int iDBIdx = StringToInt(sTempStr[0]);
		int iItemIdx = StringToInt(sTempStr[1]);
		int iTargetUid = StringToInt(sTempStr[2]);

		/*************************
		 * 조건 및 환경 변수 확인
		**************************/
		/** 환경 변수 확인(유저단) **/
		/* 접근 관련 */
		char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
		UCM_GetClassInfo(UCM_GetClientClass(client), ClassInfo_Env, sGetEnv);
		
		SelectedStuffToString(sGetEnv, "ENV_DDS_ACCESS_ITEM_TAKEAWAY", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (!StringToInt(sGetEnv))
		{
			DDS_PrintToChat(client, "%t", "error access");
			return;
		}

		/*************************
		 * 대상 클라이언트 검증
		**************************/
		int iTarget = GetClientOfUserId(iTargetUid);
		if (!IsClientInGame(iTarget))
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "system user item takeaway tarerr");
			DDS_PrintToChat(client, sBuffer);
			return;
		}

		/*************************
		 * 대상 아이템 정보 삭제
		**************************/
		// 대상 클라이언트 고유번호 추출
		char sTargetAuthId[20];
		GetClientAuthId(iTarget, AuthId_SteamID64, sTargetAuthId, sizeof(sTargetAuthId));

		// 오류 검출 생성
		ArrayList hMakeErrIf = CreateArray(8);
		hMakeErrIf.Push(client);
		hMakeErrIf.Push(2026);

		// 쿼리 전송
		Format(sSendQuery, sizeof(sSendQuery), 
			"DELETE FROM `dds_user_item` WHERE `idx` = '%d' and `authid` = '%s' and `ilidx` = '%d'", 
			iDBIdx, sTargetAuthId, iItemIdx);
		dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrIf);

		/*************************
		 * 화면 출력
		**************************/
		// 클라이언트 국가에 따른 아이템과 종류 이름 추출
		char sCGName[40];
		char sItemName[32];
		SelectedGeoNameToString(client, dds_eItemCategoryList[Find_GetItemCGListIndex(dds_eItemList[Find_GetItemListIndex(iItemIdx)][CATECODE])][NAME], sCGName, sizeof(sCGName));
		SelectedGeoNameToString(client, dds_eItemList[Find_GetItemListIndex(iItemIdx)][NAME], sItemName, sizeof(sItemName));

		// 클라이언트와 대상 클라이언트 이름 추출
		char sUsrName[32];
		GetClientName(iTarget, sUsrName, 32);

		Format(sBuffer, sizeof(sBuffer), "%t", "system user item takeaway action", sCGName, sItemName, sUsrName, "global item");
		DDS_PrintToChat(client, sBuffer);

		/*************************
		 * 로그 작성
		**************************/
		// 클라이언트 이름 추출 후 인젝션 필터
		char sTmpName[32];
		GetClientName(iTarget, sTmpName, sizeof(sTmpName));
		SetPreventSQLInject(sTmpName, sTmpName, sizeof(sTmpName));

		// 로그 출력
		Format(sMakeLogParam, sizeof(sMakeLogParam), "%s||%s||%s||%s||%d", sTmpName, sTargetAuthId, sCGName, sItemName, iItemIdx);
		Log_Data(client, "item-takeaway", sMakeLogParam);
	}
	else if (StrEqual(process, "user-refdata", false))
	{
		/*************************************************
		 *
		 * [클라이언트 기타 참고 데이터 설정]
		 *
		**************************************************/
		iSimpleProc = DataProc_USERREFDATA;

		/*************************
		 * 전달 파라메터 구분
		 *
		 * [0] - 구분 타입
		 * [1] - 설정할 문자열
		**************************/
		char sTempStr[2][64];
		ExplodeString(data, "||", sTempStr, sizeof(sTempStr), sizeof(sTempStr[]));

		char sType[32];
		Format(sType, sizeof(sType), sTempStr[0]);
		char sValue[64];
		Format(sValue, sizeof(sValue), sTempStr[1]);

		/*************************
		 * 설정 문자열 인젝션 필터
		**************************/
		SetPreventSQLInject(sValue, sValue, sizeof(sValue));

		/*************************
		 * 클라이언트 적용
		**************************/
		char sRefSet[256];
		Format(sRefSet, sizeof(sRefSet), "%s:%s", sType, sValue);
		if (strlen(dds_sUserRefData[client]) <= 0)	Format(sRefSet, sizeof(sRefSet), "%s", sRefSet);
		Format(sRefSet, sizeof(sRefSet), "%s||%s", dds_sUserRefData[client], sRefSet);

		Format(dds_sUserRefData[client], 256, sRefSet);

		/*************************
		 * 대상 아이템 정보 삭제
		**************************/
		// 오류 검출 생성
		ArrayList hMakeErrIf = CreateArray(8);
		hMakeErrIf.Push(client);
		hMakeErrIf.Push(2028);

		// 쿼리 전송
		Format(sSendQuery, sizeof(sSendQuery), 
			"UPDATE `dds_user_profile` SET `refdata` = '%s' WHERE `authid` = '%s'", 
			sRefSet, sClient_AuthId);
		dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrIf);

		/*************************
		 * 화면 출력
		**************************/
		Format(sBuffer, sizeof(sBuffer), "%t", "system user refdata", sValue);
		DDS_PrintToChat(client, sBuffer);

		/*************************
		 * 로그 작성
		**************************/
		Format(sMakeLogParam, sizeof(sMakeLogParam), "%s||%s", sType, sValue);
		Log_Data(client, "user-refdata", sMakeLogParam);
	}

	// 포워드 실행
	Forward_OnDataProcess(client, iSimpleProc, data);
}


/**
 * LOG :: 오류코드 구분 및 로그 작성
 *
 * @param client			클라이언트 인덱스
 * @param errcode			오류 코드
 * @param errordec			오류 원인
 */
public void Log_CodeError(int client, int errcode, const char[] errordec)
{
	char usrauth[20];

	// 실제 클라이언트 구분 후 고유번호 추출
	if (client > 0)
	{
		if (IsClientAuthorized(client))
			GetClientAuthId(client, AuthId_SteamID64, usrauth, sizeof(usrauth));
	}

	// 클라이언트와 서버 구분하여 접두 메세지 설정
	char sDetOutput[512];
	char sOutput[512];
	char sPrefix[128];
	char sErrDesc[1024];

	if (client > 0) // 클라이언트
	{
		Format(sPrefix, sizeof(sPrefix), "[Error :: ID %d]", errcode);
		if (strlen(errordec) > 0) Format(sErrDesc, sizeof(sErrDesc), "[Error Desc :: ID %d] %s", errcode, errordec);
	}
	else if (client == 0) // 서버
	{
		Format(sPrefix, sizeof(sPrefix), "[%t :: ID %d]", "error occurred", errcode);
		if (strlen(errordec) > 0) Format(sErrDesc, sizeof(sErrDesc), "[%t :: ID %d] %s", "error desc", errcode, errordec);
	}

	Format(sDetOutput, sizeof(sDetOutput), "%s", sPrefix);
	Format(sOutput, sizeof(sOutput), "%s", sPrefix);

	// 오류코드 구분
	switch (errcode)
	{
		case 1000:
		{
			// SQL 데이터베이스 연결 실패
			Format(sDetOutput, sizeof(sDetOutput), "%s Connecting Database is Failure!", sDetOutput);
		}
		case 1001:
		{
			// SQL 데이터베이스 핸들 전달 실패
			Format(sDetOutput, sizeof(sDetOutput), "%s Database Handle is null!", sDetOutput);
		}
		case 1002:
		{
			// SQL 데이터베이스 초기화 시 아이템 카테고리 로드
			Format(sDetOutput, sizeof(sDetOutput), "%s Retriving Item Category DB is Failure!", sDetOutput);
		}
		case 1003:
		{
			// SQL 데이터베이스 초기화 시 아이템 목록 로드
			Format(sDetOutput, sizeof(sDetOutput), "%s Retriving Item List DB is Failure!", sDetOutput);
		}
		case 1004:
		{
			// SQL 데이터베이스 초기화 시 ENV 목록 로드
			Format(sDetOutput, sizeof(sDetOutput), "%s Retriving ENV List DB is Failure!", sDetOutput);
		}
		case 1010:
		{
			// 유저가 접속하여 정보를 로드할 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql usrprofile load");
			Format(sDetOutput, sizeof(sDetOutput), "%s Retriving User Profile DB is Failure! (AuthID: %s)", sDetOutput, usrauth);
		}
		case 1011:
		{
			// 유저 체크 후 레코드가 없어 레코드를 만들 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql usrprofile make");
			Format(sDetOutput, sizeof(sDetOutput), "%s Making User Profile is Failure! (AuthID: %s)", sDetOutput, usrauth);
		}
		case 1012:
		{
			// 유저 체크 후 레코드가 있어 정보를 갱신할 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql usrprofile cnupdate");
			Format(sDetOutput, sizeof(sDetOutput), "%s Updating User Profile is Failure! (C&U) (AuthID: %s)", sDetOutput, usrauth);
		}
		case 1013:
		{
			// 유저가 서버로부터 나가면서 갱신 처리할 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql usrprofile dnupdate");
			Format(sDetOutput, sizeof(sDetOutput), "%s Updating User Profile is Failure! (D&U) (AuthID: %s)", sDetOutput, usrauth);
		}
		case 1014:
		{
			// 유저 체크하면서 프로필 목록이 잘못되었을 경우
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql usrprofile invalid");
			Format(sDetOutput, sizeof(sDetOutput), "%s Retrived User Profile DB is invalid. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 1015:
		{
			// 유저 체크하면서 유저 장착 아이템 목록이 잘못되었을 경우
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql usritem applied");
			Format(sDetOutput, sizeof(sDetOutput), "%s Retrived User Item DB is invalid. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 1016:
		{
			// 유저 체크하면서 유저 아이템 설정 상태가 잘못되었을 경우
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql usrsetting load");
			Format(sDetOutput, sizeof(sDetOutput), "%s Retrived User Setting DB is invalid. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 1017:
		{
			// 유저 체크 후 레코드가 없어 설정 정보 레코드를 만들 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql usrprofile make setting");
			Format(sDetOutput, sizeof(sDetOutput), "%s Making User Setting is Failure! (AuthID: %s)", sDetOutput, usrauth);
		}
		case 1018:
		{
			// 유저 체크 후 지속 속성 정보를 확인할 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql usrprofile load havtime");
			Format(sDetOutput, sizeof(sDetOutput), "%s Retriving User HavTime Item is Failure! (AuthID: %s)", sDetOutput, usrauth);
		}
		case 1020:
		{
			// 유저가 내 장착 아이템 종류 메뉴를 열었을 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql usritem curitem");
			Format(sDetOutput, sizeof(sDetOutput), "%s Retriving User Item DB is Failure! (AuthID: %s)", sDetOutput, usrauth);
		}
		case 1021:
		{
			// 유저가 내 인벤토리 세부 메뉴를 열었을 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql usritem inventory");
			Format(sDetOutput, sizeof(sDetOutput), "%s Retriving User Item DB is Failure! (AuthID: %s)", sDetOutput, usrauth);
		}
		case 1022:
		{
			// 유저가 아이템 활성 상태를 변경하였을 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql usrsetting set");
			Format(sDetOutput, sizeof(sDetOutput), "%s Updating User Setting DB is Failure! (AuthID: %s)", sDetOutput, usrauth);
		}
		case 1100:
		{
			// [데이터 로그] 로그를 처리할 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql log");
			Format(sDetOutput, sizeof(sDetOutput), "%s Inserting User Log DB is Failure! (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2010:
		{
			// [아이템 처리 시스템] 아이템을 구매할 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql itemproc buy");
			Format(sDetOutput, sizeof(sDetOutput), "%s Inserting User Item is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2011:
		{
			// [아이템 처리 시스템] 아이템을 구매할 때 금액 갱신
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql itemproc buy money");
			Format(sDetOutput, sizeof(sDetOutput), "%s Updating User's Money is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2012:
		{
			// [아이템 처리 시스템] 내 인벤토리에서 아이템을 장착하면서 기존 아이템 장착 해제할 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql itemproc inven use prev");
			Format(sDetOutput, sizeof(sDetOutput), "%s Updating User Item is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2013:
		{
			// [아이템 처리 시스템] 내 인벤토리에서 아이템을 장착하면서 대상 아이템 장착할 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql itemproc inven use after");
			Format(sDetOutput, sizeof(sDetOutput), "%s Updating User Item is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2014:
		{
			// [아이템 처리 시스템] 내 장착 아이템에서 아이템을 장착 해제시킬 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql itemproc curitem cancel");
			Format(sDetOutput, sizeof(sDetOutput), "%s Updating User Item is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2015:
		{
			// [아이템 처리 시스템] 내 인벤토리에서 아이템을 버릴 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql itemproc inven drop");
			Format(sDetOutput, sizeof(sDetOutput), "%s Deleting User Item is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2016:
		{
			// [아이템 처리 시스템] 내 인벤토리에서 아이템을 선물할 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql itemproc inven gift");
			Format(sDetOutput, sizeof(sDetOutput), "%s Deleting User Item is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2017:
		{
			// [아이템 처리 시스템] 내 인벤토리를 이용하여 대상이 아이템을 선물받을 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql itemproc inven gift target");
			Format(sDetOutput, sizeof(sDetOutput), "%s Inserting User Item is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2018:
		{
			// [아이템 처리 시스템] 금액 선물을 할 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql itemproc money gift");
			Format(sDetOutput, sizeof(sDetOutput), "%s Updating User Money is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2019:
		{
			// [아이템 처리 시스템] 금액 선물을 이용하여 대상이 금액을 선물받을 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql itemproc money gift target");
			Format(sDetOutput, sizeof(sDetOutput), "%s Updating User Money is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2020:
		{
			// [아이템 처리 시스템] 인벤토리에서 아이템을 되팔 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql itemproc inven resell");
			Format(sDetOutput, sizeof(sDetOutput), "%s Deleting User Item is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2021:
		{
			// [아이템 처리 시스템] 인벤토리에서 아이템을 되팔으면서 금액을 갱신할 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql itemproc inven resell money");
			Format(sDetOutput, sizeof(sDetOutput), "%s Updating User Money is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2022:
		{
			// [데이터 초기화] 모두 초기화
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql initdata alldb");
			Format(sDetOutput, sizeof(sDetOutput), "%s Deleting All Databases is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2023:
		{
			// [데이터 초기화] 모든 유저 초기화
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql initdata alluser");
			Format(sDetOutput, sizeof(sDetOutput), "%s Deleting All User Databases is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2024:
		{
			// [아이템 처리 시스템] 일반적인 금액 변경 시
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql itemproc money update");
			Format(sDetOutput, sizeof(sDetOutput), "%s Updating User Money is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2025:
		{
			// [아이템 처리 시스템] 아이템을 주어 상대방이 받을 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql itemproc item give");
			Format(sDetOutput, sizeof(sDetOutput), "%s Inserting User Item is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2026:
		{
			// [아이템 처리 시스템] 아이템을 상대방으로부터 빼앗을 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql itemproc item takeaway");
			Format(sDetOutput, sizeof(sDetOutput), "%s Deleting User Item is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2027:
		{
			// [아이템 뺏기] 대상 클라이언트의 아이템 목록을 불러올 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql itemtakeaway list");
			Format(sDetOutput, sizeof(sDetOutput), "%s Retriving User Item is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2028:
		{
			// [기타 참고 문자열] 클라이언트의 기타 참고 문자열을 설정할 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql user refdata");
			Format(sDetOutput, sizeof(sDetOutput), "%s Update User Profile is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2029:
		{
			// [아이템 처리 시스템] 대상 클라이언트애개 일정 금액을 줄 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql user money give");
			Format(sDetOutput, sizeof(sDetOutput), "%s Update User Profile is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2030:
		{
			// [아이템 처리 시스템] 대상 클라이언트애개 일정 금액을 뺏을 때
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql user money takeaway");
			Format(sDetOutput, sizeof(sDetOutput), "%s Update User Profile is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
	}

	// 클라이언트와 서버 구분하여 로그 출력
	if (client > 0) // 클라이언트
	{
		// 클라이언트 메세지 전송
		if (IsClientInGame(client))
		{
			DDS_PrintToChat(client, sOutput);
			if (strlen(sErrDesc) > 0) DDS_PrintToChat(client, sErrDesc);
		}

		// 서버 메세지 전송
		DDS_PrintToServer("%s (client: %N)", sDetOutput, client);
		if (strlen(sErrDesc) > 0) DDS_PrintToServer("%s (client: %N)", sErrDesc, client);

		// 로그 파일 작성
		LogToFile(dds_sPluginLogFile, "%s (client: %N)", sDetOutput, client);
		if (strlen(sErrDesc) > 0) LogToFile(dds_sPluginLogFile, "%s (client: %N)", sErrDesc, client);
	}
	else if (client == 0) // 서버
	{
		// 서버 메세지 전송
		DDS_PrintToServer(sDetOutput);
		if (strlen(sErrDesc) > 0) DDS_PrintToServer(sErrDesc);

		// 로그 파일 작성
		LogToFile(dds_sPluginLogFile, "%s (Server)", sDetOutput);
		if (strlen(sErrDesc) > 0) LogToFile(dds_sPluginLogFile, "%s (Server)", sErrDesc);
	}
}

/**
 * LOG :: 데이터 로그 작성
 *
 * @param client			클라이언트 인덱스
 * @param action			행동 구분
 * @param data				추가 파라메터
 */
public void Log_Data(int client, const char[] action, const char[] data)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	// ConVar 설정 확인
	if (!dds_hCV_SwitchLogData.BoolValue)	return;

	// 서버가 주체가 되면 안됨
	if (client == 0)	return;

	// 주체 클라이언트 존재 확인
	if (client > 0)
	{
		if (!IsClientAuthorized(client))
			return;
	}

	// SQL 데이터베이스가 활성화되어 있지 않다면 작동 안함
	if (!dds_bSQLStatus)	return;

	// 유저의 SQL 데이터베이스 상태가 활성화되어 있지 않다면 작동 안함
	if (!dds_bUserSQLStatus[client])	return;

	/*******************************
	 * 설정 준비
	********************************/
	// 실제 클라이언트 구분 후 고유번호 추출
	char sClient_AuthId[20];
	GetClientAuthId(client, AuthId_SteamID64, sClient_AuthId, sizeof(sClient_AuthId));

	// IP 주소 추출
	char sClient_IP[32];
	GetClientIP(client, sClient_IP, sizeof(sClient_IP));

	// 출력 설정
	//char sOutput[512];

	// 파라메터 준비
	char sSendParam[128];

	// 쿼리 준비
	char sSendQuery[512];

	/******************************************************************************
	 * -----------------------------------
	 * 'action' 파라메터 종류 별 나열
	 * -----------------------------------
	 *
	 * 'game-connect' - 게임 내에 들어왔을 때
	 * 'game-disconnect' - 게임 밖으로 나갔을 때
	 * 'item-buy' - 메인 메뉴에서 아이템을 구매할 때
	 * 'item-use' - 아이템을 장착하였을 때
	 * 'item-cancel' - 아이템을 장착 해제하였을 때
	 * 'item-resell' - 아이템을 되팔았을 때
	 * 'item-gift' - 아이템을 선물하였을 때
	 * 'item-drop' - 아이템을 버렸을 때
	 * 'money-up' - 금액이 증가될 때
	 * 'money-down' - 금액이 내려갈 때
	 * 'money-gift' - 금액을 선물할 때
	 * 'money-give' - 금액을 줄때
	 * 'money-takeaway' - 금액을 빼앗을 때
	 * 'item-give' - 아이템을 줄 때
	 * 'item-takeaway' - 아이템을 빼앗을 때
	 * 'user-refdata' - 클라이언트가 기타 참고 데이터를 설정할 때
	 *
	*******************************************************************************/
	if (StrEqual(action, "game-connect", false))
	{
		/*************************************************
		 *
		 * [게임 내에 들어왔을 때]
		 *
		 * 전달 파라메터 없음
		 *
		**************************************************/
		Format(sSendParam, sizeof(sSendParam), "%d", dds_iUserMoney[client]);
	}
	else if (StrEqual(action, "game-disconnect", false))
	{
		/*************************************************
		 *
		 * [게임 밖으로 나갔을 때]
		 *
		 * 전달 파라메터 없음
		 *
		**************************************************/
		Format(sSendParam, sizeof(sSendParam), "%d", dds_iUserMoney[client]);
	}
	else if (StrEqual(action, "item-buy", false))
	{
		/*************************************************
		 *
		 * [메인 메뉴에서 아이템을 구매할 때]
		 *
		 * (0) - 아이템 종류 이름, (1) - 아이템 이름, (2) - 아이템 번호, (3) - 아이템 금액
		 *
		**************************************************/
		Format(sSendParam, sizeof(sSendParam), data);
	}
	else if (StrEqual(action, "item-use", false))
	{
		/*************************************************
		 *
		 * [아이템을 장착하였을 때]
		 *
		 * (0) - 아이템 종류 이름, (1) - 아이템 이름, (2) - 아이템 번호
		 *
		**************************************************/
		Format(sSendParam, sizeof(sSendParam), data);
	}
	else if (StrEqual(action, "item-cancel", false))
	{
		/*************************************************
		 *
		 * [아이템을 장착 해제하였을 때]
		 *
		 * (0) - 아이템 종류 이름, (1) - 아이템 이름, (2) - 아이템 번호
		 *
		**************************************************/
		Format(sSendParam, sizeof(sSendParam), data);
	}
	else if (StrEqual(action, "item-resell", false))
	{
		/*************************************************
		 *
		 * [아이템을 되팔았을 때]
		 *
		 * (0) - 아이템 종류 이름, (1) - 아이템 이름, (2) - 아이템 번호, (3) - 팔은 금액
		 *
		**************************************************/
		Format(sSendParam, sizeof(sSendParam), data);
	}
	else if (StrEqual(action, "item-gift", false))
	{
		/*************************************************
		 *
		 * [아이템을 선물하였을 때]
		 *
		 * (0) - 대상 이름, (1) - 대상 고유 번호, (2) - 아이템 종류 이름, (3) - 아이템 이름, (4) - 아이템 번호
		 *
		**************************************************/
		Format(sSendParam, sizeof(sSendParam), data);
	}
	else if (StrEqual(action, "item-drop", false))
	{
		/*************************************************
		 *
		 * [아이템을 버렸을 때]
		 *
		 * (0) - 아이템 종류 이름, (1) - 아이템 이름, (2) - 아이템 번호
		 *
		**************************************************/
		Format(sSendParam, sizeof(sSendParam), data);
	}
	else if (StrEqual(action, "money-up", false))
	{
		/*************************************************
		 *
		 * [금액이 증가될 때]
		 *
		 * (0) - 클라이언트 금액, (1) - 증가될 금액
		 *
		**************************************************/
		Format(sSendParam, sizeof(sSendParam), data);
	}
	else if (StrEqual(action, "money-down", false))
	{
		/*************************************************
		 *
		 * [금액이 내려갈 때]
		 *
		 * (0) - 클라이언트 금액, (1) - 내려갈 금액
		 *
		**************************************************/
		Format(sSendParam, sizeof(sSendParam), data);
	}
	else if (StrEqual(action, "money-gift", false))
	{
		/*************************************************
		 *
		 * [금액을 선물할 때]
		 *
		 * (0) - 대상 이름, (1) - 대상 고유 번호, (2) - 클라이언트 금액
		 *
		**************************************************/
		Format(sSendParam, sizeof(sSendParam), data);
	}
	else if (StrEqual(action, "money-give", false))
	{
		/*************************************************
		 *
		 * [금액을 줄 때]
		 *
		 * (0) - 대상 이름, (1) - 대상 고유 번호, (2) - 변동 금액
		 *
		**************************************************/
		Format(sSendParam, sizeof(sSendParam), data);
	}
	else if (StrEqual(action, "money-takeaway", false))
	{
		/*************************************************
		 *
		 * [금액을 빼앗을 때]
		 *
		 * (0) - 대상 이름, (1) - 대상 고유 번호, (2) - 변동 금액
		 *
		**************************************************/
		Format(sSendParam, sizeof(sSendParam), data);
	}
	else if (StrEqual(action, "item-give", false))
	{
		/*************************************************
		 *
		 * [아이템을 줄 때]
		 *
		 * (0) - 대상 이름, (1) - 대상 고유 번호, (2) - 아이템 종류 이름, (3) - 아이템 이름, (4) - 아이템 번호
		 *
		**************************************************/
		Format(sSendParam, sizeof(sSendParam), data);
	}
	else if (StrEqual(action, "item-takeaway", false))
	{
		/*************************************************
		 *
		 * [아이템을 줄 때]
		 *
		 * (0) - 대상 이름, (1) - 대상 고유 번호, (2) - 아이템 종류 이름, (3) - 아이템 이름, (4) - 아이템 번호
		 *
		**************************************************/
		Format(sSendParam, sizeof(sSendParam), data);
	}
	else if (StrEqual(action, "user-refdata", false))
	{
		/*************************************************
		 *
		 * [클라이언트가 기타 참고 데이터를 설정할 때]
		 *
		 * (0) - 구분 타입, (1) - 설정할 문자열
		 *
		**************************************************/
		Format(sSendParam, sizeof(sSendParam), data);
	}

	// 전 포워드 처리
	Forward_OnLogProcessPre(sClient_AuthId, action, sSendParam, GetTime(), sClient_IP);

	/*******************************
	 * 로그 생성
	********************************/
	// 오류 검출 생성
	ArrayList hMakeErrI = CreateArray(8);
	hMakeErrI.Push(client);
	hMakeErrI.Push(1100);
		
	// 쿼리 전송
	Format(sSendQuery, sizeof(sSendQuery), 
		"INSERT INTO `dds_log_data` (`idx`, `authid`, `action`, `setdata`, `thisdate`, `usrip`) VALUES (NULL, '%s', '%s', '%s', '%d', '%s')", 
		sClient_AuthId, action, sSendParam, GetTime(), sClient_IP);
	dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrI);

	// 후 포워드 처리
	Forward_OnLogProcessPost(sClient_AuthId, action, sSendParam, GetTime(), sClient_IP);
}


/**
 * SQL :: 초기화 및 SQL 데이터베이스에 있는 데이터 로드
 */
public void SQL_DDSDatabaseInit()
{
	/** 초기화 **/
	// 서버
	Init_ServerData();
	// 유저
	Init_UserData(0, 1);

	/** 데이터 로드 **/
	char sSendQuery[512];

	// 아이템 카테고리 로드
	Format(sSendQuery, sizeof(sSendQuery), "SELECT * FROM `dds_item_category` WHERE `status` = '1' ORDER BY `orderidx` ASC");
	dds_hSQLDatabase.Query(SQL_LoadItemCategory, sSendQuery, 0, DBPrio_High);
	// 아이템 목록 로드
	Format(sSendQuery, sizeof(sSendQuery), "SELECT * FROM `dds_item_list` WHERE `status` = '1' ORDER BY `ilidx` ASC");
	dds_hSQLDatabase.Query(SQL_LoadItemList, sSendQuery, 0, DBPrio_High);
	// ENV 목록 로드
	Format(sSendQuery, sizeof(sSendQuery), "SELECT * FROM `dds_env_list`");
	dds_hSQLDatabase.Query(SQL_LoadEnvList, sSendQuery, 0, DBPrio_High);
}


/**
 * 통계 :: 통계 시작
 *
 * @param type				종류
 */
public void Statis_Send(const char[] type)
{/*
	Handle cstis = curl_easy_init();
	if (cstis != null)
	{
		// 게임 주소 추출
		char sSVAdrs[64];
		GetConVarString(FindConVar("ip"), sSVAdrs, sizeof(sSVAdrs));

		// 값 설정
		char sSendPost[150];
		Format(sSendPost, sizeof(sSendPost), "c=%s&p=%s&a=%s&d=%s&t=%s&i=%s&v=%s", 
			"plugin", DDS_ENV_CORE_NAME, type, GetTime(), sSVAdrs, "", DDS_ENV_CORE_VERSION);

		// curl 설정
		// https://code.google.com/p/sourcemod-curl-extension/source/browse/curl/curl.h
		curl_easy_setopt_string(cstis, CURLOPT_URL, "");
		curl_easy_setopt_int(cstis, CURLOPT_POST, 1);
		curl_easy_setopt_string(cstis, CURLOPT_POSTFIELDS, sSendPost);
		curl_easy_perform_thread(cstis, Statis_OnSend);
	}*/
}

/**
 * 통계 :: 통계 수행 후
 *
 * @param hndl				curl 핸들
 * @param code				curl 상태
 */
public Statis_OnSend(Handle hndl, CURLcode code)
{/*
	delete hndl;
	hndl = null;*/
}


/**
 * 메뉴 :: 메인 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param args				기타
 */
public Action Menu_Main(int client, int args)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return Plugin_Continue;

	// SQL 데이터베이스가 활성화되어 있지 않다면 작동 안함
	if (!dds_bSQLStatus)
	{
		DDS_PrintToChat(client, "%t", "error sqlstatus server");
		return Plugin_Continue;
	}

	// 유저의 SQL 데이터베이스 상태가 활성화되어 있지 않다면 작동 안함
	if (!dds_bUserSQLStatus[client])
	{
		DDS_PrintToChat(client, "%t", "error sqlstatus user");
		return Plugin_Continue;
	}

	char buffer[256];
	Menu mMain = new Menu(Main_hdlMain);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n ", "menu common title");
	mMain.SetTitle(buffer);

	// '내 프로필'
	Format(buffer, sizeof(buffer), "%t", "menu main myprofile");
	mMain.AddItem("1", buffer);
	// '내 장착 아이템'
	Format(buffer, sizeof(buffer), "%t", "menu main mycuritem");
	mMain.AddItem("2", buffer);
	// '내 인벤토리'
	Format(buffer, sizeof(buffer), "%t", "menu main myinven");
	mMain.AddItem("3", buffer);
	// '아이템 구매'
	Format(buffer, sizeof(buffer), "%t", "menu main buyitem");
	mMain.AddItem("4", buffer);
	// '설정'
	Format(buffer, sizeof(buffer), "%t\n ", "menu main setting");
	mMain.AddItem("5", buffer);
	// '플러그인 정보'
	Format(buffer, sizeof(buffer), "%t", "menu main plugininfo");
	mMain.AddItem("9", buffer);

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);

	return Plugin_Continue;
}

/**
 * 메뉴 :: 프로필 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param action			행동 구분
 */
public void Menu_Profile(int client, const char[] action)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlProfile);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t\n ", "menu common title", "menu common curpos", "menu main myprofile");
	mMain.SetTitle(buffer);

	// 행동 구분
	if (StrEqual(action, "main-menu", false))
		mMain.ExitBackButton = true;

	// 필요 정보
	char sUsrName[32];
	char sUsrAuthId[20];

	GetClientName(client, sUsrName, sizeof(sUsrName));
	GetClientAuthId(client, AuthId_SteamID64, sUsrAuthId, sizeof(sUsrAuthId));

	Format(buffer, sizeof(buffer), 
		"%t\n \n%t: %s\n%t: %s\n%t: %d", 
		"menu myprofile introduce", "global nickname", sUsrName, "global authid", sUsrAuthId, "global money", dds_iUserMoney[client]);
	mMain.AddItem("1", buffer, ITEMDRAW_DISABLED);

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 내 장착 아이템 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 */
public void Menu_CurItem(int client)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlCurItem);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t\n ", "menu common title", "menu common curpos", "menu main mycuritem");
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 갯수 파악
	int count;

	// 정보 작성
	for (int i = 0; i <= dds_iItemCategoryCount; i++)
	{
		// '전체' 통과
		if (i == 0)	continue;

		/*** 환경 변수 준비 ***/
		char sGetEnv[128];

		/** 환경 변수 확인(아이템 종류단) **/
		/* 접근 관련 */
		SelectedStuffToString(dds_eItemCategoryList[i][ENV], "ENV_DDS_LIMIT_SHOW_LIST_CLASS", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (StrEqual(sGetEnv, "none", false)) // 허용된 것이 아무것도 없음
		{
			continue;
		}
		else if (!StrEqual(sGetEnv, "all", false)) // 코드로 구분되어 졌을 경우
		{
			// 빈칸 모두 제거
			ReplaceString(sGetEnv, sizeof(sGetEnv), " ", "", false);

			// 허용 등급 추출
			char[][] sTempClStr = new char[UCM_GetClassCount() + 1][8];
			ExplodeString(sGetEnv, ",", sTempClStr, UCM_GetClassCount() + 1, 8);

			// 갯수 파악
			int chkcount;

			// 검증
			for (int j = 0; j <= UCM_GetClassCount(); j++)
			{
				// 0은 생략
				if (j == 0)	continue;

				// 맞는 것이 없으면 패스
				if (StringToInt(sTempClStr[j]) != UCM_GetClientClass(client))	continue;

				chkcount++;
			}
			
			// 없으면 차단
			if (chkcount == 0)
			{
				continue;
			}
		}

		// 번호를 문자열로 치환
		char sTempIdx[4];
		IntToString(dds_eItemCategoryList[i][CODE], sTempIdx, sizeof(sTempIdx));

		// 클라이언트 국가에 따른 아이템과 종류 이름 추출
		char sCGName[40];
		char sItemName[32];
		SelectedGeoNameToString(client, dds_eItemCategoryList[i][NAME], sCGName, sizeof(sCGName));
		SelectedGeoNameToString(client, dds_eItemList[Find_GetItemListIndex(dds_iUserAppliedItem[client][i][ITEMIDX])][NAME], sItemName, sizeof(sItemName));

		// 장착되어 있지 않으면 '없음' 처리
		if (dds_iUserAppliedItem[client][i][ITEMIDX] == 0) Format(sItemName, sizeof(sItemName), "%t", "global none");

		// 메뉴 아이템 등록
		Format(buffer, sizeof(buffer), "%t %s %t: %s", "menu mycuritem applied", sCGName, "global item", sItemName);
		mMain.AddItem(sTempIdx, buffer);

		// 갯수 증가
		count++;

		#if defined _DEBUG_
		DDS_PrintToChat(client, "\x05:: DEBUG ::\x01 My CurItem Menu ~ CG (ID: %d, CateName: %s, ItemName: %s, Count: %d)", i, sCGName, sItemName, count);
		#endif
	}

	// 아이템 종류가 없을 때
	if (count == 0)
	{
		// '없음' 출력
		Format(buffer, sizeof(buffer), "%t", "global nothing");
		mMain.AddItem("0", buffer, ITEMDRAW_DISABLED);
	}

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 내 장착 아이템 메뉴-종류 출력
 *
 * @param db					데이터베이스 연결 핸들
 * @param results				결과 쿼리
 * @param error					오류 문자열
 * @param data					기타(0 - 클라이언트 인덱스, 1 - 아이템 종류 코드)
 */
public void Menu_CurItem_CateIn(Database db, DBResultSet results, const char[] error, any data)
{
	/******
	 * @param data				Handle / ArrayList
	 * 					0 - 클라이언트 인덱스(int), 1 - 아이템 종류 코드(int)
	 ******/
	// 타입 변환(*!*핸들 누수가 있는지?)
	ArrayList hData = view_as<ArrayList>(data);

	int client = hData.Get(0);
	int catecode = hData.Get(1);

	delete hData;

	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	// 쿼리 오류 검출
	if (db == null || error[0])
	{
		Log_CodeError(0, 1020, error);
		return;
	}

	// 클라이언트 국가에 따른 아이템 종류 이름 추출
	char sCGName[40];
	for (int i = 0; i <= dds_iItemCategoryCount; i++)
	{
		// '전체' 항목은 제외
		if (i == 0)	continue;

		// 선택한 아이템 종류 코드와 맞지 않는 경우는 제외
		if (catecode != dds_eItemCategoryList[i][CODE])	continue;

		SelectedGeoNameToString(client, dds_eItemCategoryList[i][NAME], sCGName, sizeof(sCGName));
		break;
	}

	// 메뉴 및 제목 설정
	char buffer[256];
	Menu mMain = new Menu(Main_hdlCurItem_CateIn);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t-%s\n ", "menu common title", "menu common curpos", "menu main mycuritem", sCGName);
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 갯수 파악
	int count;

	// 쿼리 결과
	while (results.MoreRows)
	{
		// 제시할 행이 없다면 통과
		if (!results.FetchRow())	continue;

		// 아이템 정보
		int iTmpDbIdx = results.FetchInt(0);
		int iTmpItIdx = results.FetchInt(2);
		int iTmpItAp = results.FetchInt(3);

		// 0번은 있을 수 없지만 혹시 모르므로 제외
		if (iTmpItIdx == 0)	continue;

		// '전체' 항목이 아니면서 선택한 아이템 종류가 아닌 아이템은 제외
		if ((catecode != dds_eItemList[Find_GetItemListIndex(iTmpItIdx)][CATECODE]) && catecode != 0)	continue;

		// 체크되는 아이템의 아이템 종류가 등록되어 있는 아이템 종류가 없는 경우는 제외
		// 이유: 유저가 가지고 있는 아이템 중 그에 맞는 아이템 종류가 활성화되지 않은 아이템 종류인 경우를 피하려는 것 때문
		bool bInCate = false;
		for (int i = 0; i <= dds_iItemCategoryCount; i++)
		{
			// '전체'는 제외
			if (i == 0)	continue;

			// 유효한지 파악
			if (dds_eItemList[Find_GetItemListIndex(iTmpItIdx)][CATECODE] == dds_eItemCategoryList[i][CODE])
			{
				bInCate = true;
				break;
			}
		}
		if (!bInCate)	continue;

		// 현재 장착하고 있으면 '장착 해제' 메뉴 생성
		if (count == 0)
		{
			if (dds_iUserAppliedItem[client][catecode][ITEMIDX] > 0)
			{
				// 번호를 문자열로 치환
				char sTempIdx[16];
				Format(sTempIdx, sizeof(sTempIdx), "%d||%d||%d", catecode, catecode, 0);

				// 메뉴 등록
				Format(buffer, sizeof(buffer), "%t", "menu mycuritem apply cancel");
				mMain.AddItem(sTempIdx, buffer);
			}
		}

		/*** 환경 변수 준비 ***/
		char sGetEnv[128];

		/** 환경 변수 확인(아이템 단) **/
		/* 접근 관련 */
		SelectedStuffToString(dds_eItemList[Find_GetItemListIndex(iTmpItIdx)][ENV], "ENV_DDS_LIMIT_SHOW_LIST_CLASS", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (StrEqual(sGetEnv, "none", false)) // 허용된 것이 아무것도 없음
		{
			continue;
		}
		else if (!StrEqual(sGetEnv, "all", false)) // 코드로 구분되어 졌을 경우
		{
			// 빈칸 모두 제거
			ReplaceString(sGetEnv, sizeof(sGetEnv), " ", "", false);

			// 허용 등급 추출
			char[][] sTempClStr = new char[UCM_GetClassCount() + 1][8];
			ExplodeString(sGetEnv, ",", sTempClStr, UCM_GetClassCount() + 1, 8);

			// 갯수 파악
			int chkcount;

			// 검증
			for (int i = 0; i <= UCM_GetClassCount(); i++)
			{
				// 0은 생략
				if (i == 0)	continue;

				// 맞는 것이 없으면 패스
				if (StringToInt(sTempClStr[i]) != UCM_GetClientClass(client))	continue;

				chkcount++;
			}
			
			// 없으면 차단
			if (chkcount == 0)
			{
				continue;
			}
		}

		// 번호를 문자열로 치환
		char sTempIdx[16];
		Format(sTempIdx, sizeof(sTempIdx), "%d||%d||%d", iTmpDbIdx, iTmpItIdx, 1);

		// 클라이언트 국가에 따른 아이템 종류 이름 추출(아이템 자체에서 판단)
		char sItemCGName[40];
		SelectedGeoNameToString(client, dds_eItemCategoryList[Find_GetItemCGListIndex(dds_eItemList[Find_GetItemListIndex(iTmpItIdx)][CATECODE])][NAME], sItemCGName, sizeof(sItemCGName));

		// 클라이언트 국가에 따른 아이템 이름 추출
		char sItemName[32];
		SelectedGeoNameToString(client, dds_eItemList[Find_GetItemListIndex(iTmpItIdx)][NAME], sItemName, sizeof(sItemName));

		// 아이템이 장착되어 있는지 작성
		char sApStr[16];
		Format(sApStr, sizeof(sApStr), "");
		if (iTmpItAp > 0)
			Format(sApStr, sizeof(sApStr), " - %t", "global applied");

		// 메뉴 아이템 등록
		Format(buffer, sizeof(buffer), "[%s] %s%s", sItemCGName, sItemName, sApStr);
		// 아이템을 장착하고 있는건 사용할 수 없게 처리
		if (iTmpItAp > 0)
			mMain.AddItem(sTempIdx, buffer, ITEMDRAW_DISABLED);
		else
			mMain.AddItem(sTempIdx, buffer);

		// 갯수 증가
		count++;

		#if defined _DEBUG_
		DDS_PrintToChat(client, "\x05:: DEBUG ::\x01 Inven-CateIn Menu ~ CG (CateCode: %d, ItemName: %s, ItemIdx: %d, Count: %d)", catecode, sItemName, iTmpItIdx, count);
		#endif
	}

	// 아이템이 없을 때
	if (count == 0)
	{
		// '없음' 출력
		Format(buffer, sizeof(buffer), "%t", "global nothing");
		mMain.AddItem("0", buffer, ITEMDRAW_DISABLED);
	}

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 내 인벤토리 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param args				기타
 */
public Action Menu_Inven(int client, int args)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return Plugin_Continue;

	// SQL 데이터베이스가 활성화되어 있지 않다면 작동 안함
	if (!dds_bSQLStatus)
	{
		DDS_PrintToChat(client, "%t", "error sqlstatus server");
		return Plugin_Continue;
	}

	// 유저의 SQL 데이터베이스 상태가 활성화되어 있지 않다면 작동 안함
	if (!dds_bUserSQLStatus[client])
	{
		DDS_PrintToChat(client, "%t", "error sqlstatus user");
		return Plugin_Continue;
	}

	char buffer[256];
	Menu mMain = new Menu(Main_hdlInven);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t\n ", "menu common title", "menu common curpos", "menu main myinven");
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 갯수 파악
	int count;

	// 정보 작성
	for (int i = 0; i <= dds_iItemCategoryCount; i++)
	{
		/** 환경 변수 확인(아이템 종류단) **/
		/* 접근 관련 */
		if (i > 0)
		{
			/*** 환경 변수 준비 ***/
			char sGetEnv[128];

			/** 환경 변수 확인(아이템 종류단) **/
			/* 접근 관련 */
			SelectedStuffToString(dds_eItemCategoryList[i][ENV], "ENV_DDS_LIMIT_SHOW_LIST_CLASS", "||", ":", sGetEnv, sizeof(sGetEnv));
			if (StrEqual(sGetEnv, "none", false)) // 허용된 것이 아무것도 없음
			{
				continue;
			}
			else if (!StrEqual(sGetEnv, "all", false)) // 코드로 구분되어 졌을 경우
			{
				// 빈칸 모두 제거
				ReplaceString(sGetEnv, sizeof(sGetEnv), " ", "", false);

				// 허용 등급 추출
				char[][] sTempClStr = new char[UCM_GetClassCount() + 1][8];
				ExplodeString(sGetEnv, ",", sTempClStr, UCM_GetClassCount() + 1, 8);

				// 갯수 파악
				int chkcount;

				// 검증
				for (int j = 0; j <= UCM_GetClassCount(); j++)
				{
					// 0은 생략
					if (j == 0)	continue;

					// 맞는 것이 없으면 패스
					if (StringToInt(sTempClStr[j]) != UCM_GetClientClass(client))	continue;

					chkcount++;
				}
				
				// 없으면 차단
				if (chkcount == 0)
				{
					continue;
				}
			}
		}

		// 번호를 문자열로 치환
		char sTempIdx[4];
		IntToString(dds_eItemCategoryList[i][CODE], sTempIdx, sizeof(sTempIdx));

		// 클라이언트 국가에 따른 아이템 종류 이름 추출
		char sCGName[40];
		SelectedGeoNameToString(client, dds_eItemCategoryList[i][NAME], sCGName, sizeof(sCGName));

		// 메뉴 아이템 등록
		Format(buffer, sizeof(buffer), "%s %t", sCGName, "global item");
		mMain.AddItem(sTempIdx, buffer);

		// 갯수 증가
		count++;

		#if defined _DEBUG_
		DDS_PrintToChat(client, "\x05:: DEBUG ::\x01 My Inven Menu ~ CG (ID: %d, CateName: %s, Count: %d)", i, sCGName, count);
		#endif
	}

	// 아이템 종류가 없을 때
	if (count == 0)
	{
		// '없음' 출력
		Format(buffer, sizeof(buffer), "%t", "global nothing");
		mMain.AddItem("0", buffer, ITEMDRAW_DISABLED);
	}

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);

	return Plugin_Continue;
}

/**
 * 메뉴 :: 내 인벤토리-종류 세부 메뉴 출력
 *
 * @param db					데이터베이스 연결 핸들
 * @param results				결과 쿼리
 * @param error					오류 문자열
 * @param data					기타(0 - 클라이언트 인덱스, 1 - 아이템 종류 코드)
 */
public void Menu_Inven_CateIn(Database db, DBResultSet results, const char[] error, any data)
{
	/******
	 * @param data				Handle / ArrayList
	 * 					0 - 클라이언트 인덱스(int), 1 - 아이템 종류 코드(int)
	 ******/
	// 타입 변환(*!*핸들 누수가 있는지?)
	ArrayList hData = view_as<ArrayList>(data);

	int client = hData.Get(0);
	int catecode = hData.Get(1);

	delete hData;

	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	// 쿼리 오류 검출
	if (db == null || error[0])
	{
		Log_CodeError(0, 1021, error);
		return;
	}

	// 클라이언트 국가에 따른 아이템 종류 이름 추출
	char sCGName[40];
	for (int i = 0; i <= dds_iItemCategoryCount; i++)
	{
		if (catecode != dds_eItemCategoryList[i][CODE])	continue;

		SelectedGeoNameToString(client, dds_eItemCategoryList[i][NAME], sCGName, sizeof(sCGName));
		break;
	}

	// 메뉴 및 제목 설정
	char buffer[256];
	Menu mMain = new Menu(Main_hdlInven_CateIn);

	Format(buffer, sizeof(buffer), "%t\n%t: %t-%s\n ", "menu common title", "menu common curpos", "menu main myinven", sCGName);
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 갯수 파악
	int count;

	// 쿼리 결과
	while (results.MoreRows)
	{
		// 제시할 행이 없다면 통과
		if (!results.FetchRow())	continue;

		// 아이템 정보
		int iTmpDbIdx = results.FetchInt(0);
		int iTmpItIdx = results.FetchInt(2);
		int iTmpItAp = results.FetchInt(3);

		// 0번은 있을 수 없지만 혹시 모르므로 제외
		if (iTmpItIdx == 0)	continue;

		// '전체' 항목이 아니면서 선택한 아이템 종류가 아닌 아이템은 제외
		if ((catecode != dds_eItemList[Find_GetItemListIndex(iTmpItIdx)][CATECODE]) && catecode != 0)	continue;

		// 체크되는 아이템의 아이템 종류가 등록되어 있는 아이템 종류가 없는 경우는 제외
		// 이유: 유저가 가지고 있는 아이템 중 그에 맞는 아이템 종류가 활성화되지 않은 아이템 종류인 경우를 피하려는 것 때문
		bool bInCate = false;
		for (int i = 0; i <= dds_iItemCategoryCount; i++)
		{
			// '전체'는 제외
			if (i == 0)	continue;

			// 유효한지 파악
			if (dds_eItemList[Find_GetItemListIndex(iTmpItIdx)][CATECODE] == dds_eItemCategoryList[i][CODE])
			{
				bInCate = true;
				break;
			}
		}
		if (!bInCate)	continue;

		/*** 환경 변수 준비 ***/
		char sGetEnv[128];

		/** 환경 변수 확인(아이템 단) **/
		/* 접근 관련 */
		SelectedStuffToString(dds_eItemList[Find_GetItemListIndex(iTmpItIdx)][ENV], "ENV_DDS_LIMIT_SHOW_LIST_CLASS", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (StrEqual(sGetEnv, "none", false)) // 허용된 것이 아무것도 없음
		{
			continue;
		}
		else if (!StrEqual(sGetEnv, "all", false)) // 코드로 구분되어 졌을 경우
		{
			// 빈칸 모두 제거
			ReplaceString(sGetEnv, sizeof(sGetEnv), " ", "", false);

			// 허용 등급 추출
			char[][] sTempClStr = new char[UCM_GetClassCount() + 1][8];
			ExplodeString(sGetEnv, ",", sTempClStr, UCM_GetClassCount() + 1, 8);

			// 갯수 파악
			int chkcount;

			// 검증
			for (int i = 0; i <= UCM_GetClassCount(); i++)
			{
				// 0은 생략
				if (i == 0)	continue;

				// 맞는 것이 없으면 패스
				if (StringToInt(sTempClStr[i]) != UCM_GetClientClass(client))	continue;

				chkcount++;
			}
			
			// 없으면 차단
			if (chkcount == 0)
			{
				continue;
			}
		}

		// 번호를 문자열로 치환
		char sTempIdx[16];
		Format(sTempIdx, sizeof(sTempIdx), "%d||%d", iTmpDbIdx, iTmpItIdx);

		// 클라이언트 국가에 따른 아이템 종류 이름 추출(아이템 자체에서 판단)
		char sItemCGName[40];
		SelectedGeoNameToString(client, dds_eItemCategoryList[Find_GetItemCGListIndex(dds_eItemList[Find_GetItemListIndex(iTmpItIdx)][CATECODE])][NAME], sItemCGName, sizeof(sItemCGName));

		// 클라이언트 국가에 따른 아이템 이름 추출
		char sItemName[32];
		SelectedGeoNameToString(client, dds_eItemList[Find_GetItemListIndex(iTmpItIdx)][NAME], sItemName, sizeof(sItemName));

		// 아이템이 장착되어 있는지 작성
		char sApStr[16];
		Format(sApStr, sizeof(sApStr), "");
		if (iTmpItAp > 0)
			Format(sApStr, sizeof(sApStr), " - %t", "global applied");

		// 메뉴 아이템 등록
		Format(buffer, sizeof(buffer), "[%s] %s%s", sItemCGName, sItemName, sApStr);
		// 아이템을 장착하고 있는건 사용할 수 없게 처리
		if (iTmpItAp > 0)
			mMain.AddItem(sTempIdx, buffer, ITEMDRAW_DISABLED);
		else
			mMain.AddItem(sTempIdx, buffer);

		// 갯수 증가
		count++;

		#if defined _DEBUG_
		DDS_PrintToChat(client, "\x05:: DEBUG ::\x01 Inven-CateIn Menu ~ CG (CateCode: %d, ItemName: %s, ItemIdx: %d, Count: %d)", catecode, sItemName, iTmpItIdx, count);
		#endif
	}

	// 아이템이 없을 때
	if (count == 0)
	{
		// '없음' 출력
		Format(buffer, sizeof(buffer), "%t", "global nothing");
		mMain.AddItem("0", buffer, ITEMDRAW_DISABLED);
	}

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 내 인벤토리-정보 세부 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param dataidx			데이터베이스 인덱스 번호
 * @param itemidx			아이템 번호
 */
public void Menu_Inven_ItemDetail(int client, int dataidx, int itemidx)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlInven_ItemDetail);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t-%t\n ", "menu common title", "menu common curpos", "menu main myinven", "menu main myinven check");
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 전달 파라메터 기초 생성
	char sParam[16];

	// 클라이언트 국가에 따른 아이템 종류 이름 추출
	char sItemName[32];
	SelectedGeoNameToString(client, dds_eItemList[Find_GetItemListIndex(itemidx)][NAME], sItemName, sizeof(sItemName));

	// 메뉴 아이템 등록
	Format(buffer, sizeof(buffer), "%t", "global use");
	Format(sParam, sizeof(sParam), "%d||%d||%d", dataidx, itemidx, 1);
	mMain.AddItem(sParam, buffer);
	Format(buffer, sizeof(buffer), "%t", "global resell");
	Format(sParam, sizeof(sParam), "%d||%d||%d", dataidx, itemidx, 2);
	mMain.AddItem(sParam, buffer);
	Format(buffer, sizeof(buffer), "%t", "global gift");
	Format(sParam, sizeof(sParam), "%d||%d||%d", dataidx, itemidx, 3);
	mMain.AddItem(sParam, buffer);
	Format(buffer, sizeof(buffer), "%t\n ", "global drop");
	Format(sParam, sizeof(sParam), "%d||%d||%d", dataidx, itemidx, 4);
	mMain.AddItem(sParam, buffer);
	Format(buffer, sizeof(buffer), "%t\n \n%t: %s\n%t: %d", "menu myinven info", "global name", sItemName, "global money", dds_eItemList[Find_GetItemListIndex(itemidx)][MONEY]);
	mMain.AddItem("0", buffer, ITEMDRAW_DISABLED);

	#if defined _DEBUG_
	DDS_PrintToChat(client, "\x05:: DEBUG ::\x01 Inven-ItemDetail Menu ~ CG (ItemIdx: %d, ItemName: %s)", itemidx, sItemName);
	#endif

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 아이템 구매 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 */
public void Menu_BuyItem(int client)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlBuyItem);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t\n ", "menu common title", "menu common curpos", "menu main buyitem");
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 갯수 파악
	int count;

	// 정보 작성
	for (int i = 0; i <= dds_iItemCategoryCount; i++)
	{
		if (i > 0)
		{
			/*** 환경 변수 준비 ***/
			char sGetEnv[128];

			/** 환경 변수 확인(아이템 종류단) **/
			/* 접근 관련 */
			SelectedStuffToString(dds_eItemCategoryList[i][ENV], "ENV_DDS_LIMIT_SHOW_LIST_CLASS", "||", ":", sGetEnv, sizeof(sGetEnv));
			if (StrEqual(sGetEnv, "none", false)) // 허용된 것이 아무것도 없음
			{
				continue;
			}
			else if (!StrEqual(sGetEnv, "all", false)) // 코드로 구분되어 졌을 경우
			{
				// 빈칸 모두 제거
				ReplaceString(sGetEnv, sizeof(sGetEnv), " ", "", false);

				// 허용 등급 추출
				char[][] sTempClStr = new char[UCM_GetClassCount() + 1][8];
				ExplodeString(sGetEnv, ",", sTempClStr, UCM_GetClassCount() + 1, 8);

				// 갯수 파악
				int chkcount;

				// 검증
				for (int j = 0; j <= UCM_GetClassCount(); j++)
				{
					// 0은 생략
					if (j == 0)	continue;

					// 맞는 것이 없으면 패스
					if (StringToInt(sTempClStr[j]) != UCM_GetClientClass(client))	continue;

					chkcount++;
				}
					
				// 없으면 차단
				if (chkcount == 0)
				{
					continue;
				}
			}
		}

		// 번호를 문자열로 치환
		char sTempIdx[4];
		IntToString(dds_eItemCategoryList[i][CODE], sTempIdx, sizeof(sTempIdx));

		// 클라이언트 국가에 따른 아이템 종류 이름 추출
		char sCGName[40];
		SelectedGeoNameToString(client, dds_eItemCategoryList[i][NAME], sCGName, sizeof(sCGName));

		// 메뉴 아이템 등록
		Format(buffer, sizeof(buffer), "%s %t", sCGName, "global item");
		mMain.AddItem(sTempIdx, buffer);

		// 갯수 증가
		count++;

		#if defined _DEBUG_
		DDS_PrintToChat(client, "\x05:: DEBUG ::\x01 Buy Item Menu ~ CG (ID: %d, CateName: %s, Count: %d)", i, sCGName, count);
		#endif
	}

	// 아이템 종류가 없을 때
	if (count == 0)
	{
		// '없음' 출력
		Format(buffer, sizeof(buffer), "%t", "global nothing");
		mMain.AddItem("0", buffer, ITEMDRAW_DISABLED);
	}

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 아이템 구매-종류 세부 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param catecode			아이템 종류 코드
 */
public void Menu_BuyItem_CateIn(int client, int catecode)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlBuyItem_CateIn);

	// 클라이언트 국가에 따른 아이템 종류 이름 추출
	char sCGName[40];
	for (int i = 0; i <= dds_iItemCategoryCount; i++)
	{
		if (catecode != dds_eItemCategoryList[i][CODE])	continue;

		SelectedGeoNameToString(client, dds_eItemCategoryList[i][NAME], sCGName, sizeof(sCGName));
		break;
	}

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t-%s\n ", "menu common title", "menu common curpos", "menu main buyitem", sCGName);
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 갯수 파악
	int count;

	// 정보 작성
	for (int i = 0; i <= dds_iItemCount; i++)
	{
		// 0번은 제외
		if (i == 0)	continue;

		// '전체' 항목이 아니면서 선택한 아이템 종류가 아닌 아이템은 제외
		if ((catecode != dds_eItemList[i][CATECODE]) && catecode != 0)	continue;

		// 체크되는 아이템의 아이템 종류가 등록되어 있는 아이템 종류가 없는 경우는 제외
		// 이유: 등록되어 있는 아이템 중 그에 맞는 아이템 종류가 활성화되지 않은 아이템 종류인 경우를 피하려는 것 때문
		bool bInCate = false;
		for (int k = 0; k <= dds_iItemCategoryCount; k++)
		{
			// '전체'는 제외
			if (k == 0)	continue;

			// 유효한지 파악
			if (dds_eItemList[i][CATECODE] == dds_eItemCategoryList[k][CODE])
			{
				bInCate = true;
				break;
			}
		}
		if (!bInCate)	continue;

		/*** 환경 변수 준비 ***/
		char sGetEnv[128];

		/** 환경 변수 확인(아이템 단) **/
		/* 접근 관련 */
		SelectedStuffToString(dds_eItemList[i][ENV], "ENV_DDS_LIMIT_SHOW_LIST_CLASS", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (StrEqual(sGetEnv, "none", false)) // 허용된 것이 아무것도 없음
		{
			continue;
		}
		else if (!StrEqual(sGetEnv, "all", false)) // 코드로 구분되어 졌을 경우
		{
			// 빈칸 모두 제거
			ReplaceString(sGetEnv, sizeof(sGetEnv), " ", "", false);

			// 허용 등급 추출
			char[][] sTempClStr = new char[UCM_GetClassCount() + 1][8];
			ExplodeString(sGetEnv, ",", sTempClStr, UCM_GetClassCount() + 1, 8);

			// 갯수 파악
			int chkcount;

			// 검증
			for (int j = 0; j <= UCM_GetClassCount(); j++)
			{
				// 0은 생략
				if (j == 0)	continue;

				// 맞는 것이 없으면 패스
				if (StringToInt(sTempClStr[j]) != UCM_GetClientClass(client))	continue;

				chkcount++;
			}
			
			// 없으면 차단
			if (chkcount == 0)
			{
				continue;
			}
		}

		// 번호를 문자열로 치환
		char sTempIdx[8];
		IntToString(dds_eItemList[i][INDEX], sTempIdx, sizeof(sTempIdx));

		// 클라이언트 국가에 따른 아이템 종류 이름 추출(아이템 자체에서 판단)
		char sItemCGName[40];
		SelectedGeoNameToString(client, dds_eItemCategoryList[Find_GetItemCGListIndex(dds_eItemList[i][CATECODE])][NAME], sItemCGName, sizeof(sItemCGName));

		// 클라이언트 국가에 따른 아이템 이름 추출
		char sItemName[32];
		SelectedGeoNameToString(client, dds_eItemList[i][NAME], sItemName, sizeof(sItemName));

		// 메뉴 아이템 등록
		Format(buffer, sizeof(buffer), "[%s] %s - %d %t", sItemCGName, sItemName, dds_eItemList[i][MONEY], "global money");
		mMain.AddItem(sTempIdx, buffer);

		// 갯수 증가
		count++;

		#if defined _DEBUG_
		DDS_PrintToChat(client, "\x05:: DEBUG ::\x01 Buy Item-CateIn Menu ~ CG (CateCode: %d, ItemName: %s, ItemIdx: %d, Count: %d)", catecode, sItemName, i, count);
		#endif
	}

	// 아이템 종류가 없을 때
	if (count == 0)
	{
		// '없음' 출력
		Format(buffer, sizeof(buffer), "%t", "global nothing");
		mMain.AddItem("0", buffer, ITEMDRAW_DISABLED);
	}

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 아이템 구매-정보 세부 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param itemidx			아이템 번호
 */
public void Menu_BuyItem_ItemDetail(int client, int itemidx)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlBuyItem_ItemDetail);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t-%t\n ", "menu common title", "menu common curpos", "menu main buyitem", "menu main buyitem check");
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 전달 파라메터 기초 생성
	char sParam[16];

	// 클라이언트 국가에 따른 아이템 종류 이름 추출
	char sItemName[32];
	SelectedGeoNameToString(client, dds_eItemList[Find_GetItemListIndex(itemidx)][NAME], sItemName, sizeof(sItemName));

	// 메뉴 아이템 등록
	Format(buffer, sizeof(buffer), "%t", "global confirm");
	Format(sParam, sizeof(sParam), "%d||%d||%d", itemidx, dds_eItemList[Find_GetItemListIndex(itemidx)][CATECODE], 1);
	mMain.AddItem(sParam, buffer);
	Format(buffer, sizeof(buffer), "%t\n ", "global cancel");
	Format(sParam, sizeof(sParam), "%d||%d||%d", itemidx, dds_eItemList[Find_GetItemListIndex(itemidx)][CATECODE], 2);
	mMain.AddItem(sParam, buffer);
	Format(buffer, sizeof(buffer), "%t\n \n%t: %s\n%t: %d", "menu buyitem willbuy", "global name", sItemName, "global money", dds_eItemList[Find_GetItemListIndex(itemidx)][MONEY]);
	mMain.AddItem("0", buffer, ITEMDRAW_DISABLED);

	#if defined _DEBUG_
	DDS_PrintToChat(client, "\x05:: DEBUG ::\x01 Buy Item-ItemDetail Menu ~ CG (ItemIdx: %d, ItemName: %s)", itemidx, sItemName);
	#endif

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 설정 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 */
public void Menu_Setting(int client)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlSetting);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t\n ", "menu common title", "menu common curpos", "menu main setting");
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 메뉴 아이템 등록
	Format(buffer, sizeof(buffer), "%t", "menu setting system");
	mMain.AddItem("1", buffer);
	Format(buffer, sizeof(buffer), "%t", "menu setting item");
	mMain.AddItem("2", buffer);

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 설정-시스템 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 */
public void Menu_Setting_System(int client)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlSetting_System);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t\n ", "menu common title", "menu common curpos", "menu setting system");
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 메뉴 아이템 등록
	Format(buffer, sizeof(buffer), "%t", "global nothing");
	mMain.AddItem("1", buffer, ITEMDRAW_DISABLED);

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 설정-아이템 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 */
public void Menu_Setting_Item(int client)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlSetting_Item);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t\n ", "menu common title", "menu common curpos", "menu setting item");
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 갯수 파악
	int count;

	// 정보 작성
	for (int i = 0; i <= dds_iItemCategoryCount; i++)
	{
		// '전체' 통과
		if (i == 0)	continue;

		/*** 환경 변수 준비 ***/
		char sGetEnv[128];

		/** 환경 변수 확인(아이템 종류단) **/
		/* 접근 관련 */
		SelectedStuffToString(dds_eItemCategoryList[i][ENV], "ENV_DDS_LIMIT_SHOW_LIST_CLASS", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (StrEqual(sGetEnv, "none", false)) // 허용된 것이 아무것도 없음
		{
			continue;
		}
		else if (!StrEqual(sGetEnv, "all", false)) // 코드로 구분되어 졌을 경우
		{
			// 빈칸 모두 제거
			ReplaceString(sGetEnv, sizeof(sGetEnv), " ", "", false);

			// 허용 등급 추출
			char[][] sTempClStr = new char[UCM_GetClassCount() + 1][8];
			ExplodeString(sGetEnv, ",", sTempClStr, UCM_GetClassCount() + 1, 8);

			// 갯수 파악
			int chkcount;

			// 검증
			for (int j = 0; j <= UCM_GetClassCount(); j++)
			{
				// 0은 생략
				if (j == 0)	continue;

				// 맞는 것이 없으면 패스
				if (StringToInt(sTempClStr[j]) != UCM_GetClientClass(client))	continue;

				chkcount++;
			}
				
			// 없으면 차단
			if (chkcount == 0)
			{
				continue;
			}
		}
		
		// 번호를 문자열로 치환
		char sTempIdx[4];
		IntToString(i, sTempIdx, sizeof(sTempIdx));

		// 클라이언트 국가에 따른 아이템 종류 이름 추출
		char sCGName[40];
		SelectedGeoNameToString(client, dds_eItemCategoryList[i][NAME], sCGName, sizeof(sCGName));

		// 활성화 판단
		char sStatus[16];
		if (dds_eUserItemCGStatus[client][i][VALUE])
			Format(sStatus, sizeof(sStatus), "%t", "menu setting status active");
		else
			Format(sStatus, sizeof(sStatus), "%t", "menu setting status inactive");

		// 메뉴 아이템 등록
		Format(buffer, sizeof(buffer), "%s: %s", sCGName, sStatus);
		mMain.AddItem(sTempIdx, buffer);

		// 갯수 증가
		count++;

		#if defined _DEBUG_
		DDS_PrintToChat(client, "\x05:: DEBUG ::\x01 Setting-Item Menu ~ CG (CateCode: %d, CateName: %s, Count: %d, Value: %s)", dds_eItemCategoryList[i][CODE], sCGName, count, sStatus);
		#endif
	}

	// 아이템 종류가 없을 때
	if (count == 0)
	{
		// '없음' 출력
		Format(buffer, sizeof(buffer), "%t", "global nothing");
		mMain.AddItem("0", buffer, ITEMDRAW_DISABLED);
	}

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 플러그인 정보 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 */
public void Menu_PluginInfo(int client)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlPluginInfo);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t\n ", "menu common title", "menu common curpos", "menu main plugininfo");
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 메뉴 아이템 등록
	Format(buffer, sizeof(buffer), "%t", "menu plugininfo cmd");
	mMain.AddItem("1", buffer);
	Format(buffer, sizeof(buffer), "%t", "menu plugininfo author");
	mMain.AddItem("2", buffer);
	Format(buffer, sizeof(buffer), "%t", "menu plugininfo license");
	mMain.AddItem("3", buffer);

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 플러그인 정보-세부 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 */
public void Menu_PluginInfo_Detail(int client, int select)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlPluginInfo_Detail);

	// 세부 제목 설정
	char sDetailTitle[32];
	switch (select)
	{
		case 1:
		{
			Format(sDetailTitle, sizeof(sDetailTitle), "%t", "menu plugininfo cmd");
		}
		case 2:
		{
			Format(sDetailTitle, sizeof(sDetailTitle), "%t", "menu plugininfo author");
		}
		case 3:
		{
			Format(sDetailTitle, sizeof(sDetailTitle), "%t", "menu plugininfo license");
		}
	}

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %s\n ", "menu common title", "menu common curpos", sDetailTitle);
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 메뉴 아이템 등록
	switch (select)
	{
		case 1:
		{
			// 명령어 정보
			// 번역 준비
			char sCmdTrans[32];
			Format(sCmdTrans, sizeof(sCmdTrans), "%t", "command main menu");
			Format(buffer, sizeof(buffer), "!%s: %t", sCmdTrans, "menu plugininfo cmd desc main");
			mMain.AddItem("1", buffer);
			Format(sCmdTrans, sizeof(sCmdTrans), "%t", "command gift");
			Format(buffer, sizeof(buffer), "!%s: %t", sCmdTrans, "menu plugininfo cmd desc gift");
			mMain.AddItem("2", buffer);
		}
		case 2:
		{
			// 개발자 정보
			Format(buffer, sizeof(buffer), "%s - v%s\n ", DDS_ENV_CORE_NAME, DDS_ENV_CORE_VERSION);
			mMain.AddItem("1", buffer);
			Format(buffer, sizeof(buffer), "Made By. Eakgnarok");
			mMain.AddItem("2", buffer);
		}
		case 3:
		{
			// 저작권 정보
			Format(buffer, sizeof(buffer), "GNU General Public License 3 (GNU GPL v3)\n ");
			mMain.AddItem("1", buffer);
			Format(buffer, sizeof(buffer), "%t: http://www.gnu.org/licenses/", "menu plugininfo license detail");
			mMain.AddItem("2", buffer);
		}
	}

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 아이템 선물-대상 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param data				추가 파라메터
 */
public void Menu_ItemGift(int client, const char[] data)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlItemGift);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t-%t\n ", "menu common title", "menu common curpos", "menu itemgift", "global target");
	mMain.SetTitle(buffer);

	// 전달 파라메터 등록
	char sSendParam[16];

	// 갯수 파악
	int count;

	// 메뉴 아이템 등록
	for (int i = 0; i < MaxClients; i++)
	{
		// 서버는 통과
		if (i == 0)	continue;

		// 게임 내에 없으면 통과
		if (!IsClientInGame(i))	continue;

		// 봇이면 통과
		if (IsFakeClient(i))	continue;

		// 인증이 되어 있지 않으면 통과
		if (!IsClientAuthorized(i))	continue;

		// 본인은 통과
		if (i == client)	continue;

		Format(buffer, sizeof(buffer), "%N", i);
		Format(sSendParam, sizeof(sSendParam), "%d||%s", GetClientUserId(i), data);
		mMain.AddItem(sSendParam, buffer);

		// 갯수 증가
		count++;
	}

	// 유저가 없을 때
	if (count == 0)
	{
		// '없음' 출력
		Format(buffer, sizeof(buffer), "%t", "global nothing");
		mMain.AddItem("0", buffer, ITEMDRAW_DISABLED);
	}

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 데이터베이스 초기화 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 */
public void Menu_InitDatabase(int client)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlInitDatabase);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t\n ", "menu common title", "menu common curpos", "menu initdatabase");
	mMain.SetTitle(buffer);

	// 메뉴 등록
	Format(buffer, sizeof(buffer), "%t", "menu initdatabase player");
	mMain.AddItem("1", buffer);
	Format(buffer, sizeof(buffer), "%t", "menu initdatabase all");
	mMain.AddItem("2", buffer);

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 데이터베이스 초기화-경고 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param action			행동 구분
 */
public void Menu_InitDatabase_Warn(int client, int action)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlInitDatabase_Warn);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t-%t\n ", "menu common title", "menu common curpos", "menu initdatabase", "global waring");
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 파라메터 준비
	char sSendParam[24];

	// 메뉴 등록
	Format(buffer, sizeof(buffer), "%t", "global confirm");
	Format(sSendParam, sizeof(sSendParam), "%d||%d", action, 1);
	mMain.AddItem(sSendParam, buffer);
	Format(buffer, sizeof(buffer), "%t\n ", "global cancel");
	Format(sSendParam, sizeof(sSendParam), "%d||%d", action, 2);
	mMain.AddItem(sSendParam, buffer);
	switch (action)
	{
		case 1:
		{
			// 유저
			Format(buffer, sizeof(buffer), 
				"%t\n \n%t\n \n%t: %t", 
				"menu initdatabase desc", "menu initdatabase descmore", "menu initdatabase process", "menu initdatabase player"
			);
			mMain.AddItem("", buffer, ITEMDRAW_DISABLED);
		}
		case 2:
		{
			// 모두
			Format(buffer, sizeof(buffer), 
				"%t\n \n%t\n%t\n \n%t: %t", 
				"menu initdatabase desc", "menu initdatabase descmore", "menu initdatabase critical", "menu initdatabase process", "menu initdatabase all"
			);
			mMain.AddItem("", buffer, ITEMDRAW_DISABLED);
		}
	}

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 아이템 주기 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 */
public void Menu_ItemGive(int client)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlItemGive);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t\n ", "menu common title", "menu common curpos", "menu itemgive");
	mMain.SetTitle(buffer);

	// 갯수 파악
	int count;

	// 정보 작성
	for (int i = 0; i <= dds_iItemCategoryCount; i++)
	{
		if (i > 0)
		{
			/*** 환경 변수 준비 ***/
			char sGetEnv[128];

			/** 환경 변수 확인(아이템 종류단) **/
			/* 접근 관련 */
			SelectedStuffToString(dds_eItemCategoryList[i][ENV], "ENV_DDS_LIMIT_SHOW_LIST_CLASS", "||", ":", sGetEnv, sizeof(sGetEnv));
			if (StrEqual(sGetEnv, "none", false)) // 허용된 것이 아무것도 없음
			{
				continue;
			}
			else if (!StrEqual(sGetEnv, "all", false)) // 코드로 구분되어 졌을 경우
			{
				// 빈칸 모두 제거
				ReplaceString(sGetEnv, sizeof(sGetEnv), " ", "", false);

				// 허용 등급 추출
				char[][] sTempClStr = new char[UCM_GetClassCount() + 1][8];
				ExplodeString(sGetEnv, ",", sTempClStr, UCM_GetClassCount() + 1, 8);

				// 갯수 파악
				int chkcount;

				// 검증
				for (int j = 0; j <= UCM_GetClassCount(); j++)
				{
					// 0은 생략
					if (j == 0)	continue;

					// 맞는 것이 없으면 패스
					if (StringToInt(sTempClStr[j]) != UCM_GetClientClass(client))	continue;

					chkcount++;
				}
					
				// 없으면 차단
				if (chkcount == 0)
				{
					continue;
				}
			}
		}

		// 번호를 문자열로 치환
		char sTempIdx[4];
		IntToString(dds_eItemCategoryList[i][CODE], sTempIdx, sizeof(sTempIdx));

		// 클라이언트 국가에 따른 아이템 종류 이름 추출
		char sCGName[40];
		SelectedGeoNameToString(client, dds_eItemCategoryList[i][NAME], sCGName, sizeof(sCGName));

		// 메뉴 아이템 등록
		Format(buffer, sizeof(buffer), "%s %t", sCGName, "global item");
		mMain.AddItem(sTempIdx, buffer);

		// 갯수 증가
		count++;

		#if defined _DEBUG_
		DDS_PrintToChat(client, "\x05:: DEBUG ::\x01 Item Give Menu ~ CG (ID: %d, CateName: %s, Count: %d)", i, sCGName, count);
		#endif
	}

	// 아이템 종류가 없을 때
	if (count == 0)
	{
		// '없음' 출력
		Format(buffer, sizeof(buffer), "%t", "global nothing");
		mMain.AddItem("0", buffer, ITEMDRAW_DISABLED);
	}

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 아이템 주기-종류 세부 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param catecode			아이템 종류 코드
 */
public void Menu_ItemGive_CateIn(int client, int catecode)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlItemGive_CateIn);

	// 클라이언트 국가에 따른 아이템 종류 이름 추출
	char sCGName[40];
	for (int i = 0; i <= dds_iItemCategoryCount; i++)
	{
		if (catecode != dds_eItemCategoryList[i][CODE])	continue;

		SelectedGeoNameToString(client, dds_eItemCategoryList[i][NAME], sCGName, sizeof(sCGName));
		break;
	}

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t-%s\n ", "menu common title", "menu common curpos", "menu itemgive", sCGName);
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 갯수 파악
	int count;

	// 정보 작성
	for (int i = 0; i <= dds_iItemCount; i++)
	{
		// 0번은 제외
		if (i == 0)	continue;

		// '전체' 항목이 아니면서 선택한 아이템 종류가 아닌 아이템은 제외
		if ((catecode != dds_eItemList[i][CATECODE]) && catecode != 0)	continue;

		// 체크되는 아이템의 아이템 종류가 등록되어 있는 아이템 종류가 없는 경우는 제외
		// 이유: 등록되어 있는 아이템 중 그에 맞는 아이템 종류가 활성화되지 않은 아이템 종류인 경우를 피하려는 것 때문
		bool bInCate = false;
		for (int k = 0; k <= dds_iItemCategoryCount; k++)
		{
			// '전체'는 제외
			if (k == 0)	continue;

			// 유효한지 파악
			if (dds_eItemList[i][CATECODE] == dds_eItemCategoryList[k][CODE])
			{
				bInCate = true;
				break;
			}
		}
		if (!bInCate)	continue;

		/*** 환경 변수 준비 ***/
		char sGetEnv[128];

		/** 환경 변수 확인(아이템 단) **/
		/* 접근 관련 */
		SelectedStuffToString(dds_eItemList[i][ENV], "ENV_DDS_LIMIT_SHOW_LIST_CLASS", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (StrEqual(sGetEnv, "none", false)) // 허용된 것이 아무것도 없음
		{
			continue;
		}
		else if (!StrEqual(sGetEnv, "all", false)) // 코드로 구분되어 졌을 경우
		{
			// 빈칸 모두 제거
			ReplaceString(sGetEnv, sizeof(sGetEnv), " ", "", false);

			// 허용 등급 추출
			char[][] sTempClStr = new char[UCM_GetClassCount() + 1][8];
			ExplodeString(sGetEnv, ",", sTempClStr, UCM_GetClassCount() + 1, 8);

			// 갯수 파악
			int chkcount;

			// 검증
			for (int j = 0; j <= UCM_GetClassCount(); j++)
			{
				// 0은 생략
				if (j == 0)	continue;

				// 맞는 것이 없으면 패스
				if (StringToInt(sTempClStr[j]) != UCM_GetClientClass(client))	continue;

				chkcount++;
			}
			
			// 없으면 차단
			if (chkcount == 0)
			{
				continue;
			}
		}

		// 번호를 문자열로 치환
		char sTempIdx[8];
		IntToString(dds_eItemList[i][INDEX], sTempIdx, sizeof(sTempIdx));

		// 클라이언트 국가에 따른 아이템 종류 이름 추출(아이템 자체에서 판단)
		char sItemCGName[40];
		SelectedGeoNameToString(client, dds_eItemCategoryList[Find_GetItemCGListIndex(dds_eItemList[i][CATECODE])][NAME], sItemCGName, sizeof(sItemCGName));

		// 클라이언트 국가에 따른 아이템 이름 추출
		char sItemName[32];
		SelectedGeoNameToString(client, dds_eItemList[i][NAME], sItemName, sizeof(sItemName));

		// 메뉴 아이템 등록
		Format(buffer, sizeof(buffer), "[%s] %s", sItemCGName, sItemName);
		mMain.AddItem(sTempIdx, buffer);

		// 갯수 증가
		count++;

		#if defined _DEBUG_
		DDS_PrintToChat(client, "\x05:: DEBUG ::\x01 Item Give-CateIn Menu ~ CG (CateCode: %d, ItemName: %s, ItemIdx: %d, Count: %d)", catecode, sItemName, i, count);
		#endif
	}

	// 아이템 종류가 없을 때
	if (count == 0)
	{
		// '없음' 출력
		Format(buffer, sizeof(buffer), "%t", "global nothing");
		mMain.AddItem("0", buffer, ITEMDRAW_DISABLED);
	}

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 아이템 주기-대상 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param itemidx			아이템 번호
 */
public void Menu_ItemGive_Target(int client, int itemidx)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlItemGive_Target);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t-%t\n ", "menu common title", "menu common curpos", "menu itemgive", "global target");
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 전달 파라메터 등록
	char sSendParam[16];

	// 갯수 파악
	int count;

	// 메뉴 아이템 등록
	for (int i = 0; i < MaxClients; i++)
	{
		// 서버는 통과
		if (i == 0)	continue;

		// 게임 내에 없으면 통과
		if (!IsClientInGame(i))	continue;

		// 봇이면 통과
		if (IsFakeClient(i))	continue;

		// 인증이 되어 있지 않으면 통과
		if (!IsClientAuthorized(i))	continue;

		// 본인은 통과
		if (i == client)	continue;

		Format(buffer, sizeof(buffer), "%N", i);
		Format(sSendParam, sizeof(sSendParam), "%d||%d", GetClientUserId(i), itemidx);
		mMain.AddItem(sSendParam, buffer);

		// 갯수 증가
		count++;
	}

	// 유저가 없을 때
	if (count == 0)
	{
		// '없음' 출력
		Format(buffer, sizeof(buffer), "%t", "global nothing");
		mMain.AddItem("0", buffer, ITEMDRAW_DISABLED);
	}

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 아이템 뺏기-대상 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 */
public void Menu_ItemTakeAWay(int client)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlItemTakeAWay);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t-%t\n ", "menu common title", "menu common curpos", "menu itemtakeaway", "global target");
	mMain.SetTitle(buffer);

	// 전달 파라메터 등록
	char sSendParam[16];

	// 갯수 파악
	int count;

	// 메뉴 아이템 등록
	for (int i = 0; i < MaxClients; i++)
	{
		// 서버는 통과
		if (i == 0)	continue;

		// 게임 내에 없으면 통과
		if (!IsClientInGame(i))	continue;

		// 봇이면 통과
		if (IsFakeClient(i))	continue;

		// 인증이 되어 있지 않으면 통과
		if (!IsClientAuthorized(i))	continue;

		// 본인은 통과
		if (i == client)	continue;

		Format(buffer, sizeof(buffer), "%N", i);
		IntToString(GetClientUserId(i), sSendParam, sizeof(sSendParam));
		mMain.AddItem(sSendParam, buffer);

		// 갯수 증가
		count++;
	}

	// 유저가 없을 때
	if (count == 0)
	{
		// '없음' 출력
		Format(buffer, sizeof(buffer), "%t", "global nothing");
		mMain.AddItem("0", buffer, ITEMDRAW_DISABLED);
	}

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메뉴 :: 아이템 뺏기-전체 세부 메뉴 출력
 *
 * @param db					데이터베이스 연결 핸들
 * @param results				결과 쿼리
 * @param error					오류 문자열
 * @param data					기타(0 - 클라이언트 인덱스, 1 - 대상 클라이언트 유저 ID)
 */
public void Menu_ItemTakeAWay_CateIn(Database db, DBResultSet results, const char[] error, any data)
{
	/******
	 * @param data				Handle / ArrayList
	 * 					0 - 클라이언트 인덱스(int), 1 - 대상 클라이언트 유저 ID(int)
	 ******/
	// 타입 변환(*!*핸들 누수가 있는지?)
	ArrayList hData = view_as<ArrayList>(data);

	int client = hData.Get(0);
	int tarusrid = hData.Get(1);

	delete hData;

	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	// 쿼리 오류 검출
	if (db == null || error[0])
	{
		Log_CodeError(0, 2027, error);
		return;
	}

	// '전체' 아이템 종류 이름 추출
	char sCGName[40];
	SelectedGeoNameToString(client, dds_eItemCategoryList[0][NAME], sCGName, sizeof(sCGName));

	// 메뉴 및 제목 설정
	char buffer[256];
	Menu mMain = new Menu(Main_hdlItemTakeAWay_CateIn);

	Format(buffer, sizeof(buffer), "%t\n%t: %t-%s\n ", "menu common title", "menu common curpos", "menu itemtakeaway", sCGName);
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 갯수 파악
	int count;

	// 종류 항목은 '전체'로 선택
	int catecode = 0;

	// 쿼리 결과
	while (results.MoreRows)
	{
		// 제시할 행이 없다면 통과
		if (!results.FetchRow())	continue;

		// 아이템 정보
		int iTmpDbIdx = results.FetchInt(0);
		int iTmpItIdx = results.FetchInt(2);
		int iTmpItAp = results.FetchInt(3);

		// 0번은 있을 수 없지만 혹시 모르므로 제외
		if (iTmpItIdx == 0)	continue;

		// '전체' 항목이 아니면서 선택한 아이템 종류가 아닌 아이템은 제외
		if ((catecode != dds_eItemList[Find_GetItemListIndex(iTmpItIdx)][CATECODE]) && catecode != 0)	continue;

		// 체크되는 아이템의 아이템 종류가 등록되어 있는 아이템 종류가 없는 경우는 제외
		// 이유: 유저가 가지고 있는 아이템 중 그에 맞는 아이템 종류가 활성화되지 않은 아이템 종류인 경우를 피하려는 것 때문
		bool bInCate = false;
		for (int i = 0; i <= dds_iItemCategoryCount; i++)
		{
			// '전체'는 제외
			if (i == 0)	continue;

			// 유효한지 파악
			if (dds_eItemList[Find_GetItemListIndex(iTmpItIdx)][CATECODE] == dds_eItemCategoryList[i][CODE])
			{
				bInCate = true;
				break;
			}
		}
		if (!bInCate)	continue;

		/*** 환경 변수 준비 ***/
		char sGetEnv[128];

		/** 환경 변수 확인(아이템 단) **/
		/* 접근 관련 */
		SelectedStuffToString(dds_eItemList[Find_GetItemListIndex(iTmpItIdx)][ENV], "ENV_DDS_LIMIT_SHOW_LIST_CLASS", "||", ":", sGetEnv, sizeof(sGetEnv));
		if (StrEqual(sGetEnv, "none", false)) // 허용된 것이 아무것도 없음
		{
			continue;
		}
		else if (!StrEqual(sGetEnv, "all", false)) // 코드로 구분되어 졌을 경우
		{
			// 빈칸 모두 제거
			ReplaceString(sGetEnv, sizeof(sGetEnv), " ", "", false);

			// 허용 등급 추출
			char[][] sTempClStr = new char[UCM_GetClassCount() + 1][8];
			ExplodeString(sGetEnv, ",", sTempClStr, UCM_GetClassCount() + 1, 8);

			// 갯수 파악
			int chkcount;

			// 검증
			for (int i = 0; i <= UCM_GetClassCount(); i++)
			{
				// 0은 생략
				if (i == 0)	continue;

				// 맞는 것이 없으면 패스
				if (StringToInt(sTempClStr[i]) != UCM_GetClientClass(client))	continue;

				chkcount++;
			}
			
			// 없으면 차단
			if (chkcount == 0)
			{
				continue;
			}
		}

		// 번호를 문자열로 치환
		char sTempIdx[32];
		Format(sTempIdx, sizeof(sTempIdx), "%d||%d||%d||%d", iTmpDbIdx, iTmpItIdx, iTmpItAp, tarusrid);

		// 클라이언트 국가에 따른 아이템 종류 이름 추출(아이템 자체에서 판단)
		char sItemCGName[40];
		SelectedGeoNameToString(client, dds_eItemCategoryList[Find_GetItemCGListIndex(dds_eItemList[Find_GetItemListIndex(iTmpItIdx)][CATECODE])][NAME], sItemCGName, sizeof(sItemCGName));

		// 클라이언트 국가에 따른 아이템 이름 추출
		char sItemName[32];
		SelectedGeoNameToString(client, dds_eItemList[Find_GetItemListIndex(iTmpItIdx)][NAME], sItemName, sizeof(sItemName));

		// 아이템이 장착되어 있는지 작성
		char sApStr[16];
		Format(sApStr, sizeof(sApStr), "");
		if (iTmpItAp > 0)
			Format(sApStr, sizeof(sApStr), " - %t", "global applied");

		// 메뉴 아이템 등록
		Format(buffer, sizeof(buffer), "[%s] %s%s", sItemCGName, sItemName, sApStr);
		mMain.AddItem(sTempIdx, buffer);

		// 갯수 증가
		count++;

		#if defined _DEBUG_
		DDS_PrintToChat(client, "\x05:: DEBUG ::\x01 Item TakeaWay-CateIn Menu ~ CG (TarUsrId: %d, ItemName: %s, ItemIdx: %d, Count: %d)", tarusrid, sItemName, iTmpItIdx, count);
		#endif
	}

	// 아이템이 없을 때
	if (count == 0)
	{
		// '없음' 출력
		Format(buffer, sizeof(buffer), "%t", "global nothing");
		mMain.AddItem("0", buffer, ITEMDRAW_DISABLED);
	}

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);
}


/**
 * 찾기 :: 아이템 목록 변수 인덱스 추출
 *
 * @param itemidx			아이템 번호
 */
public int Find_GetItemListIndex(const int itemidx)
{
	// 아이템 번호가 0번이면 통과
	if (itemidx == 0)	return 0;

	// 갯수 검증
	int count;

	// 임시 값 준비
	int tempval;

	// 검증
	for (int i = 0; i <= dds_iItemCount; i++)
	{
		// 0번은 통과
		if (i == 0)	continue;

		// 맞지 않다면 통과
		if (dds_eItemList[i][INDEX] != itemidx)	continue;

		// 값 세팅
		tempval = i;

		// 갯수 증가
		count++;
	}

	if (count > 1)	return 0;
	else if (count < 1)	return 0;
	else return tempval;
}

/**
 * 찾기 :: 아이템 종류 목록 변수 인덱스 추출
 *
 * @param catecode			아이템 종류 코드
 */
public int Find_GetItemCGListIndex(const int catecode)
{
	// 아이템 종류 코드가 0번이면 통과
	if (catecode == 0)	return 0;

	// 갯수 검증
	int count;

	// 임시 값 준비
	int tempval;

	// 검증
	for (int i = 0; i <= dds_iItemCategoryCount; i++)
	{
		// '전체'는 통과
		if (i == 0)	continue;

		// 맞지 않다면 통과
		if (dds_eItemCategoryList[i][CODE] != catecode)	continue;

		// 값 세팅
		tempval = i;

		// 갯수 증가
		count++;
	}

	if (count > 1)	return 0;
	else if (count < 1)	return 0;
	else return tempval;
}


/*******************************************************
 * C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 커맨드 :: 전체 채팅
 *
 * @param client				클라이언트 인덱스
 * @param args					기타
 */
public Action Command_Say(int client, int args)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return Plugin_Continue;

	// 서버 채팅은 통과
	if (client == 0)	return Plugin_Continue;

	// 메세지 받고 맨 끝 따옴표 제거
	char sMsg[256];

	GetCmdArgString(sMsg, sizeof(sMsg));
	sMsg[strlen(sMsg)-1] = '\x0';

	// 파라메터 추출 후 분리
	char sMainCmd[32];
	char sParamStr[4][64];
	int sParamIdx;

	sParamIdx = SplitString(sMsg[1], " ", sMainCmd, sizeof(sMainCmd));
	ExplodeString(sMsg[1 + sParamIdx], " ", sParamStr, sizeof(sParamStr), sizeof(sParamStr[]));
	if (sParamIdx == -1)
	{
		strcopy(sMainCmd, sizeof(sMainCmd), sMsg[1]);
		strcopy(sParamStr[0], 64, "");
	}

	// 느낌표나 슬래시가 있다면 제거 후 명령어였늕지 파악
	bool bChkCmd;
	if (ReplaceString(sMainCmd, sizeof(sMainCmd), "!", "", false) > 0)
		bChkCmd = true;

	if (ReplaceString(sMainCmd, sizeof(sMainCmd), "/", "", false) > 0)
		bChkCmd = true;

	// 명령어 번역 준비
	char sCmhTrans[32];

	/***********************************************************************
	 * -------------------------
	 * 변수 정리
	 * -------------------------
	 *
	 * sMainCmd - 맨 처음의 전체 문자열. 슬래시나 느낌표가 없음.
	 * ex) 예를 들어 채팅에서 '!테스트 하나 둘 셋'했다면 sMainCmd는 '테스트'가 됨.
	 *
	 * sParamStr - 파라메터. sParamStr의 1차원 배열에 설정한 길이 값만큼 이용 가능
	 * add) 현재 기본값 4로 설정되어 있고 띄어쓰기 구분으로 파라메터 4개를 쓸 수 있음.
	 *
	 * bChkCmd - 슬래시나 느낌표가 들어있는 경우 명령어로 간주하여 체크 됨.
	 *
	 * sCmhTrans - 클라이언트 언어 별 명령어를 담당할 포멧을 지정하는 곳.
	 *
	************************************************************************/
	// 메인 메뉴
	Format(sCmhTrans, sizeof(sCmhTrans), "%t", "command main menu");
	if (bChkCmd && StrEqual(sMainCmd, sCmhTrans, false))
	{
		Menu_Main(client, 0);
	}

	// 프로필 정보
	Format(sCmhTrans, sizeof(sCmhTrans), "%t", "command profile");
	if (bChkCmd && StrEqual(sMainCmd, sCmhTrans, false))
	{
		Command_Profile(client, sParamStr[0]);
	}

	// 금액 또는 기타 선물
	Format(sCmhTrans, sizeof(sCmhTrans), "%t", "command gift");
	if (bChkCmd && StrEqual(sMainCmd, sCmhTrans, false))
	{
		ArrayList hSendParam = CreateArray(64);
		hSendParam.PushString(sParamStr[0]);
		hSendParam.PushString(sParamStr[1]);
		hSendParam.PushString(sParamStr[2]);
		hSendParam.PushString(sParamStr[3]);

		Command_Gift(client, hSendParam);
	}

	// 금액 주기
	Format(sCmhTrans, sizeof(sCmhTrans), "%t", "command moneygive");
	if (bChkCmd && StrEqual(sMainCmd, sCmhTrans, false))
	{
		ArrayList hSendParam = CreateArray(64);
		hSendParam.PushString(sParamStr[0]);
		hSendParam.PushString(sParamStr[1]);
		hSendParam.PushString(sParamStr[2]);
		hSendParam.PushString(sParamStr[3]);

		Command_MoneyGive(client, hSendParam);
	}

	// 금액 뺏기
	Format(sCmhTrans, sizeof(sCmhTrans), "%t", "command moneytakeaway");
	if (bChkCmd && StrEqual(sMainCmd, sCmhTrans, false))
	{
		ArrayList hSendParam = CreateArray(64);
		hSendParam.PushString(sParamStr[0]);
		hSendParam.PushString(sParamStr[1]);
		hSendParam.PushString(sParamStr[2]);
		hSendParam.PushString(sParamStr[3]);

		Command_MoneyTakeAWay(client, hSendParam);
	}

	// 아이템 주기
	Format(sCmhTrans, sizeof(sCmhTrans), "%t", "command itemgive");
	if (bChkCmd && StrEqual(sMainCmd, sCmhTrans, false))
	{
		ArrayList hSendParam = CreateArray(64);
		hSendParam.PushString(sParamStr[0]);
		hSendParam.PushString(sParamStr[1]);
		hSendParam.PushString(sParamStr[2]);
		hSendParam.PushString(sParamStr[3]);

		Command_ItemGive(client, hSendParam);
	}

	// 아이템 뺏기
	Format(sCmhTrans, sizeof(sCmhTrans), "%t", "command itemtakeaway");
	if (bChkCmd && StrEqual(sMainCmd, sCmhTrans, false))
	{
		Command_ItemTakeAWay(client);
	}

	// 초기화
	Format(sCmhTrans, sizeof(sCmhTrans), "%t", "command init");
	if (bChkCmd && StrEqual(sMainCmd, sCmhTrans, false))
	{
		Command_Init(client);
	}

	// 팀 채팅 기록 초기화
	dds_bTeamChat[client] = false;

	return dds_hCV_SwitchDisplayChat.BoolValue ? Plugin_Continue : Plugin_Handled;
}

/**
 * 커맨드 :: 팀 채팅
 *
 * @param client				클라이언트 인덱스
 * @param args					기타
 */
public Action Command_TeamSay(int client, int args)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return Plugin_Continue;

	// 팀 채팅을 했다는 변수를 남기고 일반 채팅과 동일하게 간주
	dds_bTeamChat[client] = true;
	Command_Say(client, args);

	return Plugin_Handled;
}

/**
 * 커맨드 :: 프로필
 *
 * @param client				클라이언트 인덱스
 * @param name					대상 클라이언트 이름
 */
public void Command_Profile(int client, const char[] name)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	/***********************************
	 * ~사용법~
	 *
	 * !<"command profile"> <대상이름>
	************************************/
	// 대상이 빈칸일 경우
	if (strlen(name) <= 0)
	{
		DDS_PrintToChat(client, "%t", "error command profile usage", "command profile");
		return;
	}

	// 쌍따옴표로 구성이 안되어 있을 경우
	if (!CheckDQM(name))
	{
		DDS_PrintToChat(client, "%t", "error command notarget nodqm");
		return;
	}

	// 대상을 찾는데 없을 경우
	if (SearchTargetByName(name) == 0)
	{
		DDS_PrintToChat(client, "%t", "error command notarget ingame");
		return;
	}

	// 대상을 찾는데 2명 이상일 경우
	if (SearchTargetByName(name) == -1)
	{
		DDS_PrintToChat(client, "%t", "error command notarget more");
		return;
	}

	Menu_Profile(GetClientOfUserId(SearchTargetByName(name)), "command");
}

/**
 * 커맨드 :: 금액 선물
 *
 * @param client				클라이언트 인덱스
 * @param data					추가 값
 */
public void Command_Gift(int client, ArrayList data)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	// 파라메터 값 수령
	char sGetParam[4][64];

	data.GetString(0, sGetParam[0], 64);
	data.GetString(1, sGetParam[1], 64);
	data.GetString(2, sGetParam[2], 64);
	data.GetString(3, sGetParam[3], 64);

	delete data;

	// 번역 준비
	char sCmdTrans[32];

	/***********************************
	 * ~사용법~
	 *
	 * !<"command gift"> <"global money"> <대상 이름> <양>
	************************************/
	// 행동 구분이 빈칸일 경우
	if (strlen(sGetParam[0]) <= 0)
	{
		DDS_PrintToChat(client, "%t", "error command gift usage", "command gift", "global money");
		return;
	}

	/** 행동 구분 **/
	// 금액
	Format(sCmdTrans, sizeof(sCmdTrans), "\"%t\"", "global money");
	if (StrEqual(sGetParam[0], sCmdTrans, false))
	{
		// 대상이 빈칸일 경우
		if (strlen(sGetParam[1]) <= 0)
		{
			DDS_PrintToChat(client, "%t", "error command notarget");
			return;
		}

		// 쌍따옴표로 구성이 안되어 있을 경우
		if (!CheckDQM(sGetParam[1]))
		{
			DDS_PrintToChat(client, "%t", "error command notarget nodqm");
			return;
		}

		// 대상을 찾는데 없을 경우
		if (SearchTargetByName(sGetParam[1]) == 0)
		{
			DDS_PrintToChat(client, "%t", "error command notarget ingame");
			return;
		}

		// 대상을 찾는데 2명 이상일 경우
		if (SearchTargetByName(sGetParam[1]) == -1)
		{
			DDS_PrintToChat(client, "%t", "error command notarget more");
			return;
		}

		// 선물 금액이 빈칸일 경우
		if (strlen(sGetParam[2]) <= 0)
		{
			DDS_PrintToChat(client, "%t", "error command nomoney");
			return;
		}

		// 선물 금액이 쌍따옴표로 구성이 안되어 있을 경우
		if (!CheckDQM(sGetParam[2]))
		{
			DDS_PrintToChat(client, "%t", "error command nomoney nodqm");
			return;
		}

		// 금액 쌍따옴표 제거
		StripQuotes(sGetParam[2]);

		// 파라메터 준비
		char sSendParam[32];
		Format(sSendParam, sizeof(sSendParam), "%d||%d", StringToInt(sGetParam[2]), SearchTargetByName(sGetParam[1]));

		// 처리
		System_DataProcess(client, "money-gift", sSendParam);
	}
}

/**
 * 커맨드 :: 금액 주기
 *
 * @param client				클라이언트 인덱스
 * @param data					추가 값
 */
public void Command_MoneyGive(int client, ArrayList data)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	// 파라메터 값 수령
	char sGetParam[4][64];

	data.GetString(0, sGetParam[0], 64);
	data.GetString(1, sGetParam[1], 64);
	data.GetString(2, sGetParam[2], 64);
	data.GetString(3, sGetParam[3], 64);

	delete data;

	// ENV 확인
	char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
	UCM_GetClassInfo(UCM_GetClientClass(client), ClassInfo_Env, sGetEnv);
	SelectedStuffToString(sGetEnv, "ENV_DDS_ACCESS_MONEY_GIVE", "||", ":", sGetEnv, sizeof(sGetEnv));
	if (!StringToInt(sGetEnv))
	{
		DDS_PrintToChat(client, "%t", "error access");
		return;
	}

	/***********************************
	 * ~사용법~
	 *
	 * !<"command moneygive"> <대상 이름> <값>
	************************************/
	// 대상이 빈칸일 경우
	if (strlen(sGetParam[0]) <= 0)
	{
		DDS_PrintToChat(client, "%t", "error command moneygive usage", "command moneygive");
		return;
	}

	// 쌍따옴표로 구성이 안되어 있을 경우
	if (!CheckDQM(sGetParam[0]))
	{
		DDS_PrintToChat(client, "%t", "error command notarget nodqm");
		return;
	}

	// 대상을 찾는데 없을 경우
	if (SearchTargetByName(sGetParam[0]) == 0)
	{
		DDS_PrintToChat(client, "%t", "error command notarget ingame");
		return;
	}

	// 대상을 찾는데 2명 이상일 경우
	if (SearchTargetByName(sGetParam[0]) == -1)
	{
		DDS_PrintToChat(client, "%t", "error command notarget more");
		return;
	}

	// 금액 값이 빈칸일 경우
	if (strlen(sGetParam[1]) <= 0)
	{
		DDS_PrintToChat(client, "%t", "error command nomoney");
		return;
	}

	// 금액 값이 쌍따옴표로 구성이 안되어 있을 경우
	if (!CheckDQM(sGetParam[1]))
	{
		DDS_PrintToChat(client, "%t", "error command nomoney nodqm");
		return;
	}

	// 금액 값 쌍따옴표 제거
	StripQuotes(sGetParam[1]);

	// 파라메터 준비
	char sSendParam[32];
	Format(sSendParam, sizeof(sSendParam), "%d||%d", StringToInt(sGetParam[1]), SearchTargetByName(sGetParam[0]));

	// 금액 주기
	System_DataProcess(client, "money-give", sSendParam);
}

/**
 * 커맨드 :: 금액 뺏기
 *
 * @param client				클라이언트 인덱스
 * @param data					추가 값
 */
public void Command_MoneyTakeAWay(int client, ArrayList data)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	// 파라메터 값 수령
	char sGetParam[4][64];

	data.GetString(0, sGetParam[0], 64);
	data.GetString(1, sGetParam[1], 64);
	data.GetString(2, sGetParam[2], 64);
	data.GetString(3, sGetParam[3], 64);

	delete data;

	// ENV 확인
	char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
	UCM_GetClassInfo(UCM_GetClientClass(client), ClassInfo_Env, sGetEnv);
	SelectedStuffToString(sGetEnv, "ENV_DDS_ACCESS_MONEY_TAKEAWAY", "||", ":", sGetEnv, sizeof(sGetEnv));
	if (!StringToInt(sGetEnv))
	{
		DDS_PrintToChat(client, "%t", "error access");
		return;
	}

	/***********************************
	 * ~사용법~
	 *
	 * !<"command moneytakeaway"> <대상 이름> <값>
	************************************/
	// 대상이 빈칸일 경우
	if (strlen(sGetParam[0]) <= 0)
	{
		DDS_PrintToChat(client, "%t", "error command moneytakeaway usage", "command moneytakeaway");
		return;
	}

	// 쌍따옴표로 구성이 안되어 있을 경우
	if (!CheckDQM(sGetParam[0]))
	{
		DDS_PrintToChat(client, "%t", "error command notarget nodqm");
		return;
	}

	// 대상을 찾는데 없을 경우
	if (SearchTargetByName(sGetParam[0]) == 0)
	{
		DDS_PrintToChat(client, "%t", "error command notarget ingame");
		return;
	}

	// 대상을 찾는데 2명 이상일 경우
	if (SearchTargetByName(sGetParam[0]) == -1)
	{
		DDS_PrintToChat(client, "%t", "error command notarget more");
		return;
	}

	// 금액 값이 빈칸일 경우
	if (strlen(sGetParam[1]) <= 0)
	{
		DDS_PrintToChat(client, "%t", "error command nomoney");
		return;
	}

	// 금액 값이 쌍따옴표로 구성이 안되어 있을 경우
	if (!CheckDQM(sGetParam[1]))
	{
		DDS_PrintToChat(client, "%t", "error command nomoney nodqm");
		return;
	}

	// 금액 값 쌍따옴표 제거
	StripQuotes(sGetParam[1]);

	// 파라메터 준비
	char sSendParam[32];
	Format(sSendParam, sizeof(sSendParam), "%d||%d", StringToInt(sGetParam[1]), SearchTargetByName(sGetParam[0]));

	// 금액 뺏기
	System_DataProcess(client, "money-takeaway", sSendParam);
}

/**
 * 커맨드 :: 아이템 주기
 *
 * @param client				클라이언트 인덱스
 * @param data					추가 값
 */
public void Command_ItemGive(int client, ArrayList data)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	// 파라메터 값 수령
	char sGetParam[4][64];

	data.GetString(0, sGetParam[0], 64);
	data.GetString(1, sGetParam[1], 64);
	data.GetString(2, sGetParam[2], 64);
	data.GetString(3, sGetParam[3], 64);

	delete data;

	// ENV 확인
	char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
	UCM_GetClassInfo(UCM_GetClientClass(client), ClassInfo_Env, sGetEnv);
	SelectedStuffToString(sGetEnv, "ENV_DDS_ACCESS_ITEM_GIVE", "||", ":", sGetEnv, sizeof(sGetEnv));
	if (!StringToInt(sGetEnv))
	{
		DDS_PrintToChat(client, "%t", "error access");
		return;
	}

	/***********************************
	 * ~사용법~
	 *
	 * !<"command itemgive"> <대상 이름> <아이템 번호>
	************************************/
	// 별 다른 파라메터가 없을 경우
	if (strlen(sGetParam[0]) <= 0)
	{
		// 메뉴 띄우기
		Menu_ItemGive(client);
		return;
	}

	// 쌍따옴표로 구성이 안되어 있을 경우
	if (!CheckDQM(sGetParam[0]))
	{
		DDS_PrintToChat(client, "%t", "error command notarget nodqm");
		return;
	}

	// 대상을 찾는데 없을 경우
	if (SearchTargetByName(sGetParam[0]) == 0)
	{
		DDS_PrintToChat(client, "%t", "error command notarget ingame");
		return;
	}

	// 대상을 찾는데 2명 이상일 경우
	if (SearchTargetByName(sGetParam[0]) == -1)
	{
		DDS_PrintToChat(client, "%t", "error command notarget more");
		return;
	}

	// 아이템 번호가 빈칸일 경우
	if (strlen(sGetParam[1]) <= 0)
	{
		DDS_PrintToChat(client, "%t", "error command noitem");
		return;
	}

	// 아이템 번호가 쌍따옴표로 구성이 안되어 있을 경우
	if (!CheckDQM(sGetParam[1]))
	{
		DDS_PrintToChat(client, "%t", "error command noitem nodqm");
		return;
	}

	// 아이템 번호 쌍따옴표 제거
	StripQuotes(sGetParam[1]);

	// 파라메터 준비
	char sSendParam[32];
	Format(sSendParam, sizeof(sSendParam), "%d||%d", StringToInt(sGetParam[1]), SearchTargetByName(sGetParam[0]));

	// 아이템 주기
	System_DataProcess(client, "item-give", sSendParam);
}

/**
 * 커맨드 :: 아이템 뺏기
 *
 * @param client				클라이언트 인덱스
 */
public void Command_ItemTakeAWay(int client)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	// ENV 확인
	char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
	UCM_GetClassInfo(UCM_GetClientClass(client), ClassInfo_Env, sGetEnv);
	SelectedStuffToString(sGetEnv, "ENV_DDS_ACCESS_ITEM_TAKEAWAY", "||", ":", sGetEnv, sizeof(sGetEnv));
	if (!StringToInt(sGetEnv))
	{
		DDS_PrintToChat(client, "%t", "error access");
		return;
	}

	/***********************************
	 * ~사용법~
	 *
	 * !<"command itemtakeaway">
	************************************/
	// 메뉴 띄우기
	Menu_ItemTakeAWay(client);
}

/**
 * 커맨드 :: 초기화
 *
 * @param client				클라이언트 인덱스
 * @param args					기타
 */
public void Command_Init(int client)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return;

	// 접근 가능한 권한이 있는지 확인
	char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
	UCM_GetClassInfo(UCM_GetClientClass(client), ClassInfo_Env, sGetEnv);
	SelectedStuffToString(sGetEnv, "ENV_DDS_ACCESS_INIT", "||", ":", sGetEnv, sizeof(sGetEnv));

	// 권한이 없으면 차단
	if (!StringToInt(sGetEnv))
	{
		DDS_PrintToChat(client, "%t", "error access");
		return;
	}

	Menu_InitDatabase(client);
}


/**
 * SQL :: 데이터베이스 최초 연결
 *
 * @param db					데이터베이스 연결 핸들
 * @param error					오류 문자열
 * @param data					기타
 */
public void SQL_GetDatabase(Database db, const char[] error, any data)
{
	// 데이터베이스 연결 안될 때
	if ((db == null) || (error[0]))
	{
		Log_CodeError(0, 1000, error);
		return;
	}

	// SQL 데이터베이스 핸들 등록
	dds_hSQLDatabase = db;

	if (dds_hSQLDatabase == null)
	{
		Log_CodeError(0, 1001, error);
		return;
	}

	// UTF-8 설정
	dds_hSQLDatabase.SetCharset("utf8");

	// 초기화 및 SQL 데이터베이스에 있는 데이터 로드
	SQL_DDSDatabaseInit();
}

/**
 * SQL :: 일반 SQL 쿼리 오류 발생 시
 *
 * @param db					데이터베이스 연결 핸들
 * @param results				결과 쿼리
 * @param error					오류 문자열
 * @param data					기타
 */
public void SQL_ErrorProcess(Database db, DBResultSet results, const char[] error, any data)
{
	/******
	 * @param data				Handle / ArrayList
	 * 					0 - 클라이언트 인덱스(int), 1 - 오류코드(int), 2 - 추가값(char)
	 ******/
	// 타입 변환(*!*핸들 누수가 있는지?)
	ArrayList hData = view_as<ArrayList>(data);

	int client = hData.Get(0);
	int errcode = hData.Get(1);

	delete hData;

	// 오류코드 로그 작성
	if (error[0])	Log_CodeError(client, errcode, error);
}

/**
 * SQL 초기 데이터 :: 아이템 카테고리
 *
 * @param db					데이터베이스 연결 핸들
 * @param results				결과 쿼리
 * @param error					오류 문자열
 * @param data					기타
 */
public void SQL_LoadItemCategory(Database db, DBResultSet results, const char[] error, any data)
{
	// 쿼리 오류 검출
	if (db == null || error[0])
	{
		Log_CodeError(0, 1002, error);
		return;
	}

	#if defined _DEBUG_
	DDS_PrintToServer(":: DEBUG :: Let's Start Loading Item Categories!");
	#endif

	// 쿼리 결과
	while (results.MoreRows)
	{
		// 제시할 행이 없다면 통과
		if (!results.FetchRow())	continue;

		// 데이터 임시 로드
		int iTmpCode;
		char sTmpName[DDS_ENV_VAR_GLONAME_SIZE];
		char sTmpEnv[DDS_ENV_VAR_ENV_SIZE];

		iTmpCode = results.FetchInt(0);
		results.FetchString(1, sTmpName, sizeof(sTmpName));
		results.FetchString(3, sTmpEnv, sizeof(sTmpEnv));

		/** 환경 변수 확인(아이템 종류단) **/
		char sGetEnv[128];

		/* 시스템 관련 */
		// 현재 사용하고 있는 게임 이름 추출
		char sGetGame[32];
		GetGameFolderName(sGetGame, sizeof(sGetGame));

		// 갯수 파악
		int count;

		// 지원 게임 확인
		SelectedStuffToString(sTmpEnv, "ENV_DDS_SYS_GAME", "||", ":", sGetEnv, sizeof(sGetEnv));

		#if defined _DEBUG_
		DDS_PrintToServer(":: DEBUG :: ITEM CG ENV - CG IDX: %d, SYS_GAME: %s", iTmpCode, sGetEnv);
		#endif
		if (!StrEqual(sGetEnv, "all", false) && !StrEqual(sGetEnv, sGetGame, false)) // '전체' 또는 현재 사용하고 있는 게임이 아닐 경우
		{
			// 빈칸 모두 제거
			ReplaceString(sGetEnv, sizeof(sGetEnv), " ", "", false);

			// 허용 등급 추출
			char sTmpGNStr[DDS_ENV_VAR_SUPPORT_GAME_NUM][64];
			ExplodeString(sGetEnv, ",", sTmpGNStr, sizeof(sTmpGNStr), sizeof(sTmpGNStr[]));

			// 검증
			for (int i = 0; i < DDS_ENV_VAR_SUPPORT_GAME_NUM; i++)
			{
				// 맞는 것이 없으면 패스
				if (!StrEqual(sGetGame, sTmpGNStr[i], false))	continue;

				count++;
			}

			// 없다면 통과
			if (count == 0)	continue;
		}

		// 데이터 추가
		dds_eItemCategoryList[dds_iItemCategoryCount + 1][CODE] = iTmpCode;
		Format(dds_eItemCategoryList[dds_iItemCategoryCount + 1][NAME], DDS_ENV_VAR_GLONAME_SIZE, sTmpName);
		Format(dds_eItemCategoryList[dds_iItemCategoryCount + 1][ENV], DDS_ENV_VAR_ENV_SIZE, sTmpEnv);

		#if defined _DEBUG_
		DDS_PrintToServer(":: DEBUG :: Category Loaded (CG IDX: %d, GloName: %s, TotalCount: %d)", dds_eItemCategoryList[dds_iItemCategoryCount + 1][CODE], dds_eItemCategoryList[dds_iItemCategoryCount + 1][NAME], dds_iItemCategoryCount + 1);
		#endif

		// 아이템 종류 등록 갯수 증가
		dds_iItemCategoryCount++;
	}

	#if defined _DEBUG_
	DDS_PrintToServer(":: DEBUG :: End Loading Item Categories.");
	#endif

	// 포워드 실행
	Forward_OnLoadSQLItemCategory();
}

/**
 * SQL 초기 데이터 :: 아이템 목록
 *
 * @param db					데이터베이스 연결 핸들
 * @param results				결과 쿼리
 * @param error					오류 문자열
 * @param data					기타
 */
public void SQL_LoadItemList(Database db, DBResultSet results, const char[] error, any data)
{
	// 쿼리 오류 검출
	if (db == null || error[0])
	{
		Log_CodeError(0, 1003, error);
		return;
	}

	#if defined _DEBUG_
	DDS_PrintToServer(":: DEBUG :: Let's Start Loading Items!");
	#endif

	// 쿼리 결과
	while (results.MoreRows)
	{
		// 제시할 행이 없다면 통과
		if (!results.FetchRow())	continue;

		// 데이터 임시 로드
		int iTmpIdx;
		char sTmpName[DDS_ENV_VAR_GLONAME_SIZE];
		int iTmpCode;
		int iTmpMoney;
		int iTmpHavTime;
		char sTmpEnv[DDS_ENV_VAR_ENV_SIZE];

		iTmpIdx = results.FetchInt(0);
		results.FetchString(1, sTmpName, sizeof(sTmpName));
		iTmpCode = results.FetchInt(2);
		iTmpMoney = RoundFloat(results.FetchInt(3) * dds_hCV_ItemMoneyMultiply.FloatValue);
		iTmpHavTime = results.FetchInt(4);
		results.FetchString(5, sTmpEnv, sizeof(sTmpEnv));

		/** 환경 변수 확인(아이템 단) **/
		char sGetEnv[128];

		/* 시스템 관련 */
		// 현재 사용하고 있는 게임 이름 추출
		char sGetGame[32];
		GetGameFolderName(sGetGame, sizeof(sGetGame));

		// 갯수 파악
		int count;

		// 지원 게임 확인
		SelectedStuffToString(sTmpEnv, "ENV_DDS_SYS_GAME", "||", ":", sGetEnv, sizeof(sGetEnv));

		#if defined _DEBUG_
		DDS_PrintToServer(":: DEBUG :: ITEM ENV - Item IDX: %d, SYS_GAME: %s", iTmpIdx, sGetEnv);
		#endif
		if (!StrEqual(sGetEnv, "all", false) && !StrEqual(sGetEnv, sGetGame, false)) // '전체' 또는 현재 사용하고 있는 게임이 아닐 경우
		{
			// 빈칸 모두 제거
			ReplaceString(sGetEnv, sizeof(sGetEnv), " ", "", false);

			// 허용 등급 추출
			char sTmpGNStr[DDS_ENV_VAR_SUPPORT_GAME_NUM][64];
			ExplodeString(sGetEnv, ",", sTmpGNStr, sizeof(sTmpGNStr), sizeof(sTmpGNStr[]));

			// 검증
			for (int i = 0; i < DDS_ENV_VAR_SUPPORT_GAME_NUM; i++)
			{
				// 맞는 것이 없으면 패스
				if (!StrEqual(sGetGame, sTmpGNStr[i], false))	continue;

				count++;
			}

			// 없다면 통과
			if (count == 0)	continue;
		}

		// 데이터 추가
		dds_eItemList[dds_iItemCount + 1][INDEX] = iTmpIdx;
		Format(dds_eItemList[dds_iItemCount + 1][NAME], DDS_ENV_VAR_GLONAME_SIZE, sTmpName);
		dds_eItemList[dds_iItemCount + 1][CATECODE] = iTmpCode;
		dds_eItemList[dds_iItemCount + 1][MONEY] = iTmpMoney;
		dds_eItemList[dds_iItemCount + 1][HAVTIME] = iTmpHavTime;
		Format(dds_eItemList[dds_iItemCount + 1][ENV], DDS_ENV_VAR_ENV_SIZE, sTmpEnv);

		#if defined _DEBUG_
		DDS_PrintToServer(":: DEBUG :: Item Loaded (IDX: %d, GloName: %s, CateCode: %d, Money: %d, Time: %d, TotalCount: %d)", dds_eItemList[dds_iItemCount + 1][INDEX], dds_eItemList[dds_iItemCount + 1][NAME], dds_eItemList[dds_iItemCount + 1][CATECODE], dds_eItemList[dds_iItemCount + 1][MONEY], dds_eItemList[dds_iItemCount + 1][HAVTIME], dds_iItemCount + 1);
		#endif

		// 아이템 등록 갯수 증가
		dds_iItemCount++;
	}

	#if defined _DEBUG_
	DDS_PrintToServer(":: DEBUG :: End Loading Items.");
	#endif

	// SQL 상태 활성화
	dds_bSQLStatus = true;

	// 포워드 실행
	Forward_OnLoadSQLItem();
}

/**
 * SQL 초기 데이터 :: ENV 목록
 *
 * @param db					데이터베이스 연결 핸들
 * @param results				결과 쿼리
 * @param error					오류 문자열
 * @param data					기타
 */
public void SQL_LoadEnvList(Database db, DBResultSet results, const char[] error, any data)
{
	// 쿼리 오류 검출
	if (db == null || error[0])
	{
		Log_CodeError(0, 1004, error);
		return;
	}

	#if defined _DEBUG_
	DDS_PrintToServer(":: DEBUG :: Let's Start Loading ENVs!");
	#endif

	// 쿼리 결과
	while (results.MoreRows)
	{
		// 제시할 행이 없다면 통과
		if (!results.FetchRow())	continue;

		// 데이터 임시 로드
		int iTmpIdx;
		char sTmpCG[20];
		char sTmpName[64];
		char sTmpValue[128];

		iTmpIdx = results.FetchInt(0);
		results.FetchString(1, sTmpCG, sizeof(sTmpCG));
		results.FetchString(2, sTmpName, sizeof(sTmpName));
		results.FetchString(3, sTmpValue, sizeof(sTmpValue));

		// 데이터 추가
		dds_eEnvList[dds_iEnvCount][INDEX] = iTmpIdx;
		Format(dds_eEnvList[dds_iEnvCount][CATEGORY], 20, sTmpCG);
		Format(dds_eEnvList[dds_iEnvCount][NAME], 64, sTmpName);
		Format(dds_eEnvList[dds_iEnvCount][VALUE], 128, sTmpValue);

		#if defined _DEBUG_
		DDS_PrintToServer(":: DEBUG :: ENV Loaded (IDX: %d, Category: %s, Name: %s, Value: %s)", dds_eEnvList[dds_iEnvCount][INDEX], dds_eEnvList[dds_iEnvCount][CATEGORY], dds_eEnvList[dds_iEnvCount][NAME], dds_eEnvList[dds_iEnvCount][VALUE]);
		#endif

		// ENV 등록 갯수 증가
		dds_iEnvCount++;
	}

	#if defined _DEBUG_
	DDS_PrintToServer(":: DEBUG :: End Loading ENVs.");
	#endif

	// ENV 추가 작업 시작(아이템)
	for (int i = 0; i <= dds_iItemCount; i++)
	{
		// 0번은 통과
		if (i == 0)	continue;

		// 없는 ENV 추가
		for (int j = 0; j < dds_iEnvCount; j++)
		{
			// 종류가 '아이템'이 아닌건 통과
			if (!StrEqual(dds_eEnvList[j][CATEGORY], "item", false))	continue;

			// 이미 있는건 통과
			if (StrContains(dds_eItemList[i][ENV], dds_eEnvList[j][NAME], false) != -1)	continue;

			Format(dds_eItemList[i][ENV], DDS_ENV_VAR_ENV_SIZE, 
				"%s||%s:%s", 
				dds_eItemList[i][ENV], dds_eEnvList[j][NAME], dds_eEnvList[j][VALUE]
			);
		}
	}

	// ENV 추가 작업 시작(아이템 종류)
	for (int i = 0; i <= dds_iItemCategoryCount; i++)
	{
		// '전체'는 통과
		if (i == 0)	continue;

		// 없는 ENV 추가
		for (int j = 0; j < dds_iEnvCount; j++)
		{
			// 종류가 '아이템'이 아닌건 통과
			if (!StrEqual(dds_eEnvList[j][CATEGORY], "item-category", false))	continue;

			// 이미 있는건 통과
			if (StrContains(dds_eItemCategoryList[i][ENV], dds_eEnvList[j][NAME], false) != -1)	continue;

			Format(dds_eItemCategoryList[i][ENV], DDS_ENV_VAR_ENV_SIZE, 
				"%s||%s:%s", 
				dds_eItemCategoryList[i][ENV], dds_eEnvList[j][NAME], dds_eEnvList[j][VALUE]
			);
		}
	}
}

/**
 * SQL 유저 :: 유저 정보 로드 딜레이
 *
 * @param timer					타이머 핸들
 * @param client				클라이언트 인덱스
 */
public Action SQL_Timer_UserLoad(Handle timer, any client)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!dds_hCV_PluginSwitch.BoolValue)	return Plugin_Stop;

	// 클라이언트 고유 번호 추출
	char sUsrAuthId[20];
	GetClientAuthId(client, AuthId_SteamID64, sUsrAuthId, sizeof(sUsrAuthId));

	/** 데이터 로드 **/
	char sSendQuery[512];

	// 프로필 정보
	Format(sSendQuery, sizeof(sSendQuery), "SELECT * FROM `dds_user_profile` WHERE `authid` = '%s'", sUsrAuthId);
	dds_hSQLDatabase.Query(SQL_UserLoad, sSendQuery, client);
	// 장착 아이템 정보
	Format(sSendQuery, sizeof(sSendQuery), "SELECT * FROM `dds_user_item` WHERE `authid` = '%s' and `aplied` = '1'", sUsrAuthId);
	dds_hSQLDatabase.Query(SQL_UserAppliedItemLoad, sSendQuery, client);
	// 설정 정보
	Format(sSendQuery, sizeof(sSendQuery), "SELECT * FROM `dds_user_setting` WHERE `authid` = '%s'", sUsrAuthId);
	dds_hSQLDatabase.Query(SQL_UserSettingLoad, sSendQuery, client);
	// 지속 속성 아이템 확인
	Format(sSendQuery, sizeof(sSendQuery), "SELECT * FROM `dds_user_item` WHERE `authid` = '%s'", sUsrAuthId);
	dds_hSQLDatabase.Query(SQL_UserTimeItemLoad, sSendQuery, client);

	return Plugin_Stop;
}

/**
 * SQL 유저 :: 유저 정보 로드
 *
 * @param db					데이터베이스 연결 핸들
 * @param results				결과 쿼리
 * @param error					오류 문자열
 * @param client				클라이언트 인덱스
 */
public void SQL_UserLoad(Database db, DBResultSet results, const char[] error, any client)
{
	// 쿼리 오류 검출
	if (db == null || error[0])
	{
		Log_CodeError(client, 1010, error);
		return;
	}

	// 갯수 파악
	int count;

	// 임시 정보 저장
	int iTempMoney;
	char sTempRefData[256];

	// 쿼리 결과
	while (results.MoreRows)
	{
		// 제시할 행이 없다면 통과
		if (!results.FetchRow())	continue;

		// 데이터 추가
		iTempMoney = results.FetchInt(2);
		results.FetchString(5, sTempRefData, sizeof(sTempRefData));

		// 유저 파악 갯수 증가
		count++;

		#if defined _DEBUG_
		DDS_PrintToServer(":: DEBUG :: User Load - Profile Checked (client: %N, Money: %d)", client, iTempMoney);
		#endif
	}

	/** 추후 작업 **/
	char sSendQuery[256];

	// 클라이언트 고유 번호 추출
	char sUsrAuthId[20];
	GetClientAuthId(client, AuthId_SteamID64, sUsrAuthId, sizeof(sUsrAuthId));

	// 클라이언트 이름 추출 후 필터링
	char sUsrName[32];
	GetClientName(client, sUsrName, sizeof(sUsrName));
	SetPreventSQLInject(sUsrName, sUsrName, sizeof(sUsrName));

	if (count == 0)
	{
		/** 등록된 것이 없다면 정보 생성 **/
		// 오류 검출 생성
		ArrayList hMakeErr = CreateArray(8);
		hMakeErr.Push(client);
		hMakeErr.Push(1011);

		// 쿼리 전송
		Format(sSendQuery, sizeof(sSendQuery), 
			"INSERT INTO `dds_user_profile` (`idx`, `authid`, `nickname`, `money`, `ingame`, `refdata`) VALUES (NULL, '%s', '%s', '0', '1', '')", 
			sUsrAuthId, sUsrName);
		dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErr);

		#if defined _DEBUG_
		DDS_PrintToServer(":: DEBUG :: User Load - Make Profile (client: %N)", client);
		#endif
	}
	else if (count == 1)
	{
		/** 등록된 것이 있다면 정보 로드 및 갱신 **/
		// 오류 검출 생성
		ArrayList hMakeErr = CreateArray(8);
		hMakeErr.Push(client);
		hMakeErr.Push(1012);

		// 금액 로드
		dds_iUserMoney[client] = iTempMoney;

		// 참고 데이터 로드
		Format(dds_sUserRefData[client], 256, sTempRefData);

		// 인게임 처리
		Format(sSendQuery, sizeof(sSendQuery), "UPDATE `dds_user_profile` SET `nickname` = '%s', `ingame` = '1' WHERE `authid` = '%s'", sUsrName, sUsrAuthId);
		dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErr);

		#if defined _DEBUG_
		DDS_PrintToServer(":: DEBUG :: User Load - Update Profile (client: %N)", client);
		#endif
	}
	else
	{
		/** 잘못된 정보 **/
		Log_CodeError(client, 1014, "The number of this user profile db must be one.");
	}
}

/**
 * SQL 유저 :: 유저 장착 아이템 정보 로드
 *
 * @param db					데이터베이스 연결 핸들
 * @param results				결과 쿼리
 * @param error					오류 문자열
 * @param client				클라이언트 인덱스
 */
public void SQL_UserAppliedItemLoad(Database db, DBResultSet results, const char[] error, any client)
{
	// 쿼리 오류 검출
	if (db == null || error[0])
	{
		Log_CodeError(client, 1015, error);
		return;
	}

	// 갯수 파악
	int count;

	// 쿼리 결과
	while (results.MoreRows)
	{
		// 제시할 행이 없다면 통과
		if (!results.FetchRow())	continue;

		// 데이터 로드
		int iDBIdx = results.FetchInt(0);
		int iItIdx = results.FetchInt(2);

		for (int i = 0; i <= dds_iItemCategoryCount; i++)
		{
			// '전체'는 있을 수 없지만 혹시 모르니까 제외
			if (i == 0)	continue;

			// 해당 항목이 아닌 경우 제외
			if (dds_eItemList[Find_GetItemListIndex(iItIdx)][CATECODE] != dds_eItemCategoryList[i][CODE])	continue;

			dds_iUserAppliedItem[client][i][DBIDX] = iDBIdx;
			dds_iUserAppliedItem[client][i][ITEMIDX] = iItIdx;

			// 장착 아이템 파악 갯수 증가
			count++;

			#if defined _DEBUG_
			DDS_PrintToServer(":: DEBUG :: User Load - Applied Item (client: %N, dbidx: %d, itemidx: %d)", client, iDBIdx, iItIdx);
			#endif

			break;
		}
	}

	#if defined _DEBUG_
	if (count == 0)	DDS_PrintToServer(":: DEBUG :: User Load - Applied Item (client: %N, NO APPLIED ITEMS)", client);
	#endif
}

/**
 * SQL 유저 :: 유저 설정 정보 로드
 *
 * @param db					데이터베이스 연결 핸들
 * @param results				결과 쿼리
 * @param error					오류 문자열
 * @param client				클라이언트 인덱스
 */
public void SQL_UserSettingLoad(Database db, DBResultSet results, const char[] error, any client)
{
	// 쿼리 오류 검출
	if (db == null || error[0])
	{
		Log_CodeError(client, 1016, error);
		return;
	}

	// 갯수 파악
	int count;

	// 클라이언트 고유 번호 추출
	char sUsrAuthId[20];
	GetClientAuthId(client, AuthId_SteamID64, sUsrAuthId, sizeof(sUsrAuthId));

	// 쿼리 결과
	while (results.MoreRows)
	{
		// 제시할 행이 없다면 통과
		if (!results.FetchRow())	continue;

		// 데이터 로드
		char sOneCate[20];
		int iTwoCate;
		char sValue[32];
		results.FetchString(2, sOneCate, sizeof(sOneCate));
		iTwoCate = results.FetchInt(3);
		results.FetchString(4, sValue, sizeof(sValue));

		/**********************************************************
		 * sOneCate :: 첫 분류 항목
		 * 
		 * 'sys-status' - 시스템 설정(iTwoCate ~ , sValue ~ )
		 * 'item-status' - 아이템 종류 활성 상태(iTwoCate ~ 아이템 종류 코드, sValue ~ 값[0과 1])
		 *
		 **********************************************************/
		if (StrEqual(sOneCate, "sys-status", false))
		{
			/*********************************
			 * 시스템 설정
			 *********************************/
			// 
		}
		else if (StrEqual(sOneCate, "item-status", false))
		{
			/*********************************
			 * 아이템 활성 정보
			 *********************************/
			// 현재 등록되어 있는 아이템 종류 목록과 똑같이 로드
			for (int i = 0; i <= dds_iItemCategoryCount; i++)
			{
				// 있을 수 없지만 '전체' 항목은 제외
				if (i == 0)	continue;

				// 두 번째 항목이 등록되어 있는 아이템 종류 코드와 다른 경우는 제외
				if (iTwoCate != dds_eItemCategoryList[i][CODE])	continue;

				// 등록되어 있는 아이템 종류 코드의 인덱스로 기준잡아 상태 설정
				dds_eUserItemCGStatus[client][i][CATECODE] = dds_eItemCategoryList[i][CODE];
				dds_eUserItemCGStatus[client][i][VALUE] = view_as<bool>(StringToInt(sValue));

				// 갯수 증가
				count++;

				#if defined _DEBUG_
				DDS_PrintToServer(":: DEBUG :: User Load - Setting ~ Load ItemStatus (client: %N, catelistidx: %d, catecode: %d)", client, i, dds_eItemCategoryList[i][CODE]);
				#endif

				break;
			}
		}
	}

	// 갯수가 없을 때
	if (count == 0)
	{
		/** 아이템 활성 정보 생성 **/
		for (int i = 0; i <= dds_iItemCategoryCount; i++)
		{
			// '전체' 항목 통과
			if (i == 0)	continue;

			// 오류 검출 생성
			ArrayList hMakeErrT = CreateArray(8);
			hMakeErrT.Push(client);
			hMakeErrT.Push(1017);

			// 쿼리 전송
			char sSendQuery[256];
			Format(sSendQuery, sizeof(sSendQuery), 
				"INSERT INTO `dds_user_setting` (`idx`, `authid`, `onecate`, `twocate`, `setvalue`) VALUES (NULL, '%s', 'item-status', '%d', '1')", 
				sUsrAuthId, dds_eItemCategoryList[i][CODE]);
			dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrT);

			// 데이터 변경
			dds_eUserItemCGStatus[client][i][CATECODE] = dds_eItemCategoryList[i][CODE];
			dds_eUserItemCGStatus[client][i][VALUE] = true;

			#if defined _DEBUG_
			DDS_PrintToServer(":: DEBUG :: User Load - Setting ~ Make ItemStatus (client: %N, catelistidx, catecode: %d)", client, i, dds_eItemCategoryList[i][CODE]);
			#endif
		}
	}

	// SQL 유저 상태 활성화
	dds_bUserSQLStatus[client] = true;

	/** 로그 작성 **/
	Log_Data(client, "game-connect", "");
}

/**
 * SQL 유저 :: 유저 지속 속성 아이템 정보 로드
 *
 * @param db					데이터베이스 연결 핸들
 * @param results				결과 쿼리
 * @param error					오류 문자열
 * @param client				클라이언트 인덱스
 */
public void SQL_UserTimeItemLoad(Database db, DBResultSet results, const char[] error, any client)
{
	// 쿼리 오류 검출
	if (db == null || error[0])
	{
		Log_CodeError(client, 1018, error);
		return;
	}

	// 갯수 파악
	int count;

	// 쿼리 결과
	while (results.MoreRows)
	{
		// 제시할 행이 없다면 통과
		if (!results.FetchRow())	continue;

		// 데이터 로드
		int iDBIdx = results.FetchInt(0);
		int iItIdx = results.FetchInt(2);
		char sBuyDate[20];
		results.FetchString(4, sBuyDate, sizeof(sBuyDate));

		int iBuyDate = StringToInt(sBuyDate);
		int iCurItTime = dds_eItemList[Find_GetItemListIndex(iItIdx)][HAVTIME];

		if (iBuyDate < 0)
		{
			// 없음
		}
		else if (iBuyDate > 0)
		{
			// 시간이 아직 남았다면 통과
			if (GetTime() <= (iBuyDate + iCurItTime))	continue;

			// 아이템 삭제
		}
	}

	#if defined _DEBUG_
	if (count == 0)	DDS_PrintToServer(":: DEBUG :: User Load - Time Item (client: %N)", client);
	#endif
}


/**
 * 메뉴 핸들 :: 메인 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlMain(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));
		int iInfo = StringToInt(sInfo);

		switch (iInfo)
		{
			case 1:
			{
				// 내 프로필
				Menu_Profile(client, "main-menu");
			}
			case 2:
			{
				// 내 장착 아이템
				Menu_CurItem(client);
			}
			case 3:
			{
				// 내 인벤토리
				Menu_Inven(client, 0);
			}
			case 4:
			{
				// 아이템 구매
				Menu_BuyItem(client);
			}
			case 5:
			{
				// 설정
				Menu_Setting(client);
			}
			case 9:
			{
				// 플러그인 정보
				Menu_PluginInfo(client);
			}
		}
	}
}

/**
 * 메뉴 핸들 :: 프로필 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlProfile(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));
		int iInfo = StringToInt(sInfo);

		switch (iInfo)
		{
			default:
			{
				// 없음
			}
		}
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_Main(client, 0);
		}
	}
}

/**
 * 메뉴 핸들 :: 내 장착 아이템 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlCurItem(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));
		int iInfo = StringToInt(sInfo);

		/**
		 * iInfo
		 * 
		 * @Desc 등록된 아이템 종류 코드 ('전체' 없음)
		 */
		// 클라이언트 구분
		char sUsrAuthId[20];
		GetClientAuthId(client, AuthId_SteamID64, sUsrAuthId, sizeof(sUsrAuthId));

		// 파라메터 생성
		ArrayList sSendParam = CreateArray(12);
		sSendParam.Push(client);
		sSendParam.Push(iInfo);

		// 쿼리 전송
		char sSendQuery[256];
		Format(sSendQuery, sizeof(sSendQuery), "SELECT * FROM `dds_user_item` WHERE `authid` = '%s' ORDER BY `idx` DESC", sUsrAuthId);
		dds_hSQLDatabase.Query(Menu_CurItem_CateIn, sSendQuery, sSendParam);
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_Main(client, 0);
		}
	}
}

/**
 * 메뉴 핸들 :: 내 장착 아이템-종류 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlCurItem_CateIn(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));

		// 파라메터 분리
		char sExpStr[3][16];
		ExplodeString(sInfo, "||", sExpStr, sizeof(sExpStr), sizeof(sExpStr[]));

		/**
		 * sExpStr
		 * 
		 * @Desc [0] - 데이터베이스 번호([2]가 0일 경우: 아이템 종류 코드), [1] - 아이템 번호([2]가 0일 경우: 아이템 종류 코드), [2] 장착 행동 구분
		 */
		switch (StringToInt(sExpStr[2]))
		{
			case 0:
			{
				// 장착 해제
				System_DataProcess(client, "curitem-cancel", sExpStr[1]);
			}
			case 1:
			{
				// 장착 가능한 것들
				char sSendParam[32];
				Format(sSendParam, sizeof(sSendParam), "%d||%d", StringToInt(sExpStr[0]), StringToInt(sExpStr[1]));
				System_DataProcess(client, "curitem-use", sSendParam);
			}
		}
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_CurItem(client);
		}
	}
}

/**
 * 메뉴 핸들 :: 내 인벤토리 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlInven(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));
		int iInfo = StringToInt(sInfo);

		/**
		 * iInfo
		 * 
		 * @Desc 등록된 아이템 종류 코드
		 */
		// 클라이언트 구분
		char sUsrAuthId[20];
		GetClientAuthId(client, AuthId_SteamID64, sUsrAuthId, sizeof(sUsrAuthId));

		// 파라메터 생성
		ArrayList sSendParam = CreateArray(12);
		sSendParam.Push(client);
		sSendParam.Push(iInfo);

		// 쿼리 전송
		char sSendQuery[256];
		Format(sSendQuery, sizeof(sSendQuery), "SELECT * FROM `dds_user_item` WHERE `authid` = '%s' ORDER BY `idx` DESC", sUsrAuthId);
		dds_hSQLDatabase.Query(Menu_Inven_CateIn, sSendQuery, sSendParam);
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_Main(client, 0);
		}
	}
}

/**
 * 메뉴 핸들 :: 내 인벤토리-종류 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlInven_CateIn(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));

		// 파라메터 분리
		char sExpStr[2][16];
		ExplodeString(sInfo, "||", sExpStr, sizeof(sExpStr), sizeof(sExpStr[]));

		/**
		 * sExpStr
		 * 
		 * @Desc ('||' 기준 배열 분리) [0] - 데이터베이스 번호, [1] - 아이템 번호
		 */
		Menu_Inven_ItemDetail(client, StringToInt(sExpStr[0]), StringToInt(sExpStr[1]));
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_Inven(client, 0);
		}
	}
}

/**
 * 메뉴 핸들 :: 내 인벤토리-정보 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlInven_ItemDetail(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	// Back 준비
	//int iBackDBIdx;
	int iBackItemIdx;
	//int iAction;

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));

		// 파라메터 분리
		char sExpStr[3][16];
		ExplodeString(sInfo, "||", sExpStr, sizeof(sExpStr), sizeof(sExpStr[]));

		/**
		 * sExpStr
		 * 
		 * @Desc ('||' 기준 배열 분리) [0] - 데이터베이스 번호, [1] - 아이템 번호, [2] - 행동(1 - 사용 / 2 - 판매 / 3 - 선물 / 4 - 버리기)
		 */
		// Back 준비
		iBackItemIdx = StringToInt(sExpStr[1]);

		// 행동 구분
		switch (StringToInt(sExpStr[2]))
		{
			case 1:
			{
				// 사용
				char sSendParam[32];
				Format(sSendParam, sizeof(sSendParam), "%d||%d", StringToInt(sExpStr[0]), StringToInt(sExpStr[1]));
				System_DataProcess(client, "inven-use", sSendParam);
			}
			case 2:
			{
				// 되팔기
				char sSendParam[32];
				Format(sSendParam, sizeof(sSendParam), "%d||%d", StringToInt(sExpStr[0]), StringToInt(sExpStr[1]));
				System_DataProcess(client, "inven-resell", sSendParam);
			}
			case 3:
			{
				// 선물
				char sSendParam[32];
				Format(sSendParam, sizeof(sSendParam), "%d||%d", StringToInt(sExpStr[0]), StringToInt(sExpStr[1]));
				Menu_ItemGift(client, sSendParam);
			}
			case 4:
			{
				// 버리기
				char sSendParam[32];
				Format(sSendParam, sizeof(sSendParam), "%d||%d", StringToInt(sExpStr[0]), StringToInt(sExpStr[1]));
				System_DataProcess(client, "inven-drop", sSendParam);
			}
		}
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			// 클라이언트 구분
			char sUsrAuthId[20];
			GetClientAuthId(client, AuthId_SteamID64, sUsrAuthId, sizeof(sUsrAuthId));

			// 파라메터 생성
			ArrayList sSendParam = CreateArray(8);
			sSendParam.Push(client);
			sSendParam.Push(dds_eItemList[Find_GetItemListIndex(iBackItemIdx)][CATECODE]);

			// 쿼리 전송
			char sSendQuery[256];
			Format(sSendQuery, sizeof(sSendQuery), "SELECT * FROM `dds_user_item` WHERE `authid` = '%s'", sUsrAuthId);
			dds_hSQLDatabase.Query(Menu_Inven_CateIn, sSendQuery, sSendParam);
		}
	}
}

/**
 * 메뉴 핸들 :: 아이템 구매 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlBuyItem(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));
		int iInfo = StringToInt(sInfo);

		/**
		 * iInfo
		 * 
		 * @Desc 등록된 아이템 종류 코드
		 */
		Menu_BuyItem_CateIn(client, iInfo);
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_Main(client, 0);
		}
	}
}

/**
 * 메뉴 핸들 :: 아이템 구매-종류 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlBuyItem_CateIn(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));
		int iInfo = StringToInt(sInfo);

		/**
		 * iInfo
		 * 
		 * @Desc 등록된 아이템 번호
		 */
		Menu_BuyItem_ItemDetail(client, iInfo);
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_BuyItem(client);
		}
	}
}

/**
 * 메뉴 핸들 :: 아이템 구매-정보 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlBuyItem_ItemDetail(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));

		// 파라메터 분리
		char sGetParam[3][8];
		ExplodeString(sInfo, "||", sGetParam, sizeof(sGetParam), sizeof(sGetParam[]));

		/**
		 * sGetParam
		 * 
		 * @Desc ('||' 기준 배열 분리) [0] - 아이템 번호, [1] - 아이템 종류 코드, [2] 행동(1 - 확인 / 2- 취소)
		 */
		switch (StringToInt(sGetParam[2]))
		{
			case 1:
			{
				// 확인
				char sSendParam[32];
				Format(sSendParam, sizeof(sSendParam), "%d", StringToInt(sGetParam[0]));
				System_DataProcess(client, "buy", sSendParam);
			}
			case 2:
			{
				// 취소
				// 없음(그냥 닫게 만듬)
			}
		}
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			// 선택한 아이템 종류 항목으로 돌아가게 처리
			char sInfo[32];
			menu.GetItem(item, sInfo, sizeof(sInfo));

			// 파라메터 분리
			char sGetParam[3][8];
			ExplodeString(sInfo, "||", sGetParam, sizeof(sGetParam), sizeof(sGetParam[]));

			Menu_BuyItem_CateIn(client, StringToInt(sGetParam[1]));
		}
	}
}


/**
 * 메뉴 핸들 :: 설정 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlSetting(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));
		int iInfo = StringToInt(sInfo);

		switch (iInfo)
		{
			/**
			 * iInfo
			 * 
			 * @Desc 1 - 시스템 설정, 2 - 아이템 활성화 상태 설정
			 */
			case 1:
			{
				// 시스템 설정
				Menu_Setting_System(client);
			}
			case 2:
			{
				// 아이템 설정
				Menu_Setting_Item(client);
			}
		}
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_Main(client, 0);
		}
	}
}

/**
 * 메뉴 핸들 :: 설정-시스템 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlSetting_System(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));
		int iInfo = StringToInt(sInfo);

		switch (iInfo)
		{
			/**
			 * iInfo
			 * 
			 * @Desc 아직 없음
			 */
			case 1:
			{
				// 아직 없음
			}
		}
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_Setting(client);
		}
	}
}

/**
 * 메뉴 핸들 :: 설정-아이템 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlSetting_Item(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));
		int iInfo = StringToInt(sInfo);

		/**
		 * iInfo
		 * 
		 * @Desc 등록된 아이템 종류 인덱스
		 */
		// 클라이언트 고유 번호 추출
		char sUsrAuthId[20];
		GetClientAuthId(client, AuthId_SteamID64, sUsrAuthId, sizeof(sUsrAuthId));

		/** 실제 값 변경 **/
		if (dds_eUserItemCGStatus[client][iInfo][VALUE])
		{
			// SQL 데이터베이스가 활성화되어 있지 않다면 작동 안함
			if (!dds_bSQLStatus)
			{
				DDS_PrintToChat(client, "%t", "error sqlstatus server");
				Menu_Setting(client);
				return;
			}

			// 유저의 SQL 데이터베이스 상태가 활성화되어 있지 않다면 작동 안함
			if (!dds_bUserSQLStatus[client])
			{
				DDS_PrintToChat(client, "%t", "error sqlstatus user");
				Menu_Setting(client);
				return;
			}

			dds_eUserItemCGStatus[client][iInfo][VALUE] = false;

			// 오류 검출 생성
			ArrayList hMakeErr = CreateArray(8);
			hMakeErr.Push(client);
			hMakeErr.Push(1022);

			// 데이터베이스 값 변경
			char sSendQuery[256];
			Format(sSendQuery, sizeof(sSendQuery), 
				"UPDATE `dds_user_setting` SET `setvalue` = '%d' WHERE `authid` = '%s' and `onecate` = 'item-status' and `twocate` = '%d'", 
				0, sUsrAuthId, dds_eUserItemCGStatus[client][iInfo][CATECODE]);
			dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErr);
		}
		else
		{
			// SQL 데이터베이스가 활성화되어 있지 않다면 작동 안함
			if (!dds_bSQLStatus)
			{
				DDS_PrintToChat(client, "%t", "error sqlstatus server");
				Menu_Setting(client);
				return;
			}

			// 유저의 SQL 데이터베이스 상태가 활성화되어 있지 않다면 작동 안함
			if (!dds_bUserSQLStatus[client])
			{
				DDS_PrintToChat(client, "%t", "error sqlstatus user");
				Menu_Setting(client);
				return;
			}

			dds_eUserItemCGStatus[client][iInfo][VALUE] = true;

			// 오류 검출 생성
			ArrayList hMakeErr = CreateArray(8);
			hMakeErr.Push(client);
			hMakeErr.Push(1022);

			// 데이터베이스 값 변경
			char sSendQuery[256];
			Format(sSendQuery, sizeof(sSendQuery), 
				"UPDATE `dds_user_setting` SET `setvalue` = '%d' WHERE `authid` = '%s' and `onecate` = 'item-status' and `twocate` = '%d'", 
				1, sUsrAuthId, dds_eUserItemCGStatus[client][iInfo][CATECODE]);
			dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErr);
		}

		// 다시 메뉴 출력
		Menu_Setting_Item(client);
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_Setting(client);
		}
	}
}

/**
 * 메뉴 핸들 :: 플러그인 정보 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlPluginInfo(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));
		int iInfo = StringToInt(sInfo);

		/**
		 * iInfo
		 * 
		 * @Desc 1 - 명령어 정보, 2 - 개발자 정보, 3 - 저작권 정보
		 */
		if ((iInfo > 0) && (iInfo < 4))
		{
			Menu_PluginInfo_Detail(client, iInfo);
		}
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_Main(client, 0);
		}
	}
}

/**
 * 메뉴 핸들 :: 플러그인 정보-세부 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlPluginInfo_Detail(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));
		int iInfo = StringToInt(sInfo);

		switch (iInfo)
		{
			/**
			 * iInfo
			 * 
			 * @Desc 없음
			 */
			default:
			{
				// 없음
			}
		}
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_PluginInfo(client);
		}
	}
}

/**
 * 메뉴 핸들 :: 아이템 선물 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlItemGift(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));

		// 파라메터 분리
		char sExpStr[3][32];
		ExplodeString(sInfo, "||", sExpStr, sizeof(sExpStr), sizeof(sExpStr[]));

		/**
		 * sExpStr
		 * 
		 * @Desc ('||' 기준 배열 분리) [0] - 대상 클라이언트 유저 ID, [1] - 데이터베이스 번호, [2] - 아이템 번호
		 *
		 */
		char sSendParam[32];
		Format(sSendParam, sizeof(sSendParam), "%d||%d||%d", StringToInt(sExpStr[1]), StringToInt(sExpStr[2]), StringToInt(sExpStr[0]));
		System_DataProcess(client, "inven-gift", sSendParam);
	}
}

/**
 * 메뉴 핸들 :: 데이터베이스 초기화 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlInitDatabase(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));
		int iInfo = StringToInt(sInfo);

		/**
		 * iInfo
		 * 
		 * @Desc 1 - 유저, 2 - 모두
		 *
		 */
		Menu_InitDatabase_Warn(client, iInfo);
	}
}

/**
 * 메뉴 핸들 :: 데이터베이스 초기화-경고 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlInitDatabase_Warn(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));

		// 파라메터 분리
		char sExpStr[2][24];
		ExplodeString(sInfo, "||", sExpStr, sizeof(sExpStr), sizeof(sExpStr[]));

		/**
		 * sExpStr
		 * 
		 * @Desc ('||' 기준 배열 분리) [0] - 행동 구분, [1] - 확인/취소
		 *
		 */
		switch (StringToInt(sExpStr[1]))
		{
			/* 확인 */
			case 1:
			{
				if (StringToInt(sExpStr[0]) == 1)
				{
					/* 유저만 초기화 */
					int stepcount = 5;

					for (int i = 0; i < stepcount; i++)
					{
						ArrayList hMakeErr = CreateArray(8);
						hMakeErr.Push(client);
						hMakeErr.Push(2023);

						char sSendQuery[128];
						switch (i)
						{
							case 0:
							{
								Format(sSendQuery, sizeof(sSendQuery), "DELETE FROM `dds_user_profile`");
							}
							case 1:
							{
								Format(sSendQuery, sizeof(sSendQuery), "DELETE FROM `dds_user_item`");
							}
							case 2:
							{
								Format(sSendQuery, sizeof(sSendQuery), "DELETE FROM `dds_user_setting`");
							}
							case 3:
							{
								Format(sSendQuery, sizeof(sSendQuery), "DELETE FROM `dds_log_data`");
							}
							case 4:
							{
								Format(sSendQuery, sizeof(sSendQuery), "DELETE FROM `dds_sessions`");
							}
						}
						dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErr);
					}

					// 완료 출력
					DDS_PrintToChat(client, "%t", "system initdatabase complete");
				}
				else if (StringToInt(sExpStr[0]) == 2)
				{
					/* 모두 초기화 */
					int stepcount = 7;

					for (int i = 0; i < stepcount; i++)
					{
						ArrayList hMakeErr = CreateArray(8);
						hMakeErr.Push(client);
						hMakeErr.Push(2022);

						char sSendQuery[128];
						switch (i)
						{
							case 0:
							{
								Format(sSendQuery, sizeof(sSendQuery), "DELETE FROM `dds_user_profile`");
							}
							case 1:
							{
								Format(sSendQuery, sizeof(sSendQuery), "DELETE FROM `dds_user_item`");
							}
							case 2:
							{
								Format(sSendQuery, sizeof(sSendQuery), "DELETE FROM `dds_user_setting`");
							}
							case 3:
							{
								Format(sSendQuery, sizeof(sSendQuery), "DELETE FROM `dds_log_data`");
							}
							case 4:
							{
								Format(sSendQuery, sizeof(sSendQuery), "DELETE FROM `dds_item_category`");
							}
							case 5:
							{
								Format(sSendQuery, sizeof(sSendQuery), "DELETE FROM `dds_item_list`");
							}
							case 6:
							{
								Format(sSendQuery, sizeof(sSendQuery), "DELETE FROM `dds_sessions`");
							}
						}
						dds_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErr);
					}

					// 완료 출력
					DDS_PrintToChat(client, "%t", "system initdatabase complete");
				}
			}
			/* 취소 */
			case 2:
			{
				// 할 필요 없음
			}
		}
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_InitDatabase(client);
		}
	}
}

/**
 * 메뉴 핸들 :: 아이템 주기 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlItemGive(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));
		int iInfo = StringToInt(sInfo);

		/**
		 * iInfo
		 * 
		 * @Desc 등록된 아이템 종류 코드
		 */
		Menu_ItemGive_CateIn(client, iInfo);
	}
}

/**
 * 메뉴 핸들 :: 아이템 주기-종류 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlItemGive_CateIn(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));
		int iInfo = StringToInt(sInfo);

		/**
		 * iInfo
		 * 
		 * @Desc 등록된 아이템 번호
		 */
		Menu_ItemGive_Target(client, iInfo);
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_ItemGive(client);
		}
	}
}

/**
 * 메뉴 핸들 :: 아이템 주기-대상 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlItemGive_Target(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	// Back 준비
	int iBackCGCode;

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));

		// 파라메터 분리
		char sExpStr[3][32];
		ExplodeString(sInfo, "||", sExpStr, sizeof(sExpStr), sizeof(sExpStr[]));

		/**
		 * sExpStr
		 * 
		 * @Desc ('||' 기준 배열 분리) [0] - 대상 클라이언트 유저 ID, [1] - 아이템 번호
		 *
		 */
		iBackCGCode = dds_eItemList[Find_GetItemListIndex(StringToInt(sExpStr[1]))][CATECODE];

		char sSendParam[32];
		Format(sSendParam, sizeof(sSendParam), "%d||%d", StringToInt(sExpStr[1]), StringToInt(sExpStr[0]));
		System_DataProcess(client, "item-give", sSendParam);
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_ItemGive_CateIn(client, iBackCGCode);
		}
	}
}

/**
 * 메뉴 핸들 :: 아이템 뺏기-대상 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlItemTakeAWay(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));
		int iInfo = StringToInt(sInfo);

		/**
		 * iInfo
		 * 
		 * @Desc 대상 클라이언트 유저 ID
		 */
		// 대상 클라이언트 구분
		int iTarget = GetClientOfUserId(iInfo);
		char sTarAuthId[20];
		GetClientAuthId(iTarget, AuthId_SteamID64, sTarAuthId, sizeof(sTarAuthId));

		// 파라메터 생성
		ArrayList sSendParam = CreateArray(12);
		sSendParam.Push(client);
		sSendParam.Push(iInfo);

		// 쿼리 전송
		char sSendQuery[256];
		Format(sSendQuery, sizeof(sSendQuery), "SELECT * FROM `dds_user_item` WHERE `authid` = '%s' ORDER BY `idx` DESC", sTarAuthId);
		dds_hSQLDatabase.Query(Menu_ItemTakeAWay_CateIn, sSendQuery, sSendParam);
	}
}

/**
 * 메뉴 핸들 :: 아이템 뺏기-전체 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlItemTakeAWay_CateIn(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));

		// 파라메터 분리
		char sExpStr[4][16];
		ExplodeString(sInfo, "||", sExpStr, sizeof(sExpStr), sizeof(sExpStr[]));

		/**
		 * sExpStr
		 * 
		 * @Desc ('||' 기준 배열 분리) [0] - 데이터베이스 번호, [1] - 아이템 번호, [2] - 아이템 장착 유무, [3] - 대상 클라이언트 유저 ID
		 */
		// 
		char sSendParam[32];

		// 장착되어 있으면 장착 해제 처리
		if (StringToInt(sExpStr[2]) == 1)
		{
			int iTarget = GetClientOfUserId(StringToInt(sExpStr[3]));
			Format(sSendParam, sizeof(sSendParam), "%d", dds_eItemList[Find_GetItemListIndex(StringToInt(sExpStr[1]))][CATECODE]);
			System_DataProcess(iTarget, "curitem-cancel", sSendParam);
		}

		// 그리고 빼앗음
		Format(sSendParam, sizeof(sSendParam), "%d||%d||%d", StringToInt(sExpStr[0]), StringToInt(sExpStr[1]), StringToInt(sExpStr[3]));
		System_DataProcess(client, "item-takeaway", sSendParam);
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_ItemTakeAWay(client);
		}
	}
}


/*******************************************************
 * N A T I V E  &  F O R W A R D  F U N C T I O N S
*******************************************************/
/**
 * Native :: DDS_IsPluginOn
 *
 * @brief	DDS 플러그인의 활성화 여부
 */
public int Native_DDS_IsPluginOn(Handle:plugin, numParams)
{
	return dds_hCV_PluginSwitch.BoolValue;
}

/**
 * Native :: DDS_GetServerSQLStatus
 *
 * @brief	DDS 플러그인의 SQL 서버 활성 여부
 */
public int Native_DDS_GetServerSQLStatus(Handle:plugin, numParams)
{
	return dds_bSQLStatus;
}

/**
 * Native :: DDS_GetClientSQLStatus
 *
 * @brief	클라이언트 별 SQL 활성 여부
 */
public int Native_DDS_GetClientSQLStatus(Handle:plugin, numParams)
{
	int client = GetNativeCell(1);

	return dds_bUserSQLStatus[client];
}

/**
 * Native :: DDS_CreateItemCategory
 *
 * @brief	DDS 플러그인에 아이템 종류 플러그인 연결
 */
public int Native_DDS_CreateItemCategory(Handle:plugin, numParams)
{
	int catecode = GetNativeCell(1);

	System_ValidateItemCG(catecode);
}

/**
 * Native :: DDS_GetItemCategoryStatus
 *
 * @brief	DDS 플러그인에 연결된 아이템 종류 플러그인 상태
 */
public int Native_DDS_GetItemCategoryStatus(Handle:plugin, numParams)
{
	int catecode = GetNativeCell(1);

	for (int i = 0; i <= dds_iItemCategoryCount; i++)
	{
		// '전체'는 통과
		if (i == 0)	continue;

		if (dds_eItemCategoryList[i][CODE] == catecode)
			return dds_eItemCategoryList[i][STATUS];
	}

	return false;
}

/**
 * Native :: DDS_GetItemInfo
 *
 * @brief	등록되어 있는 아이템 목록 반환
 */
public int Native_DDS_GetItemInfo(Handle:plugin, numParams)
{
	int itemidx = GetNativeCell(1);
	ItemInfo proctype = GetNativeCell(2);
	bool raw = view_as<bool>(GetNativeCell(4));

	// 데이터베이스 연결 확인
	if (dds_hSQLDatabase == null || !dds_bSQLStatus)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Server Database is not available.", DDS_ENV_CORE_CHAT_GLOPREFIX);
		return false;
	}

	// '0'은 될 수 없음
	if (itemidx == 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Item Index should be more than 0. (Item Idx %d)", DDS_ENV_CORE_CHAT_GLOPREFIX, itemidx);
		return false;
	}

	// 목록 번호로 치환이 안된 경우
	int selectidx;
	if (!raw)
	{
		// 해당 코드가 있는지 검증
		selectidx = Find_GetItemListIndex(itemidx);

		// 발견하지 못했다면 안함
		if (selectidx == 0)
		{
			ThrowNativeError(SP_ERROR_NATIVE, "%s Item Index %d is not registered.", DDS_ENV_CORE_CHAT_GLOPREFIX, itemidx);
			return false;
		}
	}

	char result[DDS_ENV_VAR_ENV_SIZE];

	// 처리 구분
	switch (proctype)
	{
		case ItemInfo_INDEX:
		{
			Format(result, sizeof(result), "%d", dds_eItemList[(raw ? itemidx : selectidx)][INDEX]);
		}
		case ItemInfo_NAME:
		{
			Format(result, sizeof(result), dds_eItemList[(raw ? itemidx : selectidx)][NAME]);
		}
		case ItemInfo_CATECODE:
		{
			Format(result, sizeof(result), "%d", dds_eItemList[(raw ? itemidx : selectidx)][CATECODE]);
		}
		case ItemInfo_MONEY:
		{
			Format(result, sizeof(result), "%d", dds_eItemList[(raw ? itemidx : selectidx)][MONEY]);
		}
		case ItemInfo_HAVTIME:
		{
			Format(result, sizeof(result), "%d", dds_eItemList[(raw ? itemidx : selectidx)][HAVTIME]);
		}
		case ItemInfo_ENV:
		{
			Format(result, sizeof(result), dds_eItemList[(raw ? itemidx : selectidx)][ENV]);
		}
	}

	SetNativeString(3, result, sizeof(result), true);

	return true;
}

/**
 * Native :: DDS_GetItemCount
 *
 * @brief	DDS 플러그인에 등록된 아이템들의 총 갯수를 반환
 */
public int Native_DDS_GetItemCount(Handle:plugin, numParams)
{
	return dds_iItemCount;
}

/**
 * Native :: DDS_GetItemCategoryInfo
 *
 * @brief	등록되어 있는 아이템 종류 목록 반환
 */
public int Native_DDS_GetItemCategoryInfo(Handle:plugin, numParams)
{
	int catecode = GetNativeCell(1);
	ItemCategoryInfo proctype = GetNativeCell(2);
	bool raw = view_as<bool>(GetNativeCell(4));

	// 데이터베이스 연결 확인
	if (dds_hSQLDatabase == null || !dds_bSQLStatus)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Server Database is not available.", DDS_ENV_CORE_CHAT_GLOPREFIX);
		return false;
	}

	// '전체'는 될 수 없음
	if (catecode == 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Item Category Code should be more than 0. (Item Category Code %d)", DDS_ENV_CORE_CHAT_GLOPREFIX, catecode);
		return false;
	}

	// 목록 번호로 치환이 안된 경우
	int selectidx;
	if (!raw)
	{
		// 해당 코드가 있는지 검증
		selectidx = Find_GetItemCGListIndex(catecode);

		// 발견하지 못했다면 안함
		if (selectidx == 0)
		{
			ThrowNativeError(SP_ERROR_NATIVE, "%s Item Category Code %d is not registered.", DDS_ENV_CORE_CHAT_GLOPREFIX, catecode);
			return false;
		}
	}

	char result[DDS_ENV_VAR_ENV_SIZE];

	// 처리 구분
	switch (proctype)
	{
		case ItemCGInfo_NAME:
		{
			Format(result, sizeof(result), dds_eItemCategoryList[(raw ? catecode : selectidx)][NAME]);
		}
		case ItemCGInfo_CODE:
		{
			Format(result, sizeof(result), "%d", dds_eItemCategoryList[(raw ? catecode : selectidx)][CODE]);
		}
		case ItemCGInfo_ENV:
		{
			Format(result, sizeof(result), dds_eItemCategoryList[(raw ? catecode : selectidx)][ENV]);
		}
		case ItemCGInfo_STATUS:
		{
			Format(result, sizeof(result), "%d", dds_eItemCategoryList[(raw ? catecode : selectidx)][STATUS]);
		}
	}

	SetNativeString(3, result, sizeof(result), true);

	return true;
}

/**
 * Native :: DDS_GetItemCategoryCount
 *
 * @brief	DDS 플러그인에 등록된 아이템들의 총 갯수를 반환
 */
public int Native_DDS_GetItemCategoryCount(Handle:plugin, numParams)
{
	return dds_iItemCategoryCount;
}

/**
 * Native :: DDS_GetClientMoney
 *
 * @brief	클라이언트의 금액 반환
 */
public int Native_DDS_GetClientMoney(Handle:plugin, numParams)
{
	int client = GetNativeCell(1);

	// 클라이언트가 인증 절차를 밝았는지의 여부
	if (!IsClientAuthorized(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s client %d is not authorized.", DDS_ENV_CORE_CHAT_GLOPREFIX, client);
		return -1;
	}

	// 클라이언트가 봇인지 여부
	if (IsFakeClient(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s client %d is a bot. We don't support this bot client.", DDS_ENV_CORE_CHAT_GLOPREFIX, client);
		return -1;
	}

	return dds_iUserMoney[client];
}

/**
 * Native :: DDS_SetClientMoney
 *
 * @brief	클라이언트의 금액 설정
 */
public int Native_DDS_SetClientMoney(Handle:plugin, numParams)
{
	int client = GetNativeCell(1);
	DataProcess process = GetNativeCell(2);
	int amount = GetNativeCell(3);

	// 클라이언트가 인증 절차를 밝았는지의 여부
	if (!IsClientAuthorized(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s client %d is not authorized.", DDS_ENV_CORE_CHAT_GLOPREFIX, client);
		return false;
	}

	// 클라이언트가 봇인지 여부
	if (IsFakeClient(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s client %d is a bot. We don't support this bot client.", DDS_ENV_CORE_CHAT_GLOPREFIX, client);
		return false;
	}

	// 추가 파라메터 값이 
	if (amount > 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s money amount should be upper integer.", DDS_ENV_CORE_CHAT_GLOPREFIX, amount);
		return false;
	}

	// 행동 구분이 금액 증가 또는 감소가 아니면 안됨
	if (process != DataProc_MONEYUP && process != DataProc_MONEYDOWN)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Process of 'DDS_SetClientMoney' should be money up or down.", DDS_ENV_CORE_CHAT_GLOPREFIX);
		return false;
	}

	// 전달 파라메터 준비
	char sSendParam[128];
	Format(sSendParam, sizeof(sSendParam), "%d||%d", 2024, amount);

	return DDS_UseDataProcess(client, process, sSendParam);
}

/**
 * Native :: DDS_GetClientAppliedDB
 *
 * @brief	클라이언트가 현재 장착한 아이템의 데이터베이스 번호 반환
 */
public int Native_DDS_GetClientAppliedDB(Handle:plugin, numParams)
{
	int client = GetNativeCell(1);
	int catecode = GetNativeCell(2);

	// 클라이언트가 인증 절차를 밝았는지의 여부
	if (!IsClientAuthorized(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s client %d is not authorized.", DDS_ENV_CORE_CHAT_GLOPREFIX, client);
		return -1;
	}

	// 클라이언트가 봇인지 여부
	if (IsFakeClient(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s client %d is a bot. We don't support this bot client.", DDS_ENV_CORE_CHAT_GLOPREFIX, client);
		return -1;
	}

	// 전달받은 아이템 종류 번호가 0 이상인지 여부
	if (catecode <= 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s catecode %d should be more than 0.", DDS_ENV_CORE_CHAT_GLOPREFIX, catecode);
		return -1;
	}

	return dds_iUserAppliedItem[client][catecode][DBIDX];
}

/**
 * Native :: DDS_GetClientAppliedItem
 *
 * @brief	클라이언트가 현재 장착한 아이템 번호 반환
 */
public int Native_DDS_GetClientAppliedItem(Handle:plugin, numParams)
{
	int client = GetNativeCell(1);
	int catecode = GetNativeCell(2);

	// 클라이언트가 인증 절차를 밝았는지의 여부
	if (!IsClientAuthorized(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s client %d is not authorized.", DDS_ENV_CORE_CHAT_GLOPREFIX, client);
		return -1;
	}

	// 클라이언트가 봇인지 여부
	if (IsFakeClient(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s client %d is a bot. We don't support this bot client.", DDS_ENV_CORE_CHAT_GLOPREFIX, client);
		return -1;
	}

	// 전달받은 아이템 종류 번호가 0 이상인지 여부
	if (catecode <= 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s catecode %d should be more than 0.", DDS_ENV_CORE_CHAT_GLOPREFIX, catecode);
		return -1;
	}

	return dds_iUserAppliedItem[client][catecode][ITEMIDX];
}

/**
 * Native :: DDS_GetClientItemCategorySetting
 *
 * @brief	클라이언트의 아이템 종류별 활성화 여부
 */
public int Native_DDS_GetClientItemCategorySetting(Handle:plugin, numParams)
{
	int client = GetNativeCell(1);
	int catecode = GetNativeCell(2);

	// 클라이언트가 인증 절차를 밝았는지의 여부
	if (!IsClientAuthorized(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s client %d is not authorized.", DDS_ENV_CORE_CHAT_GLOPREFIX, client);
		return false;
	}

	// 클라이언트가 봇인지 여부
	if (IsFakeClient(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s client %d is a bot. We don't support this bot client.", DDS_ENV_CORE_CHAT_GLOPREFIX, client);
		return false;
	}

	// 전달받은 아이템 종류 번호가 0 이상인지 여부
	if (catecode <= 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s catecode %d should be more than 0.", DDS_ENV_CORE_CHAT_GLOPREFIX, catecode);
		return false;
	}

	// 해당 코드가 있는지 검증
	int selectidx = Find_GetItemCGListIndex(catecode);

	// 발견하지 못했다면 안함
	if (selectidx == 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Item Category Code %d is not registered.", DDS_ENV_CORE_CHAT_GLOPREFIX, catecode);
		return false;
	}

	return dds_eUserItemCGStatus[client][selectidx][VALUE];
}

/**
 * Native :: DDS_GetClientRefData
 *
 * @brief	클라이언트이 기타 참고 데이터를 반환
 */
public int Native_DDS_GetClientRefData(Handle:plugin, numParams)
{
	int client = GetNativeCell(1);

	// 클라이언트가 인증 절차를 밝았는지의 여부
	if (!IsClientAuthorized(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s client %d is not authorized.", DDS_ENV_CORE_CHAT_GLOPREFIX, client);
		return false;
	}

	// 클라이언트가 봇인지 여부
	if (IsFakeClient(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s client %d is a bot. We don't support this bot client.", DDS_ENV_CORE_CHAT_GLOPREFIX, client);
		return false;
	}

	SetNativeString(2, dds_sUserRefData[client], 256);

	return true;
}

/**
 * Native :: DDS_UseDataProcess
 *
 * @brief	DDS 플러그인에 있는 데이터 처리 시스템을 이용
 */
public int Native_DDS_UseDataProcess(Handle:plugin, numParams)
{
	int client = GetNativeCell(1);
	DataProcess process = GetNativeCell(2);
	char data[128];
	GetNativeString(3, data, sizeof(data));

	// 클라이언트가 인증 절차를 밝았는지의 여부
	if (!IsClientAuthorized(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s client %d is not authorized.", DDS_ENV_CORE_CHAT_GLOPREFIX, client);
		return false;
	}

	// 클라이언트가 봇인지 여부
	if (IsFakeClient(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s client %d is a bot. We don't support this bot client.", DDS_ENV_CORE_CHAT_GLOPREFIX, client);
		return false;
	}

	char sSelectStr[32];

	switch (process)
	{
		case DataProc_BUY:
		{
			// 아이템 구매
			Format(sSelectStr, sizeof(sSelectStr), "buy");
		}
		case DataProc_USE:
		{
			// 인벤토리에서의 아이템 사용하기
			Format(sSelectStr, sizeof(sSelectStr), "inven-use");
		}
		case DataProc_RESELL:
		{
			// 인벤토리에서의 아이템 되팔기
			Format(sSelectStr, sizeof(sSelectStr), "inven-resell");
		}
		case DataProc_GIFT:
		{
			// 인벤토리에서의 아이템 선물하기
			Format(sSelectStr, sizeof(sSelectStr), "inven-gift");
		}
		case DataProc_DROP:
		{
			// 인벤토리에서의 아이템 버리기
			Format(sSelectStr, sizeof(sSelectStr), "inven-drop");
		}
		case DataProc_CURCANCEL:
		{
			// 내 장착 아이템에서의 장착 해제
			Format(sSelectStr, sizeof(sSelectStr), "curitem-cancel");
		}
		case DataProc_CURUSE:
		{
			// 내 장착 아이템에서의 장착
			Format(sSelectStr, sizeof(sSelectStr), "curitem-use");
		}
		case DataProc_MONEYUP:
		{
			// 금액 증가
			Format(sSelectStr, sizeof(sSelectStr), "money-up");
		}
		case DataProc_MONEYDOWN:
		{
			// 금액 감소
			Format(sSelectStr, sizeof(sSelectStr), "money-down");
		}
		case DataProc_MONEYGIFT:
		{
			// 금액 선물
			Format(sSelectStr, sizeof(sSelectStr), "money-gift");
		}
		case DataProc_MONEYGIVE:
		{
			// 금액 주기
			Format(sSelectStr, sizeof(sSelectStr), "money-give");
		}
		case DataProc_MONEYTAKEAWAY:
		{
			// 금액 뺏기
			Format(sSelectStr, sizeof(sSelectStr), "money-takeaway");
		}
		case DataProc_ITEMGIFT:
		{
			// 아이템 선물
			Format(sSelectStr, sizeof(sSelectStr), "item-gift");
		}
		case DataProc_ITEMGIVE:
		{
			// 아이템 주기
			Format(sSelectStr, sizeof(sSelectStr), "item-give");
		}
		case DataProc_ITEMTAKEAWAY:
		{
			// 아이템 뺏기
			Format(sSelectStr, sizeof(sSelectStr), "item-takeaway");
		}
		case DataProc_USERREFDATA:
		{
			// 클라이언트 기타 참고 데이터 설정
			Format(sSelectStr, sizeof(sSelectStr), "user-refdata");
		}
	}
	System_DataProcess(client, sSelectStr, data);

	return strlen(sSelectStr) > 0 ? true : false;
}

/**
 * Native :: DDS_GetSecureUserMin
 *
 * @brief	ConVar 'dds_get_secure_user_min'의 값
 */
public int Native_DDS_GetSecureUserMin(Handle:plugin, numParams)
{
	return dds_hCV_SecureUserMin.IntValue; 
}

/**
 * Forward :: DDS_OnLoadSQLItemCategory
 *
 * @brief	DDS 플러그인에서 SQL 데이터베이스로부터 모든 아이템 종류를 불러오고 난 후에 발생
 */
void Forward_OnLoadSQLItemCategory()
{
	Call_StartForward(dds_hOnLoadSQLItemCategory);
	Call_Finish();
}

/**
 * Forward :: DDS_OnLoadSQLItem
 *
 * @brief	DDS 플러그인에서 SQL 데이터베이스로부터 모든 아이템을 불러오고 난 후에 발생
 */
void Forward_OnLoadSQLItem()
{
	Call_StartForward(dds_hOnLoadSQLItem);
	Call_Finish();
}

/**
 * Forward :: DDS_OnDataProcess
 *
 * @brief	DDS 플러그인에서 클라이언트가 데이터를 전달할 무언가를 할 때 발생
 */
void Forward_OnDataProcess(int client, const DataProcess process, const char[] data)
{
	Call_StartForward(dds_hOnDataProcess);
	Call_PushCell(client);
	Call_PushCell(process);
	Call_PushString(data);
	Call_Finish();
}

/**
 * Forward :: DDS_OnLogProcessPre
 *
 * @brief	DDS 플러그인에서 데이터 로그를 작성하기 전에 발생
 */
Action Forward_OnLogProcessPre(const char[] authid, const char[] action, const char[] setdata, const int date, const char[] usrip)
{
	Action result;

	Call_StartForward(dds_hOnLogProcessPre);
	Call_PushString(authid);
	Call_PushString(action);
	Call_PushString(setdata);
	Call_PushCell(date);
	Call_PushString(usrip);
	Call_Finish(result);

	return result;
}

/**
 * Forward :: DDS_OnLogProcessPost
 *
 * @brief	DDS 플러그인에서 데이터 로그를 작성한 후에 발생
 */
void Forward_OnLogProcessPost(const char[] authid, const char[] action, const char[] setdata, const int date, const char[] usrip)
{
	Call_StartForward(dds_hOnLogProcessPost);
	Call_PushString(authid);
	Call_PushString(action);
	Call_PushString(setdata);
	Call_PushCell(date);
	Call_PushString(usrip);
	Call_Finish();
}