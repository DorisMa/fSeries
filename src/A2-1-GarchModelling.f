

C PART I: GARCH
C PART II: APARCH


C ##############################################################################


C ---------------------------------------------------------------------+
C  PART I: CONTENT: GARCH PACKAGE                                      �
C     garchsim          Process Simulation                             �
C     garchcvs          Conditional Variances                          �
C ---------------------------------------------------------------------+


C **********************************************************************
C garchsim:                                                            *
C Process Simulation                                                   *
C **********************************************************************


      subroutine garchsim(x, h, z, nt,
     &  omega, alpha, laga, na, beta, lagb, nb, h0)

C ----------------------------------------------------------------------
C    SIMULATION OF GARCH(p,q) TIME SERIES MODELS
C       *  x(t) = z(t) * h(t)**(1/2)         
C       *  h(t) = omega + A(L) * x(t)**2 + B(L) * h(t)                               
C     Arguments:
C       x(nt)          O  time series points to be calculated
C       h(nt)          O  garch volatilities
C       z(nt)          I  innovations for time series
C         nt           I  number of data points
C       omega          I  value of constant
C       alpha(na)      I  subset of alpha coefficients
C         laga(na)     I  lags belonging to alpha
C         na           I  number of alpha coefficients 
C                          the maximum lag is the order np
C       beta(nb)       I  subset of beta coefficients
C         lagb(nb)     I  lags belonging to beta
C         nb           I  number of beta coefficients
C                          the maximum lag is the order nq
C ----------------------------------------------------------------------


C
C>>> DECLARATIONS: 
      implicit double precision (a-h, o-z)
      dimension x(nt), h(nt), z(nt)
      dimension alpha(na), laga(na), beta(nb), lagb(nb)
C
C>>> SETTINGS:
      np=laga(na)
      nq=lagb(nb)
      maxpq=np
      if(nq.gt.np) maxpq=nq
C      
C>>> SET THE FIRST h(t) AND x(t):
      do i=1,maxpq
         h(i) = h0
         x(i) = z(i)
      enddo
C
C>>> CONTINUE BY ITERATION:
      do i=maxpq+1, nt
         h(i) = omega
         do j=1, na, 1
            h(i) = h(i) + alpha(j)*(x(i-laga(j)))**2 
         enddo
         do k=1, nq, 1
            h(i) = h(i) + beta(k)*h(i-lagb(k))
         enddo
         x(i)= dsqrt(h(i)) * z(i)
      enddo
C
      return
      end


C **********************************************************************
C  garchcvs                                                            *
C  Conditional Variances                                               *
C **********************************************************************


      subroutine garchcvs(x, h, z, nt, omega, alpha, laga, na, 
     &   beta, lagb, nb, h0)

C ----------------------------------------------------------------------
C    EVALUATION OF LOG-LIKELIHOOD FUNCTION FOR APARCH(p,q) MODELS
C       *  x(t) = z(t) * h(t)**(1/2)         
C       *  h(t) = omega + A(L) * x(t)**2 + B(L) * h(t)
C     Arguments:
C       x(nt)          I  time series points to be calculated
C       h(nt)          O  garch volatilities
C       z(nt)          I  innovations for time series
C         nt           I  number of data points
C       omega          I  value of constant
C       alpha(na)      I  subset of alpha coefficients
C         laga(na)     I  lags belonging to alpha and gamma
C         na           I  number of alpha coefficients 
C                           the maximum lag is the order np
C       beta(nb)       I  subset of beta coefficients
C         lagb(nb)     I  lags belonging to beta
C         nb           I  number of beta coefficients
C                           the maximum lag is the order nq
C ----------------------------------------------------------------------

C
C>>> DECLARATIONS:
      implicit  double precision (a-h, o-z)
      dimension x(nt), h(nt), z(nt)
      dimension alpha(na), laga(na), beta(nb), lagb(nb)
C
C>>> SETTINGS:
      np=laga(na)
      nq=lagb(nb)
      maxpq = np
      if(nq.gt.np) maxpq = nq

C>>> SET THE FIRST h(t):
      do i=1,maxpq
         h(i) = h0
	 z(i) = x(i)
      enddo
C
C>>> CONDITIONAL VARIANCES:
      do i=maxpq+1, nt
         h(i) = omega
         do j=1, na, 1
            h(i) = h(i) + alpha(j) * x(i-laga(j))**2
          enddo
          do k=1, nb, 1
             h(i) = h(i) + beta(k) * h(i-lagb(k))
          enddo
	  z(i) = x(i)/sqrt(h(i))
      enddo
C
      return
      end


C>>> LOG-LIKELIHOOD FUNCTION -- GAUSSIAN DENSITY:
C      f=0.0d0
C      do n=ncond+1,nt
C         hh=h(n)**deltainv
C         z=x(n)/hh
C         f=f-dlog(density(model,z, disparm)/hh)
C      enddo
C      fllh=f/(nt-ncond)



C ##############################################################################



C ---------------------------------------------------------------------+
C  PART II: CONTENT: A-PARCH PACKAGE                                   �
C     aparchsim         Simulation of A-PARCH Processes                �
C     aparchllh         Evaluation of Log-Likelihood Function          �
C       gdensity          Normal Gaussian Densitz                      �
C       tdensity          Student t-distribution                       �
C       adensity          Symmetric alfa-stable distribution           �
C       gamma2, derfc2    Special Functions                            �
C ---------------------------------------------------------------------+


C **********************************************************************
C aparchsim:                                                           *
C Simulation of A-PARCH Processes                                      *
C **********************************************************************


      subroutine aparchsim( z, x, h, nt,
     &  omega, alfa, gamma, laga, na, beta, lagb, nb, delta)

C ----------------------------------------------------------------------
C    SIMULATION OF APARCH(p,q) TIME SERIES MODELS
C       *  x(t) = z(t) * h(t)**(1/delta)                                                                                   
C       *  h(t) = omega                              
C       *       + A(L) * [(|eps(t)|-gamma(t)*eps(t))**delta]   
C       *       + B(L) * h(t)                               
C     Arguments:
C       z(nt)          I  innovations for time series
C       x(nt)          O  time series points to be calculated
C       h(nt)          O  aparch volatilities
C         nt           I  number of data points
C       omega          I  value of constant
C       alfa(na)       I  subset of alfa coefficients
C         gamma(na)    I  assymetry coefficients
C         laga(na)     I  lags belonging to alpha and gamma
C         na           I  number of alfa coefficients 
C                          the maximum lag is the order np
C       beta(nb)       I  subset of beta coefficients
C         lagb(nb)     I  lags belonging to beta
C         nb           I  number of beta coefficients
C                          the maximum lag is the order nq
C       delta          I  value of recursion exponent
C ----------------------------------------------------------------------


C
C>>> DECLARATIONS: 
      implicit double precision (a-h, o-z)
      dimension z(nt), x(nt), h(nt)
      dimension alfa(na), gamma(na), laga(na), beta(nb), lagb(nb)
C
C>>> SETTINGS:
      np=laga(na)
      nq=lagb(nb)
      maxpq=np
      if(nq.gt.np) maxpq=nq
      deltainv=1.0d0/delta
C      
C>>> SET THE FIRST h(t) AND x(t):
      do n=1,maxpq
         h(n)=0.0d0
         x(n)=z(n)
      enddo
C
C>>> CONTINUE BY ITERATION:
      do n = maxpq+1, nt
         h(n)=omega
         do i = 1, na, 1
	        a = (abs(x(n-laga(i))) - gamma(i)*x(n-laga(i)))
            h(n) = h(n) + alfa(i) * a**delta
         enddo
         do j = 1, nb, 1
            h(n) = h(n) + beta(j) * h(n-lagb(j))
         enddo
         x(n)=h(n)**deltainv * z(n)
      enddo
C
      return
      end


C **********************************************************************
C  aparchllh                                                           *
C  Log-likelihood Function                                             *
C **********************************************************************

C        	result <- .Fortran("sumllh",
C    			as.integer(modsel),
C    			as.double(x),
C    			as.double(h),
C    			as.integer(nt),
C    			as.double(omega),
C    			as.double(alpha),
C			 	as.double(gamma),
C    			as.integer(laga),
C    			as.integer(na),
C				as.double(beta),
C    			as.integer(lagb),
C    			as.integer(nb),
C				as.double(delta),
C				as.double(disparm),
C    			as.integer(n.cond),
C    			as.double(0)
C    			)[[16]][
    			
       subroutine sumllh (x, h, nt,
     &  omega, alfa, gamma, laga, na, beta, lagb, nb, delta,
     &  ncond)   	
     
     C
C>>> DECLARATIONS:
      implicit  double precision (a-h, o-z)
      dimension x(nt), h(nt)
      dimension alfa(na), gamma(na), laga(na), beta(nb), lagb(nb)
C
C>>> ITERATE A-PARCH TIME SERIES PROCESS:
      do n = ncond+1, nt
         h(n) = omega
         do i = 1, na, 1
            a = (abs(x(n-laga(i))) - gamma(i)*x(n-laga(i)))           
            h(n) = h(n) + alfa(i) * abs(a)**delta
          enddo
          do j = 1, nb, 1
             h(n) = h(n) + beta(j) * h(n-lagb(j))
          enddo
      enddo    
C
      return
      end		
    			
    			
C ------------------------------------------------------------------------------



C **********************************************************************
C  aparchllh                                                           *
C  Log-likelihood Function                                             *
C **********************************************************************


      subroutine aparchllh (modsel, x, h, nt,
     &  omega, alfa, gamma, laga, na, beta, lagb, nb, delta, disparm,
     &  ncond, fllh)

C ----------------------------------------------------------------------
C    EVALUATION OF LOG-LIKELIHOOD FUNCTION FOR APARCH(p,q) MODELS
C       *  x(t) = z(t) * h(t)**(1/delta)                                                                                   
C       *  h(t) = omega                              
C       *       + A(L) * [(|eps(t)|-gamma(t)*eps(t))**delta]   
C       *       + B(L) * h(t)    
C     Arguments:
C       model          I  type of model assumption:    
C                           1: Gaussian innovations
C                           2: Student t-distributed innovations
C                           3: Symmetric alpha-stable innovations
C       x(nt)          I  time series points to be calculated
C       h(nt)          O  aparch volatilities
C         nt           I  number of data points
C       omega          I  value of constant
C       alfa(na)       I  subset of alfa coefficients
C         gamma(na)    I  assymetry coefficients
C         laga(na)     I  lags belonging to alpha and gamma
C         na           I  number of alfa coefficients 
C                           the maximum lag is the order np
C       beta(nb)       I  subset of beta coefficients
C         lagb(nb)     I  lags belonging to beta
C         nb           I  number of beta coefficients
C                           the maximum lag is the order nq
C       delta          I  value of volatility exponent
C       disparm        I  Distribution parameter
C                           model 2: df degress of freedom
C                           model 3: alpha stable index
C       ncond          I  conditining start value
C       fllh           O  value of log-likelihood function
C ----------------------------------------------------------------------

C
C>>> DECLARATIONS:
      implicit  double precision (a-h, o-z)
      dimension x(nt), h(nt)
      dimension alfa(na), gamma(na), laga(na), beta(nb), lagb(nb)
C
C>>> ITERATE A-PARCH TIME SERIES PROCESS:
      np=laga(na)
      nq=lagb(nb)
      maxpq = np
      if(nq.gt.np) maxpq = nq
      deltainv=1.0/delta
      do n = maxpq+1, nt
         h(n)=omega
         do i = 1, na, 1
            a = (abs(x(n-laga(i)))-gamma(i)*x(n-laga(i)))           
            h(n) = h(n) + alfa(i) * abs(a)**delta
          enddo
          do j = 1, nb, 1
             h(n) = h(n) + beta(j) * h(n-lagb(j))
          enddo
      enddo    
C
C>>> LOG-LIKELIHOOD FUNCTION -- GAUSSIAN DENSITY:
      f=0.0d0
      do n=ncond+1,nt
         hh=abs(h(n))**deltainv
         z=x(n)/hh
         f=f-dlog(density(modsel, z, disparm)/hh)
      enddo
      fllh=f/(nt-ncond)
C
      return
      end
      

C **********************************************************************
C density:                                                             *
C selector for density function                                        *
C **********************************************************************


      double precision function density(model, x, disparm)
      implicit double precision (a-h, o-z)
      density=0.0d0
      if (model.eq.1) density=gdensity(x)
      if (model.eq.2) density=tdensity(x, disparm)
      if (model.eq.3) density=adensity(x, disparm)
      return
      end


C **********************************************************************
C gdensity:                                                            *
C normal (Gaussian Distribution)                                       *
C **********************************************************************

    
      double precision function gdensity(x)
      implicit double precision (a-h, o-z)
      pi=4.0d0*datan(1.0d0)
      gdensity=(1.0d0/dsqrt(2.0d0*pi))*dexp(-x*x/2.0d0)
      return
      end


C **********************************************************************
C tdensity:                                                            *
C Student t-distribution function                                      *
C **********************************************************************


      double precision function tdensity(x, df)
      implicit double precision (a-h, o-z)    
      tdensity=1
      return
      end


C **********************************************************************
C adensity:                                                            *
C symmetric alfa-stable distribution function                          *
C **********************************************************************

      
      double precision function adensity(x, alpha)
      implicit double precision (a-h, o-z)
      integer first                          
      dimension ei(3),u(3)                  
      dimension s(4,19),r(19),q(0:5),p(0:5,0:19)
      dimension pd(0:4,0:19)                
      dimension alf2i(4)                     
      dimension znot(19),zn4(19),zn5(19),combo(0:5),zji(19,0:5)      
      SAVE first,pi,sqpi,a2,cpxp0,gpxp0,cpxpp0,gpxpp0
      SAVE cppp,gppp,znot,zn4,zn5,zji,ei,u,q
      SAVE a,ala,alf2,alf1,pialf,sp0,sppp0,xp0
      SAVE xpp0,xppp0,spzp1,rp0,rpp0,rppp0,rp1
      SAVE alf2i,r,b,c,p,pd,oldalf
      data combo/1.d0,5.d0,10.d0,10.d0,5.d0,1.d0/      
      data ((s(i,j),i=1,4),j=1,7)/
     1    1.85141 90959 d2,  -4.67693 32663 d2,    
     1    4.84247 20302 d2,  -1.76391 53404 d2,    
     1   -3.02365 52164 d2,   7.63519 31975 d2,    
     1   -7.85603 42101 d2,   2.84263 13374 d2,    
     1    4.40789 23600 d2,  -1.11811 38121 d3,    
     1    1.15483 11335 d3,  -4.19696 66223 d2,    
     1   -5.24481 42165 d2,   1.32244 87717 d3,    
     1   -1.35556 48053 d3,   4.88340 79950 d2,    
     1    5.35304 35018 d2,  -1.33745 70340 d3,    
     1    1.36601 40118 d3,  -4.92860 99583 d2,    
     1   -4.89889 57866 d2,   1.20914 18165 d3,    
     1   -1.22858 72257 d3,   4.40631 74114 d2,    
     1    3.29055 28742 d2,  -7.32117 67697 d2,    
     1    6.81836 41829 d2,  -2.28242 91084 d2/   
      data ((s(i,j),i=1,4),j=8,14)/
     1   -2.14954 02244 d2,   3.96949 06604 d2,    
     1   -3.36957 10692 d2,   1.09058 55709 d2,    
     1    2.11125 81866 d2,  -2.79211 07017 d2,    
     1    1.17179 66020 d2,   3.43946 64342 d0,    
     1   -2.64867 98043 d2,   1.19990 93707 d2,    
     1    2.10448 41328 d2,  -1.51108 81541 d2,    
     1    9.41057 84123 d2,  -1.72219 88478 d3,    
     1    1.40875 44698 d3,  -4.24725 11892 d2,    
     1   -2.19904 75933 d3,   4.26377 20422 d3,    
     1   -3.47239 81786 d3,   1.01743 73627 d3,    
     1    3.10474 90290 d3,  -5.42042 10990 d3,    
     1    4.22210 52925 d3,  -1.23459 71177 d3,    
     1   -5.14082 60668 d3,   1.10902 64364 d4,    
     1   -1.02703 37246 d4,   3.42434 49595 d3/   
      data ((s(i,j),i=1,4),j=15,19)/      
     1    1.12151 57876 d4,  -2.42435 29825 d4,    
     1    2.15360 57267 d4,  -6.84909 96103 d3,    
     1   -1.81206 31586 d4,   3.14301 32257 d4,    
     1   -2.41642 85641 d4,   6.91268 62826 d3,    
     1    1.73884 13126 d4,  -2.21083 97686 d4,    
     1    1.33979 99271 d4,  -3.12466 11987 d3,    
     1   -7.24357 75303 d3,   4.35453 99418 d3,    
     1    2.36161 55949 d2,  -7.65716 53073 d2,    
     1   -8.73767 25439 d3,   1.55108 52129 d4,    
     1   -1.37897 64138 d4,   4.63874 17712 d3 /  
c     
      xfun(z,alpha,a)=((1.0d0-z)**(-1.0d0/alpha)-1.0d0)/a
      zpfun(x,alpha,a)=alpha*a*(1+a*x)**(-alpha-1.0d0)  
      cfun(x)=0.5d0-datan(x)/pi            
      cden(x)=1.0d0/(pi*(1.0d0+x*x))             
      gfun(x)=0.5d0*derfc2(x/2.0d0)              
      gden(x)=exp(max(-160.d0,-x*x/4.d0))/(2.0d0*sqpi) 
c                                            
c  except on the first call,skip to 10.     
      if (first.eq.0)  then            
        pi=3.14159 26535 89793 d0            
        sqpi=sqrt(pi)                        
        a2=dsqrt(2.d0)-1                   
        cpxp0=1.0d0/pi                         
        gpxp0=1.0d0/(4.0d0*a2*sqpi)            
        cpxpp0=cpxp0*2.0d0                     
        gpxpp0=gpxp0*1.5d0                   
        cppp=cpxpp0*3.0d0-2.0d0/pi             
        gppp=gpxpp0*2.5d0-1.0d0/(32.0d0*sqpi*a2**3)
        do j=1,19                         
           znot(j)=dfloat(j)*.05d0              
           zn4(j)=(1-znot(j))**4              
           zn5(j)=(1-znot(j))*zn4(j)        
           do i=0,5                          
              zji(j,i)=combo(i)*(-znot(j))**(5-i)     
           enddo
        enddo
        do i=1,3                          
           ei(i)=i                              
           u(i)=1                               
        enddo                                  
        q(0)=0                               
        first=1
      endif
c                                            
c  if alpha is unchanged from last call,skip to 20  
      if (alpha.ne.oldalf) then
        a=2.0d0**(1.0d0/alpha)-1.0d0                 
        ala=alpha*a                        
        alf2=2.0d0-alpha                       
        alf1=alpha-1.0d0                       
        pialf=pi*alpha                     
        sp0=dgamma2(1.0d0/alpha)/pialf           
        sppp0=-dgamma2(3.0d0/alpha)/pialf        
        xp0=1.d0/ala                          
        xpp0=xp0*(1.0d0+alpha)/alpha         
        xppp0=xpp0*(1+2.0d0*alpha)/alpha 
        spzp1=(a**alpha)*dgamma2(alpha)*sin(pialf/2)/pi   
        rp0=-sp0*xp0+alf2*cpxp0+alf1*gpxp0 
        rpp0=-sp0*xpp0+alf2*cpxpp0+alf1*gpxpp0
        rppp0=-sp0*xppp0-sppp0*xp0**3
     &     +alf2*cppp+alf1*gppp                          
        rp1=-spzp1+alf2/pi               
        do i=1,4                         
           alf2i(i)=alf2**i-1               
        enddo
        do j=1,19                        
           r(j)=alf2*prod(s(1,j),alf2i,4)  
        enddo
        q(1)=rp0                             
        q(2)=rpp0/2                          
        q(3)=rppp0/6                         
        b=- prod(u,q(1),3)-prod(r,zn5,19)      
        c=rp1-prod(ei,q(1),3)-5.0d0*prod(r,zn4,19)
        q(4)=5*b-c                       
        q(5)=b-q(4)                        
        do i=0,5                         
           p(i,0)=q(i)                         
           do j=1,19                        
              p(i,j)=q(i)+prod(r,zji(1,i),j) 
           enddo
        enddo
        do i=1,5                         
           do j=0,19                        
              pd(i-1,j)=i*p(i,j)               
           enddo
        enddo
        oldalf=alpha                         
      endif
c                                            
c  now calculate new x:
      xa1=1.0d0+a*dabs(x)                   
      xa1a=xa1**(-alpha)                 
      z=1.0d0-xa1a                           
      zp=ala*xa1a/xa1                  
      x1=xfun(z,1.d0,1.d0)               
      x2=xfun(z,2.d0,a2)                 
      x1p=1/zpfun (x1,1.d0,1.d0)       
      x2p=1/zpfun (x2,2.d0,a2)         
      j=20*z                               
      j=min(j,19)                         
      rz=poly(p(0,j),z,5)               
      rpz=poly(pd(0,j),z,4)             
40    continue                               
      sfun=alf2*cfun(x1)+alf1*gfun(x2)+rz  
      sden=(alf2*cden(x1)*x1p+alf1*gden(x2)*x2p-rpz)*zp 
      if (x.lt.0.0d0) sfun=1.0d0-sfun            
      adensity=sden
c
      return                                 
      end                                    
c                                             
      function poly(a,x,k)               
c  computes k degree polynomial in x with coefficients a(j)
      implicit real*8 (a-h,o-z)           
      dimension a(0: k)                      
      poly=a(k)                            
      do 10 j=k-1,0,-1                   
10    poly=poly*x+a(j)                 
      return                                 
      end                                    
c                                             
      function prod(a,b,k)                 
c  computes inner product of two k-vectors a and b
      implicit real*8 (a-h,o-z)           
      dimension a(k),b(k)                   
      prod=0                               
      do 10 j=1,k                         
10    prod=prod+a(j)*b(j)              
      return                                 
      end                                    


C **********************************************************************
C dgamma2:                                                             *
C Gamma Function                                                       *
C **********************************************************************

   
      double precision function dgamma2(xx)
      implicit real*8 (a-h,o-z)
      dimension cof(6)
      data cof,stp  /76.18009173d0,-86.50532033d0,24.01409822d0,
     &-1.231739516d0,0.120858003d-2,-0.536382d-5,2.50662827465d0/
      data half,one,fpf/0.5d0,1.0d0,5.5d0/
      x=xx-one
      tmp=x+fpf
      tmp=(x+half)*dlog(tmp)-tmp
      ser=one
      do 11 j=1,6
        x=x+one
        ser=ser+cof(j)/x
11    continue
      dgamma2=dexp(tmp+dlog(stp*ser))
      return
      end


C **********************************************************************
C derfc2:                                                              *
C Complementary Error Function                                         *
C **********************************************************************

     
      double precision function derfc2(x)
      double precision x,result
      call calerf(x,result,1)
      derfc2=result
      return
      end

      subroutine calerf(arg,result,jint)
      integer i,jint
      double precision
     1     a,arg,b,c,d,del,four,half,p,one,q,result,sixten,sqrpi,
     2     two,thresh,x,xbig,xden,xhuge,xinf,xmax,xneg,xnum,xsmall,
     3     y,ysq,zero
      dimension a(5),b(4),c(9),d(8),p(6),q(5)
C
C>>> Mathematical constants
      data four,one,half,two,zero/4.0d0,1.0d0,0.5d0,2.0d0,0.0d0/,
     1     sqrpi/5.6418958354775628695d-1/,thresh/0.46875d0/,
     2     sixten/16.0d0/
C
C>>> Machine-dependent Constants
      data xinf,xneg,xsmall/1.79d308,-26.628d0,1.11d-16/,
     1     xbig,xhuge,xmax/26.543d0,6.71d7,2.53d307/
C
C>>> Coefficients for approximation to erf in first interval
      data a/3.16112374387056560d00,1.13864154151050156d02,
     1       3.77485237685302021d02,3.20937758913846947d03,
     2       1.85777706184603153d-1/
      data b/2.36012909523441209d01,2.44024637934444173d02,
     1       1.28261652607737228d03,2.84423683343917062d03/
C
C>>> Coefficients for approximation to erfc in second interval
      data c/5.64188496988670089D-1,8.88314979438837594D0,
     1       6.61191906371416295D01,2.98635138197400131D02,
     2       8.81952221241769090D02,1.71204761263407058D03,
     3       2.05107837782607147D03,1.23033935479799725D03,
     4       2.15311535474403846D-8/
      data d/1.57449261107098347D01,1.17693950891312499D02,
     1       5.37181101862009858D02,1.62138957456669019D03,
     2       3.29079923573345963D03,4.36261909014324716D03,
     3       3.43936767414372164D03,1.23033935480374942D03/
C
C>>> Coefficients for approximation to erfc in third interval
      data p/3.05326634961232344d-1,3.60344899949804439d-1,
     1       1.25781726111229246d-1,1.60837851487422766d-2,
     2       6.58749161529837803d-4,1.63153871373020978d-2/
      data q/2.56852019228982242d00,1.87295284992346047d00,
     1       5.27905102951428412d-1,6.05183413124413191d-2,
     2       2.33520497626869185d-3/
      x=arg
      y=dabs(x)
      if (y.le.thresh) then
C
C>>> Evaluate erf for |x| <= 0.46875
        ysq=zero
        if (y.gt.xsmall) ysq=y*y
        xnum=a(5)*ysq
        xden=ysq
        do i=1, 3
          xnum=(xnum+a(i))*ysq
          xden=(xden+b(i))*ysq
        enddo    
        result=x*(xnum+a(4))/(xden+b(4))
        if (jint.ne.0) result=one-result
        if (jint.eq.2) result=dexp(ysq)*result
        return     
C
C>>> Evaluate erfc for 0.46875 <= |x| <= 4.0
      elseif (y.le.four) then
        xnum=c(9)*y
        xden=y
        do i=1, 7
          xnum=(xnum+c(i))*y
          xden=(xden+d(i))*y
        enddo     
        result=(xnum+c(8))/(xden+d(8))
        if (jint.ne.2) then
          ysq=aint(y*sixten)/sixten
          del=(y-ysq)*(y+ysq)
          result=dexp(-ysq*ysq)*dexp(-del)*result
        endif
C
C>>> Evaluate erfc for |x| > 4.0
      else
        result=zero
        if (y.ge.xbig) then
          if ((jint.ne.2).or.(y.ge.xmax)) goto 300
          if (y.ge.xhuge) then
            result=sqrpi/y
            goto 300
          endif
        endif
        ysq=one/(y*y)
        xnum=p(6)*ysq
        xden=ysq
        do i=1, 4
          xnum=(xnum+p(i))*ysq
          xden=(xden+q(i))*ysq
        enddo    
        result=ysq *(xnum+p(5))/(xden+q(5))
        result=(sqrpi-result)/y
        if (jint.ne.2) then
          ysq=aint(y*sixten)/sixten
          del=(y-ysq)*(y+ysq)
          result=dexp(-ysq*ysq)*dexp(-del)*result
        endif
      endif
C
C>>> Fix up for negative argument, erf, etc.
300   if (jint.eq.0) then
        result=(half-result)+half
        if (x.lt.zero) result=-result
      elseif (jint.eq.1) then
        if (x.lt.zero) result=two-result
      else
        if (x.lt.zero) then
          if (x.lt.xneg) then
            result=xinf
          else
            ysq=aint(x*sixten)/sixten
            del=(x-ysq)*(x+ysq)
            y=dexp(ysq*ysq)*dexp(del)
            result=(y+y)-result
          endif
        endif
      endif
      return
      end

      
C ##############################################################################
C
C  Added to each function and subroutine a "save" and replaced
C  "stop" with a call to the external function "error". "error" 
C  has to be provided by the caller, A. Trapletti, 14.10.1999
C
C  *** These routines are from the NIST Core Math LIBrary CML ***
C
      SUBROUTINE DSUMSL(N, D, X, CALCF, CALCG, IV, LIV, LV, V,
     1                  UIPARM, URPARM, UFPARM)
      save
C
C  ***  MINIMIZE GENERAL UNCONSTRAINED OBJECTIVE FUNCTION USING   ***
C  ***  ANALYTIC GRADIENT AND HESSIAN APPROX. FROM SECANT UPDATE  ***
C
      INTEGER N, LIV, LV
      INTEGER IV(LIV), UIPARM(1)
      DOUBLE PRECISION D(N), X(N), V(LV), URPARM(1)
C     DIMENSION V(71 + N*(N+15)/2), UIPARM(*), URPARM(*)
      EXTERNAL CALCF, CALCG, UFPARM
C
C  ***  PURPOSE  ***
C
C        THIS ROUTINE INTERACTS WITH SUBROUTINE  DSUMIT  IN AN ATTEMPT
C     TO FIND AN N-VECTOR  X*  THAT MINIMIZES THE (UNCONSTRAINED)
C     OBJECTIVE FUNCTION COMPUTED BY  CALCF.  (OFTEN THE  X*  FOUND IS
C     A LOCAL MINIMIZER RATHER THAN A GLOBAL ONE.)
C
C--------------------------  PARAMETER USAGE  --------------------------
C
C N........ (INPUT) THE NUMBER OF VARIABLES ON WHICH  F  DEPENDS, I.E.,
C                  THE NUMBER OF COMPONENTS IN  X.
C D........ (INPUT/OUTPUT) A SCALE VECTOR SUCH THAT  D(I)*X(I),
C                  I = 1,2,...,N,  ARE ALL IN COMPARABLE UNITS.
C                  D CAN STRONGLY AFFECT THE BEHAVIOR OF DSUMSL.
C                  FINDING THE BEST CHOICE OF D IS GENERALLY A TRIAL-
C                  AND-ERROR PROCESS.  CHOOSING D SO THAT D(I)*X(I)
C                  HAS ABOUT THE SAME VALUE FOR ALL I OFTEN WORKS WELL.
C                  THE DEFAULTS PROVIDED BY SUBROUTINE DDEFLT (SEE IV
C                  BELOW) REQUIRE THE CALLER TO SUPPLY D.
C X........ (INPUT/OUTPUT) BEFORE (INITIALLY) CALLING DSUMSL, THE CALL-
C                  ER SHOULD SET  X  TO AN INITIAL GUESS AT  X*.  WHEN
C                  DSUMSL RETURNS,  X  CONTAINS THE BEST POINT SO FAR
C                  FOUND, I.E., THE ONE THAT GIVES THE LEAST VALUE SO
C                  FAR SEEN FOR  F(X).
C CALCF.... (INPUT) A SUBROUTINE THAT, GIVEN X, COMPUTES F(X).  CALCF
C                  MUST BE DECLARED EXTERNAL IN THE CALLING PROGRAM.
C                  IT IS INVOKED BY
C                       CALL CALCF(N, X, NF, F, UIPARM, URPARM, UFPARM)
C                  NF IS THE INVOCATION COUNT FOR CALCF.  IT IS INCLUD-
C                  ED FOR POSSIBLE USE WITH CALCG.  IF X IS OUT OF
C                  BOUNDS (E.G., IF IT WOULD CAUSE OVERFLOW IN COMPUT-
C                  ING F(X)), THEN CALCF SHOULD SET NF TO 0.  THIS WILL
C                  CAUSE A SHORTER STEP TO BE ATTEMPTED.  THE OTHER
C                  PARAMETERS ARE AS DESCRIBED ABOVE AND BELOW.  CALCF
C                  SHOULD NOT CHANGE N, P, OR X.
C CALCG.... (INPUT) A SUBROUTINE THAT, GIVEN X, COMPUTES G(X), THE GRA-
C                  DIENT OF F AT X.  CALCG MUST BE DECLARED EXTERNAL IN
C                  THE CALLING PROGRAM.  IT IS INVOKED BY
C                       CALL CALCG(N, X, NF, G, UIPARM, URPARM, UFAPRM)
C                  NF IS THE INVOCATION COUNT FOR CALCF AT THE TIME
C                  F(X) WAS EVALUATED.  THE X PASSED TO CALCG IS
C                  USUALLY THE ONE PASSED TO CALCF ON EITHER ITS MOST
C                  RECENT INVOCATION OR THE ONE PRIOR TO IT.  IF CALCF
C                  SAVES INTERMEDIATE RESULTS FOR USE BY CALCG, THEN IT
C                  IS POSSIBLE TO TELL FROM NF WHETHER THEY ARE VALID
C                  FOR THE CURRENT X (OR WHICH COPY IS VALID IF TWO
C                  COPIES ARE KEPT).  IF G CANNOT BE COMPUTED AT X,
C                  THEN CALCG SHOULD SET NF TO 0.  IN THIS CASE, DSUMSL
C                  WILL RETURN WITH IV(1) = 65.  THE OTHER PARAMETERS
C                  TO CALCG ARE AS DESCRIBED ABOVE AND BELOW.  CALCG
C                  SHOULD NOT CHANGE N OR X.
C IV....... (INPUT/OUTPUT) AN INTEGER VALUE ARRAY OF LENGTH LIV (SEE
C                  BELOW) THAT HELPS CONTROL THE DSUMSL ALGORITHM AND
C                  THAT IS USED TO STORE VARIOUS INTERMEDIATE QUANTI-
C                  TIES.  OF PARTICULAR INTEREST ARE THE INITIALIZATION/
C                  RETURN CODE IV(1) AND THE ENTRIES IN IV THAT CONTROL
C                  PRINTING AND LIMIT THE NUMBER OF ITERATIONS AND FUNC-
C                  TION EVALUATIONS.  SEE THE SECTION ON IV INPUT
C                  VALUES BELOW.
C V........ (INPUT/OUTPUT) A FLOATING-POINT VALUE ARRAY OF LENGTH LV
C                  (SEE BELOW) THAT HELPS CONTROL THE DSUMSL ALGORITHM
C                  AND THAT IS USED TO STORE VARIOUS INTERMEDIATE
C                  QUANTITIES.  OF PARTICULAR INTEREST ARE THE ENTRIES
C                  IN V THAT LIMIT THE LENGTH OF THE FIRST STEP
C                  ATTEMPTED (LMAX0) AND SPECIFY CONVERGENCE TOLERANCES
C                  (AFCTOL, LMAXS, RFCTOL, SCTOL, XCTOL, XFTOL).
C LIV...... (INPUT) LENGTH OF IV ARRAY.  MUST BE AT LEAST 60.  IF LIV
C                  IS TOO SMALL, THEN DSUMSL RETURNS WITH IV(1) = 15.
C                  IF LIV IS AT LEAST LASTIV (= 44), THEN THE MINIMUM
C                  ACCEPTABLE VALUE OF LIV IS STORED IN IV(LASTIV)
C                  WHEN DSUMSL RETURNS.  (THIS IS INTENDED FOR USE
C                  WITH EXTENSIONS OF DSUMSL THAT HANDLES CONSTRAINTS.)
C LV....... (INPUT) LENGTH OF V ARRAY.  MUST BE AT LEAST 71+N*(N+15)/2.
C                  (AT LEAST 77+N*(N+17)/2 FOR DSMSNO, AT LEAST
C                  78+N*(N+12) FOR DHUMSL).  IF LV IS TOO SMALL, THEN
C                  DSUMSL RETURNS WITH IV(1) = 16.  IF LIV IS AT LEAST
C                  LASTV (= 45), THEN THE MINIMUM ACCEPTABLE VALUE OF
C                  LV IS STORED IN IV(LASTV) WHEN DSUMSL RETURNS.
C UIPARM... (INPUT) USER INTEGER PARAMETER ARRAY PASSED WITHOUT CHANGE
C                  TO CALCF AND CALCG.
C URPARM... (INPUT) USER FLOATING-POINT PARAMETER ARRAY PASSED WITHOUT
C                  CHANGE TO CALCF AND CALCG.
C UFPARM... (INPUT) USER EXTERNAL SUBROUTINE OR FUNCTION PASSED WITHOUT
C                  CHANGE TO CALCF AND CALCG.
C
C  ***  IV INPUT VALUES (FROM SUBROUTINE DDEFLT)  ***
C
C IV(1)...  ON INPUT, IV(1) SHOULD HAVE A VALUE BETWEEN 0 AND 14......
C             0 AND 12 MEAN THIS IS A FRESH START.  0 MEANS THAT
C                  DDEFLT(2, IV, LIV, LV, V)
C             IS TO BE CALLED TO PROVIDE ALL DEFAULT VALUES TO IV AND
C             V.  12 (THE VALUE THAT DDEFLT ASSIGNS TO IV(1)) MEANS THE
C             CALLER HAS ALREADY CALLED DDEFLT AND HAS POSSIBLY CHANGED
C             SOME IV AND/OR V ENTRIES TO NON-DEFAULT VALUES.
C             13 MEANS DDEFLT HAS BEEN CALLED AND THAT DSUMSL (AND
C             DSUMIT) SHOULD ONLY ALLOCATE STORAGE IN IV AND V.
C             14 MEANS THAT A STORAGE HAS BEEN ALLOCATED (E.G. BY A
C             CALL WITH IV(1) = 13) AND THAT THE ALGORITHM SHOULD BE
C             STARTED.  WHEN CALLED WITH IV(1) = 13, DSUMSL RETURNS
C             IV(1) = 14 UNLESS LIV OR LV IS TOO SMALL (OR N IS NOT
C             POSITIVE).  DEFAULT = 12.
C IV(INITH).... IV(25) TELLS WHETHER THE HESSIAN APPROXIMATION H SHOULD
C             BE INITIALIZED.  1 (THE DEFAULT) MEANS DSUMIT SHOULD
C             INITIALIZE H TO THE DIAGONAL MATRIX WHOSE I-TH DIAGONAL
C             ELEMENT IS D(I)**2.  0 MEANS THE CALLER HAS SUPPLIED A
C             CHOLESKY FACTOR  L  OF THE INITIAL HESSIAN APPROXIMATION
C             H = L*(L**T)  IN V, STARTING AT V(IV(LMAT)) = V(IV(42))
C             (AND STORED COMPACTLY BY ROWS).  NOTE THAT IV(LMAT) MAY
C             BE INITIALIZED BY CALLING DSUMSL WITH IV(1) = 13 (SEE
C             THE IV(1) DISCUSSION ABOVE).  DEFAULT = 1.
C IV(MXFCAL)... IV(17) GIVES THE MAXIMUM NUMBER OF FUNCTION EVALUATIONS
C             (CALLS ON CALCF) ALLOWED.  IF THIS NUMBER DOES NOT SUF-
C             FICE, THEN DSUMSL RETURNS WITH IV(1) = 9.  DEFAULT = 200.
C IV(MXITER)... IV(18) GIVES THE MAXIMUM NUMBER OF ITERATIONS ALLOWED.
C             IT ALSO INDIRECTLY LIMITS THE NUMBER OF GRADIENT EVALUA-
C             TIONS (CALLS ON CALCG) TO IV(MXITER) + 1.  IF IV(MXITER)
C             ITERATIONS DO NOT SUFFICE, THEN DSUMSL RETURNS WITH
C             IV(1) = 10.  DEFAULT = 150.
C IV(OUTLEV)... IV(19) CONTROLS THE NUMBER AND LENGTH OF ITERATION SUM-
C             MARY LINES PRINTED (BY DITSUM).  IV(OUTLEV) = 0 MEANS DO
C             NOT PRINT ANY SUMMARY LINES.  OTHERWISE, PRINT A SUMMARY
C             LINE AFTER EACH ABS(IV(OUTLEV)) ITERATIONS.  IF IV(OUTLEV)
C             IS POSITIVE, THEN SUMMARY LINES OF LENGTH 78 (PLUS CARRI-
C             AGE CONTROL) ARE PRINTED, INCLUDING THE FOLLOWING...  THE
C             ITERATION AND FUNCTION EVALUATION COUNTS, F = THE CURRENT
C             FUNCTION VALUE, RELATIVE DIFFERENCE IN FUNCTION VALUES
C             ACHIEVED BY THE LATEST STEP (I.E., RELDF = (F0-V(F))/F01,
C             WHERE F01 IS THE MAXIMUM OF ABS(V(F)) AND ABS(V(F0)) AND
C             V(F0) IS THE FUNCTION VALUE FROM THE PREVIOUS ITERA-
C             TION), THE RELATIVE FUNCTION REDUCTION PREDICTED FOR THE
C             STEP JUST TAKEN (I.E., PRELDF = V(PREDUC) / F01, WHERE
C             V(PREDUC) IS DESCRIBED BELOW), THE SCALED RELATIVE CHANGE
C             IN X (SEE V(RELDX) BELOW), THE STEP PARAMETER FOR THE
C             STEP JUST TAKEN (STPPAR = 0 MEANS A FULL NEWTON STEP,
C             BETWEEN 0 AND 1 MEANS A RELAXED NEWTON STEP, BETWEEN 1
C             AND 2 MEANS A DOUBLE DOGLEG STEP, GREATER THAN 2 MEANS
C             A SCALED DOWN CAUCHY STEP -- SEE SUBROUTINE DBLDOG), THE
C             2-NORM OF THE SCALE VECTOR D TIMES THE STEP JUST TAKEN
C             (SEE V(DSTNRM) BELOW), AND NPRELDF, I.E.,
C             V(NREDUC)/F01, WHERE V(NREDUC) IS DESCRIBED BELOW -- IF
C             NPRELDF IS POSITIVE, THEN IT IS THE RELATIVE FUNCTION
C             REDUCTION PREDICTED FOR A NEWTON STEP (ONE WITH
C             STPPAR = 0).  IF NPRELDF IS NEGATIVE, THEN IT IS THE
C             NEGATIVE OF THE RELATIVE FUNCTION REDUCTION PREDICTED
C             FOR A STEP COMPUTED WITH STEP BOUND V(LMAXS) FOR USE IN
C             TESTING FOR SINGULAR CONVERGENCE.
C                  IF IV(OUTLEV) IS NEGATIVE, THEN LINES OF LENGTH 50
C             ARE PRINTED, INCLUDING ONLY THE FIRST 6 ITEMS LISTED
C             ABOVE (THROUGH RELDX).
C             DEFAULT = 1.
C IV(PARPRT)... IV(20) = 1 MEANS PRINT ANY NONDEFAULT V VALUES ON A
C             FRESH START OR ANY CHANGED V VALUES ON A RESTART.
C             IV(PARPRT) = 0 MEANS SKIP THIS PRINTING.  DEFAULT = 1.
C IV(PRUNIT)... IV(21) IS THE OUTPUT UNIT NUMBER ON WHICH ALL PRINTING
C             IS DONE.  IV(PRUNIT) = 0 MEANS SUPPRESS ALL PRINTING.
C             DEFAULT = STANDARD OUTPUT UNIT (UNIT 6 ON MOST SYSTEMS).
C IV(SOLPRT)... IV(22) = 1 MEANS PRINT OUT THE VALUE OF X RETURNED (AS
C             WELL AS THE GRADIENT AND THE SCALE VECTOR D).
C             IV(SOLPRT) = 0 MEANS SKIP THIS PRINTING.  DEFAULT = 1.
C IV(STATPR)... IV(23) = 1 MEANS PRINT SUMMARY STATISTICS UPON RETURN-
C             ING.  THESE CONSIST OF THE FUNCTION VALUE, THE SCALED
C             RELATIVE CHANGE IN X CAUSED BY THE MOST RECENT STEP (SEE
C             V(RELDX) BELOW), THE NUMBER OF FUNCTION AND GRADIENT
C             EVALUATIONS (CALLS ON CALCF AND CALCG), AND THE RELATIVE
C             FUNCTION REDUCTIONS PREDICTED FOR THE LAST STEP TAKEN AND
C             FOR A NEWTON STEP (OR PERHAPS A STEP BOUNDED BY V(LMAX0)
C             -- SEE THE DESCRIPTIONS OF PRELDF AND NPRELDF UNDER
C             IV(OUTLEV) ABOVE).
C             IV(STATPR) = 0 MEANS SKIP THIS PRINTING.
C             IV(STATPR) = -1 MEANS SKIP THIS PRINTING AS WELL AS THAT
C             OF THE ONE-LINE TERMINATION REASON MESSAGE.  DEFAULT = 1.
C IV(X0PRT).... IV(24) = 1 MEANS PRINT THE INITIAL X AND SCALE VECTOR D
C             (ON A FRESH START ONLY).  IV(X0PRT) = 0 MEANS SKIP THIS
C             PRINTING.  DEFAULT = 1.
C
C  ***  (SELECTED) IV OUTPUT VALUES  ***
C
C IV(1)........ ON OUTPUT, IV(1) IS A RETURN CODE....
C             3 = X-CONVERGENCE.  THE SCALED RELATIVE DIFFERENCE (SEE
C                  V(RELDX)) BETWEEN THE CURRENT PARAMETER VECTOR X AND
C                  A LOCALLY OPTIMAL PARAMETER VECTOR IS VERY LIKELY AT
C                  MOST V(XCTOL).
C             4 = RELATIVE FUNCTION CONVERGENCE.  THE RELATIVE DIFFER-
C                  ENCE BETWEEN THE CURRENT FUNCTION VALUE AND ITS LO-
C                  CALLY OPTIMAL VALUE IS VERY LIKELY AT MOST V(RFCTOL).
C             5 = BOTH X- AND RELATIVE FUNCTION CONVERGENCE (I.E., THE
C                  CONDITIONS FOR IV(1) = 3 AND IV(1) = 4 BOTH HOLD).
C             6 = ABSOLUTE FUNCTION CONVERGENCE.  THE CURRENT FUNCTION
C                  VALUE IS AT MOST V(AFCTOL) IN ABSOLUTE VALUE.
C             7 = SINGULAR CONVERGENCE.  THE HESSIAN NEAR THE CURRENT
C                  ITERATE APPEARS TO BE SINGULAR OR NEARLY SO, AND A
C                  STEP OF LENGTH AT MOST V(LMAX0) IS UNLIKELY TO YIELD
C                  A RELATIVE FUNCTION DECREASE OF MORE THAN V(SCTOL).
C             8 = FALSE CONVERGENCE.  THE ITERATES APPEAR TO BE CONVERG-
C                  ING TO A NONCRITICAL POINT.  THIS MAY MEAN THAT THE
C                  CONVERGENCE TOLERANCES (V(AFCTOL), V(RFCTOL),
C                  V(XCTOL)) ARE TOO SMALL FOR THE ACCURACY TO WHICH
C                  THE FUNCTION AND GRADIENT ARE BEING COMPUTED, THAT
C                  THERE IS AN ERROR IN COMPUTING THE GRADIENT, OR THAT
C                  THE FUNCTION OR GRADIENT IS DISCONTINUOUS NEAR X.
C             9 = FUNCTION EVALUATION LIMIT REACHED WITHOUT OTHER CON-
C                  VERGENCE (SEE IV(MXFCAL)).
C            10 = ITERATION LIMIT REACHED WITHOUT OTHER CONVERGENCE
C                  (SEE IV(MXITER)).
C            11 = DSTOPX RETURNED .TRUE. (EXTERNAL INTERRUPT).  SEE THE
C                  USAGE NOTES BELOW.
C            14 = STORAGE HAS BEEN ALLOCATED (AFTER A CALL WITH
C                  IV(1) = 13).
C            17 = RESTART ATTEMPTED WITH N CHANGED.
C            18 = D HAS A NEGATIVE COMPONENT AND IV(DTYPE) .LE. 0.
C            19...43 = V(IV(1)) IS OUT OF RANGE.
C            63 = F(X) CANNOT BE COMPUTED AT THE INITIAL X.
C            64 = BAD PARAMETERS PASSED TO ASSESS (WHICH SHOULD NOT
C                  OCCUR).
C            65 = THE GRADIENT COULD NOT BE COMPUTED AT X (SEE CALCG
C                  ABOVE).
C            67 = BAD FIRST PARAMETER TO DDEFLT.
C            80 = IV(1) WAS OUT OF RANGE.
C            81 = N IS NOT POSITIVE.
C IV(G)........ IV(28) IS THE STARTING SUBSCRIPT IN V OF THE CURRENT
C             GRADIENT VECTOR (THE ONE CORRESPONDING TO X).
C IV(NFCALL)... IV(6) IS THE NUMBER OF CALLS SO FAR MADE ON CALCF (I.E.,
C             FUNCTION EVALUATIONS).
C IV(NGCALL)... IV(30) IS THE NUMBER OF GRADIENT EVALUATIONS (CALLS ON
C             CALCG).
C IV(NITER).... IV(31) IS THE NUMBER OF ITERATIONS PERFORMED.
C
C  ***  (SELECTED) V INPUT VALUES (FROM SUBROUTINE DDEFLT)  ***
C
C V(BIAS)..... V(43) IS THE BIAS PARAMETER USED IN SUBROUTINE DBLDOG --
C             SEE THAT SUBROUTINE FOR DETAILS.  DEFAULT = 0.8.
C V(AFCTOL)... V(31) IS THE ABSOLUTE FUNCTION CONVERGENCE TOLERANCE.
C             IF DSUMSL FINDS A POINT WHERE THE FUNCTION VALUE IS LESS
C             THAN V(AFCTOL) IN ABSOLUTE VALUE, AND IF DSUMSL DOES NOT
C             RETURN WITH IV(1) = 3, 4, OR 5, THEN IT RETURNS WITH
C             IV(1) = 6.  DEFAULT = MAX(10**-20, MACHEP**2), WHERE
C             MACHEP IS THE UNIT ROUNDOFF.
C V(DINIT).... V(38), IF NONNEGATIVE, IS THE VALUE TO WHICH THE SCALE
C             VECTOR D IS INITIALIZED.  DEFAULT = -1.
C V(LMAX0).... V(35) GIVES THE MAXIMUM 2-NORM ALLOWED FOR D TIMES THE
C             VERY FIRST STEP THAT DSUMSL ATTEMPTS.  THIS PARAMETER CAN
C             MARKEDLY AFFECT THE PERFORMANCE OF DSUMSL.
C V(LMAXS).... V(36) IS USED IN TESTING FOR SINGULAR CONVERGENCE -- IF
C             THE FUNCTION REDUCTION PREDICTED FOR A STEP OF LENGTH
C             BOUNDED BY V(LMAXS) IS AT MOST V(SCTOL) * ABS(F0), WHERE
C             F0  IS THE FUNCTION VALUE AT THE START OF THE CURRENT
C             ITERATION, AND IF DSUMSL DOES NOT RETURN WITH IV(1) = 3,
C             4, 5, OR 6, THEN IT RETURNS WITH IV(1) = 7.  DEFAULT = 1.
C V(RFCTOL)... V(32) IS THE RELATIVE FUNCTION CONVERGENCE TOLERANCE.
C             IF THE CURRENT MODEL PREDICTS A MAXIMUM POSSIBLE FUNCTION
C             REDUCTION (SEE V(NREDUC)) OF AT MOST V(RFCTOL)*ABS(F0)
C             AT THE START OF THE CURRENT ITERATION, WHERE  F0  IS THE
C             THEN CURRENT FUNCTION VALUE, AND IF THE LAST STEP ATTEMPT-
C             ED ACHIEVED NO MORE THAN TWICE THE PREDICTED FUNCTION
C             DECREASE, THEN DSUMSL RETURNS WITH IV(1) = 4 (OR 5).
C             DEFAULT = MAX(10**-10, MACHEP**(2/3)), WHERE MACHEP IS
C             THE UNIT ROUNDOFF.
C V(SCTOL).... V(37) IS THE SINGULAR CONVERGENCE TOLERANCE -- SEE THE
C             DESCRIPTION OF V(LMAXS) ABOVE.
C V(TUNER1)... V(26) HELPS DECIDE WHEN TO CHECK FOR FALSE CONVERGENCE.
C             THIS IS DONE IF THE ACTUAL FUNCTION DECREASE FROM THE
C             CURRENT STEP IS NO MORE THAN V(TUNER1) TIMES ITS PREDICT-
C             ED VALUE.  DEFAULT = 0.1.
C V(XCTOL).... V(33) IS THE X-CONVERGENCE TOLERANCE.  IF A NEWTON STEP
C             (SEE V(NREDUC)) IS TRIED THAT HAS V(RELDX) .LE. V(XCTOL)
C             AND IF THIS STEP YIELDS AT MOST TWICE THE PREDICTED FUNC-
C             TION DECREASE, THEN DSUMSL RETURNS WITH IV(1) = 3 (OR 5).
C             (SEE THE DESCRIPTION OF V(RELDX) BELOW.)
C             DEFAULT = MACHEP**0.5, WHERE MACHEP IS THE UNIT ROUNDOFF.
C V(XFTOL).... V(34) IS THE FALSE CONVERGENCE TOLERANCE.  IF A STEP IS
C             TRIED THAT GIVES NO MORE THAN V(TUNER1) TIMES THE PREDICT-
C             ED FUNCTION DECREASE AND THAT HAS V(RELDX) .LE. V(XFTOL),
C             AND IF DSUMSL DOES NOT RETURN WITH IV(1) = 3, 4, 5, 6, OR
C             7, THEN IT RETURNS WITH IV(1) = 8.  (SEE THE DESCRIPTION
C             OF V(RELDX) BELOW.)  DEFAULT = 100*MACHEP, WHERE
C             MACHEP IS THE UNIT ROUNDOFF.
C V(*)........ DDEFLT SUPPLIES TO V A NUMBER OF TUNING CONSTANTS, WITH
C             WHICH IT SHOULD ORDINARILY BE UNNECESSARY TO TINKER.  SEE
C             SECTION 17 OF VERSION 2.2 OF THE NL2SOL USAGE SUMMARY
C             (I.E., THE APPENDIX TO REF. 1) FOR DETAILS ON V(I),
C             I = DECFAC, INCFAC, PHMNFC, PHMXFC, RDFCMN, RDFCMX,
C             TUNER2, TUNER3, TUNER4, TUNER5.
C
C  ***  (SELECTED) V OUTPUT VALUES  ***
C
C V(DGNORM)... V(1) IS THE 2-NORM OF (DIAG(D)**-1)*G, WHERE G IS THE
C             MOST RECENTLY COMPUTED GRADIENT.
C V(DSTNRM)... V(2) IS THE 2-NORM OF DIAG(D)*STEP, WHERE STEP IS THE
C             CURRENT STEP.
C V(F)........ V(10) IS THE CURRENT FUNCTION VALUE.
C V(F0)....... V(13) IS THE FUNCTION VALUE AT THE START OF THE CURRENT
C             ITERATION.
C V(NREDUC)... V(6), IF POSITIVE, IS THE MAXIMUM FUNCTION REDUCTION
C             POSSIBLE ACCORDING TO THE CURRENT MODEL, I.E., THE FUNC-
C             TION REDUCTION PREDICTED FOR A NEWTON STEP (I.E.,
C             STEP = -H**-1 * G,  WHERE  G  IS THE CURRENT GRADIENT AND
C             H IS THE CURRENT HESSIAN APPROXIMATION).
C                  IF V(NREDUC) IS NEGATIVE, THEN IT IS THE NEGATIVE OF
C             THE FUNCTION REDUCTION PREDICTED FOR A STEP COMPUTED WITH
C             A STEP BOUND OF V(LMAXS) FOR USE IN TESTING FOR SINGULAR
C             CONVERGENCE.
C V(PREDUC)... V(7) IS THE FUNCTION REDUCTION PREDICTED (BY THE CURRENT
C             QUADRATIC MODEL) FOR THE CURRENT STEP.  THIS (DIVIDED BY
C             V(F0)) IS USED IN TESTING FOR RELATIVE FUNCTION
C             CONVERGENCE.
C V(RELDX).... V(17) IS THE SCALED RELATIVE CHANGE IN X CAUSED BY THE
C             CURRENT STEP, COMPUTED AS
C                  MAX(ABS(D(I)*(X(I)-X0(I)), 1 .LE. I .LE. P) /
C                     MAX(D(I)*(ABS(X(I))+ABS(X0(I))), 1 .LE. I .LE. P),
C             WHERE X = X0 + STEP.
C
C-------------------------------  NOTES  -------------------------------
C
C  ***  ALGORITHM NOTES  ***
C
C        THIS ROUTINE USES A HESSIAN APPROXIMATION COMPUTED FROM THE
C     BFGS UPDATE (SEE REF 3).  ONLY A CHOLESKY FACTOR OF THE HESSIAN
C     APPROXIMATION IS STORED, AND THIS IS UPDATED USING IDEAS FROM
C     REF. 4.  STEPS ARE COMPUTED BY THE DOUBLE DOGLEG SCHEME DESCRIBED
C     IN REF. 2.  THE STEPS ARE ASSESSED AS IN REF. 1.
C
C  ***  USAGE NOTES  ***
C
C        AFTER A RETURN WITH IV(1) .LE. 11, IT IS POSSIBLE TO RESTART,
C     I.E., TO CHANGE SOME OF THE IV AND V INPUT VALUES DESCRIBED ABOVE
C     AND CONTINUE THE ALGORITHM FROM THE POINT WHERE IT WAS INTERRUPT-
C     ED.  IV(1) SHOULD NOT BE CHANGED, NOR SHOULD ANY ENTRIES OF IV
C     AND V OTHER THAN THE INPUT VALUES (THOSE SUPPLIED BY DDEFLT).
C        THOSE WHO DO NOT WISH TO WRITE A CALCG WHICH COMPUTES THE
C     GRADIENT ANALYTICALLY SHOULD CALL DSMSNO RATHER THAN DSUMSL.
C     DSMSNO USES FINITE DIFFERENCES TO COMPUTE AN APPROXIMATE GRADIENT.
C        THOSE WHO WOULD PREFER TO PROVIDE F AND G (THE FUNCTION AND
C     GRADIENT) BY REVERSE COMMUNICATION RATHER THAN BY WRITING SUBROU-
C     TINES CALCF AND CALCG MAY CALL ON DSUMIT DIRECTLY.  SEE THE COM-
C     MENTS AT THE BEGINNING OF DSUMIT.
C        THOSE WHO USE DSUMSL INTERACTIVELY MAY WISH TO SUPPLY THEIR
C     OWN DSTOPX FUNCTION, WHICH SHOULD RETURN .TRUE. IF THE BREAK KEY
C     HAS BEEN PRESSED SINCE DSTOPX WAS LAST INVOKED.  THIS MAKES IT
C     POSSIBLE TO EXTERNALLY INTERRUPT DSUMSL (WHICH WILL RETURN WITH
C     IV(1) = 11 IF DSTOPX RETURNS .TRUE.).
C        STORAGE FOR G IS ALLOCATED AT THE END OF V.  THUS THE CALLER
C     MAY MAKE V LONGER THAN SPECIFIED ABOVE AND MAY ALLOW CALCG TO USE
C     ELEMENTS OF G BEYOND THE FIRST N AS SCRATCH STORAGE.
C
C  ***  PORTABILITY NOTES  ***
C
C        THE DSUMSL DISTRIBUTION TAPE CONTAINS BOTH SINGLE- AND DOUBLE-
C     PRECISION VERSIONS OF THE DSUMSL SOURCE CODE, SO IT SHOULD BE UN-
C     NECESSARY TO CHANGE PRECISIONS.
C        INTRINSIC FUNCTIONS ARE EXPLICITLY DECLARED.  ON CERTAIN COM-
C     PUTERS (E.G. UNIVAC), IT MAY BE NECESSARY TO COMMENT OUT THESE
C     DECLARATIONS.  SO THAT THIS MAY BE DONE AUTOMATICALLY BY A SIMPLE
C     PROGRAM, SUCH DECLARATIONS ARE PRECEDED BY A COMMENT HAVING C/+
C     IN COLUMNS 1-3 AND BLANKS IN COLUMNS 4-72 AND ARE FOLLOWED BY
C     A COMMENT HAVING C/ IN COLUMNS 1 AND 2 AND BLANKS IN COLUMNS 3-72.
C        THE DSUMSL SOURCE CODE IS EXPRESSED IN 1966 ANSI STANDARD
C     FORTRAN.  IT MAY BE CONVERTED TO FORTRAN 77 BY COMMENTING OUT ALL
C     LINES THAT FALL BETWEEN A LINE HAVING C/6 IN COLUMNS 1-3 AND A
C     LINE HAVING C/7 IN COLUMNS 1-3 AND BY REMOVING (I.E., REPLACING
C     BY A BLANK) THE C IN COLUMN 1 OF THE LINES THAT FOLLOW THE C/7
C     LINE AND PRECEDE A LINE HAVING C/ IN COLUMNS 1-2 AND BLANKS IN
C     COLUMNS 3-72.  THESE CHANGES CONVERT SOME DATA STATEMENTS INTO
C     PARAMETER STATEMENTS, CONVERT SOME VARIABLES FROM REAL TO
C     CHARACTER*4, AND MAKE THE DATA STATEMENTS THAT INITIALIZE THESE
C     VARIABLES USE CHARACTER STRINGS DELIMITED BY PRIMES INSTEAD
C     OF HOLLERITH CONSTANTS.  (SUCH VARIABLES AND DATA STATEMENTS
C     APPEAR ONLY IN MODULES DITSUM AND DPARCK.  PARAMETER STATEMENTS
C     APPEAR NEARLY EVERYWHERE.)
C
C  ***  REFERENCES  ***
C
C 1.  DENNIS, J.E., GAY, D.M., AND WELSCH, R.E. (1981), ALGORITHM 573 --
C             AN ADAPTIVE NONLINEAR LEAST-SQUARES ALGORITHM, ACM TRANS.
C             MATH. SOFTWARE 7, PP. 369-383.
C
C 2.  DENNIS, J.E., AND MEI, H.H.W. (1979), TWO NEW UNCONSTRAINED OPTI-
C             MIZATION ALGORITHMS WHICH USE FUNCTION AND GRADIENT
C             VALUES, J. OPTIM. THEORY APPLIC. 28, PP. 453-482.
C
C 3.  DENNIS, J.E., AND MORE, J.J. (1977), QUASI-NEWTON METHODS, MOTIVA-
C             TION AND THEORY, SIAM REV. 19, PP. 46-89.
C
C 4.  GOLDFARB, D. (1976), FACTORIZED VARIABLE METRIC METHODS FOR UNCON-
C             STRAINED OPTIMIZATION, MATH. COMPUT. 30, PP. 796-811.
C
C  ***  GENERAL  ***
C
C     CODED BY DAVID M. GAY (WINTER 1980).  REVISED SUMMER 1982.
C     THIS SUBROUTINE WAS WRITTEN IN CONNECTION WITH RESEARCH
C     SUPPORTED IN PART BY THE NATIONAL SCIENCE FOUNDATION UNDER
C     GRANTS MCS-7600324, DCR75-10143, 76-14311DSS, MCS76-11989,
C     AND MCS-7906671.
C
C.
C----------------------------  DECLARATIONS  ---------------------------
C
      EXTERNAL DDEFLT, DSUMIT
C
C DDEFLT.... SUPPLIES DEFAULT IV AND V INPUT COMPONENTS.
C DSUMIT... REVERSE-COMMUNICATION ROUTINE THAT CARRIES OUT DSUMSL ALGO-
C             RITHM.
C
      INTEGER G1, IV1, NF
      DOUBLE PRECISION F
C
C  ***  SUBSCRIPTS FOR IV   ***
C
      INTEGER NEXTV, NFCALL, NFGCAL, G, TOOBIG, VNEED
C
C/6
      DATA NEXTV/47/, NFCALL/6/, NFGCAL/7/, G/28/, TOOBIG/2/, VNEED/4/
C/7
C     PARAMETER (NEXTV=47, NFCALL=6, NFGCAL=7, G=28, TOOBIG=2, VNEED=4)
C/
C
C+++++++++++++++++++++++++++++++  BODY  ++++++++++++++++++++++++++++++++
C
      IF (IV(1) .EQ. 0) CALL DDEFLT(2, IV, LIV, LV, V)
      IV(VNEED) = IV(VNEED) + N
      IV1 = IV(1)
      IF (IV1 .EQ. 14) GO TO 10
      IF (IV1 .GT. 2 .AND. IV1 .LT. 12) GO TO 10
      G1 = 1
      IF (IV1 .EQ. 12) IV(1) = 13
      GO TO 20
C
 10   G1 = IV(G)
C
 20   CALL DSUMIT(D, F, V(G1), IV, LIV, LV, N, V, X)
      IF (IV(1) - 2) 30, 40, 50
C
 30   NF = IV(NFCALL)
      CALL CALCF(N, X, NF, F, UIPARM, URPARM, UFPARM)
      IF (NF .LE. 0) IV(TOOBIG) = 1
      GO TO 20
C
 40   CALL CALCG(N, X, IV(NFGCAL), V(G1), UIPARM, URPARM, UFPARM)
      GO TO 20
C
 50   IF (IV(1) .NE. 14) GO TO 999
C
C  ***  STORAGE ALLOCATION
C
      IV(G) = IV(NEXTV)
      IV(NEXTV) = IV(G) + N
      IF (IV1 .NE. 13) GO TO 10
C
 999  RETURN
C  ***  LAST CARD OF DSUMSL FOLLOWS  ***
      END
      SUBROUTINE DDEFLT(ALG, IV, LIV, LV, V)
      save
C
C  ***  SUPPLY ***SOL (VERSION 2.3) DEFAULT VALUES TO IV AND V  ***
C
C  ***  ALG = 1 MEANS REGRESSION CONSTANTS.
C  ***  ALG = 2 MEANS GENERAL UNCONSTRAINED OPTIMIZATION CONSTANTS.
C
      INTEGER LIV, LV
      INTEGER ALG, IV(LIV)
      DOUBLE PRECISION V(LV)
C
      EXTERNAL  DVDFLT
C DVDFLT.... PROVIDES DEFAULT VALUES TO V.
C
      INTEGER MIV, MV
      INTEGER MINIV(2), MINV(2)
C
C  ***  SUBSCRIPTS FOR IV  ***
C
      INTEGER ALGSAV, COVPRT, COVREQ, DTYPE, HC, IERR, INITH, INITS,
     1        IPIVOT, IVNEED, LASTIV, LASTV, LMAT, MXFCAL, MXITER,
     2        NFCOV, NGCOV, NVDFLT, OUTLEV, PARPRT, PARSAV, PERM,
     3        PRUNIT, QRTYP, RDREQ, RMAT, SOLPRT, STATPR, VNEED,
     4        VSAVE, X0PRT
C
C  ***  IV SUBSCRIPT VALUES  ***
C
C/6
      DATA ALGSAV/51/, COVPRT/14/, COVREQ/15/, DTYPE/16/, HC/71/,
     1     IERR/75/, INITH/25/, INITS/25/, IPIVOT/76/, IVNEED/3/,
     2     LASTIV/44/, LASTV/45/, LMAT/42/, MXFCAL/17/, MXITER/18/,
     3     NFCOV/52/, NGCOV/53/, NVDFLT/50/, OUTLEV/19/, PARPRT/20/,
     4     PARSAV/49/, PERM/58/, PRUNIT/21/, QRTYP/80/, RDREQ/57/,
     5     RMAT/78/, SOLPRT/22/, STATPR/23/, VNEED/4/, VSAVE/60/,
     6     X0PRT/24/
C/7
C     PARAMETER (ALGSAV=51, COVPRT=14, COVREQ=15, DTYPE=16, HC=71,
C    1           IERR=75, INITH=25, INITS=25, IPIVOT=76, IVNEED=3,
C    2           LASTIV=44, LASTV=45, LMAT=42, MXFCAL=17, MXITER=18,
C    3           NFCOV=52, NGCOV=53, NVDFLT=50, OUTLEV=19, PARPRT=20,
C    4           PARSAV=49, PERM=58, PRUNIT=21, QRTYP=80, RDREQ=57,
C    5           RMAT=78, SOLPRT=22, STATPR=23, VNEED=4, VSAVE=60,
C    6           X0PRT=24)
C/
      DATA MINIV(1)/80/, MINIV(2)/59/, MINV(1)/98/, MINV(2)/71/
C
C-------------------------------  BODY  --------------------------------
C
      IF (ALG .LT. 1 .OR. ALG .GT. 2) GO TO 40
      MIV = MINIV(ALG)
      IF (LIV .LT. MIV) GO TO 20
      MV = MINV(ALG)
      IF (LV .LT. MV) GO TO 30
      CALL DVDFLT(ALG, LV, V)
      IV(1) = 12
      IV(ALGSAV) = ALG
      IV(IVNEED) = 0
      IV(LASTIV) = MIV
      IV(LASTV) = MV
      IV(LMAT) = MV + 1
      IV(MXFCAL) = 200
      IV(MXITER) = 150
      IV(OUTLEV) = 1
      IV(PARPRT) = 1
      IV(PERM) = MIV + 1
      IV(PRUNIT) = I1MACH(2)
      IV(SOLPRT) = 1
      IV(STATPR) = 1
      IV(VNEED) = 0
      IV(X0PRT) = 1
C
      IF (ALG .GE. 2) GO TO 10
C
C  ***  REGRESSION  VALUES
C
      IV(COVPRT) = 3
      IV(COVREQ) = 1
      IV(DTYPE) = 1
      IV(HC) = 0
      IV(IERR) = 0
      IV(INITS) = 0
      IV(IPIVOT) = 0
      IV(NVDFLT) = 32
      IV(PARSAV) = 67
      IV(QRTYP) = 1
      IV(RDREQ) = 3
      IV(RMAT) = 0
      IV(VSAVE) = 58
      GO TO 999
C
C  ***  GENERAL OPTIMIZATION VALUES
C
 10   IV(DTYPE) = 0
      IV(INITH) = 1
      IV(NFCOV) = 0
      IV(NGCOV) = 0
      IV(NVDFLT) = 25
      IV(PARSAV) = 47
      GO TO 999
C
 20   IV(1) = 15
      GO TO 999
C
 30   IV(1) = 16
      GO TO 999
C
 40   IV(1) = 67
C
 999  RETURN
C  ***  LAST CARD OF DDEFLT FOLLOWS  ***
      END
      SUBROUTINE DSUMIT(D, FX, G, IV, LIV, LV, N, V, X)
      save
C
C  ***  CARRY OUT DSUMSL (UNCONSTRAINED MINIMIZATION) ITERATIONS, USING
C  ***  DOUBLE-DOGLEG/BFGS STEPS.
C
C  ***  PARAMETER DECLARATIONS  ***
C
      INTEGER LIV, LV, N
      INTEGER IV(LIV)
      DOUBLE PRECISION D(N), FX, G(N), V(LV), X(N)
C
C--------------------------  PARAMETER USAGE  --------------------------
C
C D.... SCALE VECTOR.
C FX... FUNCTION VALUE.
C G.... GRADIENT VECTOR.
C IV... INTEGER VALUE ARRAY.
C LIV.. LENGTH OF IV (AT LEAST 60).
C LV... LENGTH OF V (AT LEAST 71 + N*(N+13)/2).
C N.... NUMBER OF VARIABLES (COMPONENTS IN X AND G).
C V.... FLOATING-POINT VALUE ARRAY.
C X.... VECTOR OF PARAMETERS TO BE OPTIMIZED.
C
C  ***  DISCUSSION  ***
C
C        PARAMETERS IV, N, V, AND X ARE THE SAME AS THE CORRESPONDING
C     ONES TO DSUMSL (WHICH SEE), EXCEPT THAT V CAN BE SHORTER (SINCE
C     THE PART OF V THAT DSUMSL USES FOR STORING G IS NOT NEEDED).
C     MOREOVER, COMPARED WITH DSUMSL, IV(1) MAY HAVE THE TWO ADDITIONAL
C     OUTPUT VALUES 1 AND 2, WHICH ARE EXPLAINED BELOW, AS IS THE USE
C     OF IV(TOOBIG) AND IV(NFGCAL).  THE VALUE IV(G), WHICH IS AN
C     OUTPUT VALUE FROM DSUMSL (AND DSMSNO), IS NOT REFERENCED BY
C     DSUMIT OR THE SUBROUTINES IT CALLS.
C        FX AND G NEED NOT HAVE BEEN INITIALIZED WHEN DSUMIT IS CALLED
C     WITH IV(1) = 12, 13, OR 14.
C
C IV(1) = 1 MEANS THE CALLER SHOULD SET FX TO F(X), THE FUNCTION VALUE
C             AT X, AND CALL DSUMIT AGAIN, HAVING CHANGED NONE OF THE
C             OTHER PARAMETERS.  AN EXCEPTION OCCURS IF F(X) CANNOT BE
C             (E.G. IF OVERFLOW WOULD OCCUR), WHICH MAY HAPPEN BECAUSE
C             OF AN OVERSIZED STEP.  IN THIS CASE THE CALLER SHOULD SET
C             IV(TOOBIG) = IV(2) TO 1, WHICH WILL CAUSE DSUMIT TO IG-
C             NORE FX AND TRY A SMALLER STEP.  THE PARAMETER NF THAT
C             DSUMSL PASSES TO CALCF (FOR POSSIBLE USE BY CALCG) IS A
C             COPY OF IV(NFCALL) = IV(6).
C IV(1) = 2 MEANS THE CALLER SHOULD SET G TO G(X), THE GRADIENT VECTOR
C             OF F AT X, AND CALL DSUMIT AGAIN, HAVING CHANGED NONE OF
C             THE OTHER PARAMETERS EXCEPT POSSIBLY THE SCALE VECTOR D
C             WHEN IV(DTYPE) = 0.  THE PARAMETER NF THAT DSUMSL PASSES
C             TO CALCG IS IV(NFGCAL) = IV(7).  IF G(X) CANNOT BE
C             EVALUATED, THEN THE CALLER MAY SET IV(NFGCAL) TO 0, IN
C             WHICH CASE DSUMIT WILL RETURN WITH IV(1) = 65.
C.
C  ***  GENERAL  ***
C
C     CODED BY DAVID M. GAY (DECEMBER 1979).  REVISED SEPT. 1982.
C     THIS SUBROUTINE WAS WRITTEN IN CONNECTION WITH RESEARCH SUPPORTED
C     IN PART BY THE NATIONAL SCIENCE FOUNDATION UNDER GRANTS
C     MCS-7600324 AND MCS-7906671.
C
C        (SEE DSUMSL FOR REFERENCES.)
C
C+++++++++++++++++++++++++++  DECLARATIONS  ++++++++++++++++++++++++++++
C
C  ***  LOCAL VARIABLES  ***
C
      INTEGER DG1, DUMMY, G01, I, K, L, LSTGST, NN1O2, NWTST1, STEP1,
     1        TEMP1, W, X01, Z
      DOUBLE PRECISION T
C
C     ***  CONSTANTS  ***
C
      DOUBLE PRECISION NEGONE, ONE, ZERO
C
C  ***  NO INTRINSIC FUNCTIONS  ***
C
C  ***  EXTERNAL FUNCTIONS AND SUBROUTINES  ***
C
      EXTERNAL DASSST, DDBDOG, DDEFLT, DITSUM, DLITVM, DLIVMU,
     1         DLTVMU, DLUPDT, DLVMUL, DPARCK, DSTOPX, DVAXPY,
     2         DVSCPY, DVVMUP, DWZBFG
      LOGICAL DSTOPX
      DOUBLE PRECISION DDOT, DNRM2
C
C DASSST.... ASSESSES CANDIDATE STEP.
C DDBDOG.... COMPUTES DOUBLE-DOGLEG (CANDIDATE) STEP.
C DDEFLT.... SUPPLIES DEFAULT IV AND V INPUT COMPONENTS.
C DITSUM.... PRINTS ITERATION SUMMARY AND INFO ON INITIAL AND FINAL X.
C DLITVM... MULTIPLIES INVERSE TRANSPOSE OF LOWER TRIANGLE TIMES VECTOR.
C DLIVMU... MULTIPLIES INVERSE OF LOWER TRIANGLE TIMES VECTOR.
C DLTVMU... MULTIPLIES TRANSPOSE OF LOWER TRIANGLE TIMES VECTOR.
C LUPDT.... UPDATES CHOLESKY FACTOR OF HESSIAN APPROXIMATION.
C DLVMUL.... MULTIPLIES LOWER TRIANGLE TIMES VECTOR.
C DPARCK.... CHECKS VALIDITY OF INPUT IV AND V VALUES.
C DSTOPX.... RETURNS .TRUE. IF THE BREAK KEY HAS BEEN PRESSED.
C DVAXPY.... COMPUTES SCALAR TIMES ONE VECTOR PLUS ANOTHER.
C DVSCPY... SETS ALL ELEMENTS OF A VECTOR TO A SCALAR.
C DVVMUP... MULTIPLIES VECTOR BY VECTOR RAISED TO POWER (COMPONENTWISE).
C DWZBFG... COMPUTES W AND Z FOR DLUPDT CORRESPONDING TO BFGS UPDATE.
C
C  ***  SUBSCRIPTS FOR IV AND V  ***
C
      INTEGER CNVCOD, DG, DGNORM, DINIT, DSTNRM, DST0, F, F0,
     1        GTHG, GTSTEP, G0, INCFAC, INITH, IRC, KAGQT, LMAT,
     2        LMAX0, MODE, MODEL, MXFCAL, MXITER, NEXTV, NFCALL, NFGCAL,
     3        NGCALL, NITER, NWTSTP, RADFAC, RADINC, RADIUS, RAD0, STEP,
     4        STGLIM, STLSTG, TOOBIG, TUNER4, TUNER5, VNEED, XIRC, X0
C
C  ***  IV SUBSCRIPT VALUES  ***
C
C/6
      DATA CNVCOD/55/, DG/37/, G0/48/, INITH/25/, IRC/29/, KAGQT/33/,
     1     MODE/35/, MODEL/5/, MXFCAL/17/, MXITER/18/, NFCALL/6/,
     2     NFGCAL/7/, NGCALL/30/, NITER/31/, NWTSTP/34/, RADINC/8/,
     3     STEP/40/, STGLIM/11/, STLSTG/41/, TOOBIG/2/, XIRC/13/, X0/43/
C/7
C     PARAMETER (CNVCOD=55, DG=37, G0=48, INITH=25, IRC=29, KAGQT=33,
C    1           MODE=35, MODEL=5, MXFCAL=17, MXITER=18, NFCALL=6,
C    2           NFGCAL=7, NGCALL=30, NITER=31, NWTSTP=34, RADINC=8,
C    3           STEP=40, STGLIM=11, STLSTG=41, TOOBIG=2, XIRC=13,
C    4           X0=43)
C/
C
C  ***  V SUBSCRIPT VALUES  ***
C
C/6
      DATA DGNORM/1/, DINIT/38/, DSTNRM/2/, DST0/3/, F/10/, F0/13/,
     1     GTHG/44/, GTSTEP/4/, INCFAC/23/, LMAT/42/, LMAX0/35/,
     2     NEXTV/47/, RADFAC/16/, RADIUS/8/, RAD0/9/, TUNER4/29/,
     3     TUNER5/30/, VNEED/4/
C/7
C     PARAMETER (DGNORM=1, DINIT=38, DSTNRM=2, DST0=3, F=10, F0=13,
C    1           GTHG=44, GTSTEP=4, INCFAC=23, LMAT=42, LMAX0=35,
C    2           NEXTV=47, RADFAC=16, RADIUS=8, RAD0=9, TUNER4=29,
C    3           TUNER5=30, VNEED=4)
C/
C
C/6
      DATA NEGONE/-1.D+0/, ONE/1.D+0/, ZERO/0.D+0/
C/7
C     PARAMETER (NEGONE=-1.D+0, ONE=1.D+0, ZERO=0.D+0)
C/
C
C+++++++++++++++++++++++++++++++  BODY  ++++++++++++++++++++++++++++++++
C
      I = IV(1)
      IF (I .EQ. 1) GO TO 40
      IF (I .EQ. 2) GO TO 50
C
C  ***  CHECK VALIDITY OF IV AND V INPUT VALUES  ***
C
      IF (IV(1) .EQ. 0) CALL DDEFLT(2, IV, LIV, LV, V)
      IV(VNEED) = IV(VNEED) + N*(N+13)/2
      CALL DPARCK(2, D, IV, LIV, LV, N, V)
      I = IV(1) - 2
      IF (I .GT. 12) GO TO 999
      GO TO (160, 160, 160, 160, 160, 160, 110, 80, 110, 10, 10, 20), I
C
C  ***  STORAGE ALLOCATION  ***
C
 10   NN1O2 = N * (N + 1) / 2
      L = IV(LMAT)
      IV(X0) = L + NN1O2
      IV(STEP) = IV(X0) + N
      IV(STLSTG) = IV(STEP) + N
      IV(G0) = IV(STLSTG) + N
      IV(NWTSTP) = IV(G0) + N
      IV(DG) = IV(NWTSTP) + N
      IV(NEXTV) = IV(DG) + N
      IF (IV(1) .NE. 13) GO TO 20
         IV(1) = 14
         GO TO 999
C
C  ***  INITIALIZATION  ***
C
 20   IV(NITER) = 0
      IV(NFCALL) = 1
      IV(NGCALL) = 1
      IV(NFGCAL) = 1
      IV(MODE) = -1
      IV(MODEL) = 1
      IV(STGLIM) = 1
      IV(TOOBIG) = 0
      IV(CNVCOD) = 0
      IV(RADINC) = 0
      V(RAD0) = ZERO
      IF (V(DINIT) .GE. ZERO) CALL DVSCPY(N, D, V(DINIT))
      IV(1) = 1
      IF (IV(INITH) .NE. 1) GO TO 999
C
C     ***  SET THE INITIAL HESSIAN APPROXIMATION TO DIAG(D)**-2  ***
C
         CALL DVSCPY(NN1O2, V(L), ZERO)
         K = L - 1
         DO 30 I = 1, N
              K = K + I
              T = D(I)
              IF (T .LE. ZERO) T = ONE
              V(K) = T
 30           CONTINUE
      GO TO 999
C
 40   V(F) = FX
      IF (IV(MODE) .GE. 0) GO TO 160
      IV(1) = 2
      IF (IV(TOOBIG) .EQ. 0) GO TO 999
         IV(1) = 63
         GO TO 270
C
C  ***  MAKE SURE GRADIENT COULD BE COMPUTED  ***
C
 50   IF (IV(NFGCAL) .NE. 0) GO TO 60
         IV(1) = 65
         GO TO 270
C
 60   DG1 = IV(DG)
      CALL DVVMUP(N, V(DG1), G, D, -1)
      V(DGNORM) = DNRM2(N, V(DG1),1)
C
      IF (IV(CNVCOD) .NE. 0) GO TO 260
      IF (IV(MODE) .EQ. 0) GO TO 220
C
C  ***  ALLOW FIRST STEP TO HAVE SCALED 2-NORM AT MOST V(LMAX0)  ***
C
      V(RADFAC) = V(LMAX0)
      V(DSTNRM) = ONE
C
      IV(MODE) = 0
C
C
C-----------------------------  MAIN LOOP  -----------------------------
C
C
C  ***  PRINT ITERATION SUMMARY, CHECK ITERATION LIMIT  ***
C
 70   CALL DITSUM(D, G, IV, LIV, LV, N, V, X)
 80   K = IV(NITER)
      IF (K .LT. IV(MXITER)) GO TO 90
         IV(1) = 10
         GO TO 270
C
C  ***  UPDATE RADIUS  ***
C
 90   IV(NITER) = K + 1
      V(RADIUS) = V(RADFAC) * V(DSTNRM)
C
C  ***  INITIALIZE FOR START OF NEXT ITERATION  ***
C
      G01 = IV(G0)
      X01 = IV(X0)
      V(F0) = V(F)
      IV(IRC) = 4
      IV(KAGQT) = -1
C
C     ***  COPY X TO X0, G TO G0  ***
C
      CALL DCOPY(N, X,1,V(X01),1)
      CALL DCOPY(N, G,1,V(G01),1)
C
C  ***  CHECK DSTOPX AND FUNCTION EVALUATION LIMIT  ***
C
 100  IF (.NOT. DSTOPX(DUMMY)) GO TO 120
         IV(1) = 11
         GO TO 130
C
C     ***  COME HERE WHEN RESTARTING AFTER FUNC. EVAL. LIMIT OR DSTOPX.
C
 110  IF (V(F) .GE. V(F0)) GO TO 120
         V(RADFAC) = ONE
         K = IV(NITER)
         GO TO 90
C
 120  IF (IV(NFCALL) .LT. IV(MXFCAL)) GO TO 140
         IV(1) = 9
 130     IF (V(F) .GE. V(F0)) GO TO 270
C
C        ***  IN CASE OF DSTOPX OR FUNCTION EVALUATION LIMIT WITH
C        ***  IMPROVED V(F), EVALUATE THE GRADIENT AT X.
C
              IV(CNVCOD) = IV(1)
              GO TO 210
C
C. . . . . . . . . . . . .  COMPUTE CANDIDATE STEP  . . . . . . . . . .
C
 140  STEP1 = IV(STEP)
      DG1 = IV(DG)
      NWTST1 = IV(NWTSTP)
      IF (IV(KAGQT) .GE. 0) GO TO 150
         L = IV(LMAT)
         CALL DLIVMU(N, V(NWTST1), V(L), G)
         CALL DLITVM(N, V(NWTST1), V(L), V(NWTST1))
         CALL DVVMUP(N, V(STEP1), V(NWTST1), D, 1)
         V(DST0) = DNRM2(N, V(STEP1),1)
         CALL DVVMUP(N, V(DG1), V(DG1), D, -1)
         CALL DLTVMU(N, V(STEP1), V(L), V(DG1))
         V(GTHG) = DNRM2(N, V(STEP1),1)
         IV(KAGQT) = 0
 150  CALL DDBDOG(V(DG1), G, LV, N, V(NWTST1), V(STEP1), V)
      IF (IV(IRC) .EQ. 6) GO TO 160
C
C  ***  COMPUTE F(X0 + STEP)  ***
C
      X01 = IV(X0)
      STEP1 = IV(STEP)
      CALL DVAXPY(N, X, ONE, V(STEP1), V(X01))
      IV(NFCALL) = IV(NFCALL) + 1
      IV(1) = 1
      IV(TOOBIG) = 0
      GO TO 999
C
C. . . . . . . . . . . . .  ASSESS CANDIDATE STEP  . . . . . . . . . . .
C
 160  STEP1 = IV(STEP)
      LSTGST = IV(STLSTG)
      X01 = IV(X0)
      CALL DASSST(D, IV, N, V(STEP1), V(LSTGST), V, X, V(X01))
C
      K = IV(IRC)
      GO TO (170,200,200,200,170,180,190,190,190,190,190,190,250,220), K
C
C     ***  RECOMPUTE STEP WITH CHANGED RADIUS  ***
C
 170     V(RADIUS) = V(RADFAC) * V(DSTNRM)
         GO TO 100
C
C  ***  COMPUTE STEP OF LENGTH V(LMAX0) FOR SINGULAR CONVERGENCE TEST.
C
 180  V(RADIUS) = V(LMAX0)
      GO TO 140
C
C  ***  CONVERGENCE OR FALSE CONVERGENCE  ***
C
 190  IV(CNVCOD) = K - 4
      IF (V(F) .GE. V(F0)) GO TO 260
         IF (IV(XIRC) .EQ. 14) GO TO 260
              IV(XIRC) = 14
C
C. . . . . . . . . . . .  PROCESS ACCEPTABLE STEP  . . . . . . . . . . .
C
 200  IF (IV(IRC) .NE. 3) GO TO 210
         STEP1 = IV(STEP)
         TEMP1 = IV(STLSTG)
C
C     ***  SET  TEMP1 = HESSIAN * STEP  FOR USE IN GRADIENT TESTS  ***
C
         L = IV(LMAT)
         CALL DLTVMU(N, V(TEMP1), V(L), V(STEP1))
         CALL DLVMUL(N, V(TEMP1), V(L), V(TEMP1))
C
C  ***  COMPUTE GRADIENT  ***
C
 210  IV(NGCALL) = IV(NGCALL) + 1
      IV(1) = 2
      GO TO 999
C
C  ***  INITIALIZATIONS -- G0 = G - G0, ETC.  ***
C
 220  G01 = IV(G0)
      CALL DVAXPY(N, V(G01), NEGONE, V(G01), G)
      STEP1 = IV(STEP)
      TEMP1 = IV(STLSTG)
      IF (IV(IRC) .NE. 3) GO TO 240
C
C  ***  SET V(RADFAC) BY GRADIENT TESTS  ***
C
C     ***  SET  TEMP1 = DIAG(D)**-1 * (HESSIAN*STEP + (G(X0)-G(X)))  ***
C
         CALL DVAXPY(N, V(TEMP1), NEGONE, V(G01), V(TEMP1))
         CALL DVVMUP(N, V(TEMP1), V(TEMP1), D, -1)
C
C        ***  DO GRADIENT TESTS  ***
C
         IF (DNRM2(N, V(TEMP1),1) .LE. V(DGNORM) * V(TUNER4))
     1                  GO TO 230
              IF (DDOT(N, G,1,V(STEP1),1)
     1                  .GE. V(GTSTEP) * V(TUNER5))  GO TO 240
 230               V(RADFAC) = V(INCFAC)
C
C  ***  UPDATE H, LOOP  ***
C
 240  W = IV(NWTSTP)
      Z = IV(X0)
      L = IV(LMAT)
      CALL DWZBFG(V(L), N, V(STEP1), V(W), V(G01), V(Z))
C
C     ** USE THE N-VECTORS STARTING AT V(STEP1) AND V(G01) FOR SCRATCH..
      CALL DLUPDT(V(TEMP1), V(STEP1), V(L), V(G01), V(L), N, V(W), V(Z))
      IV(1) = 2
      GO TO 70
C
C. . . . . . . . . . . . . .  MISC. DETAILS  . . . . . . . . . . . . . .
C
C  ***  BAD PARAMETERS TO ASSESS  ***
C
 250  IV(1) = 64
C
C  ***  PRINT SUMMARY OF FINAL ITERATION AND OTHER REQUESTED ITEMS  ***
C
 260  IV(1) = IV(CNVCOD)
      IV(CNVCOD) = 0
 270  CALL DITSUM(D, G, IV, LIV, LV, N, V, X)
C
 999  RETURN
C
C  ***  LAST CARD OF DSUMIT FOLLOWS  ***
      END
      SUBROUTINE DVAXPY(P, W, A, X, Y)
      save
C
C  ***  SET W = A*X + Y  --  W, X, Y = P-VECTORS, A = SCALAR  ***
C
      INTEGER P
      DOUBLE PRECISION A, W(P), X(P), Y(P)
C
      INTEGER I
C
      DO 10 I = 1, P
 10      W(I) = A*X(I) + Y(I)
      RETURN
      END
      SUBROUTINE DVDFLT(ALG, LV, V)
      save
C
C  ***  SUPPLY ***SOL (VERSION 2.3) DEFAULT VALUES TO V  ***
C
C  ***  ALG = 1 MEANS REGRESSION CONSTANTS.
C  ***  ALG = 2 MEANS GENERAL UNCONSTRAINED OPTIMIZATION CONSTANTS.
C
      INTEGER ALG, LV
      DOUBLE PRECISION V(LV)
C/+
      DOUBLE PRECISION DMAX1
C/
      DOUBLE PRECISION D1MACH
C
      DOUBLE PRECISION MACHEP, MEPCRT, ONE, SQTEPS, THREE
C
C  ***  SUBSCRIPTS FOR V  ***
C
      INTEGER AFCTOL, BIAS, COSMIN, DECFAC, DELTA0, DFAC, DINIT, DLTFDC,
     1        DLTFDJ, DTINIT, D0INIT, EPSLON, ETA0, FUZZ, HUBERC,
     2        INCFAC, LMAX0, LMAXS, PHMNFC, PHMXFC, RDFCMN, RDFCMX,
     3        RFCTOL, RLIMIT, RSPTOL, SCTOL, SIGMIN, TUNER1, TUNER2,
     4        TUNER3, TUNER4, TUNER5, XCTOL, XFTOL
C
C/6
      DATA ONE/1.D+0/, THREE/3.D+0/
C/7
C     PARAMETER (ONE=1.D+0, THREE=3.D+0)
C/
C
C  ***  V SUBSCRIPT VALUES  ***
C
C/6
      DATA AFCTOL/31/, BIAS/43/, COSMIN/47/, DECFAC/22/, DELTA0/44/,
     1     DFAC/41/, DINIT/38/, DLTFDC/42/, DLTFDJ/43/, DTINIT/39/,
     2     D0INIT/40/, EPSLON/19/, ETA0/42/, FUZZ/45/, HUBERC/48/,
     3     INCFAC/23/, LMAX0/35/, LMAXS/36/, PHMNFC/20/, PHMXFC/21/,
     4     RDFCMN/24/, RDFCMX/25/, RFCTOL/32/, RLIMIT/46/, RSPTOL/49/,
     5     SCTOL/37/, SIGMIN/50/, TUNER1/26/, TUNER2/27/, TUNER3/28/,
     6     TUNER4/29/, TUNER5/30/, XCTOL/33/, XFTOL/34/
C/7
C     PARAMETER (AFCTOL=31, BIAS=43, COSMIN=47, DECFAC=22, DELTA0=44,
C    1           DFAC=41, DINIT=38, DLTFDC=42, DLTFDJ=43, DTINIT=39,
C    2           D0INIT=40, EPSLON=19, ETA0=42, FUZZ=45, HUBERC=48,
C    3           INCFAC=23, LMAX0=35, LMAXS=36, PHMNFC=20, PHMXFC=21,
C    4           RDFCMN=24, RDFCMX=25, RFCTOL=32, RLIMIT=46, RSPTOL=49,
C    5           SCTOL=37, SIGMIN=50, TUNER1=26, TUNER2=27, TUNER3=28,
C    6           TUNER4=29, TUNER5=30, XCTOL=33, XFTOL=34)
C/
C
C-------------------------------  BODY  --------------------------------
C
      MACHEP = D1MACH(4)
      V(AFCTOL) = 1.D-20
      IF (MACHEP .GT. 1.D-10) V(AFCTOL) = MACHEP**2
      V(DECFAC) = 0.5D+0
      SQTEPS = DSQRT(D1MACH(4))
      V(DFAC) = 0.6D+0
      V(DELTA0) = SQTEPS
      V(DTINIT) = 1.D-6
      MEPCRT = MACHEP ** (ONE/THREE)
      V(D0INIT) = 1.D+0
      V(EPSLON) = 0.1D+0
      V(INCFAC) = 2.D+0
      V(LMAX0) = 1.D+0
      V(LMAXS) = 1.D+0
      V(PHMNFC) = -0.1D+0
      V(PHMXFC) = 0.1D+0
      V(RDFCMN) = 0.1D+0
      V(RDFCMX) = 4.D+0
      V(RFCTOL) = DMAX1(1.D-10, MEPCRT**2)
      V(SCTOL) = V(RFCTOL)
      V(TUNER1) = 0.1D+0
      V(TUNER2) = 1.D-4
      V(TUNER3) = 0.75D+0
      V(TUNER4) = 0.5D+0
      V(TUNER5) = 0.75D+0
      V(XCTOL) = SQTEPS
      V(XFTOL) = 1.D+2 * MACHEP
C
      IF (ALG .GE. 2) GO TO 10
C
C  ***  REGRESSION  VALUES
C
      V(COSMIN) = DMAX1(1.D-6, 1.D+2 * MACHEP)
      V(DINIT) = 0.D+0
      V(DLTFDC) = MEPCRT
      V(DLTFDJ) = SQTEPS
      V(FUZZ) = 1.5D+0
      V(HUBERC) = 0.7D+0
      V(RLIMIT) = DSQRT(D1MACH(2))*16.
      V(RSPTOL) = 1.D-2
      V(SIGMIN) = 1.D-4
      GO TO 999
C
C  ***  GENERAL OPTIMIZATION VALUES
C
 10   V(BIAS) = 0.8D+0
      V(DINIT) = -1.0D+0
      V(ETA0) = 1.0D+3 * MACHEP
C
 999  RETURN
C  ***  LAST CARD OF DVDFLT FOLLOWS  ***
      END
      SUBROUTINE DVSCPY(P, Y, S)
      save
C
C  ***  SET P-VECTOR Y TO SCALAR S  ***
C
      INTEGER P
      DOUBLE PRECISION S, Y(P)
C
      INTEGER I
C
      DO 10 I = 1, P
 10      Y(I) = S
      RETURN
      END
      SUBROUTINE DVVMUP(N, X, Y, Z, K)
      save
C
C ***  SET X(I) = Y(I) * Z(I)**K, 1 .LE. I .LE. N (FOR K = 1 OR -1)  ***
C
      INTEGER N, K
      DOUBLE PRECISION X(N), Y(N), Z(N)
      INTEGER I
C
      IF (K .GE. 0) GO TO 20
      DO 10 I = 1, N
 10      X(I) = Y(I) / Z(I)
      GO TO 999
C
 20   DO 30 I = 1, N
 30      X(I) = Y(I) * Z(I)
 999  RETURN
C  ***  LAST CARD OF DVVMUP FOLLOWS  ***
      END
      SUBROUTINE DWZBFG (L, N, S, W, Y, Z)
      save
C
C  ***  COMPUTE  Y  AND  Z  FOR  DLUPDT  CORRESPONDING TO BFGS UPDATE.
C
      INTEGER N
      DOUBLE PRECISION L(1), S(N), W(N), Y(N), Z(N)
C     DIMENSION L(N*(N+1)/2)
C
C--------------------------  PARAMETER USAGE  --------------------------
C
C L (I/O) CHOLESKY FACTOR OF HESSIAN, A LOWER TRIANG. MATRIX STORED
C             COMPACTLY BY ROWS.
C N (INPUT) ORDER OF  L  AND LENGTH OF  S,  W,  Y,  Z.
C S (INPUT) THE STEP JUST TAKEN.
C W (OUTPUT) RIGHT SINGULAR VECTOR OF RANK 1 CORRECTION TO L.
C Y (INPUT) CHANGE IN GRADIENTS CORRESPONDING TO S.
C Z (OUTPUT) LEFT SINGULAR VECTOR OF RANK 1 CORRECTION TO L.
C
C-------------------------------  NOTES  -------------------------------
C
C  ***  ALGORITHM NOTES  ***
C
C        WHEN  S  IS COMPUTED IN CERTAIN WAYS, E.G. BY  GQTSTP  OR
C     DBLDOG,  IT IS POSSIBLE TO SAVE N**2/2 OPERATIONS SINCE  (L**T)*S
C     OR  L*(L**T)*S IS THEN KNOWN.
C        IF THE BFGS UPDATE TO L*(L**T) WOULD REDUCE ITS DETERMINANT TO
C     LESS THAN EPS TIMES ITS OLD VALUE, THEN THIS ROUTINE IN EFFECT
C     REPLACES  Y  BY  THETA*Y + (1 - THETA)*L*(L**T)*S,  WHERE  THETA
C     (BETWEEN 0 AND 1) IS CHOSEN TO MAKE THE REDUCTION FACTOR = EPS.
C
C  ***  GENERAL  ***
C
C     CODED BY DAVID M. GAY (FALL 1979).
C     THIS SUBROUTINE WAS WRITTEN IN CONNECTION WITH RESEARCH SUPPORTED
C     BY THE NATIONAL SCIENCE FOUNDATION UNDER GRANTS MCS-7600324 AND
C     MCS-7906671.
C
C------------------------  EXTERNAL QUANTITIES  ------------------------
C
C  ***  FUNCTIONS AND SUBROUTINES CALLED  ***
C
      EXTERNAL DLIVMU, DLTVMU
      DOUBLE PRECISION DDOT
C DLIVMU MULTIPLIES L**-1 TIMES A VECTOR.
C DLTVMU MULTIPLIES L**T TIMES A VECTOR.
C
C  ***  INTRINSIC FUNCTIONS  ***
C/+
      DOUBLE PRECISION DSQRT
C/
C--------------------------  LOCAL VARIABLES  --------------------------
C
      INTEGER I
      DOUBLE PRECISION CS, CY, EPS, EPSRT, ONE, SHS, YS, THETA
C
C  ***  DATA INITIALIZATIONS  ***
C
C/6
      DATA EPS/0.1D+0/, ONE/1.D+0/
C/7
C     PARAMETER (EPS=0.1D+0, ONE=1.D+0)
C/
C
C+++++++++++++++++++++++++++++++  BODY  ++++++++++++++++++++++++++++++++
C
      CALL DLTVMU(N, W, L, S)
      SHS = DDOT(N, W,1,W,1)
      YS = DDOT(N, Y,1,S,1)
      IF (YS .GE. EPS*SHS) GO TO 10
         THETA = (ONE - EPS) * SHS / (SHS - YS)
         EPSRT = DSQRT(EPS)
         CY = THETA / (SHS * EPSRT)
         CS = (ONE + (THETA-ONE)/EPSRT) / SHS
         GO TO 20
 10   CY = ONE / (DSQRT(YS) * DSQRT(SHS))
      CS = ONE / SHS
 20   CALL DLIVMU(N, Z, L, Y)
      DO 30 I = 1, N
 30      Z(I) = CY * Z(I)  -  CS * W(I)
C
 999  RETURN
C  ***  LAST CARD OF DWZBFG FOLLOWS  ***
      END
      INTEGER FUNCTION I1MACH(I)
      save
C***BEGIN PROLOGUE  I1MACH
C***DATE WRITTEN   750101   (YYMMDD)
C***REVISION DATE  910131   (YYMMDD)
C***CATEGORY NO.  R1
C***KEYWORDS  MACHINE CONSTANTS
C***AUTHOR  FOX, P. A., (BELL LABS)
C           HALL, A. D., (BELL LABS)
C           SCHRYER, N. L., (BELL LABS)
C***PURPOSE  Returns integer machine dependent constants
C***DESCRIPTION
C
C     This is the CMLIB version of I1MACH, the integer machine
C     constants subroutine originally developed for the PORT library.
C
C     I1MACH can be used to obtain machine-dependent parameters
C     for the local machine environment.  It is a function
C     subroutine with one (input) argument, and can be called
C     as follows, for example
C
C          K = I1MACH(I)
C
C     where I=1,...,16.  The (output) value of K above is
C     determined by the (input) value of I.  The results for
C     various values of I are discussed below.
C
C  I/O unit numbers.
C    I1MACH( 1) = the standard input unit.
C    I1MACH( 2) = the standard output unit.
C    I1MACH( 3) = the standard punch unit.
C    I1MACH( 4) = the standard error message unit.
C
C  Words.
C    I1MACH( 5) = the number of bits per integer storage unit.
C    I1MACH( 6) = the number of characters per integer storage unit.
C
C  Integers.
C    assume integers are represented in the S-digit, base-A form
C
C               sign ( X(S-1)*A**(S-1) + ... + X(1)*A + X(0) )
C
C               where 0 .LE. X(I) .LT. A for I=0,...,S-1.
C    I1MACH( 7) = A, the base.
C    I1MACH( 8) = S, the number of base-A digits.
C    I1MACH( 9) = A**S - 1, the largest magnitude.
C
C  Floating-Point Numbers.
C    Assume floating-point numbers are represented in the T-digit,
C    base-B form
C               sign (B**E)*( (X(1)/B) + ... + (X(T)/B**T) )
C
C               where 0 .LE. X(I) .LT. B for I=1,...,T,
C               0 .LT. X(1), and EMIN .LE. E .LE. EMAX.
C    I1MACH(10) = B, the base.
C
C  Single-Precision
C    I1MACH(11) = T, the number of base-B digits.
C    I1MACH(12) = EMIN, the smallest exponent E.
C    I1MACH(13) = EMAX, the largest exponent E.
C
C  Double-Precision
C    I1MACH(14) = T, the number of base-B digits.
C    I1MACH(15) = EMIN, the smallest exponent E.
C    I1MACH(16) = EMAX, the largest exponent E.
C
C  To alter this function for a particular environment,
C  the desired set of DATA statements should be activated by
C  removing the C from column 1.  Also, the values of
C  I1MACH(1) - I1MACH(4) should be checked for consistency
C  with the local operating system.
C***REFERENCES  FOX P.A., HALL A.D., SCHRYER N.L.,*FRAMEWORK FOR A
C                 PORTABLE LIBRARY*, ACM TRANSACTIONS ON MATHEMATICAL
C                 SOFTWARE, VOL. 4, NO. 2, JUNE 1978, PP. 177-188.
C***ROUTINES CALLED  (NONE)
C***END PROLOGUE  I1MACH
C
      INTEGER IMACH(16),OUTPUT
      EQUIVALENCE (IMACH(4),OUTPUT)
C
C     MACHINE CONSTANTS FOR IEEE ARITHMETIC MACHINES, SUCH AS THE AT&T
C     3B SERIES, MOTOROLA 68000 BASED MACHINES (E.G. SUN 3 AND AT&T
C     PC 7300), AND 8087 BASED MICROS (E.G. IBM PC AND AT&T 6300).
C
C === MACHINE = IEEE.MOST-SIG-BYTE-FIRST
C === MACHINE = IEEE.LEAST-SIG-BYTE-FIRST
C === MACHINE = SUN
C === MACHINE = 68000
C === MACHINE = 8087
C === MACHINE = IBM.PC
C === MACHINE = ATT.3B
C === MACHINE = ATT.7300
C === MACHINE = ATT.6300
       DATA IMACH( 1) /    5 /
       DATA IMACH( 2) /    6 /
       DATA IMACH( 3) /    7 /
       DATA IMACH( 4) /    6 /
       DATA IMACH( 5) /   32 /
       DATA IMACH( 6) /    4 /
       DATA IMACH( 7) /    2 /
       DATA IMACH( 8) /   31 /
       DATA IMACH( 9) / 2147483647 /
       DATA IMACH(10) /    2 /
       DATA IMACH(11) /   24 /
       DATA IMACH(12) / -125 /
       DATA IMACH(13) /  128 /
       DATA IMACH(14) /   53 /
       DATA IMACH(15) / -1021 /
       DATA IMACH(16) /  1024 /
C
C     MACHINE CONSTANTS FOR AMDAHL MACHINES.
C
C === MACHINE = AMDAHL
C      DATA IMACH( 1) /   5 /
C      DATA IMACH( 2) /   6 /
C      DATA IMACH( 3) /   7 /
C      DATA IMACH( 4) /   6 /
C      DATA IMACH( 5) /  32 /
C      DATA IMACH( 6) /   4 /
C      DATA IMACH( 7) /   2 /
C      DATA IMACH( 8) /  31 /
C      DATA IMACH( 9) / 2147483647 /
C      DATA IMACH(10) /  16 /
C      DATA IMACH(11) /   6 /
C      DATA IMACH(12) / -64 /
C      DATA IMACH(13) /  63 /
C      DATA IMACH(14) /  14 /
C      DATA IMACH(15) / -64 /
C      DATA IMACH(16) /  63 /
C
C     MACHINE CONSTANTS FOR THE BURROUGHS 1700 SYSTEM.
C
C === MACHINE = BURROUGHS.1700
C      DATA IMACH( 1) /    7 /
C      DATA IMACH( 2) /    2 /
C      DATA IMACH( 3) /    2 /
C      DATA IMACH( 4) /    2 /
C      DATA IMACH( 5) /   36 /
C      DATA IMACH( 6) /    4 /
C      DATA IMACH( 7) /    2 /
C      DATA IMACH( 8) /   33 /
C      DATA IMACH( 9) / Z1FFFFFFFF /
C      DATA IMACH(10) /    2 /
C      DATA IMACH(11) /   24 /
C      DATA IMACH(12) / -256 /
C      DATA IMACH(13) /  255 /
C      DATA IMACH(14) /   60 /
C      DATA IMACH(15) / -256 /
C      DATA IMACH(16) /  255 /
C
C     MACHINE CONSTANTS FOR THE BURROUGHS 5700 SYSTEM.
C
C === MACHINE = BURROUGHS.5700
C      DATA IMACH( 1) /   5 /
C      DATA IMACH( 2) /   6 /
C      DATA IMACH( 3) /   7 /
C      DATA IMACH( 4) /   6 /
C      DATA IMACH( 5) /  48 /
C      DATA IMACH( 6) /   6 /
C      DATA IMACH( 7) /   2 /
C      DATA IMACH( 8) /  39 /
C      DATA IMACH( 9) / O0007777777777777 /
C      DATA IMACH(10) /   8 /
C      DATA IMACH(11) /  13 /
C      DATA IMACH(12) / -50 /
C      DATA IMACH(13) /  76 /
C      DATA IMACH(14) /  26 /
C      DATA IMACH(15) / -50 /
C      DATA IMACH(16) /  76 /
C
C     MACHINE CONSTANTS FOR THE BURROUGHS 6700/7700 SYSTEMS.
C
C === MACHINE = BURROUGHS.6700
C === MACHINE = BURROUGHS.7700
C      DATA IMACH( 1) /   5 /
C      DATA IMACH( 2) /   6 /
C      DATA IMACH( 3) /   7 /
C      DATA IMACH( 4) /   6 /
C      DATA IMACH( 5) /  48 /
C      DATA IMACH( 6) /   6 /
C      DATA IMACH( 7) /   2 /
C      DATA IMACH( 8) /  39 /
C      DATA IMACH( 9) / O0007777777777777 /
C      DATA IMACH(10) /   8 /
C      DATA IMACH(11) /  13 /
C      DATA IMACH(12) / -50 /
C      DATA IMACH(13) /  76 /
C      DATA IMACH(14) /  26 /
C      DATA IMACH(15) / -32754 /
C      DATA IMACH(16) /  32780 /
C
C     MACHINE CONSTANTS FOR THE CONVEX C-120 (NATIVE MODE)
C
C === MACHINE = CONVEX.C1
C      DATA IMACH( 1) /    5 /
C      DATA IMACH( 2) /    6 /
C      DATA IMACH( 3) /    0 /
C      DATA IMACH( 4) /    6 /
C      DATA IMACH( 5) /   32 /
C      DATA IMACH( 6) /    4 /
C      DATA IMACH( 7) /    2 /
C      DATA IMACH( 8) /   31 /
C      DATA IMACH( 9) / 2147483647 /
C      DATA IMACH(10) /    2 /
C      DATA IMACH(11) /   24 /
C      DATA IMACH(12) / -127 /
C      DATA IMACH(13) /  127 /
C      DATA IMACH(14) /   53 /
C      DATA IMACH(15) / -1023 /
C      DATA IMACH(16) /  1023 /
C
C     MACHINE CONSTANTS FOR THE CONVEX (NATIVE MODE)
C     WITH -R8 OPTION
C
C === MACHINE = CONVEX.C1.R8
C      DATA IMACH( 1) /     5 /
C      DATA IMACH( 2) /     6 /
C      DATA IMACH( 3) /     0 /
C      DATA IMACH( 4) /     6 /
C      DATA IMACH( 5) /    32 /
C      DATA IMACH( 6) /     4 /
C      DATA IMACH( 7) /     2 /
C      DATA IMACH( 8) /    31 /
C      DATA IMACH( 9) / 2147483647 /
C      DATA IMACH(10) /     2 /
C      DATA IMACH(11) /    53 /
C      DATA IMACH(12) / -1023 /
C      DATA IMACH(13) /  1023 /
C      DATA IMACH(14) /    53 /
C      DATA IMACH(15) / -1023 /
C      DATA IMACH(16) /  1023 /
C
C     MACHINE CONSTANTS FOR THE CONVEX C-120 (IEEE MODE)
C
C === MACHINE = CONVEX.C1.IEEE
C      DATA IMACH( 1) /    5 /
C      DATA IMACH( 2) /    6 /
C      DATA IMACH( 3) /    0 /
C      DATA IMACH( 4) /    6 /
C      DATA IMACH( 5) /   32 /
C      DATA IMACH( 6) /    4 /
C      DATA IMACH( 7) /    2 /
C      DATA IMACH( 8) /   31 /
C      DATA IMACH( 9) / 2147483647 /
C      DATA IMACH(10) /    2 /
C      DATA IMACH(11) /   24 /
C      DATA IMACH(12) / -125 /
C      DATA IMACH(13) /  128 /
C      DATA IMACH(14) /   53 /
C      DATA IMACH(15) / -1021 /
C      DATA IMACH(16) /  1024 /
C
C     MACHINE CONSTANTS FOR THE CONVEX (IEEE MODE)
C     WITH -R8 OPTION
C
C === MACHINE = CONVEX.C1.IEEE.R8
C      DATA IMACH( 1) /     5 /
C      DATA IMACH( 2) /     6 /
C      DATA IMACH( 3) /     0 /
C      DATA IMACH( 4) /     6 /
C      DATA IMACH( 5) /    32 /
C      DATA IMACH( 6) /     4 /
C      DATA IMACH( 7) /     2 /
C      DATA IMACH( 8) /    31 /
C      DATA IMACH( 9) / 2147483647 /
C      DATA IMACH(10) /     2 /
C      DATA IMACH(11) /    53 /
C      DATA IMACH(12) / -1021 /
C      DATA IMACH(13) /  1024 /
C      DATA IMACH(14) /    53 /
C      DATA IMACH(15) / -1021 /
C      DATA IMACH(16) /  1024 /
C
C     MACHINE CONSTANTS FOR THE CYBER 170/180 SERIES USING NOS (FTN5).
C
C === MACHINE = CYBER.170.NOS
C === MACHINE = CYBER.180.NOS
C      DATA IMACH( 1) /    5 /
C      DATA IMACH( 2) /    6 /
C      DATA IMACH( 3) /    7 /
C      DATA IMACH( 4) /    6 /
C      DATA IMACH( 5) /   60 /
C      DATA IMACH( 6) /   10 /
C      DATA IMACH( 7) /    2 /
C      DATA IMACH( 8) /   48 /
C      DATA IMACH( 9) / O"00007777777777777777" /
C      DATA IMACH(10) /    2 /
C      DATA IMACH(11) /   48 /
C      DATA IMACH(12) / -974 /
C      DATA IMACH(13) / 1070 /
C      DATA IMACH(14) /   96 /
C      DATA IMACH(15) / -927 /
C      DATA IMACH(16) / 1070 /
C
C     MACHINE CONSTANTS FOR THE CDC 180 SERIES USING NOS/VE
C
C === MACHINE = CYBER.180.NOS/VE
C      DATA IMACH( 1) /     5 /
C      DATA IMACH( 2) /     6 /
C      DATA IMACH( 3) /     7 /
C      DATA IMACH( 4) /     6 /
C      DATA IMACH( 5) /    64 /
C      DATA IMACH( 6) /     8 /
C      DATA IMACH( 7) /     2 /
C      DATA IMACH( 8) /    63 /
C      DATA IMACH( 9) / 9223372036854775807 /
C      DATA IMACH(10) /     2 /
C      DATA IMACH(11) /    47 /
C      DATA IMACH(12) / -4095 /
C      DATA IMACH(13) /  4094 /
C      DATA IMACH(14) /    94 /
C      DATA IMACH(15) / -4095 /
C      DATA IMACH(16) /  4094 /
C
C     MACHINE CONSTANTS FOR THE CYBER 205
C
C === MACHINE = CYBER.205
C      DATA IMACH( 1) /      5 /
C      DATA IMACH( 2) /      6 /
C      DATA IMACH( 3) /      7 /
C      DATA IMACH( 4) /      6 /
C      DATA IMACH( 5) /     64 /
C      DATA IMACH( 6) /      8 /
C      DATA IMACH( 7) /      2 /
C      DATA IMACH( 8) /     47 /
C      DATA IMACH( 9) / X'00007FFFFFFFFFFF' /
C      DATA IMACH(10) /      2 /
C      DATA IMACH(11) /     47 /
C      DATA IMACH(12) / -28625 /
C      DATA IMACH(13) /  28718 /
C      DATA IMACH(14) /     94 /
C      DATA IMACH(15) / -28625 /
C      DATA IMACH(16) /  28718 /
C
C     MACHINE CONSTANTS FOR THE CDC 6000/7000 SERIES.
C
C === MACHINE = CDC.6000
C === MACHINE = CDC.7000
C      DATA IMACH( 1) /    5 /
C      DATA IMACH( 2) /    6 /
C      DATA IMACH( 3) /    7 /
C      DATA IMACH( 4) /    6 /
C      DATA IMACH( 5) /   60 /
C      DATA IMACH( 6) /   10 /
C      DATA IMACH( 7) /    2 /
C      DATA IMACH( 8) /   48 /
C      DATA IMACH( 9) / 00007777777777777777B /
C      DATA IMACH(10) /    2 /
C      DATA IMACH(11) /   48 /
C      DATA IMACH(12) / -974 /
C      DATA IMACH(13) / 1070 /
C      DATA IMACH(14) /   96 /
C      DATA IMACH(15) / -927 /
C      DATA IMACH(16) / 1070 /
C
C     MACHINE CONSTANTS FOR THE CRAY 1, XMP, 2, AND 3.
C     USING THE 46 BIT INTEGER COMPILER OPTION
C
C === MACHINE = CRAY.46-BIT-INTEGER
C      DATA IMACH( 1) /     5 /
C      DATA IMACH( 2) /     6 /
C      DATA IMACH( 3) /   102 /
C      DATA IMACH( 4) /     6 /
C      DATA IMACH( 5) /    64 /
C      DATA IMACH( 6) /     8 /
C      DATA IMACH( 7) /     2 /
C      DATA IMACH( 8) /    46 /
C      DATA IMACH( 9) /  777777777777777777777B /
C      DATA IMACH(10) /     2 /
C      DATA IMACH(11) /    47 /
C      DATA IMACH(12) / -8189 /
C      DATA IMACH(13) /  8190 /
C      DATA IMACH(14) /    94 /
C      DATA IMACH(15) / -8099 /
C      DATA IMACH(16) /  8190 /
C
C     MACHINE CONSTANTS FOR THE CRAY 1, XMP, 2, AND 3.
C     USING THE 64 BIT INTEGER COMPILER OPTION
C
C === MACHINE = CRAY.64-BIT-INTEGER
C      DATA IMACH( 1) /     5 /
C      DATA IMACH( 2) /     6 /
C      DATA IMACH( 3) /   102 /
C      DATA IMACH( 4) /     6 /
C      DATA IMACH( 5) /    64 /
C      DATA IMACH( 6) /     8 /
C      DATA IMACH( 7) /     2 /
C      DATA IMACH( 8) /    63 /
C      DATA IMACH( 9) /  777777777777777777777B /
C      DATA IMACH(10) /     2 /
C      DATA IMACH(11) /    47 /
C      DATA IMACH(12) / -8189 /
C      DATA IMACH(13) /  8190 /
C      DATA IMACH(14) /    94 /
C      DATA IMACH(15) / -8099 /
C      DATA IMACH(16) /  8190 /C
C     MACHINE CONSTANTS FOR THE DATA GENERAL ECLIPSE S/200
C
C === MACHINE = DATA_GENERAL.ECLIPSE.S/200
C      DATA IMACH( 1) /   11 /
C      DATA IMACH( 2) /   12 /
C      DATA IMACH( 3) /    8 /
C      DATA IMACH( 4) /   10 /
C      DATA IMACH( 5) /   16 /
C      DATA IMACH( 6) /    2 /
C      DATA IMACH( 7) /    2 /
C      DATA IMACH( 8) /   15 /
C      DATA IMACH( 9) /32767 /
C      DATA IMACH(10) /   16 /
C      DATA IMACH(11) /    6 /
C      DATA IMACH(12) /  -64 /
C      DATA IMACH(13) /   63 /
C      DATA IMACH(14) /   14 /
C      DATA IMACH(15) /  -64 /
C      DATA IMACH(16) /   63 /
C
C     ELXSI  6400
C
C === MACHINE = ELSXI.6400
C      DATA IMACH( 1) /     5 /
C      DATA IMACH( 2) /     6 /
C      DATA IMACH( 3) /     6 /
C      DATA IMACH( 4) /     6 /
C      DATA IMACH( 5) /    32 /
C      DATA IMACH( 6) /     4 /
C      DATA IMACH( 7) /     2 /
C      DATA IMACH( 8) /    32 /
C      DATA IMACH( 9) / 2147483647 /
C      DATA IMACH(10) /     2 /
C      DATA IMACH(11) /    24 /
C      DATA IMACH(12) /  -126 /
C      DATA IMACH(13) /   127 /
C      DATA IMACH(14) /    53 /
C      DATA IMACH(15) / -1022 /
C      DATA IMACH(16) /  1023 /
C
C     MACHINE CONSTANTS FOR THE HARRIS 220
C     MACHINE CONSTANTS FOR THE HARRIS SLASH 6 AND SLASH 7
C
C === MACHINE = HARRIS.220
C === MACHINE = HARRIS.SLASH6
C === MACHINE = HARRIS.SLASH7
C      DATA IMACH( 1) /       5 /
C      DATA IMACH( 2) /       6 /
C      DATA IMACH( 3) /       0 /
C      DATA IMACH( 4) /       6 /
C      DATA IMACH( 5) /      24 /
C      DATA IMACH( 6) /       3 /
C      DATA IMACH( 7) /       2 /
C      DATA IMACH( 8) /      23 /
C      DATA IMACH( 9) / 8388607 /
C      DATA IMACH(10) /       2 /
C      DATA IMACH(11) /      23 /
C      DATA IMACH(12) /    -127 /
C      DATA IMACH(13) /     127 /
C      DATA IMACH(14) /      38 /
C      DATA IMACH(15) /    -127 /
C      DATA IMACH(16) /     127 /
C
C     MACHINE CONSTANTS FOR THE HONEYWELL 600/6000 SERIES.
C     MACHINE CONSTANTS FOR THE HONEYWELL DPS 8/70 SERIES.
C
C === MACHINE = HONEYWELL.600/6000
C === MACHINE = HONEYWELL.DPS.8/70
C      DATA IMACH( 1) /    5 /
C      DATA IMACH( 2) /    6 /
C      DATA IMACH( 3) /   43 /
C      DATA IMACH( 4) /    6 /
C      DATA IMACH( 5) /   36 /
C      DATA IMACH( 6) /    4 /
C      DATA IMACH( 7) /    2 /
C      DATA IMACH( 8) /   35 /
C      DATA IMACH( 9) / O377777777777 /
C      DATA IMACH(10) /    2 /
C      DATA IMACH(11) /   27 /
C      DATA IMACH(12) / -127 /
C      DATA IMACH(13) /  127 /
C      DATA IMACH(14) /   63 /
C      DATA IMACH(15) / -127 /
C      DATA IMACH(16) /  127 /
C
C     MACHINE CONSTANTS FOR THE HP 2100
C     3 WORD DOUBLE PRECISION OPTION WITH FTN4
C
C === MACHINE = HP.2100.3_WORD_DP
C      DATA IMACH(1) /      5/
C      DATA IMACH(2) /      6 /
C      DATA IMACH(3) /      4 /
C      DATA IMACH(4) /      1 /
C      DATA IMACH(5) /     16 /
C      DATA IMACH(6) /      2 /
C      DATA IMACH(7) /      2 /
C      DATA IMACH(8) /     15 /
C      DATA IMACH(9) /  32767 /
C      DATA IMACH(10)/      2 /
C      DATA IMACH(11)/     23 /
C      DATA IMACH(12)/   -128 /
C      DATA IMACH(13)/    127 /
C      DATA IMACH(14)/     39 /
C      DATA IMACH(15)/   -128 /
C      DATA IMACH(16)/    127 /
C
C     MACHINE CONSTANTS FOR THE HP 2100
C     4 WORD DOUBLE PRECISION OPTION WITH FTN4
C
C === MACHINE = HP.2100.4_WORD_DP
C      DATA IMACH(1) /      5 /
C      DATA IMACH(2) /      6 /
C      DATA IMACH(3) /      4 /
C      DATA IMACH(4) /      1 /
C      DATA IMACH(5) /     16 /
C      DATA IMACH(6) /      2 /
C      DATA IMACH(7) /      2 /
C      DATA IMACH(8) /     15 /
C      DATA IMACH(9) /  32767 /
C      DATA IMACH(10)/      2 /
C      DATA IMACH(11)/     23 /
C      DATA IMACH(12)/   -128 /
C      DATA IMACH(13)/    127 /
C      DATA IMACH(14)/     55 /
C      DATA IMACH(15)/   -128 /
C      DATA IMACH(16)/    127 /
C
C     HP 9000
C
C === MACHINE = HP.9000
C      DATA IMACH( 1) /     5 /
C      DATA IMACH( 2) /     6 /
C      DATA IMACH( 3) /     6 /
C      DATA IMACH( 4) /     7 /
C      DATA IMACH( 5) /    32 /
C      DATA IMACH( 6) /     4 /
C      DATA IMACH( 7) /     2 /
C      DATA IMACH( 8) /    32 /
C      DATA IMACH( 9) / 2147483647 /
C      DATA IMACH(10) /     2 /
C      DATA IMACH(11) /    24 /
C      DATA IMACH(12) /  -126 /
C      DATA IMACH(13) /   127 /
C      DATA IMACH(14) /    53 /
C      DATA IMACH(15) / -1015 /
C      DATA IMACH(16) /  1017 /
C
C     MACHINE CONSTANTS FOR THE IBM 360/370 SERIES,
C     THE XEROX SIGMA 5/7/9 AND THE SEL SYSTEMS 85/86 AND
C     THE INTERDATA 3230 AND INTERDATA 7/32.
C
C === MACHINE = IBM.360
C === MACHINE = IBM.370
C === MACHINE = XEROX.SIGMA.5
C === MACHINE = XEROX.SIGMA.7
C === MACHINE = XEROX.SIGMA.9
C === MACHINE = SEL.85
C === MACHINE = SEL.86
C === MACHINE = INTERDATA.3230
C === MACHINE = INTERDATA.7/32
C      DATA IMACH( 1) /   5 /
C      DATA IMACH( 2) /   6 /
C      DATA IMACH( 3) /   7 /
C      DATA IMACH( 4) /   6 /
C      DATA IMACH( 5) /  32 /
C      DATA IMACH( 6) /   4 /
C      DATA IMACH( 7) /   2 /
C      DATA IMACH( 8) /  31 /
C      DATA IMACH( 9) / Z7FFFFFFF /
C      DATA IMACH(10) /  16 /
C      DATA IMACH(11) /   6 /
C      DATA IMACH(12) / -64 /
C      DATA IMACH(13) /  63 /
C      DATA IMACH(14) /  14 /
C      DATA IMACH(15) / -64 /
C      DATA IMACH(16) /  63 /
C
C     MACHINE CONSTANTS FOR THE INTERDATA 8/32
C     WITH THE UNIX SYSTEM FORTRAN 77 COMPILER.
C
C     FOR THE INTERDATA FORTRAN VII COMPILER REPLACE
C     THE Z'S SPECIFYING HEX CONSTANTS WITH Y'S.
C
C === MACHINE = INTERDATA.8/32.UNIX
C      DATA IMACH( 1) /   5 /
C      DATA IMACH( 2) /   6 /
C      DATA IMACH( 3) /   6 /
C      DATA IMACH( 4) /   6 /
C      DATA IMACH( 5) /  32 /
C      DATA IMACH( 6) /   4 /
C      DATA IMACH( 7) /   2 /
C      DATA IMACH( 8) /  31 /
C      DATA IMACH( 9) / Z'7FFFFFFF' /
C      DATA IMACH(10) /  16 /
C      DATA IMACH(11) /   6 /
C      DATA IMACH(12) / -64 /
C      DATA IMACH(13) /  62 /
C      DATA IMACH(14) /  14 /
C      DATA IMACH(15) / -64 /
C      DATA IMACH(16) /  62 /
C
C     MACHINE CONSTANTS FOR THE PDP-10 (KA PROCESSOR).
C
C === MACHINE = PDP-10.KA
C      DATA IMACH( 1) /    5 /
C      DATA IMACH( 2) /    6 /
C      DATA IMACH( 3) /    7 /
C      DATA IMACH( 4) /    6 /
C      DATA IMACH( 5) /   36 /
C      DATA IMACH( 6) /    5 /
C      DATA IMACH( 7) /    2 /
C      DATA IMACH( 8) /   35 /
C      DATA IMACH( 9) / "377777777777 /
C      DATA IMACH(10) /    2 /
C      DATA IMACH(11) /   27 /
C      DATA IMACH(12) / -128 /
C      DATA IMACH(13) /  127 /
C      DATA IMACH(14) /   54 /
C      DATA IMACH(15) / -101 /
C      DATA IMACH(16) /  127 /
C
C     MACHINE CONSTANTS FOR THE PDP-10 (KI PROCESSOR).
C
C === MACHINE = PDP-10.KI
C      DATA IMACH( 1) /    5 /
C      DATA IMACH( 2) /    6 /
C      DATA IMACH( 3) /    7 /
C      DATA IMACH( 4) /    6 /
C      DATA IMACH( 5) /   36 /
C      DATA IMACH( 6) /    5 /
C      DATA IMACH( 7) /    2 /
C      DATA IMACH( 8) /   35 /
C      DATA IMACH( 9) / "377777777777 /
C      DATA IMACH(10) /    2 /
C      DATA IMACH(11) /   27 /
C      DATA IMACH(12) / -128 /
C      DATA IMACH(13) /  127 /
C      DATA IMACH(14) /   62 /
C      DATA IMACH(15) / -128 /
C      DATA IMACH(16) /  127 /
C
C     MACHINE CONSTANTS FOR PDP-11 FORTRANS SUPPORTING
C     32-BIT INTEGER ARITHMETIC.
C
C === MACHINE = PDP-11.32-BIT
C      DATA IMACH( 1) /    5 /
C      DATA IMACH( 2) /    6 /
C      DATA IMACH( 3) /    7 /
C      DATA IMACH( 4) /    6 /
C      DATA IMACH( 5) /   32 /
C      DATA IMACH( 6) /    4 /
C      DATA IMACH( 7) /    2 /
C      DATA IMACH( 8) /   31 /
C      DATA IMACH( 9) / 2147483647 /
C      DATA IMACH(10) /    2 /
C      DATA IMACH(11) /   24 /
C      DATA IMACH(12) / -127 /
C      DATA IMACH(13) /  127 /
C      DATA IMACH(14) /   56 /
C      DATA IMACH(15) / -127 /
C      DATA IMACH(16) /  127 /
C
C     MACHINE CONSTANTS FOR PDP-11 FORTRANS SUPPORTING
C     16-BIT INTEGER ARITHMETIC.
C
C === MACHINE = PDP-11.16-BIT
C      DATA IMACH( 1) /    5 /
C      DATA IMACH( 2) /    6 /
C      DATA IMACH( 3) /    7 /
C      DATA IMACH( 4) /    6 /
C      DATA IMACH( 5) /   16 /
C      DATA IMACH( 6) /    2 /
C      DATA IMACH( 7) /    2 /
C      DATA IMACH( 8) /   15 /
C      DATA IMACH( 9) / 32767 /
C      DATA IMACH(10) /    2 /
C      DATA IMACH(11) /   24 /
C      DATA IMACH(12) / -127 /
C      DATA IMACH(13) /  127 /
C      DATA IMACH(14) /   56 /
C      DATA IMACH(15) / -127 /
C      DATA IMACH(16) /  127 /
C
C     MACHINE CONSTANTS FOR THE SEQUENT BALANCE 8000.
C
C === MACHINE = SEQUENT.BALANCE.8000
C      DATA IMACH( 1) /     0 /
C      DATA IMACH( 2) /     0 /
C      DATA IMACH( 3) /     7 /
C      DATA IMACH( 4) /     0 /
C      DATA IMACH( 5) /    32 /
C      DATA IMACH( 6) /     1 /
C      DATA IMACH( 7) /     2 /
C      DATA IMACH( 8) /    31 /
C      DATA IMACH( 9) /  2147483647 /
C      DATA IMACH(10) /     2 /
C      DATA IMACH(11) /    24 /
C      DATA IMACH(12) /  -125 /
C      DATA IMACH(13) /   128 /
C      DATA IMACH(14) /    53 /
C      DATA IMACH(15) / -1021 /
C      DATA IMACH(16) /  1024 /
C
C     MACHINE CONSTANTS FOR THE UNIVAC 1100 SERIES. FTN COMPILER
C
C === MACHINE = UNIVAC.1100
C      DATA IMACH( 1) /    5 /
C      DATA IMACH( 2) /    6 /
C      DATA IMACH( 3) /    1 /
C      DATA IMACH( 4) /    6 /
C      DATA IMACH( 5) /   36 /
C      DATA IMACH( 6) /    4 /
C      DATA IMACH( 7) /    2 /
C      DATA IMACH( 8) /   35 /
C      DATA IMACH( 9) / O377777777777 /
C      DATA IMACH(10) /    2 /
C      DATA IMACH(11) /   27 /
C      DATA IMACH(12) / -128 /
C      DATA IMACH(13) /  127 /
C      DATA IMACH(14) /   60 /
C      DATA IMACH(15) /-1024 /
C      DATA IMACH(16) / 1023 /
C
C     MACHINE CONSTANTS FOR THE VAX 11/780
C
C === MACHINE = VAX.11/780
C      DATA IMACH(1) /    5 /
C      DATA IMACH(2) /    6 /
C      DATA IMACH(3) /    5 /
C      DATA IMACH(4) /    6 /
C      DATA IMACH(5) /   32 /
C      DATA IMACH(6) /    4 /
C      DATA IMACH(7) /    2 /
C      DATA IMACH(8) /   31 /
C      DATA IMACH(9) /2147483647 /
C      DATA IMACH(10)/    2 /
C      DATA IMACH(11)/   24 /
C      DATA IMACH(12)/ -127 /
C      DATA IMACH(13)/  127 /
C      DATA IMACH(14)/   56 /
C      DATA IMACH(15)/ -127 /
C      DATA IMACH(16)/  127 /
C
C
C***FIRST EXECUTABLE STATEMENT  I1MACH
      IF (I .LT. 1  .OR.  I .GT. 16)
     1   CALL XERROR ( 'I1MACH -- I OUT OF BOUNDS',25,1,2)
C
      I1MACH=IMACH(I)
      RETURN
C
      END
      SUBROUTINE XERROR(MESSG,NMESSG,NERR,LEVEL)
      save
C***BEGIN PROLOGUE  XERROR
C***DATE WRITTEN   790801   (YYMMDD)
C***REVISION DATE  820801   (YYMMDD)
C***CATEGORY NO.  R3C
C***KEYWORDS  ERROR,XERROR PACKAGE
C***AUTHOR  JONES, R. E., (SNLA)
C***PURPOSE  Processes an error (diagnostic) message.
C***DESCRIPTION
C     Abstract
C        XERROR processes a diagnostic message, in a manner
C        determined by the value of LEVEL and the current value
C        of the library error control flag, KONTRL.
C        (See subroutine XSETF for details.)
C
C     Description of Parameters
C      --Input--
C        MESSG - the Hollerith message to be processed, containing
C                no more than 72 characters.
C        NMESSG- the actual number of characters in MESSG.
C        NERR  - the error number associated with this message.
C                NERR must not be zero.
C        LEVEL - error category.
C                =2 means this is an unconditionally fatal error.
C                =1 means this is a recoverable error.  (I.e., it is
C                   non-fatal if XSETF has been appropriately called.)
C                =0 means this is a warning message only.
C                =-1 means this is a warning message which is to be
C                   printed at most once, regardless of how many
C                   times this call is executed.
C
C     Examples
C        CALL XERROR('SMOOTH -- NUM WAS ZERO.',23,1,2)
C        CALL XERROR('INTEG  -- LESS THAN FULL ACCURACY ACHIEVED.',
C                    43,2,1)
C        CALL XERROR('ROOTER -- ACTUAL ZERO OF F FOUND BEFORE INTERVAL F
C    1ULLY COLLAPSED.',65,3,0)
C        CALL XERROR('EXP    -- UNDERFLOWS BEING SET TO ZERO.',39,1,-1)
C
C     Latest revision ---  19 MAR 1980
C     Written by Ron Jones, with SLATEC Common Math Library Subcommittee
C***REFERENCES  JONES R.E., KAHANER D.K., "XERROR, THE SLATEC ERROR-
C                 HANDLING PACKAGE", SAND82-0800, SANDIA LABORATORIES,
C                 1982.
C***ROUTINES CALLED  XERRWV
C***END PROLOGUE  XERROR
      CHARACTER*(*) MESSG
C***FIRST EXECUTABLE STATEMENT  XERROR
      CALL XERRWV(MESSG,NMESSG,NERR,LEVEL,0,0,0,0,0.,0.)
      RETURN
      END
      SUBROUTINE XERRWV(MESSG,NMESSG,NERR,LEVEL,NI,I1,I2,NR,R1,R2)
      save
C***BEGIN PROLOGUE  XERRWV
C***DATE WRITTEN   800319   (YYMMDD)
C***REVISION DATE  820801   (YYMMDD)
C***CATEGORY NO.  R3C
C***KEYWORDS  ERROR,XERROR PACKAGE
C***AUTHOR  JONES, R. E., (SNLA)
C***PURPOSE  Processes error message allowing 2 integer and two real
C            values to be included in the message.
C***DESCRIPTION
C     Abstract
C        XERRWV processes a diagnostic message, in a manner
C        determined by the value of LEVEL and the current value
C        of the library error control flag, KONTRL.
C        (See subroutine XSETF for details.)
C        In addition, up to two integer values and two real
C        values may be printed along with the message.
C
C     Description of Parameters
C      --Input--
C        MESSG - the Hollerith message to be processed.
C        NMESSG- the actual number of characters in MESSG.
C        NERR  - the error number associated with this message.
C                NERR must not be zero.
C        LEVEL - error category.
C                =2 means this is an unconditionally fatal error.
C                =1 means this is a recoverable error.  (I.e., it is
C                   non-fatal if XSETF has been appropriately called.)
C                =0 means this is a warning message only.
C                =-1 means this is a warning message which is to be
C                   printed at most once, regardless of how many
C                   times this call is executed.
C        NI    - number of integer values to be printed. (0 to 2)
C        I1    - first integer value.
C        I2    - second integer value.
C        NR    - number of real values to be printed. (0 to 2)
C        R1    - first real value.
C        R2    - second real value.
C
C     Examples
C        CALL XERRWV('SMOOTH -- NUM (=I1) WAS ZERO.',29,1,2,
C    1   1,NUM,0,0,0.,0.)
C        CALL XERRWV('QUADXY -- REQUESTED ERROR (R1) LESS THAN MINIMUM (
C    1R2).,54,77,1,0,0,0,2,ERRREQ,ERRMIN)
C
C     Latest revision ---  19 MAR 1980
C     Written by Ron Jones, with SLATEC Common Math Library Subcommittee
C***REFERENCES  JONES R.E., KAHANER D.K., "XERROR, THE SLATEC ERROR-
C                 HANDLING PACKAGE", SAND82-0800, SANDIA LABORATORIES,
C                 1982.
C***ROUTINES CALLED  FDUMP,I1MACH,J4SAVE,XERABT,XERCTL,XERPRT,XERSAV,
C                    XGETUA
C***END PROLOGUE  XERRWV
      CHARACTER*(*) MESSG
      CHARACTER*20 LFIRST
      CHARACTER*37 FORM
      DIMENSION LUN(5)
C     GET FLAGS
C***FIRST EXECUTABLE STATEMENT  XERRWV
      LKNTRL = J4SAVE(2,0,.FALSE.)
      MAXMES = J4SAVE(4,0,.FALSE.)
C     CHECK FOR VALID INPUT
      IF ((NMESSG.GT.0).AND.(NERR.NE.0).AND.
     1    (LEVEL.GE.(-1)).AND.(LEVEL.LE.2)) GO TO 10
         IF (LKNTRL.GT.0) CALL XERPRT('FATAL ERROR IN...',17)
         CALL XERPRT('XERROR -- INVALID INPUT',23)
         IF (LKNTRL.GT.0) CALL FDUMP
         IF (LKNTRL.GT.0) CALL XERPRT('JOB ABORT DUE TO FATAL ERROR.',
     1  29)
         IF (LKNTRL.GT.0) CALL XERSAV(' ',0,0,0,KDUMMY)
         CALL XERABT('XERROR -- INVALID INPUT',23)
         RETURN
   10 CONTINUE
C     RECORD MESSAGE
      JUNK = J4SAVE(1,NERR,.TRUE.)
      CALL XERSAV(MESSG,NMESSG,NERR,LEVEL,KOUNT)
C     LET USER OVERRIDE
      LFIRST = MESSG
      LMESSG = NMESSG
      LERR = NERR
      LLEVEL = LEVEL
      CALL XERCTL(LFIRST,LMESSG,LERR,LLEVEL,LKNTRL)
C     RESET TO ORIGINAL VALUES
      LMESSG = NMESSG
      LERR = NERR
      LLEVEL = LEVEL
      LKNTRL = MAX0(-2,MIN0(2,LKNTRL))
      MKNTRL = IABS(LKNTRL)
C     DECIDE WHETHER TO PRINT MESSAGE
      IF ((LLEVEL.LT.2).AND.(LKNTRL.EQ.0)) GO TO 100
      IF (((LLEVEL.EQ.(-1)).AND.(KOUNT.GT.MIN0(1,MAXMES)))
     1.OR.((LLEVEL.EQ.0)   .AND.(KOUNT.GT.MAXMES))
     2.OR.((LLEVEL.EQ.1)   .AND.(KOUNT.GT.MAXMES).AND.(MKNTRL.EQ.1))
     3.OR.((LLEVEL.EQ.2)   .AND.(KOUNT.GT.MAX0(1,MAXMES)))) GO TO 100
         IF (LKNTRL.LE.0) GO TO 20
            CALL XERPRT(' ',1)
C           INTRODUCTION
            IF (LLEVEL.EQ.(-1)) CALL XERPRT
     1('WARNING MESSAGE...THIS MESSAGE WILL ONLY BE PRINTED ONCE.',57)
            IF (LLEVEL.EQ.0) CALL XERPRT('WARNING IN...',13)
            IF (LLEVEL.EQ.1) CALL XERPRT
     1      ('RECOVERABLE ERROR IN...',23)
            IF (LLEVEL.EQ.2) CALL XERPRT('FATAL ERROR IN...',17)
   20    CONTINUE
C        MESSAGE
         CALL XERPRT(MESSG,LMESSG)
         CALL XGETUA(LUN,NUNIT)
         ISIZEI = LOG10(FLOAT(I1MACH(9))) + 1.0
         ISIZEF = LOG10(FLOAT(I1MACH(10))**I1MACH(11)) + 1.0
         DO 50 KUNIT=1,NUNIT
            IUNIT = LUN(KUNIT)
            IF (IUNIT.EQ.0) IUNIT = I1MACH(4)
            DO 22 I=1,MIN(NI,2)
               WRITE (FORM,21) I,ISIZEI
   21          FORMAT ('(11X,21HIN ABOVE MESSAGE, I',I1,'=,I',I2,')   ')
               IF (I.EQ.1) WRITE (IUNIT,FORM) I1
               IF (I.EQ.2) WRITE (IUNIT,FORM) I2
   22       CONTINUE
            DO 24 I=1,MIN(NR,2)
               WRITE (FORM,23) I,ISIZEF+10,ISIZEF
   23          FORMAT ('(11X,21HIN ABOVE MESSAGE, R',I1,'=,E',
     1         I2,'.',I2,')')
               IF (I.EQ.1) WRITE (IUNIT,FORM) R1
               IF (I.EQ.2) WRITE (IUNIT,FORM) R2
   24       CONTINUE
            IF (LKNTRL.LE.0) GO TO 40
C              ERROR NUMBER
               WRITE (IUNIT,30) LERR
   30          FORMAT (15H ERROR NUMBER =,I10)
   40       CONTINUE
   50    CONTINUE
C        TRACE-BACK
         IF (LKNTRL.GT.0) CALL FDUMP
  100 CONTINUE
      IFATAL = 0
      IF ((LLEVEL.EQ.2).OR.((LLEVEL.EQ.1).AND.(MKNTRL.EQ.2)))
     1IFATAL = 1
C     QUIT HERE IF MESSAGE IS NOT FATAL
      IF (IFATAL.LE.0) RETURN
      IF ((LKNTRL.LE.0).OR.(KOUNT.GT.MAX0(1,MAXMES))) GO TO 120
C        PRINT REASON FOR ABORT
         IF (LLEVEL.EQ.1) CALL XERPRT
     1   ('JOB ABORT DUE TO UNRECOVERED ERROR.',35)
         IF (LLEVEL.EQ.2) CALL XERPRT
     1   ('JOB ABORT DUE TO FATAL ERROR.',29)
C        PRINT ERROR SUMMARY
         CALL XERSAV(' ',-1,0,0,KDUMMY)
  120 CONTINUE
C     ABORT
      IF ((LLEVEL.EQ.2).AND.(KOUNT.GT.MAX0(1,MAXMES))) LMESSG = 0
      CALL XERABT(MESSG,LMESSG)
      RETURN
      END
      SUBROUTINE XERSAV(MESSG,NMESSG,NERR,LEVEL,ICOUNT)
      save
C***BEGIN PROLOGUE  XERSAV
C***DATE WRITTEN   800319   (YYMMDD)
C***REVISION DATE  820801   (YYMMDD)
C***CATEGORY NO.  Z
C***KEYWORDS  ERROR,XERROR PACKAGE
C***AUTHOR  JONES, R. E., (SNLA)
C***PURPOSE  Records that an error occurred.
C***DESCRIPTION
C     Abstract
C        Record that this error occurred.
C
C     Description of Parameters
C     --Input--
C       MESSG, NMESSG, NERR, LEVEL are as in XERROR,
C       except that when NMESSG=0 the tables will be
C       dumped and cleared, and when NMESSG is less than zero the
C       tables will be dumped and not cleared.
C     --Output--
C       ICOUNT will be the number of times this message has
C       been seen, or zero if the table has overflowed and
C       does not contain this message specifically.
C       When NMESSG=0, ICOUNT will not be altered.
C
C     Written by Ron Jones, with SLATEC Common Math Library Subcommittee
C     Latest revision ---  19 Mar 1980
C***REFERENCES  JONES R.E., KAHANER D.K., "XERROR, THE SLATEC ERROR-
C                 HANDLING PACKAGE", SAND82-0800, SANDIA LABORATORIES,
C                 1982.
C***ROUTINES CALLED  I1MACH,S88FMT,XGETUA
C***END PROLOGUE  XERSAV
      INTEGER LUN(5)
      CHARACTER*(*) MESSG
      CHARACTER*20 MESTAB(10),MES
      DIMENSION NERTAB(10),LEVTAB(10),KOUNT(10)
      SAVE MESTAB,NERTAB,LEVTAB,KOUNT,KOUNTX
C     NEXT TWO DATA STATEMENTS ARE NECESSARY TO PROVIDE A BLANK
C     ERROR TABLE INITIALLY
      DATA KOUNT(1),KOUNT(2),KOUNT(3),KOUNT(4),KOUNT(5),
     1     KOUNT(6),KOUNT(7),KOUNT(8),KOUNT(9),KOUNT(10)
     2     /0,0,0,0,0,0,0,0,0,0/
      DATA KOUNTX/0/
C***FIRST EXECUTABLE STATEMENT  XERSAV
      IF (NMESSG.GT.0) GO TO 80
C     DUMP THE TABLE
         IF (KOUNT(1).EQ.0) RETURN
C        PRINT TO EACH UNIT
         CALL XGETUA(LUN,NUNIT)
         DO 60 KUNIT=1,NUNIT
            IUNIT = LUN(KUNIT)
            IF (IUNIT.EQ.0) IUNIT = I1MACH(4)
C           PRINT TABLE HEADER
            WRITE (IUNIT,10)
   10       FORMAT (32H0          ERROR MESSAGE SUMMARY/
     1      51H MESSAGE START             NERR     LEVEL     COUNT)
C           PRINT BODY OF TABLE
            DO 20 I=1,10
               IF (KOUNT(I).EQ.0) GO TO 30
               WRITE (IUNIT,15) MESTAB(I),NERTAB(I),LEVTAB(I),KOUNT(I)
   15          FORMAT (1X,A20,3I10)
   20       CONTINUE
   30       CONTINUE
C           PRINT NUMBER OF OTHER ERRORS
            IF (KOUNTX.NE.0) WRITE (IUNIT,40) KOUNTX
   40       FORMAT (41H0OTHER ERRORS NOT INDIVIDUALLY TABULATED=,I10)
            WRITE (IUNIT,50)
   50       FORMAT (1X)
   60    CONTINUE
         IF (NMESSG.LT.0) RETURN
C        CLEAR THE ERROR TABLES
         DO 70 I=1,10
   70       KOUNT(I) = 0
         KOUNTX = 0
         RETURN
   80 CONTINUE
C     PROCESS A MESSAGE...
C     SEARCH FOR THIS MESSG, OR ELSE AN EMPTY SLOT FOR THIS MESSG,
C     OR ELSE DETERMINE THAT THE ERROR TABLE IS FULL.
      MES = MESSG
      DO 90 I=1,10
         II = I
         IF (KOUNT(I).EQ.0) GO TO 110
         IF (MES.NE.MESTAB(I)) GO TO 90
         IF (NERR.NE.NERTAB(I)) GO TO 90
         IF (LEVEL.NE.LEVTAB(I)) GO TO 90
         GO TO 100
   90 CONTINUE
C     THREE POSSIBLE CASES...
C     TABLE IS FULL
         KOUNTX = KOUNTX+1
         ICOUNT = 1
         RETURN
C     MESSAGE FOUND IN TABLE
  100    KOUNT(II) = KOUNT(II) + 1
         ICOUNT = KOUNT(II)
         RETURN
C     EMPTY SLOT FOUND FOR NEW MESSAGE
  110    MESTAB(II) = MES
         NERTAB(II) = NERR
         LEVTAB(II) = LEVEL
         KOUNT(II)  = 1
         ICOUNT = 1
         RETURN
      END
      SUBROUTINE XGETUA(IUNITA,N)
      save
C***BEGIN PROLOGUE  XGETUA
C***DATE WRITTEN   790801   (YYMMDD)
C***REVISION DATE  820801   (YYMMDD)
C***CATEGORY NO.  R3C
C***KEYWORDS  ERROR,XERROR PACKAGE
C***AUTHOR  JONES, R. E., (SNLA)
C***PURPOSE  Returns unit number(s) to which error messages are being
C            sent.
C***DESCRIPTION
C     Abstract
C        XGETUA may be called to determine the unit number or numbers
C        to which error messages are being sent.
C        These unit numbers may have been set by a call to XSETUN,
C        or a call to XSETUA, or may be a default value.
C
C     Description of Parameters
C      --Output--
C        IUNIT - an array of one to five unit numbers, depending
C                on the value of N.  A value of zero refers to the
C                default unit, as defined by the I1MACH machine
C                constant routine.  Only IUNIT(1),...,IUNIT(N) are
C                defined by XGETUA.  The values of IUNIT(N+1),...,
C                IUNIT(5) are not defined (for N .LT. 5) or altered
C                in any way by XGETUA.
C        N     - the number of units to which copies of the
C                error messages are being sent.  N will be in the
C                range from 1 to 5.
C
C     Latest revision ---  19 MAR 1980
C     Written by Ron Jones, with SLATEC Common Math Library Subcommittee
C***REFERENCES  JONES R.E., KAHANER D.K., "XERROR, THE SLATEC ERROR-
C                 HANDLING PACKAGE", SAND82-0800, SANDIA LABORATORIES,
C                 1982.
C***ROUTINES CALLED  J4SAVE
C***END PROLOGUE  XGETUA
      DIMENSION IUNITA(5)
C***FIRST EXECUTABLE STATEMENT  XGETUA
      N = J4SAVE(5,0,.FALSE.)
      DO 30 I=1,N
         INDEX = I+4
         IF (I.EQ.1) INDEX = 3
         IUNITA(I) = J4SAVE(INDEX,0,.FALSE.)
   30 CONTINUE
      RETURN
      END
      DOUBLE PRECISION FUNCTION D1MACH(I)
      save
C***BEGIN PROLOGUE  D1MACH
C***DATE WRITTEN   750101   (YYMMDD)
C***REVISION DATE  910131   (YYMMDD)
C***CATEGORY NO.  R1
C***KEYWORDS  MACHINE CONSTANTS
C***AUTHOR  FOX, P. A., (BELL LABS)
C           HALL, A. D., (BELL LABS)
C           SCHRYER, N. L., (BELL LABS)
C***PURPOSE  Returns double precision machine dependent constants
C***DESCRIPTION
C
C     This is the CMLIB version of D1MACH, the double precision machine
C     constants subroutine originally developed for the PORT library.
C
C     D1MACH can be used to obtain machine-dependent parameters
C     for the local machine environment.  It is a function
C     subprogram with one (input) argument, and can be called
C     as follows, for example
C
C          D = D1MACH(I)
C
C     where I=1,...,5.  The (output) value of D above is
C     determined by the (input) value of I.  The results for
C     various values of I are discussed below.
C
C  Double-precision machine constants
C  D1MACH( 1) = B**(EMIN-1), the smallest positive magnitude.
C  D1MACH( 2) = B**EMAX*(1 - B**(-T)), the largest magnitude.
C  D1MACH( 3) = B**(-T), the smallest relative spacing.
C  D1MACH( 4) = B**(1-T), the largest relative spacing.
C  D1MACH( 5) = LOG10(B)
C***REFERENCES  FOX P.A., HALL A.D., SCHRYER N.L.,*FRAMEWORK FOR A
C                 PORTABLE LIBRARY*, ACM TRANSACTIONS ON MATHEMATICAL
C                 SOFTWARE, VOL. 4, NO. 2, JUNE 1978, PP. 177-188.
C***ROUTINES CALLED  XERROR
C***END PROLOGUE  D1MACH
C
      INTEGER SMALL(4)
      INTEGER LARGE(4)
      INTEGER RIGHT(4)
      INTEGER DIVER(4)
      INTEGER LOG10(4)
C
      DOUBLE PRECISION DMACH(5)
C
      EQUIVALENCE (DMACH(1),SMALL(1))
      EQUIVALENCE (DMACH(2),LARGE(1))
      EQUIVALENCE (DMACH(3),RIGHT(1))
      EQUIVALENCE (DMACH(4),DIVER(1))
      EQUIVALENCE (DMACH(5),LOG10(1))
C
C     MACHINE CONSTANTS FOR IEEE ARITHMETIC MACHINES, SUCH AS THE AT&T
C     3B SERIES AND MOTOROLA 68000 BASED MACHINES (E.G. SUN 3 AND AT&T
C     PC 7300), IN WHICH THE MOST SIGNIFICANT BYTE IS STORED FIRST.
C
C === MACHINE = IEEE.MOST-SIG-BYTE-FIRST
C === MACHINE = SUN
C === MACHINE = 68000
C === MACHINE = ATT.3B
C === MACHINE = ATT.7300
C      DATA SMALL(1),SMALL(2) /    1048576,          0 /
C      DATA LARGE(1),LARGE(2) / 2146435071,         -1 /
C      DATA RIGHT(1),RIGHT(2) / 1017118720,          0 /
C      DATA DIVER(1),DIVER(2) / 1018167296,          0 /
C      DATA LOG10(1),LOG10(2) / 1070810131, 1352628735 /
C
C     MACHINE CONSTANTS FOR IEEE ARITHMETIC MACHINES AND 8087-BASED
C     MICROS, SUCH AS THE IBM PC AND AT&T 6300, IN WHICH THE LEAST
C     SIGNIFICANT BYTE IS STORED FIRST.
C
C === MACHINE = IEEE.LEAST-SIG-BYTE-FIRST
C === MACHINE = 8087
C === MACHINE = IBM.PC
C === MACHINE = ATT.6300
       DATA SMALL(1),SMALL(2) /          0,    1048576 /
       DATA LARGE(1),LARGE(2) /         -1, 2146435071 /
       DATA RIGHT(1),RIGHT(2) /          0, 1017118720 /
       DATA DIVER(1),DIVER(2) /          0, 1018167296 /
       DATA LOG10(1),LOG10(2) / 1352628735, 1070810131 /
C
C     MACHINE CONSTANTS FOR AMDAHL MACHINES.
C
C === MACHINE = AMDAHL
C      DATA SMALL(1),SMALL(2) /    1048576,          0 /
C      DATA LARGE(1),LARGE(2) / 2147483647,         -1 /
C      DATA RIGHT(1),RIGHT(2) /  856686592,          0 /
C      DATA DIVER(1),DIVER(2) /  873463808,          0 /
C      DATA LOG10(1),LOG10(2) / 1091781651, 1352628735 /
C
C     MACHINE CONSTANTS FOR THE BURROUGHS 1700 SYSTEM.
C
C === MACHINE = BURROUGHS.1700
C      DATA SMALL(1) / ZC00800000 /
C      DATA SMALL(2) / Z000000000 /
C      DATA LARGE(1) / ZDFFFFFFFF /
C      DATA LARGE(2) / ZFFFFFFFFF /
C      DATA RIGHT(1) / ZCC5800000 /
C      DATA RIGHT(2) / Z000000000 /
C      DATA DIVER(1) / ZCC6800000 /
C      DATA DIVER(2) / Z000000000 /
C      DATA LOG10(1) / ZD00E730E7 /
C      DATA LOG10(2) / ZC77800DC0 /
C
C     MACHINE CONSTANTS FOR THE BURROUGHS 5700 SYSTEM.
C
C === MACHINE = BURROUGHS.5700
C      DATA SMALL(1) / O1771000000000000 /
C      DATA SMALL(2) / O0000000000000000 /
C      DATA LARGE(1) / O0777777777777777 /
C      DATA LARGE(2) / O0007777777777777 /
C      DATA RIGHT(1) / O1461000000000000 /
C      DATA RIGHT(2) / O0000000000000000 /
C      DATA DIVER(1) / O1451000000000000 /
C      DATA DIVER(2) / O0000000000000000 /
C      DATA LOG10(1) / O1157163034761674 /
C      DATA LOG10(2) / O0006677466732724 /
C
C     MACHINE CONSTANTS FOR THE BURROUGHS 6700/7700 SYSTEMS.
C
C === MACHINE = BURROUGHS.6700
C === MACHINE = BURROUGHS.7700
C      DATA SMALL(1) / O1771000000000000 /
C      DATA SMALL(2) / O7770000000000000 /
C      DATA LARGE(1) / O0777777777777777 /
C      DATA LARGE(2) / O7777777777777777 /
C      DATA RIGHT(1) / O1461000000000000 /
C      DATA RIGHT(2) / O0000000000000000 /
C      DATA DIVER(1) / O1451000000000000 /
C      DATA DIVER(2) / O0000000000000000 /
C      DATA LOG10(1) / O1157163034761674 /
C      DATA LOG10(2) / O0006677466732724 /
C
C     MACHINE CONSTANTS FOR THE CONVEX C-120 (NATIVE MODE)
C     WITH OR WITHOUT -R8 OPTION
C
C === MACHINE = CONVEX.C1
C === MACHINE = CONVEX.C1.R8
C      DATA DMACH(1) / 5.562684646268007D-309 /
C      DATA DMACH(2) / 8.988465674311577D+307 /
C      DATA DMACH(3) / 1.110223024625157D-016 /
C      DATA DMACH(4) / 2.220446049250313D-016 /
C      DATA DMACH(5) / 3.010299956639812D-001 /
C
C     MACHINE CONSTANTS FOR THE CONVEX C-120 (IEEE MODE)
C     WITH OR WITHOUT -R8 OPTION
C
C === MACHINE = CONVEX.C1.IEEE
C === MACHINE = CONVEX.C1.IEEE.R8
C      DATA DMACH(1) / 2.225073858507202D-308 /
C      DATA DMACH(2) / 1.797693134862315D+308 /
C      DATA DMACH(3) / 1.110223024625157D-016 /
C      DATA DMACH(4) / 2.220446049250313D-016 /
C      DATA DMACH(5) / 3.010299956639812D-001 /
C
C     MACHINE CONSTANTS FOR THE CYBER 170/180 SERIES USING NOS (FTN5).
C
C === MACHINE = CYBER.170.NOS
C === MACHINE = CYBER.180.NOS
C      DATA SMALL(1) / O"00604000000000000000" /
C      DATA SMALL(2) / O"00000000000000000000" /
C      DATA LARGE(1) / O"37767777777777777777" /
C      DATA LARGE(2) / O"37167777777777777777" /
C      DATA RIGHT(1) / O"15604000000000000000" /
C      DATA RIGHT(2) / O"15000000000000000000" /
C      DATA DIVER(1) / O"15614000000000000000" /
C      DATA DIVER(2) / O"15010000000000000000" /
C      DATA LOG10(1) / O"17164642023241175717" /
C      DATA LOG10(2) / O"16367571421742254654" /
C
C     MACHINE CONSTANTS FOR THE CDC 180 SERIES USING NOS/VE
C
C === MACHINE = CYBER.180.NOS/VE
C      DATA SMALL(1) / Z"3001800000000000" /
C      DATA SMALL(2) / Z"3001000000000000" /
C      DATA LARGE(1) / Z"4FFEFFFFFFFFFFFE" /
C      DATA LARGE(2) / Z"4FFE000000000000" /
C      DATA RIGHT(1) / Z"3FD2800000000000" /
C      DATA RIGHT(2) / Z"3FD2000000000000" /
C      DATA DIVER(1) / Z"3FD3800000000000" /
C      DATA DIVER(2) / Z"3FD3000000000000" /
C      DATA LOG10(1) / Z"3FFF9A209A84FBCF" /
C      DATA LOG10(2) / Z"3FFFF7988F8959AC" /
C
C     MACHINE CONSTANTS FOR THE CYBER 205
C
C === MACHINE = CYBER.205
C      DATA SMALL(1) / X'9000400000000000' /
C      DATA SMALL(2) / X'8FD1000000000000' /
C      DATA LARGE(1) / X'6FFF7FFFFFFFFFFF' /
C      DATA LARGE(2) / X'6FD07FFFFFFFFFFF' /
C      DATA RIGHT(1) / X'FF74400000000000' /
C      DATA RIGHT(2) / X'FF45000000000000' /
C      DATA DIVER(1) / X'FF75400000000000' /
C      DATA DIVER(2) / X'FF46000000000000' /
C      DATA LOG10(1) / X'FFD04D104D427DE7' /
C      DATA LOG10(2) / X'FFA17DE623E2566A' /
C
C     MACHINE CONSTANTS FOR THE CDC 6000/7000 SERIES.
C
C === MACHINE = CDC.6000
C === MACHINE = CDC.7000
C      DATA SMALL(1) / 00604000000000000000B /
C      DATA SMALL(2) / 00000000000000000000B /
C      DATA LARGE(1) / 37767777777777777777B /
C      DATA LARGE(2) / 37167777777777777777B /
C      DATA RIGHT(1) / 15604000000000000000B /
C      DATA RIGHT(2) / 15000000000000000000B /
C      DATA DIVER(1) / 15614000000000000000B /
C      DATA DIVER(2) / 15010000000000000000B /
C      DATA LOG10(1) / 17164642023241175717B /
C      DATA LOG10(2) / 16367571421742254654B /
C
C     MACHINE CONSTANTS FOR THE CRAY 1, XMP, 2, AND 3.
C
C === MACHINE = CRAY.46-BIT-INTEGER
C === MACHINE = CRAY.64-BIT-INTEGER
C      DATA SMALL(1) / 201354000000000000000B /
C      DATA SMALL(2) / 000000000000000000000B /
C      DATA LARGE(1) / 577767777777777777777B /
C      DATA LARGE(2) / 000007777777777777776B /
C      DATA RIGHT(1) / 376434000000000000000B /
C      DATA RIGHT(2) / 000000000000000000000B /
C      DATA DIVER(1) / 376444000000000000000B /
C      DATA DIVER(2) / 000000000000000000000B /
C      DATA LOG10(1) / 377774642023241175717B /
C      DATA LOG10(2) / 000007571421742254654B /
C
C     MACHINE CONSTANTS FOR THE DATA GENERAL ECLIPSE S/200
C
C     NOTE - IT MAY BE APPROPRIATE TO INCLUDE THE FOLLOWING LINE -
C     STATIC DMACH(5)
C
C === MACHINE = DATA_GENERAL.ECLIPSE.S/200
C      DATA SMALL/20K,3*0/,LARGE/77777K,3*177777K/
C      DATA RIGHT/31420K,3*0/,DIVER/32020K,3*0/
C      DATA LOG10/40423K,42023K,50237K,74776K/
C
C     ELXSI 6400
C
C === MACHINE = ELSXI.6400
C      DATA SMALL(1), SMALL(2) / '00100000'X,'00000000'X /
C      DATA LARGE(1), LARGE(2) / '7FEFFFFF'X,'FFFFFFFF'X /
C      DATA RIGHT(1), RIGHT(2) / '3CB00000'X,'00000000'X /
C      DATA DIVER(1), DIVER(2) / '3CC00000'X,'00000000'X /
C      DATA LOG10(1), DIVER(2) / '3FD34413'X,'509F79FF'X /
C
C     MACHINE CONSTANTS FOR THE HARRIS 220
C     MACHINE CONSTANTS FOR THE HARRIS SLASH 6 AND SLASH 7
C
C === MACHINE = HARRIS.220
C === MACHINE = HARRIS.SLASH6
C === MACHINE = HARRIS.SLASH7
C      DATA SMALL(1),SMALL(2) / '20000000, '00000201 /
C      DATA LARGE(1),LARGE(2) / '37777777, '37777577 /
C      DATA RIGHT(1),RIGHT(2) / '20000000, '00000333 /
C      DATA DIVER(1),DIVER(2) / '20000000, '00000334 /
C      DATA LOG10(1),LOG10(2) / '23210115, '10237777 /
C
C     MACHINE CONSTANTS FOR THE HONEYWELL 600/6000 SERIES.
C     MACHINE CONSTANTS FOR THE HONEYWELL DPS 8/70 SERIES.
C
C === MACHINE = HONEYWELL.600/6000
C === MACHINE = HONEYWELL.DPS.8/70
C      DATA SMALL(1),SMALL(2) / O402400000000, O000000000000 /
C      DATA LARGE(1),LARGE(2) / O376777777777, O777777777777 /
C      DATA RIGHT(1),RIGHT(2) / O604400000000, O000000000000 /
C      DATA DIVER(1),DIVER(2) / O606400000000, O000000000000 /
C      DATA LOG10(1),LOG10(2) / O776464202324, O117571775714 /
C
C      MACHINE CONSTANTS FOR THE HP 2100
C      3 WORD DOUBLE PRECISION OPTION WITH FTN4
C
C === MACHINE = HP.2100.3_WORD_DP
C      DATA SMALL(1), SMALL(2), SMALL(3) / 40000B,       0,       1 /
C      DATA LARGE(1), LARGE(2), LARGE(3) / 77777B, 177777B, 177776B /
C      DATA RIGHT(1), RIGHT(2), RIGHT(3) / 40000B,       0,    265B /
C      DATA DIVER(1), DIVER(2), DIVER(3) / 40000B,       0,    276B /
C      DATA LOG10(1), LOG10(2), LOG10(3) / 46420B,  46502B,  77777B /
C
C      MACHINE CONSTANTS FOR THE HP 2100
C      4 WORD DOUBLE PRECISION OPTION WITH FTN4
C
C === MACHINE = HP.2100.4_WORD_DP
C      DATA SMALL(1), SMALL(2) /  40000B,       0 /
C      DATA SMALL(3), SMALL(4) /       0,       1 /
C      DATA LARGE(1), LARGE(2) /  77777B, 177777B /
C      DATA LARGE(3), LARGE(4) / 177777B, 177776B /
C      DATA RIGHT(1), RIGHT(2) /  40000B,       0 /
C      DATA RIGHT(3), RIGHT(4) /       0,    225B /
C      DATA DIVER(1), DIVER(2) /  40000B,       0 /
C      DATA DIVER(3), DIVER(4) /       0,    227B /
C      DATA LOG10(1), LOG10(2) /  46420B,  46502B /
C      DATA LOG10(3), LOG10(4) /  76747B, 176377B /
C
C     HP 9000
C
C      D1MACH(1) = 2.8480954D-306
C      D1MACH(2) = 1.40444776D+306
C      D1MACH(3) = 2.22044605D-16
C      D1MACH(4) = 4.44089210D-16
C      D1MACH(5) = 3.01029996D-1
C
C === MACHINE = HP.9000
C      DATA SMALL(1), SMALL(2) / 00040000000B, 00000000000B /
C      DATA LARGE(1), LARGE(2) / 17737777777B, 37777777777B /
C      DATA RIGHT(1), RIGHT(2) / 07454000000B, 00000000000B /
C      DATA DIVER(1), DIVER(2) / 07460000000B, 00000000000B /
C      DATA LOG10(1), LOG10(2) / 07764642023B, 12047674777B /
C
C     MACHINE CONSTANTS FOR THE IBM 360/370 SERIES,
C     THE XEROX SIGMA 5/7/9, THE SEL SYSTEMS 85/86, AND
C     THE INTERDATA 3230 AND INTERDATA 7/32.
C
C === MACHINE = IBM.360
C === MACHINE = IBM.370
C === MACHINE = XEROX.SIGMA.5
C === MACHINE = XEROX.SIGMA.7
C === MACHINE = XEROX.SIGMA.9
C === MACHINE = SEL.85
C === MACHINE = SEL.86
C === MACHINE = INTERDATA.3230
C === MACHINE = INTERDATA.7/32
C      DATA SMALL(1),SMALL(2) / Z00100000, Z00000000 /
C      DATA LARGE(1),LARGE(2) / Z7FFFFFFF, ZFFFFFFFF /
C      DATA RIGHT(1),RIGHT(2) / Z33100000, Z00000000 /
C      DATA DIVER(1),DIVER(2) / Z34100000, Z00000000 /
C      DATA LOG10(1),LOG10(2) / Z41134413, Z509F79FF /
C
C     MACHINE CONSTANTS FOR THE INTERDATA 8/32
C     WITH THE UNIX SYSTEM FORTRAN 77 COMPILER.
C
C     FOR THE INTERDATA FORTRAN VII COMPILER REPLACE
C     THE Z'S SPECIFYING HEX CONSTANTS WITH Y'S.
C
C === MACHINE = INTERDATA.8/32.UNIX
C      DATA SMALL(1),SMALL(2) / Z'00100000', Z'00000000' /
C      DATA LARGE(1),LARGE(2) / Z'7EFFFFFF', Z'FFFFFFFF' /
C      DATA RIGHT(1),RIGHT(2) / Z'33100000', Z'00000000' /
C      DATA DIVER(1),DIVER(2) / Z'34100000', Z'00000000' /
C      DATA LOG10(1),LOG10(2) / Z'41134413', Z'509F79FF' /
C
C     MACHINE CONSTANTS FOR THE PDP-10 (KA PROCESSOR).
C
C === MACHINE = PDP-10.KA
C      DATA SMALL(1),SMALL(2) / "033400000000, "000000000000 /
C      DATA LARGE(1),LARGE(2) / "377777777777, "344777777777 /
C      DATA RIGHT(1),RIGHT(2) / "113400000000, "000000000000 /
C      DATA DIVER(1),DIVER(2) / "114400000000, "000000000000 /
C      DATA LOG10(1),LOG10(2) / "177464202324, "144117571776 /
C
C     MACHINE CONSTANTS FOR THE PDP-10 (KI PROCESSOR).
C
C === MACHINE = PDP-10.KI
C      DATA SMALL(1),SMALL(2) / "000400000000, "000000000000 /
C      DATA LARGE(1),LARGE(2) / "377777777777, "377777777777 /
C      DATA RIGHT(1),RIGHT(2) / "103400000000, "000000000000 /
C      DATA DIVER(1),DIVER(2) / "104400000000, "000000000000 /
C      DATA LOG10(1),LOG10(2) / "177464202324, "047674776746 /
C
C     MACHINE CONSTANTS FOR PDP-11 FORTRAN SUPPORTING
C     32-BIT INTEGERS (EXPRESSED IN INTEGER AND OCTAL).
C
C === MACHINE = PDP-11.32-BIT
C      DATA SMALL(1),SMALL(2) /    8388608,           0 /
C      DATA LARGE(1),LARGE(2) / 2147483647,          -1 /
C      DATA RIGHT(1),RIGHT(2) /  612368384,           0 /
C      DATA DIVER(1),DIVER(2) /  620756992,           0 /
C      DATA LOG10(1),LOG10(2) / 1067065498, -2063872008 /
C
C      DATA SMALL(1),SMALL(2) / O00040000000, O00000000000 /
C      DATA LARGE(1),LARGE(2) / O17777777777, O37777777777 /
C      DATA RIGHT(1),RIGHT(2) / O04440000000, O00000000000 /
C      DATA DIVER(1),DIVER(2) / O04500000000, O00000000000 /
C      DATA LOG10(1),LOG10(2) / O07746420232, O20476747770 /
C
C     MACHINE CONSTANTS FOR PDP-11 FORTRAN SUPPORTING
C     16-BIT INTEGERS (EXPRESSED IN INTEGER AND OCTAL).
C
C === MACHINE = PDP-11.16-BIT
C      DATA SMALL(1),SMALL(2) /    128,      0 /
C      DATA SMALL(3),SMALL(4) /      0,      0 /
C      DATA LARGE(1),LARGE(2) /  32767,     -1 /
C      DATA LARGE(3),LARGE(4) /     -1,     -1 /
C      DATA RIGHT(1),RIGHT(2) /   9344,      0 /
C      DATA RIGHT(3),RIGHT(4) /      0,      0 /
C      DATA DIVER(1),DIVER(2) /   9472,      0 /
C      DATA DIVER(3),DIVER(4) /      0,      0 /
C      DATA LOG10(1),LOG10(2) /  16282,   8346 /
C      DATA LOG10(3),LOG10(4) / -31493, -12296 /
C
C      DATA SMALL(1),SMALL(2) / O000200, O000000 /
C      DATA SMALL(3),SMALL(4) / O000000, O000000 /
C      DATA LARGE(1),LARGE(2) / O077777, O177777 /
C      DATA LARGE(3),LARGE(4) / O177777, O177777 /
C      DATA RIGHT(1),RIGHT(2) / O022200, O000000 /
C      DATA RIGHT(3),RIGHT(4) / O000000, O000000 /
C      DATA DIVER(1),DIVER(2) / O022400, O000000 /
C      DATA DIVER(3),DIVER(4) / O000000, O000000 /
C      DATA LOG10(1),LOG10(2) / O037632, O020232 /
C      DATA LOG10(3),LOG10(4) / O102373, O147770 /
C
C     MACHINE CONSTANTS FOR THE SEQUENT BALANCE 8000
C
C === MACHINE = SEQUENT.BALANCE.8000
C      DATA SMALL(1),SMALL(2) / $00000000,  $00100000 /
C      DATA LARGE(1),LARGE(2) / $FFFFFFFF,  $7FEFFFFF /
C      DATA RIGHT(1),RIGHT(2) / $00000000,  $3CA00000 /
C      DATA DIVER(1),DIVER(2) / $00000000,  $3CB00000 /
C      DATA LOG10(1),LOG10(2) / $509F79FF,  $3FD34413 /
C
C     MACHINE CONSTANTS FOR THE UNIVAC 1100 SERIES. FTN COMPILER
C
C === MACHINE = UNIVAC.1100
C      DATA SMALL(1),SMALL(2) / O000040000000, O000000000000 /
C      DATA LARGE(1),LARGE(2) / O377777777777, O777777777777 /
C      DATA RIGHT(1),RIGHT(2) / O170540000000, O000000000000 /
C      DATA DIVER(1),DIVER(2) / O170640000000, O000000000000 /
C      DATA LOG10(1),LOG10(2) / O177746420232, O411757177572 /
C
C     MACHINE CONSTANTS FOR VAX 11/780
C     (EXPRESSED IN INTEGER AND HEXADECIMAL)
C    *** THE INTEGER FORMAT SHOULD BE OK FOR UNIX SYSTEMS***
C
C === MACHINE = VAX.11/780
C      DATA SMALL(1), SMALL(2) /        128,           0 /
C      DATA LARGE(1), LARGE(2) /     -32769,          -1 /
C      DATA RIGHT(1), RIGHT(2) /       9344,           0 /
C      DATA DIVER(1), DIVER(2) /       9472,           0 /
C      DATA LOG10(1), LOG10(2) /  546979738,  -805796613 /
C
C    ***THE HEX FORMAT BELOW MAY NOT BE SUITABLE FOR UNIX SYSYEMS***
C      DATA SMALL(1), SMALL(2) / Z00000080, Z00000000 /
C      DATA LARGE(1), LARGE(2) / ZFFFF7FFF, ZFFFFFFFF /
C      DATA RIGHT(1), RIGHT(2) / Z00002480, Z00000000 /
C      DATA DIVER(1), DIVER(2) / Z00002500, Z00000000 /
C      DATA LOG10(1), LOG10(2) / Z209A3F9A, ZCFF884FB /
C
C   MACHINE CONSTANTS FOR VAX 11/780 (G-FLOATING)
C     (EXPRESSED IN INTEGER AND HEXADECIMAL)
C    *** THE INTEGER FORMAT SHOULD BE OK FOR UNIX SYSTEMS***
C
C      DATA SMALL(1), SMALL(2) /         16,           0 /
C      DATA LARGE(1), LARGE(2) /     -32769,          -1 /
C      DATA RIGHT(1), RIGHT(2) /      15552,           0 /
C      DATA DIVER(1), DIVER(2) /      15568,           0 /
C      DATA LOG10(1), LOG10(2) /  1142112243, 2046775455 /
C
C    ***THE HEX FORMAT BELOW MAY NOT BE SUITABLE FOR UNIX SYSYEMS***
C      DATA SMALL(1), SMALL(2) / Z00000010, Z00000000 /
C      DATA LARGE(1), LARGE(2) / ZFFFF7FFF, ZFFFFFFFF /
C      DATA RIGHT(1), RIGHT(2) / Z00003CC0, Z00000000 /
C      DATA DIVER(1), DIVER(2) / Z00003CD0, Z00000000 /
C      DATA LOG10(1), LOG10(2) / Z44133FF3, Z79FF509F /
C
C
C***FIRST EXECUTABLE STATEMENT  D1MACH
      IF (I .LT. 1  .OR.  I .GT. 5)
     1   CALL XERROR( 'D1MACH -- I OUT OF BOUNDS',25,1,2)
C
      D1MACH = DMACH(I)
      RETURN
C
      END
      SUBROUTINE DASSST(D, IV, P, STEP, STLSTG, V, X, X0)
      save
C
C  ***  ASSESS CANDIDATE STEP (***SOL VERSION 2.3)  ***
C
      INTEGER P, IV(32)
      DOUBLE PRECISION D(P), STEP(P), STLSTG(P), V(37), X(P), X0(P)
C
C  ***  PURPOSE  ***
C
C        THIS SUBROUTINE IS CALLED BY AN UNCONSTRAINED MINIMIZATION
C     ROUTINE TO ASSESS THE NEXT CANDIDATE STEP.  IT MAY RECOMMEND ONE
C     OF SEVERAL COURSES OF ACTION, SUCH AS ACCEPTING THE STEP, RECOM-
C     PUTING IT USING THE SAME OR A NEW QUADRATIC MODEL, OR HALTING DUE
C     TO CONVERGENCE OR FALSE CONVERGENCE.  SEE THE RETURN CODE LISTING
C     BELOW.
C
C--------------------------  PARAMETER USAGE  --------------------------
C
C     IV (I/O) INTEGER PARAMETER AND SCRATCH VECTOR -- SEE DESCRIPTION
C             BELOW OF IV VALUES REFERENCED.
C      D (IN)  SCALE VECTOR USED IN COMPUTING V(RELDX) -- SEE BELOW.
C      P (IN)  NUMBER OF PARAMETERS BEING OPTIMIZED.
C   STEP (I/O) ON INPUT, STEP IS THE STEP TO BE ASSESSED.  IT IS UN-
C             CHANGED ON OUTPUT UNLESS A PREVIOUS STEP ACHIEVED A
C             BETTER OBJECTIVE FUNCTION REDUCTION, IN WHICH CASE STLSTG
C             WILL HAVE BEEN COPIED TO STEP.
C STLSTG (I/O) WHEN ASSESS RECOMMENDS RECOMPUTING STEP EVEN THOUGH THE
C             CURRENT (OR A PREVIOUS) STEP YIELDS AN OBJECTIVE FUNC-
C             TION DECREASE, IT SAVES IN STLSTG THE STEP THAT GAVE THE
C             BEST FUNCTION REDUCTION SEEN SO FAR (IN THE CURRENT ITERA-
C             TION).  IF THE RECOMPUTED STEP YIELDS A LARGER FUNCTION
C             VALUE, THEN STEP IS RESTORED FROM STLSTG AND
C             X = X0 + STEP IS RECOMPUTED.
C      V (I/O) REAL PARAMETER AND SCRATCH VECTOR -- SEE DESCRIPTION
C             BELOW OF V VALUES REFERENCED.
C      X (I/O) ON INPUT, X = X0 + STEP IS THE POINT AT WHICH THE OBJEC-
C             TIVE FUNCTION HAS JUST BEEN EVALUATED.  IF AN EARLIER
C             STEP YIELDED A BIGGER FUNCTION DECREASE, THEN X IS
C             RESTORED TO THE CORRESPONDING EARLIER VALUE.  OTHERWISE,
C             IF THE CURRENT STEP DOES NOT GIVE ANY FUNCTION DECREASE,
C             THEN X IS RESTORED TO X0.
C     X0 (IN)  INITIAL OBJECTIVE FUNCTION PARAMETER VECTOR (AT THE
C             START OF THE CURRENT ITERATION).
C
C  ***  IV VALUES REFERENCED  ***
C
C    IV(IRC) (I/O) ON INPUT FOR THE FIRST STEP TRIED IN A NEW ITERATION,
C             IV(IRC) SHOULD BE SET TO 3 OR 4 (THE VALUE TO WHICH IT IS
C             SET WHEN STEP IS DEFINITELY TO BE ACCEPTED).  ON INPUT
C             AFTER STEP HAS BEEN RECOMPUTED, IV(IRC) SHOULD BE
C             UNCHANGED SINCE THE PREVIOUS RETURN OF ASSESS.
C                ON OUTPUT, IV(IRC) IS A RETURN CODE HAVING ONE OF THE
C             FOLLOWING VALUES...
C                  1 = SWITCH MODELS OR TRY SMALLER STEP.
C                  2 = SWITCH MODELS OR ACCEPT STEP.
C                  3 = ACCEPT STEP AND DETERMINE V(RADFAC) BY GRADIENT
C                       TESTS.
C                  4 = ACCEPT STEP, V(RADFAC) HAS BEEN DETERMINED.
C                  5 = RECOMPUTE STEP (USING THE SAME MODEL).
C                  6 = RECOMPUTE STEP WITH RADIUS = V(LMAXS) BUT DO NOT
C                       EVAULATE THE OBJECTIVE FUNCTION.
C                  7 = X-CONVERGENCE (SEE V(XCTOL)).
C                  8 = RELATIVE FUNCTION CONVERGENCE (SEE V(RFCTOL)).
C                  9 = BOTH X- AND RELATIVE FUNCTION CONVERGENCE.
C                 10 = ABSOLUTE FUNCTION CONVERGENCE (SEE V(AFCTOL)).
C                 11 = SINGULAR CONVERGENCE (SEE V(LMAXS)).
C                 12 = FALSE CONVERGENCE (SEE V(XFTOL)).
C                 13 = IV(IRC) WAS OUT OF RANGE ON INPUT.
C             RETURN CODE I HAS PRECDENCE OVER I+1 FOR I = 9, 10, 11.
C IV(MLSTGD) (I/O) SAVED VALUE OF IV(MODEL).
C  IV(MODEL) (I/O) ON INPUT, IV(MODEL) SHOULD BE AN INTEGER IDENTIFYING
C             THE CURRENT QUADRATIC MODEL OF THE OBJECTIVE FUNCTION.
C             IF A PREVIOUS STEP YIELDED A BETTER FUNCTION REDUCTION,
C             THEN IV(MODEL) WILL BE SET TO IV(MLSTGD) ON OUTPUT.
C IV(NFCALL) (IN)  INVOCATION COUNT FOR THE OBJECTIVE FUNCTION.
C IV(NFGCAL) (I/O) VALUE OF IV(NFCALL) AT STEP THAT GAVE THE BIGGEST
C             FUNCTION REDUCTION THIS ITERATION.  IV(NFGCAL) REMAINS
C             UNCHANGED UNTIL A FUNCTION REDUCTION IS OBTAINED.
C IV(RADINC) (I/O) THE NUMBER OF RADIUS INCREASES (OR MINUS THE NUMBER
C             OF DECREASES) SO FAR THIS ITERATION.
C IV(RESTOR) (OUT) SET TO 0 UNLESS X AND V(F) HAVE BEEN RESTORED, IN
C             WHICH CASE ASSESS SETS IV(RESTOR) = 1.
C  IV(STAGE) (I/O) COUNT OF THE NUMBER OF MODELS TRIED SO FAR IN THE
C             CURRENT ITERATION.
C IV(STGLIM) (IN)  MAXIMUM NUMBER OF MODELS TO CONSIDER.
C IV(SWITCH) (OUT) SET TO 0 UNLESS A NEW MODEL IS BEING TRIED AND IT
C             GIVES A SMALLER FUNCTION VALUE THAN THE PREVIOUS MODEL,
C             IN WHICH CASE ASSESS SETS IV(SWITCH) = 1.
C IV(TOOBIG) (IN)  IS NONZERO IF STEP WAS TOO BIG (E.G. IF IT CAUSED
C             OVERFLOW).
C   IV(XIRC) (I/O) VALUE THAT IV(IRC) WOULD HAVE IN THE ABSENCE OF
C             CONVERGENCE, FALSE CONVERGENCE, AND OVERSIZED STEPS.
C
C  ***  V VALUES REFERENCED  ***
C
C V(AFCTOL) (IN)  ABSOLUTE FUNCTION CONVERGENCE TOLERANCE.  IF THE
C             ABSOLUTE VALUE OF THE CURRENT FUNCTION VALUE V(F) IS LESS
C             THAN V(AFCTOL), THEN ASSESS RETURNS WITH IV(IRC) = 10.
C V(DECFAC) (IN)  FACTOR BY WHICH TO DECREASE RADIUS WHEN IV(TOOBIG) IS
C             NONZERO.
C V(DSTNRM) (IN)  THE 2-NORM OF D*STEP.
C V(DSTSAV) (I/O) VALUE OF V(DSTNRM) ON SAVED STEP.
C   V(DST0) (IN)  THE 2-NORM OF D TIMES THE NEWTON STEP (WHEN DEFINED,
C             I.E., FOR V(NREDUC) .GE. 0).
C      V(F) (I/O) ON BOTH INPUT AND OUTPUT, V(F) IS THE OBJECTIVE FUNC-
C             TION VALUE AT X.  IF X IS RESTORED TO A PREVIOUS VALUE,
C             THEN V(F) IS RESTORED TO THE CORRESPONDING VALUE.
C   V(FDIF) (OUT) THE FUNCTION REDUCTION V(F0) - V(F) (FOR THE OUTPUT
C             VALUE OF V(F) IF AN EARLIER STEP GAVE A BIGGER FUNCTION
C             DECREASE, AND FOR THE INPUT VALUE OF V(F) OTHERWISE).
C V(FLSTGD) (I/O) SAVED VALUE OF V(F).
C     V(F0) (IN)  OBJECTIVE FUNCTION VALUE AT START OF ITERATION.
C V(GTSLST) (I/O) VALUE OF V(GTSTEP) ON SAVED STEP.
C V(GTSTEP) (IN)  INNER PRODUCT BETWEEN STEP AND GRADIENT.
C V(INCFAC) (IN)  MINIMUM FACTOR BY WHICH TO INCREASE RADIUS.
C  V(LMAXS) (IN)  MAXIMUM REASONABLE STEP SIZE (AND INITIAL STEP BOUND).
C             IF THE ACTUAL FUNCTION DECREASE IS NO MORE THAN TWICE
C             WHAT WAS PREDICTED, IF A RETURN WITH IV(IRC) = 7, 8, 9,
C             OR 10 DOES NOT OCCUR, IF V(DSTNRM) .GT. V(LMAXS), AND IF
C             V(PREDUC) .LE. V(SCTOL) * ABS(V(F0)), THEN ASSESS RE-
C             TURNS WITH IV(IRC) = 11.  IF SO DOING APPEARS WORTHWHILE,
C             THEN ASSESS REPEATS THIS TEST WITH V(PREDUC) COMPUTED FOR
C             A STEP OF LENGTH V(LMAXS) (BY A RETURN WITH IV(IRC) = 6).
C V(NREDUC) (I/O)  FUNCTION REDUCTION PREDICTED BY QUADRATIC MODEL FOR
C             NEWTON STEP.  IF ASSESS IS CALLED WITH IV(IRC) = 6, I.E.,
C             IF V(PREDUC) HAS BEEN COMPUTED WITH RADIUS = V(LMAXS) FOR
C             USE IN THE SINGULAR CONVERVENCE TEST, THEN V(NREDUC) IS
C             SET TO -V(PREDUC) BEFORE THE LATTER IS RESTORED.
C V(PLSTGD) (I/O) VALUE OF V(PREDUC) ON SAVED STEP.
C V(PREDUC) (I/O) FUNCTION REDUCTION PREDICTED BY QUADRATIC MODEL FOR
C             CURRENT STEP.
C V(RADFAC) (OUT) FACTOR TO BE USED IN DETERMINING THE NEW RADIUS,
C             WHICH SHOULD BE V(RADFAC)*DST, WHERE  DST  IS EITHER THE
C             OUTPUT VALUE OF V(DSTNRM) OR THE 2-NORM OF
C             DIAG(NEWD)*STEP  FOR THE OUTPUT VALUE OF STEP AND THE
C             UPDATED VERSION, NEWD, OF THE SCALE VECTOR D.  FOR
C             IV(IRC) = 3, V(RADFAC) = 1.0 IS RETURNED.
C V(RDFCMN) (IN)  MINIMUM VALUE FOR V(RADFAC) IN TERMS OF THE INPUT
C             VALUE OF V(DSTNRM) -- SUGGESTED VALUE = 0.1.
C V(RDFCMX) (IN)  MAXIMUM VALUE FOR V(RADFAC) -- SUGGESTED VALUE = 4.0.
C  V(RELDX) (OUT) SCALED RELATIVE CHANGE IN X CAUSED BY STEP, COMPUTED
C             BY FUNCTION  DRELST  AS
C                 MAX (D(I)*ABS(X(I)-X0(I)), 1 .LE. I .LE. P) /
C                    MAX (D(I)*(ABS(X(I))+ABS(X0(I))), 1 .LE. I .LE. P).
C             IF AN ACCEPTABLE STEP IS RETURNED, THEN V(RELDX) IS COM-
C             PUTED USING THE OUTPUT (POSSIBLY RESTORED) VALUES OF X
C             AND STEP.  OTHERWISE IT IS COMPUTED USING THE INPUT
C             VALUES.
C V(RFCTOL) (IN)  RELATIVE FUNCTION CONVERGENCE TOLERANCE.  IF THE
C             ACTUAL FUNCTION REDUCTION IS AT MOST TWICE WHAT WAS PRE-
C             DICTED AND  V(NREDUC) .LE. V(RFCTOL)*ABS(V(F0)),  THEN
C             ASSESS RETURNS WITH IV(IRC) = 8 OR 9.
C V(STPPAR) (IN)  MARQUARDT PARAMETER -- 0 MEANS FULL NEWTON STEP.
C V(TUNER1) (IN)  TUNING CONSTANT USED TO DECIDE IF THE FUNCTION
C             REDUCTION WAS MUCH LESS THAN EXPECTED.  SUGGESTED
C             VALUE = 0.1.
C V(TUNER2) (IN)  TUNING CONSTANT USED TO DECIDE IF THE FUNCTION
C             REDUCTION WAS LARGE ENOUGH TO ACCEPT STEP.  SUGGESTED
C             VALUE = 10**-4.
C V(TUNER3) (IN)  TUNING CONSTANT USED TO DECIDE IF THE RADIUS
C             SHOULD BE INCREASED.  SUGGESTED VALUE = 0.75.
C  V(XCTOL) (IN)  X-CONVERGENCE CRITERION.  IF STEP IS A NEWTON STEP
C             (V(STPPAR) = 0) HAVING V(RELDX) .LE. V(XCTOL) AND GIVING
C             AT MOST TWICE THE PREDICTED FUNCTION DECREASE, THEN
C             ASSESS RETURNS IV(IRC) = 7 OR 9.
C  V(XFTOL) (IN)  FALSE CONVERGENCE TOLERANCE.  IF STEP GAVE NO OR ONLY
C             A SMALL FUNCTION DECREASE AND V(RELDX) .LE. V(XFTOL),
C             THEN ASSESS RETURNS WITH IV(IRC) = 12.
C
C-------------------------------  NOTES  -------------------------------
C
C  ***  APPLICATION AND USAGE RESTRICTIONS  ***
C
C        THIS ROUTINE IS CALLED AS PART OF THE NL2SOL (NONLINEAR
C     LEAST-SQUARES) PACKAGE.  IT MAY BE USED IN ANY UNCONSTRAINED
C     MINIMIZATION SOLVER THAT USES DOGLEG, GOLDFELD-QUANDT-TROTTER,
C     OR LEVENBERG-MARQUARDT STEPS.
C
C  ***  ALGORITHM NOTES  ***
C
C        SEE (1) FOR FURTHER DISCUSSION OF THE ASSESSING AND MODEL
C     SWITCHING STRATEGIES.  WHILE NL2SOL CONSIDERS ONLY TWO MODELS,
C     ASSESS IS DESIGNED TO HANDLE ANY NUMBER OF MODELS.
C
C  ***  USAGE NOTES  ***
C
C        ON THE FIRST CALL OF AN ITERATION, ONLY THE I/O VARIABLES
C     STEP, X, IV(IRC), IV(MODEL), V(F), V(DSTNRM), V(GTSTEP), AND
C     V(PREDUC) NEED HAVE BEEN INITIALIZED.  BETWEEN CALLS, NO I/O
C     VALUES EXECPT STEP, X, IV(MODEL), V(F) AND THE STOPPING TOLER-
C     ANCES SHOULD BE CHANGED.
C        AFTER A RETURN FOR CONVERGENCE OR FALSE CONVERGENCE, ONE CAN
C     CHANGE THE STOPPING TOLERANCES AND CALL ASSESS AGAIN, IN WHICH
C     CASE THE STOPPING TESTS WILL BE REPEATED.
C
C  ***  REFERENCES  ***
C
C     (1) DENNIS, J.E., JR., GAY, D.M., AND WELSCH, R.E. (1981),
C        AN ADAPTIVE NONLINEAR LEAST-SQUARES ALGORITHM,
C        ACM TRANS. MATH. SOFTWARE, VOL. 7, NO. 3.
C
C     (2) POWELL, M.J.D. (1970)  A FORTRAN SUBROUTINE FOR SOLVING
C        SYSTEMS OF NONLINEAR ALGEBRAIC EQUATIONS, IN NUMERICAL
C        METHODS FOR NONLINEAR ALGEBRAIC EQUATIONS, EDITED BY
C        P. RABINOWITZ, GORDON AND BREACH, LONDON.
C
C  ***  HISTORY  ***
C
C        JOHN DENNIS DESIGNED MUCH OF THIS ROUTINE, STARTING WITH
C     IDEAS IN (2). ROY WELSCH SUGGESTED THE MODEL SWITCHING STRATEGY.
C        DAVID GAY AND STEPHEN PETERS CAST THIS SUBROUTINE INTO A MORE
C     PORTABLE FORM (WINTER 1977), AND DAVID GAY CAST IT INTO ITS
C     PRESENT FORM (FALL 1978).
C
C  ***  GENERAL  ***
C
C     THIS SUBROUTINE WAS WRITTEN IN CONNECTION WITH RESEARCH
C     SUPPORTED BY THE NATIONAL SCIENCE FOUNDATION UNDER GRANTS
C     MCS-7600324, DCR75-10143, 76-14311DSS, MCS76-11989, AND
C     MCS-7906671.
C
C------------------------  EXTERNAL QUANTITIES  ------------------------
C
C  ***  EXTERNAL FUNCTIONS AND SUBROUTINES  ***
C
      EXTERNAL DRELST
      DOUBLE PRECISION DRELST
C
C DRELST... COMPUTES V(RELDX) = RELATIVE STEP SIZE.
C
C  ***  INTRINSIC FUNCTIONS  ***
C/+
      DOUBLE PRECISION DABS, DMAX1
C/
C  ***  NO COMMON BLOCKS  ***
C
C--------------------------  LOCAL VARIABLES  --------------------------
C
      LOGICAL GOODX
      INTEGER I, NFC
      DOUBLE PRECISION EMAX, EMAXS, GTS, HALF, ONE, RELDX1, RFAC1, TWO,
     1                 XMAX, ZERO
C
C  ***  SUBSCRIPTS FOR IV AND V  ***
C
      INTEGER AFCTOL, DECFAC, DSTNRM, DSTSAV, DST0, F, FDIF, FLSTGD, F0,
     1        GTSLST, GTSTEP, INCFAC, IRC, LMAXS, MLSTGD, MODEL, NFCALL,
     2        NFGCAL, NREDUC, PLSTGD, PREDUC, RADFAC, RADINC, RDFCMN,
     3        RDFCMX, RELDX, RESTOR, RFCTOL, SCTOL, STAGE, STGLIM,
     4        STPPAR, SWITCH, TOOBIG, TUNER1, TUNER2, TUNER3, XCTOL,
     5        XFTOL, XIRC
C
C  ***  DATA INITIALIZATIONS  ***
C
C/6
      DATA HALF/0.5D+0/, ONE/1.D+0/, TWO/2.D+0/, ZERO/0.D+0/
C/7
C     PARAMETER (HALF=0.5D+0, ONE=1.D+0, TWO=2.D+0, ZERO=0.D+0)
C/
C
C/6
      DATA IRC/29/, MLSTGD/32/, MODEL/5/, NFCALL/6/, NFGCAL/7/,
     1     RADINC/8/, RESTOR/9/, STAGE/10/, STGLIM/11/, SWITCH/12/,
     2     TOOBIG/2/, XIRC/13/
C/7
C     PARAMETER (IRC=29, MLSTGD=32, MODEL=5, NFCALL=6, NFGCAL=7,
C    1           RADINC=8, RESTOR=9, STAGE=10, STGLIM=11, SWITCH=12,
C    2           TOOBIG=2, XIRC=13)
C/
C/6
      DATA AFCTOL/31/, DECFAC/22/, DSTNRM/2/, DST0/3/, DSTSAV/18/,
     1     F/10/, FDIF/11/, FLSTGD/12/, F0/13/, GTSLST/14/, GTSTEP/4/,
     2     INCFAC/23/, LMAXS/36/, NREDUC/6/, PLSTGD/15/, PREDUC/7/,
     3     RADFAC/16/, RDFCMN/24/, RDFCMX/25/, RELDX/17/, RFCTOL/32/,
     4     SCTOL/37/, STPPAR/5/, TUNER1/26/, TUNER2/27/, TUNER3/28/,
     5     XCTOL/33/, XFTOL/34/
C/7
C     PARAMETER (AFCTOL=31, DECFAC=22, DSTNRM=2, DST0=3, DSTSAV=18,
C    1           F=10, FDIF=11, FLSTGD=12, F0=13, GTSLST=14, GTSTEP=4,
C    2           INCFAC=23, LMAXS=36, NREDUC=6, PLSTGD=15, PREDUC=7,
C    3           RADFAC=16, RDFCMN=24, RDFCMX=25, RELDX=17, RFCTOL=32,
C    4           SCTOL=37, STPPAR=5, TUNER1=26, TUNER2=27, TUNER3=28,
C    5           XCTOL=33, XFTOL=34)
C/
C
C+++++++++++++++++++++++++++++++  BODY  ++++++++++++++++++++++++++++++++
C
      NFC = IV(NFCALL)
      IV(SWITCH) = 0
      IV(RESTOR) = 0
      RFAC1 = ONE
      GOODX = .TRUE.
      I = IV(IRC)
      IF (I .GE. 1 .AND. I .LE. 12)
     1             GO TO (20,30,10,10,40,280,220,220,220,220,220,170), I
         IV(IRC) = 13
         GO TO 999
C
C  ***  INITIALIZE FOR NEW ITERATION  ***
C
 10   IV(STAGE) = 1
      IV(RADINC) = 0
      V(FLSTGD) = V(F0)
      IF (IV(TOOBIG) .EQ. 0) GO TO 90
         IV(STAGE) = -1
         IV(XIRC) = I
         GO TO 60
C
C  ***  STEP WAS RECOMPUTED WITH NEW MODEL OR SMALLER RADIUS  ***
C  ***  FIRST DECIDE WHICH  ***
C
 20   IF (IV(MODEL) .NE. IV(MLSTGD)) GO TO 30
C        ***  OLD MODEL RETAINED, SMALLER RADIUS TRIED  ***
C        ***  DO NOT CONSIDER ANY MORE NEW MODELS THIS ITERATION  ***
         IV(STAGE) = IV(STGLIM)
         IV(RADINC) = -1
         GO TO 90
C
C  ***  A NEW MODEL IS BEING TRIED.  DECIDE WHETHER TO KEEP IT.  ***
C
 30   IV(STAGE) = IV(STAGE) + 1
C
C     ***  NOW WE ADD THE POSSIBILTIY THAT STEP WAS RECOMPUTED WITH  ***
C     ***  THE SAME MODEL, PERHAPS BECAUSE OF AN OVERSIZED STEP.     ***
C
 40   IF (IV(STAGE) .GT. 0) GO TO 50
C
C        ***  STEP WAS RECOMPUTED BECAUSE IT WAS TOO BIG.  ***
C
         IF (IV(TOOBIG) .NE. 0) GO TO 60
C
C        ***  RESTORE IV(STAGE) AND PICK UP WHERE WE LEFT OFF.  ***
C
         IV(STAGE) = -IV(STAGE)
         I = IV(XIRC)
         GO TO (20, 30, 90, 90, 70), I
C
 50   IF (IV(TOOBIG) .EQ. 0) GO TO 70
C
C  ***  HANDLE OVERSIZE STEP  ***
C
      IF (IV(RADINC) .GT. 0) GO TO 80
         IV(STAGE) = -IV(STAGE)
         IV(XIRC) = IV(IRC)
C
 60      V(RADFAC) = V(DECFAC)
         IV(RADINC) = IV(RADINC) - 1
         IV(IRC) = 5
         GO TO 999
C
 70   IF (V(F) .LT. V(FLSTGD)) GO TO 90
C
C     *** THE NEW STEP IS A LOSER.  RESTORE OLD MODEL.  ***
C
      IF (IV(MODEL) .EQ. IV(MLSTGD)) GO TO 80
         IV(MODEL) = IV(MLSTGD)
         IV(SWITCH) = 1
C
C     ***  RESTORE STEP, ETC. ONLY IF A PREVIOUS STEP DECREASED V(F).
C
 80   IF (V(FLSTGD) .GE. V(F0)) GO TO 90
         IV(RESTOR) = 1
         V(F) = V(FLSTGD)
         V(PREDUC) = V(PLSTGD)
         V(GTSTEP) = V(GTSLST)
         IF (IV(SWITCH) .EQ. 0) RFAC1 = V(DSTNRM) / V(DSTSAV)
         V(DSTNRM) = V(DSTSAV)
         NFC = IV(NFGCAL)
         GOODX = .FALSE.
C
C
C  ***  COMPUTE RELATIVE CHANGE IN X BY CURRENT STEP  ***
C
 90   RELDX1 = DRELST(P, D, X, X0)
C
C  ***  RESTORE X AND STEP IF NECESSARY  ***
C
      IF (GOODX) GO TO 110
      DO 100 I = 1, P
         STEP(I) = STLSTG(I)
         X(I) = X0(I) + STLSTG(I)
 100     CONTINUE
C
 110  V(FDIF) = V(F0) - V(F)
      IF (V(FDIF) .GT. V(TUNER2) * V(PREDUC)) GO TO 140
C
C        ***  NO (OR ONLY A TRIVIAL) FUNCTION DECREASE
C        ***  -- SO TRY NEW MODEL OR SMALLER RADIUS
C
         V(RELDX) = RELDX1
         IF (V(F) .LT. V(F0)) GO TO 120
              IV(MLSTGD) = IV(MODEL)
              V(FLSTGD) = V(F)
              V(F) = V(F0)
              CALL DCOPY(P,X0,1,X,1)
              IV(RESTOR) = 1
              GO TO 130
 120     IV(NFGCAL) = NFC
 130     IV(IRC) = 1
         IF (IV(STAGE) .LT. IV(STGLIM)) GO TO 160
              IV(IRC) = 5
              IV(RADINC) = IV(RADINC) - 1
              GO TO 160
C
C  ***  NONTRIVIAL FUNCTION DECREASE ACHIEVED  ***
C
 140  IV(NFGCAL) = NFC
      RFAC1 = ONE
      IF (GOODX) V(RELDX) = RELDX1
      V(DSTSAV) = V(DSTNRM)
      IF (V(FDIF) .GT. V(PREDUC)*V(TUNER1)) GO TO 190
C
C  ***  DECREASE WAS MUCH LESS THAN PREDICTED -- EITHER CHANGE MODELS
C  ***  OR ACCEPT STEP WITH DECREASED RADIUS.
C
      IF (IV(STAGE) .GE. IV(STGLIM)) GO TO 150
C        ***  CONSIDER SWITCHING MODELS  ***
         IV(IRC) = 2
         GO TO 160
C
C     ***  ACCEPT STEP WITH DECREASED RADIUS  ***
C
 150  IV(IRC) = 4
C
C  ***  SET V(RADFAC) TO FLETCHER*S DECREASE FACTOR  ***
C
 160  IV(XIRC) = IV(IRC)
      EMAX = V(GTSTEP) + V(FDIF)
      V(RADFAC) = HALF * RFAC1
      IF (EMAX .LT. V(GTSTEP)) V(RADFAC) = RFAC1 * DMAX1(V(RDFCMN),
     1                                           HALF * V(GTSTEP)/EMAX)
C
C  ***  DO FALSE CONVERGENCE TEST  ***
C
 170  IF (V(RELDX) .LE. V(XFTOL)) GO TO 180
         IV(IRC) = IV(XIRC)
         IF (V(F) .LT. V(F0)) GO TO 200
              GO TO 230
C
 180  IV(IRC) = 12
      GO TO 240
C
C  ***  HANDLE GOOD FUNCTION DECREASE  ***
C
 190  IF (V(FDIF) .LT. (-V(TUNER3) * V(GTSTEP))) GO TO 210
C
C     ***  INCREASING RADIUS LOOKS WORTHWHILE.  SEE IF WE JUST
C     ***  RECOMPUTED STEP WITH A DECREASED RADIUS OR RESTORED STEP
C     ***  AFTER RECOMPUTING IT WITH A LARGER RADIUS.
C
      IF (IV(RADINC) .LT. 0) GO TO 210
      IF (IV(RESTOR) .EQ. 1) GO TO 210
C
C        ***  WE DID NOT.  TRY A LONGER STEP UNLESS THIS WAS A NEWTON
C        ***  STEP.
C
         V(RADFAC) = V(RDFCMX)
         GTS = V(GTSTEP)
         IF (V(FDIF) .LT. (HALF/V(RADFAC) - ONE) * GTS)
     1            V(RADFAC) = DMAX1(V(INCFAC), HALF*GTS/(GTS + V(FDIF)))
         IV(IRC) = 4
         IF (V(STPPAR) .EQ. ZERO) GO TO 230
C             ***  STEP WAS NOT A NEWTON STEP.  RECOMPUTE IT WITH
C             ***  A LARGER RADIUS.
              IV(IRC) = 5
              IV(RADINC) = IV(RADINC) + 1
C
C  ***  SAVE VALUES CORRESPONDING TO GOOD STEP  ***
C
 200  V(FLSTGD) = V(F)
      IV(MLSTGD) = IV(MODEL)
      CALL DCOPY(P, STEP,1,STLSTG,1)
      V(DSTSAV) = V(DSTNRM)
      IV(NFGCAL) = NFC
      V(PLSTGD) = V(PREDUC)
      V(GTSLST) = V(GTSTEP)
      GO TO 230
C
C  ***  ACCEPT STEP WITH RADIUS UNCHANGED  ***
C
 210  V(RADFAC) = ONE
      IV(IRC) = 3
      GO TO 230
C
C  ***  COME HERE FOR A RESTART AFTER CONVERGENCE  ***
C
 220  IV(IRC) = IV(XIRC)
      IF (V(DSTSAV) .GE. ZERO) GO TO 240
         IV(IRC) = 12
         GO TO 240
C
C  ***  PERFORM CONVERGENCE TESTS  ***
C
 230  IV(XIRC) = IV(IRC)
 240  IF (DABS(V(F)) .LT. V(AFCTOL)) IV(IRC) = 10
      IF (HALF * V(FDIF) .GT. V(PREDUC)) GO TO 999
      EMAX = V(RFCTOL) * DABS(V(F0))
      EMAXS = V(SCTOL) * DABS(V(F0))
      IF (V(DSTNRM) .GT. V(LMAXS) .AND. V(PREDUC) .LE. EMAXS)
     1                       IV(IRC) = 11
      IF (V(DST0) .LT. ZERO) GO TO 250
      I = 0
      IF ((V(NREDUC) .GT. ZERO .AND. V(NREDUC) .LE. EMAX) .OR.
     1    (V(NREDUC) .EQ. ZERO. AND. V(PREDUC) .EQ. ZERO))  I = 2
      IF (V(STPPAR) .EQ. ZERO .AND. V(RELDX) .LE. V(XCTOL)
     1                        .AND. GOODX)                  I = I + 1
      IF (I .GT. 0) IV(IRC) = I + 6
C
C  ***  CONSIDER RECOMPUTING STEP OF LENGTH V(LMAXS) FOR SINGULAR
C  ***  CONVERGENCE TEST.
C
 250  IF (IV(IRC) .GT. 5 .AND. IV(IRC) .NE. 12) GO TO 999
      IF (V(DSTNRM) .GT. V(LMAXS)) GO TO 260
         IF (V(PREDUC) .GE. EMAXS) GO TO 999
              IF (V(DST0) .LE. ZERO) GO TO 270
                   IF (HALF * V(DST0) .LE. V(LMAXS)) GO TO 999
                        GO TO 270
 260  IF (HALF * V(DSTNRM) .LE. V(LMAXS)) GO TO 999
      XMAX = V(LMAXS) / V(DSTNRM)
      IF (XMAX * (TWO - XMAX) * V(PREDUC) .GE. EMAXS) GO TO 999
 270  IF (V(NREDUC) .LT. ZERO) GO TO 290
C
C  ***  RECOMPUTE V(PREDUC) FOR USE IN SINGULAR CONVERGENCE TEST  ***
C
      V(GTSLST) = V(GTSTEP)
      V(DSTSAV) = V(DSTNRM)
      IF (IV(IRC) .EQ. 12) V(DSTSAV) = -V(DSTSAV)
      V(PLSTGD) = V(PREDUC)
      IV(IRC) = 6
      CALL DCOPY(P, STEP,1,STLSTG,1)
      GO TO 999
C
C  ***  PERFORM SINGULAR CONVERGENCE TEST WITH RECOMPUTED V(PREDUC)  ***
C
 280  V(GTSTEP) = V(GTSLST)
      V(DSTNRM) = DABS(V(DSTSAV))
      CALL DCOPY(P, STLSTG,1,STEP,1)
      IV(IRC) = IV(XIRC)
      IF (V(DSTSAV) .LE. ZERO) IV(IRC) = 12
      V(NREDUC) = -V(PREDUC)
      V(PREDUC) = V(PLSTGD)
 290  IF (-V(NREDUC) .LE. V(RFCTOL) * DABS(V(F0))) IV(IRC) = 11
C
 999  RETURN
C
C  ***  LAST CARD OF ASSESS FOLLOWS  ***
      END
      SUBROUTINE DCOPY(N,DX,INCX,DY,INCY)
      save
C***BEGIN PROLOGUE  DCOPY
C***DATE WRITTEN   791001   (YYMMDD)
C***REVISION DATE  820801   (YYMMDD)
C***CATEGORY NO.  D1A5
C***KEYWORDS  BLAS,COPY,DOUBLE PRECISION,LINEAR ALGEBRA,VECTOR
C***AUTHOR  LAWSON, C. L., (JPL)
C           HANSON, R. J., (SNLA)
C           KINCAID, D. R., (U. OF TEXAS)
C           KROGH, F. T., (JPL)
C***PURPOSE  D.P. vector copy y = x
C***DESCRIPTION
C
C                B L A S  Subprogram
C    Description of Parameters
C
C     --Input--
C        N  number of elements in input vector(s)
C       DX  double precision vector with N elements
C     INCX  storage spacing between elements of DX
C       DY  double precision vector with N elements
C     INCY  storage spacing between elements of DY
C
C     --Output--
C       DY  copy of vector DX (unchanged if N .LE. 0)
C
C     Copy double precision DX to double precision DY.
C     For I = 0 to N-1, copy DX(LX+I*INCX) to DY(LY+I*INCY),
C     where LX = 1 if INCX .GE. 0, else LX = (-INCX)*N, and LY is
C     defined in a similar way using INCY.
C***REFERENCES  LAWSON C.L., HANSON R.J., KINCAID D.R., KROGH F.T.,
C                 *BASIC LINEAR ALGEBRA SUBPROGRAMS FOR FORTRAN USAGE*,
C                 ALGORITHM NO. 539, TRANSACTIONS ON MATHEMATICAL
C                 SOFTWARE, VOLUME 5, NUMBER 3, SEPTEMBER 1979, 308-323
C***ROUTINES CALLED  (NONE)
C***END PROLOGUE  DCOPY
C
      DOUBLE PRECISION DX(1),DY(1)
C***FIRST EXECUTABLE STATEMENT  DCOPY
      IF(N.LE.0)RETURN
      IF(INCX.EQ.INCY) IF(INCX-1) 5,20,60
    5 CONTINUE
C
C        CODE FOR UNEQUAL OR NONPOSITIVE INCREMENTS.
C
      IX = 1
      IY = 1
      IF(INCX.LT.0)IX = (-N+1)*INCX + 1
      IF(INCY.LT.0)IY = (-N+1)*INCY + 1
      DO 10 I = 1,N
        DY(IY) = DX(IX)
        IX = IX + INCX
        IY = IY + INCY
   10 CONTINUE
      RETURN
C
C        CODE FOR BOTH INCREMENTS EQUAL TO 1
C
C
C        CLEAN-UP LOOP SO REMAINING VECTOR LENGTH IS A MULTIPLE OF 7.
C
   20 M = MOD(N,7)
      IF( M .EQ. 0 ) GO TO 40
      DO 30 I = 1,M
        DY(I) = DX(I)
   30 CONTINUE
      IF( N .LT. 7 ) RETURN
   40 MP1 = M + 1
      DO 50 I = MP1,N,7
        DY(I) = DX(I)
        DY(I + 1) = DX(I + 1)
        DY(I + 2) = DX(I + 2)
        DY(I + 3) = DX(I + 3)
        DY(I + 4) = DX(I + 4)
        DY(I + 5) = DX(I + 5)
        DY(I + 6) = DX(I + 6)
   50 CONTINUE
      RETURN
C
C        CODE FOR EQUAL, POSITIVE, NONUNIT INCREMENTS.
C
   60 CONTINUE
      NS=N*INCX
          DO 70 I=1,NS,INCX
          DY(I) = DX(I)
   70     CONTINUE
      RETURN
      END
      SUBROUTINE DDBDOG(DIG, G, LV, N, NWTSTP, STEP, V)
      save
C
C  ***  COMPUTE DOUBLE DOGLEG STEP  ***
C
C  ***  PARAMETER DECLARATIONS  ***
C
      INTEGER LV, N
      DOUBLE PRECISION DIG(N), G(N), NWTSTP(N), STEP(N), V(LV)
C
C  ***  PURPOSE  ***
C
C        THIS SUBROUTINE COMPUTES A CANDIDATE STEP (FOR USE IN AN UNCON-
C     STRAINED MINIMIZATION CODE) BY THE DOUBLE DOGLEG ALGORITHM OF
C     DENNIS AND MEI (REF. 1), WHICH IS A VARIATION ON POWELL*S DOGLEG
C     SCHEME (REF. 2, P. 95).
C
C--------------------------  PARAMETER USAGE  --------------------------
C
C    DIG (INPUT) DIAG(D)**-2 * G -- SEE ALGORITHM NOTES.
C      G (INPUT) THE CURRENT GRADIENT VECTOR.
C     LV (INPUT) LENGTH OF V.
C      N (INPUT) NUMBER OF COMPONENTS IN  DIG, G, NWTSTP,  AND  STEP.
C NWTSTP (INPUT) NEGATIVE NEWTON STEP -- SEE ALGORITHM NOTES.
C   STEP (OUTPUT) THE COMPUTED STEP.
C      V (I/O) VALUES ARRAY, THE FOLLOWING COMPONENTS OF WHICH ARE
C             USED HERE...
C V(BIAS)   (INPUT) BIAS FOR RELAXED NEWTON STEP, WHICH IS V(BIAS) OF
C             THE WAY FROM THE FULL NEWTON TO THE FULLY RELAXED NEWTON
C             STEP.  RECOMMENDED VALUE = 0.8 .
C V(DGNORM) (INPUT) 2-NORM OF DIAG(D)**-1 * G -- SEE ALGORITHM NOTES.
C V(DSTNRM) (OUTPUT) 2-NORM OF DIAG(D) * STEP, WHICH IS V(RADIUS)
C             UNLESS V(STPPAR) = 0 -- SEE ALGORITHM NOTES.
C V(DST0) (INPUT) 2-NORM OF DIAG(D) * NWTSTP -- SEE ALGORITHM NOTES.
C V(GRDFAC) (OUTPUT) THE COEFFICIENT OF  DIG  IN THE STEP RETURNED --
C             STEP(I) = V(GRDFAC)*DIG(I) + V(NWTFAC)*NWTSTP(I).
C V(GTHG)   (INPUT) SQUARE-ROOT OF (DIG**T) * (HESSIAN) * DIG -- SEE
C             ALGORITHM NOTES.
C V(GTSTEP) (OUTPUT) INNER PRODUCT BETWEEN G AND STEP.
C V(NREDUC) (OUTPUT) FUNCTION REDUCTION PREDICTED FOR THE FULL NEWTON
C             STEP.
C V(NWTFAC) (OUTPUT) THE COEFFICIENT OF  NWTSTP  IN THE STEP RETURNED --
C             SEE V(GRDFAC) ABOVE.
C V(PREDUC) (OUTPUT) FUNCTION REDUCTION PREDICTED FOR THE STEP RETURNED.
C V(RADIUS) (INPUT) THE TRUST REGION RADIUS.  D TIMES THE STEP RETURNED
C             HAS 2-NORM V(RADIUS) UNLESS V(STPPAR) = 0.
C V(STPPAR) (OUTPUT) CODE TELLING HOW STEP WAS COMPUTED... 0 MEANS A
C             FULL NEWTON STEP.  BETWEEN 0 AND 1 MEANS V(STPPAR) OF THE
C             WAY FROM THE NEWTON TO THE RELAXED NEWTON STEP.  BETWEEN
C             1 AND 2 MEANS A TRUE DOUBLE DOGLEG STEP, V(STPPAR) - 1 OF
C             THE WAY FROM THE RELAXED NEWTON TO THE CAUCHY STEP.
C             GREATER THAN 2 MEANS 1 / (V(STPPAR) - 1) TIMES THE CAUCHY
C             STEP.
C
C-------------------------------  NOTES  -------------------------------
C
C  ***  ALGORITHM NOTES  ***
C
C        LET  G  AND  H  BE THE CURRENT GRADIENT AND HESSIAN APPROXIMA-
C     TION RESPECTIVELY AND LET D BE THE CURRENT SCALE VECTOR.  THIS
C     ROUTINE ASSUMES DIG = DIAG(D)**-2 * G  AND  NWTSTP = H**-1 * G.
C     THE STEP COMPUTED IS THE SAME ONE WOULD GET BY REPLACING G AND H
C     BY  DIAG(D)**-1 * G  AND  DIAG(D)**-1 * H * DIAG(D)**-1,
C     COMPUTING STEP, AND TRANSLATING STEP BACK TO THE ORIGINAL
C     VARIABLES, I.E., PREMULTIPLYING IT BY DIAG(D)**-1.
C
C  ***  REFERENCES  ***
C
C 1.  DENNIS, J.E., AND MEI, H.H.W. (1979), TWO NEW UNCONSTRAINED OPTI-
C             MIZATION ALGORITHMS WHICH USE FUNCTION AND GRADIENT
C             VALUES, J. OPTIM. THEORY APPLIC. 28, PP. 453-482.
C 2. POWELL, M.J.D. (1970), A HYBRID METHOD FOR NON-LINEAR EQUATIONS,
C             IN NUMERICAL METHODS FOR NON-LINEAR EQUATIONS, EDITED BY
C             P. RABINOWITZ, GORDON AND BREACH, LONDON.
C
C  ***  GENERAL  ***
C
C     CODED BY DAVID M. GAY.
C     THIS SUBROUTINE WAS WRITTEN IN CONNECTION WITH RESEARCH SUPPORTED
C     BY THE NATIONAL SCIENCE FOUNDATION UNDER GRANTS MCS-7600324 AND
C     MCS-7906671.
C
C------------------------  EXTERNAL QUANTITIES  ------------------------
C
C  ***  FUNCTIONS AND SUBROUTINES CALLED  ***
C
      DOUBLE PRECISION DDOT
C
C
C  ***  INTRINSIC FUNCTIONS  ***
C/+
      DOUBLE PRECISION DSQRT
C/
C--------------------------  LOCAL VARIABLES  --------------------------
C
      INTEGER I
      DOUBLE PRECISION CFACT, CNORM, CTRNWT, GHINVG, FEMNSQ, GNORM,
     1                 NWTNRM, RELAX, RLAMBD, T, T1, T2
      DOUBLE PRECISION HALF, ONE, TWO, ZERO
C
C  ***  V SUBSCRIPTS  ***
C
      INTEGER BIAS, DGNORM, DSTNRM, DST0, GRDFAC, GTHG, GTSTEP,
     1        NREDUC, NWTFAC, PREDUC, RADIUS, STPPAR
C
C  ***  DATA INITIALIZATIONS  ***
C
C/6
      DATA HALF/0.5D+0/, ONE/1.D+0/, TWO/2.D+0/, ZERO/0.D+0/
C/7
C     PARAMETER (HALF=0.5D+0, ONE=1.D+0, TWO=2.D+0, ZERO=0.D+0)
C/
C
C/6
      DATA BIAS/43/, DGNORM/1/, DSTNRM/2/, DST0/3/, GRDFAC/45/,
     1     GTHG/44/, GTSTEP/4/, NREDUC/6/, NWTFAC/46/, PREDUC/7/,
     2     RADIUS/8/, STPPAR/5/
C/7
C     PARAMETER (BIAS=43, DGNORM=1, DSTNRM=2, DST0=3, GRDFAC=45,
C    1           GTHG=44, GTSTEP=4, NREDUC=6, NWTFAC=46, PREDUC=7,
C    2           RADIUS=8, STPPAR=5)
C/
C
C+++++++++++++++++++++++++++++++  BODY  ++++++++++++++++++++++++++++++++
C
      NWTNRM = V(DST0)
      RLAMBD = ONE
      IF (NWTNRM .GT. ZERO) RLAMBD = V(RADIUS) / NWTNRM
      GNORM = V(DGNORM)
      DO 10 I = 1, N
 10      STEP(I) = G(I) / GNORM
      GHINVG = DDOT(N, STEP,1,NWTSTP,1)
      V(NREDUC) = HALF * GHINVG * GNORM
      V(GRDFAC) = ZERO
      V(NWTFAC) = ZERO
      IF (RLAMBD .LT. ONE) GO TO 30
C
C        ***  THE NEWTON STEP IS INSIDE THE TRUST REGION  ***
C
         V(STPPAR) = ZERO
         V(DSTNRM) = NWTNRM
         V(GTSTEP) = -GHINVG * GNORM
         V(PREDUC) = V(NREDUC)
         V(NWTFAC) = -ONE
         DO 20 I = 1, N
 20           STEP(I) = -NWTSTP(I)
         GO TO 999
C
 30   V(DSTNRM) = V(RADIUS)
      CFACT = (GNORM / V(GTHG))**2
C     ***  CAUCHY STEP = -CFACT * G.
      CNORM = GNORM * CFACT
      RELAX = ONE - V(BIAS) * (ONE - CNORM/GHINVG)
      IF (RLAMBD .LT. RELAX) GO TO 50
C
C        ***  STEP IS BETWEEN RELAXED NEWTON AND FULL NEWTON STEPS  ***
C
         V(STPPAR)  =  ONE  -  (RLAMBD - RELAX) / (ONE - RELAX)
         T = -RLAMBD
         V(GTSTEP) = T * GHINVG * GNORM
         V(PREDUC) = RLAMBD * (ONE - HALF*RLAMBD) * GHINVG * GNORM
         V(NWTFAC) = T
         DO 40 I = 1, N
 40           STEP(I) = T * NWTSTP(I)
         GO TO 999
C
 50   IF (CNORM .LT. V(RADIUS)) GO TO 70
C
C        ***  THE CAUCHY STEP LIES OUTSIDE THE TRUST REGION --
C        ***  STEP = SCALED CAUCHY STEP  ***
C
         T = -V(RADIUS) / GNORM
         V(GRDFAC) = T
         V(STPPAR) = ONE  +  CNORM / V(RADIUS)
         V(GTSTEP) = -V(RADIUS) * GNORM
      V(PREDUC) = V(RADIUS)*(GNORM - HALF*V(RADIUS)*(V(GTHG)/GNORM)**2)
         DO 60 I = 1, N
 60           STEP(I) = T * DIG(I)
         GO TO 999
C
C     ***  COMPUTE DOGLEG STEP BETWEEN CAUCHY AND RELAXED NEWTON  ***
C     ***  FEMUR = RELAXED NEWTON STEP MINUS CAUCHY STEP  ***
C
 70   CTRNWT = CFACT * RELAX * GHINVG / GNORM
C     *** CTRNWT = INNER PROD. OF CAUCHY AND RELAXED NEWTON STEPS,
C     *** SCALED BY GNORM**-2.
      T1 = CTRNWT - CFACT**2
C     ***  T1 = INNER PROD. OF FEMUR AND CAUCHY STEP, SCALED BY
C     ***  GNORM**-2.
      T2 = (V(RADIUS)/GNORM)**2 - CFACT**2
      FEMNSQ = (RELAX*NWTNRM/GNORM)**2 - CTRNWT - T1
C     ***  FEMNSQ = SQUARE OF 2-NORM OF FEMUR, SCALED BY GNORM**-2.
      T = T2 / (T1 + DSQRT(T1**2 + FEMNSQ*T2))
C     ***  DOGLEG STEP  =  CAUCHY STEP  +  T * FEMUR.
      T1 = (T - ONE) * CFACT
      V(GRDFAC) = T1
      T2 = -T * RELAX
      V(NWTFAC) = T2
      V(STPPAR) = TWO - T
      V(GTSTEP) = GNORM * (T1*GNORM + T2*GHINVG)
      V(PREDUC) = -(T1*GNORM) * ((T2 + ONE)*GNORM)
     1                  - (T2*GNORM) * (ONE + HALF*T2)*GHINVG
     2                  - HALF * (V(GTHG)*T1)**2
      DO 80 I = 1, N
 80      STEP(I) = T1*DIG(I) + T2*NWTSTP(I)
C
 999  RETURN
C  ***  LAST CARD OF DDBDOG FOLLOWS  ***
      END
      DOUBLE PRECISION FUNCTION DDOT(N,DX,INCX,DY,INCY)
      save
C***BEGIN PROLOGUE  DDOT
C***DATE WRITTEN   791001   (YYMMDD)
C***REVISION DATE  820801   (YYMMDD)
C***CATEGORY NO.  D1A4
C***KEYWORDS  BLAS,DOUBLE PRECISION,INNER PRODUCT,LINEAR ALGEBRA,VECTOR
C***AUTHOR  LAWSON, C. L., (JPL)
C           HANSON, R. J., (SNLA)
C           KINCAID, D. R., (U. OF TEXAS)
C           KROGH, F. T., (JPL)
C***PURPOSE  D.P. inner product of d.p. vectors
C***DESCRIPTION
C
C                B L A S  Subprogram
C    Description of Parameters
C
C     --Input--
C        N  number of elements in input vector(s)
C       DX  double precision vector with N elements
C     INCX  storage spacing between elements of DX
C       DY  double precision vector with N elements
C     INCY  storage spacing between elements of DY
C
C     --Output--
C     DDOT  double precision dot product (zero if N .LE. 0)
C
C     Returns the dot product of double precision DX and DY.
C     DDOT = sum for I = 0 to N-1 of  DX(LX+I*INCX) * DY(LY+I*INCY)
C     where LX = 1 if INCX .GE. 0, else LX = (-INCX)*N, and LY is
C     defined in a similar way using INCY.
C***REFERENCES  LAWSON C.L., HANSON R.J., KINCAID D.R., KROGH F.T.,
C                 *BASIC LINEAR ALGEBRA SUBPROGRAMS FOR FORTRAN USAGE*,
C                 ALGORITHM NO. 539, TRANSACTIONS ON MATHEMATICAL
C                 SOFTWARE, VOLUME 5, NUMBER 3, SEPTEMBER 1979, 308-323
C***ROUTINES CALLED  (NONE)
C***END PROLOGUE  DDOT
C
      DOUBLE PRECISION DX(1),DY(1)
C***FIRST EXECUTABLE STATEMENT  DDOT
      DDOT = 0.D0
      IF(N.LE.0)RETURN
      IF(INCX.EQ.INCY) IF(INCX-1) 5,20,60
    5 CONTINUE
C
C         CODE FOR UNEQUAL OR NONPOSITIVE INCREMENTS.
C
      IX = 1
      IY = 1
      IF(INCX.LT.0)IX = (-N+1)*INCX + 1
      IF(INCY.LT.0)IY = (-N+1)*INCY + 1
      DO 10 I = 1,N
         DDOT = DDOT + DX(IX)*DY(IY)
        IX = IX + INCX
        IY = IY + INCY
   10 CONTINUE
      RETURN
C
C        CODE FOR BOTH INCREMENTS EQUAL TO 1.
C
C
C        CLEAN-UP LOOP SO REMAINING VECTOR LENGTH IS A MULTIPLE OF 5.
C
   20 M = MOD(N,5)
      IF( M .EQ. 0 ) GO TO 40
      DO 30 I = 1,M
         DDOT = DDOT + DX(I)*DY(I)
   30 CONTINUE
      IF( N .LT. 5 ) RETURN
   40 MP1 = M + 1
      DO 50 I = MP1,N,5
         DDOT = DDOT + DX(I)*DY(I) + DX(I+1)*DY(I+1) +
     1   DX(I + 2)*DY(I + 2) + DX(I + 3)*DY(I + 3) + DX(I + 4)*DY(I + 4)
   50 CONTINUE
      RETURN
C
C         CODE FOR POSITIVE EQUAL INCREMENTS .NE.1.
C
   60 CONTINUE
      NS = N*INCX
          DO 70 I=1,NS,INCX
          DDOT = DDOT + DX(I)*DY(I)
   70     CONTINUE
      RETURN
      END
      SUBROUTINE DITSUM(D, G, IV, LIV, LV, P, V, X)
      save
C
C  ***  PRINT ITERATION SUMMARY FOR ***SOL (VERSION 2.3)  ***
C
C  ***  PARAMETER DECLARATIONS  ***
C
      INTEGER LIV, LV, P
      INTEGER IV(LIV)
      DOUBLE PRECISION D(P), G(P), V(LV), X(P)
C
C+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
C
C  ***  LOCAL VARIABLES  ***
C
      INTEGER ALG, I, IV1, M, NF, NG, OL, PU
C/6
      REAL MODEL1(6), MODEL2(6)
C/7
C     CHARACTER*4 MODEL1(6), MODEL2(6)
C/
      DOUBLE PRECISION NRELDF, OLDF, PRELDF, RELDF, ZERO
C
C  ***  INTRINSIC FUNCTIONS  ***
C/+
      INTEGER IABS
      DOUBLE PRECISION DABS, DMAX1
C/
C  ***  NO EXTERNAL FUNCTIONS OR SUBROUTINES  ***
C
C  ***  SUBSCRIPTS FOR IV AND V  ***
C
      INTEGER ALGSAV, DSTNRM, F, FDIF, F0, NEEDHD, NFCALL, NFCOV, NGCOV,
     1        NGCALL, NITER, NREDUC, OUTLEV, PREDUC, PRNTIT, PRUNIT,
     2        RELDX, SOLPRT, STATPR, STPPAR, SUSED, X0PRT
C
C  ***  IV SUBSCRIPT VALUES  ***
C
C/6
      DATA ALGSAV/51/, NEEDHD/36/, NFCALL/6/, NFCOV/52/, NGCALL/30/,
     1     NGCOV/53/, NITER/31/, OUTLEV/19/, PRNTIT/39/, PRUNIT/21/,
     2     SOLPRT/22/, STATPR/23/, SUSED/64/, X0PRT/24/
C/7
C     PARAMETER (ALGSAV=51, NEEDHD=36, NFCALL=6, NFCOV=52, NGCALL=30,
C    1           NGCOV=53, NITER=31, OUTLEV=19, PRNTIT=39, PRUNIT=21,
C    2           SOLPRT=22, STATPR=23, SUSED=64, X0PRT=24)
C/
C
C  ***  V SUBSCRIPT VALUES  ***
C
C/6
      DATA DSTNRM/2/, F/10/, F0/13/, FDIF/11/, NREDUC/6/, PREDUC/7/,
     1     RELDX/17/, STPPAR/5/
C/7
C     PARAMETER (DSTNRM=2, F=10, F0=13, FDIF=11, NREDUC=6, PREDUC=7,
C    1           RELDX=17, STPPAR=5)
C/
C
C/6
      DATA ZERO/0.D+0/
C/7
C     PARAMETER (ZERO=0.D+0)
C/
C/6
      DATA MODEL1(1)/4H    /, MODEL1(2)/4H    /, MODEL1(3)/4H    /,
     1     MODEL1(4)/4H    /, MODEL1(5)/4H  G /, MODEL1(6)/4H  S /,
     2     MODEL2(1)/4H G  /, MODEL2(2)/4H S  /, MODEL2(3)/4HG-S /,
     3     MODEL2(4)/4HS-G /, MODEL2(5)/4H-S-G/, MODEL2(6)/4H-G-S/
C/7
C     DATA MODEL1/'    ','    ','    ','    ','  G ','  S '/,
C    1     MODEL2/' G  ',' S  ','G-S ','S-G ','-S-G','-G-S'/
C/
C
C-------------------------------  BODY  --------------------------------
C
      PU = IV(PRUNIT)
      IF (PU .EQ. 0) GO TO 999
      IV1 = IV(1)
      IF (IV1 .GT. 62) IV1 = IV1 - 51
      OL = IV(OUTLEV)
      ALG = IV(ALGSAV)
      IF (IV1 .LT. 2 .OR. IV1 .GT. 15) GO TO 370
      IF (OL .EQ. 0) GO TO 120
      IF (IV1 .GE. 12) GO TO 120
      IF (IV1 .EQ. 2 .AND. IV(NITER) .EQ. 0) GO TO 390
      IF (IV1 .GE. 10 .AND. IV(PRNTIT) .EQ. 0) GO TO 120
      IF (IV1 .GT. 2) GO TO 10
         IV(PRNTIT) = IV(PRNTIT) + 1
         IF (IV(PRNTIT) .LT. IABS(OL)) GO TO 999
 10   NF = IV(NFCALL) - IABS(IV(NFCOV))
      IV(PRNTIT) = 0
      RELDF = ZERO
      PRELDF = ZERO
      OLDF = DMAX1(DABS(V(F0)), DABS(V(F)))
      IF (OLDF .LE. ZERO) GO TO 20
         RELDF = V(FDIF) / OLDF
         PRELDF = V(PREDUC) / OLDF
 20   IF (OL .GT. 0) GO TO 60
C
C        ***  PRINT SHORT SUMMARY LINE  ***
C
         IF (IV(NEEDHD) .EQ. 1 .AND. ALG .EQ. 1) WRITE(PU,30)
 30   FORMAT(/10H   IT   NF,6X,1HF,7X,5HRELDF,3X,6HPRELDF,3X,5HRELDX,
     1       2X,13HMODEL  STPPAR)
         IF (IV(NEEDHD) .EQ. 1 .AND. ALG .EQ. 2) WRITE(PU,40)
 40   FORMAT(/11H    IT   NF,7X,1HF,8X,5HRELDF,4X,6HPRELDF,4X,5HRELDX,
     1       3X,6HSTPPAR)
         IV(NEEDHD) = 0
         IF (ALG .EQ. 2) GO TO 50
         M = IV(SUSED)
         WRITE(PU,100) IV(NITER), NF, V(F), RELDF, PRELDF, V(RELDX),
     1                 MODEL1(M), MODEL2(M), V(STPPAR)
         GO TO 120
C
 50      WRITE(PU,110) IV(NITER), NF, V(F), RELDF, PRELDF, V(RELDX),
     1                 V(STPPAR)
         GO TO 120
C
C     ***  PRINT LONG SUMMARY LINE  ***
C
 60   IF (IV(NEEDHD) .EQ. 1 .AND. ALG .EQ. 1) WRITE(PU,70)
 70   FORMAT(/11H    IT   NF,6X,1HF,7X,5HRELDF,3X,6HPRELDF,3X,5HRELDX,
     1       2X,13HMODEL  STPPAR,2X,6HD*STEP,2X,7HNPRELDF)
      IF (IV(NEEDHD) .EQ. 1 .AND. ALG .EQ. 2) WRITE(PU,80)
 80   FORMAT(/11H    IT   NF,7X,1HF,8X,5HRELDF,4X,6HPRELDF,4X,5HRELDX,
     1       3X,6HSTPPAR,3X,6HD*STEP,3X,7HNPRELDF)
      IV(NEEDHD) = 0
      NRELDF = ZERO
      IF (OLDF .GT. ZERO) NRELDF = V(NREDUC) / OLDF
      IF (ALG .EQ. 2) GO TO 90
      M = IV(SUSED)
      WRITE(PU,100) IV(NITER), NF, V(F), RELDF, PRELDF, V(RELDX),
     1             MODEL1(M), MODEL2(M), V(STPPAR), V(DSTNRM), NRELDF
      GO TO 120
C
 90   WRITE(PU,110) IV(NITER), NF, V(F), RELDF, PRELDF,
     1             V(RELDX), V(STPPAR), V(DSTNRM), NRELDF
 100  FORMAT(I6,I5,D10.3,2D9.2,D8.1,A3,A4,2D8.1,D9.2)
 110  FORMAT(I6,I5,D11.3,2D10.2,3D9.1,D10.2)
C
 120  IF (IV(STATPR) .LT. 0) GO TO 430
      GO TO (999, 999, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310,
     1       330, 350, 520), IV1
C
 130  WRITE(PU,140)
 140  FORMAT(/26H ***** X-CONVERGENCE *****)
      GO TO 430
C
 150  WRITE(PU,160)
 160  FORMAT(/42H ***** RELATIVE FUNCTION CONVERGENCE *****)
      GO TO 430
C
 170  WRITE(PU,180)
 180  FORMAT(/49H ***** X- AND RELATIVE FUNCTION CONVERGENCE *****)
      GO TO 430
C
 190  WRITE(PU,200)
 200  FORMAT(/42H ***** ABSOLUTE FUNCTION CONVERGENCE *****)
      GO TO 430
C
 210  WRITE(PU,220)
 220  FORMAT(/33H ***** SINGULAR CONVERGENCE *****)
      GO TO 430
C
 230  WRITE(PU,240)
 240  FORMAT(/30H ***** FALSE CONVERGENCE *****)
      GO TO 430
C
 250  WRITE(PU,260)
 260  FORMAT(/38H ***** FUNCTION EVALUATION LIMIT *****)
      GO TO 430
C
 270  WRITE(PU,280)
 280  FORMAT(/28H ***** ITERATION LIMIT *****)
      GO TO 430
C
 290  WRITE(PU,300)
 300  FORMAT(/18H ***** STOPX *****)
      GO TO 430
C
 310  WRITE(PU,320)
 320  FORMAT(/44H ***** INITIAL F(X) CANNOT BE COMPUTED *****)
C
      GO TO 390
C
 330  WRITE(PU,340)
 340  FORMAT(/37H ***** BAD PARAMETERS TO ASSESS *****)
      GO TO 999
C
 350  WRITE(PU,360)
 360  FORMAT(/43H ***** GRADIENT COULD NOT BE COMPUTED *****)
      IF (IV(NITER) .GT. 0) GO TO 480
      GO TO 390
C
 370  WRITE(PU,380) IV(1)
 380  FORMAT(/14H ***** IV(1) =,I5,6H *****)
      GO TO 999
C
C  ***  INITIAL CALL ON DITSUM  ***
C
 390  IF (IV(X0PRT) .NE. 0) WRITE(PU,400) (I, X(I), D(I), I = 1, P)
 400  FORMAT(/23H     I     INITIAL X(I),8X,4HD(I)//(1X,I5,D17.6,D14.3))
      IF (IV1 .GE. 12) GO TO 999
      IV(NEEDHD) = 0
      IV(PRNTIT) = 0
      IF (OL .EQ. 0) GO TO 999
      IF (OL .LT. 0 .AND. ALG .EQ. 1) WRITE(PU,30)
      IF (OL .LT. 0 .AND. ALG .EQ. 2) WRITE(PU,40)
      IF (OL .GT. 0 .AND. ALG .EQ. 1) WRITE(PU,70)
      IF (OL .GT. 0 .AND. ALG .EQ. 2) WRITE(PU,80)
      IF (ALG .EQ. 1) WRITE(PU,410) V(F)
      IF (ALG .EQ. 2) WRITE(PU,420) V(F)
 410  FORMAT(/11H     0    1,D10.3)
C365  FORMAT(/11H     0    1,E11.3)
 420  FORMAT(/11H     0    1,D11.3)
      GO TO 999
C
C  ***  PRINT VARIOUS INFORMATION REQUESTED ON SOLUTION  ***
C
 430  IV(NEEDHD) = 1
      IF (IV(STATPR) .EQ. 0) GO TO 480
         OLDF = DMAX1(DABS(V(F0)), DABS(V(F)))
         PRELDF = ZERO
         NRELDF = ZERO
         IF (OLDF .LE. ZERO) GO TO 440
              PRELDF = V(PREDUC) / OLDF
              NRELDF = V(NREDUC) / OLDF
 440     NF = IV(NFCALL) - IV(NFCOV)
         NG = IV(NGCALL) - IV(NGCOV)
         WRITE(PU,450) V(F), V(RELDX), NF, NG, PRELDF, NRELDF
 450  FORMAT(/9H FUNCTION,D17.6,8H   RELDX,D17.3/12H FUNC. EVALS,
     1   I8,9X,11HGRAD. EVALS,I8/7H PRELDF,D16.3,6X,7HNPRELDF,D15.3)
C
         IF (IV(NFCOV) .GT. 0) WRITE(PU,460) IV(NFCOV)
 460     FORMAT(/1X,I4,50H EXTRA FUNC. EVALS FOR COVARIANCE AND DIAGNOST
     1ICS.)
         IF (IV(NGCOV) .GT. 0) WRITE(PU,470) IV(NGCOV)
 470     FORMAT(1X,I4,50H EXTRA GRAD. EVALS FOR COVARIANCE AND DIAGNOSTI
     1CS.)
C
 480  IF (IV(SOLPRT) .EQ. 0) GO TO 999
         IV(NEEDHD) = 1
         WRITE(PU,490)
 490  FORMAT(/22H     I      FINAL X(I),8X,4HD(I),10X,4HG(I)/)
         DO 500 I = 1, P
              WRITE(PU,510) I, X(I), D(I), G(I)
 500          CONTINUE
 510     FORMAT(1X,I5,D16.6,2D14.3)
      GO TO 999
C
 520  WRITE(PU,530)
 530  FORMAT(/24H INCONSISTENT DIMENSIONS)
 999  RETURN
C  ***  LAST CARD OF DITSUM FOLLOWS  ***
      END
      SUBROUTINE DLITVM(N, X, L, Y)
      save
C
C  ***  SOLVE  (L**T)*X = Y,  WHERE  L  IS AN  N X N  LOWER TRIANGULAR
C  ***  MATRIX STORED COMPACTLY BY ROWS.  X AND Y MAY OCCUPY THE SAME
C  ***  STORAGE.  ***
C
      INTEGER N
      DOUBLE PRECISION X(N), L(1), Y(N)
      INTEGER I, II, IJ, IM1, I0, J, NP1
      DOUBLE PRECISION XI, ZERO
C/6
      DATA ZERO/0.D+0/
C/7
C     PARAMETER (ZERO=0.D+0)
C/
C
      DO 10 I = 1, N
 10      X(I) = Y(I)
      NP1 = N + 1
      I0 = N*(N+1)/2
      DO 30 II = 1, N
         I = NP1 - II
         XI = X(I)/L(I0)
         X(I) = XI
         IF (I .LE. 1) GO TO 999
         I0 = I0 - I
         IF (XI .EQ. ZERO) GO TO 30
         IM1 = I - 1
         DO 20 J = 1, IM1
              IJ = I0 + J
              X(J) = X(J) - XI*L(IJ)
 20           CONTINUE
 30      CONTINUE
 999  RETURN
C  ***  LAST CARD OF DLITVM FOLLOWS  ***
      END
      SUBROUTINE DLIVMU(N, X, L, Y)
      save
C
C  ***  SOLVE  L*X = Y, WHERE  L  IS AN  N X N  LOWER TRIANGULAR
C  ***  MATRIX STORED COMPACTLY BY ROWS.  X AND Y MAY OCCUPY THE SAME
C  ***  STORAGE.  ***
C
      INTEGER N
      DOUBLE PRECISION X(N), L(1), Y(N)
      DOUBLE PRECISION DDOT
      INTEGER I, J, K
      DOUBLE PRECISION T, ZERO
C/6
      DATA ZERO/0.D+0/
C/7
C     PARAMETER (ZERO=0.D+0)
C/
C
      DO 10 K = 1, N
         IF (Y(K) .NE. ZERO) GO TO 20
         X(K) = ZERO
 10      CONTINUE
      GO TO 999
 20   J = K*(K+1)/2
      X(K) = Y(K) / L(J)
      IF (K .GE. N) GO TO 999
      K = K + 1
      DO 30 I = K, N
         T = DDOT(I-1, L(J+1),1,X,1)
         J = J + I
         X(I) = (Y(I) - T)/L(J)
 30      CONTINUE
 999  RETURN
C  ***  LAST CARD OF DLIVMU FOLLOWS  ***
      END
      SUBROUTINE DLTVMU(N, X, L, Y)
      save
C
C  ***  COMPUTE  X = (L**T)*Y, WHERE  L  IS AN  N X N  LOWER
C  ***  TRIANGULAR MATRIX STORED COMPACTLY BY ROWS.  X AND Y MAY
C  ***  OCCUPY THE SAME STORAGE.  ***
C
      INTEGER N
      DOUBLE PRECISION X(N), L(1), Y(N)
C     DIMENSION L(N*(N+1)/2)
      INTEGER I, IJ, I0, J
      DOUBLE PRECISION YI, ZERO
C/6
      DATA ZERO/0.D+0/
C/7
C     PARAMETER (ZERO=0.D+0)
C/
C
      I0 = 0
      DO 20 I = 1, N
         YI = Y(I)
         X(I) = ZERO
         DO 10 J = 1, I
              IJ = I0 + J
              X(J) = X(J) + YI*L(IJ)
 10           CONTINUE
         I0 = I0 + I
 20      CONTINUE
 999  RETURN
C  ***  LAST CARD OF DLTVMU FOLLOWS  ***
      END
      SUBROUTINE DLUPDT(BETA, GAMMA, L, LAMBDA, LPLUS, N, W, Z)
      save
C
C  ***  COMPUTE LPLUS = SECANT UPDATE OF L  ***
C
C  ***  PARAMETER DECLARATIONS  ***
C
      INTEGER N
      DOUBLE PRECISION BETA(N), GAMMA(N), L(1), LAMBDA(N), LPLUS(1),
     1                 W(N), Z(N)
C     DIMENSION L(N*(N+1)/2), LPLUS(N*(N+1)/2)
C
C--------------------------  PARAMETER USAGE  --------------------------
C
C   BETA = SCRATCH VECTOR.
C  GAMMA = SCRATCH VECTOR.
C      L (INPUT) LOWER TRIANGULAR MATRIX, STORED ROWWISE.
C LAMBDA = SCRATCH VECTOR.
C  LPLUS (OUTPUT) LOWER TRIANGULAR MATRIX, STORED ROWWISE, WHICH MAY
C             OCCUPY THE SAME STORAGE AS  L.
C      N (INPUT) LENGTH OF VECTOR PARAMETERS AND ORDER OF MATRICES.
C      W (INPUT, DESTROYED ON OUTPUT) RIGHT SINGULAR VECTOR OF RANK 1
C             CORRECTION TO  L.
C      Z (INPUT, DESTROYED ON OUTPUT) LEFT SINGULAR VECTOR OF RANK 1
C             CORRECTION TO  L.
C
C-------------------------------  NOTES  -------------------------------
C
C  ***  APPLICATION AND USAGE RESTRICTIONS  ***
C
C        THIS ROUTINE UPDATES THE CHOLESKY FACTOR  L  OF A SYMMETRIC
C     POSITIVE DEFINITE MATRIX TO WHICH A SECANT UPDATE IS BEING
C     APPLIED -- IT COMPUTES A CHOLESKY FACTOR  LPLUS  OF
C     L * (I + Z*W**T) * (I + W*Z**T) * L**T.  IT IS ASSUMED THAT  W
C     AND  Z  HAVE BEEN CHOSEN SO THAT THE UPDATED MATRIX IS STRICTLY
C     POSITIVE DEFINITE.
C
C  ***  ALGORITHM NOTES  ***
C
C        THIS CODE USES RECURRENCE 3 OF REF. 1 (WITH D(J) = 1 FOR ALL J)
C     TO COMPUTE  LPLUS  OF THE FORM  L * (I + Z*W**T) * Q,  WHERE  Q
C     IS AN ORTHOGONAL MATRIX THAT MAKES THE RESULT LOWER TRIANGULAR.
C        LPLUS MAY HAVE SOME NEGATIVE DIAGONAL ELEMENTS.
C
C  ***  REFERENCES  ***
C
C 1.  GOLDFARB, D. (1976), FACTORIZED VARIABLE METRIC METHODS FOR UNCON-
C             STRAINED OPTIMIZATION, MATH. COMPUT. 30, PP. 796-811.
C
C  ***  GENERAL  ***
C
C     CODED BY DAVID M. GAY (FALL 1979).
C     THIS SUBROUTINE WAS WRITTEN IN CONNECTION WITH RESEARCH SUPPORTED
C     BY THE NATIONAL SCIENCE FOUNDATION UNDER GRANTS MCS-7600324 AND
C     MCS-7906671.
C
C------------------------  EXTERNAL QUANTITIES  ------------------------
C
C  ***  INTRINSIC FUNCTIONS  ***
C/+
      DOUBLE PRECISION DSQRT
C/
C--------------------------  LOCAL VARIABLES  --------------------------
C
      INTEGER I, IJ, J, JJ, JP1, K, NM1, NP1
      DOUBLE PRECISION A, B, BJ, ETA, GJ, LJ, LIJ, LJJ, NU, S, THETA,
     1                 WJ, ZJ
      DOUBLE PRECISION ONE, ZERO
C
C  ***  DATA INITIALIZATIONS  ***
C
C/6
      DATA ONE/1.D+0/, ZERO/0.D+0/
C/7
C     PARAMETER (ONE=1.D+0, ZERO=0.D+0)
C/
C
C+++++++++++++++++++++++++++++++  BODY  ++++++++++++++++++++++++++++++++
C
      NU = ONE
      ETA = ZERO
      IF (N .LE. 1) GO TO 30
      NM1 = N - 1
C
C  ***  TEMPORARILY STORE S(J) = SUM OVER K = J+1 TO N OF W(K)**2 IN
C  ***  LAMBDA(J).
C
      S = ZERO
      DO 10 I = 1, NM1
         J = N - I
         S = S + W(J+1)**2
         LAMBDA(J) = S
 10      CONTINUE
C
C  ***  COMPUTE LAMBDA, GAMMA, AND BETA BY GOLDFARB*S RECURRENCE 3.
C
      DO 20 J = 1, NM1
         WJ = W(J)
         A = NU*Z(J) - ETA*WJ
         THETA = ONE + A*WJ
         S = A*LAMBDA(J)
         LJ = DSQRT(THETA**2 + A*S)
         IF (THETA .GT. ZERO) LJ = -LJ
         LAMBDA(J) = LJ
         B = THETA*WJ + S
         GAMMA(J) = B * NU / LJ
         BETA(J) = (A - B*ETA) / LJ
         NU = -NU / LJ
         ETA = -(ETA + (A**2)/(THETA - LJ)) / LJ
 20      CONTINUE
 30   LAMBDA(N) = ONE + (NU*Z(N) - ETA*W(N))*W(N)
C
C  ***  UPDATE L, GRADUALLY OVERWRITING  W  AND  Z  WITH  L*W  AND  L*Z.
C
      NP1 = N + 1
      JJ = N * (N + 1) / 2
      DO 60 K = 1, N
         J = NP1 - K
         LJ = LAMBDA(J)
         LJJ = L(JJ)
         LPLUS(JJ) = LJ * LJJ
         WJ = W(J)
         W(J) = LJJ * WJ
         ZJ = Z(J)
         Z(J) = LJJ * ZJ
         IF (K .EQ. 1) GO TO 50
         BJ = BETA(J)
         GJ = GAMMA(J)
         IJ = JJ + J
         JP1 = J + 1
         DO 40 I = JP1, N
              LIJ = L(IJ)
              LPLUS(IJ) = LJ*LIJ + BJ*W(I) + GJ*Z(I)
              W(I) = W(I) + LIJ*WJ
              Z(I) = Z(I) + LIJ*ZJ
              IJ = IJ + I
 40           CONTINUE
 50      JJ = JJ - J
 60      CONTINUE
C
 999  RETURN
C  ***  LAST CARD OF DLUPDT FOLLOWS  ***
      END
      SUBROUTINE DLVMUL(N, X, L, Y)
      save
C
C  ***  COMPUTE  X = L*Y, WHERE  L  IS AN  N X N  LOWER TRIANGULAR
C  ***  MATRIX STORED COMPACTLY BY ROWS.  X AND Y MAY OCCUPY THE SAME
C  ***  STORAGE.  ***
C
      INTEGER N
      DOUBLE PRECISION X(N), L(1), Y(N)
C     DIMENSION L(N*(N+1)/2)
      INTEGER I, II, IJ, I0, J, NP1
      DOUBLE PRECISION T, ZERO
C/6
      DATA ZERO/0.D+0/
C/7
C     PARAMETER (ZERO=0.D+0)
C/
C
      NP1 = N + 1
      I0 = N*(N+1)/2
      DO 20 II = 1, N
         I = NP1 - II
         I0 = I0 - I
         T = ZERO
         DO 10 J = 1, I
              IJ = I0 + J
              T = T + L(IJ)*Y(J)
 10           CONTINUE
         X(I) = T
 20      CONTINUE
 999  RETURN
C  ***  LAST CARD OF DLVMUL FOLLOWS  ***
      END
      DOUBLE PRECISION FUNCTION DNRM2(N,DX,INCX)
      save
C***BEGIN PROLOGUE  DNRM2
C***DATE WRITTEN   791001   (YYMMDD)
C***REVISION DATE  820801   (YYMMDD)
C***CATEGORY NO.  D1A3B
C***KEYWORDS  BLAS,DOUBLE PRECISION,EUCLIDEAN,L2,LENGTH,LINEAR ALGEBRA,
C             NORM,VECTOR
C***AUTHOR  LAWSON, C. L., (JPL)
C           HANSON, R. J., (SNLA)
C           KINCAID, D. R., (U. OF TEXAS)
C           KROGH, F. T., (JPL)
C***PURPOSE  Euclidean length (L2 norm) of d.p. vector
C***DESCRIPTION
C
C                B L A S  Subprogram
C    Description of parameters
C
C     --Input--
C        N  number of elements in input vector(s)
C       DX  double precision vector with N elements
C     INCX  storage spacing between elements of DX
C
C     --Output--
C    DNRM2  double precision result (zero if N .LE. 0)
C
C     Euclidean norm of the N-vector stored in DX() with storage
C     increment INCX .
C     If    N .LE. 0 return with result = 0.
C     If N .GE. 1 then INCX must be .GE. 1
C
C           C.L. Lawson, 1978 Jan 08
C
C     Four phase method     using two built-in constants that are
C     hopefully applicable to all machines.
C         CUTLO = maximum of  DSQRT(U/EPS)  over all known machines.
C         CUTHI = minimum of  DSQRT(V)      over all known machines.
C     where
C         EPS = smallest no. such that EPS + 1. .GT. 1.
C         U   = smallest positive no.   (underflow limit)
C         V   = largest  no.            (overflow  limit)
C
C     Brief outline of algorithm..
C
C     Phase 1    scans zero components.
C     move to phase 2 when a component is nonzero and .LE. CUTLO
C     move to phase 3 when a component is .GT. CUTLO
C     move to phase 4 when a component is .GE. CUTHI/M
C     where M = N for X() real and M = 2*N for complex.
C
C     Values for CUTLO and CUTHI..
C     From the environmental parameters listed in the IMSL converter
C     document the limiting values are as followS..
C     CUTLO, S.P.   U/EPS = 2**(-102) for  Honeywell.  Close seconds are
C                   Univac and DEC at 2**(-103)
C                   Thus CUTLO = 2**(-51) = 4.44089E-16
C     CUTHI, S.P.   V = 2**127 for Univac, Honeywell, and DEC.
C                   Thus CUTHI = 2**(63.5) = 1.30438E19
C     CUTLO, D.P.   U/EPS = 2**(-67) for Honeywell and DEC.
C                   Thus CUTLO = 2**(-33.5) = 8.23181D-11
C     CUTHI, D.P.   same as S.P.  CUTHI = 1.30438D19
C     DATA CUTLO, CUTHI / 8.232D-11,  1.304D19 /
C     DATA CUTLO, CUTHI / 4.441E-16,  1.304E19 /
C***REFERENCES  LAWSON C.L., HANSON R.J., KINCAID D.R., KROGH F.T.,
C                 *BASIC LINEAR ALGEBRA SUBPROGRAMS FOR FORTRAN USAGE*,
C                 ALGORITHM NO. 539, TRANSACTIONS ON MATHEMATICAL
C                 SOFTWARE, VOLUME 5, NUMBER 3, SEPTEMBER 1979, 308-323
C***ROUTINES CALLED  (NONE)
C***END PROLOGUE  DNRM2
      INTEGER          NEXT
      DOUBLE PRECISION   DX(1), CUTLO, CUTHI, HITEST, SUM, XMAX,ZERO,ONE
      DATA   ZERO, ONE /0.0D0, 1.0D0/
C
      DATA CUTLO, CUTHI / 8.232D-11,  1.304D19 /
C***FIRST EXECUTABLE STATEMENT  DNRM2
      IF(N .GT. 0) GO TO 10
         DNRM2  = ZERO
         GO TO 300
C
   10 ASSIGN 30 TO NEXT
      SUM = ZERO
      NN = N * INCX
C                                                 BEGIN MAIN LOOP
      I = 1
   20    GO TO NEXT,(30, 50, 70, 110)
   30 IF( DABS(DX(I)) .GT. CUTLO) GO TO 85
      ASSIGN 50 TO NEXT
      XMAX = ZERO
C
C                        PHASE 1.  SUM IS ZERO
C
   50 IF( DX(I) .EQ. ZERO) GO TO 200
      IF( DABS(DX(I)) .GT. CUTLO) GO TO 85
C
C                                PREPARE FOR PHASE 2.
      ASSIGN 70 TO NEXT
      GO TO 105
C
C                                PREPARE FOR PHASE 4.
C
  100 I = J
      ASSIGN 110 TO NEXT
      SUM = (SUM / DX(I)) / DX(I)
  105 XMAX = DABS(DX(I))
      GO TO 115
C
C                   PHASE 2.  SUM IS SMALL.
C                             SCALE TO AVOID DESTRUCTIVE UNDERFLOW.
C
   70 IF( DABS(DX(I)) .GT. CUTLO ) GO TO 75
C
C                     COMMON CODE FOR PHASES 2 AND 4.
C                     IN PHASE 4 SUM IS LARGE.  SCALE TO AVOID OVERFLOW.
C
  110 IF( DABS(DX(I)) .LE. XMAX ) GO TO 115
         SUM = ONE + SUM * (XMAX / DX(I))**2
         XMAX = DABS(DX(I))
         GO TO 200
C
  115 SUM = SUM + (DX(I)/XMAX)**2
      GO TO 200
C
C
C                  PREPARE FOR PHASE 3.
C
   75 SUM = (SUM * XMAX) * XMAX
C
C
C     FOR REAL OR D.P. SET HITEST = CUTHI/N
C     FOR COMPLEX      SET HITEST = CUTHI/(2*N)
C
   85 HITEST = CUTHI/FLOAT( N )
C
C                   PHASE 3.  SUM IS MID-RANGE.  NO SCALING.
C
      DO 95 J =I,NN,INCX
      IF(DABS(DX(J)) .GE. HITEST) GO TO 100
   95    SUM = SUM + DX(J)**2
      DNRM2 = DSQRT( SUM )
      GO TO 300
C
  200 CONTINUE
      I = I + INCX
      IF ( I .LE. NN ) GO TO 20
C
C              END OF MAIN LOOP.
C
C              COMPUTE SQUARE ROOT AND ADJUST FOR SCALING.
C
      DNRM2 = XMAX * DSQRT(SUM)
  300 CONTINUE
      RETURN
      END
      SUBROUTINE DPARCK(ALG, D, IV, LIV, LV, N, V)
      save
C
C  ***  CHECK ***SOL (VERSION 2.3) PARAMETERS, PRINT CHANGED VALUES  ***
C
C  ***  ALG = 1 FOR REGRESSION, ALG = 2 FOR GENERAL UNCONSTRAINED OPT.
C
      INTEGER ALG, LIV, LV, N
      INTEGER IV(LIV)
      DOUBLE PRECISION D(N), V(LV)
C
      EXTERNAL  DVDFLT
      DOUBLE PRECISION D1MACH
C DVDFLT  -- SUPPLIES DEFAULT PARAMETER VALUES TO V ALONE.
C/+
      INTEGER MAX0
C/
C
C  ***  LOCAL VARIABLES  ***
C
      INTEGER I, II, IV1, J, K, L, M, MIV1, MIV2, NDFALT, PARSV1, PU
      INTEGER IJMP, JLIM(2), MINIV(2), NDFLT(2)
C/6
      INTEGER VARNM(2), SH(2)
      REAL CNGD(3), DFLT(3), VN(2,34), WHICH(3)
C/7
C     CHARACTER*1 VARNM(2), SH(2)
C     CHARACTER*4 CNGD(3), DFLT(3), VN(2,34), WHICH(3)
C/
      DOUBLE PRECISION BIG, MACHEP, TINY, VK, VM(34), VX(34), ZERO
C
C  ***  IV AND V SUBSCRIPTS  ***
C
      INTEGER ALGSAV, DINIT, DTYPE, DTYPE0, EPSLON, INITS, IVNEED,
     1        LASTIV, LASTV, LMAT, NEXTIV, NEXTV, NVDFLT, OLDN,
     2        PARPRT, PARSAV, PERM, PRUNIT, VNEED
C
C
C/6
      DATA ALGSAV/51/, DINIT/38/, DTYPE/16/, DTYPE0/54/, EPSLON/19/,
     1     INITS/25/, IVNEED/3/, LASTIV/44/, LASTV/45/, LMAT/42/,
     2     NEXTIV/46/, NEXTV/47/, NVDFLT/50/, OLDN/38/, PARPRT/20/,
     3     PARSAV/49/, PERM/58/, PRUNIT/21/, VNEED/4/
C/7
C     PARAMETER (ALGSAV=51, DINIT=38, DTYPE=16, DTYPE0=54, EPSLON=19,
C    1           INITS=25, IVNEED=3, LASTIV=44, LASTV=45, LMAT=42,
C    2           NEXTIV=46, NEXTV=47, NVDFLT=50, OLDN=38, PARPRT=20,
C    3           PARSAV=49, PERM=58, PRUNIT=21, VNEED=4)
C     SAVE BIG, MACHEP, TINY
C/
C
      DATA BIG/0.D+0/, MACHEP/-1.D+0/, TINY/1.D+0/, ZERO/0.D+0/
C/6
      DATA VN(1,1),VN(2,1)/4HEPSL,4HON../
      DATA VN(1,2),VN(2,2)/4HPHMN,4HFC../
      DATA VN(1,3),VN(2,3)/4HPHMX,4HFC../
      DATA VN(1,4),VN(2,4)/4HDECF,4HAC../
      DATA VN(1,5),VN(2,5)/4HINCF,4HAC../
      DATA VN(1,6),VN(2,6)/4HRDFC,4HMN../
      DATA VN(1,7),VN(2,7)/4HRDFC,4HMX../
      DATA VN(1,8),VN(2,8)/4HTUNE,4HR1../
      DATA VN(1,9),VN(2,9)/4HTUNE,4HR2../
      DATA VN(1,10),VN(2,10)/4HTUNE,4HR3../
      DATA VN(1,11),VN(2,11)/4HTUNE,4HR4../
      DATA VN(1,12),VN(2,12)/4HTUNE,4HR5../
      DATA VN(1,13),VN(2,13)/4HAFCT,4HOL../
      DATA VN(1,14),VN(2,14)/4HRFCT,4HOL../
      DATA VN(1,15),VN(2,15)/4HXCTO,4HL.../
      DATA VN(1,16),VN(2,16)/4HXFTO,4HL.../
      DATA VN(1,17),VN(2,17)/4HLMAX,4H0.../
      DATA VN(1,18),VN(2,18)/4HLMAX,4HS.../
      DATA VN(1,19),VN(2,19)/4HSCTO,4HL.../
      DATA VN(1,20),VN(2,20)/4HDINI,4HT.../
      DATA VN(1,21),VN(2,21)/4HDTIN,4HIT../
      DATA VN(1,22),VN(2,22)/4HD0IN,4HIT../
      DATA VN(1,23),VN(2,23)/4HDFAC,4H..../
      DATA VN(1,24),VN(2,24)/4HDLTF,4HDC../
      DATA VN(1,25),VN(2,25)/4HDLTF,4HDJ../
      DATA VN(1,26),VN(2,26)/4HDELT,4HA0../
      DATA VN(1,27),VN(2,27)/4HFUZZ,4H..../
      DATA VN(1,28),VN(2,28)/4HRLIM,4HIT../
      DATA VN(1,29),VN(2,29)/4HCOSM,4HIN../
      DATA VN(1,30),VN(2,30)/4HHUBE,4HRC../
      DATA VN(1,31),VN(2,31)/4HRSPT,4HOL../
      DATA VN(1,32),VN(2,32)/4HSIGM,4HIN../
      DATA VN(1,33),VN(2,33)/4HETA0,4H..../
      DATA VN(1,34),VN(2,34)/4HBIAS,4H..../
C/7
C     DATA VN(1,1),VN(2,1)/'EPSL','ON..'/
C     DATA VN(1,2),VN(2,2)/'PHMN','FC..'/
C     DATA VN(1,3),VN(2,3)/'PHMX','FC..'/
C     DATA VN(1,4),VN(2,4)/'DECF','AC..'/
C     DATA VN(1,5),VN(2,5)/'INCF','AC..'/
C     DATA VN(1,6),VN(2,6)/'RDFC','MN..'/
C     DATA VN(1,7),VN(2,7)/'RDFC','MX..'/
C     DATA VN(1,8),VN(2,8)/'TUNE','R1..'/
C     DATA VN(1,9),VN(2,9)/'TUNE','R2..'/
C     DATA VN(1,10),VN(2,10)/'TUNE','R3..'/
C     DATA VN(1,11),VN(2,11)/'TUNE','R4..'/
C     DATA VN(1,12),VN(2,12)/'TUNE','R5..'/
C     DATA VN(1,13),VN(2,13)/'AFCT','OL..'/
C     DATA VN(1,14),VN(2,14)/'RFCT','OL..'/
C     DATA VN(1,15),VN(2,15)/'XCTO','L...'/
C     DATA VN(1,16),VN(2,16)/'XFTO','L...'/
C     DATA VN(1,17),VN(2,17)/'LMAX','0...'/
C     DATA VN(1,18),VN(2,18)/'LMAX','S...'/
C     DATA VN(1,19),VN(2,19)/'SCTO','L...'/
C     DATA VN(1,20),VN(2,20)/'DINI','T...'/
C     DATA VN(1,21),VN(2,21)/'DTIN','IT..'/
C     DATA VN(1,22),VN(2,22)/'D0IN','IT..'/
C     DATA VN(1,23),VN(2,23)/'DFAC','....'/
C     DATA VN(1,24),VN(2,24)/'DLTF','DC..'/
C     DATA VN(1,25),VN(2,25)/'DLTF','DJ..'/
C     DATA VN(1,26),VN(2,26)/'DELT','A0..'/
C     DATA VN(1,27),VN(2,27)/'FUZZ','....'/
C     DATA VN(1,28),VN(2,28)/'RLIM','IT..'/
C     DATA VN(1,29),VN(2,29)/'COSM','IN..'/
C     DATA VN(1,30),VN(2,30)/'HUBE','RC..'/
C     DATA VN(1,31),VN(2,31)/'RSPT','OL..'/
C     DATA VN(1,32),VN(2,32)/'SIGM','IN..'/
C     DATA VN(1,33),VN(2,33)/'ETA0','....'/
C     DATA VN(1,34),VN(2,34)/'BIAS','....'/
C/
C
      DATA VM(1)/1.0D-3/, VM(2)/-0.99D+0/, VM(3)/1.0D-3/, VM(4)/1.0D-2/,
     1     VM(5)/1.2D+0/, VM(6)/1.D-2/, VM(7)/1.2D+0/, VM(8)/0.D+0/,
     2     VM(9)/0.D+0/, VM(10)/1.D-3/, VM(11)/-1.D+0/, VM(15)/0.D+0/,
     3     VM(16)/0.D+0/, VM(19)/0.D+0/, VM(20)/-10.D+0/, VM(21)/0.D+0/,
     4     VM(22)/0.D+0/, VM(23)/0.D+0/, VM(27)/1.01D+0/,
     5     VM(28)/1.D+10/, VM(30)/0.D+0/, VM(31)/0.D+0/, VM(32)/0.D+0/,
     6     VM(34)/0.D+0/
      DATA VX(1)/0.9D+0/, VX(2)/-1.D-3/, VX(3)/1.D+1/, VX(4)/0.8D+0/,
     1     VX(5)/1.D+2/, VX(6)/0.8D+0/, VX(7)/1.D+2/, VX(8)/0.5D+0/,
     2     VX(9)/0.5D+0/, VX(10)/1.D+0/, VX(11)/1.D+0/, VX(14)/0.1D+0/,
     3     VX(15)/1.D+0/, VX(16)/1.D+0/, VX(19)/1.D+0/, VX(23)/1.D+0/,
     4     VX(24)/1.D+0/, VX(25)/1.D+0/, VX(26)/1.D+0/, VX(27)/1.D+10/,
     5     VX(29)/1.D+0/, VX(31)/1.D+0/, VX(32)/1.D+0/, VX(33)/1.D+0/,
     6     VX(34)/1.D+0/
C
C/6
      DATA VARNM(1)/1HP/, VARNM(2)/1HN/, SH(1)/1HS/, SH(2)/1HH/
      DATA CNGD(1),CNGD(2),CNGD(3)/4H---C,4HHANG,4HED V/,
     1     DFLT(1),DFLT(2),DFLT(3)/4HNOND,4HEFAU,4HLT V/
C/7
C     DATA VARNM(1)/'P'/, VARNM(2)/'N'/, SH(1)/'S'/, SH(2)/'H'/
C     DATA CNGD(1),CNGD(2),CNGD(3)/'---C','HANG','ED V'/,
C    1     DFLT(1),DFLT(2),DFLT(3)/'NOND','EFAU','LT V'/
C/
      DATA IJMP/33/, JLIM(1)/0/, JLIM(2)/24/, NDFLT(1)/32/, NDFLT(2)/25/
      DATA MINIV(1)/80/, MINIV(2)/59/
C
C...............................  BODY  ................................
C
      IF (ALG .LT. 1 .OR. ALG .GT. 2) GO TO 330
      IF (IV(1) .EQ. 0) CALL DDEFLT(ALG, IV, LIV, LV, V)
      PU = IV(PRUNIT)
      MIV1 = MINIV(ALG)
      IF (PERM .LE. LIV) MIV1 = MAX0(MIV1, IV(PERM) - 1)
      IF (IVNEED .LE. LIV) MIV2 = MIV1 + MAX0(IV(IVNEED), 0)
      IF (LASTIV .LE. LIV) IV(LASTIV) = MIV2
      IF (LIV .LT. MIV1) GO TO 290
      IV(IVNEED) = 0
      IV(LASTV) = MAX0(IV(VNEED), 0) + IV(LMAT) - 1
      IF (LIV .LT. MIV2) GO TO 290
      IF (LV .LT. IV(LASTV)) GO TO 310
      IV(VNEED) = 0
      IF (ALG .EQ. IV(ALGSAV)) GO TO 20
         IF (PU .NE. 0) WRITE(PU,10) ALG, IV(ALGSAV)
 10      FORMAT(/' THE FIRST PARAMETER TO DDEFLT SHOULD BE',I3,
     1          12H RATHER THAN,I3)
         IV(1) = 82
         GO TO 999
 20   IV1 = IV(1)
      IF (IV1 .LT. 12 .OR. IV1 .GT. 14) GO TO 50
         IF (N .GE. 1) GO TO 40
              IV(1) = 81
              IF (PU .EQ. 0) GO TO 999
              WRITE(PU,30) VARNM(ALG), N
 30           FORMAT(/8H /// BAD,A1,2H =,I5)
              GO TO 999
 40      IF (IV1 .NE. 14) IV(NEXTIV) = IV(PERM)
         IF (IV1 .NE. 14) IV(NEXTV) = IV(LMAT)
         IF (IV1 .EQ. 13) GO TO 999
         K = IV(PARSAV) - EPSLON
         CALL DVDFLT(ALG, LV-K, V(K+1))
         IV(DTYPE0) = 2 - ALG
         IV(OLDN) = N
         WHICH(1) = DFLT(1)
         WHICH(2) = DFLT(2)
         WHICH(3) = DFLT(3)
         GO TO 100
 50   IF (N .EQ. IV(OLDN)) GO TO 70
         IV(1) = 17
         IF (PU .EQ. 0) GO TO 999
         WRITE(PU,60) VARNM(ALG), IV(OLDN), N
 60      FORMAT(/5H /// ,1A1,14H CHANGED FROM ,I5,4H TO ,I5)
         GO TO 999
C
 70   IF (IV1 .LE. 11 .AND. IV1 .GE. 1) GO TO 90
         IV(1) = 80
         IF (PU .NE. 0) WRITE(PU,80) IV1
 80      FORMAT(/13H ///  IV(1) =,I5,28H SHOULD BE BETWEEN 0 AND 14.)
         GO TO 999
C
 90   WHICH(1) = CNGD(1)
      WHICH(2) = CNGD(2)
      WHICH(3) = CNGD(3)
C
 100  IF (IV1 .EQ. 14) IV1 = 12
      IF (BIG .GT. TINY) GO TO 110
         TINY = D1MACH(1)
         MACHEP = D1MACH(4)
         BIG = D1MACH(2)
         VM(12) = MACHEP
         VX(12) = BIG
         VM(13) = TINY
         VX(13) = BIG
         VM(14) = MACHEP
         VM(17) = TINY
         VX(17) = BIG
         VM(18) = TINY
         VX(18) = BIG
         VX(20) = BIG
         VX(21) = BIG
         VX(22) = BIG
         VM(24) = MACHEP
         VM(25) = MACHEP
         VM(26) = MACHEP
         VX(28) = DSQRT(D1MACH(2))*16.
         VM(29) = MACHEP
         VX(30) = BIG
         VM(33) = MACHEP
 110  M = 0
      I = 1
      J = JLIM(ALG)
      K = EPSLON
      NDFALT = NDFLT(ALG)
      DO 140 L = 1, NDFALT
         VK = V(K)
         IF (VK .GE. VM(I) .AND. VK .LE. VX(I)) GO TO 130
              M = K
              IF (PU .NE. 0) WRITE(PU,120) VN(1,I), VN(2,I), K, VK,
     1                                    VM(I), VX(I)
 120          FORMAT(/6H ///  ,2A4,5H.. V(,I2,3H) =,D11.3,7H SHOULD,
     1               11H BE BETWEEN,D11.3,4H AND,D11.3)
 130     K = K + 1
         I = I + 1
         IF (I .EQ. J) I = IJMP
 140     CONTINUE
C
      IF (IV(NVDFLT) .EQ. NDFALT) GO TO 160
         IV(1) = 51
         IF (PU .EQ. 0) GO TO 999
         WRITE(PU,150) IV(NVDFLT), NDFALT
 150     FORMAT(/13H IV(NVDFLT) =,I5,13H RATHER THAN ,I5)
         GO TO 999
 160  IF ((IV(DTYPE) .GT. 0 .OR. V(DINIT) .GT. ZERO) .AND. IV1 .EQ. 12)
     1                  GO TO 190
      DO 180 I = 1, N
         IF (D(I) .GT. ZERO) GO TO 180
              M = 18
              IF (PU .NE. 0) WRITE(PU,170) I, D(I)
 170     FORMAT(/8H ///  D(,I3,3H) =,D11.3,19H SHOULD BE POSITIVE)
 180     CONTINUE
 190  IF (M .EQ. 0) GO TO 200
         IV(1) = M
         GO TO 999
C
 200  IF (PU .EQ. 0 .OR. IV(PARPRT) .EQ. 0) GO TO 999
      IF (IV1 .NE. 12 .OR. IV(INITS) .EQ. ALG-1) GO TO 220
         M = 1
         WRITE(PU,210) SH(ALG), IV(INITS)
 210     FORMAT(/22H NONDEFAULT VALUES..../5H INIT,A1,14H..... IV(25) =,
     1          I3)
 220  IF (IV(DTYPE) .EQ. IV(DTYPE0)) GO TO 240
         IF (M .EQ. 0) WRITE(PU,250) WHICH
         M = 1
         WRITE(PU,230) IV(DTYPE)
 230     FORMAT(20H DTYPE..... IV(16) =,I3)
 240  I = 1
      J = JLIM(ALG)
      K = EPSLON
      L = IV(PARSAV)
      NDFALT = NDFLT(ALG)
      DO 280 II = 1, NDFALT
         IF (V(K) .EQ. V(L)) GO TO 270
              IF (M .EQ. 0) WRITE(PU,250) WHICH
 250          FORMAT(/1H ,3A4,9HALUES..../)
              M = 1
              WRITE(PU,260) VN(1,I), VN(2,I), K, V(K)
 260          FORMAT(1X,2A4,5H.. V(,I2,3H) =,D15.7)
 270     K = K + 1
         L = L + 1
         I = I + 1
         IF (I .EQ. J) I = IJMP
 280     CONTINUE
C
      IV(DTYPE0) = IV(DTYPE)
      PARSV1 = IV(PARSAV)
      CALL DCOPY(IV(NVDFLT), V(EPSLON),1,V(PARSV1),1)
      GO TO 999
C
 290  IV(1) = 15
      IF (PU .EQ. 0) GO TO 999
      WRITE(PU,300) LIV, MIV2
 300  FORMAT(/10H /// LIV =,I5,17H MUST BE AT LEAST,I5)
      IF (LIV .LT. MIV1) GO TO 999
      IF (LV .LT. IV(LASTV)) GO TO 310
      GO TO 999
C
 310  IV(1) = 16
      IF (PU .EQ. 0) GO TO 999
      WRITE(PU,320) LV, IV(LASTV)
 320  FORMAT(/9H /// LV =,I5,17H MUST BE AT LEAST,I5)
      GO TO 999
C
 330  IV(1) = 67
C
 999  RETURN
C  ***  LAST CARD OF DPARCK FOLLOWS  ***
      END
      DOUBLE PRECISION FUNCTION DRELST(P, D, X, X0)
      save
C
C  ***  COMPUTE AND RETURN RELATIVE DIFFERENCE BETWEEN X AND X0  ***
C  ***  NL2SOL VERSION 2.2  ***
C
      INTEGER P
      DOUBLE PRECISION D(P), X(P), X0(P)
C/+
      DOUBLE PRECISION DABS
C/
      INTEGER I
      DOUBLE PRECISION EMAX, T, XMAX, ZERO
C/6
      DATA ZERO/0.D+0/
C/7
C     PARAMETER (ZERO=0.D+0)
C/
C
      EMAX = ZERO
      XMAX = ZERO
      DO 10 I = 1, P
         T = DABS(D(I) * (X(I) - X0(I)))
         IF (EMAX .LT. T) EMAX = T
         T = D(I) * (DABS(X(I)) + DABS(X0(I)))
         IF (XMAX .LT. T) XMAX = T
 10      CONTINUE
      DRELST = ZERO
      IF (XMAX .GT. ZERO) DRELST = EMAX / XMAX
 999  RETURN
C  ***  LAST CARD OF DRELST FOLLOWS  ***
      END
      LOGICAL FUNCTION DSTOPX(IDUMMY)
      save
C     *****PARAMETERS...
      INTEGER IDUMMY
C
C     ..................................................................
C
C     *****PURPOSE...
C     THIS FUNCTION MAY SERVE AS THE DSTOPX (ASYNCHRONOUS INTERRUPTION)
C     FUNCTION FOR THE NL2SOL (NONLINEAR LEAST-SQUARES) PACKAGE AT
C     THOSE INSTALLATIONS WHICH DO NOT WISH TO IMPLEMENT A
C     DYNAMIC DSTOPX.
C
C     *****ALGORITHM NOTES...
C     AT INSTALLATIONS WHERE THE NL2SOL SYSTEM IS USED
C     INTERACTIVELY, THIS DUMMY DSTOPX SHOULD BE REPLACED BY A
C     FUNCTION THAT RETURNS .TRUE. IF AND ONLY IF THE INTERRUPT
C     (BREAK) KEY HAS BEEN PRESSED SINCE THE LAST CALL ON DSTOPX.
C
C     ..................................................................
C
      DSTOPX = .FALSE.
      RETURN
      END
      SUBROUTINE FDUMP
      save
C***BEGIN PROLOGUE  FDUMP
C***DATE WRITTEN   790801   (YYMMDD)
C***REVISION DATE  820801   (YYMMDD)
C***CATEGORY NO.  Z
C***KEYWORDS  ERROR,XERROR PACKAGE
C***AUTHOR  JONES, R. E., (SNLA)
C***PURPOSE  Symbolic dump (should be locally written).
C***DESCRIPTION
C        ***Note*** Machine Dependent Routine
C        FDUMP is intended to be replaced by a locally written
C        version which produces a symbolic dump.  Failing this,
C        it should be replaced by a version which prints the
C        subprogram nesting list.  Note that this dump must be
C        printed on each of up to five files, as indicated by the
C        XGETUA routine.  See XSETUA and XGETUA for details.
C
C     Written by Ron Jones, with SLATEC Common Math Library Subcommittee
C     Latest revision ---  23 May 1979
C***ROUTINES CALLED  (NONE)
C***END PROLOGUE  FDUMP
C***FIRST EXECUTABLE STATEMENT  FDUMP
      RETURN
      END
      FUNCTION J4SAVE(IWHICH,IVALUE,ISET)
      save
C***BEGIN PROLOGUE  J4SAVE
C***REFER TO  XERROR
C     Abstract
C        J4SAVE saves and recalls several global variables needed
C        by the library error handling routines.
C
C     Description of Parameters
C      --Input--
C        IWHICH - Index of item desired.
C                = 1 Refers to current error number.
C                = 2 Refers to current error control flag.
C                 = 3 Refers to current unit number to which error
C                    messages are to be sent.  (0 means use standard.)
C                 = 4 Refers to the maximum number of times any
C                     message is to be printed (as set by XERMAX).
C                 = 5 Refers to the total number of units to which
C                     each error message is to be written.
C                 = 6 Refers to the 2nd unit for error messages
C                 = 7 Refers to the 3rd unit for error messages
C                 = 8 Refers to the 4th unit for error messages
C                 = 9 Refers to the 5th unit for error messages
C        IVALUE - The value to be set for the IWHICH-th parameter,
C                 if ISET is .TRUE. .
C        ISET   - If ISET=.TRUE., the IWHICH-th parameter will BE
C                 given the value, IVALUE.  If ISET=.FALSE., the
C                 IWHICH-th parameter will be unchanged, and IVALUE
C                 is a dummy parameter.
C      --Output--
C        The (old) value of the IWHICH-th parameter will be returned
C        in the function value, J4SAVE.
C
C     Written by Ron Jones, with SLATEC Common Math Library Subcommittee
C    Adapted from Bell Laboratories PORT Library Error Handler
C     Latest revision ---  23 MAY 1979
C***REFERENCES  JONES R.E., KAHANER D.K., "XERROR, THE SLATEC ERROR-
C                 HANDLING PACKAGE", SAND82-0800, SANDIA LABORATORIES,
C                 1982.
C***ROUTINES CALLED  (NONE)
C***END PROLOGUE  J4SAVE
      LOGICAL ISET
      INTEGER IPARAM(9)
      SAVE IPARAM
      DATA IPARAM(1),IPARAM(2),IPARAM(3),IPARAM(4)/0,2,0,10/
      DATA IPARAM(5)/1/
      DATA IPARAM(6),IPARAM(7),IPARAM(8),IPARAM(9)/0,0,0,0/
C***FIRST EXECUTABLE STATEMENT  J4SAVE
      J4SAVE = IPARAM(IWHICH)
      IF (ISET) IPARAM(IWHICH) = IVALUE
      RETURN
      END
      SUBROUTINE XERABT(MESSG,NMESSG)
      save
C***BEGIN PROLOGUE  XERABT
C***DATE WRITTEN   790801   (YYMMDD)
C***REVISION DATE  820801   (YYMMDD)
C***CATEGORY NO.  R3C
C***KEYWORDS  ERROR,XERROR PACKAGE
C***AUTHOR  JONES, R. E., (SNLA)
C***PURPOSE  Aborts program execution and prints error message.
C***DESCRIPTION
C     Abstract
C        ***Note*** machine dependent routine
C        XERABT aborts the execution of the program.
C        The error message causing the abort is given in the calling
C        sequence, in case one needs it for printing on a dayfile,
C        for example.
C
C     Description of Parameters
C        MESSG and NMESSG are as in XERROR, except that NMESSG may
C        be zero, in which case no message is being supplied.
C
C     Written by Ron Jones, with SLATEC Common Math Library Subcommittee
C     Latest revision ---  19 MAR 1980
C***REFERENCES  JONES R.E., KAHANER D.K., "XERROR, THE SLATEC ERROR-
C                 HANDLING PACKAGE", SAND82-0800, SANDIA LABORATORIES,
C                 1982.
C***ROUTINES CALLED  (NONE)
C***END PROLOGUE  XERABT
      CHARACTER*(*) MESSG
C      EXTERNAL ERROR
C***FIRST EXECUTABLE STATEMENT  XERABT
C      CALL ERROR('dsumsl(), dsmsno() aborted\n')
      END
      SUBROUTINE XERCTL(MESSG1,NMESSG,NERR,LEVEL,KONTRL)
      save
C***BEGIN PROLOGUE  XERCTL
C***DATE WRITTEN   790801   (YYMMDD)
C***REVISION DATE  820801   (YYMMDD)
C***CATEGORY NO.  R3C
C***KEYWORDS  ERROR,XERROR PACKAGE
C***AUTHOR  JONES, R. E., (SNLA)
C***PURPOSE  Allows user control over handling of individual errors.
C***DESCRIPTION
C     Abstract
C        Allows user control over handling of individual errors.
C        Just after each message is recorded, but before it is
C        processed any further (i.e., before it is printed or
C        a decision to abort is made), a call is made to XERCTL.
C        If the user has provided his own version of XERCTL, he
C        can then override the value of KONTROL used in processing
C        this message by redefining its value.
C        KONTRL may be set to any value from -2 to 2.
C        The meanings for KONTRL are the same as in XSETF, except
C        that the value of KONTRL changes only for this message.
C        If KONTRL is set to a value outside the range from -2 to 2,
C        it will be moved back into that range.
C
C     Description of Parameters
C
C      --Input--
C        MESSG1 - the first word (only) of the error message.
C        NMESSG - same as in the call to XERROR or XERRWV.
C        NERR   - same as in the call to XERROR or XERRWV.
C        LEVEL  - same as in the call to XERROR or XERRWV.
C        KONTRL - the current value of the control flag as set
C                 by a call to XSETF.
C
C      --Output--
C        KONTRL - the new value of KONTRL.  If KONTRL is not
C                 defined, it will remain at its original value.
C                 This changed value of control affects only
C                 the current occurrence of the current message.
C***REFERENCES  JONES R.E., KAHANER D.K., "XERROR, THE SLATEC ERROR-
C                 HANDLING PACKAGE", SAND82-0800, SANDIA LABORATORIES,
C                 1982.
C***ROUTINES CALLED  (NONE)
C***END PROLOGUE  XERCTL
      CHARACTER*20 MESSG1
C***FIRST EXECUTABLE STATEMENT  XERCTL
      RETURN
      END
      SUBROUTINE XERPRT(MESSG,NMESSG)
      save
C***BEGIN PROLOGUE  XERPRT
C***DATE WRITTEN   790801   (YYMMDD)
C***REVISION DATE  820801   (YYMMDD)
C***CATEGORY NO.  Z
C***KEYWORDS  ERROR,XERROR PACKAGE
C***AUTHOR  JONES, R. E., (SNLA)
C***PURPOSE  Prints error messages.
C***DESCRIPTION
C     Abstract
C        Print the Hollerith message in MESSG, of length NMESSG,
C        on each file indicated by XGETUA.
C     Latest revision ---  19 MAR 1980
C***REFERENCES  JONES R.E., KAHANER D.K., "XERROR, THE SLATEC ERROR-
C                 HANDLING PACKAGE", SAND82-0800, SANDIA LABORATORIES,
C                 1982.
C***ROUTINES CALLED  I1MACH,S88FMT,XGETUA
C***END PROLOGUE  XERPRT
      INTEGER LUN(5)
      CHARACTER*(*) MESSG
C     OBTAIN UNIT NUMBERS AND WRITE LINE TO EACH UNIT
C***FIRST EXECUTABLE STATEMENT  XERPRT
      CALL XGETUA(LUN,NUNIT)
      LENMES = LEN(MESSG)
      DO 20 KUNIT=1,NUNIT
         IUNIT = LUN(KUNIT)
         IF (IUNIT.EQ.0) IUNIT = I1MACH(4)
         DO 10 ICHAR=1,LENMES,72
            LAST = MIN0(ICHAR+71 , LENMES)
            WRITE (IUNIT,'(1X,A)') MESSG(ICHAR:LAST)
   10    CONTINUE
   20 CONTINUE
      RETURN
      END
      SUBROUTINE DSMSNO(N, D, X, CALCF, IV, LIV, LV, V,
     1                  UIPARM, URPARM, UFPARM)
      save
C
C  ***  MINIMIZE GENERAL UNCONSTRAINED OBJECTIVE FUNCTION USING
C  ***  FINITE-DIFFERENCE GRADIENTS AND SECANT HESSIAN APPROXIMATIONS.
C
      INTEGER N, LIV, LV
      INTEGER IV(LIV), UIPARM(1)
      DOUBLE PRECISION D(N), X(N), V(LV), URPARM(1)
C     DIMENSION V(77 + N*(N+17)/2), UIPARM(*), URPARM(*)
      EXTERNAL CALCF, UFPARM
C
C  ***  PURPOSE  ***
C
C        THIS ROUTINE INTERACTS WITH SUBROUTINE  DSNOIT  IN AN ATTEMPT
C     TO FIND AN N-VECTOR  X*  THAT MINIMIZES THE (UNCONSTRAINED)
C     OBJECTIVE FUNCTION COMPUTED BY  CALCF.  (OFTEN THE  X*  FOUND IS
C     A LOCAL MINIMIZER RATHER THAN A GLOBAL ONE.)
C
C  ***  PARAMETERS  ***
C
C        THE PARAMETERS FOR DSMSNO ARE THE SAME AS THOSE FOR DSUMSL
C     (WHICH SEE), EXCEPT THAT CALCG IS OMITTED.  INSTEAD OF CALLING
C     CALCG TO OBTAIN THE GRADIENT OF THE OBJECTIVE FUNCTION AT X,
C     DSMSNO CALLS DSGRD2, WHICH COMPUTES AN APPROXIMATION TO THE
C     GRADIENT BY FINITE (FORWARD AND CENTRAL) DIFFERENCES USING THE
C     METHOD OF REF. 1.  THE FOLLOWING INPUT COMPONENT IS OF INTEREST
C     IN THIS REGARD (AND IS NOT DESCRIBED IN DSUMSL).
C
C V(ETA0)..... V(42) IS AN ESTIMATED BOUND ON THE RELATIVE ERROR IN THE
C             OBJECTIVE FUNCTION VALUE COMPUTED BY CALCF...
C                  (TRUE VALUE) = (COMPUTED VALUE) * (1 + E),
C             WHERE ABS(E) .LE. V(ETA0).  DEFAULT = MACHEP * 10**3,
C             WHERE MACHEP IS THE UNIT ROUNDOFF.
C
C        THE OUTPUT VALUES IV(NFCALL) AND IV(NGCALL) HAVE DIFFERENT
C     MEANINGS FOR DSMSNO THAN FOR DSUMSL...
C
C IV(NFCALL)... IV(6) IS THE NUMBER OF CALLS SO FAR MADE ON CALCF (I.E.,
C             FUNCTION EVALUATIONS) EXCLUDING THOSE MADE ONLY FOR
C             COMPUTING GRADIENTS.  THE INPUT VALUE IV(MXFCAL) IS A
C             LIMIT ON IV(NFCALL).
C IV(NGCALL)... IV(30) IS THE NUMBER OF FUNCTION EVALUATIONS MADE ONLY
C             FOR COMPUTING GRADIENTS.  THE TOTAL NUMBER OF FUNCTION
C             EVALUATIONS IS THUS  IV(NFCALL) + IV(NGCALL).
C
C  ***  REFERENCES  ***
C
C 1. STEWART, G.W. (1967), A MODIFICATION OF DAVIDON*S MINIMIZATION
C        METHOD TO ACCEPT DIFFERENCE APPROXIMATIONS OF DERIVATIVES,
C        J. ASSOC. COMPUT. MACH. 14, PP. 72-83.
C.
C  ***  GENERAL  ***
C
C     CODED BY DAVID M. GAY (WINTER 1980).  REVISED SEPT. 1982.
C     THIS SUBROUTINE WAS WRITTEN IN CONNECTION WITH RESEARCH
C     SUPPORTED IN PART BY THE NATIONAL SCIENCE FOUNDATION UNDER
C     GRANTS MCS-7600324, DCR75-10143, 76-14311DSS, MCS76-11989,
C     AND MCS-7906671.
C
C
C----------------------------  DECLARATIONS  ---------------------------
C
      EXTERNAL DSNOIT
C
C DSNOIT.... OVERSEES COMPUTATION OF FINITE-DIFFERENCE GRADIENT AND
C         CALLS DSUMIT TO CARRY OUT DSUMSL ALGORITHM.
C
      INTEGER NF
      DOUBLE PRECISION FX
C
C  ***  SUBSCRIPTS FOR IV   ***
C
      INTEGER NFCALL, TOOBIG
C
C/6
      DATA NFCALL/6/, TOOBIG/2/
C/7
C     PARAMETER (NFCALL=6, TOOBIG=2)
C/
C
C+++++++++++++++++++++++++++++++  BODY  ++++++++++++++++++++++++++++++++
C
 10   CALL DSNOIT(D, FX, IV, LIV, LV, N, V, X)
      IF (IV(1) .GT. 2) GO TO 999
C
C     ***  COMPUTE FUNCTION  ***
C
      NF = IV(NFCALL)
      CALL CALCF(N, X, NF, FX, UIPARM, URPARM, UFPARM)
      IF (NF .LE. 0) IV(TOOBIG) = 1
      GO TO 10
C
C
 999  RETURN
C  ***  LAST CARD OF DSMSNO FOLLOWS  ***
      END
      SUBROUTINE DSNOIT(D, FX, IV, LIV, LV, N, V, X)
      save
C
C  ***  ITERATION DRIVER FOR DSMSNO...
C  ***  MINIMIZE GENERAL UNCONSTRAINED OBJECTIVE FUNCTION USING
C  ***  FINITE-DIFFERENCE GRADIENTS AND SECANT HESSIAN APPROXIMATIONS.
C
      INTEGER LIV, LV, N
      INTEGER IV(LIV)
      DOUBLE PRECISION D(N), FX, X(N), V(LV)
C     DIMENSION V(77 + N*(N+17)/2)
C
C  ***  PURPOSE  ***
C
C        THIS ROUTINE INTERACTS WITH SUBROUTINE  DSUMIT  IN AN ATTEMPT
C     TO FIND AN N-VECTOR  X*  THAT MINIMIZES THE (UNCONSTRAINED)
C     OBJECTIVE FUNCTION  FX = F(X)  COMPUTED BY THE CALLER.  (OFTEN
C     THE  X*  FOUND IS A LOCAL MINIMIZER RATHER THAN A GLOBAL ONE.)
C
C  ***  PARAMETERS  ***
C
C        THE PARAMETERS FOR DSNOIT ARE THE SAME AS THOSE FOR DSUMSL
C     (WHICH SEE), EXCEPT THAT CALCF, CALCG, UIPARM, URPARM, AND UFPARM
C     ARE OMITTED, AND A PARAMETER  FX  FOR THE OBJECTIVE FUNCTION
C     VALUE AT X IS ADDED.  INSTEAD OF CALLING CALCG TO OBTAIN THE
C     GRADIENT OF THE OBJECTIVE FUNCTION AT X, DSNOIT CALLS DSGRD2,
C     WHICH COMPUTES AN APPROXIMATION TO THE GRADIENT BY FINITE
C     (FORWARD AND CENTRAL) DIFFERENCES USING THE METHOD OF REF. 1.
C     THE FOLLOWING INPUT COMPONENT IS OF INTEREST IN THIS REGARD
C     (AND IS NOT DESCRIBED IN DSUMSL).
C
C V(ETA0)..... V(42) IS AN ESTIMATED BOUND ON THE RELATIVE ERROR IN THE
C             OBJECTIVE FUNCTION VALUE COMPUTED BY CALCF...
C                  (TRUE VALUE) = (COMPUTED VALUE) * (1 + E),
C             WHERE ABS(E) .LE. V(ETA0).  DEFAULT = MACHEP * 10**3,
C             WHERE MACHEP IS THE UNIT ROUNDOFF.
C
C        THE OUTPUT VALUES IV(NFCALL) AND IV(NGCALL) HAVE DIFFERENT
C     MEANINGS FOR DSMSNO THAN FOR DSUMSL...
C
C IV(NFCALL)... IV(6) IS THE NUMBER OF CALLS SO FAR MADE ON CALCF (I.E.,
C             FUNCTION EVALUATIONS) EXCLUDING THOSE MADE ONLY FOR
C             COMPUTING GRADIENTS.  THE INPUT VALUE IV(MXFCAL) IS A
C             LIMIT ON IV(NFCALL).
C IV(NGCALL)... IV(30) IS THE NUMBER OF FUNCTION EVALUATIONS MADE ONLY
C             FOR COMPUTING GRADIENTS.  THE TOTAL NUMBER OF FUNCTION
C             EVALUATIONS IS THUS  IV(NFCALL) + IV(NGCALL).
C
C  ***  REFERENCES  ***
C
C 1. STEWART, G.W. (1967), A MODIFICATION OF DAVIDON*S MINIMIZATION
C        METHOD TO ACCEPT DIFFERENCE APPROXIMATIONS OF DERIVATIVES,
C        J. ASSOC. COMPUT. MACH. 14, PP. 72-83.
C.
C  ***  GENERAL  ***
C
C     CODED BY DAVID M. GAY (AUGUST 1982).
C
C----------------------------  DECLARATIONS  ---------------------------
C
      EXTERNAL DDEFLT, DSGRD2, DSUMIT, DVSCPY
      DOUBLE PRECISION DDOT
C
C DDEFLT.... SUPPLIES DEFAULT PARAMETER VALUES.
C DSGRD2... COMPUTES FINITE-DIFFERENCE GRADIENT APPROXIMATION.
C DSUMIT.... REVERSE-COMMUNICATION ROUTINE THAT DOES DSUMSL ALGORITHM.
C DVSCPY... SETS ALL ELEMENTS OF A VECTOR TO A SCALAR.
C
      INTEGER ALPHA, G1, I, IV1, J, K, W
      DOUBLE PRECISION ZERO
C
C  ***  SUBSCRIPTS FOR IV   ***
C
      INTEGER ETA0, F, G, LMAT, NEXTV, NFGCAL, NGCALL,
     1        NITER, SGIRC, TOOBIG, VNEED
C
C/6
      DATA ETA0/42/, F/10/, G/28/, LMAT/42/, NEXTV/47/,
     1     NFGCAL/7/, NGCALL/30/, NITER/31/, SGIRC/57/,
     2     TOOBIG/2/, VNEED/4/
C/7
C     PARAMETER (DTYPE=16, ETA0=42, F=10, G=28, LMAT=42, NEXTV=47,
C    1           NFCALL=6, NFGCAL=7, NGCALL=30, NITER=31, SGIRC=57,
C    2           TOOBIG=2, VNEED=4)
C/
C/6
      DATA ZERO/0.D+0/
C/7
C     PARAMETER (ONE=1.D+0, ZERO=0.D+0)
C/
C
C+++++++++++++++++++++++++++++++  BODY  ++++++++++++++++++++++++++++++++
C
      IV1 = IV(1)
      IF (IV1 .EQ. 1) GO TO 10
      IF (IV1 .EQ. 2) GO TO 50
      IF (IV(1) .EQ. 0) CALL DDEFLT(2, IV, LIV, LV, V)
      IV(VNEED) = IV(VNEED) + 2*N + 6
      IV1 = IV(1)
      IF (IV1 .EQ. 14) GO TO 10
      IF (IV1 .GT. 2 .AND. IV1 .LT. 12) GO TO 10
      G1 = 1
      IF (IV1 .EQ. 12) IV(1) = 13
      GO TO 20
C
 10   G1 = IV(G)
C
 20   CALL DSUMIT(D, FX, V(G1), IV, LIV, LV, N, V, X)
      IF (IV(1) - 2) 999, 30, 70
C
C  ***  COMPUTE GRADIENT  ***
C
 30   IF (IV(NITER) .EQ. 0) CALL DVSCPY(N, V(G1), ZERO)
      J = IV(LMAT)
      K = G1 - N
      DO 40 I = 1, N
         V(K) = DDOT(I, V(J),1,V(J),1)
         K = K + 1
         J = J + I
 40      CONTINUE
C     ***  UNDO INCREMENT OF IV(NGCALL) DONE BY DSUMIT  ***
      IV(NGCALL) = IV(NGCALL) - 1
C     ***  STORE RETURN CODE FROM DSGRD2 IN IV(SGIRC)  ***
      IV(SGIRC) = 0
C     ***  X MAY HAVE BEEN RESTORED, SO COPY BACK FX... ***
      FX = V(F)
      GO TO 60
C
C     ***  GRADIENT LOOP  ***
C
 50   IF (IV(TOOBIG) .EQ. 0) GO TO 60
      IV(NFGCAL) = 0
      GO TO 10
C
 60   G1 = IV(G)
      ALPHA = G1 - N
      W = ALPHA - 6
      CALL DSGRD2(V(ALPHA), D, V(ETA0), FX, V(G1), IV(SGIRC), N, V(W),X)
      IF (IV(SGIRC) .EQ. 0) GO TO 10
         IV(NGCALL) = IV(NGCALL) + 1
         GO TO 999
C
 70   IF (IV(1) .NE. 14) GO TO 999
C
C  ***  STORAGE ALLOCATION  ***
C
      IV(G) = IV(NEXTV) + N + 6
      IV(NEXTV) = IV(G) + N
      IF (IV1 .NE. 13) GO TO 10
C
 999  RETURN
C  ***  LAST CARD OF DSNOIT FOLLOWS  ***
      END
      SUBROUTINE DSGRD2 (ALPHA, D, ETA0, FX, G, IRC, N, W, X)
      save
C
C  ***  COMPUTE FINITE DIFFERENCE GRADIENT BY STWEART*S SCHEME  ***
C
C     ***  PARAMETERS  ***
C
      INTEGER IRC, N
      DOUBLE PRECISION ALPHA(N), D(N), ETA0, FX, G(N), W(6), X(N)
C
C.......................................................................
C
C     ***  PURPOSE  ***
C
C        THIS SUBROUTINE USES AN EMBELLISHED FORM OF THE FINITE-DIFFER-
C     ENCE SCHEME PROPOSED BY STEWART (REF. 1) TO APPROXIMATE THE
C     GRADIENT OF THE FUNCTION F(X), WHOSE VALUES ARE SUPPLIED BY
C     REVERSE COMMUNICATION.
C
C     ***  PARAMETER DESCRIPTION  ***
C
C  ALPHA IN  (APPROXIMATE) DIAGONAL ELEMENTS OF THE HESSIAN OF F(X).
C      D IN  SCALE VECTOR SUCH THAT D(I)*X(I), I = 1,...,N, ARE IN
C             COMPARABLE UNITS.
C   ETA0 IN  ESTIMATED BOUND ON RELATIVE ERROR IN THE FUNCTION VALUE...
C             (TRUE VALUE) = (COMPUTED VALUE)*(1+E),   WHERE
C             ABS(E) .LE. ETA0.
C     FX I/O ON INPUT,  FX  MUST BE THE COMPUTED VALUE OF F(X).  ON
C             OUTPUT WITH IRC = 0, FX HAS BEEN RESTORED TO ITS ORIGINAL
C             VALUE, THE ONE IT HAD WHEN DSGRD2 WAS LAST CALLED WITH
C             IRC = 0.
C      G I/O ON INPUT WITH IRC = 0, G SHOULD CONTAIN AN APPROXIMATION
C             TO THE GRADIENT OF F NEAR X, E.G., THE GRADIENT AT THE
C             PREVIOUS ITERATE.  WHEN DSGRD2 RETURNS WITH IRC = 0, G IS
C             THE DESIRED FINITE-DIFFERENCE APPROXIMATION TO THE
C             GRADIENT AT X.
C    IRC I/O INPUT/RETURN CODE... BEFORE THE VERY FIRST CALL ON DSGRD2,
C             THE CALLER MUST SET IRC TO 0.  WHENEVER DSGRD2 RETURNS A
C             NONZERO VALUE FOR IRC, IT HAS PERTURBED SOME COMPONENT OF
C             X... THE CALLER SHOULD EVALUATE F(X) AND CALL DSGRD2
C             AGAIN WITH FX = F(X).
C      N IN  THE NUMBER OF VARIABLES (COMPONENTS OF X) ON WHICH F
C             DEPENDS.
C      X I/O ON INPUT WITH IRC = 0, X IS THE POINT AT WHICH THE
C             GRADIENT OF F IS DESIRED.  ON OUTPUT WITH IRC NONZERO, X
C             IS THE POINT AT WHICH F SHOULD BE EVALUATED.  ON OUTPUT
C             WITH IRC = 0, X HAS BEEN RESTORED TO ITS ORIGINAL VALUE
C             (THE ONE IT HAD WHEN DSGRD2 WAS LAST CALLED WITH IRC = 0)
C             AND G CONTAINS THE DESIRED GRADIENT APPROXIMATION.
C      W I/O WORK VECTOR OF LENGTH 6 IN WHICH DSGRD2 SAVES CERTAIN
C             QUANTITIES WHILE THE CALLER IS EVALUATING F(X) AT A
C             PERTURBED X.
C
C     ***  APPLICATION AND USAGE RESTRICTIONS  ***
C
C        THIS ROUTINE IS INTENDED FOR USE WITH QUASI-NEWTON ROUTINES
C     FOR UNCONSTRAINED MINIMIZATION (IN WHICH CASE  ALPHA  COMES FROM
C     THE DIAGONAL OF THE QUASI-NEWTON HESSIAN APPROXIMATION).
C
C     ***  ALGORITHM NOTES  ***
C
C        THIS CODE DEPARTS FROM THE SCHEME PROPOSED BY STEWART (REF. 1)
C     IN ITS GUARDING AGAINST OVERLY LARGE OR SMALL STEP SIZES AND ITS
C     HANDLING OF SPECIAL CASES (SUCH AS ZERO COMPONENTS OF ALPHA OR G).
C
C     ***  REFERENCES  ***
C
C 1. STEWART, G.W. (1967), A MODIFICATION OF DAVIDON*S MINIMIZATION
C        METHOD TO ACCEPT DIFFERENCE APPROXIMATIONS OF DERIVATIVES,
C        J. ASSOC. COMPUT. MACH. 14, PP. 72-83.
C
C     ***  HISTORY  ***
C
C     DESIGNED AND CODED BY DAVID M. GAY (SUMMER 1977/SUMMER 1980).
C
C     ***  GENERAL  ***
C
C        THIS ROUTINE WAS PREPARED IN CONNECTION WITH WORK SUPPORTED BY
C     THE NATIONAL SCIENCE FOUNDATION UNDER GRANTS MCS76-00324 AND
C     MCS-7906671.
C
C.......................................................................
C
C     *****  EXTERNAL FUNCTION  *****
C
      DOUBLE PRECISION D1MACH
C
C     ***** INTRINSIC FUNCTIONS *****
C/+
      INTEGER IABS
      DOUBLE PRECISION DABS, DMAX1, DSQRT
C/
C     ***** LOCAL VARIABLES *****
C
      INTEGER FH, FX0, HSAVE, I, XISAVE
      DOUBLE PRECISION AAI, AFX, AFXETA, AGI, ALPHAI, AXI, AXIBAR,
     1                 DISCON, ETA, GI, H, HMIN
      DOUBLE PRECISION C2000, FOUR, HMAX0, HMIN0, H0, MACHEP, ONE, P002,
     1                 THREE, TWO, ZERO
C
C/6
      DATA C2000/2.0D+3/, FOUR/4.0D+0/, HMAX0/0.02D+0/, HMIN0/5.0D+1/,
     1     ONE/1.0D+0/, P002/0.002D+0/, THREE/3.0D+0/,
     2     TWO/2.0D+0/, ZERO/0.0D+0/
C/7
C     PARAMETER (C2000=2.0D+3, FOUR=4.0D+0, HMAX0=0.02D+0, HMIN0=5.0D+1,
C    1     ONE=1.0D+0, P002=0.002D+0, THREE=3.0D+0,
C    2     TWO=2.0D+0, ZERO=0.0D+0)
C/
C/6
      DATA FH/3/, FX0/4/, HSAVE/5/, XISAVE/6/
C/7
C     PARAMETER (FH=3, FX0=4, HSAVE=5, XISAVE=6)
C/
C
C---------------------------------  BODY  ------------------------------
C
      IF (IRC) 140, 100, 210
C
C     ***  FRESH START -- GET MACHINE-DEPENDENT CONSTANTS  ***
C
C     STORE MACHEP IN W(1) AND H0 IN W(2), WHERE MACHEP IS THE UNIT
C     ROUNDOFF (THE SMALLEST POSITIVE NUMBER SUCH THAT
C     1 + MACHEP .GT. 1  AND  1 - MACHEP .LT. 1),  AND  H0 IS THE
C     SQUARE-ROOT OF MACHEP.
C
 100  W(1) = D1MACH(4)
      W(2) = DSQRT(W(1))
C
      W(FX0) = FX
C
C     ***  INCREMENT  I  AND START COMPUTING  G(I)  ***
C
 110  I = IABS(IRC) + 1
      IF (I .GT. N) GO TO 300
         IRC = I
         AFX = DABS(W(FX0))
         MACHEP = W(1)
         H0 = W(2)
         HMIN = HMIN0 * MACHEP
         W(XISAVE) = X(I)
         AXI = DABS(X(I))
         AXIBAR = DMAX1(AXI, ONE/D(I))
         GI = G(I)
         AGI = DABS(GI)
         ETA = DABS(ETA0)
         IF (AFX .GT. ZERO) ETA = DMAX1(ETA, AGI*AXI*MACHEP/AFX)
         ALPHAI = ALPHA(I)
         IF (ALPHAI .EQ. ZERO) GO TO 170
         IF (GI .EQ. ZERO .OR. FX .EQ. ZERO) GO TO 180
         AFXETA = AFX*ETA
         AAI = DABS(ALPHAI)
C
C        *** COMPUTE H = STEWART*S FORWARD-DIFFERENCE STEP SIZE.
C
         IF (GI**2 .LE. AFXETA*AAI) GO TO 120
              H = TWO*DSQRT(AFXETA/AAI)
              H = H*(ONE - AAI*H/(THREE*AAI*H + FOUR*AGI))
              GO TO 130
 120     H = TWO*(AFXETA*AGI/(AAI**2))**(ONE/THREE)
         H = H*(ONE - TWO*AGI/(THREE*AAI*H + FOUR*AGI))
C
C        ***  ENSURE THAT  H  IS NOT INSIGNIFICANTLY SMALL  ***
C
 130     H = DMAX1(H, HMIN*AXIBAR)
C
C        *** USE FORWARD DIFFERENCE IF BOUND ON TRUNCATION ERROR IS AT
C        *** MOST 10**-3.
C
         IF (AAI*H .LE. P002*AGI) GO TO 160
C
C        *** COMPUTE H = STEWART*S STEP FOR CENTRAL DIFFERENCE.
C
         DISCON = C2000*AFXETA
         H = DISCON/(AGI + DSQRT(GI**2 + AAI*DISCON))
C
C        ***  ENSURE THAT  H  IS NEITHER TOO SMALL NOR TOO BIG  ***
C
         H = DMAX1(H, HMIN*AXIBAR)
         IF (H .GE. HMAX0*AXIBAR) H = AXIBAR * H0**(TWO/THREE)
C
C        ***  COMPUTE CENTRAL DIFFERENCE  ***
C
         IRC = -I
         GO TO 200
C
 140     H = -W(HSAVE)
         I = IABS(IRC)
         IF (H .GT. ZERO) GO TO 150
         W(FH) = FX
         GO TO 200
C
 150     G(I) = (W(FH) - FX) / (TWO * H)
         X(I) = W(XISAVE)
         GO TO 110
C
C     ***  COMPUTE FORWARD DIFFERENCES IN VARIOUS CASES  ***
C
 160     IF (H .GE. HMAX0*AXIBAR) H = H0 * AXIBAR
         IF (ALPHAI*GI .LT. ZERO) H = -H
         GO TO 200
 170     H = AXIBAR
         GO TO 200
 180     H = H0 * AXIBAR
C
 200     X(I) = W(XISAVE) + H
         W(HSAVE) = H
         GO TO 999
C
C     ***  COMPUTE ACTUAL FORWARD DIFFERENCE  ***
C
 210     G(IRC) = (FX - W(FX0)) / W(HSAVE)
         X(IRC) = W(XISAVE)
         GO TO 110
C
C  ***  RESTORE FX AND INDICATE THAT G HAS BEEN COMPUTED  ***
C
 300  FX = W(FX0)
      IRC = 0
C
 999  RETURN
C  ***  LAST CARD OF DSGRD2 FOLLOWS  ***
      END
C
     

C ------------------------------------------------------------------------------

