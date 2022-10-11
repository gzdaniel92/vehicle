clc;
clear all;
%% Introduction
% gearshift calculation for WLTC
% call-script for function "WLTC_gearshift.m"

%% Validity
% passenger cars with > 34 kW / t
% driving complete WLTC (low, medium, high, extra high)

%% Konfiguration
config.mat = 0; % Abspeichern der Ergebnisse in mat-file (sont nur Workspace)
config.display = 0; % Ausgabe Grafiken auf Bildschirm
config.engspeed = 0; % Berechnung mittlere Drehzahlen
config.corrections = 0; % Ausgabe der Corrections
config.coasting = 0; % EXPERIMENTAL Segeln entsprechend Ausrollkurve

%% data collection
% cycle data

load drivecycles_v12.mat;
cycle.kmh = drivecycle.UDDS.kmh;
cycle.name = drivecycle.UDDS.name;
cycle.time = drivecycle.UDDS.time;
clear drivecycle;


% vehicle data (incl. transmission)
load ICE_F150_2021.mat;
load trans_F150_2021.mat;
load veh_F150_2021.mat;
% load veh_F150_2021_hybAWD.mat;
% load veh_F150_2021_hyb.mat;

vehicle.name = 'F-150_ecoboost_V6_FTP75';
vehicle.nameshort = vehicle.name;

% definition of resistance is NOT optional anymore
% vehicle.f0 = vehicle.mass*vehicle.fR*9.81;
% vehicle.f1 = 0.0;
% vehicle.f2 = 0.5*vehicle.cw*vehicle.A*vehicle.AirDensity/(3.6^2);
vehicle.f0 = vehicle.F0;
vehicle.f1 = vehicle.F1;
vehicle.f2 = vehicle.F2;

% transmission
vehicle.tyrecf = vehicle.tyreR*2*pi; % tyre circumference in mm
% tool requires vehicle.r, can be defined directly or derived from transmission ratios
transmission.r(1:transmission.ni) = transmission.i * transmission.i_axle * 60 / vehicle.tyrecf * 1000 / 3.6; % gear ratios 1..ni in rpm / kmh

%% changes necessary to run with new WLTC_gearshift v2017 (30.06.2017)
vehicle.TM = vehicle.mass;
vehicle.ng = transmission.ni;
vehicle.i  = transmission.i;
vehicle.i_axle = transmission.i_axle;
%% drv2fe

%% Calculation
sprintf('Fahrzeug %s ausgewählt',vehicle.name)
% function call
[cycle,vehicle,engine,gear] = WLTC_gearshift(cycle,vehicle,engine,config);

% post processing (correct gear-0-gear events)

    shiftProfile_original = [cycle.time, cycle.gear];
    shiftProfile_modified = shiftProfile_original;

    for i=2:size(shiftProfile_original,1)-1
        n_before = shiftProfile_original(i-1,2);
        n_now    = shiftProfile_original(i,2);
        n_after  = shiftProfile_original(i+1,2);

        if n_now==0 && n_before~=0 && n_after~=0
            shiftProfile_modified(i,2) = round(mean(shiftProfile_original(i-1,2),shiftProfile_original(i+1,2)));
        end
    end

%

if config.mat == 1
    save(strcat('WLTC_',vehicle.nameshort,'_',datestr(now,'yy-mm-dd_HH-MM'),'_Shift.mat'),'-struct','cycle');
end

%% Calculation average engine speeds
if config.engspeed == 1
    engspeed.mll = sum(cycle.engspeed) / length(cycle.engspeed);
    temp = cycle.engspeed;
    temp = temp(temp > engine.n_idle);
    engspeed.oll = sum(temp) / length(temp);
    clear temp;
    sprintf('minimale Fahrdrehzahl:  %6.1f 1/min\nmaximale Drehzahl:      %6.1f 1/min',engine.n_min_drive,max(cycle.engspeed))
    sprintf('mittlere Drehzahl mit Leerlauf:  %6.1f 1/min\nmittlere Drehzahl ohne Leerlauf: %6.1f 1/min',engspeed.mll,engspeed.oll)
end

%% plot results
if config.display == 1
    subplot(2,1,1);
    plotkmh = plot(cycle.kmh);
    title([vehicle.name,' / ',cycle.name]);
    xlabel('time [s]');
    ylabel('speed [km/h]');
    ylimplotkmh = 20*ceil((max(cycle.kmh)+1)/20);
    ylim([-5 ylimplotkmh]);
    set(gca,'YTick',0:20:ylimplotkmh);
    % xlim([1500 1600]);
    grid on;

    subplot(2,1,2);
    % plotgearmin = plot(cycle.gearmin,'LineWidth',2,'Color','r');
    % hold all;
    % plotgearmax = plot(cycle.gearmax,'LineWidth',2,'Color','r');
    % plotgear = plot(cycle.gear,'Color','k');
    plotgear = plot(cycle.gear);
    xlabel('time [s]');
    ylabel('gear [-]');
    ylim([min(cycle.gearmax)-1 max(cycle.gearmax)+1]);
    % xlim([1500 1600]);
    set(gca,'YTick',min(cycle.gearmax):1:max(cycle.gearmax));
    % legend([plotgear],'gear','Location','NorthWest');
    grid on;

    figure;
    title(vehicle.name);
    hold all;
    subplot(3,1,1);
    plotp = plot(cycle.pres,'k');
    title([vehicle.name,' / ',cycle.name]);
    xlabel('time [s]');
    ylabel('required power [kW]');
    % xlim([1500 1600]);
    grid on;

    subplot(3,1,2);
    plotengspeed = plot(cycle.engspeed,'k');
    xlabel('time [s]');
    ylabel('engine speed [rpm]');
    % xlim([1500 1600]);
    ylim([0 4500]);
    if config.engspeed == 1
        hold on;
        plot([0 1800],[engine.n_min_drive engine.n_min_drive],'r');
        plot([0 1800],[engspeed.oll engspeed.oll],'b');
    end
    grid on;

    subplot(3,1,3);
    plotengtorque = plot(cycle.engtorque,'k');
    xlabel('time [s]');
    ylabel('engine torque [rpm]');
    % xlim([1500 1600]);
    grid on;
end



