<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Msg extends CI_Controller {

	function __construct()
	{
		parent::__construct();

		// 설치가 되지 않은 경우 설치 페이지로 이동
		$this->load->helper('url');
		if (!file_exists(CONFIG_PATH . '/config.php'))
		{
			redirect('/install/');
		}

		// 세션 로드
		$this->load->library('session');
		$cSess = $this->session;
		
		// 로그인 여부
		if (!$cSess->userdata('auth_id') || !$cSess->userdata('inauth')) {
			redirect('/auth/login/');
		}

		// 언어 파일 로드
		$usrLang = $this->session->userdata('lang');

		// 유저 언어에 따른 언어 파일 로드
		$this->lang->load('global', $usrLang);
	}

	public function loadPromptMsg()
	{
		// POST 로드
		$title = $this->input->post('title', TRUE);
		$msg = $this->input->post('msg', TRUE);

		echo json_encode(array(
			'title' => $this->lang->line($title), 
			'msg' => $this->lang->line($msg)
		));
	}

	public function loadTransMsg()
	{
		// POST 로드
		$msg = $this->input->post('msg', TRUE);

		echo $this->lang->line($msg);
	}

	public function index()
	{
		echo 'Why do you enter here? :)';
	}
}