cmake_init() {
    # Argument handling
    local target_type="bin"
    local source_file="main.cc"
    local target_cmd="add_executable(\${ProjectId} \"$source_file\")"
    local overwrite_choice=""

    # Help handling
    if [[ "$1" == "--help" ]]; then
        echo "Usage: cmake_init [--lib|--bin]"
        return 0
    fi

    # Argument parsing
    while (( $# > 0 )); do
        case "$1" in
            --lib)
                target_type="lib"
                source_file="lib.cc"
                target_cmd="add_library(\${ProjectId} SHARED \"$source_file\")"
                ;;
            --bin)
                target_type="bin"
                ;;
            *)
                echo >&2 "Error: Unknown argument $1"
                echo >&2 "Usage: cmake_init [--lib|--bin]"
                return 1
                ;;
        esac
        shift
    done

    # Check existing CMakeLists.txt
    if [[ -f "CMakeLists.txt" ]]; then
        read -rp "Existing CMakeLists.txt detected, overwrite? (y/N) " overwrite_choice
        if [[ "${overwrite_choice,,}" != "y" ]]; then
            echo "Operation cancelled"
            return 0
        fi
    fi

    # Generate CMake content
    local cmake_content=$(cat <<EOF
cmake_minimum_required(VERSION 3.20)

set(CMAKE_TOOLCHAIN_FILE "\$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")

get_filename_component(ProjectId \${CMAKE_CURRENT_SOURCE_DIR} NAME)
project(\${ProjectId})
message("Project \${ProjectId} building started")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(fmt CONFIG REQUIRED)

${target_cmd}

set_target_properties(\${ProjectId} PROPERTIES PREFIX "")

target_include_directories(\${ProjectId} PUBLIC include)
target_link_libraries(\${ProjectId} PUBLIC fmt::fmt)
EOF
    )

    # Write CMakeLists.txt
    echo "$cmake_content" > "CMakeLists.txt" || {
        echo >&2 "Error: Failed to write CMakeLists.txt"
        return 1
    }
    echo "Initialized CMake project: ${target_type}"

    # Create sample files
    if [[ ! -f "$source_file" ]]; then
        mkdir -p src
        case "$target_type" in
            lib)
                echo -e "#include <fmt/core.h>\n\nextern \"C\" void hello() {\n    fmt::println(\"Hello from library!\");\n}" > "src/$source_file"
                ;;
            bin)
                echo -e "#include <fmt/core.h>\n\nint main() {\n    fmt::println(\"Hello World!\");\n}" > "src/$source_file"
                ;;
        esac
        echo "Created sample file: src/$source_file"
    fi

    # Create directory structure
    mkdir -p include src || {
        echo >&2 "Error: Failed to create directory structure"
        return 1
    }

    # Initialize vcpkg
    if [[ ! -f "vcpkg.json" ]]; then
        if ! command -v vcpkg &> /dev/null; then
            echo >&2 "Warning: vcpkg not found, skipping initialization"
            return 0
        fi
        vcpkg new --application && vcpkg add port fmt || {
            echo >&2 "Error: vcpkg initialization failed"
            return 1
        }
    fi

    # Copy configuration files
    copy_config_file() {
        local src="$1"
        local dest="$2"
        if [[ -f "$src" ]]; then
            cp "$src" "$dest" && echo "Copied config file: $dest"
        else
            echo >&2 "Warning: Config file $src not found"
        fi
    }

    copy_config_file ~/.config/customize_config/.editorconfig .editorconfig
}

cmake_new() {
    # Parameter validation
    if [[ $# -eq 0 ]]; then
        echo >&2 "Error: Project name required"
        echo >&2 "Usage: cmake_new project_name [--lib|--bin]"
        return 1
    fi

    local project_name="$1"
    shift

    # Prevent directory overwrite
    if [[ -e "$project_name" ]]; then
        echo >&2 "Error: '$project_name' already exists"
        return 1
    fi

    # Create project directory
    mkdir -p "$project_name" || {
        echo >&2 "Error: Failed to create directory '$project_name'"
        return 1
    }

    # Initialize project
    (
        cd "$project_name" || {
            echo >&2 "Error: Cannot enter directory '$project_name'"
            return 1
        }
        cmake_init "$@"
    )
}

cmake_build() {
    # Pre-check
    if [[ ! -f "CMakeLists.txt" ]]; then
        echo >&2 "Error: Not a CMake project directory"
        return 1
    fi

    # Function to get latest modified timestamp
    get_latest_timestamp() {
        find "$@" -type f ! -path '*/\.*' 2>/dev/null \
        | xargs stat -c %Y 2>/dev/null \
        | sort -nr \
        | head -1
    }

    # Get source files timestamp
    local src_files=("src" "include")
    [[ -f "main.cc" ]] && src_files+=("main.cc")
    [[ -f "lib.cc" ]] && src_files+=("lib.cc")
    
    local src_timestamp
    src_timestamp=$(get_latest_timestamp "${src_files[@]}")

    # Get build files timestamp
    local build_timestamp=0
    if [[ -d "build" ]]; then
        build_timestamp=$(get_latest_timestamp "build")
    fi

    # Skip build if no changes
    if [[ -n "$src_timestamp" && -n "$build_timestamp" ]]; then
        if (( src_timestamp <= build_timestamp )); then
            echo "No source changes detected. Build skipped."
            return 0
        fi
    fi

    # Clean old cache
    if [[ -d "build" ]]; then
        echo "Found existing build directory, cleaning..."
        rm -rf build/CMakeCache.txt || {
            echo >&2 "Error: Clean failed"
            return 1
        }
    fi

    # Build process
    (
        mkdir -p build && cd build || {
            echo >&2 "Error: Failed to create build directory"
            return 1
        }

        if ! cmake ..; then
            echo >&2 "Error: CMake configuration failed"
            return 1
        fi

        local cpu_count
        cpu_count=$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 4)
        if ! make -j"$cpu_count"; then
            echo >&2 "Error: Compilation failed"
            return 1
        fi
    ) || return 1

    echo "Build successful"
}

cmake_clean() {
    # Safety check
    if [[ ! -f "CMakeLists.txt" ]]; then
        echo >&2 "Error: Not a CMake project directory"
        return 1
    fi

    if [[ -d "build" ]]; then
        echo "Cleaning build directory..."
        rm -rf build || {
            echo >&2 "Error: Clean failed"
            return 1
        }
    else
        echo "No build directory to clean"
    fi
}

