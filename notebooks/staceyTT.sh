#!/usr/bin/env sh
set -e

# ========= 可调参数 =========
AUDIO_DIR_DEFAULT="/Users/sagawithme/Downloads/HOFV 名人堂项目维权/tt/audio"
AUDIO_DIR="${1:-$AUDIO_DIR_DEFAULT}"

MODEL_DIR="$HOME/Documents/whispermodels"

PARALLEL_JOBS=6     # 同时处理几个文件（如未安装 parallel 会自动顺序处理）
WHISPER_THREADS=8   # -t
WHISPER_PROCS=3     # -p
WHISPER_QUIET="--no-prints"
# ===========================

trap 'echo; echo "⛔ 中断"; exit 130' INT

# 路径检查
if [ ! -d "$AUDIO_DIR" ]; then
  echo "❌ 音频目录不存在：$AUDIO_DIR"
  exit 1
fi
# 规范化父目录与输出目录
PARENT_DIR=$(cd "$AUDIO_DIR/.." && pwd)
OUT_DIR="$PARENT_DIR/txt"
mkdir -p "$OUT_DIR"

# 可执行程序检查
if ! command -v whisper-cli >/dev/null 2>&1; then
  echo "❌ 未找到 whisper-cli。请先：brew install whisper-cpp"
  exit 1
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ℹ 未检测到 ffmpeg（建议安装以支持更多格式）：brew install ffmpeg"
fi

# 选择模型（优先 turbo，回退 small）
if [ -f "$MODEL_DIR/ggml-large-v3-turbo.bin" ]; then
  MODEL="$MODEL_DIR/ggml-large-v3-turbo.bin"
elif [ -f "$MODEL_DIR/ggml-small.bin" ]; then
  MODEL="$MODEL_DIR/ggml-small.bin"
else
  cat <<EOF
❌ 未找到模型：
  $MODEL_DIR/ggml-large-v3-turbo.bin 或 $MODEL_DIR/ggml-small.bin
请先下载其一：
  curl -L -o "$MODEL_DIR/ggml-large-v3-turbo.bin" https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin
或：
  curl -L -o "$MODEL_DIR/ggml-small.bin" https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin
EOF
  exit 1
fi

echo "▶ 使用模型: $MODEL"
echo "▶ 音频目录: $AUDIO_DIR"
echo "▶ 输出目录: $OUT_DIR"
echo "▶ 并发设置: parallel=$PARALLEL_JOBS, -t $WHISPER_THREADS, -p $WHISPER_PROCS"
echo

# 统计 wav 文件数
COUNT=$(find "$AUDIO_DIR" -type f -iname "*.wav" | wc -l | tr -d '[:space:]')
if [ "$COUNT" -eq 0 ]; then
  echo "⚠ 未找到 wav 文件：$AUDIO_DIR"
  exit 0
fi
echo "🗂 需处理文件数：$COUNT"

# 执行转写
if command -v parallel >/dev/null 2>&1; then
  echo "▶ 启用 GNU parallel 并行处理 ..."
  export MODEL OUT_DIR WHISPER_THREADS WHISPER_PROCS WHISPER_QUIET
  # {/.} = 去扩展名的文件名；-print0 可处理空格/中文路径
  find "$AUDIO_DIR" -type f -iname "*.wav" -print0 \
  | parallel --bar -0 -P "$PARALLEL_JOBS" '
      whisper-cli -m "$MODEL" -l en -t "$WHISPER_THREADS" -p "$WHISPER_PROCS" -otxt \
        $WHISPER_QUIET \
        -of "$OUT_DIR/{/.}" "{}" 1>/dev/null
    '
else
  echo "ℹ 未检测到 GNU parallel，顺序处理（可安装：brew install parallel）"
  # 用 -print0 + while read -r -d '' 兼容空格/中文
  find "$AUDIO_DIR" -type f -iname "*.wav" -print0 \
  | while IFS= read -r -d '' f; do
      base=$(basename "$f"); name=${base%.*}
      echo "  - 转写: $base"
      whisper-cli -m "$MODEL" -l en -t "$WHISPER_THREADS" -p "$WHISPER_PROCS" -otxt \
        $WHISPER_QUIET \
        -of "$OUT_DIR/$name" "$f" 1>/dev/null
    done
fi

# 合并英文
COMBINED_EN="$OUT_DIR/all_transcripts_en.txt"
: > "$COMBINED_EN"
echo "▶ 合并英文到：$COMBINED_EN"
# 按文件名排序合并；排除已有合并文件
find "$OUT_DIR" -type f -name "*.txt" ! -name "all_transcripts_*.txt" -print0 \
| sort -z \
| while IFS= read -r -d '' tf; do
    b=$(basename "$tf")
    { echo "===== $b ====="; cat "$tf"; echo; echo; } >> "$COMBINED_EN"
  done

# 翻译 EN->ZH（离线 Argos Translate）
COMBINED_ZH="$OUT_DIR/all_transcripts_zh.txt"
echo "▶ 准备离线翻译 EN→ZH 到：$COMBINED_ZH（首次会自动安装/下载模型）"
PY=$(command -v python3 || true)
if [ -z "$PY" ]; then
  echo "❌ 未找到 python3，请先安装（如：brew install python）"
  exit 1
fi

INP="$COMBINED_EN" OUTP="$COMBINED_ZH" "$PY" - <<'PYCODE'
import sys, os, subprocess
def ensure_pkg():
    try:
        import argostranslate.package, argostranslate.translate  # noqa
    except Exception:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-U", "argostranslate"])
ensure_pkg()

import argostranslate.package as pkg, argostranslate.translate as tr
pkg.update_package_index()
cand = [p for p in pkg.get_available_packages() if p.from_code=="en" and p.to_code=="zh"]
if not cand:
    print("❌ Argos 索引中未找到 en→zh 模型", file=sys.stderr); sys.exit(1)
p = sorted(cand, key=lambda x: x.size_in_bytes)[-1]
pkg.install_from_path(p.download())

inp = os.environ["INP"]; outp = os.environ["OUTP"]
with open(inp, "r", encoding="utf-8") as f: text = f.read()
translated = tr.translate(text, "en", "zh")
with open(outp, "w", encoding="utf-8") as f: f.write(translated)
print("✅ 翻译完成：", outp)
PYCODE

echo
echo "🎉 全流程完成："
echo "  - 单文件转写：$OUT_DIR/<每个音频同名>.txt"
echo "  - 合并英文：$COMBINED_EN"
echo "  - 中文翻译：$COMBINED_ZH"
