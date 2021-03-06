/**
 *
 * Name:
 *   bp_cce_pc.v
 *
 * Description:
 *   PC register, next PC logic, and instruction memory
 *
 * Configuration Link
 *   The config link is used to fill the instruction RAM, and to set the operating mode of the CCE.
 *   At startup, reset_i and freeze_i will both be high. After reset_i goes low, and while freeze_i
 *   is still high, the CCE waits for the mode register to be written.
 *
 *   After freeze_i goes low, the CCE begins operation.
 *
 *   config_addr_i specifies which address to read or write from. The address must be large enough
 *   to support 2*inst_ram_els_p addresses, plus the CCE mode register.
 *
 *   cfg_link_addr_width_p is assumed to be 16 bits, and cfg_link_data_width_p to be 32 bits
 *
 *   The msb of cfg_link_addr_width_p is reserved for the bridge link module. Of the address bits
 *   that are sent to the CCE, they are used as follows:
 *
 *   The address arriving on config_addr_i is interpreted as follows (and is 15-bits wide)
 *   14 - 1 if address is for CCE
 *   13 - 1 if address is for CCE instruction RAM, 0 if control register
 *
 *   For instruction RAM addresses (15'b11._...._...._....)
 *   1+:inst_ram_addr_width_lp - address into instruction RAM
 *   0 - specifies if instruction RAM address is for lo (0) or hi (1) 32-bit chunk of instruction
 *
 *   For configuration register addresses (15'b10._...._...._....)
 *   0+:cfg_reg_addr_width_lp - config register address
 *
 *   Current configuration registers:
 *   0 - cce_mode_r : controls the operating mode of the CCE
 *
 */

module bp_cce_pc
  import bp_common_pkg::*;
  import bp_cce_pkg::*;
  #(parameter inst_ram_els_p             = "inv"

    // Config channel parameters
    , parameter cfg_link_addr_width_p = "inv"
    , parameter cfg_link_data_width_p = "inv"
    , parameter cfg_ram_base_addr_p   = "inv"

    // Default parameters
    , parameter harden_p                 = 0

    // Derived parameters
    , localparam inst_width_lp           = `bp_cce_inst_width
    , localparam inst_ram_addr_width_lp  = `BSG_SAFE_CLOG2(inst_ram_els_p)

    // number of bits in cfg data packet used for hi part write
    , localparam cfg_link_hi_data_width_lp = (inst_width_lp-cfg_link_data_width_p)
    , localparam cfg_link_hi_pad_width_lp = cfg_link_data_width_p-cfg_link_hi_data_width_lp

    // number of bits for addressing cfg control registers
    // top three bits of address are reserved: one by external sender, two by this module
    , localparam cfg_reg_addr_width_lp = (cfg_link_addr_width_p-3)
  )
  (input                                         clk_i
   , input                                       reset_i
   , input                                       freeze_i

   // Config channel
   , input [cfg_link_addr_width_p-2:0]           config_addr_i
   , input [cfg_link_data_width_p-1:0]           config_data_i
   , input                                       config_v_i
   , input                                       config_w_i
   , output logic                                config_ready_o

   , output logic [cfg_link_data_width_p-1:0]    config_data_o
   , output logic                                config_v_o
   , input                                       config_ready_i

   // CCE mode output
   , output bp_cce_mode_e                        cce_mode_o

   // ALU branch result signal
   , input                                       alu_branch_res_i

   // control from decode
   , input                                       pc_stall_i
   , input [inst_ram_addr_width_lp-1:0]          pc_branch_target_i

   // instruction output to decode
   , output logic [inst_width_lp-1:0]            inst_o
   , output logic                                inst_v_o
  );

  initial begin
    assert(cfg_link_addr_width_p == 16) else $error("config link address not 16-bits");
    assert(cfg_link_data_width_p == 32) else $error("config link data not 32-bits");
  end

  typedef enum logic [3:0] {
    RESET
    ,INIT
    ,INIT_CFG_REG_RESP
    ,INIT_RAM_RD_RESP
    ,INIT_END
    ,FETCH_1
    ,FETCH_2
    ,FETCH
  } pc_state_e;

  pc_state_e pc_state, pc_state_n;

  // CCE mode register
  bp_cce_mode_e cce_mode_r, cce_mode_n;
  assign cce_mode_o = cce_mode_r;

  logic [inst_ram_addr_width_lp-1:0] ex_pc_r, ex_pc_n;
  logic inst_v_r, inst_v_n;
  logic ram_v_r, ram_v_n;
  logic ram_w_r, ram_w_n;
  logic [inst_ram_addr_width_lp-1:0] ram_addr_li, ram_addr_r, ram_addr_n;
  logic [inst_width_lp-1:0] ram_data_r, ram_data_n, ram_data_lo;
  logic [inst_width_lp-1:0] ram_w_mask_r, ram_w_mask_n;

  logic cfg_hi_not_lo_r, cfg_hi_not_lo_n;

  bsg_mem_1rw_sync_mask_write_bit
    #(.width_p(inst_width_lp)
      ,.els_p(inst_ram_els_p)
      )
    cce_inst_ram
     (.clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.v_i(ram_v_r)
      ,.data_i(ram_data_r)
      ,.addr_i(ram_addr_li)
      ,.w_i(ram_w_r)
      ,.data_o(ram_data_lo)
      ,.w_mask_i(ram_w_mask_r)
      );

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      pc_state <= RESET;

      ex_pc_r <= '0;
      inst_v_r <= '0;
      ram_v_r <= '0;
      ram_w_r <= '0;
      ram_addr_r <= '0;
      ram_data_r <= '0;
      ram_w_mask_r <= '0;

      cfg_hi_not_lo_r <= '0;

      cce_mode_r <= e_cce_mode_uncached;

    end else begin
      pc_state <= pc_state_n;

      ex_pc_r <= ex_pc_n;
      inst_v_r <= inst_v_n;
      ram_v_r <= ram_v_n;
      ram_w_r <= ram_w_n;
      ram_addr_r <= ram_addr_n;
      ram_data_r <= ram_data_n;
      ram_w_mask_r <= ram_w_mask_n;

      cfg_hi_not_lo_r <= cfg_hi_not_lo_n;

      cce_mode_r <= cce_mode_n;

    end
  end

  // config logic

  // address is for CCE if high bit is set
  logic config_cce_addr_v;
  assign config_cce_addr_v = config_addr_i[cfg_link_addr_width_p-2];

  // address is for a control register in CCE - if top two bits are "10"
  logic config_reg_addr_v;
  assign config_reg_addr_v = config_cce_addr_v & ~config_addr_i[cfg_link_addr_width_p-3];

  logic [cfg_reg_addr_width_lp-1:0] config_reg_addr, config_reg_addr_r, config_reg_addr_n;
  assign config_reg_addr = config_addr_i[0+:cfg_reg_addr_width_lp];
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      config_reg_addr_r <= '0;
    end else begin
      config_reg_addr_r <= config_reg_addr_n;
    end
  end

  // address is for CCE instruction RAM if top two bits are set
  logic config_pc_ram_addr_v;
  assign config_pc_ram_addr_v = config_cce_addr_v & config_addr_i[cfg_link_addr_width_p-3];

  // lsb of address determines if command is for lo or hi chunk of instruction RAM address
  // note: only used if this is an instruction RAM read or write
  logic config_hi;
  assign config_hi = config_pc_ram_addr_v & config_addr_i[0];

  assign inst_o = ram_data_lo;
  assign inst_v_o = inst_v_r;

  always_comb begin
    // config link outputs default to 0
    config_ready_o = '0;
    config_v_o = '0;
    config_data_o = '0;

    // by default, regardless of the pc_state, send the instruction ram the registered value
    ram_addr_li = ram_addr_r;

    // next values for registers

    // defaults
    pc_state_n = RESET;
    ex_pc_n = '0;
    inst_v_n = '0;
    ram_v_n = '0;
    ram_w_n = '0;
    ram_addr_n = ram_addr_r;
    ram_data_n = '0;
    ram_w_mask_n = '0;
    cfg_hi_not_lo_n = cfg_hi_not_lo_r;

    config_reg_addr_n = '0;

    cce_mode_n = cce_mode_r;

    case (pc_state)
      RESET: begin
        pc_state_n = (reset_i) ? RESET : INIT;
      end
      INIT: begin
        // In INIT, the CCE waits for commands to arrive on the configuration link
        config_ready_o = 1'b1;
        pc_state_n = INIT;
        // init complete when freeze is low and cce mode is normal
        // if freeze goes low, but mode is uncached, the CCE operates in uncached mode
        // and this module stays in the INIT state and does not fetch microcode
        if (!freeze_i && (cce_mode_r == e_cce_mode_normal)) begin
          // finalize init, then start fetching microcode next
          pc_state_n = INIT_END;
        // only do something if the config link input is valid, and the address targets the CCE
        end else if (config_v_i && config_cce_addr_v) begin
          // address is setting a configuration register
          if (config_reg_addr_v) begin
            // only capture register on read
            config_reg_addr_n = config_w_i ? '0 : config_reg_addr;
            if (config_reg_addr == '0) begin
              cce_mode_n = config_w_i ? bp_cce_mode_e'(config_data_i[0+:`bp_cce_mode_bits])
                                      : cce_mode_r;
              pc_state_n = config_w_i ? INIT : INIT_CFG_REG_RESP;
            end
          // address is reading or writing the instruction RAM
          end else if (config_pc_ram_addr_v) begin
            // inputs to RAM are valid if config address high bit is set
            ram_v_n = config_v_i;
            ram_w_n = config_w_i;
            // lsb of config address specifies if write is first or second part, so ram addr
            // starts at bit 1
            ram_addr_n = config_addr_i[1+:inst_ram_addr_width_lp];
            cfg_hi_not_lo_n = config_hi;
            if (config_hi) begin
              ram_w_mask_n = {(cfg_link_hi_data_width_lp)'('1),(cfg_link_data_width_p)'('0)};
              ram_data_n = {config_data_i[0+:cfg_link_hi_data_width_lp],(cfg_link_data_width_p)'('0)};
            end else begin
              ram_w_mask_n = {(cfg_link_hi_data_width_lp)'('0),(cfg_link_data_width_p)'('1)};
              ram_data_n = {(cfg_link_hi_data_width_lp)'('0),config_data_i};
            end
            pc_state_n = (ram_v_n & ram_w_n) ? INIT
                         : (ram_v_n) ? INIT_RAM_RD_RESP : INIT;
          end
        end
      end
      INIT_CFG_REG_RESP: begin
        config_v_o = 1'b1;
        config_data_o = (config_reg_addr_r == '0)
                        ? {(cfg_link_data_width_p-`bp_cce_mode_bits)'('0), cce_mode_r}
                        : '0;
        // wait for ready&valid handshake to occur
        pc_state_n = (config_ready_i) ? INIT : INIT_CFG_REG_RESP;
        // hold register value until message sent
        config_reg_addr_n = (config_ready_i) ? '0 : config_reg_addr_r;
      end
      INIT_RAM_RD_RESP: begin
        // hold the read valid until cfg link accepts the outbound packet
        ram_v_n = ~config_ready_i;
        ram_addr_n = ram_addr_r;
        config_v_o = 1'b1;
        config_data_o = (cfg_hi_not_lo_r)
          ? {(cfg_link_hi_pad_width_lp)'('0),ram_data_lo[0+:cfg_link_hi_data_width_lp]}
          : ram_data_lo[0+:cfg_link_data_width_p];
        pc_state_n = (config_ready_i) ? INIT : INIT_RAM_RD_RESP;
      end
      INIT_END: begin
        // let the last cfg link write finish (if there is one)
        pc_state_n = FETCH_1;
      end
      FETCH_1: begin
        // At the end of this cycle, the RAM will write the last instruction from the boot ROM
        // into its memory array. The following cycle, PC will be setup to start fetching from
        // address 0

        // setup to fetch first instruction
        // at end of cycle 1, RAM controls are captured into registers
        // at end of cycle 2, RAM captures the registers
        // in cycle 3, the instruction is produced and executed
        pc_state_n = FETCH_2;

        // setup input registers for instruction RAM
        // fetch address 0
        ram_v_n = 1'b1;
        ram_addr_n = '0;

        ex_pc_n = '0;
        inst_v_n = '0;

      end
      FETCH_2: begin
        // setup the registers for the first instruction
        pc_state_n = FETCH;

        ram_v_n = 1'b1;
        ram_addr_n = ram_addr_r + 'd1;

        // at the end of this cycle, inputs to the instruction RAM will be latched into the
        // registers that feed the RAM inputs

        // Thus, next cycle, no instruction will be valid
        ex_pc_n = '0;
        inst_v_n = 1'b1;

      end
      FETCH: begin
        // Always continue fetching instructions
        pc_state_n = FETCH;
        // next instruction is always valid once in steady state
        inst_v_n = 1'b1;

        // Always fetch an instruction
        ram_v_n = 1'b1;
        // setup RAM address register and register tracking PC of instruction being executed
        // also, determine input address for RAM depending on stall and branch in execution
        if (pc_stall_i) begin
          // when stalling, hold executing pc and ram addr registers constant
          ex_pc_n = ex_pc_r;
          ram_addr_n = ram_addr_r;
          // feed the currently executing pc as input to instruction ram
          ram_addr_li = ex_pc_r;
        end else if (alu_branch_res_i) begin
          // when branching, the instruction executed next is the branch target
          ex_pc_n = pc_branch_target_i;
          // the following instruction to fetch is after the branch target
          ram_addr_n = pc_branch_target_i + 'd1;
          // if branching, use the branch target from the current instruction
          ram_addr_li = pc_branch_target_i;
        end else begin
          // normal execution, the instruction that will be executed is the one that will
          // be fetched in sequential order
          ex_pc_n = ram_addr_r;
          // the next instruction to fetch follows sequentially
          ram_addr_n = ram_addr_r + 'd1;
          // normally, use the address register (i.e., sequential execution)
          ram_addr_li = ram_addr_r;
        end

      end
    endcase
  end

endmodule
