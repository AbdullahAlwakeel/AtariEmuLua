TIA = {}
local bit=require("bit")
local ffi=require("ffi")
local rshift, lshift, band, bor, bxor = bit.rshift, bit.lshift, bit.band, bit.bor, bit.bxor

function TIA:new()
    -- you can accept and set parameters here
    ColorPallete={}
    if Pallete == NTSC then
        SoundClk = 30000 --30kHz clock signal
        --generate NTSC pallete
        for lum=0, 7 do
            for c=0,15 do
                ColorPallete[(lum*2)+(c*16)] = (LumAdd(ColorsNTSC[c+1][1],lum)*0x10000) + (LumAdd(ColorsNTSC[c+1][2],lum)*0x100) + LumAdd(ColorsNTSC[c+1][3],lum)
                ColorPallete[(lum*2)+(c*16)+1] = ColorPallete[(lum*2)+(c*16)]
            end
        end
    elseif Pallete == PAL then
        SoundClk = 29726 --29.726kHz clock signal
        --generate pal pallete
        for lum=0, 7 do
            for c=0,15 do
               ColorPallete[(lum*2)+(c*16)] = (LumAdd(ColorsPAL[c+1][1],lum)*0x10000) + (LumAdd(ColorsPAL[c+1][2],lum)*0x100) + LumAdd(ColorsPAL[c+1][3],lum)
               ColorPallete[(lum*2)+(c*16)+1] = ColorPallete[(lum*2)+(c*16)]
            end
        end
    elseif Pallete == SECAM then
        for lum=0, 7 do
            for c = 0, 15 do
                ColorPallete[(lum*2)+(c*16)] = (ColorsSECAM[lum][1]*0x10000)+(ColorsSECAM[lum][2]*0x100)+ColorsSECAM[lum][3]
                ColorPallete[(lum*2)+(c*16)+1] = ColorPallete[(lum*2)+(c*16)]
            end
        end
    end
    self.VSYNC=false
    self.VBLANK=0
    self.WSYNC=false
    self.RSYNC=false
    self.NUSIZ0=0
    self.NUSIZ1=0
    self.COLUP0=0
    self.COLUP1=0
    self.COLUPF=0
    self.COLUBK=0
    
    self.CXM0P=0
    self.CXM1P=0
    self.CXP0FB=0
    self.CXP1FB=0
    self.CXM0FB=0
    self.CXM1FB=0
    self.CXBLPF=0
    self.CXPPMM=0
    self.INPT0=0
    self.INPT1=0
    self.INPT2=0
    self.INPT3=0
    self.INPT4=0
    self.INPT5=math.random(0,255)

    self.TIAWRITE = ffi.new("int16_t[?]", 0x80)
    
    self.M0X = 0
    self.M1X = 0
    
    self.CTRLPF=0
    self.ReflectPlayfield = false
    
    self.DrewP0=false
    self.DrewP1=false
    
    self.REFP0=false
    self.REFP1=false
    self.PF0=0
    self.PF1=0
    self.PF2=0
    self.RESP0=false
    self.RESP1=false
    self.RESM0=false
    self.RESM1=false
    self.RESBL=false
    
    self.BallSize = 0
    
    self.AUDC0=0
    self.AUDC1=0
    self.AUDF0=0
    self.AUDF1=0
    self.AUDV0=0
    self.AUDV1=0
    
    self.GRP0=0
    self.GRP1=0
    self.OGRP0=0
    self.OGRP1=0
    
    self.ENAM0=false
    self.ENAM1=false
    self.ENABL=false

    self.PlayfieldPriority = false
    
    self.P0X=0
    self.P1X=0
    self.BLX=0
    self.HMP0=0
    self.HMP1=0
    self.HMM0=0
    self.HMM1=0
    self.HMBL=0
    
    self.M0Size=0
    self.M1Size=0
    
    
 --   self.HalfPlayField = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    self.HalfPlayField = 0
    
    self.VDELP0=false
    self.VDELP1=false
    
    self.VDELBL=false
    self.RESMP0=false
    self.RESMP1=false
   self.HMOVE=false
    self.HMCLR=false
 --   self.CXCLR=NewByte()
    self.CurrLine=0
    self.CurrPixel=0
    self.CurrPlayfieldPixel=0
    if Pallete == NTSC then
    MaxScanline=MaxScanline_N
    MaxPixel=MaxPixel_N
    TVFieldWidth=TVFieldWidth_N
    TVFieldHeight=TVFieldHeight_N
    TVFieldStartScan=TVFieldStartScan_N
    TVFieldStartPixel=TVFieldStartPixel_N
    elseif Pallete == PAL or Pallete == SECAM then
    MaxScanline=MaxScanline_P
    MaxPixel=MaxPixel_P
    TVFieldWidth=TVFieldWidth_P
    TVFieldHeight=TVFieldHeight_P
    TVFieldStartScan=TVFieldStartScan_P
    TVFieldStartPixel=TVFieldStartPixel_P
    end
    TVFieldEndScan= TVFieldStartPixel+TVFieldHeight
end

function TIA:Update()
    -- Codea does not automatically call this method
--    local r = rawget
    if self.TIAWRITE[0] ~= -1 then
        self.VSYNC=true
    --    print("vsync")
    --    self.CurrPixel=0
        self.CurrLine=0
        self.TIAWRITE[0]=-1
    else
        self.VSYNC=false
    end
    if self.TIAWRITE[1] ~= -1 then
    self.VBLANK=self.TIAWRITE[0x1]
        if band(rshift(self.VBLANK,6),0x1) == 1 then
            self.INPT4 = 0xFF
        end
        self.TIAWRITE[1]=-1
    end
    if self.TIAWRITE[2] ~= -1 then
        self.WSYNC=true
        self.TIAWRITE[2]=-1
    else
        self.WSYNC=false
    end
    if self.TIAWRITE[3] ~= -1 then
        self.RSYNC=true
        self.CurrPixel = 0
        self.TIAWRITE[3]=-1
    else
        self.RSYNC=false
    end
    if self.TIAWRITE[4]~=-1 then
    self.NUSIZ0=self.TIAWRITE[4]
        self.M0Size = lshift(0x1,band(rshift(self.NUSIZ0,4),0x3))
        self.TIAWRITE[4]=-1
    end
    if self.TIAWRITE[5]~=-1 then
    self.NUSIZ1=self.TIAWRITE[5]
        self.M1Size = lshift(0x1,band(rshift(self.NUSIZ1,4),0x3))
    self.TIAWRITE[5]=-1
        end
    if self.TIAWRITE[6]~=-1 then
    self.COLUP0=ColorPallete[self.TIAWRITE[6]]
 --       self.Player0COL = ColorPallete[self.COLUP0]
    self.TIAWRITE[6]=-1
        end
  --  self.COLUP0=0x00
    if self.TIAWRITE[7]~=-1 then
    self.COLUP1=ColorPallete[self.TIAWRITE[7]]
 --       self.Player1COL = ColorPallete[self.COLUP1]
    self.TIAWRITE[7]=-1
        end
    
--    self.COLUP1=0xE7
    
    if self.TIAWRITE[8]~=-1 then
    self.COLUPF=ColorPallete[self.TIAWRITE[8]]
  --      self.PlayfieldCOL = ColorPallete[self.COLUPF]
        self.TIAWRITE[8]=-1
        end
    if self.TIAWRITE[9]~=-1 then
    self.COLUBK=ColorPallete[self.TIAWRITE[9]]
        self.TIAWRITE[9]=-1
  --      self.BackCOL=ColorPallete[self.COLUBK]
    end
    
    
    if self.TIAWRITE[0xA]~=-1 then
    self.CTRLPF=self.TIAWRITE[0xA]
        self.BallSize = lshift(0x1,band(rshift(self.CTRLPF,4),0x2))
        self.PlayfieldPriority = band(rshift(self.CTRLPF,2),0x1) == 0x1
        self.TIAWRITE[0xA]=-1
    end
    
    if self.TIAWRITE[0xB]~=-1 then
    self.REFP0=band(rshift(self.TIAWRITE[0xB],3),0x1)==1
        self.TIAWRITE[0xB]=-1
    end
    if self.TIAWRITE[0xC]~=-1 then
    self.REFP1=band(rshift(self.TIAWRITE[0xC],3),0x1)==1
    self.TIAWRITE[0xC]=-1
    end
    if self.TIAWRITE[0xD]~=-1 then
    self.PF0=self.TIAWRITE[0xD]
    self.TIAWRITE[0xD]=-1
        end
    if self.TIAWRITE[0xE] ~= -1 then
    self.PF1=self.TIAWRITE[0xE]
    self.TIAWRITE[0xE] = -1
    end
    if self.TIAWRITE[0xF] ~= -1 then
    self.PF2=self.TIAWRITE[0xF]
        self.TIAWRITE[0xF] = -1
    end
    
    self.HalfPlayField = bxor(bxor(rshift(self.PF0,4),lshift((RevDec(self.PF1)),4)), lshift((self.PF2),12))
   -- self.HalfPlayField = RevDec(self.PF1)
    --   self.HalfPlayField = {self.PF0[5],self.PF0[6],self.PF0[7],self.PF0[8],self.PF1[8],self.PF1[7],self.PF1[6],self.PF1[5],self.PF1[4],self.PF1[3],self.PF1[2],self.PF1[1],self.PF2[1],self.PF2[2],self.PF2[3],self.PF2[4],self.PF2[5],self.PF2[6],self.PF2[7],self.PF2[8]}
    
    if self.TIAWRITE[0x10] ~= -1 then
        self.DrewP0=true
        self.P0X=self.CurrPixel+5
    --   print("Resp0 "..self.CurrPixel)
        self.TIAWRITE[0x10]=-1
    end
    if self.TIAWRITE[0x11] ~= -1 then
        self.DrewP1=true
        self.P1X=self.CurrPixel+5
  --      print("Resp1 "..self.CurrPixel)
        self.TIAWRITE[0x11]=-1
    end
    
    --[[
    if self.RESP0 then
        self.DrewP0 = true
        self.P0X = self.CurrPixel + 9
    end
    if self.RESP1 then
        self.DrewP1 = true
        self.P1X = self.CurrPixel + 9
    end
      ]]
    if self.TIAWRITE[0x12] ~= -1 then
        self.M0X = self.CurrPixel + 5
        self.TIAWRITE[0x12] = -1
    end
    if self.TIAWRITE[0x13] ~= -1 then
        self.M1X = self.CurrPixel + 5
        self.TIAWRITE[0x13] = -1
    end
    if self.TIAWRITE[0x14] ~= -1 then
        self.BLX = self.CurrPixel + 5
        self.TIAWRITE[0x14] = -1
    end
    
    if self.TIAWRITE[0x15] ~= -1 then
    self.AUDC0=band(self.TIAWRITE[0x15],0xF)
        self.TIAWRITE[0x15] = -1
        end
   -- self.AUDC0 = 5
    if self.TIAWRITE[0x16] ~= -1 then
    self.AUDC1=band(self.TIAWRITE[0x16],0xF)
    self.TIAWRITE[0x16] = -1
        end
    
    if self.TIAWRITE[0x17] ~= -1 then
    self.AUDF0=band(self.TIAWRITE[0x17],0x1F)
    self.TIAWRITE[0x17] = -1
        end
  --  self.AUDF0 = 10
    if self.TIAWRITE[0x18] ~= -1 then
    self.AUDF1=band(self.TIAWRITE[0x18],0x1F)
    self.TIAWRITE[0x18] = -1
        end
    if self.TIAWRITE[0x19] ~= -1 then
    self.AUDV0=band(self.TIAWRITE[0x19],0xF)
        self.TIAWRITE[0x19] = -1
        end
   -- self.AUDV0 = 14
    if self.TIAWRITE[0x1A] ~= -1 then
    self.AUDV1=band(self.TIAWRITE[0x1A],0xF)
    self.TIAWRITE[0x1A] = -1
        end
    
    local GRP0=self.GRP0
    if self.TIAWRITE[0x1B]~=-1 then
    self.OGRP1=self.GRP1
        self.GRP0=self.TIAWRITE[0x1B]
        self.TIAWRITE[0x1B] = -1
    end
    
    if self.TIAWRITE[0x1C]~=-1 then
    self.OGRP0=GRP0
        self.GRP1=self.TIAWRITE[0x1C]
        self.TIAWRITE[0x1C] = -1
    end
    
    if self.TIAWRITE[0x1D]~=-1 then
    self.ENAM0=(band(rshift(self.TIAWRITE[0x1D],1),0x1) == 1) 
    if self.ENAM0 then print("true") end
        self.TIAWRITE[0x1D] = -1
    end
    if self.TIAWRITE[0x1E]~=-1 then
    self.ENAM1=(band(rshift(self.TIAWRITE[0x1E],1),0x1) == 1)
        self.TIAWRITE[0x1E] = -1
    end
    if self.TIAWRITE[0x1F]~=-1 then
    self.ENABL=(band(rshift(self.TIAWRITE[0x1F],1),0x1) == 1)
        self.TIAWRITE[0x1F] = -1
        end
    
    if self.TIAWRITE[0x20]~=-1 then
    self.HMP0=rshift(self.TIAWRITE[0x20],4)
        self.TIAWRITE[0x20]=-1
    end
    if self.TIAWRITE[0x21]~=-1 then
    self.HMP1=rshift(self.TIAWRITE[0x21],4)
        self.TIAWRITE[0x21] = -1
    end
    
    if self.TIAWRITE[0x2A]~= -1 then
        self.HMOVE=true
        self.TIAWRITE[0x2A]=-1
    end
    if self.HMOVE and self.CurrPixel < 76 then
        if self.HMP0>7 then
            self.HMP0 = self.HMP0 - 16
        end
        if self.HMP1>7 then
            self.HMP1 = self.HMP1 - 16 
        end
        if self.HMBL > 7 then
            self.HMBL = self.HMBL - 16 
        end
        if self.HMM0 > 7 then
            self.HMM0 = self.HMM0 - 16 
        end
        if self.HMM1 > 7 then
            self.HMM1 = self.HMM1 - 16
        end
--    self.P0X = (((self.P0X-TVFieldStartPixel) - self.HMP0)%TVFieldWidth) + TVFieldStartPixel
      self.P0X = (self.P0X - self.HMP0)
     self.P1X = (self.P1X - self.HMP1)
        self.BLX = self.BLX - self.HMBL
        self.M0X = self.M0X - self.HMM0
        self.M1X = self.M1X - self.HMM1  
  --      self.HMP0=0
    --    self.HMP1=0
    end
    if self.P0X < TVFieldStartPixel or self.P0X>=MaxPixel then
        self.P0X = TVFieldStartPixel
    end
    if self.P1X < TVFieldStartPixel or self.P1X>=MaxPixel then
        self.P1X = TVFieldStartPixel
    end
    if self.BLX < TVFieldStartPixel or self.BLX >= MaxPixel then
        self.BLX = TVFieldStartPixel
    end
    if self.M0X < TVFieldStartPixel or self.M0X >= MaxPixel then
        self.M0X = TVFieldStartPixel
    end
    if self.M1X < TVFieldStartPixel or self.M1X >= MaxPixel then
        self.M1X = TVFieldStartPixel
    end
    self.HMOVE=false
    if self.TIAWRITE[0x22]~=-1 then
    self.HMM0=rshift(self.TIAWRITE[0x22],4)
        self.TIAWRITE[0x22] = -1
    end
    if self.TIAWRITE[0x23]~=-1 then
    self.HMM1=rshift(self.TIAWRITE[0x23],4)
    self.TIAWRITE[0x23]=-1
        end
    if self.TIAWRITE[0x24]~=-1 then
    self.HMBL=rshift(self.TIAWRITE[0x24],4)
        self.TIAWRITE[0x24]=-1
        end
    if self.TIAWRITE[0x25]~=-1 then
    if band(self.TIAWRITE[0x25],0x1) == 1 then
        self.VDELP0=true
    else
        self.VDELP0=false
    end
        self.TIAWRITE[0x25]=-1
    end
    if self.TIAWRITE[0x26]~=-1 then
    if band(self.TIAWRITE[0x26],0x1) == 1 then
        self.VDELP1=true
    else
        self.VDELP1=false
    end
        self.TIAWRITE[0x26]=-1
    end
    self.VDELBL=false
    if self.TIAWRITE[0x28] then
    self.RESMP0=band(rshift(self.TIAWRITE[0x28],1),0x1) == 0x1
        self.TIAWRITE[0x28]=-1
    end
    if self.TIAWRITE[0x29]~=-1 then
    self.RESMP1=band(rshift(self.TIAWRITE[0x29],1),0x1) == 0x1
    self.TIAWRITE[0x29]=-1
        end
    if self.TIAWRITE[0x2B] ~= -1 then
        self.HMP0=0
        self.HMP1=0
        self.HMM0=0
        self.HMM1=0
        self.HMBL=0
        self.TIAWRITE[0x2B] = -1
    end
 --   self.CXCLR=NewByte()
   -- self.COLUP1 = math.random(1,255)
   --[[
    if rshift(self.CXPPMM,7) ~= 0x1 then
    if self:GetPlayerPixel(0)~=nil and self:GetPlayerPixel(1)~=nil then
        --collision between p0 and p1
        self.CXPPMM = bor(self.CXPPMM,0x80)
    end 
        end
        if rshift(self.CXPPMM,6) ~= 0x1 then
    if self:GetMissilePixel(0)~=nil and self:GetMissilePixel(1)~=nil then
        self.CXPPMM = bor(self.CXPPMM,0x40)
    end
        end
    
    if rshift(self.CXM0P,6) ~= 0x1 then
    if self.ENAM0 and (not self.RESMP0) and (self:GetPlayerPixel(0)~=nil and self:GetMissilePixel(0)~=nil) then
        self.CXM0P = bor(self.CXM0P,0x40 )
    end
        end
    if rshift(self.CXM0P,7) ~= 0x1 then
    if self.ENAM0 and (not self.RESMP0) and (self:GetPlayerPixel(1)~=nil and self:GetMissilePixel(0)~=nil) then
        self.CXM0P = bor(self.CXM0P,0x80)
    end
        end
    
        if rshift(self.CXM1P,6) ~= 0x1 then
    if self.ENAM1 and (not self.RESMP1) and (self:GetPlayerPixel(1)~=nil and self:GetMissilePixel(1)~=nil) then
        self.CXM1P = bor(self.CXM1P,0x40)
    end
        end
    if rshift(self.CXM1P,7) ~= 0x1 then
    if self.ENAM1 and (not self.RESMP1) and (self:GetPlayerPixel(0)~=nil and self:GetMissilePixel(1)~=nil) then
        self.CXM1P = bor(self.CXM1P,0x80) 
    end
        end
    
    if rshift(self.CXP0FB,7) ~= 0x1 then
    if self:GetPlayfieldPixel()~=nil and self:GetPlayerPixel(0)~=nil then
        self.CXP0FB = bor(self.CXP0FB,0x80 )
    end
    end
        if rshift(self.CXP0FB, 6) ~= 0x1 then
    if self.ENABL and (self:GetBallPixel()~=nil and self:GetPlayerPixel(0)~=nil) then
        self.CXP0FB = bor(self.CXP0FB, 0x40)
    end
        end
        if rshift(self.CXP1FB, 7) ~= 0x1 then
    if self:GetPlayfieldPixel()~=nil and self:GetPlayerPixel(1)~=nil then
        self.CXP1FB = bor(self.CXP1FB, 0x80) 
    end
        end
   if rshift(self.CXP1FB, 6) ~= 0x1 then
    if self.ENABL and (self:GetBallPixel()~=nil and self:GetPlayerPixel(1)~=nil) then
        self.CXP1FB = bor(self.CXP1FB, 0x40)
    end
        end
    if rshift(self.CXM0FB, 7) ~= 0x1 then
    if self:GetPlayfieldPixel()~=nil and self:GetMissilePixel(0)~=nil then
        self.CXM0FB = bor(self.CXM0FB, 0x80 )
    end
        end
    if rshift(self.CXM0FB, 6) ~= 0x1 then
    if self.ENABL and (self:GetBallPixel()~=nil and self:GetMissilePixel(0)~=nil) then
        self.CXM0FB = bor(self.CXM0FB, 0x40)
    end
    end
    if rshift(self.CXM1FB, 7) ~= 0x1 then
    if self:GetPlayfieldPixel()~=nil and self:GetMissilePixel(1)~=nil then
        self.CXM1FB = bor(self.CXM1FB, 0x80 )
    end
        end
    if rshift(self.CXM1FB, 6) ~= 0x1 then
    if self.ENABL and (self:GetBallPixel()~=nil and self:GetMissilePixel(1)~=nil) then
        self.CXM1FB = bor(self.CXM1FB ,0x40)
    end
        end
    
            if rshift(self.CXBLPF, 7) ~= 0x1 then
    if self.ENABL and (self:GetBallPixel()~=nil and self:GetPlayfieldPixel()~=nil) then
        self.CXBLPF = bor(self.CXBLPF, 0x80 )
    end
        end

        ]]--
    
    if self.TIAWRITE[0x2C] ~= -1 then
        self.CXM0P = 0
        self.CXM1P = 0
        self.CXP0FB = 0
        self.CXP1FB = 0
        self.CXM0FB = 0
        self.CXM1FB = 0
        self.CXBLPF = 0
        self.CXPPMM = 0 
        self.TIAWRITE[0x2C] = -1
    end

    
 --   if math.floor((self.P0X-TVFieldStartPixel)/4)
end

function TIA:DrawPixel(I)
    
    if DRAWSCREEN then
    local Color=nil
   if ((not RenderOutsideScreen) and (self.CurrPixel>=TVFieldStartPixel and self.CurrLine>=TVFieldStartScan and self.CurrLine<TVFieldEndScan)) or (RenderOutsideScreen) then
        if band(self.CurrPixel, 0x3) == 0x0 and self.CurrPixel >= TVFieldStartPixel then
            self.CurrPlayfieldPixel = self.CurrPlayfieldPixel + 1
        end
        
        --[[
        if self.CurrPixel >= TVFieldStartPixel then
            self.CurrPlayfieldPixel = math.floor((self.CurrPixel-TVFieldStartPixel)/4)+1
        end
          ]]
        if self.PlayfieldPriority then --Players move behind playfield
            Color=self:GetPlayfieldPixel()
            if Color == nil then Color = self:GetBallPixel() end
            if Color==nil then
               Color=self:GetPlayerPixel(0) or self:GetMissilePixel(0)
                if Color==nil then
                    Color=self:GetPlayerPixel(1) or self:GetMissilePixel(1)
                end
            end
        else --Players move in front of playfield
            Color=self:GetPlayerPixel(0) or self:GetMissilePixel(0)
            if Color==nil then
                Color=self:GetPlayerPixel(1) or self:GetMissilePixel(1)
                if Color==nil then
                   Color=self:GetPlayfieldPixel()
                    if Color==nil then Color=self:GetBallPixel() end
                end
            end
          --  Color = self:GetPlayerPixel(0) or self:GetMissilePixel(0) or self:GetPlayerPixel(1) or self:GetMissilePixel(1) or self:GetPlayfieldPixel() or self:GetBallPixel()
        end
    end
        if Color==nil then
            Color=self.COLUBK
        end
  --  else
 --     Color=color(0)
 --   end
        --I:set(self.CurrPixel+1, MaxScanline-(self.CurrLine), ColorPallete[Color][1],ColorPallete[Color][2],ColorPallete[Color][3])
        if RenderOutsideScreen then
        I[self.CurrPixel][self.CurrLine] = Color
        else
            if self.CurrPixel >= TVFieldStartPixel and self.CurrLine >= TVFieldStartScan then
        I[self.CurrPixel-TVFieldStartPixel][self.CurrLine-TVFieldStartScan] = Color
            end
        end
    end

    self.CurrPixel = self.CurrPixel + 1
    if self.CurrPixel>=MaxPixel then
        self.CurrPixel=self.CurrPixel-MaxPixel
        self.CurrPlayfieldPixel=0
        self.DrewP0=false
        self.DrewP1=false
        self.VDELP0=false
        self.VDELP1=false
        self.CurrLine = self.CurrLine + 1
        if self.CurrLine>=MaxScanline then
            self.CurrLine=0
       --     print("Frame complete")
        end
    end
end

function TIA:GetPlayfieldPixel()
     --   local HalfPlayField = Concatenate(Reverse(SubTable(self.PF0, 5, 8)), Reverse(self.PF1),self.PF2)
        local PixelActive=false
        if self.CurrPlayfieldPixel <= 20 then
            if band(rshift(self.HalfPlayField,(self.CurrPlayfieldPixel-1)),0x1) == 1 then
                PixelActive=true
            end
        else
            if band(self.CTRLPF,0x1) == 1 then --Reflect Playfield
                if band(rshift(self.HalfPlayField,(40-self.CurrPlayfieldPixel)),0x1) == 1 then
                    PixelActive=true
                end
            else --No Reflect
                if band(rshift(self.HalfPlayField,(self.CurrPlayfieldPixel-21)),0x1) == 1 then
                    PixelActive=true
                end
            end
        end
        if PixelActive then
            if band(rshift(self.CTRLPF,1),0x1) == 1 then --Playercolors in playfield (left half=player 0, right half=player 1)
                if self.CurrPlayfieldPixel <= 20 then
                    return self.COLUP0
                else
                    return self.COLUP1
                end
            else --return color of playfield
                return self.COLUPF
            end
        else
            return nil
        end
end

function TIA:GetBallPixel()
    if not self.ENABL then return nil
    else
        if self.CurrPixel >= self.BLX and self.CurrPixel < (self.BLX+self.BallSize) then return self.COLUPF end
    end
    return nil
end

function TIA:GetMissilePixel(PNum)
    if PNum == 0 then
        if (not self.ENAM0) or self.RESMP0 then return nil end
        if self.CurrPixel >= self.M0X and self.CurrPixel < self.M0X + self.M0Size then return self.COLUP0 end
    else
        if (not self.ENAM1) or self.RESMP1 then return nil end
        if self.CurrPixel >= self.M1X and self.CurrPixel < self.M1X + self.M1Size then return self.COLUP1 end
    end
    return nil
end

function TIA:GetPlayerPixel(PNum)
    local PGrp
    local RefP
    local ColP
    local Ppos
    local Nup
    local CurrPos=self.CurrPixel
    if PNum==0 then --Player0
        if self.DrewP0==true or CurrPos < self.P0X then
            return nil
        end
        PGrp = self.GRP0
        if self.VDELP0 then
            PGrp = self.OGRP0
            if self.OGRP0 == 0 then
                return nil 
            end 
        else if self.GRP0 == 0 then
             return nil 
            end
        end
        RefP = self.REFP0
        ColP = self.COLUP0
        Ppos = self.P0X
        Nup=band(self.NUSIZ0,0x7)
    else --Player1
        if self.DrewP1==true or CurrPos < self.P1X then
            return nil
        end
        PGrp = self.GRP1
        if self.VDELP1 then
            PGrp = self.OGRP1
            if self.OGRP1 == 0 then
                return nil 
            end 
        else if self.GRP1 == 0 then
             return nil 
            end
        end
        RefP = self.REFP1
        ColP = self.COLUP1
        Ppos = self.P1X
        Nup = band(self.NUSIZ1,0x7)
    end
    if Nup == 1 then --2 copies of player, 1p distance
        if CurrPos >= Ppos+8 and CurrPos<Ppos+16 then
            return nil
        elseif CurrPos>=Ppos+16 then
            CurrPos = CurrPos - 16
        end
    elseif Nup == 2 then --2 copies of player, 3p distance
        if CurrPos >= Ppos+8 and CurrPos<Ppos+32 then
            return nil
        elseif CurrPos>=Ppos+32 then
            CurrPos = CurrPos - 32
        end
    elseif Nup == 3 then --3 copies of player, 1p distance
        if (CurrPos >= Ppos+8 and CurrPos<Ppos+16) or (CurrPos>=Ppos+24 and CurrPos<Ppos+32) then
            return nil
        elseif CurrPos>=Ppos+16 and CurrPos<Ppos+24 then
            CurrPos = CurrPos - 16
        elseif CurrPos>=Ppos+32 then
            CurrPos = CurrPos - 32
        end
    elseif Nup == 4 then --2 copies of player, 5p distance
        if CurrPos >= Ppos+8 and CurrPos<Ppos+64 then
            return nil
        elseif CurrPos>=Ppos+64 then
            CurrPos = CurrPos - 64
        end
    elseif Nup == 5 then --1 copy of player, double width
        if CurrPos<Ppos then
            return nil
        else
            CurrPos = math.floor((CurrPos-Ppos)/2)+Ppos
        end
    elseif Nup == 6 then --3 copies of player, 3p distance
        if (CurrPos >= Ppos+8 and CurrPos<Ppos+32) or (CurrPos>=Ppos+40 and CurrPos<Ppos+64) then
            return nil
        elseif CurrPos>=Ppos+32 and CurrPos<Ppos+40 then
            CurrPos = CurrPos - 32
        elseif CurrPos>=Ppos+64 then
            CurrPos = CurrPos - 64
        end
    elseif Nup == 7 then --1 copy of player, quad width
        if CurrPos<Ppos then
            return nil
        else
            CurrPos = math.floor((CurrPos-Ppos)/4)+Ppos
        end
    end
    
    if CurrPos < Ppos or CurrPos > Ppos+7 then
        if CurrPos > Ppos+7 then
            if PNum==0 then self.DrewP0 = true else self.DrewP1=true end
        end
        return nil
    end
    
    local PixelActive
    local Pos=(CurrPos-Ppos)
    if not RefP then --reflect player
        PixelActive = band(rshift(PGrp,(7-Pos)),0x1)==1
    else
        PixelActive = band(rshift(PGrp,(Pos)),0x1)==1
    end
    if PixelActive then
        return ColP
    else
        return nil
    end
end

function TIA:Sound(N)
    local Volume
    local Type
    local Frequency
    
    local Waveform
    if N==0 then --sound 0
        Volume = self.AUDV0/15
        Frequency = self.AUDF0
        Type = self.AUDC0
    else --sound 1
        Volume = self.AUDV1/15
        Frequency = self.AUDV1
        Type = self.AUDC1
    end 
    --[[
    Frequency=9
    Volume=1/8
    Type=4
      ]]
    --[[
    Frequency=30000 / 12
    Volume=1/8
    Type=2
    Waveform = PURE
    if Type == 0 or Type == 11 then
        Waveform = ON
    end
    if Type == 1 then
        Waveform = POLY4
    elseif Type == 2 then
        Frequency = Frequency * 15.0
        Waveform = POLY4
    elseif Type == 3 then
        Waveform = POLY54
    elseif Type == 4 or Type == 5 then
      Frequency = Frequency * 2.0
    elseif Type == 6 or Type == 10 then
        Frequency = Frequency * 31.0
        Waveform = NOISE
    elseif Type == 7 then
        Frequency = Frequency * 2.0
        Waveform = POLY5
    elseif Type == 8 then
        Waveform = NOISE
    elseif Type == 9 then
        Waveform = POLY5
    elseif Type == 12 or Type == 13 then
        Frequency = Frequency * 6.0
    elseif Type == 14 then
        Frequency = Frequency * 93.0
    elseif Type == 15 then
        Frequency = Frequency * 6.0
        Waveform=POLY5
    end
      ]]
    if Volume == 0 then
        return
    else
        PlaySound(Type, Frequency, Volume)
    end
    
end


