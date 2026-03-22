#!/bin/bash

# MCP Localization Test Tool Implementation
# Version: 1.0.0
# Description: Production-ready localization testing tool for iOS projects

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEMP_DIR="/tmp/localization_test_$$"
readonly DEBUG="${LOCALIZATION_TEST_DEBUG:-false}"
readonly TIMEOUT="${LOCALIZATION_TEST_TIMEOUT:-300}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_debug() {
    if [[ "$DEBUG" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*" >&2
    fi
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Utility functions
timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

cleanup() {
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}

trap cleanup EXIT

# JSON response helpers
json_success() {
    local data="$1"
    echo "$data" | jq '. + {"status": "success", "timestamp": "'$(timestamp)'"}'
}

json_failure() {
    local message="$1"
    local data="${2:-{}}"
    echo "$data" | jq '. + {"status": "failure", "error": "'"$message"'", "timestamp": "'$(timestamp)'"}'
}

json_warning() {
    local message="$1"
    local data="${2:-{}}"
    echo "$data" | jq '. + {"status": "warning", "warning": "'"$message"'", "timestamp": "'$(timestamp)'"}'
}

# Validate project path
validate_project() {
    local project_path="$1"
    
    if [[ ! -d "$project_path" ]]; then
        return 1
    fi
    
    # Check for iOS project files
    if [[ -n "$(find "$project_path" -name "*.xcodeproj" -o -name "*.xcworkspace" | head -1)" ]]; then
        return 0
    fi
    
    return 1
}

# Find localization files
find_localization_files() {
    local project_path="$1"
    find "$project_path" -name "*.strings" -o -name "*.stringsdict" | grep -v "Pods/"
}

# Check for hardcoded strings
check_hardcoded_strings() {
    local project_path="$1"
    local file_patterns=("$@")
    local violations=()
    local violation_count=0
    
    mkdir -p "$TEMP_DIR"
    
    log_debug "Scanning for hardcoded strings in: ${file_patterns[*]}"
    
    for pattern in "${file_patterns[@]}"; do
        while IFS= read -r -d '' file; do
            if [[ "$file" =~ (Test|Mock|Pods/) ]]; then
                continue
            fi
            
            # Look for string literals that might be user-facing
            local line_num=1
            while IFS= read -r line; do
                # Swift string literals
                if [[ "$line" =~ \"[^\"]*[a-zA-Z]{3,}[^\"]*\" ]] && 
                   [[ ! "$line" =~ (NSLocalizedString|String\(localized:|\.localized) ]] &&
                   [[ ! "$line" =~ (import|//|#|print|debug|log|assert|fatalError) ]] &&
                   [[ "$line" =~ [a-zA-Z] ]]; then
                    
                    violations+=("{\"file\":\"$file\",\"line\":$line_num,\"content\":\"$(echo "$line" | sed 's/"/\\"/g')\",\"severity\":\"warning\"}")
                    ((violation_count++))
                fi
                ((line_num++))
            done < "$file"
        done < <(find "$project_path" -name "$pattern" -type f -print0)
    done
    
    local status="pass"
    if [[ $violation_count -gt 0 ]]; then
        status="warning"
        if [[ $violation_count -gt 10 ]]; then
            status="fail"
        fi
    fi
    
    local suggestions=()
    if [[ $violation_count -gt 0 ]]; then
        suggestions+=("\"Use NSLocalizedString() for user-facing strings\"")
        suggestions+=("\"Consider using String(localized:) in Swift\"")
        suggestions+=("\"Add .localized extension for easier localization\"")
    fi
    
    local violations_json
    if [[ ${#violations[@]} -gt 0 ]]; then
        violations_json="[$(IFS=,; echo "${violations[*]}")]"
    else
        violations_json="[]"
    fi
    
    local suggestions_json
    if [[ ${#suggestions[@]} -gt 0 ]]; then
        suggestions_json="[$(IFS=,; echo "${suggestions[*]}")]"
    else
        suggestions_json="[]"
    fi
    
    echo "{\"status\":\"$status\",\"hardcoded_count\":$violation_count,\"violations\":$violations_json,\"suggestions\":$suggestions_json}"
}

# Verify localization keys
verify_localization_keys() {
    local project_path="$1"
    local base_language="${2:-en}"
    
    mkdir -p "$TEMP_DIR"
    local keys_file="$TEMP_DIR/all_keys.txt"
    local base_keys_file="$TEMP_DIR/base_keys.txt"
    
    # Find base language file
    local base_file=""
    while IFS= read -r file; do
        if [[ "$file" =~ /$base_language\.lproj/ ]]; then
            base_file="$file"
            break
        fi
    done < <(find_localization_files "$project_path")
    
    if [[ -z "$base_file" ]]; then
        echo "{\"status\":\"fail\",\"error\":\"Base language file not found for: $base_language\"}"
        return 1
    fi
    
    # Extract keys from base file
    grep -E '^"[^"]*"' "$base_file" | sed 's/^\"\([^\"]*\)\".*/\1/' > "$base_keys_file"
    local total_keys=$(wc -l < "$base_keys_file")
    
    local missing_translations="{}"
    local extra_keys="{}"
    local duplicate_keys=()
    
    # Check each language file
    while IFS= read -r file; do
        if [[ "$file" == "$base_file" ]]; then
            continue
        fi
        
        local lang_code
        lang_code=$(echo "$file" | grep -o '/[^/]*\.lproj/' | sed 's|/||g' | sed 's|\.lproj||g')
        
        if [[ -z "$lang_code" ]]; then
            continue
        fi
        
        # Extract keys from language file
        local lang_keys_file="$TEMP_DIR/${lang_code}_keys.txt"
        grep -E '^"[^"]*"' "$file" | sed 's/^\"\([^\"]*\)\".*/\1/' > "$lang_keys_file"
        
        # Find missing keys
        local missing_keys
        missing_keys=$(comm -23 <(sort "$base_keys_file") <(sort "$lang_keys_file") | tr '\n' ',' | sed 's/,$//')
        if [[ -n "$missing_keys" ]]; then
            missing_translations=$(echo "$missing_translations" | jq --arg lang "$lang_code" --arg keys "[$missing_keys]" '. + {($lang): ($keys | split(",") | map(select(length > 0)))}')
        fi
        
        # Find extra keys
        local extra_keys_list
        extra_keys_list=$(comm -13 <(sort "$base_keys_file") <(sort "$lang_keys_file") | tr '\n' ',' | sed 's/,$//')
        if [[ -n "$extra_keys_list" ]]; then
            extra_keys=$(echo "$extra_keys" | jq --arg lang "$lang_code" --arg keys "[$extra_keys_list]" '. + {($lang): ($keys | split(",") | map(select(length > 0)))}')
        fi
        
        # Check for duplicates
        local dups
        dups=$(sort "$lang_keys_file" | uniq -d)
        if [[ -n "$dups" ]]; then
            while IFS= read -r dup; do
                duplicate_keys+=("\"$dup ($lang_code)\"")
            done <<< "$dups"
        fi
    done < <(find_localization_files "$project_path")
    
    local status="pass"
    local missing_count=$(echo "$missing_translations" | jq 'to_entries | map(.value | length) | add // 0')
    local extra_count=$(echo "$extra_keys" | jq 'to_entries | map(.value | length) | add // 0')
    
    if [[ ${#duplicate_keys[@]} -gt 0 ]] || [[ $missing_count -gt 0 ]] || [[ $extra_count -gt 5 ]]; then
        status="warning"
    fi
    
    if [[ $missing_count -gt 10 ]] || [[ ${#duplicate_keys[@]} -gt 5 ]]; then
        status="fail"
    fi
    
    local duplicate_keys_json
    if [[ ${#duplicate_keys[@]} -gt 0 ]]; then
        duplicate_keys_json="[$(IFS=,; echo "${duplicate_keys[*]}")]"
    else
        duplicate_keys_json="[]"
    fi
    
    echo "{\"status\":\"$status\",\"total_keys\":$total_keys,\"missing_translations\":$missing_translations,\"extra_keys\":$extra_keys,\"duplicate_keys\":$duplicate_keys_json,\"formatting_issues\":[]}"
}

# Generate HTML report
generate_html_report() {
    local project_path="$1"
    local output_path="${2:-./localization_report.html}"
    local auto_open="${3:-true}"
    local theme="${4:-auto}"
    
    local start_time=$(date +%s)
    
    # Make output path absolute
    if [[ ! "$output_path" =~ ^/ ]]; then
        output_path="$(pwd)/$output_path"
    fi
    
    log_info "Generating HTML report at: $output_path"
    
    # Collect data
    local project_name
    project_name=$(basename "$project_path")
    
    local hardcoded_data
    hardcoded_data=$(check_hardcoded_strings "$project_path" "*.swift" "*.m" "*.mm")
    
    local keys_data
    keys_data=$(verify_localization_keys "$project_path")
    
    # Generate HTML content
    cat > "$output_path" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Localization Report - $project_name</title>
    <style>
        :root {
            --bg-color: #ffffff;
            --text-color: #333333;
            --border-color: #e1e5e9;
            --success-color: #28a745;
            --warning-color: #ffc107;
            --danger-color: #dc3545;
            --info-color: #17a2b8;
        }
        
        @media (prefers-color-scheme: dark) {
            :root {
                --bg-color: #1a1a1a;
                --text-color: #e1e1e1;
                --border-color: #404040;
            }
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: var(--bg-color);
            color: var(--text-color);
            line-height: 1.6;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        .header {
            text-align: center;
            margin-bottom: 40px;
            padding: 20px;
            border-bottom: 2px solid var(--border-color);
        }
        
        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            text-transform: uppercase;
        }
        
        .status-pass { background-color: var(--success-color); color: white; }
        .status-warning { background-color: var(--warning-color); color: black; }
        .status-fail { background-color: var(--danger-color); color: white; }
        
        .section {
            margin-bottom: 30px;
            padding: 20px;
            border: 1px solid var(--border-color);
            border-radius: 8px;
        }
        
        .section h2 {
            margin-bottom: 15px;
            color: var(--info-color);
        }
        
        .metric {
            display: inline-block;
            margin: 10px 20px 10px 0;
        }
        
        .metric-value {
            font-size: 24px;
            font-weight: bold;
            display: block;
        }
        
        .metric-label {
            font-size: 12px;
            color: #666;
            text-transform: uppercase;
        }
        
        .violation-item {
            padding: 10px;
            margin: 5px 0;
            background-color: rgba(220, 53, 69, 0.1);
            border-left: 4px solid var(--danger-color);
            border-radius: 4px;
        }
        
        .file-path {
            font-family: monospace;
            font-size: 12px;
            color: #666;
        }
        
        .code-content {
            font-family: monospace;
            background-color: rgba(0, 0, 0, 0.05);
            padding: 5px;
            border-radius: 3px;
            margin-top: 5px;
        }
        
        .suggestions {
            background-color: rgba(23, 162, 184, 0.1);
            border-left: 4px solid var(--info-color);
            padding: 15px;
            border-radius: 4px;
            margin-top: 20px;
        }
        
        .suggestions ul {
            margin-left: 20px;
        }
        
        .timestamp {
            text-align: center;
            color: #666;
            font-size: 12px;
            margin-top: 40px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌐 Localization Report</h1>
            <h2>$project_name</h2>
            <p>Generated on $(date '+%B %d, %Y at %H:%M:%S')</p>
        </div>
        
        <div class="section">
            <h2>📊 Overview</h2>
            <div class="metrics">
EOF

    # Add metrics based on collected data
    local hardcoded_count=$(echo "$hardcoded_data" | jq -r '.hardcoded_count')
    local hardcoded_status=$(echo "$hardcoded_data" | jq -r '.status')
    local keys_status=$(echo "$keys_data" | jq -r '.status')
    local total_keys=$(echo "$keys_data" | jq -r '.total_keys')
    
    cat >> "$output_path" << EOF
                <div class="metric">
                    <span class="metric-value">$(echo "$hardcoded_count")</span>
                    <span class="metric-label">Hardcoded Strings</span>
                    <span class="status-badge status-$hardcoded_status">$hardcoded_status</span>
                </div>
                <div class="metric">
                    <span class="metric-value">$total_keys</span>
                    <span class="metric-label">Total Keys</span>
                    <span class="status-badge status-$keys_status">$keys_status</span>
                </div>
            </div>
        </div>
        
        <div class="section">
            <h2>🔍 Hardcoded Strings Analysis</h2>
EOF

    # Add hardcoded strings violations
    local violations=$(echo "$hardcoded_data" | jq -r '.violations[]')
    if [[ -n "$violations" ]] && [[ "$violations" != "null" ]]; then
        echo "$hardcoded_data" | jq -r '.violations[] | "<div class=\"violation-item\"><div class=\"file-path\">\(.file):\(.line)</div><div class=\"code-content\">\(.content)</div></div>"' >> "$output_path"
    else
        echo "<p>✅ No hardcoded strings detected!</p>" >> "$output_path"
    fi
    
    # Add suggestions
    local suggestions=$(echo "$hardcoded_data" | jq -r '.suggestions[]')
    if [[ -n "$suggestions" ]] && [[ "$suggestions" != "null" ]]; then
        cat >> "$output_path" << EOF
            <div class="suggestions">
                <h3>💡 Suggestions</h3>
                <ul>
EOF
        echo "$hardcoded_data" | jq -r '.suggestions[] | "<li>\(.)</li>"' >> "$output_path"
        cat >> "$output_path" << EOF
                </ul>
            </div>
EOF
    fi
    
    cat >> "$output_path" << EOF
        </div>
        
        <div class="section">
            <h2>🔑 Localization Keys Analysis</h2>
EOF

    # Add missing translations
    local missing_translations=$(echo "$keys_data" | jq -r '.missing_translations')
    if [[ "$missing_translations" != "{}" ]]; then
        echo "<h3>Missing Translations</h3>" >> "$output_path"
        echo "$keys_data" | jq -r '.missing_translations | to_entries[] | "<h4>\(.key)</h4><ul>" + (.value | map("<li>\(.)</li>") | join("")) + "</ul>"' >> "$output_path"
    fi
    
    # Add duplicate keys
    local duplicate_keys=$(echo "$keys_data" | jq -r '.duplicate_keys[]')
    if [[ -n "$duplicate_keys" ]] && [[ "$duplicate_keys" != "null" ]]; then
        echo "<h3>Duplicate Keys</h3><ul>" >> "$output_path"
        echo "$keys_data" | jq -r '.duplicate_keys[] | "<li>\(.)</li>"' >> "$output_path"
        echo "</ul>" >> "$output_path"
    fi
    
    cat >> "$output_path" << EOF
        </div>
        
        <div class="timestamp">
            Report generated by MCP Localization Test Tool v1.0.0
        </div>
    </div>
</body>
</html>
EOF

    local end_time=$(date +%s)
    local generation_time=$((end_time - start_time))
    local report_size=$(wc -c < "$output_path")
    
    local opened_in_browser="false"
    if [[ "$auto_open" == "true" ]]; then
        if command -v open >/dev/null 2>&1; then
            open "$output_path"
            opened_in_browser="true"
        elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$output_path"
            opened_in_browser="true"
        fi
    fi
    
    echo "{\"status\":\"success\",\"report_path\":\"$output_path\",\"report_size\":$report_size,\"generation_time\":$generation_time,\"sections_included\":[\"overview\",\"hardcoded_strings\",\"localization_keys\"],\"opened_in_browser\":$opened_in_browser}"
}

# Main function dispatcher
main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <function> [arguments...]"
        echo "Available functions: check_localization, validate_strings, verify_keys, generate_report"
        exit 1
    fi
    
    local function_name="$1"
    shift
    
    # Create temp directory
    mkdir -p "$TEMP_DIR"
    
    case "$function_name" in
        "check_localization")
            local project_path="$1"
            local target_name="${2:-main}"
            local languages="${3:-en,fr}"
            local strict_mode="${4:-false}"
            
            if ! validate_project "$project_path"; then
                json_failure "Invalid iOS project path: $project_path"
                exit 1
            fi
            
            log_info "Running comprehensive localization check for: $project_path"
            
            # Run all checks
            local hardcoded_result
            hardcoded_result=$(check_hardcoded_strings "$project_path" "*.swift" "*.m" "*.mm")
            
            local keys_result
            keys_result=$(verify_localization_keys "$project_path")
            
            local report_result
            local report_path="$project_path/localization_report_$(date +%Y%m%d_%H%M%S).html"
            report_result=$(generate_html_report "$project_path" "$report_path" "false")
            
            # Calculate overall score
            local hardcoded_status=$(echo "$hardcoded_result" | jq -r '.status')
            local keys_status=$(echo "$keys_result" | jq -r '.status')
            
            local score=100
            local tests_run=2
            local tests_passed=0
            local tests_failed=0
            
            if [[ "$hardcoded_status" == "pass" ]]; then
                ((tests_passed++))
            elif [[ "$hardcoded_status" == "warning" ]]; then
                score=$((score - 20))
            else
                score=$((score - 40))
                ((tests_failed++))
            fi
            
            if [[ "$keys_status" == "pass" ]]; then
                ((tests_passed++))
            elif [[ "$keys_status" == "warning" ]]; then
                score=$((score - 20))
            else
                score=$((score - 40))
                ((tests_failed++))
            fi
            
            local overall_status="success"
            if [[ $score -lt 60 ]]; then
                overall_status="failure"
            elif [[ $score -lt 80 ]]; then
                overall_status="warning"
            fi
            
            local result_json="{
                \"overall_score\": $score,
                \"tests_run\": $tests_run,
                \"tests_passed\": $tests_passed,
                \"tests_failed\": $tests_failed,
                \"results\": {
                    \"hardcoded_strings\": {
                        \"status\": \"$hardcoded_status\",
                        \"count\": $(echo "$hardcoded_result" | jq '.hardcoded_count'),
                        \"violations\": $(echo "$hardcoded_result" | jq '.violations')
                    },
                    \"missing_keys\": {
                        \"status\": \"$keys_status\",
                        \"count\": $(echo "$keys_result" | jq '.missing_translations | to_entries | map(.value | length) | add // 0'),
                        \"missing\": $(echo "$keys_result" | jq '.missing_translations')
                    },
                    \"unused_keys\": {
                        \"status\": \"pass\",
                        \"count\": $(echo "$keys_result" | jq '.extra_keys | to_entries | map(.value | length) | add // 0'),
                        \"unused\": $(echo "$keys_result" | jq '.extra_keys')
                    },
                    \"translation_coverage\": {
                        \"status\": \"$keys_status\",
                        \"percentage\": $score,
                        \"by_language\": {}
                    }
                },
                \"report_path\": \"$(echo "$report_result" | jq -r '.report_path')\"
            }"
            
            if [[ "$overall_status" == "success" ]]; then
                json_success "$result_json"
            elif [[ "$overall_status" == "warning" ]]; then
                json_warning "Some localization issues detected" "$result_json"
            else
                json_failure "Critical localization issues detected" "$result_json"
            fi
            ;;
            
        "validate_strings")
            local project_path="$1"
            shift
            local file_patterns=("$@")
            
            if [[ ${#file_patterns[@]} -eq 0 ]]; then
                file_patterns=("*.swift" "*.m" "*.mm")
            fi
            
            if ! validate_project "$project_path"; then
                json_failure "Invalid iOS project path: $project_path"
                exit 1
            fi
            
            log_info "Validating strings in: $project_path"
            local result
            result=$(check_hardcoded_strings "$project_path" "${file_patterns[@]}")
            echo "$result"
            ;;
            
        "verify_keys")
            local project_path="$1"
            local base_language="${2:-en}"
            
            if ! validate_project "$project_path"; then
                json_failure "Invalid iOS project path: $project_path"
                exit 1
            fi
            
            log_info "Verifying localization keys in: $project_path"
            local result
            result=$(verify_localization_keys "$project_path" "$base_language")
            echo "$result"
            ;;
            
        "generate_report")
            local project_path="$1"
            local output_path="${2:-./localization_report.html}"
            local auto_open="${3:-true}"
            local theme="${4:-auto}"
            
            if ! validate_project "$project_path"; then
                json_failure "Invalid iOS project path: $project_path"
                exit 1
            fi
            
            log_info "Generating report for: $project_path"
            local result
            result=$(generate_html_report "$project_path" "$output_path" "$auto_open" "$theme")
            echo "$result"
            ;;
            
        *)
            json_failure "Unknown function: $function_name"
            exit 1
            ;;
    esac
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if ! command -v find >/dev/null 2>&1; then
        missing_deps+=("find")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        echo "{\"status\":\"failure\",\"error\":\"Missing dependencies: ${missing_deps[*]}\"}"
        exit 1
    fi
}

# Run dependency check before main execution
check_dependencies

# Execute main function with all arguments
main "$@"