function makevoltagedata()

filename = '1dspine.swc';
[A,~,~,~,~,~]=readSWC(filename);
system('mkdir voltageData')
vCol = ones(length(A(:,1)),1)*-65;
writeOut = [A(:,3:5),vCol];
for i=0:30000
    i
    writematrix(writeOut,sprintf('voltageData/vm_%0.5f.dat',i/100000),'Delimiter','space','FileType','text');
end
end