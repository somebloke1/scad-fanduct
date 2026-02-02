# CLAUDE.md

## **INVARIANT DESIGN CONSTRAINTS**: @DESIGN_CANONS.md

## 🔴 CURRENT ISSUE - READ THIS FIRST

**Problem:** Crescent gap at 135mm circular intake where rotating square profile doesn't cover circular edge.

**Gap location:** v31_perspective3.png - lower right edge (can see orange interior surface through gap)

**Root cause:** Interior wall is PLANAR where it meets circular intake. Need to **bow out/curve the wall** to match 135mm circular edge (like trumpet bell flare).

**Attempted fixes:**
- v28: base_corner_fill() - hulled from square corners (wrong geometry)
- v29: Increased steps to 120 (overloads renderer - REJECTED)
- v30: intake_crescent_fill() - hulled cylinder to segments (gap persists)
- v31: inner_void starts from circular cylinder at z=0 (gap persists)

**Next approach needed:** Create curved interior wall surface that conforms to circular perimeter instead of planar cut.

**Key files:** fan_duct_v31.scad (current), v31_perspective3.png (shows gap), fan_duct_v28.scad (original)

---

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an OpenSCAD project for designing a parametric 3D-printable fan duct. The duct transitions from a square 140mm fan mount to a rectangular exit opening, following a curved path with rotation.

## Development Commands

**Rendering the model:**
```bash
openscad fan_duct_v28.scad -o output.stl
```

**Quick preview (OpenSCAD GUI):**
```bash
openscad fan_duct_v28.scad
```

**Python environment (using uv):**
```bash
uv pip install solidpython2
uv pip list
```

## Architecture

### Core Design Approach

The fan duct uses a **hull-based sweep** technique to create a smooth transition:

1. **Profile transformation**: Rectangular profiles morph from square (140×140mm) to rectangular (30×93mm) over 60 steps
2. **Path following**: Profiles follow a curved path with simultaneous:
   - X-axis translation (sinusoidal swing with final offset)
   - Y-axis offset (for exit positioning)
   - Z-axis drop (98mm total)
   - Y-axis rotation (0° to 90° progressive rotation)
3. **Hull operation**: Adjacent profile slices are connected using `hull()` to create smooth surfaces

### Key Modules

- `outer_profile(progress)`: Generates the outer shell cross-section at any point (0-1) along the path. Uses filleted rectangles.
- `inner_profile(progress)`: Generates the inner void cross-section, inset by `wall` thickness (2.4mm).
- `outer_duct()`: Creates the outer shell by hulling 60 profile slices along the curved path. Includes a base collar for integration with mounting plate.
- `inner_void()`: Creates the hollow interior, starting at step 1 (not step 0) to preserve the base plate.
- `base_corner_fill()`: Additional geometry to fill gaps at base corners caused by hull limitations.
- `exit_cap()`: Solid end cap with opening at the exit.

### Known Issues

**Gap at base corners**: The hull-based approach has a fundamental geometric limitation. When thin profiles (0.1mm `linear_extrude`) rotate, corner vertices trace arcs through space. The convex hull between adjacent thin slices cannot capture this swept volume, especially on the concave side (-X edge) of the bend where the arc length is largest.

**Analysis files** (markdown files in root):
- `ten_questions.md`: Diagnostic questions to isolate the gap issue
- `isolation_matrix.md`: Test matrix mapping questions to explanations
- `plausible_explanations.md`: Root cause analysis
- `solidpython.md`: Note about alternative approach using SolidPython2's `extrude_along_path()`

**Current mitigation**: `base_corner_fill()` adds explicit hull geometry between base and first segments.

## Parameters

All dimensions are configurable at the top of `fan_duct_v28.scad`:
- `fan_size`, `hole_dist`: Fan mounting dimensions
- `wall`: Wall thickness
- `total_drop`: Vertical drop distance
- `exit_height`, `exit_width_y`: Exit opening dimensions
- `max_right`, `max_left`, `final_left`: Path curve control points
- `fillet_r`: Corner fillet radius

## Improved Solutions

### Using BOSL2's path_sweep() (Recommended)

The project includes `fan_duct_path_sweep.py` which uses BOSL2's `path_sweep()` function to create proper swept surfaces without hull-based gaps:

```bash
uv run python fan_duct_path_sweep.py  # Generate OpenSCAD
openscad fan_duct_path_sweep.scad     # Preview/render
```

**Advantages**:
- Mathematically correct swept geometry
- Automatic tangent/normal alignment
- Built-in morphing (twist, scale) support
- No hull gaps

### Alternative: Thicker Hull Extrusions

The `fan_duct_solidpython.py` script demonstrates fixing the gap by using 2mm extrusions (instead of 0.1mm) in the hull-based approach. This works because the arc length corners trace between steps (~1.8mm) is now captured by the thicker slices.

## Python Development

The project uses `uv` for package management:

```bash
uv pip install solidpython2 numpy  # Install dependencies
uv pip list                         # List installed packages
```

SolidPython2 provides Python bindings to generate OpenSCAD code, with access to BOSL2 library functions.
