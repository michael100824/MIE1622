function gval = computeGradERC (x)

global Q
  
  n = size(Q,1) ;  

  if(size(x,1)==1)
     x = x';
  end
  
  % Insert your gradiant computations here
  % You can use finite differences to check the gradient
  gval = zeros(n,1); 
  
  y = x.* (Q * x);
  
  for i = 1:n
      for j = 1:n
          diff1 = Q(i,:) * x + Q(i,i) * x(i);
          diff2 = Q(i,j) * x(i);
          g = (y(i)-y(j)) * (diff1 - diff2);
          gval(i,:) = gval(i,:) + g;
      end
      gval(i,:) = 4 *  gval(i,:);
  end
end
