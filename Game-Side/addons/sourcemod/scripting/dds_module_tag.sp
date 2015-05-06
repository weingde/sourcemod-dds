/************************************************************************
 * Dynamic Dollar Shop - [Module] Tag (Sourcemod)
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
#include <basecomm>
#include <dds>

#define DDS_ADD_NAME			"Dynamic Dollar Shop :: [Module] Tag"
#define DDS_ITEMCG_TAG_ID		5

/*******************************************************
 * V A R I A B L E S
*******************************************************/
// 게임 식별
char dds_sGameIdentity[32];

// 팀 채팅
bool dds_bTeamChat[MAXPLAYERS + 1];

// 자유형 태그 설정
bool dds_bUserTagSetting[MAXPLAYERS + 1];

/*******************************************************
 * P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = DDS_ADD_NAME,
	author = DDS_ENV_CORE_AUTHOR,
	description = "This can allow clients to use various tags.",
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
	// 콘솔 커맨드 연결
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_TeamSay);
}

/**
 * 설정이 로드되고 난 후
 */
public void OnConfigsExecuted()
{
	// 플러그인이 꺼져 있을 때는 동작 안함
	if (!DDS_IsPluginOn())	return;

	// 유저 태그 설정 초기화
	Init_UserTagSetData(0, 1);

	// 게임 식별
	GetGameFolderName(dds_sGameIdentity, sizeof(dds_sGameIdentity));

	// 구분 시작
	System_Identify(dds_sGameIdentity);
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

	// 팀 채팅 초기화
	dds_bTeamChat[client] = false;

	// 태그 설정 초기화
	Init_UserTagSetData(client, 2);
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

	// 팀 채팅 초기화
	dds_bTeamChat[client] = false;

	// 태그 설정 초기화
	Init_UserTagSetData(client, 2);
}

/**
 * DDS 플러그인에서 클라이언트가 데이터를 전달할 때
 *
 * @param client				클라이언트 인덱스
 * @param process				행동 구별
 * @param data					추가 파라메터
 */
public void DDS_OnDataProcess(int client, const DataProcess process, const char[] data)
{
	// 장착을 제외한 것은 모두 패스
	if ((process != DataProc_USE) && (process != DataProc_CURUSE))	return;

	/*************************
	 * 전달 파라메터 구분
	 *
	 * [0] - 데이터베이스 번호
	 * [1] - 아이템 번호
	**************************/
	char sTempStr[2][16];
	ExplodeString(data, "||", sTempStr, sizeof(sTempStr), sizeof(sTempStr[]));

	// 아이템 번호를 통해 종류 파악
	char sGetCode[8];
	DDS_GetItemInfo(StringToInt(sTempStr[1]), ItemInfo_CATECODE, sGetCode);
	if (StringToInt(sGetCode) != DDS_ITEMCG_TAG_ID)	return;

	// 아이템 번호를 통해 ENV 파악
	char sGetEnv[DDS_ENV_VAR_ENV_SIZE];
	DDS_GetItemInfo(StringToInt(sTempStr[1]), ItemInfo_ENV, sGetEnv);

	// 자유형 태그를 위한 ENV 확인
	char sEnvFree[4];
	SelectedStuffToString(sGetEnv, "ENV_DDS_INFO_FREETAG", "||", ":", sEnvFree, sizeof(sEnvFree));

	// 자유형 태그 속성을 가지고 있으면 설정 시작
	if (StringToInt(sEnvFree))
	{
		// 우선 블록킹 처리
		dds_bUserTagSetting[client] = true;

		// 절차 채팅 출력
		DDS_PrintToChat(client, "%t", "system msg set freetag");

		return;
	}

	// 태그 문자열을 위한 ENV 확인
	char sEnvTagStr[64];
	SelectedStuffToString(sGetEnv, "ENV_DDS_INFO_TAGSTR", "||", ":", sEnvTagStr, sizeof(sEnvTagStr));

	// 태그 설정
	char sSendData[128];
	Format(sSendData, sizeof(sSendData), "%s||%s", "USETAG", sEnvTagStr);
	DDS_UseDataProcess(client, DataProc_USERREFDATA, sSendData);
}

/*******************************************************
 * G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 초기화 :: 유저 태그 설정
 *
 * @param client			클라이언트 인덱스
 * @param mode				처리 모드(1 - 전체 초기화, 2 - 특정 클라이언트 초기화)
 */
public void Init_UserTagSetData(int client, int mode)
{
	switch (mode)
	{
		case 1:
		{
			for (int i = 0; i <= MAXPLAYERS; i++)
			{
				// 태그 설정 초기화
				dds_bUserTagSetting[i] = false;
			}
		}
		case 2:
		{
			// 태그 설정 초기화
			dds_bUserTagSetting[client] = false;
		}
	}
}

/**
 * System :: 게임 별 구분 처리
 *
 * @param gamename					게임 이름
 */
public void System_Identify(const char[] gamename)
{
	if (StrEqual(gamename, "cstrike", false))
	{
		/********************************************
		 * '카운터 스트라이크: 소스'
		*********************************************/
	}
	else if (StrEqual(gamename, "csgo", false))
	{
		/********************************************
		 * '카운터 스트라이크: 글로벌 오펜시브'
		*********************************************/
	}
	else if (StrEqual(gamename, "tf", false))
	{
		/********************************************
		 * '팀 포트리스'
		*********************************************/
	}
}


/**
 * 기타 :: 태그 설정 시 유효한 문자열인지 검사
 *
 * @param client				클라이언트 인덱스
 * @param str					설정할 문자열
 */
public bool CheckValidTag(int client, char[] str)
{
	// 잠시 임시 문자열로 변경
	char tempstr[64];
	strcopy(tempstr, sizeof(tempstr), str);

	// 앞 뒤 공백 제거
	TrimString(tempstr);

	// 아무것도 없으면 통과
	if (strlen(tempstr) <= 0)	return false;

	// 필터로 사용되는 것을 썼다면 통과
	if (StrContains(tempstr, "##", false) != -1)	return false;
	if (StrContains(tempstr, "@@", false) != -1)	return false;
	if (StrContains(tempstr, "||", false) != -1)	return false;
	if (StrContains(tempstr, "|", false) != -1)	return false;
	if (StrContains(tempstr, ":", false) != -1)	return false;

	return true;
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
	if (!DDS_IsPluginOn())	return Plugin_Continue;

	// 서버 채팅은 통과
	if (client == 0)	return Plugin_Continue;

	// 'sm_gag' 동작 구분
	if (BaseComm_IsClientGagged(client))	return Plugin_Continue;

	// 메세지 받고 맨 끝 따옴표 제거
	char sMsg[256];

	GetCmdArgString(sMsg, sizeof(sMsg));
	sMsg[strlen(sMsg)-1] = '\x0';

	// 원문 따로 변수 처리
	char sMainMsg[256];
	strcopy(sMainMsg, sizeof(sMainMsg), sMsg[1]);

	/****************************
	 * 준비
	*****************************/
	// 클라이언트 언어 파악
	char sUserLang[8];
	GetLanguageInfo(GetClientLanguage(client), sUserLang, sizeof(sUserLang));

	// 클라이언트 이름 파악
	char sUserName[32];
	GetClientName(client, sUserName, sizeof(sUserName));

	// 명령어 번역 준비
	//char sCmhTrans[32];

	// 채팅 출력 준비
	char sDisplay[256];

	/***********************************************************************
	 * -------------------------
	 * 변수 정리
	 * -------------------------
	 *
	 * sMainMsg - 순수한 채팅 문자열.
	 *
	 * sCmhTrans - 클라이언트 언어 별 명령어를 담당할 포멧을 지정하는 곳.
	 *
	************************************************************************/
	/****************************
	 * 조건 확인
	*****************************/
	// 태그 설정을 하고 있는 중이라면 채팅 차단 후 해제
	if (dds_bUserTagSetting[client])
	{
		if (CheckValidTag(client, sMainMsg))
		{
			// 인젝션 필터링
			SetPreventSQLInject(sMainMsg, sMainMsg, sizeof(sMainMsg));

			// 값 설정
			char sSendData[64];
			Format(sSendData, sizeof(sSendData), "%s||%s", "USETAG", sMainMsg);
			DDS_UseDataProcess(client, DataProc_USERREFDATA, sSendData);

			// 차단 해제
			dds_bUserTagSetting[client] = false;
		}
		return Plugin_Handled;
	}

	/****************************
	 * 메세지 포맷 지정
	*****************************/
	// 메시지 기본 형식 설정
	Format(sDisplay, sizeof(sDisplay), "\x03%s \x01:  %s", sUserName, sMainMsg);

	// 태그가 설정되었을 경우
	if (DDS_GetClientItemCategorySetting(client, DDS_ITEMCG_TAG_ID) && (DDS_GetClientAppliedItem(client, DDS_ITEMCG_TAG_ID) > 0))
	{
		// Ref Data 파악
		char sRefData[256];
		DDS_GetClientRefData(client, sRefData);

		// 태그 문자열 로드
		char sUseTag[32];
		SelectedStuffToString(sRefData, "USETAG", "||", ":", sUseTag, sizeof(sUseTag));

		// 적용
		Format(sDisplay, sizeof(sDisplay), "%s[%s] %s", StrEqual(dds_sGameIdentity, "csgo", false) ? " \x01\x0B\x04" : "\x04", sUseTag, sDisplay);
	}

	/****************************
	 * 살아있지 않을 때의 처리
	*****************************/
	if (IsPlayerAlive(client))
	{
		if (dds_bTeamChat[client])
		{
			/* 팀 채팅으로 말을 했을 경우 */
			if (GetClientTeam(client) == 2)	Format(sDisplay, sizeof(sDisplay), "\x01(%t)%s", "chat display red", sDisplay);
			else if (GetClientTeam(client) == 3)	Format(sDisplay, sizeof(sDisplay), "\x01(%t)%s", "chat display blue", sDisplay);
		}
		else
		{
			/* 일반적으로 그냥 말을 했을 경우 */
			// 그냥 그대로 처리
			Format(sDisplay, sizeof(sDisplay), sDisplay);
		}
	}
	else
	{
		if (GetClientTeam(client) <= 1)
		{
			/** 관전으로 말을 했을 경우 **/
			if (dds_bTeamChat[client])
			{
				/* 팀 채팅으로 말을 했을 경우 */
				Format(sDisplay, sizeof(sDisplay), "\x01(%t)%s", "chat display spec", sDisplay);
			}
			else
			{
				/* 일반적으로 그냥 말을 했을 경우 */
				Format(sDisplay, sizeof(sDisplay), "\x01*%t*%s", "chat display spec", sDisplay);
			}
		}
		else
		{
			/** 팀에 참전하면서 팀으로 있을 경우 **/
			if (dds_bTeamChat[client])
			{
				/* 팀 채팅으로 말을 했을 경우 */
				if (GetClientTeam(client) == 2)	Format(sDisplay, sizeof(sDisplay), "\x01*%t*(%t)%s", "chat display dead", "chat display red", sDisplay);
				else if (GetClientTeam(client) == 3)	Format(sDisplay, sizeof(sDisplay), "\x01*%t*(%t)%s", "chat display dead", "chat display blue", sDisplay);
			}
			else
			{
				/* 일반적으로 그냥 말을 했을 경우 */
				Format(sDisplay, sizeof(sDisplay), "\x01*%t*%s", "chat display dead", sDisplay);
			}
		}
	}

	/*****************************************
	 * 채팅 명령어 문자에 따른 출력 구분
	 *
	 * 슬래시와 골뱅이만 처리
	 * 위 두 문자는 공개적으로 출력되지 않음
	******************************************/
	if ((sMainMsg[0] != '/') && (sMainMsg[0] != '@'))
	{
		if (dds_bTeamChat[client])
		{
			/* 팀 채팅으로 말을 했을 경우 */
			for (int i = 1; i <= MaxClients; i++)
			{
				// 게임에 없는 사람은 통과
				if (!IsClientInGame(i))	continue;

				// 팀을 선택하지 않았을 경우는 통과
				if (GetClientTeam(client) < 1)	continue;

				// 같은 팀일 경우 메세지 전송
				if (GetClientTeam(client) == GetClientTeam(i))	SayText2One(client, i, sDisplay);
			}
		}
		else
		{
			/* 일반적으로 그냥 말을 했을 경우 */
			SayText2All(client, sDisplay);
			PrintToServer(sDisplay);
		}
	}

	/*****************************************
	 * 팀 세팅 기록 초기화
	******************************************/
	dds_bTeamChat[client] = false;

	return Plugin_Handled;
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
	if (!DDS_IsPluginOn())	return Plugin_Continue;

	// 팀 채팅을 했다는 변수를 남기고 일반 채팅과 동일하게 간주
	dds_bTeamChat[client] = true;
	Command_Say(client, args);

	return Plugin_Handled;
}