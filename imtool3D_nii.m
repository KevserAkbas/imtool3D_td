function tool = imtool3D_nii(filename,viewplane,maskfname)
% imtool3D_nii fmri.nii.gz
% imtool3D_nii fmri.nii.gz sagittal
% imtool3D_nii *fmri*.nii.gz
% imtool3D_nii({'fmri.nii.gz', 'T1.nii.gz'})

A = which('load_untouch_nii');
if isempty(A)
    warning('Dependency to Jimmy Shen NIFTI tools is missing. https://fr.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image');
    return
end

if ~iscell(filename)
    list = tools_ls(filename,1,1,2,1);
else
    list = filename;
end
if exist('maskfname','var') && iscell(maskfname)
    maskfname = maskfname{1};
end
if isempty(list)
    warning(['no files match ' filename])
    return;
end
for iii=1:length(list)
    if nargin>1 && ~isempty(viewplane)
        [dat{iii}, hdriii] = load_nii_data(list{iii});
        if iii==1
            hdr = hdriii;
        end
        if iii==1 && nargin>2 && ~isempty(maskfname)
            mask  = load_nii_data(maskfname);
        end
    else
        nii = load_untouch_nii(list{iii});
        dat{iii} = nii.img;
        if iii==1
            hdr = nii.hdr;
        end
        if iii==1 && nargin>2 && ~isempty(maskfname)
            mask  = load_untouch_nii(maskfname);
            mask = mask.img;
        end
    end
end

if nargin<2 || isempty(viewplane), viewplane = 'axial'; end
switch viewplane
    case 'sagittal'
        dat = cellfun(@(x) permute(x,[2 3 1]),dat,'UniformOutput',false);
    case 'coronal'
        dat = cellfun(@(x) permute(x,[1 3 2]),dat,'UniformOutput',false);
end

if nargin>2 && ~isempty(maskfname)
tool = imtool3D(dat,[],[],[],[],mask);
else
tool = imtool3D(dat);
end

% set voxelsize

H = getHandles(tool);
set(H.Axes,'DataAspectRatio',hdr.dime.pixdim(2:4))

view(-90,90)


function [list, path]=tools_ls(fname, keeppath, keepext, folders,arborescence,select)
% [list, path]=tools_ls(fname, keeppath?, keepext?, folders?,recursive?)
% Example: tools_ls('ep2d*')
% example 2: tools_ls('*',[],[],1) --> folders only
% example 3: tools_ls('*',[],[],2) --> files only

if nargin < 2, keeppath=0; end
if nargin < 3, keepext=1; end
if nargin < 4 || isempty(folders), folders=0; end
if nargin < 6 || isempty(select), select=0; end
if nargin < 5, arborescence=0; end

% [list, path]=tools_ls('*T.txt);
list=dir(fname);
[path,name,ext]= fileparts(fname); 
path=[path filesep]; name = [name ext];
if strcmp(path,filesep)
    path=['.' filesep];
end

if folders==1
    list=list(cat(1,list.isdir));
elseif folders==2
    list=list(~cat(1,list.isdir));
end

% sort by name
list=sort_nat({list.name})';


% remove files starting with .
list(cellfun(@(x) strcmp(x(1),'.'), list))=[];
if keeppath
    for iL=1:length(list)
        list{iL}=[path list{iL}];
    end
end
pathcur = path;
path = repmat({path},[length(list),1]);

if ~keepext
    list=cellfun(@(x) sct_tool_remove_extension(x,keeppath),list,'UniformOutput',false);
end

if arborescence
    listdir = tools_ls(pathcur,1,1,1);
    for idir = 1:length(listdir)
        [listidir, pathidir]=tools_ls([listdir{idir} filesep name], keeppath, keepext, folders,arborescence,0);
        list = [list; listidir];
        path = cat(1,path, pathidir{:});
    end
end

if select, list=list{select}; end


function [data, hdr]=load_nii_data(fname,slice)
% data=load_nii_data(fname)
data=load_nii(fname,[],[],[],[],[],1); 
hdr=rmfield(data,'img');
if exist('slice','var')
    data=data.img(:,:,min(slice,end),:);
else
    data=data.img;
end