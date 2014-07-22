% plots solution and nodal values. requires u = size Np*K

function plotSol(u,Nplot)

Globals2D;

if nargin<2
    Nplot = 2*N;
end

quads = size(EToV,2)==4;
if quads
    [ru, su] = EquiNodes2D(Nplot);
else
    [xe,ye] = EquiNodes2D(Nplot); [ru, su] = xytors(xe,ye);    
end
Vu = Vandermonde2D(N,ru,su); Iu = Vu*invV;
[xu yu] = getGlobalNodes(ru,su);

figure
color_line3(xu,yu,Iu*reshape(u,Np,K),Iu*reshape(u,Np,K),'.');
hold on
% plot3(x(:),y(:),u(:),'o','markersize',8);