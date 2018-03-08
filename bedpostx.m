function [bedpostx_dir_path,bedpostx_pdf_path] = bedpostx(job_dir_path, dwmri_path, bvec_path, bval_path, mask_path, fsl_path, bedpostx_name, bedpostx_params)
    % This is a bedpostx pipeline that is specifically written to work with
    % FSL 5.0.10.
    %
    % INPUTS: 
    %   job_dir_path - path to job directory
    %   dwmri_path - path to dwmri file
    %   bvec_path - path to bvec file
    %   bval_path - path to bval file
    %   mask_path - path to mask file
    %   fsl_path - path to fsl installation
    %   bedpostx_name - name of bedpostx executable
    %   bedpostx_params - params to use with bedpostx
    %
    %   Assumes bvecs are in "radiological voxel convention". Also 
    %   assumes input niftis are in radiological storage orientation.
    %
    %   From FSL documentation:
    %       What conventions do the bvecs use?
    % 
    %       The bvecs use a radiological voxel convention, which is the voxel 
    %       convention that FSL uses internally and originated before NIFTI 
    %       (i.e., it is the old Analyze convention). If the image has a 
    %       radiological storage orientation (negative determinant of 
    %       qform/sform) then the NIFTI voxels and the radiological voxels 
    %       are the same. If the image has a neurological storage 
    %       orientation (positive determinant of qform/sform) then the 
    %       NIFTI voxels need to be flipped in the x-axis (not the y-axis 
    %       or z-axis) to obtain radiological voxels. Tools such as dcm2nii 
    %       create bvecs files and images that have consistent conventions 
    %       and are suitable for FSL. Applying fslreorient2std requires 
    %       permuting and/or changing signs of the bvecs components as 
    %       appropriate, since it changes the voxel axes. 
    %
    % OUTPUTS: 
    %   Returns absolute paths to output bedpostx directory and bedpostx
    %   pdf.
    
    % Use exec_gen to generate full path to fsl executables
    fsl_exec = system_utils.exec_gen(fullfile(fsl_path,'bin'));

    % Setup job directory ------------------------------------------------%
    job_dir = system_utils.directory(job_dir_path);
    job_dir.mkdir_with_warning('Files in this directory may get modified in-place.');
    
    % Handle inputs ------------------------------------------------------%
    dwmri_file = system_utils.file.validate_path(dwmri_path);
    bvec_file = system_utils.file.validate_path(bvec_path);
    bval_file = system_utils.file.validate_path(bval_path);
    mask_file = system_utils.file.validate_path(mask_path);
        
    % Copy data into bedpostx_data directory, since data must be formatted 
    % in a specific way
    bedpostx_data_dir = system_utils.directory(job_dir,'BEDPOSTX_DATA');
    bedpostx_data_dir.mkdir();
    
    % Copy files to bedpostx_data dir     
    dwmri_file = dwmri_file.cp(bedpostx_data_dir,'data.nii.gz');  
    bvec_file = bvec_file.cp(bedpostx_data_dir,'bvecs'); %#ok<NASGU> % No file extension
    bval_file = bval_file.cp(bedpostx_data_dir,'bvals'); %#ok<NASGU> % No file extension
    mask_file = mask_file.cp(bedpostx_data_dir,'nodif_brain_mask.nii.gz');
        
    % Check to make sure dwmri and mask niftis are compatible 
    if ~nifti_utils.are_compatible(dwmri_file.get_path(),mask_file.get_path())
        warning(['niftis: ' dwmri_file.get_path() ' and ' ...
                 mask_file.get_path() ' were found to be "incompatible". ' ...
                 'Please check to make sure sform/qform are very ' ...
                 'similar.']);
    end
    
    % Check to make sure niftis are in radiological storage orientation;
    % this is for FSL's sake. If nifti is in radiological storage 
    % orientation, I assume the bvecs are correctly in "radiological voxel 
    % convention". If this is not the case, issue a warning.
    if ~nifti_utils.is_radiological_storage_orientation(dwmri_file.get_path(), ...
                                                        fsl_exec.get_path('fslorient'))
        warning(['Input nifti: ' dwmri_file.get_path() ' was found to ' ...
                 'not be in radiological storage orientation. Make sure ' ...
                 'bvecs are in correct orientation for FSL!!!']);
    end
    if ~nifti_utils.is_radiological_storage_orientation(mask_file.get_path(), ...
                                                        fsl_exec.get_path('fslorient'))
        warning(['Input nifti: ' mask_file.get_path() ' was found to ' ...
                 'not be in radiological storage orientation. Make sure ' ...
                 'bvecs are in correct orientation for FSL!!!']);
    end
    
    % Make bedpostx_datacheck call
    system_utils.system_with_errorcheck([fsl_exec.get_path('bedpostx_datacheck') ' ' bedpostx_data_dir.get_path()],'bedpostx input directory was not set up properly.');
       
    % Make bedpostx call
    bedpostx_data_bedpostx_dir = system_utils.directory(job_dir,'BEDPOSTX_DATA.bedpostX'); % Output directory
    system_utils.system_with_errorcheck([fsl_exec.get_path(bedpostx_name) ' ' bedpostx_data_dir.get_path() ' ' bedpostx_params],'bedpostx failed.');
    
    % Copy header info over to outputs - sometimes fsl mucks with it,
    % although it will be a very minor change.
    bedpostx_contents = bedpostx_data_bedpostx_dir.dir('*.nii.gz');
    for i = 1:length(bedpostx_contents.files)
        nifti_utils.copyexceptimginfo_untouch_header_only(dwmri_file.get_path(),bedpostx_contents.files(i).get_path());        
    end 
            
    % Get number of fibres
    num_fibres = 0;
    while system_utils.file(bedpostx_data_bedpostx_dir,['dyads' num2str(num_fibres+1) '.nii.gz']).exist()
        num_fibres = num_fibres + 1;
    end
    
    % Get mean_fsumsamples file, dyads* files, and mean_f*samples files
    mean_fsumsamples_file = system_utils.file(bedpostx_data_bedpostx_dir,'mean_fsumsamples.nii.gz');
    dyads_files = system_utils.file.empty();
    meanfsamples_files = system_utils.file.empty();
    for i = 1:num_fibres
        dyads_files(i) = system_utils.file(bedpostx_data_bedpostx_dir,['dyads' num2str(i) '.nii.gz']);
        meanfsamples_files(i) = system_utils.file(bedpostx_data_bedpostx_dir,['mean_f' num2str(i) 'samples.nii.gz']);
    end
    
    % Get bedpostx plot pdf
    bedpostx_pdf_path = lib.bedpostx_plot(job_dir, ...
                                          dwmri_file, ...
                                          mask_file, ...
                                          mean_fsumsamples_file, ...
                                          dyads_files, ...
                                          meanfsamples_files, ...
                                          fsl_path, ...
                                          bedpostx_params, ...
                                          num_fibres);
                                                     
    % Assign outputs -----------------------------------------------------%
    bedpostx_dir_path = bedpostx_data_bedpostx_dir.get_path();
end
