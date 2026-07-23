function stim= enter_info(stim,folder,filename)





stim.session.freezing=      2:4; % 2:4
stim.session.conditioning=  1:4;
stim.session.US=            2:4;
stim.session.CS=            1:3;
stim.session.sensoryStim=   5:6;
stim.session.motion_US=     stim.session.US;
stim.session.motion_CS=     stim.session.CS;
stim.session.nostim=        1:3;
stim.session.loco=          1;

if contains(folder.parentDir{1}, 'behavior only')
    stim.session.conditioning=  1:3;
    stim.session.freezing=      1:3; 
    stim.session.US=            2:4; % 2, 2:4
    stim.session.sensoryStim=   [];
end


if contains(folder.parentDir{1},'fullcond_S1_CST_HM4Di_behavior only') || contains(folder.parentDir{1},'SD052_fullcond_S1_CST_ChR2_behavior only and optogenetics')
    stim.session.conditioning=  1:5;
    stim.session.US=            [2 4 5];
    stim.session.freezing=      1:3;
    stim.session.CS=            1:5;
    stim.session.sensoryStim=   [];
    stim.session.motion_US=     stim.session.US;
    stim.session.motion_CS=     stim.session.CS;
    stim.session.nostim=        1:3;
    stim.session.loco=          1;
    stim.session.session_labels= {'hab','cond','ret','fullcond1','fullcond2'};

elseif  contains(folder.parentDir{1},'fullcond_S1_CST_miniscope_behavior')
    stim.session.conditioning=  1:3;
    stim.session.freezing=      stim.session.conditioning;
    stim.session.CS=            1:3;
    stim.session.motion_CS=     stim.session.CS;
    stim.session.US=            2;
    stim.session.motion_US=     stim.session.US;
    stim.session.loco=          1:3;
    stim.session.sensoryStim=   4;
    stim.session.session_labels= {'hab','cond','ret','SensoryStim'};
end


if contains(folder.parentDir{1},'fullcond')
    % fullcond trials types
    % load stimuli from .txt file
    trialD= xlsread(fullfile(folder.stimpath, filename.fullcond_stimuli));
    beh.trialD= trialD(:,1);
    beh.opto_CS_trialIDs= find(trialD(:,2)==1); % 40>35, compare to trials 5 6 7
    beh.opto_US_trialIDs= find(trialD(:,3)==1); % 50, compare to trials 2 3 4 5 6 7
    beh.ntrial= length(beh.trialD); % number of trials
    % info: stimuli trials types
    beh.info.trialD= {
        'trialD 1: tone',...                    % 30  5>0 0
        'trialD 2:        light int.0.5',...    % 10  0   5
        'trialD 3:        light int.1',...      % 10  0   5
        'trialD 4:        light int.1.5',...    % 10  0   5
        'trialD 5: tone + light int.0.5',...    % 10  5   5
        'trialD 6: tone + light int.1',...      % 50  25  25
        'trialD 7: tone + light int.1.5',...    % 10  5   5
        'trialD 8: tone + light int.1 subset',... % 10  nan nan
        'trialD 9: tone + opto',... % 40>35
        'trialD 10: light + opto'}; % 50

    % trial ID for each trial type
    beh.tone.trialD=     [1           5  6  7];
    beh.US.trialD=       [   2  3  4  5  6  7];
    beh.US.trialD_low=   [   2        5      ];
    beh.US.trialD_med=   [      3        6   ];
    beh.US.trialD_hig=   [         4        7];
    % trial number for each trial type
    beh.tone.stimuli=       find(beh.trialD==1 | beh.trialD==5 | beh.trialD==6 | beh.trialD==7);
    beh.toneonly.stimuli=   find(beh.trialD==1);
    beh.US.stimuli=         find(beh.trialD> 1);
    beh.US.stimuli_low=     find(beh.trialD==2 | beh.trialD==5);
    beh.US.stimuli_med=     find(beh.trialD==3 | beh.trialD==6);
    beh.US.stimuli_hig=     find(beh.trialD==4 | beh.trialD==7);
    beh.toneUS.stimuli=     find(beh.trialD==5 | beh.trialD==6 | beh.trialD==7);
    sub= find(beh.trialD==6);
    sub= sub(2:5:length(sub));
    stim.session.fullcond= beh; % append struct

    % CS only trials
    all_CStrials= beh.tone.stimuli;
    [CStrials,trial_ind]= sort(all_CStrials);
    trial_ind(ismember(CStrials,beh.toneonly.stimuli))  =1;
    trial_ind(~ismember(CStrials,beh.toneonly.stimuli)) =0;
    beh.opto_CS_trialIDs(ismember(beh.opto_CS_trialIDs, beh.toneonly.stimuli))= []; % remove tone onely opto trials (5)
    stim.session.fullcond.CS_trials_only= trial_ind; % append

    % CS trials categories
    CS_trials_cat= zeros(length(trial_ind),1); % reinitialize
    CS_trials_cat(ismember(CStrials,find(beh.trialD==1)))=      1;
    CS_trials_cat(ismember(CStrials,find(beh.trialD==5)))=      5;
    CS_trials_cat(ismember(CStrials,find(beh.trialD==6)))=      6;
    CS_trials_cat(ismember(CStrials,find(beh.trialD==7)))=      7;
    stim.session.fullcond.CS_trials_cat=  CS_trials_cat; % append

    % US intensity
    % make cell with US intensity 1, 2 or 3 (low, medium and high)
    all_UStrials= [beh.US.stimuli_low ; beh.US.stimuli_med;  beh.US.stimuli_hig];
    [UStrials,trial_int]= sort(all_UStrials);
    trial_int(ismember(UStrials,beh.US.stimuli_low))=1;
    trial_int(ismember(UStrials,beh.US.stimuli_med))=2;
    trial_int(ismember(UStrials,beh.US.stimuli_hig))=3;
    % replace values 1, 2 and 3 by 'l', 'm' or 'h'
    strcell= num2cell(trial_int);
    strcell( cellfun(@(c) c==1,strcell) )={'l'};
    strcell( cellfun(@(c) c==2,strcell) )={'m'};
    strcell( cellfun(@(c) c==3,strcell) )={'h'};
    stim.session.USintensityLabel= strcell'; % append
    % US trials categories (a bit of the same thing as above)
    US_trials_cat= zeros(length(trial_int),1); % reinitialize
    US_trials_cat(ismember(UStrials,find(beh.trialD==2)))=      2;
    US_trials_cat(ismember(UStrials,find(beh.trialD==3)))=      3;
    US_trials_cat(ismember(UStrials,find(beh.trialD==4)))=      4;
    US_trials_cat(ismember(UStrials,find(beh.trialD==5)))=      5;
    US_trials_cat(ismember(UStrials,find(beh.trialD==6)))=      6;
    US_trials_cat(ismember(UStrials,find(beh.trialD==7)))=      7;
    if contains(folder.parentDir{1},'fullcond_S1_CST_HM4Di_behavior only')
        US_trials_cat(ismember(UStrials,sub))=                  8; % subset of 6, length= 10 to compare
    elseif contains(folder.parentDir{1},'SD052_fullcond_S1_CST_ChR2_behavior only and optogenetics')
         US_trials_cat(ismember(UStrials,sub))=                  8; % subset of 6, length= 10 to compare
%         US_trials_cat(ismember(UStrials,beh.opto_CS_trialIDs))=     9; % opto during CS, replaces half corresponding trials
%            US_trials_cat(ismember(UStrials,beh.opto_US_trialIDs))=     10; % opto during US, replaces half corresponding trials
    end
    stim.session.fullcond.US_trials_cat=  US_trials_cat; % append

else
    % US intensity
    stim.session.USintensityLabel=... % 'l': low intensity US, 'm': medium, 'h': high
        {'m','m','m','m','m','m','m','m','m','m';...
        'm','m','m','m','l','l','h','l','h','h';...
        'm','m','m','m','l','l','h','l','h','h'};
end

% sensory test session
if contains(folder.parentDir{1},'fullcond')
    % Sensory test info
    % get tests names
    stim.names= {'vf 002 L','vf 007 L','vf 016 L','vf 04 L','vf 06 L','vf 1 L','Formalin L'};
    % von Frey
    vf.g= [0.02 0.07 0.16 0.4 0.6 1]; % von Frey filaments strength (g)
    vf.label= {'0.02','0.07','0.16','0.4','0.6','1','2'}; % von Frey filaments strength (g)
else
    stim.session.session_labels= {'hab','cond','condvar','unsi','baseline', 'CCI'};
    % Sensory test info
    % get tests names
    stim.names= {'spont','brush L','brush R','vf 002 L','vf 002 R','vf 007 L','vf 007 R','vf 04 L','vf 04 R','vf 1 L','vf 1 R','vf 2 L',...
        'vf 2 R','vf auto L','vf auto R','pinprik L','pinprik R','fake L','fake R','hot L','hot R','cold L','cold R','blue L','blue R'};
    % von Frey
    vf.g= [0.02 0.07 0.4 1 2]; % von Frey filaments strength (g)
    vf.label= {'0.02','0.07','0.4','1','2'}; % von Frey filaments strength (g)
end
% get test side (right or left hindpaw)
stim.session.sessioncols= {[52, 235, 55]/255,[235, 125, 52]/255,[235, 52, 52]/255,[52, 70, 235]/255,'k','r'};
stim.labels= {'L','R'};
stim.side= {find(contains(stim.names,'L')), find(contains(stim.names,'R'))};
stim.noxious.testIds=    find(contains(stim.names,{'pinprik','hot','blue'}));
stim.innocuous.testIds=  find(contains(stim.names,{'brush','vf 002','vf 007','vf 04','vf 1','vf 2','cold'}));
vf.trials= find( contains(stim.names,'vf') & ~contains(stim.names,'auto') ); %  VF trials numbers except auto vf
vf.trials_auto= find( contains(stim.names,'vf') & contains(stim.names,'auto') ); %  VF trials auto
vf.trials_per_side= { vf.trials(ismember(vf.trials,stim.side{1})),vf.trials(ismember(vf.trials,stim.side{2})) }; % VF trials left and right
stim.vf= vf; % append
