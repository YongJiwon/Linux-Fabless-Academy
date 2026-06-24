verdiWindowResize -win $_Verdi_1 "830" "370" "900" "700"
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiWindowResize -win $_Verdi_1 "830" "370" "900" "700"
debImport "/home/pedu21/Workspace/test/d_ff.v" -path \
          {/home/pedu21/Workspace/test}
schCreateWindow -win $_nSchema1 -hierFlatten
verdiSetActWin -win $_nSchema_2
srcInvokeEuclide -win $_nTrace1
schSelectAll -win $_nSchema2
verdiDockWidgetSetCurTab -dock widgetDock_MTB_SOURCE_TAB_1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiDockWidgetSetCurTab -dock windowDock_nSchema_2
verdiSetActWin -win $_nSchema_2
srcHBSelect "d_ff" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
wvCreateWindow
verdiSetActWin -win $_nWave3
srcHBSelect "d_ff" -win $_nTrace1
srcHBSelect "d_ff" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "d_ff" -win $_nTrace1
schZoomIn -win $_nSchema2
verdiSetActWin -win $_nSchema_2
schZoomOut -win $_nSchema2
srcHBSelect "d_ff" -win $_nTrace1
srcSetScope "d_ff" -delim "." -win $_nTrace1
srcHBSelect "d_ff" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "d_ff" -win $_nTrace1
debExit
