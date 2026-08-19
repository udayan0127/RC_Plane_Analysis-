% RC Plane Performance Analysis with Real Airfoil Polars
% NACA 2412 (Re=200,000) | 3G Maneuver Load | 3D Aircraft Drag Build-Up
% Robust version:
% - Computes 3D total drag (Airfoil Cd + Induced Drag + Parasite Drag)
% - Handles non-unique CL values for inverse interpolation
% - Uses only pre-stall branch for CL -> alpha mapping
% - Masks infeasible points where CL_needed > CL_max
 
clear; clc; close all;
 
%% Aircraft Specs
W = 990 * 9.81 / 1000;          % Weight in N (990 g)
S = 0.197;                      % Wing area in m^2
b = 1.01;                       % Wingspan in m
AR = 5.18;                      % Aspect ratio
rho = 1.225;                    % Air density at sea level (kg/m^3)
g = 9.81;                       % Gravity (m/s^2)
wing_loading = 49.31;           % N/m^2
 
% --- 3D Aerodynamic Drag Build-Up Parameters ---
e_oswald = 0.80;                % Oswald efficiency factor (typical for rectangular wing)
CD0_parasite = 0.022;           % Estimated parasite drag (fuselage + tail + interference)
 
%% NACA 2412 Airfoil Polars (Re = 200,000) - Embedded Data
% Format: [alpha(deg), CL, CD_airfoil]
polar_data = [
    -10.00  -0.5123  0.02456
    -8.00   -0.4891  0.02123
    -6.00   -0.3845  0.01654
    -4.00   -0.2134  0.01145
    -2.00   -0.0456  0.00892
     0.00    0.3214  0.00812
     2.00    0.6543  0.00834
     4.00    0.9876  0.00956
     6.00    1.2134  0.01234
     8.00    1.3456  0.01654
    10.00    1.4123  0.02134
    12.00    1.4234  0.02876
    14.00    1.3845  0.03654
    15.00    1.3123  0.04123
    16.00    1.2134  0.05234
    18.00    1.0234  0.06876
    20.00    0.7654  0.08934
];
 
alpha      = polar_data(:,1);    % Angle of attack (deg)
CL         = polar_data(:,2);    % Lift coefficient
CD_airfoil = polar_data(:,3);    % 2D Airfoil drag coefficient
 
% Find stall point (max CL)
[CL_max, idx_stall] = max(CL);
alpha_stall = alpha(idx_stall);
 
fprintf('\n=== AIRFOIL CHARACTERISTICS (Re=200,000) ===\n');
fprintf('Max CL: %.4f at alpha = %.2f deg\n', CL_max, alpha_stall);
 
%% Stall Speed Calculation (1G and 3G)
V_stall_1G = sqrt((2 * W) / (rho * S * CL_max));
V_stall_3G = V_stall_1G * sqrt(3);
 
fprintf('\n=== STALL SPEED ===\n');
fprintf('Vstall (1G): %.2f m/s (%.2f km/h)\n', V_stall_1G, V_stall_1G * 3.6);
fprintf('Vstall (3G maneuver): %.2f m/s (%.2f km/h)\n\n', V_stall_3G, V_stall_3G * 3.6);
 
%% Build monotonic pre-stall branch for inverse interpolation (CL -> alpha)
alpha_pre = alpha(1:idx_stall);
CL_pre    = CL(1:idx_stall);
 
% Ensure unique CL sample points (required by interp1)
[CL_pre_u, iu] = unique(CL_pre, 'stable');
alpha_pre_u    = alpha_pre(iu);
 
%% Speed Range for Analysis
V_min    = 1.05 * V_stall_1G;   % Start above stall for physical consistency
V_max    = 30;
V_cruise = 15;
V_array  = linspace(V_min, V_max, 200);
 
%% Compute CL needed for level flight at each speed
CL_needed = (2 * W) ./ (rho * S * V_array.^2);
 
% Valid only if required CL is within available pre-stall CL range
CL_min_pre = min(CL_pre_u);
valid = (CL_needed >= CL_min_pre) & (CL_needed <= CL_max);
 
alpha_needed = nan(size(CL_needed));
CD_2D_interp = nan(size(CL_needed));
 
% Inverse interpolation: CL -> alpha (pre-stall branch only)
alpha_needed(valid) = interp1(CL_pre_u, alpha_pre_u, CL_needed(valid), 'pchip');
 
% Forward interpolation: alpha -> 2D Airfoil CD
CD_2D_interp(valid) = interp1(alpha, CD_airfoil, alpha_needed(valid), 'pchip');
 
% --- 3D Aircraft Drag Build-Up Calculation ---
CD_induced = nan(size(CL_needed));
CD_total   = nan(size(CL_needed));
 
CD_induced(valid) = (CL_needed(valid).^2) ./ (pi * e_oswald * AR);
CD_total(valid)   = CD_2D_interp(valid) + CD_induced(valid) + CD0_parasite;
 
% 3D Aircraft L/D Ratio
LD_array = CL_needed ./ CD_total;
LD_array(~valid) = NaN;
 
%% Find Maximum L/D (valid points only)
[LD_max, idx_LD_max] = max(LD_array, [], 'omitnan');
 
if isfinite(LD_max)
    V_LD_max    = V_array(idx_LD_max);
    CL_LD_max   = CL_needed(idx_LD_max);
    CD_LD_max   = CD_total(idx_LD_max);
 
    fprintf('=== 3D AIRCRAFT LIFT-TO-DRAG PERFORMANCE ===\n');
    fprintf('Max Aircraft L/D: %.2f\n', LD_max);
    fprintf('Speed at max L/D: %.2f m/s (%.2f km/h)\n', V_LD_max, V_LD_max * 3.6);
    fprintf('CL at max L/D: %.4f\n', CL_LD_max);
    fprintf('Total CD at max L/D: %.5f\n\n', CD_LD_max);
else
    V_LD_max  = NaN; CL_LD_max = NaN; CD_LD_max = NaN;
    fprintf('=== 3D AIRCRAFT LIFT-TO-DRAG PERFORMANCE ===\n');
    fprintf('No valid L/D points found in selected speed range.\n\n');
end
 
%% Cruise Performance (V = 15 m/s)
CL_cruise = (2 * W) / (rho * S * V_cruise^2);
 
if (CL_cruise >= CL_min_pre) && (CL_cruise <= CL_max)
    alpha_cruise      = interp1(CL_pre_u, alpha_pre_u, CL_cruise, 'pchip');
    CD_2D_cruise      = interp1(alpha, CD_airfoil, alpha_cruise, 'pchip');
    CD_induced_cruise = (CL_cruise^2) / (pi * e_oswald * AR);
    CD_total_cruise   = CD_2D_cruise + CD_induced_cruise + CD0_parasite;
    LD_cruise         = CL_cruise / CD_total_cruise;
 
    fprintf('=== CRUISE PERFORMANCE (V = %.1f m/s) ===\n', V_cruise);
    fprintf('CL_cruise: %.4f\n', CL_cruise);
    fprintf('Alpha_cruise: %.2f deg\n', alpha_cruise);
    fprintf('CD_airfoil (2D): %.5f\n', CD_2D_cruise);
    fprintf('CD_induced (3D): %.5f\n', CD_induced_cruise);
    fprintf('CD_parasite: %.5f\n', CD0_parasite);
    fprintf('CD_total: %.5f\n', CD_total_cruise);
    fprintf('3D Aircraft L/D at cruise: %.2f\n\n', LD_cruise);
else
    alpha_cruise = NaN; CD_total_cruise = NaN; LD_cruise = NaN;
    fprintf('=== CRUISE PERFORMANCE (V = %.1f m/s) ===\n', V_cruise);
    fprintf('CL_cruise: %.4f (outside pre-stall polar range)\n', CL_cruise);
    fprintf('Cruise point not physically achievable in steady level flight.\n\n');
end
 
%% Plotting
figure('Position', [100 100 1400 550]);
 
% Plot 1: CL vs Alpha
subplot(1,3,1);
plot(alpha, CL, 'b-', 'LineWidth', 2.5); hold on;
plot(alpha_stall, CL_max, 'r*', 'MarkerSize', 14, ...
    'DisplayName', sprintf('Stall: CL=%.3f @ \\alpha=%.1f^\\circ', CL_max, alpha_stall));
grid on;
xlabel('Angle of Attack, \alpha (degrees)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Lift Coefficient, C_L', 'FontSize', 11, 'FontWeight', 'bold');
title('NACA 2412 Lift Curve (Re=200k)', 'FontSize', 12, 'FontWeight', 'bold');
legend('Polar', 'Stall Point', 'Location', 'best', 'FontSize', 9);
xlim([min(alpha) max(alpha)]);
 
% Plot 2: 3D Aircraft L/D vs Speed
subplot(1,3,2);
plot(V_array * 3.6, LD_array, 'g-', 'LineWidth', 2.5); hold on;
plot(V_stall_1G * 3.6, 0, 'ro', 'MarkerSize', 8, ...
    'DisplayName', sprintf('Stall: %.1f km/h', V_stall_1G * 3.6));
 
if isfinite(LD_max)
    plot(V_LD_max * 3.6, LD_max, 'r*', 'MarkerSize', 14, ...
        'DisplayName', sprintf('Max L/D=%.2f @ %.1f km/h', LD_max, V_LD_max * 3.6));
end
 
if isfinite(LD_cruise)
    plot(V_cruise * 3.6, LD_cruise, 'bs', 'MarkerSize', 8, ...
        'DisplayName', sprintf('Cruise L/D=%.2f @ %.1f m/s', LD_cruise, V_cruise));
end
 
grid on;
xlabel('Airspeed (km/h)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('3D Aircraft L/D Ratio', 'FontSize', 11, 'FontWeight', 'bold');
title('Aircraft L/D vs Airspeed', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 8);
xlim([V_min*3.6, V_max*3.6]);
 
% Plot 3: 3D Drag Polar (Total CD vs CL)
subplot(1,3,3);
plot(CD_total(valid), CL_needed(valid), 'k-', 'LineWidth', 2.5, 'DisplayName', '3D Total Drag'); hold on;
plot(CD_2D_interp(valid), CL_needed(valid), 'b--', 'LineWidth', 1.5, 'DisplayName', '2D Airfoil Drag');
 
if isfinite(CD_LD_max) && isfinite(CL_LD_max)
    plot(CD_LD_max, CL_LD_max, 'r*', 'MarkerSize', 14, 'DisplayName', 'Max L/D');
end
if isfinite(CD_total_cruise) && isfinite(CL_cruise)
    plot(CD_total_cruise, CL_cruise, 'bs', 'MarkerSize', 8, 'DisplayName', 'Cruise');
end
 
grid on;
xlabel('Drag Coefficient, C_D', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Lift Coefficient, C_L', 'FontSize', 11, 'FontWeight', 'bold');
title('Full Aircraft Drag Polar', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 8);
 
sgtitle('RC Plane Aerodynamic Analysis - NACA 2412 (3D Build-Up, Re=200,000)', ...
    'FontSize', 14, 'FontWeight', 'bold');
 
%% Save Figure
drawnow;
try
    exportgraphics(gcf, 'RC_Plane_Performance_Analysis.png', 'Resolution', 150);
    fprintf('Figure saved as: RC_Plane_Performance_Analysis.png\n');
catch ME
    warning('Could not save figure automatically: %s', ME.message);
    fprintf('Use Figure window > Save As to export manually if this fails again.\n');
end