<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Install extends CI_Controller {

	function __construct()
	{
		parent::__construct();

		// 파일 모델 로드
		$this->load->helper('file');

		// 이미 설치가 되어 있다면 기본 페이지로 이동
		if (file_exists(CONFIG_PATH . '/config.php'))
		{
			redirect('/usrlist/');
		}
	}

	public function index()
	{
		// 단계 초기화
		$stepIdx = 1;

		// 넘겨진 항목 설정
		if ($this->input->post('step', TRUE)) {
			$stepIdx = $this->input->post('step', TRUE);
		};

		// 항목 선정
		$stepList = array(
			array(1, '라이센스 확인'),
			array(2, '퍼미션 및 환경 확인'),
			array(3, '설치 준비'),
			array(4, '설치'),
			array(5, '완료'),
			array(6, '홈 이동')
		);

		// 정보 할당
		$data['step'] = 'Step ' . $stepList[$stepIdx - 1][0];
		$data['stepdesc'] = $stepList[$stepIdx - 1][1];
		$data['insdesc'] = '';

		// 설치 구성
		$rval = '';
		switch ($stepIdx)
		{
			case 1:
			{
				$attr = array('step' => '2');
				$rval .= form_open('install', '', $attr);
				$rval .= '<p>\'' . PRODUCT_NAME . '\'을 설치할 것입니다. 아래의 GPL v3 라이센스를 읽어주십시오.</p>';
				$rval .= '<textarea readonly>';
				$rval .= read_file('./gpl-3.0-ko.txt');
				$rval .= '</textarea>';
				$rval .= '<div class="buttongrp">';
				$rval .= form_button(array('name' => 'submit', 'type' => 'submit', 'content' => '<i class="fa fa-chevron-right"></i>'));
				$rval .= '</div>';
				$rval .= form_close();
				break;
			}
			case 2:
			{
				$attr = array('step' => '3');
				$rval .= form_open('install', '', $attr);
				$rval .= '<p>설치를 진행하기 위해서는 다음 두 가지 사항이 먼저 마련되어야 합니다.</p>';
				$rval .= '<p> - \'conf\' 폴더의 권한이 <strong>707</strong> 또는 <strong>777</strong> 이어야 합니다.</p>';
				$rval .= '<p><ul><li>\'conf\' 폴더: ';

				// 폴더 권한 확인
				$totalChk = FALSE;
				$dirChk = octal_permissions(fileperms('./conf'));
				if ($dirChk == "707" || $dirChk == "777") {
					$rval .= '<strong class="green">' . $dirChk . '</strong> (' . symbolic_permissions(fileperms('./conf')) . ')';
					$rval .= '</li>';
					$totalChk = TRUE;
				} else {
					$rval .= '<strong class="red">' . $dirChk . '</strong> (' . symbolic_permissions(fileperms('./conf')) . ')';
					$rval .= '</li>';
					$totalChk = FALSE;
				}

				$rval .= '</ul></p>';
				
				if ($totalChk) {
					$rval .= '<div class="buttongrp">';
					$rval .= form_button(array('name' => 'submit', 'type' => 'submit', 'content' => '<i class="fa fa-chevron-right"></i>'));
					$rval .= '</div>';
				} else {
					$rval .= '<div class="buttongrp">';
					$rval .= form_button(array('name' => 'nosubmit', 'type' => 'button', 'content' => '<i class="fa fa-chevron-right"></i>'));
					$rval .= '</div>';
				}
				$rval .= form_close();
				
				break;
			}
			case 3:
			{
				$attr = array('step' => '4');
				$rval .= form_open('install', '', $attr);
				$rval .= '<p>현 단계에서는 설정된 데이터베이스에 앞으로 \'' . PRODUCT_NAME . '\'을 이용하기 위해 필요한 데이터 구조를 설치하고 초기 접근에 있어 관리자 정보를 추가하게 됩니다.</p>';
				$rval .= '<p>여기서 설치되는 데이터 구조 및 관리자 정보는 앞으로 게임 서버 및 웹 패널에서 \'' . PRODUCT_NAME . '\'을 이용하는데 있어 반드시 필요한 절차입니다.</p>';
				$rval .= '<p>아래에 있는 고유번호 입력 폼은 웹 패널을 관리할 최고 관리자로서 활동하게 될 스팀 아이디의 고유번호와 사용할 비밀번호를 입력해주세요.</p>';
				$rval .= '<p>등록할 고유번호를 모르겠다면 <a href="http://steamidconverter.com/" target="_blank">여기</a>를 클릭하고 고유번호를 찾으세요. \'' . PRODUCT_NAME . '\'에서는 고유번호를 steamID64를 사용합니다.</p>';
				$rval .= '<p><img src="' . base_url() . 'images/install_auth.png" width="564px" height="329px" /></p>';
				$rval .= '<p>비밀번호는 6자리 이상으로 작성해주세요.</p>';
				$rval .= '<p><label for="authidkey">고유번호 입력</label>' . form_input(array('id' => 'authidkey', 'name' => 'authidkey', 'maxlength' => '20', 'title' => '고유번호를 입력해주세요.')) . '</p>';
				$rval .= '<p><label for="passkey">비밀번호 입력</label>' . form_input(array('id' => 'passkey', 'name' => 'passkey', 'type' => 'password', 'maxlength' => '30', 'title' => '비밀번호를 입력해주세요.')) . '</p>';
				$rval .= '<div class="buttongrp">';
				$rval .= form_button(array('id' => 'authsubmit', 'name' => 'nosubmit', 'type' => 'button', 'content' => '<i class="fa fa-chevron-right"></i>'));
				$rval .= '</div>';
				$rval .= form_close();
				break;
			}
			case 4:
			{
				$attr = array('step' => '5');
				$rval .= form_open('install', '', $attr);

				// 데이터베이스 설치
				$rval .= '<p>데이터베이스 설치: ';

				$totalChk = FALSE;
				$sqlPath = read_file(CONFIG_PATH . '/install.sql');
				if (!$sqlPath) {
					$rval .= '<strong class="red">SQL 파일이 없습니다.</strong></p>';
				} else {
					// 식별자 ';'' 기준으로 분리
					$sqls = explode(';', $sqlPath);
					// 쓸모없는 것은 제거
					array_pop($sqls);
					// 쿼리 한 줄마다 실행
					$qRst;
					foreach ($sqls as $q) {
						$q = $q . ';';
						$qRst = $this->db->query($q);
					}

					if (!$qRst) {
						$totalChk = FALSE;
						$rval .= '<strong class="red">설치 도중 오류가 발생했습니다.</strong></p>';
					} else {
						$totalChk = TRUE;
						$rval .= '<strong class="green">정상적으로 설치되었습니다.</strong></p>';
					}
				}

				// 관리자 정보 추가
				$rval .= '<p>관리자 정보 추가: ';

				$qset = "INSERT INTO `ucm_user_profile` (`idx`, `authid`, `clidx`, `joindate`, `passkey`) VALUES (NULL, '" . $this->input->post('authidkey', TRUE) . "', '2', '" . time() . "', PASSWORD('" . $this->input->post('passkey', TRUE) . "'));";
				$qaR = $this->db->query($qset);

				if (!$qaR) {
					$totalChk = FALSE;
					$rval .= '<strong class="red">설치 도중 오류가 발생했습니다.</strong></p>';
				} else {
					$totalChk = TRUE;
					$rval .= '<strong class="green">정상적으로 설치되었습니다.</strong></p>';
				}

				if ($totalChk) {
					$rval .= '<div class="buttongrp">';
					$rval .= form_button(array('name' => 'submit', 'type' => 'submit', 'content' => '<i class="fa fa-chevron-right"></i>'));
					$rval .= '</div>';
				} else {
					$rval .= '<div class="buttongrp">';
					$rval .= form_button(array('name' => 'nosubmit', 'type' => 'button', 'content' => '<i class="fa fa-chevron-right"></i>'));
					$rval .= '</div>';
				}
				$rval .= form_close();
				break;
			}
			case 5:
			{
				$attr = array('step' => '6');
				$rval .= form_open('install', '', $attr);
				$rval .= '<p>최종적으로 모든 준비가 완료되었습니다.</p>';
				$rval .= '<p>진행 버튼을 누르시면 마지막 설정 준비와 함께 웹 패널로 들어가게 됩니다.</p>';
				$rval .= '<p>모든 것이 완료되면 게임 내에서나 웹 패널에서나 자유롭게 사용하실 수 있습니다.</p>';
				$rval .= '<div class="buttongrp">';
				$rval .= form_button(array('name' => 'submit', 'type' => 'submit', 'content' => '<i class="fa fa-check"></i>'));
				$rval .= '</div>';
				$rval .= form_close();
				break;
			}
			case 6:
			{
				$rval .= '<p>설정 파일 작성: ';
				if (!write_file(CONFIG_PATH . '/config.php', '1')) {
					$rval .= '<strong class="red">설정 파일을 제작하지 못했습니다.</strong></p>';
				} else {
					$rval .= '<strong class="green">정상적으로 작성되었습니다.</strong></p>';
					redirect('/usrlist/');
				}
				break;
			}
		}
		$data['insdesc'] = $rval;

		$this->load->view('install/_top');
		$this->load->view('install/main', $data);
		$this->load->view('install/_foot');
	}
}

?>