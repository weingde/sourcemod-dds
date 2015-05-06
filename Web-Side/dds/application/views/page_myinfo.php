        
        <section class="row">
            <article>
                <div id="myinfo" class="box">
                    <div class="box-title">
                        <i class="fa <? echo $icon; ?> fa-2x"></i><h1><? echo $title; ?></h1>
                    </div>
                    <div class="myinfo clearfix">
                        <img class="profileimg" class="<? echo $logstatus ? 'border-logon' : 'border-logoff' ?>" src="<? echo $profileimg; ?>" />
                        <ul>
                            <li class="name"><? echo $name; ?></li>
                            <li><label class="label-black"><? echo $langData->line('myinfo_profileadrs'); ?></label><a href="<? echo $profileurl; ?>" target="_blank"><? echo $profileurl; ?></a></li>
                            <li><label class="label-black"><? echo $langData->line('myinfo_authid'); ?></label><? echo $authid; ?></li>
                            <li><label class="label-black"><? echo $langData->line('myinfo_logstatus'); ?></label><span class="<? echo $logstatus ? 'color-logon' : 'color-logoff' ?>"><? echo $logstatus ? $langData->line('myinfo_logstatus_on') : $langData->line('myinfo_logstatus_off'); ?></span></li>
                            <li><label class="label-black"><? echo $langData->line('myinfo_lastlogin'); ?></label><? echo $lastlogoff; ?></li>
                        </ul>
                    </div>
                    <div class="box-sub-title">
                        <h1><? echo $langData->line('myinfo_haveinven'); ?></h1>
                    </div>
                    <div id="myinfo-list">
                    </div>
                </div>
            </article>
        </section>

        <script type="text/javascript">;$(function($){loadList('inven', '#myinfo-list');});</script>