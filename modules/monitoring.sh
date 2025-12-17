#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/.local/bin" "$HOME/.local/state/healthcheck"
cat > "$HOME/.local/bin/dev-healthcheck" <<'EOT'
#!/usr/bin/env bash
set -euo pipefail
OUT_DIR="$HOME/.local/state/healthcheck"
mkdir -p "$OUT_DIR"
TS="$(date +%F_%H-%M-%S)"
OUT="$OUT_DIR/health_${TS}.txt"
{
  echo "=== DEV HEALTHCHECK $TS ==="
  uname -a
  df -h /
  command -v docker >/dev/null 2>&1 && docker ps || true
  command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi || true
} | tee "$OUT"
echo "Wrote $OUT"
EOT
chmod +x "$HOME/.local/bin/dev-healthcheck"
