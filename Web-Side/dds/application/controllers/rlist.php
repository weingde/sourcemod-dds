<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Rlist extends CI_Controller {

	function __construct()
	{
		parent::__construct();

		// 목록 모델 로드
		$this->load->model('list_m');

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

	function getList()
	{	
		/********************************************
		 * 기본 정보
		*********************************************/
		$data['authid'] = $this->session->userdata('auth_id');
		$data['usrLang'] = $this->session->userdata('lang');
		$data['surl'] = base_url();

		// POST 로드 및 언어 로드
		$type = $this->input->post('t', TRUE);
		$cpage = $this->input->post('p', TRUE);
		$data['type'] = $type;
		$data['langData'] = $this->lang;

		/********************************************
		 * 기타 필요 정보 삽입
		*********************************************/
		$data['usrprofile'] = $this->list_m->GetProfile($data['authid']);
		$data['nid'] = $this->list_m;

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
		$data['listCount'] = $this->list_m->GetList($type, $pageNum, $pageRecords, $data['authid'], true);
		$data['list'] = $this->list_m->GetList($type, $pageNum, $pageRecords, $data['authid'], false);

		// 전체 페이지 갯수 파악
		$data['pageTotal'] = ceil($data['listCount'] / $pageRecords);

		/********************************************
		 * 출력
		*********************************************/
		$this->load->view('ajax_list', $data);
	}

	function doProcess()
	{
		/********************************************
		 * ------------------------------------
		 *  목록에서의 기본 처리 동작
		 * ------------------------------------
		 *
		 * 준비
		*********************************************/
		// 기본 유저 고유번호
		$authid = $this->session->userdata('auth_id');

		// 타입 분별
		$type = $this->input->post('t', TRUE);
		$odata = $this->input->post('odata', TRUE);
		$tdata = $this->input->post('tdata', TRUE);

		/********************************************
		 * 행동 구분
		*********************************************/
		// 유저 프로필 로드
		$this->db->where('dds_user_profile.authid', $authid);
		$usr_Pro_q = $this->db->get('dds_user_profile');
		$usr_Profile = $usr_Pro_q->result_array();

		$usr_Money = intval($usr_Profile[0]['money']);
		$usr_pInGame = intval($usr_Profile[0]['ingame']);

		// 게임 내에 있으면 동작 못하게 처리
		if ($usr_pInGame == 1)
		{
			echo json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_nogame'));
			return;
		}

		// 행동 구분
		if (strcmp($type, 'item-apply') == 0)
		{
			/**********************************************
			 *
			 * [아이템 장착]
			 *
			***********************************************/
			// 우선 해당 아이템과 같은 종류의 장착 아이템을 모두 장착 해제 시킨다.
			$qready = "UPDATE `dds_user_item` LEFT JOIN `dds_item_list` ON `dds_user_item`.`ilidx` = `dds_item_list`.`ilidx` SET `dds_user_item`.`aplied` = '0' WHERE `dds_user_item`.`authid` = '$authid' AND `dds_item_list`.`icidx` = '$tdata' AND `dds_user_item`.`aplied` = '1'";
			$this->db->query($qready);

			// 그리고 장착 처리
			$qready = "UPDATE `dds_user_item` SET `dds_user_item`.`aplied` = '1' WHERE `dds_user_item`.`authid` = '$authid' AND `dds_user_item`.`idx` = '$odata'";
			$this->db->query($qready);
		}
		else if (strcmp($type, 'item-applycancel') == 0)
		{
			/**********************************************
			 *
			 * [아이템 장착 해제]
			 *
			***********************************************/
			$qready = "UPDATE `dds_user_item` SET `dds_user_item`.`aplied` = '0' WHERE `dds_user_item`.`authid` = '$authid' AND `dds_user_item`.`idx` = '$odata'";
			$this->db->query($qready);
		}
		else if (strcmp($type, 'item-drop') == 0)
		{
			/**********************************************
			 *
			 * [아이템 버리기]
			 *
			***********************************************/
			$setdata = array(
				'dds_user_item.authid' => $authid,
				'dds_user_item.idx' => $odata // 아이템 번호가 아닌 데이터베이스 번호(간.소.화)
			);
			$this->db->where($setdata);
			$this->db->delete('dds_user_item');
		}
		else if (strcmp($type, 'item-buy') == 0)
		{
			/**********************************************
			 *
			 * [아이템 구매]
			 *
			***********************************************/
			// 우선 아이템 금액 확인 후 금액 조건 확인
			$this->db->select('dds_item_list.ilidx, dds_item_list.money, dds_item_list.gloname AS ilname');
			$this->db->where('dds_item_list.ilidx', $odata);
			$sq = $this->db->get('dds_item_list');
			$sqc = $sq->result_array();
			if (intval($sqc[0]['money']) > $usr_Money)
			{
				echo json_encode(array('result' => false, 'title' => 'msg_title_notice', 'msg' => 'msg_results_moneymore'));
				return;
			}

			// 금액 감산 처리
			$qready = "UPDATE `dds_user_profile` SET `dds_user_profile`.`money` = `dds_user_profile`.`money` - $sqc[0]['money'] WHERE `dds_user_profile`.`authid` = '$authid'";
			$this->db->query($qready);

			// 조건이 된다면 구매 처리
			$setdata = array(
				'dds_user_item.authid' => $authid,
				'dds_user_item.ilidx' => $odata,
				'dds_user_item.buydate' => time()
			);
			$this->db->set($setdata);
			$this->db->insert('dds_user_item');
		}
		else if (strcmp($type, 'admin-usrmodify') == 0)
		{
			/**********************************************
			 *
			 * [유저 관리 - 유저 정보 수정]
			 *
			***********************************************/
			$qready = "UPDATE `dds_user_profile` SET `dds_user_profile`.`money` = '$tdata' WHERE `dds_user_profile`.`idx` = '$odata'";
			$this->db->query($qready);
		}
		else if (strcmp($type, 'admin-itemdelete') == 0)
		{
			/**********************************************
			 *
			 * [아이템 관리 - 아이템 삭제]
			 *
			***********************************************/
			$setdata = array(
				'dds_item_list.ilidx' => $odata
			);
			$this->db->where($setdata);
			$this->db->delete('dds_item_list');
		}
		else if (strcmp($type, 'admin-itemcgdelete') == 0)
		{
			/**********************************************
			 *
			 * [아이템 종류 관리 - 아이템 종류 삭제]
			 *
			***********************************************/
			$setdata = array(
				'dds_item_category.icidx' => $odata
			);
			$this->db->where($setdata);
			$this->db->delete('dds_item_category');
		}
		else if (strcmp($type, 'admin-envdelete') == 0)
		{
			/**********************************************
			 *
			 * [ENV 관리 - ENV 삭제]
			 *
			***********************************************/
			$setdata = array(
				'dds_env_list.idx' => $odata
			);
			$this->db->where($setdata);
			$this->db->delete('dds_env_list');
		}
		echo json_encode(array('result' => true, 'title' => 'msg_title_notice', 'msg' => 'msg_results_success'));
	}

	function makeDetInfo()
	{
		// 타입 분별
		$type = $this->input->post('t', TRUE);
		$detail = $this->input->post('dt', TRUE);
		$dat = $this->input->post('dat', TRUE);

		// 출력 문자열
		$rval = '';

		// 초기 설정 값 준비
		$rst_title = '';
		$rst_idx = 0;
		$rst_name = array(array('name' => '', 'value' => ''));
		$rst_money = 0;
		$rst_havtime = 0;
		$rst_orderidx = 0;
		$rst_env = array();
		$rst_status = 1;
		$rst_onecate = '';
		$rst_twocate = '';
		$rst_setdata = '';
		$rst_desc = '';

		// 세부 행동 설정시 행동별 값 설정 처리
		if (strcmp($detail, 'add-item') == 0)
		{
			/***********************************
			 *
			 * 아이템 추가
			 *
			***********************************/
			// 제목 설정
			$rst_title = $this->lang->line('admin_itemlist_add');

			// 등록된 기본 ENV 목록 로드
			$this->db->select('dds_env_list.twocate, dds_env_list.setdata, dds_env_list.desc');
			$this->db->where('dds_env_list.onecate', 'item');
			$q = $this->db->get('dds_env_list');
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
		else if (strcmp($detail, 'add-itemcg') == 0)
		{
			/***********************************
			 *
			 * 아이템 종류 추가
			 *
			***********************************/
			// 제목 설정
			$rst_title = $this->lang->line('admin_itemcglist_add');

			// 등록된 기본 ENV 목록 로드
			$this->db->select('dds_env_list.twocate, dds_env_list.setdata, dds_env_list.desc');
			$this->db->where('dds_env_list.onecate', 'item-category');
			$q = $this->db->get('dds_env_list');
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
		else if (strcmp($detail, 'add-env') == 0)
		{
			/***********************************
			 *
			 * ENV 추가
			 *
			***********************************/
			// 제목 설정
			$rst_title = $this->lang->line('admin_envlist_add');
		}
		else if (strcmp($detail, 'modify-item') == 0)
		{
			/***********************************
			 *
			 * 아이템 수정
			 *
			***********************************/
			// 데이터베이스 로드
			$this->db->select('dds_item_list.icidx, dds_item_list.gloname, dds_item_list.money, dds_item_list.havtime, dds_item_list.env, dds_item_list.status');
			$this->db->where('dds_item_list.ilidx', $dat);
			$q = $this->db->get('dds_item_list');
			$qc = $q->result_array();
			$qcount = $q->num_rows();

			// 제목 설정
			$rst_title = $this->lang->line('admin_itemlist_modify');

			// 불러온 값 적용
			if ($qcount > 0)
			{
				$rst_idx = $qc[0]['icidx'];
				$rst_name = GetTotalFormatValue($qc[0]['gloname']);
				$rst_money = $qc[0]['money'];
				$rst_havtime = $qc[0]['havtime'];
				$rst_env = GetTotalFormatValue($qc[0]['env']);
				$rst_status = intval($qc[0]['status']);
			}
		}
		else if (strcmp($detail, 'modify-itemcg') == 0)
		{
			/***********************************
			 *
			 * 아이템 종류 수정
			 *
			***********************************/
			// 데이터베이스 로드
			$this->db->select('dds_item_category.gloname, dds_item_category.orderidx, dds_item_category.env, dds_item_category.status');
			$this->db->where('dds_item_category.icidx', $dat);
			$q = $this->db->get('dds_item_category');
			$qc = $q->result_array();
			$qcount = $q->num_rows();

			// 제목 설정
			$rst_title = $this->lang->line('admin_itemcglist_modify');

			// 불러온 값 적용
			if ($qcount > 0)
			{
				$rst_name = GetTotalFormatValue($qc[0]['gloname']);
				$rst_orderidx = $qc[0]['orderidx'];
				$rst_env = GetTotalFormatValue($qc[0]['env']);
				$rst_status = intval($qc[0]['status']);
			}
		}
		else if (strcmp($detail, 'modify-env') == 0)
		{
			/***********************************
			 *
			 * 아이템 수정
			 *
			***********************************/
			// 데이터베이스 로드
			$this->db->select('dds_env_list.idx, dds_env_list.onecate, dds_env_list.twocate, dds_env_list.setdata, dds_env_list.desc');
			$this->db->where('dds_env_list.idx', $dat);
			$q = $this->db->get('dds_env_list');
			$qc = $q->result_array();
			$qcount = $q->num_rows();

			// 제목 설정
			$rst_title = $this->lang->line('admin_envlist_modify');

			// 불러온 값 적용
			if ($qcount > 0)
			{
				$rst_idx = $qc[0]['idx'];
				$rst_onecate = $qc[0]['onecate'];
				$rst_twocate = $qc[0]['twocate'];
				$rst_setdata = $qc[0]['setdata'];
				$rst_desc = $qc[0]['desc'];
			}
		}

		// 페이지 별 기본 양식
		if (strcmp($type, 'itemlist') == 0)
		{
			/***********************************
			 *
			 * 아이템
			 *
			***********************************/
			/** 제목 **/
			$rval .= '<div class="box-title"><h1>' . $rst_title . '</h1></div>';


			/** 비율형 섹션 생성 **/
			$rval .= '<div class="form-col">';


			/** 아이템 종류 코드 **/
			$rval .= '<div class="form-section">';

			// 라벨
			$rval .= '<label class="label col-2">' . $this->lang->line('tb_cate_icidx') . '</label>';
			$rval .= '<div class="col-10">';

			// 값
			$rval .= '<input name="iladd-code" class="input-line x-short" type="text" maxlength="8" value="' . $rst_idx . '"/>';
			$rval .= '</div></div>';


			/** 아이템 이름 **/
			$rval .= '<div class="form-section">';

			// 라벨
			$rval .= '<label class="label col-2">' . $this->lang->line('tb_cate_name') . '</label>';
			$rval .= '<div id="iladd-namesec" class="col-10 form-inline">';

			// 값
			for ($i = 0; $i < count($rst_name); $i++)
			{
				// 데이터 번호 설정
				$rval .= '<div class="addname" data-num="' . ($i + 1) . '">';

				// 언어코드 설정
				$rval .= '<input name="iladd-langname" class="input-line xx-short" type="text" maxlength="2" placeholder="' . $this->lang->line('tb_cate_code') . '" value="' . $rst_name[$i]['name'] . '" />';
				// 이름 값 설정
				$rval .= '<input name="iladd-name" class="input-line short" type="text" maxlength="30" placeholder="' . $this->lang->line('tb_cate_name') . '" value="' . $rst_name[$i]['value'] . '"/>';

				// 처음인 경우 '언어 추가' 버튼을 넣고 그 후에는 '언어 삭제' 버튼을 넣도록 처리
				if ($i <= 0)
					$rval .= '<button id="btn_langadd" class=".col-2-rev" name="iladd-langadd">' . $this->lang->line('btn_langadd') . '</button>';
				else
					$rval .= '<button id="btn_langdelete" class=".col-2-rev" name="iladd-langdelete">' . $this->lang->line('btn_langdelete') . '</button>';

				// E: 데이터 번호 설정
				$rval .= '</div>';
			}
			$rval .= '</div></div>';


			/** 아이템 금액 **/
			$rval .= '<div class="form-section">';

			// 라벨
			$rval .= '<label class="label col-2">' . $this->lang->line('tb_cate_money') . '</label>';
			$rval .= '<div class="col-10">';

			// 값
			$rval .= '<input name="iladd-money" class="input-line x-short" type="text" maxlength="30" value="' . $rst_money . '"/>';
			$rval .= '</div></div>';


			/** 아이템 지속 속성 **/
			$rval .= '<div class="form-section">';

			// 라벨
			$rval .= '<label class="label col-2">' . $this->lang->line('tb_cate_havtime') . '</label>';
			$rval .= '<div class="col-10">';

			// 값
			$rval .= '<input name="iladd-havtime" class="input-line x-short" type="text" maxlength="15" value="' . $rst_havtime . '"/>';
			$rval .= '</div></div>';


			/** 아이템 ENV **/
			$rval .= '<div class="form-section">';

			// 라벨
			$rval .= '<label class="label col-2">' . $this->lang->line('tb_cate_env') . '</label>';
			$rval .= '<div id="iladd-envsec" class="col-10 form-inline">';

			// 값
			for ($i = 0; $i < count($rst_env); $i++)
			{
				// 데이터 번호 설정
				$rval .= '<div class="addenv" data-num=" ' . ($i + 1) . '">';

				// ENV 이름 설정
				$rval .= '<input name="iladd-env" class="input-line short" type="text" maxlength="40" placeholder="' . $this->lang->line('tb_cate_name') . '" value="' . $rst_env[$i]['name'] . '" />';
				// ENV 값 설정
				$rval .= '<input name="iladd-envvalue" class="input-line medium" type="text" maxlength="128" placeholder="' . $this->lang->line('tb_cate_value') . '" value="' . $rst_env[$i]['value'] . '" />';

				// 처음인 경우 'ENV 추가' 버튼을 넣고 그 후에는 'ENV 삭제' 버튼을 넣도록 처리
				if ($i <= 0)
					$rval .= '<button id="btn_envadd" class=".col-2-rev" name="iladd-envadd">' . $this->lang->line('btn_envadd') . '</button>';
				else
					$rval .= '<button id="btn_envdelete" class=".col-2-rev" name="iladd-envdelete">' . $this->lang->line('btn_envdelete') . '</button>';

				// E: 데이터 번호 설정
				$rval .= '</div>';
			}
			$rval .= '</div></div>';


			/** 아이템 활성화 **/
			$rval .= '<div class="form-section">';

			// 라벨
			$rval .= '<label class="label col-2">' . $this->lang->line('tb_cate_status') . '</label>';
			$rval .= '<div class="col-10">';

			// 값
			if ($rst_status == 1)
				$rval .= '<input name="iladd-status" type="radio" value="0" />' . $this->lang->line('admin_list_nouse') . '<input name="iladd-status" type="radio" value="1" checked />' . $this->lang->line('admin_list_use');
			else
				$rval .= '<input name="iladd-status" type="radio" value="0" checked />' . $this->lang->line('admin_list_nouse') . '<input name="iladd-status" type="radio" value="1" />' . $this->lang->line('admin_list_use');

			$rval .= '</div></div>';

			/** 버튼 삽입! **/
			// 세부 행동이 '수정'
			if (strcmp($detail, 'modify-item') == 0) {
				$rval .= '<input type="hidden" name="iladd-hidden" value="' . $dat . '" />';
				$rval .= '<button id="btn_modifyitem" class=".col-2-rev">' . $this->lang->line('btn_modify') . '</button>';
			}
			else {
				$rval .= '<button id="btn_additem" class=".col-2-rev">' . $this->lang->line('btn_create') . '</button>';
			}

			$rval .= '</div>';
		}
		else if (strcmp($type, 'itemcglist') == 0)
		{
			/***********************************
			 *
			 * 아이템 종류
			 *
			***********************************/
			/** 제목 **/
			$rval .= '<div class="box-title"><h1>' . $rst_title . '</h1></div>';


			/** 비율형 섹션 생성 **/
			$rval .= '<div class="form-col">';


			/** 아이템 종류 이름 **/
			$rval .= '<div class="form-section">';

			// 라벨
			$rval .= '<label class="label col-2">' . $this->lang->line('tb_cate_name') . '</label>';
			$rval .= '<div id="icadd-namesec" class="col-10 form-inline">';

			// 값
			for ($i = 0; $i < count($rst_name); $i++)
			{
				// 데이터 번호 설정
				$rval .= '<div class="addname" data-num="' . ($i + 1) . '">';

				// 언어코드 설정
				$rval .= '<input name="icadd-langname" class="input-line xx-short" type="text" maxlength="2" placeholder="' . $this->lang->line('tb_cate_code') . '" value="' . $rst_name[$i]['name'] . '" />';
				// 이름 값 설정
				$rval .= '<input name="icadd-name" class="input-line short" type="text" maxlength="30" placeholder="' . $this->lang->line('tb_cate_name') . '" value="' . $rst_name[$i]['value'] . '" />';

				// 처음인 경우 '언어 추가' 버튼을 넣고 그 후에는 '언어 삭제' 버튼을 넣도록 처리
				if ($i <= 0)
					$rval .= '<button id="btn_langadd" class=".col-2-rev" name="icadd-langadd">' . $this->lang->line('btn_langadd') . '</button>';
				else
					$rval .= '<button id="btn_langdelete" class=".col-2-rev" name="icadd-langdelete">' . $this->lang->line('btn_langdelete') . '</button>';

				// E: 데이터 번호 설정
				$rval .= '</div>';
			}
			$rval .= '</div></div>';


			/** 아이템 종류 우선 순위 **/
			$rval .= '<div class="form-section">';

			// 라벨
			$rval .= '<label class="label col-2">' . $this->lang->line('tb_cate_orderidx') . '</label>';
			$rval .= '<div class="col-10">';

			// 값
			$rval .= '<input name="icadd-orderidx" class="input-line x-short" type="text" maxlength="4" value="' . $rst_orderidx . '"/>';
			$rval .= '</div></div>';


			/** 아이템 종류 ENV **/
			$rval .= '<div class="form-section">';

			// 라벨
			$rval .= '<label class="label col-2">' . $this->lang->line('tb_cate_env') . '</label>';
			$rval .= '<div id="icadd-envsec" class="col-10 form-inline">';

			// 값
			for ($i = 0; $i < count($rst_env); $i++)
			{
				// 데이터 번호 설정
				$rval .= '<div class="addenv" data-num="' . ($i + 1) . '">';

				// ENV 이름 설정
				$rval .= '<input name="icadd-env" class="input-line short" type="text" maxlength="40" placeholder="' . $this->lang->line('tb_cate_name') . '" value="' . $rst_env[$i]['name'] . '" />';
				// ENV 값 설정
				$rval .= '<input name="icadd-envvalue" class="input-line medium" type="text" maxlength="128" placeholder="' . $this->lang->line('tb_cate_value') . '" value="' . $rst_env[$i]['value'] . '" />';

				// 처음인 경우 'ENV 추가' 버튼을 넣고 그 후에는 'ENV 삭제' 버튼을 넣도록 처리
				if ($i <= 0)
					$rval .= '<button id="btn_envadd" class=".col-2-rev" name="icadd-envadd">' . $this->lang->line('btn_envadd') . '</button>';
				else
					$rval .= '<button id="btn_envdelete" class=".col-2-rev" name="icadd-envdelete">' . $this->lang->line('btn_envdelete') . '</button>';

				// E: 데이터 번호 설정
				$rval .= '</div>';
			}
			$rval .= '</div></div>';


			/** 아이템 종류 활성화 **/
			$rval .= '<div class="form-section">';

			// 라벨
			$rval .= '<label class="label col-2">' . $this->lang->line('tb_cate_status') . '</label>';
			$rval .= '<div class="col-10">';

			// 값
			if ($rst_status == 1)
				$rval .= '<input name="icadd-status" type="radio" value="0" />' . $this->lang->line('admin_list_nouse') . '<input name="icadd-status" type="radio" value="1" checked />' . $this->lang->line('admin_list_use');
			else
				$rval .= '<input name="icadd-status" type="radio" value="0" checked />' . $this->lang->line('admin_list_nouse') . '<input name="icadd-status" type="radio" value="1" />' . $this->lang->line('admin_list_use');

			$rval .= '</div></div>';

			/** 버튼 삽입! **/
			if (strcmp($detail, 'modify-itemcg') == 0) {
				$rval .= '<input type="hidden" name="icadd-hidden" value="' . $dat . '" />';
				$rval .= '<button id="btn_modifyitemcg" class=".col-2-rev">' . $this->lang->line('btn_modify') . '</button>';
			}
			else {
				$rval .= '<button id="btn_additemcg" class=".col-2-rev">' . $this->lang->line('btn_create') . '</button>';
			}

			$rval .= '</div>';
		}
		else if (strcmp($type, 'envlist') == 0)
		{
			/***********************************
			 *
			 * ENV 관리
			 *
			***********************************/
			/** 제목 **/
			$rval .= '<div class="box-title"><h1>' . $rst_title . '</h1></div>';


			/** 비율형 섹션 생성 **/
			$rval .= '<div class="form-col">';


			/** ENV 종류 **/
			$rval .= '<div class="form-section">';

			// 라벨
			$rval .= '<label class="label col-2">' . $this->lang->line('tb_cate_category') . '</label>';
			$rval .= '<div class="col-10">';

			// 값
			$rval .= '<input name="envadd-onecate" class="input-line x-short" type="text" maxlength="20" value="' . $rst_onecate . '"/>';
			$rval .= '</div></div>';


			/** ENV 이름 **/
			$rval .= '<div class="form-section">';

			// 라벨
			$rval .= '<label class="label col-2">' . $this->lang->line('tb_cate_name') . '</label>';
			$rval .= '<div class="col-10">';

			// 값
			$rval .= '<input name="envadd-twocate" class="input-line short" type="text" maxlength="64" value="' . $rst_twocate . '"/>';
			$rval .= '</div></div>';


			/** ENV 값 **/
			$rval .= '<div class="form-section">';

			// 라벨
			$rval .= '<label class="label col-2">' . $this->lang->line('tb_cate_value') . '</label>';
			$rval .= '<div class="col-10">';

			// 값
			$rval .= '<input name="envadd-setdata" class="input-line medium" type="text" maxlength="128" value="' . $rst_setdata . '"/>';
			$rval .= '</div></div>';


			/** ENV 설명 **/
			$rval .= '<div class="form-section">';

			// 라벨
			$rval .= '<label class="label col-2">' . $this->lang->line('tb_cate_desc') . '</label>';
			$rval .= '<div class="col-10">';

			// 값
			$rval .= '<textarea name="envadd-desc" class="textarea medium" rows="4">' . $rst_desc . '</textarea>';
			$rval .= '</div></div>';

			/** 버튼 삽입! **/
			if (strcmp($detail, 'modify-env') == 0) {
				$rval .= '<input type="hidden" name="envadd-hidden" value="' . $dat . '" />';
				$rval .= '<button id="btn_modifyenv" class=".col-2-rev">' . $this->lang->line('btn_modify') . '</button>';
			}
			else {
				$rval .= '<button id="btn_addenv" class=".col-2-rev">' . $this->lang->line('btn_create') . '</button>';
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

	function index()
	{
		echo 'Why do you enter here? :)';
	}
}

?>