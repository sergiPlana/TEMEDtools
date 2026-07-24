import matplotlib.pyplot as plt
import numpy as np
import array as ay
from scipy import ndimage
from scipy._lib._util import _asarray_validated
from scipy.cluster.vq import kmeans2
from skimage import filters, measure, morphology, segmentation
from collections import namedtuple

storageDir = 'D:\\FastADT_Storage\\'
targetImg = plt.imread(storageDir+'TargetImg.tif')

def segment_crystals(img, r=71, offset=5, r_footprint=5):
    offset = offset / 65536
    img = img * (1.0 / img.max())
    arr = img > filters.threshold_local(img, r, method='mean', offset=offset)
    arr = np.invert(arr)
    arr = morphology.binary_opening(arr, morphology.disk(3))
    arr = morphology.remove_small_objects(arr, min_size=4 * 4, connectivity=0)
    arr = morphology.binary_closing(arr, morphology.disk(r_footprint))
    arr = morphology.binary_erosion(arr, morphology.disk(r_footprint))
    bkg = np.invert(morphology.binary_dilation(arr, morphology.disk(r_footprint * 2)) | arr)
    markers = arr * 2 + bkg
    segmented = segmentation.random_walker(img, markers, beta=50, spacing=(5, 5), mode='bf')
    segmented = segmented.astype(int) - 1
    return arr, segmented

def isedge(prop):
    if (prop._slice[0].start == 0) or \
        (prop._slice[1].start == 0) or \
        (prop._slice[0].stop == prop._intensity_image.shape[0]) or \
            (prop._slice[1].stop == prop._intensity_image.shape[1]):

        hist, edges = np.histogram(prop.intensity_image[prop.image])
        if np.sum(hist) // hist[0] < 2:
            return True
    return False

def whiten(obs, check_finite=False):
    obs = _asarray_validated(obs, check_finite=check_finite)
    std_dev = np.std(obs, axis=0)
    zero_std_mask = std_dev == 0
    if zero_std_mask.any():
        std_dev[zero_std_mask] = 1.0
    return obs / std_dev, std_dev
    
with open(storageDir+"ImageSegmentation_parameters.txt", "r") as file:
    lines = file.readlines()
    r_mask = int(lines[0].strip())
    bs_filter=int(lines[1].strip())
    maxNumPositions=int(lines[2].strip())
    edgeDetect=int(lines[3].strip())
    pre_smth=int(lines[4].strip())
    px = py = float(lines[5].strip())

if pre_smth == 1:
    targetImg = ndimage.gaussian_filter(targetImg, sigma=(6, 6), order=0);

spread=5
offset=5

crystalPosition = namedtuple('CrystalPosition', ['x', 'y', 'isolated', 'n_clusters', 'area_pixel'])
arr, seg = segment_crystals(targetImg, bs_filter+1, offset, r_mask)
labels, numlabels = ndimage.label(1-seg)
props = measure.regionprops(labels, targetImg)

crystals = []
particle_edges = []
for prop in props:
    area = prop.area * px * py
    bbox = np.array(prop.bbox)
    origin = bbox[0:2]
    if isedge(prop):
        continue
    nclust = int(area // spread) + 1
    if nclust > 1:
        coordinates = np.argwhere(prop.image)
        w, std = whiten(coordinates)
        cluster_centroids, closest_centroids = kmeans2(w, nclust, iter=20, minit='points')
        xy = (cluster_centroids * std + origin[0:2])
        crystals.extend([crystalPosition(x, y, False, nclust, prop.area) for x, y in xy])
    else:
        x, y = prop.centroid
        crystals.append(crystalPosition(x, y, True, nclust, prop.area))
        
    edge_local = np.argwhere(segmentation.find_boundaries(prop.image, mode='outer'))
    edge_global = edge_local + origin[0:2]
    particle_edges.append(edge_global)

gaussianFiltered=ndimage.gaussian_filter(targetImg,20)

yInt, xInt = np.array([(crystal.x, crystal.y) for crystal in crystals]).T
intensityValues = gaussianFiltered[yInt.astype('int'),xInt.astype('int')]
orderByIntensity = np.argsort(intensityValues)[::-1]
crystals = [crystals[i] for i in orderByIntensity]
particle_edges = [particle_edges[i] for i in orderByIntensity]
        
index = 0
if len(crystals) < maxNumPositions:
    numCrystals = len(crystals)
else:
    numCrystals = maxNumPositions
StoreCrystalPosition = open(storageDir+"Segmentation_CrystalPositions.txt","w+")
StoreCrystalPosition.write(str(numCrystals)+"\n")
if len(crystals) > 0:
    y, x = np.array([(crystal.x, crystal.y) for crystal in crystals]).T
    for posX, posY in zip(x,y):
        if index < maxNumPositions:
            if edgeDetect==1:
                NParray_particle_edges = particle_edges[index]
                IntValues = gaussianFiltered[(NParray_particle_edges[:,0]-(0.1*(NParray_particle_edges[:,0]-posY))).astype('int'),
                                             (NParray_particle_edges[:,1]-(0.1*(NParray_particle_edges[:,1]-posX))).astype('int')]
                if len(NParray_particle_edges) == 0:
                    x[index] = posX
                    y[index] = posY
                else:
                    Index_minIntValue = np.argmin(IntValues)
                    x[index] = NParray_particle_edges[Index_minIntValue,1]-(0.1*(NParray_particle_edges[Index_minIntValue,1]-posX))
                    y[index] = NParray_particle_edges[Index_minIntValue,0]-(0.1*(NParray_particle_edges[Index_minIntValue,0]-posY))

            StoreCrystalPosition.write(str(x[index])+"\n")
            StoreCrystalPosition.write(str(y[index])+"\n")
            index += 1
        
StoreCrystalPosition.close()