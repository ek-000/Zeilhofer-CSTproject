function save_preprocessing_session(directory,session_stack,dfof,session_info,imouse,isession,opt,fr)

% saves session_stack as.avi and .mat, and mean and max
% projections, saves session_info

% save session_info
save(fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{isession}, 'session_info'),'session_info','-v7.3');

% save stack
if ~isempty(session_stack)
% save stack max projection as .tif
saveastiff(max(session_stack,[],3),fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{isession},'stack_max_proj.tif'),opt);
fprintf('\nsaving session stack\n')
% save session_stack as .avi
saveasavi(session_stack,fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{isession}),'session_stack','fr',fr*5);
% save session_stack as .mat
save(fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{isession}, 'session_stack'),'session_stack','-v7.3');
fprintf('\ndone\n')
end

% save dfof
if ~isempty(dfof)
fprintf('\nsaving session dfof\n')
% save mean projection as .tif
saveastiff(max(dfof,[],3),fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{isession},'stack_max_proj_dfof.tif'),opt);
% save session dfof as .avi
saveasavi(dfof,fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{isession}),'dfof','fr',fr*5);
% save session_dfof as .mat
save(fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{isession}, 'dfof'),'dfof','-v7.3');
fprintf('\ndone\n')
end


