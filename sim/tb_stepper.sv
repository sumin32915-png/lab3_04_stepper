`timescale 1ns/1ps
module tb_stepper;
reg clk_50mhz=0, rst_p=1, enable=0, direction=0;
wire [3:0] stepmotor;
integer checks=0;

always #10 clk_50mhz=~clk_50mhz;

// 시뮬레이션 가속을 위한 파라미터 설정 (CLK_HZ=8, STEP_HZ=2)
lab3_stepper #(.CLK_HZ(8), .STEP_HZ(2)) dut (
    .clk_50mhz(clk_50mhz),
    .rst_p(rst_p),
    .enable(enable),
    .direction(direction),
    .stepmotor(stepmotor)
);

task check_value(input [3:0] value);
    begin
        #1;
        if(stepmotor !== value) $fatal(1, "got=%b expected=%b", stepmotor, value);
        checks++;
    end
endtask

initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_stepper);
    
    // 1. 리셋 및 초기 상태 확인
    repeat(2) @(posedge clk_50mhz);
    rst_p = 0;
    check_value(4'b0011);

    // 2. 정방향 한 주기 테스트 (state 0 -> 1 -> 2 -> 3 -> 0)
    enable = 1;
    wait(dut.enable_sync);
    wait(dut.state == 1); check_value(4'b0110);
    wait(dut.state == 2); check_value(4'b1100);
    wait(dut.state == 3); check_value(4'b1001);
    wait(dut.state == 0); check_value(4'b0011);

    // 3. 역방향 두 단계 테스트 (direction=1 시 state가 감소함)
    direction = 1;
    wait(dut.direction_sync);
    wait(dut.state == 3); check_value(4'b1001);
    wait(dut.state == 2); check_value(4'b1100);

    // 4. Enable=0 유지 테스트
    enable = 0;
    wait(!dut.enable_sync);
    repeat(12) @(posedge clk_50mhz);
    check_value(4'b1100); // 마지막 상태 유지 확인 (패턴은 state에 따라 결정되나 enable=0시엔 로직에 따라 다름)
    // *문서상 로직상 enable=0이면 count만 0으로 초기화됨. 
    // 출력 패턴은 state에 따라 결정되므로, 마지막 state인 2의 값(1100)을 확인하는 것으로 설계됨.

    $display("LAB3_STEPPER_PASS checks=%0d", checks);
    $finish;
end

initial begin
    #5000;
    $fatal(1, "timeout");
end

endmodule
