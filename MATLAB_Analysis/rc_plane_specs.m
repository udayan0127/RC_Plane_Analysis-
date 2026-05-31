%% RC PLANE AIRCRAFT SPECIFICATIONS
% Custom fixed-wing trainer aircraft
% Purpose: Design validation and performance analysis

clear all; close all; clc;

%% GEOMETRIC PROPERTIES
% Fuselage
fuselage_length = 0.635;        % meters (62.5 cm average)
fuselage_width = 0.08;          % meters

% Wing
wing_span = 1.01;               % meters (101 cm)
wing_chord = 0.195;             % meters (19.5 cm)
wing_area = wing_span * wing_chord;  % m²

% Tail surfaces
horizontal_stab_length = 0.325; % meters
horizontal_stab_width = 0.122;  % meters
horiz_stab_area = horizontal_stab_length * horizontal_stab_width;

vertical_fin_height = 0.255;    % meters
vertical_fin_width = 0.14;      % meters
vert_fin_area = vertical_fin_height * vertical_fin_width;

% Aspect ratio
wing_aspect_ratio = wing_span^2 / wing_area;

%% WEIGHT PROPERTIES
total_mass = 0.99;              % kg (990 grams)
total_weight = total_mass * 9.81; % Newtons

%% CENTER OF GRAVITY
cg_from_nose = 0.245;           % meters (24.5 cm from nose)
cg_percent_chord = (cg_from_nose - 0) / wing_chord * 100;  % % of wing chord

%% PROPULSION PROPERTIES
motor_kv = 1000;                % RPM per Volt
battery_voltage = 11.1;         % Volts (3S LiPo)
battery_capacity = 2200;        % mAh
propeller_diameter = 10 * 0.0254; % 10 inches to meters
propeller_pitch = 6 * 0.0254;   % 6 inches to meters

% Calculate max RPM
max_rpm = motor_kv * battery_voltage;

%% CALCULATED PERFORMANCE PARAMETERS
wing_loading = total_weight / wing_area;  % N/m²
thrust_to_weight_estimate = 1.2;  % typical for RC trainer (1.0-1.5)
estimated_max_thrust = total_weight * thrust_to_weight_estimate;

%% DISPLAY SUMMARY
fprintf('=== RC PLANE AIRCRAFT SUMMARY ===\n\n');
fprintf('GEOMETRY:\n');
fprintf('  Wing Area:          %.4f m²\n', wing_area);
fprintf('  Aspect Ratio:       %.2f\n', wing_aspect_ratio);
fprintf('  Fuselage Length:    %.3f m\n', fuselage_length);
fprintf('\nWEIGHT:\n');
fprintf('  Total Mass:         %.2f kg\n', total_mass);
fprintf('  Total Weight:       %.2f N\n', total_weight);
fprintf('  Wing Loading:       %.2f N/m²\n', wing_loading);
fprintf('\nCENTER OF GRAVITY:\n');
fprintf('  Distance from nose: %.3f m (%.1f cm)\n', cg_from_nose, cg_from_nose*100);
fprintf('  %% of wing chord:    %.1f%%\n', cg_percent_chord);
fprintf('\nPROPULSION:\n');
fprintf('  Max RPM:            %.0f\n', max_rpm);
fprintf('  Est. Max Thrust:    %.2f N\n', estimated_max_thrust);
fprintf('  Est. T/W Ratio:     %.2f\n', thrust_to_weight_estimate);
fprintf('\n=====================================\n');

%% SAVE SPECS FOR OTHER SCRIPTS
save('rc_plane_specs.mat', 'wing_span', 'wing_chord', 'wing_area', ...
    'total_mass', 'total_weight', 'cg_from_nose', 'fuselage_length', ...
    'battery_voltage', 'motor_kv', 'wing_aspect_ratio', 'wing_loading');