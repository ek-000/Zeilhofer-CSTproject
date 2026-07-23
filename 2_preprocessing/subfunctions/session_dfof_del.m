function session_dfof= session_dfof(session_stack,directory,imouse,isession,opt,fr,options)

fprintf('\nrunning dfof\n')
chunksize = 1000;

% % quick check
% dfof = normalizeMovie(session_stack,'normalizationType','fft',...
%     'freqLow',options.freqLow,'freqHigh',options.freqHigh,...
%     'waitbarOn',0,'bandpassMask','gaussian');
%  play(dfof)

% proceed by batch to save RAM
nchunk= floor(size(session_stack,3)/chunksize);
% pre allocate
session_dfof= zeros(size(session_stack),'uint8');
% stack needs to be single because of the division step
ifr=1; % initialize
for ichunk=1:nchunk
    if ichunk==nchunk % last bit
        chunksize= rem(size(session_stack,3)-1,chunksize);
    end
    chunk= single(session_stack(:,:,ifr:ifr+chunksize));
    dfof = normalizeMovie(chunk,'normalizationType','fft',...
        'freqLow',options.freqLow,'freqHigh',options.freqHigh,...
        'waitbarOn',0,'bandpassMask','gaussian');
    % add offset
    dfof= dfof + abs(min(dfof,[],'all'));
    session_dfof(:,:,ifr:ifr+chunksize)= uint8(dfof); % allocate
    ifr= ifr+chunksize; % update
    fprintf([num2str(ichunk) ' '])
end
session_dfof= session_dfof.*(2^8/max(session_dfof,[],'all')); % stretch histogram
fprintf('\ndone\n')

if opt.session.save
    fprintf('\nsaving session dfof\n')
    % save max projection as .tif
    m= max(session_dfof(:,:,1:round(size(session_dfof,3)/10)),[],3); % max projecion over 10% of the stack
    saveastiff(m,fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{isession},'stack_max_proj.tif'),opt);
    % save session dfof as .avi
    saveasavi(session_dfof,fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{isession}),'session_dfof','fr',fr*3);
    % save session_dfof as .mat
    save(fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{isession}, 'session_dfof'),'session_dfof','-v7.3');
    fprintf('\nsaving session dfof done\n')
end
