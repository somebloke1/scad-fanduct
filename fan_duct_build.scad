// Clean build approach - starting with basic components
//
// === INVARIANT: X, Y, Z coordinate system is INVARIANT throughout script ===
// See DESIGN_CANONS.md for full constraints
// - All dimensions use *_x_dimension, *_y_dimension, *_z_dimension naming
// - Base bottom at Z=0, all geometry at Z >= 0
//

// === CONSTANTS ===
overlap = 0.01;  // Small overlap for 3D printing geometry fusion (reused throughout)

// === BASE PARAMETERS ===
// Standard 140mm fan mounting
fan_xy_dimension = 140;      // Square base, same for X and Y axes
base_z_dimension = 4;         // Dimension along Z axis (plate thickness)
mounting_hole_spacing = 125;  // Center-to-center distance between holes (X and Y)
mounting_hole_diameter = 4.5; // Diameter for M4 screws with clearance
intake_diameter = 135;        // Circular intake opening diameter

// === DUCT SHELL PARAMETERS ===
shell_base_radius = 70;  // intake_diameter/2 + 2.5mm rim = 67.5 + 2.5

// === EGRESS PARAMETERS ===
// Final exit opening dimensions
egress_x_dimension = 30;   // Dimension along X axis
egress_y_dimension = 93;   // Dimension along Y axis
egress_z_dimension = 2.4;  // Dimension along Z axis (wall thickness)

// Egress position (center point)
egress_x = -30;      // Left offset from center
egress_y = (fan_xy_dimension - egress_y_dimension) / 2;  // Y offset to align one edge with base edge
egress_z = 95;       // Height above bottom of base

// Egress orientation (perpendicular to base = rotated 90° around Y axis)
egress_rotation = 90;  // Degrees around Y axis

// === VISUALIZATION ===
// Set to true to show reference axes and dimensions
show_guides = false;

// === COMPONENTS ===

// Base mounting plate (bottom at z=0)
module base_plate() {
    color("lightblue")
    difference() {
        translate([0, 0, base_z_dimension/2])
            cube([fan_xy_dimension, fan_xy_dimension, base_z_dimension], center=true);

        // Circular intake opening
        translate([0, 0, 0])
            cylinder(d=intake_diameter, h=base_z_dimension*3, center=true, $fn=64);

        // Mounting screw holes at four corners
        mounting_holes();
    }
}

// Four mounting holes in standard 140mm fan pattern
module mounting_holes() {
    half_spacing = mounting_hole_spacing / 2;
    for (x = [-1, 1], y = [-1, 1]) {
        translate([x * half_spacing, y * half_spacing, 0])
            cylinder(d=mounting_hole_diameter, h=base_z_dimension*3, center=true, $fn=32);
    }
}

// Solid duct shell base (circular) - slight overlap with base for 3D printing
module shell_base() {
    color("orange", 0.7)
    translate([0, 0, base_z_dimension - overlap])
        cylinder(r=shell_base_radius, h=0.1, $fn=64);
}

// Egress opening frame (hollow rectangle)
module egress_frame() {
    color("yellow")
    translate([egress_x, egress_y, egress_z])
        rotate([0, egress_rotation, 0])
        linear_extrude(height=egress_z_dimension, center=true)
        difference() {
            square([egress_x_dimension, egress_y_dimension], center=true);
            // Inner opening slightly smaller
            square([egress_x_dimension - egress_z_dimension*2,
                    egress_y_dimension - egress_z_dimension*2], center=true);
        }
}

// Guide markers (optional visualization)
module guides() {
    if (show_guides) {
        // Base center marker
        color("red") cylinder(d=5, h=1, center=true);

        // Egress center marker
        color("green")
        translate([egress_x, egress_y, egress_z])
            sphere(d=10);

        // Connection line
        color("blue", 0.3)
        hull() {
            cylinder(d=2, h=0.1, center=true);
            translate([egress_x, egress_y, egress_z])
                sphere(d=2);
        }
    }
}

// === ASSEMBLY ===
base_plate();
shell_base();
egress_frame();
guides();

// === NOTES ===
// Next steps to build:
// 1. Add intake circular opening to base
// 2. Add duct shell connecting base to egress
// 3. Add inner void
// 4. Add mounting holes
