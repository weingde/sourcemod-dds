/************************************************************************
 * Dynamic Dollar Shop - MAIN INCLUDE :: ENV API LIST (Sourcemod)
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
 * For DDS_OnDataProcess
 * 참조하는 함수명: System_DataProcess, DDS_UseDataProcess
 */
enum DataProcess
{
	DataProc_BUY = 0,				// 아이템 구매
	DataProc_USE,					// 인벤토리에서의 아이템 사용하기
	DataProc_RESELL,				// 인벤토리에서의 아이템 되팔기
	DataProc_GIFT,					// 인벤토리에서의 아이템 선물하기
	DataProc_DROP,					// 인벤토리에서의 아이템 버리기
	DataProc_CURCANCEL,				// 내 장착 아이템에서의 장착 해제
	DataProc_CURUSE,				// 내 장착 아이템에서의 장착
	DataProc_MONEYUP,				// 금액 증가
	DataProc_MONEYDOWN,				// 금액 감소
	DataProc_MONEYGIFT,				// 금액 선물
	DataProc_MONEYGIVE,				// 금액 주기
	DataProc_MONEYTAKEAWAY,			// 금액 뺏기
	DataProc_ITEMGIFT,				// 아이템 선물
	DataProc_ITEMGIVE,				// 아이템 주기
	DataProc_ITEMTAKEAWAY,			// 아이템 뺏기
	DataProc_USERREFDATA			// 클라이언트 기타 참고 데이터
};

/**
 * For DDS_GetItemInfo
 */
enum ItemInfo
{
	ItemInfo_INDEX = 0,				// 아이템 번호
	ItemInfo_NAME,					// 아이템 이름
	ItemInfo_CATECODE,				// 아이템 종류 코드
	ItemInfo_MONEY,					// 아이템 금액
	ItemInfo_HAVTIME,				// 아이템 기간 설정
	ItemInfo_ENV					// 아이템 환경 변수
};

/**
 * For DDS_GetItemCategoryInfo
 */
enum ItemCategoryInfo
{
	ItemCGInfo_NAME = 0,			// 아이템 종류 이름
	ItemCGInfo_CODE,				// 아이템 종류 코드
	ItemCGInfo_ENV,					// 아이템 종류 환경 변수
	ItemCGInfo_STATUS				// 아이템 종류 활성 여부
};



/**
 * @brief	DDS 플러그인의 활성화 유무를 가져옵니다.
 *			'dds_switch_plugin' Convar에 의하여 결정됩니다.
 *
 * @return	DDS 플러그인이 활성화되었다면 true, 그렇지 않다면 false
 */
native bool DDS_IsPluginOn();

/**
 * @brief	DDS 플러그인의 SQL 활성화 유무를 가져옵니다.
 *			SQL 데이터베이스가 성공적으로 연결되고, 필요 정보까지 다 불러왔다면 활성화됩니다.
 *
 * @return	서버측 SQL 데이터베이스가 활성화되었다면 true, 그렇지 않다면 false
 */
native bool DDS_GetServerSQLStatus();

/**
 * @brief	클라이언트 별 SQL 활성화 유무를 가져옵니다.
 *			클라이언트가 접속하여 초반 필요 정보들을 성공적으로 불러왔다면 활성화됩니다.
 *
 * @param client				클라이언트 인덱스
 * @return	클라이언트 SQL 데이터베이스가 활성화되었다면 true, 그렇지 않다면 false
 */
native bool DDS_GetClientSQLStatus(int client);

/**
 * @brief	DDS 플러그인에 아이템 종류 플러그인을 연결합니다.
 *			연결하여 사용하면 데이터베이스에 등록되어 있는 모든 아이템 종류 코드와 비교하여
 *			등록되어 있으면 활성화되며 쓸 수 있게 됩니다.
 *			참고로, 이 함수는 'OnLibraryAdded()' 포워드 함수를 이용하여 쓰는 것이 좋습니다.
 *
 * @param catecode				아이템 종류 코드
 */
native void DDS_CreateItemCategory(int catecode);

/**
 * @brief	DDS 플러그인에 연결된 아이템 종류 플러그인이 제대로 등록되었는지 상태를 반환합니다.
 *
 * @param catecode				아이템 종류 코드
 * @return	정상적으로 등록되었다면 true, 그렇지 않다면 false
 */
native bool DDS_GetItemCategoryStatus(int catecode);

/**
 * @brief	DDS 플러그인에 등록된 아이템 정보를 가져옵니다.
 *			등록된 아이템 정보는 SQL 데이터베이스에서 가져오게 되며 코어에서 필터링을 거쳐 최종적으로 등록됩니다.
 *			이 함수는 최종적으로 등록된 아이템 정보를 가져옵니다.
 *
 * @param itemidx				아이템 번호
 * @param proctype				처리 타입
 * @param buffer				정보를 담을 문자열
 * @param raw					itemidx를 처리할 때 목록 번호로 치환하는지 여부
 * @return	정상적으로 등록되었다면 true, 그렇지 않다면 false
 */
native bool DDS_GetItemInfo(int itemidx, ItemInfo proctype, char[] buffer, bool raw = false);

/**
 * @brief	DDS 플러그인에 등록된 아이템들의 총 갯수를 반환합니다.
 *
 * @return	등록된 아이템들의 갯수
 */
native int DDS_GetItemCount();

/**
 * @brief	DDS 플러그인에 등록되어 있는 아이템 종류 정보를 가져옵니다.
 *			등록된 아이템 종류 정보는 SQL 데이터베이스에서 가져오게 되며 코어에서 필터링을 거쳐 최종적으로 등록됩니다.
 *			이 함수는 최종적으로 등록된 아이템 종류 정보를 가져옵니다.
 *
 * @param catecode				아이템 종류 코드
 * @param proctype				처리 타입
 * @param buffer				정보를 담을 문자열
 * @param raw					catecode 처리할 때 목록 번호로 치환하는지 여부
 * @return	정상적으로 등록되었다면 true, 그렇지 않다면 false
 */
native bool DDS_GetItemCategoryInfo(int catecode, ItemCategoryInfo proctype, char[] buffer, bool raw = false);

/**
 * @brief	DDS 플러그인에 등록된 아이템 종류들의 총 갯수를 반환합니다.
 *
 * @return	등록된 아이템 종류들의 갯수
 */
native int DDS_GetItemCategoryCount();

/**
 * @brief	클라이언트가 가지고 있는 금액을 가져옵니다.
 *
 * @param client				클라이언트 인덱스
 * @return	클라이언트의 금액, 실패 시 -1 반환
 */
native int DDS_GetClientMoney(int client);

/**
 * @brief	클라이언트의 금액을 설정합니다.
 *
 * @param client				클라이언트 인덱스
 * @param process				행동 구별(DataProc_MONEYUP, DataProc_MONEYDOWN)
 * @param amount				양
 * @return	정상적으로 실행을 했다면 true, 그렇지 않다면 false
 */
native bool DDS_SetClientMoney(int client, DataProcess process, int amount);

/**
 * @brief	클라이언트가 현재 장착한 아이템의 데이터베이스 번호를 가져옵니다.
 *
 * @param client				클라이언트 인덱스
 * @param catecode				아이템 종류 코드
 * @return	클라이언트가 현재 장착한 데이터베이스 번호, 실패 시 -1 반환
 */
native int DDS_GetClientAppliedDB(int client, int catecode);

/**
 * @brief	클라이언트가 현재 장착한 아이템 번호를 가져옵니다.
 *
 * @param client				클라이언트 인덱스
 * @param catecode				아이템 종류 코드
 * @return	클라이언트가 현재 장착한 아이템 번호, 실패 시 -1 반환
 */
native int DDS_GetClientAppliedItem(int client, int catecode);

/**
 * @brief	클라이언트의 아이템 종류 별 활성화 상태를 가져옵니다.
 *
 * @param client				클라이언트 인덱스
 * @param catecode				아이템 종류 코드
 * @return	활성화가 되어 있으면 true, 그렇지 않다면 false
 */
native bool DDS_GetClientItemCategorySetting(int client, int catecode);

/**
 * @brief	클라이언트의 기타 참고 데이터를 가져옵니다.
 *
 * @param client				클라이언트 인덱스
 * @param data					데이터가 담길 문자열
 * @return	정상적으로 가져 왔으면 true, 그렇지 않다면 false
 */
native bool DDS_GetClientRefData(int client, char[] data);

/**
 * @brief	DDS 플러그인에 있는 데이터 처리 시스템을 이용합니다.
 *
 * @param client				클라이언트 인덱스
 * @param process				행동 구별
 * @param data					추가 파라메터
 * @return	정상적으로 실행을 했다면 true, 그렇지 않다면 false
 */
native bool DDS_UseDataProcess(int client, DataProcess process, char[] data);

/**
 * @brief	ConVar 'dds_get_secure_user_min'의 값을 가져옵니다.
 *			본 ConVar는 작업 방지를 위한 서버 내 최소한의 인원입니다.
 *
 * @return	'dds_get_secure_user_min'의 ConVar 값
 */
native int DDS_GetSecureUserMin();

/**
 * @brief	DDS 플러그인에서 SQL 데이터베이스로부터 모든 아이템 종류를 불러오고 난 후에 발생합니다.
 *			코어에서 데이터베이스로부터 아이템 종류를 등록한 뒤에 무언가를 해야할 때 쓰시면 좋습니다.
 */
forward void DDS_OnLoadSQLItemCategory();

/**
 * @brief	DDS 플러그인에서 SQL 데이터베이스로부터 모든 아이템을 불러오고 난 후에 발생합니다.
 *			코어에서 데이터베이스로부터 아이템을 등록한 뒤에 무언가를 해야할 때 쓰시면 좋습니다.
 */
forward void DDS_OnLoadSQLItem();

/**
 * @brief	DDS 플러그인에서 클라이언트가 데이터를 전달할 무언가를 할 때 발생합니다.
 *			예를 들면 아이템을 사거나 버리거나 금액을 얻는 등의 행동을 할 때 발생합니다.
 *
 * @param client				클라이언트 인덱스
 * @param process				행동 구별
 * @param data					추가 파라메터
 */
forward void DDS_OnDataProcess(int client, const DataProcess process, const char[] data);

/**
 * @brief	DDS 플러그인에서 데이터 로그를 SQL 데이터베이스에 저장하기 전에 발생합니다.
 *
 * @param authid				주체의 고유번호
 * @param action				주체의 행동
 * @param setdata				주체의 값
 * @param date					주체의 행동으로 인한 발생 시각
 * @param usrip					주체의 아이피 주소
 */
forward Action DDS_OnLogProcessPre(const char[] authid, const char[] action, const char[] setdata, const int date, const char[] usrip);

/**
 * @brief	DDS 플러그인에서 데이터 로그를 SQL 데이터베이스에 저장한 후에 발생합니다.
 *
 * @param authid				주체의 고유번호
 * @param action				주체의 행동
 * @param setdata				주체의 값
 * @param date					주체의 행동으로 인한 발생 시각
 * @param usrip					주체의 아이피 주소
 */
forward void DDS_OnLogProcessPost(const char[] authid, const char[] action, const char[] setdata, const int date, const char[] usrip);