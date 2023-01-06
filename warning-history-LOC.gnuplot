# https://raymii.org/s/tutorials/GNUplot_tips_for_nice_looking_charts_from_a_CSV_file.html
set datafile separator ' '
set key autotitle columnhead # use the first line as title
set xlabel "revision history of the git repository"
set ylabel "number of warnings"
set y2tics # enable second axis
set ytics nomirror # dont show the tics on that side
set y2label "warnings per KLOC" # label for second axis
plot "counts.txt" using 1:2 with lines, '' using 1:($2*1000/$4) with lines axis x1y2