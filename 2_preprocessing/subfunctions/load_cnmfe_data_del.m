
function [neuron,saveDir,Coor_prev,directory]= load_cnmfe_data(directory,filename,imouse,sessions,opt)

directory.mouse_list= GetSubDirsFirstLevelOnly(directory.parentDir);
directory.session_list = GetSubDirsFirstLevelOnly(fullfile(directory.parentDir,directory.mouse_list{imouse}));

% re-create Sources2D obj
neuron= Sources2D;
for isession= sessions
    folder= fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{isession},[filename.data_session_cnmfe(1:end-4) '_source_extraction']);
    if length(sessions)>1
        saveDir{isession}=folder;
    else
        saveDir= folder;
    end
    % load session data
    if opt.curated
        dat= load(fullfile(folder,filename.cnmfe_results_curated));
    else
        dat= load(fullfile(folder,filename.cnmfe_results));
    end
    % assign each field
    fields= fieldnames(dat.S);
    for ifield= 1:length(fields)
        if length(sessions)>1
            neuron(isession).(fields{ifield})= dat.S.(fields{ifield});
        else
            neuron.(fields{ifield})= dat.S.(fields{ifield});
        end
    end
    Coor_prev= neuron(isession).Coor; % save
end
