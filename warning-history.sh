#!/bin/bash
#
# This script processes the history of a source Git repository of Rust project
# in order to find out how warnings have been addressed.
#
# Synoposis:
#
#	cp config.$rules.toml $HOME/.cargo/config
#	./warning-history.sh <path> [date]
#
# Arguments:
#
# 	$path -- indicates the path to a folder of Git repository
# 	$date -- indicates the date of the history since, e.g., "6 weeks ago"
# 	$rules -- which set of lint rules to use for the data collection
# 	   data=data1	- unwrap_used: just the unwrap_used rule
#          data=data2		- machine_applicable: the lint rules that are meant to be machine applicable
# 	   data=data3	- conventions: the lint rules that according to Rust conventions
# 	   data=data4	- combined: all these rules
#
# 		* Note that the more rules are chosen, the fewer samples we may
# 		extract because one-to-one mapping between hunks and lint types
# 		are less common when the number of lint types is larger
#
# As a result, it produces the following files where $base refers to $(basename $path):
#
#   ./$data/$base/diagnostics/$base-warnings.tar.bz2 -- the tarball of the results per project
#   ./$data/$base/diagnostics/warning-history-per-KLOC.png -- number of warnings and ratio of warning density per KLOC over time
#   ./$data/$base/diagnostics/counts.csv -- statistics data to generate the above figure
#   ./$data/$base/diagnostics/git.log -- hashes of individual versions since $date according git log 
#   ./$data/$base/diagnostics/$hash where $hash is the hash of v_i -- folder of individual v_i 
#   ./$data/$base/diagnostics/$hash/tokei.txt -- output from tokei, counting LOC in Rust
#   ./$data/$base/diagnostics/$hash/diagnostics.json -- diagnostic messages from the first run of `cargo clippy`
#   ./$data/$base/diagnostics/$hash/diagnostics.log -- output from `rust-diagnostics`, including warning pairs
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
#   ./$data/$base/diagnostics/$hash/src/*.rs -- output from `rust-diagnostics`, mark up Rust code with warnings
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

case "$3" in
1) 
     data=data1
     cp config.unwrap_used.toml $HOME/.cargo/config
     break
     ;;
2)
     data=data2
     cp config.machineapplicable.toml $HOME/.cargo/config
     break
     ;;
3)
     data=data3
     cp config.conventions.toml $HOME/.cargo/config
     break
     ;;
4)
     data=data4
     cp config.combined.toml $HOME/.cargo/config
     break
     ;;
*)
     data=data1
     cp config.unwrap_used.toml $HOME/.cargo/config
     break
     ;;
fi

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
data=$data/$(basename $repo)
if [ ! -d $data ]; then
	rm -rf $data
	git clone $repo/.git $data
	main=$(ls $repo/.git/refs/heads)
	git checkout -b $main
else
	cd $data > /dev/null
	git pull
	cd - > /dev/null
fi
repo=$data
main=$(ls $repo/.git/refs/heads)
cd $(dirname $0) > /dev/null
p=$(pwd)
cd - > /dev/null
pushd $repo > /dev/null
echo $(pwd)
if [ "$2" == "tags" ]; then
	git for-each-ref --sort=creatordate --format '%(objectname) %(refname:short)' refs/tags > git.log
	if [ ! -e git.log ] || [ ! -s git.log ]; then # fall back when there was no tags
		git log -p --reverse --since="$checkpoint" | grep "^commit " | cut -d" " -f2 > git.log
	fi
else
	git log -p --reverse --since="$checkpoint" | grep "^commit " | cut -d" " -f2 > git.log
fi
cat git.log | while read f; do
	tag=${f/[^ ]* /}
	f=${f/ [^ ]*/}
	if [ ! -f "diagnostics/$f/tokei.txt" ] || [ ! -f "diagnostics/$f/diagnostics.log" ]; then
		git stash
		git checkout -f $f
		# avoid extra downloads to save disk space 
		rm -f rust-toolchain
		g=$(grep -A1 $f git.log | tail -1 | cut -d" " -f1)
		if [ ! -f "diagnostics/$f/diagnostics.log" ]; then
			timeout 10m rust-diagnostics --patch $g --confirm --pair --function --single --mixed --location
		fi
		if [ ! -f "diagnostics/$f/tokei.txt" ]; then
			mkdir -p diagnostics/$f
			tokei -t=Rust src > diagnostics/$f/tokei.txt 
		fi
	fi
done
echo date,warning,warning fixed,warning per KLOC> counts.csv
cat git.log | while read rev; do 
	tag=${rev/* /}
	rev=${rev% *}
	d=$(git log $rev --pretty=format:'%at' --date=iso -- | head -1)
	echo $d,$(cat diagnostics/$rev/diagnostics.log | grep -v "previously generated" | head -1 | awk '{printf("%d,%d\n", $3, $8)}'),$(cat diagnostics/$rev/tokei.txt | grep " Total" | awk '{print $3}'),$tag
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
