<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Auth extends CI_Controller {

	function __construct()
	{
		parent::__construct();

		// 기본 언어 설정
		$defLang = 'korean';

		// OpenID 로드
		$hostUrl = array('url' => base_url());
		$this->load->library('LightOpenID', $hostUrl);
		// 세션 로드
		$this->load->library('session');
		// 인증 모델 로드
		$this->load->model('auth_m');

		// 스팀 Web API는 OpenID 2.0을 사용하고 있으므로 라이브러리 로드
		$oid = $this->lightopenid;
		
		// 상황별 구분
		if (!$oid->mode)
		{
			if ($this->input->post('gosign') == '1') {
				// 증명 설정
				$oid->identity = 'http://steamcommunity.com/openid';
				// 인증 페이지로 고고
				header('Location: ' . $oid->authUrl());
			}
		}
		else if ($oid->mode == 'cancel')
		{
			redirect('/auth/login/');
		}
		else
		{
			if ($oid->validate())
			{
				preg_match("/^http:\/\/steamcommunity\.com\/openid\/id\/(7[0-9]{15,25}+)$/", $oid->identity, $stid);

				// 서버에 등록된 유저인지 확인
				$isInProfile = $this->auth_m->VerifyServerPlayer($stid[1]);

				// 세션 등록
				$this->session->set_userdata('auth_id', $stid[1]);
				$this->session->set_userdata('lang', $defLang);
				$this->session->set_userdata('inauth', $isInProfile);
				redirect('/auth/login/');
			}
		}

		// 언어 파일 로드
		$usrLang = $this->session->userdata('lang');

		// 유저 언어에 따른 언어 파일 로드
		$this->lang->load('menu', $usrLang);
		$this->lang->load('global', $usrLang);
	}

	public function index()
	{
		// 기본적으로 기본 화면으로 리다이렉트
		if ($this->session->userdata('auth_id')) {
			// 서버에 등록된 유저가 아니면 다시 세션풀고 back처리
			if (!$this->session->userdata('inauth'))	redirect('/auth/logout/');

			// 정상이면 출입 가능
			redirect('/home/');
		} else {
			redirect('/auth/login/');
		}
	}

	public function login()
	{
		// 로그인되어 있으면 기본 화면으로 리다이렉트
		if ($this->session->userdata('auth_id') && (strcmp($this->session->userdata('inauth'), 'yes') == 0)) {
			redirect('/home/');
		}

		// 등록이 안되어 있을 때
		if (strcmp($this->session->userdata('inauth'), 'no') == 0)
			echo '<script>alert("서버에 등록된 사용자가 아닙니다.");</script>';

		// 로그인 페이지
		$data['setform'] = $this->auth_m->MakeSignin();

		// 언어 로드
		$data['langData'] = $this->lang;

		$this->load->view('page_login', $data);
	}

	public function logout()
	{
		// 세션 제거
		$usrdata = $this->session->all_userdata();
		foreach ($usrdata as $key => $value) {
			if ($key != 'session_id' && $key != 'ip_address' && $key != 'user_agent' && $key != 'last_activity') {
				$this->session->unset_userdata($key);
			}
		}
		redirect('/auth/login/', 'refresh');
	}
}

?>