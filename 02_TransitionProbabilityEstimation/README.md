# 02_Transition_Probability_Estimation
The second section of the project estimates the one-year transition probabilities across all 10 need states and death using multi-state modelling. The code was written in RStudio.

## Allowed instantaneous forward and reverse transitions

The allowed instantaneous forward and reverse transitions are shown in the table. 1 indicates that an instantaneous transition is allowed. 0 indicates that an instantaneous transition is not allowed.

### Table 1: Allowed instantaneous forward and reverse transitions

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

## Details of the Multi-state model

Through the [msm package](https://pages.github.com/) in R, we used an 11-state Markov model to estimate the transition probabilities of respondents across GI segments (GI I - GI V) and CF status (CF 0 or CF 1), where CF 0 indicates having no CF and CF 1 indicates having any of the five captured CFs. The states were as follows, with the GI segments ordered from least to most severe: (GI I, CF 0), (GI I, CF 1), (GI II, CF 0), (GI II, CF 1), (GI III, CF 0), (GI III, CF 1), (GI IV, CF 0), (GI IV, CF 1), (GI V, CF 0), (GI V, CF 1) and death.

## msm Formula

The following formula was used to estimate the transition probabilities:

```
msm(formula = HS ~ years, subject = hhidpn, data = dataT, 
    qmatrix = Q_HS, obstype = obstype, censor = 999)
```

| Arguments | Description | 
| --- | --- | 
| `Formula = HS ~ years` | state ~ time: A formula giving the vectors containing the observed states and the corresponding observation times. Observed states, named `HS` in the provided data frame, are numeric variables in the set 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 999 and defined as factors. The first ten numeric variables represent the states in order of severity, i.e. (GI I, CF 0), (GI I, CF 1), (GI II, CF 0), (GI II, CF 1), (GI III, CF 0), (GI III, CF 1), (GI IV, CF 0), (GI IV, CF 1), (GI V, CF 0), (GI V, CF 1). State 11 represents death and State 999 represents a censored state where the observation is known to be alive, and could therefore be in any state between 1 and 10. The times, termed `years` in the provided dataset, indicate different types of observation scheme described in obstype.|
| `subject = hhidpn` | Vector of subject identification numbers for the data specified by `formula`. The HRS ID, defined as `hhidpn` in the provided data frame, was used as subject identification.|  
| `data = dataT` | The data frame prepared in **01_PopulationSegmentation**, named `dataT`, was used to interpret the variables supplied in `formula`, `subject`, and `obstype`.|
| `qmatrix = Q_HS` | Matrix which indicates the allowed transitions in the continuous-time Markov chain, and optionally also the initial values of those transitions. Initial values were supplied by health services researchers familiar with the tool, and then adjusted by the `crudeinits.msm` function. Any diagonal entry of qmatrix is ignored, as it is constrained to be equal to minus the sum of the rest of the row. If an instantaneous transition is not allowed from state r to state s, then qmatrix has (r,s) entry 0, otherwise it is non-zero. The initial values supplied, are shown in Table 2.|
| `obstype = obstype` | A vector specifying the observation scheme, termed `obstype` was included in `dataT`. For all `HS` states except death (1, ..., 10, 999), `obstype` was defined as 1, meaning that the observation is at an arbitrary time (a "snapshot" of the process, or "panel-observed" data) and that the states are unknown between observation times. In contrast, death (`HS` = 11) is defined as 3, meaning that it is an exact transition time, but the state at the instant before entering this state is unknown.|
| `censor = 999` | Censoring means that the observed state is known only to be one of a particular set of states. For example, censor=999 indicates that all observations of 999 in the vector of observed states are censored states. By default, this means that the true state could have been any of the transient (non-absorbing) states.|

## Defined initial Transition Intensity Matrix

The allowed instantaneous forward and reverse transitions are shown in the table. 1 indicates that an instantaneous transition is allowed. 0 indicates that an instantaneous transition is not allowed.

### Table 2: Defined initial Transition Intensity Matrix

|       | **GI I, CF 0** | **GI I, CF 1** | **GI II, CF 0** | **GI II, CF 1** | **GI III, CF 0** | **GI III, CF 1** | **GI IV, CF 0** | **GI IV, CF 1**  | **GI V, CF 0** | **GI V, CF 1** | **Death** | 
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | 
| **GI I, CF 0**  | -|   0.005327283|  0.032481626|  0.002885611|  0.031889706|  0.007029053|  0.012134366|  0.002589651|  0.0025896513|  0.001849751| 0.009322745 | 
| **GI I, CF 1**  |0.0196887901|  -|  0.006351223|  0.020323912|  0.008891712|  0.045728803|  0.003810734|  0.019053668| 0.0025404890|  0.007621467| 0.020323912|
| **GI II, CF 0** | 0.0059707002|  0.000240754|  -|  0.012567361|  0.056962406|  0.017093537|  0.007993034|  0.003707612| 0.0014926751|  0.002455691| 0.011893250|
| **GI II, CF 1** | 0.0009741248|  0.001948250|  0.025814307|  -|  0.015585997|  0.069649924|  0.002191781|  0.012907154|  0.0004870624|  0.007792998| 0.024109589|
|**GI III, CF 0** | 0|  0|  0.016490029|  0.002241613|  -|            0.040555164|  0.010074377|  0.006467183|  0.0096105948|  0.013295086| 0.025611076|
|**GI III, CF 1** | 0|  0|  0.002187768|  0.008705494|  0.022196732|  -|            0.003372809|  0.018322559|  0.0024612393|  0.033545780| 0.046991439|
| **GI IV, CF 0** | 0|  0|  0|  0|  0.052727819|  0.019813870|  -|            0.018831364|  0.0072050435|  0.010480063| 0.045031522|
| **GI IV, CF 1** | 0|  0|  0|  0|  0.011164439|  0.045366610|  0.007265746|  -|            0.0023037732|  0.029594625| 0.098885033|
| **GI V, CF 0**  | 0|  0|  0|  0|  0.034646549|  0.019478705|  0.004949507|  0.003831876|  -|             0.064662915| 0.066259530|
| **GI V, CF 1**  | 0|  0|  0|  0|  0.005228908|  0.025167713|  0.000861908|  0.008504159|  0.0074124086|  -|           0.096648614|
| **Death**       | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
