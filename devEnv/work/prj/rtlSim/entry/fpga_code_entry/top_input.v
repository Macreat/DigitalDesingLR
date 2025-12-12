`timescale 1ns/1ps
// ----------------------------------------------------------------------
// top_input.v
// Integra: UART receiver → decoder → register_bank.
// Expone los parámetros escalados a su rango final.
// ----------------------------------------------------------------------

`include "uart_receiver.v"
`include "uart_packet_decoder.v"
`include "register_bank.v"

module top_input(
    input wire clk,
    input wire rstn,
    input wire uart_rx,

    // Salidas crudas de los registros
    output wire [6:0] R0,
    output wire [6:0] R1,
    output wire [6:0] R2,
    output wire [6:0] R3,
    output wire [6:0] R4,
    output wire [6:0] R5,
    output wire [6:0] R6,
    output wire [6:0] R7,
    output wire [6:0] R8,

    // Parámetros escalados
    output wire [15:0] fm,      // 0 – 435 Hz
    output wire [15:0] fc,      // 435 – 7000 Hz
    output wire [15:0] beta,    // 0 – 100
    output wire [15:0] decay,   // 0 – 15
    output wire [15:0] gain,    // 0 – 15
    output wire [7:0] b1,       // 0 – 127
    output wire [7:0] b2,
    output wire [7:0] b3,
    output wire [7:0] b4
);

    wire rx_done;
    wire [7:0] rx_data;

    wire [3:0] index;
    wire [6:0] value;
    wire packet_ready;
    wire error;

    // ---------------------------
    // Instancias
    // ---------------------------
    uart_receiver UART(
        .clk(clk),
        .rstn(rstn),
        .uart_rx(uart_rx),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );

    uart_packet_decoder DEC(
        .clk(clk),
        .rstn(rstn),
        .rx_done(rx_done),
        .rx_data(rx_data),
        .index(index),
        .value(value),
        .packet_ready(packet_ready),
        .error(error)
    );

    reg [6:0] R[0:8];

    register_bank REG(
        .clk(clk),
        .rstn(rstn),
        .packet_ready(packet_ready),
        .index(index),
        .value(value),
        .R(R)
    );

    // ---------------------------
    // Salidas crudas
    // ---------------------------
    assign R0 = R[0];
    assign R1 = R[1];
    assign R2 = R[2];
    assign R3 = R[3];
    assign R4 = R[4];
    assign R5 = R[5];
    assign R6 = R[6];
    assign R7 = R[7];
    assign R8 = R[8];

    // ---------------------------
    // Parámetros escalados
    // ---------------------------

    assign fm    = (R[0] * 435) / 127;
    assign fc    = 435 + (R[1] * (7000 - 435)) / 127;
    assign beta  = (R[2] * 100) / 127;
    assign decay = (R[3] * 15) / 127;
    assign gain  = (R[4] * 15) / 127;

    assign b1 = R[5];
    assign b2 = R[6];
    assign b3 = R[7];
    assign b4 = R[8];

endmodule
