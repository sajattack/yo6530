#![no_std]
#![no_main]

use panic_halt as _;

use arduino_hal::pac::{
    porta::{PORTA, DDRA},
    portk::{PORTK, DDRK},
    portf::{PORTF, DDRF},
};

#[arduino_hal::entry]
fn main() -> ! {
    let dp = arduino_hal::Peripherals::take().unwrap();
    loop {}
}

fn write_data(porta: &mut PORTA, ddra: &mut DDRA, data: u8) {
    ddra.write(|w| {
        w.pa0().set_bit();
        w.pa1().set_bit();
        w.pa2().set_bit();
        w.pa3().set_bit();
        w.pa4().set_bit();
        w.pa5().set_bit();
        w.pa6().set_bit();
        w.pa7().set_bit()
    });
    porta.write(|w| {
        unsafe { w.bits(data) }
    });
}

fn read_data(porta: &mut PORTA, ddra: &mut DDRA) -> u8 {
    ddra.write(|w| {
        w.pa0().clear_bit();
        w.pa1().clear_bit();
        w.pa2().clear_bit();
        w.pa3().clear_bit();
        w.pa4().clear_bit();
        w.pa5().clear_bit();
        w.pa6().clear_bit();
        w.pa7().clear_bit()
    });
    porta.read().bits()
}



fn write_addr(portf: &mut PORTF, portk: &mut PORTK, ddrf: &mut DDRF, ddrk: &mut DDRK, addr: u16) {
    ddrf.write(|w| {
        w.pf0().set_bit();
        w.pf1().set_bit();
        w.pf2().set_bit();
        w.pf3().set_bit();
        w.pf4().set_bit();
        w.pf5().set_bit();
        w.pf6().set_bit();
        w.pf7().set_bit()
    });

    ddrk.write(|w| {
        w.pk0().set_bit();
        w.pk1().set_bit()
    });

    portf.write(|w| {
        unsafe { 
            w.bits(addr as u8)
        }
    });

    portk.modify(|_, w| {
        w.pk0().bit(addr & 0b0100000000 >> 8 == 1);
        w.pk1().bit(addr & 0b1000000000 >> 9 == 1)
    });
}

fn bus_write(
    porta: &mut PORTA,
    portf: &mut PORTF,
    portk: &mut PORTK,
    ddra: &mut DDRA,
    ddrf: &mut DDRF,
    ddrk: &mut DDRK,
    addr: u16,
    data: u8
) {
    // rw is pk2
    portk.modify(|_, w| {
        w.pk2().clear_bit()
    });


    write_addr(portf, portk, ddrf, ddrk, addr);
    write_data(porta, ddra, data);
    
    arduino_hal::delay_us(1);

    // rw is pk2
    portk.modify(|_, w| {
        w.pk2().set_bit()
    });
}

fn bus_read(
    porta: &mut PORTA,
    portf: &mut PORTF,
    portk: &mut PORTK,
    ddra: &mut DDRA,
    ddrf: &mut DDRF,
    ddrk: &mut DDRK,
    addr: u16,
) -> u8 {

    // rw is pk2
    portk.modify(|_, w| {
        w.pk2().set_bit()
    });

    write_addr(portf, portk, ddrf, ddrk, addr);

    arduino_hal::delay_us(1);
    read_data(porta, ddra)
}

