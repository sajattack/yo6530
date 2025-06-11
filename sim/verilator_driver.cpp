#include <iostream>
#include <stdlib.h>
#include "../obj_dir/Vverilator_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#define MCS6530_002 1
#define DEBUG 1

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

            if ((top->PHI2 == false) & (i % 2 == 0))
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
    
    #ifdef MCS6530_002
    top->addr = 0x3c0;
    #endif
    #ifdef MCS6530_003
    top->addr = 0x380;
    #endif

    for (int i=0; i<2; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

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

    //printf("0x%x\n", top->data_o);
    assert(top->data_o == 0x55);
    assert(top->porta_o == 0x55); 
}

void check_timer(Vverilator_top* top, VerilatedVcdC* trace) {
    top->R_W = true;
    top->RS0 = true;
    top->CS1 = false;
    top->PHI2 = false;

    reset(top, trace); // reset the timer count

    // write timer
    // 0x34E = 64uS divider, interrupts enabled
    #ifdef MCS6530_002
    top->addr = 0x34E;
    #endif
    #ifdef MCS6530_003
    top->addr = 0x30E;
    #endif

    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    top->R_W = false;

    // arbitrary timer count
    top->data_i = 154;

    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    top->R_W = true;

    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    //assert(top->data_o == 153);
    
    // test decrement
    for (int i=0; i<(1*64*4)+2; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    assert(top->data_o == 153);

    for (int i=0; i<(153*64*4)-2; i++) { // time it takes for timer_count to be 0
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }
    assert(top->irq==0);
}

void check_pb7(Vverilator_top* top, VerilatedVcdC* trace) {

    // disable interrupt
    top->addr = 0x344;

    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    top->data_i = 0x0;
    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    top->R_W = false;

    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }
    
    top->R_W = true;

    top->portb_i = 0xc0;
    top->addr = 0x343;
    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    // all inputs
    top->data_i = 0x0;

    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    top->R_W = false;

    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    top->addr = 0x342;

    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    top->R_W = true;

    for (int i=0; i<4; i++) {
        top->PHI2_2X = !(top->PHI2_2X);
        top->eval();
        trace->dump(tickcount*1000);
        tickcount+=250;
    }

    //printf("0x%x\n", top->data_o);
    assert(top->data_o == 0xc0);
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

    reset(top, trace);

    top->addr = 0;
    top->PHI2 = true;
    top->eval();
    trace->dump(tickcount*1000);
    tickcount+=250;


    #ifdef MCS6530_002
    printf("CHIP 2\n");
    #elif MCS6530_003
    printf("CHIP 3\n");
    #else
    printf("CHIP UNSPECIFIED\n");
    #endif


    check_rom(top, trace);
    check_ram(top, trace);
    check_io(top, trace);
    check_timer(top, trace);
    check_pb7(top, trace);

    trace->close();
    delete trace;
    top->final();
    delete top;
}


