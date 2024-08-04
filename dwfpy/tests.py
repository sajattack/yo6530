import dwfpy as dwf
import time
from datetime import datetime

with dwf.DigitalDiscovery() as device:
    io = device.digital_io
    out = device.digital_output
    inp = device.digital_input

    device.supplies.digital.setup(voltage=5.0)
    device.supplies.master_enable = True

    io[35-24].setup(enabled=True, state=True) # rw
    io[29-24].setup(enabled=True, state=False) # rs0

    #cs1 = io[2].setup(enabled=True, state=False)

    io[38-24].setup(enabled=True, state=False) # a0
    io[34-24].setup(enabled=True, state=False) # a1
    io[37-24].setup(enabled=True, state=True) # a2
    io[33-24].setup(enabled=True, state=True) # a3
    io[36-24].setup(enabled=True, state=True) # a4
    io[32-24].setup(enabled=True, state=False) # a5
    #a6 = io[9].setup(enabled=True, state=True)
    #a7 = io[10].setup(enabled=True, state=True)
    #a8 = io[11].setup(enabled=True, state=True)
    #a9 = io[12].setup(enabled=True, state=True)

    io[35-24].setup(enabled=True, state=False) # rw

    # 8'd128
    io[28-24].setup(enabled=True, state=True) # d7

    out[39-24].setup_clock(frequency=1e5, start=True) # phi2
    io[24-24].setup(enabled=False, configure=True) # irq

    # current_irq = irq.read_status()
    # assert(current_irq==True, f"IRQ expected high, got: {current_irq}")
    # time.sleep(2.49814)
    # current_irq = irq.read_status()
    # assert(current_irq==False, f"IRQ expected low, got: {current_irq}")

    io[35-24].setup(enabled=True, state=True) # rw
    time.sleep(0.0001)
    io[35-24].setup(enabled=True, state=False) # rw

    print("setup irq trigger")
    #print(inp.channels[0].label)
    inp.setup_edge_trigger(24-24, "falling")
    start = datetime.now()
    print(inp.single(1e6, buffer_size=1, configure=True, start=True))
    #while True:
    #    print(inp.read_status())
    #inp.wait_for_status(True)
    end = datetime.now()
    print(f"triggered after {end-start} at 100KHz")
