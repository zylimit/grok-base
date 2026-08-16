#!/usr/bin/env bash
# Codebase statistics skeleton for docs/CODEMAP.md (repo-navigator skill).
# Prints a markdown skeleton to stdout: per-directory file/LOC stats + language histogram.
# Usage: bash .grok/scripts/codemap.sh [project-root] [depth (default 2)]
set -u

ROOT=${1:-.}
DEPTH=${2:-2}
cd "$ROOT" || { echo "codemap: bad root: $ROOT" >&2; exit 1; }

FILELIST=$(mktemp) || exit 1
COUNTS=$(mktemp) || exit 1
trap 'rm -f "$FILELIST" "$COUNTS"' EXIT

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git ls-files --cached --others --exclude-standard >"$FILELIST"
else
  find . -type f -not -path './.git/*' -not -path './node_modules/*' \
    -not -path './target/*' -not -path './dist/*' -not -path './.venv/*' \
    | sed 's|^\./||' >"$FILELIST"
fi

TOTAL_FILES=$(wc -l <"$FILELIST" | tr -d ' ')

# One pass: per-file line counts ("<lines> <path>"), robust to spaces via -0.
tr '\n' '\0' <"$FILELIST" | xargs -0 -r wc -l 2>/dev/null | awk '$2 != "total"' >"$COUNTS"

echo "# CODEMAP 统计骨架（$(date +%F) 生成，请合入 docs/CODEMAP.md）"
echo ""
echo "总文件数（受版本管理）：$TOTAL_FILES"
echo ""
echo "## 目录统计（前 ${DEPTH} 层，按行数降序，Top 40）"
echo ""
echo "| 目录 | 文件数 | 行数 |"
echo "|---|---|---|"

awk -v d="$DEPTH" '
{
  lines = $1
  path = $0
  sub(/^[[:space:]]*[0-9]+[[:space:]]+/, "", path)
  n = split(path, seg, "/")
  if (n == 1) key = "(root)"
  else {
    lim = (n - 1 < d) ? n - 1 : d
    key = seg[1]
    for (i = 2; i <= lim; i++) key = key "/" seg[i]
  }
  fcount[key]++
  lcount[key] += lines
}
END {
  for (k in fcount) printf "%d\t%s\t%d\n", lcount[k], k, fcount[k]
}
' "$COUNTS" | sort -rn | head -40 | awk -F'\t' '{ printf "| %s/ | %s | %s |\n", $2, $3, $1 }'

echo ""
echo "## 语言分布（按扩展名，Top 12）"
echo ""
echo "| 扩展名 | 文件数 |"
echo "|---|---|"
sed -n 's/.*\.\([A-Za-z0-9_]\{1,8\}\)$/\1/p' "$FILELIST" | sort | uniq -c | sort -rn | head -12 \
  | awk '{ printf "| .%s | %s |\n", $2, $1 }'

echo ""
echo "## 待人工补全"
echo ""
echo "- 各模块职责一句话（派 explore 子代理分片勘察）"
echo "- 快速入口（启动/配置/构建/测试命令）"
echo "- 禁区与陷阱"
