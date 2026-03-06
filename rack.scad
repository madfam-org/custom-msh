// ============================================================================
// rack.scad — AOCL 10-Slot Substrate Rack (NATIVE)
// ============================================================================
// Copyright (c) 2026 madfam-org
// Licensed under the CERN Open Hardware Licence Version 2 - Weakly Reciprocal (CERN-OHL-W-2.0).
//
// Welcome to the Staining Rack module!
// This file designs a skeletal frame designed to hold up to 10 glass slides 
// securely during chemical treatments or storage. It features a carrying handle 
// and internal ribbed separators to keep the slides spaced perfectly.

// Import our custom helper library for the retention ribs and labels
use <aocl_lib.scad>

// Import the Standard BOSL2 Library for math and geometry
include <../../libs/BOSL2/std.scad>

// --- Configuration Parameters ---
// These variables act as the control panel for the 3D model.

// Standard slide dimensions (25.4mm = 1 inch)
custom_slide_length = 25.4;
custom_slide_width = 25.4;
custom_slide_thickness = 1.0;

// Clearances and walls for 3D printing tolerances
tolerance_xy = 0.4; // Horizontal wiggle room
tolerance_z = 0.2; // Vertical wiggle room
wall_thickness = 2.0; // Standard thickness of the outer frame walls

// Features and capacities
num_slots = 10; // Number of substrate slots in the rack
handle = 1; // 1 = True (add carrying handle), 0 = False
open_bottom = 1; // 1 = True (base is open gaps to let liquids drain), 0 = solid floor
drainage_angle = 5; // Tilt angle (reserved for future fluid drainage features)
label_area = 1; // Add a recess for a label sticker
numbering_start = 1; // The first number engraved above the slide slots (e.g., 1 to 10)
fn = 32; // Curved geometry quality. Defaults to 32.
$fn = fn > 0 ? fn : 32;

// --- Derived Geometry / Math ---
// These equations figure out how big the rack needs to be based on the number of slots and tolerances.

_min_rib_w = 2.75; // The minimum thickness of the plastic dividers holding slides (forced to match AOCL spec)

// Calculate precise slot width and overall pitch (distance from slot to slot)
_slot_w = slide_slot_width(custom_slide_thickness, tolerance_z); // Gap width
_pitch = slide_pitch(_slot_w, _min_rib_w); // Distance required per slot_w, _min_rib_w);

// Determine the height of the ribs based on how deep the slide sits in it
_slot_depth = custom_slide_width + tolerance_xy;
_rib_height = _slot_depth;
_chamfer_h = min(1.5, _rib_height * 0.15); // Slope at the top of the rib for guiding slides in

// Structural elements sizing (the skeleton framework)
_pillar_w = wall_thickness;
_crossbar_w = 3.0; // Base crossbar width if open_bottom is enabled
_crossbar_h = 2.5; // Base crossbar height

// Overall bounding box of the main lattice frame
// The X axis spans all slots + all ribs + the two end walls
_body_x = (num_slots * _pitch) + _min_rib_w + (2 * _pillar_w);
// The Y axis spans the length of the slide + tolerances + front/back walls
_body_y = custom_slide_length + (2 * _pillar_w) + tolerance_xy;
_base_h = open_bottom == 1 ? _crossbar_h : wall_thickness; // Thickness of the floor
_body_z = _rib_height + _base_h; // Total height of the skeleton frame

// Side wall extended arch variables for integrated handles
_leg_w = 4.5; // Width of the solid handle support pillars on the left/right faces
_grip_h = 5; // Thickness of the top grip bar
_holey = max(10, _body_y - 2 * _leg_w); // The wide finger cutout length
_arch_height = (handle == 1) ? max(25, (_holey/2) + _grip_h + 5) : 0; // Total added height for the handle hole
_wall_z = _body_z + _arch_height; // The true ceiling height of the side walls

// Labels sizing math
_label_w = min(30, _body_x * 0.5);
_label_h = min(10, _body_z * 0.4);
_num_size = min(2.5, _pitch * 0.7);

// --- Core Modules ---

// Builds the structural lattice (skeleton) of the rack and populates the retention ribs inside
module rack_body() {
  // Solid Left wall (with handle cutout if enabled)
  difference() {
    cube([_pillar_w, _body_y, _wall_z]);
    if (handle == 1) {
      // 45-degree arched cutout for the fingers
      _holex = _pillar_w + 0.2; // Extra depth to punch through cleanly
      _rect_h = max(0, (_wall_z - _body_z - _grip_h) - (_holey/2));
      
      translate([-0.1, _leg_w, _body_z]) {
        // Base rectangle for the fingers
        if (_rect_h > 0) cube([_holex, _holey, _rect_h]);
        
        // 45-degree peaked roof to avoid bridging
        translate([0, 0, _rect_h])
          hull() {
             cube([_holex, _holey, 0.01]);
             translate([0, _holey/2, _holey/2]) cube([_holex, 0.01, 0.01]);
          }
      }
    }
  }

  // Solid Right wall (with identical handle cutout if enabled)
  translate([_body_x - _pillar_w, 0, 0]) difference() {
    cube([_pillar_w, _body_y, _wall_z]);
    if (handle == 1) {
      _holex = _pillar_w + 0.2;
      _rect_h = max(0, (_wall_z - _body_z - _grip_h) - (_holey/2));
      
      translate([-0.1, _leg_w, _body_z]) {
        if (_rect_h > 0) cube([_holex, _holey, _rect_h]);
        
        translate([0, 0, _rect_h])
          hull() {
             cube([_holex, _holey, 0.01]);
             translate([0, _holey/2, _holey/2]) cube([_holex, 0.01, 0.01]);
          }
      }
    }
  }

  // Bottom plate (either a skeletal frame or a solid floor based on `open_bottom` setting)
  if (open_bottom == 1) {
    // Skeletal crossbar base (allows fluids to drain perfectly)
    cube([_body_x, _pillar_w, _crossbar_h]); // Front rail
    translate([0, _body_y - _pillar_w, 0]) cube([_body_x, _pillar_w, _crossbar_h]); // Back rail
    cube([_pillar_w, _body_y, _crossbar_h]); // Left rail
    translate([_body_x - _pillar_w, 0, 0]) cube([_pillar_w, _body_y, _crossbar_h]); // Right rail

    // Add two inner rails spanning across the X axis to hold the glass slide's bottom edges
    for (frac = [0.33, 0.67])
      translate([0, _body_y * frac - _crossbar_w / 2, 0])
        cube([_body_x, _crossbar_w, _crossbar_h]);
  } else {
    // Solid base (no gaps)
    cube([_body_x, _body_y, wall_thickness]);
  }

  // Generate an array of plastic ribs along the front rail
  translate([_pillar_w, 0, _base_h]) {
    for (i = [0:num_slots]) {
      // Loop over every slot and move the X coordinate by the "pitch" to space it out
      translate([i * _pitch, 0, 0])
        slide_retention_rib(height=_rib_height, depth=_pillar_w, root_w=_min_rib_w, tip_w=_min_rib_w * 0.65, chamfer_h=_chamfer_h);
    }
  }

  // Generate an identical array of plastic ribs along the back rail
  translate([_pillar_w, _body_y - _pillar_w, _base_h]) {
    for (i = [0:num_slots]) {
      translate([i * _pitch, 0, 0])
        slide_retention_rib(height=_rib_height, depth=_pillar_w, root_w=_min_rib_w, tip_w=_min_rib_w * 0.65, chamfer_h=_chamfer_h);
    }
  }

  // Removed external overhead handle logic; handled natively within side walls now
}

// Extrudes standard numerical text (e.g. 1 2 3...) on the frame to identify sample locations
module slot_numbers() {
  if (fn > 0) {
    // Only generate numbers if high quality is enabled, to save compute
    for (i = [0:num_slots - 1]) {
      // Current slot number to display
      _num = numbering_start + i;
      // Get the X coordinate corresponding to this specific slot
      _rib_x = _pillar_w + (i * _pitch);

      // Position the number precisely above the front of each slot opening
      translate([_rib_x + _num_size / 2 + 0.4, -0.01, _base_h + _rib_height * 0.4])
        rotate([90, 0, 0]) // Stand the text up facing the front
          linear_extrude(height=0.5) // Punch it out by 0.5mm so it's readable
            text(str(_num), size=_num_size, halign="center", valign="center", font="Liberation Sans:style=Bold");
    }
  }
}

// Subtracts a shallow box from the solid body to form a neat labeling recess area
module rack_label() {
  if (label_area == 1) {
    // Center the label cutout horizontally and vertically on the front face
    translate([(_body_x - _label_w) / 2, -0.01, (_body_z - _label_h) / 2])
      rotate([90, 0, 0])
        translate([0, 0, -0.4])
          aocl_label_recess(_label_w, _label_h, 0.5);
    // Punches a hole exactly 0.5mm deep
  }
}

// This wrapper module cleanly combines all the shapes natively into one solid "rack"
// It ensures the label dent is cleanly SUBTRACTED out of the main body, then ADDs the raised slot numbers onto it.
module rack_complete() {
  difference() {
    rack_body();
    rack_label();
  }
  slot_numbers();
}

// Default Render 
// (This only triggers if you compile rack.scad directly. If imported by assembly.scad, it safely ignores this)
rack_complete();
