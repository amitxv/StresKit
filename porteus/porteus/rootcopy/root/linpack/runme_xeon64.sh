#!/bin/sh

usage() {
    echo "Usage: $0 [-m <gb>] [-s <samples>]"
}

is_psize_valid() {
    psize=$1
    has_avx=$2

    if [ "$has_avx" -eq 1 ]; then
        if ((psize % 16 == 0)) && ((psize % 32 != 0)); then
            return 0
        fi
    else
        if ((psize % 8 == 0)) && ((psize % 16 != 0)); then
            return 0
        fi
    fi

    return 1
}

main() {
    memory_arg=""
    samples_arg=""

    while getopts "m:s:" opt; do
        case $opt in
            m)
                memory_arg="$OPTARG"
                ;;
            s)
                samples_arg="$OPTARG"
                ;;
            \?)
                echo "error: invalid option: -$OPTARG"
                usage
                exit 1
                ;;
            :)
                echo "error: option -$OPTARG requires an argument"
                usage
                exit 1
                ;;
        esac
    done

    if [ -n "$memory_arg" ]; then
        memory_in_gb=$memory_arg
    else
        # use 80% of available memory by default
        mem_total_gb=$(echo "$(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024^2" | bc)
        memory_in_gb=$(echo "scale=2; $mem_total_gb * 0.8" | bc)
    fi

    samples=${samples_arg:-100}

    has_avx=$(grep -q "avx" /proc/cpuinfo && echo 1 || echo 0)
    memory_in_bytes=$(echo "$memory_in_gb * 1073741824" | bc)
    initial_psize=$(echo "sqrt($memory_in_bytes / 8)" | bc)
    optimal_psize=0
    n=0

    if is_psize_valid "$initial_psize" "$has_avx"; then
        optimal_psize=$initial_psize
    fi

    while [ "$optimal_psize" -eq 0 ]; do
        temp_psize=$((initial_psize + n))
        if is_psize_valid $temp_psize "$has_avx"; then
            optimal_psize=$temp_psize
        fi

        temp_psize=$((initial_psize - n))
        if is_psize_valid $temp_psize "$has_avx"; then
            optimal_psize=$temp_psize
        fi

        n=$((n + 1))
    done

    # create lininput
    echo -e "\n\n1\n$optimal_psize\n$optimal_psize\n$samples\n4" > "lininput_xeon64"

    # environment variables for linpack
    export KMP_AFFINITY=nowarnings,compact,1,0,granularity=fine

    # run linpack
    ./xlinpack_xeon64 lininput_xeon64

    return 0
}

main "$@"
