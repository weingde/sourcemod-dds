/**********************************************************
 * --------------------------------------------------------
 * Dynamic Dollar Shop
 * --------------------------------------------------------
 *
 * Author By. Eakgnarok
 *
***********************************************************/
SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";


/***********************
 * [Game Nid Databases]
************************/
CREATE TABLE IF NOT EXISTS `dds_user_profile` (
	`idx` INT(16) UNSIGNED NOT NULL AUTO_INCREMENT,
	`authid` VARCHAR(20) NOT NULL,
	`nickname` VARCHAR(32) NOT NULL DEFAULT '',
	`money` INT(16) UNSIGNED NOT NULL DEFAULT '0',
	`ingame` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
	`refdata` VARCHAR(256) NOT NULL DEFAULT '',
	PRIMARY KEY (`idx`),
	UNIQUE KEY `authid` (`authid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `dds_user_item` (
	`idx` INT(16) UNSIGNED NOT NULL AUTO_INCREMENT,
	`authid` VARCHAR(20) NOT NULL,
	`ilidx` INT(8) UNSIGNED NOT NULL,
	`aplied` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
	`buydate` VARCHAR(20) NOT NULL DEFAULT '0',
	PRIMARY KEY (`idx`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `dds_user_setting` (
	`idx` INT(16) UNSIGNED NOT NULL AUTO_INCREMENT,
	`authid` VARCHAR(20) NOT NULL,
	`onecate` VARCHAR(20) NOT NULL,
	`twocate` INT(8) UNSIGNED NOT NULL,
	`setvalue` VARCHAR(32) NOT NULL DEFAULT '',
	PRIMARY KEY (`idx`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `dds_item_category` (
	`icidx` INT(8) UNSIGNED NOT NULL AUTO_INCREMENT,
	`gloname` VARCHAR(300) NOT NULL DEFAULT '',
	`orderidx` INT(8) UNSIGNED NOT NULL DEFAULT '0',
	`env` VARCHAR(512) NOT NULL DEFAULT '',
	`status` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
	PRIMARY KEY (`icidx`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `dds_item_list` (
	`ilidx` INT(8) UNSIGNED NOT NULL AUTO_INCREMENT,
	`gloname` VARCHAR(300) NOT NULL DEFAULT '',
	`icidx` INT(8) UNSIGNED NOT NULL DEFAULT '0',
	`money` INT(16) UNSIGNED NOT NULL DEFAULT '0',
	`havtime` INT(16) NOT NULL DEFAULT '0',
	`env` VARCHAR(512) NOT NULL DEFAULT '',
	`status` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
	PRIMARY KEY (`ilidx`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `dds_log_data` (
	`idx` INT(32) UNSIGNED NOT NULL AUTO_INCREMENT,
	`authid` VARCHAR(20) NOT NULL,
	`action` VARCHAR(25) NOT NULL,
	`setdata` VARCHAR(128) NOT NULL DEFAULT '',
	`thisdate` VARCHAR(20) NOT NULL DEFAULT '0',
	`usrip` VARCHAR(20) NOT NULL,
	PRIMARY KEY (`idx`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `dds_env_list` (
	`idx` INT(32) UNSIGNED NOT NULL AUTO_INCREMENT,
	`onecate` VARCHAR(20) NOT NULL,
	`twocate` VARCHAR(64) NOT NULL,
	`setdata` VARCHAR(128) NOT NULL DEFAULT '',
	`desc` TEXT NOT NULL DEFAULT '',
	PRIMARY KEY (`idx`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


/***********************
 * [Nid Table Records to Game Databases]
************************/
/** ENV LIST **/
INSERT INTO `dds_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'item', 'ENV_DDS_SYS_GAME', 'all', '아이템이 적용될 게임 이름을 적습니다. 게임 이름은 서버의 SRCDS 실행 파일이 있는 게임 폴더의 이름으로 결정됩니다. 모두 적용하려면 [all]을 적어주시고, 따로 적용하시려면 ,(콤마)로 구분해서 적어주세요. 전부 허용을 안한다면 [none]을 적어주세요. 기본값은 [all]으로 정해져 있습니다.');
INSERT INTO `dds_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'item', 'ENV_DDS_INFO_ADRS', '', '아이템을 사용하는데 있어 필요한 파일을 적습니다. 예를 들어 플러그인에서 모델을 로드할 때 본 ENV 설정값을 로드하여 적용하듯이 활용하시면 됩니다. 기본값은 빈칸으로 정해져 있습니다.');
INSERT INTO `dds_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'item', 'ENV_DDS_INFO_POS', '0 0 0', '아이템을 사용하는데 있어 필요한 위치 정보를 적습니다. 빈칸을 구분으로 x, y, z정보를 적어주시면 됩니다. 기본값은 [0 0 0]으로 정해져 있습니다.');
INSERT INTO `dds_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'item', 'ENV_DDS_INFO_ANG', '0 0 0', '아이템을 사용하는데 있어 필요한 각도 정보를 적습니다. 빈칸을 구분으로 3구간으로 나눠 적어주시면 됩니다. 기본값은 [0 0 0]으로 정해져 있습니다.');
INSERT INTO `dds_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'item', 'ENV_DDS_INFO_COLOR', '255 255 255 255', '아이템을 사용하는데 있어 필요한 색깔 정보를 적습니다. 빈칸을 구분으로 R, G, B, A정보를 적어주시면 됩니다. 기본값은 [255 255 255 255]으로 정해져 있습니다.');
INSERT INTO `dds_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'item', 'ENV_DDS_INFO_TAGSTR', '', '아이템을 사용하는데 있어 태그 문자열을 적습니다. 태그와 관련된 아이템을 만드실 경우 플러그인에서 본 ENV 설정값을 로드하여 적용하시면 됩니다. 기본값은 빈칸으로 정해져 있습니다.');
INSERT INTO `dds_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'item', 'ENV_DDS_INFO_FREETAG', '0', '아이템을 사용하는데 있어 자유형 태그인지를 적습니다. 태그와 관련된 아이템을 만드실 경우 플러그인에서 본 ENV 설정값을 로드하여 적용하시면 됩니다. 활성화를 하려면 [1]을 적어주시면 됩니다. 기본값은 [0]으로 정해져 있습니다.');
INSERT INTO `dds_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'item', 'ENV_DDS_LIMIT_BUY_CLASS', 'all', '아이템을 구매하는데 있어 허용할 등급 번호를 적습니다. 모두 적용하려면 [all]을 적어주시고, 따로 적용하사려면 ,(콤마)로 구분해서 적어주세요. 전부 허용을 안한다면 [none]을 적어주세요. 기본값은 [all]으로 정해져 있습니다.');
INSERT INTO `dds_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'item', 'ENV_DDS_LIMIT_USE_CLASS', 'all', '아이템을 이용/장착하는데 있어 허용할 등급 번호를 적습니다. 모두 적용하려면 [all]을 적어주시고, 따로 적용하사려면 ,(콤마)로 구분해서 적어주세요. 전부 허용을 안한다면 [none]을 적어주세요. 기본값은 [all]으로 정해져 있습니다.');
INSERT INTO `dds_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'item', 'ENV_DDS_LIMIT_SHOW_LIST_CLASS', 'all', '아이템의 목록 출력이 보여질 등급 번호를 적습니다. 모두 적용하려면 [all]을 적어주시고, 따로 적용하사려면 ,(콤마)로 구분해서 적어주세요. 전부 허용을 안한다면 [none]을 적어주세요. 기본값은 [all]으로 정해져 있습니다.');
INSERT INTO `dds_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'item', 'ENV_DDS_USE_TEAM', '2,3', '아이템을 사용할 때 적용될 팀의 번호를 적습니다. 모두 적용하려면 [all]을 적어주시고, 따로 적용하사려면 ,(콤마)로 구분해서 적어주세요. 전부 허용을 안한다면 [none]을 적어주세요. 기본값은 [2,3]으로 정해져 있습니다.');
INSERT INTO `dds_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'item-category', 'ENV_DDS_SYS_GAME', 'all', '아이템이 적용될 게임 이름을 적습니다. 게임 이름은 서버의 SRCDS 실행 파일이 있는 게임 폴더의 이름으로 결정됩니다. 모두 적용하려면 all을 적어주시고, 따로 적용하시려면 ,(콤마)로 구분해서 적어주세요.');
INSERT INTO `dds_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'item-category', 'ENV_DDS_LIMIT_BUY_CLASS', 'all', '아이템 종류 내의 아이템을 구매하는데 있어 허용할 등급 번호를 적습니다. 모두 적용하려면 [all]을 적어주시고, 따로 적용하사려면 ,(콤마)로 구분해서 적어주세요. 전부 허용을 안한다면 [none]을 적어주세요. 기본값은 [all]으로 정해져 있습니다.');
INSERT INTO `dds_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'item-category', 'ENV_DDS_LIMIT_USE_CLASS', 'all', '아이템 종류 내의 아이템을 이용/장착하는데 있어 허용할 등급 번호를 적습니다. 모두 적용하려면 [all]을 적어주시고, 따로 적용하사려면 ,(콤마)로 구분해서 적어주세요. 전부 허용을 안한다면 [none]을 적어주세요. 기본값은 [all]으로 정해져 있습니다.');
INSERT INTO `dds_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'item-category', 'ENV_DDS_LIMIT_SHOW_LIST_CLASS', 'all', '아이템 종류 내의 아이템의 목록 출력이 보여질 등급 번호를 적습니다. 모두 적용하려면 [all]을 적어주시고, 따로 적용하사려면 ,(콤마)로 구분해서 적어주세요. 전부 허용을 안한다면 [none]을 적어주세요. 기본값은 [all]으로 정해져 있습니다.');
INSERT INTO `dds_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'item-category', 'ENV_DDS_USE_TEAM', '2,3', '아이템 종류 내의 아이템을 사용할 때 적용될 팀의 번호를 적습니다. 모두 적용하려면 [all]을 적어주시고, 따로 적용하사려면 ,(콤마)로 구분해서 적어주세요. 전부 허용을 안한다면 [none]을 적어주세요. 기본값은 [2,3]으로 정해져 있습니다.');


/** Apply Env List to Item and Item Category **/
INSERT INTO `dds_item_category` (`icidx`, `gloname`, `orderidx`, `env`, `status`) VALUES (NULL, 'en:Trail||ko:트레일', '1', 'ENV_DDS_SYS_GAME:all||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_category` (`icidx`, `gloname`, `orderidx`, `env`, `status`) VALUES (NULL, 'en:Red Skin||ko:레드 스킨', '2', 'ENV_DDS_SYS_GAME:all||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2', '1');
INSERT INTO `dds_item_category` (`icidx`, `gloname`, `orderidx`, `env`, `status`) VALUES (NULL, 'en:Blue Skin||ko:블루 스킨', '3', 'ENV_DDS_SYS_GAME:all||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:3', '1');
INSERT INTO `dds_item_category` (`icidx`, `gloname`, `orderidx`, `env`, `status`) VALUES (NULL, 'en:Effect Shoes||ko:이펙트 슈즈', '4', 'ENV_DDS_SYS_GAME:all||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_category` (`icidx`, `gloname`, `orderidx`, `env`, `status`) VALUES (NULL, 'en:Chat Tag||ko:채팅 태그', '5', 'ENV_DDS_SYS_GAME:all||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:all', '1');


/** ITEM LIST **/
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Big Star||ko:큰별', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/star.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Rainbow||ko:무지개', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/rainbow.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Mario||ko:마리오', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/mario.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Luigi||ko:루이지', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/luigi.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Goomba||ko:굼바', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/goomba.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Money||ko:돈', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/money.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Mushroom||ko:버섯', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/mushroom.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Burger||ko:햄버거', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/burger.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Coffee||ko:커피', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/coffee2.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Stars||ko:별들', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/stars.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:LOL||ko:LOL', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/lol.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Angry Face||ko:화난 얼굴', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/angry.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:AOL||ko:졸라맨', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/aol.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Apple||ko:사과', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/apple.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Arrow||ko:화살표', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/arrow.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Awesome Face||ko:웃는 얼굴', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/awesomeface.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Bubbles||ko:거품', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/bubbles.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Care Bear||ko:분홍색곰', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/carebear.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Chimaira||ko:키마이라', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/chimaira.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Chrome||ko:크롬', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/chrome.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:FireFox||ko:파이어폭스', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/firefox.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:HL2||ko:하프라이프2', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/hl2.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:CSS||ko:CSS', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/css.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:DODS||ko:DODS', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/dods.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Dots||ko:점들', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/dots.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Easter Egg||ko:부활절 달걀', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/easteregg.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:FireBird||ko:파이어버드', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/firebird.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Footprint||ko:발자국', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/footprint.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Handy||ko:장애인 표시', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/handy.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Happy||ko:스마일', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/happy.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Suzumiya Haruhi||ko:스즈미야 하루히', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/haruhi_suzumiya.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Konata||ko:코나타', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/konata.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Linux||ko:리눅스', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/linux.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Love||ko:하트', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/love.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Pikachu||ko:피카츄', '1', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/trails/pikachu.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');

INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:White Bear(Red)||ko:흰곰돌이(레드)', '2', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:models/player/whitebear/whitebear.mdl||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:White Bear(Blue)||ko:흰곰돌이(블루)', '3', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:models/player/whitebear/whitebear.mdl||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:3', '1');

INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Red||ko:빨강색', '4', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/sprites/laser.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 0 0 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Orange||ko:주황색', '4', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/sprites/laser.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 108 0 200||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Yellow||ko:노랑색', '4', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/sprites/laser.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 242 0 200||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Green||ko:초록색', '4', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/sprites/laser.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:0 255 0 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Blue||ko:파랑색', '4', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/sprites/laser.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:0 0 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Violet||ko:보라색', '4', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:materials/sprites/laser.vmt||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:134 0 255 200||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:2,3', '1');

INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:ADMIN||ko:ADMIN', '5', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:ADMIN||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:all', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Developer||ko:Developer', '5', '100', '0', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:Developer||ENV_DDS_INFO_FREETAG:0||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:all', '1');
INSERT INTO `dds_item_list` (`ilidx`, `gloname`, `icidx`, `money`, `havtime`, `env`, `status`) VALUES (NULL, 'en:Disposable Free Tag||ko:일회용 자유 태그', '5', '100', '-1', 'ENV_DDS_SYS_GAME:all||ENV_DDS_INFO_ADRS:||ENV_DDS_INFO_POS:0 0 0||ENV_DDS_INFO_ANG:0 0 0||ENV_DDS_INFO_COLOR:255 255 255 255||ENV_DDS_INFO_TAGSTR:||ENV_DDS_INFO_FREETAG:1||ENV_DDS_LIMIT_BUY_CLASS:all||ENV_DDS_LIMIT_USE_CLASS:all||ENV_DDS_LIMIT_SHOW_LIST_CLASS:all||ENV_DDS_USE_TEAM:all', '1');


/***********************
 * [CodeIgniter]
************************/
CREATE TABLE IF NOT EXISTS  `dds_sessions` (
	`session_id` VARCHAR(40) NOT NULL DEFAULT '0',
	`ip_address` VARCHAR(16) NOT NULL DEFAULT '0',
	`user_agent` VARCHAR(120) NOT NULL,
	`last_activity` INT(10) UNSIGNED NOT NULL DEFAULT 0,
	`user_data` TEXT NOT NULL,
	PRIMARY KEY (`session_id`),
	KEY `last_activity_idx` (`last_activity`)
);