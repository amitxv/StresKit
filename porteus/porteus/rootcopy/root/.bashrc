alias sensors='watch -n 1 sensors coretemp-isa-0000'
alias prime95='(cd /root/tools/prime95 && ./mprime)'
alias ycruncher='(cd /root/tools/ycruncher && ./y-cruncher)'

linpack() {
    (cd /root/tools/linpack && ./runme_xeon64.sh "$@")
}

chmod -R +x /root/tools