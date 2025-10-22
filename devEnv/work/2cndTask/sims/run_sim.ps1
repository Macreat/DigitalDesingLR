Param()
$here = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $here
if (!(Test-Path build)) { New-Item -ItemType Directory -Path build | Out-Null }
Write-Host "Compiling testbench..."
iverilog -g2001 -Wall -s up_counter_4bit_tb -o build/simv ../tb/up_counter_4bit_tb.v ../src/up_counter.v ../src/freq_divider.v ../src/top.v
if ($LASTEXITCODE -ne 0) { Write-Error "iverilog failed"; exit 1 }
Write-Host "Running simulation..."
vvp build/simv
Write-Host "Simulation complete; check up_counter_tb.vcd"
