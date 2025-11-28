`timescale 1ns / 1ps

module tb_sine_wave_ob;
    // Parámetros del testbench
    parameter TABLE_BITS = 6;
    parameter AMP_BITS = 16;
    parameter INDEX_BITS = 18;
    parameter CLK_PERIOD = 10; // 100 MHz
    
    // Señales del DUT
    reg clk;
    reg rst;
    reg [INDEX_BITS-1:0] step;
    wire signed [AMP_BITS-1:0] sine_out;
    
    // Instancia del DUT
    sine_wave_ob #(
        .TABLE_BITS(TABLE_BITS),
        .AMP_BITS(AMP_BITS),
        .INDEX_BITS(INDEX_BITS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .step(step),
        .sine_out(sine_out)
    );
    
    // Generación de reloj
    always #(CLK_PERIOD/2) clk = ~clk;
    
    // Contador para aumentar progresivamente el step
    reg [31:0] time_counter;
    reg [INDEX_BITS-1:0] step_counter;
    
    // Test sequence - UNA SOLA SIMULACIÓN CON FRECUENCIA PROGRESIVA
    initial begin
        // Inicializar señales
        clk = 0;
        rst = 1;
        step = 1;  // Empezar con frecuencia mínima
        time_counter = 0;
        step_counter = 0;
        
        // Generación de archivo VCD
        $dumpfile("sine_wave.vcd");
        $dumpvars(0, tb_sine_wave_ob);
        
        $display("=== Iniciando simulación con aumento progresivo de frecuencia ===");
        
        // Reset inicial
        #100;
        rst = 0;
        #100;
        
        // Ejecutar simulación por tiempo suficiente
        #2000000; // 2ms de simulación
        
        $display("=== Simulación completada ===");
        $display("Step final: %d", step);
        $finish;
    end
    
    // Contador que aumenta el step progresivamente como una perilla
    always @(posedge clk) begin
        if (rst) begin
            time_counter <= 0;
            step_counter <= 0;
            step <= 1;
        end else begin
            time_counter <= time_counter + 1;
            
            // Aumentar el step cada 5000 ciclos (como girar una perilla)
            if (time_counter >= 5000) begin
                time_counter <= 0;
                step_counter <= step_counter + 1;
                
                // Aumento progresivo del step (frecuencia)
                if (step_counter < 10) begin
                    // Fase inicial: aumento exponencial rápido
                    step <= 1 << step_counter; // 1, 2, 4, 8, 16, 32, 64, 128, 256, 512
                end else if (step_counter < 50) begin
                    // Fase media: aumento lineal
                    step <= 512 + (step_counter - 10) * 100;
                end else begin
                    // Fase final: aumento más lento pero continuo
                    step <= 5120 + (step_counter - 50) * 50;
                end
                
                // Limitar step máximo para evitar desbordamientos
                if (step > 20000) begin
                    step <= 20000;
                end
                
                // Mostrar progreso cada 10 cambios
                if (step_counter % 10 == 0) begin
                    $display("T=%0t ns: step=%d, frecuencia aumentando...", $time, step);
                end
            end
        end
    end
    
    // Monitoreo de continuidad
    reg signed [AMP_BITS-1:0] prev_sine_out = 0;
    integer discontinuity_count = 0;
    
    always @(posedge clk) begin
        if (!rst) begin
            // Detectar discontinuidades grandes (posibles reinicios)
            if (prev_sine_out != 0 && sine_out != 0) begin
                integer diff;
                if (sine_out > prev_sine_out)
                    diff = sine_out - prev_sine_out;
                else
                    diff = prev_sine_out - sine_out;
                
                // Si hay un salto muy grande, podría indicar un reinicio
                if (diff > 30000) begin
                    discontinuity_count <= discontinuity_count + 1;
                    $display("Advertencia: Posible discontinuidad en t=%0t ns", $time);
                end
            end
            prev_sine_out <= sine_out;
        end
    end
    
endmodule
