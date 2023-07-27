function DRout = Remove_SBs(DRin)
% Cout = Remove_SBs(Cin) Remove the sideband fields from the Cavity1
% instance. Could be useful to speed up a calculation when the SB are not
% useful in the simulations

p  = inputParser;
p.FunctionName = 'Remove the SB field from the input beam';

% Check if the first argument is a dual recycling instance
p.addRequired('DRin', @(x)isa(x, 'Dual_recycling'));
p.parse(DRin)

DRin = p.Results.DRin;
DRout = DRin;

% Remove the SB from the input field:
DRout.Laser_in.Nb_Pair_SB = 0;


% Remove SB from NA expected circulating field:
DRout.North_arm.Field_reso_guess.Nb_Pair_SB = 0;

% Remove SB from EA expected circulating field:
DRout.East_arm.Field_reso_guess.Nb_Pair_SB = 0;

end