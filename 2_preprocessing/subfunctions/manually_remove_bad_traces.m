function [neuron,del_ids_trace]= manually_remove_bad_traces(neuron,fr,opt,saveDir)

space= 8;
data= neuron.C_raw';
filtering= hanning(round(fr))./sum(hanning(round(fr))); % low-pass filtering for display
data= filtfilt(filtering, 1, data);

if isempty(opt.range)
    data= zscore(data,0,1); % z score data
else
    data= zscore(data(opt.range,:),0,1); % z score data
end

del_ids_location= []; ncell= size(data,2);% reset
nFr= size(data,1); t= 1/fr:1/fr:nFr/fr;

figure('color','w','position',[0 100 1600 800])
for icell= 1:ncell
    plot(t, data(:,icell) + space*(icell-1)); hold on
end
ylim([-space*0.1 space*ncell])
yticks(1:space:space*ncell)
yticklabels(num2cell(1:ncell))
set(gca,'TickLength',[0 0])
xlabel('time (s)');
axis tight; box off;
% ask user to choose neurons
prompt = '\nENTER NEURONS TO DELETE e.g. [1 99 35]\n';
del_ids_trace= input(prompt);
% apply deletion
del_ids= unique(del_ids_trace);
% update neuron
neuron.A(:,del_ids)=[];
neuron.C(del_ids,:)=[];
neuron.C_raw(del_ids,:)=[];
neuron.S(del_ids,:)=[];
neuron.ids(del_ids)=[];
neuron.Coor(del_ids)=[];
fprintf(['\n' num2str(length(del_ids)) ' deleted neurons, ' num2str(length(neuron.ids)) ' remaining\n'])
% save
if opt.save
    savefig(saveDir,'curated neuron traces') % save figure
end
close(gcf)
