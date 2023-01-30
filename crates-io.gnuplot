set terminal png enhanced
set style data histogram
set style histogram cluster gap 0
set style fill solid border rgb "black"
set auto x
set xtics rotate by -45
set yrange [0:*]
set datafile separator ','
set key autotitle columnhead # use the first line as title
set terminal png size 1024, 720 font "Helvetica,8"
set xlabel "distribution of warning types on crates-io "
set ylabel "number of warnings"
set boxwidth 1
set key top right
set output 'crates-io.png'
plot "crates-io.csv" using 1:xtic(2) with boxes, "" using 0:($1 + 20000):(sprintf("%d", $1)) w labels notitle
