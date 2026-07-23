function session_stack= align_session(imouse,isession,session_stack,directory,opt)
    if isession==1
        % create stack projection
        templ= uint8(mean(session_stack,3)); % keep projection as template
        % save current session mean projection
        saveastiff(mean(session_stack,3),fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{1},'session_template.tif'),opt);
    else
        % if not first session first test, register to template
        templ= uint8(loadtiff(fullfile(directory.parentDir, directory.mouse_list{imouse}, directory.session_list{1},'session_template.tif')));
        proj= cat(3,templ,mean(session_stack,3));
        [optimizer,metric]= imregconfig(opt.session.registration.mode); % set parameters
        % create tform
        if strcmp(opt.session.registration.method,'imregister2')
            for iproj = 1:size(proj,3)
                I= proj(:,:,iproj);
                [~,~, tform] = imregister2(I, proj(:,:,1), opt.session.registration.transformation, optimizer, metric );
            end
        elseif strcmp(opt.session.registration.method,'imregtform')
            for iproj = 1:size(proj,3)
                tform = imregtform( proj(:,:,iproj), proj(:,:,1), opt.session.registration.transformation, optimizer, metric);
            end
        end
        
        % apply tform (shift) to stack
        Rfixed = imref2d(size(proj));
        fprintf('\napplying shifts\n')
        session_stack= imwarp(session_stack, tform, 'OutputView', Rfixed);
        fprintf('done\n')
        % save registered stack projection
        if opt.session.save_shift
            saveastiff(cat(3,templ,mean(session_stack,3)), fullfile(directory.parentDir, directory.mouse_list{imouse}, directory.session_list{isession},'projection.tif'), opt);
        end
    end