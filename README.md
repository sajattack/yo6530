![yo6530 running a KIM-1 replica](img/yo6530.jpg)

[![build status](https://builds.sr.ht/~sajattack/yo6530.svg)](https://builds.sr.ht/~sajattack/yo6530?)

## Dependencies
- FPGA Toolchain: https://github.com/YosysHQ/oss-cad-suite-build
- Simulator: https://verilator.org/guide/latest/install.html
- C++ toolchain: gcc and gnu make
- Trace Viewer: https://gtkwave.sourceforge.net/
- SPI flash programmer: https://www.flashrom.org/
- Linter: https://github.com/chipsalliance/verible
- Hardware research in dwfpy directory uses a Digilent Digital Discovery, python and the dwfpy library to probe and stimulate a MOS6532, for understanding expected behaviour from real hardware

## Target Hardware
https://github.com/daglem/redip-riot

## Programming the board using Raspberry Pi (3B) with flashrom
### Wiring
![image](https://github.com/user-attachments/assets/bc206d53-67dd-4660-89ce-49be5b99f39b)
| Raspi pin name/num  | ReDIP RIOT name/num|
| ------------------- | -----------------|
| SCK / 23            | SPI_SCLK / 3     |
| MISO / 21           | SPI_SIO1 / 5     |
| MOSI / 19           | SPI_SIO0 / 7     |
| CE0 / 24            | SPI_CS / 1       |
| GPIO25 / 22         | CDONE / 2        |
| 3v3 / 17            | 3v3 / 8          |
| GND / 20            | GND / 6          |
| GPIO24 / 18         | CRESET / 4       |

```sh
make # build the project
scp build/mcs6530.bin pi@<your-pi's-ip>: # copy the build artifact to the pi for flashing
ssh pi@<your-pi's-ip> # connect to the pi
sudo raspi-config # go into the interfaces menu and enable spi after running this command
pinctrl set 24 op dl # put the board into programming mode by setting creset low
flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=20000 # if this detects the device, all is good, otherwise check your spi is enabled and your wiring
truncate -s 128K mcs6530.bin # pad the rom to 128K
flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=20000 -w mcs6530.bin # write the flash
pinctrl set 24 ip pu # exit programming mode by returning creset to input pullup
```

## Building and running the simulation tests
```sh
make sim
./obj_dir/Vverilator_top # this will throw assertion errors if the tests fail
```
Also you can examine the logic signals output during the test in the Vverilator_top.vcd file using [GTKWave](https://gtkwave.sourceforge.net/)
