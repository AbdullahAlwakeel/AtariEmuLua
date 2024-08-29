local ffi = require("ffi")
RIOT = {}

function RIOT:init()
    -- you can accept and set parameters here
    self.Timer=0
    self.IntervalTimer=0
    self.Interval=0
    TIM1T=0x294
    TIM8T=0x295
    TIM64T=0x296
    TIM1024T=0x297
    INTIM=0x284
    self.ReachedZ=false
    self.Stop=false
    --self.Memory = ffi.new("uint8_t[?]", 0x298)
    self.Memory = {}
    for i=0, 0x298 do
        self.Memory[i] = 0
    end
end

function RIOT:Update(Cycles)
    if self.Memory[0x294]>0 then
        self.ReachedZ=false
        self.Stop=false
        self.Timer = self.Memory[0x294]
        self.Interval=1
        self.Memory[0x294]=0
        self.IntervalTimer=0
    elseif self.Memory[0x295] > 0 then
        self.ReachedZ=false
        self.Stop=false
        self.Timer = self.Memory[0x295]
        self.Interval=8
        self.Memory[0x295]=0
        self.IntervalTimer=0
    elseif self.Memory[0x296] > 0 then
        self.ReachedZ=false
        self.Stop=false
        self.Timer = self.Memory[0x296]
        self.Interval=64
        self.Memory[0x296]=0
        self.IntervalTimer=0
    elseif self.Memory[0x297] > 0 then
        self.ReachedZ=false
        self.Stop=false
        self.Timer = self.Memory[0x297]
        self.Interval=1024
        self.Memory[0x297]=0
        self.IntervalTimer=0
    end
    
    self.Memory[0x284]=self.Timer
    if Debug then
        print("RIOT: INTIM=$"..Dec2Hex(self.Timer)..", (Decimal): "..self.Timer..", "..self.IntervalTimer.."/"..self.Interval)
    end
end

function RIOT:Tick(Cycles)
    if self.Interval > 0 then
        if self.Timer>=0 and not self.ReachedZ then
            self.IntervalTimer = self.IntervalTimer + Cycles
            self.Timer = self.Timer - math.floor(self.IntervalTimer/self.Interval)
            self.IntervalTimer = self.IntervalTimer % self.Interval
        end
        if self.Timer < 0 and not self.ReachedZ then
            self.Timer = 0xFF
            self.ReachedZ = true
        end
        if self.Timer >= 0 and self.ReachedZ then
            self.Timer = self.Timer - Cycles
            if self.Timer < 0 then
                self.Stop=true
                self.Timer=0
            end
            if self.Stop then
                self.Timer = 0
            end
        end
    end
end
