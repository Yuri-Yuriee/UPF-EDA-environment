# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
puts "User script [info script]"

set_db add_fillers_preserve_user_order true
set_db add_fillers_no_single_site_gap false
set_db add_fillers_with_drc true

set_db add_fillers_cells $FILLER_FLOW_CELLS

add_fillers

check_filler

# if there's filler gap, delete the nearby violation TAPCUTOD manually, and re-run add_fillers
# add_fillers
# check_filler


#check_drc
#add_fillers -fix_drc

write_db dbs/15_add_filler.enc