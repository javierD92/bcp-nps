module mod_coupling
  use mod_core_types
  implicit none
  public :: coupling

contains

  subroutine coupling(mu, psi, particles, cfg,E_cpl)
    real, intent(inout)           :: mu(:,:)
    real, intent(in)              :: psi(:,:)
    type(Particle_t), intent(inout) :: particles(:)
    type(Config_t), intent(in)    :: cfg
    real, intent(out) :: E_cpl
    integer :: p, i, j, xg, yg, N2
    real    :: dx, dy, r2, r2_Reff2, psic, dpsic, dpsi, K1, r_inv_sq

    E_cpl = 0.0



    N2 = int(cfg%Reff) + 1
    r_inv_sq = 1.0 / cfg%Reff_2

    do p = 1, cfg%Np
      particles(p)%fx = 0.0
      particles(p)%fy = 0.0

      do j = -N2, N2
        do i = -N2, N2
          ! 1. Identify grid cell with PBC
          xg = modulo(nint(particles(p)%x) + i - 1, cfg%Lx) + 1
          yg = modulo(nint(particles(p)%y) + j - 1, cfg%Ly) + 1

          ! 2. Calculate distance (Minimum Image Convention)
          dx = particles(p)%x - real(xg)
          if (abs(dx) > cfg%Lx*0.5) dx = dx - sign(real(cfg%Lx), dx)
          dy = particles(p)%y - real(yg)
          if (abs(dy) > cfg%Ly*0.5) dy = dy - sign(real(cfg%Ly), dy)
          r2 = dx**2 + dy**2

          ! 3. Interaction check
          if (r2 < cfg%Reff_2) then
            ! Smooth potential calculation
            r2_Reff2 = r2 * r_inv_sq
            psic = exp(1.0 - 1.0 / (1.0 - r2_Reff2))
            dpsic = (psic * 2.0 * r_inv_sq) / (1.0 - r2_Reff2)**2

            dpsi = psi(xg, yg) - cfg%affinity
            
            ! Field interaction (MuCPL)
            mu(xg, yg) = mu(xg, yg) + 2.0 * cfg%sigma * psic * dpsi

            ! Force contribution
            K1 = cfg%sigma * dpsic * (dpsi**2)
            particles(p)%fx = particles(p)%fx + K1 * dx
            particles(p)%fy = particles(p)%fy + K1 * dy

            ! energy contribution 
            E_cpl = E_cpl + cfg%sigma * psic * dpsi**2

          endif
        enddo
      enddo
    enddo
  end subroutine coupling

end module mod_coupling