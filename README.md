# Custom Microscope Slide Holder (AOCL)

Welcome to the `custom-msh` repository! If you're new to parametric manufacturing or the Yantra4D platform, you're in the right place. This document is designed to help you understand not just *what* this project does, but *why* it's built this way.

## Introduction: Welcome to the Era of Hyperobjects

If you've ever 3D printed a file from the internet, you're probably familiar with `.stl` files. An STL is what we call a **Static Mesh**—a fixed, rigid shell made of tiny triangles. If a hole is 3 millimeters wide but you only have a 4-millimeter screw, you are out of luck. The intelligence of the design is lost.

This project is different. It is a **Bounded 4D Hyperobject**.

Instead of a fixed shape, a Hyperobject is a *computational definition* of a family of objects that exist within a multidimensional parameter space. Written in OpenSCAD (a code-based 3D modeling language), the "object" here is actually a script. You don't download a specific slide holder; you download the *recipe* to generate infinite variations of a slide holder.

The "4th Dimension" in this context is the potential of the design space itself. It is "Bounded" because the code enforces logical limits (e.g., preventing a wall from becoming so thin it snaps).

## The Theory: Common Denominator Geometry (CDG)

Why do we need Hyperobjects? Because of **Common Denominator Geometry (CDG)**.

Originating in aerospace engineering, CDG is the idea that to build complex systems, you need a shared, mathematically rigorous "truth" or interface. In the realm of additive manufacturing, CDG represents the standardized interfaces—the rails, grids, threads, and sockets—that allow a globally distributed community to build compatible infrastructure without centralized coordination.

For this project, the **CDG** is the specific width, clearance, and interaction profile to hold a standard **AOCL (1-inch x 1-inch, or 25.4mm x 25.4mm) microscope slide/substrate**. 

By standardizing this interface in open code:
- You know that *any* variation you generate will securely hold the industry-standard glass slide.
- You can adjust tolerances for different 3D printers or materials, without breaking the core functionality.
- You empower a "right to repair" and open science ecosystem independent of proprietary, rigid commercial lab hardware.

## Standalone Usage

This hyperobject is designed to be fully functional entirely independent of the Yantra4D ecosystem. The core geometry logic relies solely on the open-source **BOSL2** standard library.

To use this on your own machine via OpenSCAD:

```bash
# Clone the repository and properly pull the BOSL2 library submodule
git clone --recursive https://github.com/madfam-org/custom-msh.git

# Open the files directly in OpenSCAD
# (The code automatically links to the local BOSL2 folder included in the clone)
```

---

## Technical Architecture

This repository contains the OpenSCAD generators for a custom substrate holder system tailored for the 1×1 inch AOCL standard. It includes a single holder, a 10-slot rack, and a 3-rack storage box.

### The Yantra4D Manifest (`project.json`)

To make these Hyperobjects usable for non-programmers, this project includes a `project.json` file. This is the **Yantra4D Manifest**.

Yantra4D is an open platform that visualizes and configures these parametric models in a web browser. The `project.json` file acts as the bridge:
1. It reads the OpenSCAD variables (like `tolerance_xy` or `num_slots`).
2. It translates them into a user-friendly web interface with sliders and checkboxes.
3. It bundles standard presets (like a "Tight Tolerance" vs "Loose Tolerance" preset).

When you see the tables below, they are derived from this manifest.

---

## Project Specifications 

**Version**: 2.0.0  
**Slug**: `custom-msh`  
**License**: CERN-OHL-W-2.0  
**Official Configurator**: [Yantra4D](https://github.com/madfam-org/yantra4d)

### Included Modes (Hyperobject Generators)

| ID | Label | SCAD File | Parts | Description |
|---|---|---|---|---|
| `holder` | Single Holder | `holder.scad` | holder_body | Generates a single AOCL substrate holder. |
| `rack` | 10-Slot Rack | `rack.scad` | rack | Generates a rack holding multiple substrates. |
| `box` | 3-Rack Box | `box.scad` | box_base, box_lid | Generates an outer enclosure for racks. |

### Parameters & Data Standards

The following interactive parameters define the bounds of this hyperobject. Notice how the core CDG (the AOCL 25.4mm substrate size) is exposed but defaults to the industry standard.

| Name | Type | Default | Range | Description |
|---|---|---|---|---|
| `substrate_size` | slider | 25.4 | 24.0–27.0 (step 0.1) | Square substrate side length. **AOCL spec: 25.4 mm (1 inch)** |
| `tolerance_xy` | slider | 0.4 | 0.1–0.8 (step 0.05) | Horizontal clearance added to pocket/slot openings for FDM shrinkage |
| `tolerance_z` | slider | 0.2 | 0.05–0.5 (step 0.05) | Slot width clearance over substrate thickness |
| `wall_thickness` | slider | 2.0 | 1.2–4.0 (step 0.2) | Outer structural wall and pillar thickness |
| `label_area` | checkbox | Yes | - | Subtracts a debossed recess for adding a handwritten or adhesive label |
| `chamfer_pocket` | checkbox | Yes | - | Adds a 45° chamfer at pocket entry to guide substrate insertion |
| `num_slots` | slider | 10 | 5–15 | Number of substrate positions per rack. |
| `handle` | checkbox | Yes | - | Appends an integrated handle arch for carrying the rack |
| `open_bottom` | checkbox | Yes | - | Toggles an open crossbar base (less material, cleanable) vs. solid floor |
| `drainage_angle` | slider | 5 | 0–15 | Slope for fluid runoff (0 = flat). Reserved for future use. |
| `numbering_start` | slider | 1 | 1–100 | First slot number engraved on the rack. Requires high polygon quality. |
| `num_racks` | slider | 3 | 1–5 | How many racks the box accommodates. |
| `box_depth_target` | slider | 26.0 | 24.0–40.0 (step 0.5) | Outer box Z-height. Clamped to minimum rack height automatically. |
| `snap_lid` | checkbox | Yes | - | Generates snap-fit cantilever latch arms on the lid. |
| `fn` | slider | 0 | 0–64 (step 8) | Polygon resolution. 0 = auto (fast draft). Higher = slower but detailed. |

### Configurator Presets

- **AOCL Default (1"×1", 10 slots, 3 racks)**
  `substrate_size`=25.4, `num_slots`=10, `num_racks`=3, `tolerance_xy`=0.4, `tolerance_z`=0.2, `wall_thickness`=2.0, `label_area`=1, `snap_lid`=1, `handle`=1, `open_bottom`=1
- **Tight Tolerance (precision printer)**
  `substrate_size`=25.4, `tolerance_xy`=0.2, `tolerance_z`=0.1, `wall_thickness`=2.0
- **Loose Tolerance (easy extraction)**
  `substrate_size`=25.4, `tolerance_xy`=0.6, `tolerance_z`=0.3, `wall_thickness`=2.0

### Color Identifiers

| ID | Label | Default Color |
|---|---|---|
| `holder_body` | Holder Body | `#4a90d9` |
| `rack` | Rack | `#e5e7eb` |
| `box_base` | Box Base | `#4a90d9` |
| `box_lid` | Box Lid | `#6b7280` |

---
*Generated alongside `project.json` for integration with Yantra4D*
