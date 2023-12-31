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

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vverilator_top *top = new Vverilator_top;
    Verilated::traceEverOn(true);
    trace = new VerilatedVcdC;
    top->trace(trace, 99);
    trace->open("Vverilator_top.vcd");

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
    top->R_W = false;
    top->RS0 = false;
    top->CS2_PB5 = false;
    top->CS1_PB6 = false;
    top->eval();
    trace->dump(10*tickcount);
    tickcount++;

    top->addr = 0; 
    top->PHI2 = true;
    top->eval();
    trace->dump(10*tickcount);
    tickcount++;

    for (int i=0; i<10000; i++) {
        top->PHI2 = !(top->PHI2);
        if (i%10==0)
        {
            top->addr = top->addr+1;
        }
        top->eval();
        trace->dump(10*tickcount);
        tickcount++;
    }

    trace->close();
    delete trace;
    top->final();
    delete top;
}
