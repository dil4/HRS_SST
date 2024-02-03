# 02_Transition_Probability_Estimation
The second section of the project estimates the one-year transition probabilities across all 10 need states and death using multi-state modelling. The code was written in RStudio.

## Details of the Multi-state model

Through the [msm package](https://pages.github.com/) in R, we used an 11-state Markov model to estimate the transition probabilities of respondents across GI segments (GI I - GI V) and CF status (CF 0 or CF 1), where CF 0 indicates having no CF and CF 1 indicates having any of the five captured CFs. The states were as follows, with the GI segments ordered from least to most severe: (GI I, CF 0), (GI I, CF 1), (GI II, CF 0), (GI II, CF 1), (GI III, CF 0), (GI III, CF 1), (GI IV, CF 0), (GI IV, CF 1), (GI V, CF 0), (GI V, CF 1) and death.

## msm Formula

The following formula was used to estimate the transition probabilities:

```
msm(formula = HS ~ years, subject = hhidpn, data = dataT, 
    qmatrix = Q_HS,     obstype = obstype, censor = 999, 
    control = list(fnscale = x, maxit = 10000, trace = 2,
                   REPORT = 1))))
```


| **Formula = HS ~ years** | slkfdj |  
| :---: | :---: |  
| **GI I, CF 0**  | - |  

For example, what are the outcomes and predictors in the model? Are there any adjusting covariates? Is time included in the model?

f_data_msm_GI <- function(x) {
  print(x)
  return(tryCatch(msm(formula = HS ~ years, subject = hhidpn, data = dataT, 
                      qmatrix = Q_HS,     obstype = obstype, censor = 999, 
                      control = list(fnscale = x, maxit = 10000, trace = 2, 
                                     REPORT = 1))))

## Allowed instantaneous forward and reverse transitions

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




