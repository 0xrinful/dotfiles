#!/usr/bin/env bash
#|---/ /+--------------------------------------------------+---/ /|#
#|--/ /-| Simple Wallbash Template Parser                 |--/ /-|#
#|-/ /--| Parses .dcol templates and applies colors       |-/ /--|#
#|/ /---+--------------------------------------------------+/ /---|#

# Function to show usage
show_usage() {
  cat <<EOF
╔═══════════════════════════════════════════════════════════════════════════════╗
║                    Wallbash Template Parser v1.0                              ║
║          Extract and apply color palettes from images to configs              ║
╚═══════════════════════════════════════════════════════════════════════════════╝

USAGE:
    $(basename "$0") [OPTIONS] <dcol_file> [template_path]

ARGUMENTS:
    dcol_file       .dcol file with color definitions (from wallbash.sh)
    template_path   Single .dcol template OR directory (default: ~/.config/wallbash/)

OPTIONS:
    -h, --help      Show this help message
    -i, --invert    Invert colors (swap dark/light)
    -j, --jobs N    Parallel jobs (default: CPU cores)
    -s, --serial    Process one at a time
    -v, --verbose   Show detailed errors

═══════════════════════════════════════════════════════════════════════════════

TEMPLATE FORMAT:

    Line 1: <output_path>|<optional_command>
    Line 2+: Your config with color placeholders

Example (kitty.dcol):
    \$HOME/.config/kitty/colors.conf|pkill -USR1 kitty
    foreground #<wallbash_txt1>
    background #<wallbash_pry1>
    color0 #<wallbash_1xa5>

═══════════════════════════════════════════════════════════════════════════════

COLOR PLACEHOLDERS:

Basic:
    <wallbash_mode>              Color mode (dark/light)
    <wallbash_pry[1-4]>          4 primary colors (hex)
    <wallbash_txt[1-4]>          4 text colors (hex)
    <wallbash_[1-4]xa[1-9]>      Accent variations (xa1=dark, xa9=light)
    <<HOME>>                     Home directory

RGB/RGBA Formats:
    <wallbash_pry1_rgb>          Outputs: 48,32,98
    <wallbash_pry1_rgba>         Outputs: rgba(48,32,98,1)
    <wallbash_1xa5_rgb>          Outputs: 122,101,163
    <wallbash_1xa5_rgba>         Outputs: rgba(122,101,163,1)

Usage in templates:
    background: #<wallbash_pry1>;              → #302062
    background: rgb(<wallbash_pry1_rgb>);      → rgb(48,32,98)
    background: <wallbash_pry1_rgba>;          → rgba(48,32,98,1)
    transparent: rgba(<wallbash_pry1_rgb>,0.8); → rgba(48,32,98,0.8)

═══════════════════════════════════════════════════════════════════════════════

EXAMPLES:

Single file:
    $(basename "$0") colors.dcol ~/.config/wallbash/kitty.dcol

All templates in directory (recursive):
    $(basename "$0") colors.dcol ~/.config/wallbash/

With options:
    $(basename "$0") -v colors.dcol                    # Show errors
    $(basename "$0") -i colors.dcol                    # Invert colors
    $(basename "$0") -j 16 colors.dcol                 # 16 parallel jobs
    $(basename "$0") --serial --verbose colors.dcol    # Debug mode

═══════════════════════════════════════════════════════════════════════════════

WORKFLOW:

1. Generate colors from image:
   $ wallbash.sh wallpaper.jpg  →  Creates wallpaper.jpg.dcol

2. Create templates in ~/.config/wallbash/:
   kitty.dcol, waybar.dcol, rofi.dcol, etc.

3. Apply colors:
   $ $(basename "$0") wallpaper.jpg.dcol

═══════════════════════════════════════════════════════════════════════════════

MODES:

Single File:  Processes one specific template
Directory:    Finds and processes all .dcol templates recursively (faster!)

EOF
  exit 0
}

# Parse arguments
USE_INVERTED=false
PARALLEL_JOBS=$(nproc 2>/dev/null || echo 4)
USE_PARALLEL=true
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
  -h | --help)
    show_usage
    ;;
  -i | --invert)
    USE_INVERTED=true
    shift
    ;;
  -j | --jobs)
    PARALLEL_JOBS="$2"
    if ! [[ "$PARALLEL_JOBS" =~ ^[0-9]+$ ]] || [ "$PARALLEL_JOBS" -lt 1 ]; then
      echo "Error: Invalid number of jobs: $2"
      exit 1
    fi
    shift 2
    ;;
  -s | --serial)
    USE_PARALLEL=false
    shift
    ;;
  -v | --verbose)
    VERBOSE=true
    shift
    ;;
  -*)
    echo "Error: Unknown option $1"
    show_usage
    ;;
  *)
    break
    ;;
  esac
done

# Check arguments
if [ $# -lt 1 ]; then
  echo "Error: Missing dcol file argument"
  show_usage
fi

DCOL_FILE="$1"
TEMPLATE_PATH="${2:-$HOME/.config/wallbash}"

# Validate dcol file
if [ ! -f "${DCOL_FILE}" ]; then
  echo "Error: dcol file not found: ${DCOL_FILE}"
  exit 1
fi

# Source the dcol file to load color variables
# shellcheck disable=SC1090
source "${DCOL_FILE}"

# Set inverted mode variable
if [ "${dcol_mode}" == "dark" ]; then
  dcol_invt="light"
else
  dcol_invt="dark"
fi

# Function to convert RGBA to RGB
rgba_to_rgb() {
  local rgba="$1"
  echo "${rgba}" | sed -E 's/rgba\(([0-9]+,[0-9]+,[0-9]+),.*/\1/'
}

# Create RGB versions from RGBA if they exist
for i in {1..4}; do
  # Primary colors - fix RGBA format
  pry_rgba_var="dcol_pry${i}_rgba"
  if [ -n "${!pry_rgba_var:-}" ]; then
    # Replace \1 with 1 in RGBA values
    fixed_rgba="${!pry_rgba_var//\\1/1}"
    declare "dcol_pry${i}_rgba=${fixed_rgba}"
    declare "dcol_pry${i}_rgb=$(rgba_to_rgb "${fixed_rgba}")"
  fi

  # Text colors - fix RGBA format
  txt_rgba_var="dcol_txt${i}_rgba"
  if [ -n "${!txt_rgba_var:-}" ]; then
    # Replace \1 with 1 in RGBA values
    fixed_rgba="${!txt_rgba_var//\\1/1}"
    declare "dcol_txt${i}_rgba=${fixed_rgba}"
    declare "dcol_txt${i}_rgb=$(rgba_to_rgb "${fixed_rgba}")"
  fi

  # Accent colors - fix RGBA format
  for j in {1..9}; do
    xa_rgba_var="dcol_${i}xa${j}_rgba"
    if [ -n "${!xa_rgba_var:-}" ]; then
      # Replace \1 with 1 in RGBA values
      fixed_rgba="${!xa_rgba_var//\\1/1}"
      declare "dcol_${i}xa${j}_rgba=${fixed_rgba}"
      declare "dcol_${i}xa${j}_rgb=$(rgba_to_rgb "${fixed_rgba}")"
    fi
  done
done

# Function to create sed substitution script
create_sed_script() {
  local use_inverted=$1
  local sed_script=""

  # Add mode substitution
  if ${use_inverted}; then
    sed_script+="s|<wallbash_mode>|${dcol_invt}|g;"
  else
    sed_script+="s|<wallbash_mode>|${dcol_mode}|g;"
  fi

  # Add color substitutions
  for i in {1..4}; do
    # Determine source index (reversed if inverted)
    if ${use_inverted}; then
      src_i=$((5 - i))
    else
      src_i=$i
    fi

    # Primary colors
    pry_var="dcol_pry${src_i}"
    [ -n "${!pry_var:-}" ] && sed_script+="s|<wallbash_pry${i}>|${!pry_var}|g;"

    # Text colors
    txt_var="dcol_txt${src_i}"
    [ -n "${!txt_var:-}" ] && sed_script+="s|<wallbash_txt${i}>|${!txt_var}|g;"

    # RGBA versions
    pry_rgba_var="dcol_pry${src_i}_rgba"
    [ -n "${!pry_rgba_var:-}" ] && sed_script+="s|<wallbash_pry${i}_rgba>|${!pry_rgba_var}|g;"

    txt_rgba_var="dcol_txt${src_i}_rgba"
    [ -n "${!txt_rgba_var:-}" ] && sed_script+="s|<wallbash_txt${i}_rgba>|${!txt_rgba_var}|g;"

    # RGB versions
    pry_rgb_var="dcol_pry${src_i}_rgb"
    [ -n "${!pry_rgb_var:-}" ] && sed_script+="s|<wallbash_pry${i}_rgb>|${!pry_rgb_var}|g;"

    txt_rgb_var="dcol_txt${src_i}_rgb"
    [ -n "${!txt_rgb_var:-}" ] && sed_script+="s|<wallbash_txt${i}_rgb>|${!txt_rgb_var}|g;"

    # Accent colors
    for j in {1..9}; do
      xa_var="dcol_${src_i}xa${j}"
      [ -n "${!xa_var:-}" ] && sed_script+="s|<wallbash_${i}xa${j}>|${!xa_var}|g;"

      xa_rgba_var="dcol_${src_i}xa${j}_rgba"
      [ -n "${!xa_rgba_var:-}" ] && sed_script+="s|<wallbash_${i}xa${j}_rgba>|${!xa_rgba_var}|g;"

      xa_rgb_var="dcol_${src_i}xa${j}_rgb"
      [ -n "${!xa_rgb_var:-}" ] && sed_script+="s|<wallbash_${i}xa${j}_rgb>|${!xa_rgb_var}|g;"
    done
  done

  # Add home directory substitution
  sed_script+="s|<<HOME>>|\${HOME}|g"

  echo "${sed_script}"
}

# Function to process a single template
process_template() {
  template_file="$1"
  template_name=$(basename "${template_file}")

  # Read the first line to get output path and optional command
  first_line=$(head -1 "${template_file}")
  output_path=$(echo "${first_line}" | awk -F '|' '{print $1}')
  exec_command=$(echo "${first_line}" | awk -F '|' '{print $2}')

  # Expand variables in output path
  eval output_path="${output_path}"

  # Check if output directory exists
  output_dir=$(dirname "${output_path}")
  if [ ! -d "${output_dir}" ]; then
    if ${VERBOSE}; then
      echo "  ✗ ${template_name}: Output directory does not exist: ${output_dir}"
    fi
    return 1
  fi

  # Create temporary file
  temp_file=$(mktemp)

  # Copy template content (skip first line) and apply substitutions
  if ! sed '1d' "${template_file}" | sed "${SED_SCRIPT}" >"${temp_file}" 2>/dev/null; then
    if ${VERBOSE}; then
      echo "  ✗ ${template_name}: Failed to process template"
    fi
    rm -f "${temp_file}"
    return 1
  fi

  # Move to final destination
  if [ -s "${temp_file}" ]; then
    mv "${temp_file}" "${output_path}"
    echo "  ✓ ${template_name} → ${output_path}"

    # Execute optional command if provided
    if [ -n "${exec_command}" ]; then
      bash -c "${exec_command}" &>/dev/null &
    fi
  else
    if ${VERBOSE}; then
      echo "  ✗ ${template_name}: Generated file is empty"
    fi
    rm -f "${temp_file}"
    return 1
  fi

  return 0
}

# Create sed script once
SED_SCRIPT=$(create_sed_script ${USE_INVERTED})

# Export necessary variables and functions for parallel processing
export SED_SCRIPT VERBOSE
export -f process_template

# Determine if we're processing a file or directory
if [ -f "${TEMPLATE_PATH}" ]; then
  # Single file mode
  echo "═══════════════════════════════════════════════════════"
  echo "Wallbash Template Parser - Single File Mode"
  echo "═══════════════════════════════════════════════════════"
  echo "Colors: ${DCOL_FILE}"
  echo "Mode: ${dcol_mode} $(${USE_INVERTED} && echo "(inverted)")"
  echo ""

  process_template "${TEMPLATE_PATH}"

elif [ -d "${TEMPLATE_PATH}" ]; then
  # Directory mode
  echo "═══════════════════════════════════════════════════════"
  echo "Wallbash Template Parser - Directory Mode"
  echo "═══════════════════════════════════════════════════════"
  echo "Colors: ${DCOL_FILE}"
  echo "Mode: ${dcol_mode} $(${USE_INVERTED} && echo "(inverted)")"
  echo "Templates: ${TEMPLATE_PATH}"

  # Find all .dcol files in the directory (recursive)
  mapfile -t template_files < <(find "${TEMPLATE_PATH}" -type f -name "*.dcol" | sort)

  if [ ${#template_files[@]} -eq 0 ]; then
    echo ""
    echo "  ✗ No .dcol template files found in ${TEMPLATE_PATH}"
    exit 1
  fi

  if ${USE_PARALLEL}; then
    echo "Found ${#template_files[@]} template(s) - Processing with ${PARALLEL_JOBS} parallel jobs"
  else
    echo "Found ${#template_files[@]} template(s) - Processing serially"
  fi
  echo ""

  # Process templates
  if ${USE_PARALLEL} && command -v parallel &>/dev/null; then
    # Use GNU parallel if available
    # Create temporary files for tracking results
    success_file=$(mktemp)
    error_file=$(mktemp)

    # Process in parallel and capture output
    printf "%s\n" "${template_files[@]}" | parallel -j "${PARALLEL_JOBS}" "process_template {} && echo >> '${success_file}' || echo >> '${error_file}'"

    success_count=$(wc -l <"${success_file}" 2>/dev/null || echo 0)
    fail_count=$(wc -l <"${error_file}" 2>/dev/null || echo 0)

    rm -f "${success_file}" "${error_file}"
  elif ${USE_PARALLEL} && command -v xargs &>/dev/null; then
    # Fallback to xargs for parallel processing
    success_file=$(mktemp)
    error_file=$(mktemp)

    printf "%s\n" "${template_files[@]}" | xargs -P "${PARALLEL_JOBS}" -I {} bash -c 'process_template "$@" && echo >> "'"${success_file}"'" || echo >> "'"${error_file}"'"' _ {}

    success_count=$(wc -l <"${success_file}" 2>/dev/null || echo 0)
    fail_count=$(wc -l <"${error_file}" 2>/dev/null || echo 0)

    rm -f "${success_file}" "${error_file}"
  else
    # Serial processing fallback
    if ${USE_PARALLEL}; then
      echo "Warning: Neither 'parallel' nor 'xargs' found, falling back to serial processing"
      echo ""
    fi
    success_count=0
    fail_count=0

    for template_file in "${template_files[@]}"; do
      if process_template "${template_file}"; then
        ((success_count++))
      else
        ((fail_count++))
      fi
    done
  fi

  # Summary
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "Summary: ${success_count} succeeded, ${fail_count} failed"
  echo "═══════════════════════════════════════════════════════"

else
  echo "Error: Template path not found: ${TEMPLATE_PATH}"
  exit 1
fi

echo ""
echo "✓ Done!"
