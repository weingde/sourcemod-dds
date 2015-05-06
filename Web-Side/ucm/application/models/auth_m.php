<?php

class Auth_m extends CI_Model {
	
	function __construct()
	{
		parent::__construct();
	}

	function MakeSignin()
	{
		$rval = form_open('auth/login', '', array('gosign' => '1'));
		$rval .= '<p class="center">';
		$rval .= '<p><label for="idf">고유번호: </label>';
		$rval .= form_input(array('type' => 'text', 'name' => 'idf', 'id' => 'idf', 'maxlength' => '20', 'class' => 'input-line short')) . '</p>';
		$rval .= '<p><label for="passf">비밀번호: </label>';
		$rval .= form_input(array('type' => 'password', 'name' => 'passf', 'id' => 'passf', 'maxlength' => '30', 'class' => 'input-line short')) . '</p>';
		$rval .= '</p>';
		$rval .= form_input(array('type' => 'submit', 'name' => 'submit', 'id' => 'submit', 'value' => '확인'));
		$rval .= form_close();

		return $rval;
	}
}

?>