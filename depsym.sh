#!/bin/bash
### Jakub Vitasek, xvitas02, sk.41 ###
### depsym.sh ###

# initializing variables
output=0
obj1=0
obj2=0
obj_id=0
graph=0
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
while getopts ":gr:d:" opt; do
	case 	$opt 	in
		g)		graph=1;;
		r)		obj2=1 obj_id=$OPTARG;;
		d)		obj1=1 obj_id=$OPTARG;;
		*)		echo "Invalid option: -$OPTARG" >&2; exit 1;;
	esac
done

# shifting args
((OPTIND--))
shift $OPTIND

# passing the leftover args to a varible
filename=$*

if [[ $obj1 -eq 1 && $obj2 -eq 1 ]]; then
	echo "Can't have both -r and -d!"
	exit 1
fi

# the basic functionality into a temp file
nm $filename > $tmp
# getting the parts we need
output=$(awk 'NF==1{sub(/:$/, ""); p=$1;next} NF==3{print p, $2, $3;next} NF==2{print p, $1, $2}' "$tmp")
# filtering through to the formatted output
if [ $graph -eq 1 ]; then
	output=$(echo "$output" | awk '$3 in t{line[$3]=($2=="U")?$1" -> "t[$3]:t[$3]" -> "$1;next}{t[$3]=$1}
END{for(k in line) print line[k],"[label=\""k"\"];"}')
else
	output=$(echo "$output" | awk '$3 in t{line[$3]=($2=="U")?$1" -> "t[$3]:t[$3]" -> "$1;next}{t[$3]=$1}
END{for(k in line) print line[k],"("k")"}')
fi

if [[ $obj1 -eq 1 ]]; then
	output=$(echo "$output" | awk -v pat="$obj_id" '$1==pat{print $1,$2,$3,$4}')
elif [[ $obj2 -eq 1 ]]; then
	output=$(echo "$output" | awk -v pat="$obj_id" '$3==pat{print $1,$2,$3,$4}')
fi

# behavior based on passed flags
if [[ $graph -eq 0 ]]; then
	echo "$output"
	exit 0
elif [[ $graph -eq 1 ]]; then
	output=$(echo "$output" | sed -e 's/\./D/g' -e 's/+/P/g')
	echo "digraph GSYM {"
	echo "$output"
	echo "}"
	exit 0
elif [[ $graph -eq 0 && $obj1 -eq 1 && $obj2 -eq 0 ]]; then
	output=$(echo "$output" | awk -v pat="$obj_id" '$1==pat{print $1,$2,$3,$4}')
	echo "$output"
	exit 0
elif [[ $graph -eq 0 && $obj1 -eq 0 && $obj2 -eq 1 ]]; then
	output=$(echo "$output" | awk -v pat="$obj_id" '$3==pat{print $1,$2,$3,$4}')
	echo "$output"
	exit 0
elif [[ $graph -eq 1 && $obj1 -eq 1 && $obj2 -eq 0 ]]; then
	output=$(echo "$output" | awk -v pat="$obj_id" '$1==pat{print $1,$2,$3,$4}')
	output=$(echo "$output" | sed -e 's/\./D/g' -e 's/+/P/g')
	echo "digraph GSYM {"
	echo "$output"
	echo "}"
	exit 0
elif [[ $graph -eq 1 && $obj1 -eq 0 && $obj2 -eq 1 ]]; then
	output=$(echo "$output" | awk -v pat="$obj_id" '$3==pat{print $1,$2,$3,$4}')
	output=$(echo "$output" | sed -e 's/\./D/g' -e 's/+/P/g')
	echo "digraph GSYM {"
	echo "$output"
	echo "}"
	exit 0
fi