# rescale_weights works as expected

    Code
      head(rescale_weights(nhanes_sample, "WTINT2YR", "SDMVSTRA"))
    Output
        total  age RIAGENDR RIDRETH1 SDMVPSU SDMVSTRA WTINT2YR rescaled_weights_a
      1     1 2.20        1        3       2       31 97593.68          1.5733612
      2     7 2.08        2        3       1       29 39599.36          0.6231745
      3     3 1.48        2        1       2       42 26619.83          0.8976966
      4     4 1.32        2        4       2       33 34998.53          0.7083628
      5     1 2.00        2        1       1       41 14746.45          0.4217782
      6     6 2.20        2        4       1       38 28232.10          0.6877550
        rescaled_weights_b
      1          1.2005159
      2          0.5246593
      3          0.5439111
      4          0.5498944
      5          0.3119698
      6          0.5155503

---

    Code
      head(rescale_weights(nhanes_sample, "WTINT2YR", c("SDMVSTRA", "SDMVPSU")))
    Output
        total  age RIAGENDR RIDRETH1 SDMVPSU SDMVSTRA WTINT2YR pweight_a_SDMVSTRA
      1     1 2.20        1        3       2       31 97593.68          1.5733612
      2     7 2.08        2        3       1       29 39599.36          0.6231745
      3     3 1.48        2        1       2       42 26619.83          0.8976966
      4     4 1.32        2        4       2       33 34998.53          0.7083628
      5     1 2.00        2        1       1       41 14746.45          0.4217782
      6     6 2.20        2        4       1       38 28232.10          0.6877550
        pweight_b_SDMVSTRA pweight_a_SDMVPSU pweight_b_SDMVPSU
      1          1.2005159         1.8458164         1.3699952
      2          0.5246593         0.8217570         0.5780808
      3          0.5439111         0.5034683         0.3736824
      4          0.5498944         0.6619369         0.4913004
      5          0.3119698         0.3060151         0.2152722
      6          0.5155503         0.5858662         0.4121388

---

    Code
      head(rescale_weights(nhanes_sample, probability_weights = "WTINT2YR", method = "kish"))
    Output
        total  age RIAGENDR RIDRETH1 SDMVPSU SDMVSTRA WTINT2YR rescaled_weights
      1     1 2.20        1        3       2       31 97593.68        1.3952529
      2     7 2.08        2        3       1       29 39599.36        0.5661343
      3     3 1.48        2        1       2       42 26619.83        0.3805718
      4     4 1.32        2        4       2       33 34998.53        0.5003582
      5     1 2.00        2        1       1       41 14746.45        0.2108234
      6     6 2.20        2        4       1       38 28232.10        0.4036216

---

    Code
      rescale_weights(nhanes_sample, "WTINT2YR", "SDMVSTRA")
    Output
         total  age RIAGENDR RIDRETH1 SDMVPSU SDMVSTRA WTINT2YR rescaled_weights_a
      1      1 2.20        1        3       2       31 97593.68          1.0000000
      2      7 2.08        2        3       1       29 39599.36          0.5819119
      3      3 1.48        2        1       2       42       NA                 NA
      4      4 1.32        2        4       2       33 34998.53          0.6766764
      5      1 2.00        2        1       1       41 14746.45          0.7471696
      6      6 2.20        2        4       1       38 28232.10          1.0000000
      7    350 1.60        1        3       2       33 93162.43          1.8012419
      8     NA 1.48        2        3       1       29 82275.99          1.2090441
      9      3 2.28        2        4       1       41 24726.39          1.2528304
      10    30 0.84        1        3       2       35       NA                 NA
      11    70 1.24        1        4       2       33 27002.70          0.5220817
      12     5 1.68        2        1       2       39 18792.03          1.0000000
      13    60 2.20        1        3       2       30 76894.56          1.0000000
      14     2 1.48        2        3       1       29       NA                 NA
      15     8 2.36        2        3       2       39       NA                 NA
      16     3 2.04        2        3       2       36 98200.91          1.0000000
      17     1 2.08        1        3       1       40 87786.09          1.0000000
      18     7 1.00        1        3       2       32 90803.16          1.0000000
      19     9 2.28        2        3       2       34       NA                 NA
      20     2 1.24        2        3       1       29 82275.99          1.2090441
         rescaled_weights_b
      1           1.0000000
      2           0.5351412
      3                  NA
      4           0.5107078
      5           0.7022777
      6           1.0000000
      7           1.3594509
      8           1.1118681
      9           1.1775572
      10                 NA
      11          0.3940306
      12          1.0000000
      13          1.0000000
      14                 NA
      15                 NA
      16          1.0000000
      17          1.0000000
      18          1.0000000
      19                 NA
      20          1.1118681

---

    Code
      rescale_weights(nhanes_sample, "WTINT2YR", method = "kish")
    Output
         total  age RIAGENDR RIDRETH1 SDMVPSU SDMVSTRA WTINT2YR rescaled_weights
      1      1 2.20        1        3       2       31 97593.68        1.2734329
      2      7 2.08        2        3       1       29 39599.36        0.5167049
      3      3 1.48        2        1       2       42       NA               NA
      4      4 1.32        2        4       2       33 34998.53        0.4566718
      5      1 2.00        2        1       1       41 14746.45        0.1924164
      6      6 2.20        2        4       1       38 28232.10        0.3683813
      7    350 1.60        1        3       2       33 93162.43        1.2156126
      8     NA 1.48        2        3       1       29 82275.99        1.0735629
      9      3 2.28        2        4       1       41 24726.39        0.3226377
      10    30 0.84        1        3       2       35       NA               NA
      11    70 1.24        1        4       2       33 27002.70        0.3523397
      12     5 1.68        2        1       2       39 18792.03        0.2452044
      13    60 2.20        1        3       2       30 76894.56        1.0033444
      14     2 1.48        2        3       1       29       NA               NA
      15     8 2.36        2        3       2       39       NA               NA
      16     3 2.04        2        3       2       36 98200.91        1.2813563
      17     1 2.08        1        3       1       40 87786.09        1.1454605
      18     7 1.00        1        3       2       32 90803.16        1.1848281
      19     9 2.28        2        3       2       34       NA               NA
      20     2 1.24        2        3       1       29 82275.99        1.0735629

# rescale_weights nested works as expected

    Code
      rescale_weights(data = head(nhanes_sample, n = 30), by = c("SDMVSTRA",
        "SDMVPSU"), probability_weights = "WTINT2YR", nest = TRUE)
    Output
         total  age RIAGENDR RIDRETH1 SDMVPSU SDMVSTRA  WTINT2YR rescaled_weights_a
      1      1 2.20        1        3       2       31 97593.679          1.0000000
      2      7 2.08        2        3       1       29 39599.363          0.5502486
      3      3 1.48        2        1       2       42 26619.834          0.9512543
      4      4 1.32        2        4       2       33 34998.530          0.6766764
      5      1 2.00        2        1       1       41 14746.454          0.7147710
      6      6 2.20        2        4       1       38 28232.100          1.0000000
      7    350 1.60        1        3       2       33 93162.431          1.8012419
      8     NA 1.48        2        3       1       29 82275.986          1.1432570
      9      3 2.28        2        4       1       41 24726.391          1.1985056
      10    30 0.84        1        3       2       35 39895.048          1.0000000
      11    70 1.24        1        4       2       33 27002.703          0.5220817
      12     5 1.68        2        1       2       39 18792.034          0.3866720
      13    60 2.20        1        3       2       30 76894.563          1.0000000
      14     2 1.48        2        3       1       29 82275.986          1.1432570
      15     8 2.36        2        3       2       39 78406.811          1.6133280
      16     3 2.04        2        3       2       36 98200.912          1.0000000
      17     1 2.08        1        3       1       40 87786.091          1.0000000
      18     7 1.00        1        3       2       32 90803.158          1.2693642
      19     9 2.28        2        3       2       34 45002.917          1.0000000
      20     2 1.24        2        3       1       29 82275.986          1.1432570
      21     4 2.28        2        3       1       34 91437.145          1.4088525
      22     3 1.04        1        1       2       42 29348.027          1.0487457
      23     4 1.12        1        1       1       34 38366.567          0.5911475
      24     1 1.52        2        1       1       42  6622.334          1.0000000
      25    22 2.24        1        4       1       41 22420.209          1.0867233
      26     7 1.00        2        3       2       41 65529.204          1.0000000
      27     5 0.92        2        4       1       30 27089.745          1.0000000
      28    15 1.04        1        3       2       32 52265.570          0.7306358
      29     3 0.80        1        3       1       33 64789.307          1.0000000
      30     1 1.00        1        3       1       29 73404.222          1.0199804
         rescaled_weights_b
      1           1.0000000
      2           0.5226284
      3           0.9489993
      4           0.5107078
      5           0.6854605
      6           1.0000000
      7           1.3594509
      8           1.0858702
      9           1.1493587
      10          1.0000000
      11          0.3940306
      12          0.2809766
      13          1.0000000
      14          1.0858702
      15          1.1723308
      16          1.0000000
      17          1.0000000
      18          1.1834934
      19          1.0000000
      20          1.0858702
      21          1.2070771
      22          1.0462596
      23          0.5064835
      24          1.0000000
      25          1.0421602
      26          1.0000000
      27          1.0000000
      28          0.6812093
      29          1.0000000
      30          0.9687816

