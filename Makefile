PROJ=mcs6530
BUILD_DIR=build
SRC_DIR=src
SRCS=$(SRC_DIR)/mcs6530.sv $(SRC_DIR)/top.v $(SRC_DIR)/rom.v $(SRC_DIR)/ram.v
SEED=1337
DEVICE=up5k
PACKAGE=sg48
BOARD=redip-rriot

all: $(BUILD_DIR)/$(PROJ).bin $(BUILD_DIR)/$(PROJ).rpt

$(BUILD_DIR)/$(PROJ).json: $(SRCS)
	@mkdir -p $(@D)
	yosys -f verilog -l $(BUILD_DIR)/$(PROJ).yslog -p 'read_verilog -sv $^; synth_ice40 -json $@'

$(BUILD_DIR)/$(PROJ).asc: $(BUILD_DIR)/$(PROJ).json $(BOARD).pcf 
	@mkdir -p $(@D)
	nextpnr-ice40 -l $(BUILD_DIR)/$(PROJ).nplog --$(DEVICE) --package $(PACKAGE) --asc $@ --pcf $(BOARD).pcf --seed $(SEED) --json $<

$(BUILD_DIR)/$(PROJ).bin: $(BUILD_DIR)/$(PROJ).asc
	@mkdir -p $(@D)
	icepack $< $@

$(BUILD_DIR)/$(PROJ).rpt: $(BUILD_DIR/$(PROJ).asc
	@mkdir -p $(@D)

obj_dir/Vverilator_top: $(SRCS) sim/verilator_top.v sim/verilator_driver.cpp
	verilator -cc --top-module verilator_top sim/verilator_top.v src/mcs6530.sv src/ram.v src/rom.v -I./src -exe sim/verilator_driver.cpp --trace
	make -C obj_dir -f Vverilator_top.mk

sim: obj_dir/Vverilator_top

clean: 
	rm -rf build
	rm -rf obj_dir

.PHONY: all
