alias skhelp='cat /usr/local/.skhelp'

linpack() {
    (cd /usr/local/tools/linpack && bash ./runme_xeon64.sh "$@")
}

prime95() {
    (cd /usr/local/tools/prime95 && ./mprime "$@")
}

ycruncher() {
    (cd /usr/local/tools/ycruncher && ./y-cruncher "$@")
}

mlc() {
    (cd /usr/local/tools && ./mlc "$@")
}

gsat() {
    (cd /usr/local/tools && ./stressapptest "$@")
}
