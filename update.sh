if [ "$1" == "" ]; then
	data=data
	split=split
else
	data=$1
	split=split1
fi
for d in $data/*; do
  if [ -f $d/counts.csv ]; then
	  cd $d > /dev/null
	  e=$(basename $d)
	  gnuplot ../../warning-history-LOC.gnuplot
	  sudo cp warning-history-per-KLOC.png /var/www/html/$e.png
	  cd - > /dev/null
  fi
done
find $data -name diagnostics.log | xargs cat | grep -v "^There are" | awk -f $split.awk 
ls *.cs | while read f; do 
	echo $(grep "^##\[Warning(" $f | wc -l) $f
done | sort -n -k1 -r | head -20
echo number of warnings, top 20 types of warning > clippy-warning-fix-count.csv
ls *.cs | while read f; do 
	echo $(grep "^##\[Warning(" $f | wc -l) $f
done | sort -n -k1 -r | head -20 | grep -v clippy.cs | grep -v total | \
	sed -e 's/\#\#\[Warning(//g' -e 's/).cs-java.txt.java//g' -e 's/^ *//g' -e 's/ /,/g' -e 's/_/-/g' \
	>> clippy-warning-fixes-count-function.csv
gnuplot clippy-warning-fixes-function.gnuplot
sudo cp clippy-warning-fixes-function.png /var/www/html
sudo cp clippy-warning-fixes-count-function.csv /var/www/html
cd $data
sudo sh copy.sh
sudo sh copy.sh
cd -
tar cfj clippy-warning-fixes-function.tar.bz2 clippy-warning-fixes-count-function.csv *.cs *.java
sudo cp clippy-warning-fixes-function.tar.bz2 /var/www/html
echo $(ls data/*/diagnostics -dtr | wc -l) projects have been processed
