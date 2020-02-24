Measure Projection Toolbox (MPT) is an open source Matlab toolbox for probabilistic multi-subject EEG independent component source comparison and inference (an alternative to IC clustering).

<center>
<embed src=" Ersp_measure_projection_and_domains_for_wiki.png‎" title=" Ersp_measure_projection_and_domains_for_wiki.png‎" width="747" />

</center>
|                                                                                              |
|----------------------------------------------------------------------------------------------|
| Developed and Maintained by: Nima Bigdely-Shamlo (SCCN, INC, UCSD)                           
 Web: <http://sccn.ucsd.edu/~nima>                                                             
 Email: <Nima's first name> (at) sccn (dot) ucsd (dot) edu with help from: Özgür Yiğit Balkan  |

MPT includes derived data from LONI Probabilistic Brain Atlas (LPBA40): Shattuck DW, Mirza M, Adisetiyo V, Hojatkashani C, Salamon G, Narr KL, Poldrack RA, Bilder RM, Toga AW, Construction of a 3D Probabilistic Atlas of Human Cortical Structures, NeuroImage (2007), doi: 10.1016/j.neuroimage.2007.09.031

News
====

Measure Projection reference paper was recently published in NeuroImage and made it to the cover of the magazine:

<center>
![]( Neuro_image_cover_png_small.png‎ " Neuro_image_cover_png_small.png‎")

</center>
Here is the reference:

`Bigdely-Shamlo, Nima, Mullen, Tim, Kreutz-Delgado,  Kenneth, Makeig, Scott,`
`Measure Projection Analysis: A Probabilistic  Approach  to EEG Source Comparison and Multi-Subject Inference,`
`NeuroImage (2013), Vol. 72, pp. 287-303, doi:   10.1016/j.neuroimage.2013.01.04 `[`(download` `preprint)`](http://sccn.ucsd.edu/~nima/downloads/mpa_paper_preprint.pdf)

Quick Start
===========

Download the [latest version of the toolbox](http://bitbucket.org/bigdelys/measure-projection/get/default.zip), unzip it and place the folder under /plugins/ folder of EEGLAB (10.2.5.5b or later, otherwise will likely encounter errors). If EEGLAB is already running you may run:

`>> eeglab rebuild`

to load the toolbox. You should see 'Measure Projection' menu under STUDY (if STUDY menu is active). You may also type:

`>> pr.getVersionString`

to obtain the version of the toolbox (and check if it is installed). Load your EEGLAB study and look under <b>Study</b> to find <b>Measure Projection</b> submenu. To use the toolbox you must have pre-computed the measure(s) of interest and localized equivalent IC dipoles, similar to what you would do before performing default EEGLAB IC clustering.

Downloads
---------

[The latest version of Measure Projection Toolbox (MPT).](http://bitbucket.org/bigdelys/measure-projection/get/default.zip)

[MPT reference paper.](http://sccn.ucsd.edu/~nima/downloads/mpa_paper_preprint.pdf)

Tutorial RSVP EEGLAB Study: <ftp://sccn.ucsd.edu/pub/measure_projection/rsvp_study.zip> as a single (4.7 GB) zip file\], or as an [FTP folder](ftp://sccn.ucsd.edu/pub/measure_projection/rsvp_study/).

[Paper describing tutorial EEGLAB Study](http://sccn.ucsd.edu/~nima/downloads/brain_activity_based_image_classification.pdf)

[Report an issue or make a suggestion.](http://bitbucket.org/bigdelys/measure-projection/issues/new)

Introduction
============

Background
----------

A crucial step in the analysis of multi-subject electroencephalographic (EEG) data using Independent Component Analysis (ICA) is combining information across multiple recordings from different subjects, each associated with its own set of independent component (IC) processes. IC clustering (e.g. as implemented in EEGLAB software) is a common method for analyzing multi-session data, but it is associated with some issues that limit its usefulness for statistical analysis of EEG signal:

-   High sensitivity to clustering parameters such as number of clusters and relative weights of different EEG measures (e.g. ERSP vs. ERP).
-   Difficulty in proper statistical evaluation of cluster memberships.
-   Discontinuous nature of clustering which confounds group comparisons.

Description
-----------

Measure Projection Analysis (MPA) is a novel probabilistic multi-subject inference method that overcomes IC clustering issues by abandoning the notion of distinct IC clusters. Instead, it searches voxel by voxel for brain regions having event-related IC process dynamics that exhibit statistically significant consistency across subjects and/or sessions as quantified by the values of various EEG measures. Local-mean EEG measure values are then assigned to all such locations based on a probabilistic model of IC localization error and inter-subject anatomical and functional differences.

MPA overcomes issues associated with IC clustering by reducing the number of analysis parameters while avoiding over-simplifying the implicit neurophysiological assumptions of cluster-based analysis. Instead of representing equivalent dipoles of independent components as points, Measure Projection models each of them by a Gaussian density. <m> \\text{P(y), y}\\in \\text{Brain Location} </m>

MPA calculates the expected value <m>E\\{M(y)\\}</m> (or ‘Projected value’) of the selected EEG measure M (e.g. ERSP of a certain experiment condition, like button-press) at brain locations spanning a regular grid (~8 mm spacing):

<center>
<m>\[E\left\{ M(y) \right\}=\langle M(y) \rangle=\frac{\sum\limits_{i=1}^{n}{{{P}_{i}}(}y){{M}_{i}}}{\sum\limits_{i=1}^{n}{{{P}_{i}}(}y)}\] </m>

</center>
Next, it obtains significance values for these brain locations to find out which brain areas, or neighborhoods, contain similarities between nearby dipoles which are highly unlikely to have occurred by chance. To do so, Convergence <m>C(y)</m> at each brain location is calculated:

<center>
<m> \[C\left( y \right)=E\left\{ S\left( y \right) \right\}=~\frac{\sum\limits_{i=1}^{n}{\sum\limits_{j=1,j\ne i}^{n}{{{P}_{i}}\left( y \right)~{{P}_{j}}\left( y \right){{S}_{i,j}}}}}{\sum\limits_{i=1}^{n}{\sum\limits_{j=1,j\ne i}^{n}{{{P}_{i}}\left( y \right)~{{P}_{j}}\left( y \right)}}}\]</m>

</center>
In this equation <m>P\_i(y)</m> is the probability density of dipole <m>i</m> at brain position <m>y</m> and <m>S\_{i,j}</m> is the degree of similarity (e.g. correlation) between measure vectors associated with dipoles <m>i</m> and <m>j</m> . Calculated convergence quantity <m>C(y)</m> is higher for areas with homogeneous (similar) measures and significance (p-values) may be obtained for each brain location by bootstrap statistics. Projected values associated with highly significant brain locations are then grouped based on their similarities and analyzed.

Here is a comparison between IC clustering and Measure Projection:

<center>
![](Clustering and mpa flowchart.png "Clustering and mpa flowchart.png")

</center>
Tutorial
========

-   [Install MPT in EEGLAB (version 10.2.5.5a) or later)](#Quick_Start "wikilink").
-   [Download and place tutorial toolbox on your computer](#Downloads "wikilink"). You may want to read [the paper](http://sccn.ucsd.edu/~nima/downloads/brain_activity_based_image_classification.pdf) that describes tutorial experimental RSVP paradigm.
-   Make sure your memory options are set:

<center>
![ 800px](Mpt tutorial memorysettings.png  " 800px")

</center>

### Loading the Study

Load tutorial study called **study\_rsvp.study** in EEGLAB by clicking **File** -&gt; **Load existing study**. You should now be able to see the Measure Project menu as shown to the right.

<center>
![ 500px](EEGLAB Measure Project Submenu.png  " 500px")

</center>

-   Go to **Study** -&gt; **Measure Projection** -&gt; **ERSP** -&gt; **Project**
-   Click **Show colored by Measure** under the ERSP menu

<center>
![ 250px](Mpt tutorial coloredbymeasure.png  " 250px")

</center>

-   Click **Create Domains** under the ERSP menu. Notice the 'Domains' submenu becomes available which takes some time to finish. Alternatively, you may load **study\_rsvp\_with\_ersp\_domains.study**, but this can crash Matlab 2009a on 32 bit Windows.
-   Click **Show colored by Domain** under the ERSP menu

<center>
|![ 300px](Mpt tutorial coloredbydomain.png  "fig: 300px")

</center>

`Note: if your Matlab crashed while loading study_rsvp_with_ersp_domains.study or study_rsvp_with_domains.study, try loading study_rsvp_with_erp_domains.study which is considerably smaller. If you do so, follow the tutorial steps for ERP instead of ERSP.`

### GUI: Condition Differences

-   Click on **ERSP** -&gt; **Domains** -&gt; **Domain 2** -&gt; **Show Measure**
-   Click on **ERSP** -&gt; **Domains** -&gt; **Domain 2** -&gt; **Show condition difference**

===GUI: Domain Dipoles===

-   Click on **ERSP** -&gt; **Domains** -&gt; **Domain 2** -&gt; **Show high contributing scalp maps**
-   Click on **ERSP** -&gt; **Domains** -&gt; **Domain 2** -&gt; **Show high contributing dipoles**

### GUI

-   Load **study\_rsvp\_with\_domains.study** in EEGLAB

<font color="green"> Note: </font>On Windows 21bit with Matlab 2009a, this operation may crash Matlab. You may choose instead to try loading files named study\_rsvp\_with\_{erp, ersp, ...}\_domains.study.

### Setting Options from GUI

1.  Select **Measure Projection** -&gt; **Options**
2.  Change **ERSP** -&gt; **Significance** from 0.01 to 0.001
3.  Close the figure
4.  Select **STUDY** -&gt; **Measure Projection** -&gt; **ERSP** -&gt; **Show colored by Measure**

Scripting
---------

### Projection from Script

This is the code than runs 'under the hood' when you use M&lt;PT GUI. You can use it as a basis for your scripts. The example below is for ERSP measure, you may replace 'ERSP' in the following commands with other measure names (ITC, ERP, Spec).

`// read the data (calculated measure, etc.) from STUDY`
`STUDY.measureProjection.ersp.object = pr.dipoleAndMeasureOfStudyErsp(STUDY, ALLEEG);`

`// define HeadGRID based on GUI options (you can change this in your script of course)`
`STUDY.measureProjection.ersp.headGrid = pr.headGrid(STUDY.measureProjection.option.headGridSpacing);`

`// do the actual projection`
`STUDY.measureProjection.ersp.projection = pr.meanProjection(STUDY.measureProjection.ersp.object,...`
`STUDY.measureProjection.ersp.object.getPairwiseMutualInformationSimilarity, ...`
`STUDY.measureProjection.ersp.headGrid, 'numberOfPermutations', ...`
`STUDY.measureProjection.option.numberOfPermutations, 'stdOfDipoleGaussian',...`
`STUDY.measureProjection.option.standardDeviationOfEstimatedDipoleLocation,'numberOfStdsToTruncateGaussian',...`
`STUDY.measureProjection.option.numberOfStandardDeviationsToTruncatedGaussaian, 'normalizeInBrainDipoleDenisty', ...`
`fastif(STUDY.measureProjection.option.normalizeInBrainDipoleDenisty,'on', 'off'));`

`// visualize significant voxels individually (voxel p < 0.01)`
`STUDY.measureProjection.ersp.projection.plotVoxel(0.01);`

`// visualize significant voxles as a volume (voxel p < 0.01)`
`STUDY.measureProjection.ersp.projection.plotVolume(0.01);`

`// create domains`

`// find out the significance level to use (e.g. corrected by FDR)`
`if STUDY.measureProjection.option.('erspFdrCorrection')`
`   significanceLevel = fdr(STUDY.measureProjection.ersp.projection.convergenceSignificance(...`
`STUDY.measureProjection.ersp.headGrid.insideBrainCube(:)), STUDY.measureProjection.option.(['erspSignificance']));`
`else`
`   significanceLevel = STUDY.measureProjection.option.('erspSignificance');`
`end;`

`maxDomainExemplarCorrelation = STUDY.measureProjection.option.('erspMaxCorrelation');`

`// the command below makes the domains using parameters significanceLevel and maxDomainExemplarCorrelation:`
`STUDY.measureProjection.(measureName).projection = ...`
`STUDY.measureProjection.(measureName).projection.createDomain(...`
`STUDY.measureProjection.(measureName).object, maxDomainExemplarCorrelation, significanceLevel);`

`// visualize domains (change 'voxle' to 'volume' for a different type of visualization)`
`STUDY.measureProjection.ersp.projection.plotVoxelColoredByDomain;`

### Finding ICs associated with a Domain

You may want to find out which ICs contribute most to a certain domain. This can be done by calculating the dipole mass that lays inside the domain as it provides the probability that the dipoles is located inside the domain volume. This may be obtained from getDipoleDensityContributionToRegionOfInterest() function in pr.dipole class:

`function [dipoleId sortedDipoleDensity orderOfDipoles dipoleDenisty dipoleDenistyInRegion] = getDipoleDensityContributionToRegionOfInterest(obj, regionOfInterest, projection, cutoffRatio)`
`           % [dipoleId sortedDipoleDensity orderOfDipoles dipoleDenistyInRegion dipoleDenistyInRegion] = getDipoleDensityContributionToRegionOfInterest(obj, projection, regionOfInterest, cutoffRatio)`
`           % projection is a type of meanProjection (or compatible).`
`           % return dipoles ids (in dipoleId)  which cumulatively contribute at least 'cutoffRatio' to the dipole`
`           % denisty over the region.`
`           %`
`           % cutoffRatio is either a scalar or a 2-vector. The first number contains the percent of`
`           % region (domain) dipole mass explained by selected dipoles after which there will be a no`
`           % other dipole selected. The second is the miminum dipole mass ratio contribution to the`
`           % region (dipoles with a  contribution less than this value will not be selected).`
`           % For example cutoffRatio = 0.98 requires selected dipoles to at least explain 98% of`
`           % dipoles mass in the region.`
`           % cutoffRatio = [1 0.05] means that all dipoles that at least contribute %5 of their`
`           % mass to the region will be selected.`
`           % default cutoffRatio is [1 0.05].`

For example, lets assume you have made 5 ERSP domains and want to find out ICs associated with domain \#3. Here is the code to do this:

`domainNumber = 3;`
`dipoleAndMeasure = STUDY.measureProjection.ersp.object; % get the ERSP and dipole data (dataAndMeasure object) from the STUDY structure.`
`domain = STUDY.measureProjection.ersp.projection.domain(domainNumber); % get the domain in a separate variable`
`projection  = STUDY.measureProjection.ersp.projection;`
`[dipoleId sortedDipoleDensity orderOfDipoles dipoleDenisty dipoleDenistyInRegion] = dipoleAndMeasure.getDipoleDensityContributionToRegionOfInterest(domain.membershipCube, projection, [1 0.05])% the last value, [1 0.05]) indicates that we want all the ICs that at least has a 0.05 chance of being in the domain. You may want to use 0.1 or even 0.5 to get fewer ICs.`

`domainICs = dipoleAndMeasure.createSubsetForId(dipoleId); % here we create a new variable that contain information only for dipoles associates with domain ICs.`

domainICs will have all the information you need to identify domain ICs, for example:

`>> domainICs`
`domainICs =`
` dipoleAndMeasureOfStudyErsp with properties:`
`                        time: [1x200 double]`
`                   frequency: [1x100 double]`
`                 conditionId: [1 2]`
`              conditionLabel: {'PM_C'  'NTaC & TarC'}`
`   relationshipToBrainVolume: 'insidebrain'`
`                    scalpmap: [1x1 pr.scalpmapOfStudy]`
`                   removedIc: [1x1 struct]`
`           linearizedMeasure: [40000x34 single]`
`                measureLabel: 'ERSP'`
`   numberOfMeasureDimensions: 2`
`                    location: [34x3 double]`
`                   direction: [34x3 double]`
`            residualVariance: []`
`            coordinateFormat: 'mni'`
`              numberOfGroups: 2`
`                 insideBrain: [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]`
`                   datasetId: [31 11 48 43 49 44 43 44 12 41 9 35 43 47 40 1 43 8 27 10 32 14 47 1 32 47 23 27 3 39 31 43 14 1]`
`      datasetIdAllConditions: [31 11 48 43 49 44 43 44 12 41 9 35 43 47 40 1 43 8 27 10 32 14 47 1 32 47 23 27 3 39 31 43 14 1]`
`                   groupName: {1x34 cell}`
`                 groupNumber: [1 1 2 1 1 2 1 2 2 1 1 1 1 1 2 1 1 2 1 2 2 2 1 1 2 1 1 1 1 1 1 1 2 1]`
`             uniqueGroupName: {'C'  'P'}`
`             numberInDataset: [17 12 29 26 14 37 37 53 26 82 6 83 33 48 12 62 23 40 12 11 29 20 32 24 33 21 1 4 58 13 42 10 8 1]`
`        icIndexForEachDipole: [1x34 double]`
`                 subjectName: {1x34 cell}`
`               subjectNumber: [13 43 32 27 33 28 27 28 44 25 41 17 27 31 24 19 27 40 9 42 14 46 31 19 14 31 5 9 35 23 13 27 46 19]`
`           uniqueSubjectName: {1x21 cell}`

of these fields, the most relevant ones are <b>datasetIdAllConditions</b> and <b>numberInDataset</b>. <b>datasetIdAllConditions</b> gives you the IDs in ALLEEG structure array of the dataset associated with each IC. <b>numberInDataset</b> gives you the IC number in the dataset. (for exmaple IC \#5 in dataset ALLEEG(10)).

### Exporting session projected measures for a Domain

You may want to have access to the measures projected to a domain from each session. This could be used to perform different types of statistics and try more complicated designs. It is also quite easy do to in MPT with the <b>getMeanProjectedMeasureForEachSession</b> function provided in <b>pr.dipoleAndMeasureOfStudy</b> class:

(for session)

` function [linearProjectedMeasure sessionConditionCell groupId uniqeDatasetId dipoleDensity] = getMeanProjectedMeasureForEachSession(obj, headGrid, regionOfInterestCube, projectionParameter, varargin)`
`           % [linearProjectedMeasure sessionConditionCell groupId uniqeDatasetId dipoleDensity] = getProjectedMeasureForEachSession(obj, headGrid, regionOfInterestCube, projectionParameter, (key, value pair options))`
`           %`
`           % projects each session (dataset) to provided position(s) and returns a NxS`
`           % matrix containing dipole-density-weghted- average measures for each session over the`
`           % region.`
`           %`
`           % N is the numbr of dimensions of the linearized measure.`
`           % S is the number of sessions (datasets)`
`           %`
`           % by setting 'calculateMeasure' to 'off' you can only get the total dipole density (much`
`           % faster and less memory).`
`           %`
`           % sessionConditionCell is a cell array of number of sessions x number of conditions,`
`           % each containing a single condition with the original shape (e.g. 2-D for ERSP).`

Here is an example code to export projected session data to domain \#3 on an ERSP projection:

`domainNumber = 3;`
`dipoleAndMeasure = STUDY.measureProjection.ersp.object; % get the ERSP and dipole data (dataAndMeasure object) from the STUDY structure.`
`domain = STUDY.measureProjection.ersp.projection.domain(domainNumber); % get the domain in a separate variable`
`projection  = STUDY.measureProjection.ersp.projection;`
`headGrid = STUDY.measureProjection.ersp.headGrid;`
`[linearProjectedMeasure sessionConditionCell groupId uniqeDatasetId dipoleDensity] = dipoleAndMeasure.getMeanProjectedMeasureForEachSession(headGrid, domain.membershipCube, projection.projectionParameter);`

<b>sessionConditionCell</b> variable will contain a cell array of <b>number of sessions x number of conditions</b>, each containing a single condition with the original shape (e.g. 2-D for ERSP). For example:

`>> sessionConditionCell`
`sessionConditionCell =`

`   [200x100 double]    [200x100 double]`
`   [200x100 double]    [200x100 double]`
`   [200x100 double]    [200x100 double]`
`   [200x100 double]    [200x100 double]...`

You can now use these in your own custom analysis.

### ROI-based Measure Projection

Instead of creating domains based on your data and then finding their associated anatomical areas you can directly use anatomical ROIs as “super voxels” and perform measure projection on them with two lines of code (change 'ersp' below to your desired measure):

`>> roiProjection = pr.regionOfInterestProjection(STUDY.measureProjection.ersp.object, STUDY.measureProjection.ersp.object.getPairwiseFishersZSimilarity, pr.headGrid);`

This makes an object that contains projection for AAL atlas ROIs. To see the output:

`>> roiProjection.makeReport(‘[name of your report]',‘[top report folder]’ );`

Currently the report only compares the first two conditions.
