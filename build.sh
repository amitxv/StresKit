#!/bin/bash

fetch_sha256() {
    source="$1"
    target_file_name="$2"

    response=$(wget -qO- "$source")

    echo "$response" | while IFS= read -r line; do
        # shellcheck disable=SC2206
        split=($line)

        hash=${split[0]}
        file_name=${split[1]}

        if [ "$file_name" == "$target_file_name" ]; then
            echo "$hash"
        fi
    done

    echo ""

}

main() {
    streskit_version=$1

    # http://porteus.org/porteus-mirrors.html
    src="http://ftp.vim.org/ftp/os/Linux/distr/porteus/x86_64/Porteus-v5.01"
    file_name="Porteus-OPENBOX-v5.01-x86_64.iso"

    # download ISO file
    wget -O "$file_name" "$src/$file_name"

    if [ ! -e "./$file_name" ]; then
        echo "error: $file_name download failed"
        return 1
    fi

    # get remote SHA256
    remote_hash=$(fetch_sha256 "$src/sha256sums.txt" "$file_name")

    if [ -z "$remote_hash" ]; then
        echo "error: hash not found for file $file_name"
        return 1
    fi

    # get local SHA256
    local_hash=$(sha256sum "./$file_name" | awk '{print $1}')

    # check if hashes match
    if [ "$local_hash" != "$remote_hash" ]; then
        echo "error: hashes do not match"
        return 1
    fi

    # extract ISO
    7z x "./$file_name" -o"./extracted_iso"

    # delete unnecessary modules
    rm "./extracted_iso/porteus/base/002-xorg.xzm"
    rm "./extracted_iso/porteus/base/002-xtra.xzm"
    rm "./extracted_iso/porteus/base/003-openbox.xzm"

    # setup Linpack
    bin_path="./porteus/porteus/rootcopy/usr/bin"

    if ! bash "./setup_linpack.sh" $bin_path; then
        echo "error: failed to setup linpack"
        return 1
    fi

    # patch linpack binary for AMD
    if ! python3 "./patch_linpack.py" "$bin_path/xlinpack_xeon64"; then
        echo "error: failed to patch binary"
        return 1
    fi

    # move custom files
    cp -ru ./porteus/* "./extracted_iso"

    # make ISO
    bash "./extracted_iso/porteus/make_iso.sh" "StresKit-v$streskit_version-x86_64.iso"

    return 0
}

main "$@"
