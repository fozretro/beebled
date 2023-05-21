
BeebLED
=======

So after nearly a year at this point (24th Nov 2022) of learning electronics, "re"collecting various retro computers, modifying and fixing them. I figured I would revist a childhood dream to have my own scrolling message board! Just like the ones down my local kebab shop! So lets build an LED matrix scroller for the Beeb! The proof of concept can be found [here](https://www.reddit.com/r/beneater/comments/xq2d4h/completed_6502_project_with_led_scroller/).

You can also see a demo video [here](https://drive.google.com/file/d/1L_YhwlXpUD0SaMJsGKrx3CFpbm8zI_nu/view).

![](/img/BeebLED.png)
![](/img/BeebLEDv1-1.jpg)

Credits
=======
- [Ben Eater](https://eater.net/6502), for opening my eyes to the joy of hardware and software building together!
- [Anders Brauner Nielsen](https://abnielsen.com), his well timed [blog](https://abnielsen.com/2021/12/23/ws2812b-rgb-lights-on-a-6502/) turned up (to my suprise) in my web searches for 6502 and LEDs! His ingenious circuit, with some additional components and modificaitons is at the core of this solution! Thank you Anders!
- [StarDot Forums](https://stardot.org.uk/forums/), the place for advice and encourgement for all your Acorn projects! This project uses [BeebASM](https://github.com/stardot/beebasm), [UPURSFS](https://www.retro-kit.co.uk/UPURS/) and [Visual Studio Code Extension for BeebASM](https://marketplace.visualstudio.com/items?itemName=simondotm.beeb-vsc). The authors of these amazing tools also hangout on stardot!

Usage
=====

It is a little early in development to complete this section, though my eventual goal is some kind of ROM, possibly using sideways RAM to avoid using the main RAM. Maybe even a VDU driver to plot stuff on the LED display? For now please see [this StarDot Forum thread](https://stardot.org.uk/forums/viewtopic.php?f=3&t=26047).

Developmet Tools
================

The ```/dist``` always contains the latest .ssd, but if you want to try to build it locally this section contains my notes on how I set things up with UPURSFS.

- Shift+Command+B bulds stuff and copies over to ```/dev/beebled``` and ```/dist```
- Shift+Ctrl+T launches the emulator (hard coded to where I have it)
- See below for connecting Beeb to the ```/dev/beebled``` folder to test hardware

Running UPURSFS and TubeHost
----------------------------

This enables the fastest possible inner loop for development, build on the Mac and instantly the compiled output is visble to the connected Beeb! This is especially useful since the only way (currently without mocking) is to see results is on real hardware.

**On the Beeb**, have UPURSFS ROM installed and pressing U+Break, U+Crl+Break or U+Shift+Break. If it says (No RTS) things are not connected - check the cable. See general instructions in the ```/bin/UPURSFS/Tubehost/README.txt```. ```*HSTATUS``` is a good test command. Press Ctrl+U+Break to boot the ```/dev/beebled``` disc on the Beeb. Note if you have ```Configure BOOT``` setup you have to use Ctrl+U+Break, if this gets frustrating just switch auto boot off.

**On the Mac**, you need to run ```/bin/UPURSFS/TubeHost/TubeHost.perl```. I had some issues running it and posted on StarDot forums what I found and my fix, see [here](https://stardot.org.uk/forums/viewtopic.php?f=3&t=24976) and also other tips.

```perl ./bin/UPURSFS/TubeHost/TubeHost.perl -U /dev/cu.usbserial-FTCL544Z```

By default the files it serves up to the BBC are in ```$HOME/Beeb_Disks```, however the above script has been modified to serve from ```/dev```. Note that when working on the files on the Beeb changes are also instantly reflected as well. For example when editing the sprites using the native Acorn GFX sprite editor and commands as described below.

Updating Sprites
----------------

Sprites can be used in the scroller and use the Acorn GFX sprite file format. You must then use the Acorn GFX Sprites ROM if on Master (as shown below), or one of the others if on other systems to edit. Note if you use a Master to edit the sprites and use the ROM in Sideways RAM the reminder of the ram bank is used for your sprites storage nice! Bellow is using indirect way of loading via memory as on UPURS ```SRLOAD``` command hangs.

```*LOAD R.SPRITES 3000```

```*SRWRITE 3000 6000 8000 4```

```*SLOAD Sprites```

Use commands like ...

```*SEDIT 1```

```*SDELETE 1```

```*SRENUMBER 4 1```

Then use to save ... (last two commands if on UPURS only)

```*SSAVE Sprites```

```*HTSTATUS```

```*CLOSE```

TODO's
======

Software
--------
- Add support #s command to support sprites of different heights (hard coded to 8)
- Build config. for the MODE2 emulation of LED output (consider using MODE 8)
- Remove hard coded mode2 calculated rows table and replace with asm macro script?
- Add config to support different size led panels, constants and logic behavior hard codedto 11x44
- It is not optimized other than having a secondary display buffer to ensure consistent timing output to the LED. Likely when I share this further, it can be optimized even further with feedback. 
- Implement 1 pixel scroll (currently 2 pixel)
- Eventually I would like to have the code in a ROM, e.g. *BEEBLED Hello World, or *BEEBLED #m3000 (displays whats on screen), and/or maybe a VDU driver? Not sure what to do about storage, use sideways ram if ROM loaded into sideways ram bank? Otherwise take PAGE?

Hardware
---------
- Experiment with adding additional 11x44 pixel matrix for longer and/or wider displays
- Build and Populate the PCB and test it!

Development Diary
=================

20th May 2023
-------------
- Week prior to today, the PCB arrived from PCBWay, along with various components
- Assemebling on and off during weekday evenings
- First test failed!
- Made a quick hack to the code to simply flip 1 LED off and on with a keypress, should add this in the future as a flag
- After compariing with the prototype and studying the PCB layout, realized i flipped the diode footprint on the PCB layout!
- Also found that the matrix JST connector I used is to small
- Have the breadboard prototype to compare signals really helped!
- After a soldering the matrix fly lead diretly to the PCB for now, and flipping the diode, success!
- Next job fix the PCB design, and source larger JST connector, also publish a BOM
- Then build the next version!

5th May 2023
------------
- Reproduce the circuit in Kicad
- Design the PCB in Kicad
- Build PCB via PCBWay
- Share the designs

Dec 25th
--------
- Removed hard coded font and used OS API to get character definitions

Dec 24th
--------
- Updated flash screen with new BeebLED logo
- Shorter default message with new holiday themed sprite!
- Published repo on fozretro GitHub
- Made a video shared on StarDot

Dec 21-23rd
-----------
- Implemented expressing sprite, text color changes and pause in message string

```#cX - Text color where x is 0-7```

```#pX - Pause for 0-9 seconds```

```#sX - Scroll on sprite 0-9 for now assumed 8 pixels with, but can be variable width```

```#dX - Display sprite 0-9 then scroll```

- Acorn GFX sprites are stored in logical top-down order for rows but right-left order horizontally, would love to know why?!?! Optimization in the sprite plotting code?

Dec 20th
--------
- Fixed the colors on the LED since moving to how true Mode 2 pixels are encoded
- Its not the most performant code right now - more tables or something needed in the future
- Refactored a little into two other .asm files
- Added some commands as follows

```#cX - Text color where x is 0 to 7```

```#sp - Pause for 0 to 9 seconds```

```#d - Display sprite 0```

Dec 19th
--------
- Broke the pixel coloring being output to the LED, since using true Mode 2 pixel encoding
- Removed hard coded scrolling message and splash screen
- Now loads from Acorn GFX sprite file and text file respectively
- Very strange format for sprites not sure how performant it will be to scroll in sprites
- Oh and implemented a debug feature to write to mode 2 screen as well as the LED
- Made sure all files under ```/dev/beebled``` are also copied to ```.ssd```

Dec 18th
--------
- In understanding the Acorn GFX sprite editor I mostly spent a few hours realizing my encoding for MODE 2 I had in mind was wrong and does not match the Beebs after all!
- So I wanted some way to easily add graphics into the scroller and decided to investigate the Acorn GFX sprite editor and its file format ... (later read same on StarDot doh)
    - File length - 2 bytes (including these two bytes)
    - Number of spirtes in file (not zero based) - 1 byte
    - Sprite
        - width (in bytes - base zero) - 1 byte
        - height (in bytes - base zero) - 1 byte
        - size (in bytes) - 2 byte
        - mode - 1 byte
        - id - 1 byte
        - data - bytes
- Ideas for message text format and making BeebLED configurable!
    - Scroll on a sprite, sprites smaller than 11 pixels in height get a border
    - Option to just display it a sprite on a clear screen then scroll
    - Scroll text uses built in font (for now!)
    - Pause the scrolling for x seconds
    - Change scroll direction 
    - Syntax ideas... ```#S1 #P5 This is the rest of the message... I #S2 my Beeb!```
    - Have sprites dynamically loaded, if ```Sprites``` file exists
    - Have message dynanically loaded, if ```Message``` file exists
- Added GFX ROMS and setup dummy config files Sprites and Message
- Drew the very early prototype splash screen from Sarah and stores in ```Sprites```

Dec 16th
--------
- Added basic argument reading to pass in different messages (really just to play with it for now - want to make a set of ROM commands for this). Now supports ```*BEEBLED My Message!```
- Exit the app on key press back to command line

Dec 12th
--------
- Fixed most of the gitter I  was seeing by remove fly leds, attach end of cable direct to breadboard - it still occurs now and again - but not enough to stop me progressing with some more of the software side of things

Dec 11th
--------
- Ported over code from my Ben Eater project which used a different compiler and memory addreses.
- Success! We have LED scroller powered by a BBC Micro!
- Well with the some glitching, which I think is due to fly leads etc. So I think I will atttempt to direct connect the User Port cable end more directly to the board with some pins.
- This is quite a milestone, so once I can fix the glitching I'll do a share on stardot
- Next up make the software a bit more accessible, to pass a message in from the command line
- After that likely I can split my time between software and progressing a schematic and pcb

Dec 10th
---------
- After much reading and re-learning I probed each of the steps in converting the Beebs clock pulse into a pulse to latch the data into the serial output IC. I noticed the inversion happening and decided to use an additional input/output on the 74HC14, 6A and 6Y, to have pulse generated on the actual Beebs pulse, not the inversion of it.
- I also found that if I have the LEDs to bright, the signal I think suffers and LEDs remain on or don't show the correct color. I probably need some more smoothing capactitors in some place?!?! Anyway the software fix was to low the brightness and hey presto it all stablized! I fill the 11x44 matrix with pixels and toggled them on and off with success. 
- Next up more fun with software for a bit! Scrolling message here we come!

Dec 4th
-------
- WIP > Coping over some code from my very first prototype [here](https://www.reddit.com/r/beneater/comments/wd6irw/ben_eater_6502_computer_driving_ws2812b_rgb_leds/) - trigger based on keypress as no timer code setup yet
- Partial success I can toggle an LED and show a strip of them..... but the signals are out
- However on closer inspection the data signal to LED matrix is missing the first bit of each byte sent via CB2, it sends a 0 and then only the first 7 bits from CB2 are being sent. Looking at it through my scope I can see that the small pulse sent to the PL pin is being sent to soon before data on CB2 starts to be sent. Afterwards due to timing the second pulse picks up the tail end of the first bit of data from CB2, but by this time the circuit has of course sent 1 of 8 bits.
-When I look at the data sheet for mode 110 it does show this as well. The odd thing is on the Ben Eater system above it worked fine (I plan to do more compares at the weekend with my scope).

Dec 2nd, 3rd
--------
- Built a new breadboard of the circuit to send to LED matrix I used for my Ben Eater computer [here](https://www.reddit.com/r/beneater/comments/wd6irw/ben_eater_6502_computer_driving_ws2812b_rgb_leds/)
- Tested on the above and works fine - yay!
- Will it work on the Beeb though? Is the data line to long? Had sights of clitchs on the original breadboard when this was the case?

27th Nov
--------
- Labelled up some GND, CB1 and CB2 fly leads from the cable socket ready to plug into breadboard
- Write some basic code that sets up the VIA and send bytes (keyboard input)so I could monitor with my scope to check the basic serial output is working from beeb user port. Monitoring CB1 and CB2 shows signals as expected. Nice!
- Also fixed !BOOT

26th Nov
--------
- Udpated the README with some info on the dev tools and captured pinout for user port
- Some good notes [here](https://stardot.org.uk/forums/viewtopic.php?t=11671) on testing user port
- I tested my cable pins do have 5v on them yay!

24th Nov
--------
- Built a BBC user port cable and tested continuity it with my meter
- Setup this project with various VSCode tasks and levergaging the UPURSFS file system to make stuff available instantly on the connected Beeb for testing. 
