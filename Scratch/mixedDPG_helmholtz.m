% Poisson example for reference. 
% square domain, forcing = 1
% BCs: left Dirichlet, right (nonconstant) inhomogeneous Neumann BC, and
% penalty enforcement of nonzero BCs on top and bottom 

function mixedDPG_poisson

Globals2D

% Polynomial order used for approximation
Ntrial = 2;
Ntest = Ntrial+2;

N = Ntest;
global k
k = 1;

% Read in Mesh
% [Nv, VX, VY, K, EToV] = MeshReaderGambit2D('squarereg.neu');
% [Nv, VX, VY, K, EToV] = MeshReaderGambit2D('squareireg.neu');
% [Nv, VX, VY, K, EToV] = MeshReaderGambit2D('block2.neu');
% [Nv, VX, VY, K, EToV] = MeshReaderGambit2D('Maxwell1.neu');
% [Nv, VX, VY, K, EToV] = MeshReaderGambit2D('Maxwell05.neu');
% [Nv, VX, VY, K, EToV] = MeshReaderGambit2D('Maxwell025.neu');
[Nv, VX, VY, K, EToV] = MeshReaderGambit2D('Maxwell0125.neu');

% Initialize solver and construct grid and metric
StartUp2D;

NpTrial = (Ntrial+1);
NpTest = (Ntest+1);
PPB = numel(vmapB)*(NpTrial/NpTest)/4 % 4 boundaries - points per boundary of trial
PPW = 8;
k = PPB/PPW

% keyboard
% PPW = PPB/k


% get block operators
[M, Dx, Dy] = getBlockOps();
[AK, BK] = getVolOp(M,Dx,Dy);

% forcing = 0
f = zeros(Np*K,1);

% make CG operators
[R vmapBT] = getCGRestriction();
[Rp Irp vmapBTr xr yr] = pRestrictCG(Ntrial); % restrict test to trial space 
Rr = Rp*Irp';
B = R*BK*Rr';
RV = R*AK*R';
b = R*M*f;

% BC data for u
u0 = zeros(size(B,2),1);
t = 0*pi/4;
u0f = @(x,y) exp(1i*k*(cos(t)*x + sin(t)*y));
u0 = u0f(x(:),y(:));
dudx0 = 1i*k*cos(t)*exp(1i*k*(cos(t)*x(:) + sin(t)*y(:)));
dudy0 = 1i*k*sin(t)*exp(1i*k*(cos(t)*x(:) + sin(t)*y(:)));
dudn0 = nx(mapB).*dudx0(vmapB) + ny(mapB).*dudy0(vmapB);

% Ng = Ntest + 10;
% [rg,sg,wg, Ncub] = Cubature2D(Ng);
% Vg = Vandermonde2D(N,rg,sg); Ig = Vg*invV;
% xg = 0.5*(-(rg+sg)*VX(va)+(1+rg)*VX(vb)+(1+sg)*VX(vc));
% yg = 0.5*(-(rg+sg)*VY(va)+(1+rg)*VY(vb)+(1+sg)*VY(vc));
% keyboard

% penalty/robin BCs 
% robin = y(vmapB) > 1 - NODETOL | x(vmapB) > 1-NODETOL; % top/right boundaries
robin = abs(nx(mapB)+1) < NODETOL | abs(ny(mapB)+1) < NODETOL;
% robin = ones(size(vmapB));
[Mb Eb] = getBoundaryMatrix(robin);
B = B - 1i*k*R*Eb'*Mb*Eb*Rr';
b = b + R*Eb'*Mb*(-1i*k*u0(vmapB) + dudn0);

% nonhomogeneous neumann BCs
% onlyLeft = (x(vmapB) < -1 + NODETOL) & (y(vmapB) < 1-NODETOL);
% onlyBot = (y(vmapB) < -1 + NODETOL) & (x(vmapB) < 1-NODETOL);
% neum = onlyLeft | onlyBot; % left/bottom boundary
neum = abs(nx(mapB)-1) < NODETOL | abs(ny(mapB)-1) < NODETOL;
% neum = zeros(size(vmapB));
[Mb Eb] = getBoundaryMatrix(neum(:)); 
b = b + R*Eb'*Mb*dudn0;

% add boundary trace?
[Mb Eb] = getBoundaryMatrix(robin);
% RV = RV - k*R*Eb'*Mb*Eb*R';

RV = B*B' + 1e-4*R*M*R';
% RV = RV - k*R*Eb'*Mb*Eb*R';
% DuDnB = (spdiag(nx(mapB(:)))*Eb*Dx + spdiag(ny(mapB(:)))*Eb*Dy)*R';
% RV = RV + k^2*DuDnB'*Mb*DuDnB;

% make saddle point system
A = [RV B;B' zeros(size(B,2))];
b = [b; zeros(size(B,2),1)]; 

% vmapBT(robin) = [];
% b(vmapBT) = 0;
% A(vmapBT,:) = 0; A(:,vmapBT) = 0;
% A(vmapBT,vmapBT) = speye(length(vmapBT));

% try Dir on bot/left
% u0 = zeros(size(B,2),1);
% onlyLeft = (xr < -1 + NODETOL) & (yr < 1-NODETOL);
% onlyBot = (yr < -1 + NODETOL) & (xr < 1-NODETOL);
% neum = onlyLeft | onlyBot; % left/bottom boundary
% u0(vmapBTr) = neum.*u0f(xr,yr); 
% U0 = [zeros(size(B,1),1);u0];
% b = b - A*U0;
% vmapBTr(~neum) = [];
% vmapBTU = vmapBTr + size(B,1);
% b(vmapBTU) = U0(vmapBTU);
% A(vmapBTU,:) = 0; A(:,vmapBTU) = 0;
% A(vmapBTU,vmapBTU) = speye(length(vmapBTU));

% solve and prolong solution u to local storage
U = (A\b);
u = Rr'*U(size(B,1)+1:end);

e = U(1:size(B,1));
% err = e'*RV*e;
e = R'*e;

Nplot = 25; [xu,yu] = EquiNodes2D(Nplot); 
% Nplot = Ntrial; [xu,yu] = Nodes2D(Nplot); 
Nplot = 25; [xu,yu] = Nodes2D(Nplot); 
[ru, su] = xytors(xu,yu);
Vu = Vandermonde2D(N,ru,su); Iu = Vu*invV;
xu = 0.5*(-(ru+su)*VX(va)+(1+ru)*VX(vb)+(1+su)*VX(vc));
yu = 0.5*(-(ru+su)*VY(va)+(1+ru)*VY(vb)+(1+su)*VY(vc));

% figure
Iu0 = u0f(xu(:),yu(:));

figure 
Iuh = Iu*reshape(u,Np,K);Iuh = Iuh(:);
Ie = Iu*reshape(e,Np,K);Ie = Ie(:);
% title('Mixed form of DPG')
ax = [-1 1 -1 1 -1 1];
subplot(2,1,1);color_line3(xu,yu,Iuh,Iuh,'.');axis(ax);view(2);%view(0,0)
subplot(2,1,2);color_line3(xu,yu,Iu0,Iu0,'.');axis(ax);view(2);%view(0,0)
figure
subplot(2,1,1);color_line3(xu,yu,Ie,Ie,'.');%axis([-1 1 -1 1 -.1 .1])
colorbar;view(2);%view(0,0);
subplot(2,1,2);color_line3(xu,yu,Iuh-Iu0,Iuh-Iu0,'.');%axis([-1 1 -1 1 -.1 .1])
colorbar;view(2);%view(0,0);

Vu = Vandermonde2D(Nplot,ru,su);
Mu = inv(Vu*Vu');
Nplotp = (Nplot+1)*(Nplot+2)/2;
e = reshape(Iuh-Iu0,Nplotp,K);
tmp = Mu*e;
L2err = sqrt(abs(e(:)'*tmp(:)));
subplot(2,1,1);title(['L2 error = ' num2str(L2err) ' at k = ' num2str(k) ' and ' num2str(PPW) ' ppw.'])

% keyboard

function [Test, Trial] = getVolOp(M,Dx,Dy)

Globals2D
Ks = Dx'*M*Dx + Dy'*M*Dy;

% Poisson
% Test = M + Ks;
% Trial = Ks;

global k;
Trial = -k^2*M + Ks;
% Test = k^2*M + Ks;
% Test = (1/k^2)*M + Ks;
% L = -k^2*speye(size(M)) - Dx*Dx - Dy*Dy;
% Test = Ks + k^2*L'*M*L + 1e-6*M;
Test = (k^2)*M + Ks;
% blkiM = kron(speye(K),inv(MassMatrix));
% invM = spdiag(1./J(:))*blkiM; % J = h^2
% Test = Trial*blkiM*Trial' + 1e-6*M;%(1/k^2)*M;

function [M, Dx, Dy] = getBlockOps()

Globals2D

blkDr = kron(speye(K),Dr);
blkDs = kron(speye(K),Ds);
blkM = kron(speye(K),MassMatrix);

M = spdiag(J(:))*blkM; % J = h^2
Dx = spdiag(rx(:))*blkDr + spdiag(sx(:))*blkDs;
Dy = spdiag(ry(:))*blkDr + spdiag(sy(:))*blkDs;


