import dwfpy as dwf
import time
from datetime import datetime

with dwf.DigitalDiscovery() as device:
    io = device.digital_io
    out = device.digital_output
    inp = device.digital_input

    device.supplies.digital.setup(voltage=5.0)
    device.supplies.master_enable = True

    phi2 = out[39-24]
    phi2.setup_clock(frequency=1e5, start=True) # 100KHz

    rw = io[35-24]
    rw.setup(enabled=True, state=True)
    rs0 = io[29-24]
    rs0.setup(enabled=True, state=False)

    # do we need this?
    #cs1 = io[2].setup(enabled=True, state=False)

    a0 = io[38-24]
    a0.setup(enabled=True, state=False)
    a1 = io[34-24]
    a1.setup(enabled=True, state=False)
    a2 = io[37-24]
    a2.setup(enabled=True, state=True)
    a3 = io[33-24]
    a3.setup(enabled=True, state=True)
    a4 = io[36-24]
    a4.setup(enabled=True, state=True)
    a5 = io[32-24]
    a5.setup(enabled=True, state=False)

    rw = io[35-24]
    rw.setup(enabled=True, state=False)

    # 8'd128
    d7 = io[28-24]
    d7.setup(enabled=True, state=True) # d7

    rw.setup(enabled=True, state=True)
    time.sleep(0.0001)
    rw.setup(enabled=True, state=False)

    print("setup irq trigger")
    # investigate more accurate ways to time irq
    inp.setup_edge_trigger(0, "falling") # irq
    start = datetime.now()
    print(inp.single(1e6, buffer_size=1, configure=True, start=True))
    end = datetime.now()
    print(f"triggered after {end-start} at 100KHz")
