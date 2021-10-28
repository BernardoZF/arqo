--------------------------------------------------------------------------------
-- Procesador MIPS con pipeline curso Arquitectura 2020-2021
--
-- Adrián Sebastián Gil y Javier Mateos Najari
-- 
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity processor is
    port(
      Clk         : in  std_logic; -- Reloj activo en flanco subida
      Reset       : in  std_logic; -- Reset asincrono activo nivel alto
      -- Instruction memory
      IAddr      : out std_logic_vector(31 downto 0); -- Direccion Instr
      IDataIn    : in  std_logic_vector(31 downto 0); -- Instruccion leida
      -- Data memory
      DAddr      : out std_logic_vector(31 downto 0); -- Direccion
      DRdEn      : out std_logic;                     -- Habilitacion lectura
      DWrEn      : out std_logic;                     -- Habilitacion escritura
      DDataOut   : out std_logic_vector(31 downto 0); -- Dato escrito
      DDataIn    : in  std_logic_vector(31 downto 0)  -- Dato leido
    );
end processor;

architecture rtl of processor is

  component alu
    port(
      OpA : in std_logic_vector (31 downto 0);
      OpB : in std_logic_vector (31 downto 0);
      Control : in std_logic_vector (3 downto 0);
      Result : out std_logic_vector (31 downto 0);
      Zflag : out std_logic
    );
  end component;

  component reg_bank
      port (
        Clk   : in std_logic; -- Reloj activo en flanco de subida
        Reset : in std_logic; -- Reset as�ncrono a nivel alto
        A1    : in std_logic_vector(4 downto 0);   -- Direcci�n para el puerto Rd1
        Rd1   : out std_logic_vector(31 downto 0); -- Dato del puerto Rd1
        A2    : in std_logic_vector(4 downto 0);   -- Direcci�n para el puerto Rd2
        Rd2   : out std_logic_vector(31 downto 0); -- Dato del puerto Rd2
        A3    : in std_logic_vector(4 downto 0);   -- Direcci�n para el puerto Wd3
        Wd3   : in std_logic_vector(31 downto 0);  -- Dato de entrada Wd3
        We3   : in std_logic -- Habilitaci�n de la escritura de Wd3
      );
  end component reg_bank;

  component control_unit
      port (
        -- Entrada = codigo de operacion en la instruccion:
        OpCode   : in  std_logic_vector (5 downto 0);
        -- Seniales para el PC
        Branch   : out  std_logic; -- 1 = Ejecutandose instruccion branch
        Jump : out std_logic; -- 1 = Ejecutandose instrucción j
        -- Seniales relativas a la memoria
        MemToReg : out  std_logic; -- 1 = Escribir en registro la salida de la mem.
        MemWrite : out  std_logic; -- Escribir la memoria
        MemRead  : out  std_logic; -- Leer la memoria
        -- Seniales para la ALU
        ALUSrc   : out  std_logic;                     -- 0 = oper.B es registro, 1 = es valor inm.
        ALUOp    : out  std_logic_vector (2 downto 0); -- Tipo operacion para control de la ALU
        -- Seniales para el GPR
        RegWrite : out  std_logic; -- 1=Escribir registro
        RegDst   : out  std_logic  -- 0=Reg. destino es rt, 1=rd
      );
  end component;

  component alu_control is
    port (
      -- Entradas:
      ALUOp  : in std_logic_vector (2 downto 0); -- Codigo de control desde la unidad de control
      Funct  : in std_logic_vector (5 downto 0); -- Campo "funct" de la instruccion
      -- Salida de control para la ALU:
      ALUControl : out std_logic_vector (3 downto 0) -- Define operacion a ejecutar por la ALU
    );
  end component alu_control;

  -- (IF) Instruction Fetch Signals
  signal PC_next_IF, PC_plus4_IF, Pc_reg_IF: std_logic_vector(31 downto 0);
  signal Instruction_IF: std_logic_vector(31 downto 0);
  
  -- (IF/ID) Incoming signals from Instruction Fetch Stage to Instruction Decode Stage
  signal PC_plus4_IFID: std_logic_vector(31 downto 0);
  signal Instruction_IFID: std_logic_vector(31 downto 0);

  -- (ID) Instruction Decode Signals
  signal reg_RS_ID, reg_RT_ID: std_logic_vector(31 downto 0);
  signal Ctrl_Jump_ID, Ctrl_Branch_ID, Ctrl_MemToReg_ID, Ctrl_MemWrite_ID: std_logic;
  signal Ctrl_MemRead_ID, Ctrl_AluSrc_ID: std_logic;
  signal Ctrl_AluOp_ID: std_logic_vector(2 downto 0);
  signal Ctrl_RegWrite_ID, Ctrl_RegDest_ID: std_logic;
  signal Inm_ext_ID: std_logic_vector(31 downto 0);

  -- (ID/EX) Incoming signals from Instruction Decode Stage to Execution Stage
  signal PC_plus4_IDEX: std_logic_vector(31 downto 0);
  signal reg_RS_IDEX, reg_RT_IDEX: std_logic_vector(31 downto 0);
  signal Ctrl_Jump_IDEX, Ctrl_Branch_IDEX, Ctrl_MemToReg_IDEX, Ctrl_MemWrite_IDEX: std_logic;
  signal Ctrl_MemRead_IDEX, Ctrl_AluSrc_IDEX: std_logic;
  signal Ctrl_AluOp_IDEX: std_logic_vector(2 downto 0);
  signal Ctrl_RegWrite_IDEX, Ctrl_RegDest_IDEX: std_logic;
  signal Inm_ext_IDEX: std_logic_vector(31 downto 0);
  signal Instruction_IDEX_RT, Instruction_IDEX_RD: std_logic_vector(4 downto 0);
  signal Instruction_IDEX_Inm: std_logic_vector(25 downto 0);

  -- (EX) Execution Signals
  signal AluControl_EX: std_logic_vector(3 downto 0);
  signal Alu_Op2_EX: std_logic_vector(31 downto 0);
  signal Alu_Res_EX: std_logic_vector(31 downto 0);
  signal Alu_Igual_EX: std_logic;
  signal reg_RD_EX: std_logic_vector(4 downto 0);
  signal Addr_Branch_EX, Addr_Jump_EX: std_logic_vector(31 downto 0);

  -- (EX/MEM) Incoming signals from Execution Stage to Memory Write Stage 
  signal Ctrl_RegWrite_EXMEM, Ctrl_MemToReg_EXMEM: std_logic;
  signal Ctrl_Branch_EXMEM, Ctrl_Jump_EXMEM, Ctrl_MemWrite_EXMEM, Ctrl_MemRead_EXMEM: std_logic;
  signal Addr_Branch_EXMEM, Addr_Jump_EXMEM: std_logic_vector(31 downto 0);
  signal Alu_Igual_EXMEM: std_logic;
  signal Alu_Res_EXMEM: std_logic_vector(31 downto 0);
  signal reg_RT_EXMEM: std_logic_vector(31 downto 0);
  signal reg_RD_EXMEM: std_logic_vector(4 downto 0);
  
  -- (MEM) Memory Write Signals
  signal desition_Jump_MEM: std_logic;
  signal Addr_Jump_dest_MEM: std_logic_vector(31 downto 0);
  signal dataIn_Mem_MEM: std_logic_vector(31 downto 0);

  -- (MEM/WB) Incoming signals from Memory Write Stage to Write Back Stage
  signal reg_RD_MEMWB: std_logic_vector(4 downto 0);
  signal Ctrl_RegWrite_MEMWB, Ctrl_MemToReg_MEMWB: std_logic;
  signal dataIn_Mem_MEMWB: std_logic_vector(31 downto 0);
  signal Alu_Res_MEMWB: std_logic_vector(31 downto 0);

  -- (WB) Write Back Signals
  signal reg_RD_data_WB: std_logic_vector(31 downto 0);

begin
  
  ------------------------------------------------------------------------------ 
  -- Instrucction Fetch Stage
  ------------------------------------------------------------------------------
  PC_next_IF <= Addr_Jump_dest_MEM when desition_Jump_MEM = '1' else PC_plus4_IF;
  PC_plus4_IF    <= PC_reg_IF + 4;
  Instruction_IF <= IDataIn;

  PC_reg_proc: process(Clk, Reset)
  begin
    if Reset = '1' then
      PC_reg_IF <= (others => '0');
    elsif rising_edge(Clk) then
      PC_reg_IF <= PC_next_IF;
    end if;
  end process;

  IAddr <= PC_reg_IF;

  ------------------------------------------------------------------------------ 
  -- IF/ID
  ------------------------------------------------------------------------------
  IFID_proc: process(Clk, Reset)
  begin
    if Reset = '1' then
      PC_plus4_IFID <= (others => '0');
      Instruction_IFID <= (others => '0');
    elsif rising_edge(Clk) then
      PC_plus4_IFID <= PC_plus4_IF;
      Instruction_IFID <= Instruction_IF;
    end if;
  end process;
  
  ------------------------------------------------------------------------------ 
  -- Instruction Decode / Register file read
  ------------------------------------------------------------------------------
  RegsMIPS : reg_bank
  port map (
    Clk   => Clk,
    Reset => Reset,
    A1    => Instruction_IFID(25 downto 21),
    Rd1   => reg_RS_ID,
    A2    => Instruction_IFID(20 downto 16),
    Rd2   => reg_RT_ID,
    A3    => reg_RD_MEMWB,
    Wd3   => reg_RD_data_WB,
    We3   => Ctrl_RegWrite_MEMWB
  );

  UnidadControl : control_unit
  port map(
    OpCode   => Instruction_IFID(31 downto 26),
    -- Señales para el PC
    Jump   => Ctrl_Jump_ID,
    Branch   => Ctrl_Branch_ID,
    -- Señales para la memoria
    MemToReg => Ctrl_MemToReg_ID,
    MemWrite => Ctrl_MemWrite_ID,
    MemRead  => Ctrl_MemRead_ID,
    -- Señales para la ALU
    ALUSrc   => Ctrl_AluSrc_ID,
    ALUOP    => Ctrl_AluOp_ID,
    -- Señales para el GPR
    RegWrite => Ctrl_RegWrite_ID,
    RegDst   => Ctrl_RegDest_ID
  );

  -- Sign extend
  Inm_ext_ID <= x"FFFF" & Instruction_IFID(15 downto 0) when Instruction_IFID(15)='1' else
                x"0000" & Instruction_IFID(15 downto 0);

  ------------------------------------------------------------------------------ 
  -- ID/EX
  ------------------------------------------------------------------------------
  IDEX_proc: process(Clk, Reset)
  begin
    if Reset = '1' then
      Ctrl_Jump_IDEX <= '0';
      Ctrl_Branch_IDEX <= '0';
      Ctrl_MemWrite_IDEX <= '0';
      Ctrl_MemRead_IDEX <= '0';
      Ctrl_AluSrc_IDEX <= '0';
      Ctrl_RegDest_IDEX <= '0';
      Ctrl_MemToReg_IDEX <= '0';
      Ctrl_RegWrite_IDEX <= '0';
      Ctrl_AluOp_IDEX <= (others => '0');
      reg_RS_IDEX <= (others => '0');
      reg_RT_IDEX <= (others => '0');
      Inm_ext_IDEX <= (others => '0');
      PC_plus4_IDEX <= (others => '0');
      Instruction_IDEX_rt <= (others => '0');
      Instruction_IDEX_rd <= (others => '0');
      Instruction_IDEX_Inm <= (others => '0');
    elsif rising_edge(Clk) then 
      Ctrl_Jump_IDEX <= Ctrl_Jump_ID;
      Ctrl_Branch_IDEX <= Ctrl_Branch_ID;
      Ctrl_MemWrite_IDEX <= Ctrl_MemWrite_ID;
      Ctrl_MemRead_IDEX <= Ctrl_MemRead_ID;
      Ctrl_AluSrc_IDEX <= Ctrl_AluSrc_ID;
      Ctrl_RegDest_IDEX <= Ctrl_RegDest_ID;
      Ctrl_MemToReg_IDEX <= Ctrl_MemToReg_ID;
      Ctrl_RegWrite_IDEX <= Ctrl_RegWrite_ID;
      Ctrl_AluOp_IDEX <= Ctrl_AluOp_ID;
      reg_RS_IDEX <= reg_RS_ID;
      reg_RT_IDEX <= reg_RT_ID;
      Inm_ext_IDEX <= Inm_ext_ID;
      PC_plus4_IDEX <= PC_plus4_IFID;
      Instruction_IDEX_RT <= Instruction_IFID(20 downto 16);
      Instruction_IDEX_RD <= Instruction_IFID(15 downto 11);
      Instruction_IDEX_Inm <= Instruction_IFID(25 downto 0);
    end if;
  end process;

  ------------------------------------------------------------------------------ 
  -- Execution Stage
  ------------------------------------------------------------------------------
  Alu_control_i: alu_control
  port map(
    -- Entradas:
    ALUOp  => Ctrl_AluOp_IDEX, -- Codigo de control desde la unidad de control
    Funct  => Inm_ext_IDEX (5 downto 0), -- Campo "funct" de la instruccion
    -- Salida de control para la ALU:
    ALUControl => AluControl_EX -- Define operacion a ejecutar por la ALU
  );

  Alu_MIPS : alu
  port map (
    OpA     => reg_RS_IDEX,
    OpB     => Alu_Op2_EX,
    Control => AluControl_EX,
    Result  => Alu_Res_EX,
    Zflag   => Alu_Igual_EX
  );
  
  Alu_Op2_EX <= reg_RT_IDEX when Ctrl_AluSrc_IDEX = '0' else Inm_ext_IDEX;
  reg_RD_EX <= Instruction_IDEX_RT when Ctrl_RegDest_IDEX = '0' else Instruction_IDEX_RD;
  
  Addr_Branch_EX <= PC_plus4_IDEX + (Inm_ext_IDEX(29 downto 0) & "00");
  Addr_Jump_EX <= PC_plus4_IDEX(31 downto 28) & Instruction_IDEX_Inm & "00";

  ------------------------------------------------------------------------------ 
  -- EX/MEM
  ------------------------------------------------------------------------------
  EXMEM_proc: process(Clk, Reset) begin
     if Reset = '1' then
      Ctrl_RegWrite_EXMEM <= '0';
      Ctrl_MemToReg_EXMEM <= '0';
      Ctrl_Branch_EXMEM <= '0';
      Ctrl_Jump_EXMEM <= '0';
      Ctrl_MemWrite_EXMEM <= '0';
      Ctrl_MemRead_EXMEM <= '0';
      Addr_Branch_EXMEM <= (others => '0'); 
      Addr_Jump_EXMEM <= (others => '0');
      Alu_Igual_EXMEM <= '0';
      Alu_Res_EXMEM <= (others => '0');
      reg_RT_EXMEM <= (others => '0');
      reg_RD_EXMEM <= (others => '0');
    elsif rising_edge(Clk) then
      Ctrl_RegWrite_EXMEM <= Ctrl_RegWrite_IDEX;
      Ctrl_MemToReg_EXMEM <= Ctrl_MemToReg_IDEX; 
      Ctrl_Branch_EXMEM <= Ctrl_Branch_IDEX;
      Ctrl_Jump_EXMEM <= Ctrl_Jump_IDEX;
      Ctrl_MemWrite_EXMEM <= Ctrl_MemWrite_IDEX;
      Ctrl_MemRead_EXMEM <= Ctrl_MemRead_IDEX;
      Addr_Branch_EXMEM <= Addr_Branch_EX;
      Addr_Jump_EXMEM <= Addr_Jump_EX;
      Alu_Igual_EXMEM <= ALU_Igual_EX;
      Alu_Res_EXMEM <= Alu_Res_EX;
      reg_RT_EXMEM <= reg_RT_IDEX;
      reg_RD_EXMEM <= reg_RD_EX;
    end if;
  end process;

  ------------------------------------------------------------------------------ 
  -- Memory Access Stage and PC+4+IMM
  ------------------------------------------------------------------------------
  desition_Jump_MEM  <= Ctrl_Jump_EXMEM or (Ctrl_Branch_EXMEM and Alu_Igual_EXMEM);
  Addr_Jump_dest_MEM <= Addr_Jump_EXMEM   when Ctrl_Jump_EXMEM='1' else 
                        Addr_Branch_EXMEM when Ctrl_Branch_EXMEM='1' else
                        (others =>'0');
  
  DAddr      <= Alu_Res_EXMEM;
  DDataOut   <= reg_RT_EXMEM;
  DWrEn      <= Ctrl_MemWrite_EXMEM;
  dRdEn      <= Ctrl_MemRead_EXMEM;
  dataIn_Mem_MEM <= DDataIn;

  ------------------------------------------------------------------------------ 
  -- MEM/WB
  ------------------------------------------------------------------------------
  MEMWB_proc: process(Clk, Reset)
  begin
    if Reset = '1' then
      reg_RD_MEMWB <= (others => '0');
      Ctrl_RegWrite_MEMWB <= '0';
      Ctrl_MemToReg_MEMWB <= '0';
      dataIn_Mem_MEMWB <= (others => '0');
      Alu_Res_MEMWB <= (others => '0');
    elsif rising_edge(Clk) then
      reg_RD_MEMWB <= reg_RD_EXMEM;
      Ctrl_RegWrite_MEMWB <= Ctrl_RegWrite_EXMEM;
      Ctrl_MemToReg_MEMWB <= Ctrl_MemToReg_EXMEM;
      dataIn_Mem_MEMWB <= dataIn_Mem_MEM;
      Alu_Res_MEMWB <= Alu_Res_EXMEM;
    end if;
  end process;

  ------------------------------------------------------------------------------ 
  -- Write Back Stage
  ------------------------------------------------------------------------------ 
  reg_RD_data_WB <= dataIn_Mem_MEMWB when Ctrl_MemToReg_MEMWB = '1' else Alu_Res_MEMWB;

end architecture;