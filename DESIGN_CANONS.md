# DESIGN_CANONS.md

## Invariant Design Constraints

These constraints MUST be maintained throughout all code in this project.

### Coordinate System Invariant

**X, Y, Z coordinate system is INVARIANT throughout the entire script.**

- **X axis**: Horizontal, left-right (negative = left, positive = right)
- **Y axis**: Horizontal, front-back
- **Z axis**: Vertical (zero = bottom of base plate, positive = up)

**All dimension variables must use axis-based naming:**
- `*_x_dimension` - dimension along X axis
- `*_y_dimension` - dimension along Y axis
- `*_z_dimension` - dimension along Z axis

**NEVER use relativistic terms like:**
- ~~width~~, ~~height~~, ~~length~~, ~~thickness~~, ~~depth~~

**Naming Examples:**
- `base_z_dimension` - base plate thickness (along Z axis)
- `egress_x_dimension` - egress opening dimension along X axis
- `egress_y_dimension` - egress opening dimension along Y axis

### Origin Point

- Base plate bottom surface sits at Z=0
- Base plate is centered at X=0, Y=0
- All geometry is at Z ≥ 0

### Comments

All dimension variables should include axis-reference comments:
```scad
base_z_dimension = 4;  // Dimension along Z axis (plate thickness)
```
