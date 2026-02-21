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
include <../../libs/BOSL2/std.scad>
include <../microscope-slide-hyperobject/slide.scad>

// --- CDG Math Functions ---
// --- Core Modules ---
// These modules generate physical 3D shapes.

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
