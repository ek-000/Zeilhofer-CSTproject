function data= resample_motion(data,stim,par)

% define sessions
sessions= stim.session.conditioning;
if size(data,2) < length(sessions) % if less sessions than conditioning sessions (e.g control conditioning)
    sessions=sessions(1:size(data,2));
end

fprintf('\nresampling motion\n')
for imouse= stim.mice
    for isession= sessions
        if ~isempty(data(imouse,isession).motion)
            centroid= data(imouse,isession).motion.centroid; % get centroid mouse position
            clear distance

            % calculate distance
            parfor ifr= 2:size(centroid,2) % calculate distance between centroids
                distance(ifr-1)= pdist([centroid(:,ifr), centroid(:,ifr-1)],'euclidean');
            end
            motion= abs(diff(distance)); % motion

            % Interpolate missing values
            nanx = isnan(motion);
            t    = 1:numel(motion);
            motion(nanx) = prctile(motion,98);

            nfr= size(data(imouse,isession).traces,2); % get number of frames % 15200
            if nfr==0 % empty traces
                nfr= 15200;
            end

            % resample motion at imaging frame rate
            rs_motion= resample(motion,nfr,length(motion)); % resample motion
            rs_motion(rs_motion<0)= 0; % can happen that a few frames go negative while resampling
            % convert to cm/s: 385 px (cropped movie)= 30 cm (arena size)
            rs_motion= rs_motion * stim.fr * 30 / 385;
            data(imouse,isession).motion.rs_motion= rs_motion; % append

            % resample centroid the same way
            clear rs_centroid
            rs_centroid(1,:)= resample(centroid(1,:),nfr,length(centroid));
            rs_centroid(2,:)= resample(centroid(2,:),nfr,length(centroid));
            data(imouse,isession).motion.rs_centroid= rs_centroid; % append
           
            % resample motion at different frame rate
            if ~isempty(par.motion_frame_rate)
                nMotfr= nfr/stim.fr*par.motion_frame_rate;
                rs_motion2= resample(motion,nMotfr/5, round(length(motion)/5)); % resample motion
                if length(rs_motion2) > nMotfr % adjust vector size
                    rs_motion2= rs_motion2(1:nMotfr);
                elseif length(rs_motion2) < nMotfr
                    rs_motion2= [rs_motion2 zeros(1,nMotfr-length(rs_motion2))];
                end
                rs_motion2(rs_motion2<0)= 0; % can happen that a few frames go negative while resampling
                % convert to cm/s: 385 px (cropped movie)= 30 cm (arena size)
                rs_motion2= rs_motion2 * par.motion_frame_rate * 30 / 385;
                data(imouse,isession).motion.rs_motion2= rs_motion2; % append
            end

            % bin motion
            data(imouse,isession).motion.binnedMotion= resample(rs_motion, round(nfr/(stim.fr*par.binsize)), length(rs_motion)); % binned motion
        end
    end
end
fprintf('\ndone\n')