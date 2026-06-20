#!/bin/bash
# write_files.sh — Processa payload JSON com múltiplos arquivos e os cria em paralelo
# Uso: ./write_files.sh <arquivo.json> [--verbose] [--log-to-file <log>] [--silent]
#
# Fonte: https://claudelog.com/mechanics/multi-file-system/
# Autor original: InventorBlack

set -e

VERBOSE=false
LOG_TO_FILE=false
LOG_FILE=""
OUTPUT_FILE=""
SILENT=false
COMPACT=true

WHITE='\033[1;37m'
GRAY='\033[0;37m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SUCCESS_ICON="🟢"
NEUTRAL_ICON="⚪"
ERROR_ICON="🔴"
CLOCK_ICON="⏱️"
DATE_ICON="📅"
SIMPLE_CHECK="✓"

declare -a NUMBER_OUTPUTS
declare -a SIMPLE_OUTPUTS
number_items=0
simple_items=0
start_time=$(date +%s)

process_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose) VERBOSE=true; COMPACT=false; shift ;;
            --log-to-file) LOG_TO_FILE=true; LOG_FILE="$2"; shift 2 ;;
            --output-file) OUTPUT_FILE="$2"; SILENT=true; shift 2 ;;
            --silent) SILENT=true; shift ;;
            --no-compact) COMPACT=false; shift ;;
            -h|--help) print_usage; exit 0 ;;
            *) [[ -z "$JSON_FILE" ]] && { JSON_FILE="$1"; shift; } || { echo "Argumento desconhecido: $1"; exit 1; } ;;
        esac
    done
    [[ -z "$JSON_FILE" ]] && { echo "Erro: JSON é obrigatório."; print_usage; exit 1; }
    [[ ! -f "$JSON_FILE" ]] && { echo "Erro: Arquivo não encontrado: $JSON_FILE"; exit 1; }
    [[ "$LOG_TO_FILE" = true && -n "$LOG_FILE" ]] && { mkdir -p "$(dirname "$LOG_FILE")"; echo "--- Log $(date) ---" > "$LOG_FILE"; }
    [[ -n "$OUTPUT_FILE" ]] && { mkdir -p "$(dirname "$OUTPUT_FILE")"; echo "Resultados $(date)" > "$OUTPUT_FILE"; }
}

print_usage() {
    cat << EOF
Uso: $0 <arquivo.json> [opções]
Opções:
  --verbose               Detalhes de cada arquivo
  --log-to-file <arquivo> Salvar log em arquivo
  --output-file <arquivo> Resultados em arquivo (modo silencioso)
  --silent                Sem output no terminal
  --no-compact            Desabilitar formato compacto
  -h, --help              Esta mensagem
EOF
}

log() { [[ "$LOG_TO_FILE" = true && -n "$LOG_FILE" ]] && echo "$(date +"%H:%M:%S") $1" >> "$LOG_FILE"; }
write_out() { [[ -n "$OUTPUT_FILE" ]] && echo "$1" >> "$OUTPUT_FILE"; [[ "$SILENT" = false ]] && echo "$1"; }
write_colored() { [[ "$SILENT" = false ]] && echo -e "$1"; }

print_number_item() {
    log "$2 $1"
    if [[ "$COMPACT" = false ]]; then write_colored "${GRAY}$2 $1${NC}"
    else number_items=$((number_items+1)); NUMBER_OUTPUTS[$number_items]="$2 $1"; fi
}
print_simple_item() {
    log "$SIMPLE_CHECK $1"
    if [[ "$COMPACT" = false ]]; then write_colored "${GRAY}$SIMPLE_CHECK $1${NC}"
    else simple_items=$((simple_items+1)); SIMPLE_OUTPUTS[$simple_items]="$SIMPLE_CHECK $1"; fi
}
print_success() { [[ "$1" =~ [0-9] ]] && print_number_item "$1" "$SUCCESS_ICON" || print_simple_item "$1"; }
print_warning() { [[ "$1" =~ [0-9] ]] && print_number_item "$1" "$NEUTRAL_ICON" || print_simple_item "$1"; }
print_error()   { [[ "$1" =~ [0-9] ]] && print_number_item "$1" "$ERROR_ICON"   || print_simple_item "$1"; }
print_verbose() { log "VERBOSE: $1"; [[ "$VERBOSE" = true ]] && write_out "⚪ $1"; }

format_elapsed() { local e=$1; [[ $e -lt 60 ]] && echo "${e}s" || echo "$((e/60))m $((e%60))s"; }

print_compact_output() {
    if [[ "$COMPACT" = true && "$SILENT" = false ]]; then
        local end_time=$(date +%s)
        local elapsed_str=$(format_elapsed $((end_time - start_time)))
        write_colored "${WHITE}Multi-File Extraction ${DATE_ICON} $(date) ${CLOCK_ICON} ${elapsed_str}${NC}"
        [[ $number_items -gt 0 ]] && {
            local line=""
            for i in $(seq 1 $number_items); do line="${line:+$line }${NUMBER_OUTPUTS[$i]}"; done
            write_colored "${GRAY}${line}${NC}"
        }
        [[ $simple_items -gt 0 ]] && {
            local line=""
            for i in $(seq 1 $simple_items); do line="${line:+$line }${SIMPLE_OUTPUTS[$i]}"; done
            write_colored "${GRAY}${line}${NC}"
        }
        [[ "$CREATED_COUNT" -eq "$FILE_COUNT" ]] \
            && write_colored "${GREEN}${SUCCESS_ICON} Extração concluída com sucesso!${NC}" \
            || write_colored "${RED}${ERROR_ICON} Extração concluída com erros${NC}"
    fi
}

check_dependencies() {
    command -v jq &>/dev/null || { echo "Erro: 'jq' não encontrado. Instale com: sudo apt install jq"; exit 1; }
}

prepare_extraction() {
    FILE_COUNT=$(jq '.files | length' "$JSON_FILE")
    [[ "$FILE_COUNT" -eq 0 ]] && { print_warning "Nenhum arquivo no JSON."; exit 0; }
    print_success "Encontrados: $FILE_COUNT arquivos"
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT
}

create_extraction_scripts() {
    for i in $(seq 0 $((FILE_COUNT - 1))); do
        local info=$(jq -c ".files[$i]" "$JSON_FILE")
        local name=$(echo "$info" | jq -r '.file_name')
        local type=$(echo "$info" | jq -r '.file_type // "text"')
        local content_file="$TEMP_DIR/content_$i.txt"
        jq -r '.file_content' <<< "$info" > "$content_file"
        local dir=$(dirname "$name")
        cat > "$TEMP_DIR/extract_$i.sh" << EOF
#!/bin/bash
mkdir -p "$dir"
if [[ "$type" == "binary" ]]; then
    base64 -d "$content_file" > "$name"
    echo "EXTRACTED|binary|$name"
else
    cat "$content_file" > "$name"
    echo "EXTRACTED|text|$name"
fi
EOF
        chmod +x "$TEMP_DIR/extract_$i.sh"
        print_verbose "Script criado para: $name"
    done
}

execute_extraction() {
    RESULTS_FILE="$TEMP_DIR/results.txt"
    touch "$RESULTS_FILE"
    find "$TEMP_DIR" -name "extract_*.sh" -print0 | xargs -0 -P 8 -I {} bash -c "{} >> $RESULTS_FILE 2>/dev/null"
    [[ "$VERBOSE" = true ]] && while IFS= read -r line; do
        [[ "$line" == EXTRACTED* ]] && { IFS='|' read -r _ type path <<< "$line"; print_success "Extraído $type: $path"; }
    done < "$RESULTS_FILE"
}

verify_extraction() {
    CREATED_COUNT=0
    FAILED_FILES=()
    for i in $(seq 0 $((FILE_COUNT - 1))); do
        local name=$(jq -r ".files[$i].file_name" "$JSON_FILE")
        [[ -f "$name" ]] && CREATED_COUNT=$((CREATED_COUNT+1)) || FAILED_FILES+=("$name")
    done
    log "Criados: $CREATED_COUNT / $FILE_COUNT"
    [[ ${#FAILED_FILES[@]} -gt 0 ]] && for f in "${FAILED_FILES[@]}"; do log "FALHOU: $f"; done
}

print_summary() {
    print_success "Processados: $FILE_COUNT"
    print_success "Criados: $CREATED_COUNT"
    local failed=$((FILE_COUNT - CREATED_COUNT))
    [[ $failed -gt 0 ]] && print_error "Falharam: $failed" || true
}

main() {
    process_args "$@"
    check_dependencies
    prepare_extraction
    create_extraction_scripts
    execute_extraction
    verify_extraction
    print_summary
    [[ "$COMPACT" = true ]] && print_compact_output
    [[ "$SILENT" = true && -n "$OUTPUT_FILE" ]] && echo "$OUTPUT_FILE"
}

main "$@"
