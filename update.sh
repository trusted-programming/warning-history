if [ "$1" == "" ]; then
	data=data3
	split=split
else
	data=$1
	split=split1
fi
mkdir var/www/html -p
for d in $data/*; do
  if [ -f $d/counts.csv ]; then
	  cd $d > /dev/null
	  e=$(basename $d)
	  gnuplot ../../warning-history-LOC.gnuplot
	  cp warning-history-per-KLOC.png var/www/html/$e.png
	  cd - > /dev/null
  fi
done
tail -20 crates-io-warnings.csv | sort -n -k1 -t, -r | sed -e 's/_/-/g' > crates-io.csv
gnuplot crates-io.gnuplot
cp crates-io.png var/www/html
find $data -name diagnostics.log | xargs cat | grep -v "^There are" | awk -f $split.awk 
ls *.cs | while read f; do 
	echo $(grep "^##\[Warning(" $f | wc -l) $f
done | sort -n -k1 -r | grep clippy | head -20
N=$(grep "^##\[Warning(" clippy.cs*.cs | wc -l) 
echo number of warnings, top-20 warning types, % of total $N warnings > clippy-warning-fixes-count-function.csv
ls *.cs | while read f; do 
	echo $(grep "^##\[Warning(" $f | wc -l) $f $N
done | sort -n -k1 -r | head -20 | grep clippy | grep -v clippy.cs | grep -v total | \
	sed -e 's/\#\#\[Warning(//g' -e 's/).cs-java.txt.cs//g' -e 's/^ *//g' -e 's/ /,/g' -e 's/_/-/g' -e 's/clippy:://g' \
	>> clippy-warning-fixes-count-function.csv
gnuplot clippy-warning-fixes-function.gnuplot
cp clippy-warning-fixes-function.png var/www/html
cp clippy-warning-fixes-count-function.csv var/www/html
cd $data
sh copy.sh
sh copy.sh
cd -
tar cfj clippy-warning-fixes-function.tar.bz2 clippy-warning-fixes-count-function.csv *.cs *.java
cp clippy-warning-fixes-function.tar.bz2 var/www/html
echo $(ls $data/*/diagnostics -dtr | wc -l) projects have been processed
