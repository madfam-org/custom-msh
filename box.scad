// ============================================================================
// box.scad — AOCL Outer Box (Portamuestras) (NATIVE)
// ============================================================================
// Copyright (c) 2026 madfam-org
// Licensed under the CERN Open Hardware Licence Version 2 - Weakly Reciprocal (CERN-OHL-W-2.0).
//
// Welcome to the Box & Lid module!
// This file designs an outer protective casing tailored specifically to hold 
// 3 assembled "staining racks". It consists of two selectable components:
// a deeper base, and a snap-fit lid to lock everything safely inside.

// Import our custom helper library for building snaps and catches
use <aocl_lib.scad>

// Import the Standard BOSL2 Library for advanced geometric shapes like 'cuboid'
include <../../libs/BOSL2/std.scad>

// --- Configuration Parameters ---

// Accommodated slide dimensions (Standard 1 inch AOCL slides)
substrate_length = 25.4;
substrate_width = 25.4;
custom_slide_thickness = 1.0;

// Fits and Tolerances (Wiggle room for 3D printing accuracy)
tolerance_xy = 0.4;
tolerance_z = 0.2;
wall_thickness = 2.0;

// Global Setup Configuration
num_racks = 3; // Determines how wide the box should be to fit this many racks
snap_lid = 1; // Creates locking latch hooks (1 = True)
label_area = 1; // Indents a space for writing labels
stack_along_y = 0; // If 1, expand box along the Y-axis instead of the X-axis
fn = 32; // Smoothness curve quality. (Default to 32)
$fn = fn > 0 ? fn : 32;

// Part renderer (0 = Draw Base, 1 = Draw Lid)
render_mode = 0;

// --- Imposed Rack Math ---
// Recalculating the exact physical footprint of the inner `rack.scad` objects 
// here so the box can dynamically scale to fit them perfectly without importing them.

_min_rib_w = 2.75;
_slot_w = slide_slot_width(custom_slide_thickness, tolerance_z); // Gap width
_pitch = slide_pitch(_slot_w, _min_rib_w); // Centre-to-centre distance between adjacent slots
num_slots = 10; // Substrate slots per rack (matches rack.scad default)
_pillar_w = wall_thickness;

_rack_x = (num_slots * _pitch) + _min_rib_w + (2 * _pillar_w); // Total Rack Width
_rack_y = substrate_length + (2 * _pillar_w) + tolerance_xy; // Total Rack Length
_slot_depth = substrate_width + tolerance_xy;
_crossbar_h = 2.5;

_rack_z = _slot_depth + _crossbar_h; // Height without handle
_handle_h = 0; // Handle is an internal arch (no protrusion above _rack_z)

// --- Box Cavity Calculations ---

_rack_clearance = 0.5; // Gap between the racks and the box walls

// Define inner hollow cavity to hold all racks across X, Y, Z dimensions
_inner_x =
  (stack_along_y) ? (_rack_x + _rack_clearance * 2)
  : (num_racks * (_rack_x + _rack_clearance) + _rack_clearance);

_inner_y =
  (stack_along_y) ? (num_racks * (_rack_y + _rack_clearance) + _rack_clearance)
  : (_rack_y + _rack_clearance * 2);
// Box base height = exactly half the rack body height (so the lid covers the upper half)
_inner_z = _rack_z / 2 - wall_thickness;

// Define the absolute outer shell boundaries of the box base
_box_x = _inner_x + 2 * wall_thickness;
_box_y = _inner_y + 2 * wall_thickness;
_box_z = _inner_z + wall_thickness;

// Inner dividing rails (little walls printed inside the base to separate the racks)
_guide_h = _crossbar_h + 2;
_guide_w = 1.5;
_guide_d = _inner_y;

// Latch arm specifications (for the snap-fit hooks locking the lid to the base)
_latch_arm_len = 15;
_latch_arm_w = 8;
_latch_arm_t = 1.2;
_latch_hook_h = 2;
_latch_hook_d = 1.5;

// Lid specs (It has slightly different walls than the base)
_lid_clearance = 0.3; // Wiggle room between lid inner wall and box outer wall
_lid_wall = 1.5;
// Lid depth = full outer box height + ceiling thickness, so the skirt reaches the base floor
_lid_z = _box_z + 1.5;

_label_w = min(60, _box_x * 0.55);
_label_h = min(18, _box_y * 0.35);

// --- Core Modules ---

// Builds internal ribs/walls along the floor to prevent identical racks from colliding laterally
module rack_guide_rails() {
  for (r = [0:num_racks - 1]) {
    if (stack_along_y) {
      // Stacking along Y-axis: racks are arranged sequentially along Y
      _ry = wall_thickness + _rack_clearance + r * (_rack_y + _rack_clearance);
      // Front guide rail for current rack slot
      translate([wall_thickness, _ry - _guide_w, wall_thickness])
        cube([_inner_x, _guide_w, _guide_h]);
      // Back guide rail for current rack slot
      translate([wall_thickness, _ry + _rack_y, wall_thickness])
        cube([_inner_x, _guide_w, _guide_h]);
    } else {
      // Stacking along X-axis: racks are arranged sequentially along X
      _rx = wall_thickness + _rack_clearance + r * (_rack_x + _rack_clearance);
      // Left guide rail for current rack slot
      translate([_rx - _guide_w, wall_thickness, wall_thickness])
        cube([_guide_w, _inner_y, _guide_h]);
      // Right guide rail for current rack slot
      translate([_rx + _rack_x, wall_thickness, wall_thickness])
        cube([_guide_w, _inner_y, _guide_h]);
    }
  }
}

// Bottom enclosure shell (Base of the box)
module box_base() {
  // Use `difference()` to scoop out an inner cavity from a solid block
  difference() {
    union() {
      // 1. Draw solid outer box shell with rounded bottom edges
      difference() {
        cuboid([_box_x, _box_y, _box_z], rounding=1.5, edges=[BOTTOM], anchor=BOTTOM + LEFT + FRONT);
        
        // 1a. Subtract Honeycomb/Voronoi grid from Left and Right sides
        // We leave a 5mm solid frame around the top, bottom, and edges so stability isn't ruined
        _hex_frame = 5;
        _hex_d = 8;
        _hx_len = _box_y - (_hex_frame * 2);
        _hx_hei = _box_z - (_hex_frame * 2) - 4; // Extra clearance from top
        
        // Subtract honeycomb hex pattern from left and right walls
        if (_hx_hei > 5 && _hx_len > 5) {
          _hex_sp_y = _hex_d + 1;
          _hex_sp_z = _hex_d + 1.5;
          _hex_cols = floor(_hx_len / _hex_sp_y);
          _hex_rows = floor(_hx_hei / _hex_sp_z);
          _hex_oy = (_hx_len - _hex_cols * _hex_sp_y) / 2;
          _hex_oz = (_hx_hei - _hex_rows * _hex_sp_z) / 2;

          // Left wall hex cutouts
          for (row = [0:_hex_rows - 1])
            for (col = [0:_hex_cols - 1]) {
              _stagger = (row % 2 == 1) ? _hex_sp_y / 2 : 0;
              _cy = _hex_frame + _hex_oy + col * _hex_sp_y + _hex_sp_y / 2 + _stagger;
              _cz = _hex_frame + _hex_oz + row * _hex_sp_z + _hex_sp_z / 2;
              if (_cy > _hex_frame + _hex_d/2 && _cy < _box_y - _hex_frame - _hex_d/2 &&
                  _cz > _hex_frame + _hex_d/2 && _cz < _box_z - _hex_frame - _hex_d/2 - 4)
                translate([-1, _cy, _cz])
                  rotate([0, 90, 0])
                    cylinder(d=_hex_d, h=wall_thickness+2, $fn=6);
            }

          // Right wall hex cutouts
          for (row = [0:_hex_rows - 1])
            for (col = [0:_hex_cols - 1]) {
              _stagger = (row % 2 == 1) ? _hex_sp_y / 2 : 0;
              _cy = _hex_frame + _hex_oy + col * _hex_sp_y + _hex_sp_y / 2 + _stagger;
              _cz = _hex_frame + _hex_oz + row * _hex_sp_z + _hex_sp_z / 2;
              if (_cy > _hex_frame + _hex_d/2 && _cy < _box_y - _hex_frame - _hex_d/2 &&
                  _cz > _hex_frame + _hex_d/2 && _cz < _box_z - _hex_frame - _hex_d/2 - 4)
                translate([_box_x - wall_thickness - 1, _cy, _cz])
                  rotate([0, 90, 0])
                    cylinder(d=_hex_d, h=wall_thickness+2, $fn=6);
            }
        }
      }

      // 2. Build protruding catch mechanisms (ledges) on the front and back for the lid hooks to grab onto
      if (snap_lid == 1) {
        // Front Catch
        translate([_box_x / 2 - _latch_arm_w / 2, -0.01, _box_z - _latch_hook_h - 1])
          aocl_snap_catch(_latch_arm_w, _latch_hook_h, wall_thickness + _latch_hook_d);

        // Back Catch
        translate([_box_x / 2 - _latch_arm_w / 2, _box_y - wall_thickness - _latch_hook_d + 0.01, _box_z - _latch_hook_h - 1])
          aocl_snap_catch(_latch_arm_w, _latch_hook_h, wall_thickness + _latch_hook_d);
      }

      // 3. Draw the interior sorting rails inside the solid block
      rack_guide_rails();
    }

    // Finally, subtract the huge core cubic volume for the main internal cavity!
    translate([wall_thickness, wall_thickness, wall_thickness])
      cube([_inner_x, _inner_y, _inner_z + 1]);

    // Subtract a labeling recess from the front shell surface
    if (label_area == 1) {
      _lbl_w = min(40, _box_x * 0.45);
      _lbl_h = min(10, _box_z * 0.35);
      translate([(_box_x - _lbl_w) / 2, -0.01, (_box_z - _lbl_h) / 2])
        rotate([90, 0, 0])
          translate([0, 0, -0.4])
            aocl_label_recess(_lbl_w, _lbl_h, 0.5);
    }
  }
}

// Top cap enclosure that slips over the perimeter of the base locking the system
module box_lid() {
  // Define lid outer boundaries expanding outside the main box 
  _o_x = _box_x + _lid_clearance * 2 + _lid_wall * 2;
  _o_y = _box_y + _lid_clearance * 2 + _lid_wall * 2;

  // Define lid inner cavity enclosing the base perimeter
  _i_x = _box_x + _lid_clearance * 2;
  _i_y = _box_y + _lid_clearance * 2;

  difference() {
    // Draw the overall solid outer lid shell with rounded top edges
    cuboid([_o_x, _o_y, _lid_z], rounding=1.5, edges=[TOP], anchor=BOTTOM + LEFT + FRONT);

    // Scoop out the inner empty cavity where the base and rack handles enter
    translate([_lid_wall, _lid_wall, 1.5]) cube([_i_x, _i_y, _lid_z]);

    // Indent a small label space directly on the ceiling of the lid
    if (label_area) {
      translate([(_o_x - _label_w) / 2, (_o_y - _label_h) / 2, _lid_z - 0.39])
        aocl_label_recess(_label_w, _label_h, 0.4);
    }
  }

  // Draw two downward-facing cantilever snap hooks to lock into the base catches
  if (snap_lid) {
    // Front Hook
    translate([_o_x / 2 - _latch_arm_w / 2, 0, _lid_z])
      mirror([0, 0, 1]) // Point hook descending down explicitly
        aocl_snap_arm(_latch_arm_len, _latch_arm_w, _latch_arm_t, _latch_hook_h, _latch_hook_d);

    // Back hook
    translate([_o_x / 2 - _latch_arm_w / 2, _o_y - _latch_arm_t, _lid_z])
      mirror([0, 0, 1]) // Point hook descending down explicitly
        aocl_snap_arm(_latch_arm_len, _latch_arm_w, _latch_arm_t, _latch_hook_h, _latch_hook_d);
}

// Render the selected discrete part natively based on configuration
if (render_mode == 0 || render_mode == 2) {
  box_base();
}
if (render_mode == 1 || render_mode == 3) {
  box_lid();
}
