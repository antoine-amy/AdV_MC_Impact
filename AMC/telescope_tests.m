clearvars; close all;
addpath(genpath([pwd filesep '..' filesep 'Classes']));

disp('---------------------------------------------------------------------------')
disp('                  OSCAR V3.30                                      ')
disp('  ')

%% Define fields:
load('AV_DR-1410m-100nrad.mat');
SB_6M_freq = 6.270777E6;
SB_8M_freq = 8.361036E6;

AV_DR.Field_circ.Grid=Grid(256,50e-2);
E_input = AV_DR.Field_circ;
G1=AV_DR.Field_circ.Grid;
G1.Step_sq=G1.Step^2;

% Propagate over 10m
E2 = Propagate_E(E_input,10);

fprintf('Old length of the grid: %g \n',G1.Length)
disp('Before FFT code result:')
Fit_TEM00(E2)
disp('')

%% Then define a telescope:

% Initialize x values and empty array for F32
x_values = linspace(1.79747, 1.79848, 10);
F33_values = zeros(size(x_values));
min_diff = inf;
target_W = 133e-6;
selected_x = 0;
selected_WP = 0;

% Initialize progress bar
f = waitbar(0,'Please wait...');


for i = 1:length(x_values)
    x = x_values(i);
    [E3,G3] = Focus_Beam_With_Telescope(E2,[50 51 -x 0.20]);
    [F32,F33] = Fit_TEM00(E3);
    [w,R,w0,Pos] = Fit_TEM00(E3);
    Fit_TEM00(E3,'Output','W_P');

    % Check if this W is closer to target_W than previous min_diff
    if abs(w0 - target_W) < min_diff
        min_diff = abs(w0 - target_W);
        selected_x = x;
        selected_WP = Pos;
    end
    
    fprintf('For: %g \n',x)
    
    % Update progress bar
    waitbar(i / length(x_values), f, sprintf('Progress: %3.2f %%', 100 * i / length(x_values)));
end

% Close progress bar
close(f)

disp('')
disp(selected_x)
disp(selected_WP)
disp('')

[E32,G32] = Focus_Beam_With_Telescope(E2,[50 51 -selected_x 0.20]);

Fit_TEM00(E3,'Output','W_P');
disp('')

% Propagate the field over the distance WP
E_final = Propagate_E(E3, selected_WP);
Fit_TEM00(E_final);
E_Plot(E_final);
