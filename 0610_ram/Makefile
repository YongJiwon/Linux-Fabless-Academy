VCS_OPTS = -full64 -sverilog
VCS_OPTS += -ntb_opts uvm-1.2
VCS_OPTS += -timescale=1ns/10ps
VCS_OPTS += -debug_access+all -kdb -lca
VCS_OPTS += -cm line+cond+fsm+tgl+branch+assert
VCS_INCDIR = +incdir+tb +incdir+trl
VCS_OUTPUT = -o simv

VCS_SRC_FILES = ./tb/ram_pkg.sv ./rtl/ram.sv ./tb/ram_if.sv ./tb/tb_top.sv

TEST ?= ram_basic_test
SEED ?= 1
INFO_LEVEL ?= UVM_DEBUG

SIMV_OPTS =  +UVM_TESTNAME=$(TEST)
SIMV_OPTS +=  +UVM_VERBOSITY=$(INFO_LEVEL)
SIMV_OPTS +=  +ntb_random_seed=$(SEED)
SIMV_OPTS +=  -cm line+cond+fsm+tgl+branch+assert
SIMV_OPTS +=  -cm_dir coverage.vdb
SIMV_OPTS +=  -cm_name sim1

.PHONY: compile simv clean

all: simv

compile:
	@vcs  $(VCS_OPTS) $(VCS_INCDIR) $(VCS_SRC_FILES) $(VCS_OUTPUT)
	@echo "타겟 [$@]"

simv: compile
	@./simv $(SIMV_OPTS)
	@echo "의존 타겟 [$<]"
	@echo "타겟 [$@]"

clean:
	rm -rf simv* csrc *.log *.key *.h ucli.key DVEfiles
	@echo "결과물 정리 중 ..."