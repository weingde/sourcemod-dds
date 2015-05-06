/************************************************************************
 * User Class Management - CORE (Sourcemod)
 * 
 * Copyright (C) 2015 Eakgnarok
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
************************************************************************/
#include <sourcemod>
#include <ucm>

/*******************************************************
 * E N U M S
*******************************************************/
enum Class
{
	CODE,
	String:NAME[UCM_ENV_VAR_GLONAME_SIZE],
	String:ENV[UCM_ENV_VAR_ENV_SIZE]
}

enum EnvList
{
	INDEX,
	String:CATEGORY[20],
	String:NAME[64],
	String:VALUE[128]
}

/*******************************************************
 V A R I A B L E S
*******************************************************/
// SQL 데이터베이스
Database ucm_hSQLDatabase;
bool ucm_bSQLStatus;

// 유저 SQL 확인
bool ucm_bUserSQLStatus[MAXPLAYERS + 1];

// 로그 파일
char ucm_sPluginLogFile[256];

// Convar 변수
ConVar ucm_hCV_PluginSwitch;
ConVar ucm_hCV_SwitchDisplayChat;

// 팀 채팅
bool ucm_bTeamChat[MAXPLAYERS + 1];

// 클래스
int ucm_iClassCount = 0;
int ucm_eClassList[UCM_ENV_CLASS_MAX + 1][Class];

// ENV 목록
int ucm_iEnvCount;
int ucm_eEnvList[UCM_ENV_USEENV_MAX][EnvList];

// 유저 소유
int ucm_iUserClass[MAXPLAYERS + 1];

/*******************************************************
 * P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = UCM_ENV_CORE_NAME,
	author = UCM_ENV_CORE_AUTHOR,
	description = "This can control user's class with another plugins using native functions efficiently.",
	version = UCM_ENV_CORE_VERSION,
	url = UCM_ENV_CORE_HOMEPAGE
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
	CreateConVar("sm_userclassmanagement_version", UCM_ENV_CORE_VERSION, "Made By. Eakgnarok", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// Convar 등록
	ucm_hCV_PluginSwitch = CreateConVar("ucm_switch_plugin", "1", "본 플러그인의 작동 여부입니다. 작동을 원하지 않으시다면 0을, 원하신다면 1을 써주세요.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	ucm_hCV_SwitchDisplayChat = CreateConVar("ucm_switch_chat", "0", "채팅을 할 때 메세지 출력 여부입니다. 작동을 원하지 않으시다면 0을, 원하신다면 1을 써주세요.", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// 플러그인 로그 작성 등록
	BuildPath(Path_SM, ucm_sPluginLogFile, sizeof(ucm_sPluginLogFile), "logs/userclassmanagement.log");

	// 번역 로드
	LoadTranslations("userclassmanagement.phrases");

	// 콘솔 커멘드 연결
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_TeamSay);
}

/**
 * API 등록
 */
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// 라이브러리 등록
	RegPluginLibrary("ucm_core");

	// Native 함수 등록
	CreateNative("UCM_IsPluginOn", Native_UCM_IsPluginOn);
	CreateNative("UCM_GetClientClass", Native_UCM_GetClientClass);
	CreateNative("UCM_GetClassCount", Native_UCM_GetClassCount);
	CreateNative("UCM_GetClassInfo", Native_UCM_GetClassInfo);

	return APLRes_Success;
}

/**
 * 설정이 로드되고 난 후
 */
public void OnConfigsExecuted()
{
	// 플러그인이 꺼져 있을 때는 동작 안함
	if (!ucm_hCV_PluginSwitch.BoolValue)	return;

	// SQL 데이터베이스 연결
	Database.Connect(SQL_GetDatabase, "ucm");
}

/**
 * 맵이 종료된 후
 */
public void OnMapEnd()
{
	// SQL 데이터베이스 핸들 초기화
	if (ucm_hSQLDatabase != null)
	{
		delete ucm_hSQLDatabase;
	}
	ucm_hSQLDatabase = null;

	// SQL 상태 초기화
	ucm_bSQLStatus = false;
}

/**
 * 클라이언트가 접속하면서 스팀 고유번호를 받았을 때
 *
 * @param client			클라이언트 인덱스
 * @param auth				클라이언트 고유 번호(타입 2)
 */
public void OnClientAuthorized(client, const String:auth[])
{
	// 플러그인이 꺼져 있을 때는 동작 안함
	if (!ucm_hCV_PluginSwitch.BoolValue)	return;

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
public void OnClientDisconnect(client)
{
	// 게임에 없으면 통과
	if (!IsClientInGame(client))	return;

	// 봇은 제외
	if (IsFakeClient(client))	return;

	// 클라이언트 고유 번호 추출
	char sUsrAuthId[20];
	GetClientAuthId(client, AuthId_SteamID64, sUsrAuthId, sizeof(sUsrAuthId));

	// 오류 검출 생성
	ArrayList hMakeErr = CreateArray(8);
	hMakeErr.Push(client);
	hMakeErr.Push(1013);

	// 유저 정보 갱신
	char sSendQuery[256];
	Format(sSendQuery, sizeof(sSendQuery), 
		"UPDATE `ucm_user_profile` SET `stacktime` = '%d' - `recentdate` + `stacktime`, `ingame` = '0' WHERE `authid` = '%s'", 
		GetTime(), sUsrAuthId);
	ucm_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErr);

	// 유저 데이터 초기화
	Init_UserData(client, 2);

	#if defined _DEBUG_
	UCM_PrintToServer(":: DEBUG :: User Disconnect - Update (client: %N)", client);
	#endif
}


/*******************************************************
 G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 초기화 :: 서버 데이터
 */
public void Init_ServerData()
{
	/** 클래스 **/
	// 클래스 갯수
	ucm_iClassCount = 0;
	// 클래스 목록
	for (int i = 0; i <= UCM_ENV_CLASS_MAX; i++)
	{
		ucm_eClassList[i][CODE] = 0;
		Format(ucm_eClassList[i][NAME], UCM_ENV_VAR_GLONAME_SIZE, "");
		Format(ucm_eClassList[i][ENV], UCM_ENV_VAR_ENV_SIZE, "");
	}
	// 클래스 0번 'X' 설정
	Format(ucm_eClassList[0][NAME], UCM_ENV_VAR_GLONAME_SIZE, "EN:X");

	/** ENV **/
	// ENV 갯수
	ucm_iEnvCount = 0;
	// ENV 목록
	for (int i = 0; i < UCM_ENV_USEENV_MAX; i++)
	{
		ucm_eEnvList[i][INDEX] = 0;
		Format(ucm_eEnvList[i][CATEGORY], 20, "");
		Format(ucm_eEnvList[i][NAME], 64, "");
		Format(ucm_eEnvList[i][VALUE], 128, "");
	}

	#if defined _DEBUG_
	UCM_PrintToServer(":: DEBUG :: Server Data Initialization Complete");
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
				ucm_bUserSQLStatus[i] = false;

				// 팀 채팅
				ucm_bTeamChat[i] = false;

				// 클래스
				ucm_iUserClass[i] = 0;
			}
		}
		case 2:
		{
			/** 특정 클라이언트 초기화 **/
			// SQL 데이터베이스 유저 상태
			ucm_bUserSQLStatus[client] = false;

			// 팀 채팅
			ucm_bTeamChat[client] = false;

			// 클래스
			ucm_iUserClass[client] = 0;
		}
	}

	#if defined _DEBUG_
	UCM_PrintToServer(":: DEBUG :: User Data Initialization Complete (client: %N, mode: %d)", client, mode);
	#endif
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
	if (!ucm_hCV_PluginSwitch.BoolValue)	return;

	// SQL 데이터베이스가 활성화되어 있지 않다면 작동 안함
	if (!ucm_bSQLStatus)
	{
		UCM_PrintToChat(client, "%t", "error sqlstatus server");
		return;
	}

	// 유저의 SQL 데이터베이스 상태가 활성화되어 있지 않다면 작동 안함
	if (!ucm_bUserSQLStatus[client])
	{
		UCM_PrintToChat(client, "%t", "error sqlstatus user");
		return;
	}

	/***** 클라이언트 정보 추출 *****/
	// 클라이언트의 이름 파악
	char sClient_Name[32];
	GetClientName(client, sClient_Name, sizeof(sClient_Name));

	// 클라이언트의 고유 번호 파악
	char sClient_AuthId[20];
	GetClientAuthId(client, AuthId_SteamID64, sClient_AuthId, sizeof(sClient_AuthId));

	// 쿼리 구문 준비
	char sSendQuery[512];

	// 버퍼 준비
	char sBuffer[128];

	// 로그 준비
	//char sMakeLogParam[128];

	/******************************************************************************
	 * -----------------------------------
	 * 'process' 파라메터 종류 별 나열
	 * -----------------------------------
	 *
	 * 'change-class' - 등급 변경
	 *
	*******************************************************************************/
	if (StrEqual(process, "change-class", false))
	{
		/*************************************************
		 *
		 * [등급 변경]
		 *
		**************************************************/

		/*************************
		 * 전달 파라메터 구분 준비
		 *
		 * [0] - 등급 코드
		 * [1] - 대상 클라이언트 유저 ID
		**************************/
		char sExpStr[2][32];
		ExplodeString(data, "||", sExpStr, sizeof(sExpStr), sizeof(sExpStr[]));

		int iClsCode = StringToInt(sExpStr[0]);
		int iTarUsrId = StringToInt(sExpStr[1]);

		/*************************
		 * 조건 및 환경 변수 확인
		**************************/
		/** 환경 변수 확인(유저단) **/
		// 

		/** 조건 확인 **/
		// 

		/*************************
		 * 변경 처리
		**************************/
		// 오류 검출 생성
		ArrayList hMakeErrI = CreateArray(8);
		hMakeErrI.Push(client);
		hMakeErrI.Push(2010);

		// 대상 클라이언트 식별
		int iTarget = GetClientOfUserId(iTarUsrId);
		char sTarget_AuthId[20];
		GetClientAuthId(iTarget, AuthId_SteamID64, sTarget_AuthId, sizeof(sTarget_AuthId));
		
		// 쿼리 전송
		Format(sSendQuery, sizeof(sSendQuery), 
			"UPDATE `ucm_user_profile` SET `clidx` = '%d' `authid` = '%s'", 
			iClsCode, sTarget_AuthId);
		ucm_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrI);

		// 적용
		ucm_iUserClass[iTarget] = iClsCode;

		/*************************
		 * 화면 출력
		**************************/
		// 클라이언트 국가에 따른 클래스 이름 추출
		char sClassName[64];
		SelectedGeoNameToString(client, ucm_eClassList[FindClassIndex(ucm_iUserClass[iTarget])][NAME], sClassName, sizeof(sClassName));

		// 이름 추출
		char sTarName[32];
		GetClientName(iTarget, sTarName, sizeof(sTarName));

		Format(sBuffer, sizeof(sBuffer), "%t", "system user change class client", sTarName, sClassName);
		UCM_PrintToChat(client, sBuffer);
		Format(sBuffer, sizeof(sBuffer), "%t", "system user change class target", sClient_Name, sClassName);
		UCM_PrintToChat(iTarget, sBuffer);

		/*************************
		 * 로그 작성
		**************************/
		// 
	}
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
			// SQL 데이터베이스 초기화 시 등급 목록 로드
			Format(sDetOutput, sizeof(sDetOutput), "%s Retriving Class List DB is Failure!", sDetOutput);
		}
		case 1003:
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
		case 2001:
		{
			// [데이터 초기화] 모두 초기화
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql initdata alldb");
			Format(sDetOutput, sizeof(sDetOutput), "%s Deleting All Databases is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
		case 2002:
		{
			// [데이터 초기화] 모든 유저 초기화
			Format(sOutput, sizeof(sOutput), "%s %t", sOutput, "error sql initdata alluser");
			Format(sDetOutput, sizeof(sDetOutput), "%s Deleting All User Databases is Failure. (AuthID: %s)", sDetOutput, usrauth);
		}
	}

	// 클라이언트와 서버 구분하여 로그 출력
	if (client > 0) // 클라이언트
	{
		// 클라이언트 메세지 전송
		if (IsClientInGame(client))
		{
			UCM_PrintToChat(client, sOutput);
			if (strlen(sErrDesc) > 0) UCM_PrintToChat(client, sErrDesc);
		}

		// 서버 메세지 전송
		UCM_PrintToServer("%s (client: %N)", sDetOutput, client);
		if (strlen(sErrDesc) > 0) UCM_PrintToServer("%s (client: %N)", sErrDesc, client);

		// 로그 파일 작성
		LogToFile(ucm_sPluginLogFile, "%s (client: %N)", sDetOutput, client);
		if (strlen(sErrDesc) > 0) LogToFile(ucm_sPluginLogFile, "%s (client: %N)", sErrDesc, client);
	}
	else if (client == 0) // 서버
	{
		// 서버 메세지 전송
		UCM_PrintToServer(sDetOutput);
		if (strlen(sErrDesc) > 0) UCM_PrintToServer(sErrDesc);

		// 로그 파일 작성
		LogToFile(ucm_sPluginLogFile, "%s (Server)", sDetOutput);
		if (strlen(sErrDesc) > 0) LogToFile(ucm_sPluginLogFile, "%s (Server)", sErrDesc);
	}
}


/**
 * SQL :: 초기화 및 SQL 데이터베이스에 있는 데이터 로드
 */
public void SQL_UCMDatabaseInit()
{
	/** 초기화 **/
	// 서버
	Init_ServerData();
	// 유저
	Init_UserData(0, 1);

	/** 데이터 로드 **/
	char sSendQuery[512];

	// 등급 목록 로드
	Format(sSendQuery, sizeof(sSendQuery), "SELECT * FROM `ucm_class_list` WHERE `status`='1' ORDER BY `orderidx` ASC");
	ucm_hSQLDatabase.Query(SQL_LoadClassList, sSendQuery, 0, DBPrio_High);
	// ENV 목록 로드
	Format(sSendQuery, sizeof(sSendQuery), "SELECT * FROM `ucm_env_list`");
	ucm_hSQLDatabase.Query(SQL_LoadEnvList, sSendQuery, 0, DBPrio_High);
}


/**
 * 메뉴 :: 메인 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param args				기타
*/
public Action:Menu_Main(int client, int args)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!ucm_hCV_PluginSwitch.BoolValue)	return Plugin_Continue;

	// SQL 데이터베이스가 활성화되어 있지 않다면 작동 안함
	if (!ucm_bSQLStatus)
	{
		UCM_PrintToChat(client, "%t", "error sqlstatus server");
		return Plugin_Continue;
	}

	// 유저의 SQL 데이터베이스 상태가 활성화되어 있지 않다면 작동 안함
	if (!ucm_bUserSQLStatus[client])
	{
		UCM_PrintToChat(client, "%t", "error sqlstatus user");
		return Plugin_Continue;
	}

	char buffer[256];
	Menu mMain = new Menu(Main_hdlMain);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n ", "menu common title");
	mMain.SetTitle(buffer);

	// '내 정보'
	Format(buffer, sizeof(buffer), "%t\n", "menu main myinfo");
	mMain.AddItem("1", buffer);
	// '등급 변경'
	char sGetEnv[64];
	SelectedStuffToString(ucm_eClassList[FindClassIndex(ucm_iUserClass[client])][ENV], "ENV_UCM_ACCESS_CHANGE_CLASS", "||", ":", sGetEnv, sizeof(sGetEnv));
	if (StringToInt(sGetEnv))
	{
		Format(buffer, sizeof(buffer), "%t\n ", "menu main changeclass");
		mMain.AddItem("2", buffer);
	}
	// '플러그인 정보'
	Format(buffer, sizeof(buffer), "%t", "menu main plugininfo");
	mMain.AddItem("9", buffer);

	// 메뉴 출력
	mMain.Display(client, MENU_TIME_FOREVER);

	return Plugin_Continue;
}

/**
 * 메뉴 :: 등급 변경 메뉴 출력
 *
 * @param client			클라이언트 인덱스
*/
public void Menu_ChangeClass(int client)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!ucm_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlChangeClass);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t\n ", "menu common title", "menu common curpos", "menu main changeclass");
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 갯수 파악
	int count;

	for (int i = 0; i< MaxClients; i++)
	{
		// 서버는 통과
		if (i == 0)	continue;

		// 서버 내에 없다면 통과
		if (IsClientInGame(i))	continue;

		// 봇이라면 통과
		if (IsFakeClient(i))	continue;

		// 인증을 못받았다면 통과
		if (!IsClientAuthorized(i))	continue;

		// 본인은 통과
		if (i == client)	continue;

		// 전달 파라메터 준비
		char sSendParam[16];
		IntToString(GetClientUserId(i), sSendParam, sizeof(sSendParam));

		// 클라이언트 국가에 따른 클래스 이름 추출
		char sClassName[64];
		SelectedGeoNameToString(i, ucm_eClassList[FindClassIndex(ucm_iUserClass[i])][NAME], sClassName, sizeof(sClassName));

		// 메뉴 등록
		Format(buffer, sizeof(buffer), "%N - %s", i, sClassName);
		mMain.AddItem(sSendParam, buffer);

		// 갯수 증가
		count++;
	}

	// 사람이 없을 때
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
 * 메뉴 :: 등급 변경-세부 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param tarusrid			대상 클라이언트 유저 ID
 */
public void Menu_ChangeClass_Select(int client, int tarusrid)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!ucm_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlChangeClass_Select);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t\n ", "menu common title", "menu common curpos", "menu changeclass select");
	mMain.SetTitle(buffer);
	mMain.ExitBackButton = true;

	// 갯수 파악
	int count;

	for (int i = 0; i <= ucm_iClassCount; i++)
	{
		// 0번은 사용 안함
		if (i == 0)	continue;

		// 전달 파라메터 준비
		char sSendParam[20];

		// 클라이언트 국가에 따른 클래스 이름 추출
		char sClassName[64];
		SelectedGeoNameToString(i, ucm_eClassList[i][NAME], sClassName, sizeof(sClassName));

		// 메뉴 등록
		Format(buffer, sizeof(buffer), "%s", sClassName);
		Format(sSendParam, sizeof(sSendParam), "%d||%d", tarusrid, ucm_eClassList[i][CODE]);
		mMain.AddItem(sSendParam, buffer);
	}

	// 등급이 없을 때
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
 * 메뉴 :: 내 정보 메뉴 출력
 *
 * @param client			클라이언트 인덱스
 * @param action			행동 구분
 */
public void Menu_Myinfo(int client, const char[] action)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!ucm_hCV_PluginSwitch.BoolValue)	return;

	char buffer[256];
	Menu mMain = new Menu(Main_hdlMyinfo);

	// 제목 설정
	Format(buffer, sizeof(buffer), "%t\n%t: %t\n ", "menu common title", "menu common curpos", "menu main myinfo");
	mMain.SetTitle(buffer);

	// 행동 구분
	if (StrEqual(action, "main-menu", false))
		mMain.ExitBackButton = true;

	// 필요 정보
	char sUsrName[32];
	char sUsrAuthId[20];

	GetClientName(client, sUsrName, sizeof(sUsrName));
	GetClientAuthId(client, AuthId_SteamID64, sUsrAuthId, sizeof(sUsrAuthId));

	// 클라이언트 국가에 따른 클래스 이름 추출
	char sClassName[64];
	SelectedGeoNameToString(client, ucm_eClassList[FindClassIndex(ucm_iUserClass[client])][NAME], sClassName, sizeof(sClassName));

	// 메뉴 아이템 등록
	Format(buffer, sizeof(buffer), 
		"%t\n \n%t: %s\n%t: %s\n%t: %s", 
		"menu myinfo introduce", "global nickname", sUsrName, "global authid", sUsrAuthId, "global class", sClassName);
	mMain.AddItem("1", buffer, ITEMDRAW_DISABLED);

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
	if (!ucm_hCV_PluginSwitch.BoolValue)	return;

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
	if (!ucm_hCV_PluginSwitch.BoolValue)	return;

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
		}
		case 2:
		{
			// 개발자 정보
			Format(buffer, sizeof(buffer), "%s - v%s\n ", UCM_ENV_CORE_NAME, UCM_ENV_CORE_VERSION);
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
 * 메뉴 :: 데이터베이스 초기화 메뉴 출력
 *
 * @param client			클라이언트 인덱스
*/
public void Menu_InitDatabase(int client)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!ucm_hCV_PluginSwitch.BoolValue)	return;

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
	if (!ucm_hCV_PluginSwitch.BoolValue)	return;

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
 * 기타 :: 등급 인덱스 찾기
 *
 * @param classcode				등급 코드
*/
public int FindClassIndex(int classcode)
{
	for (int i = 0; i <= ucm_iClassCount; i++)
	{
		// 0번은 제외
		if (i == 0)	continue;

		// 맞지 않은 것들은 통과
		if (ucm_eClassList[i][CODE] != classcode)	continue;

		return i;
	}

	return 0;
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
public Action:Command_Say(int client, int args)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!ucm_hCV_PluginSwitch.BoolValue)	return Plugin_Continue;

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
	Format(sCmhTrans, sizeof(sCmhTrans), "%t", "command myinfo");
	if (bChkCmd && StrEqual(sMainCmd, sCmhTrans, false))
	{
		Command_MyInfo(client, sParamStr[0]);
	}

	// 초기화
	Format(sCmhTrans, sizeof(sCmhTrans), "%t", "command init");
	if (bChkCmd && StrEqual(sMainCmd, sCmhTrans, false))
	{
		Command_Init(client);
	}

	// 팀 채팅 기록 초기화
	ucm_bTeamChat[client] = false;

	return ucm_hCV_SwitchDisplayChat.BoolValue ? Plugin_Continue : Plugin_Handled;
}

/**
 * 커맨드 :: 팀 채팅
 *
 * @param client				클라이언트 인덱스
 * @param args					기타
 */
public Action:Command_TeamSay(int client, int args)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!ucm_hCV_PluginSwitch.BoolValue)	return Plugin_Continue;

	// 팀 채팅을 했다는 변수를 남기고 일반 채팅과 동일하게 간주
	ucm_bTeamChat[client] = true;
	Command_Say(client, args);

	return Plugin_Handled;
}

/**
 * 커맨드 :: 프로필 정보
 *
 * @param client				클라이언트 인덱스
 * @param data					추가 값
 */
public Command_MyInfo(int client, const char[] name)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!ucm_hCV_PluginSwitch.BoolValue)	return;

	// 대상이 빈칸일 경우
	if (strlen(name) <= 0)
	{
		UCM_PrintToChat(client, "%t", "error command myinfo usage", "command myinfo");
		return;
	}

	// 쌍따옴표로 구성이 안되어 있을 경우
	if (!CheckDQM(name))
	{
		UCM_PrintToChat(client, "%t", "error command notarget nodqm");
		return;
	}

	// 대상을 찾는데 없을 경우
	if (SearchTargetByName(name) == 0)
	{
		UCM_PrintToChat(client, "%t", "error command notarget ingame");
		return;
	}

	// 대상을 찾는데 2명 이상일 경우
	if (SearchTargetByName(name) == -1)
	{
		UCM_PrintToChat(client, "%t", "error command notarget more");
		return;
	}

	Menu_Myinfo(GetClientOfUserId(SearchTargetByName(name)), "command");
}

/**
 * 커맨드 :: 초기화
 *
 * @param client				클라이언트 인덱스
 */
public Command_Init(int client)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!ucm_hCV_PluginSwitch.BoolValue)	return;

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
	ucm_hSQLDatabase = db;

	if (ucm_hSQLDatabase == null)
	{
		Log_CodeError(0, 1001, error);
		return;
	}

	// UTF-8 설정
	ucm_hSQLDatabase.SetCharset("utf8");

	// 초기화 및 SQL 데이터베이스에 있는 데이터 로드
	SQL_UCMDatabaseInit();
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
 * SQL 초기 데이터 :: 등급 목록
 *
 * @param db					데이터베이스 연결 핸들
 * @param results				결과 쿼리
 * @param error					오류 문자열
 * @param data					기타
 */
public void SQL_LoadClassList(Database db, DBResultSet results, const char[] error, any data)
{
	// 쿼리 오류 검출
	if (db == null || error[0])
	{
		Log_CodeError(0, 1002, error);
		return;
	}

	#if defined _DEBUG_
	UCM_PrintToServer(":: DEBUG :: Let's Start Loading Classes!");
	#endif

	// 쿼리 결과
	while (results.MoreRows)
	{
		// 제시할 행이 없다면 통과
		if (!results.FetchRow())	continue;

		// 데이터 추가
		ucm_eClassList[ucm_iClassCount + 1][CODE] = results.FetchInt(0);
		results.FetchString(1, ucm_eClassList[ucm_iClassCount + 1][NAME], UCM_ENV_VAR_GLONAME_SIZE);
		results.FetchString(3, ucm_eClassList[ucm_iClassCount + 1][ENV], UCM_ENV_VAR_ENV_SIZE);

		#if defined _DEBUG_
		UCM_PrintToServer(":: DEBUG :: Class Loaded (ID: %d, GloName: %s, TotalCount: %d)", ucm_eClassList[ucm_iClassCount + 1][CODE], ucm_eClassList[ucm_iClassCount + 1][NAME], ucm_iClassCount + 1);
		#endif

		// 클래스 등록 갯수 증가
		ucm_iClassCount++;
	}

	#if defined _DEBUG_
	UCM_PrintToServer(":: DEBUG :: End Loading Classes.");
	#endif
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
		Log_CodeError(0, 1003, error);
		return;
	}

	#if defined _DEBUG_
	UCM_PrintToServer(":: DEBUG :: Let's Start Loading ENVs!");
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
		ucm_eEnvList[ucm_iEnvCount][INDEX] = iTmpIdx;
		Format(ucm_eEnvList[ucm_iEnvCount][CATEGORY], 20, sTmpCG);
		Format(ucm_eEnvList[ucm_iEnvCount][NAME], 64, sTmpName);
		Format(ucm_eEnvList[ucm_iEnvCount][VALUE], 128, sTmpValue);

		#if defined _DEBUG_
		UCM_PrintToServer(":: DEBUG :: ENV Loaded (IDX: %d, Category: %s, Name: %s, Value: %s)", ucm_eEnvList[ucm_iEnvCount][INDEX], ucm_eEnvList[ucm_iEnvCount][CATEGORY], ucm_eEnvList[ucm_iEnvCount][NAME], ucm_eEnvList[ucm_iEnvCount][VALUE]);
		#endif

		// ENV 등록 갯수 증가
		ucm_iEnvCount++;
	}

	#if defined _DEBUG_
	UCM_PrintToServer(":: DEBUG :: End Loading ENVs.");
	#endif

	// SQL 상태 활성화
	ucm_bSQLStatus = true;

	// ENV 추가 작업 시작(클래스)
	for (int i = 0; i <= ucm_iClassCount; i++)
	{
		// 0번은 통과
		if (i == 0)	continue;

		// 없는 ENV 추가
		for (int j = 0; j < ucm_iEnvCount; j++)
		{
			// 종류가 '클래스'이 아닌건 통과
			if (!StrEqual(ucm_eEnvList[j][CATEGORY], "class", false))	continue;

			// 이미 있는건 통과
			if (StrContains(ucm_eClassList[i][ENV], ucm_eEnvList[j][NAME], false) != -1)	continue;

			Format(ucm_eClassList[i][ENV], UCM_ENV_VAR_ENV_SIZE, 
				"%s||%s:%s", 
				ucm_eClassList[i][ENV], ucm_eEnvList[j][NAME], ucm_eEnvList[j][VALUE]
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
public Action:SQL_Timer_UserLoad(Handle timer, any client)
{
	// 플러그인이 켜져 있을 때에는 작동 안함
	if (!ucm_hCV_PluginSwitch.BoolValue)	return Plugin_Stop;

	// 클라이언트 고유 번호 추출
	char sUsrAuthId[20];
	GetClientAuthId(client, AuthId_SteamID64, sUsrAuthId, sizeof(sUsrAuthId));

	// 데이터 로드
	char sSendQuery[512];

	Format(sSendQuery, sizeof(sSendQuery), "SELECT * FROM `ucm_user_profile` WHERE `authid` = '%s'", sUsrAuthId);
	ucm_hSQLDatabase.Query(SQL_UserLoad, sSendQuery, client);

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
	int iTempClass;

	// 쿼리 결과
	while (results.MoreRows)
	{
		// 제시할 행이 없다면 통과
		if (!results.FetchRow())	continue;

		// 데이터 추가
		iTempClass = results.FetchInt(3);

		// 유저 파악 갯수 증가
		count++;

		#if defined _DEBUG_
		UCM_PrintToServer(":: DEBUG :: User Load - Checked (client: %N, Class: %d)", client, iTempClass);
		#endif
	}

	/** 추후 작업 **/
	char sSendQuery[256];

	// 클라이언트 고유 번호 추출
	char sUsrAuthId[20];
	GetClientAuthId(client, AuthId_SteamID64, sUsrAuthId, sizeof(sUsrAuthId));

	if (count == 0)
	{
		/** 등록된 것이 없다면 정보 생성 **/
		// 오류 검출 생성
		ArrayList hMakeErr = CreateArray(8);
		hMakeErr.Push(client);
		hMakeErr.Push(1011);

		// 닉네임 처리
		char sTempName[30];
		GetClientName(client, sTempName, sizeof(sTempName));
		SetPreventSQLInject(sTempName, sTempName, sizeof(sTempName));

		/************************************
		 * [기본 필수 등급]
		 * 
		 * 일반: 코드 1
		 * 최고 관리자: 코드 2
		 ************************************/
		// 기본 등급 결정
		int sDefClassCode = 1;
		if (GetAdminFlag(GetUserAdmin(client), Admin_Root, Access_Effective))
			sDefClassCode = 2;

		ucm_iUserClass[client] = sDefClassCode;

		Format(sSendQuery, sizeof(sSendQuery), 
			"INSERT INTO `ucm_user_profile` (`idx`, `authid`, `nickname`, `clidx`, `joindate`, `recentdate`, `ingame`) VALUES (NULL, '%s', '%s', '%d', '%d', '%d', '1')", 
			sUsrAuthId, sTempName, sDefClassCode, GetTime(), GetTime());
		ucm_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErr);

		#if defined _DEBUG_
		UCM_PrintToServer(":: DEBUG :: User Load - Make (client: %N, classcode: %d)", client, sDefClassCode);
		#endif
	}
	else if (count == 1)
	{
		/** 등록된 것이 있다면 정보 로드 및 갱신 **/
		// 오류 검출 생성
		ArrayList hMakeErr = CreateArray(8);
		hMakeErr.Push(client);
		hMakeErr.Push(1012);

		// 등급 로드
		ucm_iUserClass[client] = iTempClass;

		// 닉네임 처리
		char sTempName[30];
		GetClientName(client, sTempName, sizeof(sTempName));
		SetPreventSQLInject(sTempName, sTempName, sizeof(sTempName));

		// 인게임 처리
		Format(sSendQuery, sizeof(sSendQuery), 
			"UPDATE `ucm_user_profile` SET `nickname` = '%s', `recentdate` = '%d', `ingame` = '1' WHERE `authid` = '%s'", 
			sTempName, GetTime(), sUsrAuthId);
		ucm_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErr);

		#if defined _DEBUG_
		UCM_PrintToServer(":: DEBUG :: User Load - Update (client: %N)", client);
		#endif
	}
	else
	{
		/** 잘못된 정보 **/
		Log_CodeError(client, 1014, "The number of this user profile db must be one.");
	}

	// SQL 유저 상태 활성화
	ucm_bUserSQLStatus[client] = true;
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
				// 내 정보
				char sMyName[32];
				GetClientName(client, sMyName, sizeof(sMyName));
				Menu_Myinfo(client, sMyName);
			}
			case 2:
			{
				// 등급 변경
				Menu_ChangeClass(client);
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
 * 메뉴 핸들 :: 내 정보 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlMyinfo(Menu menu, MenuAction action, int client, int item)
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
 * 메뉴 핸들 :: 등급 변경 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlChangeClass(Menu menu, MenuAction action, int client, int item)
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
		 * @Desc [0] - 대상 클라이언트 유저 ID
		 */
		Menu_ChangeClass_Select(client, iInfo);
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
 * 메뉴 핸들 :: 등급 변경-세부 메뉴 핸들러
 *
 * @param menu				메뉴 핸들
 * @param action			메뉴 액션
 * @param client 			클라이언트 인덱스
 * @param item				메뉴 아이템 소유 문자열
 */
public Main_hdlChangeClass_Select(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}

	if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(item, sInfo, sizeof(sInfo));

		char sExpStr[2][32];
		ExplodeString(sInfo, "||", sExpStr, sizeof(sExpStr), sizeof(sExpStr[]));

		/**
		 * sExpStr
		 * 
		 * @Desc [0] - 대상 클라이언트 유저 ID, [1] - 등급 코드
		 */
		// 전달 파라메터 준비
		char sSendParam[32];
		Format(sSendParam, sizeof(sSendParam), "%d||%d", StringToInt(sExpStr[1]), StringToInt(sExpStr[0]));

		// Go
		System_DataProcess(client, "change-class", sSendParam);
	}

	if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			Menu_ChangeClass(client);
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
					int stepcount = 1;

					for (int i = 0; i < stepcount; i++)
					{
						ArrayList hMakeErr = CreateArray(8);
						hMakeErr.Push(client);
						hMakeErr.Push(2002);

						char sSendQuery[128];
						switch (i)
						{
							case 0:
							{
								Format(sSendQuery, sizeof(sSendQuery), "DELETE FROM `ucm_user_profile`");
							}
						}
						ucm_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErr);
					}

					// 완료 출력
					UCM_PrintToChat(client, "%t", "system initdatabase complete");
				}
				else if (StringToInt(sExpStr[0]) == 2)
				{
					/* 모두 초기화 */
					int stepcount = 2;

					for (int i = 0; i < stepcount; i++)
					{
						ArrayList hMakeErr = CreateArray(8);
						hMakeErr.Push(client);
						hMakeErr.Push(2001);

						char sSendQuery[128];
						switch (i)
						{
							case 0:
							{
								Format(sSendQuery, sizeof(sSendQuery), "DELETE FROM `ucm_user_profile`");
							}
							case 1:
							{
								Format(sSendQuery, sizeof(sSendQuery), "DELETE FROM `ucm_class_list`");
							}
						}
						ucm_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErr);
					}

					// 필수 레코드 생성
					ArrayList hMakeErrF = CreateArray(8);
					hMakeErrF.Push(client);
					hMakeErrF.Push(2001);
					ArrayList hMakeErrTW = CreateArray(8);
					hMakeErrTW.Push(client);
					hMakeErrTW.Push(2001);
					ArrayList hMakeErrTH = CreateArray(8);
					hMakeErrTH.Push(client);
					hMakeErrTH.Push(2001);

					char sSendQuery[128];
					Format(sSendQuery, sizeof(sSendQuery), "ALTER TABLE `ucm_class_list` auto_increment = 1");
					ucm_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrF);
					Format(sSendQuery, sizeof(sSendQuery), "INSERT INTO `ucm_class_list` (`clidx`, `gloname`, `orderidx`, `status`) VALUES (NULL, 'EN:Normal||KO:일반', '1', '1')");
					ucm_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrTH);
					Format(sSendQuery, sizeof(sSendQuery), "INSERT INTO `ucm_class_list` (`clidx`, `gloname`, `orderidx`, `env`, `status`) VALUES (NULL, 'EN:Super Admin||KO:최고 관리자', '2', 'ENV_UCM_ADMIN_STATUS:1', '1')");
					ucm_hSQLDatabase.Query(SQL_ErrorProcess, sSendQuery, hMakeErrTW);

					// 완료 출력
					UCM_PrintToChat(client, "%t", "system initdatabase complete");
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


/*******************************************************
 * N A T I V E  &  F O R W A R D  F U N C T I O N S
*******************************************************/
/**
 * Native :: UCM_IsPluginOn
 *
 * @brief	UCM 플러그인의 활성화 여부
 */
public int Native_UCM_IsPluginOn(Handle:plugin, numParams)
{
	return ucm_hCV_PluginSwitch.BoolValue;
}

/**
 * Native :: UCM_GetClientClass
 *
 * @brief	클라이언트의 등급 반환
 */
public int Native_UCM_GetClientClass(Handle:plugin, numParams)
{
	int client = GetNativeCell(1);

	// 클라이언트가 인증 절차를 밝았는지의 여부
	if (!IsClientAuthorized(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s client %d is not authorized.", UCM_ENV_CORE_CHAT_GLOPREFIX, client);
		return 0;
	}

	// 클라이언트가 봇인지 여부
	if (IsFakeClient(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s client %d is a bot. We don't support this bot client.", UCM_ENV_CORE_CHAT_GLOPREFIX, client);
		return 0;
	}

	return ucm_iUserClass[client];
}

/**
 * Native :: UCM_GetClassCount
 *
 * @brief	UCM 플러그인에 등록되어 있는 등급의 갯수
 */
public int Native_UCM_GetClassCount(Handle:plugin, numParams)
{
	return ucm_iClassCount;
}

/**
 * Native :: UCM_GetClassInfo
 *
 * @brief	UCM 플러그인에 등록된 등급 정보 반환
 */
public int Native_UCM_GetClassInfo(Handle:plugin, numParams)
{
	int classcode = GetNativeCell(1);
	ClassInfo proctype = GetNativeCell(2);

	// 데이터베이스 연결 확인
	if (ucm_hSQLDatabase == null || !ucm_bSQLStatus)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Server Database is not available.", UCM_ENV_CORE_CHAT_GLOPREFIX);
		return false;
	}

	// '0'은 될 수 없음
	if (classcode == 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Class Code should be more than 0. (Class Code %d)", UCM_ENV_CORE_CHAT_GLOPREFIX, classcode);
		return false;
	}

	// 해당 코드가 있는지 검증
	int count;
	int selectidx;
	for (int i = 0; i <= ucm_iClassCount; i++)
	{
		// 0번은 제외
		if (i == 0)	continue;

		// 맞지 않으면 통과
		if (ucm_eClassList[i][CODE] != classcode)	continue;

		selectidx = i;
		count++;

		break;
	}

	// 발견하지 못했다면 안함
	if (count == 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Class Code %d is not registered.", UCM_ENV_CORE_CHAT_GLOPREFIX, classcode);
		return false;
	}

	char result[UCM_ENV_VAR_ENV_SIZE];

	// 처리 구분
	switch (proctype)
	{
		case ClassInfo_Name:
		{
			Format(result, sizeof(result), ucm_eClassList[selectidx][NAME]);
		}
		case ClassInfo_Code:
		{
			Format(result, sizeof(result), "%d", ucm_eClassList[selectidx][CODE]);
		}
		case ClassInfo_Env:
		{
			Format(result, sizeof(result), ucm_eClassList[selectidx][ENV]);
		}
	}

	SetNativeString(3, result, sizeof(result), true);

	return true;
}

/**
 * Native :: UCM_FindClassIndex
 *
 * @brief	해당하는 등급 코드가 담긴 등급 목록 인덱스 반환
 */
public int Native_UCM_FindClassIndex(Handle:plugin, numParams)
{
	int classcode = GetNativeCell(1);

	// '0'은 될 수 없음
	if (classcode == 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%s Class Code should be more than 0. (Class Code %d)", UCM_ENV_CORE_CHAT_GLOPREFIX, classcode);
		return 0;
	}

	return FindClassIndex(classcode);
}