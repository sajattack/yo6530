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

void check_rom(Vverilator_top* top, VerilatedVcdC* trace) {
    top->R_W = true;
    top->RS0 = true;
    top->CS1_PB6 = true;
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
            assert(top->data_o==0xad);
        }
    }

    }
}

void check_ram(Vverilator_top* top, VerilatedVcdC* trace) {
    top->R_W = true;
    top->RS0 = false;
    top->CS1_PB6 = false;

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

    top->addr = 193;
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

    top->addr = 193;
    top->PHI2 = !(top->PHI2);
    top->eval();
    trace->dump(10*tickcount);
    tickcount++;
    assert(top->data_o == 0x55);
}

void check_io(Vverilator_top* top, VerilatedVcdC* trace) {
    top->R_W = true;
    top->RS0 = false;
    top->CS1_PB6 = false;

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
    top->addr = 0x3c1;
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
    top->addr = 0x3c0;
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
    top->addr = 0x3c0;
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
    top->RS0 = false;
    top->CS1_PB6 = false;

    for (int i=0; i<2; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }

    // write timer
    top->addr = 0x3c4;
    top->R_W = false;

    for (int i=0; i<1; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }

    // arbitrary
    top->data_i = 123;

    for (int i=0; i<1; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }

    top->R_W = true;
    top->addr = 0x3c4;
    top->PHI2 = !(top->PHI2);
    top->eval();
    
    trace->dump(10*tickcount);
    tickcount++;

    //assert(top->data_o == 122);

    for (int i=0; i<2048; i++) {
        top->PHI2 = !(top->PHI2);
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }

    //assert(top->data_o == 121);

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


