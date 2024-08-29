local bit = require("bit")
local rshift,lshift,band,bor,bxor = bit.rshift,bit.lshift,bit.band,bit.bor,bit.bxor
local ffi = require("ffi")
P6502 = {}

function P6502:init(H,E)
    -- you can accept and set parameters here
    self.ReadMem = function(key) end
    self.WriteMem = function(key,value) end

    self.AllowIllegals=false
    self.StackStart = 0x100
    self.X=0x00
    self.Y=0x00
    self.HaltOnBRK=H
    self.HaltOnError=E
    if self.HaltOnBRK==nil then
        self.HaltOnBRK = true
    end
    if self.HaltOnError==nil then
        self.HaltOnError=true
    end
    self.S=0xFF
    self.A=0x00
    self.PC=0x1000
    --self.MemorySize = MemorySize or 65536
    self.P={C=0,Z=0,I=0,D=0,B=1,V=0,N=0}
    --self.Memory=NewBlock(self.MemorySize)
    --setmetatable(self.Memory, function __index__(i) return self.Memory[math.fmod(i,#self.Memory)+1] end)
    self.Cycles=0
    self.H2D=Hex2Dec
    self.D2H=Dec2Hex
    self.B2D=Bin2Dec
    self.D2B=Dec2Bin
    
    self.ASM2INS = {
    ADC = self.ADC,
    AND = self.AND,
    ASL = self.ASL,
    BCC = self.BCC,
    BCS = self.BCS,
    BEQ = self.BEQ,
    BIT = self.BIT,
    BMI = self.BMI,
    BNE = self.BNE,
    BPL = self.BPL,
    BRK = self.BRK,
    BVC = self.BVC,
    BVS = self.BVS,
    CLC = self.CLC,
    CLD = self.CLD,
    CLI = self.CLI,
    CLV = self.CLV,
    CMP = self.CMP,
    CPX = self.CPX,
    CPY = self.CPY,
    DEC = self.DEC,
    DEX = self.DEX,
    DEY = self.DEY,
    EOR = self.EOR,
    INC = self.INC,
    INX = self.INX,
    INY = self.INY,
    JMP = self.JMP,
    JSR = self.JSR,
    LDA = self.LDA,
    LDX = self.LDX,
    LDY = self.LDY,
    LSR = self.LSR,
    NOP = self.NOP,
    ORA = self.ORA,
    PHA = self.PHA,
    PHP = self.PHP,
    PLA = self.PLA,
    PLP = self.PLP,
    ROL = self.ROL,
    ROR = self.ROR,
    RTI = self.RTI,
    RTS = self.RTS,
    SBC = self.SBC,
    SEC = self.SEC,
    SED = self.SED,
    SEI = self.SEI,
    STA = self.STA,
    STX = self.STX,
    STY = self.STY,
    TAX = self.TAX,
    TAY = self.TAY,
    TSX = self.TSX,
    TXA = self.TXA,
    TXS = self.TXS,
    TYA = self.TYA,
    --ILLEGAL OPCODES
    ASO = self.ASO,
    RLA = self.RLA,
    LSE = self.LSE,
    RRA = self.RRA,
    AXS = self.AXS,
    LAX = self.LAX,
    DCM = self.DCM,
    INS = self.INS,
    ALR = self.ALR,
    ARR = self.ARR,
    XAA = self.XAA,
    OAL = self.OAL,
    SAX = self.SAX,
    SKB = self.SKB,
    SKW = self.SKW,
    HLT = self.HLT,
    TAS = self.TAS,
    SAY = self.SAY,
    XAS = self.XAS,
    AXA = self.AXA,
    ANC = self.ANC,
    LAS = self.LAS
    }

    self.OPCD2ASM = {
    --[0x00] = self.BRK,
    [0x00] = function() return 1,7 end,
    [0x01] = function(self,O) return self:Indirect_X_Operand("ORA",O) end,
    [0x05] = function(self,O) return self:ZeroPage_Operand("ORA",O) end,
    [0x06] = function(self,O) return self:ZeroPage_Operand("ASL",O) end,
    [0x08] = self.PHP,
    [0x09] = function(self,O) return self:Immediate_Operand("ORA",O) end,
    [0x0A] = function(self) return self:Accumulator_Operand("ASL") end,
    [0x0D] = function(self,O,P) return self:Absolute_Operand("ORA",P,O) end,
    [0x0E] = function(self,O,P) return self:Absolute_Operand("ASL",P,O) end,
    [0x10] = function(self,O) return self:Relative_Operand("BPL",O) end,
    [0x11] = function(self,O) return self:Indirect_Y_Operand("ORA",O) end,
    [0x15] = function(self,O) return self:ZeroPage_X_Operand("ORA",O) end,
    [0x16] = function(self,O) return self:ZeroPage_X_Operand("ASL",O) end,
    [0x18] = self.CLC,
    [0x19] = function(self,O,P) return self:Absolute_Y_Operand("ORA",P,O) end,
    [0x1D] = function(self,O,P) return self:Absolute_X_Operand("ORA",P,O) end,
    [0x1E] = function(self,O,P) return self:Absolute_X_Operand("ASL",P,O) end,
    [0x20] = function(self,O,P) return self:Absolute_Operand("JSR",P,O) end,
    [0x21] = function(self,O) return self:Indirect_X_Operand("AND",O) end,
    [0x24] = function(self,O) return self:ZeroPage_Operand("BIT",O) end,
    [0x25] = function(self,O) return self:ZeroPage_Operand("AND",O) end,
    [0x26] = function(self,O) return self:ZeroPage_Operand("ROL",O) end,
    [0x28] = self.PLP,
    [0x29] = function(self,O) return self:Immediate_Operand("AND",O) end,
    [0x2A] = function(self,O) return self:Accumulator_Operand("ROL") end,
    [0x2C] = function(self,O,P) return self:Absolute_Operand("BIT",P,O) end,
    [0x2D] = function(self,O,P) return self:Absolute_Operand("AND",P,O) end,
    [0x2E] = function(self,O,P) return self:Absolute_Operand("ROL",P,O) end,
    [0x30] = function(self,O) return self:Relative_Operand("BMI",O) end,
    [0x31] = function(self,O) return self:Indirect_Y_Operand("AND",O) end,
    [0x35] = function(self,O) return self:ZeroPage_X_Operand("AND",O) end,
    [0x36] = function(self,O) return self:ZeroPage_X_Operand("ROL",O) end,
    [0x38] = self.SEC,
    [0x39] = function(self,O,P) return self:Absolute_Y_Operand("AND",P,O) end,
    [0x3D] = function(self,O,P) return self:Absolute_X_Operand("AND",P,O) end,
    [0x3E] = function(self,O,P) return self:Absolute_X_Operand("ROL",P,O) end,
    [0x40] = self.RTI,
    [0x41] = function(self,O) return self:Indirect_X_Operand("EOR",O) end,
    [0x45] = function(self,O) return self:ZeroPage_Operand("EOR",O) end,
    [0x46] = function(self,O) return self:ZeroPage_Operand("LSR",O) end,
    [0x48] = self.PHA,
    [0x49] = function(self,O) return self:Immediate_Operand("EOR",O) end,
    [0x4A] = function(self) return self:Accumulator_Operand("LSR") end,
    [0x4C] = function(self,O,P) return self:Absolute_Operand("JMP",P,O) end,
    [0x4D] = function(self,O,P) return self:Absolute_Operand("EOR",P,O) end,
    [0x4E] = function(self,O,P) return self:Absolute_Operand("LSR",P,O) end,
    [0x50] = function(self,O) return self:Relative_Operand("BVC",O) end,
    [0x51] = function(self,O) return self:Indirect_Y_Operand("EOR",O) end,
    [0x55] = function(self,O) return self:ZeroPage_X_Operand("EOR",O) end,
    [0x56] = function(self,O) return self:ZeroPage_X_Operand("LSR",O) end,
    [0x58] = self.CLI,
    [0x59] = function(self,O,P) return self:Absolute_Y_Operand("EOR",P,O) end,
    [0x5D] = function(self,O,P) return self:Absolute_X_Operand("EOR",P,O) end,
    [0x5E] = function(self,O,P) return self:Absolute_X_Operand("LSR",P,O) end,
    [0x60] = self.RTS,
    [0x61] = function(self,O) return self:Indirect_X_Operand("ADC",O) end,
    [0x65] = function(self,O) return self:ZeroPage_Operand("ADC",O) end,
    [0x66] = function(self,O) return self:ZeroPage_Operand("ROR",O) end,
    [0x68] = self.PLA,
    [0x69] = function(self,O) return self:Immediate_Operand("ADC",O) end,
    [0x6A] = function(self) return self:Accumulator_Operand("ROR") end,
    [0x6C] = function(self,O,P) return self:Indirect_Operand("JMP",P,O) end,
    [0x6D] = function(self,O,P) return self:Absolute_Operand("ADC",P,O) end,
    [0x6E] = function(self,O,P) return self:Absolute_Operand("ROR",P,O) end,
    [0x70] = function(self,O) return self:Relative_Operand("BVS",O) end,
    [0x71] = function(self,O) return self:Indirect_Y_Operand("ADC",O) end,
    [0x75] = function(self,O) return self:ZeroPage_X_Operand("ADC",O) end,
    [0x76] = function(self,O) return self:ZeroPage_X_Operand("ROR",O) end,
    [0x78] = self.SEI,
    [0x79] = function(self,O,P) return self:Absolute_Y_Operand("ADC",P,O) end,
    [0x7D] = function(self,O,P) return self:Absolute_X_Operand("ADC",P,O) end,
    [0x7E] = function(self,O,P) return self:Absolute_X_Operand("ROR",P,O) end,
    [0x81] = function(self,O) return self:Indirect_X_Operand("STA",O) end,
    [0x84] = function(self,O) return self:ZeroPage_Operand("STY",O) end,
    [0x85] = function(self,O) return self:ZeroPage_Operand("STA",O) end,
    [0x86] = function(self,O) return self:ZeroPage_Operand("STX",O) end,
    [0x88] = self.DEY,
    [0x8A] = self.TXA,
    [0x8C] = function(self,O,P) return self:Absolute_Operand("STY",P,O) end,
    [0x8D] = function(self,O,P) return self:Absolute_Operand("STA",P,O) end,
    [0x8E] = function(self,O,P) return self:Absolute_Operand("STX",P,O) end,
    [0x90] = function(self,O) return self:Relative_Operand("BCC",O) end,
    [0x91] = function(self,O) return self:Indirect_Y_Operand("STA",O) end,
    [0x94] = function(self,O) return self:ZeroPage_X_Operand("STY",O) end,
    [0x95] = function(self,O) return self:ZeroPage_X_Operand("STA",O) end,
    [0x96] = function(self,O) return self:ZeroPage_Y_Operand("STX",O) end,
    [0x98] = self.TYA,
    [0x99] = function(self,O,P) return self:Absolute_Y_Operand("STA",P,O) end,
    [0x9A] = self.TXS,
    [0x9D] = function(self,O,P) return self:Absolute_X_Operand("STA",P,O) end,
    [0xA0] = function(self,O) return self:Immediate_Operand("LDY",O) end,
    [0xA1] = function(self,O) return self:Indirect_X_Operand("LDA",O) end,
    [0xA2] = function(self,O) return self:Immediate_Operand("LDX",O) end,
    [0xA4] = function(self,O) return self:ZeroPage_Operand("LDY",O) end,
    [0xA5] = function(self,O) return self:ZeroPage_Operand("LDA",O) end,
    [0xA6] = function(self,O) return self:ZeroPage_Operand("LDX",O) end,
    [0xA8] = self.TAY,
    [0xA9] = function(self,O) return self:Immediate_Operand("LDA",O) end,
    [0xAA] = self.TAX,
    [0xAC] = function(self,O,P) return self:Absolute_Operand("LDY",P,O) end,
    [0xAD] = function(self,O,P) return self:Absolute_Operand("LDA",P,O) end,
    [0xAE] = function(self,O,P) return self:Absolute_Operand("LDX",P,O) end,
    [0xB0] = function(self,O) return self:Relative_Operand("BCS",O) end,
    [0xB1] = function(self,O) return self:Indirect_Y_Operand("LDA",O) end,
    [0xB4] = function(self,O) return self:ZeroPage_X_Operand("LDY",O) end,
    [0xB5] = function(self,O) return self:ZeroPage_X_Operand("LDA",O) end,
    [0xB6] = function(self,O) return self:ZeroPage_Y_Operand("LDX",O) end,
    [0xB8] = self.CLV,
    [0xB9] = function(self,O,P) return self:Absolute_Y_Operand("LDA",P,O) end,
    [0xBA] = self.TSX,
    [0xBC] = function(self,O,P) return self:Absolute_X_Operand("LDY",P,O) end,
    [0xBD] = function(self,O,P) return self:Absolute_X_Operand("LDA",P,O) end,
    [0xBE] = function(self,O,P) return self:Absolute_Y_Operand("LDX",P,O) end,
    [0xC0] = function(self,O) return self:Immediate_Operand("CPY",O) end,
    [0xC1] = function(self,O) return self:Indirect_X_Operand("CMP",O) end,
    [0xC4] = function(self,O) return self:ZeroPage_Operand("CPY",O) end,
    [0xC5] = function(self,O) return self:ZeroPage_Operand("CMP",O) end,
    [0xC6] = function(self,O) return self:ZeroPage_Operand("DEC",O) end,
    [0xC8] = self.INY,
    [0xC9] = function(self,O) return self:Immediate_Operand("CMP",O) end,
    [0xCA] = self.DEX,
    [0xCC] = function(self,O,P) return self:Absolute_Operand("CPY",P,O) end,
    [0xCD] = function(self,O,P) return self:Absolute_Operand("CMP",P,O) end,
    [0xCE] = function(self,O,P) return self:Absolute_Operand("DEC",P,O) end,
    [0xD0] = function(self,O) return self:Relative_Operand("BNE",O) end,
    [0xD1] = function(self,O) return self:Indirect_Y_Operand("CMP",O) end,
    [0xD5] = function(self,O) return self:ZeroPage_X_Operand("CMP",O) end,
    [0xD6] = function(self,O) return self:ZeroPage_X_Operand("DEC",O) end,
    [0xD8] = self.CLD,
    [0xD9] = function(self,O,P) return self:Absolute_Y_Operand("CMP",P,O) end,
    [0xDD] = function(self,O,P) return self:Absolute_X_Operand("CMP",P,O) end,
    [0xDE] = function(self,O,P) return self:Absolute_X_Operand("DEC",P,O) end,
    [0xE0] = function(self,O) return self:Immediate_Operand("CPX",O) end,
    [0xE1] = function(self,O) return self:Indirect_X_Operand("SBC",O) end,
    [0xE4] = function(self,O) return self:ZeroPage_Operand("CPX",O) end,
    [0xE5] = function(self,O) return self:ZeroPage_Operand("SBC",O) end,
    [0xE6] = function(self,O) return self:ZeroPage_Operand("INC",O) end,
    [0xE8] = self.INX,
    [0xE9] = function(self,O) return self:Immediate_Operand("SBC",O) end,
    [0xEA] = self.NOP,
    [0xEC] = function(self,O,P) return self:Absolute_Operand("CPX",P,O) end,
    [0xED] = function(self,O,P) return self:Absolute_Operand("SBC",P,O) end,
    [0xEE] = function(self,O,P) return self:Absolute_Operand("INC",P,O) end,
    [0xF0] = function(self,O) return self:Relative_Operand("BEQ",O) end,
    [0xF1] = function(self,O) return self:Indirect_Y_Operand("SBC",O) end,
    [0xF5] = function(self,O) return self:ZeroPage_X_Operand("SBC",O) end,
    [0xF6] = function(self,O) return self:ZeroPage_X_Operand("INC",O) end,
    [0xF8] = self.SED,
    [0xF9] = function(self,O,P) return self:Absolute_Y_Operand("SBC",P,O) end,
    [0xFD] = function(self,O,P) return self:Absolute_X_Operand("SBC",P,O) end,
    [0xFE] = function(self,O,P) return self:Absolute_X_Operand("INC",P,O) end,
    --ILLEGAL OPCODES
    [0x0F] = function(self,O,P) self:Absolute_Operand("ASL", P, O) self:Absolute_Operand("ORA", P, O) return 3,5 end, --ASO
    [0x1F] = function(self,O,P) self:Absolute_X_Operand("ASL", P, O) self:Absolute_X_Operand("ORA", P, O) return 3,7 end,
    [0x1B] = function(self,O,P) self:Absolute_Y_Operand("ASL", P, O) self:Absolute_Y_Operand("ORA", P, O) return 3,7 end,
    [0x07] = function(self,O)   self:ZeroPage_Operand("ASL", O) self:ZeroPage_Operand("ORA", O) return 2,5 end,
    [0x17] = function(self,O) self:ZeroPage_X_Operand("ASL", O) self:ZeroPage_X_Operand("ORA", O) return 2,6 end,
    [0x03] = function(self,O) self:Indirect_X_Operand("ASL", O) self:Indirect_X_Operand("ORA", O) return 2,8 end,
    [0x13] = function(self,O) self:Indirect_Y_Operand("ASL", O) self:Indirect_Y_Operand("ORA", O) return 2,8 end,
    [0x2F] = function(self,O,P) self:Absolute_Operand("ROL", P, O) self:Absolute_Operand("AND", P, O) return 3,5 end,
    [0x3F] = function(self,O,P) self:Absolute_X_Operand("ROL", P, O) self:Absolute_X_Operand("AND", P, O) return 3,7 end,
    [0x3B] = function(self,O,P) self:Absolute_Y_Operand("ROL", P, O) self:Absolute_Y_Operand("AND", P, O) return 3,7 end,
    [0x27] = function(self,O)   self:ZeroPage_Operand("ROL", O) self:ZeroPage_Operand("AND", O) return 2,5 end,
    [0x37] = function(self,O)   self:ZeroPage_X_Operand("ROL", O) self:ZeroPage_X_Operand("AND", O) return 2,6 end,
    [0x23] = function(self,O)   self:Indirect_X_Operand("ROL", O) self:Indirect_X_Operand("AND", O) return 2,8 end,
    [0x33] = function(self,O)   self:Indirect_Y_Operand("ROL", O) self:Indirect_Y_Operand("AND", O) return 2,8 end,
    [0x4F] = function(self,O,P) self:Absolute_Operand("LSR", P, O) self:Absolute_Operand("EOR", P, O) return 3,5 end,
    [0x5F] = function(self,O,P) self:Absolute_X_Operand("LSR", P, O) self:Absolute_X_Operand("EOR", P, O) return 3,7 end,
    [0x5B] = function(self,O,P) self:Absolute_Y_Operand("LSR", P, O) self:Absolute_Y_Operand("EOR", P, O) return 3,7 end,
    [0x47] = function(self,O)   self:ZeroPage_Operand("LSR", O) self:ZeroPage_Operand("EOR", O) return 2,5 end,
    [0x57] = function(self,O) self:ZeroPage_X_Operand("LSR", O) self:ZeroPage_X_Operand("EOR", O) return 2,6 end,
    [0x43] = function(self,O) self:Indirect_X_Operand("LSR", O) self:Indirect_X_Operand("EOR", O) return 2,8 end,
    [0x53] = function(self,O) self:Indirect_Y_Operand("LSR", O) self:Indirect_Y_Operand("EOR", O) return 2,8 end,
    [0x6F] = function(self,O,P) self:Absolute_Operand("ROR", P, O) self:Absolute_Operand("ADC", P, O) return 3,5 end,
    [0x7F] = function(self,O,P) self:Absolute_X_Operand("ROR", P, O) self:Absolute_X_Operand("ADC", P, O) return 3,7 end,
    [0x7B] = function(self,O,P) self:Absolute_Y_Operand("ROR", P, O) self:Absolute_Y_Operand("ADC", P, O) return 3,7 end,
    [0x67] = function(self,O)   self:ZeroPage_Operand("ROR", O) self:ZeroPage_Operand("ADC", O) return 2,5 end,
    [0x77] = function(self,O) self:ZeroPage_X_Operand("ROR", O) self:ZeroPage_X_Operand("ADC", O) return 2,6 end,
    [0x63] = function(self,O) self:Indirect_X_Operand("ROR", O) self:Indirect_X_Operand("ADC", O) return 2,8 end,
    [0x73] = function(self,O) self:Indirect_Y_Operand("ROR", O) self:Indirect_Y_Operand("ADC", O) return 2,8 end,
    [0x8F] = function(self,O,P) self.WriteMem(lshift(P,8)+O,band(self.A, self.X)) return 3,4 end,
    [0x87] = function(self,O) self.WriteMem(O,band(self.A, self.X)) return 2,3 end,
    [0x97] = function(self,O) self.WriteMem(band((O+self.Y),0xFF),band(self.A, self.X)) return 2,4 end,
    [0x83] = function(self,O)  local Adr=lshift(self.ReadMem(band((O+self.X+1), 0xFF)),8) + self.ReadMem(band((O+self.X), 0xFF)) self.WriteMem(Adr,band(self.A, self.X)) return 2,6 end,
    [0xAF] = function(self,O,P) self:Absolute_Operand("LDA", P, O) self:Absolute_Operand("LDX", P, O) return 3,4 end,
    [0xBF] = function(self,O,P) self:Absolute_X_Operand("LDA", P, O) self:Absolute_X_Operand("LDX", P, O) return 3,4 end, --TODO: +PageChanged
    [0xA7] = function(self,O)   self:ZeroPage_Operand("LDA", O) self:ZeroPage_Operand("LDX", O) return 2,3 end,
    [0xB7] = function(self,O) self:ZeroPage_X_Operand("LDA", O) self:ZeroPage_X_Operand("LDX", O) return 2,4 end,
    [0xA3] = function(self,O) self:Indirect_X_Operand("LDA", O) self:Indirect_X_Operand("LDX", O) return 2,6 end,
    [0xB3] = function(self,O) self:Indirect_Y_Operand("LDA", O) self:Indirect_Y_Operand("LDX", O) return 2,5 end, --TODO: +PageChanged
    [0xCF] = function(self,O,P) self:Absolute_Operand("DEC", P, O) self:Absolute_Operand("CMP", P, O) return 3,5 end,
    [0xDF] = function(self,O,P) self:Absolute_X_Operand("DEC", P, O) self:Absolute_X_Operand("CMP", P, O) return 3,7 end,
    [0xDB] = function(self,O,P) self:Absolute_Y_Operand("DEC", P, O) self:Absolute_Y_Operand("CMP", P, O) return 3,7 end,
    [0xC7] = function(self,O)   self:ZeroPage_Operand("DEC", O) self:ZeroPage_Operand("CMP", O) return 2,5 end,
    [0xD7] = function(self,O) self:ZeroPage_X_Operand("DEC", O) self:ZeroPage_X_Operand("CMP", O) return 2,6 end,
    [0xC3] = function(self,O) self:Indirect_X_Operand("DEC", O) self:Indirect_X_Operand("CMP", O) return 2,8 end,
    [0xD3] = function(self,O) self:Indirect_Y_Operand("DEC", O) self:Indirect_Y_Operand("CMP", O) return 2,8 end,
    [0xEF] = function(self,O,P) self:Absolute_Operand("INC", P, O) self:Absolute_Operand("SBC", P, O) return 3,5 end,
    [0xFF] = function(self,O,P) self:Absolute_X_Operand("INC", P, O) self:Absolute_X_Operand("SBC", P, O) return 3,7 end,
    [0xFB] = function(self,O,P) self:Absolute_Y_Operand("INC", P, O) self:Absolute_Y_Operand("SBC", P, O) return 3,7 end,
    [0xE7] = function(self,O)   self:ZeroPage_Operand("INC", O) self:ZeroPage_Operand("SBC", O) return 2,5 end,
    [0xF7] = function(self,O) self:ZeroPage_X_Operand("INC", O) self:ZeroPage_X_Operand("SBC", O) return 2,6 end,
    [0xE3] = function(self,O) self:Indirect_X_Operand("INC", O) self:Indirect_X_Operand("SBC", O) return 2,8 end,
    [0xF3] = function(self,O) self:Indirect_Y_Operand("INC", O) self:Indirect_Y_Operand("SBC", O) return 2,8 end,
    [0x4B] = function(self,O) self:Immediate_Operand("AND",O) self:Accumulator_Operand("LSR") return 2,2 end,
    [0x6B] = function(self,O) self:Immediate_Operand("AND",O) self:Accumulator_Operand("ROR") return 2,2 end,
    [0x8B] = function(self,O) self:TXA() self:Immediate_Operand("AND",O) return 2,2 end,
    [0xAB] = function(self,O) self:Immediate_Operand("ORA",0xEE) self:Immediate_Operand("AND",O) self:TAX() return 2,2 end,
    [0xCB] = function(self,O) local OldA = self.A self.A = band(self.A, self.X) self:Immediate_Operand("CMP", Operand1) self.X = self.A - Operand1 self.A = OldA return 2,2 end,
    [0x1A] = self.NOP,
    [0x3A] = self.NOP,
    [0x5A] = self.NOP,
    [0x7A] = self.NOP,
    [0xDA] = self.NOP,
    [0xFA] = self.NOP,
    [0x80] = function() return 2, math.random(2,4) end,
    [0x82] = function() return 2, math.random(2,4) end,
    [0xC2] = function() return 2, math.random(2,4) end,
    [0xE2] = function() return 2, math.random(2,4) end,
    [0x04] = function() return 2, math.random(2,4) end,
    [0x14] = function() return 2, math.random(2,4) end,
    [0x34] = function() return 2, math.random(2,4) end,
    [0x44] = function() return 2, math.random(2,4) end,
    [0x54] = function() return 2, math.random(2,4) end,
    [0x64] = function() return 2, math.random(2,4) end,
    [0x74] = function() return 2, math.random(2,4) end,
    [0xD4] = function() return 2, math.random(2,4) end,
    [0xF4] = function() return 2, math.random(2,4) end,
    [0x0C] = function() return 3,4 end,
    [0x1C] = function() return 3,4 end,
    [0x3C] = function() return 3,4 end,
    [0x5C] = function() return 3,4 end,
    [0x7C] = function() return 3,4 end,
    [0xDC] = function() return 3,4 end,
    [0xFC] = function() return 3,4 end,
    --HLT OPCODES INTENTIONALLY LEFT OUT, PROGRAM WILL CRASH ANYWAYS
    [0x9B] = function(self,O,P) local A = band(self.A, self.X) self.S = A self.WriteMem(lshift(P,8)+O+self.Y,band(A, (Operand2+0x01))) return 3,5 end,
    [0x9C] = function(self,O,P) local Result = band(self.Y , (P + 0x01)) self.WriteMem(lshift(P,8)+O+self.X,Result) return 3,5 end,
    [0x9E] = function(self,O,P) local Result = band(self.X , (P + 0x01)) self.WriteMem(lshift(P,8)+O+self.Y,Result) return 3,5 end,
    [0x9F] = function(self,O,P) local A = band(self.A , self.X) A = band(A , (P+0x01)) self.WriteMem(lshift(P,8)+O+self.Y,A) return 3,5 end,
    [0x93] = function(self,O) local A = band(self.A , self.X) A = band(A , (P+0x01)) local Addr = lshift(self.ReadMem(P),8) + self.ReadMem(O) self.WriteMem(Addr+self.Y,A) return 3,6 end,
    [0x2B] = function(self,O) self:Immediate_Operand("AND", O) self.P.C = self.P.N return 2,2 end,
    [0x0B] = function(self,O) self:Immediate_Operand("AND", O) self.P.C = self.P.N return 2,2 end,
    [0xEB] = function(self,O) return self:Immediate_Operand("SBC",O) end,
    [0x89] = function() return 2,2 end,
    [0xBB] = function(self,O,P) local R=band(self.ReadMem(lshift(Operand2,8)+Operand1+self.Y) , self.S) self.A = R self.S = R self.X = R return 3,4 end
    }


    --setmetatable(self.OPCD2ASM, {__index = function(table, key) print("PC = $"..self.D2H(self.PC)) print(key) end})
end

--ALL ADDRESSING MODES

function P6502:Immediate_Operand(F,Operand)
    return 2, self:DoInstruction(F,nil, Operand,Immediate)
end

function P6502:Accumulator_Operand(F)
    return 1, self:DoInstruction(F,nil,self.A, Accumulator)
end

function P6502:Absolute_Operand(F,High,Low)
    local Adr=bor(lshift(High,8),Low)
    return 3, self:DoInstruction(F,Adr, self.ReadMem(Adr),Absolute)
end
    
function P6502:ZeroPage_Operand(F,Operand)
    return 2, self:DoInstruction(F,Operand, self.ReadMem(Operand), ZeroPage)
end

function P6502:Absolute_X_Operand(F, High,Low)
    local Adr=(bor(lshift(High,8),Low)+self.X)
    local P=0
    if band((Adr - self.X),0x100) ~= band(Adr,0x100) then P=1 end
    return 3, self:DoInstruction(F,Adr, self.ReadMem(Adr), AbsoluteX, P)
end

function P6502:Absolute_Y_Operand(F, High,Low)
    local Adr=bor(lshift(High,8),Low)+self.Y
    local P=0
    if band((Adr - self.Y),0x100) ~= band(Adr, 0x100) then P=1 end
    return 3, self:DoInstruction(F,Adr, self.ReadMem(Adr), AbsoluteY, P)
end

function P6502:Indirect_Operand(F,High,Low)
    local OpAddress= bor(lshift(High, 8),Low)
    local Adr=bor(lshift(self.ReadMem(OpAddress + 1),8),self.ReadMem(OpAddress))
    return 3, self:DoInstruction(F, Adr, self.ReadMem(Adr), Indirect)
end

function P6502:Indirect_X_Operand(F,Operand)
    local Adr=bor(lshift(self.ReadMem(band((Operand+self.X+1), 0xFF)),8), self.ReadMem(band((Operand+self.X), 0xFF)))
    return 2, self:DoInstruction(F,Adr, self.ReadMem(Adr), IndirectX)
end

function P6502:Indirect_Y_Operand(F, Operand)
    local Adr = bor(lshift(self.ReadMem(band((Operand+1), 0xFF)),8), self.ReadMem(Operand))+self.Y
    local P=0
    if band((Adr-self.Y),0x100) ~= band(Adr, 0x100) then
        P=1
    end
    return 2, self:DoInstruction(F,Adr, self.ReadMem(Adr), IndirectY,P)
end

function P6502:ZeroPage_X_Operand(F, Operand)
    local Adr=Operand+self.X
    return 2, self:DoInstruction(F, band(Adr, 0xFF), self.ReadMem(band(Adr,0xFF)), ZeroPageX)
end

function P6502:ZeroPage_Y_Operand(F, Operand)
    local Adr=Operand+self.Y
    return 2, self:DoInstruction(F, band(Adr, 0xFF), self.ReadMem(band(Adr, 0xFF)), ZeroPageY)
end

function P6502:Relative_Operand(F,Operand)
    local V
    if Operand > 127 then
        V = Operand-256
    else
        V = Operand
    end
    local P=0
    if band(self.PC,0x100) ~= band((self.PC+V+2), 0x100) then P=1 end
    return 2, self:DoInstruction(F, nil, V, Relative, P)
end



--END ADDRESSING MODES

function P6502:DoInstruction(String,Address,Value,Type,PageChanged)
    if Debug then
        print(String)
    end
    
    local F=self.ASM2INS[String]
    if F==nil then
        if self.HaltOnError then
            error("6502: Invalid Instruction "..String)
        else
            if PRINTMSG then print("6502: Invalid Instruction "..String) end
        end
        return nil
    end
    return F(self, Address, Value, Type, PageChanged)
end

MAXDECIMAL = 0x99
--START INSTRUCTION SET
function P6502:ADC(Address,Value,Type,PageChanged)
    local OldA=self.A
    local Result
    if self.P.D == 1 then --BCD MODE
        Result = self.H2D(tostring(math.min(tonumber(self.D2H(Value)),MAXDECIMAL) + math.min(tonumber(self.D2H(self.A)),MAXDECIMAL) + self.P.C))
     --   print("A: "..self.D2H(self.A)..", V: "..self.D2H(Value)..", Result = "..self.D2H(Result))
    else
     Result=Value + self.A + self.P.C
    end
    self.P.C=band(rshift(Result,8),0x1)
    self.A=band(Result,0xFF)
    if self.A>127 then
        self.P.N=1
    else
        self.P.N=0
    end
    if self.A==0 then
        self.P.Z=1
    else
        self.P.Z=0
    end
    if (rshift(bxor(OldA, Value), 7)==0x0 and rshift(bxor(OldA,band(Result,0xFF)),7)==0x1) then
        self.P.V=1
    else
        self.P.V=0
    end
    if Type == Immediate then return  2
    elseif Type == ZeroPage then return  3
    elseif Type == ZeroPageX then return  4
    elseif Type == Absolute then return  4
    elseif Type == AbsoluteX then return (4+PageChanged)
    elseif Type == AbsoluteY then return  (4+PageChanged)
    elseif Type == IndirectX then return  6
    elseif Type == IndirectY then return  (5+PageChanged) end
end

function P6502:AND(Address,Value,Type,PageChanged)
    local Result=band(Value,self.A)
    self.A=band(Result,0xFF)
    if self.A>127 then
        self.P.N=1
    else
        self.P.N=0
    end
    if self.A==0 then
        self.P.Z=1
    else
        self.P.Z=0
    end
    if Type == Immediate then return  2
    elseif Type == ZeroPage then return  3
    elseif Type == ZeroPageX then return  4
    elseif Type == Absolute then return  4
    elseif Type == AbsoluteX then return   (4+PageChanged)
    elseif Type == AbsoluteY then return   (4+PageChanged)
    elseif Type == IndirectX then return  6
    elseif Type == IndirectY then return   (5+PageChanged) end
end

function P6502:ASL(Address,Value,Type,PageChanged)
    local Re=lshift(Value,1)
    self.P.C=rshift(Value, 7)
    if Type~=Accumulator then
        self.WriteMem(Address,band(Re, 0xFF))
    else
        self.A = band(Re, 0xFF)
    end
    if band(Re,0xFF)>127 then
        self.P.N=1
        self.P.Z=0
    else
        self.P.N=0
        if band(Re,0xFF)==0 then
            self.P.Z=1
        else
            self.P.Z=0
        end
    end
    if Type == Accumulator then return 2
    elseif Type == ZeroPage then return  5
    elseif Type == ZeroPageX then return  6
    elseif Type == Absolute then return  6
    elseif Type == AbsoluteX then return  7 end
    
end

function P6502:BCC(Address,Value,Type,PageChanged)
    if self.P.C == 0 then
        self.PC = self.PC + Value
        return  (3+PageChanged)
    end
    return  2
end

function P6502:BCS(Address,Value,Type,PageChanged)
    if self.P.C == 1 then
        self.PC = self.PC + Value
        return  (3+PageChanged)
    end
    return  2
end

function P6502:BEQ(Address,Value,Type,PageChanged)
    if self.P.Z == 1 then
        self.PC = self.PC + Value
        return  (3+PageChanged)
    end
    return  2
end

function P6502:BIT(Address,Value,Type,PageChanged)
    --BIT ZeroPage
    if band(Value,self.A)==0 then
        self.P.Z=1
    else
        self.P.Z=0
    end
    self.P.V= band(rshift(Value, 6),0x1)
    self.P.N= band(rshift(Value, 7),0x1)
    
    if Type==ZeroPage then return 3 else return 4 end
end

function P6502:BMI(Address,Value,Type,PageChanged)
    if self.P.N == 1 then
        self.PC = self.PC + Value
        return  (3+PageChanged)
    end
    return  2
end

function P6502:BNE(Address,Value,Type,PageChanged)
    if self.P.Z == 0 then
        self.PC = self.PC + Value
        return  (3+PageChanged)
    end
    return  2
end

function P6502:BPL(Address,Value,Type,PageChanged)
    if self.P.N == 0 then
        self.PC = self.PC + Value
        return  (3+PageChanged)
    end
    return  2
end

function P6502:BRK()
    if self.P.B == 1 then
    if self.HaltOnBRK then
    error("BRK at PC=$"..self.D2H(self.PC))
            else
if Debug or PRINTMSG then
        print("BRK at PC=$"..self.D2H(self.PC))
        end
    end
    self:Push(self.PC+2,nil,true)
    self:Push(self.P,true,nil)
    self.PC = lshift(self.ReadMem(0xFFFF),8)+self.ReadMem(0xFFFE) - 1
    self.P.I = 1
    return 1,7
    else
        --Break Bit On, turn off interrupts
        return 1,7
    end
end

function P6502:BVC(Address,Value,Type,PageChanged)
    if self.P.V == 0 then
        self.PC = self.PC + Value
        return  (3+PageChanged)
    end
    return  2
end

function P6502:BVS(Address,Value,Type,PageChanged)
    if self.P.V == 1 then
        self.PC = self.PC + Value
        return  (3+PageChanged)
    end
    return  2
end

function P6502:CLC()
    self.P.C = 0
    return 1,2
end

function P6502:CLD()
    self.P.D = 0
    return 1,2
end

function P6502:CLI()
    self.P.I = 0
    return 1,2
end

function P6502:CLV()
    self.P.V = 0
    return 1,2
end

function P6502:CMP(Address,Value,Type,PageChanged)
    local Result=self.A - Value
    if Result < 0 then Result = Result + 256 end
    if self.A >= Value then
        self.P.C = 1
    else
        self.P.C=0
    end
    if Result>127 then
        self.P.N=1
    else
        self.P.N=0
    end
    if Result==0 then
        self.P.Z=1
    else
        self.P.Z=0
    end
    if Type == Immediate then return  2
    elseif Type == ZeroPage then return  3
    elseif Type == ZeroPageX then return  4
    elseif Type == Absolute then return  4
    elseif Type == AbsoluteX then return   (4+PageChanged)
    elseif Type == AbsoluteY then return   (4+PageChanged)
    elseif Type == IndirectX then return  6
    elseif Type == IndirectY then return   (5+PageChanged) end
end

function P6502:CPX(Address,Value,Type,PageChanged)
    local Result=self.X - Value
    if Result < 0 then Result = Result + 256 end
    if (self.X >= Value) then
        self.P.C = 1
    else
        self.P.C=0
    end
    if Result>127 then
        self.P.N=1
    else
        self.P.N=0
    end
    if Result==0 then
        self.P.Z=1
    else
        self.P.Z=0
    end
    if Type == Immediate then return  2
    elseif Type == ZeroPage then return  3
    elseif Type == Absolute then return  4 end
end

function P6502:CPY(Address,Value,Type,PageChanged)
    local Result=self.Y - Value
    if Result < 0 then Result = Result + 256 end
    if (self.Y >= Value) then
        self.P.C = 1
    else
        self.P.C=0
    end
    if Result>127 then
        self.P.N=1
    else
        self.P.N=0
    end
    if Result==0 then
        self.P.Z=1
    else
        self.P.Z=0
    end
    if Type == Immediate then return  2
    elseif Type == ZeroPage then return  3
    elseif Type == Absolute then return  4 end
end

function P6502:DEC(Address,Value,Type,PageChanged)
    local Result = (Value - 1)
    if Result < 0 then Result = Result + 256 end
    Result = band(Result, 0xFF)
    if Result > 127 then
        self.P.N = 1
    else
        self.P.N = 0
    end
    if Result == 0 then
        self.P.Z = 1
    else
        self.P.Z = 0
    end
    self.WriteMem(Address,Result)
    if Type == ZeroPage then return  5
    elseif Type == ZeroPageX then return  6
    elseif Type == Absolute then return  6
    elseif Type == AbsoluteX then return  7 end
end

function P6502:DEX()
    self.X = (self.X - 1)
    if self.X<0 then self.X = band(self.X + 256,0xFF) end
    if self.X > 127 then
        self.P.N = 1
    else
        self.P.N = 0
    end
    if self.X == 0 then
        self.P.Z = 1
    else
        self.P.Z = 0
    end
    return 1,2
end

function P6502:DEY()
    self.Y = (self.Y - 1)
    if self.Y < 0 then self.Y = band(self.Y + 256, 0xFF) end
    if self.Y > 127 then
        self.P.N = 1
    else
        self.P.N = 0
    end
    if self.Y == 0 then
        self.P.Z = 1
    else
        self.P.Z = 0
    end
    return 1,2
end

function P6502:EOR(Address,Value,Type,PageChanged)
    local Result=bxor(Value,self.A)
    self.A=Result
    if self.A>127 then
        self.P.N=1
    else
        self.P.N=0
    end
    if self.A==0 then
        self.P.Z=1
    else
        self.P.Z=0
    end
    if Type == Immediate then return  2
    elseif Type == ZeroPage then return  3
    elseif Type == ZeroPageX then return  4
    elseif Type == Absolute then return  4
    elseif Type == AbsoluteX then return   (4+PageChanged)
    elseif Type == AbsoluteY then return   (4+PageChanged)
    elseif Type == IndirectX then return  6
    elseif Type == IndirectY then return   (5+PageChanged) end
end

function P6502:INC(Address,Value,Type,PageChanged)
    local Result = band((Value + 1),0xFF)
    if Result > 127 then
        self.P.N = 1
    else
        self.P.N = 0
    end
    if Result == 0 then
        self.P.Z = 1
    else
        self.P.Z = 0
    end
    self.WriteMem(Address,Result)
    if Type == ZeroPage then return  5
    elseif Type == ZeroPageX then return  6
    elseif Type == Absolute then return  6
    elseif Type == AbsoluteX then return  7
    end
end

function P6502:INX()
    self.X = band((self.X + 1),0xFF)
    if self.X > 127 then
        self.P.N = 1
    else
        self.P.N = 0
    end
    if self.X == 0 then
        self.P.Z = 1
    else
        self.P.Z = 0
    end
    return 1,2
end

function P6502:INY()
    self.Y = band((self.Y + 1),0xFF)
    if self.Y > 127 then
        self.P.N = 1
    else
        self.P.N = 0
    end
    if self.Y == 0 then
        self.P.Z = 1
    else
        self.P.Z = 0
    end
    return 1,2
end

function P6502:JMP(Address,Value,Type,PageChanged)
    self.PC = Address - 3
    if Type == Absolute then return  3
    elseif Type == Indirect then return  5 end
end

function P6502:JSR(Address,Value,Type,PageChanged)
    self:Push(self.PC+2, nil, true)
    self.PC = Address - 3
    return 6
end

function P6502:LDA(Address,Value,Type,PageChanged)
    self.A = Value
    if self.A > 127 then
        self.P.N = 1
        self.P.Z=0
    else
        self.P.N = 0
        if self.A == 0 then
            self.P.Z = 1
        else
            self.P.Z = 0
        end
    end
    if Type == Immediate then return  2
    elseif Type == ZeroPage then return  3
    elseif Type == ZeroPageX then return  4
    elseif Type == Absolute then return  4
    elseif Type == AbsoluteX or Type == AbsoluteY then return  (4+PageChanged)
    elseif Type == IndirectX then return  6
    elseif Type == IndirectY then return  (5+PageChanged) end
end

function P6502:LDX(Address,Value,Type,PageChanged)
    self.X = Value
    if self.X>127 then self.P.N = 1 self.P.Z = 0 else
        self.P.N=0
        if self.X == 0 then self.P.Z = 1 else self.P.Z = 0 end
    end
    if Type == Immediate then return  2
    elseif Type == ZeroPage then return  3
    elseif Type == ZeroPageY then return  4
    elseif Type == Absolute then return  4
    elseif Type == AbsoluteY then return  (4+PageChanged) end
end

function P6502:LDY(Address,Value,Type,PageChanged)
    self.Y = Value
    if self.Y>127 then self.P.N = 1 self.P.Z=0 else
        self.P.N=0
        if self.Y == 0 then self.P.Z = 1 else self.P.Z = 0 end
    end
    if Type == Immediate then return  2
    elseif Type == ZeroPage then return  3
    elseif Type == ZeroPageX then return  4
    elseif Type == Absolute then return  4
    elseif Type == AbsoluteX then return  (4+PageChanged) end
end

function P6502:LSR(Address,Value,Type,PageChanged)
    self.P.C=band(Value,0x1)
   -- print(self.P.C)
    if Type ~= Accumulator then
        self.WriteMem(Address,rshift(Value,1))
    else
        self.A = rshift(self.A,1) 
    end
    self.P.N=0
    local R=rshift(Value,1)
    if R==0 then
        self.P.Z=1
    else
        self.P.Z=0
    end
    if Type == Accumulator then return 2
    elseif Type == ZeroPage then return  5
    elseif Type == ZeroPageX then return  6
    elseif Type == Absolute then return  6
    elseif Type == AbsoluteX then return  7 end
end

function P6502:NOP()
    return 1,2
end

function P6502:ORA(Address,Value,Type,PageChanged)
    local Result=bor(Value,self.A)
    self.A=Result
    if self.A>127 then
        self.P.N=1
    else
        self.P.N=0
    end
    if self.A==0 then
        self.P.Z=1
    else
        self.P.Z=0
    end
    if Type == Immediate then return  2
    elseif Type == ZeroPage then return  3
    elseif Type == ZeroPageX then return  4
    elseif Type == Absolute then return  4
    elseif Type == AbsoluteX then return   (4+PageChanged)
    elseif Type == AbsoluteY then return   (4+PageChanged)
    elseif Type == IndirectX then return  6
    elseif Type == IndirectY then return   (5+PageChanged) end
end

function P6502:PHA()
    self:Push(self.A,false,false)
    return 1,3
end

function P6502:PHP()
    self:Push(self.P,true,false)
    return 1,3
end

function P6502:PLA()
    self.A = self:Pop(false,false)
    if self.A > 127 then self.P.N = 1 else self.P.N=0 end
    if self.A == 0 then self.P.Z = 1 else self.P.Z = 0 end
    return 1,4
end

function P6502:PLP()
    self.P = self:Pop(false,true)
    self.P.B = 1 --always
    return 1,4
end

function P6502:ROL(Address,Value,Type,PageChanged)
    local Re=lshift(Value,1) + self.P.C
    self.P.C = band(rshift(Value, 7), 0x1)
    if Type == Accumulator then
        self.A = band(Re, 0xFF)
    else
        self.WriteMem(Address,band(Re, 0xFF))
    end
    if band(Re,0xFF)>127 then
        self.P.N = 1
        self.P.Z=0
    else
        self.P.N = 0
        if band(Re,0xFF)==0 then
            self.P.Z = 1
        else
            self.P.Z = 0
        end
    end
    if Type == Accumulator then return 2
    elseif Type == ZeroPage then return  5
    elseif Type == ZeroPageX then return  6
    elseif Type == Absolute then return  6
    elseif Type == AbsoluteX then return  7 end
end

function P6502:ROR(Address,Value,Type,PageChanged)
    local Re= rshift(Value,1) + lshift(self.P.C,7)
    self.P.C = band(Value,0x1)
    if Type == Accumulator then
        self.A = band(Re,0xFF)
    else
        self.WriteMem(Address,band(Re,0xFF))
    end
    if Re>127 then
        self.P.N = 1
        self.P.Z=0
    else
        self.P.N = 0
        if Re==0 then
            self.P.Z = 1
        else
            self.P.Z = 0
        end
    end
    if Type == Accumulator then return 2
    elseif Type == ZeroPage then return  5
    elseif Type == ZeroPageX then return  6
    elseif Type == Absolute then return  6
    elseif Type == AbsoluteX then return  7 end
end

function P6502:RTI()
    self.P = self:Pop(false,true)
    self.P.B=1
    
    self.PC = self:Pop(true,false)
    return 0,6 --PC Already in correct location
end

function P6502:RTS()
    self.PC = self:Pop(true)
    return 1,6
end

function P6502:SBC(Address,Value,Type,PageChanged)
    local Result=(self.A - Value) - (1-self.P.C)
    if self.P.D == 1 then
  --           print("A: "..self.D2H(self.A)..", V: "..self.D2H(Value)..", C: "..self.P.C)
        Result = self.H2D(tostring(math.min(tonumber(self.D2H(self.A)), 99)-math.min(tonumber(self.D2H(Value)),99) - (1-self.P.C)))
        if Result < 0 then
            Result = band(self.H2D(tostring(math.min(tonumber(self.D2H(Value)), 99)-math.min(tonumber(self.D2H(self.A)),99) - (1-self.P.C))),0xFF)
            self.P.C = 0
        else 
            self.P.C = 1
        end
      --      print("Result = "..self.D2H(Result))
    else
        if Result <0 then self.P.C=0 Result = Result + 0x100 else self.P.C=1 end
    end
    if rshift(bxor(self.A,Result), 7)==0x1 and rshift(bxor(self.A, Value), 7)==0x1 then
        self.P.V=1
    else
        self.P.V=0
    end
    if band(Result,0xFF)>127 then
        self.P.N=1
    else
        self.P.N=0
    end
    if band(Result,0xFF)==0 then
        self.P.Z=1
    else
        self.P.Z=0
    end
    self.A=band(Result , 0xFF)
    if Type == Immediate then return  2
    elseif Type == ZeroPage then return  3
    elseif Type == ZeroPageX then return  4
    elseif Type == Absolute then return  4
    elseif Type == AbsoluteX then return   (4+PageChanged)
    elseif Type == AbsoluteY then return   (4+PageChanged)
    elseif Type == IndirectX then return  6
    elseif Type == IndirectY then return   (5+PageChanged) end
end

function P6502:SEC()
    self.P.C = 1
    return 1,2
end

function P6502:SED()
    self.P.D=1
    return 1,2
end

function P6502:SEI()
    self.P.I=1
    return 1,2
end

function P6502:STA(Address,Value,Type,PageChanged)
    self.WriteMem(Address,self.A)
    if Type == ZeroPage then return  3
    elseif Type == ZeroPageX then return  4
    elseif Type == Absolute then return  4
    elseif Type == AbsoluteX or Type == AbsoluteY then return  5
    elseif Type == IndirectX or Type == IndirectY then return  6 end
end

function P6502:STX(Address,Value,Type,PageChanged)
    self.WriteMem(Address,self.X)
    if Type == ZeroPage then return  3
    elseif Type == ZeroPageY then return  4
    elseif Type == Absolute then return  4 end
end

function P6502:STY(Address,Value,Type,PageChanged)
    self.WriteMem(Address,self.Y)
    if Type == ZeroPage then return  3
    elseif Type == ZeroPageX then return  4
    elseif Type == Absolute then return  4 end
end

function P6502:TAX()
    self.X = self.A
    if self.X >127 then
        self.P.N=1
        self.P.Z=0
    else
        self.P.N=0
        if self.X==0 then
            self.P.Z=1
        else
            self.P.Z=0
        end
    end
    return 1,2
end

function P6502:TAY()
    self.Y = self.A
    if self.Y >127 then
        self.P.N=1
        self.P.Z=0
    else
        self.P.N=0
        if self.Y==0 then
            self.P.Z=1
        else
            self.P.Z=0
        end
    end
    return 1,2
end

function P6502:TSX()
    self.X = self.S
    if self.X >127 then
        self.P.N=1
        self.P.Z=0
    else
        self.P.N=0
        if self.X==0 then
            self.P.Z=1
        else
            self.P.Z=0
        end
    end
    return 1,2
end

function P6502:TXA()
    self.A = self.X
    if self.X >127 then
        self.P.N=1
        self.P.Z=0
    else
        self.P.N=0
        if self.X==0 then
            self.P.Z=1
        else
            self.P.Z=0
        end
    end
    return 1,2
end

function P6502:TXS()
    self.S = self.X
    return 1,2
end

function P6502:TYA()
    self.A = self.Y
    if self.A >127 then
        self.P.N=1
        self.P.Z=0
    else
        self.P.N=0
        if self.A==0 then
            self.P.Z=1
        else
            self.P.Z=0
        end
    end
    return 1,2
end



--END INSTRUCTION SET

function P6502:Push(V,P,W)
    if W~=true then
        local Inserty=V
        if P~=nil and P==true then
            --self.P
            Inserty=self.B2D({V.C, V.Z, V.I, V.D, V.B, 1, V.V, V.N})
        end
        self.WriteMem(self.S+self.StackStart,Inserty)
        self.S=self.S-1
        if self.S<0 then self.S=0xFF
            if self.HaltOnError then
         error("Stack overflow at PC=$"..self.D2H(self.PC))
                else
                if Debug or PRINTMSG then
                         print("Stack overflow at PC=$"..self.D2H(self.PC))
                end
            end
         end
    else
        local Low=band(V,0xFF)
        local High=rshift(V,8)
        self:Push(High)
        self:Push(Low)
    end
end

function P6502:Pop(IsWord,P)
    if IsWord~=true then
        if P~=true then
            local R
            if self.S < 0xFF then
             R=self.ReadMem(self.S+self.StackStart+0x1) --0x101 because stack points to first unused element not last used element
            else
            R=self.ReadMem(self.StackStart)
            end
            
         --   self.Memory[self.S+257]=0
            self.S=band((self.S+1),0xFF)
            if self.S==0 then
                if self.HaltOnError then
                error("Stack underflow at PC=$"..self.D2H(self.PC))
                    else
                    if Debug or PRINTMSG then
                           print("Stack underflow at PC=$"..self.D2H(self.PC)) 
                        end
                    end
            end
            return R
        else
            local R=self.D2B(self:Pop(false,false))
            return {C=R[1], Z=R[2], I=R[3],D=R[4], B=R[5], V=R[7], N=R[8]}
        end
    else
        local L=self:Pop()
        local H=self:Pop()
        return lshift(H,8)+L
    end
end

function StatusRegisterToString(s)
    local Str = ""
    if s.N == 1 then Str = Str .. "N" else Str = Str .. "-" end
    if s.V == 1 then Str = Str .. "V" else Str = Str .. "-" end
    Str = Str .. "1"
    if s.B == 1 then Str = Str .. "B" else Str = Str .. "-" end
    if s.D == 1 then Str = Str .. "D" else Str = Str .. "-" end
    if s.I == 1 then Str = Str .. "I" else Str = Str .. "-" end
    if s.Z == 1 then Str = Str .. "Z" else Str = Str .. "-" end
    if s.C == 1 then Str = Str .. "C" else Str = Str .. "-" end
    return Str
end

function P6502:ExecuteCode()
    --if self.PC < 0 then self.PC = self.PC + self.MemorySize elseif self.PC+1>self.MemorySize then     self.PC =(self.PC - self.MemorySize) end
    local OpCode = self.ReadMem(self.PC)
    local Operand1 = self.ReadMem(self.PC+1)
    local Operand2 = self.ReadMem(self.PC+2)

    local Cycles
    local Size
    local F = self.OPCD2ASM[OpCode]

   --[[ if F == nil then
        if self.HaltOnError and not self.AllowIllegals then
        error("Invalid OpCode: "..self.D2H(OpCode))
        else
            if self.AllowIllegals then
                Size, Cycles = self:ExecuteIllegalCode(OpCode, Operand1, Operand2)
            else
                if Debug or PRINTMSG then
            print("Invalid OpCode: "..self.D2H(OpCode))
                end
                    Size=1
        Cycles=7
        self.PC = self.PC + Size
        return -1
            end
        end
    else ]]--
        Size, Cycles = F(self,Operand1, Operand2)
  --end
    if Debug then
        print("-x-x-x-x-x-x-x-x-x-x-x-x")
        print("PC: $"..self.D2H(self.PC))
     print("Instruction: "..self.D2H(OpCode) .. " "..self.D2H(Operand1).." "..self.D2H(Operand2))
        print("(Decimal): ("..OpCode..") ("..Operand1..") ("..Operand2..")")
        print("Processor Info: A: $"..self.D2H(self.A)..", X: $"..self.D2H(self.X)..", Y: $"..self.D2H(self.Y)..", S: $"..self.D2H(self.S))
        print("Status Register: "..StatusRegisterToString(self.P))
        --print("Stack: "..HexDump(self.Memory,0x100+self.S+1, 0x1FF))
    end
    self.PC = self.PC + Size
    return Cycles
end
