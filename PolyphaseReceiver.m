% PolyphaseReceiver.m   (stand‑alone版本, 2025‑06‑09)
% ---------------------------------------------------------------------
% 一个文件 = 一个外部可见主函数 + 若干局部函数
%   • 主函数  : PolyphaseReceiver  —— 供项目其他脚本直接调用
%   • 局部函数: localPolyphaseAnalysis —— 封装多相滤波 + 抽取
%               (外部无需再单独准备 PolyphaseAnalysis.m)
% ---------------------------------------------------------------------
%  用法
%  -----
%   cfg = struct();
%   cfg.fs         = 200e6;   % 采样率
%   cfg.D          = 8;       % 子信道数
%   cfg.Rdec       = 10;      % 抽取倍率
%   cfg.M          = 1024;    % FIR 阶数 (可选, 默认 1024)
%   cfg.detector   = 'Energy';% 'Energy' | 'CFAR'
%   cfg.combine_adjacent = false; % 合并邻道能量再做检测
%   cfg.do_baseband= true;    % 是否输出基带
%   cfg.do_recon   = false;   % 是否综合重构
%   % 可选自定义原型低通, 否则自动 fir1()
%   % cfg.h_proto  = [...];
%   rx_out = PolyphaseReceiver(rx_sig, cfg);
% ---------------------------------------------------------------------

function rx_out = PolyphaseReceiver(rx_sig, cfg)
%POLYPHASERECEIVER  多相滤波数字信道化 + (可选)基带还原 + (可选)综合重构
%
%  输入
%  ----
%  rx_sig : 列/行复向量, ADC 基带或IF信号
%  cfg    : 结构体, 字段见文件头说明
%
%  输出 (rx_out)
%  ----
%  .active_ch        检测到的信道号 (行向量)
%  .y_dec{ch}        抽取后子带信号 (行向量, D×1 cell)
%  .y_base{ch}       (可选) 已下变频到 0 Hz 的子带
%  .rx_recon         (可选) 综合重构信号 (列向量)
%  .Fs_dec           抽取后采样率
%  .energy_per_ch    每子带能量
%  .h_ch             分析滤波器系数 (D×M)
%  .param            一份 cfg 归档
%
%  注意: 本函数完全 self‑contained, 仅依赖 Signal Processing Toolbox 的
%        fir1 / filter / upfirdn
% ------------------------------------------------------------------

%% ---------- 0. 输入整理 & 默认值 ----------
% arguments
%     rx_sig                     {mustBeNumeric}
%     cfg.fs        (1,1) double {mustBePositive}
%     cfg.D         (1,1) double {mustBeInteger,mustBePositive}
%     cfg.Rdec      (1,1) double {mustBeInteger,mustBePositive}
%     cfg.M         (1,1) double {mustBeInteger,mustBePositive}  = 1024
%     cfg.detector           char               = 'Energy'
%     cfg.do_baseband        logical            = false
%     cfg.do_recon           logical            = false
%     cfg.h_proto            double             = []
%     cfg.cfar_win   (1,1) double {mustBeInteger,mustBeNonnegative} = 2
%     cfg.cfar_alpha (1,1) double {mustBePositive} = 4.5
% end

% 强制列向量
if size(rx_sig,1)==1; rx_sig = rx_sig.'; end

fs    = cfg.fs;
D     = cfg.D;
Rdec  = cfg.Rdec;
M     = cfg.M;
if isfield(cfg, 'combine_adjacent')
    combine_adjacent = cfg.combine_adjacent;
else
    combine_adjacent = false;
end
cfar_win   = 5;      % 3 左 + 3 右
os_rank    = 6;      % 取排序后第 4 位功率作噪声估计
cfar_alpha = 3.0;
% 若未给 h_proto -> 自动设计
if isempty(cfg.h_proto)
    if Rdec > D
        warning('Rdec (%d) > D (%d); prototype LPF widened to cover channel spacing.', Rdec, D);
        cutoff = 1/D;             % 保证通带覆盖 D 个子信道的间隔
    else
        cutoff = 1/Rdec;
    end
    h_proto = fir1(M-1, cutoff, hamming(M));
else
    h_proto = cfg.h_proto(:).';   % 确保行向量
    M       = length(h_proto);
end

%% ---------- 1. 多相分析滤波 + 抽取 ----------
[y_dec, h_ch, Fs_dec] = polyphaseAnalysis(rx_sig, fs, D, Rdec, h_proto);
len_dec = length(y_dec{1});

%% ---------- 2. 信道检测 ----------
E = cellfun(@(x) sum(abs(x).^2), y_dec);   % 每子带能量
if combine_adjacent
    E = E + circshift(E,1) + circshift(E,-1);
end

switch lower(cfg.detector)
    %-------------------------------------------------
    % 2‑A  能量固定门限 (最简单)
    %-------------------------------------------------
    case 'energy'
        thr    = mean(E) * 2;              % 可改系数
        active = find(E > thr);

    %-------------------------------------------------
    % 2‑B  CA‑CFAR (平均参考窗)
    %-------------------------------------------------
    case 'cfar'
        win   = cfar_win;              % 左/右各 win 个参考单元
        alpha = cfar_alpha;            % 阈值缩放系数
        pad   = [E(end-win+1:end)  E  E(1:win)];
        active = [];
        for k = 1:D
            noise_est = mean(pad(k:k+2*win));
            if E(k) > alpha * noise_est
                active(end+1) = k; %#ok<AGROW>
            end
        end

    %-------------------------------------------------
    % 2‑C  OS‑CFAR (Order‑Statistics，对强邻道更稳健)
    %       cfg.os_rank : 取排序后第 rank 位功率当作噪声估计
    %-------------------------------------------------
    case 'oscfar'
        win   = cfar_win;              % 参考窗大小复用 cfar_win
        rank  = os_rank;               % 排序后第 rank 位
        pad   = [E(end-win+1:end)  E  E(1:win)];
        active = [];
        for k = 1:D
            ref = pad(k:k+2*win);
            ref_sorted = sort(ref);
            noise_est  = ref_sorted(rank); % 第 rank 小的功率
            if E(k) > cfar_alpha * noise_est
                active(end+1) = k; %#ok<AGROW>
            end
        end

    %-------------------------------------------------
    % 2‑D  GO‑CFAR (Greatest‑Of，用于抑制多目标丢检)
    %-------------------------------------------------
    case 'gocfar'
        win   = cfar_win;
        alpha = cfar_alpha;
        pad   = [E(end-win+1:end)  E  E(1:win)];
        active = [];
        for k = 1:D
            left  = pad(k:k+win-1);
            right = pad(k+win+1:k+2*win);
            noise_est = max(mean(left), mean(right));
            if E(k) > alpha * noise_est
                active(end+1) = k; %#ok<AGROW>
            end
        end

    otherwise
        error('Unknown detector type %s', cfg.detector);
end

%% ---------- 5. 打包输出 ----------
rx_out.active_ch       = active(:).';   % 行向量
rx_out.y_dec           = y_dec;
rx_out.Fs_dec          = Fs_dec;
rx_out.energy_per_ch   = E;
rx_out.h_ch            = h_ch;
rx_out.param           = cfg;
end


