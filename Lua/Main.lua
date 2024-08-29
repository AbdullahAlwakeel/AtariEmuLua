    -- Atari2600
DRAWSCREEN=true
RenderOutsideScreen = false

package.path = "/Users/abdullahalwakeel/Desktop/Coding/lua/Atari2600/?.lua;/Users/abdullahalwakeel/Desktop/Coding/lua/Atari2600/?.dylib;" .. package.path

require("Pallete")
require("Bankswitch")
require("TIA")
require("Sound")
require("Functions")
require("6502Functions")
require("RIOT")
require("P6502")
require("Atari2600")

Pallete = NTSC
ROMNAME = "SpaceInvadersTbl.txt"
Debug = false
CurrS = F8BANKSWITCH
BankSwitchingEnabled = false
BINARYROM=false



local io = require("io")

-- Use this function to perform your initial setup

    local RomIO=io.open("/Users/abdullahalwakeel/Desktop/Coding/lua/Atari2600/"..ROMNAME, "rb")
    local RomT=RomIO:read("*all")
    print("Read ROM file.")
    io.close(RomIO)
    print("Finished Reading")
    print("ROM SIZE: "..#RomT.." bytes")
    if RomT:sub(1,1) == "{" then
     RomT=string.gsub(RomT:sub(2,#RomT - 2), "0x", "")
     RomT = string.gsub(RomT, ", ", "")
     ROM = HexDumpToROM(RomT)
    else
        if BINARYROM then
            if #RomT > 5000 then
                ROM={}
                for i=1, #RomT do
                    ROM[i] = string.byte(RomT, i, i)
                end
            else
            ROM = table.pack(string.byte(RomT, 1, #RomT))
            end
        else
        ROM = HexDumpToROM(RomT)
        end
    end
--    print(HexDump(ROM,1,#ROM))
    --print(WIDTH)
    Device=Atari2600
    Device:init(ROM)
    
    FPS = 60
    
    CyclesPerFrame = math.floor(ClockSpeed / FPS)
    print("CyclesPerFrame = "..CyclesPerFrame)
    --[[
    Device.TIA.INPT0 = 183
    Device.Core.Memory[8] = 1
    Device.TIA:Update(Device.Core.Memory)
      ]]
    --parameter.integer("InstructionPerSecond",1,60, function()     ClockSpeed=1/InstructionPerSecond end)
  --  parameter.action("Clear",function() background(20) end)
    if Debug==true then
        CyclesPerFrame=1
    end
    
    Time=0


   -- ClockSpeed=1/InstructionPerSecond
   if RenderOutsideScreen then
    Draw={}
    IMGWIDTH = MaxPixel
    IMGHEIGHT = MaxScanline
    for i=0, MaxPixel-1 do
        Draw[i] = {}
        for j=0, MaxScanline-1 do
            Draw[i][j] = 0x0
        end
    end
else
    IMGWIDTH = TVFieldWidth
    IMGHEIGHT = TVFieldHeight
    Draw = {}
    for i=0, TVFieldWidth-1 do
        Draw[i] = {}
        for j=0, TVFieldHeight-1 do
            Draw[i][j] = 0x0
        end
    end
end

    local ffi = require( "ffi" )
local sdl = require( "ffi/sdl" )
local wm = require( "lib/wm/sdl" )
local uint32ptr = ffi.typeof( "uint32_t*" )

local a = ffi.load("/Users/abdullahalwakeel/Desktop/Coding/lua/Atari2600/libaudio_callback.dylib")
ffi.cdef [[
    void *malloc(size_t size);
    void free(void *ptr);
    void *memset(void *ptr, int value, size_t num);
    void audio_callback(void* userdata, unsigned char* stream, int len);

    struct Sound {
        unsigned char *Data;
        int length;
    };
]]

--ffi.C.audio_callback();

local band, bor, bxor, shl, shr, rol, ror = bit.band, bit.bor, bit.bxor, bit.lshift, bit.rshift, bit.rol, bit.ror

function getpixel(x,y)
    return Draw[math.floor(x*IMGWIDTH)][math.floor(y*IMGHEIGHT)]
end

local function render( screen, tick )
    local pixels_u32 = ffi.cast( uint32ptr, screen.pixels )
    local width, height, pitch = screen.w, screen.h, screen.pitch / 4
    for i = 0, height-1 do
       for j = 0, width-1 do
	  pixels_u32[ j + i*pitch ] = getpixel(j/width,i/height)
       end
    end
end

do

    --sdl.SDL_Init(sdl.SDL_INIT_AUDIO)
    MakeSoundTbl()
        print("Made sound table")
        desired = ffi.new("SDL_AudioSpec")
        obtained = ffi.new("SDL_AudioSpec")
        Buff = SoundBuffers[0][20]
        --ffi.fill(ffi.new("SDL_AudioSpec[1]",desired), ffi.sizeof(desired))
        desired.freq = SoundClk
        desired.format = 0x0008
        desired.channels = 1
        desired.samples = SAMPLESPERFRAME
        --desired.userdata = ffi.cast("void *", ffi.cast("uint8_t *",CurrBUFF0))
        --desired.userdata = ffi.cast("void *",Buff)
        --SIZEBUFF = #SoundBuffers[4][20]
        --desired.callback = function(userdata, audio, size) for i = 0, size - 1 do audio[i] = i end end
        desired.callback = a.audio_callback
        --    print(size..", "..SIZEBUFF) end
        --ffi.fill(audio,size) end
        local c_str = ffi.new("char["..(#SoundBuffers[0][15]).."]", SoundBuffers[0][15])
        --ffi.copy(c_str, SoundBuffers[0][15])
        --end
        Sound_Struct = ffi.new("struct Sound" ,{Data = c_str, length = 4096})
        --ffi.copy(Sound_Struct.Data, SoundBuffers[2][15])
        desired.userdata = ffi.cast("void *", Sound_Struct) --userdata points to pointer that points to table
        if (sdl.SDL_OpenAudio(desired,obtained) < 0) then
            error(ffi.string(sdl.SDL_GetError()))
        else
            print("Completed Audio Open: "..obtained.freq..", "..obtained.format..", "..obtained.channels..", "..obtained.samples)
            sdl.SDL_PauseAudio(0)
        end
    --sdl.SDL_Mix_OpenAudio(SoundClk, AUDIO_U8, 1, 1024)
   local prev_time, curr_time, fps = nil, 0, 0, 0, 0


   local ticks_base, ticks = 256 * 128, 0, 0
   local bounce_mode, bounce_range, bounce_delta, bounce_step = false, 1024, 0, 1
    --local SoundPlaying = false
   while wm:update() do
    collectgarbage()
    --print(Device.ButtonPressed)
    --print(Device.TIA.INPT4)

        Device:draw(Draw)
      local event = wm.event
      local sym, mod = event.key.keysym.sym, event.key.keysym.mod
      --print(wm.kb)
      --print(event.type..", "..sdl.SDL_KEYDOWN)
      --print(Device.InputJoy.x..", "..Device.InputJoy.y)
      --print("wm.kb="..wm.kb)
      local Flip = 0
      if event.type == sdl.SDL_KEYUP then
        --print("KEY UP")
      elseif event.type == sdl.SDL_KEYDOWN then
        Flip = 1
        --print("KEY DOWN")
      end
      if wm.kb == 13 then --enter for reset
        Device.ResetPressed = (Flip==1)
      end

      if wm.kb == 8 and event.type == sdl.SDL_KEYUP then
        sdl.SDL_WM_ToggleFullScreen( wm.window )
      end
        

      if wm.kb == ("d"):byte() then --d for select switch
        Device.GameSelectPressed = (Flip==1)
      end

      if wm.kb == sdl.SDLK_LSHIFT or wm.kb == sdl.SDLK_RSHIFT then --any shift for joystick button
        Device.ButtonPressed = (Flip==1)
      end

      if wm.kb == 27 then --press escape to exit
	 wm:exit()
	 break
      end

      if wm.kb == sdl.SDLK_UP then --up arrow
        Device.InputJoy.y = Flip
      elseif wm.kb == sdl.SDLK_DOWN then --down arrow
        Device.InputJoy.y = -Flip
      end

      if wm.kb == sdl.SDLK_RIGHT then --right arrow
        Device.InputJoy.x = Flip
      elseif wm.kb == sdl.SDLK_LEFT then --left arrow
        Device.InputJoy.x = -Flip
      end

      ticks = sdl.SDL_GetTicks()

      -- Render the screen, and flip it
      render( wm.window, ticks)

      -- Calculate the frame rate
      prev_time, curr_time = curr_time, os.clock()
      local diff = curr_time - prev_time + 0.00001
      local real_fps = 1/diff
      if math.abs( fps - real_fps ) * 10 > real_fps then
	 fps = real_fps
      end
      fps = fps*0.99 + 0.01*real_fps
	 
      -- Update the window caption with statistics
      sdl.SDL_WM_SetCaption( string.format("Abdullah AlWakeel's ATARI2600: %d %s %dx%d | %.2f fps", ticks_base, tostring(bounce_mode), wm.window.w, wm.window.h, fps), nil )
   end
   sdl.SDL_Quit()
end
  --  Profiler:activate()


