<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
        <!--meta name="viewport" content="width=device-width, initial-scale=1"-->
        <meta name="keywords" content="Dynamic Dollar Shop">
        <meta name="author" content="Eakgnarok">
        
        <title><? echo PRODUCT_NAME; ?> :: <? echo $langData->line('login_title'); ?></title>
        <link rel="stylesheet" href="<? echo assets_url(); ?>css/login.css">
        <link rel="shortcut icon" type="image/x-icon" href="<? echo images_url(); ?>favicon.ico">
    </head>
    
    <body>
        <div id="container">
            <div id="title" class="page-title">
                <h1><? echo PRODUCT_NAME; ?></h1>
            </div>
        
            <div id="login">
                <? echo $langData->line('login_index'); ?>
                <? echo $setform; ?>
            </div>
        
            <div id="copyright">Copyright (c) 2012-2015 Eakgnarok All Rights Reserved</div>
        </div>
    </body>
    <script type="text/javascript" src="<? echo assets_url(); ?>js/jquery-1.11.2.min.js"></script>
    <script type="text/javascript" src="<? echo assets_url(); ?>js/nprogress.js"></script>
    <script type="text/javascript" src="<? echo assets_url(); ?>js/common.js"></script>
</html>