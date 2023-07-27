function Pout = Refined_tuning(Pin,varargin)

p = inputParser;
p.addRequired('Pin', @(x)isa(x, 'Dual_recycling'));
p.addParameter('zoom',0.04,@(x)isnumeric(x) && x>0);
p.addParameter('Nb_iter',4,@(x)isnumeric(x) && x>0);
p.addParameter('Nb_scan',21,@(x)isnumeric(x) && x>0);
p.addOptional('Find_max','quadratic_fit', @(x)strcmpi(x,'quadratic_fit') | ...
    strcmpi(x,'max') |  strcmpi(x,'airy_fit'))

p.parse(Pin,varargin{:})
Zoom_range = p.Results.zoom;
Nb_iter = p.Results.Nb_iter; % to calculate the circulating power
Nb_pt_scan = p.Results.Nb_scan; % to scan the detuning

display_switch = false;

Pout = Pin;

Common_detuning = linspace(-Zoom_range,Zoom_range,Nb_pt_scan);
Pcirc_vec = zeros(1,length(Common_detuning));

% Pin.I_SRM.t = 1i;
% Pin.I_SRM.r = 0;
% Pin.reso_South = 0;

for ii = 1:length(Common_detuning)
    P2 = Remove_SBs(Pin);
    %P2 = Pin;
    %P2
    P2.reso_North = P2.reso_North .* exp(1i*Common_detuning(ii));
    P2.reso_East = P2.reso_East .* exp(1i*Common_detuning(ii));
    
    P2 = Calculate_fields(P2,'iter',Nb_iter,'display',false);
    Pcirc_vec(ii) = Calculate_Power(P2.Field_circ);
    
end

switch p.Results.Find_max
    case 'airy_fit'
        options = optimset('Display','off','MaxFunEvals',10000);
        fct_airy = @(param,x_data) param(1) ./ (1 + param(2) * sin(param(3)*(x_data - param(4) )).^2);
        x_sol = lsqcurvefit(fct_airy,[max(Pcirc_vec) 800 1 0.3],Common_detuning,Pcirc_vec,[],[],options);
        max_pox = x_sol(4);
    case 'quadratic_fit'
        poly = polyfit(Common_detuning,Pcirc_vec,2);
        max_pox = - poly(2) / (2*poly(1));
    case 'max'
        [~,ind_max] = max(Pcirc_vec);
        max_pox = Common_detuning(ind_max);
end

if display_switch
    figure(201);clf;
    hold on
    plot(Common_detuning,Pcirc_vec)
    title(['Common mode tuned, max' num2str(max_pox)])
end


if abs(max_pox) > Zoom_range
    disp('Refined_tuning(), warning: common tuning zoom range to be likely to be too small')
    disp('Stop here')
    figure(301)
    plot(Common_detuning,Pcirc_vec)
    disp('Common mode tuned')
    abs(max_pox)
    Zoom_range/2
    return
end

Pin.reso_North = Pin.reso_North .* exp(1i*max_pox);
Pin.reso_East = Pin.reso_East .* exp(1i*max_pox);

differenting_detuning = linspace(-Zoom_range,Zoom_range,Nb_pt_scan);
Pcirc_vec = zeros(1,length(Common_detuning));

for ii = 1:length(Common_detuning)
    P2 = Remove_SBs(Pin);
    %P2 = Pin;
    P2.reso_North = P2.reso_North .* exp(1i*differenting_detuning(ii));
    P2.reso_East = P2.reso_East .* exp(-1i*differenting_detuning(ii));
    
    P2 = Calculate_fields(P2,'iter',Nb_iter,'display',false);
    Pcirc_vec(ii) = Calculate_Power(P2.Field_circ);  
end



switch p.Results.Find_max
    case 'airy_fit'
        options = optimset('Display','off','MaxFunEvals',10000);
        fct_airy = @(param,x_data) param(1) ./ (1 + param(2) * sin(param(3)*(x_data - param(4) )).^2);
        x_sol = lsqcurvefit(fct_airy,[max(Pcirc_vec) 800 1 0.3],differenting_detuning,Pcirc_vec,[],[],options);
        max_pox = x_sol(4);
    case 'quadratic_fit'
        poly = polyfit(differenting_detuning,Pcirc_vec,2);
        max_pox = - poly(2) / (2*poly(1));
    case 'max'
        [~,ind_max] = max(Pcirc_vec);
        max_pox = differenting_detuning(ind_max);
end

if display_switch
    figure(202)
    plot(differenting_detuning,Pcirc_vec)
    title(['Differential mode tuned, max' num2str(max_pox)])
end

if abs(max_pox) > Zoom_range
    disp('Refined_tuning(), warning: differential tuning to be likely to be too small')
    disp('Stop here')
    figure(302)
    plot(differenting_detuning,Pcirc_vec)
    disp('Differential mode tuned')
    return
end

Pin.reso_North = Pin.reso_North .* exp(1i*max_pox);
Pin.reso_East = Pin.reso_East .* exp(-1i*max_pox);

Pout = Pin;

disp('fine tuning done')

end