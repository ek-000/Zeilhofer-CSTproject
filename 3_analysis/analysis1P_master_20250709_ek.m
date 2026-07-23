% safety check: make sure we REALLY want to run script
% prompt = 'Are we REALLY doing it? (y/n): ';
% if strcmp(input(prompt,'s'),'y'); fprintf('\n here we go \n'), else, error('cancelled'); end
clc, clear, close all, warning off % start fresh

% Define directories
% folder.parentDir{1}=  'K:\z_Simon\data\SD023-025-027_CaMKII-GCaMP8m_S1_miniscope_cond_sens_CCI';
% folder.parentDir{2}=  'K:\z_Simon\data\SD018-029-031_DIO-hSyn-GCaMP8m_S1_miniscope_cond_sens_CCI_PNs';
% folder.parentDir{1}=      'K:\z_Simon\data\SD021-030_opto-conditioning behavior only\SNS-ChR2_Cre-negative';
% folder.parentDir{2}=      'K:\z_Simon\data\SD021-030_opto-conditioning behavior only\SNS-ChR2_Cre-positive';
% folder.parentDir{1}=            'K:\z_Simon\data\SD040_TetxLC_S1-CST_behavior only\conditioning beh\GFP control';
% folder.parentDir{2}=            'K:\z_Simon\data\SD040_TetxLC_S1-CST_behavior only\conditioning beh\TeTxLC';
% folder.parentDir{1}=            'K:\z_Simon\data\SD047_fullcond_S1_CST_miniscope_behavior';
% folder.parentDir{1}=    'K:\z_Simon\data\SD051_fullcond_S1_CST_HM4Di_behavior only';
% folder.parentDir{1}=    'K:\z_Simon\data\SD052_fullcond_S1_CST_ChR2_behavior only and optogenetics';
% folder.parentDir{1}=    'K:\z_Simon\data\SD056_fullcond_S1_CST_HM4Di_behavior only\mCherry control';
% folder.parentDir{2}=    'K:\z_Simon\data\SD056_fullcond_S1_CST_HM4Di_behavior only\HM4Di';
folder.parentDir{1}=    'K:\z_Simon\data\SD066_fullcond_S1_CST_HM4Di_behavior only';


groupName= {'vehicle', 'CNO'}; % {'all_cells','CST'}; {'cre neg','cre pos'} {'TeTxLC','GFP'}, {'all_cells'} {'vehicle', 'CNO'};
groups= 1:length(folder.parentDir);

% saving directory (results saved there)
for igroup= groups
    folder.figDir{igroup}= fullfile(folder.parentDir{igroup},'results'); mkdir(folder.figDir{igroup});
end

% codes directory
folder.codeDir= 'K:\z_Simon\codes'; % where codes are  %%% codeDir = 'mypath\codes';
addpath(genpath(folder.codeDir));
rmpath(genpath('K:\z_Simon\codes\Simon\1-photon\3_analysis\old')); % add codes, but remove old versions from path (only latest version available)

% filenames
filename.session_info=          'session_info.mat'; % in folder.parentDir
filename.motion=                'motion.mat'; % for conditioning sessions only
filename.freezing=              'behavior.mat'; % for conditioning sessions only
filename.session_data_cnmfe=    'session_stack_source_extraction'; % CNMFE results folder name (in folder.parentDir)
filename.cnmfe_results_curated= 'cnmfe_results_curated_global.mat'; % in CNMFE results folder: 'cnmfe_results.mat', 'cnmfe_results_curated.mat', 'cnmfe_results_curated_global.mat'
filename.fullcond_stimuli=      'fullcond_stimuli.xlsx'; % list of stimuli types (IDs)
folder.stimpath=                'K:\z_Simon\codes\Simon\1-photon\1_behavior\acquisition\fullcond2'; addpath(folder.stimpath)


for igroup= groups
    stim.group= igroup;
    % data to load
    stim.mice=         [];  % leave empty for all '[]' or '[1:5]'
    stim.sessions=     [];  % leave empty for all '[]' or e.g '[1:3]'

    %% enter_info
    stim= enter_info(stim,folder,filename);

    %% load_1P_data and info
    clear data
    par.zscore= 1;
    par.dfof=   0;     
        par.dfof_pctile= 5; % percentile trace value ato consider as baseline F0
    par.range= 1:14200; % '1:14200'; % frames range to consider for zscore (does not change data size)
    [stim,data]= load_1P_data(filename,folder,stim,par); %%%%%%%%%%%% out: data(imouse,isession).traces .spikee .motion .info


    %% get_global_cell_ids
    if contains(filename.cnmfe_results_curated,'global') && ~contains(folder.parentDir{stim.group}, 'behavior only')
        stim= get_global_cell_ids(stim,data,folder); %%%%%%%%%%%%%
    else
        stim.session.globalCellsIds=[]; 
    end

    %% Resample_neuronal_activity at theoretical fr
    if ~contains(folder.parentDir{stim.group}, 'behavior only')
    [stim,data]= resample_neuronal_activity(stim,data,folder);
    end

    %% resample_motion
    par.binsize=            1; % seconds
    par.motion_frame_rate=  50; % resample motion at this frame rate, e.g '50', '[]' to skip
    data= resample_motion(data,stim,par,folder,igroup); %%%%%%%%%%%%%%%%%%%%%

    %% bin_spikes
    if ~contains(folder.parentDir{stim.group}, 'behavior only')
    par.binsize= 1; % sec, spikes bin size
    data= bin_spikes(data,stim,par); %%%%%%%%%%
    end

    % append group data
    groupData{igroup}= data; groupStim{igroup}= stim; % append back
end

for igroup= groups
    groupStim{igroup}.groupName= groupName{igroup};
end

%% Freezing
for igroup= groups
    par.group=  igroup; % "1": S1 neurons, "2": S1 CST neurons
    par.merge_groups=   []; % concatenate data (merge mice) from groups e.g '[1 2]'; leave empty '[]' for no 
    par.single_mouse=   0; % plot single mouse motion and freezing detection
    par.freez_thres=    0.25;
    par.remove_session2=0; 
    par.plot=           1;
    par.save=           1;
    par.saveDir=        fullfile(folder.figDir{par.group},'quantify_freezing'); mkdir(par.saveDir)
    groupData{par.group}= quantify_freezing(groupData{par.group},groupStim{par.group},par); %%%%%%%%%%%%
end
    if ~isempty(par.merge_groups)
        quantify_freezing([groupData(par.merge_groups)],[groupStim{par.merge_groups}],par);
    end

%% collect locomotion timestamps
par.Mindist= 300; % 300: 30sec*fr
par.Thresh= 2;
for igroup= groups
    par.group= igroup; % "1": S1 neurons, "2": S1 CST neurons
    for imouse = 1:size(groupData{igroup},1)

        % define sessions
        par.sessions= stim(1).session.conditioning;
        if size(data,2) < length(par.sessions) % if less sessions than conditioning sessions (e.g control conditioning)
            par.sessions= par.sessions(1:size(data,2));
        end

        for isession= par.sessions
            if ~isempty(groupData{igroup}(imouse,isession).motion)
                m= groupData{igroup}(imouse,isession).motion.rs_motion; %binnedMotion
                m= diff(m);
                [~,lk] = findpeaks(m,'MinPeakDistance',par.Mindist,'Threshold',par.Thresh);
                lk(lk<par.Mindist)=[];
                lk(lk>length(m)-par.Mindist)=[];
                %     plot(1:length(m),m,lk,pk,'o')
                %     ylim([0 5])
                % append
                groupData{igroup}(imouse,isession).motion.ts= lk;
                length(lk);
            end
        end
    end
end

%% get_test_data: Collect info and mean responses per test
for igroup= groups
    data= groupData{igroup}; stim= groupStim{igroup}; % distribute
    % parameters
    par.globalCellsIds=         0; % restrict to global cells (found in conditioning sessions)
    par.cell_sort=              0; % sort responses from each cell according to test_order or each test (default= 0, no sort)
    
    par.cell_sort_test=             0; % according to what test to reorder (default= 0, sort each test independently)
    par.cell_sort_maxRespTime=      0; % according to the time of max response
    par.no_withdrawal=          0; % 0: all trials (default); 1: only trials with no reaction; 2: only trials with any reaction
    par.high_fr_motion=         1;  % use par.motion_frame_rate instead of stim.fr
    par.mice=                   stim.mice;

    par.datFields=      {'traces'}; % {'traces', 'spikes'}
    par.stims=          {'CS',      'US',       'freezing', 'sensoryStim',  'motion_CS',    'motion_US',    'nostim',   'loco'}; % {'CS', 'US' ,'freezing', 'sensoryStim'} postion matters, leave empty fields to not process
    par.imagingStim=    [1          1           1           1               0               0               1           1];
    stim.stim_duration= [20         0.05         nan         nan             1               0.05            nan,        nan]; % duration (s) of each stimulus
    par.trials=         {1:10,      1:10,       1:8,        1:5,            1:10,           1:10,           1:5,        1:10}; % {'CS', 'US' ,'freezing', 'sensoryStim','motion_CS','motion_US'
    stim.twin=          {[-5 19.5], [-3 10],    [-5 10],    [-2 10],        [-5 1],         [-0.5 2],       [-5 10],    [-5 10]}; % (s) time window for plot {'CS', 'US' ,'freezing', 'sensoryStim', 'motion'}
    par.baseline=       [5          3           5           2               nan             nan,            5,          5]; % s, FIRST seconds of stim.win (not necessarily right before stimulus onset)
    % note: for US, 2 conditions to be defined as responsive: higher response than baseline (pre-CS) AND higher than same baseline period immediately before US onset
    stim.twin_resp=     {[0 19.5],  [0.5 5.5],  [0 10],     [0 1.5],       [0 1],            [0 1],          [0 5],     [0 5]}; % (s) time window to sort max activity {'CS', 'US' ,'freezing', 'sensoryStim', 'motion'} % US  .5
    par.thres_resp=     [2/3        2/3         2/3         2/3,            -inf,           -inf,           2/3,        2/3 ]; % ['CS', 'US' ,'freezing', 'sensoryStim', 'motion'] threshold for defining as responsive (maximmum z-score within twin_resp)  2/3
    par.pval=           0;
    par.nresptrials=    1;
    par.Pval=           0.000001; % to define cell as responsive 0.000001
    par.minRespTrials=  [4          4           4           2,              0,              0,              4,          4]; % 4 20 or 4(fullcond) 4  2 0 0 4 4
    par.nLongestFreezEpisodes= par.trials{3}(end); % take only the x longer freezing episodes

    stim= get_test_data(par,data,stim,folder); %%%%%%%%%%%%%

    % if no data, resplace withdrawal values with nans
%     if ~contains(folder.parentDir{1}, 'behavior only')
%         stim.sensoryStim.withdrawal{5} (sum(stim.sensoryStim.withdrawal{5},2)==0, :)= nan;
%     end
        groupData{igroup}= data; groupStim{igroup}= stim; % append back
    clear data stim igroup
end
fprintf('\ndone\n')

%%
        error('code ready')

%% plot_response_per_trial
% US baseline before CS
% merge and per mouse does not work
for igroup= groups
    par.group=   igroup; % "1": S1 neurons, "2": S1 CST neurons
    par.stim=    'motion_US'; % 'CS', 'US' ,'freezing', 'motion_CS', 'motion_US', 'nostim','loco'
    par.save=                   1;
    % Neuronal response selection (mutually exclusive)
    par.high_fidelity_cells=    0; % '0' or '1' restrict to cells with responses in at least ntrial (respIds)
    par.thres_topNbTrials=      0; % '0' to not sort: x% cells sorted according to number responsive trials per cell % '10' for CS '20' for US
    par.thres_topRespPerTrial=  0; % '0' to not sort: x% cells sorted according to the integral response per trial (different cells on each trial) %%%%%%%%%%
    par.TotalRespPerTrial=      0; % '0' or '1'; responses of all responsive cells on each trial (different number of cells per trial), not per mouse
    
    % other parameters
    par.merge_groups=           0; % concatenate data (merge mice) from groups 0 or 1
    % y '[]' for no, use for behavior only
    par.per_mouse=              0; % average cells per mouse in single sessions and per mouse (instead of per trial) to compare sessions
    par.mice=                     []; % default '[]', mouse number to include 
    par.acceleration=           0; % consider acceleration instead of velocity and integral motion
    par.max=                    0; % consider maximum (locomotion or acceleration)
    par.time_to_max=            0; % latency            
    par.per_US_intensity=       {} ; % default '{}' or {'l','m','h'} for all, NEEDS par.trials=[] ; par.session_compare = '3' or '4'; par.stim= 'US' or 'motion_US'
    par.session_compare=        [5]; % [] for all sessions   
    par.UStrial_compare=        {[2, 3, 4],[5, 8, 7]}; % needs only one session_compare, fullcond, info: "groupStim{1}.session.fullcond.info.trialD{:}" only US vs US and CS  [2 3 4],[5 8 7] 
    % for SD052, compare opto vs no opto during tone: session 4  trial 9 vs 5:7 ; for light session 5 trial 10 vs 2:7, set which one in enter_info
    par.ylim_plot=              [0 60]; % -0.1 0.85 150
    par.ylim_whisker=           [0 3500]; % -0.1 0.85 40000
    par.CS_trials_only=         0; % needs fullcond and session_compare empty
    par.trial=                  []; % default emtpy '[]' for all, otherwise e.g [1:4] low intensity [5 6 8] medium intensity [1 2 3 4] high intensity [7 9 10]
    par.CS_US_cells_only=       0; % needs Venn! only CS and US responsive cells on cond and condvar sessions
    par.CS_US_cells_excluded=   0; % needs Venn! ignore CS and US responsive cells on cond and condvar sessions
    par.filt=                   [2 0 5 5 2 0 2 2]; % acceleration 8 % response smoothening  'CS', 'US', 'freezing', 'sensoryStim',  'motion_CS', 'motion_US',  'nostim', loco' ('0' for no filtering)
    par.cols= {1-hot(130), flipud(hot(130)), flipud(pink(130)),  flipud(hot(130)),  flipud(bone(130)), flipud(bone(130)), flipud(bone(130)), flipud(bone(130))}; % colormap 'CS', 'US' ,'freezing', 'motion_CS', 'motion_US'
    par.saveDir=                fullfile(folder.figDir{par.group},'Plot response per trial',par.stim); mkdir(par.saveDir)
    par.saveDir
    if ~par.merge_groups
        [dat,means]= plot_response_per_trial(groupStim{par.group},par); %%%%%%%%%%%%%%%%%%%%%
    else
        [dat,means]= plot_response_per_trial([groupStim{[1 2]}],par); %%%%%%%%%%%%%%%%%%%%%
    end
end

% intensity compare:
% per mouse: cannot compare behavior and neuronal activity (top 20% )
% merge groups: cannot compare behavior and neuronal activity (merge cells between groups)
% merge group= 0
% per_mouse= 0

%% Imagesc_mean_resp_per_test (or session)
for igroup= 1
    par.stim=                   'motion_US'; % 'CS', 'US' ,'freezing', 'sensoryStim', 'motion_CS', 'motion_US', 'nostim', 'loco'
    par.group=                  igroup; % "1": S1 neurons, "2": S1 CST neurons
    par.sort_session=           0; % session to sort cells if par.globalCellsIds=1 and par.cell_sort=1; default '0'
    par.CS_US_cells_only=       0; % needs Venn! only CS and US responsive cells on cond and condvar sessions, needs par.stim='US'
    par.CS_US_cells_excluded=   0; % needs Venn! ignore CS and US responsive cells on cond and condvar sessions
    par.caxis=      [1.5,3,2,2,10,100,2,2]; % zscore colormap color limits [-par.caxis par.caxis] 0.7,1,2,2,10,100,2,2
    par.datFields=  'traces';
    par.save=       1; % save figure in saveDir
%     par.saveDir=    fullfile(folder.figDir{par.group},'imagesc mean response per test',par.stim); mkdir(par.saveDir)
    imagesc_mean_resp_per_test(groupData{par.group},groupStim{par.group},par) %%%%%%%%%%%%%
end


%% Response_properties_per_trial
par.stim= 'US'; % 'CS','US','freezing', 'nostim'
for igroup= 1%groups
    par.group= igroup; % "1": S1 neurons, "2": S1 CST neurons
    par.trial= []
    par.save= 0;
    par.saveDir= fullfile(folder.figDir{par.group},'response properties per trial',par.stim); mkdir(par.saveDir)
    response_properties_per_trial(groupStim{par.group},par) %%%%%%%%%%%%%%%%%%%%%%%%
end

%% Number_responsive_trials_per_cell
par.stim= 'freezing'; % 'CS','US','freezing'
for igroup= groups
    par.group= igroup;
    par.save= 1;
    par.saveDir= fullfile(folder.figDir{par.group},'Number responsive trials per cell',par.stim); mkdir(par.saveDir)
    Number_responsive_trials_per_cell(groupStim{par.group},par) %%%%%%%%%%%%%%%%%%%%%%%
end

%% single_trial_CSUS_response_overlap_per_mouse (+ single trial CS-US amplitude correlation) not good
% Q: Are CS-responsive cells more likely to be US-responsive? overlap CS-responsive or CS-unresponsive and US-responsive cells 
% for each trial take all CS resp / non resp cell Ids
% percent overlap with US resp cell Ids over number of CS resp / non resp
for igroup= 1
    par.group=      igroup;
    par.sess=        2 % default [2:3]: CS-US sessions
    par.trials=     {1:10, 1:10}; % comparable trials (same intensity): [1:4]
    par.xlim=       [-800 800];
    par.ylim=       [-200 200];    
    par.save=       1; % save figure in saveDir
    par.saveDir=    fullfile(folder.figDir{par.group},'single trial CSUS response overlap'); mkdir(par.saveDir)
    single_trial_CSUS_response_overlap_per_mouse(groupStim{par.group},par); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

%% Venn_CSUS
for igroup= 1
    par.group=      igroup; % "1": S1 neurons, "2": S1 CST neurons
    par.save=       0;
    par.saveDir=    fullfile(folder.figDir{par.group},'Venn responsive cells cond vs condvar'); mkdir(par.saveDir)
    groupStim{par.group}= venn_CSUS(groupStim{par.group},par); %%%%%%%%%%%%%%
end

%% Venn_US_intensity
for igroup= 1%groups
    par.group=          igroup; % "1": S1 neurons, "2": S1 CST neurons
    par.minRespTrial=   4; % of 10 trials, 3
    par.UStrials=       [5 8 7]; % 2 3 4 ; 5 8 7
    par.session=        [2]; % [3 4]
    
    par.transparency=   [0.6 0.6 0.6]; % per session: preCCI, postCCI
    par.cols=           {'r',[0.8500 0.3250 0.0980],'y'}; % noxious, innocuous, all
    par.save=           1; % save figure in saveDir
    par.saveDir=        fullfile(folder.figDir{par.group},'Venn_CS_US_response_stability'); mkdir(par.saveDir)
    Venn_US_intensity(groupStim{par.group},par) %%%%%%%%%%%%%%%%%%%%%%%%
end

%% Neuronal_behavioral_single_trial_correlation
% correlation between neuronal response integral per cell and behavior, per trial
for igroup= 1
    par.group= igroup;
    par.high_fidelity_cells_only=   1;
    par.sort_stim=                      'US'; % 'CS','US' (par.high_fidelity_cells_only)
    par.thres_topRespPerTrial=          20; % x% cells sorted according to number responsive trials per cell (par.high_fidelity_cells_only)
    par.average_cells=                  1; % mean of high fidelity cells over trial 
    par.session=                    []; % merge session data 
    par.trials=                     [];   
    par.save=                       0; % save figure in saveDir
    par.saveDir=                    fullfile(folder.figDir{par.group},'Neuronal behavioral single trial correlation'); mkdir(par.saveDir)
    Neuronal_behavioral_single_trial_correlation(groupStim{par.group},par); %%%%%%%%%%%%%%%%%%%%
end

%% Venn_CS_US_response_stability (needs global cells)
% NOTE: needs global cells: par.globalCellsIds in get_test_data
for igroup= 1
    par.group=          igroup; % "1": S1 neurons, "2": S1 CST neurons
    par.stim=           {groupStim{par.group}.session.CS, groupStim{par.group}.session.US};
    par.transparency=   [0.6 0.6 0.6]; % per session: preCCI, postCCI
    par.CSUS=           0;
    par.save=           0 % save figure in saveDir
    par.saveDir=        fullfile(folder.figDir{par.group},'Venn_CS_US_response_stability'); mkdir(par.saveDir)
    Venn_CS_US_response_stability(groupStim{par.group},par,folder); %%%%%%%%%%%%%%%%%%%%%%
end

%% neuronal_activity_locomotion_correlation_during_CS
% CS responsive cell ids per session (1:3)
% CS resp and CS unresp cells activity during CS per cell per session per mouse
% CS motion per mouse per session 
for igroup= groups
    par.group=              igroup; % "1": S1 neurons, "2": S1 CST neurons
    par.binsize=            1; % second
    par.datFields=          'traces'; % 'traces' or 'spikes'
    par.response_selection= 'high fidelity'; % 'high fidelity' or 'trial resp'
    par.save=               1; % save figure in saveDir
    par.saveDir=            fullfile(folder.figDir{par.group},'neuronal_activity_locomotion_correlation_during_CS'); mkdir(par.saveDir)
    neuronal_activity_locomotion_correlation_during_CS(groupStim{par.group},par); %%%%%%%%%%%%%%%%%%%%%
end

%% global cells CS US response correlation on different days
% are US-responsive cells more likely to develop a CS response?
for igroup= 1%groups
    par.group=              igroup; % "1": S1 neurons, "2": S1 CST neurons
    par.response_selection= 'integral response'; % 'integral response' or 'number of responsive trials'
    par.xdata=              'US day2'; % 'US day2' or 'US day3' or 'CS day1', CS day2, CS day3' or 'CS day2 - CS day1', 'CS day3 - CS day1', 'CS day3 - CS day2'
    par.ydata=              'CS day3'; % 'US day2' or 'US day3' or 'CS day1', CS day2, CS day3' or 'CS day2 - CS day1', 'CS day3 - CS day1', 'CS day3 - CS day2'
    
    par.xlim= [-2 4 ]; %     par.xlim= [-0.4 0.8];
    par.ylim= [-1.5 1.5];   %     par.ylim= [-1 1.2];                                                                           
    
    par.save=               1; % save figure in saveDir
    par.saveDir=            fullfile(folder.figDir{par.group},'global_cells_CS_US_response_correlation_on_different_days'); mkdir(par.saveDir)
    global_cells_CS_US_response_correlation_on_different_days(groupStim{par.group},par,folder); %%%%%%%%%%%%%%%%%%%%%%%
end










%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SensoryStim from there %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%




%% plot_test_response
% only for sensory stim
% parameters
par.group=                  1; % "1": S1 neurons, "2": S1 CST neurons
par.session=                4; % default '[5 6]'
par.pos_response=           0;  % '0', all neurons, '1': neurons with response above baseline, '2': below
par.thres_topNbTrials=      0; % '0' to not sort: x% cells sorted according to number responsive trials per cell % 10 (gr1)
par.thres_topRespPerTest=   0; % '0' to not sort: x% cells sorted according to the mean integral response per test (different cells on each trial) % 20 (gr2)

par.save=                   1;
par.saveDir=                fullfile(folder.figDir{par.group},'plot_test_response'); mkdir(par.saveDir)
plot_test_response(groupStim{par.group},par); %%%%%%%%%%%
% add option to sort by top % cells with max. number of responsive trials

%% sig_fit_mech_sens
% plots Von Frey (auto and manual) withdrawal thresholds (g)
for igroup= 1
    par.group=      igroup; % "1": S1 neurons, "2": S1 CST neurons
    par.session=    'sensoryStim';
    par.paw=        'left'; % 'left' (CCI) or 'right' (unaffected)
    par.noXscale=   0;
    par.save=       1;
    par.saveDir=    fullfile(folder.figDir{par.group},'sig_fit_mech_sens'); mkdir(par.saveDir)
    sig_fit_mech_sens(par,groupStim{par.group}); %%%%%%%%%%%%%%
end

%% VonFrey_auto
par.group=          1; % "1": S1 neurons, "2": S1 CST neurons
par.stim=        'sensoryStim'; % 'sensoryStim', just for info
par.marker_alpha=   0.5; % 0 to 1, transparency of boxplot markers. '0' for no visible markers
par.save=           1;
par.saveDir=        fullfile(folder.figDir{par.group},'VonFrey_auto'); mkdir(par.saveDir)
VonFrey_auto(groupData{par.group},groupStim{par.group},par); %%%%%%%%%%%%%%


%% Venn_nox_inno
for igroup= 1
    par.group=          igroup; % "1": S1 neurons, "2": S1 CST neurons
    par.stim=        'sensoryStim'; % 'sensoryStim', just for info
    par.transparency=   [0.6 0.6]; % per session: preCCI, postCCI
    par.cols=           {'r','g',0.65*[1 1 1]}; % noxious, innocuous, all
    par.save=           1;
    par.saveDir=        fullfile(folder.figDir{par.group},'Venn_nox_inno'); mkdir(par.saveDir)
    venn_nox_inno(groupStim{par.group},par); %%%%%%%%%%%%%%%%%%%%%
end



%% plot imagesc stimuli_correlation
for igroup= 1
    par.group=      igroup; % "1": S1 neurons, "2": S1 CST neurons
    par.stim=       'sensoryStim'; % only 'sensoryStim'
    par.side=       'L'; % 'R' or 'L'
    par.diff=       1; % difference between session 5 and 6 (post minus pre-CCI)
    par.cax=        'user-defined'; % color axis 'zero-max', 'min-max', 'user-defined'
    par.caxi=       [-5 5]; % color axis if par.cax= 'user-defined'
    par.name=       'response per trial';
    par.save=       1;
    par.saveDir= fullfile(folder.figDir{par.group},'stimuli_correlation'); mkdir(par.saveDir)
    stimuli_correlation(groupStim{par.group},par); %%%%%%%%%%%%%%%%
end



%% plot single_cell_test_response_comparison imagesc scatter
for igroup= 1
    stim=           groupStim{par.group};
    par.group=      igroup; % "1": S1 neurons, "2": S1 CST neurons
    par.session=    4;
    opt.imagesc=    1; 
    par.colaxis=        0.2; % stretch visualization 
    par.tests=          1:7; %2:2:24; 
    opt.scatter=    0;
    par.test_compare=   {[2 3],[2 7],[3 7]}; % what test numbers to compare single cell, stim time window: -2 1.5s
    par.save=       1   ;
    par.saveDir= fullfile(folder.figDir{par.group},'single_cell_test_response_comparison'); mkdir(par.saveDir)
    P= single_cell_test_response_comparison(stim,par,opt); %%%%%%%%%%%%%%%%
end


%% plot bar spontaneous_firing_frequency
par.group=              1; % "1": S1 neurons, "2": S1 CST neurons
par.spontaneous.time=   900; % seconds spontaneous activity
par.session=            [5 6]; % only 'sensoryStim'
par.norm=               1; % normalize values to pre-CCI, des not work per mouse (different cells on different sessions)
par.per_mouse=          1; % '0': per cells, '1'; per mouse
par.marker_alpha=       0; % 0 to 1, transparency of boxplot markers. '0' for no visible markers
par.save=               0;
par.saveDir=            fullfile(folder.figDir{par.group},'spontaneous_firing_frequency'); mkdir(par.saveDir)
spontaneous_firing_frequency(groupData{par.group},groupStim{par.group},par); %%%%%%%%%%%%%


%% plot_session_traces (+ spikes and motion)
% red trace: trials with light only; gray trace: trials with tone
% edit changes as exeptions in "resample_motion"
par.group=                  1; % "1": S1 neurons, "2": S1 CST neurons
par.mouse=                  5;
par.session=                4;

par.dropped_frames_nb=      0;
par.added_frames=           0;


par.save=           0;
opt.motion_only=    1;

par.plot_selec= 0; % separate plot within range
par.cellRange=      1:50; % cells %% add option for all
par.timeRange=      1:40000; % frames  %% add option for all
par.saveDir= fullfile(folder.figDir{par.group},'plot_session_traces'); mkdir(par.saveDir)
% display
par.spike_motion_correlation=   0;
par.show_spikes_on_traces=      0;
par.space=                      6; % plot space between traces (zscore)
plot_session_traces(groupData{par.group},groupStim{par.group},par,opt) %%%%%%%%%%


%% plot_motion_path
for igroup= groups
    par.group=                      igroup; % "1": S1 neurons, "2": S1 CST neurons
    par.session=                    groupStim{igroup}.session.conditioning; % stim.session.conditioning ([1 2 3 4])
    par.save=                       1;
    par.compare_motion=             1;
    par.compare_total_motion=       1;
    par.total_motion_sessions=        [4 5]; % 2 sessions to compare
    par.plot_path=                  1;
    par.plot_center_corner_ratio=   1;
    par.saveDir=                    fullfile(folder.figDir{par.group},'plot_motion_path'); mkdir(par.saveDir)
    [groupStim{igroup}.mean_speed, groupStim{igroup}.total_motion]=   plot_motion_path(groupData{par.group},groupStim{par.group},par); %%%%%%%%%%%%
    if igroup==2 && par.compare_motion
        compare_motion
    end
end


%% get_activity_motion_corr
for igroup= groups
    par.group=  igroup; % "1": S1 neurons, "2": S1 CST neurons
    par.plot_path= 1; % individual plots
    par.plot_center_corner_ratio= 0;
    par.freez= 'all'; % freezing period to consider 'CS' or 'all'
    get_activity_motion_corr(groupData{par.group},groupStim{par.group},par);
end


% %%
% for isession=1:4
%     figure;
%     dim1= squeeze(binnedMotion(:,isession,:))
%     dim2= squeeze(binnedSpikes(:,isession,:));
%     scatter(dim1(:),dim2(:))
% end

%% motion track
clc
igroup=     1;
imouse=     1
isession=   1;
twin= [-0 2]; % sec

data= groupData{igroup};
stim= groupStim{igroup};
dat= data(imouse,isession).motion.centroid; % get centroid position
ts= data(imouse,isession).info.timestamps{2};

plotwin= 1+twin(1)*stim.fr : twin(2)*stim.fr;

% plot
plotdat= data(imouse,isession).motion.rs_centroid;
scatter(plotdat(1,:),plotdat(2,:),'.','k'); hold on;


for istim=1:length(ts)
stimfr= round(ts(istim)*stim.fr) + plotwin;
stimpos= data(imouse,isession).motion.rs_centroid(:,stimfr);
figure; scatter(stimpos(1,:),stimpos(2,:),'.','r'); hold on
title(num2str(istim))
xlim([0 450])
ylim([0 450])
end

%% Fisher test statistics
% all S1 overlap pairing 1 and 2 
[~,p] = fishertest([round(724*0.249) 724 ; round(769*0.285) 769]) % light
[~,p] = fishertest([round(724*0.080) 724 ; round(769*0.137) 769]) % tone
[~,p] = fishertest([round(724*0.018) 724 ; round(769*0.043) 769]) % tone+light

% all S1 overlap light-responsive global neurons
[~,p] = fishertest([round(259*0.212) 259 ; round(259*0.174) 259]) % Pairing1-Pairing2 vs Pairing1-Unsignaled
[~,p] = fishertest([round(259*0.212) 259 ; round(259*0.189) 259]) % Pairing1-Pairing2 vs Pairing2-Unsignaled 
[~,p] = fishertest([round(259*0.174) 259 ; round(259*0.189) 259]) % Pairing1-Unsignaled vs Pairing2-Unsignaled 

% all S1 overlap tone-responsive global neurons
[~,p] = fishertest([round(259*0.017) 259 ; round(259*0.009) 259]) % Pre.-Pairing1 vs Pre.-Pairing2
[~,p] = fishertest([round(259*0.017) 259 ; round(259*0.029) 259]) % Pre.-Pairing1 vs Pairing1-Pairing2 
[~,p] = fishertest([round(259*0.009) 259 ; round(259*0.029) 259]) % Pre.-Pairing2 vs Pairing1-Pairing2 

% CSNs overlap
[~,p] = fishertest([round(153*0.027) 153 ; round(153*0.079) 153]) % Pre.Tone-Pairing.Light vs Post.Tone-Pairing.Light

%% SD059
par.saveDir= 'K:\z_Simon\LNB\SD059 NO EFFECT 20240125 behavior 5 Phox2a-GCaMP6f AAV flp-GFP v149r sc + 5 frt-HM3Dq-mChrerry  v190-9 or 5 control AAV frt-mCherry v188-9 S1\matlab figures';
clear name; name{1}=  'Percent phox2a+ cfos+ of all phox2a+ [supperficial (LI/II)] stim vs no stim side'
dat= {[38 59	58	50	67	43	53	52	59	59],[14	6	0	0	0	17	11	6	23	15]}
[str]= SD_ttest(dat{1},dat{2})
figure; boxplots(dat); ylim([0 100])
name{2}= str{1};
name{3}= str{2};
title(name,'fontsize',10)
SD_save('sup', par.saveDir)

clear name; name{1}=  'Percent phox2a+ cfos+ of all phox2a+ [supperficial (LI/II)] stim vs no stim side'
dat= {[50 74	74	82	59	59	59	58	65	75], [25	23	0	5	43	11	10	7	22	23]}
[str]= SD_ttest(dat{1},dat{2})
figure; boxplots(dat); ylim([0 100])
name{2}= str{1};
name{3}= str{2};
title(name,'fontsize',10)
SD_save('deep', par.saveDir)


clear name; name{1}=  'Percent phox2a+ cfos+ of all phox2a+ [supperficial (LI/II)] stim vs no stim side'
dat= {[43	67	65	65	63	51	56	54	61	67], [19	13	0	3	12	15	10	6	23	19]}
[str]= SD_ttest(dat{1},dat{2})
figure; boxplots(dat); ylim([0 100])
name{2}= str{1};
name{3}= str{2};
title(name,'fontsize',10)
SD_save('all', par.saveDir)

% Percent phox2a+ cfos+ on stim side of all phox2a+ cfos+
[mm,ss]= mmss([72	86	100	97	90	81	90	89	90	76])
% mean= 87.10 +/- 2.7546