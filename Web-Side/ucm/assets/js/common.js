/**
 * 맛나는 쿠키 가져오기
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
 * 목록 가져오기
 *
 * @param stype				행동 타입
 * @param starget			목록 타겟
 * @param spage				페이지 번호
 */
function loadList(stype, starget, spage)
{
	var controller = 'clist';

	// 매개변수가 할당되어 있지 않을 때 처리
	spage = typeof spage !== 'undefined' ? spage : 1;

	// 실행
	$.ajax({
		url: base_Url + controller + '/getList',
		type: 'POST',
		data: {
			'ucm_t': getCookie('ucm_c'), 
			't': stype, 
			'p': spage
		},
		success: function(data) {
			if (data) {
				$(starget).html(data);
			}
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
function loadDetInfo(stype, sdetail, starget, sdata)
{
	var controller = 'clist';

	// 매개변수가 할당되어 있지 않을 때 처리
	sdata = typeof sdata !== 'undefined' ? sdata : 0;

	$.ajax({
		url: base_Url + controller + '/loadDetInfo',
		type: 'POST',
		data: {
			'ucm_t': getCookie('ucm_c'), 
			't': stype,
			'dt': sdetail,
			'dat': sdata
		},
		success: function(data) {
			$(starget).html(data).trigger("create");
		},
		error: function(req, status, error) {
			alert('오류가 발생했습니다.\n\n내용: ' + error);
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
	var controller = 'clist';

	//console.log(stype + ' / ' + sdetail + ' / ' + starget + ' / ' + sdata);

	$.ajax({
		url: base_Url + controller + '/setDetInfo',
		type: 'POST',
		data: {
			'ucm_t': getCookie('ucm_c'), 
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
					alert('성공!\n\n' + jdata.msg);
				} else {
					alert('오류가 발생했습니다.\n\n원인: json 객체가 아닙니다.');
				}
			} catch (e) {
				alert('오류가 발생했습니다.\n\n원인: ' + e + '\n' + '내용: ' + error);
			}
		},
		error: function(req, status, error) {
			alert('오류가 발생했습니다.\n\n내용: ' + error);
		}
	});
}

;$(function($) {
	// AUTHID 입력 시
	$('#authidkey').on('keyup', function() {
		var $authkey = $('#authidkey').val();
		var $passkey = $('#passkey').val();

		// 고유번호는 적어도 15글자, 비밀번호는 6글자 입력해야 함
		if ($authkey.length >= 15 && $passkey.length >= 6)
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
	// PASS 입력 시
	$('#passkey').on('keyup', function() {
		var $authkey = $('#authidkey').val();
		var $passkey = $('#passkey').val();

		// 고유번호는 적어도 15글자, 비밀번호는 6글자 입력해야 함
		if ($authkey.length >= 15 && $passkey.length >= 6)
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
	 * 목록 내 버튼
	***********************/
	$(document).on('click', '#class-list .btn_classmodify', function() {
		var $tcol = $(this);

		var sType = $tcol.attr('data-t'); var sDetail = $tcol.attr('data-dt');
		var sClIdx = $tcol.attr('data-clidx'); var sPage = $tcol.attr('data-p');

		loadDetInfo(sType, sDetail, '#class-info', sClIdx);
	});
	$(document).on('click', '#class-list .btn_classdelete', function() {
		var $tcol = $(this);

		var sType = $tcol.attr('data-t'); var sDetail = $tcol.attr('data-dt');
		var sClIdx = $tcol.attr('data-clidx'); var sPage = $tcol.attr('data-p');

		// 
	});
	$(document).on('click', '#env-list .btn_envmodify', function() {
		var $tcol = $(this);

		var sType = $tcol.attr('data-t'); var sDetail = $tcol.attr('data-dt');
		var sEIdx = $tcol.attr('data-eidx'); var sPage = $tcol.attr('data-p');

		loadDetInfo(sType, sDetail, '#env-info', sEIdx);
	});
	$(document).on('click', '#env-list .btn_envdelete', function() {
		var $tcol = $(this);

		var sType = $tcol.attr('data-t'); var sDetail = $tcol.attr('data-dt');
		var sEIdx = $tcol.attr('data-eidx'); var sPage = $tcol.attr('data-p');

		// 
	});

	/**********************
	 * 세부 정보 내 처리
	***********************/
	/** [아이템 추가] 아이템 이름 입력 폼 추가 **/
	$(document).on('click', '#class-info #btn_langadd', function() {
		// 설정 준비
		var $ntarget = $('#cladd-namesec');
		var coutput = '';

		// 기존 대상
		var $prvTarget = $('.addname');

		// 데이터 처리 번호 파악
		var prvNum = 0;
		$prvTarget.each(function() {
			prvNum = $(this).attr('data-num');
		});

		// 입력 폼 생성
		coutput += '<div class="addname" data-num="' + (Number(prvNum) + 1) + '">';
		coutput += '<div class="col-xs-1">';
		coutput += '<input name="cladd-langname" class="form-control" type="text" maxlength="2" value="" />';
		coutput += '</div>';
		coutput += '<div class="col-xs-3">';
		coutput += '<input name="cladd-name" class="form-control" type="text" maxlength="30" />';
		coutput += '</div>';
		coutput += '<button id="btn_langdelete" class="btn btn-default" name="cladd-langdelete">언어 삭제</button>';
		coutput += '</div>';
		$ntarget.append(coutput);
	});
	/** [아이템 추가] 아이템 이름 입력 폼 추가했던 것을 삭제 **/
	$(document).on('click', '.addname #btn_langdelete', function() {
		$(this).parent().remove();
	});
	/** [아이템 추가] 아이템 ENV 입력 폼 추가 **/
	$(document).on('click', '#class-info #btn_envadd', function() {
		// 설정 준비
		var $ntarget = $('#cladd-envsec');
		var coutput = '';

		// 기존 대상
		var $prvTarget = $('.addenv');

		// 데이터 처리 번호 파악
		var prvNum = 0;
		$prvTarget.each(function() {
			prvNum = $(this).attr('data-num');
		});

		// 입력 폼 생성
		coutput += '<div class="addenv" data-num="' + (Number(prvNum) + 1) + '">';
		coutput += '<div class="col-xs-3">';
		coutput += '<input name="cladd-env" class="form-control" type="text" maxlength="40" />';
		coutput += '</div>';
		coutput += '<div class="col-xs-5">';
		coutput += '<input name="cladd-envvalue" class="form-control" type="text" maxlength="128" />';
		coutput += '</div>';
		coutput += '<button id="btn_envdelete" class="btn btn-default" name="cladd-envdelete">ENV 삭제</button>';
		coutput += '</div>';
		$ntarget.append(coutput);
	});
	/** [아이템 추가] 아이템 ENV 입력 폼 추가했던 것을 삭제 **/
	$(document).on('click', '.addenv #btn_envdelete', function() {
		// 상위 부모로부터 제거
		$(this).parent().remove();
	});

	/** '유저 관리'에서 유저 정보를 수정할 때 **/
	$(document).on('click', '#user-list .btn_usrmodify', function() {
		var $ctable = $(this); // 선택 칼럼
		var $ctarget; // 등급 칼럼

		// 목록 설정 관련
		var sType = $(this).attr('data-t'); var sDetail = $(this).attr('data-dt');
		var usrIdx = $ctable.attr('data-uidx'); var sPage = $(this).attr('data-p');

		// 참조 자료
		var usrClass = '';

		// 위치 획득
		$('.usrclidx').each(function() {
			if ($(this).attr('data-uidx') == usrIdx) {
				$ctarget = $(this);
			}
		});

		// 행동 구분
		if ($ctable.html() == '완료')
		{
			// 입력한 등급 파악
			var modclass = $ctarget.find('input').val();

			// 태그 정보 수정
			$ctable.html('수정');
			$ctarget.html(modclass);
			//doProcess(sType, sDetail, '', usrIdx, modclass, sPage);
		}
		else
		{
			// 있던 금액 파악 후 입력 가능하게 변경
			usrClass = $ctarget.html();
			$ctarget.html('<input class="input-line xx-short" type="text" value="' + usrClass + '">');
			
			$ctable.html('완료');
		}
	});

	/** [등급 추가] 정보 전송 **/
	$(document).on('click', '#class-info #btn_addclass', function() {
		var $cl = $(this).parent().parent();
		var $cl_name = '';
		$cl.find('.addname').each(function() {
			// 언어와 이름 파악
			var $setLang = $(this).find('input[name="cladd-langname"]').val();
			var $setName = $(this).find('input[name="cladd-name"]').val();

			// 언어 공백은 없애준다.
			$setLang.replace(/\s/gi, '');

			// 언어 또는 이름이 비어있으면 패스
			if ($setLang == '') {return true;}
			if ($setName == '') {return true;}

			// 이미 무언가 추가되어 있는 경우 라인컷 삽입
			if ($cl_name != '') {$cl_name += '||';}

			// 밸류컷으로 넣어준다.
			$cl_name += $setLang;
			$cl_name += ':';
			$cl_name += $setName;
		});
		var $cl_orderidx = $cl.find('input[name="cladd-orderidx"]').val();
		var $cl_env = '';
		$cl.find('.addenv').each(function() {
			var $setEnv = $(this).find('input[name="cladd-env"]').val();
			var $setEnvVal = $(this).find('input[name="cladd-envvalue"]').val();

			// ENV 이름의 공백을 없애준다.
			$setEnv.replace(/\s/gi, '');

			// ENV 이름이 비어있으면 패스
			if ($setEnv == '') {return true;}

			// 이미 무언가 추가되어 있는 경우 라인컷 삽입
			if ($cl_env != '') {$cl_env += '||';}

			// 밸류컷으로 넣어준다.
			$cl_env += $setEnv;
			$cl_env += ':';
			$cl_env += $setEnvVal;
		});
		var $cl_status = $cl.find('input[name="cladd-status"]:checked').val();
		var cl_send = new Array($cl_name, $cl_orderidx, $cl_env, $cl_status);
		setDetInfo('classlist', 'addclass', '#class-list', cl_send);
	});
	/** [등급 수정] 정보 전송 **/
	$(document).on('click', '#class-info #btn_modifyclass', function() {
		var $cl = $(this).parent().parent();
		var $cl_name = '';
		$cl.find('.addname').each(function() {
			// 언어와 이름 파악
			var $setLang = $(this).find('input[name="cladd-langname"]').val();
			var $setName = $(this).find('input[name="cladd-name"]').val();

			// 언어 공백은 없애준다.
			$setLang.replace(/\s/gi, '');

			// 언어 또는 이름이 비어있으면 패스
			if ($setLang == '') {return true;}
			if ($setName == '') {return true;}

			// 이미 무언가 추가되어 있는 경우 라인컷 삽입
			if ($cl_name != '') {$cl_name += '||';}

			// 밸류컷으로 넣어준다.
			$cl_name += $setLang;
			$cl_name += ':';
			$cl_name += $setName;
		});
		var $cl_orderidx = $cl.find('input[name="cladd-orderidx"]').val();
		var $cl_env = '';
		$cl.find('.addenv').each(function() {
			var $setEnv = $(this).find('input[name="cladd-env"]').val();
			var $setEnvVal = $(this).find('input[name="cladd-envvalue"]').val();

			// ENV 이름의 공백을 없애준다.
			$setEnv.replace(/\s/gi, '');

			// ENV 이름이 비어있으면 패스
			if ($setEnv == '') {return true;}

			// 이미 무언가 추가되어 있는 경우 라인컷 삽입
			if ($cl_env != '') {$cl_env += '||';}

			// 밸류컷으로 넣어준다.
			$cl_env += $setEnv;
			$cl_env += ':';
			$cl_env += $setEnvVal;
		});
		var $cl_status = $cl.find('input[name="cladd-status"]:checked').val();
		var $cl_hidden = $cl.find('input[name="cladd-hidden"]').val();
		var cl_send = new Array($cl_name, $cl_orderidx, $cl_env, $cl_status, $cl_hidden);
		setDetInfo('classlist', 'modifyclass', '#class-list', cl_send);
	});
	/** [ENV 추가] 정보 전송 **/
	$(document).on('click', '#env-info #btn_addenv', function() {
		var $env = $(this).parent().parent();
		var $env_onecate = $env.find('input[name="envadd-onecate"]').val();
		var $env_twocate = $env.find('input[name="envadd-twocate"]').val();
		var $env_setdata = $env.find('input[name="envadd-setdata"]').val();
		var $env_desc = $env.find('textarea').val();

		// '종류', '이름' 공백은 없애준다.
		$env_onecate.replace(/\s/gi, '');
		$env_twocate.replace(/\s/gi, '');

		var env_send = new Array($env_onecate, $env_twocate, $env_setdata, $env_desc);
		setDetInfo('envlist', 'addenv', '#env-list', env_send);
	});
	/** [ENV 수정] 정보 전송 **/
	$(document).on('click', '#env-info #btn_modifyenv', function() {
		var $env = $(this).parent().parent();
		var $env_onecate = $env.find('input[name="envadd-onecate"]').val();
		var $env_twocate = $env.find('input[name="envadd-twocate"]').val();
		var $env_setdata = $env.find('input[name="envadd-setdata"]').val();
		var $env_desc = $env.find('textarea').val();

		// '종류', '이름' 공백은 없애준다.
		$env_onecate.replace(/\s/gi, '');
		$env_twocate.replace(/\s/gi, '');

		var $env_hidden = $env.find('input[name="envadd-hidden"]').val();
		var env_send = new Array($env_onecate, $env_twocate, $env_setdata, $env_desc, $env_hidden);
		setDetInfo('envlist', 'modifyenv', '#env-list', env_send);
	});
});