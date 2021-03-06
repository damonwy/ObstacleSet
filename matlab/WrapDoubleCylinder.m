classdef WrapDoubleCylinder
    
    properties
        
        point_P         % bounding-fixed via point 1
        point_S         % bounding-fixed via point 2
        point_U         % Obstacle center point
        vec_z_U         % z-axis of the cylinder
        point_V
        vec_z_V
        radius_U        % radius of the cylinder
        radius_V
        wrap_path_len   % wrap path length
        point_Q         % obstacle via point 1
        point_G
        point_H
        point_T         % obstacle via point 2
        status_U
        status_V
    end
    
    methods
        
        function obj = WrapDoubleCylinder(point_P, point_U, vec_z_U, radius_U,...
                                          point_S, point_V, vec_z_V, radius_V)
            
            obj.point_P = transpose(point_P);
            obj.point_S = transpose(point_S);
            obj.point_U = transpose(point_U);
            obj.vec_z_U = transpose(vec_z_U);
            obj.point_Q = [0.0, 0.0, 0.0];
            obj.point_G = [0.0, 0.0, 0.0];
            obj.radius_U = radius_U;
            obj.point_V = transpose(point_V);
            obj.vec_z_V = transpose(vec_z_V);
            obj.point_H = [0.0, 0.0, 0.0];
            obj.point_T = [0.0, 0.0, 0.0];
            obj.radius_V = radius_V;
            obj.wrap_path_len = 0;
            
            obj = wrap_line(obj);
            display_points(obj);
        end
        
        function res = wrap_line(obj)
             
            vec_OP = obj.point_P - obj.point_U;
            vec_OP = vec_OP / norm(vec_OP);
            vec_Z_U = obj.vec_z_U / norm(obj.vec_z_U);
            vec_X_U = cross(vec_Z_U, vec_OP);
            vec_X_U = vec_X_U / norm(vec_X_U);
            vec_Y_U = cross(vec_Z_U, vec_X_U);
            vec_Y_U = vec_Y_U / norm(vec_Y_U);
            
            vec_OS = obj.point_S - obj.point_V;
            vec_OS = vec_OS / norm(vec_OS);
            vec_Z_V = obj.vec_z_V / norm(obj.vec_z_V);
            vec_X_V = cross(vec_Z_V, vec_OS);
            vec_X_V = vec_X_V / norm(vec_X_V);
            vec_Y_V = cross(vec_Z_V, vec_X_V);
            vec_Y_V = vec_Y_V / norm(vec_Y_V);
            
            mat_U = [transpose(vec_X_U); 
                     transpose(vec_Y_U); 
                     transpose(vec_Z_U)];
            mat_V = [transpose(vec_X_V);
                     transpose(vec_Y_V);
                     transpose(vec_Z_V)];
            
            % step 1
            pv = mat_V * (obj.point_P - obj.point_V);
            sv = mat_V * (obj.point_S - obj.point_V);
            
            pv_x = pv(1); pv_y = pv(2); pv_z = pv(3);
            sv_x = sv(1); sv_y = sv(2); sv_z = sv(3);
            Rv = obj.radius_V;
            
            denom_h = pv_x^2 + pv_y^2;
            denom_t = sv_x^2 + sv_y^2;
            
            root_H = sqrt(denom_h - Rv^2);
            root_T = sqrt(denom_t - Rv^2);
            
            h_x = (pv_x*Rv^2 + Rv*pv_y*root_H) / denom_h;
            h_y = (pv_y*Rv^2 - Rv*pv_x*root_H) / denom_h;
            t_x = (sv_x*Rv^2 - Rv*sv_y*root_T) / denom_t;
            t_y = (sv_y*Rv^2 + Rv*sv_x*root_T) / denom_t;
            
            if Rv* (h_x * t_y - h_y * t_x) > 0.0
                obj.status_V = 0;
                h_x = sv_x;
                h_y = sv_y;
            end
            
            HT_xy = abs(Rv * acos(1.0 - ...
                    0.5 * ((h_x-t_x)^2 + (h_y-t_y)^2) / Rv^2));  
            PH_xy = abs(Rv * acos(1.0 - ...
                    0.5 * ((pv_x-h_x)^2 + (pv_y-h_y)^2) / Rv^2));
            TS_xy = abs(Rv * acos(1.0 - ...
                    0.5 * ((t_x-sv_x)^2 + (t_y-sv_y)^2) / Rv^2));
    
            disp(pv);
            disp(sv);
            disp([HT_xy PH_xy TS_xy]);
                
            h_z = pv_z + (sv_z-pv_z) * PH_xy / (PH_xy + HT_xy + TS_xy);
            t_z = sv_z - (sv_z-pv_z) * TS_xy / (PH_xy + HT_xy + TS_xy);

            pH = transpose(mat_V) * [h_x; h_y; h_z] + obj.point_V;
            pT = transpose(mat_V) * [t_x; t_y; t_z] + obj.point_V;

            disp([h_x; h_y; h_z]);
            disp([t_x; t_y; t_z]);
            
            obj.point_H = [pH(1), pH(2), pH(3)];
            obj.point_T = [pT(1), pT(2), pT(3)];
            point_H0 = obj.point_H;
            
            disp(obj.point_H);
            disp(obj.point_T);
            
            for i = 1:100
                disp (i);
                
                % step 2
                pu = mat_U * (obj.point_P - obj.point_U);
                hu = mat_U * (obj.point_H.' - obj.point_U);
                
                pu_x = pu(1); pu_y = pu(2); pu_z = pu(3);
                hu_x = hu(1); hu_y = hu(2); hu_z = hu(3);
                Ru = -obj.radius_U;

                denom_q = pu_x^2 + pu_y^2;
                denom_g = hu_x^2 + hu_y^2;

                root_Q = sqrt(denom_q - Ru^2);
                root_G = sqrt(denom_g - Ru^2);

                q_x = (pu_x*Ru^2 + Ru*pu_y*root_Q) / denom_q;
                q_y = (pu_y*Ru^2 - Ru*pu_x*root_Q) / denom_q;
                g_x = (hu_x*Ru^2 - Ru*hu_y*root_G) / denom_g;
                g_y = (hu_y*Ru^2 + Ru*hu_x*root_G) / denom_g;
                
                if Ru * (q_x * g_y - q_y * g_x) > 0.0
                    obj.status_U = 0;
                    g_x = pu_x;
                    g_y = pu_y;
                end
                
                disp([q_x q_y 0]);
                disp([g_x g_y 0]);

                QG_xy = abs(Ru * acos(1.0 - ...
                        0.5 * ((q_x-g_x)^2 + (q_y-g_y)^2) / Ru^2));  
                PQ_xy = abs(Ru * acos(1.0 - ...
                        0.5 * ((pu_x-q_x)^2 + (pu_y-q_y)^2) / Ru^2));
                GH_xy = abs(Ru * acos(1.0 - ...
                        0.5 * ((g_x-hu_x)^2 + (g_y-hu_y)^2) / Ru^2));

                q_z = pu_z + (hu_z-pu_z) * PQ_xy / (PQ_xy + QG_xy + GH_xy);
                g_z = hu_z - (hu_z-pu_z) * GH_xy / (PQ_xy + QG_xy + GH_xy);

                pQ = transpose(mat_U) * [q_x; q_y; q_z] + obj.point_U;
                pG = transpose(mat_U) * [g_x; g_y; g_z] + obj.point_U;

                obj.point_Q = [pQ(1), pQ(2), pQ(3)];
                obj.point_G = [pG(1), pG(2), pG(3)];

                disp(pQ);
                disp(pG);
                
                % step 3
                gv = mat_V * (obj.point_G.' - obj.point_V);
                gv_x = gv(1); gv_y = gv(2); gv_z = gv(3);

                denom_h = gv_x^2 + gv_y^2;
                root_H = sqrt(denom_h - Rv^2);

                h_x = (gv_x*Rv^2 + Rv*gv_y*root_H) / denom_h;
                h_y = (gv_y*Rv^2 - Rv*gv_x*root_H) / denom_h;

                if Rv * (h_x * t_y - h_y * t_x) > 0.0
                    obj.status_V = 0;
                    h_x = sv_x;
                    h_y = sv_y;
                end
                
                HT_xy = abs(Rv * acos(1.0 - ...
                        0.5 * ((h_x-t_x)^2 + (h_y-t_y)^2) / Rv^2));  
                GH_xy = abs(Rv * acos(1.0 - ...
                        0.5 * ((gv_x-h_x)^2 + (gv_y-h_y)^2) / Rv^2));
                TS_xy = abs(Rv * acos(1.0 - ...
                        0.5 * ((t_x-sv_x)^2 + (t_y-sv_y)^2) / Rv^2));

                h_z = gv_z + (sv_z-gv_z) * GH_xy / (GH_xy + HT_xy + TS_xy);
                t_z = sv_z - (sv_z-gv_z) * TS_xy / (GH_xy + HT_xy + TS_xy);

                pH = transpose(mat_V) * [h_x; h_y; h_z] + obj.point_V;
                pT = transpose(mat_V) * [t_x; t_y; t_z] + obj.point_V;

                obj.point_H = [pH(1), pH(2), pH(3)];
                obj.point_T = [pT(1), pT(2), pT(3)];
                
                dist = sqrt((obj.point_H(1) - point_H0(1))^2 + ...
                            (obj.point_H(2) - point_H0(2))^2 + ...
                            (obj.point_H(3) - point_H0(3))^2);
                
                
                disp (obj.point_H);
                
                if dist == 0
                    break;
                end
                point_H0 = obj.point_H;
            end
            
            if obj.status_V == 0
                obj.point_T = obj.point_S;
            end
            
            if obj.status_U == 0
                obj.point_Q = obj.point_P;
            end
            
            disp(obj.point_Q);
            disp(obj.point_G);
            disp(obj.point_H);
            disp(obj.point_T);
            
            res = obj;
        end
        
        function display_points(obj)
            figure
            x = [obj.point_P(1), obj.point_S(1), obj.point_Q(1), obj.point_G(1),...
                 obj.point_H(1), obj.point_T(1), obj.point_U(1), obj.point_V(1)];
            y = [obj.point_P(2), obj.point_S(2), obj.point_Q(2), obj.point_G(2),...
                 obj.point_H(2), obj.point_T(2), obj.point_U(2), obj.point_V(2)];
            z = [obj.point_P(3), obj.point_S(3), obj.point_Q(3), obj.point_G(3),...
                 obj.point_H(3), obj.point_T(3), obj.point_U(3), obj.point_V(3)];
                        
            hold on 
             
            % U
            ru = obj.radius_U;
            rot_u = vrrotvec([0,0,1], obj.vec_z_U);

            [ux, uy, uz] = cylinder();
            xu0 = obj.point_U(1);
            yu0 = obj.point_U(2);
            zu0 = obj.point_U(3);

            hu = mesh(ux*ru,uy*ru,8*uz*abs(ru)-4*abs(ru));
            rotate(hu, [rot_u(1) rot_u(2) rot_u(3)], rot_u(4) / pi * 180);
            %vzu = obj.vec_z_U / norm(obj.vec_z_U);
            vzu = [0, 0, 0];
            hu.XData = hu.XData + abs(ru)*vzu(1) + xu0;
            hu.YData = hu.YData + abs(ru)*vzu(2) + yu0;
            hu.ZData = hu.ZData + abs(ru)*vzu(3) + zu0;
            
            % V
            rv = obj.radius_V;
            rot_v = vrrotvec([0,0,1], obj.vec_z_V);

            [vx, vy, vz] = cylinder();
            xv0 = obj.point_V(1);
            yv0 = obj.point_V(2);
            zv0 = obj.point_V(3);

            hv = mesh(vx*rv,vy*rv,8*vz*abs(rv)-4*abs(rv));
            rotate(hv, [rot_v(1) rot_v(2) rot_v(3)], rot_v(4) / pi * 180);
            %vzv = obj.vec_z_V / norm(obj.vec_z_V);
            vzv = [0, 0, 0];
            hv.XData = hv.XData + abs(rv)*vzv(1) + xv0;
            hv.YData = hv.YData + abs(rv)*vzv(2) + yv0;
            hv.ZData = hv.ZData + abs(rv)*vzv(3) + zv0;
            
            plot3(x, y, z, '.', 'MarkerSize', 10);
            text(obj.point_P(1), obj.point_P(2), obj.point_P(3), 'P');
            text(obj.point_S(1), obj.point_S(2), obj.point_S(3), 'S');
            text(obj.point_Q(1), obj.point_Q(2), obj.point_Q(3), 'Q');
            text(obj.point_T(1), obj.point_T(2), obj.point_T(3), 'T');
            text(obj.point_H(1), obj.point_H(2), obj.point_H(3), 'H');
            text(obj.point_G(1), obj.point_G(2), obj.point_G(3), 'G');
            text(obj.point_U(1), obj.point_U(2), obj.point_U(3), 'U');
            text(obj.point_V(1), obj.point_V(2), obj.point_V(3), 'V');
            
            
            plot3([obj.point_P(1), obj.point_Q(1)], ...
                  [obj.point_P(2), obj.point_Q(2)], ...
                  [obj.point_P(3), obj.point_Q(3)]);
            plot3([obj.point_H(1), obj.point_G(1)], ...
                  [obj.point_H(2), obj.point_G(2)], ...
                  [obj.point_H(3), obj.point_G(3)]);
            plot3([obj.point_S(1), obj.point_T(1)], ...
                  [obj.point_S(2), obj.point_T(2)], ...
                  [obj.point_S(3), obj.point_T(3)]);
            
            lightGrey = 0.8*[1 1 1];
            %surface(sx,sy,sz,'FaceColor', 'none','EdgeColor',lightGrey)
            hold off
            grid on
            axis equal
        end
        
    end
end
