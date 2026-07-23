% load miniscope .avi movies (compressed with FFV1)
% IMPORTANT: requires codec, see: https://codecguide.com/download_k-lite_codec_pack_basic.htm
function stack= load_miniscope_avi(directory)

fprintf('\nloading recordings\n')
FileListAvi = dir(fullfile(directory.test, directory.miniscope_movies, '**', '*.avi')); % get all files in directory

% reorder movies ('0.avi','1.avi','10.avi'... to '0.avi','1.avi','2.avi'...'10.avi')
for imov= 1:length(FileListAvi)
movNum(imov)= str2num(FileListAvi(imov).name(1:end-4));
end
[~,order]= sort(movNum); % get movie order by sorting actual number

stack= [];
% load movies on order
for imov= order %%%%%%%%%%%
    filename= FileListAvi(imov).name;
    stacki= load_avi(fullfile(directory.test,directory.miniscope_movies),filename,'single');
    % concatenate movies
    if size(stacki,3) > 10 % sometimes records extra few frames in the end, do not add them
        stack= single(cat(3,stack,stacki));
        fprintf([num2str(imov) ' '])
    end
end
fprintf('\nloading done\n')

