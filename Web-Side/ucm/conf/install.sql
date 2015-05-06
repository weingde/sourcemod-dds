/*********************************************************
 * Author By. Eakgnarok
 *********************************************************/
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

/** NORMAL USER **/
INSERT INTO `ucm_class_list` (`clidx`, `gloname`, `orderidx`, `env`, `status`) VALUES (NULL, 'EN:Normal||KO:일반', '1', 'ENV_UCM_ACCESS_CHANGE_CLASS:0', '1');

/** ADMINISTRATOR **/
INSERT INTO `ucm_class_list` (`clidx`, `gloname`, `orderidx`, `env`, `status`) VALUES (NULL, 'EN:Super Admin||KO:최고 관리자', '2', 'ENV_UCM_ACCESS_CHANGE_CLASS:1', '1');


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