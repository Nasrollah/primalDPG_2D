function mortarTestNorm

Globals2D;
FaceGlobals2D

N = 4; % when N = even, Nf = N-1, fails?
Nf = 2; % = N trial
Nt = 3; % = 
%     Read in Mesh
[Nv, VX, VY, K, EToV] = MeshReaderGambit2D('squarereg.neu');
%     Nv = 3;
%     VX = VX(EToV(1,:)); VY = VY(EToV(1,:));
%     EToV = [3 1 2];
%     K = 1;
[Nv, VX, VY, K, EToV] = MeshReaderGambit2D('Maxwell025.neu');
% [Nv, VX, VY, K, EToV] = MeshReaderGambit2D('Maxwell1.neu');

% Initialize solver and construct grid and metric
StartUp2D;FaceStartUp2D

[M, Dx, Dy] = getBlockOps();
Div = [Dx Dy];
Grad = [Dx;Dy];
M2 = blkdiag(M,M);
I2 = speye(size(M2));
O = zeros(size(M));
Adj_h = [I2 Grad;
         Div O];
     
M3 = blkdiag(M2,M);
RV = Adj_h'*M3*Adj_h + blkdiag(M,M,M); % regularize on v
f = ones(Np*K,1);
ftau = 0*[f;f];
fv = f;
b = Adj_h'*M3*[ftau;fv];

Btau = getMortarConstraintDiv();
% fmapBd = fmapB;xfd = xf;yfd = yf; 
xtb = xt(tmapB);ytb = yt(tmapB);

Btau(tmapB(abs(1-xtb.^2)<NODETOL | abs(1-ytb.^2) < NODETOL),:) = []; %remove constraints for fluxes
Bv = getMortarConstraint();

[mtau ntau] = size(Btau);
[mv nv] = size(Bv);
B = [Btau zeros(mtau,nv);
     zeros(mv,ntau) Bv];
 
nU = size(B,2); % num CG nodes
nM = size(B,1); % num mortar nodes

Am = [RV B'
    B zeros(nM)];
bm = [b;zeros(nM,1)];
um = Am\bm;

U = um(1:nU);

I1 = 1:Np*K;
I2 = Np*K + (1:Np*K);
I3 = 2*Np*K + (1:Np*K);

tau1 = U(I1);
tau2 = U(I2);
v = U(I3);

taunorm = sqrt(tau1.^2 + tau2.^2);
plotSol(taunorm,15);title('norm of tau')
plotSol(v,15);title('v')
