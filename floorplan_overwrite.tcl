# ================================
# FLOORPLAN OVERRIDE SCRIPT
# ================================

puts " Loading custom floorplan override..."

# --------------------------------
# OVERRIDE EXISTING PROC
# --------------------------------
catch {rename floorplan_create_floorplan floorplan_create_floorplan_old}

proc floorplan_create_floorplan {} {

    puts " Running AUTO floorplan (25% utilization)..."

    # --------------------------------
    # 1. COMPUTE TOTAL CELL AREA
    # --------------------------------
    set total_area 0

    foreach inst [get_cells -hierarchical] {
        set area [get_property $inst area]
        if {$area != ""} {
            set total_area [expr {$total_area + $area}]
        }
    }

    if {$total_area == 0} {
        puts " ERROR: Cell area is zero. Check design loading."
        exit
    }

    puts " Total Cell Area: $total_area"

    # --------------------------------
    # 2. APPLY UTILIZATION = 25%
    # --------------------------------
    set utilization 0.25
    set core_area [expr {$total_area / $utilization}]

    puts " Target Core Area: $core_area"

    # --------------------------------
    # 3. COMPUTE CORE DIMENSIONS
    # --------------------------------
    set core_width  [expr {sqrt($core_area)}]
    set core_height $core_width

    puts " Core Size: $core_width x $core_height"

    # --------------------------------
    # 4. ADD MARGIN (IO + ROUTING)
    # --------------------------------
    set margin 20

    set die_width  [expr {$core_width + 2*$margin}]
    set die_height [expr {$core_height + 2*$margin}]

    puts " Die Size: $die_width x $die_height"

    # --------------------------------
    # 5. CREATE FLOORPLAN
    # --------------------------------
    initialize_floorplan \
        -die_area "0 0 $die_width $die_height" \
        -core_area "$margin $margin \
                    [expr {$margin + $core_width}] \
                    [expr {$margin + $core_height}]"

    make_tracks

    puts " Floorplan created"

    # --------------------------------
    # 6. TAP CELLS (SAFE TO ADD HERE)
    # --------------------------------
    tapcell -distance 14
    puts " Tapcells inserted"

    # --------------------------------
    # 7. SIMPLE IO PIN DISTRIBUTION
    # --------------------------------
    set pins [all_inputs]
    set num_pins [llength $pins]

    if {$num_pins > 0} {

        set spacing [expr {$core_width / $num_pins}]
        set x $margin

        foreach pin $pins {
            place_pin $pin $x $die_height
            set x [expr {$x + $spacing}]
        }

        puts " IO pins placed on top edge"
    } else {
        puts " No input pins found"
    }

    puts " Custom floorplan override completed"
}

# --------------------------------
# CONFIRM OVERRIDE
# --------------------------------
puts " floorplan_create_floorplan successfully overridden"