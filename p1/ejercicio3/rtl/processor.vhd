--------------------------------------------------------------------------------
-- Procesador MIPS con pipeline curso Arquitectura 2021-2022
--
-- Luis Miguel Nucifora Izquierdo & Bernardo Andrés Zambrano Ferreira
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
      OpA      : in std_logic_vector (31 downto 0);
      OpB      : in std_logic_vector (31 downto 0);
      Control  : in std_logic_vector (3 downto 0);
      Result   : out std_logic_vector (31 downto 0);
      Signflag : out std_logic;
      Zflag    : out std_logic
    );
  end component;

  component reg_bank
     port (
        Clk   : in std_logic; -- Reloj activo en flanco de subida
        Reset : in std_logic; -- Reset asincrono a nivel alto
        A1    : in std_logic_vector(4 downto 0);   -- Direccion para el puerto Rd1
        Rd1   : out std_logic_vector(31 downto 0); -- Dato del puerto Rd1
        A2    : in std_logic_vector(4 downto 0);   -- Direccion para el puerto Rd2
        Rd2   : out std_logic_vector(31 downto 0); -- Dato del puerto Rd2
        A3    : in std_logic_vector(4 downto 0);   -- Direccion para el puerto Wd3
        Wd3   : in std_logic_vector(31 downto 0);  -- Dato de entrada Wd3
        We3   : in std_logic -- Habilitacion de la escritura de Wd3
     );
  end component reg_bank;

  component control_unit
     port (
        -- Entrada = codigo de operacion en la instruccion:
        OpCode   : in  std_logic_vector (5 downto 0);
        -- Seniales para el PC
	Jump     : out 	std_logic; -- 1 = Ejecutandose instruccion jump
        Branch   : out  std_logic; -- 1 = Ejecutandose instruccion branch
        -- Seniales relativas a la memoria
        MemToReg : out  std_logic; -- 1 = Escribir en registro la salida de la mem.
        MemWrite : out  std_logic; -- Escribir la memoria
        MemRead  : out  std_logic; -- Leer la memoria
        -- Seniales para la ALU
        ALUSrc   : out  std_logic;                     -- 0 = oper.B es registro, 1 = es valor inm.
        ALUOp    : out  std_logic_vector (2 downto 0); -- Tipo operacion para control de la ALU
        -- Seniales para el GPR
        RegWrite : out  std_logic; -- 1 = Escribir registro
        RegDst   : out  std_logic  -- 0 = Reg. destino es rt, 1=rd
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

  -- ALU relted signals
  signal Alu_Op2EX                    		 : std_logic_vector(31 downto 0);
  signal ALU_IgualEX, Alu_IgualEXMEM  		 : std_logic;
  signal AluControlEX                 		 : std_logic_vector(3 downto 0);
  signal Alu_ResEX, Alu_ResEXMEM, Alu_ResMEMWB   : std_logic_vector(31 downto 0);

  -- Register related signals
  
  signal reg_RDEX, reg_RDEXMEM, reg_RDMEMWB        : std_logic_vector(4 downto 0);
  signal reg_RD_dataWB                 		   : std_logic_vector(31 downto 0);
  signal reg_RSID, reg_RSIDEX                      : std_logic_vector(31 downto 0);
  signal reg_RTID, reg_RTIDEX, reg_RTEXMEM         : std_logic_vector(31 downto 0);

  -- PC related signals
  signal Regs_eq_branch   : std_logic;
  signal PC_nextIF        : std_logic_vector(31 downto 0);
  signal PC_regIF         : std_logic_vector(31 downto 0);
  signal PC_plus4IF       : std_logic_vector(31 downto 0);

  signal PC_plus4IFID   :std_logic_vector(31 downto 0);
  signal PC_plus4IDEX   :std_logic_vector(31 downto 0);

  -- Instrucction related signals 
  signal InstructionIF, InstructionIFID, InstructionIDEX    : std_logic_vector(31 downto 0); -- La instrucción desde lamem de instr
  signal InstructionIDEX_Inm                                : std_logic_vector(25 downto 0);
  signal InstructionIDEX_RD, InstructionIDEX_RT             : std_logic_vector(4 downto 0);
  signal Inm_extID, Inm_extIDEX                             : std_logic_vector(31 downto 0); -- La parte baja de la instrucción extendida de signo
  

  signal dataIn_MemMEM, dataIn_MemMEMWB : std_logic_vector(31 downto 0); --From Data Memory
  signal Addr_Branch                    : std_logic_vector(31 downto 0);

  -- Control related signals
  signal Ctrl_JumpID, Ctrl_JumpIDEX, Ctrl_JumpEXMEM              :std_logic;
  signal Ctrl_BranchID, Ctrl_BranchIDEX, Ctrl_BranchEXMEM        :std_logic;
  signal Ctrl_MemWriteID, Ctrl_MemWriteIDEX, Ctrl_MemWriteEXMEM  :std_logic;
  signal Ctrl_MemReadID, Ctrl_MemReadIDEX, Ctrl_MemReadEXMEM     :std_logic;
  signal Ctrl_ALUSrcID, Ctrl_AluSrcIDEX                          :std_logic;
  signal Ctrl_RegDestID, Ctrl_RegDestIDEX                        :std_logic;

  signal Ctrl_MemToRegID, Ctrl_MemToRegIDEX, Ctrl_MemToRegEXMEM, Ctrl_MemToRegMEMWB   :std_logic;
  signal Ctrl_RegWriteID, Ctrl_RegWriteIDEX, Ctrl_RegWriteEXMEM, Ctrl_RegWriteMEMWB   :std_logic;

  signal Ctrl_ALUOPID, Ctrl_ALUOPIDEX : std_logic_vector(2 downto 0);

  -- Jump related signals
  signal Addr_JumpEX, Addr_JumpEXMEM  : std_logic_vector(31 downto 0);
  signal Addr_Jump_destMEM            : std_logic_vector(31 downto 0);
  signal desition_JumpMEM             : std_logic;

  signal Addr_BranchEX, Addr_BranchEXMEM  : std_logic_vector(31 downto 0);
  

begin

  PC_nextIF <= Addr_Jump_destMEM when desition_JumpMEM = '1' else PC_plus4IF;
  
  ---------------------------------------------------
  -- PC REGISTER PROCESS
  ---------------------------------------------------
  PC_reg_proc: process(Clk, Reset)
  begin
    if Reset = '1' then
      PC_regIF <= (others => '0');
    elsif rising_edge(Clk) then
      PC_regIF <= PC_nextIF;
    end if;
  end process;

  PC_plus4IF <= PC_regIF + 4;
  IAddr       <= PC_regIF;
  InstructionIF <= IDataIn;

  ---------------------------------------------------
  -- IFID PROCESS
  ---------------------------------------------------
  IFID_process: process(Clk, Reset)
  begin
    if Reset = '1' then
      PC_plus4IFID <= (others => '0');
      InstructionIFID <= (others => '0');
    elsif rising_edge(Clk) then
      PC_plus4IFID <= InstructionIF;
    end if;
  end process;

  ---------------------------------------------------
  -- IDEX PROCESS
  ---------------------------------------------------
  IDEX_process: process(Clk, Reset)
  begin
    if Reset = '1' then
      Ctrl_AluSrcIDEX     <= '0';
      Ctrl_BranchIDEX     <= '0';
      Ctrl_JumpIDEX       <= '0';
      Ctrl_MemReadIDEX    <= '0';
      Ctrl_MemToRegIDEX   <= '0';
      Ctrl_MemWriteIDEX   <= '0';
      Ctrl_RegDestIDEX    <= '0';
      Ctrl_RegWriteIDEX   <= '0';
      Ctrl_ALUOPIDEX      <= (others => '0');
      Inm_extIDEX         <= (others => '0');
      InstructionIDEX_Inm <= (others => '0');
      InstructionIDEX_RD  <= (others => '0');
      InstructionIDEX_RT  <= (others => '0');
      PC_plus4IDEX        <= (others => '0');
      reg_RSIDEX          <= (others => '0');
      reg_RTIDEX          <= (others => '0');
    elsif rising_edge(Clk) then
      Ctrl_AluSrcIDEX     <= Ctrl_AluSrcID;
      Ctrl_BranchIDEX     <= Ctrl_BranchID;
      Ctrl_JumpIDEX       <= Ctrl_JumpID;
      Ctrl_MemReadIDEX    <= Ctrl_MemReadID;
      Ctrl_MemToRegIDEX   <= Ctrl_MemToRegID;
      Ctrl_MemWriteIDEX   <= Ctrl_MemWriteID;
      Ctrl_RegDestIDEX    <= Ctrl_RegDestID;
      Ctrl_RegWriteIDEX   <= Ctrl_RegWriteID;
      Ctrl_ALUOPIDEX      <= Ctrl_ALUOPID;
      Inm_extIDEX         <= Inm_extID;
      InstructionIDEX_Inm <= InstructionIFID (25 downto 0);
      InstructionIDEX_RD  <= InstructionIFID (15 downto 11);
      InstructionIDEX_RT  <= InstructionIFID (20 downto 16);
      PC_plus4IDEX        <= PC_plus4IFID;
      reg_RSIDEX          <= reg_RSID;
      reg_RTIDEX          <= reg_RTID;
    end if;
  end process;

  ---------------------------------------------------
  -- EXMEM PROCESS
  ---------------------------------------------------
  EXMEM_process: process(Clk, Reset)
  begin
    if Reset = '1' then
      Alu_IgualEXMEM      <= '0';
      Ctrl_BranchEXMEM    <= '0';
      Ctrl_JumpEXMEM      <= '0';
      Ctrl_MemReadEXMEM   <= '0';
      Ctrl_MemToRegEXMEM  <= '0';
      Ctrl_MemWriteEXMEM  <= '0';
      Ctrl_RegWriteEXMEM  <= '0';
      Addr_BranchEXMEM    <= (others => '0');
      Addr_JumpEXMEM      <= (others => '0');
      Alu_ResEXMEM        <= (others => '0');
      reg_RDEXMEM         <= (others => '0');
      reg_RTEXMEM         <= (others => '0');
    elsif rising_edge(Clk) then
      Alu_IgualEXMEM      <= Alu_IgualEX;
      Ctrl_BranchEXMEM    <= Ctrl_BranchIDEX;
      Ctrl_JumpEXMEM      <= Ctrl_JumpIDEX;
      Ctrl_MemReadEXMEM   <= Ctrl_MemReadIDEX;
      Ctrl_MemToRegEXMEM  <= Ctrl_MemToRegIDEX;
      Ctrl_MemWriteEXMEM  <= Ctrl_MemWriteIDEX;
      Ctrl_RegWriteEXMEM  <= Ctrl_RegWriteIDEX;
      Addr_BranchEXMEM    <= Addr_BranchEX;
      Addr_JumpEXMEM      <= Addr_JumpEX;
      Alu_ResEXMEM        <= Alu_ResEX;
      reg_RDEXMEM         <= reg_RDEX;
      reg_RTEXMEM         <= reg_RTIDEX;
    end if;
  end process;

  ---------------------------------------------------
  -- MEMWB PROCESS
  ---------------------------------------------------
  MEMWB_process: process(Clk, Reset)
  begin
    if Reset = '1' then
      Ctrl_MemToRegMEMWB  <= '0';
      Ctrl_RegWriteMEMWB  <= '0';
      Alu_ResMEMWB        <= (others => '0');
      dataIn_MemMEMWB     <= (others => '0');
      reg_RDMEMWB         <= (others => '0');
    elsif rising_edge(Clk) then
      Ctrl_MemToRegMEMWB  <= Ctrl_MemToRegEXMEM;
      Ctrl_RegWriteMEMWB  <= Ctrl_RegWriteEXMEM;
      Alu_ResMEMWB        <= Alu_ResEXMEM;
      dataIn_MemMEMWB     <= dataIn_MemMEM;
      reg_RDMEMWB         <= reg_RDEXMEM;
    end if;
  end process;

      
  ---------------------------------------------------
  -- PORT MAPS
  ---------------------------------------------------
  RegsMIPS : reg_bank
  port map (
    Clk   => Clk,
    Reset => Reset,
    A1    => InstructionIFID(25 downto 21),
    Rd1   => reg_RSID,
    A2    => InstructionIFID(20 downto 16),
    Rd2   => reg_RTID,
    A3    => reg_RDMEMWB,
    Wd3   => reg_RD_dataWB,
    We3   => Ctrl_RegWriteMEMWB
  );
  
  -- La unidad de control se encuentra en la etapa ID
  UnidadControl : control_unit
  port map(
    OpCode   => InstructionIFID(31 downto 26),
    -- Señales para el PC
    Jump   => Ctrl_JumpID,
    Branch   => Ctrl_BranchID,
    -- Señales para la memoria
    MemToReg => Ctrl_MemToRegID,
    MemWrite => Ctrl_MemWriteID,
    MemRead  => Ctrl_MemReadID,
    -- Señales para la ALU
    ALUSrc   => Ctrl_ALUSrcID,
    ALUOP    => Ctrl_ALUOPID,
    -- Señales para el GPR
    RegWrite => Ctrl_RegWriteID,
    RegDst   => Ctrl_RegDestID
  );

  Alu_control_i: alu_control
  port map(
    -- Entradas:
    ALUOp  => Ctrl_ALUOPIDEX, -- Codigo de control desde la unidad de control
    Funct  => Inm_extIDEX (5 downto 0), -- Campo "funct" de la instruccion
    -- Salida de control para la ALU:
    ALUControl => AluControlEX -- Define operacion a ejecutar por la ALU
  );

  Alu_MIPS : alu
  port map (
    OpA      => reg_RSIDEX,
    OpB      => Alu_Op2EX,
    Control  => AluControlEX,
    Result   => Alu_ResEX,
    Signflag => open,
    Zflag    => Alu_IgualEX
  );

  -- Operacion del Sign extend
  Inm_extID        <= x"FFFF" & InstructionIFID(15 downto 0) when InstructionIFID(15)='1' else
                    x"0000" & InstructionIFID(15 downto 0);

  -- Operaciones de Jump y Branch
  Addr_JumpEX       <= PC_plus4IDEX(31 downto 28) & InstructionIDEX_Inm(25 downto 0) & "00";
  Addr_BranchEX   <= PC_plus4IDEX + ( Inm_extIDEX(29 downto 0) & "00");

  Regs_eq_branch    <= '1' when (reg_RSIDEX = reg_RTIDEX) else '0'; -- Equivalente a Alu_IgualEXMEM
  desition_JumpMEM  <= Ctrl_JumpEXMEM or (Ctrl_BranchEXMEM and Regs_eq_branch);
  Addr_Jump_destMEM <= Addr_JumpEXMEM   when Ctrl_JumpEXMEM='1' else
                       Addr_BranchEXMEM when Ctrl_BranchEXMEM='1' else
                       (others =>'0');

  Alu_Op2EX    <= reg_RTIDEX when Ctrl_ALUSrcIDEX = '0' else Inm_extIDEX;
  reg_RDEX     <= InstructionIDEX_RT when Ctrl_RegDestIDEX = '0' else InstructionIDEX_RD;

  DAddr      	<= Alu_ResEXMEM;
  DDataOut   	<= reg_RTEXMEM;
  DWrEn      	<= Ctrl_MemWriteEXMEM;
  dRdEn      	<= Ctrl_MemReadEXMEM;
  dataIn_MemMEM <= DDataIn;

  reg_RD_dataWB <= dataIn_MemMEMWB when Ctrl_MemToRegMEMWB = '1' else Alu_ResMEMWB;

end architecture;
