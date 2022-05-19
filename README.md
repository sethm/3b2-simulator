# AT&T 3B2/400 and 3B2/700 Simulator

## About

This is an AT&T 3B2/400 and 3B2/700 simulator. It can simulate the following
computer systems and run unmodified 3B2 software:

### 3B2/400

![3B2/400](https://archives.loomcom.com/3b2/images/3b2_400.png)

3B2 Version 2 system with the following components avaialble:

 - 3B2 Model 400 System Board with 1 MB, 2 MB, or 4 MB RAM
 - WE32100 CPU at 10MHz (CPU)
 - WE32101 MMU (MMU)
 - WE32106 Math Accelerator (MAU)
 - PD8253 Interval Timer (TMR)
 - AM9517 DMA controller (DMAC)
 - SCN2681A Integrated DUART (IU)
 - TMS2793 Integrated Floppy Controller (IFLOPPY)
 - uPD7261A Integrated MFM Fixed Disk Controller (IDISK)
    - 30 MB winchester disk
    - 72 MB winchester disk
    - 161 MB winchester disk
 - Non-Volatile Memory (NVRAM)
 - MM58174A Time Of Day Clock (TOD)
 - CM195A Ethernet Network Interface (NI)
 - CM195B 4-port Serial MUX (PORTS)
 - CM195H Cartridge Tape Controller (CTC)
    - 23 MB streaming QIC tape

### 3B2/700

![3B2/700](https://archives.loomcom.com/3b2/images/3b2_700.png)

3B2 Version 3 system with the following components avaialble:

 - 3B2 Model 700 System Board (CM518B) with up to 64 MB of RAM
 - WE32200 CPU at 18MHz (CPU)
 - WE32201 MMU (MMU)
 - WE32206 Math Accelerator (MAU)
 - PD82C54 Interval Timer (TMR)
 - AM9517 DMA controller (DMAC)
 - SCN2681A Integrated DUART (IU)
 - TMS2793 Integrated Floppy Controller (IFLOPPY)
 - Non-Volatile Memory (NVRAM)
 - MM58274C Time Of Day Clock (TOD)
 - CM195A Ethernet Network Interface (NI)
 - CM195B 4-port Serial MUX (PORTS)
 - CM195W SCSI Controller Card (SCSI)
    - 155 MB SCSI disk
    - 300 MB SCSI disk
    - 327 MB SCSI disk
    - 630 MB SCSI disk
    - 120 MB SCSI QIC tape

## Acknowledgements

The simulator framework used to control the 3B2 simulator, known as SCP
("Simulator Control Program"), is based on the SIMH project, originally written
by Robert M. Supnik. Many people have contributed to the SIMH project, and
I wish to thank them all for their work. The 3B2 simulator in its current
form would not be possible without them.

## Copyright

Portions of this code are Copyrighted by the following authors:

  - J. David Bryan
  - Matt Burke
  - Howard M. Harte
  - John R. Hauser
  - David T. Hittner
  - Tod C. Miller
  - Seth J. Morabito
  - Mark Pizzolato
  - Robert M. Supnik

Copyright is acknowledged in each contributed file.

## License

Please see the license statement included in each source code file.

Unless otherwise specified, the following license applies:

    Copyright (c) 2022, Seth J. Morabito

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation files
    (the "Software"), to deal in the Software without restriction,
    including without limitation the rights to use, copy, modify, merge,
    publish, distribute, sublicense, and/or sell copies of the Software,
    and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
    BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
    ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Except as contained in this notice, the name of the author shall not
    be used in advertising or otherwise to promote the sale, use or
    other dealings in this Software without prior written authorization
    from the author.

