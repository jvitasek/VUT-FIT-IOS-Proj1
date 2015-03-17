#!/bin/bash
### Jakub Vitasek, xvitas02, sk.41 ###
### depcg.sh ###
 
# initializing variables
output=0
func_id=0
cllee=0
cllr=0
graph=0
inc_plt=0
filename=0
 
# creating a temporary file
tmp=`mktemp '/tmp/'$USER'.XXXXXX'`
 
# catching signals
trap -- 'rm /tmp/$USER/XXXXXX; exit' SIGHUP
trap -- 'rm /tmp/$USER/XXXXXX; exit' SIGINT
trap -- 'rm /tmp/$USER/XXXXXX; exit' SIGTERM
 
# function used when there was an error while loading args
help() { echo "Please specify the file's location."; exit 1; }
 
# at least two args
if (($# < 1))
then
        help
fi
 
# getting user input flags and args
while getopts ":gpr:d:" opt; do
        case    $opt    in
                g)              graph=1;;
                p)              inc_plt=1;;
                r)              cllee=1 func_id=$OPTARG;;
                d)              cllr=1 func_id=$OPTARG;;
                *)              echo "Invalid option: -$OPTARG" >&2; exit 1;;
        esac
done
 
# shifting args
((OPTIND--))
shift $OPTIND
 
# passing the leftover args to a varible
filename=$*
 
if [[ $cllee -eq 1 && $cllr -eq 1 ]]; then
        echo "Can't have both -r and -d!"
        exit 1
fi
 
# the basic functionality into a temp file
objdump -d -j .text $filename > $tmp
 
# adding a semicolon at the end of each line for the graphviz syntax
if [ $graph -eq 1 ]; then
        output=$(awk '{gsub(/[<>:]/, "")} NF==2{name=$2;next} NF>2 && $0 ~ /callq/{print name, "->", $NF";"} ' $tmp | sort -u)
# normal behavior
else
        output=$(awk '{gsub(/[<>:]/, "")} NF==2{name=$2;next} NF>2 && $0 ~ /callq/{print name, "->", $NF} ' $tmp | sort -u)
fi
 
# removing all lines with an aterisk and init+
output=$(echo "$output" | sed -e '/*/d' -e '/init+/d')
 
# behavior based on passed flags
if [[ $graph -eq 0 && $inc_plt -eq 0 && $cllee -eq 0 && $cllr -eq 0 ]]; then ###
        output=$(echo "$output" | sed '/@plt/d')
        echo "$output"
        exit 0
elif [[ $graph -eq 1 && $inc_plt -eq 0 && $cllee -eq 0 && $cllr -eq 0 ]]; then ###
        output=$(echo "$output" | sed '/@plt/d')
        echo "digraph CG {"
        echo "$output"
        echo "}"
        exit 0
elif [[ $graph -eq 0 && $inc_plt -eq 1 && $cllee -eq 0 && $cllr -eq 0 ]]; then ###
        echo "$output"
        exit 0
elif [[ $graph -eq 0 && $inc_plt -eq 0 && $cllee -eq 1 && $cllr -eq 0 ]]; then ###
        output=$(echo "$output" | sed '/@plt/d' | awk -v pat="$func_id" '$3==pat{print $1,$2,$3}')
        echo "$output"
        exit 0
elif [[ $graph -eq 0 && $inc_plt -eq 0 && $cllee -eq 0 && $cllr -eq 1 ]]; then ###
        output=$(echo "$output" | sed '/@plt/d' | awk -v pat="$func_id" '$1==pat{print $1,$2,$3}')
        echo "$output"
        exit 0
elif [[ $graph -eq 1 && $inc_plt -eq 1 && $cllee -eq 0 && $cllr -eq 0 ]]; then ###
        output=$(echo "$output" | sed 's/@plt/_PLT/')
        echo "digraph CG {"
        echo "$output"
        echo "}"
        exit 0
elif [[ $graph -eq 1 && $inc_plt -eq 0 && $cllee -eq 1 && $cllr -eq 0 ]]; then #!! nevypisuje
        output=$(echo "$output" | sed '/@plt/d' | awk -v pat="$func_id" '$3==pat{print $1,$2,$3}')
        echo "digraph CG {"
        echo "$output"
        echo "}"
        exit 0
elif [[ $graph -eq 1 && $inc_plt -eq 0 && $cllee -eq 0 && $cllr -eq 1 ]]; then ###
        output=$(echo "$output" | sed '/@plt/d' | awk -v pat="$func_id" '$1==pat{print $1,$2,$3}')
        echo "digraph CG {"
        echo "$output"
        echo "}"
        exit 0
elif [[ $graph -eq 0 && $inc_plt -eq 1 && $cllee -eq 1 && $cllr -eq 0 ]]; then ###
        output=$(echo "$output" | awk -v pat="$func_id" '$3==pat{print $1,$2,$3}')
        echo "$output"
        exit 0
elif [[ $graph -eq 0 && $inc_plt -eq 1 && $cllee -eq 0 && $cllr -eq 1 ]]; then ###
        output=$(echo "$output" | awk -v pat="$func_id" '$1==pat{print $1,$2,$3}')
        echo "$output"
        exit 0
elif [[ $graph -eq 1 && $inc_plt -eq 1 && $cllee -eq 1 && $cllr -eq 0 ]]; then #!! nevypisuje
        output=$(echo "$output" | sed 's/@plt/_PLT/' | awk -v pat="$func_id" '$3==pat{print $1,$2,$3}')
        echo "digraph CG {"
        echo "$output"
        echo "}"
        exit 0
elif [[ $graph -eq 1 && $inc_plt -eq 1 && $cllee -eq 0 && $cllr -eq 1 ]]; then ###
        output=$(echo "$output" | sed 's/@plt/_PLT/' | awk -v pat="$func_id" '$1==pat{print $1,$2,$3}')
        echo "digraph CG {"
        echo "$output"
        echo "}"
        exit 0
fi