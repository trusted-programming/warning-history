#!/bin/bsh
page=/var/www/html/rust-diagnostics2.html
echo > $page
#echo "<a href='../clippy-warning-fix-count.csv'>warning fixes counts</a>" >> $page
#echo "<a href='../clippy-warning-fix.tar.bz2'>data</a><br/>" >> $page
echo "Ordered by length of git history <ul>" >> $page
cat ../../../rust-lang/rust-counts.csv | while read a; do
   f=${a%% *}
   g=${a%%* }
   if [ -f /var/www/html/$f.png ]; then
	echo "<li><a href='$f.png'>$g</a></li>" >> $page
   else 
	echo "<li> $g -- (pending ...)</li>" >> $page
   fi
done
echo "</ul>" >> $page
