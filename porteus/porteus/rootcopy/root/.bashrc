alias sensors='watch -n 1 sensors coretemp-isa-0000'
alias prime95='(cd /root/prime95 && ./mprime)'
alias ycruncher='(cd /root/ycruncher && ./y-cruncher)'

linpack () {
    (cd /root/linpack && ./runme_xeon64.sh "$@")
}
