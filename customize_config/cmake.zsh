cmake_init() {
    if [[ $1 == "--help" ]]; then
        echo "usage: cmake_init [--lib|--bin]"
        return 0
    fi
    
    local target_type="bin"  
    local source_file="main.cc"
    local target_cmd="add_executable(\${ProjectId} \"$source_file\")"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --lib)
                target_type="lib"
                source_file="lib.cc"
                target_cmd="add_library(\${ProjectId} SHARED \"$source_file\")"
                ;;
            --bin)
                target_type="bin"
                ;;
            *)
                echo "Unknown argument: $1"
                echo "usage: cmake_init [--lib|--bin]"
                return 1
                ;;
        esac
        shift
    done

    local cmake_content="cmake_minimum_required(VERSION 3.20)

set(CMAKE_TOOLCHAIN_FILE \"\$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake\")

get_filename_component(ProjectId \${CMAKE_CURRENT_SOURCE_DIR} NAME)
project(\${ProjectId})
message(\"Project \${ProjectId} start to build\")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(fmt CONFIG REQUIRED)

${target_cmd}

set_target_properties(\${ProjectId} PROPERTIES PREFIX \"\")

target_include_directories(\${ProjectId} PUBLIC include)

target_link_libraries(\${ProjectId} PUBLIC fmt::fmt)"

    if [[ -f CMakeLists.txt ]]; then
        read -rp "Found existing CMakeLists.txt, overwrite? (y/N) " answer
        [[ "$answer" != "y" && "$answer" != "Y" ]] && return 0
    fi

    echo "$cmake_content" > CMakeLists.txt
    echo "Initialized CMake project: ${target_type}"

    if [[ ! -f $source_file ]]; then
        if [[ $target_type == "lib" ]]; then
            echo -e "// lib.cc\n#include <fmt/core.h>\n\nextern \"C\" void hello() {\n    fmt::println(\"Hello from library!\");\n}" > $source_file
        else
            echo -e "// main.cc\n#include <fmt/core.h>\n\nint main() {\n    fmt::println(\"Hello World!\");\n}" > $source_file
        fi
        echo "Created source file: $source_file"
    fi

    mkdir -p include src

    if [[ ! -f vcpkg.json ]]; then
        vcpkg new --application
        vcpkg add port fmt
    fi

    cp ~/.config/.clang-format .clang-format
}

cmake_new() {
    if [[ $# -eq 0 ]] || [[ $1 == "--help" ]]; then
        echo "usage: cmake_new project_name [--lib|--bin]"
        return 1
    fi

    local project_name=$1
    shift

    if [[ -d $project_name ]]; then
        echo "Error: Directory $project_name already exists"
        return 1
    fi

    mkdir -p "$project_name" && cd "$project_name" && cmake_init "$@"
}

cmake_build() {
    if [[ ! -f CMakeLists.txt ]]; then
        echo "Error: CMakeLists.txt not found in current directory"
        return 1
    fi

    mkdir -p build && cd build && cmake .. && make -j$(nproc)
    return $?
}

cmake_clean() {
    if [[ ! -f CMakeLists.txt ]]; then
        echo "Error: Not a CMake project directory"
        return 1
    fi

    if [[ -d build ]]; then
        echo "Removing build directory..."
        rm -rf build
    else
        echo "Build directory does not exist"
    fi
}

cmake_run() {
    if [[ $1 == "--help" ]]; then
        echo "usage: cmake_run [executable_name]"
        return 0
    fi

    local project_id=$(basename "$PWD")
    if grep -qE "^[^#]*add_executable\(" CMakeLists.txt; then
        cmake_build || return $?
    elif grep -qE "^[^#]*add_library\(" CMakeLists.txt; then
        echo "This project is a library, not an executable"
        return 0
    else
        echo "Error: No add_executable or add_library in CMakeLists.txt"
        return 1
    fi

    local exe_name=${1:-$project_id}
    local exe_path
    exe_path=$(find build -type f -executable -name "$exe_name" 2>/dev/null | head -n1)
    
    if [[ -n "$exe_path" ]]; then
        echo "Running: ${exe_path}"
        "$exe_path"
    else
        echo "Error: Executable '${exe_name}' not found"
        return 1
    fi
}

