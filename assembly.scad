// ============================================================================
// assembly.scad — AOCL Assembly Visualization (NATIVE)
// ============================================================================
// Copyright (c) 2026 madfam-org
// Licensed under the CERN Open Hardware Licence Version 2 - Weakly Reciprocal (CERN-OHL-W-2.0).

use <aocl_lib.scad>
include <BOSL2/std.scad>

// Include the base models
include <rack.scad>
include <box.scad>

// --- Configuration Parameters ---
// Level 1: Just Staining Rack & Slides
// Level 2: Box Base + Racks + Slides
// Level 3: Box Base + Racks + Slides + Box Lid
assembly_level = 3;

// --- Substrate Mockup ---

module mockup_slide() {
  // Renders a semi-transparent glass slide taking on the master dimensions
  color("white", 0.3)
    cuboid([_slot_w - tolerance_z, custom_slide_length, custom_slide_width], rounding=0.2, edges=[TOP, BOTTOM, RIGHT, LEFT], anchor=BOTTOM + FRONT + LEFT);
}

module populated_rack() {
  // Draw the actual physical printed rack
  rack_complete();

  // Populate exactly `num_slots` slides into it
  for (i = [0:num_slots - 1]) {
    _slide_x = _pillar_w + (i * _pitch) + _min_rib_w / 2 + (_slot_w - tolerance_z) / 2;
    translate([_slide_x, _pillar_w, _base_h])
      mockup_slide();
  }
}

// --- Assembly Logic ---

if (assembly_level == 1) {
  populated_rack();
}

if (assembly_level >= 2) {
  box_base();

  // Populate the box base with multiple loaded racks
  for (r = [0:num_racks - 1]) {
    _rx = wall_thickness + _rack_clearance + r * (_rack_x + _rack_clearance);

    translate([_rx, wall_thickness + _rack_clearance, wall_thickness + _rack_clearance])
      populated_rack();
  }
}

if (assembly_level == 3) {
  // Move the lid dynamically based on the final box height and add a slight Z separation
  // to avoid overlapping planes, maintaining an "exploded" look
  color("#6b7280", 0.9)
    translate([0, 0, _box_z + 20])
      box_lid();
}
