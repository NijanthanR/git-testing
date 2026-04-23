# OpenROAD floorplan script
puts "Starting floorplan... [pwd]"
flush stdout
source ../setup.tcl
source ../scripts/openroad/common.tcl
# Read floorplan control parameters from environment variables
set from_step ""
set to_step ""
set no_exit 0

# Check for environment variables
if {[info exists env(CHIPSUTRA_FLOORPLAN_FROM)]} {
    set from_step $env(CHIPSUTRA_FLOORPLAN_FROM)
    puts "Starting from step: $from_step"
}

if {[info exists env(CHIPSUTRA_FLOORPLAN_TO)]} {
    set to_step $env(CHIPSUTRA_FLOORPLAN_TO)
    puts "Running up to step: $to_step"
}

if {[info exists env(CHIPSUTRA_FLOORPLAN_NO_EXIT)]} {
    set no_exit 1
    puts "No exit mode enabled"
}


## sourcing all the procs used in openroad
source ../scripts/openroad/floorplan_procs.tcl

# Define floorplan subtasks
set floorplan_steps {setup setup_library read_design read_constraints create_floorplan place_macros insert_tap_cells place_pins additional_steps reports outputs}

# Determine start and end indices
set start_idx 0
set end_idx [expr {[llength $floorplan_steps] - 1}]

if {$from_step ne ""} {
    set start_idx [lsearch -exact $floorplan_steps $from_step]
    if {$start_idx == -1} {
        puts "Error: Invalid from step '$from_step'. Valid steps: $floorplan_steps"
        exit 1
    }
}

if {$to_step ne ""} {
    set end_idx [lsearch -exact $floorplan_steps $to_step]
    if {$end_idx == -1} {
        puts "Error: Invalid to step '$to_step'. Valid steps: $floorplan_steps"
        exit 1
    }
}

# Validate step range
if {$start_idx > $end_idx} {
    puts "Error: 'from' step ($from_step) comes after 'to' step ($to_step)"
    exit 1
}

puts "Executing steps [lindex $floorplan_steps $start_idx] to [lindex $floorplan_steps $end_idx]"

# Execute floorplan steps based on range
for {set step_idx $start_idx} {$step_idx <= $end_idx} {incr step_idx} {
    set current_step [lindex $floorplan_steps $step_idx]
    puts "=== Executing floorplan step: $current_step ==="
    
    switch -exact -- $current_step {
        "setup" {
           floorplan_setup
        }
        "setup_library" {
           floorplan_setup_library
        }
        "read_design" {
           floorplan_read_design
        }
        "read_constraints" {
           floorplan_read_constraints
        }
        "create_floorplan" {
           floorplan_create_floorplan 
        }
        "place_macros" {
           floorplan_place_macros 
        }
        "insert_tap_cells" {
           floorplan_insert_tap_cells
        }
        "place_pins" {
           floorplan_place_pins
        }
        "additional_steps" {
           floorplan_additional_steps
        }
        "reports" {
           floorplan_reports
        }
        "outputs" {
           floorplan_outputs
        }
    }
    
    puts "\n\n=== Completed floorplan step: $current_step ===\n\n"
    if {$to_step == $current_step} {
                set no_exit 1
            }
}



# Exit unless no_exit flag is set
if {!$no_exit} {
    puts "Floorplan completed successfully!"
    exit
} else {
    gui::show
}
