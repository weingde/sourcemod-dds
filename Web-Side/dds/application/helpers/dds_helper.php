<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');

function GetCodeByLanguage($code, $lower = true, $rev = true) {
	$data = array(
		"en" => "English",
		"ar" => "Arabic",
		"pt" => "Brazilian",
		"bg" => "Bulgarian",
		"cze" => "Czech",
		"da" => "Danish",
		"nl" => "Dutch",
		"fi" => "Finnish",
		"fr" => "French",
		"de" => "German",
		"el" => "Greek",
		"he" => "Hebrew",
		"hu" => "Hungarian",
		"it" => "Italian",
		"jp" => "Japanese",
		"ko" => "Korean",
		"lv" => "Latvian",
		"lt" => "Lithuanian",
		"no" => "Norwegian",
		"pl" => "Polish",
		"pt_p" => "Portuguese",
		"ro" => "Romanian",
		"ru" => "Russian",
		"chi" => "SChinese",
		"sk" => "Slovak",
		"es" => "Spanish",
		"sv" => "Swedish",
		"zho" => "TChinese",
		"th" => "Thai",
		"tr" => "Turkish",
		"ua" => "Ukrainian"
	);
	foreach ($data as $key => $val)
	{
		if (!$rev)
		{
			if (strcasecmp($key, $code) != 0)	continue;
			return $lower ? strtolower($val) : $val;
		}
		else
		{
			if (strcasecmp($val, $code) != 0)	continue;
			return $lower ? strtolower($key) : $key;
		}
	}
}

function SplitStrByGeoName($geo, $gloname)
{
	$lineCut = '||';
	$valueCut = ':';

	if (strlen($gloname) <= 0)
	{
		return '';
	}
	$geoidx = strpos($gloname, $geo);
	$endidx = strpos($gloname, $lineCut, $geoidx);
	$realData = '';
	if ($endidx === false)	$realData = substr($gloname, $geoidx);
	else	$realData = substr($gloname, $geoidx, $endidx);

	$val = explode($valueCut, $realData);

	return $val[1];
}

function GetTotalFormatValue($val)
{
	// '||'를 기준으로 라인 커팅
	$valList = explode('||', $val);

	// 맨 마지막이 비어있는 경우는 제거
	if (empty($valList[count($valList) - 1]) && (count($valList) > 1) && (strcmp($valList[count($valList) -1], '0') != 0))
		array_pop($valList);

	// ':'를 기준으로 값 커팅
	$setList = array();
	for ($i = 0; $i < count($valList); $i++) {
		$tp_set = explode(':', $valList[$i]);
		array_push($setList, array('name' => $tp_set[0], 'value' => (isset($tp_set[1])) ? $tp_set[1] : ''));
	}

	return $setList;
}

function GetSeparateValue($val)
{
	// '||'를 기준으로 라인 커팅
	$valList = explode('||', $val);

	// 맨 마지막이 비어있는 경우는 제거
	if (empty($valList[count($valList) - 1]) && (count($valList) > 1) && (strcmp($valList[count($valList) -1], '0') != 0))
		array_pop($valList);

	return $valList;
}

?>