param(
    [string]$test = "all"
)

$ErrorActionPreference = "Stop"

# Directories (based on your structure)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$proj = Split-Path -Parent $root

$build = Join-Path $proj "build"
$logs  = Join-Path $proj "logs"
$waves = Join-Path $proj "waves"

# Ensure dirs exist
New-Item -ItemType Directory -Force -Path $build,$logs,$waves | Out-Null

# Tools
$iverilog = "iverilog"
$vvp      = "vvp"

# RTL + TB paths
$rtl = Join-Path $proj "rtl/src/"
$tb  = Join-Path $proj "rtl/tb/"

# Output VVP file
$out = Join-Path $build "tb_pwm_uart.vvp"

Write-Host "Compiling testbench: tb_pwm_uart.v"
& $iverilog -g2012 -Wall -I $rtl -o $out `
    (Join-Path $tb  "tb_pwm_uart.v") `
    (Join-Path $rtl "uart/uart_rx.v") `
    (Join-Path $rtl "uart/uart_tx.v") `
    (Join-Path $rtl "cmdParser/cmd_parser.v") `
    (Join-Path $rtl "pwm/pwm_core.v") `
    (Join-Path $rtl "pwm/pwm_divider.v") `
    (Join-Path $rtl "topModule/top_pwm_uart.v")

Write-Host "Compilation done."

# Run simulation
Write-Host "Running simulation..."
& $vvp $out | Tee-Object -FilePath (Join-Path $logs "sim.log")

# Move VCD to waves/
$vcdPath = Join-Path $waves "waves.vcd"
if (Test-Path "dump.vcd") {
    Move-Item -Force "dump.vcd" $vcdPath
    Write-Host "VCD waves moved to: $vcdPath"
} else {
    Write-Host "WARNING: Testbench did not generate dump.vcd"
}

Write-Host "Done."
Write-Host "Logs: $logs"
