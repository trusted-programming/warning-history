#!/bin/bash
hash rust-diagnostics
if ! [ $? == 0 ]; then
	cargo install rust-diagnostics
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
pushd $repo > /dev/null
git tag -f original
n=0
rm -rf diagnosticses
mkdir -p diagnosticses
git log -p --reverse | grep "^commit " | cut -d" " -f2 | while read f; do
	n=$(( n + 1 ))
	git checkout $f
	rust-diagnostics > $n.txt
	if [ -d diagnostics ]; then
		mv diagnostics diagnosticses/$n
	else
		mkdir -p diagnosticses/$n
	fi
	mv $n.txt diagnosticses/$n/counts.txt
done
git checkout -f original
popd > /dev/null
