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
// Final exit opening dimensions (in WORLD coordinates after rotation)
egress_x_dimension = 2.4;  // Dimension along X axis (wall thickness)
egress_y_dimension = 93;   // Dimension along Y axis (height)
egress_z_dimension = 30;   // Dimension along Z axis (width)

// === INTERMEDIATE PARAMETERS ===
intermediate_x_dimension = egress_z_dimension;
intermediate_y_dimension = egress_y_dimension;
intermediate_z_dimension = 0.1;
intermediate_x_scale_center = 2.0;  // Scale factor at Y center (coefficient)
intermediate_x_scale_edges = 1.0;   // Scale factor at Y edges

// Egress position (center point)
egress_x = -30;      // Left offset from center
egress_y = (fan_xy_dimension - egress_y_dimension) / 2;  // Y offset to align one edge with base edge (93mm)
egress_z = 95;       // Height above bottom of base

// === HULL DISTRIBUTION PARAMETERS ===
base_hull_profile_count = 11;        // Number of intermediate profiles in first hull segment
base_hull_spacing_factor = 1.0;      // Cosine acceleration factor (>1.0 = more aggressive)
base_fillet_radius = 70;             // Fillet radius at base (circular)
terminus_fillet_radius = 10;         // Fillet radius at intermediate terminus
terminus_left_extension_factor = 0.20;  // Left edge extension as fraction of terminus max X dimension
terminus_y_offset = 10;              // Y-axis offset at terminus (dimension along Y axis)

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

// Intermediate rectangular profile - horizontal, guides transition (cosine curve along Y)
module shell_intermediate() {
    intermediate_z = (base_z_dimension + egress_z) / 2;

    color("purple", 0.7)
    translate([0, 0, intermediate_z])
        linear_extrude(height=intermediate_z_dimension, center=true) {
            // Create profile with cosine-based X variation along Y
            steps = 20;
            polygon(concat(
                // Right edge with cosine curve
                [for (i = [0:steps])
                    let(
                        y = -intermediate_y_dimension/2 + i * intermediate_y_dimension/steps,
                        t = i / steps,
                        curve = (1 - cos((t - 0.5) * 360)) / 2,
                        scale = intermediate_x_scale_edges + (intermediate_x_scale_center - intermediate_x_scale_edges) * curve,
                        x = intermediate_x_dimension * scale
                    )
                    [x, y]
                ],
                [for (i = [steps:-1:0]) [0, -intermediate_y_dimension/2 + i * intermediate_y_dimension/steps]]
            ));
        }
}

// Morphing profile: base (circular) to intermediate (rounded rectangle with cosine curve)
// progress: 0 = base position/shape, 1 = intermediate position/shape
module shell_base_to_intermediate_profile(progress) {
    // Calculate eased progress (accelerating distribution toward terminus)
    eased = 1 - cos(progress * 90 * base_hull_spacing_factor);

    // Calculate Z position
    intermediate_z = (base_z_dimension + egress_z) / 2;
    z = base_z_dimension + (intermediate_z - base_z_dimension) * eased;

    // Calculate Y offset (morphs from 0 at base to terminus_y_offset at terminus)
    y_offset = terminus_y_offset * eased;

    // Calculate morphing fillet radius
    fillet = base_fillet_radius - (base_fillet_radius - terminus_fillet_radius) * eased;

    // Morph Y dimension
    y_dim = shell_base_radius * 2 + (intermediate_y_dimension - shell_base_radius * 2) * eased;

    // Calculate left edge extension at terminus
    terminus_max_x = intermediate_x_dimension * intermediate_x_scale_center;  // 30 * 2.0 = 60mm
    left_extension = terminus_max_x * terminus_left_extension_factor;  // 60 * 0.33 = 20mm

    color("purple", 0.7)
    translate([0, y_offset, z])
        linear_extrude(height=intermediate_z_dimension, center=true) {
            if (progress == 0) {
                // At base: circular
                circle(r=base_fillet_radius, $fn=64);
            } else {
                // Morphing to rectangular with cosine curve
                offset(r=fillet)
                offset(r=-fillet) {
                    steps = 20;
                    polygon(concat(
                        // Right edge with cosine curve morphing
                        [for (i = [0:steps])
                            let(
                                y = -y_dim/2 + i * y_dim/steps,
                                t = i / steps,
                                curve = (1 - cos((t - 0.5) * 360)) / 2,
                                // At base: scale=1 (circular), at terminus: cosine curve scale
                                scale = 1 + (intermediate_x_scale_center - 1) * curve * eased,
                                // Morph from +70mm (base) to cosine-scaled width (terminus)
                                x = shell_base_radius * (1 - eased) + intermediate_x_dimension * scale * eased
                            )
                            [x, y]
                        ],
                        // Left edge morphing from -70mm to -left_extension
                        [for (i = [steps:-1:0])
                            let(
                                y = -y_dim/2 + i * y_dim/steps,
                                x = -shell_base_radius * (1 - eased) - left_extension * eased
                            )
                            [x, y]
                        ]
                    ));
                }
            }
        }
}

// Hull segment: base to intermediate (with all intermediate profiles)
module hull_base_to_intermediate() {
    color("orange", 0.7)
    hull() {
        // Generate all profiles from base (progress=0) to intermediate (progress=1)
        // Total profiles = base_hull_profile_count + 2 (base and terminus)
        for (i = [0 : base_hull_profile_count + 1]) {
            progress = i / (base_hull_profile_count + 1);
            shell_base_to_intermediate_profile(progress);
        }
    }
}

// Hull segment: intermediate to egress
module hull_intermediate_to_egress() {
    color("orange", 0.7)
    hull() {
        shell_base_to_intermediate_profile(1);  // Use morphed terminus profile
        shell_egress();
    }
}

// Solid egress end piece (rectangular) - positioned at outer surface of egress frame (closest to Z axis)
module shell_egress() {
    color("orange", 0.7)
    // Position at outer surface (closest to Z axis/base) with overlap
    translate([egress_x - egress_x_dimension/2 + overlap, egress_y, egress_z])
        rotate([0, egress_rotation, 0])
        cube([egress_z_dimension, egress_y_dimension, egress_x_dimension + overlap], center=true);
}

// Complete solid shell - union of hull segments
module shell_solid() {
    union() {
        hull_base_to_intermediate();
        hull_intermediate_to_egress();
    }
}

// Egress opening frame (hollow rectangle)
module egress_frame() {
    color("yellow")
    translate([egress_x, egress_y, egress_z])
        rotate([0, egress_rotation, 0])
        linear_extrude(height=egress_x_dimension, center=true)
        difference() {
            square([egress_z_dimension, egress_y_dimension], center=true);
            // Inner opening slightly smaller
            square([egress_z_dimension - egress_x_dimension*2,
                    egress_y_dimension - egress_x_dimension*2], center=true);
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
shell_solid();
egress_frame();  // Keep for reference
guides();

// === NOTES ===
// Next steps to build:
// 1. Add intake circular opening to base
// 2. Add duct shell connecting base to egress
// 3. Add inner void
// 4. Add mounting holes
