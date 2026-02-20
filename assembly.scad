// ============================================================================
// assembly.scad — AOCL Box & Racks Assembly (NATIVE)
// ============================================================================
// Copyright (c) 2026 madfam-org
// Licensed under the CERN Open Hardware Licence Version 2 - Weakly Reciprocal (CERN-OHL-W-2.0).
//
// Welcome to the Assembly module! This file acts as the master scene that brings 
// all our individually designed parts (racks, boxes) together into a single 
// view, and adds "glass slides" to show how everything fits and operates.
//
// Think of this script as the instructions for putting Lego pieces together.

// "use" allows us to call modules from other files without executing their global code.
use <rack.scad>
use <box.scad>

// "include" brings in an external library entirely (BOSL2 here provides advanced shapes if needed).
include <BOSL2/std.scad>

// --- Configuration Parameters ---

// Assembly Level allows us to toggle between 3 different stages of assembly.
// Mode 1: Just a single Rack, loaded with glass slides.
// Mode 2: The bottom Box Base, loaded with 3 Racks, each loaded with slides.
// Mode 3: Everything in Mode 2, but we also place the Lid on top to close the box.
assembly_level = 1;

// Part renderer (-1 = Draw Everything, 1 = Draw Racks, 2 = Draw Base, 3 = Draw Lid)
// The Yantra4D frontend API injects this parameter to map materials and colors individually
render_mode = -1;

// --- Physical Dimensions ---
// Note: We redefine the core measurements here so that our assembly math perfectly 
// aligns with the separate source files without having to pass variables around globally.

custom_slide_length = 25.4; // Standard AOCL slide length (25.4mm = 1 inch)
custom_slide_width = 25.4; // Standard AOCL slide width
custom_slide_thickness = 1.0; // Standard AOCL glass slide thickness
tolerance_xy = 0.4; // Wiggle room left and right to allow for 3D printer imprecision
tolerance_z = 0.2; // Wiggle room top and bottom
num_slots = 10; // How many slides fit into one rack
num_racks = 3; // How many racks fit into one box
wall_thickness = 2.0; // Thickness of the standard plastic walls

// --- Math & Alignment Variables ---
// We calculate the exact footprint of the objects so we know where to place them.

// 1. Rack Footprint Math
_crossbar_h = 2.5; // Height of the bottom floor/crossbars in the rack
_min_rib_w = 2.75; // Width of the plastic separators (ribs) holding the slides
_slot_w = custom_slide_thickness + tolerance_z + 0.2; // How wide the actual opening needs to be for the slide
_pitch = _slot_w + _min_rib_w; // "Pitch" is the distance from the start of one slot to the start of the next one
_base_h = _crossbar_h; // Where the slide sits vertically in the rack (on top of the crossbars)

// Calculating the entire width (X) and length (Y) of *one* full rack
_rack_x = (num_slots * _pitch) + _min_rib_w + (2 * wall_thickness);
_rack_y = custom_slide_length + (2 * wall_thickness) + tolerance_xy;
_rack_clearance = 0.5; // Wiggle room between the rack & the box guide rails

// Calculating the exact height (Z) of *one* full rack
_slot_depth = custom_slide_width + tolerance_xy;
_rack_z = _slot_depth + _crossbar_h;

// 2. Box Cavity Math
// Calculate the hollow interior size of the box based on how many racks we need it to hold
_inner_x = num_racks * (_rack_x + _rack_clearance) + _rack_clearance;
_inner_y = _rack_y + _rack_clearance * 2;
_inner_z = max(26.0 - 2 * wall_thickness, _rack_z + _rack_clearance);

// 3. Lid Positioning Math
// We need to know where the outer edges of the box are to snap the lid perfectly over it.
_box_x = _inner_x + 2 * wall_thickness;
_box_y = _inner_y + 2 * wall_thickness;
_box_z = _inner_z + wall_thickness; // Absolute top of the open box
_lid_clearance = 0.3; // Extra space so the lid isn't too tight
_lid_wall = 1.5; // The thickness of the lid's walls
_o_y = _box_y + _lid_clearance * 2 + _lid_wall * 2; // Outer dimension for the lid

// --- Visual Modules ---

// Module: Creates a semi-transparent, light-blue "glass slide"
module slide() {
  // We use RGBA color: Red=0.8, Green=0.9, Blue=0.95, Alpha (transparency)=0.6
  color([0.8, 0.9, 0.95, 0.6])
    cube([custom_slide_thickness, custom_slide_length, custom_slide_width]);
}

// Module: Creates one field of glass slides for a single rack (positional only, no rack body)
module slides_for_rack() {
  for (i = [0:num_slots - 1]) {
    translate([wall_thickness + i * _pitch + _min_rib_w + (_slot_w - custom_slide_thickness) / 2, wall_thickness + tolerance_xy / 2, _base_h])
      slide();
  }
}

// Module: Renders one Rack and fills its slots with glass slides
module racks_with_slides() {
  // 1. Draw the physical rack model (imported from rack.scad)
  rack_complete();

  // 2. Overlay the glass slides
  slides_for_rack();
}

// Module: Renders ONLY the glass slides at their correct assembly positions
module slides_only() {
  if (assembly_level == 1) {
    // Single rack with slides
    slides_for_rack();
  } else {
    // Multiple racks inside the box — position matches box_assembly() placement
    for (r = [0:num_racks - 1]) {
      _rx = wall_thickness + _rack_clearance + r * (_rack_x + _rack_clearance);
      translate([_rx, wall_thickness + _rack_clearance, wall_thickness])
        slides_for_rack();
    }
  }
}

// Module: Renders the Box Base and populates it with 3 completed slide-racks
module box_assembly() {
  // 1. Draw the physical box base (imported from box.scad)
  box_base();

  // 2. Run a loop to place all the required racks inside the box cavity
  for (r = [0:num_racks - 1]) {
    // Calculate the starting X coordinate for each rack. 
    // Skips over previously placed racks + the guide rails separating them.
    _rx = wall_thickness + _rack_clearance + r * (_rack_x + _rack_clearance);

    // Translate (move) the completed rack to its designated slot inside the box
    translate([_rx, wall_thickness + _rack_clearance, wall_thickness])
      racks_with_slides();
    // Draw the rack containing the slides!
  }
}

// --- Main Execution Logic ---
// We check the "render_mode" variable configured by the frontend API
// to decide if we should isolate a specific part to export.

if (render_mode == 1) {
  // 1 = Rack(s)
  if (assembly_level == 1) {
    racks_with_slides();
  } else {
    for (r = [0:num_racks - 1]) {
      _rx = wall_thickness + _rack_clearance + r * (_rack_x + _rack_clearance);
      translate([_rx, wall_thickness + _rack_clearance, wall_thickness])
        racks_with_slides();
    }
  }
} else if (render_mode == 2) {
  // 2 = Box Base
  box_base();
} else if (render_mode == 3) {
  // 3 = Box Lid
  translate(
    [
      -(_lid_wall + _lid_clearance),
      -(_lid_wall + _lid_clearance) + _o_y,
      _box_z + 1.5,
    ]
  )
    rotate([180, 0, 0])
      box_lid();
} else if (render_mode == 4) {
  // 4 = Slides only — AOCL glass substrates positioned in their assembly slots
  slides_only();
} else {
  // If no explicit render_mode is given (-1), we render the full visual assembly preview
  if (assembly_level == 1) {
    // Mode 1: Render just the single rack with slides.
    racks_with_slides();
  } else if (assembly_level == 2) {
    // Mode 2: Render the open box, filled with racks and slides.
    box_assembly();
  } else if (assembly_level == 3) {
    // Mode 3: Render the whole system capped securely with the lid.
    box_assembly();

    // Now we must perfectly place the lid on top of the box.
    // By default, box_lid() renders rightside-up on the ground.
    // We move it over (X/Y) to account for wall offsets, and lift it up (Z) to the top of the box.
    translate(
      [
        -(_lid_wall + _lid_clearance), // Align left edge
        -(_lid_wall + _lid_clearance) + _o_y, // Align front edge (handling rotation shift)
        _box_z + 1.5, // Lift it to the absolute top of the box base
      ]
    )
      // The lid is printed upside down, so we do a 180-degree flip over the X axis to cap the box.
      rotate([180, 0, 0])
        box_lid();
  }
}
