function data= resample_motion(data,stim,par,folder,igroup)

% define sessions
sessions= stim.session.conditioning;
if size(data,2) < length(sessions) % if less sessions than conditioning sessions (e.g control conditioning)
    sessions= sessions(1:size(data,2));
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
            nanx=   isnan(motion);
            t=      1:numel(motion);
            motion(nanx) = prctile(motion,98);

            nfr= size(data(imouse,isession).traces,2); % get number of frames % 15200

            if nfr==0 % empty traces
                nfr= 15200;
            end


            if contains(folder.parentDir{1},'fullcond')
                nfr= stim.fr * round(data(imouse,isession).info.behavior.rec.ts,1);
                if   contains(folder.parentDir{1},'SD051') && isession>3
                    frame_offset{4}= [2 3 3 1 10 1 13]; % [5 7 7 5 16 3 20];
                    frame_offset{5}= [0 8 1 -2 0 0 4]; % [3 14 4 163 2 2 8];
                elseif  contains(folder.parentDir{1},'SD052') && isession>3
                    frame_offset{4}= [2 5 1 1 3 1 1]-1;
                    frame_offset{5}= [4 0 3 3 1 0 1]-1;
                    nfr= stim.fr * round(data(imouse,isession).info.behavior.rec.ts,1) + frame_offset{isession}(imouse);
                elseif  contains(folder.parentDir{1},'SD056') && isession>3 && igroup==1
                    frame_offset{4}= [2 0 4 2 0 2 2 4];
                    frame_offset{5}= [0 4 2 1 1 1 -2 2];
                    if isession==4
                        dropped_frames_nb= [2 26 0 0 3 2 2 0]*8;
                        motion= [zeros(1,dropped_frames_nb(imouse)) motion];
                    elseif isession==5
                        dropped_frames_nb= [1 3 3 1 1 1 5 1]*8;
                        motion= [zeros(1,dropped_frames_nb(imouse)) motion];
                    end
                    nfr= stim.fr * round(data(imouse,isession).info.behavior.rec.ts,1) + frame_offset{isession}(imouse);
                elseif  length(folder.parentDir)==2 && contains(folder.parentDir{2},'SD056') && isession>3 && igroup==2
                    frame_offset{4}= [3 0 4 5 12 9 12 1 0 2 0];
                    frame_offset{5}= [1 -1 -1 -2 2 -3 0 2 2 6 0];
                    if isession==4
                        dropped_frames_nb= [1 3 1 0 1 0 2 2 4 2 1]*8;
                        motion= [zeros(1,dropped_frames_nb(imouse)) motion];
                    elseif isession==5
                        dropped_frames_nb= [1 3 2 0 0 3 3 2 2 0 1]*8;
                        motion= [zeros(1,dropped_frames_nb(imouse)) motion];
                    end
                    nfr= stim.fr * round(data(imouse,isession).info.behavior.rec.ts,1) + frame_offset{isession}(imouse);

                elseif  contains(folder.parentDir{1},'SD063') && isession>3
                    frame_offset{4}= [3 -2 0 0 -3]; 
                    frame_offset{5}= [1 0 1 1 0]; 
                    if isession==4
                        dropped_frames_nb= [1 2 1 2 6]*8; 
                        motion= [zeros(1,dropped_frames_nb(imouse)) motion];
                    elseif isession==5
                        dropped_frames_nb= [3 1 0 2 1]*8; 
                        motion= [zeros(1,dropped_frames_nb(imouse)) motion];
                    end
                    nfr= stim.fr * round(data(imouse,isession).info.behavior.rec.ts,1) + frame_offset{isession}(imouse);

                elseif  contains(folder.parentDir{1},'SD065') && isession>3
                    frame_offset{4}= [3 -2 1 1 0 0 0 -2 0 0 -3];
                    frame_offset{5}= [1 0 -2 0 0 0 1 0 1 1 0];
                    if isession==4
                        dropped_frames_nb= [1 3 0 0 0 2 0 2 1 2 6]*8;
                        motion= [zeros(1,dropped_frames_nb(imouse)) motion];
                    elseif isession==5
                        dropped_frames_nb= [3 0 7 0 0 1 0 1 0 2 1]*8; 
                        motion= [zeros(1,dropped_frames_nb(imouse)) motion];
                    end
                    nfr= stim.fr * round(data(imouse,isession).info.behavior.rec.ts,1) + frame_offset{isession}(imouse);

                elseif  contains(folder.parentDir{1},'SD066') && isession>3
                    frame_offset{4}= [3 3 -2 0 4 5 12 1 1 9 12 0 0 0 1 0 2 0 -2 0 0 -3];
                    frame_offset{5}= [1 1 0 -1 -1 -2 2 -2 0 -3 0 0 0 1 2 2 6 0 0 1 1 0];
                    if isession==4
                        dropped_frames_nb= [1 1 3 3 1 0 1 0 0 0 2 0 2 0 2 4 2 1 2 1 2 6]*8;
                        motion= [zeros(1,dropped_frames_nb(imouse)) motion];
                    elseif isession==5
                        dropped_frames_nb= [1 3 0 3 2 0 0 7 0 3 3 0 1 0 2 2 0 1 1 0 2 1]*8; 
                        motion= [zeros(1,dropped_frames_nb(imouse)) motion];
                    end
                    nfr= stim.fr * round(data(imouse,isession).info.behavior.rec.ts,1) + frame_offset{isession}(imouse);
                    
                end
            end


            % resample motion at imaging frame rate
            % subsample motion if too large for matlab to resample later
            if nfr*length(motion)> 2^31
                sub_rate= ceil((nfr*length(motion))/2^31);
                motion= motion(1:sub_rate:length(motion));
                centroid= centroid(:,1:sub_rate:size(centroid,2));
            end

            rs_motion= resample(motion,nfr,length(motion)); % resample motion
            rs_motion(rs_motion<0)= 0; % can happen that a few frames go negative while resampling
            rs_motion= rs_motion * stim.fr * 30/385; % convert to cm/s: 385 px (cropped movie)= 30 cm (arena size)
            data(imouse,isession).motion.rs_motion= rs_motion; % append

            % resample centroid the same way
            clear rs_centroid
            rs_centroid(1,:)= resample(centroid(1,:),nfr,length(centroid));
            rs_centroid(2,:)= resample(centroid(2,:),nfr,length(centroid));
            data(imouse,isession).motion.rs_centroid= rs_centroid; % append

            % resample motion at different frame rate
            if ~isempty(par.motion_frame_rate)
                nMotfr= nfr/stim.fr*par.motion_frame_rate;
                rs_motion2= resample(motion, nMotfr/5, round(length(motion)/5)); % resample motion
                if length(rs_motion2) > nMotfr % adjust vector size
                    rs_motion2= rs_motion2(1:nMotfr);
                elseif length(rs_motion2) < nMotfr
                    rs_motion2= [rs_motion2 zeros(1,nMotfr-length(rs_motion2))];
                end
                rs_motion2(rs_motion2<0)= 0; % can happen that a few frames go negative while resampling
                rs_motion2= rs_motion2 * par.motion_frame_rate * 30 / 385; % convert to cm/s: 385 px (cropped movie)= 30 cm (arena size)
                data(imouse,isession).motion.rs_motion2= rs_motion2; % append
            end

            % bin motion
            data(imouse,isession).motion.binnedMotion= resample(rs_motion, round(nfr/(stim.fr*par.binsize)), length(rs_motion)); % binned motion
        end
    end
end
fprintf('\ndone\n')