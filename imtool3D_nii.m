function tool = imtool3D_nii(filename,viewplane,maskfname, parent, range)
% NIFTI Viewer
%
% INPUT
%   filename            String or cell of string with nifti filenames
%                       First filename is used as spatial reference
%                       Other nifti are resliced to this spatial reference
%   viewplane           String. 'axial', 'sagittal' or 'coronal'
%   maskfname           String. filename of the mask in NIFTI
%   parent              Handle to a figure or panel
%   range               1x2 or cell of 1x2 float numbers (min and max intensity)
%
% OUTPUT
%   tool                imtool3D object. 
%
% EXAMPLE
%   imtool3D_nii fmri.nii.gz
%   imtool3D_nii fmri.nii.gz sagittal
%   imtool3D_nii *fmri*.nii.gz
%   imtool3D_nii({'fmri.nii.gz', 'T1.nii.gz'})
%
% Tanguy DUVAL, INSERM, 2019
% SEE ALSO imtool3D, imtool3D_nii_3planes

if nargin==0, filename = []; end

if ~exist('parent','var'), parent=[]; end
if ~exist('viewplane','var'), viewplane=[]; end
if isempty(viewplane), untouch = true; viewplane=3; else, untouch = false; end
if ~exist('range','var'), range=[]; end
if ~exist('maskfname','var'), maskfname=[]; end

% LOAD IMAGE
if ~isempty(filename)
    if isnumeric(filename)
        filename = nii_tool('init',filename);
        filename.hdr.pixdim = [4 1 1 1 1 1 0 0 0];
        filename.fname = inputname(1);
    end
    if isstruct(filename)
        dat = filename.img;
        hdr = filename.hdr;
        if isfield(filename,'fname')
            list = filename.fname;
        elseif isfield(filename,'label')
            list = filename.label;
        else
            list = {''};
        end
    else
        [dat, hdr, list] = nii_load(filename,untouch);
    end
    disp(list)
else
    load mri % example mri image provided by MATLAB
    dat = D;
    dat = squeeze(dat);
    dat = permute(dat(end:-1:1,:,:),[2 1 3]); % LPI orientation
    list = {'MRI EXAMPLE'};
    if ~isdeployed
        A = which('nii_tool');
        if isempty(A)
            error('Dependency to Xiangrui Li NIFTI tools is missing. http://www.mathworks.com/matlabcentral/fileexchange/42997');
        end
    end
    niiinit = nii_tool('init',dat);
    hdr = niiinit.hdr;
    hdr.file_name = 'MRI EXAMPLE';
    hdr.pixdim = [4 1 1 2.5];
    untouch = false;
end

% LOAD MASK
if iscell(maskfname), maskfname = maskfname{1}; end
if ~isempty(maskfname)
    if isnumeric(maskfname)
        mask = maskfname;
    else
        mask = nii_load({hdr,maskfname},untouch); 
        if iscell(mask),    mask = mask{1}; end
    end
else
    mask = [];
end

% OPEN IMTOOL3D
if isnumeric(viewplane) && length(viewplane)>1
    % Call imtool3D_3planes
    tool3P = imtool3D_3planes(dat,mask,parent,range);
    tool = tool3P.getTool;
else
    tool = imtool3D(dat,[],parent,range,[],mask);
    tool.setviewplane(viewplane);
end


% Set Labels
for ii=1:length(tool)
    tool(ii).setlabel(list);
end

% set voxelsize
for ii=1:length(tool)
    tool(ii).setAspectRatio(hdr.pixdim(2:4));
end

% add Header Info button
Pos = get(tool(1).getHandles.Tools.Save,'Position');
Pos(1) = Pos(1)+2*Pos(3);
Pos(3) = 20;
HeaderButton           =   uicontrol(tool(1).getHandles.Panels.Tools,'Style','pushbutton','String','HDR','Position',Pos,'FontSize',6);
set(HeaderButton,'Callback',@(h,e) openvar2(get(h,'UserData')))
str = evalc('hdr');
set(HeaderButton,'TooltipString',str)
set(HeaderButton,'UserData',hdr)

% add header to save/load Mask
H = tool(1).getHandles;
set(H.Tools.maskSave,'Callback',@(hObject,evnt)saveMask(tool(1),hObject,get(HeaderButton,'UserData')))
set(H.Tools.maskLoad,'Callback',@(hObject,evnt)loadMask(tool(1),hObject,get(HeaderButton,'UserData')))

% add load Image features
Pos = get(tool(1).getHandles.Tools.Save,'Position');
Pos(1) = Pos(1) + Pos(3);
Parent = get(tool(1).getHandles.Tools.Save,'Parent');
Loadbut           =   uicontrol(Parent,'Style','pushbutton','String','','Position',Pos);
MATLABdir = fullfile(toolboxdir('matlab'), 'icons');
icon_load = makeToolbarIconFromPNG([MATLABdir '/file_open.png']);
set(Loadbut,'CData',icon_load);
fun=@(hObject,evnt) loadImage(hObject,tool,HeaderButton);
set(Loadbut,'Callback',fun)
set(Loadbut,'TooltipString','Load Image')
if length(tool)==1
Pos = get(tool(1).getHandles.Tools.ViewPlane,'Position');
Pos(1) = Pos(1) + 30;
set(tool(1).getHandles.Tools.ViewPlane,'Position',Pos);
end

% add LPI labels
if untouch
    [~,orient] = nii_get_orient(hdr);
else
    orient = {'L' 'P' 'I';
              'R' 'A' 'S'};
end
annotation(tool(1).getHandles.Panels.Image,'textbox','EdgeColor','none','String',orient{1,1},'Position',[0 0.5 0.05 0.05],'Color',[1 1 1]);
annotation(tool(1).getHandles.Panels.Image,'textbox','EdgeColor','none','String',orient{2,1},'Position',[1-0.05 0.5 0.05 0.05],'Color',[1 1 1]);
annotation(tool(1).getHandles.Panels.Image,'textbox','EdgeColor','none','String',orient{1,2},'Position',[0.5 0 0.05 0.05],'Color',[1 1 1]);
annotation(tool(1).getHandles.Panels.Image,'textbox','EdgeColor','none','String',orient{2,2},'Position',[0.5 1-0.05 0.05 0.05],'Color',[1 1 1]);

if length(tool)>1
    annotation(tool(2).getHandles.Panels.Image,'textbox','EdgeColor','none','String','P','Position',[0 0.5 0.05 0.05],'Color',[1 1 1]);
    annotation(tool(2).getHandles.Panels.Image,'textbox','EdgeColor','none','String','A','Position',[1-0.05 0.5 0.05 0.05],'Color',[1 1 1]);
    annotation(tool(2).getHandles.Panels.Image,'textbox','EdgeColor','none','String','S','Position',[0.5 1-0.05 0.05 0.05],'Color',[1 1 1]);
    annotation(tool(2).getHandles.Panels.Image,'textbox','EdgeColor','none','String','I','Position',[0.5 0 0.05 0.05],'Color',[1 1 1]);
    
    annotation(tool(3).getHandles.Panels.Image,'textbox','EdgeColor','none','String','L','Position',[0 0.5 0.05 0.05],'Color',[1 1 1]);
    annotation(tool(3).getHandles.Panels.Image,'textbox','EdgeColor','none','String','R','Position',[1-0.05 0.5 0.05 0.05],'Color',[1 1 1]);
    annotation(tool(3).getHandles.Panels.Image,'textbox','EdgeColor','none','String','S','Position',[0.5 1-0.05 0.05 0.05],'Color',[1 1 1]);
    annotation(tool(3).getHandles.Panels.Image,'textbox','EdgeColor','none','String','I','Position',[0.5 0 0.05 0.05],'Color',[1 1 1]);
end

% Add Drag and Drop feature
%             txt_drop = annotation(tool.handles.Panels.Image,'textbox','Visible','off','EdgeColor','none','FontSize',25,'String','DROP!','Position',[0.5 0.5 0.6 0.1],'FitBoxToText','on','Color',[1 0 0]);
wrn = warning('off','MATLAB:ui:javaframe:PropertyToBeRemoved');
jFrame = get(H.fig, 'JavaFrame');
jAxis = jFrame.getAxisComponent();
dndcontrol.initJava();
dndobj = dndcontrol(jAxis);
dndobj.DropFileFcn = @(s, e)onDrop(tool, s, e, HeaderButton); %,'DragEnterFcn',@(s,e) setVis(txt_drop,1),'DragExitFcn',@(s,e) setVis(txt_drop,0));
warning(wrn);

if exist('tool3P','var'), tool = tool3P; end

function loadImage(hObject,tool, HeaderButton)
hdr = get(HeaderButton,'UserData');
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');
if ~isfield(hdr,'file_name'), hdr.file_name = fullfile(pwd,'Mask.nii.gz'); end
path = fileparts(hdr.file_name);
[FileName,PathName] = uigetfile('*.nii;*.nii.gz','Load NIFTI',path,'MultiSelect', 'on');
if isequal(FileName,0)
    return;
end
if strcmp(hdr.file_name,'MRI EXAMPLE')
    [dat, hdr] = nii_load(fullfile(PathName,FileName));
    for ii=1:length(tool)
        tool(ii).setImage(dat(:))
        tool(ii).setNvol(1);
        tool(ii).setlabel(fullfile(PathName,FileName));
        tool(ii).setAspectRatio(hdr.pixdim(2:4))
    end
    set(HeaderButton, 'UserData',hdr)
    str = evalc('hdr');
    set(HeaderButton, 'TooltipString',str);
else
    if iscell(FileName)
        dat = nii_load([{hdr},fullfile(PathName,FileName)]);
    else
        dat = nii_load({hdr,fullfile(PathName,FileName)});
    end
    I = tool(1).getImage(1);
    for ii=1:length(tool)
        tool(ii).setImage([I(:)',dat(:)'])
        tool(ii).setNvol(1+length(I));
        tool(ii).setlabel(fullfile(PathName,FileName));
    end
end


function icon = makeToolbarIconFromPNG(filename)
% makeToolbarIconFromPNG  Creates an icon with transparent
%   background from a PNG image.

%   Copyright 2004 The MathWorks, Inc.
%   $Revision: 1.1.8.1 $  $Date: 2004/08/10 01:50:31 $

% Read image and alpha channel if there is one.
[icon,map,alpha] = imread(filename);

% If there's an alpha channel, the transparent values are 0.  For an RGB
% image the transparent pixels are [0, 0, 0].  Otherwise the background is
% cyan for indexed images.
if (ndims(icon) == 3) % RGB
    
    idx = 0;
    if ~isempty(alpha)
        mask = alpha == idx;
    else
        mask = icon==idx;
    end
    
else % indexed
    
    % Look through the colormap for the background color.
    if isempty(map), idx=1; icon = im2double(repmat(icon, [1 1 3])); return; end
    for i=1:size(map,1)
        if all(map(i,:) == [0 1 1])
            idx = i;
            break;
        end
    end
    
    mask = icon==(idx-1); % Zero based.
    icon = ind2rgb(icon,map);
    
end

% Apply the mask.
icon = im2double(icon);

for p = 1:3
    
    tmp = icon(:,:,p);
    if ndims(mask)==3
        tmp(mask(:,:,p))=NaN;
    else
        tmp(mask) = NaN;
    end
    icon(:,:,p) = tmp;
    
end


function openvar2(hdr)
assignin('base','hdr',hdr);
evalin('base', ['openvar hdr']);


function onDrop(tool, listener, evtArg, HeaderButton)
ht = wait_msgbox;

% Get back the dropped data
data = evtArg.Data;

% Is it transferable as a list of files
if length(data)==1 && isdir(data{1})
    imtool3D_BIDS(data{1})
else
    [~,~,ext] = fileparts(data{1});
    switch ext
        case {'.nii','.gz'}
            [dat, hdr] = nii_load(data);
        case {'.tif', '.png'}
            for id = 1:length(data)
                dat{id} = imread(data{id});
            end
            hdr.pixdim = [1 1 1 1];
        case '.mat'
            for id = 1:length(data)
                tmp = load(data{id});
                ff = fieldnames(tmp);
                dat{id} = tmp.(ff{1});
            end
            hdr.pixdim = [1 1 1 1];
        otherwise
            error('unknown format %s',ext)
    end
    for ii=1:length(tool)
        tool(ii).setImage(dat)
        tool(ii).setAspectRatio(hdr.pixdim(2:4));
        tool(ii).setlabel(data);
    end
    set(HeaderButton, 'UserData',hdr)
    str = evalc('hdr');
    set(HeaderButton, 'TooltipString',str)
end

if ishandle(ht), delete(ht); end

function h = setVis(h,value)
h.Visible = value;

function h = wait_msgbox
txt = 'Loading files. Please wait...';
h=figure('units','norm','position',[.5 .75 .2 .2],'menubar','none','numbertitle','off','resize','off','units','pixels');
ha=uicontrol('style','text','units','norm','position',[0 0 1 1],'horizontalalignment','center','string',txt,'units','pixels','parent',h);
hext=get(ha,'extent');
hext2=hext(end-1:end)+[60 60];
hpos=get(h,'position');
set(h,'position',[hpos(1)-hext2(1)/2,hpos(2)-hext2(2)/2,hext2(1),hext2(2)]);
set(ha,'position',[30 30 hext(end-1:end)]);
disp(char(txt));
drawnow;

