clear;clc
close all
%%
nsteps = 10000;
%%
data = dlmread('full/time-particles.dat');
n = data(:,1);
t = data(:,2);

dt = t - t(1);

loglog(n, 1e3 * dt / nsteps,'-o','DisplayName','Full')
hold on 

%%
data = dlmread('no-cpl/time-particles.dat');
n = data(:,1);
t = data(:,2);

dt = t - t(1);

loglog(n,1e3 * dt / nsteps,'-s','DisplayName','No coupling')
hold on 

%%
data = dlmread('no-pp/time-particles.dat');
n = data(:,1);
t = data(:,2);

dt = t - t(1);

loglog(n,1e3 * dt / nsteps,'-^','DisplayName','No particle-particle')
hold on 

%%
legend Location northwest

loglog(n,1e-4*n,'--','DisplayName','\propto N_p')

xlabel('Number of particles')
ylabel(' iteration time - time(N=0)  / ms')
title('L = 512')

exportgraphics(gcf, 'time-number-particles.png')
