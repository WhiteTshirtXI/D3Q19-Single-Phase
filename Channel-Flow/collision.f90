!=============================================================================
!University of Delaware LBM D3Q19 Single Phase Simulation 
!Copyright (C) 2017 Lian-Ping Wang

!This program is free software: you can redistribute it and/or modify
!it under the terms of the GNU General Public License as published by
!the Free Software Foundation, either version 3 of the License, or
!(at your option) any later version.

!This program is distributed in the hope that it will be useful,
!but WITHOUT ANY WARRANTY; without even the implied warranty of
!MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!GNU General Public License for more details.

!You should have received a copy of the GNU General Public License
!along with this program.  If not, see <http://www.gnu.org/licenses/>.
!=============================================================================
!@subroutine collision_MRT 
!@desc Executes collision and propagation of the fluid. Current follows the
!      swap algorythm which fuses collision and propagation together
!      into a single step. Calculations have be movef to element-wise
!      operations to help increase performance. May change in the future.
!=============================================================================
      subroutine collision_MRT    
      use mpi
      use var_inc
      implicit none 

      real, dimension(0:npop-1) :: f9
      real, dimension(0:npop-1) :: Fbar
      real, dimension(0:npop-1,lx,ly)     :: tmpzpS, tmpzmS
      real, dimension(0:npop-1,lx,0:lz+1) :: tmpypS,tmpymS
      real rho9, ux9, uy9, uz9, ux9s, uy9s, uz9s
      real t1, tl1, tl2, tl3, tl4, tl5, tl6, tl7, tl8, tl9, tl10, tl11,&
           tl12, tl13, tl14, tl15, tl16, tl17, tl18, tl19, tl20, tl21
      real eqm1, eqm2, eqm3, eqm4, eqm5, eqm6, eqm7, eqm8, eqm9, eqm10,&
           eqm11, eqm12, eqm13, eqm14, eqm15 
      real sum1, sum2, sum3, sum4, sum5, sum6, sum7, sum8, sum9, sum10,&
           sum11
      real evlm1, evlm2, evlm3, evlm4, evlm5, evlm6, evlm7, evlm8,     &
           evlm9, evlm10, evlm11, evlm12, evlm13, evlm14, evlm15
      real eqmc1, eqmc2, eqmc3, eqmc4, eqmc5, eqmc6, eqmc7, eqmc8,     &
           eqmc9, eqmc10, eqmc11, eqmc12, eqmc13, eqmc14, eqmc15
      real suma, sumb, sumc, sumd, sume, sumf, sumg, sumh, sumi, sumk, &
           sump, sum67, sum89, sum1011
      integer ip, ipi, ix, iy, iz, imove, jmove, kmove, snext
      real fx9,fy9,fz9,G1,G2,G3

      !Index through fluid nodes
      do iz = 1,lz
      do iy = 1,ly
      do ix = 1,lx
        
      if(ibnodes(ix,iy,iz) > 0) goto 111
      !If we are not in a solid particle execute collision
        rho9 = rho(ix,iy,iz)
        ux9 = ux(ix,iy,iz)
        uy9 = uy(ix,iy,iz)
        uz9 = uz(ix,iy,iz)
        ux9s = ux9*ux9
        uy9s = uy9*uy9
        uz9s = uz9*uz9

        !Merging the forcing term with the collision operator
        fx9 = force_realx(ix,iy,iz)
        fy9 = force_realy(ix,iy,iz)
        fz9 = force_realz(ix,iy,iz)
        G3 = ux9*fx9 + uy9*fy9 + uz9*fz9

        Fbar(0) = -G3

        do ip=1,6
          G1 = cix(ip)*fx9 + ciy(ip)*fy9 + ciz(ip)*fz9
          G2 = cix(ip)*ux9 + ciy(ip)*uy9 + ciz(ip)*uz9
          Fbar(ip) = ww1*(3.*G1 + 9.*G1*G2 - 3.*G3)
        enddo

        do ip=7,(npop-1)
          G1 = cix(ip)*fx9 + ciy(ip)*fy9 + ciz(ip)*fz9
          G2 = cix(ip)*ux9 + ciy(ip)*uy9 + ciz(ip)*uz9
          Fbar(ip) = ww2*(3.*G1 + 9.*G1*G2 - 3.*G3)
        enddo 

        f9(:) = f(:,ix,iy,iz) + 0.5*Fbar(:)

        t1 = ux9s + uy9s + uz9s
        eqm1 = -11.0*rho9 + 19.0*t1
        eqm2 = omegepsl*rho9 + omegepslj*t1
        eqm3 = coef1*ux9
        eqm4 = coef1*uy9
        eqm5 = coef1*uz9
        eqm6 = 2.0*ux9s - uy9s - uz9s
        eqm7 = omegxx*eqm6
        eqm8 = uy9s - uz9s
        eqm9 = omegxx*eqm8
        eqm10 = ux9*uy9
        eqm11 = uy9*uz9
        eqm12 = ux9*uz9
        eqm13 = 0.0
        eqm14 = 0.0
        eqm15 = 0.0

        sum1 = f9(1) + f9(2) + f9(3) + f9(4) + f9(5) + f9(6)        
        sum2 = f9(7) + f9(8) + f9(9) + f9(10) + f9(11) + f9(12)        &
             + f9(13) + f9(14) + f9(15) + f9(16) + f9(17) + f9(18)      
        sum3 = f9(7) - f9(8) + f9(9) - f9(10) + f9(11) - f9(12)        &
             + f9(13) - f9(14)
        sum4 = f9(7) + f9(8) - f9(9) - f9(10) + f9(15) - f9(16)        &
             + f9(17) - f9(18)
        sum5 = f9(11) + f9(12) - f9(13) - f9(14) + f9(15) + f9(16)     &
             - f9(17) - f9(18)
        sum6 = f9(1) + f9(2)
        sum7 = f9(3) + f9(4) + f9(5) + f9(6)
        sum8 = f9(7) + f9(8) + f9(9) + f9(10) + f9(11) + f9(12)        &
             + f9(13) + f9(14)
        sum9 = f9(15) + f9(16) + f9(17) + f9(18)
        sum10 = f9(3) + f9(4) - f9(5) - f9(6)
        sum11 = f9(7) + f9(8) + f9(9) + f9(10) - f9(11) - f9(12)       &
              - f9(13) - f9(14)
    
        evlm1 = -30.0*f9(0) + coef2*sum1 + coef3*sum2
        evlm2 = 12.0*f9(0) + coef4*sum1 + sum2
        evlm3 = coef4*(f9(1) - f9(2)) + sum3
        evlm4 = coef4*(f9(3) - f9(4)) + sum4
        evlm5 = coef4*(f9(5) - f9(6)) + sum5
        evlm6 = coef5*sum6 - sum7 + sum8 - coef5*sum9
        evlm7 = coef4*sum6 + coef5*sum7 + sum8 - coef5*sum9
        evlm8 = sum10 + sum11
        evlm9 =-coef5*sum10 + sum11
        evlm10 = f9(7) - f9(8) - f9(9) + f9(10)
        evlm11 = f9(15) - f9(16) - f9(17) + f9(18)
        evlm12 = f9(11) - f9(12) - f9(13) + f9(14)
        evlm13 = f9(7) - f9(8) + f9(9) - f9(10) - f9(11) + f9(12)      &
               - f9(13) + f9(14)
        evlm14 =-f9(7) - f9(8) + f9(9) + f9(10) + f9(15) - f9(16)      &
               + f9(17) - f9(18)
        evlm15 = f9(11) + f9(12) - f9(13) - f9(14) - f9(15) - f9(16)   &
               + f9(17) + f9(18)
   
        eqmc1 = evlm1 - s1*(evlm1 - eqm1)
        eqmc2 = evlm2 - s2*(evlm2 - eqm2)
        eqmc3 = evlm3 - s4*(evlm3 - eqm3)
        eqmc4 = evlm4 - s4*(evlm4 - eqm4)
        eqmc5 = evlm5 - s4*(evlm5 - eqm5)
        eqmc6 = evlm6 - s9*(evlm6 - eqm6)
        eqmc7 = evlm7 - s10*(evlm7 - eqm7)
        eqmc8 = evlm8 - s9*(evlm8 - eqm8)
        eqmc9 = evlm9 - s10*(evlm9 - eqm9)
        eqmc10 = evlm10 - s13*(evlm10 - eqm10)
        eqmc11 = evlm11 - s13*(evlm11 - eqm11)
        eqmc12 = evlm12 - s13*(evlm12 - eqm12)
        eqmc13 = evlm13 - s16*(evlm13 - eqm13)
        eqmc14 = evlm14 - s16*(evlm14 - eqm14)
        eqmc15 = evlm15 - s16*(evlm15 - eqm15)


        tl1 = val1i*rho9
        tl2 = coef2*val2i*eqmc1
        tl3 = coef3*val2i*eqmc1
        tl4 = coef4*val3i*eqmc2
        tl5 = val3i*eqmc2
        tl6 = val4i*ux9
        tl7 = val5i*eqmc3
        tl8 = val4i*uy9
        tl9 = val5i*eqmc4
        tl10 = val4i*uz9
        tl11 = val5i*eqmc5
        tl12 = val6i*eqmc6
        tl13 = val7i*eqmc7
        tl14 = val8i*eqmc8
        tl15 = val9i*eqmc9
        tl16 = -coef4i*eqmc10
        tl17 = -coef4i*eqmc11
        tl18 = -coef4i*eqmc12
        tl19 = coef3i*eqmc13
        tl20 = coef3i*eqmc14
        tl21 = coef3i*eqmc15


        f9(0) = tl1 - 30.0*val2i*eqmc1 + val8*val3i*eqmc2

        suma = tl1 + tl2 + tl4
        sumb = tl1 + tl3 + tl5
        sumc = tl6 + coef4*tl7
        sumd = coef5*tl12 + coef4*tl13
        sume = tl8 + coef4*tl9
        sumf = -tl12 + coef5*tl13 + tl14 - coef5*tl15
        sumg = tl10 + coef4*tl11
        sumh = -tl12 + coef5*tl13 - tl14 + coef5*tl15
 
        sumi = tl12 + tl13 + tl14 + tl15
        sumk = tl12 + tl13 - tl14 - tl15
 
        sump = -coef5*tl12 - coef5*tl13

        sum67 = tl6 + tl7
        sum89 = tl8 + tl9
        sum1011 = tl10 + tl11

        f9(1) = suma + sumc + sumd
        f9(2) = suma - sumc + sumd
        f9(3) = suma + sume + sumf
        f9(4) = suma - sume + sumf
        f9(5) = suma + sumg + sumh
        f9(6) = suma - sumg + sumh

        f9(7) = sumb + sum67 + sum89 + sumi + tl16 + tl19 - tl20
        f9(8) = sumb - sum67 + sum89 + sumi - tl16 - tl19 - tl20
        f9(9) = sumb + sum67 - sum89 + sumi - tl16 + tl19 + tl20
        f9(10) = sumb - sum67 - sum89 + sumi + tl16 - tl19 + tl20
 
        f9(11) = sumb + sum67 + sum1011 + sumk + tl18 - tl19 + tl21
        f9(12) = sumb - sum67 + sum1011 + sumk - tl18 + tl19 + tl21
        f9(13) = sumb + sum67 - sum1011 + sumk - tl18 - tl19 - tl21
        f9(14) = sumb - sum67 - sum1011 + sumk + tl18 + tl19 - tl21
 
        f9(15) = sumb + sum89 + sum1011 + sump + tl17 + tl20 - tl21
        f9(16) = sumb - sum89 + sum1011 + sump - tl17 - tl20 - tl21
        f9(17) = sumb + sum89 - sum1011 + sump - tl17 + tl20 + tl21
        f9(18) = sumb - sum89 - sum1011 + sump + tl17 - tl20 + tl21
        
        !Place updated distributions into post-stream locations
        !If that location is ina MPI neighbor place into proper send buffer     
        do ipi = 1,10
          ip = ipstay(ipi)  
          imove = ix + cix(ip) 
          jmove = iy + ciy(ip)
          kmove = iz + ciz(ip)
          if(imove < 1 .or. imove > lx)then
            f(ipopp(ip),ix,iy,iz) = f9(ip) + 0.5*Fbar(ip)
          elseif(jmove < 1)then
             tmpymS(ip,imove,kmove) =  f9(ip) + 0.5*Fbar(ip)
          elseif(jmove > ly)then
            tmpypS(ip,imove,kmove) = f9(ip) + 0.5*Fbar(ip)
          elseif(kmove < 1)then
            tmpzmS(ip,imove,jmove) = f9(ip) + 0.5*Fbar(ip)
          elseif(kmove > lz)then
            tmpzpS(ip,imove,jmove) = f9(ip) + 0.5*Fbar(ip)
          else
            f(ipopp(ip),ix,iy,iz) = f9(ip) + 0.5*Fbar(ip)
          endif
        enddo

111     continue        
        do ipi = 1,9
          ip = ipswap(ipi)
          imove = ix + cix(ip) 
          jmove = iy + ciy(ip)
          kmove = iz + ciz(ip)
          if(imove < 1 .or. imove > lx)then
            f(ipopp(ip),ix,iy,iz) = f9(ip) + 0.5*Fbar(ip)
          elseif(jmove < 1)then
             tmpymS(ip,imove,kmove) =  f9(ip) + 0.5*Fbar(ip)
          elseif(jmove > ly)then
            tmpypS(ip,imove,kmove) = f9(ip) + 0.5*Fbar(ip)
          elseif(kmove < 1)then
            tmpzmS(ip,imove,jmove) = f9(ip) + 0.5*Fbar(ip)
          elseif(kmove > lz)then
            tmpzpS(ip,imove,jmove) = f9(ip) + 0.5*Fbar(ip)
          else
            f(ipopp(ip),ix,iy,iz) = f(ip,imove,jmove,kmove)
            f(ip,imove,jmove,kmove) = f9(ip) + 0.5*Fbar(ip)
          endif
        enddo
      
      end do !x
      end do !y
      end do !z

      !Exchange information with MPI neighbors to update edges
      call collisionExchnge(tmpymS,tmpypS,tmpzmS,tmpzpS)

      end subroutine collision_MRT
!=============================================================================
!@subroutine collisionExchnge 
!@desc Exchanges updated fluid distributions between neighboring MPI tasks and
!      updates the local domains edges with distributions recieved
!@param tmpymSi,tmpypSi,tmpzmSi,tmpzpSi = real array; contains fluid
!       distributions that need to be passed to nieghboring MPI tasks
!=============================================================================
      subroutine collisionExchnge(tmpymSi,tmpypSi,tmpzmSi,tmpzpSi)
      use var_inc
      use mpi
      implicit none

      integer ilen
      integer status_array(MPI_STATUS_SIZE,4), req(4)
      real, dimension(0:npop-1,lx,0:lz+1) ::  tmpypSi, tmpymSi
      real, dimension(0:npop-1,lx,ly)     :: tmpzpSi, tmpzmSi
      real, dimension(5,lx,0:lz+1):: tmpypS, tmpymS, tmpypR, tmpymR
      real, dimension(5,lx,ly):: tmpzpS, tmpzmS, tmpzmR, tmpzpR

      !Create send buffers
      !Note that we only pass the distributions needed to decrease message size
      tmpypS(1,:,:) = tmpypSi(3,:,:)
      tmpypS(2,:,:) = tmpypSi(7,:,:)
      tmpypS(3,:,:) = tmpypSi(8,:,:)
      tmpypS(4,:,:) = tmpypSi(15,:,:)
      tmpypS(5,:,:) = tmpypSi(17,:,:)

      tmpymS(1,:,:) = tmpymSi(4,:,:)
      tmpymS(2,:,:) = tmpymSi(9,:,:)
      tmpymS(3,:,:) = tmpymSi(10,:,:)
      tmpymS(4,:,:) = tmpymSi(16,:,:)
      tmpymS(5,:,:) = tmpymSi(18,:,:)

      ilen = 5 * lx * (lz + 2)
      !Send/Recieve updated distributions with Y MPI neighbors
      call MPI_IRECV(tmpymR,ilen,MPI_REAL8,mym,0,MPI_COMM_WORLD,req(1),ierr)
      call MPI_IRECV(tmpypR,ilen,MPI_REAL8,myp,1,MPI_COMM_WORLD,req(2),ierr)

      call MPI_ISEND(tmpymS,ilen,MPI_REAL8,mym,1,MPI_COMM_WORLD,req(3),ierr)
      call MPI_ISEND(tmpypS,ilen,MPI_REAL8,myp,0,MPI_COMM_WORLD,req(4),ierr)
      call MPI_WAITALL(4,req,status_array,ierr)

      !Update local domain Y edge nodes
      !Note we must account for wall bounce back here!
      f(3,:,1,:) = tmpymR(1,:,1:lz)
      f(7,2:lx,1,:) = tmpymR(2,2:lx,1:lz)
      f(8,1:lx-1,1,:) = tmpymR(3,1:lx-1,1:lz)
      f(15,:,1,:) = tmpymR(4,:,1:lz)
      f(17,:,1,:) = tmpymR(5,:,1:lz)

      f(4,:,ly,:) = tmpypR(1,:,1:lz)
      f(9,2:lx,ly,:) = tmpypR(2,2:lx,1:lz)
      f(10,1:lx-1,ly,:) = tmpypR(3,1:lx-1,1:lz)
      f(16,:,ly,:) = tmpypR(4,:,1:lz)
      f(18,:,ly,:) = tmpypR(5,:,1:lz)
      
      !Add corner distributions to Z buffer
      tmpzmSi(17,:,1) = tmpymR(5,:,0)
      tmpzmSi(18,:,ly) = tmpypR(5,:,0)
      tmpzpSi(15,:,1) = tmpymR(4,:,lz+1)
      tmpzpSi(16,:,ly) = tmpypR(4,:,lz+1)

      !Add local data to Z send buffers
      tmpzpS(1,:,:) = tmpzpSi(5,:,:)
      tmpzpS(2,:,:) = tmpzpSi(11,:,:)
      tmpzpS(3,:,:) = tmpzpSi(12,:,:)
      tmpzpS(4,:,:) = tmpzpSi(15,:,:)
      tmpzpS(5,:,:) = tmpzpSi(16,:,:)

      tmpzmS(1,:,:) = tmpzmSi(6,:,:)
      tmpzmS(2,:,:) = tmpzmSi(13,:,:)
      tmpzmS(3,:,:) = tmpzmSi(14,:,:)
      tmpzmS(4,:,:) = tmpzmSi(17,:,:)
      tmpzmS(5,:,:) = tmpzmSi(18,:,:)

      ilen = 5*lx*ly
      !Send/Recieve updated distributions with Z MPI neighbors
      call MPI_IRECV(tmpzmR,ilen,MPI_REAL8,mzm,0,MPI_COMM_WORLD,req(1),ierr)
      call MPI_IRECV(tmpzpR,ilen,MPI_REAL8,mzp,1,MPI_COMM_WORLD,req(2),ierr)

      call MPI_ISEND(tmpzmS,ilen,MPI_REAL8,mzm,1,MPI_COMM_WORLD,req(3),ierr)
      call MPI_ISEND(tmpzpS,ilen,MPI_REAL8,mzp,0,MPI_COMM_WORLD,req(4),ierr)
      call MPI_WAITALL(4,req,status_array,ierr)

      !Update local domain Z edge nodes
      !Note we must account for wall bounce back here!
      f(5,:,:,1) = tmpzmR(1,:,:)
      f(11,2:lx,:,1) = tmpzmR(2,2:lx,:)
      f(12,1:lx-1,:,1) = tmpzmR(3,1:lx-1,:)
      f(15,:,:,1) = tmpzmR(4,:,:)
      f(16,:,:,1) = tmpzmR(5,:,:)

      f(6,:,:,lz) = tmpzpR(1,:,:)
      f(13,2:lx,:,lz) = tmpzpR(2,2:lx,:)
      f(14,1:lx-1,:,lz) = tmpzpR(3,1:lx-1,:)
      f(17,:,:,lz) = tmpzpR(4,:,:)
      f(18,:,:,lz) = tmpzpR(5,:,:)

      end subroutine collisionExchnge
!=============================================================================
!@subroutine macrovar 
!@desc Calculates macroscopic fluid properties density(rho), x-velocity(ux),
!      y-velocity(uy), and z-velocity(uz)
!=============================================================================
      subroutine macrovar 
      use var_inc
      implicit none 

      integer ip, ix, iy, iz, id             
      real xc, yc, zc, xpnt, ypnt, zpnt, xx0, yy0, zz0     
      real w1, w2, w3, omg1, omg2, omg3 

      real  sum1,sum2,sum3,sum4,sum5,sum6,ux9,uy9,uz9
      real  rho9
      real, dimension(0:npop-1) :: f9

      !Calculate denisty and velocities of the fluid
      do iz = 1,lz
      do iy = 1,ly
      do ix = 1,lx
        if(ibnodes(ix,iy,iz) < 0)then
          !If we are not inside a solid particle
          f9 = f(:,ix,iy,iz)

          sum1 = f9(7) - f9(10)
          sum2 = f9(9) - f9(8)

          sum3 = f9(11) - f9(14)
          sum4 = f9(13) - f9(12)

          sum5 = f9(15) - f9(18)
          sum6 = f9(17) - f9(16)

          ux9 = f9(1) - f9(2) + sum1 + sum2 + sum3 + sum4
          uy9 = f9(3) - f9(4) + sum1 - sum2 + sum5 + sum6
          uz9 = f9(5) - f9(6) + sum3 - sum4 + sum5 - sum6

          rho9 = f9(0)+f9(1)+f9(2)+f9(3)+f9(4)+f9(5)+f9(6)&
               +f9(7)+f9(8)+f9(9)+f9(10)+f9(11)+f9(12)&
              + f9(13)+f9(14)+f9(15)+f9(16)+f9(17)+f9(18)

          ux(ix,iy,iz) = ux9 + force_realx(ix,iy,iz)/2.
          uy(ix,iy,iz) = uy9 + force_realy(ix,iy,iz)/2.
          uz(ix,iy,iz) = uz9 + force_realz(ix,iy,iz)/2.
          rho(ix,iy,iz) = rho9

        elseif(ipart)then
          !If we are in a solid particle, adjust velocity to the particles velocity
          id = isnodes(ix,iy,iz) 

          xpnt = real(ix) - 0.5
          ypnt = real(iy) - 0.5 + globaly
          zpnt = real(iz) - 0.5 + globalz

          xc = ypglb(1,id)
          yc = ypglb(2,id)
          zc = ypglb(3,id)

          !Use the nearest particle center instead of the real center
          !if((xc - xpnt) > real(nxh)) xc = xc - real(nx)
          !if((xc - xpnt) < -real(nxh)) xc = xc + real(nx)

          if((yc - ypnt) > real(nyh)) yc = yc - real(ny)
          if((yc - ypnt) < -real(nyh)) yc = yc + real(ny)

          if((zc - zpnt) > real(nzh)) zc = zc - real(nz)
          if((zc - zpnt) < -real(nzh)) zc = zc + real(nz)

          xx0 = xpnt - xc
          yy0 = ypnt - yc
          zz0 = zpnt - zc

          w1 = wp(1,id)
          w2 = wp(2,id)
          w3 = wp(3,id)

          omg1 = omgp(1,id)
          omg2 = omgp(2,id)
          omg3 = omgp(3,id)

          ux(ix,iy,iz) = w1 + (omg2*zz0 - omg3*yy0)
          uy(ix,iy,iz) = w2 + (omg3*xx0 - omg1*zz0)
          uz(ix,iy,iz) = w3 + (omg1*yy0 - omg2*xx0)

          rho(ix,iy,iz) = rhopart
        endif
      enddo !x
      enddo !y
      enddo !z
      end subroutine macrovar
!=============================================================================
!@subroutine rhoupdat
!@desc Updates only density of the local fluid nodes, currently only used in
!      the pre-relaxation process.
!=============================================================================
      subroutine rhoupdat 
      use var_inc
      implicit none 

      integer ip

      rho = f(0,:,:,:)
      do ip = 1,npop-1
        rho = rho + f(ip,:,:,:)
      end do

      end subroutine rhoupdat 
!=============================================================================
!@subroutine avedensity
!@desc Calculates the average density for the entire fluid domain and removes
!      it from all densities of local nodes. This is to account for loss
!      of mass in the interpolation bounceback.
!=============================================================================
      subroutine avedensity
      use var_inc
      use mpi    
      implicit none

      integer iz, iy, ix
      integer nfluid0, nfluidtotal
      real rhomean0, rhomean

      rhomean0 = 0.d0
      nfluid0 = count(ibnodes(1:lx,1:ly,1:lz) < 0)
      rhomean0 = sum(rho,MASK = (ibnodes(1:lx,1:ly,1:lz) < 0))
      CALL MPI_BARRIER(MPI_COMM_WORLD,ierr)
      CALL MPI_ALLREDUCE(nfluid0,nfluidtotal,1,MPI_INTEGER,MPI_SUM,mpi_comm_world,ierr)
      CALL MPI_ALLREDUCE(rhomean0,rhomean,1,MPI_REAL8,MPI_SUM,mpi_comm_world,ierr)

      rhomean = rhomean/dfloat(nfluidtotal)

      do iz = 1,lz
        do iy = 1,ly
          do ix = 1,lx
            rho(ix,iy,iz) = rho(ix,iy,iz) - rhomean
          enddo
        enddo
      enddo

      end subroutine avedensity
!==================================================================
      SUBROUTINE FORCING
      use mpi
      use var_inc
      implicit none
      integer ixs,ihh,i,j,k,jj,kk
      real x9,y9,z9

      force_realx(:,:,:) = 0.0
      force_realy(:,:,:) = force_in_y*force_mag
      force_realz(:,:,:) = 0.0

      RETURN
      END SUBROUTINE FORCING
!=================================
      SUBROUTINE FORCINGP
      use mpi
      use var_inc
      implicit none
      integer ixs,ihh,i,j,k,jj,kk
      real x9,y9,z9,Amp0,beta9,gamma9,Tpd, phase9,Tpdp,ixs0
      real alphay, alphaz

      Tpd = 2000.
      Tpdp = 1500.
      beta9 = 3.0
      gamma9=2.0
      ixs0 = 2
      Amp0 = 40.00*beta9/real(ny)*sin(pi2*real(istep)/Tpd)
!     phase9 = sin(pi2*real(istep)/Tpdp)
      phase9 = 0.25

      force_realx(:,:,:) = 0.0
      force_realy(:,:,:) = force_in_y
      force_realz(:,:,:) = 0.0
      
      !Get global position of local fluid domain
      alphay = 0
      alphaz = 0
      do i = 0, indy-1
         alphay = alphay + mpily(indz*nprocY + i)
      enddo
      do i = 0, indz-1
        alphaz = alphaz + mpilz(i*nprocY + indy)
      enddo
      
      !Add some perturbation
      ixs = ixs0
      ihh = lxh/2
      do k=1,lz
        kk = k + alphaz
        z9 = pi2*(real(kk)-0.5)/real(nz)
        do j=1,ly
         jj = j + alphay
         y9 = pi2*(real(jj)-0.5)/real(ny)
         do i=1,ihh
           x9 = pi2*(real(i)-0.5)/real(ihh)
           force_realx(i+ixs,j,k) = force_in_y*0.5*Amp0*real(ihh)*(1.-cos(x9))  &
                                 *cos(beta9*y9)*cos(gamma9*z9)
           force_realy(i+ixs,j,k) = force_in_y*(1.0-Amp0*real(ny)/beta9    &
                       *sin(x9)*sin(beta9*y9)*cos(gamma9*z9))
           force_realz(i+ixs,j,k) = force_in_y*0.5*Amp0*real(nz)/gamma9*   &
                        sin(x9)*cos(beta9*y9)*sin(gamma9*z9)
          end do!x
         end do!y
      end do!z

      ihh = lxh/2
      ixs = nx - ixs0 - ihh
      do k=1,lz
      kk = k + alphaz
      z9 = pi2*(real(kk)-0.5)/real(nz)
      do j=1,ly
      jj = j + alphay
      y9 = pi2*( (real(jj)-0.5)/real(ny) + phase9 )
      do i=1,ihh
      x9 = pi2*(real(i)-0.5)/real(ihh)
      force_realx(i+ixs,j,k) = -force_in_y*0.5*Amp0*real(ihh)*(1.-cos(x9))  &
                                 *cos(beta9*y9)*cos(gamma9*z9)
      force_realy(i+ixs,j,k) = force_in_y*(1.0+Amp0*real(ny)/beta9    &
                       *sin(x9)*sin(beta9*y9)*cos(gamma9*z9))
      force_realz(i+ixs,j,k) = -force_in_y*0.5*Amp0*real(nz)/gamma9*   &
                        sin(x9)*cos(beta9*y9)*sin(gamma9*z9)
      end do
      end do
      end do

      RETURN
      END SUBROUTINE FORCINGP
