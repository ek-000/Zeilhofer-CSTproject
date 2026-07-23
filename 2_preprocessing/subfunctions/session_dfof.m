function cat_dfof= session_dfof(session_stack,options)

fprintf('\nrunning dfof\n')
chunksize = 1000;


%% quick check
% session_stack= session_stack(:,:,1:1000);
% options.freqLow=    60;
% options.freqHigh=   5;
% 
% dfof = normalizeMovie(session_stack,'normalizationType','fft',...
%     'freqLow',options.freqLow,'freqHigh',options.freqHigh,...
%     'waitbarOn',0,'bandpassMask','gaussian');
% 
%  play(dfof)
%  %%
%  dfof= dfof + abs(min(dfof,[],'all'));
%  session_dfof=dfof;
%  session_dfof= session_dfof.*(2^8/max(session_dfof,[],'all')); % stretch histogram
%  session_dfof=uint8(session_dfof);
%%

% proceed by batch to save RAM
nchunk= floor(size(session_stack,3)/chunksize);
% pre allocate
cat_dfof= zeros(size(session_stack),'uint8');
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
    dfof(isnan(dfof))=0; % remove nans
    % add offset (make all values positive)
    dfof= dfof + abs(min(dfof,[],'all'));
    cat_dfof(:,:,ifr:ifr+chunksize)= uint8(dfof); % allocate
    ifr= ifr+chunksize; % update
    fprintf([num2str(ichunk) ' '])
end

% stretch histogram
dflims= [prctile(cat_dfof,1,'all') prctile(cat_dfof,99.9,'all')]; 
cat_dfof= cat_dfof.*(2^8/dflims(2)); % stretch histogram
cat_dfof(cat_dfof<dflims(1))= dflims(1); % stretch histogram

fprintf('\ndone\n')

