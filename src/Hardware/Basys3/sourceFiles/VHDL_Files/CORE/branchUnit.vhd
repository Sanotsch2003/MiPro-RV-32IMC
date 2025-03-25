LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY BranchUnit IS
    PORT (
        clk          : IN STD_LOGIC;
        reset        : IN STD_LOGIC;
        enable       : IN STD_LOGIC;
        rs1          : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        rs2          : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        branchOp     : IN STD_LOGIC_VECTOR(2 DOWNTO 0); -- encoded branch operation
        outputEnable : IN STD_LOGIC;
        branchTaken  : OUT STD_LOGIC;
        debug        : OUT STD_LOGIC_VECTOR(68 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE Behavioral OF BranchUnit IS

    -- Branch operation encodings
    CONSTANT BEQ  : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000"; -- Branch if equal
    CONSTANT BNE  : STD_LOGIC_VECTOR(2 DOWNTO 0) := "001"; -- Branch if not equal
    CONSTANT BLT  : STD_LOGIC_VECTOR(2 DOWNTO 0) := "100"; -- Branch if less than (signed)
    CONSTANT BGE  : STD_LOGIC_VECTOR(2 DOWNTO 0) := "101"; -- Branch if greater or equal (signed)
    CONSTANT BLTU : STD_LOGIC_VECTOR(2 DOWNTO 0) := "110"; -- Branch if less than (unsigned)
    CONSTANT BGEU : STD_LOGIC_VECTOR(2 DOWNTO 0) := "111"; -- Branch if greater or equal (unsigned)

    SIGNAL rs1Signed           : signed(31 DOWNTO 0);
    SIGNAL rs2Signed           : signed(31 DOWNTO 0);
    SIGNAL rs1Unsigned         : unsigned(31 DOWNTO 0);
    SIGNAL rs2Unsigned         : unsigned(31 DOWNTO 0);
    SIGNAL internalBranchTaken : STD_LOGIC;
BEGIN

    rs1Signed   <= signed(rs1);
    rs2Signed   <= signed(rs2);
    rs1Unsigned <= unsigned(rs1);
    rs2Unsigned <= unsigned(rs2);

    PROCESS (outputEnable, rs1, rs2, rs1Signed, rs2Signed, rs1Unsigned, rs2Unsigned)
    BEGIN
        IF outputEnable = '1' THEN
            CASE branchOp IS
                WHEN BEQ =>
                    IF rs1 = rs2 THEN
                        internalBranchTaken <= '1';
                    ELSE
                        internalBranchTaken <= '0';
                    END IF;
                WHEN BNE =>
                    IF rs1 /= rs2 THEN
                        internalBranchTaken <= '1';
                    ELSE
                        internalBranchTaken <= '0';
                    END IF;
                WHEN BLT =>
                    IF rs1Signed < rs2Signed THEN
                        internalBranchTaken <= '1';
                    ELSE
                        internalBranchTaken <= '0';
                    END IF;
                WHEN BGE =>
                    IF rs1Signed >= rs2Signed THEN
                        internalBranchTaken <= '1';
                    ELSE
                        internalBranchTaken <= '0';
                    END IF;
                WHEN BLTU =>
                    IF rs1Unsigned < rs2Unsigned THEN
                        internalBranchTaken <= '1';
                    ELSE
                        internalBranchTaken <= '0';
                    END IF;
                WHEN BGEU =>
                    IF rs1Unsigned >= rs2Unsigned THEN
                        internalBranchTaken <= '1';
                    ELSE
                        internalBranchTaken <= '0';
                    END IF;
                WHEN OTHERS =>
                    internalBranchTaken <= '0';
            END CASE;
        ELSE
            internalBranchTaken <= '0';
        END IF;
    END PROCESS;

    branchTaken <= internalBranchTaken;

    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            debug <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF enable = '1' THEN
                debug <= rs1 & rs2 & branchOp & outputEnable & internalBranchTaken;
            END IF;
        END IF;
    END PROCESS;

END Behavioral;