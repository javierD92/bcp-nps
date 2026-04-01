module mod_field
  use mod_core_types
  implicit none
  public :: calculate_mu_pure, evolve_field_model_b

contains
   subroutine noise(psi, cfg, csi1, csi2)
    real, intent(inout)        :: psi(:,:)
    type(Config_t), intent(in) :: cfg
    real, intent(inout)        :: csi1(:,:), csi2(:,:) ! Pre-allocated buffers
    
    integer :: i, j, ip, jp
    real    :: noise_scale

    noise_scale = cfg%noiseStrength * sqrt(cfg%dt) * sqrt(12.0)

    ! 1. Highly optimized vectorized random generation
    call random_number(csi1)
    call random_number(csi2)

    ! 2. Optimized nested loop (Minimize work inside)
    do j = 1, cfg%Ly
        jp = mod(j, cfg%Ly) + 1
        do i = 1, cfg%Lx
            ip = mod(i, cfg%Lx) + 1
            
            ! We do the "- 0.5" math here to avoid an extra loop over csi1/csi2
            psi(i,j) = psi(i,j) + noise_scale * ( &
                       csi1(ip, j) - csi1(i, j) + &
                       csi2(i, jp) - csi2(i, j) )        
        end do
    end do
end subroutine noise

  subroutine calculate_mu_pure(mu, psi, cfg, e_field)
    real, intent(out) :: mu(:,:)
    real, intent(in)  :: psi(:,:)
    type(Config_t), intent(in) :: cfg
    integer :: i, j, ip, im, jp, jm
    real :: lap_psi
    real :: grad_sq
    real, intent(out) :: e_field

    ! Weights for the isotropic 9-point stencil (Oono-Puri / CDS style)
    real, parameter :: w_nn = 1.0/6.0
    real, parameter :: w_dn = 1.0/12.0
    
    e_field = 0.0

    do j = 1, cfg%Ly
      jp = modulo(j, cfg%Ly) + 1; jm = modulo(j-2+cfg%Ly, cfg%Ly) + 1
      do i = 1, cfg%Lx
        ip = modulo(i, cfg%Lx) + 1; im = modulo(i-2+cfg%Lx, cfg%Lx) + 1

        ! 9-Point Laplacian of Psi
        ! lap_psi = [1/6 * sum(NN)] + [1/12 * sum(DN)] - [1 * center]
        lap_psi = w_nn * (psi(ip,j) + psi(im,j) + psi(i,jp) + psi(i,jm)) + &
                  w_dn * (psi(ip,jp) + psi(im,jp) + psi(ip,jm) + psi(im,jm)) - &
                  psi(i,j)

        mu(i,j) = -cfg%tau*psi(i,j) + cfg%u*(psi(i,j)**3) - cfg%kappa*lap_psi

        grad_sq = (psi(ip,j) - psi(i,j))**2 + (psi(i,jp) - psi(i,j))**2
        e_field = e_field -0.5*cfg%tau*psi(i,j)**2 + 0.25*cfg%u*psi(i,j)**4 + 0.5*cfg%kappa*grad_sq

      enddo
    enddo
  end subroutine calculate_mu_pure

  subroutine evolve_field_model_b(psi, mu, cfg)
    real, intent(inout) :: psi(:,:)
    real, intent(in)    :: mu(:,:)
    type(Config_t), intent(in) :: cfg
    integer :: i, j, ip, im, jp, jm
    real :: lap_mu
    ! Same weights for consistency
    real, parameter :: w_nn = 1.0/6.0
    real, parameter :: w_dn = 1.0/12.0

    do j = 1, cfg%Ly
      jp = modulo(j, cfg%Ly) + 1; jm = modulo(j-2+cfg%Ly, cfg%Ly) + 1
      do i = 1, cfg%Lx
        ip = modulo(i, cfg%Lx) + 1; im = modulo(i-2+cfg%Lx, cfg%Lx) + 1
        ! 9-Point Laplacian of Mu
        lap_mu = w_nn * (mu(ip,j) + mu(im,j) + mu(i,jp) + mu(i,jm)) + &
                 w_dn * (mu(ip,jp) + mu(im,jp) + mu(ip,jm) + mu(im,jm)) - &
                 mu(i,j)
                 
        psi(i,j) = psi(i,j) + cfg%dt * cfg%M * lap_mu
      enddo
    enddo
  end subroutine evolve_field_model_b
end module mod_field