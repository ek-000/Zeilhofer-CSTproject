function save_preprocessing_test(stack,behavior,test_dat,directory,opt,fr,beh_montage)

% append all relevant information (including stack)
test_dat.stack.stack=   stack;
test_dat.behavior=      behavior;
test_dat.options=       opt;

% save
fprintf('\nsaving started\n')
% save stack as .avi
if opt.test.save_stack
    saveasavi(stack,directory.test,'stack_prepro','fr',fr*3); % speed *3
end
% save stack and behavior as .mat
if opt.test.save_test_dat
    save(fullfile(directory.test,'test_dat'),'test_dat','-v7.3');
end
% save behavior + imaging montage
if opt.test.save_montage && opt.test.montage
    saveasavi(beh_montage,directory.test,'movie','fr',10)
end
fprintf('\nsaving done\n')