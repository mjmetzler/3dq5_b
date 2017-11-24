`timescale 1ns/100ps
`default_nettype none

`include "define_state.h"

module Milestone2 (
    
    
    output logic   [17:0]   SRAM_address,
    output logic   [15:0]   SRAM_write_data,
    input logic    [15:0]   SRAM_read_data,
    output logic            SRAM_we_enable
);

milestone_2_state m2_state;


//multiplier variables
logic [31:0] op1, op2, op3, op4, prod1, prod2, prod3, prod4;
logic [63:0] prod1_long, prod2_long, prod3_long, prod4_long;

//multipliers
assign prod1_long = $signed(op1*op3);//op1*op3;
assign prod1 = (prod1_long[63] == 1'b0 ? (prod1_long[31:0] : ~prod1_long[31:0] + 1'd1));

assign prod2_long = $signed(op1*op4);//op1*op4;
assign prod2 = (prod2_long[63] == 1'b0 ? (prod2_long[31:0] : ~prod2_long[31:0] + 1'd1));

assign prod3_long = $signed(op2*op3);//op2*op3;
assign prod3 = (prod3_long[63] == 1'b0 ? (prod3_long[31:0] : ~prod3_long[31:0] + 1'd1));

assign prod4_long = $signed(op3*op4);//op2*op4;
assign prod1 = (prod4_long[63] == 1'b0 ? (prod4_long[31:0] : ~prod4_long[31:0] + 1'd1));

//modulo-counter system for reading Y
logic [17:0] read_address_y;
logic [8:0] RA_ry, CA_ry;
logic [5:0] counterM_ry, counterC_ry;
logic [4:0] counterR_ry;
logic [2:0] ri_ry, ci_ry;

assign ri_ry = counterM_ry[5:3];
assign ci_ry = counterM_ry[2:0];
assign RA_ry = {counterR_ry,ri_ry};
assign CA_ry = {counterC_ry,ci_ry};
assign read_address_y = yidct_offset + {RA_ry,8'd0} + {RA_ry,6'd0} + CA_ry;

//modulo-counter system for writing Y
logic [17:0] write_address_y;
logic [7:0] RA_wy, CA_wy;
logic [5:0] counterC_wy;
logic [4:0] counterM_wy, counterR_wy;
logic [2:0] ri_wy;
logic [1:0] ci_wy;

assign ri_wy = counterM_wy[4:2];
assign ci_wy = counterM_wy[1:0];
assign RA_wy = {counterR_wy,ri_wy};
assign CA_wy = {counterC_wy,ci_wy};
assign write_address_y = y_offset + {RA_wy,7'd0} + {RA_wy,5'd0} + CA_wy;

//modulo-counter system for reading U/V
logic [17:0] read_address_uv;
logic [7:0] RA_ruv, CA_ruv;
logic [5:0] counterM_ruv;
logic [4:0] counterR_ruv, counterC_ruv;
logic [2:0] ri_ruv, ci_ruv;

assign ri_ruv = counterM_ruv[5:3];
assign ci_ruv = counterM_ruv[2:0];
assign RA_ruv = {counterR_ruv,ri_ruv};
assign CA_ruv = {counterC_ruv,ci_ruv};
assign read_address_uv = uvidct_offset + {RA_ruv,7'd0} + {RA_ruv,5'd0} + CA_ruv;

//modulo-counter system for writing U/V
logic [17:0] write_address_uv;
logic [7:0] RA_wuv, CA_wuv;
logic [4:0] counterM_wuv, counterR_wuv, counterC_wuv;
logic [2:0] ri_wuv;
logic [1:0] ci_wuv;

assign ri_wuv = counterM_wuv[4:2];
assign ci_wuv = counterM_wuv[1:0];
assign RA_wuv = {counterR_wuv,ri_wuv};
assign CA_wuv = {counterC_wuv,ci_wuv};
assign write_address_uv = uv_offset + {RA_wuv,6'd0} + {RA_wuv,4'd0} + CA_wuv;

always @(posedge CLOCK or negedge Resetn) begin

    if (~Resetn) begin
        
        m2_state <= S_idle2;
        
        m2_done <= 1'b0;
    
    end else begin
    
        if (read_flagY) begin
            counterM_ry <= counterM_ry + 1'd1;
            if (&counterM_ry) begin
                if (counterC_ry == 6'd39) begin
                    counterC_ry <= 6'd0;
                    if (counterR_ry == 5'd29)
                        counterR_ry <= 5'd0;
                        ready_y_done <= 1'b1;
                    end else
                        counterR_ry <= counterR_ry + 1'd1;
                    end
                end else
                    counterC_ry <= counterC_ry + 1'd1;
            end
        end
        
        if (write_flagY) begin
            counterM_wy <= counterM_wy + 1'd1;
            if (&counterM_wy) begin
                if (counterC_wy == 6'd39) begin
                    counterC_wy <= 6'd0;
                    if (counterR_wy == 5'd29)
                        counterR_wy <= 5'd0;
                        y_done <= 1'b1;
                    end else
                        counterR_wy <= counterR_wy + 1'd1;
                    end
                end else
                    counterC_wy <= counterC_wy + 1'd1;
            end
        end
        
        if (read_flagUV) begin
            counterM_ruv <= counterM_ruv + 1'd1;
            if (&counterM_ruv) begin
                if (counterC_ruv == 6'd19) begin
                    counterC_ruv <= 6'd0;
                    if (counterR_ruv == 5'd29)
                        counterR_ruv <= 5'd0;
                        ready_uv_done <= 1'b1;
                    end else
                        counterR_ruv <= counterR_ruv + 1'd1;
                    end
                end else
                    counterC_ruv <= counterC_ruv + 1'd1;
            end
        end
        
        if (write_flagUV) begin
            counterM_wuv <= counterM_wuv + 1'd1;
            if (&counterM_wuv) begin
                if (counterC_wuv == 6'd19) begin
                    counterC_wuv <= 6'd0;
                    if (counterR_wuv == 5'd29)
                        counterR_wuv <= 5'd0;
                        uv_done <= 1'b1;
                    end else
                        counterR_wuv <= counterR_wuv + 1'd1;
                    end
                end else
                    counterC_wuv <= counterC_wuv + 1'd1;
            end
        end
                    
    
        case(m2_state)
        
        S_idle2: begin
        end
        
        S_read_in: begin
            //1 cycle to toggle read_flag_Y
            if (toggle) begin
                toggle <= ~toggle;
                read_flag_Y <= 1'b1;
            end
            //3 cycles to begin reading from SRAM
            else if (|reads) begin
                SRAM_address <= read_address;
                SRAM_we_enable <= 1'b1;
                reads <= reads - 1'd1;
            end
            //61 cycles to finish reading from SRAM and begin writing into DP RAM
            else if (|reads_writes) begin
                SRAM_address <= read_address;
                SRAM_we_enable <= 1'b1;
                
                dp0_adr_a <= s_prime_adr;
                s_prime_adr <= s_prime_adr + 1'd1;
                dp0_write_data_a <= { 16{SRAM_read_data[15]}, SRAM_read_data };
                dp0_enable_a <= 1'b1;
                
                if(reads_writes == 6'd1)
                    read_flag_Y <= 1'b0;
            end
            //3 cycles to finish writing to DPRAM
            else if (|writes) begin
                dp0_adr_a <= s_prime_adr;
                s_prime_adr <= s_prime_adr + 1'd1;
                dp0_write_data_a <= { 16{SRAM_read_data[15]}, SRAM_read_data };
                dp0_enable_a <= 1'b1;
            end else
                dp0_enable_a <= 1'b0;
                s_prime_adr <= 8'd0;
                sp_adrb <= 8'd0;//might neeed to move 
                m2_state <= S_compute_in;
            end
            
        end
        
        S_compute_in: begin
            
            if(start_T) begin
                if(leadT < 3'd2) begin
                    dp0_adr_a <= s_prime_adr;
                    s_prime_adr <= s_prime_adr + 1'd1;
                    dp0_adr_b <= sp_adrb;
                    sp_adrb <= sp_adrb + 1'd1;
                    dp0_enable_a <= 1'b0;
                    dp0_enable_b <= 1'b0;
                    leadT <= leadT + 1'd1;//needs to be initialized
                end
                else if (leadT == 3'd2) begin
                    dp0_adr_a <= s_prime_adr;
                    s_prime_adr <= s_prime_adr + 1'd1;
                    dp0_adr_b <= sp_adrb;
                    sp_adrb <= sp_adrb + 1'd1;
                    dp0_enable_a <= 1'b0;
                    dp0_enable_b <= 1'b0;
                    
                    op1 <= dp0_read_data_a;
                    op2 <= dp0_read_data_b;
                    c_pair <= c_pair_count; //sets op3 and op4 as values from the C matrix
                    c_pair_count <= c_pair_count + 1'd1;
                    leadT <= leadT + 1'd1;
                end
                else begin
                    dp0_adr_a <= s_prime_adr;
                    s_prime_adr <= s_prime_adr + 1'd1;
                    dp0_adr_b <= sp_adrb;
                    sp_adrb <= sp_adrb + 1'd1;
                    dp0_enable_a <= 1'b0;
                    dp0_enable_b <= 1'b0;
                    
                    op1 <= dp0_read_data_a;
                    op2 <= dp0_read_data_b;
                    c_pair <= c_pair_count; //sets op3 and op4 as values from the C matrix
                    c_pair_count <= c_pair_count + 1'd1;
                    
                    if(leadT == 3'd3) begin
                        t_aa <= { 8{prod1[31]}, prod1[31:8] };
                        t_ab <= { 8{prod2[31]}, prod2[31:8] };
                        t_ba <= { 8{prod3[31]}, prod3[31:8] };
                        t_bb <= { 8{prod4[31]}, prod4[31:8] };
                    end
                    else begin
                        t_aa <= t_aa + { 8{prod1[31]}, prod1[31:8] };
                        t_ab <= t_ab + { 8{prod2[31]}, prod2[31:8] };
                        t_ba <= t_ba + { 8{prod3[31]}, prod3[31:8] };
                        t_bb <= t_bb + { 8{prod4[31]}, prod4[31:8] };
                    end
                    
                    if (leadT == 3'd7) begin
                        leadT <= 3'd0;
                        s_prime_adr <= 8'd0;
                        sp_adrb <= 8'd8;
                        sp_read_cycle <= 4'd1;
                        start_T <= 1'b0;
                    end else
                        leadT <= leadT + 1'd1;
                end
            end
            else if (!T_end) begin
                //2 cycles to read(0) and compute(-1)
                if (|stage_a) begin
                    //accumulating matrix values
                    t_aa <= t_aa + { 8{prod1[31]}, prod1[31:8] };
                    t_ab <= t_ab + { 8{prod2[31]}, prod2[31:8] };
                    t_ba <= t_ba + { 8{prod3[31]}, prod3[31:8] };
                    t_bb <= t_bb + { 8{prod4[31]}, prod4[31:8] };

                    //preparing next addresses to read from dual port
                    dp0_adr_a <= s_prime_adr;
                    s_prime_adr <= s_prime_adr + 1'd1;
                    dp0_adr_b <= sp_adrb;
                    sp_adrb <= sp_adrb + 1'd1;
                    dp0_enable_a <= 1'b0;
                    dp0_enable_b <= 1'b0;

                    //reading s' values from dual port
                    op1 <= dp0_read_data_a;
                    op2 <= dp0_read_data_b;
                    c_pair <= c_pair_count; //sets op3 and op4 as values from the C matrix
                    c_pair_count <= c_pair_count + 1'd1;

                    stage_a <= stage_a - 2'd1;
                end
                //3 cycles to read(0), write(-1) and compute(0)
                else if (|stage_b) begin
                    //final matrix values (from previous stage)
                    if(stage_b == 2'd3) begin
                        result_t_aa <= t_aa + { 8{prod1[31]}, prod1[31:8] };
                        result_t_ab <= t_ab + { 8{prod2[31]}, prod2[31:8] };
                        result_t_ba <= t_ba + { 8{prod3[31]}, prod3[31:8] };
                        result_t_bb <= t_bb + { 8{prod4[31]}, prod4[31:8] }; 
                    end
                    //accumulating and computing matrix values
                    //reset case (from previous accumulation)
                    else if ((c_count_pair == 5'd1) || (c_count_pair == 5'd9) || (c_count_pair == 5'd17) || (c_count_pair == 5'd25)) begin
                        t_aa <= { 8{prod1[31]}, prod1[31:8] };
                        t_ab <= { 8{prod2[31]}, prod2[31:8] };
                        t_ba <= { 8{prod3[31]}, prod3[31:8] };
                        t_bb <= { 8{prod4[31]}, prod4[31:8] };
                    end
                    //common accumulation case
                    else begin
                        t_aa <= t_aa + { 8{prod1[31]}, prod1[31:8] };
                        t_ab <= t_ab + { 8{prod2[31]}, prod2[31:8] };
                        t_ba <= t_ba + { 8{prod3[31]}, prod3[31:8] };
                        t_bb <= t_bb + { 8{prod4[31]}, prod4[31:8] };
                    end 

                    //preparing next addresses to read from dual port
                    dp0_adr_a <= s_prime_adr;
                    s_prime_adr <= s_prime_adr + 1'd1;
                    dp0_adr_b <= sp_adrb;
                    sp_adrb <= sp_adrb + 1'd1;
                    dp0_enable_a <= 1'b0;
                    dp0_enable_b <= 1'b0;

                    //reading s' values from dual port
                    op1 <= dp0_read_data_a;
                    op2 <= dp0_read_data_b;
                    c_pair <= c_pair_count; //sets op3 and op4 as values from the C matrix
                    c_pair_count <= c_pair_count + 1'd1;

                    //writing the 4 T values into dp-ram 1
                    //first pair
                    if (stage_b == 2'd2) begin
                        dp1_adr_a <= ta_adr;
                        dp1_adr_b <= tb_adr;
                        dp1_write_data_a <= result_t_aa;
                        dp1_write_data_b <= result_t_ba;
                        dp1_enable_a <= 1'b1;
                        dp1_enable_b <= 1'b1;
                        ta_adr <= ta_adr + 1'd1;
                        tb_adr <= tb_adr + 1'd1;
                    end
                    //second pair
                    else if (stage_b == 2'd1) begin
                        dp1_adr_a <= ta_adr;
                        dp1_adr_b <= tb_adr;
                        dp1_write_data_a <= result_t_ab;
                        dp1_write_data_b <= result_t_bb;
                        dp1_enable_a <= 1'b1;
                        dp1_enable_b <= 1'b1;
                        //matrix address incrementation
                        if ((ta_adr == 6'd7) || (ta_adr == 6'd23) || (ta_adr == 6'd39) || (ta_adr == 6'd55)) begin
                            ta_adr <= ta_adr + 1'd9;
                            tb_adr <= tb_adr + 1'd9;
                        end else begin
                            ta_adr <= ta_adr + 1'd1;
                            tb_adr <= tb_adr + 1'd1;
                        end
                    end
                    stage_b <= stage_b - 2'd1;
                end //stage_b
                //3 cycles to read(0) and compute (0)
                else begin //stage_c

                    //accumulating the results of the previous cycle's multiplication
                    t_aa <= t_aa + { 8{prod1[31]}, prod1[31:8] };
                    t_ab <= t_ab + { 8{prod2[31]}, prod2[31:8] };
                    t_ba <= t_ba + { 8{prod3[31]}, prod3[31:8] };
                    t_bb <= t_bb + { 8{prod4[31]}, prod4[31:8] };

                    //setting operands for the matrix multiplications
                    op1 <= dp0_read_data_a;
                    op2 <= dp0_read_data_b;
                    c_pair <= c_pair_count; //sets op3 and op4 as values from the C matrix
                    c_pair_count <= c_pair_count + 1'd1;

                    // reading s' values 
                    if (stage_c == 2'd1) begin //last read of the current set of 4 multiplications
                        dp0_adr_a <= s_prime_adr;
                        dp0_adr_b <= sp_adrb;
                        dp0_enable_a <= 1'b0;
                        dp0_enable_b <= 1'b0;

                        //reset stage flags
                        stage_a <= 2'd2;
                        stage_b <= 2'd3;
                        stage_c <= 2'd3;

                        if (sp_read_cycle == 4'd15) begin // have done all reads to compute the current 8 by 8 matrix
                            s_prime_adr <= 6'd0;
                            sp_adrb <= 6'd8;
                            T_end <= 1'b1;
                        end
                        //begin using next two rows of s'
                        else if ((sp_read_cycle == 4'd3) ||(sp_read_cycle == 4'd7) || (sp_read_cycle == 4'd11)) begin
                            s_prime_adr <= s_prime_adr + 6'd9;
                            sp_adrb <= sp_adrb + 6'd9;
                        end else begin // reset the s' values to the start of the rows
                            s_prime_adr <= s_prime_adr - 6'd7;
                            sp_adrb <= sp_adrb - 6'd7;
                        end
                    end else begin
                        dp0_adr_a <= s_prime_adr;
                        dp0_adr_b <= sp_adrb;
                        dp0_enable_a <= 1'b0;
                        dp0_enable_b <= 1'b0;
                        s_prime_adr <= s_prime_adr + 1'd1;
                        sp_adrb <= sp_adrb + 1'd1;
                        stage_c <= stage_c - 2'd1;
                    end
                end //end stage_c  
                //begin lead out (5 cycles)
            end else begin //T_end
                //first 2 cycles: computing and accumulating (-1)
                if (|compute_end) begin
                    t_aa <= t_aa + { 8{prod1[31]}, prod1[31:8] };
                    t_ab <= t_ab + { 8{prod2[31]}, prod2[31:8] };
                    t_ba <= t_ba + { 8{prod3[31]}, prod3[31:8] };
                    t_bb <= t_bb + { 8{prod4[31]}, prod4[31:8] };

                    //setting operands for the matrix multiplications
                    op1 <= dp0_read_data_a;
                    op2 <= dp0_read_data_b;
                    c_pair <= c_pair_count; //sets op3 and op4 as values from the C matrix
                    c_pair_count <= c_pair_count + 1'd1;                  
                end 

                // next cycle: final accumulation (-1)
                else if (last_multiplication) begin
                    last_multiplication <= 1'b0;
                    t_aa <= t_aa + { 8{prod1[31]}, prod1[31:8] };
                    t_ab <= t_ab + { 8{prod2[31]}, prod2[31:8] };
                    t_ba <= t_ba + { 8{prod3[31]}, prod3[31:8] };
                    t_bb <= t_bb + { 8{prod4[31]}, prod4[31:8] };
                end 

                // next cycle: writing(-1) first pair into DPRAM
                else if (tb_adr == 6'd62) begin
                    dp1_adr_a <= ta_adr;
                    dp1_adr_b <= tb_adr;
                    dp1_write_data_a <= result_t_aa;
                    dp1_write_data_b <= result_t_ba;
                    dp1_enable_a <= 1'b1;
                    dp1_enable_b <= 1'b1;
                    ta_adr <= ta_adr + 1'd1;
                    tb_adr <= tb_adr + 1'd1;
                end 

                // last cycle: writing(-1) second pair into DPRAM, reset for next megastate reentry
                else begin
                    dp1_adr_a <= ta_adr;
                    dp1_adr_b <= tb_adr;
                    dp1_write_data_a <= result_t_ab;
                    dp1_write_data_b <= result_t_bb;
                    dp1_enable_a <= 1'b1;
                    dp1_enable_b <= 1'b1;
                    ta_adr <= 6'd0;
                    tb_adr <= 6'd0;
                    state <= megastate_1;
                end
            end
        end //end compute_in
            
        //begin computation for S
        
        //2 cycles reading the t matrix    
        S_compute_out1: begin
            dp1_adr_a <= ta_adr;
            ta_adr <= ta_adr + 1'd1;
            dp1_adr_b <= tb_adr;
            tb_adr <= tb_adr + 1'd1;
            dp1_enable_a <= 1'b0;
            dp1_enable_b <= 1'b0;
            if (out1_first) begin
                out1_first <= 1'b0;
            end else
                m2_state <= S_compute_out2;  
        end
        
        //6 cycles reading the t matrix and computing and accumulating the results (0)    
        S_compute_out2: begin
            //accumulation
            if (out2 == 3'd1) begin
                s_aa <= { 8{prod1[31]}, prod1[31:8] };
                s_ab <= { 8{prod2[31]}, prod2[31:8] };
                s_ba <= { 8{prod3[31]}, prod3[31:8] };
                s_bb <= { 8{prod4[31]}, prod4[31:8] };
            end
            else if (out2 > 3'd1) begin
                s_aa <= s_aa + { 8{prod1[31]}, prod1[31:8] };
                s_ab <= s_ab + { 8{prod2[31]}, prod2[31:8] };
                s_ba <= s_ba + { 8{prod3[31]}, prod3[31:8] };
                s_bb <= s_bb + { 8{prod4[31]}, prod4[31:8] };
            end
            
            //address incrementation
            dp1_adr_a <= ta_adr;
            ta_adr <= ta_adr + 1'd1;
            dp1_adr_b <= tb_adr;
            tb_adr <= tb_adr + 1'd1;
            dp1_enable_a <= 1'b0;
            dp1_enable_b <= 1'b0;

            //data reading 
            op1 <= dp1_read_data_a;
            op2 <= dp1_read_data_b;
            transpose_pair <= transpose_pair_count; //sets op3 and op4 as values from the C transpose matrix
            transpose_pair_count <= transpose_pair_count + 1'd1;
            out2 <= out2 + 1'd1;
            
            //state transitions and reset
            if (out2 == 3'd5) begin
                ta_adr <= 8'd0;
                tb_adr <= 8'd8;
                t_read_cycle <= 4'd1;
                m2_state <= S_compute_out3;
            end
        end
        
        S_compute_out3: begin //common case of 
            //2 cycles of reads (0) and computes (-1)
            if (|stage_a_out) begin
                //reads
                s_aa <= s_aa + { 8{prod1[31]}, prod1[31:8] };
                s_ab <= s_ab + { 8{prod2[31]}, prod2[31:8] };
                s_ba <= s_ba + { 8{prod3[31]}, prod3[31:8] };
                s_bb <= s_bb + { 8{prod4[31]}, prod4[31:8] };

                //address increments
                dp1_adr_a <= ta_adr;
                ta_adr <= ta_adr + 1'd1;
                dp1_adr_b <= tb_adr;
                tb_adr <= tb_adr + 1'd1;
                dp1_enable_a <= 1'b0;
                dp1_enable_b <= 1'b0;
                
                //computes
                op1 <= dp1_read_data_a;
                op2 <= dp1_read_data_b;
                transpose_pair <= transpose_pair_count; //sets op3 and op4 as values from the C transpose matrix
                transpose_pair_count <= transpose_pair_count + 1'd1;

                stage_a_out <= stage_a_out - 2'd1;
            end
            else if (|stage_b_out) begin
                //accumulating the results of the previous cycle's multiplication
                if(stage_b_out == 2'd3) begin
                    result_s_aa <= s_aa + { 8{prod1[31]}, prod1[31:8] };
                    result_s_ab <= s_ab + { 8{prod2[31]}, prod2[31:8] };
                    result_s_ba <= s_ba + { 8{prod3[31]}, prod3[31:8] };
                    result_s_bb <= s_bb + { 8{prod4[31]}, prod4[31:8] }; 
                end
                
                //accumulating results of current cycle multiplication
                else if ((transpose_pair_count == 5'd1) || (transpose_pair_count == 5'd9) || (transpose_pair_count == 5'd17) || (transpose_pair_count == 5'd25)) begin
                    s_aa <= { 8{prod1[31]}, prod1[31:8] };
                    s_ab <= { 8{prod2[31]}, prod2[31:8] };
                    s_ba <= { 8{prod3[31]}, prod3[31:8] };
                    s_bb <= { 8{prod4[31]}, prod4[31:8] };
                end
                else begin
                    s_aa <= s_aa + { 8{prod1[31]}, prod1[31:8] };
                    s_ab <= s_ab + { 8{prod2[31]}, prod2[31:8] };
                    s_ba <= s_ba + { 8{prod3[31]}, prod3[31:8] };
                    s_bb <= s_bb + { 8{prod4[31]}, prod4[31:8] };
                end 

                //reading s values from dp-ram 1
                dp1_adr_a <= ta_adr;
                ta_adr <= ta_adr + 1'd1;
                dp1_adr_b <= tb_adr;
                tb_adr <= tb_adr + 1'd1;
                dp1_enable_a <= 1'b0;
                dp1_enable_b <= 1'b0;

                //setting operands for the matrix multiplications
                op1 <= dp1_read_data_a;
                op2 <= dp1_read_data_b;
                transpose_pair <= transpose_pair_count; //sets op3 and op4 as values from the C transpose matrix
                transpose_pair_count <= transpose_pair_count + 1'd1;

                //writing the 4 s values into dp-ram 2
                if (stage_b_out == 2'd2) begin
                    dp2_adr_a <= sa_adr;
                    dp2_adr_b <= sb_adr;
                    dp2_write_data_a <= result_s_aa;
                    dp2_write_data_b <= result_s_ba;
                    dp2_enable_a <= 1'b1;
                    dp2_enable_b <= 1'b1;
                    sa_adr <= sa_adr + 1'd1;
                    sb_adr <= sb_adr + 1'd1;
                end
                else if (stage_b_out == 2'd1) begin
                    dp2_adr_a <= sa_adr;
                    dp2_adr_b <= sb_adr;
                    dp2_write_data_a <= result_s_aa;
                    dp2_write_data_b <= result_s_ba;
                    dp2_enable_a <= 1'b1;
                    dp2_enable_b <= 1'b1;

                    if ((sa_adr == 6'd7) || (sa_adr == 6'd23) || (sa_adr == 6'd39) || (sa_adr == 6'd55)) begin
                        sa_adr <= sa_adr + 1'd9;
                        sb_adr <= sb_adr + 1'd9;
                    end else begin
                        sa_adr <= sa_adr + 1'd1;
                        sb_adr <= sb_adr + 1'd1;
                    end
                end
                stage_b_out <= stage_b_out - 2'd1;
            end //stage_b
            
            //3 cycles to read and compute for the current cycle (0)
            else begin //stage_c

                //accumulating the results of the previous cycle's multiplication
                s_aa <= s_aa + { 8{prod1[31]}, prod1[31:8] };
                s_ab <= s_ab + { 8{prod2[31]}, prod2[31:8] };
                s_ba <= s_ba + { 8{prod3[31]}, prod3[31:8] };
                s_bb <= s_bb + { 8{prod4[31]}, prod4[31:8] };

                //setting operands for the matrix multiplications
                op1 <= dp1_read_data_a;
                op2 <= dp1_read_data_b;
                transpose_pair <= transpose_pair_count; //sets op3 and op4 as values from the C transpose matrix
                transpose_pair_count <= transpose_pair_count + 1'd1;

                // reading s values 
                if (stage_c_out == 2'd1) begin //last read of the current set of 4 multiplications
                    dp1_adr_a <= ta_adr;
                    dp1_adr_b <= tb_adr;
                    dp1_enable_a <= 1'b0;
                    dp1_enable_b <= 1'b0;

                    stage_a_out <= 2'd2;
                    stage_b_out <= 2'd3;
                    stage_c_out <= 2'd3;

                    if (t_read_cycle == 4'd15) begin // have done all reads to compute the current 8 by 8 matrix
                        ta_adr <= 6'd0;
                        tb_adr <= 6'd8;
                        m2_state <= S_compute_out4
                    end
                    //begin using next two rows of s'
                    else if ((t_read_cycle == 4'd3) || (t_read_cycle == 4'd7) || (t_read_cycle == 4'd11)) begin
                        ta_adr <= ta_adr + 6'd9;
                        tb_adr <= tb_adr + 6'd9;
                    end else begin // reset the s values to the start of the rows
                        ta_adr <= ta_adr - 6'd7;
                        tb_adr <= tb_adr - 6'd7;
                    end
                end else begin
                    dp1_adr_a <= ta_adr;
                    ta_adr <= ta_adr + 1'd1;
                    dp1_adr_b <= tb_adr;
                    tb_adr <= tb_adr + 1'd1;
                    dp1_enable_a <= 1'b0;
                    dp1_enable_b <= 1'b0;
                    stage_c_out <= stage_c_out - 2'd1;
                end
            end //end stage_c
        end //end compute_out3
        
        //5 cycle lead out state
        S_compute_out4: begin
            //2 computes and accumulations
            if (|compute_end_out) begin
                s_aa <= s_aa + { 8{prod1[31]}, prod1[31:8] };
                s_ab <= s_ab + { 8{prod2[31]}, prod2[31:8] };
                s_ba <= s_ba + { 8{prod3[31]}, prod3[31:8] };
                s_bb <= s_bb + { 8{prod4[31]}, prod4[31:8] };

                //setting operands for the matrix multiplications
                op1 <= dp1_read_data_a;
                op2 <= dp1_read_data_b;
                transpose_pair <= transpose_pair_count; //sets op3 and op4 as values from the C transpose matrix
                transpose_pair_count <= transpose_pair_count + 1'd1;

                compute_end_out <= compute_end_out - 2'd1;
            end 
            
            //last accumulation
            else if (last_multiplication_out) begin
                last_multiplication_out <= 1'b0;
                result_s_aa <= s_aa + { 8{prod1[31]}, prod1[31:8] };
                result_s_ab <= s_ab + { 8{prod2[31]}, prod2[31:8] };
                result_s_ba <= s_ba + { 8{prod3[31]}, prod3[31:8] };
                result_s_bb <= s_bb + { 8{prod4[31]}, prod4[31:8] };
            end 
            //second last write into DPRAM
            else if (sb_adr == 6'd62) begin
                dp2_adr_a <= sa_adr;
                dp2_adr_b <= sb_adr;
                dp2_write_data_a <= result_s_aa;
                dp2_write_data_b <= result_s_ba;
                dp2_enable_a <= 1'b1;
                dp2_enable_b <= 1'b1;
                sa_adr <= sa_adr + 1'd1;
                sb_adr <= sb_adr + 1'd1;
            end 
            
            //last write into DPRAM
            else begin
                dp2_adr_a <= sa_adr;
                dp2_adr_b <= sb_adr;
                dp2_write_data_a <= result_s_ab;
                dp2_write_data_b <= result_s_bb;
                dp2_enable_a <= 1'b1;
                dp2_enable_b <= 1'b1;
                sa_adr <= 6'd0;
                sb_adr <= 6'd0;
                state <= S_write_outa;
            end
        end
            
        //initialize writeout to 0
        S_write_outa: begin
            dp2_adr_a <= s_adr;
            s_adr <= s_adr + 1'd1;
            dp2_adr_b <= s_adrb;
            s_adrb <= s_adrb + 1'd1;
            dp2_enable_a <= 1'b0;
            dp2_enable_b <= 1'b0;
            writeout <= writeout + 6'd1;
            if (writeout == 6'd1) begin
                write_flagUV <= 1'b1;
                m2_state <= S_write_outb;
            end
        end
            
        S_write_outb: begin
            SRAM_address <= write_address_uv;
            SRAM_write_data[15:8] <= (dp2_read_data_a[31]) ? 8'd0 : ( (|dp2_read_data_a[30:24]) ? 8'd255 : dp2_read_data_a[23:16] );
            SRAM_write_data[7:0] <= (dp2_read_data_b[31]) ? 8'd0 : ( (|dp2_read_data_b[30:24]) ? 8'd255 : dp2_read_data_b[23:16] );
            SRAM_we_enable <= 1'b0;
            
            dp2_adr_a <= s_adr;
            dp2_adr_b <= s_adrb;
            dp2_enable_a <= 1'b0;
            dp2_enable_b <= 1'b0;
            
            if ( (s_adr == 6'd7) || (s_adr == 6'd23) || (s_adr == 6'd39) || (s_adr == 6'd55) ) begin
                s_adr <= s_adr + 6'd9;
                s_adrb <= s_adrb + 6'd9;
            end else begin
                s_adr <= s_adr + 1'd1;
                s_adrb <= s_adrb + 1'd1;
            end
            
            writeout <= writeout + 6'd1;
            if (writeout == 6'd31)
                m2_state <= S_write_outc;
        end
        
        S_write_outc: begin
            SRAM_address <= write_address_uv;
            SRAM_write_data[15:8] <= (dp2_read_data_a[31]) ? 8'd0 : ( (|dp2_read_data_a[30:24]) ? 8'd255 : dp2_read_data_a[23:16] );
            SRAM_write_data[7:0] <= (dp2_read_data_b[31]) ? 8'd0 : ( (|dp2_read_data_b[30:24]) ? 8'd255 : dp2_read_data_b[23:16] );
            SRAM_we_enable <= 1'b0;
            
            writeout <= writeout + 6'd1;
            if (writeout == 6'd33)
                m2_state <= S_idle2;
        end
        
        endcase
    
    end
end
endmodule
