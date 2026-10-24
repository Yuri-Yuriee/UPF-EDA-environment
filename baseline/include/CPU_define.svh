// opcode type define
`define NOP         7'd0
`define R_type      7'b0110011
`define I_type_1    7'b0000011
`define I_type_2    7'b0010011  
`define I_type_3    7'b1100111
`define S_type      7'b0100011  
`define B_type      7'b1100011
`define U_type_1    7'b0010111  
`define U_type_2    7'b0110111
`define J_type      7'b1101111
`define F_type_1    7'b0000111
`define F_type_2    7'b0100111  
`define F_type_3    7'b1010011
`define CSR         7'b1110011

// R-type base instructions {funct7, funct3}
`define ADD     {7'b0000000, 3'b000} // Add
`define SUB     {7'b0100000, 3'b000} // Subtract
`define SLL     {7'b0000000, 3'b001} // Shift left logical
`define SLT     {7'b0000000, 3'b010} // Set less than (signed)
`define SLTU    {7'b0000000, 3'b011} // Set less than (unsigned)
`define XOR     {7'b0000000, 3'b100} // Bitwise XOR
`define SRL     {7'b0000000, 3'b101} // Shift right logical
`define SRA     {7'b0100000, 3'b101} // Shift right arithmetic
`define OR      {7'b0000000, 3'b110} // Bitwise OR
`define AND     {7'b0000000, 3'b111} // Bitwise AND

// M-extension (integer multiplication)
`define MUL     {7'b0000001, 3'b000} // Multiply (low bits)
`define MULH    {7'b0000001, 3'b001} // Multiply high (signed × signed)
`define MULHSU  {7'b0000001, 3'b010} // Multiply high (signed × unsigned)
`define MULHU   {7'b0000001, 3'b011} // Multiply high (unsigned × unsigned)

// I-type   {funct3, opcode}
`define LW      {3'b010, 7'b0000011} // Load Word
`define ADDI    {3'b000, 7'b0010011} // Add Immediate
`define SLTI    {3'b010, 7'b0010011} // Set Less Than Immediate (signed)
`define SLTIU   {3'b011, 7'b0010011} // Set Less Than Immediate (unsigned)
`define XORI    {3'b100, 7'b0010011} // XOR Immediate
`define ORI     {3'b110, 7'b0010011} // OR Immediate
`define ANDI    {3'b111, 7'b0010011} // AND Immediate
`define LB      {3'b000, 7'b0000011} // Load Byte
`define JALR    {3'b000, 7'b1100111} // Jump And Link Register
`define LH      {3'b001, 7'b0000011} // Load Halfword
`define LBU     {3'b100, 7'b0000011} // Load Byte Unsigned
`define LHU     {3'b101, 7'b0000011} // Load Halfword Unsigned

// I-type shift  {funct7 ,funct3, opcode}
`define SLLI    {7'b0000000, 3'b001, 7'b0010011} // Shift Left Logical Immediate
`define SRLI    {7'b0000000, 3'b101, 7'b0010011} // Shift Right Logical Immediate
`define SRAI    {7'b0100000, 3'b101, 7'b0010011} // Shift Right Arithmetic Immediate

//S-type    {funct3}
`define SW      {3'b010}
`define SB      {3'b000}
`define SH      {3'b001}

//B-type    {funct3}
`define BEQ     {3'b000} // Branch if Equal
`define BNE     {3'b001} // Branch if Not Equal
`define BLT     {3'b100} // Branch if Less Than (signed)
`define BGE     {3'b101} // Branch if Greater or Equal (signed)
`define BLTU    {3'b110} // Branch if Less Than (unsigned)
`define BGEU    {3'b111} // Branch if Greater or Equal (unsigned)

//U-type    {opcode}
`define AUIPC   {7'b0010111}
`define LUI     {7'b0110111}

//F-type    {funct3, opcode}
`define FLW     {3'b010, 7'b0000111}
`define FSW     {3'b010, 7'b0100111}

//  {funct5, opcode}
`define FADD_S  {5'b00000, 7'b1010011}
`define FSUB_S  {5'b00001, 7'b1010011}

//CSR   {funct3}
`define CSRRW   {3'b001} // Atomic Read/Write CSR
`define CSRRS   {3'b010} // Atomic Read and Set Bits in CSR
`define CSRRC   {3'b011} // Atomic Read and Clear Bits in CSR
`define CSRRWI  {3'b101} // Atomic Read/Write CSR (immediate)
`define CSRRSI  {3'b110} // Atomic Read and Set Bits in CSR (immediate)
`define CSRRCI  {3'b111} // Atomic Read and Clear Bits in CSR (immediate)

`define RDINSTRETH {12'b110010000010, 5'b00000, 3'd010} // Read Upper 32 bits of Instret
`define RDINSTRET  {12'b110000000010, 5'b00000, 3'd010} // Read Lower 32 bits of Instret
`define RDCYCLEH   {12'b110010000000, 5'b00000, 3'd010} // Read Upper 32 bits of Cycle Counter
`define RDCYCLE    {12'b110000000000, 5'b00000, 3'd010} // Read Lower 32 bits of Cycle Counter
