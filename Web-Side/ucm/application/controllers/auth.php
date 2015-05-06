<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Auth extends CI_Controller {

	function __construct()
	{
		parent::__construct();

		// 세션 로드
		$this->load->library('session');
		// 인증 모델 로드
		$this->load->model('auth_m');

		// 로그인 후 처리
		$sign = $this->input->post('gosign', TRUE);
		if (intval($sign) == 1)
		{
			if (!empty($this->input->post('idf', TRUE)) && !empty($this->input->post('passf', TRUE)))
			{
				$qset = "SELECT * FROM `ucm_user_profile` WHERE `authid` = '" . $this->input->post('idf', TRUE) . "' AND `passkey` = PASSWORD('" . $this->input->post('passf', TRUE) . "');";
				$qaR = $this->db->query($qset);
				$isok = $qaR->num_rows();

				if ($isok > 0)
				{
					$this->session->set_userdata('auth_id', $this->input->post('idf', TRUE));
					$this->session->set_userdata('inauth', 'yes');
				}
				else
				{
					$this->session->set_userdata('inauth', 'no');
				}
			}
		}
	}

	public function index()
	{
		// 기본적으로 기본 화면으로 리다이렉트
		if ($this->session->userdata('auth_id')) {
			// 서버에 등록된 유저가 아니면 다시 세션풀고 back처리
			if (!$this->session->userdata('inauth'))	redirect('/auth/logout/');

			// 정상이면 출입 가능
			redirect('/usrlist/');
		} else {
			redirect('/auth/login/');
		}
	}

	public function login()
	{
		// 로그인되어 있으면 기본 화면으로 리다이렉트
		if ($this->session->userdata('auth_id') && (strcmp($this->session->userdata('inauth'), 'yes') == 0)) {
			redirect('/usrlist/');
		}

		$sign = $this->input->post('gosign', TRUE);
		if (intval($sign) == 1)
		{
			if (empty($this->input->post('idf', TRUE)))
				echo '<script>alert("고유번호를 입력해주세요.");</script>';
			else if (empty($this->input->post('passf', TRUE)))
				echo '<script>alert("비밀번호를 입력해주세요.");</script>';
		}

		// 등록이 안되어 있을 때
		if (strcmp($this->session->userdata('inauth'), 'no') == 0)
			echo '<script>alert("서버에 등록된 사용자가 아니거나 비밀번호가 틀렸습니다.");</script>';

		// 로그인 페이지
		$data['setform'] = $this->auth_m->MakeSignin();

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