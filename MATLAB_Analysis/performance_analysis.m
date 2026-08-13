% RC Plane Performance Analysis with Real Airfoil Polars
% NACA 2412 (Re=200,000) | 3G Maneuver Load | CL vs Alpha + Performance
% Robust version:
% - Handles non-unique CL values for inverse interpolation
% - Uses only pre-stall branch for CL -> alpha mapping
% - Masks infeasible points where CL_needed > CL_max



%% Aircraft Specs
W = 990 * 9.81 / 1000;          % Weight in N (990 g)
S = 0.197;                      % Wing area in m^2
b = 1.01;                       % Wingspan in m
AR = 5.18;                      % Aspect ratio
rho = 1.225;                    % Air density at sea level (kg/m^3)
g = 9.81;                       % Gravity (m/s^2)
wing_loading = 49.31;           % N/m^2

%% NACA 2412 Airfoil Polars (Re = 200,000) - Embedded Data
% Format: [alpha(deg), CL, CD]
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

alpha = polar_data(:,1);        % Angle of attack (deg)
CL    = polar_data(:,2);        % Lift coefficient
CD    = polar_data(:,3);        % Drag coefficient

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
V_min    = 1.05 * V_stall_1G;   % start above stall for physical consistency
V_max    = 30;
V_cruise = 15;
V_array  = linspace(V_min, V_max, 200);

%% Compute CL needed for level flight at each speed
CL_needed = (2 * W) ./ (rho * S * V_array.^2);

% Valid only if required CL is within available pre-stall CL range
CL_min_pre = min(CL_pre_u);
valid = (CL_needed >= CL_min_pre) & (CL_needed <= CL_max);

alpha_needed = nan(size(CL_needed));
CD_interp    = nan(size(CL_needed));

% Inverse interpolation: CL -> alpha (pre-stall branch only)
alpha_needed(valid) = interp1(CL_pre_u, alpha_pre_u, CL_needed(valid), 'pchip');

% Forward interpolation: alpha -> CD
CD_interp(valid) = interp1(alpha, CD, alpha_needed(valid), 'pchip');

% L/D
LD_array = CL_needed ./ CD_interp;
LD_array(~valid) = NaN;

%% Find Maximum L/D (valid points only)
[LD_max, idx_LD_max] = max(LD_array, [], 'omitnan');

if isfinite(LD_max)
    V_LD_max  = V_array(idx_LD_max);
    CL_LD_max = CL_needed(idx_LD_max);
    CD_LD_max = CD_interp(idx_LD_max);

    fprintf('=== LIFT-TO-DRAG PERFORMANCE ===\n');
    fprintf('Max L/D: %.2f\n', LD_max);
    fprintf('Speed at max L/D: %.2f m/s (%.2f km/h)\n', V_LD_max, V_LD_max * 3.6);
    fprintf('CL at max L/D: %.4f\n', CL_LD_max);
    fprintf('CD at max L/D: %.5f\n\n', CD_LD_max);
else
    V_LD_max  = NaN; CL_LD_max = NaN; CD_LD_max = NaN;
    fprintf('=== LIFT-TO-DRAG PERFORMANCE ===\n');
    fprintf('No valid L/D points found in selected speed range.\n\n');
end

%% Cruise Performance (V = 15 m/s)
CL_cruise = (2 * W) / (rho * S * V_cruise^2);

if (CL_cruise >= CL_min_pre) && (CL_cruise <= CL_max)
    alpha_cruise = interp1(CL_pre_u, alpha_pre_u, CL_cruise, 'pchip');
    CD_cruise    = interp1(alpha, CD, alpha_cruise, 'pchip');
    LD_cruise    = CL_cruise / CD_cruise;

    fprintf('=== CRUISE PERFORMANCE (V = %.1f m/s) ===\n', V_cruise);
    fprintf('CL_cruise: %.4f\n', CL_cruise);
    fprintf('Alpha_cruise: %.2f deg\n', alpha_cruise);
    fprintf('CD_cruise: %.5f\n', CD_cruise);
    fprintf('L/D at cruise: %.2f\n\n', LD_cruise);
else
    alpha_cruise = NaN; CD_cruise = NaN; LD_cruise = NaN;
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

% Plot 2: L/D vs Speed
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
ylabel('L/D Ratio', 'FontSize', 11, 'FontWeight', 'bold');
title('Lift-to-Drag vs Airspeed', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 8);
xlim([V_min*3.6, V_max*3.6]);

% Plot 3: Drag Polar (CD vs CL)
subplot(1,3,3);
plot(CD, CL, 'b-', 'LineWidth', 2.5); hold on;

if isfinite(CD_LD_max) && isfinite(CL_LD_max)
    plot(CD_LD_max, CL_LD_max, 'r*', 'MarkerSize', 14, 'DisplayName', 'Max L/D');
end
if isfinite(CD_cruise) && isfinite(CL_cruise)
    plot(CD_cruise, CL_cruise, 'bs', 'MarkerSize', 8, 'DisplayName', 'Cruise');
end

grid on;
xlabel('Drag Coefficient, C_D', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Lift Coefficient, C_L', 'FontSize', 11, 'FontWeight', 'bold');
title('Drag Polar (NACA 2412)', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 9);

sgtitle('RC Plane Aerodynamic Analysis - NACA 2412 (Re=200,000)', ...
    'FontSize', 14, 'FontWeight', 'bold');

%% Save Figure
saveas(gcf, 'RC_Plane_Performance_Analysis.png');
fprintf('Figure saved as: RC_Plane_Performance_Analysis.png\n');%