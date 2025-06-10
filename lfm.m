function [LFM]=lfm(PW,B,t)
    %% 函数功能：产生lfm基带信号
    %% 输入
        %pw       脉宽
        %B        带宽
        %t        时间
    %% 输出
        %LFM      线性调频基带信号
    k=B/PW;            %调频斜率
    LFM=exp(1j*pi*k*t.^2);
end

