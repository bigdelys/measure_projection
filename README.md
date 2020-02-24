Measure Projection Toolbox (MPT) is an open source Matlab toolbox for
probabilistic multi-subject EEG independent component source comparison
and inference (an alternative to IC clustering).

<center>

![\_Ersp\_measure\_projection\_and\_domains\_for\_wiki.png‎](_Ersp_measure_projection_and_domains_for_wiki.png‎
"_Ersp_measure_projection_and_domains_for_wiki.png‎")

</center>

<table>
<tbody>
<tr class="odd">
<td><p>Developed and Maintained by: Nima Bigdely-Shamlo (SCCN, INC, UCSD)<br />
Web: <a href="http://sccn.ucsd.edu/~nima">http://sccn.ucsd.edu/~nima</a><br />
Email: &lt;Nima's first name&gt; (at) sccn (dot) ucsd (dot) edu with help from: Özgür Yiğit Balkan</p></td>
</tr>
</tbody>
</table>

MPT includes derived data from LONI Probabilistic Brain Atlas (LPBA40):
Shattuck DW, Mirza M, Adisetiyo V, Hojatkashani C, Salamon G, Narr KL,
Poldrack RA, Bilder RM, Toga AW, Construction of a 3D Probabilistic
Atlas of Human Cortical Structures, NeuroImage (2007), doi:
10.1016/j.neuroimage.2007.09.031

# News

Measure Projection reference paper was recently published in NeuroImage
and made it to the cover of the magazine:

<center>

![\_Neuro\_image\_cover\_png\_small.png‎](_Neuro_image_cover_png_small.png‎
"_Neuro_image_cover_png_small.png‎")

</center>

Here is the reference:

`Bigdely-Shamlo, Nima, Mullen, Tim, Kreutz-Delgado,  Kenneth, Makeig, Scott, `  
`Measure Projection Analysis: A Probabilistic  Approach  to EEG Source Comparison and Multi-Subject Inference,`  
`NeuroImage (2013), Vol. 72, pp. 287-303, doi:   10.1016/j.neuroimage.2013.01.04 `[`(download`` 
 ``preprint)`](http://sccn.ucsd.edu/~nima/downloads/mpa_paper_preprint.pdf)

# Quick Start

Download the [latest version of the
toolbox](http://bitbucket.org/bigdelys/measure-projection/get/default.zip),
unzip it and place the folder under /plugins/ folder of EEGLAB
(10.2.5.5b or later, otherwise will likely encounter errors). If EEGLAB
is already running you may run:

`>> eeglab rebuild`

to load the toolbox. You should see 'Measure Projection' menu under
STUDY (if STUDY menu is active). You may also type:

`>> pr.getVersionString`

to obtain the version of the toolbox (and check if it is installed).
Load your EEGLAB study and look under <b>Study</b> to find <b>Measure
Projection</b> submenu. To use the toolbox you must have pre-computed
the measure(s) of interest and localized equivalent IC dipoles, similar
to what you would do before performing default EEGLAB IC clustering.

## Downloads

[The latest version of Measure Projection Toolbox
(MPT).](http://bitbucket.org/bigdelys/measure-projection/get/default.zip)

[MPT reference
paper.](http://sccn.ucsd.edu/~nima/downloads/mpa_paper_preprint.pdf)

Tutorial RSVP EEGLAB Study:
<ftp://sccn.ucsd.edu/pub/measure_projection/rsvp_study.zip> as a single
(4.7 GB) zip file\], or as an [FTP
folder](ftp://sccn.ucsd.edu/pub/measure_projection/rsvp_study/).

[Paper describing tutorial EEGLAB
Study](http://sccn.ucsd.edu/~nima/downloads/brain_activity_based_image_classification.pdf)

[Report an issue or make a
suggestion.](http://bitbucket.org/bigdelys/measure-projection/issues/new)

# Introduction

## Background

A crucial step in the analysis of multi-subject electroenceph
