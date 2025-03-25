LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY registerFile IS
    PORT (
        enable     : IN STD_LOGIC;
        reset      : IN STD_LOGIC;
        clk        : IN STD_LOGIC;
        alteredClk : IN STD_LOGIC;

        dataIn          : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        loadRegisterSel : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
        dataOut         : OUT STD_LOGIC_VECTOR(32 * 32 - 1 DOWNTO 0);
        debug           : OUT STD_LOGIC_VECTOR(31 * 32 - 1 DOWNTO 0)
    );
END registerFile;

ARCHITECTURE Behavioral OF registerFile IS
    TYPE register_array IS ARRAY (0 TO 30) OF STD_LOGIC_VECTOR(32 - 1 DOWNTO 0); -- 31 registers, register x0 always returns 0 and does not need to be implemented.
    SIGNAL registers  : register_array := (OTHERS => (OTHERS => '0'));
    SIGNAL dataOutTmp : STD_LOGIC_VECTOR(32 * 32 - 1 DOWNTO 0);
BEGIN

    -- Concatenating the registers to dataOut
    PROCESS (registers)
    BEGIN
        dataOutTmp(31 DOWNTO 0) <= (OTHERS => '0'); -- Register x0 is always 0.
        FOR i IN 1 TO 31 LOOP
            dataOutTmp((i + 1) * 31 - 1 DOWNTO i * 32) <= registers(i - 1);
        END LOOP;
    END PROCESS;

    dataOut <= dataOutTmp;

    -- Sequential logic for the registers (loading and resetting).
    PROCESS (clk, reset)
        VARIABLE var_loadRegisterSel : INTEGER;
    BEGIN
        IF reset = '1' THEN
            FOR i IN 0 TO 30 LOOP
                registers(i) <= (OTHERS => '0');
            END LOOP;
            debug <= (others => '0');
        ELSIF rising_edge(clk) THEN
            IF enable = '1' THEN
                debug <= dataOutTmp(32 * 32 - 1 DOWNTO 32);
                IF alteredClk = '1' THEN
                    var_loadRegisterSel := to_integer(unsigned(loadRegisterSel));
                    IF var_loadRegisterSel /= 0 THEN -- Cannot write to register x0.
                        registers(var_loadRegisterSel - 1) <= dataIn;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

END Behavioral;