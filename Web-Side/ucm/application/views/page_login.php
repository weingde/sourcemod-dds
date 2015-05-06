<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
        <!--meta name="viewport" content="width=device-width, initial-scale=1"-->
        <meta name="keywords" content="User Class Management">
        <meta name="author" content="Eakgnarok">
        
        <title><? echo PRODUCT_NAME; ?> :: 로그인</title>
        <link rel="stylesheet" href="<? echo assets_url(); ?>css/main.css">
    </head>
    
    <body>
        <div id="container">
            <div id="title" class="page-title">
                <h1><? echo PRODUCT_NAME; ?></h1>
            </div>
        
            <div id="login">
                <? echo $setform; ?>
            </div>
        
            <div id="copyright">Copyright (c) 2015 Eakgnarok All Rights Reserved</div>
        </div>
    </body>
</html>