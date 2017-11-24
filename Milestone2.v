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

//modulo-counter system for Y
logic [17:0] read_address;
logic [8:0] RA, CA;
logic [5:0] counterM, counterC;
logic [4:0] counterR;
logic [3:0] ri, ci;

assign ri = counterM[5:3];
assign ci = counterM[2:0];
assign RA = {counterR,ri};
assign CA = {counterC,ci};
assign read_address = {RA,8'd0} + {RA,6'd0} + CA;

always @(posedge CLOCK or negedge Resetn) begin

    if (~Resetn) begin
        
        m2_state <= S_idle2;
        
        m2_done <= 1'b0;
    
    end else begin
    
        if (read_flag) begin
            counterM <= counterM + 1'd1;
            if (&counterM) begin
                if (counterC == 6'd39) begin
                    counterC <= 6'd0;
                    if (counterR == 5'd29)
                        counterR <= 5'd0;
                        ready_y_done <= 1'b1;
                    end else
                        counterR <= counterR + 1'd1;
                    end
                end else
                    counterC <= counterC + 1'd1;
            end
        end
                    
    
        case(m2_state)
        
        S_idle2: begin
        end
        
        S_read_in: begin
            
            if (toggle) begin
                toggle <= ~toggle;
                read_flag <= 1'b1;
            end
            else if (|reads) begin
                SRAM_address <= read_address;
                SRAM_we_enable <= 1'b1;
                reads <= reads - 1'd1;
            end
            else if (|reads_writes) begin
                SRAM_address <= read_address;
                SRAM_we_enable <= 1'b1;
                
                dp0_adr_a <= s_prime_adr;
                s_prime_adr <= s_prime_adr + 1'd1;
                dp0_write_data_a <= { 16{SRAM_read_data[15]}, SRAM_read_data };
                dp0_enable_a <= 1'b1;
                
                if(reads_writes == 6'd1)
                    read_flag <= 1'b0;
            end
            else if (|writes) begin
                dp0_adr_a <= s_prime_adr;
                s_prime_adr <= s_prime_adr + 1'd1;
                dp0_write_data_a <= { 16{SRAM_read_data[15]}, SRAM_read_data };
                dp0_enable_a <= 1'b1;
            end else
                dp0_enable_a <= 1'b0;
                s_prime_adr <= 8'd0;
                sp_adrb <= 8'd0;
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
                    leadT <= leadT + 1'd1;
                end
                else if (leadT == 3'd2) begin
                    dp0_adr_a <= s_prime_adr;
                    s_prime_adr <= s_prime_adr + 1'd1;
                    dp0_adr_b <= sp_adrb;
                    sp_adrb <= sp_adrb + 1'd1;
                    dp0_enable_a <= 1'b0;
                    dp0_enable_b <= 1'b0;
                    
                    op1 <= dp0_read_data_a; //sign extend
                    op2 <= { 16{dp0_read_data_b[15]}, dp0_read_data_b };
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
                    op2 <= { 16{dp0_read_data_b[15]}, dp0_read_data_b };
                    c_pair <= c_pair_count; //sets op3 and op4 as values from the C matrix
                    c_pair_count <= c_pair_count + 1'd1;
                    
                    if(leadT == 3'd3) begin
                        t_aa <= prod1[23:8];
                        t_ab <= prod2[23:8];
                        t_ba <= prod3[23:8];
                        t_bb <= prod4[23:8];
                    end
                    else begin
                        t_aa <= t_aa + signed(prod1[23:8]);
                        t_ab <= t_ab + siprod2[23:8];
                        t_ba <= t_ba + prod3[23:8];
                        t_bb <= t_bb + prod4[23:8];
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
                else if (!T_end) begin
                    if (|stage_a) begin
                        t_aa <= t_aa + prod1[23:8];
                        t_ab <= t_ab + prod2[23:8];
                        t_ba <= t_ba + prod3[23:8];
                        t_bb <= t_bb + prod4[23:8];
                                                
                        dp0_adr_a <= s_prime_adr;
                        s_prime_adr <= s_prime_adr + 1'd1;
                        dp0_adr_b <= sp_adrb;
                        sp_adrb <= sp_adrb + 1'd1;
                        dp0_enable_a <= 1'b0;
                        dp0_enable_b <= 1'b0;

                        op1 <= dp0_read_data_a;
                        op2 <= { 16{dp0_read_data_b[15]}, dp0_read_data_b };
                        c_pair <= c_pair_count; //sets op3 and op4 as values from the C matrix
                        c_pair_count <= c_pair_count + 1'd1;
                        
                        stage_a <= stage_a - 2'd1;
                    end
                    else if (|stage_b) begin
                        //accumulating the results of the previous cycle's multiplication
                        if(stage_b == 2'd3) begin
                            result_t_aa <= t_aa + prod1[23:8];
                            result_t_ab <= t_ab + prod2[23:8];
                            result_t_ba <= t_ba + prod3[23:8];
                            result_t_bb <= t_bb + prod4[23:8]; 
                        end
                        else if ((c_count_pair == 5'd1) || (c_count_pair == 5'd9) || (c_count_pair == 5'd17) || (c_count_pair == 5'd25)) begin
                            t_aa <= prod1[23:8];
                            t_ab <= prod2[23:8];
                            t_ba <= prod3[23:8];
                            t_bb <= prod4[23:8];
                        end
                        else begin
                            t_aa <= t_aa + prod1[23:8];
                            t_ab <= t_ab + prod2[23:8];
                            t_ba <= t_ba + prod3[23:8];
                            t_bb <= t_bb + prod4[23:8];
                        end 
                        
                        //reading s' values from dp-ram 0
                        dp0_adr_a <= s_prime_adr;
                        s_prime_adr <= s_prime_adr + 1'd1;
                        dp0_adr_b <= sp_adrb;
                        sp_adrb <= sp_adrb + 1'd1;
                        dp0_enable_a <= 1'b0;
                        dp0_enable_b <= 1'b0;
                        
                        //setting operands for the matrix multiplications
                        op1 <= dp0_read_data_a;
                        op2 <= { 16{dp0_read_data_b[15]}, dp0_read_data_b };
                        c_pair <= c_pair_count; //sets op3 and op4 as values from the C matrix
                        c_pair_count <= c_pair_count + 1'd1;
                        
                        //writing the 4 T values into dp-ram 1
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
                        if (stage_b == 2'd1) begin
                            dp1_adr_a <= ta_adr;
                            dp1_adr_b <= tb_adr;
                            dp1_write_data_a <= result_t_ab;
                            dp1_write_data_b <= result_t_bb;
                            dp1_enable_a <= 1'b1;
                            dp1_enable_b <= 1'b1;
                            
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
                    else begin //stage_c
                        
                        //accumulating the results of the previous cycle's multiplication
                            t_aa <= t_aa + prod1[23:8];
                            t_ab <= t_ab + prod2[23:8];
                            t_ba <= t_ba + prod3[23:8];
                            t_bb <= t_bb + prod4[23:8];
                        
                        //setting operands for the matrix multiplications
                        op1 <= dp0_read_data_a;
                        op2 <= { 16{dp0_read_data_b[15]}, dp0_read_data_b };
                        c_pair <= c_pair_count; //sets op3 and op4 as values from the C matrix
                        c_pair_count <= c_pair_count + 1'd1;
                        
                        // reading s' values 
                        if (stage_c == 2'd1) begin //last read of the current set of 4 multiplications
                            dp0_adr_a <= s_prime_adr;
                            dp0_adr_b <= sp_adrb;
                            dp0_enable_a <= 1'b0;
                            dp0_enable_b <= 1'b0;
                            
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
                end else begin //T_end
                    if (|compute_end) begin
                        t_aa <= t_aa + prod1[23:8];
                        t_ab <= t_ab + prod2[23:8];
                        t_ba <= t_ba + prod3[23:8];
                        t_bb <= t_bb + prod4[23:8];
                        
                        //setting operands for the matrix multiplications
                        op1 <= dp0_read_data_a;
                        op2 <= { 16{dp0_read_data_b[15]}, dp0_read_data_b };
                        c_pair <= c_pair_count; //sets op3 and op4 as values from the C matrix
                        c_pair_count <= c_pair_count + 1'd1;
                    end else if (last_multiplication) begin
                        last_multiplication <= 1'b0;
                        t_aa <= t_aa + prod1[23:8];
                        t_ab <= t_ab + prod2[23:8];
                        t_ba <= t_ba + prod3[23:8];
                        t_bb <= t_bb + prod4[23:8];
                    end else if (tb_adr == 6'd62) begin
                        dp1_adr_a <= ta_adr;
                        dp1_adr_b <= tb_adr;
                        dp1_write_data_a <= result_t_aa;
                        dp1_write_data_b <= result_t_ba;
                        dp1_enable_a <= 1'b1;
                        dp1_enable_b <= 1'b1;
                        ta_adr <= ta_adr + 1'd1;
                        tb_adr <= tb_adr + 1'd1;
                    end else begin
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
        end //end compute_in
        
        S_compute_out1: begin
            dp1_adr_a <= s_adr;
            s_adr <= s_adr + 1'd1;
            dp1_adr_b <= s_adrb;
            s_adrb <= s_adrb + 1'd1;
            dp1_enable_a <= 1'b0;
            dp1_enable_b <= 1'b0;
            if (out1_first) begin
                out1_first <= 1'b0;
            end else begin
              m2_state <= S_compute_out2;  
        end
        
        S_compute_out2: begin
            if (out2 == 3'd0) begin
                dp1_adr_a <= s_adr;
                s_adr <= s_adr + 1'd1;
                dp1_adr_b <= s_adrb;
                s_adrb <= s_adrb + 1'd1;
                dp1_enable_a <= 1'b0;
                dp1_enable_b <= 1'b0;

                op1 <=  {16{dp1_read_data_a[15]},dp1_read_data_a};
                op2 <= { 16{dp1_read_data_b[15]}, dp1_read_data_b };
                c_pair <= c_pair_count; //sets op3 and op4 as values from the C matrix
                transpose_pair_count <= trasnpose_pair_count + 1'd1;
                out2 <= out2 + 1'd1;
            end
        end
            
        
        endcase
    
    end
end
endmodule