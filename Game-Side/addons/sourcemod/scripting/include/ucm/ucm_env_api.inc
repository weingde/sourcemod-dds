/************************************************************************
 * User Class Management - MAIN INCLUDE :: ENV API LIST (Sourcemod)
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

enum ClassInfo
{
	ClassInfo_Name = 0,			// 등급 이름
	ClassInfo_Code,				// 등급 코드
	ClassInfo_Env				// 등급 Env
};

/**
 * @brief	UCM 플러그인의 활성화 유무를 가져옵니다.
 *			'ucm_switch_plugin' Convar에 의하여 결정됩니다.
 *
 * @return	UCM 플러그인이 활성화되었다면 true, 그렇지 않다면 false
 */
native bool UCM_IsPluginOn();

/**
 * @brief	클라이언트의 등급 코드를 가져옵니다.
 *
 * @param client				클라이언트 인덱스
 * @return	클라이언트의 등급 코드, 실패했다면 0
 */
native int UCM_GetClientClass(int client);

/**
 * @brief	UCM 플러그인에 등록되어 있는 등급의 갯수를 가져옵니다.
 *
 * @return	등록된 등급 갯수
 */
native int UCM_GetClassCount();

/**
 * @brief	UCM 플러그인에 등록되어 있는 등급 정보를 가져옵니다.
 *			등록된 등급 정보는 SQL 데이터베이스에서 가져오게 되며 코어에서 필터링을 거쳐 최종적으로 등록됩니다.
 *			이 함수는 최종적으로 등록된 등급 정보를 가져옵니다.
 *
 * @param classcode				등급 코드
 * @param proctype				처리 타입
 * @param buffer				정보를 담을 문자열
 * @return	정상적으로 등록되었다면 true, 그렇지 않다면 false
 */
native bool UCM_GetClassInfo(int classcode, ClassInfo proctype, char[] buffer);

/**
 * @brief	해당하는 등급 코드가 담긴 등급 목록 인덱스를 가져옵니다.
 *
 * @param classcode				등급 코드
 * @return	등급 목록 인덱스, 실패했다면 -1
 */
native int UCM_FindClassIndex(int classcode);