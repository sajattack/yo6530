#![no_std]
#![no_main]

#![feature(abi_avr_interrupt)]
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
    pac::{
        PORTA,
        PORTB,
        PORTC,
        PORTK,
        PORTF,
        PORTH,
        PORTG,
        PORTD,
        TC1, USART0, EXINT,
    }, hal::{Usart, Atmega, port::{PE0, PE1}}, port::{Pin, mode::{Input, Output}}, clock::MHz16
};

static ROM_002: [u8; 1024] = *include_bytes!("../../../../../roms/6530-002.bin");
static ROM_003: [u8; 1024] = *include_bytes!("../../../../../roms/6530-003.bin");

#[avr_device::interrupt(atmega2560)]
fn INT0() {
    //let dp = unsafe { arduino_hal::Peripherals::steal() };
    //let pins = arduino_hal::hal::pins!(dp);
    //let mut serial = arduino_hal::hal::usart::Usart0::new(dp.USART0, pins.pe0.into(), pins.pe1.into_output(), arduino_hal::usart::Baudrate::<arduino_hal::hal::clock::MHz16>::new(115200));
    //ufmt::uwriteln!(&mut serial, "INTERRUPT FIRED\r").unwrap();
}

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
    let mut exint = dp.EXINT;

    // disable pull-ups
    dp.CPU.mcucr.modify(|_, w| { w.pud().set_bit()});

    start_1mhz_clock_out(&mut portb,  &mut timer);
    //start_125KHz_clock_out(&mut portb,  &mut timer);
    toggle_reset(&mut portb);
    test_rom_003(&mut porta, &mut portb, &mut portf, &mut portg, &mut porth, &mut serial);
    test_ram_003(&mut porta, &mut portb, &mut portf, &mut portg, &mut porth, &mut serial);
    test_io_003(&mut porta, &mut portb, &mut portf, &mut portg, &mut porth, &mut portk, &mut serial);
    test_timer_003(&mut porta, &mut portb, &mut portf, &mut portg, &mut porth, &mut exint, &mut serial);
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

fn start_125KHz_clock_out(
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
        w.cs1().prescale_8();
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

    let mut error_count = 0;
    ufmt::uwriteln!(serial, "ROM 002 test start\r").unwrap();

    for addr in 0..1023 {
        let byte_read = bus_read(porta, portf, portg, porth, addr);
        let byte_expected = ROM_002[addr as usize];

        if byte_read != byte_expected {
            ufmt::uwriteln!(serial, "ROM read mismatch. Expected 0x{:02X} Got 0x{:02X}\r", byte_expected, byte_read).unwrap();
            error_count += 1;
        }
    }
    ufmt::uwriteln!(serial, "Error count: {}\r", error_count).unwrap();
    ufmt::uwriteln!(serial, "Finished rom test.\r").unwrap();

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

    let mut error_count = 0;

    ufmt::uwriteln!(serial, "ROM 003 test start\r").unwrap();

    for addr in 0..1023 {
        let byte_read = bus_read(porta, portf, portg, porth, addr);
        let byte_expected = ROM_003[addr as usize];

        if byte_read != byte_expected {
            ufmt::uwriteln!(serial, "ROM read mismatch. Expected 0x{:02X} Got 0x{:02X}\r", byte_expected, byte_read).unwrap();
            error_count += 1;
        }
    }
    ufmt::uwriteln!(serial, "Error count: {}\r", error_count).unwrap();
    ufmt::uwriteln!(serial, "Finished rom test.\r").unwrap();

}

fn test_ram_003(
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
        w.pb7().set_bit() // RS0
    });
    porth.porth.modify(|_, w| {
        w.ph0().clear_bit()  // CS1
    });

    let start_addr = 0x380;

    let bytes = [0xAA, 0x55, 0xAA, 0x55, b'H', b'E', b'L', b'L', b'O', b'W', b'O', b'R', b'L', b'D', b'!'];

    ufmt::uwriteln!(serial, "RAM write start\r").unwrap();

    for addr in start_addr..start_addr + bytes.len() {
        bus_write(porta, portf, portg, porth, addr as u16, bytes[addr-start_addr]);
    }

    ufmt::uwriteln!(serial, "RAM read start\r").unwrap();

    let mut error_count = 0;
    for addr in start_addr..start_addr + bytes.len() {
        let byte_read = bus_read(porta, portf, portg, porth, addr as u16);
        let byte_expected = bytes[addr-start_addr];

        if byte_read != byte_expected {
            ufmt::uwriteln!(serial, "RAM read mismatch. Expected 0x{:02X} Got 0x{:02X}\r", byte_expected, byte_read).unwrap();
            error_count += 1;
        }
    }
    ufmt::uwriteln!(serial, "Error count: {}\r", error_count).unwrap();
    ufmt::uwriteln!(serial, "Finished ram test.\r").unwrap();

}

fn test_io_003(
    porta: &mut PORTA,
    portb: &mut PORTB,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    portk: &mut PORTK,
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>
) {
    portb.ddrb.modify(|_, w| {
        w.pb7().set_bit() // RS0
    });
    porth.ddrh.modify(|_, w| {
        w.ph0().set_bit() // CS1
    });

    portb.portb.modify(|_, w| {
        w.pb7().set_bit() // RS0
    });
    porth.porth.modify(|_, w| {
        w.ph0().clear_bit()  // CS1
    });

    ufmt::uwriteln!(serial, "Begin IO test\r").unwrap();
    // write RRIOT DDRA
    let addr = 0x301;
    let data = 0xff;
    bus_write(porta, portf, portg, porth, addr, data);

    // write RRIOT IO
    let addr = 0x300;
    let data = 0x55;
    bus_write(porta, portf, portg, porth, addr, data);
    
    // check output on PORTA (PK on the mega2560);
    portk.ddrk.write(|w| {
        w.pk0().clear_bit();
        w.pk1().clear_bit();
        w.pk2().clear_bit();
        w.pk3().clear_bit();
        w.pk4().clear_bit();
        w.pk5().clear_bit();
        w.pk6().clear_bit();
        w.pk7().clear_bit()
    });
    let porta_out = portk.pink.read().bits();
    if porta_out == data {
        ufmt::uwriteln!(serial, "Successfully output {} on PORTA", data).unwrap();
    }
    else {
        ufmt::uwriteln!(serial, "Output mismatch on PORTA, expected 0x{:02X}, got 0x{:02X}", data, porta_out).unwrap();
    }
    ufmt::uwriteln!(serial, "Finished IO test").unwrap(); 
}

fn test_timer_003(
    porta: &mut PORTA,
    portb: &mut PORTB,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    exint: &mut EXINT,
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>
) {

    portb.ddrb.modify(|_, w| {
        w.pb7().set_bit() // RS0
    });
    porth.ddrh.modify(|_, w| {
        w.ph0().set_bit() // CS1
    });

    portb.portb.modify(|_, w| {
        w.pb7().set_bit() // RS0
    });
    porth.porth.modify(|_, w| {
        w.ph0().clear_bit()  // CS1
    });

    unsafe { avr_device::interrupt::enable() }; 

    // enable INT0 falling edge interrupt
    exint.eicra.modify(|_, w| { w.isc0().val_0x02()});
    exint.eimsk.modify(|_, w| { w.int().bits(1)});

    ufmt::uwriteln!(serial, "Timer write start\r").unwrap();
    let addr = 0x30f;
    bus_write(porta, portf, portg, porth, addr, 0);

    ufmt::uwriteln!(serial, "Timer read start\r").unwrap();
    let addr = 0x30e;

    let timer_val = bus_read(porta, portf, portg, porth, addr);
    ufmt::uwriteln!(serial, "Timer value: {}\r", timer_val).unwrap();

    ufmt::uwriteln!(serial, "Timer read end\r").unwrap();
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
        w.pg0().bit(addr & 0b0100000000 > 0);
        w.pg1().bit(addr & 0b1000000000 > 0)
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
    porth.ddrh.modify(|_, w| {
        w.ph1().set_bit()
    });
    porth.porth.modify(|_, w| {
        w.ph1().clear_bit()
    });

    arduino_hal::delay_us(1);

    write_addr(portf, portg, addr);

    arduino_hal::delay_us(1);

    write_data(porta, data);

    arduino_hal::delay_us(1);

    // rw is ph1
    // deassert
    porth.porth.modify(|_, w| {
        w.ph1().set_bit()
    });

    // deassert data bus
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
    porta.porta.write(|w| {
        w.pa0().clear_bit();
        w.pa1().clear_bit();
        w.pa2().clear_bit();
        w.pa3().clear_bit();
        w.pa4().clear_bit();
        w.pa5().clear_bit();
        w.pa6().clear_bit();
        w.pa7().clear_bit()
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
    porth.ddrh.modify(|_, w| {
        w.ph1().set_bit()
    });
    porth.porth.modify(|_, w| {
        w.ph1().set_bit()
    });

    write_addr(portf, portg, addr);

    arduino_hal::delay_us(1);

    read_data(porta)
}

