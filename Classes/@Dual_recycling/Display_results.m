function Display_results(DRin)
% Display_results(Pin) display the results of the PRC calculations.
% The function Calculate_fields() must have been run first

if isempty(DRin.Field_circ)
    error('Display_results(): Before displaying the results, the function Calculate_fields() must be run')
end

fprintf(' Input power for the carrier: %g [W] \n',Calculate_Power(DRin.Laser_in))
disp('')
fprintf(' PRC carrier circulating power; %g [W] \n',Calculate_Power(DRin.Field_circ))
fprintf(' North arm carrier circulating power: %g [W] \n',Calculate_Power(DRin.Field_NA_circ))
fprintf(' East arm carrier circulating power: %g [W] \n',Calculate_Power(DRin.Field_EA_circ))
disp('  ')
fprintf(' PRC reflected field %g [W] \n',Calculate_Power(DRin.Field_ref))
fprintf(' Carrier Dark port power (after SR): %g [W] \n',Calculate_Power(DRin.Field_DP))

fprintf('\n---- Relative gain for the carrier: ------ \n')
fprintf(' PRC carrier recycling gain: %g \n',Calculate_Power(DRin.Field_circ)/Calculate_Power(DRin.Laser_in))
fprintf(' PRC DP carrier (after SR): %g [W] \n',Calculate_Power(DRin.Field_DP)/Calculate_Power(DRin.Laser_in))
fprintf(' PRC Reflect field carrier %g  \n',Calculate_Power(DRin.Field_ref)/Calculate_Power(DRin.Laser_in))

for ii = 1:DRin.Field_circ.Nb_Pair_SB
    fprintf('\n---- SB %i: %5.4g MHz : ------ \n',ii,DRin.Laser_in.SB(ii).Frequency_Offset/1E6)
    
    [l1,u1] = Calculate_Power(DRin.Laser_in,'include','SB','SB_num',ii);
    [l2,u2] = Calculate_Power(DRin.Field_circ,'include','SB','SB_num',ii);
    [l3,u3] = Calculate_Power(DRin.Field_DP,'include','SB','SB_num',ii);
    
    fprintf(' PRC circulating SB gains: %g  %g    \n',l2/l1,u2/u1)
    fprintf(' PRC DP SB gains (after SR): %g  %g    \n',l3/l1,u3/u1)
    
end



%figure(104)
%plot(Pin.Power_buildup)

figure(105)
clf;
subplot(2,2,1)
E_Plot(DRin.Laser_in)
title('Input field')
subplot(2,2,2)
E_Plot(DRin.Field_circ)
title('Circulating field')
subplot(2,2,3)
E_Plot(DRin.Field_ref)
title('Reflected field')
subplot(2,2,4)
E_Plot(DRin.Field_DP)
title('Dark port field')

%Calculate_power(Pin.Field_circ)*0.0216 + Calculate_power(Pin.Field_ref)

end