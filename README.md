# NACA 4-Digit Aerofoil Analysis Tool

A MATLAB tool for aerodynamic analysis of NACA 4-digit series aerofoils, implementing both **Thin Aerofoil Theory** and a **Vortex Panel Method** from scratch.

Built as a portfolio project during my placement year at PCC Airfoils, prior to final year of Aerospace Engineering at Sheffield Hallam University.

---

## What it does

Given any NACA 4-digit designation (e.g. 2412, 0012, 4415), the tool generates:

- **Aerofoil geometry** from the NACA analytical equations with cosine spacing
- **Cl vs alpha** comparison between thin aerofoil theory and vortex panel method
- **Pressure distribution (Cp)** across upper and lower surfaces at a specified angle of attack
- **Drag polar** using the parabolic drag model (Cd = Cd0 + Cl²/πAR)
- **L/D vs alpha** showing the optimum cruise angle of attack

---

Results — NACA 2412

![Aerofoil Geometry](figures/Figure%201%20Aerofoil%20Geometry.png)
![Cl vs Alpha](figures/Figure%202%20Cl%20vs%20Alpha.png)
![Pressure Distribution](figures/Figure%203%20Pressure%20Distribution.png)
![Drag Polar](figures/Figure%204%20Drag%20Polar.png)
![L/D vs Alpha](figures/Figure%205%20L.D%20vs%20Alpha.png)

---

## How to run

1. Open `aerofoil_analysis3.m` in MATLAB or MATLAB Online
2. Set your chosen aerofoil and parameters at the top of the script:
matlab
naca        = '2412';   % any NACA 4-digit series
alpha_range = -10:1:20; % angle of attack sweep [deg]
N_panels    = 100;      % number of vortex panels
alpha_cp    = 5;        % alpha for Cp plot [deg]
AR          = 8;        % wing aspect ratio
Cd0         = 0.02;     % zero-lift drag coefficient

3. Run the script — all 5 figures generate automatically

> **Note** The panel method involves nested loops and may take 30–60 seconds in MATLAB Online.

---

## Theory

### Thin Aerofoil Theory
Assumes the aerofoil is replaced by an infinitely thin vortex sheet along the camber line. The lift curve slope is derived analytically as 2π per radian, with the zero-lift angle computed from the Fourier integral of the camber line slope:

Cl = 2π(α − α_L0)


### Vortex Panel Method
Implements a constant-strength vortex panel scheme with the Kutta condition enforced at the trailing edge. The no-penetration boundary condition is applied at each panel midpoint, forming a linear system solved via least squares. Lift is computed using the Kutta-Joukowski theorem:

Cl = 2Γ / (V∞ · c)


### Drag Model
Both methods assume inviscid potential flow. By d'Alembert's paradox, pressure drag is theoretically zero in inviscid flow. The drag polar therefore uses the standard parabolic model:

Cd = Cd0 + Cl² / (π · AR)


For viscous drag and stall prediction, the natural next step is coupling with a boundary layer solver such as XFOIL.

---

## Known limitations

- Inviscid flow only - no viscosity, no boundary layer, no stall prediction
- Thin aerofoil theory assumes small angles and attached flow
- Vortex panel Cl accuracy degrades at high angles of attack
- Compressibility effects not modelled (valid for low Mach number only)

---

## Author

Vincent Cattell - Aerospace Engineering, Sheffield Hallam University  
