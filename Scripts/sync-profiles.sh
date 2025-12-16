#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2025 Petro Rovenskyi

# Sync inverter profiles from ha-solarman upstream repository
# Usage: ./Scripts/sync-profiles.sh [--all | --profile <name>]
#
# Examples:
#   ./Scripts/sync-profiles.sh --all          # Sync all profiles
#   ./Scripts/sync-profiles.sh deye_hybrid    # Sync specific profile
#   ./Scripts/sync-profiles.sh --list         # List available profiles

set -eo pipefail

# Configuration
UPSTREAM_REPO="davidrapan/ha-solarman"
UPSTREAM_BRANCH="main"
UPSTREAM_PATH="custom_components/solarman/inverter_definitions"
PROFILES_DIR="Sources/SolarCore/Profiles/Resources"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print with color
print_info() {
    echo -e "${BLUE}→${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] [PROFILE...]

Sync inverter profiles from upstream ha-solarman repository.

Options:
    --all           Sync all available profiles
    --list          List available upstream profiles
    --dry-run       Show what would be done without making changes
    --clean         Remove local profiles not in upstream
    --help          Show this help message

Arguments:
    PROFILE         One or more profile names (e.g., deye_hybrid sofar_g3)

Examples:
    $0 --list                   # List available profiles
    $0 --all                    # Sync all profiles
    $0 deye_hybrid             # Sync single profile
    $0 deye_hybrid sofar_g3    # Sync multiple profiles
    $0 --all --clean           # Sync all and remove old local files

Repository: https://github.com/${UPSTREAM_REPO}
EOF
}

# Get list of upstream profiles
list_upstream_profiles() {
    print_info "Fetching profile list from upstream..." >&2

    local api_url="https://api.github.com/repos/${UPSTREAM_REPO}/contents/${UPSTREAM_PATH}?ref=${UPSTREAM_BRANCH}"
    local response

    response=$(curl -s -H "Accept: application/vnd.github.v3+json" "$api_url")

    # Check for API error (presence of "message" field indicates error)
    if echo "$response" | grep -q '"message"' 2>/dev/null; then
        print_error "Failed to fetch profile list: $(echo "$response" | grep -o '"message":[^,]*')" >&2
        exit 1
    fi

    # Extract profile names from JSON response (note: space after colon in JSON)
    echo "$response" | grep -oE '"name": "[^"]*\.yaml"' | sed 's/"name": "//; s/\.yaml"//' | sort
}

# Get manufacturer from profile name
get_manufacturer() {
    local profile="$1"

    # Handle special cases first (profiles with hyphen in manufacturer name)
    case "$profile" in
        astro-energy_*)
            echo "astro-energy"
            return
            ;;
    esac

    # Standard case: extract prefix before first underscore
    local prefix="${profile%%_*}"

    # Map prefix to manufacturer directory
    case "$prefix" in
        afore|anenji|chint|deye|hinen|invt|kstar|maxge|megarevo|pylontech|renon|sofar|solarman|solis|srne|swatten|tsun|victron)
            echo "$prefix"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Download a single profile
download_profile() {
    local profile="$1"
    local dry_run="${2:-false}"
    local filename="${profile}.yaml"
    local manufacturer
    manufacturer=$(get_manufacturer "$profile")
    local target_dir="${PROFILES_DIR}/${manufacturer}"
    local target_file="${target_dir}/${filename}"
    local raw_url="https://raw.githubusercontent.com/${UPSTREAM_REPO}/${UPSTREAM_BRANCH}/${UPSTREAM_PATH}/${filename}"

    if [[ "$dry_run" == "true" ]]; then
        print_info "[dry-run] Would download: $filename -> $target_file"
        return 0
    fi

    # Create manufacturer directory if needed
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
        print_info "Created directory: $target_dir"
    fi

    # Download profile
    print_info "Downloading: $filename"
    if curl -sf "$raw_url" -o "$target_file"; then
        print_success "Saved: $target_file"
        return 0
    else
        print_error "Failed to download: $filename"
        return 1
    fi
}

# Sync all profiles
sync_all() {
    local dry_run="${1:-false}"
    local profiles

    profiles=$(list_upstream_profiles)
    local count=0
    local failed=0

    echo ""
    print_info "Syncing all upstream profiles..."
    echo ""

    while IFS= read -r profile; do
        if [[ -n "$profile" ]]; then
            if download_profile "$profile" "$dry_run"; then
                ((count++))
            else
                ((failed++))
            fi
        fi
    done <<< "$profiles"

    echo ""
    print_success "Synced $count profiles"
    if [[ $failed -gt 0 ]]; then
        print_warning "Failed: $failed profiles"
    fi
}

# Sync specific profiles
sync_profiles() {
    local dry_run="${1:-false}"
    shift
    local profiles=("$@")
    local count=0
    local failed=0

    for profile in "${profiles[@]}"; do
        # Remove .yaml extension if provided
        profile="${profile%.yaml}"

        if download_profile "$profile" "$dry_run"; then
            ((count++))
        else
            ((failed++))
        fi
    done

    echo ""
    print_success "Synced $count profiles"
    if [[ $failed -gt 0 ]]; then
        print_warning "Failed: $failed profiles"
    fi
}

# Clean local profiles not in upstream
clean_old_profiles() {
    local dry_run="${1:-false}"
    local upstream_profiles
    upstream_profiles=$(list_upstream_profiles)

    print_info "Checking for obsolete local profiles..."

    # Find all local YAML files
    if [[ ! -d "$PROFILES_DIR" ]]; then
        print_warning "Profiles directory does not exist: $PROFILES_DIR"
        return 0
    fi

    local removed=0
    while IFS= read -r -d '' local_file; do
        local basename
        basename=$(basename "$local_file" .yaml)

        if ! echo "$upstream_profiles" | grep -q "^${basename}$"; then
            if [[ "$dry_run" == "true" ]]; then
                print_info "[dry-run] Would remove: $local_file"
            else
                rm "$local_file"
                print_warning "Removed obsolete: $local_file"
            fi
            ((removed++))
        fi
    done < <(find "$PROFILES_DIR" -name "*.yaml" -print0)

    if [[ $removed -eq 0 ]]; then
        print_success "No obsolete profiles found"
    else
        print_info "Removed $removed obsolete profiles"
    fi
}

# Main
main() {
    # Change to project root
    local script_dir
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    cd "$script_dir/.."

    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    local dry_run=false
    local clean=false
    local action=""
    local profiles=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                usage
                exit 0
                ;;
            --list|-l)
                action="list"
                shift
                ;;
            --all|-a)
                action="all"
                shift
                ;;
            --dry-run|-n)
                dry_run=true
                shift
                ;;
            --clean|-c)
                clean=true
                shift
                ;;
            -*)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                profiles+=("$1")
                shift
                ;;
        esac
    done

    case "$action" in
        list)
            list_upstream_profiles
            ;;
        all)
            sync_all "$dry_run"
            if [[ "$clean" == "true" ]]; then
                clean_old_profiles "$dry_run"
            fi
            ;;
        *)
            if [[ ${#profiles[@]} -gt 0 ]]; then
                sync_profiles "$dry_run" "${profiles[@]}"
            else
                usage
                exit 1
            fi
            ;;
    esac
}

main "$@"
