#include <iostream>
#include <stdlib.h>
#include "../obj_dir/Vverilator_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#define MOS6530_003 1;

static VerilatedVcdC *trace = nullptr;
unsigned long tickcount = 0;

double sc_time_stamp() {
    return (double) tickcount;
}

void check_rom(Vverilator_top* top, VerilatedVcdC* trace) {
    top->R_W = true;
    top->RS0 = false;
    top->CS1 = true;
    top->addr = 0;

    for (int i=0; i<2; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }

    while (top->addr < 1024) {

    for (int i=0; i<2; i++) {
        top->PHI2 = !(top->PHI2);


        if (top->PHI2 == false)
        {
            top->addr = top->addr+1;
        }

        top->eval();
        trace->dump(10*tickcount);
        tickcount++;

        if (top->addr == 1 && top->PHI2 == true)
        {
            #ifdef MOS6530_002
            assert(top->data_o==0xf3);
            #endif
            #ifdef MOS6530_003
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

    for (int i=0; i<2; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }


    for (int i=0; i<2; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }


    for (int i=0; i<2; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }

    #ifdef MOS6530_002
    top->addr = 960;
    #endif
    #ifdef MOS6530_003
    top->addr = 896;
    #endif
    top->R_W = false; 
    top->PHI2 = !(top->PHI2);
    top->eval();
    trace->dump(10*tickcount);
    tickcount++;
    top->data_i = 0x55;

    for (int i=0; i<2; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }

    top->data_i = 0;
    top->addr = 0;
    top->R_W = true;

    for (int i=0; i<2; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }
    assert(top->data_o != 0x55);

    #ifdef MOS6530_002
    top->addr = 960;
    #endif
    #ifdef MOS6530_003
    top->addr = 896;
    #endif

    top->PHI2 = !(top->PHI2);
    top->eval();
    trace->dump(10*tickcount);
    tickcount++;
    assert(top->data_o == 0x55);
}

void check_io(Vverilator_top* top, VerilatedVcdC* trace) {
    top->R_W = true;
    top->RS0 = true;
    top->CS1 = false;

    for (int i=0; i<2; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }


    for (int i=0; i<2; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }

    // write ddra

    #ifdef MOS6530_002
    top->addr = 833;
    #endif
    #ifdef MOS6530_003
    top->addr = 769;
    #endif

    // all outputs
    top->data_i = 255;
    top->R_W = false; 

    for (int i=0; i<2; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }

    // write pins off/on

    #ifdef MOS6530_002
    top->addr = 832;
    #endif
    #ifdef MOS6530_003
    top->addr = 768;
    #endif

    // magic value
    top->data_i = 0x55;
    top->R_W = false; 
    
    for (int i=0; i<2; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }

    top->R_W = true;

    // move to an arbitrary other address, read
    top->addr = 200;
    top->R_W = true;

    for (int i=0; i<2; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }

    assert(top->data_o != 0x55);

    // move back to porta, read
    #ifdef MOS6530_002
    top->addr = 832;
    #endif
    #ifdef MOS6530_003
    top->addr = 768;
    #endif

    top->R_W = true;

    // should this take 1 clock cycle (i=2) or 0.5 clock cycles (i=1)?
    for (int i=0; i<2; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }

    assert(top->data_o == 0x55);
    assert(top->porta_o == 0x55); 
}

void check_timer(Vverilator_top* top, VerilatedVcdC* trace) {
    top->R_W = true;
    top->RS0 = true;
    top->CS1 = false;

    // write timer
    #ifdef MOS6530_002
    top->addr = 836;
    #endif
    #ifdef MOS6530_003
    top->addr = 772;
    #endif

    top->R_W = false;

    // arbitrary
    top->data_i = 123;

    for (int i=0; i<2; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }

    top->R_W = true;

    for (int i=0; i<2; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }

    
    #ifdef MOS6530_002
    top->addr = 836;
    #endif
    #ifdef MOS6530_003
    top->addr = 772;
    #endif




    top->PHI2 = !(top->PHI2);
    top->eval();

    trace->dump(10*tickcount);
    tickcount++;

    // test decrement
    assert(top->data_o == 122);
    for (int i=0; i<2048; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }
    assert(top->data_o == 121);

    // test irq
    #ifdef MOS6530_002
    top->addr = 844;
    #endif
    #ifdef MOS6530_003
    top->addr = 780;
    #endif


    top->PB0 = true;
    top->PB1 = true;
    top->PB2 = true;
    top->PB3 = true;
    top->PB4 = true;
    top->CS2_PB5 = true;
    top->IRQ_PB7 = true;
    top->R_W = true;

    for (int i=0; i<10; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }

    top->R_W = true;

    for (int i=0; i<2048*122-42; i++) { // time it takes for timer_count to be 0
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
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
    trace->dump(10*tickcount);
    tickcount++;

    top->RES = false;
    top->PHI2 = true;
    top->eval();
    trace->dump(10*tickcount);
    tickcount++;

    top->RES = true;
    top->PHI2 = false;
    top->eval();
    trace->dump(10*tickcount);
    tickcount++;

    top->addr = 0; 
    top->PHI2 = true;
    top->eval();
    trace->dump(10*tickcount);
    tickcount++;

    check_rom(top, trace);
    check_ram(top, trace);
    check_io(top, trace);
    check_timer(top, trace);

    trace->close();
    delete trace;
    top->final();
    delete top;
}


