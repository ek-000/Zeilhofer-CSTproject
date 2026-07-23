% collects freezing frames, start and stop frames from .avi files
% path = parentDir/'mouse_folders'/sessions/My_Webcam/.avi
% crop: draw rectangle on first frame and double-click inside (1st movie)
% load beh file and add the tones
% Simon d'Aquin started feb. 2022

% to do
% include session 4 (no tones)
% split cre pos and cre neg into 2 groups: do not compare in the code

% to do: summary plot with connection between individual mice

clear, clc, close all, warning off
addpath(genpath('K:\z_Simon\codes')) % path to codes

% parentDir= 'K:\z_Simon\data\SD040_TetxLC_S1-CST_behavior only\conditioning beh\TeTxLC';
% parentDir= 'K:\z_Simon\data\SD021-030_opto-conditioning behavior only\SNS-ChR2_Cre-negative'; % [2 2.1 2 1.4 1.2 1.2 1.4 1.2 1.4 1.2]
% parentDir= 'K:\z_Simon\data\opto-conditioning behavior
% only\SNS-ChR2_Cre-positive' % [2 2 2 1.4 1.3 1.3 1.3]
% parentDir= 'K:\z_Simon\data\SD042_TetxLC_S1-CST_behavior only\SD042_data'; %% [1.8]
% parentDir= 'K:\z_Simon\data\CaMKII-GCaMP8m_S1_miniscope_cond_sens_CCI'
% parentDir= 'K:\z_Simon\data\DIO-hSyn-GCaMP8m_S1_miniscope_cond_sens_CCI_PNs'
parentDir= 'K:\z_Simon\data\SD065_fullcond_S1_CST_HM4Di_behavior only\SO4003 LR'; % experiment folder
% parentDir= 'K:\z_Simon\data\SD052_fullcond_S1_CST_ChR2_behavior only and optogenetics';



addpath(genpath(parentDir)) % path to codes


%%%%%%%%%%%%%%%%%%%%%%% WHAT TO DO: %%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%
sessionNames= {'5 fullcond'}; %  {'1_hab','2_cond','3_condvar','4_unsi'} or {'1 hab','2 cond','3 ret', '4 fullcond','5 fullcond'} %  name of session to process
%%%%%%%%%%%%%%

%%%%%%%%%%%%
opt.single=         0; % part1: get mouse motion (single movies)
opt.batch=          1; % part2: freezing quantification (batch)
%%%%%%%%%%%

% not important anymore: will be analyzed later
opt.singleMouse=        0; % plots freezing detection for each mouse
par.freez_thres=        20; % threshold  a.u pixel change per frame (i.e motion) normalized to mouse size (/ fr) miniscope: 850, no miniscope: 370; 520 for old videos (beh only)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%
opt.movielist=          0; % (default: '0', get movie in folder with sessionName/My_Webcam/0.avi), '1': ignore folder structure, use all .avi files in parentDir and subfolders
opt.testmode=           1; % saves intermediate video  (recommended to check)
testVidRange=           [7000:11000]; % if opt.testmode, test frames to save (in addition) % default '7000:11000', '[]' for whole movie
opt.nframe=             []; % default '[]' process only the first nframe of the movie for test e.g 1000
opt.filter_out_cable=   1; % bindil just leave it there
%%%%%%%%%%%%%%

% saves as .avi:
% 1) part1: raw movie (bin),
% 2) part1: binarized movie (bin),
% 3) part1: difference between frames (bind)


% part1 (motion) parameters
dilateDiameter=         9; % pixels to dilate binary image and get rid of the miniscope cable (default= 4 for miniscope, 9 for opto cables); '0': no change
% part2 (freezing) parameters: not important anymore: will be analyzed later
par.winmerge=           0.2; % sec, merge freezing episodes
par.winfreez=           2; % sec, minimum time freezing for freezing episode
%%%%%%%%
opt.manual_bin_thresh=  1.8; % the higher the more mouse, leave empty for semi-automatic, one value for all '1.8', '2.5' for opto or one value per mouse
%%%%%%%%


% other options: not important anymore: will be analyzed later
crePos= []; % leave empty for all mice SD020  [1 4 5 6 7 9];
creNeg= []; % SD020 [2 3 8];
tones=  [1:10]; % restrict to subset of tone for quantification (batch), leave empty for all tones
sessionCols= {0.6*[1 1 1], [0 0.4470 0.7410], [0.8500 0.3250 0.0980], [0.6500 0.2250 0.0980]};


%% %%%%%%%%%%%%%%%%     Part1:    SINGLE     %%%%%%%%%%%%%%%%%%%%%

if opt.single
    time_start= clock;
    sessions= 1:length(sessionNames); %%%%%%%%%%%

    for isession= sessions
        % loop through sessions
        % find all behavioral videos in subfolder
        cd(parentDir)
        if opt.movielist
            movlist= dir('**\*.avi');
        else
            movlist= dir(['**\' sessionNames{isession} '\**\My_Webcam\0.avi']);
        end


        for imouse= 1:length(movlist) %%%%%%%%%%%%%%%% one movie per mouse
            % loop through movies in subfolder
            saveDir= dir([movlist(imouse).folder,'\..']).folder;

            %% load movie
            % read movie
            mov= VideoReader(fullfile(movlist(imouse).folder, movlist(imouse).name));
            % get movie frame number
            if ~isempty(opt.nframe)
                NumFrames= opt.nframe;
            else
                NumFrames= mov.NumFrames;
            end

            % Crop movie (if first movie, then use same crop)
            if not(exist('rect','var'))
                figure;
                I= rgb2gray(read(mov,1));
                [J,rect] = imcrop(I);
            end

            % load movie and convert to grayscale
            fprintf('\nloading movie\n')
            tic
            % pre-allocate
            bwmov= zeros(size(J,1),size(J,2),NumFrames,'uint8');
            % load movie as grayscale + apply crop
            parfor ifr= 1:NumFrames %%%%%%%%%%
                bwmov(:,:,ifr)= imcrop(rgb2gray(read(mov,ifr)), rect);
            end
            if opt.testmode
                if isempty(testVidRange)
                    Range= 1:NumFrames-1;
                else
                    Range= testVidRange;
                end
            end
            toc


            %% downsample
            %             nfr= 15200;
            %
            %             writer = VideoWriter(fullfile(movlist(imouse).folder, [movlist(imouse).name,'_resampled']));
            %             writer.FrameRate=  mov.FrameRate
            %             writer.NumFrames= nfr;
            %             open(writer)


            % rs= resample(bwmov,nfr,length(bwmov));

            %             %% save movie as .mat for faster loading next time
            %             cd(movlist(imouse).folder)
            %             save('mov.mat','bwmov','-v7.3')
            %             tic
            %             mov= load('mov.mat')
            %             toc



            %% remove dark corner
            px_remove= 35; % 35
            dims= size(bwmov);
            bwmov(dims(1)-px_remove:dims(1), dims(2)-px_remove:dims(2), :)= 255; % make the corner white

            %% binarize movie
            % rules for binarize threshold: useless
            if mean(bwmov,'all') > 100
                par.binThres= 1.2;
            elseif mean(bwmov,'all') > 90 && mean(bwmov,'all') < 100
                par.binThres= 1.3;
            elseif mean(bwmov,'all') > 85 && mean(bwmov,'all') < 90
                par.binThres= 1.5;
            else
                par.binThres= 1.8;
            end

            % adative threshold: not required
            if ~isempty(opt.manual_bin_thresh)
                if length(opt.manual_bin_thresh)==1
                    par.binThres= opt.manual_bin_thresh;
                elseif  length(opt.manual_bin_thresh)>=1
                    par.binThres= opt.manual_bin_thresh(imouse);
                end
            end

            bin= true(size(bwmov)); % preallocate


            fprintf('\nbinarizing raw movie\n')
            for ifr= 1:size(bin,3)
                I= (bwmov(:,:,ifr));
                bin(:,:,ifr)= I > prctile(I(:), par.binThres); % finds the par.binThres % darkest pixels in frame (I)
            end
            fprintf('\nbinarizing done\n')

            %             play(bin)

            if opt.testmode
                bwmov(:,:,end)=[];
                fprintf('\nsaving in:\n'); disp(saveDir)
                saveasavi(bin(:,:,Range),saveDir,[num2str(imouse) '_bin'],'fr',mov.FrameRate);
                fprintf('\nbinary saved in:\n'); disp(saveDir)
            end

            clear bwmov
            toc

            %% morphologically filter out connected cables
            fprintf('\nmorphologically filter out miniscope cable\n')
            tic
            se= strel('cube',dilateDiameter); % morphological element

            bindil= bin; % pre-allocate
            if opt.filter_out_cable
                % imdilate to remove thin objects
                for ifr=1:size(bin,3)
                    bindil(:,:,ifr)= imdilate(bin(:,:,ifr),se);
                end
            end

            if opt.testmode
                fprintf('\nsaving in:\n'); disp(saveDir)
                saveasavi(bindil(:,:,Range),saveDir,[num2str(imouse) '_bindil'],'fr',mov.FrameRate);
                fprintf('\ndilated binary saved in:\n'); disp(saveDir)
            end

            %% Collect centroid position
            clear centroid
            parfor ifr= 1:size(bindil,3)
                I= bindil(:,:,ifr); % get frame
                % find and pot centroid
                [y,x] = find(~I); % get black pixels coordinates
                xy= [x y]; % concatenate coordinates
                centroid(:,ifr)= mean(xy); % get centroid
            end
            clear bin
            toc

            %%

            % figure;
            % for ifr=1:1000
            % imshow(bindil(:,:,ifr)); hold on
            % plot(centroid(1,ifr),centroid(2,ifr),'.','markersize',20,'color','r')
            % drawnow
            % end

            %% Save
            clear mot
            mot.centroid= centroid;
            mot.par= par;
            mot.mov= movlist(imouse);
            if opt.movielist
                save(fullfile(saveDir,[num2str(imouse) '_motion.mat']),'mot','-v7.3')
            else
                save(fullfile(saveDir,'motion.mat'),'mot','-v7.3')
            end
            % time elapsed
            fprintf(['\nmovie ' num2str(imouse) ' of ' num2str(length(movlist)) ' done\n'])
            SD_time(time_start)
        end
        fprintf(['\nfolder ' num2str(isession) ' of ' num2str(length(sessions)) ' done\n'])
    end
end



%% %%%%%%%%%%%%%%%%     Part2:    BATCH     %%%%%%%%%%%%%%%%%%%%%
if opt.batch

    %% load all freezing and behavior aquisition data
    fprintf('\nloading all data\n')
    freez_all= struct([]); beh_all= struct([]);
    sessions= 1:length(sessionNames);

    for isession= sessions %%%%%

        % find all behavioral videos in subfolder
        cd(parentDir)
        motionFileList= dir(['**\' sessionNames{isession} '\**\motion.mat']);

        for imouse= 1:length(motionFileList) %%%%%%
            % loop through movies in subfolder
            saveDir= fullfile(parentDir,'freezing_all'); try mkdir(saveDir); end

            % load motion
            load(fullfile(motionFileList(imouse).folder, 'motion.mat'))

            % calculate motion from centroid
            clear distance
            parfor ifr= 2:size(mot.centroid,2) % calculate distance between centroids
                distance(ifr-1)= pdist([mot.centroid(:,ifr), mot.centroid(:,ifr-1)],'euclidean');
            end
            motion= abs(diff(distance)); % motion
            motion(find(isnan(motion)))= nanmean(motion);
            mot.motion= motion;

            % transfer mot fields
            fields= fieldnames(mot);
            % add freezing data for mouse and session to freez_all
            for ifield= 1:length(fields)
                freez_all(imouse,isession).(fields{ifield}) = mot.(fields{ifield});
            end
            % get mouse name
            p= regexp(freez_all(imouse,isession).mov.folder,'\','split');
            freez_all(imouse,isession).mouse_name= p{end-3};


            % load behavior data
            beh= dir([motionFileList(imouse).folder '\' sessionNames{isession}(3:end) '.mat']);
            load(fullfile(beh.folder,beh.name))
            fields= fieldnames(beh);
            % add behavior data for mouse and session to beh_all
            for ifield= 1:length(fields)
                beh_all(imouse,isession).(fields{ifield}) = beh.(fields{ifield});
            end
            if ~isempty(beh_all(imouse,isession).camera)
                % get camera frame rate
                beh_all(imouse,isession).camera.fr= length(beh_all(imouse,isession).camera.ts) / beh_all(imouse,isession).rec.ts;
            end
        end
    end

    %% get tone frames
    if isempty(tones); tones= 1:length(beh_all(end,end-1).tone.fron); end

    for isession= sessions
        for imouse= 1:length(motionFileList)
            tonefr={};
            for itone= tones
                try
                    tonefr{itone}= beh_all(imouse,isession).tone.fron(itone): beh_all(imouse,isession).tone.froff(itone);
                catch
                    tonefr{itone}= [];
                end
            end
            beh_all(imouse,isession).tone.tonefr= tonefr;
        end
    end


    %% get freezing episodes
    fprintf('\ncalculating freezing\n')
    for isession= sessions
        for imouse= 1:length(motionFileList)
            if ~isempty(beh_all(imouse,isession).camera)
                fr= beh_all(imouse,isession).camera.fr;
                motion= freez_all(imouse,isession).motion;
                % cut off LED stimulation artifacts
                motion(motion > prctile(motion,99.95))= prctile(motion,99.95);
                % low-pass filter motion
                filtering= hanning(round(fr/20))./sum(hanning(round(fr/20))); % low-pass filtering for display
                motion= filtfilt(filtering, 1, motion);
                % append
                freez_all(imouse,isession).motion= motion;

                % freezing frames
                freezfr= motion < (par.freez_thres/fr) ;
                freezfr(1)=0; freezfr(end)=0;

                % freezing episodes
                start= find(diff(freezfr)==1);
                stop= find(diff(freezfr)==-1);

                % merge closeby episodes
                for iep=2:length(start)
                    stop_time= start(iep) - stop(iep-1);
                    if stop_time < par.winmerge*fr
                        start(iep)=nan; stop(iep-1)=nan;
                    end
                end
                start(isnan(start))=[]; stop(isnan(stop))=[];

                % remove short episodes
                for iep=1:length(start)
                    ep_time= stop(iep) - start(iep);
                    if ep_time < par.winfreez*fr
                        start(iep)=nan; stop(iep)=nan;
                    end
                end
                start(isnan(start))=[]; stop(isnan(stop))=[];

                % update freezing frames
                freezfr=[];
                for iep=1:length(start)
                    ifreez= start(iep):stop(iep);
                    freezfr= [freezfr ifreez];
                end
                % append
                freez_all(imouse,isession).freezfr= freezfr;
                freez_all(imouse,isession).startfr= start;
                freez_all(imouse,isession).stopfr= stop;
            else
                freez_all(imouse,isession).freezfr= [];
                freez_all(imouse,isession).startfr= [];
                freez_all(imouse,isession).stopfr= [];
            end
        end
    end


    %% freezing during tones
    for isession= sessions
        for imouse= 1:length(motionFileList)
            if ~isempty(beh_all(imouse,isession).camera)
                freezfr= freez_all(imouse,isession).freezfr;
                toneFreezfr={}; pctToneFreez=[];
                for itone= tones
                    toneFreezfr{itone}= ismember(beh_all(imouse,isession).tone.tonefr{itone},freezfr);
                    pctToneFreez(itone)= round(sum(toneFreezfr{itone}/length(toneFreezfr{itone}))*100,2);
                end
                % append
                freez_all(imouse,isession).pctToneFreez= pctToneFreez;
            else
                freez_all(imouse,isession).pctToneFreez= nan(1,length(tones));
            end
        end
    end

    %% plot motion + freezing (single mouse)
    saveDir= fullfile(parentDir,'freezing_single mouse'); try mkdir(saveDir); end
    fprintf('\nplot freezing per mouse per session\n')
    if isempty(crePos); crePos= 1:length(motionFileList); end % all mice

    if opt.singleMouse
        for imouse= 1:length(motionFileList)
            for isession= sessions
                if ~isempty(beh_all(imouse,isession).camera)
                    motion= freez_all(imouse,isession).motion;
                    start=  freez_all(imouse,isession).startfr;
                    stop=   freez_all(imouse,isession).stopfr;
                    fr=     beh_all(imouse,isession).camera.fr;
                    toneon= beh_all(imouse,isession).tone.fron;
                    toneoff= beh_all(imouse,isession).tone.froff;
                    if ~isempty(beh_all(imouse,isession).US)
                        averon= beh_all(imouse,isession).US.fron;
                        averoff= beh_all(imouse,isession).US.froff;
                    else
                        averon=[];
                        averoff=[];
                    end

                    % name
                    if ismember(imouse,crePos); tag= 'crePos'; else, tag= 'creNeg'; end
                    name= [freez_all(imouse,isession).mouse_name ' ' sessionNames{isession} ' ' tag '    '...
                        num2str(round(mean(freez_all(imouse,isession).pctToneFreez))) ' percent freezing during tone'];
                    % plot motion
                    t=(1:length(motion))./fr;
                    figure('position',[100 100 1600 500]);
                    % plot motion
                    plot(t, motion,'k'); hold on
                    % add threshold line
                    line([0 t(end)],[par.freez_thres par.freez_thres]/fr, 'color', 'm')
                    % add freezing episodes
                    for iep=1:length(start)
                        plot([start(iep) stop(iep)]/fr,[0 0],'r','linewidth',6)
                    end
                    % add tones
                    for istim=1:length(toneon)
                        xrect = [toneon(istim) toneoff(istim)  toneoff(istim) toneon(istim)]/fr ;
                        yrect = [0, 0, max(motion), max(motion)];
                        patch(xrect, yrect, 'b','FaceAlpha',0.15,'edgecolor','none');
                    end
                    % add aversive stimulus
                    for istim=1:length(averon)
                        xrect = [averon(istim) averoff(istim)  averoff(istim) averon(istim)]/fr ;
                        yrect = [0, 0, max(motion), max(motion)];
                        patch(xrect, yrect, 'r','FaceAlpha',0.8,'edgecolor','none');
                    end
                    % appearance
                    SD_figure_appearance
                    ylabel('motion between frames')
                    xlabel('time (sec)')
                    set(gca,'ticklength',[0 0]);
                    title(name,'interpreter','none')
                    % save
                    SD_save(name,saveDir)
                end
            end
        end
    end

    %% average freezing per group
    saveDir= fullfile(parentDir,'freezing_all'); try mkdir(saveDir); end
    fprintf('\nplot averagefreezing\n')
    groups= {crePos,creNeg};
    groupNames= {'Cre-positive','Cre-negative'};

    for igroup= 1:length(groups)
        if ~isempty(groups{igroup})
            % data
            data= [];
            for imouse= 1:length(groups{igroup})
                for isession= sessions
                    data(isession,imouse,:)= freez_all(groups{igroup}(imouse),isession).pctToneFreez;
                end
            end
            plotdat= nanmean(data,3);
            plotdat= mat2cell(plotdat,ones(length(sessions),1),[length(groups{igroup})]);

            % plot per session
            figure;
            [~,str]= boxplots(plotdat,'mean','outliers','color', 0.7*[1 1 1]);

            % appearance
            ylim([0 100])
            ylabel('% freezing during tone')
            xticklabels(sessionNames)
            clear name; name{1} = [groupNames{igroup} ' group'];
            name{2}= str;
            title(name,'fontsize',12,'interpreter','none')
            % add freezing values per mouse
            hold on
            plotdat= mean(data,3);
            for imouse= 1:length(groups{igroup})
                p = plotdat(:,imouse);
                plot(find(isfinite(p)), p(isfinite(p)));
            end
            % save
            SD_save(name{1},saveDir)
        end

        % plot per tone
        plotdat= squeeze(nanmean(data,2))';
        plotdat= reshape(plotdat,[1 size(plotdat,1)*size(plotdat,2)]);
        figure;
        b= bar(plotdat); hold on
        b.FaceColor = 'flat';
        for isession=1:length(sessions)
            trials= 1+(isession-1)*size(data,3) : isession*size(data,3);
            b.CData(trials,:)= repmat(sessionCols{isession},length(trials),1);
        end
        % appearance
        SD_figure_appearance
        ylim([0 100])
        ylabel('% freezing during CS')
        %  add freezing values per mouse
        for imouse= 1:length(groups{igroup})
            plotdat= squeeze(data(:,imouse,:))';
            plotdat= reshape(plotdat,[1 size(plotdat,1)*size(plotdat,2)]);
            plot(plotdat,'linewidth',1)
        end
        name{1}= [name{1} ' per tone'];
        title(name,'fontsize',12,'interpreter','none')
        % save
        SD_save(name{1} ,saveDir)
    end

    %% save workspace
    fprintf('\nsaving data per mouse\n')
    cd(parentDir)
    for isession= sessions
        motionFileList= dir(['**\' sessionNames{isession} '\**\motion.mat']);
        for imouse= 1:length(motionFileList)
            saveDir= motionFileList(imouse).folder;
            % split data per mouse
            behavior= beh_all(imouse,isession);
            behavior.freezing= freez_all(imouse,isession);
            % save .mat
            save(fullfile(saveDir,'behavior.mat'),'behavior','-v7.3')
        end
    end
end