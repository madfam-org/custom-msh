/*
 * ============================================================================
 * YANTRA4D AOCL HYPEROBJECT LIBRARY (NATIVE)
 *
 * Copyright (c) 2026 madfam-org
 * Licensed under the CERN Open Hardware Licence Version 2 - Weakly Reciprocal (CERN-OHL-W-2.0).
 * ============================================================================
 * 
 * CORE CDG: AOCL Substrate Retention & Box Latches
 *
 * Welcome to the AOCL Library!
 * This file contains reusable "helper modules" and mathematical functions. 
 * Instead of rewriting the code for a latch or a slide-holder rib in every 
 * single file, we write it once here. Other files can then "use" this file 
 * to generate those shapes effortlessly. Think of it as a toolbox!
 */

// Import the BOSL2 standard library for advanced 3D geometry manipulation
include <BOSL2/std.scad>

// --- CDG Math Functions ---
// These are simple mathematical formulas that other files can call to calculate sizes.

// Calculates the total physical width required for a slide slot, 
// including the thickness of the glass, the vertical wiggle room (tol_z), 
// and a tiny bit of extra padding (0.2mm) to ensure slides don't get stuck.
function slot_width(slide_thick, tol_z) = slide_thick + tol_z + 0.2;

// Calculates the "pitch". Pitch is a common engineering term meaning the distance 
// from the center (or start) of one repeating feature to the next.
// Here, it's the width of the slot opening + the width of the plastic rib separating them.
function pitch(slot_w, rib_w) = slot_w + rib_w;

// --- Core Modules ---
// These modules generate physical 3D shapes.

// Generates a vertical plastic divider (rib) meant to hold a slide in place.
// It is built using a 2D "polygon" (drawing a shape with X,Y coordinates) 
// that is then extruded (pulled into 3D) to create a tapered fin with an optional chamfer (slant) at the top.
module aocl_retention_rib(height, depth, root_w, tip_w, chamfer_h) {
  _ch = min(chamfer_h, height * 0.25); // Limit chamfer height to max 25% of total height
  _body = height - _ch; // The straight vertical part of the rib
  _off = (root_w - tip_w) / 2; // The angle offset to make the rib taper (get thinner) towards the top

  // Rotate and move the shape so it stands upright when generated
  rotate([-90, 0, 0]) translate([0, -height, 0]) {
      // 1. Extrude the main part of the rib
      linear_extrude(height=depth)
        polygon([[0, 0], [root_w, 0], [root_w - _off, _body], [_off, _body]]);

      // 2. Extrude the tapered/chamfered top guide, which helps slides slide in easily
      if (_ch > 0) {
        _w = tip_w; // Top width
        translate([_off, 0, 0])
          linear_extrude(height=depth)
            // Polygon drawing of the chamfer
            polygon([[0, _body], [_w, _body], [_w / 2 + _w * 0.3, _body + _ch], [_w / 2 - _w * 0.3, _body + _ch]]);
      }
    }
}

// Generates a solid rectangular block that will later be SUBTRACTED from another object to make a shallow dent (recess) for sticking a label on.
module aocl_label_recess(w, h, d = 0.4) {
  // Create a box anchored to the bottom face
  cuboid([w, h, d], anchor=BOTTOM);
}

// Generates a snap-fit cantilever arm. This is a flexible plastic stick with a hook at the top.
// Used mainly on the lid to securely snap onto the box.
module aocl_snap_arm(len, w, t, hook_h, hook_d) {
  // First, draw the flexible stick (arm)
  cuboid([w, t, len], anchor=BOTTOM + BACK) {
    // Then, attach the hook to the top of the stick
    attach(TOP) cuboid([w, t + hook_d, hook_h], anchor=BOTTOM + BACK);
  }
}

// Generates the solid catch/receptacle for the snap-fit arm.
// This is simply a small block sticking out of the box base that the snap-arm hook grabs onto.
module aocl_snap_catch(w, h, d) {
  cuboid([w, d, h], anchor=BOTTOM);
}
