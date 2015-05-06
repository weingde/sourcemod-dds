<?php

class Envlist extends CI_Controller {

	function __construct()
	{
		parent::__construct();

		// 설치가 되지 않은 경우 설치 페이지로 이동
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
	}

	public function index()
	{
		$this->load->view('_top');
		$this->load->view('page_envlist');
		$this->load->view('_foot');
	}
}

?>