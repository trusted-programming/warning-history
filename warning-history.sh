#!/bin/bash
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
cd $(dirname $0) > /dev/null
p=$(pwd)
cd - > /dev/null
pushd $repo > /dev/null
if [ ! -d diagnosticses ]; then
	n=0
	mkdir -p diagnosticses
	git log -p --reverse | grep "^commit " | cut -d" " -f2 > git.log
	cat git.log | while read f; do
		git stash
		n=$(( n + 1 ))
		git checkout $f
		tokei -t=Rust src > $n-tokei.txt 
		g=$(grep -A1 $f git.log | tail -1)
		rust-diagnostics --patch $g --confirm > $n.txt
		if [ -d diagnostics ]; then
			mkdir -p diagnosticses/$n/$f
			mv diagnostics diagnosticses/$n/$f/
		else
			mkdir -p diagnosticses/$n/$f/
		fi
		mv $n.txt diagnosticses/$n/counts.txt
		mv $n-tokei.txt diagnosticses/$n/tokei.txt
	done
	git stash
	git checkout -f main
fi
#echo revision,warning,LOC,hash,date> counts.csv
echo date,warning,warning/file,warning/KLOC> counts.csv
find diagnosticses -name "counts.txt" | while read f; do
	g=$(basename $(dirname $f)/[a-f0-9][a-f0-9][a-f0-9]*)
	rev=$(basename $g)
#	d=$(git log $rev --pretty=format:'%ad' --date=iso |head -1)
	d=$(git log $rev --pretty=format:'%at' --date=iso |head -1)
#	echo $(basename $(dirname $f)),$(cat $f | grep -v "previously generated" | awk '{print $3, ",", $6}'),$(cat ${f/counts/tokei} | grep " Total" | awk '{print $3}'),$(basename $g),$d
#	echo $(basename $(dirname $f)),"\""$d"\"",$(cat $f | grep -v "previously generated" | awk '{print $3, ",", $6}'),$(cat ${f/counts/tokei} | grep " Total" | awk '{print $3}')
echo $(( d - 1667370179 )),$(cat $f | grep -v "previously generated" | head -1 | awk '{printf("%d,%d\n", $3, $6)}'),$(cat ${f/counts/tokei} | grep " Total" | awk '{print $3}')
done | sort -n -k1 >> counts.csv
grep "^\#\[Warning" diagnosticses/*/counts.txt | cut -d: -f2-4 | sort | uniq -c | sort -n
counts=$(grep "^\#\[Warning" diagnosticses/*/counts.txt | cut -d: -f2-4 | wc -l)
echo In total there have been $counts warnings fixed in the git history. 
#gnuplot -p $p/warning-history.gnuplot
#gnuplot -p $p/warning-history-files.gnuplot
gnuplot -p $p/warning-history-LOC.gnuplot
tar cfj $(basename $(pwd))-warnings.tar.bz2 diagnosticses counts.csv warning-history-per-KLOC.png
popd > /dev/null
