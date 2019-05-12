clear all
clc

files=dir('color_*.bmp');
numOfFiles=length(files);
disp(strcat('Total files in process queue: ', int2str(numOfFiles)));
%%
for fileIndex=1:numOfFiles
st=files(fileIndex).name;
disp(strcat('Processing file: ', st));
%%resultFilename = sprintf('elemental_%d.bmp',fileIndex-1);
resultFilename = strcat('elemental_',st(7),st(8),st(9),st(10),'.bmp');
tic

PL=5;         
f=10;           
g=15;           
Nx=30;          
Ny=30 ;        
PD=0.25;      
CenterDepth = f*g/(g-f);
%%
NumObject = 1;
objectNx = 320 ;
objectNy = 240;
object = uint8(zeros(objectNy,objectNx,3,NumObject));
object(:,:,:,1) = uint8(imresize(imread(st,'bmp'), [objectNy objectNx]));

object_gray(:,:,1) = double(rgb2gray(object(:,:,:,1)));


x_shift = [0, 0];
y_shift = [0, 0];

[objectNy, objectNx, dummy, dummy] = size(object);
CD=f*g/(g-f);
PI =PD*CD/g;  % [mm] PIxel size of the object image

center_object_x = objectNx*PI/2;    %mm
center_object_y = objectNx*PI/2;    %mm
threshold = 10;



%%
NumPoint = objectNx * objectNx;

%%
Lens_center_X = zeros(Ny, Nx);
Lens_center_Y = zeros(Ny, Nx);

Center_lens_index_X = round(Nx/2);  
Center_lens_index_Y = round(Ny/2); 

[Lens_center_X, Lens_center_Y] = meshgrid(PL*((1-Center_lens_index_X):(Nx-Center_lens_index_X)), PL*((1-Center_lens_index_Y):(Ny-Center_lens_index_Y)));   
Num_pixel_X = round(Nx*PL/PD);      
Num_pixel_Y = round(Ny*PL/PD);      

M =load('DepthUserImage.txt');
z = M(:,3)/8;
measure = (CenterDepth)*(max(z)+min(z))/2;
depth = (measure./z)+7;

x=M(:,1)+1;
y=M(:,2)+1;
M2 = [x,y,depth];
DepthData = zeros(240,320);
 for i = 1:size(x);
          DepthData(y(i),x(i)) = depth(i);
 end
 
theta1= 0*pi/180; 
Ele_image = zeros(Num_pixel_Y, Num_pixel_X, 3);     

for object_idx = 1:NumObject,
    for ix=1:objectNx,
        for iy = 1:objectNy,
            if (object_gray(iy, ix, object_idx)>threshold)
                Object_point = [ix*PI - center_object_x + x_shift(object_idx), iy*PI - center_object_y + y_shift(object_idx), z(object_idx)];
                for lx=1:Nx,
                    for ly=1:Ny,
                        Lens_center = [Lens_center_X(ly, lx), Lens_center_Y(ly, lx)];
                         if PL*round(Nx/2)-Object_point(1)>z(object_idx)*tan(theta1),
                            Ele_point_X = Lens_center(1) + (g/Object_point(3))*(Lens_center(1)-Object_point(1));
                            Ele_point_Y = Lens_center(2) + (g/Object_point(3))*(Lens_center(2)-Object_point(2));
                            if (abs(Ele_point_X-g*tan(theta1)-Lens_center(1))<PL/2) && (abs(Ele_point_Y-(Lens_center(2)))<PL/2),
                                Ele_point_X_pixel = round(Ele_point_X/PD) + round(Num_pixel_X/2);
                                Ele_point_Y_pixel = round(Ele_point_Y/PD) + round(Num_pixel_Y/2);
                                Ele_point_X_pixel = max(1, Ele_point_X_pixel);
                                Ele_point_X_pixel = min(Num_pixel_X, Ele_point_X_pixel);
                                Ele_point_Y_pixel = max(1, Ele_point_Y_pixel);
                                Ele_point_Y_pixel = min(Num_pixel_Y, Ele_point_Y_pixel);
                                Ele_image(Ele_point_Y_pixel, Ele_point_X_pixel, 1) = object(iy, ix, 1, object_idx);
                                Ele_image(Ele_point_Y_pixel, Ele_point_X_pixel, 2) = object(iy, ix, 2, object_idx);
                                Ele_image(Ele_point_Y_pixel, Ele_point_X_pixel, 3) = object(iy, ix, 3, object_idx);
                            end
                        end
                    end
                end
            end
        end
    end
end
xx=size(Ele_image,1);
yy=size(Ele_image,2);
projection_image1= imresize(Ele_image, [yy xx*cos(theta1)]);
%%figure(2);

%%imshow(uint8(projection_image1));figure(2);
%%title('Elemental image');
imwrite(uint8(projection_image1), resultFilename, 'bmp')
toc
end

disp('**** Processing Complete ****');


