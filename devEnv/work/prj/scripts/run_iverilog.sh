#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TB_PATH="${1:-tb/nexys_audio_top_tb.v}"

cd "$ROOT_DIR"
make run TB="$TB_PATH"
