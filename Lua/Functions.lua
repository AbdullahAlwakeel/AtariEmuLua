local bit = require("bit")
local band, bor, bxor, rshift, lshift = bit.band, bit.bor, bit.bxor, bit.rshift, bit.lshift


    MaxScanline_N=262
    MaxPixel_N=228
    TVFieldWidth_N=160
    TVFieldHeight_N=192
    TVFieldStartScan_N=40
    TVFieldStartPixel_N=68

    MaxScanline_P=312
    MaxPixel_P=228
    TVFieldWidth_P=160
    TVFieldHeight_P=228
    TVFieldStartScan_P=48
    TVFieldStartPixel_P=68


function LumAdd(val,lum)
    local r= val+(lum*20)-60
    if r<0 then return 0
    elseif r>255 then return 255
    else
        return r
    end
end
PAL=0
NTSC=1
SECAM=2
    
function CloneTable(T)
    local Z={}
    for i,v in pairs(T) do
        Z[i]=v
    end
    return Z
end

function NewByte()
    return {0,0,0,0,0,0,0,0}
end

function TextToNumber(T)
    local Z={}
    for i=1, #T do
        local j=T:sub(i,i)
        table.insert(Z,string.byte(j))
    end
    return Z
end

function NumTblToBin(N)
    local Z={}
    for i=1, #N do
        table.insert(Z,Dec2Bin(N[i]))
    end
    return Z
end

function NewBlock(Size)
    local Z={}
    for i=0, Size-1 do
        Z[i]=0
    end
    return Z
end

function Dec2Bin(N)
    --[[
    local t={0,0,0,0,0,0,0,0} -- will contain the bits    
    local L=8
    if N>255 then
        L=16
    end
    for i=1,L do
        t[i] = (N >> (i-1)) & 0x01
    end
      ]]
    --[[
    if N<256 then
    return DB[N]
    else
    local t={}
    for b=1,16 do
        t[b]=math.floor(math.fmod(N,2))
        N=(N-t[b])/2
    end
    return t
    end
      ]]
    return {band(N,0x1), band(rshift(N,1),0x1), band(rshift(N,2),0x1), band(rshift(N,3),0x1), band(rshift(N,4),0x1), band(rshift(N,5),0x1), band(rshift(N,6),0x1), band(rshift(N,7),0x1)}
end

function Bin2Dec(N)
    --[[
    local Z=0
    local M=1
    for i=1,#N do
        if i==1 then
            else
            M = M * 2
        end
        Z = Z + (M*N[i])
    end
    return Z
      ]]
--    if #N~=8 then
    return tonumber(table.concat(N):reverse(),2)
--    else
 --       return BD[TableToString(N)]
--    end
end

function Hex2Dec(N)
    --[[
    if #N==2 then
    local Letters="0123456789ABCDEF"
    local X=Letters:find(N:sub(2,2))-1
    local Y=Letters:find(N:sub(1,1))-1
    return X+(Y*16)
    elseif #N==4 then
        local Letters="0123456789ABCDEF"
    local X=Letters:find(N:sub(2,2))-1
    local Y=Letters:find(N:sub(1,1))-1
    local Z=Letters:find(N:sub(3,3))-1
    local W=Letters:find(N:sub(4,4))-1
    return W+(Z*16)+(X*256)+(Y*4096)
    end
      ]]
    
    return tonumber(N,16)
end

function Dec2Hex(N)
    if N<256 then
        --[[
    local Letters="0123456789ABCDEF"
    local X=math.fmod(N,16)
    local Y=math.floor(N/16)
    return Letters:sub(Y+1,Y+1)..Letters:sub(X+1,X+1)
          ]]
        if N>16 then
            return string.format("%X",N):sub(1,2)
        else
            return "0"..string.format("%X",N):sub(1,2)
        end
    else
        --[[
    local Letters="0123456789ABCDEF"
    local X=math.fmod(N,16)
    local Y=math.fmod(math.floor(N/16),16)
    local Z=math.fmod(math.floor(math.floor(N/16)/16),16)
    local W=math.fmod(math.floor(math.floor(math.floor(N/16)/16)/16),16)
    return Letters:sub(W+1,W+1)..Letters:sub(Z+1,Z+1)..Letters:sub(Y+1,Y+1)..Letters:sub(X+1,X+1)
          ]]
        return string.format("%X",N):sub(1,4)
    end
end

function RevDec(d)
    local n=0x0
    local e = d
    local B=0
    while B<8 do
        n = lshift(n, 1)
        if band(e,0x1) == 0x1 then n = bor(n, 0x1) end
        e = rshift(e, 1)
        B = B + 1
    end
    return n
end

function BinToString(B)
    if #B==4 then
        return B[4]..B[3]..B[2]..B[1]
    else
        return B[8]..B[7]..B[6]..B[5]..B[4]..B[3]..B[2]..B[1]
    end
end


