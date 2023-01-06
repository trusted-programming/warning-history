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
	git tag -f original
	mkdir -p diagnosticses
	git log -p --reverse | grep "^commit " | cut -d" " -f2 | while read f; do
		git stash
		n=$(( n + 1 ))
		git checkout $f
		tokei -t=Rust src > $n-tokei.txt 
		rust-diagnostics > $n.txt
		if [ -d diagnostics ]; then
			mkdir -p diagnosticses/$n/$f
			mv diagnostics diagnosticses/$n/$f/
		else
			mkdir -p diagnosticses/$n/$f/
		fi
		mv $n.txt diagnosticses/$n/counts.txt
		mv $n-tokei.txt diagnosticses/$n/tokei.txt
	done
	git checkout -f original
fi
echo revision warning_count file_count> counts.txt
find diagnosticses -name "counts.txt" | while read f; do
	echo $(basename $(dirname $f)) $(cat $f | grep -v "Marked warning(s) into" | awk '{print $3, $6}') $(cat ${f/counts/tokei} | grep " Total" | awk '{print $3}')
done | sort -n -k1 >> counts.txt
gnuplot -p $p/warning-history.gnuplot
gnuplot -p $p/warning-history-files.gnuplot
gnuplot -p $p/warning-history-LOC.gnuplot
popd > /dev/null
