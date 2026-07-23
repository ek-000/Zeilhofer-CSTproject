function movf= fft_filter_movie(stack, par, opt) 

    % select frame(s)
    if opt.test
        frames= opt.testFrame;
    else
        frames= 1:size(stack,3);
    end

    % pre-allocate for speed
    movf= zeros(size(stack),'uint16');

    % loop through frames
    for ifr= frames
        % select image
        if opt.test
            I= stack(:,:,opt.testFrame);
        else
            I= stack(:,:,ifr);
        end

        I= uint16(I); % convert to uint16

        % original image
        if opt.test
            figure('position',[100 100 1800 800])
            subplot_tight(2,4,1)
            imshow(I,[0 max(I(:))]);
            title('original')
        end

        % perform image 2-D fourier transform and plot shifted frequencies
        frequencyImage= fftshift(fft2(I)); % image 2-D fourier transform
        amplitudeImage = log(abs(frequencyImage)); % Take log magnitude so we can see it better in the display.
        minValue = min(amplitudeImage(:));
        maxValue = max(amplitudeImage(:));
        if opt.test
            subplot_tight(2,4,2)
            imshow(amplitudeImage, []);
            title('amplitudeImage')
        end

        % show selected frequency spikes
        del_frequencies = amplitudeImage > par.amplitudeThresholdlow & amplitudeImage < par.amplitudeThresholdhigh; % Binary image.
        if opt.test
            subplot_tight(2,4,3)
            imshow(del_frequencies);
            title('brightSpikes')
        end

        % Exclude the central DC spike 
        dims=size(I);
%         blank1= round(dims(1)/2)-par.px_exclude: round(dims(1)/2)+par.px_exclude;
        blank2= round(dims(2)/2)-par.px_exclude: round(dims(2)/2)+par.px_exclude;
%         del_frequencies(blank1,:) = 1;
        del_frequencies(:,blank2) = 1;
        if opt.test
            subplot_tight(2,4,4)
            imshow(del_frequencies);
            title('blanked brightSpikes')
        end

        % Filter/mask the spectrum
        frequencyImage(del_frequencies) = 0;
        amplitudeImage2 = log(abs(frequencyImage));
        minValue = min(amplitudeImage2(:));
        maxValue = max(amplitudeImage2(:));
        if opt.test
            subplot_tight(2,4,5)
            imshow(amplitudeImage2, [minValue maxValue]);
            title('filtered amplitudeImage')
        end

        temp = ifft2(fftshift(frequencyImage));
        filteredImage = abs(temp);
        filteredImage= uint16(filteredImage);
        if opt.test
            subplot_tight(2,4,7)
            imshow(filteredImage, []); % [0 max(I(:))]
            title('filtered Image')
        end
        movf(:,:,ifr)= filteredImage; % append

        if opt.test
            subplot_tight(2,4,6)
            removed= I- filteredImage;
            imshow(removed, []); % [0 max(removed(:))/3]
            title('subtracted image')
        end
    end
    fprintf('\ndone FFT filtering\n')
