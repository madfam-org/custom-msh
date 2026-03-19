// ============================================================================
// multi_rack.scad — AOCL Multi-Rack Joined Body (NATIVE)
// ============================================================================
// Copyright (c) 2026 madfam-org
// Licensed under the CERN Open Hardware Licence Version 2 - Weakly Reciprocal (CERN-OHL-W-2.0).
//
// Produces 2–5 contiguous staining racks joined side-by-side along the X-axis.
// Internal junctions use Diamond Grid Side Guards instead of double solid walls.
// Front/back guards span continuously across the full multi-rack width.
// Side guards are mandatory (always ON) — not toggleable in this mode.

use <aocl_lib.scad>
include <../../libs/BOSL2/std.scad>

// --- Configuration Parameters ---
substrate_length = 25.4;
substrate_width = 25.4;
custom_slide_thickness = 1.0;
tolerance_xy = 0.4;
tolerance_z = 0.2;
wall_thickness = 2.0;

num_slots = 10;
multi_num_racks = 3;
handle = 1;
open_bottom = 1;
label_area = 1;
numbering_start = 1;
divider_style = 1;
show_numbers = 1;
frame_base_grid = 1;
fn = 32;
$fn = fn > 0 ? fn : 32;

// --- Derived Geometry ---
_min_rib_w = 2.75;
_slot_w = slide_slot_width(custom_slide_thickness, tolerance_z);
_pitch = slide_pitch(_slot_w, _min_rib_w);

_slot_depth = substrate_width + tolerance_xy;
_rib_height = _slot_depth;
_cavity_y = substrate_length + tolerance_xy;
_chamfer_h = min(1.5, _rib_height * 0.15);

_pillar_w = wall_thickness;
_crossbar_w = 3.0;
_crossbar_h = 2.5;

// Single-rack inner width (dividers + slots, without end walls)
_inner_per_rack = (num_slots * _pitch) + _min_rib_w;

// Body dimensions (Y and Z identical to single rack)
_body_y = substrate_length + (2 * _pillar_w) + tolerance_xy;
_base_h = open_bottom == 1 ? _crossbar_h : wall_thickness;
_body_z = _rib_height + _base_h;

// Total multi-rack width along X
_total_x = (multi_num_racks * _inner_per_rack)
         + (2 * _pillar_w)                       // outer end walls
         + ((multi_num_racks - 1) * _pillar_w);  // junction guard panels

// Handle geometry (matches rack.scad)
_leg_w = 4.5;
_grip_h = 5;
_holey = max(10, _body_y - 2 * _leg_w);
_wall_z = _body_z;

// Labels
_label_w = min(30, _total_x * 0.3);
_label_h = min(10, _body_z * 0.4);
_num_size = min(2.5, _pitch * 0.7, _base_h * 0.85);

// Diamond grid
_grid_h = _body_z * 0.6;
_grid_thick = 1.5;

// --- Helper Modules ---

module am_ramp(w, l, h) {
  translate([-w/2, 0, 0])
    rotate([90, 0, 90])
      linear_extrude(w)
        polygon([[0,0], [0,h], [l,h]]);
}

// Solid end wall with optional handle cutout (left or right outer end)
module end_wall(x_pos) {
  translate([x_pos, 0, 0]) difference() {
    cube([_pillar_w, _body_y, _wall_z]);
    if (handle == 1) {
      _holex = _pillar_w + 0.2;
      _rect_h = max(0, (_wall_z - _base_h - _grip_h) - (_holey / 2));
      translate([-0.1, _leg_w, _base_h]) {
        if (_rect_h > 0) cube([_holex, _holey, _rect_h]);
        translate([0, 0, _rect_h])
          hull() {
            cube([_holex, _holey, 0.01]);
            translate([0, _holey / 2, _holey / 2]) cube([_holex, 0.01, 0.01]);
          }
      }
    }
  }
}

// Dividers for one rack segment (identical to single rack logic)
module rack_segment_dividers(seg_index) {
  _seg_x = _pillar_w + seg_index * (_inner_per_rack + _pillar_w);
  _z_offset = frame_base_grid == 1 ? 0 : _base_h;
  _actual_rib_height = frame_base_grid == 1 ? _rib_height + _base_h : _rib_height;

  translate([_seg_x + _min_rib_w / 2, _pillar_w + _cavity_y / 2, _z_offset]) {
    for (i = [0:num_slots]) {
      translate([i * _pitch, 0, 0]) {
        if (divider_style == 0) {
          // Stub-rib mode
          if (frame_base_grid == 0) {
            _stub_ramp_l = min(_base_h, _pillar_w);
            translate([0, -(_cavity_y / 2), -_base_h])
              am_ramp(_min_rib_w, _stub_ramp_l, _base_h);
            translate([0, (_cavity_y / 2), -_base_h])
              rotate([0, 0, 180])
                am_ramp(_min_rib_w, _stub_ramp_l, _base_h);
          } else {
            prismoid(size1=[_min_rib_w, _cavity_y], size2=[_min_rib_w, _cavity_y],
                     h=_base_h, anchor=BOTTOM);
          }
          translate([0, -(_cavity_y / 2 - _pillar_w / 2), 0])
            slide_retention_rib(height=_actual_rib_height, depth=_pillar_w,
                               root_w=_min_rib_w, tip_w=_min_rib_w * 0.65,
                               chamfer_h=_chamfer_h);
          translate([0, (_cavity_y / 2 - _pillar_w / 2), 0])
            slide_retention_rib(height=_actual_rib_height, depth=_pillar_w,
                               root_w=_min_rib_w, tip_w=_min_rib_w * 0.65,
                               chamfer_h=_chamfer_h);
        } else {
          // Full-depth fin mode
          if (frame_base_grid == 0) {
            translate([0, -(_cavity_y / 2), -_base_h])
              am_ramp(_min_rib_w, _base_h, _base_h);
            translate([0, (_cavity_y / 2), -_base_h])
              rotate([0, 0, 180])
                am_ramp(_min_rib_w, _base_h, _base_h);
          }
          slide_retention_rib(height=_actual_rib_height, depth=_cavity_y,
                             root_w=_min_rib_w, tip_w=_min_rib_w * 0.65,
                             chamfer_h=_chamfer_h);
        }
      }
    }
  }
}

// Slot numbers for one segment with continuous numbering across all segments
module rack_segment_numbers(seg_index) {
  if (show_numbers == 1 && fn > 0) {
    _seg_x = _pillar_w + seg_index * (_inner_per_rack + _pillar_w);
    _seg_start = numbering_start + (seg_index * num_slots);

    for (i = [0:num_slots - 1]) {
      _num = _seg_start + i;
      _slot_center_x = _seg_x + _min_rib_w + _slot_w / 2 + i * _pitch;

      // Front face number
      translate([_slot_center_x, 0.4, _base_h / 2])
        rotate([90, 0, 0])
          linear_extrude(height=0.9)
            text(str(_num), size=_num_size, halign="center", valign="center",
                 font="Liberation Sans:style=Bold");

      // Back face number
      translate([_slot_center_x, _body_y - 0.4, _base_h / 2])
        rotate([90, 0, 180])
          linear_extrude(height=0.9)
            text(str(_num), size=_num_size, halign="center", valign="center",
                 font="Liberation Sans:style=Bold");
    }
  }
}

// Diamond grid guard panel in Y-Z plane at junction between adjacent segments
module junction_guard(junction_index) {
  _jx = _pillar_w + (junction_index + 1) * _inner_per_rack
       + junction_index * _pillar_w;

  // Rotate the standard X-Z diamond grid 90° into Y-Z plane
  translate([_jx + _pillar_w, 0, _base_h])
    rotate([0, 0, 90])
      diamond_grid_guard(_body_y, _pillar_w, _grid_h - _base_h);
}

// Full-width front and back diamond grid guards
module continuous_front_back_guards() {
  _guard_span_x = _total_x - 2 * _pillar_w;

  // Front guard (Y = 0 face)
  translate([_pillar_w, 0, _base_h])
    diamond_grid_guard(_guard_span_x, _grid_thick, _grid_h - _base_h);

  // Back guard (Y = _body_y face)
  translate([_pillar_w, _body_y - _grid_thick, _base_h])
    diamond_grid_guard(_guard_span_x, _grid_thick, _grid_h - _base_h);
}

// Label recess centered on the front face
module multi_rack_label() {
  if (label_area == 1) {
    translate([(_total_x - _label_w) / 2, -0.01, (_body_z - _label_h) / 2])
      rotate([90, 0, 0])
        translate([0, 0, -0.4])
          aocl_label_recess(_label_w, _label_h, 0.5);
  }
}

// --- Main Composition ---
module multi_rack_complete() {
  difference() {
    union() {
      // Outer end walls (solid, with handle cutouts)
      end_wall(0);
      end_wall(_total_x - _pillar_w);

      // Base plate
      if (open_bottom == 1) {
        // Full-width front and back rails
        cube([_total_x, _pillar_w, _crossbar_h]);
        translate([0, _body_y - _pillar_w, 0])
          cube([_total_x, _pillar_w, _crossbar_h]);

        // Outer side rails (front-to-back at each end)
        cube([_pillar_w, _body_y, _crossbar_h]);
        translate([_total_x - _pillar_w, 0, 0])
          cube([_pillar_w, _body_y, _crossbar_h]);

        // Junction side rails (front-to-back at each internal junction)
        for (j = [0:multi_num_racks - 2]) {
          _jx = _pillar_w + (j + 1) * _inner_per_rack + j * _pillar_w;
          translate([_jx, 0, 0])
            cube([_pillar_w, _body_y, _crossbar_h]);
        }

        // Inner crossbar rails (full-width at 33% and 67% of Y)
        for (frac = [0.33, 0.67])
          translate([0, _body_y * frac - _crossbar_w / 2, 0])
            cube([_total_x, _crossbar_w, _crossbar_h]);
      } else {
        // Solid base floor
        cube([_total_x, _body_y, wall_thickness]);
      }

      // Dividers and slot numbers for each rack segment
      for (i = [0:multi_num_racks - 1]) {
        rack_segment_dividers(i);
        rack_segment_numbers(i);
      }

      // Junction diamond grid guards (between adjacent segments)
      for (j = [0:multi_num_racks - 2]) {
        junction_guard(j);
      }

      // Continuous front/back diamond grid guards (full width)
      continuous_front_back_guards();
    }

    // Subtract label recess
    multi_rack_label();
  }
}

// --- Render ---
render_mode = 5;
if (render_mode == 5) multi_rack_complete();
