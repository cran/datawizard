# data_to_long works - complex dataset

    Code
      str(long)
    Output
      'data.frame':	70000 obs. of  6 variables:
       $ gender     : int  1 1 1 1 1 1 1 1 1 1 ...
       $ education  : int  NA NA NA NA NA NA NA NA NA NA ...
       $ age        : int  16 16 16 16 16 16 16 16 16 16 ...
       $ Participant: num  61617 61617 61617 61617 61617 ...
       $ Item       : chr  "A1" "A2" "A3" "A4" ...
       $ Score      : int  2 4 3 4 4 2 3 3 4 4 ...

# don't convert factors to integer

    Code
      print(mtcars_long)
    Output
         cyl  hp drat    wt vs am gear carb am_f cyl_f id    g  value
      1    4  93 3.85 2.320  1  1    4    1    1     4  3  mpg  22.80
      2    4  93 3.85 2.320  1  1    4    1    1     4  3 qsec  18.61
      3    4  93 3.85 2.320  1  1    4    1    1     4  3 disp 108.00
      4    8 245 3.21 3.570  0  0    3    4    0     8  7  mpg  14.30
      5    8 245 3.21 3.570  0  0    3    4    0     8  7 qsec  15.84
      6    8 245 3.21 3.570  0  0    3    4    0     8  7 disp 360.00
      7    4  66 4.08 2.200  1  1    4    1    1     4 10  mpg  32.40
      8    4  66 4.08 2.200  1  1    4    1    1     4 10 qsec  19.47
      9    4  66 4.08 2.200  1  1    4    1    1     4 10 disp  78.70
      10   8 264 4.22 3.170  0  1    5    4    1     8 11  mpg  15.80
      11   8 264 4.22 3.170  0  1    5    4    1     8 11 qsec  14.50
      12   8 264 4.22 3.170  0  1    5    4    1     8 11 disp 351.00
      13   6 110 3.08 3.215  1  0    3    1    0     6  4  mpg  21.40
      14   6 110 3.08 3.215  1  0    3    1    0     6  4 qsec  19.44
      15   6 110 3.08 3.215  1  0    3    1    0     6  4 disp 258.00
      16   8 175 3.15 3.440  0  0    3    2    0     8  5  mpg  18.70
      17   8 175 3.15 3.440  0  0    3    2    0     8  5 qsec  17.02
      18   8 175 3.15 3.440  0  0    3    2    0     8  5 disp 360.00
      19   8 335 3.54 3.570  0  1    5    8    1     8 12  mpg  15.00
      20   8 335 3.54 3.570  0  1    5    8    1     8 12 qsec  14.60
      21   8 335 3.54 3.570  0  1    5    8    1     8 12 disp 301.00
      22   6 110 3.90 2.620  0  1    4    4    1     6  1  mpg  21.00
      23   6 110 3.90 2.620  0  1    4    4    1     6  1 qsec  16.46
      24   6 110 3.90 2.620  0  1    4    4    1     6  1 disp 160.00
      25   6 110 3.90 2.875  0  1    4    4    1     6  2  mpg  21.00
      26   6 110 3.90 2.875  0  1    4    4    1     6  2 qsec  17.02
      27   6 110 3.90 2.875  0  1    4    4    1     6  2 disp 160.00
      28   4  95 3.92 3.150  1  0    4    2    0     4  9  mpg  22.80
      29   4  95 3.92 3.150  1  0    4    2    0     4  9 qsec  22.90
      30   4  95 3.92 3.150  1  0    4    2    0     4  9 disp 140.80
      31   4  62 3.69 3.190  1  0    4    2    0     4  8  mpg  24.40
      32   4  62 3.69 3.190  1  0    4    2    0     4  8 qsec  20.00
      33   4  62 3.69 3.190  1  0    4    2    0     4  8 disp 146.70
      34   6 105 2.76 3.460  1  0    3    1    0     6  6  mpg  18.10
      35   6 105 2.76 3.460  1  0    3    1    0     6  6 qsec  20.22
      36   6 105 2.76 3.460  1  0    3    1    0     6  6 disp 225.00

