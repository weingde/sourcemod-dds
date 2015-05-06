/************************************************************************
 * Dynamic Dollar Shop - MAIN INCLUDE :: Stock (Sourcemod)
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
/**
 * 채팅 :: 모든 클라이언트에게 메세지 전달
 *
 * @param client					클라이언트 인덱스
 * @param message					전달할 메세지
 *
 * @ref CS:GO Protobuf 종류 - https://github.com/alliedmodders/hl2sdk/blob/csgo/public/game/shared/csgo/protobuf/cstrike15_usermessages.proto#L68
 */
stock SayText2All(int client, const char[] message)
{
	Handle hMsg = StartMessageAll("SayText2");

	if (hMsg != null)
	{
		if (GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(hMsg, "ent_idx", client);
			PbSetBool(hMsg, "chat", true);
			PbSetString(hMsg, "msg_name", message);

			PbAddString(hMsg, "params", "");
			PbAddString(hMsg, "params", "");
			PbAddString(hMsg, "params", "");
			PbAddString(hMsg, "params", "");

			EndMessage();
		}
		else
		{
			BfWriteByte(hMsg, client);
			BfWriteByte(hMsg, true);
			BfWriteString(hMsg, message);
			EndMessage();
		}
	}
}

/**
 * 채팅 :: 특정 클라이언트에게 메세지 전달
 *
 * @param client					클라이언트 인덱스
 * @param target					전달할 목표 클라이언트 인덱스
 * @param message					전달할 메세지
 *
 * @ref CS:GO Protobuf 종류 - https://github.com/alliedmodders/hl2sdk/blob/csgo/public/game/shared/csgo/protobuf/cstrike15_usermessages.proto#L68
 */
stock SayText2One(int client, int target, const char[] message)
{
	Handle hMsg = StartMessageOne("SayText2", target);

	if (hMsg != null)
	{
		if (GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(hMsg, "ent_idx", client);
			PbSetBool(hMsg, "chat", false);
			PbSetString(hMsg, "msg_name", message);

			PbAddString(hMsg, "params", "");
			PbAddString(hMsg, "params", "");
			PbAddString(hMsg, "params", "");
			PbAddString(hMsg, "params", "");

			EndMessage();
		}
		else
		{
			BfWriteByte(hMsg, client);
			BfWriteByte(hMsg, false);
			BfWriteString(hMsg, message);
			EndMessage();
		}
	}
}

/**
 * 채팅 :: 개별 채팅 메세지 전달
 *
 * @param client					클라이언트 인덱스
 * @param message					전달할 메세지
 * @param ...						전달할 파라메터
 */
stock DDS_PrintToChat(int client, const char[] message, any:...)
{
	char sMsg[1024];
	char sTempMsg[1024];
	char sGameType[32];

	// 게임 종류 판별
	GetGameFolderName(sGameType, sizeof(sGameType));

	// 포멧 메세지 파라메터 위치 지정
	VFormat(sTempMsg, sizeof(sTempMsg), message, 3);

	// 포멧 지정
	Format(sMsg, sizeof(sMsg), "%s%s \x03%s", StrEqual(sGameType, "csgo", false) ? " \x01\x0B\x04" : "\x04", DDS_ENV_CORE_CHAT_GLOPREFIX, sTempMsg);

	PrintToChat(client, sMsg);
}

/**
 * 채팅 :: 전체 채팅 메세지 전달
 *
 * @param message					전달할 메세지
 * @param ...						전달할 파라메터
 */
stock DDS_PrintToChatAll(const char[] message, any:...)
{
	char sMsg[1024];
	char sTempMsg[1024];
	char sGameType[32];

	// 게임 종류 판별
	GetGameFolderName(sGameType, sizeof(sGameType));

	// 포멧 메세지 파라메터 위치 지정
	VFormat(sTempMsg, sizeof(sTempMsg), message, 2);

	// 포멧 지정
	Format(sMsg, sizeof(sMsg), "%s%s \x03%s", StrEqual(sGameType, "csgo", false) ? " \x01\x0B\x04" : "\x04", DDS_ENV_CORE_CHAT_GLOPREFIX, sTempMsg);

	PrintToChatAll(sMsg);
}

/**
 * 채팅 :: 서버 메세지 전달
 *
 * @param message					전달할 메세지
 * @param ...						전달할 파라메터
 */
stock DDS_PrintToServer(const char[] message, any:...)
{
	char sMsg[1024];
	char sTempMsg[1024];

	// 포멧 메세지 파라메터 위치 지정
	VFormat(sTempMsg, sizeof(sTempMsg), message, 2);

	// 포멧 지정
	Format(sMsg, sizeof(sMsg), "%s %s", DDS_ENV_CORE_CHAT_GLOPREFIX, sTempMsg);

	PrintToServer(sMsg);
}

/**
 * 추출 :: 특정 문자열 항목의 값 추출
 *
 * @param findStr					대상 문자열
 * @param wantStr					찾을 문자열
 * @param lineCut					항목을 잘라낼 문자
 * @param valueCut					값을 잘라낼 문자
 * @param output					저장할 문자열
 * @param len						저장할 문자열 길이
 */
stock SelectedStuffToString(const char[] findStr, const char[] wantStr, const char[] lineCut, const char[] valueCut,  char[] output, int len)
{
	// 값이 없는 경우엔 생략
	if (strlen(lineCut) <= 0)	return;
	if (strlen(valueCut) <= 0)	return;

	int envPos;
	char bufValue[64];
	char value[2][512];

	// 찾을 문자열이 어느 위치에 있는지 파악
	if ((envPos = StrContains(findStr, wantStr, false)) != -1)
	{
		char tmpStr[512];

		// 찾은 문자열 위치부터 항목을 잘라낼 문자까지 따로 값을 분리
		if (SplitString(findStr[envPos], lineCut, tmpStr, sizeof(tmpStr)) == -1)
			strcopy(tmpStr, sizeof(tmpStr), findStr[envPos]);

		// 값을 잘라낼 문자로 위에서 구한 값을 분리
		ExplodeString(tmpStr, valueCut, value, sizeof(value), sizeof(value[]));
	}
	strcopy(output, len, value[1]);
}

/**
 * 추출 :: 유저 별 언어 환경에 따른 특정 문자열 항목의 값 추출
 *
 * @param client					클라이언트 인덱스
 * @param findStr					대상 문자열
 * @param output					저장할 문자열
 * @param len						저장할 문자열 길이
 *
 * @ref '||'로 항목을 자르고, ':'로 값을 잘라냄. 국가 코드는 두 글자.
 */
stock SelectedGeoNameToString(int client, const char[] findStr, char[] output, int len)
{
	// 클라이언트가 없는 경우는 생략
	if (!IsClientInGame(client))	return;

	char sUsrLang[16];
	char sValue[128];

	// 클라이언트 언어 파악
	GetLanguageInfo(GetClientLanguage(client), sUsrLang, sizeof(sUsrLang));

	// 값 추출
	SelectedStuffToString(findStr, sUsrLang, "||", ":", sValue, sizeof(sValue));

	strcopy(output, len, sValue);
}

/**
 * 보안 :: SQL 인젝션 방어
 *
 * @param input						대상 문자열
 * @param output					저장 문자열
 * @param oplength					저장할 문자열 길이
 */
stock SetPreventSQLInject(const char[] input, char[] output, oplength)
{
	char sTempStr[1024];

	strcopy(sTempStr, sizeof(sTempStr), input);

	ReplaceString(sTempStr, sizeof(sTempStr), "'", "''", false);
	ReplaceString(sTempStr, sizeof(sTempStr), "`", "", false);
	ReplaceString(sTempStr, sizeof(sTempStr), "//", "////", false);

	strcopy(output, oplength, sTempStr);
}

/**
 * 추출 :: 이름을 통한 대상 클라이언트 이름 찾기
 *
 * @param name				찾을 문자열
 * @return 대상 클라이언트 유저 ID
 */
stock int SearchTargetByName(const char[] name)
{
	// 안적혀 있으면 통과
	if (strlen(name) <= 0)	return 0;

	// 쌍따옴표 제거
	char sTmpName[32];
	strcopy(sTmpName, sizeof(sTmpName), name);
	StripQuotes(sTmpName);

	// 개수 파악
	int count;

	// 찾을 인덱스 준비
	int iChkIdx;

	for (int i = 0; i < MaxClients; i++)
	{
		// 서버는 통과
		if (i == 0)	continue;

		// 인증이 안되어 있으면 통과
		if (!IsClientAuthorized(i))	continue;

		// 게임에 없으면 통과
		if (!IsClientInGame(i))	continue;

		// 봇은 통과
		if (IsFakeClient(i))	continue;

		// 이름 추출
		char sUsrName[32];
		GetClientName(i, sUsrName, sizeof(sUsrName));

		if (StrContains(sUsrName, sTmpName, false) != -1)
		{
			// 인덱스 설정
			iChkIdx = i;

			// 갯수 증가
			count++;
		}
	}
	
	if (count == 0)	return 0;
	else if (count > 1)	return -1;
	else return GetClientUserId(iChkIdx);
}

/**
 * 추출 :: 파라메터 쌍따옴표 확인
 *
 * @param msg				대상 문자열
 * @return 대상 클라이언트 유저 ID
 */
stock bool CheckDQM(const char[] msg)
{
	// 안적혀 있으면 통과
	if (strlen(msg) <= 0)	return false;

	// 쌍따옴표 하나가 적히면 통과
	if ((strlen(msg) - 1) == 0)	return false;

	// 조건 확인
	if ((msg[0] == '"') && (msg[strlen(msg)-1] == '"'))
		return true;

	return false;
}

/**
 * 보안 :: 서버 내 클라이언트 인원 파악
 *
 * @param mode						적용 대상 설정
 */
// 기본 define 설정
#define CLIENTCOUNT_MODE_SERVER				(1<<0)
#define CLIENTCOUNT_MODE_BOT				(1<<1)
#define CLIENTCOUNT_MODE_NONE				(1<<2)
#define CLIENTCOUNT_MODE_SPEC				(1<<3)
#define CLIENTCOUNT_MODE_RED				(1<<4)
#define CLIENTCOUNT_MODE_BLUE				(1<<5)
#define CLIENTCOUNT_MODE_ALIVE				(1<<6)

// 인원 파악
stock int GetClientCountEx(int mode = CLIENTCOUNT_MODE_RED|CLIENTCOUNT_MODE_BLUE|CLIENTCOUNT_MODE_ALIVE)
{
	// 인원 파악 준비
	int count;

	// 파악 시작
	for (int i = 1; i <= MaxClients; i++)
	{
		// 인증받지 않았다면 제외
		if (!IsClientAuthorized(i))	continue;

		// 게임 내에 있지 않다면 제외
		if (!IsClientInGame(i))	continue;

		// 살아있지 않다면 패스
		if (mode & CLIENTCOUNT_MODE_ALIVE)
			if (!IsPlayerAlive(i))	continue;

		// 봇 파악
		if (mode & CLIENTCOUNT_MODE_BOT)
			if (IsFakeClient(i))	count++;

		// 게임은 들어와있는데 팀을 선정안했을 경우
		if (mode & CLIENTCOUNT_MODE_NONE)
			if (GetClientTeam(i) == 0)	count++;

		// 관전자일 경우
		if (mode & CLIENTCOUNT_MODE_SPEC)
			if (GetClientTeam(i) == 1)	count++;

		// 레드 팀일 경우
		if (mode & CLIENTCOUNT_MODE_RED)
			if (GetClientTeam(i) == 2)	count++;

		// 블루 팀일 경우
		if (mode & CLIENTCOUNT_MODE_BLUE)
			if (GetClientTeam(i) == 3)	count++;
	}

	return (mode & CLIENTCOUNT_MODE_SERVER) ? count + 1 : count;
}