# ZeilhoferLab-CSTproject

This is a repository for code used for analysis of imaging and behavioural data in the manuscript d’Aquin et al. entitled "A corticospinal circuit conveys pain expectation and modulates nociceptive behavior". 

This code was written on MATLAB R2021b and tested on Windows Server 2022, version 21H2. The installed MATLAB add-ons are: Financial Toolbox v6.2, Curve Fitting Toolbox v3.6, Parallel Computing Toolbox v7.5, Statistics and Machine Learning Toolbox v12.2, Simulink v10.4, Signal Processing Toolbox v8.7, Optimization Toolbox v9.2, MATLAB Report Generator v5.11, MATLAB Compiler SDK v6.11, MATLAB Coder v5.3, Image Processing Toolbox v11.4, Image Acquisition Toolbox v6.5, Database Toolbox v10.2, and MATLAB Compiler v8.3.

# data acquisition
Data is organized as Mouse Label / Sessions (here, "1 hab", "2 cond", "3 ret", and for some experiments "4 fullcond", "5 fullcond") / Date of session / Files from the recordings. With the help of the overhead camera recordings and miniscope imaging data collected via MATLAB R2021b, Inscopix software and miniscope DAQ box, and miniscope DAQ software (https://aharoni-lab.com/), the output files include "My_WebCam" folder with the behavioural recording, "My_V3_Miniscope" folder with the miniscope recordings, "(sessionname).mat", and metaData files.

# overview of analysis
Change the required paths, parent directories, and specific options as needed in the MATLAB R2021b codes:
* "freezing_20240214.m" = imports, synchronizes, resamples, and organizes the raw behavioral and movement data for further analysis (binarizes recordings and tracks location over time)
* "preprocessing_20250709.m" = preprocesses imaging and behavioural data for each test, combines test data per session, runs CNMFE on session data, allows manual curation of traces, and an option to find global cells or same cells present in different sessions
* "analysis1P_master_20250709_ek.m" = combines behavioral and imaging data to calculate response measures, compare conditions or groups, perform statistics, and generate figures

## analysis of behavioural data
* The behavioral movies are binarized with an adaptive threshold considering the darkest pixel values on each frame to account for changes in illumination due to the floor LED array. 
* A morphological filter (image dilation) is applied to the binarized movie to filter out the miniature microscope cable.
* Locomotion:
* * The mouse’s centroid location over time is used to calculate locomotion.
  * Mice are considered freezing if immobile (locomotion < 3 mm per second) for more than 2 s. Freezing episodes under 0.2 seconds apart are merged.
  * Corner to center ratio: The square floor of the behavioral box is considered as a 4-by-4 grid. The corner to center ratio is calculated as the total time spent in the corners of the grid divided by the total time spent in the 4 central parts of the grid.
* Distance covered by mice in response to the painful stimulus: To calculate this, the integral velocity over a 2 s window following the onset of the blue light stimulus is considered.

## analysis of imaging data
* Raw imaging movies are preprocessed by subtracting acquisition noise (acquired with the miniature microscope lid on) from each frame, spatial down-sampling by a factor of two, and non-rigid image registration with NoRMCorre (Pnevmatikakis et al., 2017). 
* Single-cell ROIs extraction involving denoising, deconvolution, and demixing is obtained by applying constrained non-negative matrix factorization (CNMFE; Zhou et al., 2018) to the preprocessed imaging movies on each session. ROIs detected at the proximity of the prism edge are removed from further analysis.
* The extracted calcium traces are then manually curated by visual inspection with the following exclusion criteria: absence of clear calcium transients (sharp rise and slow decay), drifting baseline, presence of negative transients, very slow transients (indicative of reduced calcium buffering capacity).
* Calcium traces are z-scored z = (X−μ) / σ; X = value being measured; μ = mean of the group of values; σ = standard deviation of the group of values.   
### stimulus-response analysis in the study
* A neuron was considered responsive to a tone or light stimulus presentation when its z-scored calcium activity during the stimulus response window was significantly higher than during the 5 s baseline preceding the stimulus onset.
* A neuron was considered tone- or light-responsive when its z-scored calcium activity averaged over all stimuli presentations was significantly higher during the stimulus response window than during baseline.
* Overall stimulus responses were calculated by averaging each neuron's mean z-scored activity across all relevant stimulus presentations within a session.
* For comparisons across sessions, analyses were restricted to the most reliably responsive neurons in each session (top 10% for tones, top 20% for light stimuli).
* For Venn diagrams, the expected chance overlap between neurons responsive to stimuli A and B was calculated as P(A).P(B) (P = proportion of neurons responsive to a given stimulus).
* Single-cell stimulus response correlations were calculated using linear regression on the mean response amplitudes of individual neurons for the two stimuli considered.
### global cells identification 
Global cells are ROIs identified in all recording sessions for a given animal. To identify them, the spatial footprints of the extracted ROIs in each session are registered in MATLAB and ROIs with >60 % spatial overlap between all consecutive sessions are considered global cells. 

Please direct any questions regarding the analysis on this repository to simondaquin@gmail.com and eshita.kamal@pharma.uzh.ch.
