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
			redirect('/home/');
		}
	}

	public function index()
	{
		// 인덱스 초기화
		$stepIdx = 1;

		// 넘겨진 항목 설정
		if ($this->input->post('step', TRUE)) {
			$stepIdx = $this->input->post('step', TRUE);
		};

		// 항목 목록
		$stepList = array(
			array(1, '라이센스 확인'),
			array(2, '퍼미션 및 환경 확인'),
			array(3, '설치 준비'),
			array(4, '설치'),
			array(5, 'API Key 입력'),
			array(6, '완료'),
			array(7, '홈 이동')
		);

		// 정보 할당
		$data['step'] = 'Step ' . $stepList[$stepIdx - 1][0];
		$data['stepdesc'] = $stepList[$stepIdx - 1][1];

		// 설치 페이지 구성
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
				$rval .= '<p> - \'conf\' 폴더의 권한이 <strong>707</strong> 또는 <strong>777</strong> 이어야 합니다.<br>';
				$rval .= ' - 웹 서버에서 <strong>cUrl</strong>의 <strong>HTTPS 프로토콜</strong>을 지원해야 합니다. 이는 웹 패널에서의 인증과 관련이 있습니다.</p>';
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

				// cUrl 기능 확인(HTTPS)
				$rval .= '<li>cUrl의 HTTPS 프로토콜 지원: ';
				$getcurl = FALSE;
				$getExt = get_loaded_extensions();
				for ($i = 0; $i < count($getExt); $i++)
				{
					if (strcmp($getExt[$i], 'curl') == 0)
					{
						// cUrl 라이브러리 파악
						$getcurl = TRUE;

						// 테스트 시작
						$testCurl = curl_init();

						// 역시 구글이 체고!
						curl_setopt($testCurl, CURLOPT_URL, 'https://www.google.co.kr/');
						curl_setopt($testCurl, CURLOPT_SSL_VERIFYPEER, FALSE);
						curl_setopt($testCurl, CURLOPT_SSLVERSION, 3);
						curl_setopt($testCurl, CURLOPT_HEADER, 0);
						curl_setopt($testCurl, CURLOPT_RETURNTRANSFER, 1);
						curl_setopt($testCurl, CURLOPT_POST, 0);
						curl_setopt($testCurl, CURLOPT_TIMEOUT, 3);
						$testBuf = curl_exec($testCurl);
						$testInfo = curl_getinfo($testCurl);

						// 정상 작동(200)
						if ($testInfo['http_code'] != 200)
						{
							if (curl_errno($testCurl))
							{
								$rval .= '<strong class="red">미지원</strong></li>';
								$totalChk = FALSE;
								break;
							}
						}
						curl_close($testCurl);

						$rval .= '<strong class="green">지원</strong></li>';
						$totalChk = TRUE;
						break;
					}
				}

				if (!$getcurl) {
					$rval .= '<strong class="red">cUrl Extension 없음</strong></li>';
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
				// UCM 테이블 존재 확인
				$c_ucmq = "SELECT * FROM `information_schema`.`TABLES` WHERE `table_name` = 'ucm_user_profile'";
				$c_ucmc = $this->db->query($c_ucmq);
				$c_ucmr = $c_ucmc->num_rows();

				$attr = array('step' => '4');
				$rval .= form_open('install', '', $attr);
				$rval .= '<p>현 단계에서는 설정된 데이터베이스에 앞으로 \'' . PRODUCT_NAME . '\'을 이용하기 위해 필요한 데이터 구조를 설치하고 초기 접근에 있어 관리자 정보를 추가하게 됩니다.</p>';
				$rval .= '<p>여기서 설치되는 데이터 구조 및 관리자 정보는 앞으로 게임 서버 및 웹 패널에서 \'' . PRODUCT_NAME . '\'을 이용하는데 있어 반드시 필요한 절차입니다.</p>';
				$rval .= '<p>아래에 있는 고유번호 입력 폼은 웹 패널을 관리할 초기의 최고 관리자로서 활동하게 될 스팀 아이디의 고유번호를 입력해주세요.</p>';
				$rval .= '<p>\'' . PRODUCT_NAME . '\'는 UCM을 이용하여 관리자 정보를 등록하게 됩니다.</p>';
				$rval .= '<p>등록할 고유번호를 모르겠다면 <a href="http://steamidconverter.com/" target="_blank">여기</a>를 클릭하고 고유번호를 찾으세요. \'' . PRODUCT_NAME . '\'에서는 고유번호를 steamID64를 사용합니다.</p>';
				$rval .= '<p><img src="' . base_url() . 'images/install_auth.png" width="564px" height="329px" /></p>';
				$rval .= '<p><label for="authidkey">고유번호 입력</label>' . form_input(array('id' => 'authidkey', 'name' => 'authidkey', 'maxlength' => '20', 'title' => '고유번호를 입력해주세요.')) . '</p>';
				if ($c_ucmr <= 0) {
					$rval .= '<p>아래의 항목은 UCM이 설치되어 있지 않아 생긴 것입니다.<br>UCM 웹 패널을 이용 시 사용할 비밀번호 6자리 이상을 적어주세요.</p>';
					$rval .= '<p><label for="passkey">비밀번호 입력</label>' . form_input(array('id' => 'passkey', 'name' => 'passkey', 'type' => 'password', 'maxlength' => '30', 'title' => '비밀번호를 입력해주세요.')) . '</p>';
				}
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

				// UCM 테이블 존재 확인
				$c_ucmq = "SELECT * FROM `information_schema`.`TABLES` WHERE `table_name` = 'ucm_user_profile'";
				$c_ucmc = $this->db->query($c_ucmq);
				$c_ucmr = $c_ucmc->num_rows();

				$c_ucm = FALSE;
				if ($c_ucmr <= 0)	$c_ucm = TRUE;

				$totalStr = '';
				$inst_dds = FALSE;
				$inst_ucm = FALSE;
				$dds_sqlPath = read_file(CONFIG_PATH . '/install_dds.sql'); // DDS
				$ucm_sqlPath = read_file(CONFIG_PATH . '/install_ucm.sql'); // UCM
				if (!$dds_sqlPath || !$ucm_sqlPath) {
					$rval .= '<strong class="red">SQL 파일이 없습니다.</strong></p>';
				} else {
					// DDS 먼저 처리
					if ($dds_sqlPath) {
						// 식별자 ';'' 기준으로 분리
						$sqls = explode(';', $dds_sqlPath);
						// 쓸모없는 것은 제거
						array_pop($sqls);
						// 쿼리 한 줄마다 실행
						$qRst;
						foreach ($sqls as $q) {
							$q = $q . ';';
							$qRst = $this->db->query($q);
						}

						if ($qRst) {
							$inst_dds = TRUE;
							$totalStr .= 'DDS 설치 완료';
						} else {
							$inst_dds = FALSE;
							$totalStr .= 'DDS 설치 실패';
						}
					}
					// UCM 조건 하 처리
					if ($ucm_sqlPath) {
						// 기존 테이블이 없는지 확인
						if ($c_ucm)
						{
							// 식별자 ';'' 기준으로 분리
							$sqls = explode(';', $ucm_sqlPath);
							// 쓸모없는 것은 제거
							array_pop($sqls);
							// 쿼리 한 줄마다 실행
							$qRst;
							foreach ($sqls as $q) {
								$q = $q . ';';
								$qRst = $this->db->query($q);
							}

							if ($qRst) {
								$inst_ucm = TRUE;
								$totalStr .= ' / UCM 설치 완료';
							} else {
								$inst_ucm = FALSE;
								$totalStr .= ' / UCM 설치 실패';
							}
						}
					}
					if ($inst_dds && $inst_ucm) {
						$totalChk = TRUE;
						$rval .= '<strong class="green">' . $totalStr . '</strong></p>';
					} else {
						$totalChk = FALSE;
						$rval .= '<strong class="red">' . $totalStr . '</strong></p>';
					}
				}

				// 관리자 정보 추가
				$rval .= '<p>관리자 정보 추가: ';

				$qset = "INSERT INTO `dds_user_profile` (`idx`, `authid`) VALUES (NULL, '" . $this->input->post('authidkey', TRUE) . "');";
				$qaR = $this->db->query($qset);
				if ($c_ucm) {
					$qset = "INSERT INTO `ucm_user_profile` (`idx`, `authid`, `clidx`, `joindate`, `passkey`) VALUES (NULL, '" . $this->input->post('authidkey', TRUE) . "', '2', '" . time() . "', PASSWORD('" . $this->input->post('passkey', TRUE) . "'));";
					$qaR = $this->db->query($qset);
				}

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
				$rval .= '<p>최종적으로 웹 패널을 이용하기 위해서는 스팀 Web API Key가 필요합니다.</p>';
				$rval .= '<p>\'' . PRODUCT_NAME . '\'는 스팀 API를 이용하여 편하게 웹 패널에 들어가고 자세한 정보를 확인할 수 있으며 관리도 손쉽게 할 수 있도록 도와줍니다.</p>';
				$rval .= '<p>스팀 Web API Key 는 <a href="http://steamcommunity.com/dev/apikey" target="_blank">여기</a>로 들어가셔서 발급받을 수 있습니다.<br>받은 32자리 API Key를 아래의 입력란에 써주십시오.</p>';
				$rval .= '<label for="apikey">Key 입력</label>' . form_input(array('id' => 'apikey', 'name' => 'apikey', 'maxlength' => '32', 'title' => '32자리의 API Key를 입력해주세요.'));
				$rval .= '<div class="buttongrp">';
				$rval .= form_button(array('id' => 'apisubmit', 'name' => 'nosubmit', 'type' => 'button', 'content' => '<i class="fa fa-chevron-right"></i>'));
				$rval .= '</div>';
				$rval .= form_close();
				break;
			}
			case 6:
			{
				$attr = array('step' => '7', 'apikey' => $this->input->post('apikey', TRUE));
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
			case 7:
			{
				// 설정 파일 작성
				$rval .= '<p>설정 파일 작성: ';
				if (!write_file(CONFIG_PATH . '/config.php', $this->input->post('apikey', TRUE))) {
					$rval .= '<strong class="red">설정 파일을 제작하지 못했습니다.</strong></p>';
				} else {
					$rval .= '<strong class="green">정상적으로 작성되었습니다.</strong></p>';
					redirect('/home/');
				}
				break;
			}
		}
		$data['insdesc'] = $rval;

		// 출력
		$this->load->view('install/_top');
		$this->load->view('install/main', $data);
		$this->load->view('install/_foot');
	}
}

?>