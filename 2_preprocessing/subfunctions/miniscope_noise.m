function noise= miniscope_noise(directory,filename,minoscope_id)
% make a new noise projection (1 per miniscope)
% load noise movie (10 s) from file
noisemov= load_avi(directory.noise,filename.noise);
noise= 1.1*single(mean(noisemov,3)); % projection