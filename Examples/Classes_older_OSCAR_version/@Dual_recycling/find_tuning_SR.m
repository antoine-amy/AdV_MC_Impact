function Pout = find_tuning_SR(Pin,varargin)

p = inputParser;
p.addRequired('Pin', @(x)isa(x, 'Dual_recycling'));
p.addParameter('Nb_point',201,@(x)isnumeric(x) && x>0);
p.addParameter('Nb_iter',16,@(x)isnumeric(x) && x>0);
p.addOptional('Find_max','max', @(x)strcmpi(x,'quadratic_fit') | ...
    strcmpi(x,'max') |  strcmpi(x,'airy_fit')) % other not working so good

p.parse(Pin,varargin{:})
Scan_Nb_point = round(p.Results.Nb_point);
Nb_iter = round(p.Results.Nb_iter);

Pout = Pin;

display_switch = true;

% Add a large dark fringe offset
dfo = 2*pi*(8E-11)/1064E-9;
Pin.North_arm.Resonance_phase = Pin.North_arm.Resonance_phase .* exp(1i*dfo);
Pin.East_arm.Resonance_phase = Pin.East_arm.Resonance_phase .* exp(-1i*dfo);

SR_detuning = linspace(0,pi,Scan_Nb_point);
Pcirc_SR_vec = zeros(1,length(SR_detuning));

for ii = 1:length(SR_detuning)
    P2 = Remove_SBs(Pin);
    P2.reso_South  = SR_detuning(ii);   
    P2 = Calculate_fields(P2,'iter',Nb_iter,'display',false);
    Pcirc_SR_vec(ii) = Calculate_Power(P2.Field_DP);   
end

if display_switch
    figure(301)
    plot(SR_detuning,Pcirc_SR_vec)
    disp('SR phase scan')
end

switch p.Results.Find_max
    case 'airy_fit'
        options = optimset('Display','off','MaxFunEvals',10000);
        fct_airy = @(param,x_data) param(1) ./ (1 + param(2) * sin(param(3)*(x_data - param(4) )).^2);
        x_sol = lsqcurvefit(fct_airy,[max(Pcirc_SR_vec) 10 1 0.3],SR_detuning,Pcirc_SR_vec,[],[],options);
        max_pox = x_sol(4);
    case 'quadratic_fit'
        poly = polyfit(SR_detuning,Pcirc_SR_vec,2);
        max_pox = - poly(2) / (2*poly(1));
    case 'max'
        [~,ind_max] = max(Pcirc_SR_vec);
        max_pox = SR_detuning(ind_max);
end

Pout.reso_South = max_pox + pi/2;

fprintf('SR Detuning: %g \n',Pout.reso_South);

end
