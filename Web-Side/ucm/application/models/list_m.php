<?php

class List_m extends CI_Model {
	
	function __construct()
	{
		parent::__construct();
	}

	function GetList($type, $limitc, $limitidx, $numcheck = false)
	{
		if (strcmp($type, 'usrlist') == 0)
		{
			/*********************************************
			 * [유저 관리 - 목록]
			 * 후에 총 9개 필드
			**********************************************/
			/*
			SELECT * 
			FROM `ucm_user_profile` 
			ORDER BY `idx` DESC;
			*/
			$this->db->order_by('idx', 'DESC');
			// Limit 거꾸로임 ㄱ-
			if (!$numcheck)	$this->db->limit($limitidx, $limitc);
			$q = $this->db->get('ucm_user_profile');

			// 갯수 파악 또는 결과
			if ($numcheck)
				return $q->num_rows();
			else
				return $q->result_array();
		}
		else if (strcmp($type, 'classlist') == 0)
		{
			/*********************************************
			 * [등급 관리 - 목록]
			 * 후에 총 5개 필드
			**********************************************/
			/*
			SELECT * 
			FROM `ucm_class_list` 
			ORDER BY `clidx` DESC;
			*/
			$this->db->order_by('clidx', 'DESC');
			// Limit 거꾸로임 ㄱ-
			if (!$numcheck)	$this->db->limit($limitidx, $limitc);
			$q = $this->db->get('ucm_class_list');

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
			 * 후에 총 개 필드
			**********************************************/
			/*
			SELECT * 
			FROM `ucm_env_list` 
			ORDER BY `idx` DESC;
			*/
			$this->db->order_by('idx', 'DESC');
			// Limit 거꾸로임 ㄱ-
			if (!$numcheck)	$this->db->limit($limitidx, $limitc);
			$q = $this->db->get('ucm_env_list');

			// 갯수 파악 또는 결과
			if ($numcheck)
				return $q->num_rows();
			else
				return $q->result_array();
		}
	}

	function SetDetInfo($type, $data)
	{
		if (strcmp($type, 'addclass') == 0)
		{
			$cl_name = $data[0];
			$cl_orderidx = $data[1];
			$cl_env = $data[2];
			$cl_status = $data[3];

			// 우선순위 겹치는지 확인
			$setwhere = array(
				'ucm_class_list.orderidx' => $cl_orderidx,
				'ucm_class_list.status' => '1'
			);
			$this->db->where($setwhere);
			$chk = $this->db->get('ucm_class_list');
			$chkC = $chk->num_rows();

			if (strlen($cl_name) <= 0) {
				return '등급 이름을 적어주세요.';
			}
			if (strlen($cl_orderidx) <= 0) {
				return '우선순위를 적어주세요.';
			}
			if (!is_numeric($cl_orderidx)) {
				return '우선순위는 숫자이어야 합니다.';
			}
			if ($chkC >= 1) {
				return '활성화된 등급과 중복되는 우선순위가 있으면 안됩니다.';
			}
			if (strlen($cl_env) <= 0) {
				return 'ENV를 적어주세요.';
			}

			$setdata = array(
				'ucm_class_list.gloname' => $cl_name,
				'ucm_class_list.orderidx' => $cl_orderidx,
				'ucm_class_list.env' => $cl_env,
				'ucm_class_list.status' => $cl_status
			);
			$this->db->set($setdata);
			$this->db->insert('ucm_class_list');
		}
		else if (strcmp($type, 'addenv') == 0)
		{
			$env_onecate = $data[0];
			$env_twocate = $data[1];
			$env_setdata = $data[2];
			$env_desc = $data[3];

			// 이름 겹치는지 확인
			$setwhere = array(
				'ucm_env_list.twocate' => $env_twocate
			);
			$this->db->where($setwhere);
			$chk = $this->db->get('ucm_env_list');
			$chkC = $chk->num_rows();
			$chkQ = $chk->result_array();

			if (strlen($env_onecate) <= 0) {
				return 'ENV 종류를 적어주세요.';
			}
			if (strlen($env_twocate) <= 0) {
				return 'ENV 이름을 적어주세요.';
			}
			if (strlen($env_setdata) <= 0) {
				return 'ENV 값을 적어주세요.';
			}
			if (($chkC >= 1 ) && (strcmp($chkQ[0]['twocate'], $env_twocate) != 0)) {
				return '등록된 ENV 항목 중에 중복되는 이름이 있습니다. 이름을 바꾸어주세요.';
			}

			$setdata = array(
				'ucm_env_list.onecate' => $env_onecate,
				'ucm_env_list.twocate' => $env_twocate,
				'ucm_env_list.setdata' => $env_setdata,
				'ucm_env_list.desc' => $env_desc
			);
			$this->db->set($setdata);
			$this->db->insert('ucm_env_list');
		}
		else if (strcmp($type, 'modifyclass') == 0)
		{
			$cl_name = $data[0];
			$cl_orderidx = $data[1];
			$cl_env = $data[2];
			$cl_status = $data[3];
			$cl_hidden = $data[4];

			// 우선순위 겹치는지 확인
			$setwhere = array(
				'ucm_class_list.orderidx' => $cl_orderidx,
				'ucm_class_list.status' => '1'
			);
			$this->db->where($setwhere);
			$chk = $this->db->get('ucm_class_list');
			$chkC = $chk->num_rows();

			if (strlen($cl_name) <= 0) {
				return '등급 이름을 적어주세요.';
			}
			if (strlen($cl_orderidx) <= 0) {
				return '우선순위를 적어주세요.';
			}
			if (!is_numeric($cl_orderidx)) {
				return '우선순위는 숫자이어야 합니다.';
			}
			if ($chkC >= 1) {
				return '활성화된 등급과 중복되는 우선순위가 있으면 안됩니다.';
			}
			if (strlen($cl_env) <= 0) {
				return 'ENV를 적어주세요.';
			}

			$setdata = array(
				'ucm_class_list.gloname' => $cl_name,
				'ucm_class_list.orderidx' => $cl_orderidx,
				'ucm_class_list.env' => $cl_env,
				'ucm_class_list.status' => $cl_status
			);
			$this->db->where('ucm_class_list.clidx', $cl_hidden);
			$this->db->update('ucm_class_list');
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
				'ucm_env_list.twocate' => $env_twocate
			);
			$this->db->where($setwhere);
			$chk = $this->db->get('ucm_env_list');
			$chkC = $chk->num_rows();
			$chkQ = $chk->result_array();

			if (strlen($env_onecate) <= 0) {
				return 'ENV 종류를 적어주세요.';
			}
			if (strlen($env_twocate) <= 0) {
				return 'ENV 이름을 적어주세요.';
			}
			if (strlen($env_setdata) <= 0) {
				return 'ENV 값을 적어주세요.';
			}
			if (($chkC >= 1 ) && (strcmp($chkQ[0]['twocate'], $env_twocate) != 0)) {
				return '등록된 ENV 항목 중에 중복되는 이름이 있습니다. 이름을 바꾸어주세요.';
			}

			$setdata = array(
				'ucm_env_list.onecate' => $env_onecate,
				'ucm_env_list.twocate' => $env_twocate,
				'ucm_env_list.setdata' => $env_setdata,
				'ucm_env_list.desc' => $env_desc
			);
			$this->db->where('ucm_env_list.idx', $env_hidden);
			$this->db->update('ucm_env_list');
		}

		return '성공적으로 완료되었습니다.';
	}
}

?>