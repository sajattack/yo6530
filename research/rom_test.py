import dwfpy as dwf
import time

with dwf.DigitalDiscovery() as device:
    io = device.digital_io
    out = device.digital_output
    inp = device.digital_input

    device.supplies.digital.setup(voltage=5.0)
    device.supplies.master_enable = True

    time.sleep(0.5)

    phi2 = out[32-24]
    phi2.setup_clock(frequency=1e6, start=True) # 1MHz

    time.sleep(0.5)

    reset = io[36-24]
    reset.setup(enabled=True, state=True)
    time.sleep(0.5)
    reset.setup(enabled=True, state=False)
    time.sleep(0.5)
    reset.setup(enabled=True, state=True)

    rw = io[34-24]
    rs0 = io[38-24]
    cs1 = io[35-24]

    rs0.setup(enabled=True, state=True)
    rw.setup(enabled=True, state=True)
    cs1.setup(enabled=True, state=True)

    time.sleep(0.5)

    a0 = io[33-24]
    a0.setup(enabled=True, state=False)

    time.sleep(0.5)

    d0 = io[24-24]
    d1 = io[25-24]
    d2 = io[26-24]
    d3 = io[27-24]
    d4 = io[28-24]
    d5 = io[29-24]
    d6 = io[30-24]
    d7 = io[31-24]

    d0.setup(enabled=False, configure=True)
    d1.setup(enabled=False, configure=True)
    d2.setup(enabled=False, configure=True)
    d3.setup(enabled=False, configure=True)
    d4.setup(enabled=False, configure=True)
    d5.setup(enabled=False, configure=True)
    d6.setup(enabled=False, configure=True)
    d7.setup(enabled=False, configure=True)


    time.sleep(0.5)

    io.read_status()

    b = [
        d7.input_state,
        d6.input_state,
        d5.input_state,
        d4.input_state,
        d3.input_state,
        d2.input_state,
        d1.input_state,
        d0.input_state,
    ]

    print(b)
    v = sum(a<<i for i,a in enumerate(b))
    print(hex(v))

    time.sleep(0.5)

