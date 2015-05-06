<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Lang extends CI_Controller {

	function __construct()
	{
		parent::__construct();

		// 설치가 되지 않은 경우 설치 페이지로 이동
		$this->load->helper('url');
		if (!file_exists(CONFIG_PATH . '/config.php'))
		{
			redirect('/install/');
		}

		// 에이전트 로드
		$this->load->library('user_agent');

		// 세션 로드
		$this->load->library('session');
	}

	public function switchlang($langcode = '')
	{
		// 기본 언어는 영어
		$langcode = ($langcode != '') ? $langcode : 'english';

		// 언어 할당
		$this->session->set_userdata('lang', $langcode);

		// 다시 이동
		redirect($this->agent->referrer());
	}

	public function index()
	{
		echo 'Why do you enter here? :)';
	}
}