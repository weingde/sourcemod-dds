/**
 *
 * Dynamic Dollar Shop (DDS)
 * - Main Javascript file
 *
 * Author By. Eakgnarok
 * (c) 2012 - 2015 
 *
 */

/**
 * 쿠키 가져오기
 *
 * @param name				쿠키 값 이름
 */
function getCookie(name) {
	name = name + '=';
	var cData = document.cookie;
	var wantIdx = cData.indexOf(name);
	var rval = '';

	if (wantIdx != -1) {
		wantIdx += name.length;
		
		var endIdx = cData.indexOf(';', wantIdx);
		if (endIdx == -1)
			endIdx = cData.length;

		rval = cData.substring(wantIdx, endIdx);
	}
	return unescape(rval);
}

/**
 * 숫자만 입력하도록 설정
 *
 * @param obj				DOM 객체
 */
function ChkNum(obj)
{
}

/**
 * 프로그래스 바 초기화
 */
function initProgress() {
	// 프로그래스 바 설정
	NProgress.start();
	NProgress.done();
	// 프로그래스 바 설정(ajax)
	$(document).ajaxStart(function() {
		NProgress.start();
		NProgress.done();
	});
}

/**
 * 목록 가져오기
 *
 * @param stype				행동 타입
 * @param starget			목록 타겟
 * @param spage				페이지 번호
 */
function loadList(stype, starget, spage)
{
	var controller = 'rlist';

	// 매개변수가 할당되어 있지 않을 때 처리
	spage = typeof spage !== 'undefined' ? spage : 1;

	// 실행
	$.ajax({
		url: base_Url + controller + '/getList',
		type: 'POST',
		data: {
			'dds_t': getCookie('dds_c'), 
			't': stype, 
			'p': spage
		},
		success: function(data) {
			if (data) {
				$(starget).html(data);
			}
		},
		error: function(req, status, error) {
			loadPromptMsgError('msg_title_notice', 'msg_results_requestfail', error);
		}
	});
}

/**
 * 목록 설정하기
 *
 * @param stype				행동 타입
 * @param sdetail			세부 행동 타입
 * @param starget			목록 타겟
 * @param sodata			첫 번째 데이터 값
 * @param stdata			두 번째 데이터 값
 * @param spage				페이지 번호
 */
function doProcess(stype, sdetail, starget, sodata, stdata, spage)
{
	var controller = 'rlist';

	// 매개변수가 할당되어 있지 않을 때 처리
	stdata = typeof stdata !== 'undefined' ? stdata : 0;
	spage = typeof spage !== 'undefined' ? spage : 1;

	// 실행
	$.ajax({
		url: base_Url + controller + '/doProcess',
		type: 'POST',
		data: {
			'dds_t': getCookie('dds_c'), 
			't': sdetail, 
			'odata': sodata, 
			'tdata': stdata
		},
		success: function(data) {
			// 다시 목록을 로드
			loadList(stype, starget, spage);

			try {
				// Json 파싱
				var jdata = $.parseJSON(data);
				if (typeof jdata == 'object') {
					loadPromptMsg(jdata.title, jdata.msg);
				} else {
					loadPromptMsgError('msg_title_notice', 'msg_results_requestfail', 'No Object');
				}
			} catch (e) {
				loadPromptMsgError('msg_title_notice', 'msg_results_requestfail', data + '<p>' + e + '</p>');
			}
		},
		error: function(req, status, error) {
			loadPromptMsgError('msg_title_notice', 'msg_results_requestfail', error);
		}
	});
}

/**
 * 버튼이 하나인 알림창 열기
 *
 * @param title				제목
 * @param msg				메세지
 */
function loadPromptMsg(title, msg)
{
	var controller = 'msg';

	$.ajax({
		url: base_Url + controller + '/loadPromptMsg',
		type: 'POST',
		data: {
			'dds_t': getCookie('dds_c'), 
			'title': title,
			'msg': msg
		},
		success: function(data) {
			try {
				// Json 파싱
				var jdata = $.parseJSON(data);
				if (typeof jdata == 'object') {
					$.prompt(jdata.msg, {
						title: jdata.title,
						buttons: {"O": true}
					});
				} else {
					loadPromptMsgError('msg_title_notice', 'msg_results_requestfail', 'No Object');
				}
			} catch (e) {
				loadPromptMsgError('msg_title_notice', 'msg_results_requestfail', data + '<p>' + e + '</p>');
			}
		},
		error: function(req, status, error) {
			loadPromptMsgError('msg_title_notice', 'msg_results_requestfail', error);
		}
	});
}

/**
 * 버튼이 두 개인 알림창 열기
 *
 * @param title				제목
 * @param msg				메세지
 * @param func				O 버튼을 누를 시 실행될 함수
 */
function loadPromptMsg2(title, msg, func)
{
	var controller = 'msg';

	$.ajax({
		url: base_Url + controller + '/loadPromptMsg',
		type: 'POST',
		data: {
			'dds_t': getCookie('dds_c'), 
			'title': title,
			'msg': msg
		},
		success: function(data) {
			try {
				// Json 파싱
				var jdata = $.parseJSON(data);
				if (typeof jdata == 'object') {
					$.prompt(jdata.msg, {
						title: jdata.title,
						buttons: {"O": true, "X": false},
						submit: function (e, v, m, f) {
							if (v) {
								func();
							}
						}
					});
				} else {
					loadPromptMsgError('msg_title_notice', 'msg_results_requestfail', 'No Object');
				}
			} catch (e) {
				loadPromptMsgError('msg_title_notice', 'msg_results_requestfail', data + '<p>' + e + '</p>');
			}
		},
		error: function(req, status, error) {
			loadPromptMsgError('msg_title_notice', 'msg_results_requestfail', error);
		}
	});
}

/**
 * 버튼이 하나인 오류 알림창 열기
 *
 * @param title				제목
 * @param msg				일반 메세지
 * @param errmsg			오류 메세지
 */
function loadPromptMsgError(title, msg, errmsg)
{
	var controller = 'msg';

	$.ajax({
		url: base_Url + controller + '/loadPromptMsg',
		type: 'POST',
		data: {
			'dds_t': getCookie('dds_c'), 
			'title': title,
			'msg': msg
		},
		success: function(data) {
			try {
				// Json 파싱
				var jdata = $.parseJSON(data);
				if (typeof jdata == 'object') {
					$.prompt(jdata.msg + '<p>' + errmsg + '</p>', {
						title: jdata.title,
						buttons: {"O": true}
					});
				} else {
					console.log('Loaded JSON is not object!');
				}
			} catch (e) {
				console.log('Error Occurred! - Data:' + data + ' / E: ' + e);
			}
		},
		error: function(req, status, error) {
			console.log('Error Occurred! - ' + data);
		}
	});
}

/**
 * 번역 로드
 *
 * @param msg				메세지
 * @param getStr			콜백 함수
 */
function loadTransMsg(msg, getStr)
{
	var controller = 'msg';

	$.ajax({
		url: base_Url + controller + '/loadTransMsg',
		type: 'POST',
		data: {
			'dds_t': getCookie('dds_c'), 
			'msg': msg
		},
		success: function(data) {
			getStr(data);
		},
		error: function(req, status, error) {
			loadPromptMsgError('msg_title_notice', 'msg_results_requestfail', error);
		}
	});
}

/**
 * 세부 정보 삽입
 *
 * @param stype				타입 배분
 * @param sdetail			세부 행동 타입
 * @param starget			대상 목표
 * @param sdata				전송 데이터
 */
function makeDetInfo(stype, sdetail, starget, sdata)
{
	var controller = 'rlist';

	// 매개변수가 할당되어 있지 않을 때 처리
	sdata = typeof sdata !== 'undefined' ? sdata : 0;

	$.ajax({
		url: base_Url + controller + '/makeDetInfo',
		type: 'POST',
		data: {
			'dds_t': getCookie('dds_c'), 
			't': stype,
			'dt': sdetail,
			'dat': sdata
		},
		success: function(data) {
			$(starget).html(data);
		},
		error: function(req, status, error) {
			loadPromptMsgError('msg_title_notice', 'msg_results_requestfail', error);
		}
	});
}

/**
 * 세부 정보 등록
 *
 * @param stype				타입 배분
 * @param sdetail			세부 행동 타입
 * @param starget			대상 목표
 * @param sdata				전송 데이터
 */
function setDetInfo(stype, sdetail, starget, sdata)
{
	var controller = 'rlist';

	//console.log(stype + ' / ' + sdetail + ' / ' + starget + ' / ' + sdata);

	$.ajax({
		url: base_Url + controller + '/setDetInfo',
		type: 'POST',
		data: {
			'dds_t': getCookie('dds_c'), 
			'dt': sdetail,
			'dat': sdata
		},
		success: function(data) {
			// 다시 목록을 로드
			loadList(stype, starget);
			
			try {
				// Json 파싱
				var jdata = $.parseJSON(data);
				if (typeof jdata == 'object') {
					loadPromptMsg(jdata.title, jdata.msg);
				} else {
					loadPromptMsgError('msg_title_notice', 'msg_results_requestfail', 'No Object');
				}
			} catch (e) {
				loadPromptMsgError('msg_title_notice', 'msg_results_requestfail', data + '<p>' + e + '</p>');
			}
		},
		error: function(req, status, error) {
			loadPromptMsgError('msg_title_notice', 'msg_results_requestfail', error);
		}
	});
}

// 최초 실행
;$(function($) {
	// 프로그래스 바 설정
	initProgress();
	// traditional 설정
	//$.ajaxSettings.traditional = true;

	// AUTHID 입력 시
	$('#authidkey').on('keyup', function() {
		var $key = $('#authidkey').val();

		// 적어도 15글자는 입력해야 함
		if ($key.length >= 15)
		{
			$('#authsubmit').attr({
				'name': 'submit',
				'type': 'submit'
			});
		}
		else
		{
			$('#authsubmit').attr({
				'name': 'nosubmit',
				'type': 'button'
			});
		}
	});
	// API KEY 입력 시
	$('#apikey').on('keyup', function() {
		var $key = $('#apikey').val();

		// 적어도 32글자는 입력해야 함
		if ($key.length >= 32)
		{
			$('#apisubmit').attr({
				'name': 'submit',
				'type': 'submit'
			});
		}
		else
		{
			$('#apisubmit').attr({
				'name': 'nosubmit',
				'type': 'button'
			});
		}
	});

	/******************************************
	 * ----------------------
	 * 버튼 클릭 관련
	 * ----------------------
	*******************************************/
	/**********************
	 * 페이지 전환
	***********************/
	$(document).on('click', '.pagination > li > a', function() {
		loadList($(this).attr('data-t'), $(this).attr('data-tar'), $(this).html());
	});

	/**********************
	 * 유저 인벤토리
	***********************/
	/** 아이템 장착 **/
	$(document).on('click', '#user-invenlist .btnapl', function() {
		// 목록 갱신 관련
		var sType = $(this).attr('data-t'); var sPage = $(this).attr('data-p');

		// 목록 설정 관련
		var sDetail = $(this).attr('data-dt'); 
		var sIlIdx = $(this).attr('data-ilidx'); 
		var sIcIdx = $(this).attr('data-icidx');
		loadPromptMsg2('msg_title_notice', 'msg_contents_itemuse', (function() {
			doProcess(sType, sDetail, '#myinfo-list', sIlIdx, sIcIdx, sPage);
		}));
	});
	/** 아이템 장착 해제 **/
	$(document).on('click', '#user-invenlist .btnaplcan', function() {
		// 목록 갱신 관련
		var sType = $(this).attr('data-t'); var sPage = $(this).attr('data-p');

		// 목록 설정 관련
		var sDetail = $(this).attr('data-dt');
		var sIlIdx = $(this).attr('data-ilidx');
		var sIcIdx = $(this).attr('data-icidx');
		loadPromptMsg2('msg_title_notice', 'msg_contents_itemcancel', (function() {
			doProcess(sType, sDetail, '#myinfo-list', sIlIdx, sIcIdx, sPage);
		}));
	});
	/** 아이템 버리기 **/
	$(document).on('click', '#user-invenlist .btndrop', function() {
		// 목록 갱신 관련
		var sType = $(this).attr('data-t'); var sPage = $(this).attr('data-p');

		// 목록 설정 관련
		var sDetail = $(this).attr('data-dt');
		var sIlIdx = $(this).attr('data-ilidx');
		loadPromptMsg2('msg_title_notice', 'msg_contents_itemdrop', (function() {
			doProcess(sType, sDetail, '#myinfo-list', sIlIdx, 0, sPage);
		}));
	});
	/**********************
	 * 아이템 구매
	***********************/
	$(document).on('click', '#user-buylist .btnbuy', function() {
		// 목록 갱신 관련
		var sType = $(this).attr('data-t'); var sPage = $(this).attr('data-p');

		// 목록 설정 관련
		var sDetail = $(this).attr('data-dt');
		var sUsrAuth = $(this).attr('data-aid');
		var sIlIdx = $(this).attr('data-ilidx');
		loadPromptMsg2('msg_title_notice', 'msg_contents_itembuy', (function() {
			doProcess(sType, sDetail, '#buy-list', sIlIdx, 0, sPage);
		}));
	});
	/**********************
	 * 관리 페이지
	***********************/
	/** 서브 메뉴 **/
	$(document).on('click', '#admin > .nav-add-menu > li', function() {
		var $getTarget = $(this).find('span');
		var $tgType = $getTarget.attr('data-t');
		loadList($tgType, '#admin-list', base_Url, 1);

		// 맨 처음 기본으로 들어갈 경우 '추가' 세부 페이지 생성
		var $detTarget = $('#admin-info');
		if ($tgType == 'itemlist') {
			// '아이템 추가'
			$detTarget.css('display', 'block');
			makeDetInfo('itemlist', 'add-item', '#admin-info');
		}
		else if ($tgType == 'itemcglist') {
			// '아이템 종류 추가'
			$detTarget.css('display', 'block');
			makeDetInfo('itemcglist', 'add-itemcg', '#admin-info');
		}
		else if ($tgType == 'envlist') {
			// 'ENV 추가'
			$detTarget.css('display', 'block');
			makeDetInfo('envlist', 'add-env', '#admin-info');
		}
		else {
			// 세부 페이지 초기화
			$detTarget.css('display', 'none');
			$detTarget.html('');
		}
	});
	/** '유저 관리'에서 유저 정보를 수정할 때 **/
	$(document).on('click', '#admin-userlist .btn_usrmodify', function() {
		var $mtable = $(this); // 선택 칼럼
		var $mtarget; // 금액 칼럼

		// 목록 설정 관련
		var sType = $(this).attr('data-t'); var sDetail = $(this).attr('data-dt');
		var usrIdx = $mtable.attr('data-uidx'); var sPage = $(this).attr('data-p');

		// 참조 자료
		var usrMoney = '';

		// 위치 획득
		$('.usrmoney').each(function() {
			if ($(this).attr('data-uidx') == usrIdx) {
				$mtarget = $(this);
			}
		});

		// 행동 구분
		loadTransMsg('btn_done', function(done_output)
		{
			if ($mtable.html() == done_output)
			{
				// 입력한 금액 파악
				var modmoney = $mtarget.find('input').val();

				// 태그 정보 수정
				loadTransMsg('btn_modify', function(mod_output) {
					$mtable.html(mod_output);
					$mtarget.html(modmoney);
				});
				doProcess(sType, sDetail, '', usrIdx, modmoney, sPage);
			}
			else
			{
				// 있던 금액 파악 후 입력 가능하게 변경
				usrMoney = $mtarget.html();
				$mtarget.html('<input class="input-line x-short" type="text" onkeypress="" value="' + usrMoney + '">');
			
				$mtable.html(done_output);
			}
		});
	});
	/** '아이템 관리'에서 아이템 정보를 수정할 때 **/
	$(document).on('click', '#admin-itemlist .btn_itemmodify', function() {
		var $mtable = $(this); // 선택 칼럼

		// 목록 설정 관련
		var sType = $(this).attr('data-t'); var sDetail = $(this).attr('data-dt');
		var ilIdx = $mtable.attr('data-ilidx'); var sPage = $(this).attr('data-p');

		makeDetInfo('itemlist', 'modify-item', '#admin-info', ilIdx);
	});
	/** '아이템 관리'에서 아이템 정보를 삭제할 때 **/
	$(document).on('click', '#admin-itemlist .btn_itemdelete', function() {
		var $mtable = $(this); // 선택 칼럼

		// 목록 설정 관련
		var sType = $(this).attr('data-t'); var sDetail = $(this).attr('data-dt');
		var ilIdx = $mtable.attr('data-ilidx'); var sPage = $(this).attr('data-p');

		loadPromptMsg2('msg_title_notice', 'msg_contents_itemdelete', (function() {
			doProcess(sType, sDetail, '#admin-list', ilIdx, 0, sPage);
		}));
	});
	/** '아이템 종류 관리'에서 아이템 종류 정보를 수정할 때 **/
	$(document).on('click', '#admin-itemcglist .btn_itemcgmodify', function() {
		var $mtable = $(this); // 선택 칼럼

		// 목록 설정 관련
		var sType = $(this).attr('data-t'); var sDetail = $(this).attr('data-dt');
		var icIdx = $mtable.attr('data-icidx'); var sPage = $(this).attr('data-p');

		makeDetInfo('itemcglist', 'modify-itemcg', '#admin-info', icIdx);
	});
	/** '아이템 종류 관리'에서 아이템 종류 정보를 삭제할 때 **/
	$(document).on('click', '#admin-itemcglist .btn_itemcgdelete', function() {
		var $mtable = $(this); // 선택 칼럼

		// 목록 설정 관련
		var sType = $(this).attr('data-t'); var sDetail = $(this).attr('data-dt');
		var icIdx = $mtable.attr('data-icidx'); var sPage = $(this).attr('data-p');

		loadPromptMsg2('msg_title_notice', 'msg_contents_itemcgdelete', (function() {
			doProcess(sType, sDetail, '#admin-list', icIdx, 0, sPage);
		}));
	});
	/** 'ENV 관리'에서 ENV 정보를 수정할 때 **/
	$(document).on('click', '#admin-envlist .btn_envmodify', function() {
		var $mtable = $(this); // 선택 칼럼

		// 목록 설정 관련
		var sType = $(this).attr('data-t'); var sDetail = $(this).attr('data-dt');
		var eIdx = $mtable.attr('data-eidx'); var sPage = $(this).attr('data-p');

		makeDetInfo('envlist', 'modify-env', '#admin-info', eIdx);
	});
	/** 'ENV 관리'에서 ENV 정보를 삭제할 때 **/
	$(document).on('click', '#admin-envlist .btn_envdelete', function() {
		var $mtable = $(this); // 선택 칼럼

		// 목록 설정 관련
		var sType = $(this).attr('data-t'); var sDetail = $(this).attr('data-dt');
		var eIdx = $mtable.attr('data-eidx'); var sPage = $(this).attr('data-p');

		loadPromptMsg2('msg_title_notice', 'msg_contents_envdelete', (function() {
			doProcess(sType, sDetail, '#admin-list', eIdx, 0, sPage);
		}));
	});
	/**********************
	 * 관리 페이지 - 세부
	***********************/
	/** [아이템 추가] 아이템 이름 입력 폼 추가 **/
	$(document).on('click', '#iladd-namesec #btn_langadd', function() {
		// 설정 준비
		var $ntarget = $('#iladd-namesec');
		var coutput = '';

		// 기존 대상
		var $prvTarget = $('.addname');

		// 데이터 처리 번호 파악
		var prvNum = 0;
		$prvTarget.each(function() {
			prvNum = $(this).attr('data-num');
		});

		// 입력 폼 생성
		loadTransMsg('btn_langdelete', function(del_output) {
			coutput += '<div class="addname" data-num="' + (Number(prvNum) + 1) + '">';
			coutput += '<input name="iladd-langname" class="input-line xx-short" type="text" maxlength="2" value="" />';
			coutput += '<input name="iladd-name" class="input-line short" type="text" maxlength="30" />';
			coutput += '<button id="btn_langdelete" name="iladd-langdelete">';
			coutput += del_output;
			coutput += '</button>';
			coutput += '</div>';
			$ntarget.append(coutput);
		});
	});
	/** [아이템 추가] 아이템 이름 입력 폼 추가했던 것을 삭제 **/
	$(document).on('click', '.addname #btn_langdelete', function() {
		$(this).parent().remove();
	});
	/** [아이템 추가] 아이템 ENV 입력 폼 추가 **/
	$(document).on('click', '#iladd-envsec #btn_envadd', function() {
		// 설정 준비
		var $ntarget = $('#iladd-envsec');
		var coutput = '';

		// 기존 대상
		var $prvTarget = $('.addenv');

		// 데이터 처리 번호 파악
		var prvNum = 0;
		$prvTarget.each(function() {
			prvNum = $(this).attr('data-num');
		});

		// 입력 폼 생성
		loadTransMsg('btn_langdelete', function(del_output) {
			coutput += '<div class="addenv" data-num="' + (Number(prvNum) + 1) + '">';
			coutput += '<input name="iladd-env" class="input-line short" type="text" maxlength="40" />';
			coutput += '<input name="iladd-envvalue" class="input-line medium" type="text" maxlength="128" />';
			coutput += '<button id="btn_envdelete" name="iladd-envdelete">';
			coutput += del_output;
			coutput += '</button>';
			coutput += '</div>';
			$ntarget.append(coutput);
		});
	});
	/** [아이템 추가] 아이템 ENV 입력 폼 추가했던 것을 삭제 **/
	$(document).on('click', '.addenv #btn_envdelete', function() {
		// 상위 부모로부터 제거
		$(this).parent().remove();
	});
	/** [아이템 추가] 정보 전송 **/
	$(document).on('click', '#admin-info #btn_additem', function() {
		var $il = $(this).parent();
		var $il_code = $il.find('input[name="iladd-code"]').val();
		var $il_name = '';
		$il.find('.addname').each(function() {
			// 언어와 이름 파악
			var $setLang = $(this).find('input[name="iladd-langname"]').val();
			var $setName = $(this).find('input[name="iladd-name"]').val();

			// 언어 공백은 없애준다.
			$setLang.replace(/\s/gi, '');

			// 언어 또는 이름이 비어있으면 패스
			if ($setLang == '') {return true;}
			if ($setName == '') {return true;}

			// 이미 무언가 추가되어 있는 경우 라인컷 삽입
			if ($il_name != '') {$il_name += '||';}

			// 밸류컷으로 넣어준다.
			$il_name += $setLang;
			$il_name += ':';
			$il_name += $setName;
		});
		var $il_money = $il.find('input[name="iladd-money"]').val();
		var $il_havtime = $il.find('input[name="iladd-havtime"]').val();
		var $il_env = '';
		$il.find('.addenv').each(function() {
			// ENV 이름과 값 파악
			var $setEnv = $(this).find('input[name="iladd-env"]').val();
			var $setEnvVal = $(this).find('input[name="iladd-envvalue"]').val();

			// ENV 이름의 공백을 없애준다.
			$setEnv.replace(/\s/gi, '');

			// ENV 이름이 비어있으면 패스
			if ($setEnv == '') {return true;}

			// 이미 무언가 추가되어 있는 경우 라인컷 삽입
			if ($il_env != '') {$il_env += '||';}

			// 밸류컷으로 넣어준다.
			$il_env += $setEnv;
			$il_env += ':';
			$il_env += $setEnvVal;
		});
		var $il_status = $il.find('input[name="iladd-status"]:checked').val();
		var il_send = new Array($il_code, $il_name, $il_money, $il_havtime, $il_env, $il_status);
		setDetInfo('itemlist', 'additem', '#admin-list', il_send);
	});
	/** [아이템 수정] 정보 전송 **/
	$(document).on('click', '#admin-info #btn_modifyitem', function() {
		var $il = $(this).parent();
		var $il_code = $il.find('input[name="iladd-code"]').val();
		var $il_name = '';
		$il.find('.addname').each(function() {
			// 언어와 이름 파악
			var $setLang = $(this).find('input[name="iladd-langname"]').val();
			var $setName = $(this).find('input[name="iladd-name"]').val();

			// 언어 공백은 없애준다.
			$setLang.replace(/\s/gi, '');

			// 언어 또는 이름이 비어있으면 패스
			if ($setLang == '') {return true;}
			if ($setName == '') {return true;}

			// 이미 무언가 추가되어 있는 경우 라인컷 삽입
			if ($il_name != '') {$il_name += '||';}

			// 밸류컷으로 넣어준다.
			$il_name += $setLang;
			$il_name += ':';
			$il_name += $setName;
		});
		var $il_money = $il.find('input[name="iladd-money"]').val();
		var $il_havtime = $il.find('input[name="iladd-havtime"]').val();
		var $il_env = '';
		$il.find('.addenv').each(function() {
			// ENV 이름과 값 파악
			var $setEnv = $(this).find('input[name="iladd-env"]').val();
			var $setEnvVal = $(this).find('input[name="iladd-envvalue"]').val();

			// ENV 이름의 공백을 없애준다.
			$setEnv.replace(/\s/gi, '');

			// ENV 이름이 비어있으면 패스
			if ($setEnv == '') {return true;}

			// 이미 무언가 추가되어 있는 경우 라인컷 삽입
			if ($il_env != '') {$il_env += '||';}

			// 밸류컷으로 넣어준다.
			$il_env += $setEnv;
			$il_env += ':';
			$il_env += $setEnvVal;
		});
		var $il_status = $il.find('input[name="iladd-status"]:checked').val();
		var $il_hidden = $il.find('input[name="iladd-hidden"]').val();
		var il_send = new Array($il_code, $il_name, $il_money, $il_havtime, $il_env, $il_status, $il_hidden);
		setDetInfo('itemlist', 'modifyitem', '#admin-list', il_send);
	});

	$(document).on('click', '#icadd-namesec #btn_langadd', function() {
		var $ntarget = $('#icadd-namesec');
		var coutput = '';

		var $prvTarget = $('.addname');
		var prvNum = 0;
		$prvTarget.each(function() {
			prvNum = $(this).attr('data-num');
		});
		loadTransMsg('btn_langdelete', function(del_output) {
			coutput += '<div class="addname" data-num="' + (Number(prvNum) + 1) + '">';
			coutput += '<input name="icadd-langname" class="input-line xx-short" type="text" maxlength="2" value="" />';
			coutput += '<input name="icadd-name" class="input-line short" type="text" maxlength="30" />';
			coutput += '<button id="btn_langdelete" name="icadd-langdelete">';
			coutput += del_output;
			coutput += '</button>';
			coutput += '</div>';
			$ntarget.append(coutput);
		});
	});
	/** [아이템 종류 추가] 아이템 종류 이름 입력 폼 추가했던 것을 삭제 **/
	$(document).on('click', '.addname #btn_langdelete', function() {
		$(this).parent().remove();
	});
	$(document).on('click', '#icadd-envsec #btn_envadd', function() {
		var $ntarget = $('#icadd-envsec');
		var coutput = '';

		var $prvTarget = $('.addenv');
		var prvNum = 0;
		$prvTarget.each(function() {
			prvNum = $(this).attr('data-num');
		});
		loadTransMsg('btn_envdelete', function(del_output) {
			coutput += '<div class="addenv" data-num="' + (Number(prvNum) + 1) + '">';
			coutput += '<input name="icadd-env" class="input-line short" type="text" maxlength="40" />';
			coutput += '<input name="icadd-envvalue" class="input-line medium" type="text" maxlength="128" />';
			coutput += '<button id="btn_envdelete" name="icadd-envdelete">';
			coutput += del_output;
			coutput += '</button>';
			coutput += '</div>';
			$ntarget.append(coutput);
		});
	});
	/** [아이템 종류 추가] 아이템 종류 ENV 입력 폼 추가했던 것을 삭제 **/
	$(document).on('click', '.addenv #btn_envdelete', function() {
		$(this).parent().remove();
	});
	/** [아이템 종류 추가] 정보 전송 **/
	$(document).on('click', '#admin-info #btn_additemcg', function() {
		var $ic = $(this).parent();
		var $ic_name = '';
		$ic.find('.addname').each(function() {
			// 언어와 이름 파악
			var $setLang = $(this).find('input[name="icadd-langname"]').val();
			var $setName = $(this).find('input[name="icadd-name"]').val();

			// 언어 공백은 없애준다.
			$setLang.replace(/\s/gi, '');

			// 언어 또는 이름이 비어있으면 패스
			if ($setLang == '') {return true;}
			if ($setName == '') {return true;}

			// 이미 무언가 추가되어 있는 경우 라인컷 삽입
			if ($ic_name != '') {$ic_name += '||';}

			// 밸류컷으로 넣어준다.
			$ic_name += $setLang;
			$ic_name += ':';
			$ic_name += $setName;
		});
		var $ic_orderidx = $ic.find('input[name="icadd-orderidx"]').val();
		var $ic_env = '';
		$ic.find('.addenv').each(function() {
			var $setEnv = $(this).find('input[name="icadd-env"]').val();
			var $setEnvVal = $(this).find('input[name="icadd-envvalue"]').val();

			// ENV 이름의 공백을 없애준다.
			$setEnv.replace(/\s/gi, '');

			// ENV 이름이 비어있으면 패스
			if ($setEnv == '') {return true;}

			// 이미 무언가 추가되어 있는 경우 라인컷 삽입
			if ($ic_env != '') {$ic_env += '||';}

			// 밸류컷으로 넣어준다.
			$ic_env += $setEnv;
			$ic_env += ':';
			$ic_env += $setEnvVal;
		});
		var $ic_status = $ic.find('input[name="icadd-status"]:checked').val();
		var ic_send = new Array($ic_name, $ic_orderidx, $ic_env, $ic_status);
		setDetInfo('itemcglist', 'additemcg', '#admin-list', ic_send);
	});
	/** [아이템 종류 수정] 정보 전송 **/
	$(document).on('click', '#admin-info #btn_modifyitemcg', function() {
		var $ic = $(this).parent();
		var $ic_name = '';
		$ic.find('.addname').each(function() {
			// 언어와 이름 파악
			var $setLang = $(this).find('input[name="icadd-langname"]').val();
			var $setName = $(this).find('input[name="icadd-name"]').val();

			// 언어 공백은 없애준다.
			$setLang.replace(/\s/gi, '');

			// 언어 또는 이름이 비어있으면 패스
			if ($setLang == '') {return true;}
			if ($setName == '') {return true;}

			// 이미 무언가 추가되어 있는 경우 라인컷 삽입
			if ($ic_name != '') {$ic_name += '||';}

			// 밸류컷으로 넣어준다.
			$ic_name += $setLang;
			$ic_name += ':';
			$ic_name += $setName;
		});
		var $ic_orderidx = $ic.find('input[name="icadd-orderidx"]').val();
		var $ic_env = '';
		$ic.find('.addenv').each(function() {
			var $setEnv = $(this).find('input[name="icadd-env"]').val();
			var $setEnvVal = $(this).find('input[name="icadd-envvalue"]').val();

			// ENV 이름의 공백을 없애준다.
			$setEnv.replace(/\s/gi, '');

			// ENV 이름이 비어있으면 패스
			if ($setEnv == '') {return true;}

			// 이미 무언가 추가되어 있는 경우 라인컷 삽입
			if ($ic_env != '') {$ic_env += '||';}

			// 밸류컷으로 넣어준다.
			$ic_env += $setEnv;
			$ic_env += ':';
			$ic_env += $setEnvVal;
		});
		var $ic_status = $ic.find('input[name="icadd-status"]:checked').val();
		var $ic_hidden = $ic.find('input[name="icadd-hidden"]').val();
		var ic_send = new Array($ic_name, $ic_orderidx, $ic_env, $ic_status, $ic_hidden);
		setDetInfo('itemcglist', 'modifyitemcg', '#admin-list', ic_send);
	});
	/** [ENV 추가] 정보 전송 **/
	$(document).on('click', '#admin-info #btn_addenv', function() {
		var $env = $(this).parent();
		var $env_onecate = $env.find('input[name="envadd-onecate"]').val();
		var $env_twocate = $env.find('input[name="envadd-twocate"]').val();
		var $env_setdata = $env.find('input[name="envadd-setdata"]').val();
		var $env_desc = $env.find('textarea').val();

		// '종류', '이름' 공백은 없애준다.
		$env_onecate.replace(/\s/gi, '');
		$env_twocate.replace(/\s/gi, '');

		var env_send = new Array($env_onecate, $env_twocate, $env_setdata, $env_desc);
		setDetInfo('envlist', 'addenv', '#admin-list', env_send);
	});
	/** [ENV 수정] 정보 전송 **/
	$(document).on('click', '#admin-info #btn_modifyenv', function() {
		var $env = $(this).parent();
		var $env_onecate = $env.find('input[name="envadd-onecate"]').val();
		var $env_twocate = $env.find('input[name="envadd-twocate"]').val();
		var $env_setdata = $env.find('input[name="envadd-setdata"]').val();
		var $env_desc = $env.find('textarea').val();

		// '종류', '이름' 공백은 없애준다.
		$env_onecate.replace(/\s/gi, '');
		$env_twocate.replace(/\s/gi, '');

		var $env_hidden = $env.find('input[name="envadd-hidden"]').val();
		var env_send = new Array($env_onecate, $env_twocate, $env_setdata, $env_desc, $env_hidden);
		setDetInfo('envlist', 'modifyenv', '#admin-list', env_send);
	});
});