#![no_std]
#![no_main]

#![feature(abi_avr_interrupt)]
#![feature(asm_experimental_arch)]
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

use panic_serial as _;

panic_serial::impl_panic_handler!(
  // This is the type of the UART port to use for printing the message:
  arduino_hal::usart::Usart<
    arduino_hal::pac::USART0,
    arduino_hal::port::Pin<arduino_hal::port::mode::Input, arduino_hal::hal::port::PE0>,
    arduino_hal::port::Pin<arduino_hal::port::mode::Output, arduino_hal::hal::port::PE1>
  >
);

extern crate alloc;

use alloc::vec::Vec;

use core::{time::Duration, convert::Infallible};

use arduino_hal::{
    Pins,
    Peripherals,
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
        SPI,
    }, hal::{Usart, Atmega, port::{PE0, PE1}}, port::{Pin, mode::{Input, Output}}, clock::MHz16
};

use arduino_hal::hal::spi::{self, Spi, SpiOps};
use spi_flash::Flash;
use embedded_hal::{spi::SpiDevice, spi::SpiBus , digital::OutputPin};
use embedded_hal_bus::spi::ExclusiveDevice;

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
    let mut dp = arduino_hal::Peripherals::take().unwrap();
    let pins = arduino_hal::hal::pins!(dp);


    let mut serial = arduino_hal::hal::usart::Usart0::new(dp.USART0, pins.pe0.into(), pins.pe1.into_output(), arduino_hal::usart::Baudrate::<arduino_hal::hal::clock::MHz16>::new(115200));
    let mut serial = share_serial_port_with_panic(serial);

    let mut dp2 = unsafe { arduino_hal::Peripherals::steal() };


    let mut timer = dp2.TC1;
    let mut porta = dp2.PORTA;
    let mut portb = dp2.PORTB;
    let mut portk = dp2.PORTK;
    let mut portf = dp2.PORTF;
    let mut porth = dp2.PORTH;
    let mut portg = dp2.PORTG;
    let mut portd = dp2.PORTD;
    let mut exint = dp2.EXINT;

    // disable pull-ups
    //dp.CPU.mcucr.modify(|_, w| { w.pud().set_bit()});
    
    loop {
        ufmt::uwriteln!(serial, "Press 2 or 3 to test MOS6530-002 or MOS6530-003\r").unwrap();
        ufmt::uwriteln!(serial, "Press p to reprogram").unwrap();

        let input = serial.read_byte();

        start_1mhz_clock_out(&mut portb,  &mut timer);
        toggle_reset(&mut portb);

        if input == b'2' {
            test_rom_002(&mut porta, &mut portb, &mut portf, &mut portg, &mut porth, serial);
            test_ram_002(&mut porta, &mut portb, &mut portf, &mut portg, &mut porth, serial);
            test_io_002(&mut porta, &mut portb, &mut portf, &mut portg, &mut porth, &mut portk, serial);
            test_timer_002(&mut porta, &mut portb, &mut portf, &mut portg, &mut porth, &mut exint, serial);
        } 

        else if input == b'3' {
            test_rom_003(&mut porta, &mut portb, &mut portf, &mut portg, &mut porth, serial);
            test_ram_003(&mut porta, &mut portb, &mut portf, &mut portg, &mut porth, serial);
            test_io_003(&mut porta, &mut portb, &mut portf, &mut portg, &mut porth, &mut portk, serial);
            test_timer_003(&mut porta, &mut portb, &mut portf, &mut portg, &mut porth, &mut exint, serial);
        }

        else if input == b'p' {
            let dp3 = unsafe { arduino_hal::Peripherals::steal() };
            reprogram(dp3);
        }

        dp2 = unsafe { arduino_hal::Peripherals::steal() };

        let pins = arduino_hal::hal::pins!(dp2);
        serial = share_serial_port_with_panic(arduino_hal::hal::usart::Usart0::new(dp2.USART0, pins.pe0.into(), pins.pe1.into_output(), arduino_hal::usart::Baudrate::<arduino_hal::hal::clock::MHz16>::new(115200)));
        ufmt::uwriteln!(serial, "\r").unwrap();
    }
}

fn start_1mhz_clock_out(
    portb: &mut PORTB,
    timer: &mut TC1,
) {
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

fn test_rom_003(
    porta: &mut PORTA,
    portb: &mut PORTB,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>,
) {
    test_rom(porta, portb, portf, portg, porth, serial, &ROM_003);
}

fn test_rom_002(
    porta: &mut PORTA,
    portb: &mut PORTB,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>,
) {
    test_rom(porta, portb, portf, portg, porth, serial, &ROM_002);
}

fn test_ram_003(
    porta: &mut PORTA,
    portb: &mut PORTB,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>,
) {
    test_ram(porta, portb, portf, portg, porth, serial, 0x380);
}

fn test_ram_002(
    porta: &mut PORTA,
    portb: &mut PORTB,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>,
) {
    test_ram(porta, portb, portf, portg, porth, serial, 0x3c0);
}

fn test_io_003(
    porta: &mut PORTA,
    portb: &mut PORTB,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    portk: &mut PORTK,
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>,
) {
    test_io(porta, portb, portf, portg, porth, portk, serial, 0x300);
}

fn test_io_002(
    porta: &mut PORTA,
    portb: &mut PORTB,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    portk: &mut PORTK,
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>,
) {
    test_io(porta, portb, portf, portg, porth, portk, serial, 0x340);
}

fn test_timer_003(
    porta: &mut PORTA,
    portb: &mut PORTB,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    exint: &mut EXINT,
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>,
) {
    test_timer(porta, portb, portf, portg, porth, exint, serial, 0x300);
}

fn test_timer_002(
    porta: &mut PORTA,
    portb: &mut PORTB,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    exint: &mut EXINT,
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>,
) {
    test_timer(porta, portb, portf, portg, porth, exint, serial, 0x340);
}

fn test_rom(
    porta: &mut PORTA,
    portb: &mut PORTB,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>,
    rom: &'static [u8],
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

    ufmt::uwriteln!(serial, "ROM read start\r").unwrap();
    let mut error_count = 0;
    for addr in 0..rom.len() {
        let byte_read = bus_read(porta, portf, portg, porth, addr as u16);
        let byte_expected = rom[addr];

        if byte_read != byte_expected {
            ufmt::uwriteln!(serial, "ROM read mismatch. Expected 0x{:02X} Got 0x{:02X}\r", byte_expected, byte_read).unwrap();
            error_count += 1;
        }
    }
    ufmt::uwriteln!(serial, "Error count: {}\r", error_count).unwrap();
    ufmt::uwriteln!(serial, "Finished rom test.\r").unwrap();
}

fn test_ram(
    porta: &mut PORTA,
    portb: &mut PORTB,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>,
    base_addr: u16,
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

    let bytes = [0xAA, 0x55, 0xAA, 0x55, b'H', b'E', b'L', b'L', b'O', b'W', b'O', b'R', b'L', b'D', b'!'];

    ufmt::uwriteln!(serial, "RAM write start\r").unwrap();

    for addr in base_addr..base_addr + (bytes.len() as u16) {
        bus_write(porta, portf, portg, porth, addr as u16, bytes[(addr-base_addr) as usize]);
    }

    ufmt::uwriteln!(serial, "RAM read start\r").unwrap();

    let mut error_count = 0;
    for addr in base_addr..base_addr + (bytes.len() as u16) {
        let byte_read = bus_read(porta, portf, portg, porth, addr as u16);
        let byte_expected = bytes[(addr-base_addr) as usize];

        if byte_read != byte_expected {
            ufmt::uwriteln!(serial, "RAM read mismatch. Expected 0x{:02X} Got 0x{:02X}\r", byte_expected, byte_read).unwrap();
            error_count += 1;
        }
    }
    ufmt::uwriteln!(serial, "Error count: {}\r", error_count).unwrap();
    ufmt::uwriteln!(serial, "Finished ram test.\r").unwrap();

}

fn test_io(
    porta: &mut PORTA,
    portb: &mut PORTB,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    portk: &mut PORTK,
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>,
    base_addr: u16,
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
    let addr = base_addr+1;
    let data = 0xff;
    bus_write(porta, portf, portg, porth, addr, data);

    // write RRIOT IO
    let addr = base_addr;
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
        ufmt::uwriteln!(serial, "Successfully output 0x{:02X} on PORTA\r", data).unwrap();
    }
    else {
        ufmt::uwriteln!(serial, "Output mismatch on PORTA, expected 0x{:02X}, got 0x{:02X}\r", data, porta_out).unwrap();
    }
    ufmt::uwriteln!(serial, "Finished IO test\r").unwrap(); 
}

fn test_timer(
    porta: &mut PORTA,
    portb: &mut PORTB,
    portf: &mut PORTF,
    portg: &mut PORTG,
    porth: &mut PORTH,
    exint: &mut EXINT,
    serial: &mut Usart<USART0, Pin<Input, PE0>, Pin<Output, PE1>, MHz16>,
    base_addr: u16
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
    let addr = base_addr + 0xf;
    bus_write(porta, portf, portg, porth, addr, 0);

    ufmt::uwriteln!(serial, "Timer read start\r").unwrap();
    let addr = base_addr + 0xe;

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

    write_addr(portf, portg, addr);

    arduino_hal::delay_us(1);

    write_data(porta, data);

    arduino_hal::delay_us(1);

    // rw is ph1
    // deassert
    porth.porth.modify(|_, w| {
        w.ph1().set_bit()
    });
    porth.ddrh.modify(|_, w| {
        w.ph1().clear_bit()
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

fn reprogram(
    dp: Peripherals,  
) {
    let pins = arduino_hal::pins!(dp);
    let (spi, cs) = Spi::new(dp.SPI, pins.d52.into_output(), pins.d51.into_output(), pins.d50.into_pull_up_input(), pins.d53.into_output(), spi::Settings::default());
    let mut spi = ExclusiveDevice::new(spi, cs, arduino_hal::Delay::new()).unwrap();
    let mut spi = spi.bus_mut();
    let mut serial = arduino_hal::hal::usart::Usart0::new(dp.USART0, pins.d0.into_pull_up_input(), pins.d1.into_output(), arduino_hal::usart::Baudrate::<arduino_hal::hal::clock::MHz16>::new(115200));
    let mut interface = SpiFlashInterface::new(spi);
    let mut spi_flash = Flash::new(&mut interface);
    let result = spi_flash.erase();
    if result.is_err() {
        ufmt::uwriteln!(&mut serial, "Flash Erase Error\r");
    } else {
        ufmt::uwriteln!(&mut serial, "Flash Erase Success\r");
    }
    let result = spi_flash.program(0, &[0x55; 1], true);
    if result.is_err() {
        ufmt::uwriteln!(&mut serial, "Flash Verify Error\r");
    } else {
        ufmt::uwriteln!(&mut serial, "Flash Verify Success\r");
    }
}

use buddy_alloc::{BuddyAllocParam, FastAllocParam, NonThreadsafeAlloc};

const FAST_HEAP_SIZE: usize = 64; 
const HEAP_SIZE: usize = 1024;

pub static mut FAST_HEAP: [u8; FAST_HEAP_SIZE] = [0u8; FAST_HEAP_SIZE];
pub static mut HEAP: [u8; HEAP_SIZE] = [0u8; HEAP_SIZE];

// This allocator can't work in tests since it's non-threadsafe.
#[cfg_attr(not(test), global_allocator)]
static ALLOC: NonThreadsafeAlloc = unsafe {
    let fast_param = FastAllocParam::new(FAST_HEAP.as_ptr(), FAST_HEAP_SIZE);
    let buddy_param = BuddyAllocParam::new(HEAP.as_ptr(), HEAP_SIZE, 16);
    NonThreadsafeAlloc::new(fast_param, buddy_param)
};

struct SpiFlashInterface<'a> {
    spi: &'a mut Spi,
}

impl<'a> SpiFlashInterface<'a> {
    fn new(spi: &'a mut Spi) -> Self {
        Self {
            spi
        }
    }
}

impl<'a> spi_flash::FlashAccess for SpiFlashInterface<'a> {
    type Error = spi_flash::Error;

    fn exchange(&mut self, data: &[u8]) -> Result<Vec<u8>, Self::Error> 
    {
        let mut read_vec = Vec::new();
        read_vec.resize(8, 0);
        let result = self.spi.transfer(read_vec.as_mut(), data);
        match result {
            Ok(()) => Ok(read_vec),
            Err(_e) => Err(spi_flash::Error::Access)
        }
    }

    fn write(&mut self, data: &[u8]) -> Result<(), Self::Error> {
        let _ = self.spi.write(data);
        Ok(())
    }

    fn delay(&mut self, duration: Duration) {
        // this has pretty horrible accuracy but yolo
        if duration.as_micros() < 1000 
        {
            arduino_hal::delay_us(duration.as_micros() as u32);
        }
        else {
            arduino_hal::delay_ms(duration.as_millis() as u16);
        }
    }
}
