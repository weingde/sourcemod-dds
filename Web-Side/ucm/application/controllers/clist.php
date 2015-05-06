<?php

class Clist extends CI_Controller {

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

		// 목록 모델 로드
		$this->load->model('list_m');
	}

	public function getList()
	{
		/********************************************
		 * 기본 정보
		*********************************************/
		// POST 로드
		$type = $this->input->post('t', TRUE);
		$cpage = $this->input->post('p', TRUE);
		$data['type'] = $type;

		/********************************************
		 * 페이지 조정
		*********************************************/
		// 페이지 양쪽 번호 범위 갯수
		$pageSideCount = 4;
		// 페이지 당 레코드 갯수
		$pageRecords = 20;
		// 페이지
		$pageNum = 0;

		// 페이지 조정
		if ($cpage == 0)	$cpage = 1; // 잡혀있지 않은 경우 번호 1로 세팅
		$data['pageIdx'] = $cpage; // 현재 페이지 번호
		if ($cpage > 0)	$cpage -= 1; // 페이지 당 레코드 갯수로 인해 1을 빼서 처리
		$pageNum += $cpage * $pageRecords;

		// 목록 추출
		$data['pageSideCount'] = $pageSideCount;
		$data['pageRecords'] = $pageRecords;
		$data['pageNum'] = $pageNum;
		$data['listCount'] = $this->list_m->GetList($type, $pageNum, $pageRecords, true);
		$data['list'] = $this->list_m->GetList($type, $pageNum, $pageRecords, false);

		// 전체 페이지 갯수 파악
		$data['pageTotal'] = ceil($data['listCount'] / $pageRecords);

		/********************************************
		 * 출력
		*********************************************/
		$this->load->view('ajax_list', $data);
	}

	public function loadDetInfo()
	{
		/********************************************
		 * 기본 정보
		*********************************************/
		// POST 로드
		$type = $this->input->post('t', TRUE);
		$detail = $this->input->post('dt', TRUE);
		$data = $this->input->post('dat', TRUE);

		// 출력 문자열
		$rval = '';

		// 초기값 설정
		$rst_title = '';
		$rst_name = array(array('name' => '', 'value' => ''));
		$rst_orderidx = 0;
		$rst_env = array();
		$rst_status = 1;
		$rst_onecate = '';
		$rst_twocate = '';
		$rst_setdata = '';
		$rst_desc = '';

		// 세부 행동 설정시 행동별 값 설정 처리
		if (strcmp($detail, 'addclass') == 0)
		{
			/***********************************
			 *
			 * 등급 추가
			 *
			***********************************/
			// 제목 설정
			$rst_title = '등급 추가';

			// 등록된 기본 ENV 목록 로드
			$this->db->select('ucm_env_list.twocate, ucm_env_list.setdata, ucm_env_list.desc');
			//$this->db->where('ucm_env_list.onecate', '');
			$q = $this->db->get('ucm_env_list');
			$qc = $q->result_array();
			$qcount = $q->num_rows();

			// 불러온 값 적용
			if ($qcount > 0)
			{
				for ($i = 0; $i < $qcount; $i++) {
					array_push($rst_env, array('name' => $qc[$i]['twocate'], 'value' => (empty($qc[$i]['setdata'])) ? '' : $qc[$i]['setdata']));
				}
			}
		}
		else if (strcmp($detail, 'addenv') == 0)
		{
			/***********************************
			 *
			 * ENV 추가
			 *
			***********************************/
			// 제목 설정
			$rst_title = 'ENV 추가';
		}
		else if (strcmp($detail, 'modifyclass') == 0)
		{
			/***********************************
			 *
			 * 등급 수정
			 *
			***********************************/
			// 데이터베이스 로드
			$this->db->select('ucm_class_list.gloname, ucm_class_list.orderidx, ucm_class_list.env, ucm_class_list.status');
			$this->db->where('ucm_class_list.clidx', $data);
			$q = $this->db->get('ucm_class_list');
			$qc = $q->result_array();
			$qcount = $q->num_rows();

			// 제목 설정
			$rst_title = '등급 수정';

			// 불러온 값 적용
			if ($qcount > 0)
			{
				$rst_name = GetTotalFormatValue($qc[0]['gloname']);
				$rst_orderidx = $qc[0]['orderidx'];
				$rst_env = GetTotalFormatValue($qc[0]['env']);
				$rst_status = intval($qc[0]['status']);
			}
		}
		else if (strcmp($detail, 'modifyenv') == 0)
		{
			/***********************************
			 *
			 * ENV 수정
			 *
			***********************************/
			// 데이터베이스 로드
			$this->db->select('ucm_env_list.idx, ucm_env_list.onecate, ucm_env_list.twocate, ucm_env_list.setdata, ucm_env_list.desc');
			$this->db->where('ucm_env_list.idx', $data);
			$q = $this->db->get('ucm_env_list');
			$qc = $q->result_array();
			$qcount = $q->num_rows();

			// 제목 설정
			$rst_title = 'ENV 수정';

			// 불러온 값 적용
			if ($qcount > 0)
			{
				$rst_onecate = $qc[0]['onecate'];
				$rst_twocate = $qc[0]['twocate'];
				$rst_setdata = $qc[0]['setdata'];
				$rst_desc = $qc[0]['desc'];
			}
		}

		// 페이지 별 기본 양식
		if (strcmp($type, 'classlist') == 0)
		{
			/** 제목 설정 **/
			$rval .= '<h1>' . $rst_title . '</h1>';

			$rval .= '<div class="form-horzontal">';


			/** 등급 이름 **/
			$rval .= '<div class="form-group">';
			$rval .= '<label class="col-sm-2 control-label">이름</label>';
			$rval .= '<div id="cladd-namesec" class="col-sm-10">';
			for ($i = 0; $i < count($rst_name); $i++)
			{
				// 데이터 번호 설정
				$rval .= '<div class="addname" data-num="' . ($i + 1) . '">';

				// 언어코드 설정
				$rval .= '<div class="col-xs-1">';
				$rval .= '<input name="cladd-langname" class="form-control" type="text" maxlength="2" placeholder="코드" value="' . $rst_name[$i]['name'] . '" />';
				$rval .= '</div>';
				// 이름 값 설정
				$rval .= '<div class="col-xs-3">';
				$rval .= '<input name="cladd-name" class="form-control" type="text" maxlength="30" placeholder="이름" value="' . $rst_name[$i]['value'] . '" />';
				$rval .= '</div>';

				// 처음인 경우 '언어 추가' 버튼을 넣고 그 후에는 '언어 삭제' 버튼을 넣도록 처리
				if ($i <= 0)
					$rval .= '<button id="btn_langadd" class="btn btn-default" name="cladd-langadd">언어 추가</button>';
				else
					$rval .= '<button id="btn_langdelete" class="btn btn-default" name="cladd-langdelete">언어 삭제</button>';

				// E: 데이터 번호 설정
				$rval .= '</div>';
			}
			$rval .= '</div></div>';


			/** 등급 우선순위 **/
			$rval .= '<div class="form-group">';
			$rval .= '<label class="col-sm-2 control-label">우선순위</label>';
			$rval .= '<div class="col-sm-10">';
			$rval .= '<div class="col-xs-2">';
			$rval .= '<input name="cladd-orderidx" class="form-control" type="text" maxlength="4" value="' . $rst_orderidx . '" />';
			$rval .= '</div>';
			$rval .= '</div></div>';


			/** 등급 ENV **/
			$rval .= '<div class="form-group">';
			$rval .= '<label class="col-sm-2 control-label">ENV</label>';
			$rval .= '<div id="cladd-envsec" class="col-sm-10">';
			for ($i = 0; $i < count($rst_env); $i++)
			{
				// 데이터 번호 설정
				$rval .= '<div class="addenv" data-num="' . ($i + 1) . '">';

				// ENV 이름 설정
				$rval .= '<div class="col-xs-3">';
				$rval .= '<input name="cladd-env" class="form-control" type="text" maxlength="40" placeholder="이름" value="' . $rst_env[$i]['name'] . '" />';
				$rval .= '</div>';
				// ENV 값 설정
				$rval .= '<div class="col-xs-5">';
				$rval .= '<input name="cladd-envvalue" class="form-control" type="text" maxlength="128" placeholder="값" value="' . $rst_env[$i]['value'] . '" />';
				$rval .= '</div>';

				// 처음인 경우 'ENV 추가' 버튼을 넣고 그 후에는 'ENV 삭제' 버튼을 넣도록 처리
				if ($i <= 0)
					$rval .= '<button id="btn_envadd" class="btn btn-default" name="cladd-envadd">ENV 추가</button>';
				else
					$rval .= '<button id="btn_envdelete" class="btn btn-default" name="cladd-envdelete">ENV 삭제</button>';

				// E: 데이터 번호 설정
				$rval .= '</div>';
			}
			$rval .= '</div></div>';


			/** 등급 활성화 **/
			$rval .= '<div class="form-group">';
			$rval .= '<label class="col-sm-2 control-label">활성화</label>';
			$rval .= '<div class="col-sm-10">';
			if ($rst_status == 1)
				$rval .= '<input name="cladd-status" type="radio" value="0" />이용안함<input name="cladd-status" type="radio" value="1" checked />이용';
			else
				$rval .= '<input name="cladd-status" type="radio" value="0" checked />이용안함<input name="cladd-status" type="radio" value="1" />이용';
			$rval .= '</div></div>';

			/** 버튼 삽입! **/
			$rval .= '<div class="col-sm-offset-2 col-sm-10">';
			if (strcmp($detail, 'modifyclass') == 0) {
				$rval .= '<input type="hidden" name="cladd-hidden" value="' . $data . '" />';
				$rval .= '<button id="btn_modifyclass" class="btn btn-primary">수정</button>';
			}
			else {
				$rval .= '<button id="btn_addclass" class="btn btn-primary">생성</button>';
			}
			$rval .= '</div>';
		}
		else if (strcmp($type, 'envlist') == 0)
		{
			/** 제목 설정 **/
			$rval .= '<h1>' . $rst_title . '</h1>';

			$rval .= '<div class="form-horzontal">';


			/** ENV 종류 **/
			$rval .= '<div class="form-group">';
			$rval .= '<label class="col-sm-2 control-label">종류</label>';
			$rval .= '<div class="col-sm-10">';
			$rval .= '<div class="col-xs-3">';
			$rval .= '<input name="envadd-onecate" class="form-control" type="text" maxlength="20" value="' . $rst_onecate . '" />';
			$rval .= '</div>';
			$rval .= '</div></div>';


			/** ENV 이름 **/
			$rval .= '<div class="form-group">';
			$rval .= '<label class="col-sm-2 control-label">이름</label>';
			$rval .= '<div class="col-sm-10">';
			$rval .= '<div class="col-xs-3">';
			$rval .= '<input name="envadd-twocate" class="form-control" type="text" maxlength="64" value="' . $rst_twocate . '" />';
			$rval .= '</div>';
			$rval .= '</div></div>';


			/** ENV 값 **/
			$rval .= '<div class="form-group">';
			$rval .= '<label class="col-sm-2 control-label">값</label>';
			$rval .= '<div class="col-sm-10">';
			$rval .= '<div class="col-xs-5">';
			$rval .= '<input name="envadd-setdata" class="form-control" type="text" maxlength="128" value="' . $rst_setdata . '" />';
			$rval .= '</div>';
			$rval .= '</div></div>';


			/** ENV 설명 **/
			$rval .= '<div class="form-group">';
			$rval .= '<label class="col-sm-2 control-label">설명</label>';
			$rval .= '<div class="col-sm-10">';
			$rval .= '<div class="col-xs-5">';
			$rval .= '<textarea name="envadd-desc" class="form-control" rows="4">' . $rst_desc . '</textarea>';
			$rval .= '</div>';
			$rval .= '</div></div>';

			/** 버튼 삽입! **/
			$rval .= '<div class="col-sm-offset-2 col-sm-10">';
			if (strcmp($detail, 'modifyenv') == 0) {
				$rval .= '<input type="hidden" name="envadd-hidden" value="' . $data . '" />';
				$rval .= '<button id="btn_modifyenv" class="btn btn-primary">수정</button>';
			}
			else {
				$rval .= '<button id="btn_addenv" class="btn btn-primary">생성</button>';
			}
			$rval .= '</div>';
		}

		echo $rval;
	}

	function setDetInfo()
	{
		// 타입 분별
		$type = $this->input->post('dt', TRUE);
		$dat = $this->input->post('dat', TRUE);
		
		$rval = $this->list_m->SetDetInfo($type, $dat);
		echo $rval;
	}

	public function index()
	{
		echo 'Why do you enter here? :)';
	}
}

?>