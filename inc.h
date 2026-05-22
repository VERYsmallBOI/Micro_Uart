`define WORD_LEN 8
`define XTAL_CLK 50000000
`define BAUD 2400
`define CW (`XTAL_CLK / ((`BAUD * 2) * 16))
`define CWR $clog2(`CW)
`define WLR $clog2(`WORD_LEN)
