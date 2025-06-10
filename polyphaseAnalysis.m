%% ================================================================
%  局部函数: 多相分析滤波 + 抽取
% ================================================================
function [y_dec, h_ch, Fs_dec] = polyphaseAnalysis(rx_sig, fs, D, Rdec, h_proto)
M       = length(h_proto);
idx     = 0:M-1;
h_ch    = zeros(D, M);
for k = 1:D
    h_ch(k,:) = h_proto .* exp(1j*2*pi*(k-1)/D .* idx);
end

% 卷积 + 抽取
y_dec = cell(1,D);
for k = 1:D
    tmp      = filter(h_ch(k,:),1,rx_sig);
    y_dec{k} = tmp(Rdec:Rdec:end).';    % 行向量
end
Fs_dec = fs / Rdec;
end