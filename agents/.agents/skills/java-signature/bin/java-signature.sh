#!/usr/bin/env bash
set -euo pipefail

CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/java-signature"

PROJECT=""
REFRESH=0
CP_FULL=""
CP_JARS=""
PROJ_HASH=""
JAR_HASH=""
JAR_LISTING=""

usage() {
  cat <<EOF
java-signature — Inspect Maven dependency signatures with cached results

Usage:
  java-signature class <class-name> [--project <dir>] [--refresh]
  java-signature find <regex> [--project <dir>] [--refresh]
  java-signature list [--project <dir>] [--refresh]
  java-signature --help

Commands:
  class   Print public members and descriptors using javap -public -s.
  find    Search dependency class names with a case-insensitive regex.
  list    Print dependency jar paths.

Options:
  --project  Maven project directory (default: working directory).
  --refresh  Rebuild the selected project's dependency classpath with Maven.

Run the absolute script path from the project directory and pass --project.
Only dependency jars are inspected; target/classes is never added or used as a fallback.
No jar extraction is needed. Results go to stdout; diagnostics to stderr.
Failures return a nonzero exit status.

Cache (under \${XDG_CACHE_HOME:-\$HOME/.cache}/java-signature):
  Classpath: projects/<canonical-path-hash>/<pom-hash>/classpath.txt
  Listings:  jars/<jar-md5>/listing.txt
  Signatures: jars/<jar-md5>/signatures-public-v1/<class-name>.javap
Changes to the selected pom.xml or jar contents invalidate their caches.
Parent POMs, other modules, Maven settings/profiles, environment, and repository
updates are not tracked automatically. Use --refresh after those changes.
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
  die "$tool not found; install a JDK or set JAVA_HOME"
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
  die "mvn not found; install Maven or set MAVEN_HOME"
}

resolve_classpath() {
  local pom="$PROJECT/pom.xml"
  [[ -f "$pom" ]] || die "pom.xml not found: $pom; point --project to a Maven project directory"
  PROJ_HASH="$(md5_of "$pom")"
  local path_hash
  path_hash="$(printf '%s' "$PROJECT" | md5_of /dev/stdin)"
  local cache="$CACHE_ROOT/projects/$path_hash/$PROJ_HASH/classpath.txt"
  local dep_cp
  if [[ "$REFRESH" == 1 || ! -f "$cache" || "$pom" -nt "$cache" ]]; then
    mkdir -p "$(dirname "$cache")"
    local mvn_bin
    mvn_bin="$(require_mvn)"
    rm -f "$cache"
    echo "info: Resolving dependency classpath with Maven..." >&2
    if ! (cd "$PROJECT" && "$mvn_bin" -q dependency:build-classpath \
        -Dmdep.outputFile="$cache" -Dmdep.pathSeparator=":" >/dev/null); then
      rm -f "$cache"
      die "mvn dependency:build-classpath failed: $PROJECT"
    fi
  fi
  dep_cp="$(cat "$cache")"
  CP_FULL="$dep_cp"
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
    --refresh) REFRESH=1; shift ;;
    --project|-p)
      [[ $# -ge 2 ]] || die "$1 requires a <dir> argument"
      PROJECT="$2"
      shift 2
      ;;
    *) POS+=("$1"); shift ;;
  esac
done

[[ -z "$PROJECT" ]] && PROJECT="$PWD"
PROJECT="$(cd "$PROJECT" && pwd -P)"

cmd="${POS[0]:-list}"
[[ -n "$cmd" ]] || cmd="list"

case "$cmd" in
  list)
    resolve_classpath
    echo "$CP_JARS"
    ;;
  find)
    pattern="${POS[1]:-}"
    [[ -n "$pattern" ]] || die "find requires a <pattern> argument"
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
    [[ -n "$cls" ]] || die "class requires a <class-name> argument"
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
    [[ -n "$cache_dir" ]] || die "Class not found in Maven dependencies (use find to search): $cls"
    out="$cache_dir/signatures-public-v1/${cls}.javap"
    if [[ ! -f "$out" ]]; then
      mkdir -p "$(dirname "$out")"
      jp="$(require_jdk_tool javap)"
      if ! "$jp" -public -s -classpath "$CP_FULL" "$cls" > "$out" 2> "$cache_dir/javap.err"; then
        rm -f "$out"
        cat "$cache_dir/javap.err" >&2
        die "javap failed; check the class name with find: $cls"
      fi
    fi
    cat "$out"
    ;;
  *)
    die "Unknown command: $cmd (see --help)"
    ;;
esac
