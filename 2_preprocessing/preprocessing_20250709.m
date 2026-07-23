% INFO: File structure
% level 1: one parentDir per experiment, eg 'SD013'
% level 2: one mouseDir per mouse, eg 'SO 0405 L'
% level 3: one folder per session (miniscope plane), eg '2021_09_21'
% level 4: one folder per test containing several test trials (trial
% repeats), eg '02_brush L'
% exact names don't matter but the order does
clc, clear, close all, warning('off','all')

% codes directory
codeDir= 'K:\z_Simon\codes'; % where codes are  %%% codeDir = 'mypath\codes';
addpath(genpath(codeDir))

% data directory (results saved there)
parentDir = 'K:\z_Simon\data\SD065_alsomedinj_fullcond_S1_CST_HM4Di_behavior only'; % level 1, contains one folder per mouse %%% parentDir = 'mypath\data';
addpath(genpath(parentDir))

%% Options
conditioningSession=    [1:5]; % anything with only one test; sessions per mouse
sensoryStimSession=     []; % if several tests per session, for "manual" sensory stimulation

% Select data to process
mice=           []; % referring to folders, leave empty (=[]) to process all
sessions=       []; % referring to folders, leave empty (=[]) to process all
tests=          []; % referring to folders, leave empty (=[]) to process all (applies only to part 1)

% parts of the code to run
opt.TEST=               1; % 0 or 1 % part1: preprocess imaging and behavioral data for each test1
opt.SESSION=            1; % 0 or 1 % part2: combines test data per session
opt.CNMFE=              0; % 0 or 1 % part3: run CNMFE on session data
opt.CURATION=           0; % 0 or 1 % part4: manual curation
opt.GLOBAL=             0; % 0 or 1 % part5: find global cells (present in different sessions)

% %% Part 1: TEST collect data for each test (image preprocessing and behavior)
% aquisition noise
opt.test.subtract_aquisition_noise=      0; % 0 or 1, based on miniscope aquisition noise
% wiener filtering (not necessary)
opt.test.wiefilt=                        0; % wiener filtering to remove noise (blurs but helps registration)
% median filtering (not necessary)
opt.test.medfilt=                        0; % median filtering to remove noise (blurs but helps registration)

% miniscope movie spatial downsampling
opt.test.resize=                         0; % 0 or 1
opt.test.resize_factor=                  0.5; % spatial resampling, default = 1 (no change)

% miniscope movie rotation
opt.test.rotate=                         0; % 0 or 1
opt.test.rotate_deg=                     180; % rotation (degrees)

% behavior + ca imaging montage
opt.test.behavior=                       1; % 0 or 1, collect behavior annotations from .xlsx sheet
opt.test.montage=                        0; % 0 or 1, creates and saves a montage of mean fluo + behavior
opt.test.montage_ds=                     2; % spatial downsampling , default= 1 (no change) 
opt.test.save_montage=                   1; % 0 or 1, behavior + dfof + raw, saves as .avi in folder
% save test stack as .avi
opt.test.save_stack=                     1; % 0 or 1 % saves test stack as .avi (default=0, done at session level in part2)
% save test stack and behavior info as .mat (needed to concatenate sessions)
opt.test.save_test_dat=                  1; % 0 or 1 (default=1, needed to concatenate into session)

% %% Part2: SESSION combine test_dat into session_dat
opt.session.save=                       1; % 0 or 1
opt.session.fft_filtering=              0; % 0 or 1 % applied to dfof to help with motion correction
opt.session.motion_correction=          0; % 0 or 1 % rigid and non-rigid
% shift session stack relative to first session
opt.session.align=                      0; % 0 or 1 5 net needed, sessions are independent currently
opt.session.save_shift=                             0; % saves stack projection before and after shift
opt.session.registration.method=                    'imregister2'; % 'imregtform' or 'imregister2' (default)
opt.session.registration.mode=                      'multimodal'; % 'monomodal' or 'multimodal' (default)
opt.session.registration.transformation=            'rigid'; % 'affine' or 'rigid' (default)

% %% Part3: CNMFE
opt.cnmfe.save_results =                1; % saves CNMFE results
opt.cnmfe.plot_traces=                  0; % plot neuron traces
opt.cnmfe.savetracesplot =              0; % saves plot raw and fitted traces

%% before starting/parameters
clear filename directory
directory.parentDir=             parentDir;
directory.miniscope_movies=     'My_V3_Miniscope';
directory.behavior_movies=      'My_WebCam';
filename.behavior_movies=       '0.avi';

filename.behavior=              'behavior_annotation.xlsx'; % leave empty if no behavior, no files needed if no "manual" sensory stim 
filename.timestamps_camera=     'timeStamps.csv'; % leave empty if no behavior
filename.notes=                 'notes.txt'; % in session folder, irrelevant now
filename.data_session_cnmfe=    'session_stack.mat'; % run CNMFE on this data from session folder
filename.ca_movie_projection=   'stack_max_proj.tif';
filename.cnmfe_results=         'cnmfe_results.mat';
filename.cnmfe_results_curated= 'cnmfe_results_curated.mat';
filename.session_info=          'session_info.mat';

fr= 10; % miniscope recording frame per second
opt.overwrite= true; % saveastiff can overwrite file with same name
filtering= hanning(round(fr*2))./sum(hanning(round(fr*2))); % low-pass filtering for display
nrepeats= []; % repetitions per test '[]' for all
sessioncols= {'k','r','b','k','r','b'};

time_start= clock;

%% %%%%%%%%%%%%%%%%%%%%   Part1 TEST   %%%%%%%%%%%%%%%%%%%%%%%%%%%
if opt.TEST
    % level 1
    % mouse folders: get name of all folders one level below parentDir
    directory.mouse_list= GetSubDirsFirstLevelOnly(directory.parentDir);
    % remove folders that have to do with freezing and results
    directory.mouse_list(find(~cellfun(@isempty,strfind(directory.mouse_list ,'freezing'))))=[];
    directory.mouse_list(find(~cellfun(@isempty,strfind(directory.mouse_list ,'result'))))=[];
    if ~exist('mice','var') || isempty(mice)
        mice= 1:length(directory.mouse_list);
        fprintf(['\nfound ' num2str(mice(end)) ' mice\n'])
    end

    for imouse= mice % level 2
        % session folders: get name of all folders one level below mouseDir
        directory.session_list = GetSubDirsFirstLevelOnly(fullfile(directory.parentDir,directory.mouse_list{imouse}));
        if ~exist('sessions','var') || isempty(sessions)
            sessions= 1:length(directory.session_list);
            fprintf(['\nfound ' num2str(sessions(end)) ' sessions\n'])
        end

        for isession= sessions % level 3
            if ismember(isession,sensoryStimSession)
                experiment= 'sensoryStim';
            elseif ismember(isession,conditioningSession)
                experiment= 'conditioning';
            end

            % test folders: get name of all folders one level below session folder
            directory.test_list= GetSubDirsFirstLevelOnly(fullfile(directory.parentDir,directory.mouse_list{imouse}, directory.session_list{isession}));
            % remove folders created by CNMFE that start with 'session'
            directory.test_list(startsWith(directory.test_list,'session'))=[];
            if  ~exist('tests','var') || isempty(tests)
                tests= 1:length(directory.test_list);
                fprintf(['\nfound ' num2str(tests(end)) ' tests\n'])
            end

            for itest= tests % level 4
                %% collect_test_info
                directory.test= fullfile(directory.parentDir,directory.mouse_list{imouse}, directory.session_list{isession}, directory.test_list{itest});
                test_dat= collect_test_info(directory,filename,imouse,isession,itest,fr);

                % check that folder contains any miniscope movie
                flag.imaging= exist(fullfile(directory.test,directory.miniscope_movies),'file');

                %% load_1P_avi
                % load miniscope .avi movies (compressed with FFV1)
                % IMPORTANT: requires codec, see: https://codecguide.com/download_k-lite_codec_pack_basic.htm
                if flag.imaging
                    stack= load_miniscope_avi(directory);
                    test_dat.info.nframes= size(stack,3);
                else
                    stack=[];
                end

                %% miniscope_noise
                if flag.imaging
                    if opt.test.subtract_aquisition_noise
                        directory.noise= fullfile(parentDir,directory.mouse_list{imouse},directory.session_list{isession});
                        cd(directory.noise); % same as session folder
                        filename.noise= dir('M*G*LED*.avi'); filename.noise= filename.noise.name;
                        miniscope_id= filename.noise(2);
                        noise= miniscope_noise(directory,filename,miniscope_id);
                        test_dat.info.miniscope_id= miniscope_id; % append to info
                        % subtract noise
                        stack= stack-noise;
                    end
                end

                %% wierner 2D filter (not necessary)
                if opt.test.wiefilt
                    wienR= [2 2];
                    parfor ifr=1:size(stack,3)
                        [~,noise_out] = wiener2(stack(:,:,ifr),wienR);
                        stack(:,:,ifr) = wiener2(stack(:,:,ifr),wienR, noise_out);
                    end
                end

                %% median filter (not necessary)
                if opt.test.medfilt
                    medR= [2 2];
                    parfor ifr=1:size(stack,3)
                        stack(:,:,ifr) = medfilt2(stack(:,:,ifr),medR);
                    end
                end

                %% Spatial downsampling
                if opt.test.resize
                    stack= resize_mov(stack,opt.test.resize_factor);
                end

                %% Rotate
                if opt.test.rotate
                    stack= imrotate(stack,opt.test.rotate_deg);
                end

                %% convert to uint8
                if flag.imaging
                    stack= uint8(stack.*(2^8/max(stack,[],'all'))); % stretch histogram
                end

                %% Behavior
                if opt.test.behavior && ~contains(test_dat.info.test,'spont')
                    if contains(experiment,'sensoryStim')
                        behavior= get_behavior_annotation(directory,filename,nrepeats);
                    elseif contains(experiment,'conditioning') % load mat file generated during acquisition
                        load(fullfile(parentDir,directory.mouse_list{imouse},directory.session_list{isession},directory.test_list{itest},...
                            [directory.session_list{isession}(3:end) '.mat']))
                        behavior= beh;
                    end
                else
                    behavior=[];
                end

                %% beh_montage
                % Combine behavior movie + Ca movie + mean fluorescence and behavior time
                % stamps
                if opt.test.behavior && opt.test.montage && flag.imaging
                    beh_montage= montage_mov(behavior,directory,filename,stack,filtering,test_dat,fr,opt,experiment);
                else
                    beh_montage=[];
                end

                %% save_preprocessing_test
                save_preprocessing_test(stack,behavior,test_dat,directory,opt,fr,beh_montage)
                fprintf(['\ntest ' num2str(itest) ' of ' num2str(length(directory.test_list)) ' done\n']) % level 4
                SD_time(time_start)
            end
            fprintf(['\nsession ' num2str(isession) ' of ' num2str(length(directory.session_list)) ' done\n']) % level 3
        end
        fprintf(['\nmouse ' num2str(imouse) ' of ' num2str(length(directory.mouse_list)) ' done\n']) % level 2
    end
end

%% %%%%%%%%%%%%%%%%%%%%   Part2 SESSION   %%%%%%%%%%%%%%%%%%%%%%%%%%%

if opt.SESSION
    directory.mouse_list= GetSubDirsFirstLevelOnly(directory.parentDir);
    directory.mouse_list(find(~cellfun(@isempty,strfind(directory.mouse_list ,'freezing'))))=[];
    directory.mouse_list(find(~cellfun(@isempty,strfind(directory.mouse_list ,'result'))))=[];
    if isempty(mice) % all data by default
        mice= 1:length(directory.mouse_list);
    end

    for imouse= mice % level 2
        directory.session_list = GetSubDirsFirstLevelOnly(fullfile(directory.parentDir,directory.mouse_list{imouse}));
        if isempty(sessions) % all data by default
            sessions= 1:length(directory.session_list);
        end

        for isession= sessions % level 3
            %% concatenate_test_data
            [session_stack,session_info]= concatenate_test_data(directory,imouse,isession); % gets all test data from subfolders

            % check that session stack exist
            flag.imaging= ~isempty(session_stack);

            % replace black frames (couple first frames)
            if flag.imaging
                black_frames= find(sum(sum(session_stack))==0);
                session_stack(:,:,black_frames)= session_stack(:,:,black_frames+length(black_frames));
            end

            %% Dfof filtering (needed for motion correction)
            if flag.imaging
                % with option to save as .avi, .mat and projection as .tif
                options.freqLow  = 12; % 1 12
                options.freqHigh = 30; % 4 30
                dfof= session_dfof(session_stack,options);
            else
                session_stack=[]; dfof=[];
            end

            %             play(dfof)
            %             %%
            % I= dfof(:,:,5)
            % figure; imshow(I,[])
            % BW = im2bw(dfof(:,:,5),0.52)
            % figure; imshow(BW,[])
            % I(BW==0)= median(I(:))
            % figure; imshow(I,[])
            %

            %             %% blurr dfof for better registration
            %             parfor ifr= 1:size(dfof,3)
            %              dfof(:,:,ifr)= medfilt2(dfof(:,:,ifr),[20 20]);
            %             end

            %% FFT frequencies filtering dfof % never really worked
            if opt.session.fft_filtering
                % options
                options.test=               0; % '0': whole movie or '1' one frame (testFrame)
                options.testFrame=              24000; % frame to test
                % frequencies rage to filter out: between [low high]
                par.amplitudeThresholdlow = 11; % low 0
                par.amplitudeThresholdhigh= 20 ; % high 8.5
                par.px_exclude=             1; % pixel to exclude around center frequencies
                out_mov= fft_filter_movie(dfof, par, options); %%%%%%%%%%%%%%%%%%
                if ~options.test
                    dfof= uint8(out_mov);
                end
            end

            %% Motion correction
            if opt.session.motion_correction && flag.imaging
                % parameters
                dim= size(dfof);
                options = NoRMCorreSetParms('d1',dim(1),'d2',dim(2),'max_shift', [25 25 10],'boundary','zero');
                % register dfof
                [dfof,shifts_rigid]= normcorre_batch(dfof,options);
                % apply shifts_rigid to stack
                fprintf('\napplying shifts\n')
                session_stack= apply_shifts(session_stack,shifts_rigid,options);

                % register session_stack: nonrigid
                % parameters
                options = NoRMCorreSetParms('d1',dim(1),'d2',dim(2),'grid_size', ...
                    [dim(1)/5, dim(2)/5, 1], 'mot_uf', [1 1 1], 'max_shift', [15 15 10],'boundary','zero');
                % register dfof
                [dfof,shifts_nonrigid]= normcorre_batch(dfof,options);
                % apply shifts shifts_nonrigid to stack
                fprintf('\napplying shifts\n')
                session_stack= apply_shifts(session_stack,shifts_nonrigid,options);
            end


%             % Motion correction: directly corresct session_stack instead
%             of dfof + applying shifts
%             if opt.session.motion_correction && flag.imaging
%                 dfof= session_stack; %%%%%%%%%
%                 parameters
%                 dim= size(dfof);
%                 options = NoRMCorreSetParms('d1',dim(1),'d2',dim(2),'max_shift', [25 25 10],'boundary','zero');
%                 register dfof
%                 [dfof,shifts_rigid]= normcorre_batch(dfof,options);
%                 apply shifts_rigid to stack
%                 fprintf('\napplying shifts\n')
%                 session_stack= apply_shifts(session_stack,shifts_rigid,options);
% 
%                 register session_stack: nonrigid
%                 parameters
%                 options = NoRMCorreSetParms('d1',dim(1),'d2',dim(2),'grid_size', ...
%                     [dim(1)/5, dim(2)/5, 1], 'mot_uf', [1 1 1], 'max_shift', [15 15 10],'boundary','zero');
%                 register dfof
%                 [dfof,shifts_nonrigid]= normcorre_batch(dfof,options);
%                 % apply shifts shifts_nonrigid to stack
%                 fprintf('\napplying shifts\n')
%                 session_stack= apply_shifts(session_stack,shifts_nonrigid,options);
%             end


            %% Shift session_stack to previous session
            if opt.session.align && flag.imaging
                session_stack= align_session(imouse,isession,session_stack,directory,opt);
            end

            %% Save_preprocessing_session
            % saves session_stack as.avi and .mat, and mean and max
            % projections, saves session_info
            if opt.session.save
                save_preprocessing_session(directory,session_stack,dfof,session_info,imouse,isession,opt,fr)
            end
            clear session_stack dfof
            SD_time(time_start)

        end
    end
end


%% %%%%%%%%%%%%%%%%%%%%   Part3 CNMFE   %%%%%%%%%%%%%%%%%%%%%%%%%%%

if opt.CNMFE

    %% loop through folders
    directory.mouse_list= GetSubDirsFirstLevelOnly(directory.parentDir);
    % remove folders that have to do with freezing or results
    directory.mouse_list(find(~cellfun(@isempty,strfind(directory.mouse_list ,'freezing'))))=[];
    directory.mouse_list(find(~cellfun(@isempty,strfind(directory.mouse_list ,'result'))))=[];
    if isempty(mice) % all data by default
        mice= 1:length(directory.mouse_list);
    end
    if isempty(mice)
        mice=1; % no folder structure
        directory.mouse_list{1}=[];
    end

    for imouse= mice % level 2
        directory.session_list = GetSubDirsFirstLevelOnly(fullfile(directory.parentDir,directory.mouse_list{imouse}));
        if isempty(sessions) % all data by default
            sessions= 1:length(directory.session_list);
        end
        if isempty(sessions)
            sessions=1; % no folder structure
            directory.session_list{1}=[];
        end

        for isession= sessions % level 3
            folder= fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{isession});
            fprintf(['\nrunning CNMFE on mouse ' num2str(imouse) ' session ' num2str(isession) '\n'])
            fprintf(filename.data_session_cnmfe)
            clear('mat_data*','dat')

            %% choose data
            cd(folder)
            saveDir= fullfile(folder,[filename.data_session_cnmfe(1:end-4) '_source_extraction']); mkdir(saveDir)
            % delete previous data file and replace it
            list= dir(saveDir); % get files in directory
            idx= find(contains({list.name},'data')); % find file name containing 'data'
            cd(saveDir); if ~isempty(idx); delete(list(idx).name); end % delete file
            cd(folder)
            % input data name
            neuron = Sources2D();
            nam = ['./' filename.data_session_cnmfe]; % './data_1p.tif'
            nam = neuron.select_data(nam);

            %% Parameters
            % -------------------------    COMPUTATION    -------------------------  %
            pars_envs = struct('memory_size_to_use', 50, ...   % GB, memory space you allow to use in MATLAB % 24
                'memory_size_per_patch', 6, ...   % GB, space for loading data within one patch % 0.6
                'patch_dims', [64, 64]);  % GB, patch size
            % -------------------------      SPATIAL      -------------------------  %
            gSig = 3;           % pixel, gaussian width of a gaussian kernel for filtering the data. 0 means no filtering % 3
            gSiz = 13;          % pixel, neuron diameter % 13
            ssub = 1;           % spatial downsampling factor % 1
            % -------------------------      TEMPORAL     -------------------------  %
            fr   = 10;          % frame rate
            tsub = 2;           % temporal downsampling factor % 1
            % -------------------------  INITIALIZATION   -------------------------  %
            min_pnr = 10;        % minimum peak-to-noise ratio for a seeding pixel % 8
            min_corr= 0.6;      % minimum local correlation for a seeding pixel % 0.8
            K = [30];              % maximum number of neurons per patch. when K=[], take as many as possible.
            use_parallel = false; % use parallel computation for parallel computing % true
            % -------------------------     CUSTOM       ---------------------------
            % determine the search locations by selecting a round area
            updateA_search_method = 'ellipse';
            updateA_dist = 5; % 5
            updateA_bSiz = neuron.options.dist;

            % custom options apply, see first code section
            spatial_constraints = struct('connected', true, 'circular', true);  % you can include following constraints: 'circular'
            spatial_algorithm = 'hals_thresh';

            % spike deconvolution
            deconv_flag = true;     % run deconvolution or not % true
            deconv_options = struct('type', 'ar1', ... % model of the calcium traces. {'ar1', 'ar2'} % ar1
                'method', 'foopsi', ... % method for running deconvolution {'foopsi', 'constrained', 'thresholded'} % foopsie
                'smin', -4, ...         % minimum spike size. When the value is negative, the actual threshold is abs(smin)*noise level %-5
                'optimize_pars', true, ...  % optimize AR coefficients
                'optimize_b', true, ... % optimize the baseline);
                'max_tau', 100);        % maximum decay time (unit: frame);
            nk = 3; % detrending the slow fluctuation. usually 1 is fine (no detrending) % 3
            % when changed, try some integers smaller than total_frame/(Fs*30)
            detrend_method = 'spline';  % compute the local minimum as an estimation of trend

            % -------------------------     BACKGROUND    -------------------------  %
            bg_model = 'ring';  % model of the background {'ring', 'svd'(default), 'nmf'} % use ring, otherwise error
            nb = 1;            % number of background sources for each patch (only be used in SVD and NMF model)
            ring_radius = 18;  % when the ring model used, it is the radius of the ring used in the background model. % 18
            % otherwise, it's just the width of the overlapping area
            num_neighbors = []; % number of neighbors for each neuron
            bg_ssub = 1;        % downsample background for a faster speed % 1

            % -------------------------      MERGING      -------------------------  %
            show_merge = false;  % if true, manually verify the merging step
            merge_thr = 0.65;     % thresholds for merging neurons; only C % 0.65 merge if corr > thr and d<dmin
            method_dist = 'mean'; % method for computing neuron distances {'mean', 'max'} % max
            dmin = 6;       % minimum distances between two neurons. it is used together with merge_thr % 5
            dmin_only = 5;  % merge neurons if their distances are smaller than dmin_only. % 2
            merge_thr_spatial = [0.6, -inf, -inf]; % merge neurons if all thresh for A (spatial), C (temporal) and S (spike). If only one value then C only: [0 T 0] % [0.8, 0.4, -inf]
            % flag_merge = (A_overlap>=A_thr)&(C_corr>=C_thr)&(S_corr>=S_thr);

            % -------------------------  INITIALIZATION   -------------------------  %
            show_init = false;   % show initialization results % true
            min_pixel = gSig^2;  % minimum number of nonzero pixels for each neuron & gSig^2
            bd = 15;             % number of rows/columns to be ignored in the boundary (mainly for motion corrected data) % 0
            frame_range = [];   % when [], uses all frames, otherwise faster with [1,2000] % []
            save_initialization = false;    % save the initialization procedure as a video.
            choose_params = true; % manually choose parameters
            center_psf = true;  % set the value as true when the background fluctuation is large (usually 1p data) % true
            % set the value as false when the background fluctuation is small (2p)

            % -------------------------  Residual   -------------------------  %
            min_corr_res = min_corr;
            min_pnr_res = min_pnr*1.2; % 6
            seed_method_res = 'auto';  % method for initializing neurons from the residual
            update_sn = false;

            % ----------------------  WITH MANUAL INTERVENTION  --------------------  %
            with_manual_intervention = false;
            % -------------------------  FINAL RESULTS   -------------------------  %
            save_demixed = true;    % save the demixed file or not % true %%%%%%%%%%%%%
            kt = 3;                 % frame intervals

            % -------------------------    UPDATE OPTIONS    -------------------------  %
            neuron.updateParams('gSig', gSig, ...       % -------- spatial --------
                'gSiz', gSiz, ...
                'ring_radius', ring_radius, ...
                'ssub', ssub, ...
                'search_method', updateA_search_method, ...
                'bSiz', updateA_bSiz, ...
                'dist', updateA_bSiz, ...
                'spatial_constraints', spatial_constraints, ...
                'spatial_algorithm', spatial_algorithm, ...
                'tsub', tsub, ...                       % -------- temporal --------
                'deconv_flag', deconv_flag, ...
                'deconv_options', deconv_options, ...
                'nk', nk, ...
                'detrend_method', detrend_method, ...
                'background_model', bg_model, ...       % -------- background --------
                'nb', nb, ...
                'ring_radius', ring_radius, ...
                'num_neighbors', num_neighbors, ...
                'bg_ssub', bg_ssub, ...
                'merge_thr', merge_thr, ...             % -------- merging ---------
                'dmin', dmin, ...
                'method_dist', method_dist, ...
                'min_corr', min_corr, ...               % ----- initialization -----
                'min_pnr', min_pnr, ...
                'min_pixel', min_pixel, ...
                'bd', bd, ...
                'center_psf', center_psf);
            neuron.Fs = fr;

            %%%%%%%%%%%%%% START %%%%%%%%%%%%%%
            %% distribute data and be ready to run source extraction
            neuron.getReady(pars_envs);

            %% initialize neurons from the video data within a selected temporal range
            if choose_params
                % change parameters for optimized initialization
                [gSig, gSiz, ring_radius, min_corr, min_pnr] = neuron.set_parameters();
            end

            % use parallel if data is small enough
            dat= whos('mat_data*');
            if dat.bytes < 5*10^9 % check size dataset
                use_parallel= true;
            end

            fprintf('\nINITIALIZATION\n')
            [center,Cn,PNR] = neuron.initComponents_parallel(K, frame_range, save_initialization, use_parallel);
            neuron.compactSpatial();

            neuron.show_contours(0.8); hold on % show contours updated
            title(['initialization: ' num2str(size(neuron.C,1)) ' neurons found '], 'fontsize', 16)
            savefig(saveDir,'1 initial neurons contours') % save figure

            %% estimate the background components
            neuron.update_background_parallel(use_parallel);
            neuron_init = neuron.copy();

            %% merge neurons and update spatial/temporal components
            neuron.merge_neurons_dist_corr(show_merge); % merge_thr
            neuron.merge_high_corr(show_merge, merge_thr_spatial);

            %% pick neurons from the residual
            [center_res, Cn_res, PNR_res] = neuron.initComponents_residual_parallel([], save_initialization, use_parallel, min_corr_res, min_pnr_res, seed_method_res);
            if show_init
                axes(ax_init);
                plot(center_res(:, 2), center_res(:, 1), '.g', 'markersize', 10);
            end
            neuron_init_res = neuron.copy();

            %% udpate spatial and temporal components, delete false positives and merge neurons
            % update spatial
            if update_sn
                neuron.update_spatial_parallel(use_parallel, true);
                udpate_sn = false;
            else
                neuron.update_spatial_parallel(use_parallel);
            end
            % merge neurons based on correlations
            neuron.merge_high_corr(show_merge, merge_thr_spatial);

            for m=1:2
                % update temporal
                neuron.update_temporal_parallel(use_parallel);
                % delete bad neurons
                neuron.remove_false_positives();
                % merge neurons based on temporal correlation + distances
                neuron.merge_neurons_dist_corr(show_merge);
            end

            %% Add a manual intervention and run the whole procedure for a second time
            neuron.options.spatial_algorithm = 'nnls';
            if with_manual_intervention
                show_merge = true;
                neuron.orderROIs('snr');   % order neurons in different ways {'snr', 'decay_time', 'mean', 'circularity'}
                neuron.viewNeurons([], neuron.C_raw);

                % merge closeby neurons
                neuron.merge_close_neighbors(true, dmin_only);

                % delete neurons
                tags = neuron.tag_neurons_parallel();  % find neurons with fewer nonzero pixels than min_pixel and silent calcium transients
                ids = find(tags>0);
                if ~isempty(ids)
                    neuron.viewNeurons(ids, neuron.C_raw);
                end
            end

            %% save the workspace for future analysis
            neuron.orderROIs('snr');
            % cnmfe_path = neuron.save_workspace();

            %% show neuron contours
            Coor = neuron.show_contours(0.8);
            title(['residual: ' num2str(length(Coor)) ' neurons found '], 'fontsize', 16)
            savefig(saveDir,'2 residual neurons contours') % save figure

            %% save
            if opt.cnmfe.save_results
                S= struct(neuron);
                save(fullfile(saveDir,'cnmfe_results'),'S','-v7.3')
            end

            %% plot_traces_cnmfe
            if opt.cnmfe.plot_traces
                % parameters
                nrange=      []; % neurons to plot, all if empty (default)
                frrange=     []; % frame range, all if empty (default)

                plot_traces_cnmfe(neuron,nrange,frrange,fr,opt,saveDir)
            end

            close all
            SD_time(time_start)
        end
    end
end



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%    Part 4 MANUAL CURATION   %%%%%%%%%%%%%%%%%%%
if opt.CURATION

    %% parameters
    % choose data
    imouse=         1;
    isession=       1; %  one session at a time

    % options
    opt.curation.save_results=     0; % option to change later, keep 0 by defaul to avoid overwriting
    opt.curated=                   1; % loads already curated cnfme data for further inspection

    % what to do
    opt.curation.remove_inactive_neurons=   1;
    opt.curation.remove_inactive=           1;
    opt.curation.remove_oddsize=            1;
    opt.curation.remove_oddshape=           1; % removes non circular neurons
    opt.curation.manually_remove_neurons=   1;
    opt.curation.manually_remove_bad_traces=1;
    opt.curation.save_before_after_contours=1;

    % load_cnmfe_data
    [neuron,saveDir,Coor_prev,directory]= load_cnmfe_data(directory,filename,imouse,isession,opt);
    fprintf('\n data loaded\n')


    %% 1_Remove_inactive_neurons (based on filter)
    % removes inactive neurons and neurons with odd shapes and sizes
    if opt.curation.remove_inactive_neurons
        % parameters
        opt.curation.thr_act=    0.001; % kick out neurons with no activity
        opt.curation.thr_size=   [80 inf]; % [minsize maxsize] [100 1000]
        opt.curation.thr_shape=  2.8; % circularity
        [neuron,del_ids_shape]= remove_inactive_neurons(neuron,opt,saveDir);
    end


    %% 2_Manually_remove_bad_traces (based on activity)
    if opt.curation.manually_remove_bad_traces
        close all
        opt.save= 0; % save updated trace
        opt.range= []; % '[]' for all, e.g 1:14000
        [neuron,del_ids_trace]= manually_remove_bad_traces(neuron,fr,opt,saveDir);
    else
        del_ids_trace=[];
    end


    %% 3_Manually_remove_neurons (based on location)
    if opt.curation.manually_remove_neurons
        close all
        [neuron,del_ids_location]= manually_remove_neurons(neuron);
    else
        del_ids_location= [];
    end


    %% 4_SAVE
    % save updated contours (Cn)
    if opt.curation.save_results
        Coor= neuron.show_contours;
        title([num2str(length(Coor)) ' remaining'], 'fontsize', 12)
        savefig(saveDir,'4 curated neurons contours') % save figure
        close(gcf)
    end

    % SAVE contours before / after
    if opt.curation.save_before_after_contours
        save_before_after_contours(neuron,directory,filename,Coor_prev,saveDir,imouse,isession); % contours.tif
    end

    % SAVE CNMFE results
    if opt.curation.save_results
        S= struct(neuron);
        save(fullfile(saveDir,'cnmfe_results_curated'),'S','-v7.3')
        fprintf('\nResults saved\n')
    end
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%    Part 5 GLOBAL   %%%%%%%%%%%%%%%%%%%
if opt.GLOBAL
    % choose data
    mice=         [1]; % e.g 1:5
    sessions=     []; % 1:5; % leave empty for all '[]'
    % options
    opt.global.save_results=     1; % append glocal cells to "neuron"
    opt.curated=                 1; % loads already curated cnfme data for additional inspection, default=1
    saveFilename= 'cnmfe_results_curated_global'; % save name

    for imouse= mice
        % load_cnmfe_data
        [neuron,saveDir,Coor_prev,directory, sessions]= load_cnmfe_data(directory,filename,imouse,sessions,opt);

        % contour_session_overlap
        % parameters
        par.SpatialOverlapThresh= 0.5; % threshold overlap proportion (last to first session contour)
        par.reg_tform=      'imregister2';  % 'imregister2', 'imregtform'
        par.reg_mode=       'multimodal';    % 'multimodal', 'monomodal'
        par.reg_transfo=    'rigid';    % 'translation','rigid','similarity','affine'

        par.angle=              []; % manually enter angle 1.4
        par.angle_session=      0; % default '0' 2
        par.tranlation=         []; % [x y] translation -30 80
        par.tranlation_session= 0;  % default '0' 2

        par.save= 1; % saves results in a subfolder 'contours' in saveDir

        [global_cells,Icat,name]= find_global(neuron,sessions,sessioncols,par,saveDir); %%%%%%%%%%

        % append global cells to neuron data
        for isession= sessions
            if isession==sessions(end) % no global cells for last session
                neuron(sessions(isession)).neurons_per_patch= [];
            else
                neuron(sessions(isession)).neurons_per_patch= global_cells{isession};
            end
        end

        % save (append results)
        if opt.global.save_results
            for isession=sessions
                S= struct(neuron(isession));
                save(fullfile(saveDir{isession},saveFilename),'S','-v7.3')
            end
            fprintf('\nresults saved\n')
        end
        fprintf(['\nmouse ' num2str(imouse) ' of ' num2str(length(mice)) ' done\n'])
    end
end