proc floorplan_setup {} {
    puts "Chipsutra step: proc_name > [lindex [info level 0] 0]"
    puts "Setting up floorplan environment... "
    puts "Chipsutra Info Library Name: ${setup::library:library:name}"
    puts "Chipsutra Info Library Technology Node: ${setup::library:library:technology_node}"
    puts "Chipsutra Info Library Description: ${setup::library:library:description}"
    puts "Chipsutra Info Library Foundry: ${setup::library:library:foundry}"
    puts "Chipsutra Info Library Process: ${setup::library:library:process}"
}

proc floorplan_setup_library {} {
    puts "Chipsutra step: proc_name > [lindex [info level 0] 0]"
    puts "Setting up library for floorplan..."
    puts "Chipsurta Info Library Corners: ${setup::library:library_info:pvt_corners}"
    common_setup_library
}

proc floorplan_read_design {} {
    puts "Chipsutra step: proc_name > [lindex [info level 0] 0]"
    puts "Reading design for floorplan implementation... ../synthesis/outputs/${setup::design:design:top_module}.synth.v"
    if {[file exists ../synthesis/outputs/${setup::design:design:top_module}.synth.v]} {
        read_verilog ../synthesis/outputs/${setup::design:design:top_module}.synth.v
    } else {
        puts "Chipsutra ERROR: Synthesis output file ../synthesis/outputs/${setup::design:design:top_module}.synth.v not found. Please ensure synthesis step is completed."
        exit 1
    }
    link_design ${setup::design:design:top_module}
}

proc floorplan_read_constraints {} {
    puts "Chipsutra step: proc_name > [lindex [info level 0] 0]"
    puts "Reading constraints for floorplan..."
    if {[info exists setup::design:constraints:sdc_file]} {
        puts "Chipsutra Info: loading SDC file ${setup::design:constraints:sdc_file}"
        read_sdc ${setup::design:constraints:sdc_file}
    } else {
        puts "Chipsutra Error: SDC file not found."
    }
    ### setup IO constraints
    set con "report_clock_properties"
    tee -variable exec $con
    set clk_period [lindex $exec 5]
    set clk_name [lindex $exec 4]

    set_input_delay [expr {( ${setup::design:constraints:input_delay} / 100.0 ) * $clk_period}] -clock $clk_name [all_inputs -no_clocks]
    set_output_delay [expr {( ${setup::design:constraints:output_delay} / 100.0 ) * $clk_period}] -clock $clk_name [all_outputs]
}

proc floorplan_create_floorplan {} {
    puts "Chipsutra step: proc_name > [lindex [info level 0] 0]"
    puts "Creating floorplan..."

    set def_file "setup::design:${setup::library:library:name}:def_file"
    if {[info exists $def_file] && [set $def_file] ne "auto"} {
        puts "Chipsutra Info: Def file is present, reading def file from [set $def_file]"
        catch {read_def [set $def_file] -floorplan_initialize -continue_on_error}
    } else {
        puts "Chipsutra Info: Def file is not present creating floorplan from scratch"
        if {[info exists setup::design:physical:die_area]} {
            set util ${setup::design:physical:core_utilization}
        } else {
            set util 50
        }
        puts "Chipsutra Info: Die Utilization set to $util %"
        if {[info exists setup::design:physical:aspect_ratio]} {
            set aspect_ratio ${setup::design:physical:aspect_ratio}
        } else {
            set aspect_ratio 1
        }
        puts "Chipsutra Info: Aspect Ratio set to $aspect_ratio"

        initialize_floorplan    -utilization $util \
                                -aspect_ratio $aspect_ratio \
                                -core_space 20 \
                                -site ${setup::library:technology:site_name}
        puts "Chipsutra Info: creating tracks"
        if {[info exists library:technology:make_track]} {
            source ${setup::library:technology:make_track}
        } else {
            puts "Chipsutra Warning: No track information found in library.ini, using default track settings."
            make_tracks
        }
    }
}

proc floorplan_place_macros {} {
    puts "Chipsutra step: proc_name > [lindex [info level 0] 0]"
    puts "Placing macros..."
    
}

proc floorplan_insert_tap_cells {} {
    puts "Chipsutra step: proc_name > [lindex [info level 0] 0]"
    puts "Inserting tap cells..."
    catch {tapcell -distance 13 -tapcell_master ${setup::library:special_cells:tapcell_master} -endcap_master ${setup::library:special_cells:endcap_master} -tap_prefix TAP_ -endcap_prefix PHY_}
}

proc floorplan_place_pins {} {
    puts "Chipsutra step: proc_name > [lindex [info level 0] 0]"
    puts "Placing pins..."
  
    set port_file_var "setup::design:${setup::library:library:name}:port_placement_file"
    set def_file "setup::design:${setup::library:library:name}:def_file"
    if {[info exists $port_file_var] && [set ${port_file_var}] ne "auto"} {
        source [set $port_file_var]
    } else {
        if {[info exists $def_file] && [set $def_file] eq "auto"} {
            puts "Chipsutra Info: using port placement is set to automatic"
            place_pins -hor_layers ${setup::library:preference:port_horizontal_layers} -ver_layers ${setup::library:preference:port_vertical_layers} -random -min_distance 10 -corner_avoidance 10 -exclude top:0-20 -exclude bottom:0-20 -exclude left:0-20 -exclude right:0-20
        }
    }
}

proc floorplan_additional_steps {} {
    puts "Chipsutra step: proc_name > [lindex [info level 0] 0]"
    puts "Performing additional steps..."
}

proc floorplan_reports {} {
    puts "Chipsutra step: proc_name > [lindex [info level 0] 0]"
    puts "Generating reports..."
########## Die and core area report ############
    set units [[[::ord::get_db] getTech] getDbUnitsPerMicron]

    set llx_die [expr {[[[[[::ord::get_db] getChip] getBlock] getDieArea] xMin] / "$units.0" } ]
    set lly_die [expr {[[[[[::ord::get_db] getChip] getBlock] getDieArea] yMin] / "$units.0" } ]
    set urx_die [expr {[[[[[::ord::get_db] getChip] getBlock] getDieArea] xMax] / "$units.0" } ]
    set ury_die [expr {[[[[[::ord::get_db] getChip] getBlock] getDieArea] yMax] / "$units.0" } ]

    set Die_area [expr {($urx_die - $llx_die) * ($ury_die - $lly_die)}]

    set llx_core [expr {[[[[[::ord::get_db] getChip] getBlock] getCoreArea] xMin] / "$units.0"} ]
    set lly_core [expr {[[[[[::ord::get_db] getChip] getBlock] getCoreArea] yMin] / "$units.0"} ]
    set urx_core [expr {[[[[[::ord::get_db] getChip] getBlock] getCoreArea] xMax] / "$units.0"} ]
    set ury_core [expr {[[[[[::ord::get_db] getChip] getBlock] getCoreArea] yMax] / "$units.0"} ]

    set Core_area [expr {($urx_core - $llx_core) * ($ury_core - $lly_core)}]

    set report [open reports/core_and_die_area.rpt w]
    puts -nonewline $report "Die_Area = $Die_area microns^2"
    puts -nonewline $report "\ncore_Area = $Core_area microns^2"

    close $report

##################### Pin placement report###################
write_pin_placement reports/pin_placement.tcl

########### Macro placement report ##########################
write_macro_placement reports/macro_placement.tcl

#############################################################
#set pwr_domains [[[[::ord::get_db] getChip] getBlock] getPowerDomains]
#set blockages [[[[::ord::get_db] getChip] getBlock] getBlockages]

}

proc floorplan_outputs {} {
    puts "Chipsutra step: proc_name > [lindex [info level 0] 0]"
    puts "Generating outputs..."
    write_def outputs/${setup::design:design:top_module}.floorplan.def
    write_database -path database/floorplan -name ${setup::design:design:top_module}
}
