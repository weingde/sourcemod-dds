<?php

class Auth_m extends CI_Model {
	
	function __construct()
	{
		parent::__construct();
	}

	function MakeSignin()
	{
		$rval = form_open('auth/login', '', array('gosign' => '1'));
		$rval .= '<p class="center">';
		$rval .= form_input(array('type' => 'image', 'src' => images_url() . 'login.png', 'maxlength' => '0', 'style' => 'width: 114px; height: 43px; text-align: center;'));
		$rval .= '</p>';
		$rval .= form_close();

		return $rval;
	}

	function LoadPlayerProfile($authid)
	{
		// 파일 헬퍼 로드
		$this->load->helper('file');

		// API KEY 로드
		$key = read_file(CONFIG_PATH . '/config.php');

		$lnk = file_get_contents('http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=' . $key . '&steamids=' . $authid . '&format=json');
		$rval = json_decode($lnk, true);

		return $rval['response']['players'][0];
	}

	function VerifyServerPlayer($authid)
	{
		$this->db->select('dds_user_profile.idx, dds_user_profile.authid, dds_user_profile.nickname');
		$this->db->where('dds_user_profile.authid', $authid);
		$q = $this->db->get('dds_user_profile');
		return ($q->num_rows() > 0) ? 'yes' : 'no';
	}
}

?>