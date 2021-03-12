function vmData=makePMvoltagemovie(movieName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% makematlabmov this makes a movie of the voltage data from the neuron sim
%  Input:
%  dataFolder: this is the folder that contains the vm voltage files
%  geometryfile: this is the folder/file.swc of the geometry
%  movieName: what do you want to call the movie?
%
%   Written by James Rosado 09/20/2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

t0 = 0;
tf = 0.1;
dt = 1e-5;
times = [t0:dt:tf];
length(times)
filename = sprintf('vm_%0.5f.dat',times(1));
vmData = readmatrix(filename);
coords = vmData(:,1:3);
size(coords)
markerSize = 12;

% make a new figure windows
fig=figure('units','normalized','outerposition',[0 0 0.325 1.0]);
% this is for recording the movie
v = VideoWriter(sprintf('%s.mp4',movieName),'MPEG-4');
open(v)

% this part is for setting the text values on the color bar, no need to
% modify this except maybe the cmax and cmin if your action potentials have
% lower/higher peak values
yticklabel={};
cmax = 45; cmin = -78;
% vals = [cmin:5:cmax];
% for i=1:length(vals)
%     yticklabel{i}=num2str(vals(i));
% end

% if you change the 100 this will affect the length of the movie
for i=0:10:length(times)
        % read the voltage data from the .dat files
        filename = sprintf('vm_%0.5f.dat',i/100000);
        filename
        vmData = readmatrix(filename);
        vmData = vmData(:,4);
        
        % make a scatter plot
        scatter3(coords(:,1),coords(:,2),coords(:,3),markerSize,'filled','CData',vmData);
        
        %set labels
        xlabel(sprintf('{\\mu}m'))
        ylabel(sprintf('{\\mu}m'))
        set(gca,'Color', [0.5 0.5 0.5])
        caxis([cmin cmax])
        title(sprintf('MatLab, t = %0.2f [ms]',times(i+1)*1e3))
        colormap('jet')
        colorbar
        
        % set tick labels on colorbar
        c = colorbar;  
        c.Label.String="[mV]";
        %c.TickLabels = yticklabel; 
        view(2)
        
        % save the frame to video file
        thisframe=getframe(fig);
        writeVideo(v, thisframe);

        drawnow
        fprintf('frame = %i\n',i)
end
% don't forget to close the video file, if not it will be corrupted!
close(v)