function [Signal] = radarcmReceiveSignalGen(Global,RADARpara,RADARCMpara)
%% 函数说明
%功能： 本函数根据预设仿真场景，生成场景中各侦察接收机收到的来自所有辐射源的经传输相关调制后的信号，
%       仿真从辐射源发射信号生成开始至进入侦察机接收天线为止
%输入： 
%   Global          仿真全局参数结构体
%   RADARpara       雷达辐射源参数结构体
%   RADARCMpara     雷达对抗参数结构体
%输出：
%   Signal          进入侦察机天线后的信号
%Matlab版本 R2018b
%最后更新时间 2025.06.07
%%
%====================================辐射源仿真======================================%
for ii=1:length(RADARpara)
    %参数提取及预处理（第ii个辐射源）
    pw=RADARpara(ii).signal.tau;%脉宽
    fs=Global.fs;%采样率
    frame=Global.frame;%时长
    pri=RADARpara(ii).signal.pri;%重复间隔
    %基准信号生成 （单个脉冲）
    switch RADARpara(ii).signal.modulationType
        case 1%常规脉冲
            
        case 2%线性调频
            t=0:1/fs:pw-1/fs;   
            lfm_signal=lfm(pw,RADARpara(ii).signal.band,t);
            zeroNum=floor((pri-pw)*fs);%pri-pw的采样点补零
            single_signal=[lfm_signal,zeros(1,zeroNum)];
    end
    %脉组调制
    %根据基准信号及prt等参数生成脉冲组
    pulse_num=floor(frame/pri);%时长内包含的脉冲数（pri固定的情况下）
    signal=repmat(single_signal,pulse_num,1);%复制pulse_num个single_signal，形成矩阵
    signal_vector=reshape(signal',1,[]);%矩阵转成一行
    
    t=0:1/fs:frame-1/fs;
    if length(t)~=length(signal_vector)
        signal_vector=[signal_vector,zeros(1,abs(length(t)-length(signal_vector)))];
    end
    %发射机相关调制
%     功率，频率等
    A=sqrt(RADARpara(ii).transmitter.P);%功率  
    signal_midfreq=exp(1j * 2 * pi * RADARpara(ii).signal.f0 * t);%中频信号
%     signalInRadar
    signalInRadar(ii).index=ii;
    signalRadar=A.*signal_midfreq.*signal_vector;
    signalInRadar(ii).signal=signalRadar;
%     for i=1:length(signalInRadar)
%         figure;
%         subplot(2,1,1);
%         plot(t,signalInRadar(i).signal);
%         N = length(t);
%         f = (-N / 2 : N / 2 - 1) / N * fs;    
%         subplot(2,1,2);
%         plot(f / 1e6, abs(fftshift(fft(signalInRadar(i).signal))));
%     end
end
%====================================辐射源天线仿真======================================%
% for 循环所有RADARpara内包含的辐射源
%     %参数提取及预处理（第ii个辐射源的天线）
%     
%     %天线方向图生成（机扫/相扫等合成出天线方向图）
%     
%     %相对坐标系转换
%     
%     %提取出射角度及增益
% 
% end
%====================================侦察机天线仿真======================================%
% for 循环所有RADARCMpara内包含的侦察设备
%     %参数提取及预处理（第jj个侦察机的天线）
%     
%     %天线方向图生成（机扫/相扫等合成出天线方向图）
%     
%     %相对坐标系转换
%     
%     %提取入射角度及增益
% 
% end
%====================================侦察接收信号生成======================================%
for jj=1:length(RADARCMpara)
    %参数提取及预处理（第jj个侦察机）
    
    for ii=1:length(RADARpara)
        %第ii个辐射源至第jj个侦察设备信号仿真
        
        %根据出射角度进行辐射源天线增益计算
        
        %传输衰减调制(幅度调制)
        %辐射源到侦察站的距离
        distance=sqrt((RADARpara(ii).position.locationX-RADARCMpara(jj).position.locationX).^2+...
            (RADARpara(ii).position.locationY-RADARCMpara(jj).position.locationY).^2+...
            (RADARpara(ii).position.locationZ-RADARCMpara(jj).position.locationZ).^2);
        %波长
        lamda=3e8/RADARpara(ii).signal.f0;
        %幅度衰减系数
        amplitude_coefficient=Amplitude_Modulation(distance,lamda,RADARpara(ii).antenna.gain,RADARCMpara(jj).antenna.gain);
        A=amplitude_coefficient*sqrt(RADARpara(ii).transmitter.P);
        %延时调制
        delay_t=distance/3e8;
        %多普勒频移调制
        vr=sqrt((RADARpara(ii).position.VX-RADARCMpara(jj).position.VX).^2+...
            (RADARpara(ii).position.VY-RADARCMpara(jj).position.VY).^2+...
            (RADARpara(ii).position.VZ-RADARCMpara(jj).position.VZ).^2);
        fd=(2*vr)/lamda;
        %云雨等复杂衰减影响调制
        
        %多径等复杂影响调制
        
        %根据入射角度进行侦察天线增益计算
        
        %输出信号
        k=ii*jj;
        Signal(k).sender = ii;
        Signal(k).receiver = jj;
        t=0:1/fs:frame-1/fs;
        before_delay_signals=A.*exp(1j * 2 * pi * fd * t).*signalInRadar(ii).signal;%加上幅度调制和多普勒频移，不加时延              
        delay_samples=round(delay_t*fs);
        delay_signals=[zeros(1,delay_samples),before_delay_signals(1:end-delay_samples)];%加上时延
        Signal(k).signal =delay_signals;
        end
    end
end



