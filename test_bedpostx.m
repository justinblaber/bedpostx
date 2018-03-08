%% Set environment
addpath('system_utils');
addpath(genpath('nifti_utils'));
addpath(genpath('dwmri_visualizer'));
addpath('bedpostx');

%% Run bedpostx pipeline

% Set job directory path
job_dir_path = 'test_bedpostx';

% Use outputs from PREPROCESSED folder of topup_eddy_preprocess pipeline
dwmri_path = 'PREPROCESSED/dwmri.nii.gz';
bvec_path = 'PREPROCESSED/dwmri.bvec';
bval_path = 'PREPROCESSED/dwmri.bval';
mask_path = 'PREPROCESSED/mask.nii.gz';

% Set FSL path
fsl_path = '~/fsl_5_0_10_eddy_5_0_11';

% Name of bedpostx executable
bedpostx_name = 'bedpostx';

% Bedpostx params 
bedpostx_params = '';

% Perform bedpostx pipeline
[bedpostx_dir_path,bedpostx_pdf_path] = bedpostx(job_dir_path, ...
                                                 dwmri_path, ...
                                                 bvec_path, ...
                                                 bval_path, ...
                                                 mask_path, ...
                                                 fsl_path, ...
                                                 bedpostx_name, ...
                                                 bedpostx_params);