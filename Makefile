PROJ=mcs6530
BUILD_DIR=build
SRCS=mcs6530.sv
SEED=1337
DEVICE=up5k
PACKAGE=sg48
BOARD=icebreaker

all: $(BUILD_DIR)/$(PROJ).bin $(BUILD_DIR)/$(PROJ).rpt

$(BUILD_DIR)/$(PROJ).json: SRCS
	@mkdir -p $(@D)
	yosys -f verilog -l ${BUILD_DIR)/$(PROJ).yslog -p 'read_verilog -sv $^; synth_ice40 -json $@'

$(BUILD_DIR)/$(PROJ).asc: $(BUILD_DIR)/$(PROJ).json $(BOARD).pcf 
	@mkdir -p $(@D)
	nextpnr-ice40 -l $(BUILD_DIR)/$(PROJ).nplog --$(DEVICE) --package $(PACKAGE) --asc $@ --pcf ${BOARD).pcf --seed $(SEED) --json $<

$(BUILD_DIR)/(PROJ).bin: $(BUILD_DIR)/$(PROJ).asc
	@mkdir -p $(@D)
	icecpack $< $@

$(BUILD_DIR)/$(PROJ).rpt: $(BUILD_DIR/$(PROJ).asc
	@mkdir -p $(@D)

.PHONY: all
