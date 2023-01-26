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
#   ./data/$base/diagnostics/$hash where $hash is the hash of v_i -- folder of individual v_i 
#   ./data/$base/diagnostics/$hash/tokei.txt -- output from tokei, counting LOC in Rust
#   ./data/$base/diagnostics/$hash/diagnostics.json -- diagnostic messages from the first run of `cargo clippy`
#   ./data/$base/diagnostics/$hash/diagnostics.log -- output from `rust-diagnostics`, including warning pairs
#       by default: the pair is a diff patch
#   	by the option --pair : the pair are texts before and after the patch
#   	by the options --pair --function: the pair are functions before and after the patch
#   	by the options --pair --function --single: the pair are functions before and after the patch which fixes a single warning
#   	by the options --pair --function --single --location: the pair are
#   		functions before and after the patch which fixes a single warning while
#   		the function before is located and marked up by warning hints 
#   	by the options --pair --function --single --location --mixed: the first
#   		part of the pair is the function before the patch which fixes a single
#   		warning and the function before is located and marked up by warning
#   		hints, while the second part is the patch text
#   ./data/$base/diagnostics/$hash/src/*.rs -- output from `rust-diagnostics`, mark up Rust code with warnings
#
# At the end, it aggregates individual warning pairs for CodeT5's "translate" task, and the "cs-java" sub-task.
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
checkpoint="30 years ago"
#checkpoint="12 months ago"
if [ "$2" != "" ]; then
	if [ "$2" != "tags" ]; then
		checkpoint="$2"
	fi
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
	main=$(ls $repo/.git/refs/heads)
	git checkout -b $main
else
	cd $data
	git pull
	cd -
fi
repo=$data
main=$(ls $repo/.git/refs/heads)
cd $(dirname $0) > /dev/null
p=$(pwd)
cd - > /dev/null
pushd $repo > /dev/null
if [ "$2" == "tags" ]; then
	git for-each-ref --sort=creatordate --format '%(objectname)' refs/tags > git.log
else
	git log -p --reverse --since="$checkpoint" | grep "^commit " | cut -d" " -f2 > git.log
fi
cat git.log | while read f; do
	if [ ! -f "diagnostics/$f/tokei.txt" ]; then
		git stash
		git checkout $f
		g=$(grep -A1 $f git.log | tail -1)
		timeout 10m rust-diagnostics --patch $g --confirm --pair --function --single --mixed --location 
		tokei -t=Rust src > diagnostics/$f/tokei.txt 
	fi
done
git stash
git checkout -f $main
echo date,warning,warning/file,warning/KLOC> counts.csv
cat git.log | while read rev; do 
	d=$(git log $rev --pretty=format:'%at' --date=iso -- | head -1)
	echo $d,$(cat diagnostics/$rev/diagnostics.log | grep -v "previously generated" | head -1 | awk '{printf("%d,%d\n", $3, $6)}'),$(cat diagnostics/$rev/tokei.txt | grep " Total" | awk '{print $3}')
done | sort -t, -n -k1,1 >> counts.csv
find . -name diagnostics.log | xargs cat | grep "^\#\[Warning" | cut -d: -f1-4 | sort | uniq -c | sort -n
counts=$(find . -name diagnostics.log | xargs cat | grep "^\#\[Warning" | cut -d: -f1-4 | wc -l)
echo In total there have been $counts warnings fixed in the git history. 
gnuplot -p $p/warning-history-LOC.gnuplot
cargo clean
popd > /dev/null
rm *.cs *.java
find . -name diagnostics.log | xargs cat | grep -v "^There are " | awk -f $p/split.awk
tar cfj clippy-warning-fix.tar.bz2 *.cs *.java
