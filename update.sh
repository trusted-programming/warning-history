find data -name diagnostics.log | xargs cat | grep -v "^There are" | awk -f split.awk 
wc *.java | sort -n -k1 -r | head -20
echo number of warnings, top 20 types of warning > clippy-warning-fix-count.csv
wc -l *.java | sort -n -k1 -r | head -20 | grep -v clippy.cs | grep -v total | \
	sed -e 's/\#\[Warning(//g' -e 's/).cs-java.txt.java//g' -e 's/^ *//g' -e 's/ /,/g' -e 's/_/-/g' \
	>> clippy-warning-fix-count.csv
gnuplot clippy-warning-fixes.gnuplot
exit 0
sudo cp clippy-warning-fixes.png /var/www/html
sudo cp clippy-warning-fix-count.csv /var/www/html
cd data
sudo sh copy.sh
sudo sh copy.sh
cd -
sudo cp clippy-warning-fix.tar.bz2 /var/www/html
