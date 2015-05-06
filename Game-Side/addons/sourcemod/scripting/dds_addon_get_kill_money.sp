/************************************************************************
 * Dynamic Dollar Shop - [Addon] Get Kill Money (Sourcemod)
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

#define DDS_ADD_NAME			"Dynamic Dollar Shop :: [Addon] Get Kill Money"

/*******************************************************
 * V A R I A B L E S
*******************************************************/
// Convar 변수
ConVar dds_hCV_MoneyKillRedMin;
ConVar dds_hCV_MoneyKillBlueMin;
ConVar dds_hCV_MoneyKillRedMax;
ConVar dds_hCV_MoneyKillBlueMax;

// 외부 Convar 연결
ConVar dds_hSecureUserMin;

/*******************************************************
 * P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = DDS_ADD_NAME,
	author = DDS_ENV_CORE_AUTHOR,
	description = "This can allow clients to get moneys by killing players.",
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
	dds_hCV_MoneyKillRedMin = 		CreateConVar("dds_get_money_red_min", 		"10", 		"빨간 팀(테러리스트, 레드)에 있는 사람을 죽였을 때 얻는 금액의 최솟값을 적어주세요.", FCVAR_PLUGIN);
	dds_hCV_MoneyKillBlueMin = 		CreateConVar("dds_get_money_blue_min", 		"10", 		"파란 팀(대테러리스트, 블루)에 있는 사람을 죽였을 때 얻는 금액의 최솟값을 적어주세요.", FCVAR_PLUGIN);
	dds_hCV_MoneyKillRedMax = 		CreateConVar("dds_get_money_red_max", 		"50", 		"빨간 팀(테러리스트, 레드)에 있는 사람을 죽였을 때 얻는 금액의 최댓값을 적어주세요.", FCVAR_PLUGIN);
	dds_hCV_MoneyKillBlueMax = 		CreateConVar("dds_get_money_blue_max", 		"50", 		"파란 팀(대테러리스트, 블루)에 있는 사람을 죽였을 때 얻는 금액의 최댓값을 적어주세요.", FCVAR_PLUGIN);

	// Event Hook 연결
	HookEvent("player_death", Event_OnPlayerDeath);
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
		// 작업 방지 ConVar 로드
		dds_hSecureUserMin = FindConVar("dds_get_secure_user_min");
	}
}


/*******************************************************
 * C A L L B A C K   F U N C T I O N S
*******************************************************/
/**
 * 이벤트 :: 플레이어를 죽일 때
 *
 * @param event					이벤트 핸들
 * @param name					이벤트 이름 문자열
 * @param dontbroadcast			이벤트 브로드캐스트 차단 여부
 */
public Action Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// 플러그인이 꺼져 있을 때는 동작 안함
	if (!DDS_IsPluginOn())	return Plugin_Continue;

	// 이벤트 핸들을 통해 클라이언트 식별
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	// 희생자가 없다면 통과
	if (victim <= 0)	return Plugin_Continue;

	// 공격자가 없다면 통과
	if (attacker <= 0)	return Plugin_Continue;

	// 희생자가 게임 내에 없다면 통과
	if (!IsClientInGame(victim))	return Plugin_Continue;

	// 공격자가 게임 내에 없다면 통과
	if (!IsClientInGame(attacker))	return Plugin_Continue;

	// 희생자가 인증을 받지 못했다면 통과
	if (!IsClientAuthorized(victim))	return Plugin_Continue;

	// 공격자가 인증을 받지 못했다면 통과
	if (!IsClientAuthorized(attacker))	return Plugin_Continue;

	// 희생자가 봇이라면 통과
	if (IsFakeClient(victim))	return Plugin_Continue;

	// 공격자가 봇이라면 통과
	if (IsFakeClient(attacker))	return Plugin_Continue;

	// 최소 인원이 들어가있지 않다면 통과
	if (GetClientCountEx() < dds_hSecureUserMin.IntValue) return Plugin_Continue;

	// 희생자 이름 추출
	char sVicName[32];
	GetClientName(victim, sVicName, sizeof(sVicName));

	// 팀에 따른 금액 결정
	int iRanMoney;
	if (GetClientTeam(victim) == 2)
		iRanMoney = GetRandomInt(dds_hCV_MoneyKillRedMin.IntValue, dds_hCV_MoneyKillRedMax.IntValue);
	else if (GetClientTeam(victim) == 3)
		iRanMoney = GetRandomInt(dds_hCV_MoneyKillBlueMin.IntValue, dds_hCV_MoneyKillBlueMax.IntValue);

	// 금액 설정
	DDS_SetClientMoney(attacker, DataProc_MONEYUP, iRanMoney);

	// 채팅창 출력
	DDS_PrintToChat(attacker, "%t", "system get money kill msg", sVicName, iRanMoney, "global money");

	return Plugin_Continue;
}