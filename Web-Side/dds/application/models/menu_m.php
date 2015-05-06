<?php

class Menu_m extends CI_Model {
	
	function __construct()
	{
		parent::__construct();

		// 유저 세션 로드
		$this->load->library('session');
		$usrLang = $this->session->userdata('lang');

		// 유저 언어에 따른 언어-메뉴 파일 로드
		$this->lang->load('menu', $usrLang);
	}

	function GetMenu()
	{
		$langLoad = $this->lang;
		$menuList = array(
			array($langLoad->line('menu_home'), "home", "fa-home", 0),
			array($langLoad->line('menu_myinfo'), "myinfo", "fa-user", 0),
			array($langLoad->line('menu_itembuy'), "buy", "fa-shopping-cart", 0),
			array($langLoad->line('menu_admin'), "admin", "fa-cog", 1),
			array($langLoad->line('menu_logout'), "auth/logout", "fa-user-times", 0)
		);

		return $menuList;
	}

	function CreateMenu($focus, $authid)
	{
		$rval = '';

		// UCM을 통해 관리 권한이 있는지 확인
		$this->db->select('ucm_user_profile.idx, ucm_class_list.env');
		$this->db->join('ucm_class_list', 'ucm_user_profile.clidx = ucm_class_list.clidx', 'left');
		$this->db->where('ucm_user_profile.authid', $authid);
		$q = $this->db->get('ucm_user_profile');
		$qc = $q->result_array();
		$qCount = $q->num_rows();

		// 관리자 ENV 찾기
		$qEnv = ($qCount > 0) ? GetTotalFormatValue($qc[0]['env']) : GetTotalFormatValue('ENV_DDS_ACCESS_WEB_MANAGE:0');
		$qwVal = 0;
		for ($i = 0; $i < count($qEnv); $i++)
		{
			if (strcmp($qEnv[$i]['name'], 'ENV_DDS_ACCESS_WEB_MANAGE') == 0) {
				$qwVal = intval($qEnv[$i]['value']);
				break;
			}
		}

		for ($i = 0; $i < count($this->GetMenu()); $i++) {
			// 관리자용 처리
			if (($this->GetMenu()[$i][3] > $qwVal) && ($this->GetMenu()[$i][3] == 1))	continue;

			// 클래스 처리
			$classSet = '';

			// 현재 있는 페이지 포커스
			if (strcmp($this->GetMenu()[$i][0], $focus) == 0) {
				$classSet .= 'active';
			}

			// 적용
			if ($classSet) {
				$rval .= '<li class="' . $classSet . '">';
			} else {
				$rval .= '<li>';
			}
			$rval .= '<a href="' . base_url() . $this->GetMenu()[$i][1] . '"><i class="fa ' . $this->GetMenu()[$i][2] . ' fa-fw"></i>&nbsp; ' . $this->GetMenu()[$i][0] . '</a></li>';
		}

		return $rval;
	}

	function GetIcon($focus)
	{
		$rval = '';
		for ($i = 0; $i < count($this->GetMenu()); $i++) {
			// 구하고자 하는 페이지가 아니면 패스
			if (strcmp($this->GetMenu()[$i][0], $focus) != 0)	continue;

			// 추출
			$rval = $this->GetMenu()[$i][2];
		}
		return $rval;
	}
}

?>