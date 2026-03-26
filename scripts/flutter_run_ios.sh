#!/usr/bin/env bash
# iOS シミュレータで VM Service が「Connection reset by peer」になる場合の回避用。
# DDS を無効化するとホットリロードは制限されることがありますが、接続は安定しやすいです。
set -euo pipefail
cd "$(dirname "$0")/.."
exec flutter run -d ios "$@" --no-dds
