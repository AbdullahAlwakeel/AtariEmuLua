# AtariEmuLua

Note: Work has stopped on this project. I am uploading the code for anyone who is interested in the implementation or details of the CPU (6507/6502), TIA, or Audio processing which are mostly complete. However, the only feature left to implement is more types of bankswapping cartridges simulation (it supports F6, F8, and the Pitfall 2 backswapping scheme)

Project start/stop date: 2017

An Atari2600 emulator written almost entirely using Lua. Uses LuaJIT and SDL Lua port for displaying graphics. This implementation prioritizes easy-to-understand code than performance gains, however it still performs very fast ( > 500fps without fps limiting) thanks to the JIT compiler for Lua.

This project was ported from a previous project that used pure Lua, and was writted in Codea for iPad. Hence, there are many residual code (commented out) that was meant to work only for the Codea version of Lua.

Lua (+JIT) is used for all operations including emulation, displaying graphics, taking user input, and generating audio. A single C file (audio_callback.c) is used to handle the audio buffer for SDL (simply copies the Lua audio buffer to the SDL audio buffer).

The program supports binary ROM files, as well as .txt files containing hex values for every byte (used for Lua versions that do not support binary read eg. Codea). This emulator has been tested on a number of Atari games and works succesfully on 2k cartridges and F8/F6 bankswapping cartridges. Pitfall 2 bankswapping scheme is implemented though untested.

# Details:

Atari2600.lua: Class that contains the Atari2600 emulator. Contains all subsystems, including CPU, TIA, sound, user input, etc.

P6502.Lua: Implements the main processor of the Atari2600 (6507 variant of 6502 processor). It passes multiple number of processor instruction tests, stack operation tests, and general tests. It implements all documented 6502 instructions, as well as the undocumented / extended instruction set.

TIA.lua: Implements the Atari 2600 graphics processing chip (Television Interface Adapter). All operations including sprite drawing, collision detection, and register updating / timing is implemented.

RIOT.lua: Implements the timing chip for the Atari 2600.

Sound.lua: Implements the sound processor chip for the Atari 2600. During startup, the emulator creates a lookup wavetable for every possible sound a single sound channel can produce (which is suprisingly low). Then, it reads the sound registers and outputs the specific wave corresponding to the register values to a C file (audio_callback.c) which copies the value to the SDL audio buffer. This C file had to be pre-compiled in order to work with SDL, as the audio buffer code did not support JIT.

Bankswitch.lua: This file implements 3 bankswitching schemes that are used in the Atari2600 cartridges.