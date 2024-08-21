#![no_std]
#![no_main]

use panic_halt as _;

use arduino_hal::pac::{
    PORTA,
    PORTK,
    PORTF,
};

static ROM_002: [u8; 1024] = *include_bytes!("../../../../roms/6530-002.bin");
static ROM_003: [u8; 1024] = *include_bytes!("../../../../roms/6530-003.bin");

#[arduino_hal::entry]
fn main() -> ! {
    let dp = arduino_hal::Peripherals::take().unwrap();
    let mut porta = dp.PORTA;
    let mut portf = dp.PORTF;
    let mut portk = dp.PORTK;
    test_rom_002(&mut porta, &mut portf, &mut portk);
    loop {}
}

fn test_rom_002(
    porta: &mut PORTA,
    portf: &mut PORTF,
    portk: &mut PORTK,
) {
   for addr in 0..1023 {
       assert_eq!(bus_read(porta, portf, portk, addr), ROM_002[addr as usize])
   }
}

fn test_rom_003(
    porta: &mut PORTA,
    portf: &mut PORTF,
    portk: &mut PORTK,
) {
   for addr in 0..1023 {
       assert_eq!(bus_read(porta, portf, portk, addr), ROM_003[addr as usize])
   }
}

fn write_data(porta: &mut PORTA, data: u8) {
    porta.ddra.write(|w| {
        w.pa0().set_bit();
        w.pa1().set_bit();
        w.pa2().set_bit();
        w.pa3().set_bit();
        w.pa4().set_bit();
        w.pa5().set_bit();
        w.pa6().set_bit();
        w.pa7().set_bit()
    });
    porta.porta.write(|w| {
        unsafe { w.bits(data) }
    });
}

fn read_data(porta: &mut PORTA) -> u8 {
    porta.ddra.write(|w| {
        w.pa0().clear_bit();
        w.pa1().clear_bit();
        w.pa2().clear_bit();
        w.pa3().clear_bit();
        w.pa4().clear_bit();
        w.pa5().clear_bit();
        w.pa6().clear_bit();
        w.pa7().clear_bit()
    });
    porta.porta.read().bits()
}



fn write_addr(portf: &mut PORTF, portk: &mut PORTK, addr: u16) {
    portf.ddrf.write(|w| {
        w.pf0().set_bit();
        w.pf1().set_bit();
        w.pf2().set_bit();
        w.pf3().set_bit();
        w.pf4().set_bit();
        w.pf5().set_bit();
        w.pf6().set_bit();
        w.pf7().set_bit()
    });

    portk.ddrk.write(|w| {
        w.pk0().set_bit();
        w.pk1().set_bit()
    });

    portf.portf.write(|w| {
        unsafe { 
            w.bits(addr as u8)
        }
    });

    portk.portk.modify(|_, w| {
        w.pk0().bit(addr & 0b0100000000 >> 8 == 1);
        w.pk1().bit(addr & 0b1000000000 >> 9 == 1)
    });
}

fn bus_write(
    porta: &mut PORTA,
    portf: &mut PORTF,
    portk: &mut PORTK,
    addr: u16,
    data: u8
) {
    // rw is pk2
    portk.portk.modify(|_, w| {
        w.pk2().clear_bit()
    });


    write_addr(portf, portk, addr);
    write_data(porta, data);
    
    arduino_hal::delay_us(1);

    // rw is pk2
    portk.portk.modify(|_, w| {
        w.pk2().set_bit()
    });
}

fn bus_read(
    porta: &mut PORTA,
    portf: &mut PORTF,
    portk: &mut PORTK,
    addr: u16,
) -> u8 {

    // rw is pk2
    portk.portk.modify(|_, w| {
        w.pk2().set_bit()
    });

    write_addr(portf, portk, addr);

    arduino_hal::delay_us(1);
    read_data(porta)
}

