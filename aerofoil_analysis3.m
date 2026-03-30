%% =========================================================
%  AEROFOIL ANALYSIS TOOL
%  NACA 4-Digit Series | Thin Aerofoil Theory + Vortex Panel Method
%  Author: Vinnie | Sheffield Hallam University
%% =========================================================
%
%  NOTE ON DRAG:
%  This tool uses inviscid potential flow (no viscosity). By d'Alembert's
%  paradox, a body in inviscid flow has zero pressure drag. The drag polar
%  is therefore replaced with an L/D vs alpha plot using a simple flat-plate
%  drag estimate (Cd = Cd0 + Cl^2/pi*AR) which is physically meaningful.
%  For real viscous drag, couple with a boundary layer solver e.g. XFOIL.
%
%% =========================================================

clc; clear; close all;

%% ---- USER INPUTS ----------------------------------------
naca        = '2412';   % NACA 4-digit designation (e.g. '0012', '2412', '4415')
alpha_range = -10:1:20; % Angle of attack sweep [degrees]
N_panels    = 100;      % Number of panels (keep even)
alpha_cp    = 5;        % Alpha at which to plot Cp distribution [deg]
AR          = 8;        % Wing aspect ratio for drag estimate (typical light aircraft)
Cd0         = 0.02;     % Zero-lift drag coefficient (parasite drag estimate)

%% =========================================================
%  PART 1: GEOMETRY GENERATION & VISUALISATION
%% =========================================================

fprintf('Generating geometry...\n');
[x, y_upper, y_lower, camber_line] = naca4_geometry(naca, 200);

figure('Name','Aerofoil Geometry','Color','w','Position',[100 550 800 300]);
fill([x, fliplr(x)], [y_upper, fliplr(y_lower)], [0.2 0.5 0.8], ...
    'EdgeColor','k','LineWidth',1.2,'FaceAlpha',0.35); hold on;
plot(x, camber_line, 'r--', 'LineWidth', 1.5, 'DisplayName','Camber Line');
plot(x, y_upper,     'k-',  'LineWidth', 1.2, 'DisplayName','Surface');
plot(x, y_lower,     'k-',  'LineWidth', 1.2, 'HandleVisibility','off');
axis equal; grid on;
xlabel('x/c'); ylabel('y/c');
title(['NACA ', naca, ' — Aerofoil Geometry'], 'FontSize', 14);
legend('Aerofoil Fill','Camber Line','Surface','Location','northeast');
xlim([-0.05 1.05]);
drawnow; pause(0.5);
fprintf('Geometry done.\n\n');

%% =========================================================
%  PART 2: THIN AEROFOIL THEORY
%% =========================================================

[Cl_thin, alpha_ZL_deg] = thin_aerofoil_theory(naca, alpha_range);

fprintf('===== THIN AEROFOIL THEORY =====\n');
fprintf('NACA %s\n', naca);
fprintf('Zero-lift angle of attack : %.2f deg\n', alpha_ZL_deg);
fprintf('Lift curve slope          : 2*pi = %.4f per radian\n\n', 2*pi);

%% =========================================================
%  PART 3: VORTEX PANEL METHOD
%% =========================================================

fprintf('===== VORTEX PANEL METHOD =====\n');
fprintf('Running panel method with %d panels across %d alpha values...\n', ...
    N_panels, length(alpha_range));
fprintf('This may take 30-60 seconds in MATLAB Online — please wait.\n\n');

Cl_panel  = zeros(size(alpha_range));
Cp_store  = [];
xcp_store = [];

for i = 1:length(alpha_range)
    fprintf('  alpha = %+.0f deg (%d/%d)\n', alpha_range(i), i, length(alpha_range));
    [Cl_panel(i), Cp, xcp] = vortex_panel(naca, alpha_range(i), N_panels);
    if alpha_range(i) == alpha_cp
        Cp_store  = Cp;
        xcp_store = xcp;
    end
end

fprintf('\nPanel method complete.\n\n');

% Drag estimate using parabolic drag polar: Cd = Cd0 + Cl^2/(pi*AR)
% This is the induced + parasite drag model — standard aircraft performance
Cd_estimate = Cd0 + Cl_panel.^2 / (pi * AR);
LD_panel    = Cl_panel ./ Cd_estimate;

%% =========================================================
%  PLOT: Cl vs Alpha
%% =========================================================

fprintf('Plotting Cl vs Alpha...\n');
figure('Name','Cl vs Alpha','Color','w','Position',[100 100 680 430]);
plot(alpha_range, Cl_thin,  'b--', 'LineWidth', 2, 'DisplayName','Thin Aerofoil Theory'); hold on;
plot(alpha_range, Cl_panel, 'r-',  'LineWidth', 2, 'DisplayName','Vortex Panel Method');
xline(0,'k:','LineWidth',0.8); yline(0,'k:','LineWidth',0.8);
xlabel('Angle of Attack \alpha [deg]', 'FontSize',12);
ylabel('Lift Coefficient C_L',         'FontSize',12);
title(['NACA ', naca, ' — C_L vs \alpha'], 'FontSize',14);
legend('Location','northwest','FontSize',11);
grid on; box on;
drawnow; pause(0.5);

%% =========================================================
%  PLOT: Pressure Distribution (Cp)
%% =========================================================

if ~isempty(Cp_store)
    fprintf('Plotting Cp distribution...\n');
    n_half  = floor(length(xcp_store)/2);
    x_upper = xcp_store(1:n_half);
    x_lower = xcp_store(n_half+1:end);
    Cp_up   = Cp_store(1:n_half);
    Cp_lo   = Cp_store(n_half+1:end);

    figure('Name','Pressure Distribution','Color','w','Position',[800 550 680 380]);
    plot(x_upper, Cp_up, 'b-', 'LineWidth', 2, 'DisplayName','Upper Surface'); hold on;
    plot(x_lower, Cp_lo, 'r-', 'LineWidth', 2, 'DisplayName','Lower Surface');
    set(gca,'YDir','reverse');
    yline(0,'k--','LineWidth',0.8);
    xlabel('x/c','FontSize',12);
    ylabel('Pressure Coefficient C_p','FontSize',12);
    title(['NACA ', naca, ' — C_p at \alpha = ', num2str(alpha_cp), '°'],'FontSize',14);
    legend('Location','best','FontSize',11);
    grid on; box on;
    drawnow; pause(0.5);
end

%% =========================================================
%  PLOT: Drag Polar (Cl vs Cd — parabolic estimate)
%% =========================================================

fprintf('Plotting drag polar...\n');
figure('Name','Drag Polar','Color','w','Position',[800 100 500 430]);
plot(Cd_estimate, Cl_panel, 'k-o', 'LineWidth', 2, 'MarkerSize', 4, ...
    'MarkerFaceColor','k', 'DisplayName', sprintf('AR=%d, Cd0=%.2f', AR, Cd0)); hold on;

[LD_max, idx] = max(LD_panel);
plot(Cd_estimate(idx), Cl_panel(idx), 'r*', 'MarkerSize', 14, ...
    'DisplayName', sprintf('Max L/D = %.1f at \\alpha = %d°', LD_max, alpha_range(idx)));

xlabel('Drag Coefficient C_D',  'FontSize',12);
ylabel('Lift Coefficient C_L',  'FontSize',12);
title(['NACA ', naca, ' — Drag Polar (AR = ', num2str(AR), ')'], 'FontSize',14);
legend('Location','northwest','FontSize',10);
grid on; box on;

% Annotation explaining the model
text(0.98, 0.04, {'C_D = C_{D0} + C_L^2/(\pi AR)', 'Inviscid + induced drag model'}, ...
    'Units','normalized','HorizontalAlignment','right', ...
    'FontSize',9,'Color',[0.4 0.4 0.4]);
drawnow; pause(0.5);

%% =========================================================
%  PLOT: L/D vs Alpha
%% =========================================================

fprintf('Plotting L/D vs Alpha...\n');
figure('Name','L/D vs Alpha','Color','w','Position',[450 100 600 430]);
plot(alpha_range, LD_panel, 'k-', 'LineWidth', 2);
xline(alpha_range(idx), 'r--', sprintf('\\alpha = %d°', alpha_range(idx)), ...
    'LineWidth', 1.2, 'LabelVerticalAlignment','bottom');
yline(LD_max, 'r--', sprintf('Max L/D = %.1f', LD_max), ...
    'LineWidth', 1.2, 'LabelHorizontalAlignment','left');
xlabel('Angle of Attack \alpha [deg]', 'FontSize',12);
ylabel('Lift-to-Drag Ratio L/D',       'FontSize',12);
title(['NACA ', naca, ' — L/D vs \alpha (AR = ', num2str(AR), ')'], 'FontSize',14);
grid on; box on;
drawnow; pause(0.5);

fprintf('\n===== COMPLETE =====\n');
fprintf('Max L/D = %.2f at alpha = %d deg\n', LD_max, alpha_range(idx));
fprintf('All figures rendered. Click each figure tab to view.\n');


%% =========================================================
%  FUNCTIONS
%% =========================================================

function [x, y_upper, y_lower, camber] = naca4_geometry(naca_str, n_points)
%NACA4_GEOMETRY  Generate NACA 4-digit aerofoil surface coordinates

    m = str2double(naca_str(1)) / 100;
    p = str2double(naca_str(2)) / 10;
    t = str2double(naca_str(3:4)) / 100;

    beta = linspace(0, pi, n_points);
    x    = (1 - cos(beta)) / 2;

    yt = 5*t .* (0.2969*sqrt(x) - 0.1260*x - 0.3516*x.^2 ...
               + 0.2843*x.^3   - 0.1015*x.^4);

    camber = zeros(size(x));
    dydx   = zeros(size(x));
    if m > 0 && p > 0
        i1 = x <= p;  i2 = x > p;
        camber(i1) = (m/p^2)       .* (2*p*x(i1) - x(i1).^2);
        camber(i2) = (m/(1-p)^2)   .* (1 - 2*p + 2*p*x(i2) - x(i2).^2);
        dydx(i1)   = (2*m/p^2)     .* (p - x(i1));
        dydx(i2)   = (2*m/(1-p)^2) .* (p - x(i2));
    end

    theta   = atan(dydx);
    y_upper = camber + yt.*cos(theta);
    y_lower = camber - yt.*cos(theta);
end


function [Cl, alpha_ZL_deg] = thin_aerofoil_theory(naca_str, alpha_range_deg)
%THIN_AEROFOIL_THEORY  Cl = 2*pi*(alpha - alpha_L0)

    m = str2double(naca_str(1)) / 100;
    p = str2double(naca_str(2)) / 10;

    theta = linspace(0, pi, 2000);
    x_th  = (1 - cos(theta)) / 2;
    dydx  = zeros(size(x_th));

    if m > 0 && p > 0
        i1 = x_th <= p;  i2 = x_th > p;
        dydx(i1) = (2*m/p^2)      .* (p - x_th(i1));
        dydx(i2) = (2*m/(1-p)^2)  .* (p - x_th(i2));
    end

    alpha_ZL     = -(1/pi) * trapz(theta, dydx .* (cos(theta) - 1));
    alpha_ZL_deg = rad2deg(alpha_ZL);
    Cl           = 2*pi * (deg2rad(alpha_range_deg) - alpha_ZL);
end


function [Cl, Cp, x_mid] = vortex_panel(naca_str, alpha_deg, N)
%VORTEX_PANEL  Constant-strength vortex panel method with Kutta condition
%
%  Cl computed via Kutta-Joukowski theorem: Cl = 2*Gamma/(V_inf*c)
%  This is more accurate than pressure integration for constant-strength panels
%
%  Panel ordering: upper surface TE->LE, lower surface LE->TE (CCW loop)

    %--- Geometry ---
    m = str2double(naca_str(1)) / 100;
    p = str2double(naca_str(2)) / 10;
    t = str2double(naca_str(3:4)) / 100;

    n_half = N/2 + 1;
    beta   = linspace(0, pi, n_half);
    xc     = (1 - cos(beta)) / 2;

    yt = 5*t .* (0.2969*sqrt(xc) - 0.1260*xc - 0.3516*xc.^2 ...
               + 0.2843*xc.^3   - 0.1015*xc.^4);

    camber = zeros(size(xc));
    dydx   = zeros(size(xc));
    if m > 0 && p > 0
        i1 = xc <= p;  i2 = xc > p;
        camber(i1) = (m/p^2)       .* (2*p*xc(i1) - xc(i1).^2);
        camber(i2) = (m/(1-p)^2)   .* (1 - 2*p + 2*p*xc(i2) - xc(i2).^2);
        dydx(i1)   = (2*m/p^2)     .* (p - xc(i1));
        dydx(i2)   = (2*m/(1-p)^2) .* (p - xc(i2));
    end
    theta_c = atan(dydx);
    xu = xc - yt.*sin(theta_c);  yu = camber + yt.*cos(theta_c);
    xl = xc + yt.*sin(theta_c);  yl = camber - yt.*cos(theta_c);

    % Closed CCW node list
    X = [xu(end:-1:1), xl(2:end)];
    Y = [yu(end:-1:1), yl(2:end)];
    n = length(X) - 1;

    %--- Panel geometry ---
    X1 = X(1:n);   Y1 = Y(1:n);
    X2 = X(2:n+1); Y2 = Y(2:n+1);
    x_mid = 0.5*(X1 + X2);
    y_mid = 0.5*(Y1 + Y2);
    S     = sqrt((X2-X1).^2 + (Y2-Y1).^2);
    cosp  = (X2-X1)./S;
    sinp  = (Y2-Y1)./S;

    alpha = deg2rad(alpha_deg);

    %--- Influence coefficients ---
    CN = zeros(n, n);
    CT = zeros(n, n);

    for i = 1:n
        for j = 1:n
            if i ~= j
                dx1 = x_mid(i) - X1(j);
                dy1 = y_mid(i) - Y1(j);
                dx2 = x_mid(i) - X2(j);
                dy2 = y_mid(i) - Y2(j);

                r1 = max(sqrt(dx1^2 + dy1^2), 1e-10);
                r2 = max(sqrt(dx2^2 + dy2^2), 1e-10);

                theta1 = atan2(dy1, dx1);
                theta2 = atan2(dy2, dx2);
                dtheta = mod(theta2 - theta1 + pi, 2*pi) - pi;
                ln_r   = log(r2/r1);

                u = ( sinp(j)*ln_r - cosp(j)*dtheta) / (2*pi);
                v = (-cosp(j)*ln_r - sinp(j)*dtheta) / (2*pi);

                CN(i,j) = -u*sinp(i) + v*cosp(i);
                CT(i,j) =  u*cosp(i) + v*sinp(i);
            end
        end
    end

    %--- Build and solve system ---
    A   = zeros(n+1, n);
    RHS = zeros(n+1, 1);

    for i = 1:n
        A(i, 1:n) = CN(i, :);
        RHS(i)    = sin(alpha - atan2(sinp(i), cosp(i)));
    end

    % Kutta condition: gamma(1) + gamma(n) = 0
    A(n+1, 1) =  1;
    A(n+1, n) =  1;
    RHS(n+1)  =  0;

    gamma = A \ RHS;

    %--- Cl via Kutta-Joukowski theorem ---
    % Total circulation Gamma = sum(gamma * panel_length)
    % Cl = 2*Gamma / (V_inf * c), V_inf = 1, c = 1
    Gamma = sum(gamma .* S');
    Cl    = 2 * Gamma;

    %--- Surface velocity and Cp ---
    Vt = zeros(n, 1);
    for i = 1:n
        panel_angle = atan2(sinp(i), cosp(i));
        Vt(i) = cos(alpha - panel_angle) + CT(i,:) * gamma;
    end

    Cp = 1 - Vt.^2;
end
