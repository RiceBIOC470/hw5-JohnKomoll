%HW5
%GB Comments:
1a 70 questions asks to save an image in the repository. Or at the very least provide the script to visualize the image
1b 90 You may have improved the mask, but you learned many other approaches to segment cells. For example, using watershed would have greatly improved the image. 
1c 70 same issue has 1a
1d 90 same issue has 1b.
2yeast: 100 
2worm: 100
2bacteria: 90 Segmentation is still pretty poor and could have benefited in trying to implement imerode or watershed. 
2phase: 100
Overall: 90

% Note. You can use the code readIlastikFile.m provided in the repository to read the output from
% ilastik into MATLAB.

%% Problem 1. Starting with Ilastik

% Part 1. Use Ilastik to perform a segmentation of the image stemcells.tif
% in this folder. Be conservative about what you call background - i.e.
% don't mark something as background unless you are sure it is background.
% Output your mask into your repository. What is the main problem with your segmentation?  

% The main issue is that most of the cells, especially in the brighter
% region, are connected in the mask. It will be difficult to segment these
% cells apart from each other, especially in the large mass in the upper
% right.

% Part 2. Read you segmentation mask from Part 1 into MATLAB and use
% whatever methods you can to try to improve it. 

conservative_mask = ~logical(reshape(h5read('stemcells_Simple Segmentation conservative.h5', '/exported_data') - 1, 2048, 2048))';
conservative_mask = imopen(conservative_mask, strel('disk', 5));
% Smooth mask
rad = 7;
sigma = 5;
fgauss = fspecial('gaussian', rad, sigma);
conservative_mask = imfilter(conservative_mask, fgauss);
figure
imshow(conservative_mask)

% Part 3. Redo part 1 but now be more aggresive in defining the background.
% Try your best to use ilastik to separate cells that are touching. Output
% the resulting mask into the repository. What is the problem now?

% Now the nuclei are separated slightly better, but there is a high degree
% of uncertainty in the masking. The mask is very fuzzy, and the outlines
% of the cells are not clearly distinguishable.

% Part 4. Read your mask from Part 3 into MATLAB and try to improve
% it as best you can.

liberal_mask = ~logical(reshape(h5read('stemcells_Simple Segmentation liberal.h5', '/exported_data') - 1, 2048, 2048))';
% Smooth mask
rad = 7;
sigma = 5;
fgauss = fspecial('gaussian', rad, sigma);
liberal_mask = imfilter(liberal_mask, fgauss);
liberal_mask = imclose(liberal_mask, strel('disk', 3));
liberal_mask = imfilter(liberal_mask, fgauss);
figure
imshow(liberal_mask)


%% Problem 2. Segmentation problems.

% The folder segmentationData has 4 very different images. Use
% whatever tools you like to try to segment the objects the best you can. Put your code and
% output masks in the repository. If you use Ilastik as an intermediate
% step put the output from ilastik in your repository as well as an .h5
% file. Put code here that will allow for viewing of each image together
% with your final segmentation. 

img1 = 'segmentationData/bacteria.tif';
img2 = 'segmentationData/cellPhaseContrast.png';
img3 = 'segmentationData/worms.tif';
img4 = 'segmentationData/yeast.tif';

bac = im2double(imread(img1));
cellpc = im2double(imread(img2));
worm = im2double(imread(img3));
yeast = im2double(imread(img4));

% Work with bacteria image first, importing h5 file from ilastik
mask1 = ~logical(reshape(h5read('bacteria_Simple Segmentation.h5', '/exported_data') - 1, 546, 558))';
imwrite(mask1, 'Ilastik_bacteria_intermediate.tif')
mask1 = imopen(mask1, strel('disk', 1));
% Smooth mask
rad = 7;
sigma = 5;
fgauss = fspecial('gaussian', rad, sigma);
mask1 = imfilter(mask1, fgauss);
mask1 = imopen(mask1, strel('disk', 6));
figure
imshow(mask1)
imwrite(mask1, 'bacteria_mask.tif')


% Now work with cells in phase contrast
cellpc = abs(cellpc-1);

% Take a binary mask to get all nuclei as true
mask2 = cellpc > 0.5;

% Find connected components and only take those of appropriate area size
CC = bwconncomp(mask2);
cell_data = regionprops(CC, cellpc, 'Area');
area = [cell_data.Area];
noise_region = area > 2000 | area < 65;
sublist = CC.PixelIdxList(noise_region);
sublist = cat(1, sublist{:});
mask2(sublist) = 0;

% Remove last patch of noise and fill holes
mask2(730:820, 1320:1380) = 0;
mask2 = imfill(mask2, 'holes');
figure
imshow(mask2)
imwrite(mask2, 'phase_contrast_cells_mask.tif')


% Now work with worm image
worm = imadjust(abs(worm-1));

% Smooth image
rad = 5;
sigma = 5;
fgauss = fspecial('gaussian', rad, sigma);
worm = imfilter(worm, fgauss);

% Get rid of the outline of the image by subtracting it out
outline_mask = worm > 0.85;
outline_mask = imopen(outline_mask, strel('disk', 3));
outline_mask = imdilate(outline_mask, strel('disk', 3));
back = imopen(worm, strel('disk', 75));
worm = imsubtract(worm, back);
worm = imsubtract(worm, worm.*outline_mask);

% Smooth the image of just the worms
mask3 = worm > 0.11;
mask3 = imopen(mask3, strel('disk', 2));
figure
imshow(mask3)
imwrite(mask3, 'worms_mask.tif')

% % Now work with yeast image

% yeast = imadjust(abs(yeast - 1));
% 
% %% 
% % Normalize and subtract background noise
% yeast_dilate = imdilate(yeast, strel('disk', 50));
% yeast_norm = yeast./yeast_dilate;
% back = imopen(yeast_norm, strel('disk', 50));
% yeast_norm_bs = imsubtract(yeast_norm, back);
% imshow(yeast_norm_bs,[])
% 
% % Take mask and close holes in mask
% mask4 = yeast_norm_bs > 0.33;
% figure
% imshow(mask4)
% mask4 = imclose(mask4, strel('disk', 3));
% figure
% imshow(mask4)
% 
% % Get rid of noise in center
% mask4(225:275, 340:400) = 0;
% 
% figure
% imshow(mask4)

% Import mask from Ilastik and work with it
mask4b = ~logical(reshape(h5read('yeast_Simple Segmentation.h5', '/exported_data') - 1, 689, 525))';
imwrite(mask4b, 'ilastik_yeast_intermediate.tif')
mask4b = imopen(mask4b, strel('disk', 1));
mask4b = imerode(mask4b, strel('disk', 1));

% Smooth the image
rad = 5;
sigma = 5;
fgauss = fspecial('gaussian', rad, sigma);
mask4b = imfilter(mask4b, fgauss);

% Find connected components and only take those of appropriate area size
CC = bwconncomp(mask4b);
cell_data = regionprops(CC, yeast, 'Area');
area = [cell_data.Area];
noise_region = area > 50000 | area < 100;
sublist = CC.PixelIdxList(noise_region);
sublist = cat(1, sublist{:});
mask4b(sublist) = 0;

% Fill the holes
mask4b = imfill(mask4b, 'holes');

figure
imshow(mask4b)
imwrite(mask4b, 'yeast_mask.tif')

% % Perform watershed segmentation to get separated nuclei
% nucmin = imerode(mask4, strel('disk', 15));
% figure
% imshow(nucmin)
% outside = ~imdilate(mask4, strel('disk', 1));
% figure
% imshow(outside,[])
% basin = imcomplement(bwdist(outside));
% basin = imimposemin(basin, nucmin | outside);
% figure
% imshow(basin,[])
% L = watershed(basin);
% mask4 = L > 1;
% figure
% imshow(mask4)
% 
% 
% 
