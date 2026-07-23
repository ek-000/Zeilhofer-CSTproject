function test_dat= collect_test_info(directory,filename,imouse,isession,itest,fr)
directory.test= fullfile(directory.parentDir,directory.mouse_list{imouse}, directory.session_list{isession}, directory.test_list{itest});
% collect test info
pathparts = strsplit(fullfile(directory.parentDir,directory.mouse_list{imouse}),filesep); % get path structure
test_dat.info.experiment= pathparts{end-1};
test_dat.info.mouse_number= pathparts{end};
test_dat.info.session= directory.session_list{isession};
test_dat.info.session_number= isession;
test_dat.info.test= directory.test_list{itest}(4:end);
test_dat.info.side= directory.test_list{itest}(end);
test_dat.info.test_number= itest;
test_dat.info.frame_rate= fr;
% get notes from .txt file
if exist(fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{isession},filename.notes),'file')>0
    test_dat.info.notes= importdata(fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{isession},filename.notes));
end