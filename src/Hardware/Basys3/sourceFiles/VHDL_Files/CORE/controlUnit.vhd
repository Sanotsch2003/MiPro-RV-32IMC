-- The control unit contains the state machine which will manage pipelined instruction fetching, decoding, and executing.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ControlUnit IS
    PORT (
        clk         : IN STD_LOGIC;
        enable      : IN STD_LOGIC;
        alteredClk  : IN STD_LOGIC;
        reset       : IN STD_LOGIC;
        instr       : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        branchTaken : IN STD_LOGIC;

        -- Control outputs
        pcWrite      : OUT STD_LOGIC;
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
        rs2Sel       : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        isCompressed : OUT STD_LOGIC;

        -- pipeline control
        pipelineAdvance : OUT STD_LOGIC
    );
END ENTITY;

ARCHITECTURE rtl OF ControlUnit IS

    TYPE StateType IS (Fetch, Decode, Execute, MemAccess, WriteBack);
    SIGNAL state : StateType := Fetch;

    -- Internal decode signals
    SIGNAL aluOp        : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL branchOp     : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL memRead      : STD_LOGIC;
    SIGNAL memWrite     : STD_LOGIC;
    SIGNAL regWrite     : STD_LOGIC;
    SIGNAL aluSrcImm    : STD_LOGIC;
    SIGNAL jump         : STD_LOGIC;
    SIGNAL jumpReg      : STD_LOGIC;
    SIGNAL useImmediate : STD_LOGIC;
    SIGNAL immediate    : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rdSel        : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL rs1Sel       : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL rs2Sel       : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL isCompressed : STD_LOGIC;

    -- Internal control signals
    SIGNAL fetchRdy     : STD_LOGIC;
    SIGNAL decodeRdy    : STD_LOGIC;
    SIGNAL executeRdy   : STD_LOGIC;
    SIGNAL memAccessRdy : STD_LOGIC;
    SIGNAL writeBackRdy : STD_LOGIC;
    SIGNAL pipelineRdy  : STD_LOGIC;

    -- pipelining
    TYPE PipelineControlType IS RECORD
        pcWrite      : STD_LOGIC;
        aluOp        : STD_LOGIC_VECTOR(3 DOWNTO 0);
        branchOp     : STD_LOGIC_VECTOR(2 DOWNTO 0);
        memRead      : STD_LOGIC;
        memWrite     : STD_LOGIC;
        regWrite     : STD_LOGIC;
        aluSrcImm    : STD_LOGIC;
        jump         : STD_LOGIC;
        jumpReg      : STD_LOGIC;
        useImmediate : STD_LOGIC;
        immediate    : STD_LOGIC_VECTOR(31 DOWNTO 0);
        rdSel        : STD_LOGIC_VECTOR(4 DOWNTO 0);
        rs1Sel       : STD_LOGIC_VECTOR(4 DOWNTO 0);
        rs2Sel       : STD_LOGIC_VECTOR(4 DOWNTO 0);
        isCompressed : STD_LOGIC;
    END RECORD;

    TYPE PipelineArrayType IS ARRAY (0 TO 2) OF PipelineControlType;
    SIGNAL pipeline : PipelineArrayType;
    COMPONENT DecodeUnit
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
    END COMPONENT;

BEGIN

    -- Instantiate Decode Unit
    decode_inst : DecodeUnit
    PORT MAP(
        instr        => instr,
        isCompressed => isCompressed,
        aluOp        => aluOp,
        branchOp     => branchOp,
        memRead      => memRead,
        memWrite     => memWrite,
        regWrite     => regWrite,
        aluSrcImm    => aluSrcImm,
        jump         => jump,
        jumpReg      => jumpReg,
        useImmediate => useImmediate,
        immediate    => immediate,
        rdSel        => rdSel,
        rs1Sel       => rs1Sel,
        rs2Sel       => rs2Sel
    );

    -- State machine process
    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            state <= Fetch;
        ELSIF rising_edge(clk) THEN
            CASE state IS
                WHEN Fetch =>
                    pcWrite <= '1';
                    state   <= Decode;

                WHEN Decode =>
                    pcWrite <= '0';
                    state   <= Execute;

                WHEN Execute =>
                    state <= MemAccess;

                WHEN MemAccess =>
                    state <= WriteBack;

                WHEN WriteBack =>
                    state <= Fetch;
            END CASE;
        END IF;
    END PROCESS;

    --pipelining
    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            -- Clear pipeline
            pipeline <= (OTHERS => (OTHERS => '0'));
        ELSIF rising_edge(clk) THEN
            IF enable = '1' THEN
                IF alteredClk = '1' THEN
                    -- Shift the pipeline forward
                    pipeline(2) <= pipeline(1);
                    pipeline(1) <= pipeline(0);
                    -- Insert new values from decode stage into pipeline(0)
                    pipeline(0).pcWrite      <= pcWriteIn;
                    pipeline(0).aluOp        <= aluOpIn;
                    pipeline(0).branchOp     <= branchOpIn;
                    pipeline(0).memRead      <= memReadIn;
                    pipeline(0).memWrite     <= memWriteIn;
                    pipeline(0).regWrite     <= regWriteIn;
                    pipeline(0).aluSrcImm    <= aluSrcImmIn;
                    pipeline(0).jump         <= jumpIn;
                    pipeline(0).jumpReg      <= jumpRegIn;
                    pipeline(0).useImmediate <= useImmediateIn;
                    pipeline(0).immediate    <= immediateIn;
                    pipeline(0).rdSel        <= rdSelIn;
                    pipeline(0).rs1Sel       <= rs1SelIn;
                    pipeline(0).rs2Sel       <= rs2SelIn;
                    pipeline(0).isCompressed <= isCompressedIn;
                END IF;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE;