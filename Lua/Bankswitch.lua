local bit=require("bit")
local band,bor,bxor,rshift,lshift = bit.band, bit.bor, bit.bxor, bit.rshift, bit.lshift
NOBANK=-1
F8BANKSWITCH=0
F6BANKSWITCH=1
PITFALL2=2

CurrentBlock = 0
    
function GetROMAddress(key) --Bankswitching
    if CurrS == F8BANKSWITCH then
        if band(key,0xFFF) == 0xFF8 then
            if Debug then print("Changed to bank 0, PC = $"..Dec2Hex(Device.Core.PC)) end
            CurrentBlock = 0
            return 0
        elseif band(key,0xFFF) == 0xFF9 then
                if Debug then print("Changed to bank 1, PC = $"..Dec2Hex(Device.Core.PC)) end
            CurrentBlock = 1
            return 0
        else
            if CurrentBlock == 0 then
            return band(key,0xFFF) --B000 TO BFFF
            else
                return band(key,0xFFF) + 0x1000
            end
        end
    elseif CurrS == PITFALL2 then
        if band(key,0xFFF) == 0xFF8 then
            if Debug then print("Changed to bank 0, PC = $"..Dec2Hex(Device.Core.PC)) end
            CurrentBlock = 0
            return 0
        elseif band(key,0xFFF) == 0xFF9 then
                if Debug then print("Changed to bank 1, PC = $"..Dec2Hex(Device.Core.PC)) end
            CurrentBlock = 1
            return 0
        else
            if CurrentBlock == 0 then
            return band(key,0xFFF) --B000 TO BFFF
            else
                return band(key,0xFFF) + 0x1000
            end
        end
    elseif CurrS == F6BANKSWITCH then
        if key == 0x1FF6 then
            CurrentBlock = 0
            return 0
        elseif key == 0x1FF7 then
            CurrentBlock = 1
            return 0
        elseif key == 0x1FF8 then
            CurrentBlock = 2
            return 0
        elseif key == 0x1FF9 then
            CurrentBlock = 3
            return 0
        else
            return band(key,0xFFF)+((CurrentBlock-1)*0x1000)
        end
    end
end

function ReadPitfall2(key)
end

function WritePitfall2(key, value)
end