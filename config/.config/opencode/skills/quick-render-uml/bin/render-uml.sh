#!/bin/zsh

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"
lib_dir="$skill_dir/lib"

command_name="$(basename "$0")"
format="svg"
preview="open"
engine="auto"
input_name="diagram"

usage() {
  print "Usage: $command_name <doctor|file|stdin|clipboard> [options]"
  print ""
  print "Commands:"
  print "  doctor"
  print "  file <diagram.puml>"
  print "  stdin"
  print "  clipboard"
  print ""
  print "Options:"
  print "  --svg                 Render SVG (default)"
  print "  --png                 Render PNG"
  print "  --open                Open result with macOS open (default)"
  print "  --no-open             Do not open result"
  print "  --engine <auto|jar|plantuml>"
  print "  --name <base-name>    Base file name for stdin/clipboard"
}

fail() {
  print -- "$1" >&2
  exit 1
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

resolve_jar() {
  setopt local_options null_glob
  local jars=("$lib_dir"/plantuml-*.jar(N))

  if (( ${#jars[@]} == 0 )); then
    return 1
  fi

  print -- "$jars[-1]"
}

resolve_engine() {
  case "$engine" in
    auto)
      if has_command java && resolve_jar >/dev/null 2>&1; then
        print -- "jar"
        return 0
      fi

      if has_command plantuml; then
        print -- "plantuml"
        return 0
      fi

      fail "No available PlantUML engine found. Install java with lib/plantuml-*.jar or install plantuml."
      ;;
    jar)
      has_command java || fail "java not found in PATH"
      resolve_jar >/dev/null 2>&1 || fail "No PlantUML jar found under lib/"
      print -- "jar"
      ;;
    plantuml)
      has_command plantuml || fail "plantuml not found in PATH"
      print -- "plantuml"
      ;;
    *)
      fail "Unsupported engine: $engine"
      ;;
  esac
}

resolve_temp_root() {
  local temp_root="${TMPDIR:-/tmp}"

  [[ -d "$temp_root" ]] || fail "Temporary directory is not available: $temp_root"
  print -- "$temp_root"
}

make_tmp_dir() {
  local temp_root
  temp_root="$(resolve_temp_root)"
  mktemp -d "${temp_root%/}/opencode-uml.XXXXXX"
}

format_flag() {
  case "$format" in
    svg)
      print -- "-tsvg"
      ;;
    png)
      print -- "-tpng"
      ;;
    *)
      fail "Unsupported format: $format"
      ;;
  esac
}

output_extension() {
  print -- "$format"
}

open_preview() {
  local output_path="$1"

  if [[ "$preview" == "open" ]]; then
    has_command open || fail "open not found in PATH"
    open "$output_path" >/dev/null 2>&1 &
  fi
}

render_with_jar() {
  local input_path="$1"
  local output_dir="$2"
  local jar_path
  jar_path="$(resolve_jar)"

  java -jar "$jar_path" "$(format_flag)" --output-dir "$output_dir" "$input_path"
}

render_with_plantuml() {
  local input_path="$1"
  local output_dir="$2"

  plantuml "$(format_flag)" --output-dir "$output_dir" "$input_path"
}

render_input_file() {
  local input_path="$1"
  local base_name="$2"
  local resolved_engine="$3"
  local tmp_dir output_path extension

  [[ -f "$input_path" ]] || fail "Input file not found: $input_path"

  tmp_dir="$(make_tmp_dir)"

  if [[ "$resolved_engine" == "jar" ]]; then
    render_with_jar "$input_path" "$tmp_dir"
  else
    render_with_plantuml "$input_path" "$tmp_dir"
  fi

  extension="$(output_extension)"
  output_path="$tmp_dir/$base_name.$extension"

  [[ -f "$output_path" ]] || fail "Render succeeded but output file not found: $output_path"

  open_preview "$output_path"
  print -- "$output_path"
}

parse_options() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --svg)
        format="svg"
        ;;
      --png)
        format="png"
        ;;
      --open)
        preview="open"
        ;;
      --no-open)
        preview="none"
        ;;
      --engine)
        shift
        [[ $# -gt 0 ]] || fail "Missing value for --engine"
        engine="$1"
        ;;
      --name)
        shift
        [[ $# -gt 0 ]] || fail "Missing value for --name"
        input_name="$1"
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        fail "Unknown option: $1"
        ;;
    esac
    shift
  done
}

run_doctor() {
  local jar_path="missing"
  local resolved_engine="unavailable"

  if resolve_jar >/dev/null 2>&1; then
    jar_path="$(resolve_jar)"
  fi

  if has_command java && [[ "$jar_path" != "missing" ]]; then
    resolved_engine="jar"
  elif has_command plantuml; then
    resolved_engine="plantuml"
  fi

  print -- "java: $(has_command java && print -- yes || print -- no)"
  print -- "open: $(has_command open && print -- yes || print -- no)"
  print -- "pbpaste: $(has_command pbpaste && print -- yes || print -- no)"
  print -- "plantuml: $(has_command plantuml && print -- yes || print -- no)"
  print -- "jar: $jar_path"
  print -- "auto-engine: $resolved_engine"

  [[ "$resolved_engine" != "unavailable" ]] || exit 1
}

render_file_command() {
  [[ $# -ge 1 ]] || fail "Usage: $command_name file <diagram.puml> [options]"

  local input_path="$1"
  shift

  parse_options "$@"

  local base_name resolved_engine
  base_name="$(basename "${input_path:r}")"
  resolved_engine="$(resolve_engine)"
  render_input_file "$input_path" "$base_name" "$resolved_engine"
}

render_stdin_command() {
  parse_options "$@"

  local resolved_engine tmp_dir input_path
  resolved_engine="$(resolve_engine)"
  tmp_dir="$(make_tmp_dir)"
  input_path="$tmp_dir/$input_name.puml"

  cat > "$input_path"
  [[ -s "$input_path" ]] || fail "No PlantUML content provided on stdin"

  render_input_file "$input_path" "$input_name" "$resolved_engine"
}

render_clipboard_command() {
  parse_options "$@"
  has_command pbpaste || fail "pbpaste not found in PATH"

  local resolved_engine tmp_dir input_path
  resolved_engine="$(resolve_engine)"
  tmp_dir="$(make_tmp_dir)"
  input_path="$tmp_dir/$input_name.puml"

  pbpaste > "$input_path"
  [[ -s "$input_path" ]] || fail "Clipboard does not contain PlantUML content"

  render_input_file "$input_path" "$input_name" "$resolved_engine"
}

main() {
  [[ $# -gt 0 ]] || {
    usage
    exit 1
  }

  local command="$1"
  shift

  case "$command" in
    doctor)
      parse_options "$@"
      run_doctor
      ;;
    file)
      render_file_command "$@"
      ;;
    stdin)
      render_stdin_command "$@"
      ;;
    clipboard)
      render_clipboard_command "$@"
      ;;
    --help|-h)
      usage
      ;;
    *)
      fail "Unknown command: $command"
      ;;
  esac
}

main "$@"
