clc;
clear;
close all;
%% 雷达对抗仿真工程，用于进行雷达信号侦查与干扰的全过程信号级仿真。
%% 仿真参数配置
% 仿真处理帧长 仿真采样率等
% 辐射源参数 （多个，位置，天线方向图样式，天线指向，信号样式及参数）
% 侦察接收机参数 （多个，参测、测向、定位体制）
%******************************************************************%
%仿真全局参数结构体
Global.fs = 200e6;%采样率 Hz
Global.frame = 10e-3;%仿真处理帧长 s

%雷达1信息结构体
%发射机参数
RADARpara(1).transmitter.startTime = 0;%开机时间 s
RADARpara(1).transmitter.endTime = 0;%关机时间 s
RADARpara(1).transmitter.P = 6e6;%发射功率 W
RADARpara(1).transmitter.ERP = 5e6;%有效辐射功率 W
%波形参数 用于定义辐射源发射信号的类型、脉内及脉组间参数的结构体，本结构体为理论最大结构体，参数不一定全部使用
RADARpara(1).signal.modulationType = 2;%信号类型 1-常规脉冲 2-LFM 3-NLFM 4-PSK 5-频率分集 6-频率捷变 7-复杂波形
RADARpara(1).signal.f0 = 25e6;%中心频率 Hz
RADARpara(1).signal.tau = 16.7e-6;%脉宽 s
RADARpara(1).signal.band = 2.5e6;%带宽 Hz
RADARpara(1).signal.fai0 = 0;%初相 rad
RADARpara(1).signal.pri = 1.67e-4;%重复间隔 s
%天线参数  指导生成天线方向图以及用于提取天线方向图中增益的参数
RADARpara(1).antenna.antennaType = 0;%天线类型 0-
RADARpara(1).antenna.azi = 45;%天线指向 方位角
RADARpara(1).antenna.ele = 0;%天线指向 俯仰角 度
RADARpara(1).antenna.gain = 10;%天线增益 dbi
%态势信息
RADARpara(1).position.locationX = 1e4;%X坐标 m
RADARpara(1).position.locationY = 300;%Y坐标 m
RADARpara(1).position.locationZ = 800;%Z坐标 m
RADARpara(1).position.locationLon = 45;%经度
RADARpara(1).position.locationLat = 30;%纬度
RADARpara(1).position.locationAlt = 300;%高度
RADARpara(1).position.VX = 100;%X速度分量 m
RADARpara(1).position.VY = 0;%Y速度分量 m
RADARpara(1).position.VZ = 0;%Z速度分量 m

%雷达2信息结构体
%发射机参数
RADARpara(2).transmitter.startTime = 0;%开机时间 s
RADARpara(2).transmitter.endTime = 0;%关机时间 s
RADARpara(2).transmitter.P = 5e6;%发射功率 W
RADARpara(2).transmitter.ERP = 5e6;%有效辐射功率 W
%波形参数 用于定义辐射源发射信号的类型、脉内及脉组间参数的结构体，本结构体为理论最大结构体，参数不一定全部使用
RADARpara(2).signal.modulationType = 2;%信号类型 1-常规脉冲 2-LFM 3-NLFM 4-PSK 5-频率分集 6-频率捷变 7-复杂波形
RADARpara(2).signal.f0 = 75e6;%中心频率 Hz
RADARpara(2).signal.tau = 30e-6;%脉宽 s
RADARpara(2).signal.band = 2.5e6;%带宽 Hz
RADARpara(2).signal.fai0 = 0;%初相 rad
RADARpara(2).signal.pri = 3e-4;%重复间隔 s
%天线参数  指导生成天线方向图以及用于提取天线方向图中增益的参数
RADARpara(2).antenna.antennaType = 0;%天线类型 0-
RADARpara(2).antenna.azi = 45;%天线指向 方位角
RADARpara(2).antenna.ele = 0;%天线指向 俯仰角 度
RADARpara(2).antenna.gain = 20;%天线增益 dbi
%态势信息
RADARpara(2).position.locationX = 1e4;%X坐标 m
RADARpara(2).position.locationY = -100;%Y坐标 m
RADARpara(2).position.locationZ = 500;%Z坐标 m
RADARpara(2).position.locationLon = 45;%经度
RADARpara(2).position.locationLat = 30;%纬度
RADARpara(2).position.locationAlt = 300;%高度
RADARpara(2).position.VX = 80;%X速度分量 m
RADARpara(2).position.VY = 0;%Y速度分量 m
RADARpara(2).position.VZ = 0;%Z速度分量 m

%侦察干扰方参数
%接收机参数  侦察接收机相关参数，包括信道化等
RADARCMpara(1).recerver.startTime = 0;%开机时间 s
RADARCMpara(1).recerver.endTime = 0;%关机时间 s
RADARCMpara(1).recerver.recerverF = 3;%接收机噪声系数 dB
RADARCMpara(1).recerver.bandStart = 2.4e9;%频段起点 Hz
RADARCMpara(1).recerver.bandEnd = 3e9;%频段起点 Hz
%天线参数  指导生成天线方向图以及用于提取天线方向图中增益的参数
RADARCMpara(1).antenna.antennaType = 0;%天线类型 0-
RADARCMpara(1).antenna.azi = 45;%天线指向 方位角
RADARCMpara(1).antenna.ele = 0;%天线指向 俯仰角 度
RADARCMpara(1).antenna.gain = 8;%天线增益 dbi
%测向相关参数  测向天线阵参数在此项目下配置
RADARCMpara(1).direction.type = 0;%测向体制
%定位相关参数  若多站定位需要配置多个侦察设备
RADARCMpara(1).location.type = 0;%定位体制
%态势信息
RADARCMpara(1).position.locationX = 0;%X坐标 m
RADARCMpara(1).position.locationY = 0;%Y坐标 m
RADARCMpara(1).position.locationZ = 0;%Z坐标 m
RADARCMpara(1).position.locationLon = 45;%经度
RADARCMpara(1).position.locationLat = 30;%纬度
RADARCMpara(1).position.locationAlt = 300;%高度 m
RADARCMpara(1).position.VX = 0;%X速度分量 m
RADARCMpara(1).position.VY = 0;%Y速度分量 m
RADARCMpara(1).position.VZ = 0;%Z速度分量 m
% ***** 新增子结构：信道化参数 *****
RADARCMpara(1).receiver.chPara.fs      = 200e6;   % ADC采样率
RADARCMpara(1).receiver.chPara.D       = 8;       % 信道数
RADARCMpara(1).receiver.chPara.Rdec    = 10;      % 抽取倍数
RADARCMpara(1).receiver.chPara.M       = 2048;    % FIR阶数
RADARCMpara(1).receiver.chPara.detector= 'oscfar';  % 'Energy' | 'CFAR'


%% 侦察 接收信号生成
% 构建场景，进行各辐射源到达各个侦察设备天线内的信号仿真，包括信号生成、时延、天线增益、相位变化、多普勒等调制，
% 若一个侦察设备涉及多个天线阵元，可能需要对多天线阵元分情况处理
%******************************************************************%
[receiveSignal] = radarcmReceiveSignalGen(Global,RADARpara,RADARCMpara);


%% 天线模型
% 可能直接包含在接收信号生成内，主要用于生成天线方向图并根据信号出射角度及信号入射角度提取发射接收增益
%******************************************************************%


%% 侦察 接收机仿真
%进行信号叠加 噪声叠加 低通滤波 数字信道化 信号检测
%******************************************************************%
[signal] = radarcmReceiverSim(Global,receiveSignal,RADARCMpara);



%% 侦察 信号处理仿真
% 侦察信号处理分为三部分独立进行，前端处理输出可能用于支撑后端处理算法
%******************************************************************%
% 侦察参测
[PDW_matrix_all] = radarcmParameterMeasurement(Global, signal, RADARCMpara);
% 侦察测向

% 侦察定位






















%% 侦察 信号识别仿真
% 后续进行

%% 干扰 干扰决策


%% 干扰 干扰生成



