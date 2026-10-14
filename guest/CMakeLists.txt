cmake_minimum_required(VERSION 3.16)
project(bird_plane_guests CXX)

# The three behaviours, each built against the godot-sandbox guest API's cmake helper and installed
# next to its source, with the riscv64 sysroot through the toolchain file tools/build.exs passes.
# Single precision: the project runs in a stock Godot 4 editor, whose Variant is 24 bytes.
get_filename_component(BIRD_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/.." ABSOLUTE)
set(SANDBOX_API_ROOT "${BIRD_ROOT}/third_party/sandbox-api" CACHE PATH "The godot-sandbox guest API")

add_compile_options("-ffile-prefix-map=${BIRD_ROOT}/=")

set(DOWNLOAD_RUNTIME_API OFF CACHE BOOL "" FORCE)
add_subdirectory(${SANDBOX_API_ROOT}/cmake sandbox_api)

foreach(name smooth_follow thrust turning)
	set(dir ${BIRD_ROOT}/bird_plane/core/${name})
	add_sandbox_program(${name} ${dir}/${name}.cpp)
	target_link_libraries(${name} PRIVATE -lm -lstdc++)
	add_custom_command(TARGET ${name} POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${name}> ${dir}/${name}.elf
		COMMENT "Installing bird_plane/core/${name}/${name}.elf"
	)
endforeach()
