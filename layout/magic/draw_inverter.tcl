grid 0.17um 0.17um
snap int

# NMOS ndiffusion — 0.42um wide, 0.65um tall (satisfies diff.1 width rule)
box 0.17um 0um 1.02um 0.65um
paint ndiffusion

# PMOS pdiffusion — same size
box 0.17um 1.36um 1.02um 2.01um
paint pdiffusion

# nwell — 0.18um enclosure on all sides around pdiff (diff/tap.8)
box 0um 1.18um 1.19um 2.2um
paint nwell

# Poly gate — 0.15um wide, extends 0.13um past diff on each side (poly.7 + poly.8)
box 0.42um -0.13um 0.6um 2.14um
paint poly

# li1 output connection between drains
box 0.42um 0.65um 0.6um 1.36um
paint li

# Save
save inverter
