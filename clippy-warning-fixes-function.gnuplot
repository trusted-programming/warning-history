set terminal png enhanced
set style data histogram
set style histogram cluster gap 0
set style fill solid border rgb "black"
set auto x
set xtics rotate
set yrange [0:10]
set y2range [0:100]
set datafile separator ','
set key autotitle columnhead # use the first line as title
set terminal png size 720, 480 font "Helvetica,8"
set xlabel "manually fixed warning types"
set ylabel "% warnings"
set boxwidth 1
set key top right
set output 'clippy-warning-fixes-function.png'
plot "clippy-warning-fixes-count-function.csv" using ($1*100/$3):xtic(2) with boxes, "" using 0:($1*100/$3+0.2):(sprintf("%3.1f %",$1*100/$3)) w labels notitle
# xtic(2):(sprintf("%3.2f",$1))
