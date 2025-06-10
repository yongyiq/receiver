function [amplitude_coefficient] = Amplitude_Modulation(R,lamda,Gt,Gr)
    %% 幅度调制算法函数说明
    %% 输入
    %     R      辐射源到侦察站的距离
    %     lamda  信号波长
    %     Gt     辐射源天线增益
    %     Gr     侦察站天线增益
    %% 输出
    %     amplitude_coefficient        幅度衰减系数
    %自由空间传播损耗
    L=(4*pi*R/lamda)^2;
    %功率衰减系数A
    A=(Gt*Gr*lamda^2)/((4*pi)^3*R^4*L);
    %幅度衰减系数
    amplitude_coefficient=sqrt(A);
end

