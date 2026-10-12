#!/usr/bin/env bash
set -euo pipefail

CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/java-signature"

PROJECT=""
CP_FULL=""
CP_JARS=""
PROJ_HASH=""
JAR_HASH=""
JAR_LISTING=""

usage() {
  cat <<EOF
java-signature — 查看 Maven 依赖类的方法签名/类结构，全流程按内容 hash 缓存

用法:
  java-signature class <class-name> [--project <dir>]   javap 输出类结构/方法签名
  java-signature find <regex> [--project <dir>]         在全部依赖 jar 中按正则搜类名
  java-signature list [--project <dir>]                 列出全部依赖 jar 路径
  java-signature --help                                 显示本帮助

说明:
  agent 无需关心具体 jar，只需给类全名和项目根目录，脚本自动:
    1. 解析项目 Maven 依赖 classpath（首次跑 mvn，之后缓存）
    2. 用 javap -classpath 直接反编译目标类，零解压
  --project 缺省为当前工作目录

缓存:
  依赖 classpath : \${CACHE_ROOT}/projects/<pom-hash>/classpath.txt
  每个 jar 清单  : \${CACHE_ROOT}/jars/<jar-md5>/listing.txt
  javap 输出     : \${CACHE_ROOT}/jars/<jar-md5>/signatures/<class-name>.javap
  jar 内容变化自动失效；pom 变化自动重跑 mvn
EOF
}

die() { echo "error: $*" >&2; exit 1; }

md5_of() {
  local f="$1"
  if command -v md5 >/dev/null 2>&1; then
    md5 -q "$f"
  else
    md5sum "$f" | awk '{print $1}'
  fi
}

require_jdk_tool() {
  local tool="$1"
  if [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/$tool" ]]; then
    echo "$JAVA_HOME/bin/$tool"
    return
  fi
  if command -v "$tool" >/dev/null 2>&1; then
    command -v "$tool"
    return
  fi
  die "未找到 $tool，请安装 JDK 或设置 JAVA_HOME"
}

require_mvn() {
  if [[ -n "${MAVEN_HOME:-}" && -x "$MAVEN_HOME/bin/mvn" ]]; then
    echo "$MAVEN_HOME/bin/mvn"
    return
  fi
  if command -v mvn >/dev/null 2>&1; then
    command -v mvn
    return
  fi
  die "未找到 mvn，请安装 Maven"
}

resolve_classpath() {
  local pom="$PROJECT/pom.xml"
  [[ -f "$pom" ]] || die "未找到 pom.xml: $pom（--project 需指向 Maven 项目根）"
  PROJ_HASH="$(md5_of "$pom")"
  local cache="$CACHE_ROOT/projects/$PROJ_HASH/classpath.txt"
  local dep_cp
  if [[ ! -f "$cache" || "$pom" -nt "$cache" ]]; then
    mkdir -p "$(dirname "$cache")"
    local mvn_bin
    mvn_bin="$(require_mvn)"
    echo "info: 解析依赖 classpath（首次较慢，后续走缓存）..." >&2
    if ! (cd "$PROJECT" && "$mvn_bin" -q dependency:build-classpath \
        -Dmdep.outputFile="$cache" -Dmdep.pathSeparator=":" >/dev/null); then
      rm -f "$cache"
      die "mvn dependency:build-classpath 失败: $PROJECT"
    fi
  fi
  dep_cp="$(cat "$cache")"
  CP_FULL="$PROJECT/target/classes:${dep_cp}"
  CP_JARS="$(printf '%s' "$dep_cp" | tr ':' '\n' | grep '\.jar$' || true)"
}

ensure_jar_listing() {
  local jar_path="$1"
  local jar_bin
  JAR_HASH="$(md5_of "$jar_path")"
  JAR_LISTING="$CACHE_ROOT/jars/$JAR_HASH/listing.txt"
  if [[ -f "$JAR_LISTING" ]]; then
    return
  fi
  mkdir -p "$(dirname "$JAR_LISTING")"
  jar_bin="$(require_jdk_tool jar)"
  "$jar_bin" tf "$jar_path" > "$JAR_LISTING" 2>/dev/null || {
    rm -f "$JAR_LISTING"
    return 1
  }
}

POS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --project|-p)
      [[ $# -ge 2 ]] || die "$1 需要 <dir> 参数"
      PROJECT="$2"
      shift 2
      ;;
    *) POS+=("$1"); shift ;;
  esac
done

[[ -z "$PROJECT" ]] && PROJECT="$PWD"
PROJECT="$(cd "$PROJECT" && pwd)"

cmd="${POS[0]:-list}"
[[ -n "$cmd" ]] || cmd="list"

case "$cmd" in
  list)
    resolve_classpath
    echo "$CP_JARS"
    ;;
  find)
    pattern="${POS[1]:-}"
    [[ -n "$pattern" ]] || die "find 需要 <pattern> 参数"
    resolve_classpath
    j=""
    while IFS= read -r j; do
      [[ -n "$j" ]] || continue
      ensure_jar_listing "$j" || continue
      grep '\.class$' "$JAR_LISTING" \
        | sed -e 's/\.class$//' -e 's|/|.|g' \
        | grep -iE "$pattern" \
        | sed "s|^|$(basename "$j"): |"
    done <<< "$CP_JARS" || true
    ;;
  class)
    cls="${POS[1]:-}"
    [[ -n "$cls" ]] || die "class 需要 <class-name> 参数"
    cls="${cls%.class}"
    resolve_classpath
    class_entry="${cls//./\/}.class"
    cache_dir=""
    j=""
    while IFS= read -r j; do
      [[ -n "$j" ]] || continue
      ensure_jar_listing "$j" || continue
      if grep -qxF "$class_entry" "$JAR_LISTING"; then
        cache_dir="$CACHE_ROOT/jars/$JAR_HASH"
        break
      fi
    done <<< "$CP_JARS"
    if [[ -z "$cache_dir" ]]; then
      target_class="$PROJECT/target/classes/$class_entry"
      [[ -f "$target_class" ]] || die "未在 Maven 依赖中找到类（可用 find 搜索）: $cls"
      cache_dir="$CACHE_ROOT/classes/$(md5_of "$target_class")"
    fi
    out="$cache_dir/signatures/${cls}.javap"
    if [[ ! -f "$out" ]]; then
      mkdir -p "$(dirname "$out")"
      jp="$(require_jdk_tool javap)"
      if ! "$jp" -p -s -classpath "$CP_FULL" "$cls" > "$out" 2> "$cache_dir/javap.err"; then
        rm -f "$out"
        cat "$cache_dir/javap.err" >&2
        die "javap 失败，类名可能不对（可用 find 搜索）: $cls"
      fi
    fi
    cat "$out"
    ;;
  *)
    die "未知命令: $cmd（见 --help）"
    ;;
esac
