PROJ=mcs6530
BUILD_DIR=build
DRAW_DIR=draw
SRC_DIR=src
SRCS=top.v mcs6530.v rom.v ram.v io.v timer.v 
SEED=1337
DEVICE=up5k
PACKAGE=sg48
BOARD=redip-rriot

MCS6530_002 ?= 1
MCS6530_003 ?= 0


ifeq "$(MCS6530_003)" "1"
	FLG = -DMCS6530_003
	ARTIFACT = $(BUILD_DIR)/mcs6530_003.bin
else ifeq "$(MCS6530_002)" "1"
	FLG = -DMCS6530_002
	ARTIFACT = $(BUILD_DIR)/mcs6530_002.bin
endif

all: ${BUILD_DIR}/${PROJ}.bin
	@mv ${BUILD_DIR}/${PROJ}.bin $(ARTIFACT)

$(BUILD_DIR)/$(PROJ).json: $(addprefix $(SRC_DIR)/, $(SRCS))
	@mkdir -p $(@D)
	yosys -f verilog -l $(BUILD_DIR)/$(PROJ).yslog -p 'read_verilog -sv $(FLG) $^; synth_ice40 -json $@'

$(BUILD_DIR)/$(PROJ).asc: $(BUILD_DIR)/$(PROJ).json $(BOARD).pcf 
	@mkdir -p $(@D)
	nextpnr-ice40 -l $(BUILD_DIR)/$(PROJ).nplog --$(DEVICE) --package $(PACKAGE) --asc $@ --pcf $(BOARD).pcf --seed $(SEED) --json $<

$(BUILD_DIR)/$(PROJ).bin: $(BUILD_DIR)/$(PROJ).asc 
	@mkdir -p $(@D)
	icepack $< $@

$(BUILD_DIR)/$(PROJ).rpt: $(BUILD_DIR)/$(PROJ).asc
	@mkdir -p $(@D)

$(DRAW_DIR)/%.svg: $(SRC_DIR)/%.v
	@mkdir -p $(@D)
	yosys -p 'read_verilog -sv $(FLG) $<; show -prefix $(addprefix $(DRAW_DIR)/,$*) -format svg $*'


obj_dir/Vverilator_top: $(addprefix $(SRC_DIR)/, $(SRCS)) sim/verilator_top.v sim/verilator_driver.cpp
	verilator -cc --top-module verilator_top sim/verilator_top.v $(FLG) $(addprefix $(SRC_DIR)/, $(SRCS)) -I./src -exe sim/verilator_driver.cpp --trace -Wall
	make -C obj_dir -f Vverilator_top.mk

sim: obj_dir/Vverilator_top

lint: 
	verible-verilog-lint $(addprefix $(SRC_DIR)/, $(SRCS)) $(FLG) sim/verilator_top.v --rules +explicit-parameter-storage-type=exempt_type:string

format:
	verible-verilog-format $(addprefix $(SRC_DIR)/, $(SRCS))  sim/verilator_top.v --inplace 


draw: $(addprefix $(DRAW_DIR)/,$(subst .v,.svg, $(SRCS)))

clean: 
	rm -rf $(BUILD_DIR)
	rm -rf obj_dir
	rm -rf $(DRAW_DIR)

# This invalidates any previous build and rebuilds everything every time
# Needed because otherwise `make MCS6530_003=1 && make MCS6530_002=1`
# would result in two copies of 003 being created, one of which would have the 002 name
# definitely not what we want
.PHONY: all clean ${BUILD_DIR}/${PROJ}.bin ${BUILD_DIR}/${PROJ}.asc ${BUILD_DIR}/${PROJ}.json
