VCS_OPTS = -full64 -sverilog
VCS_OPTS += -ntb_opts uvm-1.2
VCS_OPTS += -timescale=1ns/10ps
VCS_OPTS += -debug_access+all -kdb -lca
VCS_OUTPUT = -o simv
VCS_SRC_FILES = ./tb/tb_adder.sv ./rtl/adder.sv

SIMV_OTPS =  + UVM_TESTNAME=adder_test
SIMV_OTPS +=  + UVM_VERBOSITY=UVM_MEDIUM 
SIMV_OTPS +=  + ntb_random_seed=1234
# 1. = 재귀 확장 - 참조 시점에 확장 ()
# 2. := 즉시 확장 - 선언 시점에 확장(마지막으로 덮어 씌워진 값으로 실행됨, 참조 이후 선언된 값은 반영되지 않음)
# 3. ?= 조건부 할당 - 참조 직전까지 값이 정의되지 않았을 경우에만 할당
# 4. += 값 추가 - 기존 값 뒤에 공백+시 값 추가(append)

.PHONY: compile simv clean
#make 실행시 타겟 이름과 파일 이름이 같을 경우 타겟 이름 실행

compile:
	@vcs  $(VCS_OPTS)  $(VCS_SRC_FILES) $(VCS_OUTPUT)
	@echo "의존 타겟 [$@]"
#clear
simv: compile #target : dependency(의존성)
	@./simv $(SIMV_OTPS)
	@echo "의존 타겟 [$<]"
	@echo "타겟 [$@]"
#clear
#<TAB> recipe(레시피)
# 1. $@ : 현재 타겟 이름
# 2. $< : 첫 번째 dependency 이름

clean:
	@rm -rf simv* csrc *.log *.key *.h
	@echo "결과물 정리 중 ..."
	clear



A ?= hello
B := $(A) world
A := goodbye

test:
	@echo $(B)




#target : 만들려고 하는 이름
#dependency : 타겟을 만들기 전에 먼저 준비되어야 하는 것들
#recipe : 실헹할 쉘 커맨드
#Makefile




#<make 실행 흐름>
# 1. make compile(make 타겟 이름)
# 2. Makefile을 찾고 읽기
# 3. 의존성 확인, dependency 해소
# 4. recipe 실행 :VCS 명령 실행
# 5. 
# 6. 
# 7. 