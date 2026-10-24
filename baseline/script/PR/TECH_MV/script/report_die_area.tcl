
set diearea [get_db designs .bbox]
puts "Die area : [join $diearea " "]"

set outfile [open [tech_mv_report_path 40 die_area rpt 06] w+]
puts $outfile "Die area : [join $diearea " "]"
close $outfile
