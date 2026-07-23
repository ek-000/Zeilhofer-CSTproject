function plot_traces_cnmfe(neuron,nrange,frrange,fr,opt,saveDir)

% parameters
space_traces= 2; % how much space between traces
figsize= [0 0 1800 1600];
data= {neuron.C_raw', neuron.C'};

cols= {'k','r','k'}; % data traces colors
pos= {[1 2] 3 4}; % subplot position for each data: raw, fitted, overlay
titles= {'denoised data','fitted data','overlay'};

% restrict plot to range of neurons or frames
for idata= 1:length(data)
    % neuron range
    if ~isempty(nrange)
        data{idata}= data{idata}(:,nrange);
    end
    % frame range
    if ~isempty(frrange)
        data{idata}= data{idata}(frrange,:);
    end
end

figure('color','w','position',figsize);

for idata= 1:length(data)
    ncell=size(data{idata},2);
    nFr= size(data{idata},1); % number of frames total
    t= 1/fr:1/fr:nFr/fr;
    space= mean(prctile(data{idata},98))*space_traces;
    
    % raw or fitted traces
    subplot(2,length(data),pos{idata})
    for icell=1:ncell
        plot(t, data{idata}(:,icell) + space*(icell-1),cols{idata}); hold on
        text(-t(end)/15, mean(data{idata}(:,icell)) + space*(icell-1), num2str(icell), 'fontsize', 8);
    end
    ylim([-space*0.1 space*ncell])
    yticks([])
    xlabel('time (s)');
    title(titles{idata})
    axis tight
end

% merge raw and fitted traces
subplot(2,length(data),pos{3})
for idata=1:2
    space= mean(cell2mat(cellfun(@max,data(1:2),'UniformOutput',false)))*1;
    for icell=1:ncell
        plot(t, data{idata}(:,icell) + space*(icell-1), cols{idata}); hold on
        text(-t(end)/15, mean(data{idata}(:,icell)) + space*(icell-1), num2str(icell), 'fontsize', 8);
    end
end
ylim([-space*0.1 space*ncell])
yticks([])
xlabel('time (s)');
title(titles{idata+1})
axis tight

if opt.cnmfe.savetracesplot
    savefig(saveDir,'CNMFE_traces') % save
end
