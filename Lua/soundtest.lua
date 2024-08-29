local sdl = require 'ffi/sdl'
local ffi = require 'ffi'
local wm = require("lib/wm/sdl")
local uint32ptr = ffi.typeof( "uint32_t*" )

local a = ffi.load("audio_callback")
ffi.cdef([[
void *malloc(size_t size);
void free(void *ptr);
void *memset(void *ptr, int value, size_t size);
void audio_callback(void* userdata, unsigned char* stream, int len);
]])

local desired = ffi.new('SDL_AudioSpec')
local obtained = ffi.new('SDL_AudioSpec')

desired.freq = 44100
desired.format = 0x0008
desired.channels = 1
desired.samples = 256
desired.callback = a.audio_callback
desired.userdata = nil

if sdl.SDL_OpenAudio(desired, obtained) ~= 0 then
   error(string.format('could not open audio device: %s', ffi.string(sdl.getError())))
end

print(string.format('obtained parameters: format=%s, channels=%s freq=%s size=%s bytes',
                    bit.band(obtained.format, 0xff), obtained.channels, obtained.freq, obtained.samples))

function getpixel(x,y)
    return bit.band(x*100000,0xF0FDA8)-bit.bxor((y*1000)+3,0xf010A)
end

function render(screen)
    local pixels_u32 = ffi.cast( uint32ptr, screen.pixels )
    local width, height, pitch = screen.w, screen.h, screen.pitch / 4
    for i = 0, height-1 do
       for j = 0, width-1 do
	  pixels_u32[ j + i*pitch ] = getpixel(j/width,i/height)
       end
    end
end

--jit.off()
sdl.SDL_PauseAudio(0)
--wm:update()
while true do
    wm:update()
    render(wm.window)
    sdl.SDL_WM_SetCaption("hi", nil)
end
sdl.SDL_Quit()
