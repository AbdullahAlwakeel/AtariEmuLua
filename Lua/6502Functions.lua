Accumulator=0
Immediate=1
Absolute=2
ZeroPage=3
Implicit=4
Indirect=5
AbsoluteX=6
AbsoluteY=7
ZeroPageX=8
ZeroPageY=9
IndirectX=10
IndirectY=11
Relative = 12

function HexDumpToROM(str)
    s = string.gsub(str,"....:", "")
    print(s)
    s=string.gsub(s,"%s+","")
    print(s)
    local H={}
    for i=1, #s, 2 do
        H[(i+1)/2] = Hex2Dec(s:sub(i,i+1))
    end
    return H
end

function HexDump(A, Start, End)
    Start=Start or 0
    End=End or (#A - 1)
    local Str=""
    for i=Start, End do
        Str = Str .. Dec2Hex(A[i]) .. " "
    end
    return Str
end

function NewBlock(Size)
    local Z={}
    for i=0, Size-1 do
        Z[i]=0
    end
    return Z
end

function SubTable(t,i,j) --start at i, end at j (inclusive)
    local a={}
    for ind=i, j do
        table.insert(a, t[ind])
    end
    return a
end