<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8">
		<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
		
		<title><? echo PRODUCT_NAME; ?></title>
		
		<link rel="stylesheet" href="<? echo assets_url(); ?>css/bootstrap.min.css">
		<link rel="stylesheet" href="<? echo assets_url(); ?>css/main.css">

		<script type="text/javascript" src="<? echo assets_url(); ?>js/jquery-1.11.2.min.js"></script>
		<script type="text/javascript" src="<? echo assets_url(); ?>js/init.js"></script>
		<script type="text/javascript">init('<? echo base_url(); ?>');</script>
		<!--[if lt IE 9]>
			<script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
			<script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
		<![endif]-->
	</head>
	
	<body>
		<div class="container">
			<div class="page-header">
				<h1><? echo PRODUCT_NAME; ?></h1>
				<ul class="nav nav-pills">
					<li role="presentation"><a href="<? echo base_url(); ?>usrlist">유저 관리</a></li>
					<li role="presentation"><a href="<? echo base_url(); ?>classlist">등급 관리</a></li>
					<li role="presentation"><a href="<? echo base_url(); ?>envlist">ENV 관리</a></li>
					<li role="presentation"><a href="<? echo base_url(); ?>auth/logout">로그아웃</a></li>
				</ul>
			</div>

