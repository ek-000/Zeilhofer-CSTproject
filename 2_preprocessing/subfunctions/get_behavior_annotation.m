function behavior= get_behavior_annotation(directory,filename,nrepeats)


% get behavior annotation from .xlsx file
    % collect timestamps from .xlsx sheet
    % get camera timestamps from .xlsx sheet
    camera_ts= readmatrix(fullfile(directory.test, directory.behavior_movies, filename.timestamps_camera));
    % get behavior notes from .xlsx sheet
    behavior_table = readtable(fullfile(directory.test, filename.behavior));
    if isempty(nrepeats)
        trials= 1:size(table2struct(behavior_table),1);
    else
        trials= 1:nrepeats;
    end
    % restrict to a certain number of trials
    behavior_table= behavior_table(trials,:); 
    % convert to struct
    behavior= table2struct(behavior_table,'ToScalar',true);
    % find camera timestamps for stimulation start
    stim_start_sec= camera_ts(behavior.stimulus_start_cameraFrame,2) /1000; % convert to sec
    behavior.stim_start_sec= stim_start_sec; % add to struct