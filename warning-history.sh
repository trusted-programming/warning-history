#!/bin/bash
hash rust-diagnostics
if ! [ $? == 0 ]; then
	cargo install rust-diagnostics
fi
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
