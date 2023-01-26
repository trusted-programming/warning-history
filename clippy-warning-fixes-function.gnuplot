set terminal png enhanced
set style data histogram
set style histogram cluster gap 0
set style fill solid border rgb "black"
set auto x
set xtics rotate
set yrange [0:*]
set datafile separator ','
set key autotitle columnhead # use the first line as title
set terminal png size 720, 480 font "Helvetica,8"
set xlabel "manually fixed warning types"
set ylabel "number of warnings"
set boxwidth 1
set output 'clippy-warning-fixes-function.png'
plot "clippy-warning-fixes-count-function.csv" using 1:xtic(2) 
