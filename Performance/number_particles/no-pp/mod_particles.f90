module mod_particles
  use mod_core_types
  implicit none
  public :: compute_pp_forces, integrate_particles

  ! Persistent arrays to avoid re-allocation overhead
  integer, allocatable, save :: head(:), list(:)

contains

  subroutine compute_pp_forces(particles, cfg, e_pp)
    type(Particle_t), intent(inout) :: particles(:)
    type(Config_t),   intent(in)    :: cfg
    real,             intent(out)   :: e_pp
    
    integer :: ncx, ncy, ic, jc, c, nc, i, j, icn, jcn
    real    :: cell_w
    
    cell_w = sqrt(cfg%r_cut_sq)
    ncx = max(3, int(real(cfg%Lx) / cell_w))
    ncy = max(3, int(real(cfg%Ly) / cell_w))
    
    if (.not. allocated(head)) allocate(head(ncx * ncy))
    if (.not. allocated(list)) allocate(list(cfg%Np))
    if (size(head) /= ncx*ncy) then
       deallocate(head); allocate(head(ncx*ncy))
    end if

    head = 0  
    e_pp = 0.0
    particles%fx_pp = 0.0
    particles%fy_pp = 0.0

    ! 1. Binning
    do i = 1, cfg%Np
      ic = max(1, min(ncx, int(particles(i)%x * ncx / cfg%Lx) + 1))
      jc = max(1, min(ncy, int(particles(i)%y * ncy / cfg%Ly) + 1))
      c = ic + (jc - 1) * ncx
      list(i) = head(c)
      head(c) = i
    end do

    ! 2. Interaction Loop
    do jc = 1, ncy
      do ic = 1, ncx
        c = ic + (jc - 1) * ncx
        
        ! --- A. Self-cell interactions ---
        i = head(c)
        do while (i > 0)
          j = list(i) 
          do while (j > 0)
            call force_pair(i, j, particles, cfg, e_pp)
            j = list(j)
          end do
          i = list(i)
        end do

        ! --- B. Neighbor-cell interactions ---
        do jcn = jc, jc + 1
          do icn = ic - 1, ic + 1
            if (jcn == jc .and. icn <= ic) cycle 
            
            nc = modulo(icn - 1 + ncx, ncx) + 1 + &
                 modulo(jcn - 1 + ncy, ncy) * ncx
            
            i = head(c)
            do while (i > 0)
              j = head(nc)
              do while (j > 0)
                call force_pair(i, j, particles, cfg, e_pp)
                j = list(j)
              end do
              i = list(i)
            end do
          end do
        end do
      end do
    end do
  end subroutine compute_pp_forces

  ! -------------------------------------------------------------------
  ! CENTRALIZED FORCE CALCULATION
  ! -------------------------------------------------------------------
pure subroutine force_pair(i, j, particles, cfg, e_pp)
    integer, intent(in) :: i, j
    type(Particle_t), intent(inout) :: particles(:)
    type(Config_t), intent(in) :: cfg
    real, intent(inout) :: e_pp
    
    real :: dx, dy, r2, r, f_mag, overlap
    ! k_stiff: The "Spring Constant". 
    ! For dt=0.1, gamma=1, k=10 is very stable.
    !real, parameter :: k_stiff = 10.0 

    dx = particles(i)%x - particles(j)%x
    dy = particles(i)%y - particles(j)%y
    
    ! Minimum Image Convention
    if (abs(dx) > cfg%Lx * 0.5) dx = dx - sign(real(cfg%Lx), dx)
    if (abs(dy) > cfg%Ly * 0.5) dy = dy - sign(real(cfg%Ly), dy)
    
    r2 = dx**2 + dy**2
    
    ! If distance is less than diameter
    if (r2 < cfg%diam**2) then
      r = sqrt(max(r2, 1e-12))
      overlap = cfg%diam - r
      
      ! Force = k * overlap. 
      ! Divided by r to project onto the dx, dy components.
      f_mag = cfg%epsilon * overlap / r
      
      particles(i)%fx_pp = particles(i)%fx_pp + f_mag * dx
      particles(i)%fy_pp = particles(i)%fy_pp + f_mag * dy
      particles(j)%fx_pp = particles(j)%fx_pp - f_mag * dx
      particles(j)%fy_pp = particles(j)%fy_pp - f_mag * dy
      
      ! Energy = 1/2 * k * overlap^2
      e_pp = e_pp + 0.5 * cfg%epsilon * (overlap**2)
    end if
  end subroutine force_pair

  ! Overdamped Langevin integration (Euler-Maruyama)
  subroutine integrate_particles(particles, cfg)
    type(Particle_t), intent(inout) :: particles(:)
    type(Config_t),   intent(in)    :: cfg
    real    :: amp_pos,amp_rot, rx, ry, rphi
    integer :: i
    real    :: dx_total, dy_total, dr_total_2, dr_max_2

    amp_pos = sqrt(2.0 * cfg%temperature * cfg%dt / cfg%gamm_T)
    amp_rot = sqrt(2.0 * cfg%temperature * cfg%dt / cfg%gamm_R)

    dr_max_2  =  ( 1.0 * cfg%diam )**2
    
    do i = 1, cfg%Np
      call random_number(rx)
      call random_number(ry)
      call random_number(rphi)
      
      ! (Force-driven + Active-driven)
      dx_total = ((particles(i)%fx + particles(i)%fx_pp) / cfg%gamm_T) * cfg%dt + &
                 cfg%vact * cos(particles(i)%phi) * cfg%dt
      
      dy_total = ((particles(i)%fy + particles(i)%fy_pp) / cfg%gamm_T) * cfg%dt + &
                 cfg%vact * sin(particles(i)%phi) * cfg%dt

      ! 2. Stability Check: Catch "explosions" before updating coordinates
      dr_total_2 = dx_total**2 + dy_total**2
      
      if (dr_total_2 > dr_max_2) then
          print *, "--- INSTABILITY DETECTED ---"
          print *, "Particle ID:", i
          print *, "Total displacement:", sqrt( dr_total_2 )
          print *, "Limit (10% diam): ", sqrt( dr_max_2 )
          print *, "Field Force: ", particles(i)%fx, particles(i)%fy
          print *, "PP Force:    ", particles(i)%fx_pp, particles(i)%fy_pp
          stop 1
      end if

      ! 3. Apply updates including Noise
      particles(i)%x = particles(i)%x + dx_total + amp_pos * (rx - 0.5) * 3.4641
      particles(i)%y = particles(i)%y + dy_total + amp_pos * (ry - 0.5) * 3.4641
      
      ! Periodic Boundary Conditions
      particles(i)%x = modulo(particles(i)%x, real(cfg%Lx))
      particles(i)%y = modulo(particles(i)%y, real(cfg%Ly))

      ! 3.46 is sqrt(12), used to convert uniform random [-0.5, 0.5] to unit variance
      particles(i)%phi = particles(i)%phi + amp_rot * (rphi - 0.5) * 3.46
      
      ! Keep phi within [0, 2*pi]
      particles(i)%phi = modulo(particles(i)%phi, 2.0 * pi)

    enddo
  end subroutine integrate_particles

end module mod_particles