%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This subroutine is used to design gusset plates using the method presented by Astaneh-Asl et al. %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Written by Ehsan Bakhshivand %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
clear;
close all;
%%

% Initial Informations Include: Material Peroperties of Brace, Column, Beam and Gusset Plate and etc
%--------------------------------------------------------------------------
% Level: 1 Upper
% Beam type: N/A
% Brace type: HSS 5X5X5/16
% Column type: W8X58
Es=29000;      %ksi; Elastic section modulus of steel 
Brise=15;      %ft;  height of story
Brun=10;       %ft;  length of each bay
Fexx=70;       %ksi; filler metal classification strength
a=1;           %in;  Distance from the face of the bracing to the edge of the gusset plate 
Ry=1.4;        %Ratio of the expected yield stress to the specified minimum yield stress of brace members
Fybr=46;       %ksi; The minimum yield stress of brace material
Fubr=58;       %ksi; The minimum tensile stress of brace material
b=5.0;         %in;  The width of bracing member on the gusset plate
twbr=5/16;     %in;  The nominal brace wall thickness
twdesbr=0.291; %in; The real brace wall thickness
Agbr=5.26;     %in^2; Cross sectional area of brace
rbr=1.90;      %in; The radius of gyration of brace
Dwdbr=3/8;     %in; The weld leg size of brace weld to gusset plate
dc=8.75;       %in; The depth of column
db=0.0;        %in; The depth of beam (for gusset plates at the base of column the depth of beam equals to 0.0)
Fyg=50;        %ksi; The minimum yield stress of gusset plate
Fug=65;        %ksi; The minimum tensile strees of gusset plate
tre=0.2;       %The thickness of reinforcement plate
alpha=pi/6;    %Rad; Angle of the gusset edge to the brace axis

% Computing Gusset Width at Hinge Zone, Ww, and Thickness of Gusset Plate, t
%--------------------------------------------------------------------------
% Computing the required weld length of brace to gusset plate connection
teta=atan(Brise/Brun); %rad; The angle between the centerline of brace & centerline of beam
teta=(teta*180)/pi; %Degree;
if teta>=30 & teta<60;
    disp('Teta is Ok')
else
    disp('Teta is Not Ok')
end
Put=Ry*Fybr*Agbr;   %kips; Maximum required tensile strength for connection design
Lw=max(ceil(Put/(2*0.6*0.75*Fexx*Dwdbr*sqrt(2))),b); %in; The required weld length
Lb=Lw+1;    %in; Length of brace member lap on the gusset plate

% Computing Whitmore length and gusset plate thickness
Ww=b+2*Lw*tan(pi/6); %in, Whitmore length
tg=Put/(0.9*Ww*Fyg); %in, The thickness of gusset plate
if tg<=0.25;
    tg=0.25;
elseif tg>0.25 & tg<=0.5;
    tg=0.5;
elseif tg>0.5 & tg<=0.75;
    tg=0.75;
elseif tg>0.75 & tg<=1;
    tg=1.0;
elseif tg>1 & tg<=1.25;
    tg=1.25;
elseif tg>1.25 & tg<=1.5;
    tg=1.5;
elseif tg>1.5 & tg<=1.75;
    tg=1.75;
elseif tg>1.75 & tg<=2.0;
    tg=2.0;
end

% Brace Limit States:
%--------------------------------------------------------------------------
% Shear Ruprure of Brace:
Rt=1.3;
Anvbr=4*Lw*twdesbr; %in^2
Rnvrbr=0.75*Rt*0.6*Fubr*Anvbr; %kips
if Put<=Rnvrbr;
    disp('Brace Shear Rupture is Ok')
else
    disp('Brace Shear Rupture is Not Ok')
end

% Tensile Rupture of Brace:
Anbr=Agbr+(2*tre*(b-2*twbr))-(2*(tg+1/16)*(twdesbr)); %in^2
xbar=(b^2+2*b*b)/(4*(b+b)); %in
U=1-xbar/Lw;
Aebr=U*Anbr; %in^2
if Aebr>=Agbr;
    disp('Brace Tensile Rupture is Ok')
else
    disp('Brace Tensile Rupture is Not Ok')
end

% Brace-Gusset Weld Limit States
%--------------------------------------------------------------------------
% Brace-Gusset Weld Size:
tthin=min(tg,twbr); %in
if tthin<=1/4;
    Dwmin=1/8; %in
elseif tthin>1/4; tthin<=1/2;
    Dwmin=3/16; %in
elseif tthin>1/2; tthin<=3/4;
    Dwmin=1/4; %in
else
    Dwmin=5/16; %in
end
if Dwdbr>=Dwmin
    disp('Brace-Gusset Weld Size is Ok')
else
    disp('Brace-Gusset Weld Size is Not Ok')
end

% Brace-Gusset Weld Strength:
Rnwbr=0.75*0.6*Fexx*Dwdbr*Lw*4*0.5*sqrt(2); %kips
if Rnwbr>=Put;
    disp('Brace-Gusset Weld Strength is Ok')
else
    disp('Brace-Gusset Weld Strength is Not Ok')
end

% Gusset Plate Limit States
%--------------------------------------------------------------------------
%Block Shear Rupture of Gusset at Brace-Gusset Welds:
Ubs=1;
Agvg=2*Lw*tg; %in^2
Antg=b*tg; %in^2
Rnbsg=0.75*(Ubs*Fug*Antg+min(0.6*Fug*Agvg, 0.6*Fyg*Agvg)); %kips
if Put<=Rnbsg;
    disp('Gusset Block Shear Rupture is Ok')
else
    disp('Gusset Block Shear Rupture is Not Ok')
end

% Computing W, Wprl
%--------------------------------------------------------------------------
Lgph=2*tg+0.5;  %in, Length of gusset-plate hinge zone
W=2*(a+b/2+Lb*tan(alpha));  %in; Width of the gusset plate at the end of the brace 
Wprl=2*(a+b/2+(Lb+Lgph)*tan(alpha));    %in; Width of the gusset-plate restraint line 

% Determining whether the first re-entrant corner is at the beam or the column flange
%------------------------------------------------------------------------------------
C=dc*0.5;
D=db*0.5;
C1=C/(sind(teta)*cosd(teta))+(0.5*Wprl/cosd(teta)); % Vertical dimension measured from the intersection of the beam and column centerlines 
                                                    % to the intersection of the line of restraint at the column flange and the column centerline
C2=D/((sind(teta)^2))+(0.5*Wprl)/(sind(teta)*tand(teta)); % Vertical dimension measured from the intersection of the beam and column centerlines...
                                                          % to the intersection of the line of restraint at the beam flange and the column centerline
U=C1-C2;
if U>0;
    disp('the point of intersection of the restraint line is on the column')
elseif U<0;
    disp('then the point of intersection of the restraint line is on the beam')
else
    disp('the point of intersection of the restraint line is on the beam as well as on the column')
end

% Establishing gusset dimensions A, B, and L1 to L6
%--------------------------------------------------------------------------
alpha=(180*alpha)/pi;
if U>=0;
    L6=((Lgph+Lb)/cosd(alpha))*sind(teta-alpha);
    L5=((Lgph+Lb)/cosd(alpha))*cosd(teta-alpha);
    L4=(2*a+b)*sind(teta);
    A=C*tand(teta)+(0.5*Wprl)/cosd(teta)-D;
    L1=(2*a+b)*cosd(teta);
    L2=A+L6-L1;
    L3=L2*tand(90-teta-alpha);
    B=L4+L5-L3;
else 
    L1=(2*a+b)*cosd(teta);
    L2=((Lgph+Lb)/cosd(alpha))*sind(teta+alpha);
    L3=L2/(tand(teta+alpha));
    B=D/tand(teta)+(0.5*Wprl)/sind(teta)-C;
    L4=(2*a+b)*sind(teta);
    L5=B+L3-L4;
    L6=L5*tand(tata-alpha);
    A=L1+L2-L6;
end

% Computing joint offset of brace and buckling length of gusset plate
%--------------------------------------------------------------------------
if C==0;
    gama=90;
else
    gama=atand(D/C);
end
x=(a+b/2)*cosd(teta);
joff=(x+L2+D)/sind(teta)-Lb;    %in, joint offset of brace
if gama>=teta;
    Lcg=joff-D/sind(teta);
else
    Lcg=joff-C/cosd(teta);
end

% Control of Gusset in Compression
%--------------------------------------------------------------------------
% Computing Compresion Demand
LandaBr=1.0*(sqrt(Brun^2+Brise^2))*12/rbr;
Febr=(pi^2*Es)/(LandaBr^2); %ksi
if (Ry*Fybr)/Febr<=2.25;
    PncBr=1.14*Ry*Fybr*(0.658^((Ry*Fybr)/Febr))*Agbr;  %kips
else
    PncBr=1.14*0.877*Febr*Agbr; %kips
end
Kg=0.6;
rg=tg/sqrt(12); %in
LandaG=Kg*Lcg/rg;
Feg=(pi^2*Es)/(LandaG^2); %ksi
Awh=Ww*tg;
if LandaG<=25;
    Pncg=0.9*Fyg*Awh; %kips
elseif (LandaG>25 & LandaG<=4.71*sqrt(Es/Fyg));
    Pncg=0.9*Fyg*(0.658^(Fyg/Feg))*Awh; %kip
else
    Pncg=0.9*0.877*Feg*Awh; %kips
end
if Pncg>=PncBr;
    disp('Gusset Buckling is Ok')
else
    tg=tg+0.25;
    rg=tg/sqrt(12); %in
    LandaG=Kg*Lcg/rg;
    Feg=(pi^2*Es)/(LandaG^2); %ksi
    Awh=Ww*tg;
    if LandaG<=25;
        Pncg=0.9*Fyg*Awh; %kips
    elseif (LandaG>25 & LandaG<=4.71*sqrt(Es/Fyg));
        Pncg=0.9*Fyg*(0.658^(Fyg/Feg))*Awh; %kip
    else
        Pncg=0.9*0.877*Feg*Awh; %kips
    end
    if Pncg>=PncBr;
        disp('Gusset Buckling is Ok')
    else
        disp('Gusset Buckling is Not Ok')
    end
end


%Results
%--------------------------------------------------------------------------
disp('The Design is Completed and')
fprintf('The value of L1 is %4.2f \n',L1)
fprintf('The value of L2 is %4.2f \n',L2)
fprintf('The value of L3 is %4.2f \n',L3)
fprintf('The value of L4 is %4.2f \n',L4)
fprintf('The value of L5 is %4.2f \n',L5)
fprintf('The value of L6 is %4.2f \n',L6)
fprintf('The value of A is %4.2f \n',A)
fprintf('The value of B is %4.2f \n',B)
fprintf('The value of tg is %4.2f \n',tg)
fprintf('The value of tre is %4.2f \n',tre)
fprintf('The value of Lwbr is %4.2f \n',Lw)
fprintf('The value of Dwbr is %4.2f \n',Dwdbr)
fprintf('The value of jointoffset is %4.2f \n',joff)
fprintf('The value of Ww is %4.2f \n',Ww)
fprintf('The value of Lgph is %4.2f \n',Lgph)
disp('Required data to analysis design process')
fprintf('The value of Agbr is %4.2f \n',Agbr)
fprintf('The value of Aebr is %4.2f \n',Aebr)
fprintf('The value of Put is %4.2f \n',Put)
fprintf('The value of Rnbsg is %4.2f \n',Rnbsg)
fprintf('The value of Rnvrbr is %4.2f \n',Rnvrbr)
fprintf('The value of Rnwbr is %4.2f \n',Rnwbr)
fprintf('The value of PncBr is %4.2f \n',PncBr)
fprintf('The value of Pncg is %4.2f \n',Pncg)
