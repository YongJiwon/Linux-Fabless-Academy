verdiWindowResize -win $_vdCoverage_1 "830" "370" "900" "700"
gui_set_pref_value -category {coveragesetting} -key {geninfodumping} -value 1
gui_exclusion -set_force true
verdiSetFont  -font  {DejaVu Sans}  -size  12
verdiSetFont -font "DejaVu Sans" -size "12"
gui_assert_mode -mode flat
gui_class_mode -mode hier
gui_excl_mgr_flat_list -on  0
gui_covdetail_select -id  CovDetail.1   -name   Line
verdiWindowWorkMode -win $_vdCoverage_1 -coverageAnalysis
verdiSetActWin -dock widgetDock_Message
verdiWindowResize -win $_vdCoverage_1 "830" "370" "1001" "710"
verdiSetActWin -dock widgetDock_<CovDetail>
verdiSetActWin -dock widgetDock_<Summary>
gui_open_cov  -hier simv.vdb -testdir  {simv.vdb coverage.vdb/snps/coverage coverage.vdb} -test { coverage/sim1 } -merge MergedTest -db_max_tests 10 -sdc_level 1 -fsm transition
gui_list_select -id CoverageTable.1 -list covtblInstancesList { uvm_custom_install_recording   }
gui_list_action -id  CoverageTable.1 -list {covtblInstancesList} uvm_custom_install_recording  -column {} 
gui_list_select -id CoverageTable.1 -list covtblInstancesList { uvm_custom_install_recording  tb_top   }
gui_list_expand -id  CoverageTable.1   -list {covtblInstancesList} tb_top
gui_list_expand -id CoverageTable.1   tb_top
gui_list_action -id  CoverageTable.1 -list {covtblInstancesList} tb_top  -column {} 
gui_list_select -id CoverageTable.1 -list covtblInstancesList { tb_top  uvm_custom_install_recording   }
gui_list_action -id  CoverageTable.1 -list {covtblInstancesList} uvm_custom_install_recording  -column {} 
gui_list_select -id CoverageTable.1 -list covtblInstancesList { uvm_custom_install_recording  uvm_custom_install_verdi_recording   }
gui_list_action -id  CoverageTable.1 -list {covtblInstancesList} uvm_custom_install_verdi_recording  -column {} 
gui_list_select -id CoverageTable.1 -list covtblInstancesList { uvm_custom_install_verdi_recording  tb_top.dut   }
gui_list_collapse -id  CoverageTable.1   -list {covtblInstancesList} tb_top
gui_covtable_show -show  { Function Groups } -id  CoverageTable.1  -test  MergedTest
gui_covtable_show -show  { Asserts } -id  CoverageTable.1  -test  MergedTest
gui_list_expand -id  CoverageTable.1   -list {covtblStatAssertInstList} Assertion
gui_list_expand -id  CoverageTable.1   -list {covtblStatAssertInstList} {Cover Property}
gui_list_expand -id  CoverageTable.1   -list {covtblStatAssertInstList} {Cover Sequence}
gui_list_expand -id  CoverageTable.1   -list {covtblStatAssertInstList} Total
gui_covtable_show -show  { Statistics } -id  CoverageTable.1  -test  MergedTest
gui_list_expand -id  CoverageTable.1   -list {covtblStatModuleList} Assert
gui_list_expand -id  CoverageTable.1   -list {covtblStatAssertDefList} Assertion
gui_list_expand -id  CoverageTable.1   -list {covtblStatAssertDefList} {Cover Property}
gui_list_expand -id  CoverageTable.1   -list {covtblStatAssertDefList} {Cover Sequence}
gui_list_expand -id  CoverageTable.1   -list {covtblStatAssertDefList} Total
verdiWindowResize -win $_vdCoverage_1 "830" "370" "1018" "710"
gui_covtable_show -show  { Asserts } -id  CoverageTable.1  -test  MergedTest
verdiWindowResize -win $_vdCoverage_1 "1255" "296" "1018" "710"
gui_list_select -id CoverageTable.1 -list covtblAssertList_flat { {/uvm_pkg.\uvm_reg_map::do_read .unnamed$$_0.unnamed$$_1}   }
gui_list_action -id  CoverageTable.1 -list {covtblAssertList_flat} {/uvm_pkg.\uvm_reg_map::do_read .unnamed$$_0.unnamed$$_1}  -column {Assert} 
gui_list_select -id CoverageTable.1 -list covtblAssertList_flat { {/uvm_pkg.\uvm_reg_map::do_read .unnamed$$_0.unnamed$$_1}  {/uvm_pkg.\uvm_reg_map::do_write .unnamed$$_0.unnamed$$_1}   }
gui_list_action -id  CoverageTable.1 -list {covtblAssertList_flat} {/uvm_pkg.\uvm_reg_map::do_write .unnamed$$_0.unnamed$$_1}  -column {Assert} 
gui_covtable_show -show  { Function Groups } -id  CoverageTable.1  -test  MergedTest
gui_list_select -id CoverageTable.1 -list covtblFGroupsList { /ram_pkg::ram_coverage::ram_cg   }
gui_list_expand -id  CoverageTable.1   -list {covtblFGroupsList} /ram_pkg::ram_coverage::ram_cg
gui_list_expand -id CoverageTable.1   /ram_pkg::ram_coverage::ram_cg
gui_list_action -id  CoverageTable.1 -list {covtblFGroupsList} /ram_pkg::ram_coverage::ram_cg  -column {} 
gui_list_select -id CoverageTable.1 -list covtblFGroupsList { /ram_pkg::ram_coverage::ram_cg  ram_pkg::ram_coverage::ram_cg.cp_addr   }
gui_list_action -id  CoverageTable.1 -list {covtblFGroupsList} ram_pkg::ram_coverage::ram_cg.cp_addr  -column {} 
gui_list_select -id CoverageTable.1 -list covtblFGroupsList { ram_pkg::ram_coverage::ram_cg.cp_addr  ram_pkg::ram_coverage::ram_cg.cp_op   }
gui_list_action -id  CoverageTable.1 -list {covtblFGroupsList} ram_pkg::ram_coverage::ram_cg.cp_op  -column {} 
gui_list_select -id CoverageTable.1 -list covtblFGroupsList { ram_pkg::ram_coverage::ram_cg.cp_op  ram_pkg::ram_coverage::ram_cg.cx_op_addr   }
gui_list_action -id  CoverageTable.1 -list {covtblFGroupsList} ram_pkg::ram_coverage::ram_cg.cx_op_addr  -column {} 
gui_list_select -id CoverageTable.1 -list covtblFGroupsList { ram_pkg::ram_coverage::ram_cg.cx_op_addr  /ram_pkg::ram_coverage::ram_cg/ram_pkg::ram_coverage::ram_cg.tb_top.me.obj.ram_cg   }
gui_list_expand -id  CoverageTable.1   -list {covtblFGroupsList} /ram_pkg::ram_coverage::ram_cg/ram_pkg::ram_coverage::ram_cg.tb_top.me.obj.ram_cg
gui_list_expand -id CoverageTable.1   /ram_pkg::ram_coverage::ram_cg/ram_pkg::ram_coverage::ram_cg.tb_top.me.obj.ram_cg
gui_list_action -id  CoverageTable.1 -list {covtblFGroupsList} /ram_pkg::ram_coverage::ram_cg/ram_pkg::ram_coverage::ram_cg.tb_top.me.obj.ram_cg  -column {} 
verdiWindowResize -win $_vdCoverage_1 "1255" "296" "1018" "710"
verdiWindowResize -win $_vdCoverage_1 "1281" "31" "1278" "1360"
gui_list_select -id CoverageTable.1 -list covtblFGroupsList { /ram_pkg::ram_coverage::ram_cg/ram_pkg::ram_coverage::ram_cg.tb_top.me.obj.ram_cg  ram_pkg::ram_coverage::ram_cg.cp_op   }
