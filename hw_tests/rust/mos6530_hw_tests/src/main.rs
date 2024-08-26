#![no_std]
#![no_main]

/// MOS 6530 Chip Tester
///
/// Data bus PA0-PA7
/// Addr bus PF0-PF7 + PK0-1
/// PHI2 PB6
/// RW PK2
/// RS0 PK4
/// RESET PK5
/// IRQ PK6
/// CS1 PK7
/// IO PORTS TBD


use panic_halt as _;

use arduino_hal::{
    prelude::*,
    pac::{
        PORTA,
        PORTB,
        PORTK,
        PORTF,
        TC1, USART0,
    }, hal::{Usart, Atmega, port::{PE0, PE1}}, port::{Pin, mode::{Input, Output}}, clock::MHz16
};

static ROM_002: [u8; 1024] = *include_bytes!("../../../../roms/6530-002.bin");
static ROM_003: [u8; 1024] = *include_bytes!("../../../../roms/6530-003.bin");

#[arduino_hal::entry]
fn main() -> ! {
    let dp = arduino_hal::Peripherals::take().unwrap();
    let pins = arduino_hal::hal::pins!(dp);
    let mut serial = arduino_hal::hal::usart::Usart0::new(dp.USART0, pins.pe0.into(), pins.pe1.into_output(), arduino_hal::usart::Baudrate::<arduino_hal::hal::clock::MHz16>::new(115200));
    let dp = unsafe { arduino_hal::Peripherals::steal() };
    let mut timer = dp.TC1;
    let mut porta = dp.PORTA;
    let mut portb = dp.PORTB;
    let mut portf = dp.PORTF;
    let mut portk = dp.PORTK;
    start_1mhz_clock_out(&mut portb,  &mut timer);
    toggle_reset(&mut portk);
    test_rom_003(&mut porta, &mut portf, &mut portk, &mut serial);
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
    portk: &mut PORTK,
) {
    portk.ddrk.modify(|_, w| w.pk5().set_bit());
    portk.portk.modify(|_, w| w.pk5().set_bit());
    arduino_hal::delay_us(1);
    portk.portk.modify(|_, w| w.pk5().clear_bit());
    arduino_hal::delay_us(1);
    portk.portk.modify(|_, w| w.pk5().set_bit());
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
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>
) {
    
    portk.ddrk.modify(|_, w| {
        w.pk4().set_bit(); // RS0
        w.pk7().set_bit()  // CS1
    });

    portk.portk.modify(|_, w| {
        w.pk4().clear_bit(); // RS0
        w.pk7().set_bit()  // CS1
    });


    for addr in 0..1023 {
        let byte_read = bus_read(porta, portf, portk, addr);
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

    portk.ddrk.modify(|_, w| {
        w.pk0().set_bit();
        w.pk1().set_bit()
    });

    portf.portf.write(|w| {
        unsafe { 
            w.bits(addr as u8)
        }
    });

    portk.portk.modify(|_, w| {
        w.pk0().bit(addr & 0b0100000000 >> 8 > 0);
        w.pk1().bit(addr & 0b1000000000 >> 9 > 0)
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

