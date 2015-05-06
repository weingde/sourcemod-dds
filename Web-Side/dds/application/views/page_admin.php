
        <section class="row">
            <article>
                <div id="admin" class="box">
                    <div class="box-title">
                        <i class="fa <? echo $icon; ?> fa-2x"></i><h1 class="clearfix"><? echo $title; ?></h1>
                    </div>
                    <ul class="nav nav-add-menu">
                        <li><a href="#"><span data-t="usrlist" data-url="<? echo base_url(); ?>"><? echo $langData->line('admin_usrlist'); ?></span></a></li>
                        <li><a href="#"><span data-t="itemlist" data-url="<? echo base_url(); ?>"><? echo $langData->line('admin_itemlist'); ?></span></a></li>
                        <li><a href="#"><span data-t="itemcglist" data-url="<? echo base_url(); ?>"><? echo $langData->line('admin_itemcglist'); ?></span></a></li>
                        <li><a href="#"><span data-t="envlist" data-url="<? echo base_url(); ?>"><? echo $langData->line('admin_envlist'); ?></span></a></li>
                        <li><a href="#"><span data-t="dataloglist" data-url="<? echo base_url(); ?>"><? echo $langData->line('admin_dataloglist'); ?></span></a></li>
                    </ul>
                    <div id="admin-list">
                    </div>
                </div>

                <div id="admin-info" class="box">
                </div>
            </article>
        </section>

        <script type="text/javascript">;$(function($){loadList('usrlist','#admin-list');});</script>