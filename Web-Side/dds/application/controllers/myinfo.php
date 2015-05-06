<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Myinfo extends CI_Controller {

	function __construct()
	{
		parent::__construct();

		// 설치가 되지 않은 경우 설치 페이지로 이동
		$this->load->helper('url');
		if (!file_exists(CONFIG_PATH . '/config.php'))
		{
			redirect('/install/');
		}

		// 로그인 여부
		$this->load->library('session');
		$cSess = $this->session;
		
		if (!$cSess->userdata('auth_id') || !$cSess->userdata('inauth')) {
			redirect('/auth/login/');
		}

		// 언어 파일 로드
		$usrLang = $this->session->userdata('lang');

		// 유저 언어에 따른 언어 파일 로드
		$this->lang->load('menu', $usrLang);
		$this->lang->load('global', $usrLang);

		// 메뉴 모델 로드
		$this->load->model('menu_m');

		// 인증 모델 로드
		$this->load->model('auth_m');
	}

	public function index()
	{
		/********************************************
		 * 기본 정보
		*********************************************/
		// 기본
		$User_AuthId = $this->session->userdata('auth_id');

		// 상단
		$tdata['title'] = $this->lang->line('menu_myinfo');
		$tdata['menuset'] = $this->menu_m->CreateMenu($tdata['title'], $User_AuthId);
		$tdata['usr_authid'] = $User_AuthId;

		// 내용
		$pdata['icon'] = $this->menu_m->GetIcon($tdata['title']);
		$pdata['title'] = $tdata['title'];
		$pdata['langData'] = $this->lang;

		// 프로필 정보 로드
		// https://developer.valvesoftware.com/wiki/Steam_Web_API#GetPlayerSummaries_.28v0002.29
		// ajax로 하고 싶지만 Access-Control-Allow-Origin 문제 때문에 그냥 서버에서 ㄱ-;
		$proinfo = $this->auth_m->LoadPlayerProfile($this->session->userdata('auth_id'));
		
		$pdata['authid'] = $proinfo['steamid'];
		$pdata['name'] = $proinfo['personaname'];
		$pdata['logstatus'] = $proinfo['personastate'];
		$pdata['profileimg'] = $proinfo['avatarfull'];
		$pdata['profileurl'] = $proinfo['profileurl'];
		$pdata['lastlogoff'] = date("Y-m-d H:i:s", $proinfo['lastlogoff']);

		/********************************************
		 * 출력
		*********************************************/
		$this->load->view('_top', $tdata);
		$this->load->view('page_myinfo', $pdata);
		$this->load->view('_foot');
	}
}

?>