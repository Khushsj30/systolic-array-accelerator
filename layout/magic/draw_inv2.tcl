grid 0.17um 0.17um
snap int

# NMOS ndiffusion
# poly.7: ndiff must extend 0.25um PAST poly on each side
# poly gate will be at x: 0.51um to 0.68um
# so ndiff must start at 0.51 - 0.25 = 0.26um and end at 0.68 + 0.25 = 0.93um
box 0.26um 0.34um 0.93um 0.85um
paint ndiffusion

# PMOS pdiffusion
# same rule: pdiff extends 0.25um past poly on each side
box 0.26um 1.53um 0.93um 2.04um
paint pdiffusion

# nwell — must overlap pdiff by 0.18um on ALL 4 sides
# pdiff box: x(0.26 to 0.93) y(1.53 to 2.04)
# nwell: x(0.26-0.18=0.08) y(1.53-0.18=1.35) x(0.93+0.18=1.11) y(2.04+0.18=2.22)
box 0.08um 1.35um 1.11um 2.22um
paint nwell

# Poly gate — 0.15um wide minimum (poly.1a satisfied)
# centered at x=0.595um → 0.51um to 0.68um
# must cross both diff regions completely
box 0.51um 0.17um 0.68um 2.21um
paint poly

# li connecting drain of NMOS to drain of PMOS (output node)
box 0.51um 0.85um 0.68um 1.53um
paint li

save inv2
