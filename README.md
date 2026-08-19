# RC Plane CAD & Aerodynamic Analysis

A full engineering analysis of an existing RC aircraft — reverse-engineered from physical measurements, modeled in CAD, structurally validated, and analyzed aerodynamically using real airfoil data.

## Overview

This project takes a build I already own — a 990g fixed-wing RC trainer — and treats it as a case study in aircraft design analysis. The goal wasn't to build something new, but to demonstrate the full analysis workflow an aerospace engineer applies to an existing airframe: measuring and reconstructing the geometry in CAD, validating the wing structure under maneuvering loads, and characterizing the aircraft's aerodynamic performance using real airfoil data rather than textbook approximations.

The work is split into three parts:

1. **CAD modeling** (Fusion 360) — full geometry reconstruction from physical measurements
2. **Structural analysis** (Fusion Simulation) — wing stress under a 3G maneuvering load
3. **Aerodynamic analysis** (MATLAB) — stall speed, lift-to-drag performance, and cruise efficiency using NACA 2412 wind tunnel polars with a 3D aircraft drag build-up

## Aircraft Specifications

| Parameter | Value |
|---|---|
| Wingspan | 1010 mm |
| Wing chord (uniform) | 195 mm |
| Airfoil | NACA 2412 |
| Wing area | 0.197 m² |
| Aspect ratio | 5.18 |
| Fuselage length | 625 mm |
| Horizontal stabilizer span | 325 mm (tapered, 120 mm root / 60 mm tip) |
| Vertical fin height | 146 mm (swept) |
| Weight | 990 g |
| CG location | 245 mm from nose |
| Wing loading | 50.2 N/m² |
| Motor | 1000KV, 10×6 prop |
| Battery | 11.1V 2200mAh 3S LiPo |

All dimensions were taken directly from the physical aircraft and cross-checked against photos before modeling.

## CAD Design

The aircraft was modeled as four separate bodies in Fusion 360, then assembled into a single file:

- **Fuselage** — tapered profile (72 mm nose → 35 mm tail), motor mount cutout, battery bay opening, shelled/hollowed for weight, 2.5 mm edge fillets
- **Wing** — NACA 2412 airfoil sketched from manually-entered coordinates (UIUC/airfoiltools.com `.dat` file), lofted root-to-tip across the full 1010 mm span, with a center notch cut through the trailing edge to seat the fuselage
- **Horizontal tail** — stabilizer and elevator as separate hinged bodies, tapered planform, hinge pin and control horn modeled
- **Vertical tail** — fixed fin and rudder as separate hinged bodies, swept planform

**Wing spar:** A rectangular spar (~10 mm × 1010 mm, 5 mm extrusion) was added roughly 50 mm aft of the leading edge, modeled in stainless steel, to reinforce the wing against bending loads — see Structural Analysis below.

![Assembly - Isometric](CAD_Models/Assembly_Isometric.jpeg)
![Assembly - Side View](CAD_Models/Assembly_Side.jpeg)
![Assembly - Top View](CAD_Models/Assembly_Top.jpeg)

## Structural Analysis

**Objective:** Verify the wing survives a 3G maneuvering load without structural failure.

**Setup:**
- Wing body material: Polystyrene (closest available approximation to the depron foam used in the actual build)
- Constraint: fixed at the wing root
- Load: 30 N applied upward on the top wing surface, representing a 3G maneuver (990 g × 3g)
- Reinforcement: stainless steel spar positioned ~50 mm aft of the leading edge

**Result:**

| Metric | Value |
|---|---|
| Max von Mises stress | 0.265 MPa |
| Minimum safety factor | 163.75 |
| Safety factor target | 4.00 |
| Calculation basis | Yield strength (stainless steel, ~215 MPa) |

![Wing Stress Result](CAD_Models/Wing_Stress_Result.jpeg)

The wing sits far above the required safety margin — max von Mises stress of only 0.265 MPa against stainless steel's ~215 MPa yield strength — with no localized stress concentration near the root or the trailing-edge notch. This is a physically valid result but represents a significant over-design: a stainless steel spar has vastly more capacity than a 990g foam aircraft can generate under normal 3G loads.

A more realistic material choice for weight optimization would be a **carbon fiber pultruded tube** (e.g., ~5 mm OD × 3 mm ID, E ≈ 135 GPa, ρ ≈ 1600 kg/m³), which is the industry standard for RC aircraft spars in this weight class. Sizing to a target safety factor of 3–6 with CF would cut the spar mass by roughly 80% while still comfortably surviving the 3G load case. A future iteration of this analysis will run the trade study with that material and geometry.

In practical terms, the main real-world limiting factor for this design is more likely to be foam crushing/dent resistance at point loads (hand launches, hard landings) than in-flight bending — something a foam-specific material model would capture better than the polystyrene approximation used here.

## Aerodynamic Performance

**Objective:** Characterize stall speed, lift-to-drag performance, and cruise efficiency using real airfoil data combined with a 3D aircraft drag build-up.

**Method:** NACA 2412 lift and drag polars were pulled from Airfoil Tools (UIUC database, Xfoil-predicted) at Re = 200,000 — matching the Reynolds number at the aircraft's estimated cruise speed and chord length. These sectional polars were then combined with an aircraft-level drag build-up in a MATLAB script (`performance_analysis.m`):

- **Sectional airfoil drag** from the NACA 2412 polars
- **Induced drag:** CDᵢ = CL² / (π · e · AR), with Oswald efficiency e = 0.80 and AR = 5.18
- **Parasite drag:** estimated CD₀ = 0.022 (fuselage + tail + interference, flat-plate equivalent)

The Oswald efficiency and parasite drag coefficient are engineering estimates typical for a simple untapered wing and small foam airframe, not measured values — the resulting L/D figures should be read as first-order aircraft-level estimates, not precise performance predictions.

**Results:**

| Metric | Value |
|---|---|
| Max CL | 1.42 at α = 12° |
| Stall speed (1G, level flight) | 7.52 m/s (27.1 km/h) |
| Stall speed (3G maneuver) | 13.02 m/s (46.9 km/h) |
| Max aircraft L/D | 10.36 at 11.34 m/s (40.8 km/h) |
| Cruise L/D (at 15 m/s) | 8.95 at α = 0.21° |

**Cruise drag breakdown (at 15 m/s):**

| Drag component | Value |
|---|---|
| CD_airfoil (2D sectional) | 0.00812 |
| CD_induced (3D finite wing) | 0.00983 |
| CD_parasite (fuselage + tail) | 0.02200 |
| **CD_total** | **0.03995** |

![Aerodynamic Analysis](MATLAB_Analysis/RC_Plane_Performance_Analysis.png)

The three plots show the NACA 2412 lift curve, aircraft L/D vs. airspeed, and the full aircraft drag polar (with the 2D sectional polar overlaid for comparison).

Two things are worth noting from the drag breakdown. First, **parasite drag dominates at cruise** (~55% of total drag) — expected for a small, high-frontal-area foam airframe where the wing itself contributes relatively little of the total drag. Second, the aircraft cruises at a very low angle of attack (0.21°) with an L/D of ~9, below the maximum achievable L/D of ~10.4 which occurs closer to the stall boundary. Cruising near max L/D would leave little margin before stall, so trading a bit of efficiency for a comfortable stability margin is the right call for a hand-launched trainer.

## Results & Conclusions

Putting the structural and aerodynamic analysis together:

- The wing has significantly more structural margin than it needs — safety factor of 163 (max stress 0.265 MPa) against a target of 4 — because the stainless steel spar is over-designed for a 990g foam aircraft. A carbon fiber pultruded tube would be the realistic material choice in a future iteration.
- The aircraft's low stall speed (7.5 m/s) and reasonable aircraft L/D (~10 max, ~9 at cruise) are consistent with a well-matched wing loading for a lightweight trainer — good for easy hand launches and forgiving low-speed handling.
- Cruise performance sits well clear of stall with a comfortable stability margin still in reserve, which is a sensible, conservative trim point for this class of aircraft.
- Parasite drag dominates the cruise drag budget, so the biggest real-world efficiency gains would come from cleaning up the fuselage/tail rather than tweaking the airfoil.

The main limitations of this analysis are (1) the use of polystyrene as a stand-in for depron foam in the structural study, (2) an over-designed stainless steel spar rather than a realistic CF spar, and (3) estimated (not measured) values for Oswald efficiency and parasite drag in the aerodynamic study. All three are reasonable first-pass approximations for this scope. The next iteration would incorporate a proper foam material model, a CF spar sized for a realistic SF of 3–6, and a more refined parasite drag estimate (component build-up rather than a single flat-plate equivalent).

## Repository Structure

```
RC_Plane_Analysis-/
├── CAD_Models/          # Fusion 360 files + assembly/stress screenshots
├── MATLAB_Analysis/     # performance_analysis.m, rc_plane_specs.m, plots
├── Documentation/       # This README and supporting docs
└── README.md
```

## Tools Used

- **CAD & Simulation:** Autodesk Fusion 360 (modeling + Static Stress FEA)
- **Aerodynamic Analysis:** MATLAB
- **Airfoil Data:** NACA 2412 polars, UIUC Airfoil Coordinates Database via Airfoil Tools (Xfoil prediction, Re = 200,000)
