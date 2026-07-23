% writes mov as uncompressed Grayscale .avi in current folder
% e.g. saveasavi(stack,path,'movie.avi','fr',10)
% default frame rate: 30fps
function saveasavi(mov,path,name,varargin)

cd(path)
dims= size(mov);

% change logical to uint8
if islogical(mov)
    mov= 255*uint8(mov);
end

% get frame rate
frame_rate= find(strcmp(varargin,'fr'));
if not(isempty(frame_rate))
    frame_rate= varargin{frame_rate+1};
end

% get video format
format= find(strcmp(varargin,'format'));
if not(isempty(format))
    format= varargin{format+1};
else
    format= 'Motion JPEG AVI'; % default
end

% create video writer
v= VideoWriter([name '.avi'], format);
% update frame rate
if not(isempty(frame_rate)) 
    v.FrameRate= frame_rate;
end

open(v)

% save each frame into file
% if mov frames are collected from a figure e.g F=figure; F(ifig)=gcf
if length(dims)==2
    for ifr=1:dims(2)
        fr = mov(ifr);
        writeVideo(v,fr)
    end
    % if mov is a 3-D array
elseif length(dims)==3
    for ifr=1:dims(3)
        fr = mov(:,:,ifr);
        writeVideo(v,fr)
    end
end
close(v)
fprintf('\nmovie was saved as .avi\n')
end

