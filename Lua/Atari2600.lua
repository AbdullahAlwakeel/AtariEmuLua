local bit = require("bit")
local ffi = require("ffi")
local band, bor, bxor, rshift, lshift = bit.band, bit.bor, bit.bxor, bit.rshift, bit.lshift

Atari2600 = {}

Pallete = PAL
ClockSpeed = 1789772 --NTSC

function Atari2600:ReadROM(key)
    if BankSwitchingEnabled then
        return self.ROM[GetROMAddress(key)]
    else
        return self.ROM[band(key,0xFFF)]
    end
end


function Atari2600:init(ROM)
    if Pallete ~= NTSC then
        ClockSpeed = 1773447 --PAL
    end
    -- you can accept and set parameters here
    self.ROM= ffi.new("uint8_t[?]", #ROM)
    --self.ROM={}
    for i=0, #ROM - 1 do
        self.ROM[i] = ROM[i+1]
    end
    if #ROM > 4096 then
        BankSwitchingEnabled = true
    else
        BankSwitchingEnabled = false
    end
    local Offset=0x1000
    self.Core=P6502
    self.Core:init()
    self.Core.StackStart = 0x00
    self.Core.AllowIllegals = true
    --self.Core.P.B=0
    self.Core.HaltOnError=false
    self.Core.HaltOnBRK=false


    self.Core.WriteMem = function(key,value)
        if key < 0x80 then
            if key > 0x3F then key = band(key,0x3F) end
            if key == 0x00 then
                self.TIA.VSYNC = true
                self.TIA.CurrLine = 0
            elseif key == 0x01 then
                self.TIA.VBLANK = value
                if band(rshift(value,6),0x1) == 1 then
                    self.INPT4 = 0xFF
                end
            elseif key == 0x02 then
                self.TIA.WSYNC = true
            elseif key == 0x03 then
                self.TIA.RSYNC = true
                self.TIA.CurrPixel = 0
            elseif key == 0x04 then
                self.TIA.NUSIZ0 = value
                self.TIA.M0Size = lshift(0x1,band(rshift(value,4),0x3))
                self.TIA.ChangedGraphics = true
            elseif key == 0x05 then
                self.TIA.NUSIZ1 = value
                self.TIA.M1Size = lshift(0x1,band(rshift(value,4),0x3))
                self.TIA.ChangedGraphics = true
            elseif key == 0x06 then
                self.TIA.COLUP0 = ColorPallete[value]
            elseif key == 0x07 then
                self.TIA.COLUP1 = ColorPallete[value]
            elseif key == 0x08 then
                self.TIA.COLUPF = ColorPallete[value]
            elseif key == 0x09 then
                self.TIA.COLUBK = ColorPallete[value]
            elseif key == 0x0A then
                self.TIA.CTRLPF = value
                self.TIA.BallSize = lshift(0x1,band(rshift(value,4),0x3))
                self.TIA.PlayfieldPriority = band(rshift(value,2),0x1) == 0x1
                self.TIA.ChangedGraphics = true
            elseif key == 0x0B then
                self.TIA.REFP0 = (band(rshift(value,3),0x1)==1)
            elseif key == 0x0C then
                self.TIA.REFP1 = (band(rshift(value,3),0x1)==1)
            elseif key == 0x0D then
                self.TIA.PF0 = value
                self.TIA.HalfPlayField = bxor(bxor(rshift(self.TIA.PF0,4),lshift((RevDec(self.TIA.PF1)),4)), lshift((self.TIA.PF2),12))
                self.TIA.ChangedGraphics = true
            elseif key == 0x0E then
                self.TIA.PF1 = value
                self.TIA.HalfPlayField = bxor(bxor(rshift(self.TIA.PF0,4),lshift((RevDec(self.TIA.PF1)),4)), lshift((self.TIA.PF2),12))
                self.TIA.ChangedGraphics = true
            elseif key == 0x0F then
                self.TIA.PF2 = value
                self.TIA.HalfPlayField = bxor(bxor(rshift(self.TIA.PF0,4),lshift((RevDec(self.TIA.PF1)),4)), lshift((self.TIA.PF2),12))
                self.TIA.ChangedGraphics = true
            elseif key == 0x10 then
                --self.TIA.DrewP0 = true
                --self.TIA.P0X = self.TIA.CurrPixel + 5
                self.TIA.RESP0 = true
                self.TIA.ChangedGraphics = true
            elseif key == 0x11 then
                --self.TIA.DrewP1 = true
                --self.TIA.P1X = self.TIA.CurrPixel + 5
                self.TIA.RESP1=true
                self.TIA.ChangedGraphics = true
            elseif key == 0x12 then
                --self.TIA.M0X = self.TIA.CurrPixel + 5
                self.TIA.RESM0 = true
                self.TIA.ChangedGraphics = true
            elseif key == 0x13 then
                --self.TIA.M1X = self.TIA.CurrPixel + 5
                self.TIA.RESM1=true
                self.TIA.ChangedGraphics = true
            elseif key == 0x14 then
                --self.TIA.BLX = self.TIA.CurrPixel + 5
                self.TIA.RESBL=true
                self.TIA.ChangedGraphics = true
            elseif key == 0x15 then
                self.TIA.AUDC0 = band(value, 0xF)
            elseif key == 0x16 then
                self.TIA.AUDC1 = band(value, 0xF)
            elseif key == 0x17 then
                self.TIA.AUDF0 = band(value, 0x1F)
            elseif key == 0x18 then
                self.TIA.AUDF1 = band(value, 0x1F)
            elseif key == 0x19 then
                self.TIA.AUDV0 = band(value, 0xF)
            elseif key == 0x1A then
                self.TIA.AUDV1 = band(value, 0xF)
            elseif key == 0x1B then
                self.TIA.WRP0=true
                self.TIA.NGRP0=value
                --self.TIA.OGRP1=self.TIA.GRP1
                --self.TIA.GRP0=value
            elseif key == 0x1C then
                self.TIA.WRP1=true
                self.TIA.NGRP1=value
                --self.TIA.OGRP0=self.TIA.GRP0
                --self.TIA.GRP1=value
            elseif key == 0x1D then
                self.TIA.ENAM0=(band(rshift(value,1),0x1) == 1) 
                self.TIA.ChangedGraphics = true
            elseif key == 0x1E then
                self.TIA.ENAM1=(band(rshift(value,1),0x1) == 1) 
                self.TIA.ChangedGraphics = true
            elseif key == 0x1F then
                self.TIA.ENABL=(band(rshift(value,1),0x1) == 1) 
                self.TIA.ChangedGraphics = true
            elseif key == 0x20 then
                self.TIA.HMP0 = rshift(value,4)
            elseif key == 0x21 then
                self.TIA.HMP1 = rshift(value,4)
            elseif key == 0x22 then
                self.TIA.HMM0 = rshift(value,4)
            elseif key == 0x23 then
                self.TIA.HMM1 = rshift(value,4)
            elseif key == 0x24 then
                self.TIA.HMBL = rshift(value,4)
            elseif key == 0x25 then
                self.TIA.VDELP0 = (band(value,0x1) == 1)
            elseif key == 0x26 then
                self.TIA.VDELP1 = (band(value,0x1) == 1) 
            elseif key == 0x27 then
                self.TIA.VDELBL = (band(value,0x1) == 1)
            elseif key == 0x28 then
                self.TIA.RESMP0=band(rshift(value,1),0x1) == 0x1
                self.TIA.ChangedGraphics = true
            elseif key == 0x29 then
                self.TIA.RESMP1=band(rshift(value,1),0x1) == 0x1
                self.TIA.ChangedGraphics = true
            elseif key == 0x2A then
                self.TIA.HMOVE = true
                self.TIA.ChangedGraphics = true
            elseif key == 0x2B then
                self.TIA.HMP0=0
                self.TIA.HMP1=0
                self.TIA.HMM0=0
                self.TIA.HMM1=0
                self.TIA.HMBL=0
            elseif key == 0x2C then
                self.TIA.CXM0P=0
                self.TIA.CXM1P=0
                self.TIA.CXP0FB=0
                self.TIA.CXP1FB=0
                self.TIA.CXM0FB=0
                self.TIA.CXM1FB=0
                self.TIA.CXBLPF=0
                self.TIA.CXPPMM=0
            end
        elseif (key >= 0x80 and key < 0x180) or (key >= 0x280 and key < 0x380) then
            self.RIOT.Memory[key] = value
        elseif (key >= 0x180 and key < 0x280) or key >= 0x380 and key < 0x1000 then
            self.RIOT.Memory[key - 0x100] = value
        elseif key >= 0x1000 then
            if CurrS == PITFALL2 then
                WritePitfall2(key,value)
            end
        end
    end

    self.Core.ReadMem = function(key) 
        if key >= 0x1000 then return self:ReadROM(key)
        elseif (key >= 0x180 and key < 0x280) or key >= 0x380 then
            return self.RIOT.Memory[key - 0x100]
        elseif key >= 0x80 then
            return self.RIOT.Memory[key]
        else
            if key > 0x0D then key = bit.band(key,0xF) end
            if key == 0x00 then
                return self.TIA.CXM0P or 0
            elseif key == 0x01 then
                return self.TIA.CXM1P or 0
            elseif key == 0x02 then
                return self.TIA.CXP0FB or 0
            elseif key == 0x03 then
                return self.TIA.CXP1FB or 0
            elseif key == 0x04 then
                return self.TIA.CXM0FB or 0
            elseif key == 0x05 then
                return self.TIA.CXM1FB or 0
            elseif key == 0x06 then
                return self.TIA.CXBLPF or 0
            elseif key == 0x07 then
                return self.TIA.CXPPMM or 0
            elseif key == 0x08 then
                return self.TIA.INPT0 or 0
            elseif key == 0x09 then
                return self.TIA.INPT1 or 0
            elseif key == 0x0A then
                return self.TIA.INPT2 or 0
            elseif key == 0x0B then
                return self.TIA.INPT3 or 0
            elseif key == 0x0C then
                return self.TIA.INPT4 or 0
            elseif key == 0x0D then
                return self.TIA.INPT5 or 0
            else
                return 0x0F
            end
        end
    end
    self.TIA=TIA
    self.TIA:new()
    --self.LastCycles=self.Core:ExecuteCode()
    self.LastCycles=0
    self.RIOT=RIOT
    self.RIOT:init()
    
    self.InputJoy = {x=0,y=0}
    self.ButtonPressed = false
    self.ResetPressed = false
    self.GameSelectPressed=false
    self.Core.PC = 0xF000
end

function Atari2600:draw(Frame)
    -- Codea does not automatically call this method
    --Frame:set(TVFieldStartPixel+1, MaxScanline-TVFieldStartScan, math.random(1,255),math.random(1,255),math.random(1,255))
    local Time=os.clock()
    local C=0
    self.RIOT.Memory[0x282] = 0x3F --color, easy difficulty, no switches pressed
    if self.ButtonPressed then
        --  self.Core.Memory[0]=1
        if band(rshift(self.TIA.VBLANK,6),0x1) == 1 then
            self.TIA.INPT4 = 0x00
        else
            self.TIA.INPT4 = 0x00
        end
    else
        if band(rshift(self.TIA.VBLANK,6),0x1) == 0 then --for non latched ports
        self.TIA.INPT4= 0x80
        end
    end
    if self.ResetPressed then
        self.RIOT.Memory[0x282] = 0x3E
        print("Reset pressed")
    else
        self.RIOT.Memory[0x282] = 0x3F
    end
    if self.GameSelectPressed then
        self.RIOT.Memory[0x282] = band(self.RIOT.Memory[0x282], 0xFD)
        print("Game select pressed")
        self.GameSelectPressed = false
    else
        self.RIOT.Memory[0x282] = bor(self.RIOT.Memory[0x282] , 0x2)
    end
    self.RIOT.Memory[0x280] = 0xFF
    if self.InputJoy.x > 0 then --right
        self.RIOT.Memory[0x280] = bxor(self.RIOT.Memory[0x280] , 0x80)
    elseif self.InputJoy.x < 0 then --left
        self.RIOT.Memory[0x280] = bxor(self.RIOT.Memory[0x280] , 0x40)
    end
    if self.InputJoy.y < 0 then --down
        self.RIOT.Memory[0x280] = bxor(self.RIOT.Memory[0x280] , 0x20)
    elseif self.InputJoy.y > 0 then --up
        self.RIOT.Memory[0x280] = bxor(self.RIOT.Memory[0x280] ,0x10)
    end
    self.TIA:Sound(0)
    self.TIA:Sound(1)
    while math.abs(C)<CyclesPerFrame do
        --self.Core.P.B=0
        --[[
            for i=0, 0x7f do
        self.Core.Memory[i]=nil
    end
          ]]
         -- local OldScan = self.TIA.CurrLine
    self.LastCycles = self.Core:ExecuteCode()
    for j=1, (3*self.LastCycles) do
        --  if self.Core.MemoryChanged[2]==true then break end
        self.TIA:DrawPixel(Frame)
    end
    self.TIA:Update()
     -- self.LastCycles = 4
        if Debug then
        print("Cycles passed: "..self.LastCycles)
            print(self.TIA.INPT4)
        end
        self.RIOT:Update()
        if self.TIA.WSYNC==true then
      --     DRAWSCREEN=false
            self.TIA.WSYNC=false
            local T=0
            while self.TIA.CurrPixel < MaxPixel-1 do
             self.TIA:DrawPixel(Frame)
                T=T+1
            end
            T=T+1
            C = C + math.floor(T/3) 
                        self.RIOT:Tick(math.floor(T / 3)+self.LastCycles)
            --       print((MaxPixel*MaxScanline).." pixels are drawn in about "..T.."seconds")
            self.TIA:DrawPixel(Frame)
    --        DRAWSCREEN=true
        else
            self.RIOT:Tick(self.LastCycles)
        end
        C = C + self.LastCycles
        if Debug then
           --local i = (((self.Core.Memory[(0x83 + self.Core.X + 1)&0xFF]<<4)+self.Core.Memory[(0x83+self.Core.X)&0xFF]))
   --   print(i..", $"..Dec2Hex(i))
        print("CurrPixel: "..self.TIA.CurrPixel..", CurrScan: "..self.TIA.CurrLine..", P0X: "..self.TIA.P0X..", P1X: "..self.TIA.P1X)
           end
  --      if (os.clock()-Time)*20 >= 1.0 then
            --  print((C/19552)*100)
          --     break
  --     end
       if self.TIA.CurrLine>=MaxScanline-1 and self.TIA.CurrPixel > MaxPixel - 5 then break end
    end
end