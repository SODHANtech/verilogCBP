# Comprehensive Architectural Guide: 32-Bit Single-Cycle RISC-V CPU

This guide provides an end-to-end breakdown of the 32-bit Single-Cycle RISC-V CPU implemented in `E:\verilogCBP\rtl`. It includes structural mindmaps, datapath diagrams, per-module input/output interface schematics, internal logic explanations, and an instruction execution trace.

---

## 1. System Overview & Architecture Mindmap

```mermaid
mindmap
  root((RISC-V 32-Bit Single-Cycle CPU))
    Instruction Fetch [1. Fetch Stage]
      Program Counter [pc.v]
        Active-low reset to 0x0
        Updates every posedge clk
      PC Adder
        pc_plus_4 = pc + 4
      Instruction Memory [instruction_memory.v]
        64-word ROM / 256 bytes
        Word-addressed: pc[7:2]
    Instruction Decode [2. Decode Stage]
      Decoder [decoder.v]
        opcode [6:0]
        rd [11:7]
        funct3 [14:12]
        rs1 [19:15]
        rs2 [24:20]
        funct7 [31:25]
      Control Unit [control_unit.v]
        branch
        mem_read / mem_write
        mem_to_reg
        alu_src
        reg_write
        alu_op [1:0]
      Immediate Generator [immediate_gen.v]
        I-Type [Loads, ADDI, JALR]
        S-Type [Stores]
        B-Type [Branches]
        U-Type [LUI, AUIPC]
        J-Type [JAL]
      Register File [regfile.v]
        32 registers x 32 bits
        Dual async read ports rs1, rs2
        Single sync write port rd
        x0 hardwired to 0
    Execute [3. Execute Stage]
      ALU Control [alu_control.v]
        Decodes alu_op + funct3 + funct7[5]
        Generates 4-bit alu_control
      ALU Mux
        Chooses rs2_data vs imm_out
      ALU [alu.v]
        ADD, SUB, AND, OR, XOR, SLT
        Zero flag output
      Branch Target Adder
        pc_branch_target = pc + imm_out
      Next PC Mux
        Branch condition: branch AND zero
    Writeback [4. Writeback Stage]
      Result Mux
        Routes alu_result to rd_data
        Synchronous commit on posedge clk
```

---

## 2. Top-Level Datapath Interconnection

The complete single-cycle datapath connects the 8 internal submodules as shown below:

```mermaid
graph LR
    subgraph FETCH ["Fetch Stage"]
        PC["pc.v<br/>(Program Counter)"] -->|pc_current| IMEM["instruction_memory.v<br/>(ROM)"]
        PC -->|pc_current| PCADD["Adder: PC + 4"]
        PCADD -->|pc_plus_4| PCMUX{"Next PC Mux"}
        PCMUX -->|pc_next| PC
    end

    subgraph DECODE ["Decode & Register Stage"]
        IMEM -->|instruction| DEC["decoder.v"]
        IMEM -->|instruction| IMMGEN["immediate_gen.v"]
        
        DEC -->|opcode[6:0]| CTRL["control_unit.v"]
        DEC -->|rs1[4:0]| RF["regfile.v"]
        DEC -->|rs2[4:0]| RF
        DEC -->|rd[4:0]| RF

        CTRL -->|reg_write| RF
        CTRL -->|alu_src| ALUMUX{"ALU Mux"}
        CTRL -->|alu_op[1:0]| ALUCTRL["alu_control.v"]
        CTRL -->|branch| BR_AND{"AND Gate"}

        DEC -->|funct3[2:0]| ALUCTRL
        DEC -->|funct7[5]| ALUCTRL
    end

    subgraph EXECUTE ["Execution Stage"]
        RF -->|rs1_data| ALU["alu.v"]
        RF -->|rs2_data| ALUMUX
        IMMGEN -->|imm_out| ALUMUX
        ALUMUX -->|alu_b_operand| ALU
        ALUCTRL -->|alu_control[3:0]| ALU

        IMMGEN -->|imm_out| BRADD["Adder: PC + Imm"]
        PC -->|pc_current| BRADD
        BRADD -->|pc_branch_target| PCMUX

        ALU -->|zero| BR_AND
        BR_AND -->|branch & zero| PCMUX
    end

    subgraph WRITEBACK ["Writeback Stage"]
        ALU -->|alu_result| RF
    end
```

---

## 3. Module-by-Module Breakdown

```mermaid
graph TD
    classDef mod fill:#2b3a42,stroke:#4f9da6,stroke-width:2px,color:#ffffff;
    classDef inPort fill:#1b4965,stroke:#62b6cb,stroke-width:1px,color:#ffffff;
    classDef outPort fill:#2c6e49,stroke:#90be6d,stroke-width:1px,color:#ffffff;
```

---

### Module 1: Program Counter (`pc.v`)

#### Interface Diagram
```mermaid
graph LR
    CLK["clk (1-bit)"] --> PC["pc.v<br/>(Program Counter)"]
    RST["rst_n (1-bit active-low)"] --> PC
    PC_NEXT["pc_next [31:0]"] --> PC
    PC --> PC_OUT["pc_out [31:0]"]
```

#### Port Definitions
| Port | Direction | Width | Connected To | Description |
| :--- | :---: | :---: | :--- | :--- |
| `clk` | Input | 1 | Global Clock | Triggers state update on rising edge. |
| `rst_n` | Input | 1 | Global Reset | Active-low asynchronous reset. Resets PC to `0x00000000`. |
| `pc_next` | Input | 32 | Next PC Mux | Next instruction byte address (`pc + 4` or branch target). |
| `pc_out` | Output | 32 | IMEM, Adders | Current instruction memory address. |

#### Internal Logic
- **Flip-Flop Behavior**: Evaluates on `@(posedge clk or negedge rst_n)`.
- When `rst_n == 0`, `pc_out <= 32'h00000000`.
- Otherwise on clock tick, `pc_out <= pc_next`.

---

### Module 2: Instruction Memory (`instruction_memory.v`)

#### Interface Diagram
```mermaid
graph LR
    PC["pc [31:0]"] --> IMEM["instruction_memory.v<br/>(ROM)"]
    IMEM --> INSTR["instruction [31:0]"]
```

#### Port Definitions
| Port | Direction | Width | Connected To | Description |
| :--- | :---: | :---: | :--- | :--- |
| `pc` | Input | 32 | `pc.v` (`pc_out`) | Byte-aligned program counter. |
| `instruction` | Output | 32 | `decoder`, `immediate_gen` | Fetched 32-bit machine code instruction. |

#### Internal Logic & Design Considerations
- **Word-Aligned Addressing**: RISC-V instructions are 4 bytes (32 bits) wide. Therefore, the lowest 2 bits of `pc` (`pc[1:0]`) are always `2'b00`.
- The memory array is indexed by `pc[7:2]` (`pc >> 2`), selecting one of the 64 words (256-byte ROM space).
- Asynchronous combinational read: `assign instruction = memory[pc[7:2]];`. As soon as `pc` settles, the instruction is immediately available.

---

### Module 3: Instruction Decoder (`decoder.v`)

#### Interface Diagram
```mermaid
graph LR
    INSTR["instr [31:0]"] --> DEC["decoder.v<br/>(Field Extractor)"]
    DEC --> OPC["opcode [6:0]"]
    DEC --> RD["rd [4:0]"]
    DEC --> F3["funct3 [2:0]"]
    DEC --> RS1["rs1 [4:0]"]
    DEC --> RS2["rs2 [4:0]"]
    DEC --> F7["funct7 [6:0]"]
```

#### Port Definitions
| Port | Direction | Width | Connected To | Description |
| :--- | :---: | :---: | :--- | :--- |
| `instr` | Input | 32 | `instruction_memory` | 32-bit instruction code. |
| `opcode` | Output | 7 | `control_unit` | Instruction opcode (`instr[6:0]`). |
| `rd` | Output | 5 | `regfile.rd_addr` | Destination register address (`instr[11:7]`). |
| `funct3` | Output | 3 | `alu_control` | 3-bit sub-function code (`instr[14:12]`). |
| `rs1` | Output | 5 | `regfile.rs1_addr` | Source register 1 address (`instr[19:15]`). |
| `rs2` | Output | 5 | `regfile.rs2_addr` | Source register 2 address (`instr[24:20]`). |
| `funct7` | Output | 7 | `alu_control` | 7-bit function code (`instr[31:25]`). |

#### Internal Logic
Pure combinational direct bit extraction:
```verilog
assign opcode = instr[6:0];
assign rd     = instr[11:7];
assign funct3 = instr[14:12];
assign rs1    = instr[19:15];
assign rs2    = instr[24:20];
assign funct7 = instr[31:25];
```

---

### Module 4: Main Control Unit (`control_unit.v`)

#### Interface Diagram
```mermaid
graph LR
    OPC["opcode [6:0]"] --> CTRL["control_unit.v<br/>(Opcode Decoder)"]
    CTRL --> BR["branch (1-bit)"]
    CTRL --> MR["mem_read (1-bit)"]
    CTRL --> M2R["mem_to_reg (1-bit)"]
    CTRL --> ALUP["alu_op [1:0]"]
    CTRL --> MW["mem_write (1-bit)"]
    CTRL --> ASRC["alu_src (1-bit)"]
    CTRL --> RW["reg_write (1-bit)"]
```

#### Control Signals Truth Table
| Instruction Type | `opcode` | `reg_write` | `alu_src` | `alu_op` | `branch` | `mem_read` | `mem_write` | `mem_to_reg` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **R-Type** (`add`, `sub`, etc.) | `0110011` | 1 | 0 | `2'b10` | 0 | 0 | 0 | 0 |
| **I-Type ALU** (`addi`, etc.) | `0010011` | 1 | 1 | `2'b11` | 0 | 0 | 0 | 0 |
| **Load** (`lw`) | `0000011` | 1 | 1 | `2'b00` | 0 | 1 | 0 | 1 |
| **Store** (`sw`) | `0100011` | 0 | 1 | `2'b00` | 0 | 0 | 1 | X |
| **Branch** (`beq`) | `1100011` | 0 | 0 | `2'b01` | 1 | 0 | 0 | X |

#### Key Logic Separation
- `alu_op = 2'b10` is reserved specifically for **R-type** instructions where `funct7[5]` distinguishes `ADD` from `SUB`.
- `alu_op = 2'b11` is dedicated to **I-type arithmetic** instructions (`ADDI`, etc.) where subtraction does not exist, ensuring negative immediate values never accidentally trigger a `SUB`.

---

### Module 5: Immediate Generator (`immediate_gen.v`)

#### Interface Diagram
```mermaid
graph LR
    INSTR["instr [31:0]"] --> IMM["immediate_gen.v<br/>(Sign Extender)"]
    IMM --> IMMOUT["imm_out [31:0]"]
```

#### Immediate Formats Supported
```
I-Type:  [31 ---------------- 20] -> Sign-extended to 32 bits
S-Type:  [31 --- 25] [11 -- 7]   -> Sign-extended to 32 bits
B-Type:  [31] [7] [30:25] [11:8] '0' -> Sign-extended branch offset
U-Type:  [31 ---------------- 12] 12'b0 -> Upper 20 bits
J-Type:  [31] [19:12] [20] [30:21] '0' -> Sign-extended jump offset
```

#### Bit Reconstruction Formulas
| Format | Opcode | Immediate Extraction Formula |
| :--- | :--- | :--- |
| **I-Type** | `0010011`, `0000011`, `1100111` | `{{20{instr[31]}}, instr[31:20]}` |
| **S-Type** | `0100011` | `{{20{instr[31]}}, instr[31:25], instr[11:7]}` |
| **B-Type** | `1100011` | `{{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}` |
| **U-Type** | `0110111`, `0010111` | `{instr[31:12], 12'b0}` |
| **J-Type** | `1101111` | `{{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}` |

---

### Module 6: Register File (`regfile.v`)

#### Interface Diagram
```mermaid
graph LR
    CLK["clk"] --> RF["regfile.v<br/>(32 x 32-bit Registers)"]
    RST["rst_n"] --> RF
    WE["we (reg_write)"] --> RF
    RS1A["rs1_addr [4:0]"] --> RF
    RS2A["rs2_addr [4:0]"] --> RF
    RDA["rd_addr [4:0]"] --> RF
    RDD["rd_data [31:0]"] --> RF
    RF --> RS1D["rs1_data [31:0]"]
    RF --> RS2D["rs2_data [31:0]"]
```

#### Port Definitions
| Port | Direction | Width | Connected To | Description |
| :--- | :---: | :---: | :--- | :--- |
| `clk` | Input | 1 | Global Clock | Synchronous write trigger. |
| `rst_n` | Input | 1 | Global Reset | Active-low reset (clears registers to 0). |
| `we` | Input | 1 | `control_unit.reg_write` | Write enable signal. |
| `rs1_addr` | Input | 5 | `decoder.rs1` | Read address port 1 ($x0 - x31$). |
| `rs2_addr` | Input | 5 | `decoder.rs2` | Read address port 2 ($x0 - x31$). |
| `rd_addr` | Input | 5 | `decoder.rd` | Write address port ($x0 - x31$). |
| `rd_data` | Input | 32 | Datapath Writeback | Data to commit into `rd_addr`. |
| `rs1_data` | Output | 32 | `alu.a` | Asynchronous read data for `rs1`. |
| `rs2_data` | Output | 32 | `alu_src` Mux | Asynchronous read data for `rs2`. |

#### Essential Architecture Rules
1. **$x0$ Hardwired Zero**:
   - `assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : rf[rs1_addr];`
   - `assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : rf[rs2_addr];`
   - Writes to $x0$ are explicitly suppressed: `if (we && (rd_addr != 5'd0))`.
2. **Dual Asynchronous Read**: Reads occur combinationally during the decode cycle without waiting for a clock edge.
3. **Synchronous Write**: Register writes commit on `posedge clk`.

---

### Module 7: ALU Control Unit (`alu_control.v`)

#### Interface Diagram
```mermaid
graph LR
    ALUOP["alu_op [1:0]"] --> ALUC["alu_control.v<br/>(ALU Decoder)"]
    F3["funct3 [2:0]"] --> ALUC
    F75["funct7_5 (instr[30])"] --> ALUC
    ALUC --> ALUC_OUT["alu_control [3:0]"]
```

#### Operation Truth Table
| `alu_op` | Instruction Class | `funct3` | `funct7[5]` | Output `alu_control` | Operation |
| :---: | :--- | :---: | :---: | :---: | :--- |
| `2'b00` | Loads & Stores | `XXX` | `X` | `4'b0000` | ADD |
| `2'b01` | Branches (`beq`) | `XXX` | `X` | `4'b0001` | SUB |
| `2'b10` | R-Type (`add`/`sub`) | `3'b000` | `1'b0` | `4'b0000` | ADD |
| `2'b10` | R-Type (`sub`) | `3'b000` | `1'b1` | `4'b0001` | SUB |
| `2'b10` | R-Type (`or`) | `3'b110` | `X` | `4'b0011` | OR |
| `2'b10` | R-Type (`and`) | `3'b111` | `X` | `4'b0010` | AND |
| `2'b10` | R-Type (`xor`) | `3'b100` | `X` | `4'b0100` | XOR |
| `2'b10` | R-Type (`slt`) | `3'b010` | `X` | `4'b0101` | SLT |
| `2'b11` | I-Type (`addi`) | `3'b000` | `X` | `4'b0000` | ADD |
| `2'b11` | I-Type (`ori`) | `3'b110` | `X` | `4'b0011` | OR |
| `2'b11` | I-Type (`andi`) | `3'b111` | `X` | `4'b0010` | AND |
| `2'b11` | I-Type (`xori`) | `3'b100` | `X` | `4'b0100` | XOR |
| `2'b11` | I-Type (`slti`) | `3'b010` | `X` | `4'b0101` | SLT |

---

### Module 8: Arithmetic Logic Unit (`alu.v`)

#### Interface Diagram
```mermaid
graph LR
    A["a [31:0] (from rs1_data)"] --> ALU["alu.v<br/>(Arithmetic Logic Unit)"]
    B["b [31:0] (rs2_data or imm_out)"] --> ALU
    ALUC["alu_control [3:0]"] --> ALU
    ALU --> RES["result [31:0]"]
    ALU --> ZERO["zero (1-bit flag)"]
```

#### Operation Encoding
| `alu_control` | Constant | Operation | Verilog Implementation |
| :---: | :--- | :--- | :--- |
| `4'b0000` | `ALU_ADD` | Addition | `result = a + b;` |
| `4'b0001` | `ALU_SUB` | Subtraction | `result = a - b;` |
| `4'b0010` | `ALU_AND` | Bitwise AND | `result = a & b;` |
| `4'b0011` | `ALU_OR` | Bitwise OR | `result = a \| b;` |
| `4'b0100` | `ALU_XOR` | Bitwise XOR | `result = a ^ b;` |
| `4'b0101` | `ALU_SLT` | Set Less Than (signed) | `result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;` |

#### Zero Flag Generation
```verilog
assign zero = (result == 32'h00000000);
```
Used in conditional branching: if `a == b` during a branch instruction (`SUB`), `result == 0`, asserting `zero = 1`. Combined with `branch == 1`, this enables the branch target mux.

---

### Module 9: Top-Level Integration (`cpu.v`)

#### Interface Diagram
```mermaid
graph LR
    CLK["clk (System Clock)"] --> CPU["cpu.v<br/>(Top-Level Core)"]
    RST["rst_n (System Reset)"] --> CPU
```

#### Datapath Muxes
1. **ALU Operand B Mux**:
   - `assign alu_b_operand = alu_src ? imm_out : rs2_data;`
   - Selects immediate value for I-type/Loads/Stores, or register value for R-type/Branches.
2. **Next PC Mux**:
   - `assign pc_next = (branch & zero) ? pc_branch_target : pc_plus_4;`
   - Selects `PC + 4` sequentially or jumps to `PC + imm_out` on taken branch.
3. **Writeback Data**:
   - `assign writeback_data = alu_result;` (connects ALU computation to `regfile.rd_data`).

---

## 4. End-to-End Single-Cycle Execution Trace

The preloaded test program in `instruction_memory.v` executes as follows across 7 clock cycles:

```mermaid
sequenceDiagram
    autonumber
    actor Clock as posedge clk
    participant PC as Program Counter
    participant IMEM as Instruction ROM
    participant DEC as Decoder & Control
    participant RF as Register File
    participant ALU as ALU & Muxes

    Note over PC, ALU: Cycle 1: PC=0x00, addi x1, x0, 20
    Clock->>PC: PC updates to 0x00
    PC->>IMEM: Fetch 0x01400093
    IMEM->>DEC: Decode opcode=0010011, rd=1, imm=20
    DEC->>RF: rs1=0 (value=0)
    DEC->>ALU: alu_src=1 (selects imm 20), ALU_ADD
    ALU->>RF: Writeback 20 into x1 on next clock edge

    Note over PC, ALU: Cycle 2: PC=0x04, addi x2, x0, 22
    Clock->>PC: PC updates to 0x04
    PC->>IMEM: Fetch 0x01600113
    IMEM->>DEC: Decode opcode=0010011, rd=2, imm=22
    ALU->>RF: Writeback 22 into x2 on next clock edge

    Note over PC, ALU: Cycle 3: PC=0x08, add x3, x1, x2 (20 + 22)
    Clock->>PC: PC updates to 0x08
    PC->>IMEM: Fetch 0x002081b3
    IMEM->>DEC: Decode R-type, rs1=1, rs2=2, rd=3
    DEC->>RF: Read x1(20) and x2(22)
    RF->>ALU: ALU calculates 20 + 22 = 42
    ALU->>RF: Writeback 42 into x3 on next clock edge

    Note over PC, ALU: Cycle 4: PC=0x0C, sub x4, x3, x1 (42 - 20)
    Clock->>PC: PC updates to 0x0C
    PC->>IMEM: Fetch 0x40118233 (funct7[5]=1 -> SUB)
    DEC->>RF: Read x3(42) and x1(20)
    RF->>ALU: ALU calculates 42 - 20 = 22
    ALU->>RF: Writeback 22 into x4 on next clock edge

    Note over PC, ALU: Cycle 5: PC=0x10, and x5, x1, x2 (20 & 22)
    Clock->>PC: PC updates to 0x10
    ALU->>RF: Writeback 20 into x5 on next clock edge

    Note over PC, ALU: Cycle 6: PC=0x14, or x6, x1, x2 (20 | 22)
    Clock->>PC: PC updates to 0x14
    ALU->>RF: Writeback 22 into x6 on next clock edge

    Note over PC, ALU: Cycle 7: PC=0x18, xor x7, x1, x2 (20 ^ 22)
    Clock->>PC: PC updates to 0x18
    ALU->>RF: Writeback 2 into x7 on next clock edge
```

---

## 5. Verification Commands & Waveforms

You can re-run any simulation directly from PowerShell:

```powershell
# 1. Ensure PATH has the Icarus Verilog binary
$env:Path = "E:\iverilog\app\bin;E:\iverilog\app\gtkwave\bin;" + $env:Path

# 2. Run ALU standalone testbench
iverilog -o alu_sim.vvp E:\verilogCBP\rtl\alu.v E:\verilogCBP\testbenches\alu_milestone1tb.v
vvp alu_sim.vvp

# 3. Run Register File + ALU integration testbench
iverilog -o ms2_sim.vvp E:\verilogCBP\rtl\alu.v E:\verilogCBP\rtl\regfile.v E:\verilogCBP\testbenches\tb_milestone2.v
vvp ms2_sim.vvp

# 4. Run Full Single-Cycle CPU testbench
iverilog -o sim_cpu.vvp (Get-ChildItem E:\verilogCBP\rtl\*.v).FullName E:\verilogCBP\testbenches\tb_cpu.v
vvp sim_cpu.vvp

# 5. Open waveform in GTKWave
gtkwave cpu_trace.vcd
```
