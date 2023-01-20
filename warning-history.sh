#!/bin/bash
#
# This script processes the history of a source Git repository of Rust project
# in order to find out how warnings have been addressed.
#
# Synoposis:
#
#	./warning-history.sh <path> [date]
#
# Arguments:
#
# 	$path -- indicates the path to a folder of Git repository
# 	$date -- indicates the date of the history since, e.g., "6 weeks ago"
#
# As a result, it produces the following files where $base refers to $(basename $path):
#
#   ./data/$base/diagnostics/$base-warnings.tar.bz2 -- the tarball of the results per project
#   ./data/$base/diagnostics/warning-history-per-KLOC.png -- number of warnings and ratio of warning density per KLOC over time
#   ./data/$base/diagnostics/counts.csv -- statistics data to generate the above figure
#   ./data/$base/diagnostics/git.log -- hashes of individual versions since $date according git log 
#   ./data/$base/diagnosticses/$i where i = 1 .. n -- folder of individual version from the date of analysis as v1.
#   ./data/$base/diagnosticses/$i/$hash where $hash is the hash of vi -- folder of individual vi 
#   ./data/$base/diagnosticses/$i/$hash/counts.txt -- output from rust-diagnostics, including warning pairs
#   ./data/$base/diagnosticses/$i/$hash/counts.txt/tokei.txt -- output from tokei, counting LOC in Rust
#
# At the end, it aggregates the individual warning pairs for CodeT5's "translate" task, and the "cs-java" sub-task.
# Specifically, we map the code hunks before fix as "cs", and the code hunks after fix as "java", e.g.,
# the warning accociated with `clippy::as_conversions` will be listed as parallel data in the following two files:
#
#   ./[Warning(clippy::as_conversions).cs-java.txt.cs
#   ./[Warning(clippy::as_conversions).cs-java.txt.java
#
# Overall, all these different types of warnings are aggregated into the following two files:
#
#   ./clippy.cs-java.txt.cs
#   ./clippy.cs-java.txt.java
#
# They are packed into the following tarball:
#   ./clippy-warning-fix.tar.bz2 -- the above warning data in CodeT5 format
#

# default value is the period of the major release cycle in Rust
checkpoint="20 years ago"
if [ "$2" != "" ]; then
	checkpoint="$2"
	dd=$(date +%s -d "$checkpoint")
fi

hash rust-diagnostics > /dev/null
if ! [ $? == 0 ]; then
	cargo install rust-diagnostics
fi
hash gnuplot > /dev/null
if ! [ $? == 0 ]; then
	sudo apt install gnuplot -y
	sudo apt install adwaita-icon-theme-full -y
fi
if [ "$1" == "" ]; then
	if [ -d .git ]; then
		repo=.
	else
		echo Please provide the path to git repository as an argument
	fi
else
	repo=$1
fi
data=data/$(basename $repo)
if [ ! -d $data ]; then
	rm -rf $data
	git clone $repo/.git $data
	git checkout -b master
fi
repo=$data
cd $(dirname $0) > /dev/null
p=$(pwd)
cd - > /dev/null
pushd $repo > /dev/null
m=-1
ls *-tokei.txt > t.t
if [ $? == 0 ]; then
	m=$(ls *-tokei.txt | sed -e "s/-tokei.txt//")
	echo resume from v$m
fi
if [ ! -d diagnosticses ] || ! [ "$m" -eq "-1" ]; then
	n=0
	mkdir -p diagnosticses
	git log -p --reverse --since="$checkpoint" | grep "^commit " | cut -d" " -f2 > git.log
	wc git.log
	cat git.log | while read f; do
		n=$(( n + 1 ))
		if [ $(( m != -1 )) ] && [ $n -ge $m ]; then
			git stash
			git checkout $f
			tokei -t=Rust src > $n-tokei.txt 
			g=$(grep -A1 $f git.log | tail -1)
			timeout 10m rust-diagnostics --patch $g --confirm --pair --function --single > $n.txt
			if [ -d diagnostics ]; then
				mkdir -p diagnosticses/$n/$f
				mv diagnostics diagnosticses/$n/$f/
			else
				mkdir -p diagnosticses/$n/$f/
			fi
			mv $n.txt diagnosticses/$n/counts.txt
			mv $n-tokei.txt diagnosticses/$n/tokei.txt
		fi
	done
	git stash
	git checkout -f master
fi
echo date,warning,warning/file,warning/KLOC> counts.csv
if [ "$2" == "" ]; then ## default is the Unix epoc of v1 
	dd=$(git log $(cat git.log | head -1) --pretty=format:'%at' --date=iso | head -1)
fi
find diagnosticses -name "counts.txt" | while read f; do
	g=$(basename $(dirname $f)/[a-f0-9][a-f0-9][a-f0-9]*)
	rev=$(basename $g)
	d=$(git log $rev --pretty=format:'%at' --date=iso |head -1)
	# The relative time since $dd
	# echo $(( d - dd )),$(cat $f | grep -v "previously generated" | head -1 | awk '{printf("%d,%d\n", $3, $6)}'),$(cat ${f/counts/tokei} | grep " Total" | awk '{print $3}')
	# Alternatively, the absolute time
	echo $d,$(cat $f | grep -v "previously generated" | head -1 | awk '{printf("%d,%d\n", $3, $6)}'),$(cat ${f/counts/tokei} | grep " Total" | awk '{print $3}')
done | sort -t, -n -k1,1 >> counts.csv
grep "^\#\[Warning" diagnosticses/*/counts.txt | cut -d: -f2-4 | sort | uniq -c | sort -n
counts=$(grep "^\#\[Warning" diagnosticses/*/counts.txt | cut -d: -f2-4 | wc -l)
echo In total there have been $counts warnings fixed in the git history. 
gnuplot -p $p/warning-history-LOC.gnuplot
# project specific tarball
tar cfj $(basename $(pwd))-warnings.tar.bz2 diagnosticses counts.csv warning-history-per-KLOC.png
cargo clean
popd > /dev/null
rm *.fix *.warn
cat data/*/diagnosticses/*/counts.txt | grep -v "^There are " | awk -f $p/split.awk
tar cfj clippy-warning-fix.tar.bz2 *.cs *.java
