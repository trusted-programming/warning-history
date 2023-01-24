# https://raymii.org/s/tutorials/GNUplot_tips_for_nice_looking_charts_from_a_CSV_file.html
# https://stackoverflow.com/questions/36138334/how-to-concatenate-strings-in-gnuplot
# https://stackoverflow.com/questions/32354387/reading-plot-names-from-folder-using-gnuplot
set datafile separator ','
set key autotitle columnhead # use the first line as title
set terminal png size 2000,800 enhanced font "Helvetica,20"
set output 'warning-history-per-KLOC.png'
#plot "counts.csv" using 1:($2==0?NaN:$2) with lines, '' using 1:($2==0?NaN:$2*1000/$4) with lines axis x1y2
set multiplot layout 2,1
set ylabel "number of warnings"
plot "counts.csv" using 1:($2==0?NaN:$2) with lines
repo=system("basename $(pwd)")
set xlabel "evolution of the git repository: " . repo
set ylabel "warnings per KLOC" # label for second axis
plot "counts.csv" using 1:($2==0?NaN:$2*1000/$4) with lines
