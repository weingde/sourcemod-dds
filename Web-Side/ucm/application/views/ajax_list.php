<?php
/*****************************************
 * GET LIST BY POST (AJAX)
 * Eakgnarok
******************************************/
?>

<?php

if (isset($list)) {
    $count = 0;
?>
<? /** USER LIST **/ ?>
<? if (strcmp($type, 'usrlist') == 0): ?>
                    <table class="table table-striped table-bordered table-hover">
                        <thead>
                            <tr>
                                <td>번호</td>
                                <td>고유번호</td>
                                <td>이름</td>
                                <td>등급번호</td>
                                <td>가입날짜</td>
                                <td>최근접속날짜</td>
                                <td>누적시간</td>
                                <td>게임접속</td>
                                <td>선택</td>
                            </tr>
                        </thead>
                        <tbody>
<? foreach($list as $usrlist): ?>
<? $count++; ?>
                            <tr>
                                <td><? echo $usrlist['idx']; ?></td>
                                <td><? echo $usrlist['authid']; ?></td>
                                <td><? echo $usrlist['nickname']; ?></td>
                                <td class="usrclidx" data-uidx="<? echo $usrlist['idx']; ?>"><? echo $usrlist['clidx']; ?></td>
                                <td><? echo date("Y-m-d H:i:s", $usrlist['joindate']); ?></td>
                                <td><? echo date("Y-m-d H:i:s", $usrlist['recentdate']); ?></td>
                                <td><? echo date("H:i:s", $usrlist['stacktime']); ?></td>
                                <td><? echo str_replace(array(0, 1), array('X', 'O'), $usrlist['ingame']); ?></td>
                                <td><span class="btn_usrmodify" data-dt="modifyusr" data-t="<? echo $type; ?>" data-uidx="<? echo $usrlist['idx']; ?>" data-p="<? echo $pageIdx; ?>">수정</span></td>
                            </tr>
<? endforeach; ?>
<? if ($count == 0): ?>
                            <tr>
                                <td colspan="9">결과가 없습니다.</td>
                            </tr>
                        </tbody>
                    </table>
<? else: ?>
                        </tbody>
                    </table>
                    <div class="list-pagin">
                        <nav>
                            <ul class="pagination">
<? 
for ($i = 0; $i < $pageTotal; $i++)
{
    if ((($pageIdx - $pageSideCount) <= ($i + 1)) && (($pageIdx + $pageSideCount) >= ($i + 1)))
        if ($pageIdx == ($i + 1))
            echo '<li><a href="#" data-t="' . $type . '" data-tar=".usrlist" class="active">' . ($i + 1) .'</a></li>';
        else
            echo '<li><a href="#" data-t="' . $type . '" data-tar=".usrlist">' . ($i + 1) . '</a></li>';
}

?>
                            </ul>
                        </nav>
                    </div>
<? endif; ?>
<? /** CLASS LIST **/ ?>
<? elseif (strcmp($type, 'classlist') == 0): ?>
                    <table class="table table-striped table-bordered table-hover">
                        <thead>
                            <tr>
                                <td>번호</td>
                                <td>이름</td>
                                <td>우선순위</td>
                                <td>활성화</td>
                                <td>선택</td>
                            </tr>
                        </thead>
                        <tbody>
<? foreach($list as $classlist): ?>
<? $count++; ?>
                            <tr>
                                <td><? echo $classlist['clidx']; ?></td>
                                <td><? echo SplitStrByGeoName(GetCodeByLanguage('ko'), $classlist['gloname']); ?></td>
                                <td><? echo $classlist['orderidx']; ?></td>
                                <td><? echo str_replace(array(0, 1), array('X', 'O'), $classlist['status']); ?></td>
                                <td><span class="btn_classmodify" data-dt="modifyclass" data-t="<? echo $type; ?>" data-clidx="<? echo $classlist['clidx']; ?>" data-p="<? echo $pageIdx; ?>">수정</span><span class="btn_classdelete" data-dt="deleteclass" data-t="<? echo $type; ?>" data-clidx="<? echo $classlist['clidx']; ?>" data-p="<? echo $pageIdx; ?>">삭제</span></td>
                            </tr>
<? endforeach; ?>
<? if ($count == 0): ?>
                            <tr>
                                <td colspan="5">결과가 없습니다.</td>
                            </tr>
                        </tbody>
                    </table>
<? else: ?>
                        </tbody>
                    </table>
                    <div class="list-pagin">
                        <nav>
                            <ul class="pagination">
<? 
for ($i = 0; $i < $pageTotal; $i++)
{
    if ((($pageIdx - $pageSideCount) <= ($i + 1)) && (($pageIdx + $pageSideCount) >= ($i + 1)))
        if ($pageIdx == ($i + 1))
            echo '<li><a href="#" data-t="' . $type . '" data-tar=".classlist" class="active">' . ($i + 1) .'</a></li>';
        else
            echo '<li><a href="#" data-t="' . $type . '" data-tar=".classlist">' . ($i + 1) . '</a></li>';
}

?>
                            </ul>
                        </nav>
                    </div>
<? endif; ?>
<? /** ENV LIST **/ ?>
<? elseif (strcmp($type, 'envlist') == 0): ?>
                    <table class="table table-striped table-bordered table-hover">
                        <thead>
                            <tr>
                                <td>번호</td>
                                <td>종류</td>
                                <td>이름</td>
                                <td>값</td>
                                <td>선택</td>
                            </tr>
                        </thead>
                        <tbody>
<? foreach($list as $envlist): ?>
<? $count++; ?>
                            <tr>
                                <td><? echo $envlist['idx']; ?></td>
                                <td><? echo $envlist['onecate']; ?></td>
                                <td><? echo $envlist['twocate']; ?></td>
                                <td><? echo $envlist['setdata']; ?></td>
                                <td><span class="btn_envmodify" data-dt="modifyenv" data-t="<? echo $type; ?>" data-eidx="<? echo $envlist['idx']; ?>" data-p="<? echo $pageIdx; ?>">수정</span><span class="btn_classenv" data-dt="deleteenv" data-t="<? echo $type; ?>" data-eidx="<? echo $envlist['idx']; ?>" data-p="<? echo $pageIdx; ?>">삭제</span></td>
                            </tr>
<? endforeach; ?>
<? if ($count == 0): ?>
                            <tr>
                                <td colspan="5">결과가 없습니다.</td>
                            </tr>
                        </tbody>
                    </table>
<? else: ?>
                        </tbody>
                    </table>
                    <div class="list-pagin">
                        <nav>
                            <ul class="pagination">
<? 
for ($i = 0; $i < $pageTotal; $i++)
{
    if ((($pageIdx - $pageSideCount) <= ($i + 1)) && (($pageIdx + $pageSideCount) >= ($i + 1)))
        if ($pageIdx == ($i + 1))
            echo '<li><a href="#" data-t="' . $type . '" data-tar=".envlist" class="active">' . ($i + 1) .'</a></li>';
        else
            echo '<li><a href="#" data-t="' . $type . '" data-tar=".envlist">' . ($i + 1) . '</a></li>';
}

?>
                            </ul>
                        </nav>
                    </div>
<? endif; ?>
<? endif; ?>
<?php } ?>