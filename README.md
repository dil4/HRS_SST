# HRS_SST
Supplementary material of "Population segmentation and transition probability estimation using data on health and health-related social service needs from the US Health and Retirement Study"

This GitHub repository provides the code explained in the following manuscript:
* [Authors]. Population segmentation and transition probability estimation using data on health and health-related social service needs from the US Health and Retirement Study. *Submitted for publication.* (Link to article).

I recommend to first read the manuscript before using the code. 

## Data
This project requires raw data to be downloaded from the [Health and Retirement Study (HRS) platform for researchers](https://hrs.isr.umich.edu/). The raw data required for segmentation are public datasets, accessable to all persons with a registered HRS user account. Detailed instructions on downloading the data can be found in the first script of the first section in the project __01_Population_Segmentation__, called __01_Data_Extraction.ipynb__.

## 01_Population_Segmentation
This first section adapts a validated instrument for segmenting individuals by distinct, homogenous health and health-related social service needs to the Health and Retirement Study (HRS), a nationally representative survey dataset from the US population aged 50 years and older. The code was written in Jupyter Notebook in a markdown format.

The segmentation results per wave are shown in Table 1.

### Table 1: Segmentation results per wave
| **Wave** | **GI I, CF 0** | **GI I, CF 1** | **GI II, CF 0** | **GI II, CF 1** | **GI III, CF 0** | **GI III, CF 1** | **GI IV, CF 0** | **GI IV, CF 1**  | **GI V, CF 0** | **GI V, CF 1** | **Death** | **Not segmentable**  
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | 
| **8**  | 730 | 86 | 1201 | 184 | 2174 | 938 | 351 | 262 | 376 | 851 | - | 14 |
| **9** | 545 | 68 | 962 | 168 | 1968 | 927 | 297 | 281 | 356 | 840 | 1284 | 9 |
| **10** | 1046 | 100 | 1304 | 259 | 2272 | 1358 | 391 | 352 | 360 | 1005 | 1600 | 18 |
| **11** | 772 | 86 | 1142 | 236 | 1968 | 1348 | 582 | 459 | 272 | 1059 | 1199 | 18 |
| **12** | 667 | 85 | 960 | 243 | 1914 | 1300 | 505 | 441 | 275 | 1064 | 1341 | 20 |
| **13** | 863 | 114 | 971 | 248 | 2003 | 1499 | 447 | 398 | 259 | 1039 | 1477 | 28 |
| **14** | 678 | 97 | 859 | 228 | 1805 | 1283 | 403 | 405 | 226 | 921 | 1215 | 17 |

## 02_Transition_Probability_Estimation
The second section section of the project estimates the one-year transition probabilities across all 10 need states and death using multi-state modelling. The code was written in RStudio.

The allowed instantaneous forward and reverse transitions are shown in the table. 1 indicates that an instantaneous transition is allowed. 0 indicates that an instantaneous transition is not allowed.

### Table 2: Allowed instantaneous forward and reverse transitions

|       | **GI I, CF 0** | **GI I, CF 1** | **GI II, CF 0** | **GI II, CF 1** | **GI III, CF 0** | **GI III, CF 1** | **GI IV, CF 0** | **GI IV, CF 1**  | **GI V, CF 0** | **GI V, CF 1** | **Death** | 
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | 
| **GI I, CF 0**  | - | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 
| **GI I, CF 1**  | 1 | - | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| **GI II, CF 0** | 1 | 1 | - | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| **GI II, CF 1** | 1 | 1 | 1 | - | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
|**GI III, CF 0** | 0 | 0 | 1 | 1 | - | 1 | 1 | 1 | 1 | 1 | 1 |
|**GI III, CF 1** | 0 | 0 | 1 | 1 | 1 | - | 1 | 1 | 1 | 1 | 1 |
| **GI IV, CF 0** | 0 | 0 | 0 | 0 | 1 | 1 | - | 1 | 1 | 1 | 1 |
| **GI IV, CF 1** | 0 | 0 | 0 | 0 | 1 | 1 | 1 | - | 1 | 1 | 1 |
| **GI V, CF 0**  | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | - | 1 | 1 |
| **GI V, CF 1**  | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | - | 1 |
| **Death**       | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |




# Full list of contributors:
[Authors]
