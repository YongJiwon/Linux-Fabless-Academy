verdiSetActWin -dock widgetDock_<Message>
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiWindowResize -win $_Verdi_1 "716" "358" "900" "700"
viaCreateLogViewer
verdiSetActWin -win $_SmartLog_2
viaLogViewerOpenLog -file {/home/pedu21/Workspace/20260604_ram/vcs.log} -hyperRuleFile {/tools/synopsys/verdi/X-2025.06-1/share/VIA/Apps/PredefinedRules/Generic_rule.rc} -parRuleFile {} -window "$_SmartLog_2"
verdiWindowResize -win $_Verdi_1 "1" "31" "1414" "1360"
debImport "/home/pedu21/Workspace/20260604_ram/tb_fifo_sv.sv" \
          "/home/pedu21/Workspace/20260604_ram/fifo_sv.sv" \
          "/home/pedu21/Workspace/20260604_ram/ram_ip.sv" "-sv" -path \
          {/home/pedu21/Workspace/20260604_ram}
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiOneSearch -tab "GUI Content"
verdiOneSearch -tab "Menu Command"
verdiSetActWin -win $_OneSearch
verdiOneSearch -tab "GUI Content"
verdiOneSearch -tab "DB/Log/Doc"
verdiDockWidgetSetCurTab -dock widgetDock_<Message>
verdiSetActWin -dock widgetDock_<Message>
viaCreateLogViewer
verdiFindBar -show -win SmartLog_3
verdiSetActWin -win $_SmartLog_3
viaLogViewerOpenLog -file {/home/pedu21/Workspace/20260604_ram/vcs.log} -hyperRuleFile {/tools/synopsys/verdi/X-2025.06-1/share/VIA/Apps/PredefinedRules/Generic_rule.rc} -parRuleFile {} -window "$_SmartLog_3"
wvCreateWindow
verdiSetActWin -win $_nWave4
verdiDockWidgetSetCurTab -dock windowDock_nWave_4
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiSetActWin -win $_nWave4
verdiDockWidgetSetCurTab -dock windowDock_nWave_4
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiDockWidgetSetCurTab -dock windowDock_SmartLog_3
verdiSetActWin -win $_SmartLog_3
verdiDockWidgetSetCurTab -dock windowDock_nWave_4
verdiSetActWin -win $_nWave4
wvSetPosition -win $_nWave4 {("G1" 0)}
wvOpenFile -win $_nWave4 {/home/pedu21/Workspace/20260604_ram/tb_fifo_sv.fsdb}
wvGetSignalOpen -win $_nWave4
wvGetSignalSetScope -win $_nWave4 "/tb_fifo_sv"
wvGetSignalSetScope -win $_nWave4 "/tb_fifo_sv/dut"
wvGetSignalSetScope -win $_nWave4 "/tb_fifo_sv/ram_if"
wvSetPosition -win $_nWave4 {("G1" 6)}
wvSetPosition -win $_nWave4 {("G1" 6)}
wvAddSignal -win $_nWave4 -clear
wvAddSignal -win $_nWave4 -group {"G1" \
{/tb_fifo_sv/ram_if/addr\[7:0\]} -height 16 \
{/tb_fifo_sv/ram_if/clk} -height 16 \
{/tb_fifo_sv/ram_if/rdata\[7:0\]} -height 16 \
{/tb_fifo_sv/ram_if/rst_n} -height 16 \
{/tb_fifo_sv/ram_if/wdata\[7:0\]} -height 16 \
{/tb_fifo_sv/ram_if/we} -height 16 \
}
wvAddSignal -win $_nWave4 -group {"G2" \
}
wvSelectSignal -win $_nWave4 {( "G1" 1 2 3 4 5 6 )} 
wvSetPosition -win $_nWave4 {("G1" 6)}
wvGetSignalClose -win $_nWave4
wvSetCursor -win $_nWave4 4792.478577 -snap {("G2" 0)}
wvSelectSignal -win $_nWave4 {( "G1" 6 )} 
wvSelectSignal -win $_nWave4 {( "G1" 3 )} 
wvSelectSignal -win $_nWave4 {( "G1" 2 )} 
wvSelectSignal -win $_nWave4 {( "G1" 2 )} 
wvSetPosition -win $_nWave4 {("G1" 1)}
wvSetPosition -win $_nWave4 {("G1" 0)}
wvMoveSelected -win $_nWave4
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G1" 1)}
wvZoomAll -win $_nWave4
wvSelectSignal -win $_nWave4 {( "G1" 2 )} 
wvSelectSignal -win $_nWave4 {( "G1" 1 2 3 4 5 )} 
wvSelectGroup -win $_nWave4 {G2}
wvSelectGroup -win $_nWave4 {G2}
verdiDockWidgetSetCurTab -dock windowDock_SmartLog_3
verdiSetActWin -win $_SmartLog_3
verdiDockWidgetSetCurTab -dock windowDock_nWave_4
verdiSetActWin -win $_nWave4
wvScrollDown -win $_nWave4 0
wvScrollDown -win $_nWave4 0
wvScrollDown -win $_nWave4 0
wvScrollDown -win $_nWave4 0
wvScrollDown -win $_nWave4 0
wvScrollDown -win $_nWave4 0
wvScrollDown -win $_nWave4 0
wvScrollDown -win $_nWave4 0
wvScrollDown -win $_nWave4 0
wvScrollDown -win $_nWave4 0
wvScrollDown -win $_nWave4 0
wvScrollDown -win $_nWave4 0
debExit
