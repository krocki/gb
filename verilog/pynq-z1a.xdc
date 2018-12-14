## this file is a general .xdc for the pynq-z1 board rev. c
## to use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## clock signal 125 mhz

set_property -dict { package_pin h16   iostandard lvcmos33 } [get_ports { clk }]; #io_l13p_t2_mrcc_35 sch=sysclk
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

##switches

set_property -dict { package_pin m20   iostandard lvcmos33 } [get_ports { sw[0] }]; #io_l7n_t1_ad2n_35 sch=sw[0]
set_property -dict { package_pin m19   iostandard lvcmos33 } [get_ports { sw[1] }]; #io_l7p_t1_ad2p_35 sch=sw[1]

##rgb leds

set_property -dict { package_pin l15   iostandard lvcmos33 } [get_ports { led_rgb[0] }]; #io_l22n_t3_ad7n_35 sch=led4_b
set_property -dict { package_pin g17   iostandard lvcmos33 } [get_ports { led_rgb[1] }]; #io_l16p_t2_35 sch=led4_g
set_property -dict { package_pin n15   iostandard lvcmos33 } [get_ports { led_rgb[2] }]; #io_l21p_t3_dqs_ad14p_35 sch=led4_r
set_property -dict { package_pin g14   iostandard lvcmos33 } [get_ports { led_rgb[3] }]; #io_0_35 sch=led5_b
set_property -dict { package_pin l14   iostandard lvcmos33 } [get_ports { led_rgb[4] }]; #io_l22p_t3_ad7p_35 sch=led5_g
set_property -dict { package_pin m15   iostandard lvcmos33 } [get_ports { led_rgb[5] }]; #io_l23n_t3_35 sch=led5_r

##leds

set_property -dict { package_pin r14   iostandard lvcmos33 } [get_ports { led[0] }]; #io_l6n_t0_vref_34 sch=led[0]
set_property -dict { package_pin p14   iostandard lvcmos33 } [get_ports { led[1] }]; #io_l6p_t0_34 sch=led[1]
set_property -dict { package_pin n16   iostandard lvcmos33 } [get_ports { led[2] }]; #io_l21n_t3_dqs_ad14n_35 sch=led[2]
set_property -dict { package_pin m14   iostandard lvcmos33 } [get_ports { led[3] }]; #io_l23p_t3_35 sch=led[3]

##buttons

set_property -dict { package_pin d19   iostandard lvcmos33 } [get_ports { btn[0] }]; #io_l4p_t0_35 sch=btn[0]
set_property -dict { package_pin d20   iostandard lvcmos33 } [get_ports { btn[1] }]; #io_l4n_t0_35 sch=btn[1]
set_property -dict { package_pin l20   iostandard lvcmos33 } [get_ports { btn[2] }]; #io_l9n_t1_dqs_ad3n_35 sch=btn[2]
set_property -dict { package_pin l19   iostandard lvcmos33 } [get_ports { btn[3] }]; #io_l9p_t1_dqs_ad3p_35 sch=btn[3]

#pmod header ja

set_property -dict { package_pin y18   iostandard lvcmos33 } [get_ports { ja[0] }]; #io_l17p_t2_34 sch=ja_p[1]
set_property -dict { package_pin y19   iostandard lvcmos33 } [get_ports { ja[1] }]; #io_l17n_t2_34 sch=ja_n[1]
set_property -dict { package_pin y16   iostandard lvcmos33 } [get_ports { ja[2] }]; #io_l7p_t1_34 sch=ja_p[2]
set_property -dict { package_pin y17   iostandard lvcmos33 } [get_ports { ja[3] }]; #io_l7n_t1_34 sch=ja_n[2]
set_property -dict { package_pin u18   iostandard lvcmos33 } [get_ports { ja[4] }]; #io_l12p_t1_mrcc_34 sch=ja_p[3]
set_property -dict { package_pin u19   iostandard lvcmos33 } [get_ports { ja[5] }]; #io_l12n_t1_mrcc_34 sch=ja_n[3]
set_property -dict { package_pin w18   iostandard lvcmos33 } [get_ports { ja[6] }]; #io_l22p_t3_34 sch=ja_p[4]
set_property -dict { package_pin w19   iostandard lvcmos33 } [get_ports { ja[7] }]; #io_l22n_t3_34 sch=ja_n[4]

#pmod header jb

set_property -dict { package_pin w14   iostandard lvcmos33 } [get_ports { jb[0] }]; #io_l8p_t1_34 sch=jb_p[1]
set_property -dict { package_pin y14   iostandard lvcmos33 } [get_ports { jb[1] }]; #io_l8n_t1_34 sch=jb_n[1]
set_property -dict { package_pin t11   iostandard lvcmos33 } [get_ports { jb[2] }]; #io_l1p_t0_34 sch=jb_p[2]
set_property -dict { package_pin t10   iostandard lvcmos33 } [get_ports { jb[3] }]; #io_l1n_t0_34 sch=jb_n[2]
set_property -dict { package_pin v16   iostandard lvcmos33 } [get_ports { jb[4] }]; #io_l18p_t2_34 sch=jb_p[3]
set_property -dict { package_pin w16   iostandard lvcmos33 } [get_ports { jb[5] }]; #io_l18n_t2_34 sch=jb_n[3]
set_property -dict { package_pin v12   iostandard lvcmos33 } [get_ports { jb[6] }]; #io_l4p_t0_34 sch=jb_p[4]
set_property -dict { package_pin w13   iostandard lvcmos33 } [get_ports { jb[7] }]; #io_l4n_t0_34 sch=jb_n[4]

##audio out

#set_property -dict { package_pin r18   iostandard lvcmos33 } [get_ports { aud_pwm }]; #io_l20n_t3_34 sch=aud_pwm
#set_property -dict { package_pin t17   iostandard lvcmos33 } [get_ports { aud_sd }]; #io_l20p_t3_34 sch=aud_sd

##mic input

#set_property -dict { package_pin f17   iostandard lvcmos33 } [get_ports { m_clk }]; #io_l6n_t0_vref_35 sch=m_clk
#set_property -dict { package_pin g18   iostandard lvcmos33 } [get_ports { m_data }]; #io_l16n_t2_35 sch=m_data

##chipkit single ended analog inputs
##note: the ck_an_p pins can be used as single ended analog inputs with voltages from 0-3.3v (chipkit analog pins a0-a5). 
##      these signals should only be connected to the xadc core. when using these pins as digital i/o, use pins ck_io[14-19].

#set_property -dict { package_pin d18   iostandard lvcmos33 } [get_ports { ck_an_n[0] }]; #io_l3n_t0_dqs_ad1n_35 sch=ck_an_n[0]
#set_property -dict { package_pin e17   iostandard lvcmos33 } [get_ports { ck_an_p[0] }]; #io_l3p_t0_dqs_ad1p_35 sch=ck_an_p[0]
#set_property -dict { package_pin e19   iostandard lvcmos33 } [get_ports { ck_an_n[1] }]; #io_l5n_t0_ad9n_35 sch=ck_an_n[1]
#set_property -dict { package_pin e18   iostandard lvcmos33 } [get_ports { ck_an_p[1] }]; #io_l5p_t0_ad9p_35 sch=ck_an_p[1]
#set_property -dict { package_pin j14   iostandard lvcmos33 } [get_ports { ck_an_n[2] }]; #io_l20n_t3_ad6n_35 sch=ck_an_n[2]
#set_property -dict { package_pin k14   iostandard lvcmos33 } [get_ports { ck_an_p[2] }]; #io_l20p_t3_ad6p_35 sch=ck_an_p[2]
#set_property -dict { package_pin j16   iostandard lvcmos33 } [get_ports { ck_an_n[3] }]; #io_l24n_t3_ad15n_35 sch=ck_an_n[3]
#set_property -dict { package_pin k16   iostandard lvcmos33 } [get_ports { ck_an_p[3] }]; #io_l24p_t3_ad15p_35 sch=ck_an_p[3]
#set_property -dict { package_pin h20   iostandard lvcmos33 } [get_ports { ck_an_n[4] }]; #io_l17n_t2_ad5n_35 sch=ck_an_n[4]
#set_property -dict { package_pin j20   iostandard lvcmos33 } [get_ports { ck_an_p[4] }]; #io_l17p_t2_ad5p_35 sch=ck_an_p[4]
#set_property -dict { package_pin g20   iostandard lvcmos33 } [get_ports { ck_an_n[5] }]; #io_l18n_t2_ad13n_35 sch=ck_an_n[5]
#set_property -dict { package_pin g19   iostandard lvcmos33 } [get_ports { ck_an_p[5] }]; #io_l18p_t2_ad13p_35 sch=ck_an_p[5]

##chipkit digital i/o low

#set_property -dict { package_pin t14   iostandard lvcmos33 } [get_ports { ck_io[0] }]; #io_l5p_t0_34 sch=ck_io[0]
#set_property -dict { package_pin u12   iostandard lvcmos33 } [get_ports { ck_io[1] }]; #io_l2n_t0_34 sch=ck_io[1]
#set_property -dict { package_pin u13   iostandard lvcmos33 } [get_ports { ck_io[2] }]; #io_l3p_t0_dqs_pudc_b_34 sch=ck_io[2]
#set_property -dict { package_pin v13   iostandard lvcmos33 } [get_ports { ck_io[3] }]; #io_l3n_t0_dqs_34 sch=ck_io[3]
#set_property -dict { package_pin v15   iostandard lvcmos33 } [get_ports { ck_io[4] }]; #io_l10p_t1_34 sch=ck_io[4]
#set_property -dict { package_pin t15   iostandard lvcmos33 } [get_ports { ck_io[5] }]; #io_l5n_t0_34 sch=ck_io[5]
#set_property -dict { package_pin r16   iostandard lvcmos33 } [get_ports { ck_io[6] }]; #io_l19p_t3_34 sch=ck_io[6]
#set_property -dict { package_pin u17   iostandard lvcmos33 } [get_ports { ck_io[7] }]; #io_l9n_t1_dqs_34 sch=ck_io[7]
#set_property -dict { package_pin v17   iostandard lvcmos33 } [get_ports { ck_io[8] }]; #io_l21p_t3_dqs_34 sch=ck_io[8]
#set_property -dict { package_pin v18   iostandard lvcmos33 } [get_ports { ck_io[9] }]; #io_l21n_t3_dqs_34 sch=ck_io[9]
#set_property -dict { package_pin t16   iostandard lvcmos33 } [get_ports { ck_io[10] }]; #io_l9p_t1_dqs_34 sch=ck_io[10]
#set_property -dict { package_pin r17   iostandard lvcmos33 } [get_ports { ck_io[11] }]; #io_l19n_t3_vref_34 sch=ck_io[11]
#set_property -dict { package_pin p18   iostandard lvcmos33 } [get_ports { ck_io[12] }]; #io_l23n_t3_34 sch=ck_io[12]
#set_property -dict { package_pin n17   iostandard lvcmos33 } [get_ports { ck_io[13] }]; #io_l23p_t3_34 sch=ck_io[13]

##chipkit digital i/o on outer analog header
##note: these pins should be used when using the analog header signals a0-a5 as digital i/o (chipkit digital pins 14-19)

#set_property -dict { package_pin y11   iostandard lvcmos33 } [get_ports { ck_io[14] }]; #io_l18n_t2_13 sch=ck_a[0]
#set_property -dict { package_pin y12   iostandard lvcmos33 } [get_ports { ck_io[15] }]; #io_l20p_t3_13 sch=ck_a[1]
#set_property -dict { package_pin w11   iostandard lvcmos33 } [get_ports { ck_io[16] }]; #io_l18p_t2_13 sch=ck_a[2]
#set_property -dict { package_pin v11   iostandard lvcmos33 } [get_ports { ck_io[17] }]; #io_l21p_t3_dqs_13 sch=ck_a[3]
#set_property -dict { package_pin t5    iostandard lvcmos33 } [get_ports { ck_io[18] }]; #io_l19p_t3_13 sch=ck_a[4]
#set_property -dict { package_pin u10   iostandard lvcmos33 } [get_ports { ck_io[19] }]; #io_l12n_t1_mrcc_13 sch=ck_a[5]

##chipkit digital i/o on inner analog header
##note: these pins will need to be connected to the xadc core when used as differential analog inputs (chipkit analog pins a6-a11)

#set_property -dict { package_pin b20   iostandard lvcmos33 } [get_ports { ck_io[20] }]; #io_l1n_t0_ad0n_35 sch=ad_n[0]
#set_property -dict { package_pin c20   iostandard lvcmos33 } [get_ports { ck_io[21] }]; #io_l1p_t0_ad0p_35 sch=ad_p[0]
#set_property -dict { package_pin f20   iostandard lvcmos33 } [get_ports { ck_io[22] }]; #io_l15n_t2_dqs_ad12n_35 sch=ad_n[12]
#set_property -dict { package_pin f19   iostandard lvcmos33 } [get_ports { ck_io[23] }]; #io_l15p_t2_dqs_ad12p_35 sch=ad_p[12]
#set_property -dict { package_pin a20   iostandard lvcmos33 } [get_ports { ck_io[24] }]; #io_l2n_t0_ad8n_35 sch=ad_n[8]
#set_property -dict { package_pin b19   iostandard lvcmos33 } [get_ports { ck_io[25] }]; #io_l2p_t0_ad8p_35 sch=ad_p[8]

##chipkit digital i/o high

#set_property -dict { package_pin u5    iostandard lvcmos33 } [get_ports { ck_io[26] }]; #io_l19n_t3_vref_13 sch=ck_io[26]
#set_property -dict { package_pin v5    iostandard lvcmos33 } [get_ports { ck_io[27] }]; #io_l6n_t0_vref_13 sch=ck_io[27]
#set_property -dict { package_pin v6    iostandard lvcmos33 } [get_ports { ck_io[28] }]; #io_l22p_t3_13 sch=ck_io[28]
#set_property -dict { package_pin u7    iostandard lvcmos33 } [get_ports { ck_io[29] }]; #io_l11p_t1_srcc_13 sch=ck_io[29]
#set_property -dict { package_pin v7    iostandard lvcmos33 } [get_ports { ck_io[30] }]; #io_l11n_t1_srcc_13 sch=ck_io[30]
#set_property -dict { package_pin u8    iostandard lvcmos33 } [get_ports { ck_io[31] }]; #io_l17n_t2_13 sch=ck_io[31]
#set_property -dict { package_pin v8    iostandard lvcmos33 } [get_ports { ck_io[32] }]; #io_l15p_t2_dqs_13 sch=ck_io[32]
#set_property -dict { package_pin v10   iostandard lvcmos33 } [get_ports { ck_io[33] }]; #io_l21n_t3_dqs_13 sch=ck_io[33]
#set_property -dict { package_pin w10   iostandard lvcmos33 } [get_ports { ck_io[34] }]; #io_l16p_t2_13 sch=ck_io[34]
#set_property -dict { package_pin w6    iostandard lvcmos33 } [get_ports { ck_io[35] }]; #io_l22n_t3_13 sch=ck_io[35]
#set_property -dict { package_pin y6    iostandard lvcmos33 } [get_ports { ck_io[36] }]; #io_l13n_t2_mrcc_13 sch=ck_io[36]
#set_property -dict { package_pin y7    iostandard lvcmos33 } [get_ports { ck_io[37] }]; #io_l13p_t2_mrcc_13 sch=ck_io[37]
#set_property -dict { package_pin w8    iostandard lvcmos33 } [get_ports { ck_io[38] }]; #io_l15n_t2_dqs_13 sch=ck_io[38]
#set_property -dict { package_pin y8    iostandard lvcmos33 } [get_ports { ck_io[39] }]; #io_l14n_t2_srcc_13 sch=ck_io[39]
#set_property -dict { package_pin w9    iostandard lvcmos33 } [get_ports { ck_io[40] }]; #io_l16n_t2_13 sch=ck_io[40]
#set_property -dict { package_pin y9    iostandard lvcmos33 } [get_ports { ck_io[41] }]; #io_l14p_t2_srcc_13 sch=ck_io[41]
#set_property -dict { package_pin y13   iostandard lvcmos33 } [get_ports { ck_io[42] }]; #io_l20n_t3_13 sch=ck_ioa

## chipkit spi

#set_property -dict { package_pin w15   iostandard lvcmos33 } [get_ports { ck_miso }]; #io_l10n_t1_34 sch=ck_miso
#set_property -dict { package_pin t12   iostandard lvcmos33 } [get_ports { ck_mosi }]; #io_l2p_t0_34 sch=ck_mosi
#set_property -dict { package_pin h15   iostandard lvcmos33 } [get_ports { ck_sck }]; #io_l19p_t3_35 sch=ck_sck
#set_property -dict { package_pin f16   iostandard lvcmos33 } [get_ports { ck_ss }]; #io_l6p_t0_35 sch=ck_ss

## chipkit i2c

#set_property -dict { package_pin p16   iostandard lvcmos33 } [get_ports { ck_scl }]; #io_l24n_t3_34 sch=ck_scl
#set_property -dict { package_pin p15   iostandard lvcmos33 } [get_ports { ck_sda }]; #io_l24p_t3_34 sch=ck_sda

##hdmi rx

#set_property -dict { package_pin h17   iostandard lvcmos33 } [get_ports { hdmi_rx_cec }]; #io_l13n_t2_mrcc_35 sch=hdmi_rx_cec
#set_property -dict { package_pin p19   iostandard tmds_33  } [get_ports { hdmi_rx_clk_n }]; #io_l13n_t2_mrcc_34 sch=hdmi_rx_clk_n
#set_property -dict { package_pin n18   iostandard tmds_33  } [get_ports { hdmi_rx_clk_p }]; #io_l13p_t2_mrcc_34 sch=hdmi_rx_clk_p
#set_property -dict { package_pin w20   iostandard tmds_33  } [get_ports { hdmi_rx_d_n[0] }]; #io_l16n_t2_34 sch=hdmi_rx_d_n[0]
#set_property -dict { package_pin v20   iostandard tmds_33  } [get_ports { hdmi_rx_d_p[0] }]; #io_l16p_t2_34 sch=hdmi_rx_d_p[0]
#set_property -dict { package_pin u20   iostandard tmds_33  } [get_ports { hdmi_rx_d_n[1] }]; #io_l15n_t2_dqs_34 sch=hdmi_rx_d_n[1]
#set_property -dict { package_pin t20   iostandard tmds_33  } [get_ports { hdmi_rx_d_p[1] }]; #io_l15p_t2_dqs_34 sch=hdmi_rx_d_p[1]
#set_property -dict { package_pin p20   iostandard tmds_33  } [get_ports { hdmi_rx_d_n[2] }]; #io_l14n_t2_srcc_34 sch=hdmi_rx_d_n[2]
#set_property -dict { package_pin n20   iostandard tmds_33  } [get_ports { hdmi_rx_d_p[2] }]; #io_l14p_t2_srcc_34 sch=hdmi_rx_d_p[2]
#set_property -dict { package_pin t19   iostandard lvcmos33 } [get_ports { hdmi_rx_hpd }]; #io_25_34 sch=hdmi_rx_hpd
#set_property -dict { package_pin u14   iostandard lvcmos33 } [get_ports { hdmi_rx_scl }]; #io_l11p_t1_srcc_34 sch=hdmi_rx_scl
#set_property -dict { package_pin u15   iostandard lvcmos33 } [get_ports { hdmi_rx_sda }]; #io_l11n_t1_srcc_34 sch=hdmi_rx_sda

##hdmi tx

#set_property -dict { package_pin g15   iostandard lvcmos33 } [get_ports { hdmi_tx_cec }]; #io_l19n_t3_vref_35 sch=hdmi_tx_cec
set_property -dict { package_pin l17   iostandard tmds_33  } [get_ports { clk_n }]; #io_l11n_t1_srcc_35 sch=hdmi_tx_clk_n
set_property -dict { package_pin l16   iostandard tmds_33  } [get_ports { clk_p }]; #io_l11p_t1_srcc_35 sch=hdmi_tx_clk_p
set_property -dict { package_pin k18   iostandard tmds_33  } [get_ports { data_n[0] }]; #io_l12n_t1_mrcc_35 sch=hdmi_tx_d_n[0]
set_property -dict { package_pin k17   iostandard tmds_33  } [get_ports { data_p[0] }]; #io_l12p_t1_mrcc_35 sch=hdmi_tx_d_p[0]
set_property -dict { package_pin j19   iostandard tmds_33  } [get_ports { data_n[1] }]; #io_l10n_t1_ad11n_35 sch=hdmi_tx_d_n[1]
set_property -dict { package_pin k19   iostandard tmds_33  } [get_ports { data_p[1] }]; #io_l10p_t1_ad11p_35 sch=hdmi_tx_d_p[1]
set_property -dict { package_pin h18   iostandard tmds_33  } [get_ports { data_n[2] }]; #io_l14n_t2_ad4n_srcc_35 sch=hdmi_tx_d_n[2]
set_property -dict { package_pin j18   iostandard tmds_33  } [get_ports { data_p[2] }]; #io_l14p_t2_ad4p_srcc_35 sch=hdmi_tx_d_p[2]
#set_property -dict { package_pin r19   iostandard lvcmos33 } [get_ports { hdmi_tx_hpdn }]; #io_0_34 sch=hdmi_tx_hpdn
#set_property -dict { package_pin m17   iostandard lvcmos33 } [get_ports { hdmi_tx_scl }]; #io_l8p_t1_ad10p_35 sch=hdmi_tx_scl
#set_property -dict { package_pin m18   iostandard lvcmos33 } [get_ports { hdmi_tx_sda }]; #io_l8n_t1_ad10n_35 sch=hdmi_tx_sda

##crypto sda 

#set_property -dict { package_pin j15   iostandard lvcmos33 } [get_ports { crypto_sda }]; #io_25_35 sch=crypto_sda
