function [stim,data]= resample_neuronal_activity(stim,data,folder)
% because a few extra frames are acquired

% info
% bas= 120; CS= 20; iti= 120; ntrial=10; bas+ntrial*(CS+iti)=1520;
% bas= 120; trial= 30; ntrial=130; bas+(ntrial*trial)=4020;

stim.duration= [1520 1523 3993]; % theoretical experiment duration (s) 4020
frame_offset= [0 31 1 0 0 0]; % for each fullcond mouse group


for imouse= 1:size(data,1)
    for isession= stim.session.conditioning
        % exception: last session longer by mistake for mice 1:5 S1 imaging
        if ismember(imouse,1:5) && isession==4 && strcmp(folder.parentDir{stim.group},'K:\z_Simon\data\CaMKII-GCaMP8m_S1_miniscope_cond_sens_CCI')
            nfr= stim.fr * stim.duration(2);
        else
            nfr= stim.fr * stim.duration(1);
        end
        if contains(folder.parentDir{1},'fullcond')
            nfr= stim.fr * round(data(imouse,isession).info.behavior.rec.ts,1) - frame_offset(imouse);
        end
        % append
        data(imouse,isession).info.info.nfr= nfr;
        % get current number of frames
        dims= size(data(imouse,isession).traces);
        rs= dims(2)/nfr; % resample rate
        frames= round(rs:rs:dims(2)); % frames to include
        % resample traces
        data(imouse,isession).traces= data(imouse,isession).traces(:,frames);
        % resample spikes
        data(imouse,isession).spikes= data(imouse,isession).spikes(:,frames);
        % exception
        if imouse==2 && isession==2 && contains(folder.parentDir{1},'fullcond')
            data(imouse,isession).traces= cat(2,data(imouse,isession).traces(:,1:22000), data(imouse,isession).traces(:,21970:22000), data(imouse,isession).traces(:,22001:end));
            data(imouse,isession).spikes= cat(2,data(imouse,isession).spikes(:,1:22000), data(imouse,isession).spikes(:,21970:22000), data(imouse,isession).spikes(:,22001:end));
        end
        
    end
end