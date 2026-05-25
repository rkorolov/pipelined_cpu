`timescale 1ns/10ps

/*
    Dynamically predicts whether a branch will be taken or not. Prediction must be wrong 
    twice in a row to change the prediction. 

    2 bit predictor has 4 stages:
    - Taken (correct) -        T0
    - Taken (wrong once) -     T1 
    - Not Taken (correct) -    NT0
    - Not Taken (wrong once) - NT1

    Output: (1) - branch taken, (0) branch not taken
*/
module branch_predictor(
    input logic clk,
    input logic reset,
    input logic in,
    input logic enable,
    output logic out
    );

    enum { T0, T1, NT0, NT1} ps, ns;
    
    // next state logic
    always_comb begin
        case (ps)
            T0:  if (in) ns = T0;
                    else ns = T1;
            T1:  if (in) ns = T0;
                    else ns = NT0;
            NT0: if (in) ns = NT1;
                    else ns = NT0;
            NT1: if (in) ns = T0;
                    else ns = NT0;
        endcase
    end

    // output logic 
    always_comb begin
        case (ps)   
            T0, T1:   out = 1'b1;
            NT0, NT1: out = 1'b0;
        endcase
    end

    // update
    always_ff @(posedge clk or posedge reset) begin 
        if (reset)
            ps <= T0;   // based on branches mainly being usedin  loops, so common case is not taken
        else if (enable) // only for switch states based on branch instr
            ps <= ns;
    end
endmodule