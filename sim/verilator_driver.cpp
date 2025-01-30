#include <iostream>
#include <stdlib.h>
#include "../obj_dir/Vverilator_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

static VerilatedVcdC *trace = nullptr;
unsigned long tickcount = 0;

double sc_time_stamp() {
    return (double) tickcount;
}

void reset(Vverilator_top* top, VerilatedVcdC* trace) {
    top->RES = true;

    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }


    top->RES = false;


    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    top->RES = true;
}


void check_rom(Vverilator_top* top, VerilatedVcdC* trace) {
    top->R_W = true;
    top->RS0 = false;
    top->CS1 = true;
    top->PHI2_2X = true;
    top->addr = 0;

    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    while (top->addr < 1024) {
        for (int i=0; i<4; i++) {
            top->PHI2_2X = !(top->PHI2_2X);

            if (top->PHI2 == false)
            {
                top->addr = top->addr+1;
            }

            top->eval();
            trace->dump(tickcount*1000);
            tickcount+=250;

            if (top->addr == 1 && top->PHI2 == true)
            {
                #ifdef MCS6530_002
                assert(top->data_o==0xf3);
                #endif
                #ifdef MCS6530_003
                assert(top->data_o==0xad);
                #endif
            }
        }
    }
}

void check_ram(Vverilator_top* top, VerilatedVcdC* trace) {
    top->R_W = true;
    top->RS0 = true;
    top->CS1 = false;
    //top->PHI2 = false;

    for (int i=0; i<2; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    #ifdef MCS6530_002
    top->addr = 0x3c0;
    #endif
    #ifdef MCS6530_003
    top->addr = 0x380;
    #endif

    top->R_W = false; 

    for (int i=0; i<2; i++)
    {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    top->data_i = 0x55;

    for (int i=0; i<2; i++)
    {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }


    top->R_W = true;
    top->addr = top->addr + 1;
    top->data_i = 0;

    for (int i=0; i<6; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }
    assert(top->data_o != 0x55);

    #ifdef MCS6530_002
    top->addr = 0x3c0;
    #endif
    #ifdef MCS6530_003
    top->addr = 0x380;
    #endif

    for (int i=0; i<4; i++)
    {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    assert(top->data_o == 0x55);
}

void check_io(Vverilator_top* top, VerilatedVcdC* trace) {
    top->R_W = true;
    top->RS0 = true;
    top->CS1 = false;
    top->PHI2 = false;

    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    // write ddra

    #ifdef MCS6530_002
    top->addr = 0x341;
    #endif
    #ifdef MCS6530_003
    top->addr = 0x301;
    #endif

    // all outputs
    top->data_i = 0xFF;
    top->R_W = false; 

    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    // write pins off/on

    #ifdef MCS6530_002
    top->addr = 0x340;
    #endif
    #ifdef MCS6530_003
    top->addr = 0x300;
    #endif

    // magic value
    top->data_i = 0x55;
    top->R_W = false; 
    
    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    top->R_W = true;

    top->data_i = 0x00;


    // read
    #ifdef MCS6530_002
    top->addr = 0x340;
    #endif
    #ifdef MCS6530_003
    top->addr = 0x300;
    #endif

    top->R_W = true;

    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    assert(top->data_o == 0x55);
    assert(top->porta_o == 0x55); 
}

void check_timer(Vverilator_top* top, VerilatedVcdC* trace) {
    top->R_W = true;
    top->RS0 = true;
    top->CS1 = false;
    top->PHI2 = false;

    // write timer
    #ifdef MCS6530_002
    top->addr = 0x34E;
    #endif
    #ifdef MCS6530_003
    top->addr = 0x30E;
    #endif

    reset(top, trace); // reset the timer count

    top->R_W = false;

    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    // arbitrary timer count
    top->data_i = 3;

    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    top->R_W = true;

    for (int i=0; i<6; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    assert(top->data_o == 2);
    
    // test decrement
    // 0x34E = 63uS divider
    for (int i=0; i<63*4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    assert(top->data_o == 1);

    for (int i=0; i<63*4*2-1; i++) { // time it takes for timer_count to be 0
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }
    assert(top->IRQ_PB7==0);
}


int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vverilator_top *top = new Vverilator_top;
    Verilated::traceEverOn(true);
    trace = new VerilatedVcdC;
    top->trace(trace, 99);
    trace->open("Vverilator_top.vcd");
    top->R_W = true;
    top->RES = true;
    top->PHI2 = false;
    top->eval();
    trace->dump(tickcount*1000);
    tickcount+=250;

    top->RES = false;
    top->PHI2 = true;
    top->eval();
    trace->dump(tickcount*1000);
    tickcount+=250;

    top->RES = true;
    top->PHI2 = false;
    top->eval();
    trace->dump(tickcount*1000);
    tickcount+=250;

    top->addr = 0;
    top->PHI2 = true;
    top->eval();
    trace->dump(tickcount*1000);
    tickcount+=250;

    check_rom(top, trace);
    check_ram(top, trace);
    check_io(top, trace);
    check_timer(top, trace);

    trace->close();
    delete trace;
    top->final();
    delete top;
}


