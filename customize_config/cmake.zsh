cmake_init() {
    local target_type="bin"
    local source_file="main.cc"
    local target_cmd="add_executable(\${ProjectId} \"src/$source_file\")"
    local overwrite_choice=""

    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo "Usage: cmake_init [--lib|--bin]"
        return 0
    fi

    while (( $# > 0 )); do
        case "$1" in
            --lib)
                target_type="lib"
                source_file="lib.cc"
                target_cmd="add_library(\${ProjectId} SHARED \"src/$source_file\")"
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

    if [[ -f "CMakeLists.txt" ]]; then
        read -rp "Existing CMakeLists.txt detected, overwrite? (y/N) " overwrite_choice
        if [[ "${overwrite_choice:l}" != "y" ]]; then
            echo "Operation cancelled"
            return 0
        fi
    fi

    mkdir -p include src || {
        echo >&2 "Error: Failed to create directory structure"
        return 1
    }

    local cmake_content=$(cat <<EOF
cmake_minimum_required(VERSION 3.20)

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

    echo "$cmake_content" > CMakeLists.txt || {
        echo >&2 "Error: Failed to write CMakeLists.txt"
        return 1
    }
    echo "Initialized CMake project: ${target_type}"

    if [[ ! -f "src/$source_file" ]]; then
        case "$target_type" in
            lib)
                cat > "src/$source_file" <<EOF
#include <fmt/core.h>

extern "C" void hello() {
    fmt::println("Hello from library!");
}
EOF
                ;;
            bin)
                cat > "src/$source_file" <<EOF
#include <fmt/core.h>

int main() {
    fmt::println("Hello World!");
}
EOF
                ;;
        esac
        echo "Created sample file: src/$source_file"
    fi

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
    if [[ $# -eq 0 || $1 == "--help" || $1 == "-h" ]]; then
        echo "Usage: cmake_new project_name [--lib|--bin]"
        return 0
    fi

    local project_name="$1"
    shift

    if [[ -e "$project_name" ]]; then
        echo >&2 "Error: '$project_name' already exists"
        return 1
    fi

    mkdir -p "$project_name" || {
        echo >&2 "Error: Failed to create directory '$project_name'"
        return 1
    }

    (
        cd "$project_name" || {
            echo >&2 "Error: Cannot enter directory '$project_name'"
            return 1
        }
        cmake_init "$@"
    )
}

cmake_build() {
    if [[ ! -f "CMakeLists.txt" ]]; then
        echo >&2 "Error: Not a CMake project directory"
        return 1
    fi

    echo "Building project..."

    if [[ -d build ]]; then
        echo "Cleaning old CMake cache..."
        rm -f build/CMakeCache.txt || {
            echo >&2 "Error: Clean failed"
            return 1
        }
    fi

    (
        mkdir -p build && cd build || {
            echo >&2 "Error: Failed to create build directory"
            return 1
        }

        cmake .. || {
            echo >&2 "Error: CMake configuration failed"
            return 1
        }

        local cpu_count
        cpu_count=$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 4)
        make -j"$cpu_count" || {
            echo >&2 "Error: Compilation failed"
            return 1
        }
    )

    echo "Build successful"
}

cmake_clean() {
    if [[ ! -f "CMakeLists.txt" ]]; then
        echo >&2 "Error: Not a CMake project directory"
        return 1
    fi

    if [[ -d build ]]; then
        echo "Cleaning build directory..."
        rm -rf build || {
            echo >&2 "Error: Clean failed"
            return 1
        }
    else
        echo "No build directory to clean"
    fi
}

