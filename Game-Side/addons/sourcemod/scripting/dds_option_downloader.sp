/************************************************************************
 * Dynamic Dollar Shop - [Option] Downloader (Sourcemod)
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

#define DDS_ADD_NAME			"Dynamic Dollar Shop :: [Option] Downloader"
#define DDS_DOWNCONFIG_PATH		"dds_downloader.ini"

/*******************************************************
 * V A R I A B L E S
*******************************************************/
// Convar 변수
ConVar dds_hCV_SwitchDownloader;

// 다운로드
File dds_hDownConfigFile = null;

/*******************************************************
 * P L U G I N  I N F O R M A T I O N
*******************************************************/
public Plugin:myinfo = 
{
	name = DDS_ADD_NAME,
	author = DDS_ENV_CORE_AUTHOR,
	description = "This can allow clients to download using server files for playing game.",
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
	dds_hCV_SwitchDownloader = CreateConVar("dds_switch_downloader", "1", "다운로더의 작동 여부입니다. 작동을 원하지 않으시다면 0을, 원하신다면 1을 써주세요.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
}

/**
 * 설정이 로드되고 난 후
 */
public void OnConfigsExecuted()
{
	// 플러그인이 꺼져 있을 때는 동작 안함
	if (!DDS_IsPluginOn())	return;

	// 다운로더가 꺼져 있을 때는 동작 안함
	if (!dds_hCV_SwitchDownloader.BoolValue)	return;

	// 버퍼 준비
	char buffer[256];

	// 다운로드 목록 파일 로드
	Format(buffer, sizeof(buffer), "./addons/sourcemod/configs/%s", DDS_DOWNCONFIG_PATH);
	dds_hDownConfigFile = OpenFile(buffer, "r");

	// 파일 없으면 차단
	if (dds_hDownConfigFile == null)
	{
		DDS_PrintToServer("configs/%s is not loadable!", DDS_DOWNCONFIG_PATH);
		return;
	}

	// 라인 로드
	char sLine[512];

	while (dds_hDownConfigFile.ReadLine(sLine, sizeof(sLine)))
	{
		// 주석(세미콜론) 제외 처리
		// 주석이 시작하는 부분부터 삭제처리
		char sRealLine[512];
		if (SplitString(sLine, ";", sRealLine, sizeof(sRealLine)) == -1)
			strcopy(sRealLine, sizeof(sRealLine), sLine);

		// 공백 허용 안함
		TrimString(sRealLine);

		// 아무것도 없는 빈 줄은 통과
		if (strlen(sRealLine) <= 0)	continue;

		// 다운로드 테이블 등록
		AddFileToDownloadTable(sRealLine);
	}
}

/*******************************************************
 * G E N E R A L   F U N C T I O N S
*******************************************************/
/**
 * 다운로더 :: 다운로드 테이블 등록
 *
 * @param path					경로
 */
public void AddFileToDownloadTable(const char[] path)
{
	// 경로 오픈
	DirectoryListing hCurDir = OpenDirectory(path);

	// 이용 변수 준비
	char sFileName[64];
	char sSetDir[256];
	FileType eType;

	// 경로가 없다면 차단
	if (hCurDir == null)
	{
		DDS_PrintToServer("Adding to Download table is Failed: %s", path);
		return;
	}

	while (hCurDir.GetNext(sFileName, sizeof(sFileName), eType))
	{
		if (eType == FileType_Directory)	// 디렉토리
		{
			// 확장자가 없으면 디렉토리
			if (FindCharInString(sFileName, '.', false) == -1)
			{
				// 한번 더 조사
				Format(sSetDir, sizeof(sSetDir), "%s/%s", path, sFileName);
				AddFileToDownloadTable(sSetDir);
			}
		}
		else if (eType == FileType_File)	// 파일
		{
			// 바로 추가
			Format(sSetDir, sizeof(sSetDir), "%s/%s", path, sFileName);
			AddFileToDownloadsTable(sSetDir);
		}
	}

	delete hCurDir;
	hCurDir = null;
}