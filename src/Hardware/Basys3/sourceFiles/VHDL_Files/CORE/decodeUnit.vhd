LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY decodeUnit IS
    PORT (
        instr        : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        isCompressed : OUT STD_LOGIC;
        aluOp        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        branchOp     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        memRead      : OUT STD_LOGIC;
        memWrite     : OUT STD_LOGIC;
        regWrite     : OUT STD_LOGIC;
        aluSrcImm    : OUT STD_LOGIC;
        jump         : OUT STD_LOGIC;
        jumpReg      : OUT STD_LOGIC;
        useImmediate : OUT STD_LOGIC;
        immediate    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rdSel        : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        rs1Sel       : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        rs2Sel       : OUT STD_LOGIC_VECTOR(4 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE rtl OF decodeUnit IS

    SIGNAL opcode : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL funct3 : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL funct7 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL rd     : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL rs1    : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL rs2    : STD_LOGIC_VECTOR(4 DOWNTO 0);

BEGIN

    -- Extract common fields from instruction
    opcode <= instr(6 DOWNTO 0);
    rd     <= instr(11 DOWNTO 7);
    funct3 <= instr(14 DOWNTO 12);
    rs1    <= instr(19 DOWNTO 15);
    rs2    <= instr(24 DOWNTO 20);
    funct7 <= instr(31 DOWNTO 25);

    -- Example logic for isCompressed (simplified)
    isCompressed <= '1' WHEN instr(1 DOWNTO 0) /= "11" ELSE
        '0';

    -- Output register selections
    rdSel  <= rd;
    rs1Sel <= rs1;
    rs2Sel <= rs2;

    -- Control signal defaults (can be overwritten in process)
    aluOp        <= (OTHERS => '0');
    branchOp     <= (OTHERS => '0');
    memRead      <= '0';
    memWrite     <= '0';
    regWrite     <= '0';
    aluSrcImm    <= '0';
    jump         <= '0';
    jumpReg      <= '0';
    useImmediate <= '0';
    immediate    <= (OTHERS => '0');

    -- Decoding process (placeholder)
    -- Add instruction decoding logic here to set control signals based on opcode/funct3/funct7

END ARCHITECTURE;