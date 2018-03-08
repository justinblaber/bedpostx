# bedpostx
bedpostx pipeline

# Installation instructions:
1) Install [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki)
2) Download repos and (optional) example data:
```
git clone https://github.com/justinblaber/system_utils.git
git clone https://github.com/justinblaber/nifti_utils.git
git clone https://github.com/justinblaber/dwmri_visualizer.git
git clone https://github.com/justinblaber/bedpostx.git

# Optionally download example data
wget https://justinblaber.org/downloads/github/bedpostx/PREPROCESSED.zip
unzip PREPROCESSED.zip
```
4) In MATLAB:
```
>> addpath('system_utils');
>> addpath(genpath('nifti_utils'));
>> addpath(genpath('dwmri_visualizer'));
>> addpath('bedpostx');
```
If you've downloaded the example data, then edit the test script (only the `fsl_path` should have to be changed) and run it:

```
>> edit test_bedpostx
```
The output PDF should look like:

<a href="https://justinblaber.org/downloads/github/bedpostx/bedpostx.pdf">
<p align="center">
  <img width="769" height="995" src="https://i.imgur.com/P6vLxCP.png">
</p>
<p align="center">
  <img width="768" height="994" src="https://i.imgur.com/2iuPADP.png">
</p>
</a>
