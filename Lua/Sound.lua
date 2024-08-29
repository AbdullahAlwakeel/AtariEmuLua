local sdl = require("ffi/sdl")
local ffi = require("ffi")

BIT4={ 1,255,255,1,1,255,1,255,1,1,1,1,255,255,255 }
BIT5={ 1,1,1,1,1,255,255,255,1,1,255,1,1,1,255,1,255,1,255,255,255,255,1,255,255,1,255,1,1,255,255 }
BIT5T =  { 1,0,0,0,0,1,0,0,1,0,1,1,0,0,1,1,1,1,1,0,0,0,1,1,0,1,1,1,0,1,0 }
BIT45={}
BITNOIS={}

POLY4=1
POLY5=2
POLY54=3
PURE=4
ON=5
NOISE=6
function GeneratePCM(Type)
    if Type == ON then
        return {255,255}
    elseif Type == POLY4 then --4BIT POLY
        return BIT4
    elseif Type == PURE then --PURE
        return {1,255}
    elseif Type == POLY5 then --5BIT POLY
        return BIT5
    elseif Type == POLY54 then --5BIT 4BIT
        if #BIT45 == 0 then
        for i=1, 31 do
            if BIT4[(i%15)+1] == 255 and BIT5T[i]==1 then
                BIT45[i]=255
            else
                BIT45[i]=1
            end
        end
        end
        return BIT45
    elseif Type == NOISE then
        for i=1, 64 do
            BITNOIS[i] = math.random(0,255)
        end
        return BITNOIS
    end
end

function GeneratePCMFreq(Type)
    local Frequency = 1
    local Waveform = PURE
    if Type == 0 or Type == 11 then
        Waveform = ON
    elseif Type == 1 then
        Waveform = POLY4
    elseif Type == 2 then
        Frequency = 15.0
        Waveform = POLY4
    elseif Type == 3 then
        Waveform = POLY54
    elseif Type == 4 or Type == 5 then
      Frequency = 2.0
    elseif Type == 6 or Type == 10 then
        Frequency = 31.0
    elseif Type == 7 then
        Frequency = 2.0
        Waveform = POLY5
    elseif Type == 8 then
        Waveform = NOISE
    elseif Type == 9 then
        Waveform = POLY5
    elseif Type == 12 or Type == 13 then
        Frequency = 6.0
    elseif Type == 14 then
        Frequency = 93.0
    elseif Type == 15 then
        Frequency = 6.0
        Waveform=POLY5
    end
    return GeneratePCM(Waveform), Frequency
end

CurrSOUND=0
CurrBUFF0 = {}
CurrBUFF1 = {}

SAMPLESPERFRAME = 4096

function GenerateBuffer(Type, Freq, Length)
    local F
    local data=""
    local datum, Fr = GeneratePCMFreq(Type)
    datum = string.char(unpack(datum))
    F = (Freq+1)*Fr
  --  print("Frequency="..F..", (Type="..Dec2Hex(Type)..", F="..Dec2Hex(Freq)..")")
    for i=1, math.floor(SAMPLESPERFRAME / (#datum*F)) do
        for j=1, #datum do
            for k=1, F do
                data = data .. datum:sub(j,j)
            end
        end
    end
    data = data .. datum:sub(1, math.ceil(((SAMPLESPERFRAME/#datum)-math.floor(SAMPLESPERFRAME / #datum))*#datum))
    if #data == 0 then
        data = data .. string.char(0)
    end
    --local b=soundbuffer(data,FORMAT_MONO8,F)
   -- print("length of datum: "..#datum)
  --  print("F value: "..F)
  --  print("Samples per frame: "..SAMPLESPERFRAME)
    print("length of data: "..#data..", Freq="..Freq..", Type="..Type)
  --  print("fraction: "..math.ceil(((SAMPLESPERFRAME/#datum)-math.floor(SAMPLESPERFRAME / #datum))*#datum))

    return data
end

SoundBuffers = {}

function MakeSoundTbl()
    for Type = 0, 15 do
        SoundBuffers[Type] = {}
        for Freq = 0, 31 do
            local d = GenerateBuffer(Type, Freq, (0.1))
            SoundBuffers[Type][Freq] = d
        end
    end
end

LastWave = nil
LastFreq = nil
LastVol = nil

function ClearSound()
    Buff = table.pack(string.byte(SoundBuffers[0][0],1,#SoundBuffers[0][0]))
    for i=1, #Buff do
        Buff[i] = math.floor(Buff[i]*volume)
    end
    Buff = string.char(unpack(Buff))

    --desired.userdata = ffi.C.malloc(#Buff)
    --ffi.copy(desired.userdata, Buff)

    --print("wave = "..wave..", freq = "..freq..", vol = "..volume)

    --print(S)

    --if CurrSOUND == 0 then CurrBUFF0 = Buff else CurrBUFF1 = Buff end
       -- desired.userdata = ffi.cast("void *", SoundBuffers[wave][freq])
      --  SIZEBUFF = #Buff
      --local c_str = ffi.new("char[?]", #Buff)
      --ffi.copy(Sound_Struct.data, Buff)
      for i=1, Sound_Struct.length do
        Sound_Struct.Data[i-1] = Buff[i]
      end

      --Sound_Struct.Data = c_str
      --Sound_Struct.length = #Buff
end

LastData = {-1, -1, -1, -1, -1, -1}

function PlaySound(wave,freq,volume, w2, f2, v2)
    if (LastData[1]==wave and LastData[2] == freq and LastData[3] == volume and LastData[4] == w2 and LastData[5] == f2 and LastData[6] == v2) then
        return 
    end
    LastData[1] = wave
    LastData[2] = freq
    LastData[3] = volume
    LastData[4] = w2
    LastData[5] = f2
    LastData[6] = v2
    --print("wave = "..wave..", freq = "..freq..", vol = "..volume..", len = "..#SoundBuffers[wave][freq])
    --print("w2: "..w2..", f2: "..f2..", v2: "..v2..", l2: "..#SoundBuffers[w2][f2])

    Buff = table.pack(string.byte(SoundBuffers[wave][freq],1,#SoundBuffers[wave][freq]))
    for i=1, #Buff do
        Buff[i] = math.floor(Buff[i]*volume)
    end

    Buff2 = table.pack(string.byte(SoundBuffers[w2][f2],1,#SoundBuffers[w2][f2]))
    for i=1, #Buff2 do
        Buff2[i] = math.floor(Buff2[i]*v2)
    end

    for i=1,math.max(#Buff,#Buff2) do
        if #Buff < #Buff2 then
            Buff[i] = math.min(Buff[(i % (#Buff))+1] + Buff2[i], 255)
        else
            Buff[i] = math.min(Buff[i] + Buff2[(i % (#Buff2))+1], 255)
        end
    end

    --Buff = string.char(unpack(Buff))

    --local c_str = ffi.new("char[?]", #Buff)


    --ffi.copy(Sound_Struct.Data, Buff)
    for i=1, Sound_Struct.length do
        Sound_Struct.Data[i-1] = Buff[(i % #Buff)+1]
    end

    --Sound_Struct.Data = c_str
    --Sound_Struct.length = #Buff

    --print("snd, length = " + #Buff)
    --Sound_Struct.Data_CH2 = d_str
    --Sound_Struct.length_CH2 = #Buff2
end