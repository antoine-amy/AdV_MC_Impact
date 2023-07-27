function Cout = Remove_SBs(Cin)
% Cout = Remove_SBs(Cin) Remove the sideband fields from the dual Recycling
% cavity instance. Could be useful to speed up a calculation when the SB are not
% useful in the simulations

p  = inputParser;
p.FunctionName = 'Remove the SBs field from a cavity';

% Check if the first argument is an interface
p.addRequired('Cin', @(x)isa(x, 'Cavity1'));

p.parse(Cin)

Cin = p.Results.Cin;

Cout = Cin;

% Remove the SB from the input field:
Cout.Laser_in.Nb_Pair_SB = 0;

% Remove from the expected circulating field:
Cout.Field_reso_guess.Nb_Pair_SB = 0;

end