set terminal png enhanced
set style data histogram
set style histogram cluster gap 1
set style fill solid border rgb "black"
set auto x
set yrange [0:*]
set datafile separator ','
set key autotitle columnhead # use the first line as title
set xlabel "manually fixed warning types"
set ylabel "number of warnings"
set output 'clippy-warning-fixes.png'
plot "clippy-warning-fix-count.csv" using 1:xtic(2)
