<?php

class List_m extends CI_Model {
	
	function __construct()
	{
		parent::__construct();
	}

	function GetList($type, $limitc, $limitidx, $authid, $numcheck = false)
	{
		if (strcmp($type, 'inven') == 0)
		{
			/*********************************************
			 * [내 정보 - 인벤토리 목록]
			 * 후에 총 6개 필드
			**********************************************/
			/*
			SELECT dds_user_item.idx, dds_item_list.icidx, dds_item_category.gloname AS icname, dds_item_list.gloname AS ilname, dds_user_item.buydate, dds_user_item.aplied
			FROM `dds_user_item` 
			LEFT JOIN `dds_item_list` ON `dds_user_item`.`ilidx` = `dds_item_list`.`ilidx` 
			LEFT JOIN `dds_item_category` ON `dds_item_category`.`icidx` = `dds_item_list`.`icidx` 
			WHERE `dds_item_category`.`status` = '1' 
			ORDER BY `dds_user_item`.`ilidx` ASC;
			*/
			$this->db->select('dds_user_item.idx, dds_item_list.icidx, dds_item_category.gloname AS icname, dds_item_list.gloname AS ilname, dds_user_item.buydate, dds_user_item.aplied');
			$this->db->join('dds_item_list', 'dds_user_item.ilidx = dds_item_list.ilidx', 'left');
			$this->db->join('dds_item_category', 'dds_item_category.icidx = dds_item_list.icidx', 'left');
			$this->db->where(array('dds_item_category.status' => '1', 'dds_user_item.authid' => $authid));
			$this->db->order_by('dds_user_item.idx', 'ASC');
			// Limit 거꾸로임 ㄱ-
			if (!$numcheck)	$this->db->limit($limitidx, $limitc);
			$q = $this->db->get('dds_user_item');

			// 갯수 파악 또는 결과
			if ($numcheck)
				return $q->num_rows();
			else
				return $q->result_array();
		}
		else if (strcmp($type, 'buy') == 0)
		{
			/*********************************************
			 * [아이템 구입 - 목록]
			 * 후에 총 6개 필드
			**********************************************/
			/*
			SELECT dds_item_category.gloname AS icname, dds_item_list.ilidx, dds_item_list.gloname AS itname, dds_item_list.money, dds_item_list.havtime 
			FROM `dds_item_category` 
			LEFT JOIN `dds_item_list` ON `dds_item_category`.`icidx` = `dds_item_list`.`icidx` 
			WHERE `dds_item_list`.`status` = '1' AND `dds_item_category`.`status` = '1' 
			ORDER BY `dds_item_list`.`ilidx` ASC;
			*/
			$this->db->select('dds_item_category.gloname AS icname, dds_item_list.ilidx, dds_item_list.gloname AS itname, dds_item_list.money, dds_item_list.havtime');
			$this->db->join('dds_item_list', 'dds_item_category.icidx = dds_item_list.icidx', 'left');
			$this->db->where(array('dds_item_list.status' => '1', 'dds_item_category.status' => '1'));
			$this->db->order_by('dds_item_list.ilidx', 'ASC');
			// Limit 거꾸로임 ㄱ-
			if (!$numcheck)	$this->db->limit($limitidx, $limitc);
			$q = $this->db->get('dds_item_category');

			// 갯수 파악 또는 결과
			if ($numcheck)
				return $q->num_rows();
			else
				return $q->result_array();
		}
		else if (strcmp($type, 'usrlist') == 0)
		{
			/*********************************************
			 * [유저 관리 - 목록]
			 * 후에 총 5개 필드
			**********************************************/
			/*
			SELECT * 
			FROM `dds_user_profile` 
			ORDER BY `idx` DESC;
			*/
			$this->db->order_by('idx', 'DESC');
			// Limit 거꾸로임 ㄱ-
			if (!$numcheck)	$this->db->limit($limitidx, $limitc);
			$q = $this->db->get('dds_user_profile');

			// 갯수 파악 또는 결과
			if ($numcheck)
				return $q->num_rows();
			else
				return $q->result_array();
		}
		else if (strcmp($type, 'itemlist') == 0)
		{
			/*********************************************
			 * [아이템 관리 - 목록]
			 * 후에 총 7개 필드
			**********************************************/
			$this->db->select('dds_item_list.ilidx, dds_item_list.icidx, dds_item_category.gloname AS icname, dds_item_list.gloname AS itname, dds_item_list.money, dds_item_list.havtime, dds_item_list.env, dds_item_list.status');
			$this->db->join('dds_item_category', 'dds_item_category.icidx = dds_item_list.icidx', 'left');
			$this->db->order_by('ilidx', 'DESC');
			// Limit 거꾸로임 ㄱ-
			if (!$numcheck)	$this->db->limit($limitidx, $limitc);
			$q = $this->db->get('dds_item_list');

			// 갯수 파악 또는 결과
			if ($numcheck)
				return $q->num_rows();
			else
				return $q->result_array();
		}
		else if (strcmp($type, 'itemcglist') == 0)
		{
			/*********************************************
			 * [아이템 종류 관리 - 목록]
			 * 후에 총 5개 필드
			**********************************************/
			/*
			SELECT * 
			FROM `dds_item_category` 
			ORDER BY `icidx` DESC;
			*/
			$this->db->order_by('icidx', 'DESC');
			// Limit 거꾸로임 ㄱ-
			if (!$numcheck)	$this->db->limit($limitidx, $limitc);
			$q = $this->db->get('dds_item_category');

			// 갯수 파악 또는 결과
			if ($numcheck)
				return $q->num_rows();
			else
				return $q->result_array();
		}
		else if (strcmp($type, 'envlist') == 0)
		{
			/*********************************************
			 * [ENV 관리 - 목록]
			 * 후에 총 5개 필드
			**********************************************/
			/*
			SELECT * 
			FROM `dds_env_list` 
			ORDER BY `idx` DESC;
			*/
			$this->db->order_by('idx', 'DESC');
			// Limit 거꾸로임 ㄱ-
			if (!$numcheck)	$this->db->limit($limitidx, $limitc);
			$q = $this->db->get('dds_env_list');

			// 갯수 파악 또는 결과
			if ($numcheck)
				return $q->num_rows();
			else
				return $q->result_array();
		}
		else if (strcmp($type, 'dataloglist') == 0)
		{
			/*********************************************
			 * [데이터 로그 관리 - 목록]
			 * 후에 총 6개 필드
			**********************************************/
			/*
			SELECT * 
			FROM `dds_log_data` 
			ORDER BY `idx` DESC;
			*/
			$this->db->order_by('idx', 'DESC');
			// Limit 거꾸로임 ㄱ-
			if (!$numcheck)	$this->db->limit($limitidx, $limitc);
			$q = $this->db->get('dds_log_data');

			// 갯수 파악 또는 결과
			if ($numcheck)
				return $q->num_rows();
			else
				return $q->result_array();
		}
	}

	function SetDetInfo($type, $data)
	{
		if (strcmp($type, 'additem') == 0)
		{
			$il_code = $data[0];
			$il_name = $data[1];
			$il_money = $data[2];
			$il_havtime = $data[3];
			$il_env = $data[4];
			$il_status = $data[5];

			if (strlen($il_code) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writecgcode'));
			}
			if (!is_numeric($il_code)) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writecgcode_num'));
			}
			if (intval($il_code) == 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_nozero'));
			}
			if (strlen($il_name) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writename'));
			}
			if (strlen($il_money) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writemoney'));
			}
			if (!is_numeric($il_money)) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writemoney_num'));
			}
			if (strlen($il_havtime) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writehavtime'));
			}
			if (!is_numeric($il_havtime)) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writehavtime_num'));
			}
			if (strlen($il_env) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writeenv'));
			}

			$setdata = array(
				'dds_item_list.gloname' => $il_name,
				'dds_item_list.icidx' => $il_code,
				'dds_item_list.money' => $il_money,
				'dds_item_list.havtime' => $il_havtime,
				'dds_item_list.env' => $il_env,
				'dds_item_list.status' => $il_status
			);
			$this->db->set($setdata);
			$this->db->insert('dds_item_list');
		}
		else if (strcmp($type, 'additemcg') == 0)
		{
			$ic_name = $data[0];
			$ic_orderidx = $data[1];
			$ic_env = $data[2];
			$ic_status = $data[3];

			// 우선순위 겹치는지 확인
			$setwhere = array(
				'dds_item_category.orderidx' => $ic_orderidx,
				'dds_item_category.status' => '1'
			);
			$this->db->where($setwhere);
			$chk = $this->db->get('dds_item_category');
			$chkC = $chk->num_rows();

			if (strlen($ic_name) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writename'));
			}
			if (strlen($ic_orderidx) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writeorderidx'));
			}
			if (!is_numeric($ic_orderidx)) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writeorderidx_num'));
			}
			if ($chkC >= 1) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writeorderidx_dup'));
			}
			if (strlen($ic_env) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writeenv'));
			}

			$setdata = array(
				'dds_item_category.gloname' => $ic_name,
				'dds_item_category.orderidx' => $ic_orderidx,
				'dds_item_category.env' => $ic_env,
				'dds_item_category.status' => $ic_status
			);
			$this->db->set($setdata);
			$this->db->insert('dds_item_category');
		}
		else if (strcmp($type, 'addenv') == 0)
		{
			$env_onecate = $data[0];
			$env_twocate = $data[1];
			$env_setdata = $data[2];
			$env_desc = $data[3];

			// 이름 겹치는지 확인
			$setwhere = array(
				'dds_env_list.twocate' => $env_twocate
			);
			$this->db->where($setwhere);
			$chk = $this->db->get('dds_env_list');
			$chkC = $chk->num_rows();
			$chkQ = $chk->result_array();

			if (strlen($env_onecate) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writeenv_category'));
			}
			if (strlen($env_twocate) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writeenv_name'));
			}
			if (($chkC >= 1 ) && (strcmp($chkQ[0]['twocate'], $env_twocate) != 0)) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writeenv_name_dup'));
			}

			$setdata = array(
				'dds_env_list.onecate' => $env_onecate,
				'dds_env_list.twocate' => $env_twocate,
				'dds_env_list.setdata' => $env_setdata,
				'dds_env_list.desc' => $env_desc
			);
			$this->db->set($setdata);
			$this->db->insert('dds_env_list');
		}
		else if (strcmp($type, 'modifyitem') == 0)
		{
			$il_code = $data[0];
			$il_name = $data[1];
			$il_money = $data[2];
			$il_havtime = $data[3];
			$il_env = $data[4];
			$il_status = $data[5];
			$il_hidden = $data[6];

			if (strlen($il_code) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writecgcode'));
			}
			if (!is_numeric($il_code)) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writecgcode_num'));
			}
			if (intval($il_code) == 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_nozero'));
			}
			if (strlen($il_name) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writename'));
			}
			if (strlen($il_money) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writemoney'));
			}
			if (!is_numeric($il_money)) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writemoney_num'));
			}
			if (strlen($il_havtime) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writehavtime'));
			}
			if (!is_numeric($il_havtime)) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writehavtime_num'));
			}
			if (strlen($il_env) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writeenv'));
			}

			$setdata = array(
				'dds_item_list.gloname' => $il_name,
				'dds_item_list.icidx' => $il_code,
				'dds_item_list.money' => $il_money,
				'dds_item_list.havtime' => $il_havtime,
				'dds_item_list.env' => $il_env,
				'dds_item_list.status' => $il_status
			);
			$this->db->set($setdata);
			$this->db->where('dds_item_list.ilidx', $il_hidden);
			$this->db->update('dds_item_list');
		}
		else if (strcmp($type, 'modifyitemcg') == 0)
		{
			$ic_name = $data[0];
			$ic_orderidx = $data[1];
			$ic_env = $data[2];
			$ic_status = $data[3];
			$ic_hidden = $data[4];

			// 우선순위 겹치는지 확인
			$setwhere = array(
				'dds_item_category.orderidx' => $ic_orderidx,
				'dds_item_category.status' => '1'
			);
			$this->db->where($setwhere);
			$chk = $this->db->get('dds_item_category');
			$chkC = $chk->num_rows();
			$chkQ = $chk->result_array();

			if (strlen($ic_name) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writename'));
			}
			if (strlen($ic_orderidx) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writeorderidx'));
			}
			if (!is_numeric($ic_orderidx)) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writeorderidx_num'));
			}
			if (($chkC >= 1 ) && $chkQ[0]['orderidx'] != $ic_orderidx) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writeorderidx_dup'));
			}
			if (strlen($ic_env) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writeenv'));
			}

			$setdata = array(
				'dds_item_category.gloname' => $ic_name,
				'dds_item_category.orderidx' => $ic_orderidx,
				'dds_item_category.env' => $ic_env,
				'dds_item_category.status' => $ic_status
			);
			$this->db->set($setdata);
			$this->db->where('dds_item_category.icidx', $ic_hidden);
			$this->db->update('dds_item_category');
		}
		else if (strcmp($type, 'modifyenv') == 0)
		{
			$env_onecate = $data[0];
			$env_twocate = $data[1];
			$env_setdata = $data[2];
			$env_desc = $data[3];
			$env_hidden = $data[4];

			// 이름 겹치는지 확인
			$setwhere = array(
				'dds_env_list.twocate' => $env_twocate
			);
			$this->db->where($setwhere);
			$chk = $this->db->get('dds_env_list');
			$chkC = $chk->num_rows();
			$chkQ = $chk->result_array();

			if (strlen($env_onecate) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writeenv_category'));
			}
			if (strlen($env_twocate) <= 0) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writeenv_name'));
			}
			if (($chkC >= 1 ) && (strcmp($chkQ[0]['twocate'], $env_twocate) != 0)) {
				return json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_writeenv_name_dup'));
			}

			$setdata = array(
				'dds_env_list.onecate' => $env_onecate,
				'dds_env_list.twocate' => $env_twocate,
				'dds_env_list.setdata' => $env_setdata,
				'dds_env_list.desc' => $env_desc
			);
			$this->db->set($setdata);
			$this->db->where('dds_env_list.idx', $env_hidden);
			$this->db->update('dds_env_list');
		}

		return json_encode(array('result' => true, 'title' => 'msg_title_notice', 'msg' => 'msg_results_success'));
	}

	function GetProfile($authid)
	{
		// 유저 프로필 로드
		$this->db->where('dds_user_profile.authid', $authid);
		$q = $this->db->get('dds_user_profile');
		
		return $q->result_array();
	}
}

?>