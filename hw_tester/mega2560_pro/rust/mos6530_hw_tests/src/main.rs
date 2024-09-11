#![no_std]
#![no_main]

/// MOS 6530 Chip Tester
///
/// Data bus PA0-PA7
/// Addr bus PF0-PF7 + PG0-1
/// PHI2 PB6
/// RW PH1
/// RS0 PB7
/// RESET PB4
/// IRQ PD0
/// CS1 PH0
/// IO PORTS PC0-5 PK0-7


use panic_halt as _;

use arduino_hal::{
    prelude::*,
    pac::{
        PORTA,
        PORTB,
        PORTK,
        PORTF,
        PORTH,
        PORTG,
        PORTD,
        TC1, USART0,
    }, hal::{Usart, Atmega, port::{PE0, PE1}}, port::{Pin, mode::{Input, Output}}, clock::MHz16
};

static ROM_002: [u8; 1024] = *include_bytes!("../../../../../roms/6530-002.bin");
static ROM_003: [u8; 1024] = *include_bytes!("../../../../../roms/6530-003.bin");

#[arduino_hal::entry]
fn main() -> ! {
    let dp = arduino_hal::Peripherals::take().unwrap();
    let pins = arduino_hal::hal::pins!(dp);
    let mut serial = arduino_hal::hal::usart::Usart0::new(dp.USART0, pins.pe0.into(), pins.pe1.into_output(), arduino_hal::usart::Baudrate::<arduino_hal::hal::clock::MHz16>::new(115200));
    let dp = unsafe { arduino_hal::Peripherals::steal() };
    let mut timer = dp.TC1;
    let mut porta = dp.PORTA;
    let mut portb = dp.PORTB;
    let mut portk = dp.PORTK;
    let mut portf = dp.PORTF;
    let mut porth = dp.PORTH;
    let mut portg = dp.PORTG;
    let mut portd = dp.PORTD;
    start_1mhz_clock_out(&mut portb,  &mut timer);
    toggle_reset(&mut portb);
    test_rom_003(&mut porta, &mut portb, &mut portf, &mut portg, &mut porth, &mut serial);
    loop {}
}

fn start_1mhz_clock_out(
    portb: &mut PORTB,
    timer: &mut TC1,
)
{
    portb.ddrb.modify(|_, w| w.pb6().set_bit());
    
    timer.tccr1a.write(|w| {
        w.com1b().match_set();
        w.wgm1().bits(15)
    });
    timer.tccr1b.write(|w| {
        w.cs1().direct();
        w.wgm1().bits(15)
    });

    timer.ocr1a.write(|w| w.bits(15));
    timer.ocr1b.write(|w| w.bits(7));
}

fn toggle_reset( 
    portb: &mut PORTB,
) {
    portb.ddrb.modify(|_, w| w.pb4().set_bit());
    portb.portb.modify(|_, w| w.pb4().set_bit());
    arduino_hal::delay_us(1);
    portb.portb.modify(|_, w| w.pb4().clear_bit());
    arduino_hal::delay_us(1);
    portb.portb.modify(|_, w| w.pb4().set_bit());
}

fn test_rom_002(
    porta: &mut PORTA,
    portb: &mut PORTB,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>
) {

    portb.ddrb.modify(|_, w| {
        w.pb7().set_bit() // RS0
    });
    porth.ddrh.modify(|_, w| {
        w.ph0().set_bit() // CS1
    });

    portb.portb.modify(|_, w| {
        w.pb7().clear_bit() // RS0
    });
    porth.porth.modify(|_, w| {
        w.ph0().set_bit()  // CS1
    });



   for addr in 0..1023 {
        let byte_read = bus_read(porta, portf, portg, porth, addr);
        let byte_expected = ROM_002[addr as usize];

        if byte_read != byte_expected {
            ufmt::uwriteln!(serial, "ROM read mismatch. Expected 0x{:02X} Got 0x{:02X}", byte_expected, byte_read).unwrap();
        }
    }
    ufmt::uwriteln!(serial, "Finished rom test.").unwrap();

}

fn test_rom_003(
    porta: &mut PORTA,
    portb: &mut PORTB,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>
) {
    
    portb.ddrb.modify(|_, w| {
        w.pb7().set_bit() // RS0
    });
    porth.ddrh.modify(|_, w| {
        w.ph0().set_bit() // CS1
    });

    portb.portb.modify(|_, w| {
        w.pb7().clear_bit() // RS0
    });
    porth.porth.modify(|_, w| {
        w.ph0().set_bit()  // CS1
    });


    for addr in 0..1023 {
        let byte_read = bus_read(porta, portf, portg, porth, addr);
        let byte_expected = ROM_003[addr as usize];

        if byte_read != byte_expected {
            ufmt::uwriteln!(serial, "ROM read mismatch. Expected 0x{:02X} Got 0x{:02X}", byte_expected, byte_read).unwrap();
        }
    }
    ufmt::uwriteln!(serial, "Finished rom test.").unwrap();

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
    porta.pina.read().bits()
}

fn write_addr(portf: &mut PORTF, portg: &mut PORTG, addr: u16) {
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

    portg.ddrg.modify(|_, w| {
        w.pg0().set_bit();
        w.pg1().set_bit()
    });

    portf.portf.write(|w| {
        unsafe { 
            w.bits(addr as u8)
        }
    });

    portg.portg.modify(|_, w| {
        w.pg0().bit(addr & 0b0100000000 >> 8 > 0);
        w.pg1().bit(addr & 0b1000000000 >> 9 > 0)
    });
}

fn bus_write(
    porta: &mut PORTA,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    addr: u16,
    data: u8
) {
    // rw is ph1
    porth.porth.modify(|_, w| {
        w.ph1().clear_bit()
    });


    write_addr(portf, portg, addr);
    write_data(porta, data);
    
    arduino_hal::delay_us(1);

    // rw is ph1
    porth.porth.modify(|_, w| {
        w.ph1().set_bit()
    });
}

fn bus_read(
    porta: &mut PORTA,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    addr: u16,
) -> u8 {

    // rw is ph1
    porth.porth.modify(|_, w| {
        w.ph1().set_bit()
    });

    write_addr(portf, portg, addr);

    arduino_hal::delay_us(1);
    read_data(porta)
}

