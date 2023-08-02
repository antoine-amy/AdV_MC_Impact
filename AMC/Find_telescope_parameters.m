clearvars; close all;
addpath(genpath([pwd filesep '..' filesep 'Classes']));

% Define the grid for the simulation: 256 X 256, 10 cm X 10 cm
G1 = Grid(256,0.10);

% Define one incoming beam (beam radius: 5 cm) 
E_input = E_Field(G1,'w',0.0487314);

% Propagate over 10m
E2 = Propagate_E(E_input,10);

% Define an anonymous function for optimization
beam_radius_error = @(x) abs(Fit_TEM00(Focus_Beam_With_Telescope(E2,x)) - 133e-6);

% Initial guess
x0 = [5.85398, 5.06768, -4.10824, 0.661768];

% Set boundaries for the 4 parameters
lb = [-100, 0, -100, 0];
ub = [100, 20, 100, 20];

% Perform the optimization
options = optimoptions('fmincon','Algorithm','sqp'); % 'sqp' is Sequential Quadratic Programming method
optimal_params = fmincon(beam_radius_error, x0, [], [], [], [], lb, ub, [], options);

% Propagate the beam using the optimized parameters
[E3,G3] = Focus_Beam_With_Telescope(E2,optimal_params);

% Then display the beam parameters:
disp('FFT code result:')
[end_radius, end_RofC] = Fit_TEM00(E3);
fprintf('End radius: %g \n',end_radius);

% Display the new length of the grid
fprintf('New length of the grid: %g \n',G3.Length)
