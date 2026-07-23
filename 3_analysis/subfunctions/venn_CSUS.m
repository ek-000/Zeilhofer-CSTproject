function stim= venn_CSUS(stim,par)
% plots Venn diagram intersection between all cells, CS and US responsive
% cells for session 2 (conditoning) and 3 (condvar). CS-responsive are
% defined as >0.2/3 zscore over tone period 4/10 trials and 2/4 first
% trials for US (because US intensties beyond 4th trial are not
% comparable).

par.session=    'conditioning'; % just for info, no use
par.name= [stim.groupName ' Venn responsive cells cond vs condvar'];

%% collect data
% conditioning: get number and intersection of CS and US-responsive cells
isession=2;
cond.ncell= stim.session.ncell(isession); % n all cells
cond.CS= stim.traces.CS.respCellIds{isession}; % CS resp cell ids
cond.US= stim.traces.US.respCellIds{isession}; % US resp cells
cond.CS_US= intersect(cond.CS, cond.US); % CS and US resp cells
% append to new struct
cond.overlapPC.CS_of_all=       length(cond.CS)/cond.ncell*100;
cond.overlapPC.US_of_all=       length(cond.US)/cond.ncell*100;
cond.overlapPC.CS_US_of_all=    length(cond.CS_US)/cond.ncell*100;
cond.overlapPC.CS_US_of_CS=     length(cond.CS_US)/length(cond.CS)*100;
cond.overlapPC.CS_US_of_US=     length(cond.CS_US)/length(cond.US)*100;

% condvar: get number and intersection of CS and US-responsive cells
isession=3;
condvar.ncell= stim.session.ncell(isession); % n all cells
condvar.CS= stim.traces.CS.respCellIds{isession}; % CS resp cells
condvar.US= stim.traces.US.respCellIds{isession}; % US resp cells
condvar.CS_US= intersect(condvar.CS, condvar.US); % CS and US resp cells
% append to new struct
condvar.overlapPC.CS_of_all=       length(condvar.CS)/condvar.ncell*100;
condvar.overlapPC.US_of_all=       length(condvar.US)/condvar.ncell*100;
condvar.overlapPC.CS_US_of_all=    length(condvar.CS_US)/condvar.ncell*100;
condvar.overlapPC.CS_US_of_CS=     length(condvar.CS_US)/length(condvar.CS)*100;
condvar.overlapPC.CS_US_of_US=     length(condvar.CS_US)/length(condvar.US)*100;

condvar.PcChangeToCond= struct2array(condvar.overlapPC) ./ struct2array(cond.overlapPC)*100 -100;


%% plot Venn diagrams
% conditioning
figure('position',[100 100 1080 950]);
subplot(2,2,1)
venn([cond.ncell length(cond.CS) length(cond.US) ], [ length(cond.CS)  length(cond.US)    length(cond.CS_US)  length(cond.CS_US)]); % venn([c1 c2 c3], [i12 i13 i23 i123])
ax(1)= gca;
title('Conditioning session'), SD_figure_appearance, box off, axis off % appearance

% condvar
subplot(2,2,2)
venn([condvar.ncell length(condvar.CS) length(condvar.US)], [length(condvar.CS) length(condvar.US) length(condvar.CS_US) length(condvar.CS_US)]); % venn([c1 c2 c3], [i12 i13 i23 i123])
ax(2)= gca;
title('Condvar session'), SD_figure_appearance, box off, axis off % appearance
linkaxes(ax)

% add text
% conditioning
subplot(2,2,3)
box off, axis off
T{1}= ['Gray: all cells (n= ' num2str(cond.ncell) ')'];
T{2}= ['Red: ' num2str(round(cond.overlapPC.US_of_all,1)) '%  US-responsive cells (n= ' num2str(length(cond.US)) ')'];
T{3}= ['Blue: ' num2str(round(cond.overlapPC.CS_of_all,1)) '%  CS-responsive cells (n= ' num2str(length(cond.CS)) ')'];
T{4}= '';
T{5}= [num2str(round(cond.overlapPC.CS_US_of_all,1)) '%  CS and US-responsive cells (n= ' num2str(length(cond.CS_US)) ')'];
T{6}= '';
T{7}= [num2str(round(cond.overlapPC.CS_US_of_CS,1)) '%  CS and US-responsive cells among CS-responsive cells (n= ' ...
    num2str(length(cond.CS_US)) ' of ' num2str(length(cond.CS)) ')'];
T{8}= [num2str(round(cond.overlapPC.CS_US_of_US,1)) '%  CS and US-responsive cells among US-responsive cells (n= ' ...
    num2str(length(cond.CS_US)) ' of ' num2str(length(cond.US)) ')'];
text(-0.2,1, T);

% condvar
subplot(2,2,4)
box off,  axis off
T{1}= ['Gray: all cells (n= ' num2str(condvar.ncell) ')'];
T{2}= ['Red: ' num2str(round(condvar.overlapPC.US_of_all,1)) '% (+' num2str(round(condvar.PcChangeToCond(2),1))...
    '%)  US-responsive cells (n= ' num2str(length(condvar.US)) ')'];
T{3}= ['Blue: ' num2str(round(condvar.overlapPC.CS_of_all,1)) '% (+' num2str(round(condvar.PcChangeToCond(1),1))...
    '%)  CS-responsive cells (n= ' num2str(length(condvar.CS)) ')'];
T{4}= '';
T{5}= [num2str(round(condvar.overlapPC.CS_US_of_all,1)) '% (+' num2str(round(condvar.PcChangeToCond(3),1))...
    '%)  CS and US-responsive cells (n= ' num2str(length(condvar.CS_US)) ')'];
T{6}= '';
T{7}= [num2str(round(condvar.overlapPC.CS_US_of_CS,1))  '% (+' num2str(round(condvar.PcChangeToCond(4),1))...
    '%)  CS and US-responsive cells among CS-responsive cells (n= ' num2str(length(condvar.CS_US)) ' of ' num2str(length(condvar.CS)) ')'];
T{8}= [num2str(round(condvar.overlapPC.CS_US_of_US,1))  '% (+' num2str(round(condvar.PcChangeToCond(5),1))...
    '%)  CS and US-responsive cells among US-responsive cells (n= ' num2str(length(condvar.CS_US)) ' of ' num2str(length(condvar.US)) ')'];
text(-0.2,1, T);

subtitle(par.name)

% append to stim
stim.session.cond= cond;
stim.session.condvar= condvar;

if par.save
    SD_save(par.name,par.saveDir);
end
