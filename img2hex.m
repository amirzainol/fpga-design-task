b=imread('landscape.jpg'); 

k=1;
for i=1080:-1:1 % img is written from last row to the first row
for j=1:1920
a(k)=b(i,j,1);
a(k+1)=b(i,j,2);
a(k+2)=b(i,j,3);
k=k+3;
end
end
fid = fopen('landscape.hex', 'wt');
fprintf(fid, '%x\n', a);
disp('Done');disp(' ');
fclose(fid);