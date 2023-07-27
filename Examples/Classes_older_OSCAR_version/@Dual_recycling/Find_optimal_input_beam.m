% Already defined the ifo

% Assume the perfect mode matching for the arm
[wo,ro] = Check_Stability(West_arm,varargin);
West_arm.Laser_in = E_Field(G1,'w',wo,'R',wo);
West_arm = Calculate_Fields_AC(West_arm);
West_arm.Display_Results