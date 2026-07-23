function beh_montage= montage_mov(behavior,directory,filename,stack,filtering,test_dat,fr,opt,experiment)

% Combine behavior movie + Ca movie + mean fluorescence and behavior time
% stamps
% load behavior movie and downsample to match miniscope video size
brightness_factor= 1; % increase behavior movie brightness

% load behavior movie (limits number of frames to size of stack)
mov= VideoReader(fullfile(directory.test,directory.behavior_movies,filename.behavior_movies)); % load .avi movie from file
beh_mov= zeros(mov.Height, mov.Width, size(stack,3),'uint8'); % pre-allocate
% downsample to have same number of frames miniscope and behavior
ds= mov.NumFrames/size(stack,3);
frame= round(1:ds:mov.NumFrames);
% turn beh_mov to 8 bit grayscale
fprintf('\nloading behavior movie\n')
parfor ifr= 1:size(stack,3)
    beh_mov(:,:,ifr)= rgb2gray(read(mov,frame(ifr)));
end
beh_mov= uint8(beh_mov*brightness_factor); % stretch histogram
beh_mov(beh_mov> 2^8)= 2^8; % max out brightness
% resize behavior movie to fit stack xy dimensions
beh_mov= resize_mov(beh_mov,size(stack,1)/size(beh_mov,1));

% make montage
sep= repmat(2^8,[(size(stack,1)) 2 size(stack,3)]); % separation between vids
beh_ima_montage= cat(2, beh_mov, sep, stack);

% get mean raw fluorescence
mean_fluo= squeeze(mean(stack,[1 2]));
mean_fluo(1:5)= mean(mean_fluo); % remove dark frames for scale
% smoothen a bit
% mean_fluo= filtfilt(filtering, 1, mean_fluo);
t= 1/fr:1/fr:length(mean_fluo)/fr; % time for plot, s

% %% PLOT: montage behavior + imaging (update later)
clear F
figure('position',[200 100 1200 800])

subplot(2,4,1:4), % montage: behavior (left) and imaging (right)
imshow(beh_ima_montage(:,:,1),'InitialMagnification','fit');
title(directory.test)

%   %% PLOT: mean fluorescence + stimuli  overlay
subplot(2,4,5:7) % mean trace  and timestamps
% plot full trace
name= 'mean fluo timestamps overlay';
plot(t,mean_fluo,'k'); hold on
% appearance
SD_figure_appearance
axis tight
xlabel('time, s')
ylabel('mean raw fluorescence intensity')
title(name)

% simulus start line
if contains(experiment,'sensoryStim')
if ~contains(test_dat.info.test,'spont')
    line([behavior.stim_start_sec behavior.stim_start_sec], [min(mean_fluo) max(mean_fluo)], 'color', 'r')
    % "withdrawal" text mark
    str= repmat('.',[length(behavior.stim_start_sec) 1]); % no withdrawal
    str(behavior.paw_withdrawal==1)= 'W';  % withdrawal
    text(behavior.stim_start_sec, repmat(max(mean_fluo),[length(behavior.stim_start_sec) 1]), str)
    % stim rectangle (hargreaves)
    if not(isnan(behavior.Hargreaves_sec_to_withdrawal(1)))
        xrect = [behavior.stim_start_sec behavior.stim_start_sec - behavior.Hargreaves_sec_to_withdrawal ...
            behavior.stim_start_sec - behavior.Hargreaves_sec_to_withdrawal behavior.stim_start_sec];
        yrect = [min(mean_fluo) min(mean_fluo) max(mean_fluo) max(mean_fluo)];
        yrect = repmat(yrect,[size(xrect,1) 1]);
        xrect= xrect'; yrect= yrect';
        patch(xrect, yrect, 'r', 'FaceAlpha',0.15,'edgecolor','none');
    end
end
elseif contains(experiment,'conditioning')
    if not(isempty(behavior.US.tson))
    behavior.stim_start_sec= behavior.US.tson';
    else
        behavior.stim_start_sec= behavior.tone.tson';
    end
    % stim rectangle (tone CS)
    if ~isempty(behavior.tone.tson)
        xrect = [behavior.tone.tsoff' behavior.tone.tson' behavior.tone.tson' behavior.tone.tsoff'];
        yrect = [min(mean_fluo) min(mean_fluo) max(mean_fluo) max(mean_fluo)];
        yrect = repmat(yrect,[size(xrect,1) 1]);
        xrect= xrect'; yrect= yrect';
        patch(xrect, yrect, 'k', 'FaceAlpha',0.1,'edgecolor','none');
    end
    % stim line (US)
    if ~isempty(behavior.US.tson)
        line([behavior.US.tson' behavior.US.tson'], [min(mean_fluo) max(mean_fluo)], 'color', 'r')
    end
end
% create dynamic line
l= line([0 0], [min(mean_fluo) max(mean_fluo)], 'color', 'b');

%   %% PLOT: average triggered response
if ~contains(test_dat.info.test,'spont')

    subplot(2,4,8) % average triggered response
    twin_fr=    -3*fr:4*fr;
    twin_s=     -3:1/fr:4;
    % plot
    [mm,ss]= SD_meanEventTrigResp(mean_fluo, behavior.stim_start_sec, t', twin_fr, 1);
    SD_shadedErrorBar(twin_s, mm, ss, {'-', 'LineWidth', 1, 'color', 'k'}, 'transparent', 0.3);
    % appearance
    % simulus start line
    line([0 0], [min(mm)-ss max(mm)+ss], 'LineWidth', 2, 'color', 'r')
    SD_figure_appearance
    axis tight
    xlabel('time, s')
    name= 'average triggered response';
    title(name)
end
% UPDATE figure elements
subplot(2,4,1:4)
corr_fr=0; % initialize frame number
for ifr=1:opt.test.montage_ds:length(mean_fluo)
    corr_fr=corr_fr+1; % update frame number
    % update behavior camera and imaging
    imshow(beh_ima_montage(:,:,ifr),'InitialMagnification','fit');
    title(directory.test)
    % update dynamic line position
    l.XData= [round(ifr/fr) round(ifr/fr)];
    beh_montage(corr_fr) = getframe(gcf); % keep figures to save movie later
end
close(gcf)