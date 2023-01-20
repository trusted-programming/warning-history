#!/bin/bsh
page=/var/www/html/rust-diagnostics.html
echo "Ordered by length of git history <ul>" > $page
cat ../../../rust-lang/rust-counts.csv | while read a; do
   f=${a%% *}
   g=${a%%* }
   if [ -f /var/www/html/$f.png ]; then
	echo "<li><a href='$f.png'>$f - $g</a></li>" >> $page
   fi
done
echo "</ul>" >> $page
echo "Ordered alphabetically <ul>" >> $page
for d in */warning-history-per-KLOC.png; do
	if [ -f $d ]; then
		f=$(basename $(dirname $d))
		sudo cp $d /var/www/html/$f.png
		echo "<li><a href='$f.png'>$f</a></li>" >> $page
	fi
done
echo "</ul>" >> $page
