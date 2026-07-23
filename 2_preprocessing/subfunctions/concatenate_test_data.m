function [session_stack,session_info]= concatenate_test_data(directory,imouse,isession)

session_stack=[]; session_info=[]; 
% get list of test folders (inside session folder)
directory.test_list= GetSubDirsFirstLevelOnly(fullfile(directory.parentDir, directory.mouse_list{imouse}, directory.session_list{isession}));
% remove folders created by CNMFE starting with 'session'
directory.test_list(startsWith(directory.test_list,'session'))=[];
tests= 1:length(directory.test_list);

% load and concatenate data (imaging + info/behavior) from each test
fprintf(['\nloading test data for session ' num2str(isession) '\n'])
for itest= tests % level 4
    % load test_dat.mat file
    load([fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{isession}, directory.test_list{itest}) '\test_dat.mat']);
    % copy each field into session_dat
    fields= fieldnames(test_dat);
    for ifield= 1:length(fields)
        test_dat.info.nframe=[];
        if ~isempty(test_dat.(fields{ifield}))
            if strcmp(fields{ifield},'stack')
                % concatenate stacks
                session_stack= cat(3,session_stack,test_dat.stack.stack);
            else
                session_info.(fields{ifield})(itest) = test_dat.(fields{ifield});
                if ifield==1
                    session_info.info(itest).nframe = size(test_dat.stack.stack,3);
                end
            end
        end
    end
    fprintf([num2str(itest) ' '])
end
fprintf('\nloading done\n')