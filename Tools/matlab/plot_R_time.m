clear;clc
close all
%%
Pe = linspace( 4.0, 10.0 , 20 );
%%
for s2 = 1:length(Pe)
    folder = sprintf('SIM_0_%d',s2-1);
    file = 'stats.dat';
    data = readmatrix( fullfile(folder,file) ,'NumHeaderLines',1 );
    t = data(:,1);
    R = data(:,2);

    dt = 0.1; 
    treal = t*dt;

    teq = 1e4;

    idx = treal > (treal(end) - teq);

    Rsteady(s2) = mean( R(idx) );
    
end

semilogx(Pe,Rsteady,'-o')

dlmwrite('Rsteady-Pe.dat',[Pe', Rsteady'])
