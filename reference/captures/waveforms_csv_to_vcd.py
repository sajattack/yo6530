import os, sys
import csv
from vcd import VCDWriter

csvfile = open('c64_bus_timing.csv', 'r')
vcdfile = open('c64_bus_timing.vcd', 'w+')
reader = csv.DictReader(csvfile)
writer = VCDWriter(vcdfile, timescale='1ps', init_timestamp=0)
phi2 = writer.register_var(scope='', name='PHI2', var_type='wire', size=1) 
r_w = writer.register_var(scope='', name='R_W', var_type='wire', size=1) 
d0 = writer.register_var(scope='', name='D0', var_type='wire', size=1) 
a0 = writer.register_var(scope='', name='A0', var_type='wire', size=1) 
for row in reader:
    timestamp = int(float(row['Time (s)'])*10000000)+16383
    writer.change(phi2, timestamp, row['PHI2'])
    writer.change(r_w, timestamp, row['R_W'])
    writer.change(d0, timestamp, row['D0'])
    writer.change(a0, timestamp, row['A0'])
    #print(timestamp)
writer.close()        
vcdfile.close()
csvfile.close()


