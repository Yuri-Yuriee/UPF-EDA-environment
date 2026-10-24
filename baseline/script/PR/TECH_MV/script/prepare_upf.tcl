# Stage the original UPF files from setup/UPF without modifying their contents.
file mkdir $UPF_RUNTIME_DIR

foreach source_file $UPF_SOURCE_FILES {
    set destination_file [file join $UPF_RUNTIME_DIR [file tail $source_file]]
    file copy -force $source_file $destination_file
}
