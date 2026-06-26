
//  Hermes Lite - 赫耳墨斯轻型软件定义无线电
//
//  本程序是自由软件；您可以根据自由软件基金会发布的 GNU 通用公共许可证
//  第 2 版或（根据您的选择）任何更高版本的条款重新分发和/或修改它。
//
//  本程序的发布是希望它有用，但不提供任何担保；甚至没有适销性或
//  特定用途适用性的暗示担保。有关详细信息，请参阅 GNU 通用公共许可证。
//
//  您应该已经收到一份 GNU 通用公共许可证的副本；如果没有，请写信给：
//  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

// (C) Steve Haynal KF7O 2014-2019
// 此 RTL 代码源自 www.openhpsdr.org，并已修改以支持
// Hermes-Lite 硬件，详见 http://github.com/softerhardware/Hermes-Lite2。

// 模块名称：hermeslite
// 功能描述：Hermes-Lite SDR 顶层模块，实例化核心模块并连接所有外部接口
// 主要接口：
//   - 电源控制输出
//   - 以太网 PHY 接口（RG MII）
//   - 时钟管理 I2C 接口
//   - RF 前端 AD9866 芯片接口
//   - LED 指示灯
//   - IO 扩展接口（UART、I2C、CW 键等）
module hermeslite (
  // ========== 电源管理输出 ==========
  output       pwr_clk3p3           ,  // 3.3V 时钟电源使能
  output       pwr_clk1p2           ,  // 1.2V 时钟电源使能
  output       pwr_envpa            ,  // PA 包络电源使能
  output       pwr_envop            ,  // 操作包络电源使能
  output       pwr_envbias          ,  // 偏置包络电源使能
  
  // ========== 以太网 PHY 接口（RG MII 模式） ==========
  input        phy_clk125           ,  // 125MHz 参考时钟输入
  output [3:0] phy_tx               ,  // RGMII 发送数据 [3:0]
  output       phy_tx_en            ,  // RGMII 发送使能
  output       phy_tx_clk           ,  // RGMII 发送时钟
  input  [3:0] phy_rx               ,  // RGMII 接收数据 [3:0]
  input        phy_rx_dv            ,  // RGMII 接收数据有效
  input        phy_rx_clk           ,  // RGMII 接收时钟
  input        phy_rst_n            ,  // PHY 复位（低电平有效）
  inout        phy_mdio             ,  // MDIO 管理数据 IO
  output       phy_mdc              ,  // MDIO 管理时钟
  
  // ========== 时钟管理模块 I2C 接口 ==========
  output       io_db1_1             ,  // DB1 连接器引脚 1（TX 包络 PWM 输出）
  inout        clk_sda1             ,  // 时钟芯片 I2C 数据线
  inout        clk_scl1             ,  // 时钟芯片 I2C 时钟线
  
  // ========== RF 前端 AD9866 收发器芯片接口 ==========
  output       rffe_ad9866_rst_n    ,  // AD9866 复位（低电平有效）
  output [5:0] rffe_ad9866_tx       ,  // AD9866 发送数据 [5:0]
  input  [5:0] rffe_ad9866_rx       ,  // AD9866 接收数据 [5:0]
  input        rffe_ad9866_rxsync   ,  // AD9866 接收帧同步
  input        rffe_ad9866_rxclk    ,  // AD9866 接收时钟
  output       rffe_ad9866_txquiet_n,// AD9866 发送静噪控制（低电平有效）
  output       rffe_ad9866_txsync   ,  // AD9866 发送帧同步
  output       rffe_ad9866_sdio     ,  // AD9866 SPI 数据 IO
  output       rffe_ad9866_sclk     ,  // AD9866 SPI 时钟
  output       rffe_ad9866_sen_n    ,  // AD9866 SPI 片选（低电平有效）
  input        rffe_ad9866_clk76p8  ,  // AD9866 76.8MHz 时钟输入
  output       rffe_rfsw_sel        ,  // RF 开关选择控制
  output       rffe_ad9866_mode     ,  // AD9866 模式控制
  output       rffe_ad9866_pga5     ,  // AD9866 PGA5 增益控制
  
  // ========== LED 指示灯输出 ==========
  output       io_led_d2            ,  // D2 LED（运行状态指示）
  output       io_led_d3            ,  // D3 LED（TX 活动指示）
  output       io_led_d4            ,  // D4 LED（ADC 75% 过载指示）
  output       io_led_d5            ,  // D5 LED（ADC 100% 过载指示）
  
  // ========== HL2Link 差分串行接口 ==========
  input  [1:0] io_link_rx           ,  // HL2Link 接收差分对
  output [1:0] io_link_tx           ,  // HL2Link 发送差分对
  
  // ========== 数字输入信号 ==========
  input        io_cn8               ,  // CN8 连接器输入（TX 抑制）
  input        io_cn9               ,  // CN9 连接器输入（HL2 ID 检测）
  input        io_cn10              ,  // CN10 连接器输入（备用 MAC 地址选择）
  
  // ========== I2C 总线接口 ==========
  inout        io_adc_scl           ,  // ADC 相关 I2C 时钟线
  inout        io_adc_sda           ,  // ADC 相关 I2C 数据线
  inout        io_scl2              ,  // 扩展 I2C 时钟线 2
  inout        io_sda2              ,  // 扩展 I2C 数据线 2
  
  // ========== DB1 连接器及其他 IO ==========
  input        io_db1_2             ,  // DB1 引脚 2（UART RX）
  output       io_db1_3             ,  // DB1 引脚 3（UART TX）
  output       io_db1_4             ,  // DB1 引脚 4（风扇 PWM 输出）
  input        io_db1_5             ,  // DB1 引脚 5（ATU 确认）
  output       io_db1_6             ,  // DB1 引脚 6（ATU 请求）
  input        io_phone_tip         ,  // 耳机 Tip 检测输入
  input        io_phone_ring        ,  // 耳机 Ring 检测输入
  input        io_tp2               ,  // 测试点 TP2 输入
  input        io_tp7               ,  // 测试点 TP7 输入
  input        io_tp8               ,  // 测试点 TP8 输入
  input        io_tp9               ,  // 测试点 TP9 输入
  
  // ========== 功放（PA）控制输出 ==========
  output       pa_inttr             ,  // 内部功放松弛控制
  output       pa_exttr             // 外部功放松弛控制
);


  hermeslite_core #(
    .BOARD        (5                                    ),
    .IP           ({8'd0,8'd0,8'd0,8'd0}                ),
    .MAC          ({8'h00,8'h1c,8'hc0,8'ha2,8'h13,8'hdd}),
    .NR           (4                                    ),
    .NT           (1                                    ),
    .UART         (1                                    ),
    .ATU          (1                                    ),
    .FAN          (1                                    ),
    .PSSYNC       (1                                    ),
    .CW           (1                                    ),
    .ASMII        (1                                    ),
    .HL2LINK      (1                                    ),
    .AK4951       (0                                    ),
    .FAST_LNA     (1                                    ),
    .EXTENDED_RESP(1                                    ),
    .EXTENDED_DEBUG_RESP(1                              )
  ) hermeslite_core_i (
    .pwr_clk3p3                (pwr_clk3p3           ),
    .pwr_clk1p2                (pwr_clk1p2           ),
    .pwr_envpa                 (pwr_envpa            ),
    .pwr_envop                 (pwr_envop            ),
    .pwr_envbias               (pwr_envbias          ),
    .phy_clk125                (phy_clk125           ),
    .phy_tx                    (phy_tx               ),
    .phy_tx_en                 (phy_tx_en            ),
    .phy_tx_clk                (phy_tx_clk           ),
    .phy_rx                    (phy_rx               ),
    .phy_rx_dv                 (phy_rx_dv            ),
    .phy_rx_clk                (phy_rx_clk           ),
    .phy_rst_n                 (phy_rst_n            ),
    .phy_mdio                  (phy_mdio             ),
    .phy_mdc                   (phy_mdc              ),
    .clk_sda1                  (clk_sda1             ),
    .clk_scl1                  (clk_scl1             ),
    .rffe_ad9866_rst_n         (rffe_ad9866_rst_n    ),
    .rffe_ad9866_tx            (rffe_ad9866_tx       ),
    .rffe_ad9866_rx            (rffe_ad9866_rx       ),
    .rffe_ad9866_rxsync        (rffe_ad9866_rxsync   ),
    .rffe_ad9866_rxclk         (rffe_ad9866_rxclk    ),
    .rffe_ad9866_txquiet_n     (rffe_ad9866_txquiet_n),
    .rffe_ad9866_txsync        (rffe_ad9866_txsync   ),
    .rffe_ad9866_sdio          (rffe_ad9866_sdio     ),
    .rffe_ad9866_sclk          (rffe_ad9866_sclk     ),
    .rffe_ad9866_sen_n         (rffe_ad9866_sen_n    ),
    .rffe_ad9866_clk76p8       (rffe_ad9866_clk76p8  ),
    .rffe_rfsw_sel             (rffe_rfsw_sel        ),
    .rffe_ad9866_mode          (rffe_ad9866_mode     ),
    .rffe_ad9866_pga5          (rffe_ad9866_pga5     ),
    .io_led_run                (io_led_d2            ),
    .io_led_tx                 (io_led_d3            ),
    .io_led_adc75              (io_led_d4            ),
    .io_led_adc100             (io_led_d5            ),
    .io_tx_envelope_pwm_out    (io_db1_1             ),
    .io_tx_envelope_pwm_out_inv(                     ),
    .io_tx_inhibit             (io_cn8               ),
    .io_id_hermeslite          (io_cn9               ),
    .io_alternate_mac          (io_cn10              ),
    .io_adc_scl                (io_adc_scl           ),
    .io_adc_sda                (io_adc_sda           ),
    .io_scl2                   (io_scl2              ),
    .io_sda2                   (io_sda2              ),
    .io_uart_txd               (io_db1_3             ),
    .io_uart_rxd               (io_db1_2             ),
    .io_cw_keydown             (                     ),
    .io_phone_tip              (io_phone_tip         ),
    .io_phone_ring             (io_phone_ring        ),
    .io_atu_ack                (io_db1_5             ),
    .io_atu_req                (io_db1_6             ),
    .pa_inttr                  (pa_inttr             ),
    .pa_exttr                  (pa_exttr             ),
    .fan_pwm                   (io_db1_4             ),
    .linkrx                    (io_link_rx           ),
    .linktx                    (io_link_tx           ),
    .pa_exttr_clone            (                     ),
    .io_ptt_in                 (1'b0                 ),
    .i2s_pdn                   (                     ),
    .i2s_bck                   (                     ),
    .i2s_lrck                  (                     ),
    .i2s_miso                  (1'b0                 ),
    .i2s_mosi                  (                     )
  );

endmodule



