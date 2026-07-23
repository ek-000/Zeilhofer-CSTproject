function data= bin_spikes(data,stim,par)

for imouse= stim.mice
    for isession= stim.sessions
        spikeSum= sum(data(imouse,isession).spikes,1);
        bins= 1:length(spikeSum);
        bins= ceil(par.binsize*bins/stim.fr);
        data(imouse,isession).binnedSpikes= accumarray(bins', spikeSum')';
    end
end