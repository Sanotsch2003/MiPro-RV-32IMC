LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ALU IS
    PORT (
        clk          : IN STD_LOGIC;
        reset        : IN STD_LOGIC;
        enable       : IN STD_LOGIC;
        rs1          : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        rs2          : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        aluOp        : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- encoded ALU operation
        outputEnable : IN STD_LOGIC;
        result       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        debug        : OUT STD_LOGIC_VECTOR(100 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE Behavioral OF ALU IS

    -- ALU operation encodings
    CONSTANT ALU_ADD  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000"; -- Addition
    CONSTANT ALU_SUB  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0001"; -- Subtraction
    CONSTANT ALU_AND  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010"; -- Bitwise AND
    CONSTANT ALU_OR   : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0011"; -- Bitwise OR
    CONSTANT ALU_XOR  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0100"; -- Bitwise XOR
    CONSTANT ALU_SLL  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0101"; -- Shift left logical
    CONSTANT ALU_SRL  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0110"; -- Shift right logical
    CONSTANT ALU_SRA  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0111"; -- Shift right arithmetic
    CONSTANT ALU_SLT  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1000"; -- Set less than (signed)
    CONSTANT ALU_SLTU : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1001"; -- Set less than (unsigned)

    SIGNAL rs1Signed   : signed(31 DOWNTO 0);
    SIGNAL rs2Signed   : signed(31 DOWNTO 0);
    SIGNAL rs1Unsigned : unsigned(31 DOWNTO 0);
    SIGNAL rs2Unsigned : unsigned(31 DOWNTO 0);
    SIGNAL aluResult   : STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN

    rs1Signed   <= signed(rs1);
    rs2Signed   <= signed(rs2);
    rs1Unsigned <= unsigned(rs1);
    rs2Unsigned <= unsigned(rs2);

    PROCESS (outputEnable, rs1, rs2, rs1Signed, rs2Signed, rs1Unsigned, rs2Unsigned)
    BEGIN
        IF outputEnable = '1' THEN
            CASE aluOp IS
                WHEN ALU_ADD => aluResult <= STD_LOGIC_VECTOR(rs1Signed + rs2Signed);
                WHEN ALU_SUB => aluResult <= STD_LOGIC_VECTOR(rs1Signed - rs2Signed);
                WHEN ALU_AND => aluResult <= rs1 AND rs2;
                WHEN ALU_OR  => aluResult  <= rs1 OR rs2;
                WHEN ALU_XOR => aluResult <= rs1 XOR rs2;
                WHEN ALU_SLL => aluResult <= STD_LOGIC_VECTOR(shift_left(rs1Unsigned, to_integer(unsigned(rs2(4 DOWNTO 0)))));
                WHEN ALU_SRL => aluResult <= STD_LOGIC_VECTOR(shift_right(rs1Unsigned, to_integer(unsigned(rs2(4 DOWNTO 0)))));
                WHEN ALU_SRA => aluResult <= STD_LOGIC_VECTOR(shift_right(rs1Signed, to_integer(unsigned(rs2(4 DOWNTO 0)))));
                WHEN ALU_SLT =>
                    IF rs1Signed < rs2Signed THEN
                        aluResult <= x"00000001";
                    ELSE
                        aluResult <= x"00000000";
                    END IF;
                WHEN ALU_SLTU =>
                    IF rs1Unsigned < rs2Unsigned THEN
                        aluResult <= x"00000001";
                    ELSE
                        aluResult <= x"00000000";
                    END IF;
                WHEN OTHERS => aluResult <= (OTHERS => '0');
            END CASE;
        ELSE
            aluResult <= (OTHERS => '0');
        END IF;
    END PROCESS;

    result <= aluResult;

    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            debug <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF enable = '1' THEN
                debug <= rs1 & rs2 & aluOp & outputEnable & aluResult;
            END IF;
        END IF;
    END PROCESS;

END Behavioral;