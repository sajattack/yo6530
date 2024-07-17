import dwfpy as dwf
#import time
from datetime import datetime

with dwf.Device() as device:
    io = device.digital_io
    rw = io[0].setup(enabled=True, state=True)
    rs0 = io[1].setup(enabled=True, state=False)
    cs1 = io[2].setup(enabled=True, state=False)

    # 0x3c4
    a0 = io[3].setup(enabled=True, state=False)
    a1 = io[4].setup(enabled=True, state=False)
    a2 = io[5].setup(enabled=True, state=True)
    a3 = io[6].setup(enabled=True, state=False)
    a4 = io[7].setup(enabled=True, state=False)
    a5 = io[8].setup(enabled=True, state=False)
    a6 = io[9].setup(enabled=True, state=True)
    a7 = io[10].setup(enabled=True, state=True)
    a8 = io[11].setup(enabled=True, state=True)
    a9 = io[12].setup(enabled=True, state=True)

    rw.output_state = False

    # 0'd123
    d0 = io[13].setup(enabled=True, state=True)
    d1 = io[14].setup(enabled=True, state=True)
    d2 = io[15].setup(enabled=True, state=False)
    d3 = io[16].setup(enabled=True, state=True)
    d4 = io[17].setup(enabled=True, state=True)
    d5 = io[18].setup(enabled=True, state=True)
    d6 = io[19].setup(enabled=True, state=True)
    d7 = io[20].setup(enabled=True, state=True)
    d8 = io[21].setup(enabled=True, state=False)

    phi2 = io[22].setup_clock(frequency=1e5, start=True)
    irq = io[23].setup(enabled=False, configure=True)
    # current_irq = irq.read_status()
    # assert(current_irq==True, f"IRQ expected high, got: {current_irq}")
    # time.sleep(2.49814)
    # current_irq = irq.read_status()
    # assert(current_irq==False, f"IRQ expected low, got: {current_irq}")
    print("setup irq trigger")

    irq.setup_edge_trigger(0, "falling")
    start = datetime.now()
    irq.wait_for_status(True)
    end = datetime.now()
    print("triggered after {end-start} at 100KHz")
