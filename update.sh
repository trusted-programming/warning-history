find data -name counts.txt | xargs cat | grep -v "^There are"  > t.t
cat t.t | awk -f split.awk 
wc *.java | sort -n -k1
cd data
sudo sh copy.sh
sudo sh copy.sh
cd -
sudo cp clippy-warning-fix.tar.bz2 /var/www/html
