#!/bin/sh

usage() {
    echo "Usage: $0 [-m <gb>] [-s <samples>]"
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
        mem_total_gb=$(echo "$(grep MemTotal /proc/meminfo | awk '{print $2}') / 1048576" | bc)
        memory_in_gb=$(echo "scale=2; $mem_total_gb * 0.8" | bc)
    fi

    samples=${samples_arg:-100}

    has_avx=$(grep -q "avx" /proc/cpuinfo && echo 1 || echo 0)
    memory_in_bytes=$(echo "$memory_in_gb * 1073741824" | bc)

    if [ "$has_avx" -eq 1 ]; then
        base=16
        ignore=32
    else
        base=8
        ignore=16
    fi

    psize=$(echo "sqrt($memory_in_bytes / 8)" | bc)
    optimal_psize=$(( (($psize + $base - 1) / $ignore) * $ignore + $base ))

    # create lininput
    echo -e "\n\n1\n$optimal_psize\n$optimal_psize\n$samples\n4" > "lininput_xeon64"

    # environment variables for linpack
    export KMP_AFFINITY=nowarnings,compact,1,0,granularity=fine

    # run linpack
    ./xlinpack_xeon64 lininput_xeon64

    return 0
}

main "$@"
