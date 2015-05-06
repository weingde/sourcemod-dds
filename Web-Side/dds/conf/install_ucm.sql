/**********************************************************
 * --------------------------------------------------------
 * Dynamic Dollar Shop - FOR UCM
 * --------------------------------------------------------
 *
 * Author By. Eakgnarok
 *
***********************************************************/
SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";


CREATE TABLE IF NOT EXISTS `ucm_user_profile` (
	`idx` INT(16) UNSIGNED NOT NULL AUTO_INCREMENT,
	`authid` VARCHAR(20) NOT NULL,
	`nickname` VARCHAR(30) NOT NULL DEFAULT '',
	`clidx` INT(8) UNSIGNED NOT NULL DEFAULT '0',
	`joindate` INT(20) UNSIGNED NOT NULL DEFAULT '0',
	`recentdate` INT(20) UNSIGNED NOT NULL DEFAULT '0',
	`stacktime` INT(20) UNSIGNED NOT NULL DEFAULT '0',
	`ingame` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
	`passkey` VARCHAR(64) NOT NULL DEFAULT '',
	PRIMARY KEY (`idx`),
	UNIQUE KEY `authid` (`authid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `ucm_class_list` (
	`clidx` INT(8) UNSIGNED NOT NULL AUTO_INCREMENT,
	`gloname` VARCHAR(256) NOT NULL DEFAULT '',
	`orderidx` INT(8) UNSIGNED NOT NULL DEFAULT '0',
	`env` VARCHAR(512) NOT NULL DEFAULT 'ENV_UCM_ACCESS_CHANGE_CLASS:0',
	`status` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
	PRIMARY KEY (`clidx`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `ucm_env_list` (
	`idx` INT(32) UNSIGNED NOT NULL AUTO_INCREMENT,
	`onecate` VARCHAR(20) NOT NULL,
	`twocate` VARCHAR(64) NOT NULL,
	`setdata` VARCHAR(128) NOT NULL DEFAULT '',
	`desc` TEXT NOT NULL DEFAULT '',
	PRIMARY KEY (`idx`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

/**************************************
 * We have to set default class list!!
 **************************************/
/** ENV LIST **/
INSERT INTO `ucm_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'class', 'ENV_UCM_ACCESS_CHANGE_CLASS', '0', '게임 내에서 유저들의 등급을 바꿀 수 있는 지를 적습니다. 관리자 역할이면 활성화를 권장합니다. 가능하게 하려면 [1]을 적어주세요. 기본값은 [0]으로 정해져 있습니다.');
INSERT INTO `ucm_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'class', 'ENV_DDS_ACCESS_MONEY_GIFT', '1', '금액 선물 기능을 사용할 수 있는지를 적습니다. 가능하게 하려면 [1]을 적어주세요. 기본값은 [1]으로 정해져 있습니다.');
INSERT INTO `ucm_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'class', 'ENV_DDS_ACCESS_MONEY_GIVE', '0', '금액 주기 기능을 사용할 수 있는지를 적습니다. 관리자 역할이면 활성화를 권장합니다. 가능하게 하려면 [1]을 적어주세요. 기본값은 [0]으로 정해져 있습니다.');
INSERT INTO `ucm_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'class', 'ENV_DDS_ACCESS_MONEY_TAKEAWAY', '0', '금액 뺏기 기능을 사용할 수 있는지를 적습니다. 관리자 역할이면 활성화를 권장합니다. 가능하게 하려면 [1]을 적어주세요. 기본값은 [0]으로 정해져 있습니다.');
INSERT INTO `ucm_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'class', 'ENV_DDS_ACCESS_ITEM_GIFT', '1', '아이템 선물을 사용할 수 있는지를 적습니다. 가능하게 하려면 [1]을 적어주세요. 기본값은 [1]으로 정해져 있습니다.');
INSERT INTO `ucm_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'class', 'ENV_DDS_ACCESS_ITEM_RESELL', '1', '아이템 재판매를 사용할 수 있는지를 적습니다. 가능하게 하려면 [1]을 적어주세요. 기본값은 [1]으로 정해져 있습니다.');
INSERT INTO `ucm_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'class', 'ENV_DDS_ACCESS_ITEM_GIVE', '0', '아이템 주기를 사용할 수 있는지를 적습니다. 관리자 역할이면 활성화를 권장합니다. 가능하게 하려면 [1]을 적어주세요. 기본값은 [0]으로 정해져 있습니다.');
INSERT INTO `ucm_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'class', 'ENV_DDS_ACCESS_ITEM_TAKEAWAY', '0', '아이템 뺏기를 사용할 수 있는지를 적습니다. 관리자 역할이면 활성화를 권장합니다. 가능하게 하려면 [1]을 적어주세요. 기본값은 [0]으로 정해져 있습니다.');
INSERT INTO `ucm_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'class', 'ENV_DDS_ACCESS_INIT', '0', '데이터베이스 초기화를 사용할 수 있는지를 적습니다. 관리자 역할이면 활성화를 권장합니다. 가능하게 하려면 [1]을 적어주세요. 기본값은 [0]으로 정해져 있습니다.');
INSERT INTO `ucm_env_list` (`idx`, `onecate`, `twocate`, `setdata`, `desc`) VALUES (NULL, 'class', 'ENV_DDS_ACCESS_WEB_MANAGE', '0', '웹 패널의 관리 기능을 사용할 수 있는지를 적습니다. 관리자 역할이면 활성화를 권장합니다. 가능하게 하려면 [1]을 적어주세요. 기본값은 [0]으로 정해져 있습니다.');


/** NORMAL CLASS **/
INSERT INTO `ucm_class_list` (`clidx`, `gloname`, `orderidx`, `env`, `status`) VALUES (NULL, 'EN:Normal||KO:일반', '1', 'ENV_UCM_ACCESS_CHANGE_CLASS:0||ENV_DDS_ACCESS_MONEY_GIFT:1||ENV_DDS_ACCESS_MONEY_GIVE:0||ENV_DDS_ACCESS_MONEY_TAKEAWAY:0||ENV_DDS_ACCESS_ITEM_GIFT:1||ENV_DDS_ACCESS_ITEM_RESELL:1||ENV_DDS_ACCESS_ITEM_GIVE:0||ENV_DDS_ACCESS_ITEM_TAKEAWAY:0||ENV_DDS_ACCESS_INIT:0||ENV_DDS_ACCESS_WEB_MANAGE:0||ENV_DDS_USE_MONEY:1', '1');

/** SUPER ADMINISTRATOR CLASS **/
INSERT INTO `ucm_class_list` (`clidx`, `gloname`, `orderidx`, `env`, `status`) VALUES (NULL, 'EN:Super Admin||KO:최고 관리자', '4', 'ENV_UCM_ACCESS_CHANGE_CLASS:1||ENV_DDS_ACCESS_MONEY_GIFT:1||ENV_DDS_ACCESS_MONEY_GIVE:1||ENV_DDS_ACCESS_MONEY_TAKEAWAY:1||ENV_DDS_ACCESS_ITEM_GIFT:1||ENV_DDS_ACCESS_ITEM_RESELL:1||ENV_DDS_ACCESS_ITEM_GIVE:1||ENV_DDS_ACCESS_ITEM_TAKEAWAY:1||ENV_DDS_ACCESS_INIT:1||ENV_DDS_ACCESS_WEB_MANAGE:1||ENV_DDS_USE_MONEY:0', '1');

/** NORMAL ADMINISTRATOR CLASS **/
INSERT INTO `ucm_class_list` (`clidx`, `gloname`, `orderidx`, `env`, `status`) VALUES (NULL, 'EN:General Admin||KO:일반 관리자', '3', 'ENV_UCM_ACCESS_CHANGE_CLASS:0||ENV_DDS_ACCESS_MONEY_GIFT:1||ENV_DDS_ACCESS_MONEY_GIVE:1||ENV_DDS_ACCESS_MONEY_TAKEAWAY:1||ENV_DDS_ACCESS_ITEM_GIFT:1||ENV_DDS_ACCESS_ITEM_RESELL:1||ENV_DDS_ACCESS_ITEM_GIVE:1||ENV_DDS_ACCESS_ITEM_TAKEAWAY:1||ENV_DDS_ACCESS_INIT:0||ENV_DDS_ACCESS_WEB_MANAGE:0||ENV_DDS_USE_MONEY:0', '1');

/** Very Important Person CLASS **/
INSERT INTO `ucm_class_list` (`clidx`, `gloname`, `orderidx`, `env`, `status`) VALUES (NULL, 'EN:VIP||KO:VIP', '2', 'ENV_UCM_ACCESS_CHANGE_CLASS:0||ENV_DDS_ACCESS_MONEY_GIFT:1||ENV_DDS_ACCESS_MONEY_GIVE:0||ENV_DDS_ACCESS_MONEY_TAKEAWAY:0||ENV_DDS_ACCESS_ITEM_GIFT:1||ENV_DDS_ACCESS_ITEM_RESELL:1||ENV_DDS_ACCESS_ITEM_GIVE:0||ENV_DDS_ACCESS_ITEM_TAKEAWAY:0||ENV_DDS_ACCESS_INIT:0||ENV_DDS_ACCESS_WEB_MANAGE:0||ENV_DDS_USE_MONEY:0', '1');


/***********************
 * [CodeIgniter]
************************/
CREATE TABLE IF NOT EXISTS  `ucm_sessions` (
	`session_id` VARCHAR(40) NOT NULL DEFAULT '0',
	`ip_address` VARCHAR(16) NOT NULL DEFAULT '0',
	`user_agent` VARCHAR(120) NOT NULL,
	`last_activity` INT(10) UNSIGNED NOT NULL DEFAULT 0,
	`user_data` TEXT NOT NULL,
	PRIMARY KEY (`session_id`),
	KEY `last_activity_idx` (`last_activity`)
);