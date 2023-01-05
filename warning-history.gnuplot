set datafile separator ' '
plot "counts.txt" using 1:2 with lines
set xlabel "revision history of the git repository"
set ylabel "number of warnings"
