function [nspike,spikeFreq]= spontaneous_firing_frequency(data,stim,par)

sessions= par.session;

% collect number of spontaneous spike per mouse
clear nspike spikeFreq
for isession= sessions
    nspikeiCat=[];
    for imouse= stim.mice % average per mouse the sum of spikes over spontaneous time window
        if par.per_mouse
            nspikeiCat(imouse)= mean(sum(data(imouse,isession).spikes(:,1:par.spontaneous.time*stim.fr),2));
        else
            nspikei= sum(data(imouse,isession).spikes(:,1:par.spontaneous.time*stim.fr),2);
            nspikeiCat= [nspikeiCat ; nspikei];
        end
    end
    nspike{:,isession-sessions(1)+1}= nspikeiCat;
end

% get spike frequency
for isession= 1:length(sessions)
    spikeFreq{isession}= nspike{isession} /par.spontaneous.time; % Hz
end

% normalize to session 1
if par.norm && par.per_mouse % because not the same cells
    for isession= length(sessions):-1:1
        spikeFreq{isession}= spikeFreq{isession} ./ spikeFreq{1};
    end
end

% plot
figure; clear name
x1= spikeFreq{1}; % pre-CCI
x2= spikeFreq{2}; % post-CCI
if par.norm && par.per_mouse
    yl= boxplots({x2},'mean','color',{'k','r'},'scatter');

else
    yl= boxplots({x1,x2},'mean','color',{'k','r'},'line','scatter','marker_alpha',par.marker_alpha);
end
ylim([0 yl(2)])
ylabel('Spike frequency (Hz)')
name{1}= [stim.groupName ' Spontaneous spike frequency'];
% statistics
if par.norm && par.per_mouse
    full_str= SD_ttest1(x2);
    line([0 2],[1 1],'color',0.5*[1 1 1],'LineStyle','--')
    xticklabels({'post-CCI'})
else
    full_str= SD_ttest(x1,x2);
    xticklabels({'Baseline','post-CCI'})
end
name{2}= full_str{1}; name{3}= full_str{2};

title(name,'fontsize',12)

% par.save
if par.save
    SD_save(name, par.saveDir)
end