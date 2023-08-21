%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to calculate the Factor Of Merit as a function of the OMC ROC, assuming a design with two OMCs, identical waists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%
% INPUT PARAMETERS
%%%%%%%%%%%%%%%%%%%

idxn = 1.44963;
length = 0.06200; %minimum length corresponding to an angle of 6 degrees
lopt = 2 * idxn * length;
%rho = 1.499;
%Fomc = 210;
Fomc = 145;
m = 0.1;

% Almost frozen parameters
fmod1 = 6.270777e6; % MSRC design
fmod2 = 56.436993e6; % MSRC design
fmod4 = 131.686317e6;
lambda = 1064.0e-9;

Pcar = 0.080;
% Powers in HOMs
PmodeCar = [];
PmodeCar(1) = 0.200;
PmodeCar(2) = 0.060;
for N=3:5
        PmodeCar(N) = 0.025;
end
PmodeCar(6) = 0.060;
for N=7:8
        PmodeCar(N) = 0.250;
end
PmodeCar(9) = 0.095;
PmodeCar(10) = 0.060;
for N=11:14
        PmodeCar(N) = 0.025;
end

Psb1 = 0.0025;
% Powers in HOMs
PmodeSb1 = [];
PmodeSb1(1) = 0.0063;
for N=2:14
        PmodeSb1(N) = 0.001;
end

Psb2 = 0.160;
% Powers in HOMs
PmodeSb2 = [];
%PmodeSb2(1) = 0.400;
PmodeSb2(1) = 0.090;
for N=2:14
        PmodeSb2(N) = 0.062;
end

Psb4 = 0.540*0.01;
% Powers in HOMs
PmodeSb4 = [];
PmodeSb4(1) = 1.350*0.01;
for N=2:14
        PmodeSb4(N) = 0.200*0.01;
end


% Fixed parameters
c = 2.99792458e8;
hp = 6.626068e-34;
nu = c/lambda;

%waist = sqrt( lambda/(idxn*pi)*sqrt(length*(rho - length)) );
%fprintf('OMC waist=%g\n',waist);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Start loop on the ROC value (from rho=0.5 to 1.5)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

RhoVect = [];
FoMVectCar = [];
FoMVectSB1 = [];
FoMVectSB2 = [];

for M=1:10001

	rho = 0.9999 + M*0.0001;
	%rho = 0.4999 + M*0.0001;
	%rho = 0.64999 + M*0.00001;
	RhoVect(M) = rho;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Transmission of carrier TEM(mn) up to m+n=18
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	FoM = 0; % Factor of merit

	%for N = 1:10
	for N = 1:14
	  Tomc = 1./(1 + (2*Fomc/pi)^2 * (sin(N*acos(sqrt(1 - 2*length/rho))))^2 );
	  Pomc = Tomc^2 * PmodeCar(N);
	  %fprintf('Power in TEM for m+n=%g, Pomc = %g\n',N,Pomc);
	  FoM = FoM + Pomc;
	end
	%fprintf('Factor of merit for carrier HOMs and ROC=%g, FoM = %g\n',rho,FoM);
	FoMVectCar(M) = FoM;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Expected power on SB1 TEM(mn) up to m+n=18
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	FoM = 0; % Factor of merit

	Tomc = 1./(1 + (2*Fomc/pi)^2 * (sin(-2*pi*fmod1*lopt/c))^2 ) * 1./(1 + (2*Fomc/pi)^2 * (sin(-2*pi*fmod1*lopt/c))^2 );
        Pomc = Tomc * Psb1;
        FoM = FoM + Pomc;

	%for N = 1:10
	for N = 1:14
	  Tomc = 1./(1 + (2*Fomc/pi)^2 * (sin(-2*pi*fmod1*lopt/c - N*acos(sqrt(1 - 2*length/rho))))^2 );
	  Pomc = Tomc^2 * PmodeSb1(N)/2.;
	  FoM = FoM + Pomc;
	end

	%for N = 1:10
	for N = 1:14
	  Tomc = 1./(1 + (2*Fomc/pi)^2 * (sin(2*pi*fmod1*lopt/c - N*acos(sqrt(1 - 2*length/rho))))^2 );
	  Pomc = Tomc^2 * PmodeSb1(N)/2.;
	  FoM = FoM + Pomc;
	end

	%fprintf('Factor of merit for SB1 HOMs and ROC=%g, FoM = %g\n',rho,FoM);
	FoMVectSB1(M) = FoM;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Expected power on SB2 TEM(mn) up to m+n=18
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	FoM = 0; % Factor of merit

	Tomc = 1./(1 + (2*Fomc/pi)^2 * (sin(-2*pi*fmod2*lopt/c))^2 ) * 1./(1 + (2*Fomc/pi)^2 * (sin(-2*pi*fmod2*lopt/c))^2 );
        Pomc = Tomc * Psb2;
        FoM = FoM + Pomc;

	%for N = 1:10
	for N = 1:14
	  Tomc = 1./(1 + (2*Fomc/pi)^2 * (sin(-2*pi*fmod2*lopt/c - N*acos(sqrt(1 - 2*length/rho))))^2 );
	  Pomc = Tomc^2 * PmodeSb2(N)/2.;
	  FoM = FoM + Pomc;
	end

	%for N = 1:10
	for N = 1:14
	  Tomc = 1./(1 + (2*Fomc/pi)^2 * (sin(2*pi*fmod2*lopt/c - N*acos(sqrt(1 - 2*length/rho))))^2 );
	  Pomc = Tomc^2 * PmodeSb2(N)/2.;
	  FoM = FoM + Pomc;
	end

	%fprintf('Factor of merit for SB2 HOMs and ROC=%g, FoM = %g\n',rho,FoM);
	FoMVectSB2(M) = FoM;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Expected power on SB4 TEM(mn) up to m+n=18
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        FoM = 0; % Factor of merit

	Tomc = 1./(1 + (2*Fomc/pi)^2 * (sin(-2*pi*fmod4*lopt/c))^2 ) * 1./(1 + (2*Fomc/pi)^2 * (sin(-2*pi*fmod4*lopt/c))^2 );
        Pomc = Tomc * Psb4;
        FoM = FoM + Pomc;

        %for N = 1:10
        for N = 1:14
          Tomc = 1./(1 + (2*Fomc/pi)^2 * (sin(-2*pi*fmod4*lopt/c - N*acos(sqrt(1 - 2*length/rho))))^2 );
          Pomc = Tomc^2 * PmodeSb4(N)/2.;
          FoM = FoM + Pomc;
        end

        %for N = 1:10
        for N = 1:14
          Tomc = 1./(1 + (2*Fomc/pi)^2 * (sin(2*pi*fmod4*lopt/c - N*acos(sqrt(1 - 2*length/rho))))^2 );
          Pomc = Tomc^2 * PmodeSb4(N)/2.;
          FoM = FoM + Pomc;
        end

        %fprintf('Factor of merit for SB4 HOMs and ROC=%g, FoM = %g\n',rho,FoM);
        FoMVectSB4(M) = FoM;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make plots of OMC FoM versus ROC value
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fig1 = figure;

FoMVectSum = FoMVectCar + FoMVectSB1 + FoMVectSB2;

FoMVectCombined = [FoMVectCar;FoMVectSB1;FoMVectSB2];

% turn on the log scale
tmp1 = semilogy(FoMVectCar');
hold on;
set(tmp1,'visible','off');

% set limits
%maxy=10^ceil(log10(max(max(FoMVectCombined*1000))));
%miny=10^floor(log10(min(min(FoMVectCombined*1000))));
maxy = 10^2;
miny = 10^(-3);

%for M = 1:101
%  myplot1 = plot([0.49 + M*0.01 - 0.002,0.49 + M*0.01 - 0.002],[miny,FoMVectCar(M)*1000],'b','linewidth',1);
%  myplot2 = plot([0.49 + M*0.01,0.49 + M*0.01],[miny,FoMVectSB1(M)*1000],'r','linewidth',1);
%  myplot3 = plot([0.49 + M*0.01 + 0.002,0.49 + M*0.01 + 0.002],[miny,FoMVectSB2(M)*1000],'g','linewidth',1);
%end

myplot1 = plot(RhoVect,FoMVectCar*1000,'b','linewidth',1);
myplot2 = plot(RhoVect,FoMVectSB1*1000,'r','linewidth',1);
myplot3 = plot(RhoVect,FoMVectSB2*1000,'g','linewidth',1);
myplot4 = plot(RhoVect,FoMVectSum*1000,'k','linewidth',1);
myplot5 = plot(RhoVect,FoMVectSB4*1000,'m','linewidth',1);

% apply limits and labels
%axis([0.5 2.0 miny maxy]);
%set(gca,'xtick', [0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]);
%set(gca,'xticklabel', {'0.5' '0.55' '0.6' '0.65' '0.7' '0.75' '0.8' '0.85' '0.9' '0.95' '1.0' '1.05' '1.1' '1.15' '1.2' '1.25' '1.3' '1.35' '1.4' '1.45' '1.5' '1.55' '1.6' '1.65' '1.7' '1.75' '1.8' '1.85' '1.9' '1.95' '2.0'});

%axis([0.7 0.9 miny maxy]);
%set(gca,'xtick', [0.7 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90]);
%set(gca,'xticklabel', {'0.7' '0.71' '0.72' '0.73' '0.74' '0.75' '0.76' '0.77' '0.78' '0.79' '0.80' '0.81' '0.82' '0.83' '0.84' '0.85' '0.86' '0.87' '0.88' '0.89' '0.90'});

hold off;

% add a legend
%leg = legend([myplot1,myplot2,myplot3,myplot4],{'Car HOM','SB1 HOM 6.27 MHz','SB2 HOM 56.44 MHz','Sum'});
leg = legend([myplot1,myplot2,myplot3,myplot4,myplot5],{'Car HOM','SB1 6.27 MHz','SB2 56.44 MHz','Sum', 'SB4 131.69 MHz'});

grid on;
xlabel('RoC (m)')
ylabel('Transmitted power (mW)')
title('Factor of Merit versus OMC RoC','FontWeight','bold');

print -dpng FoMvsROC_SR125W_2OMCs_Len6p200_F145_RoC1700;
