module mod_stats
    use mod_core_types
    implicit none

contains

    subroutine calculate_domain_size(psi, cfg, avg_size)
        real,    intent(in)  :: psi(:,:)
        type(Config_t), intent(in) :: cfg
        real,    intent(out) :: avg_size
        integer :: i, j, crossings
        real :: psi_mean

        crossings = 0
        psi_mean = cfg%psimean

        ! Count horizontal crossings
        do j = 1, cfg%Ly
            do i = 1, cfg%Lx
                if ((psi(i,j) - psi_mean) * (psi(modulo(i, cfg%Lx)+1, j) - psi_mean) < 0.0) then
                    crossings = crossings + 1
                end if
            end do
        end do

        ! Count vertical crossings
        do i = 1, cfg%Lx
            do j = 1, cfg%Ly
                if ((psi(i,j) - psi_mean) * (psi(i, modulo(j, cfg%Ly)+1) - psi_mean) < 0.0) then
                    crossings = crossings + 1
                end if
            end do
        end do

        ! Avoid division by zero: Domain size ~ System Area / Crossings
        if (crossings > 0) then
            avg_size = (2.0 * real(cfg%Lx * cfg%Ly)) / real(crossings)
        else
            avg_size = real(cfg%Lx) ! Default to system size
        end if
    end subroutine calculate_domain_size

    subroutine psi_averages(psi, cfg , psiavg, psiabsavg)
        real,    intent(in)  :: psi(:,:)
        type(Config_t), intent(in) :: cfg
        real,    intent(out) :: psiavg, psiabsavg
        !integer :: i, j 

        psiavg = sum( psi ) / real( size(psi) )

        psiabsavg = sum( abs( psi - psiavg ) ) / real( size(psi) )

    end subroutine psi_averages 

    subroutine domain_masscentre(psi, cfg, centre_mass_x, centre_mass_y)
    real,    intent(in)  :: psi(:,:)
    type(Config_t), intent(in) :: cfg
    real,    intent(out) :: centre_mass_x, centre_mass_y
    
    integer :: i, j
    real :: psieq, psi_a, theta_x, theta_y
    real(8) :: sum_cos_x, sum_sin_x, sum_cos_y, sum_sin_y, total_w
    real, parameter :: PI = 3.141592653589793

    psieq = sqrt(cfg%tau / cfg%u)

    ! Initialize accumulators (using double precision for stability)
    sum_cos_x = 0.0d0; sum_sin_x = 0.0d0
    sum_cos_y = 0.0d0; sum_sin_y = 0.0d0
    total_w   = 0.0d0

    do j = 1, cfg%Ly
        ! Precompute theta_y for this row
        theta_y = (real(j) / cfg%Ly) * 2.0 * PI
        do i = 1, cfg%Lx
            psi_a = 0.5 * (1.0 + psi(i,j) / psieq)
            
            if (psi_a > 0.0) then
                theta_x = (real(i) / cfg%Lx) * 2.0 * PI
                
                sum_cos_x = sum_cos_x + psi_a * cos(theta_x)
                sum_sin_x = sum_sin_x + psi_a * sin(theta_x)
                
                sum_cos_y = sum_cos_y + psi_a * cos(theta_y)
                sum_sin_y = sum_sin_y + psi_a * sin(theta_y)
                
                total_w = total_w + psi_a
            end if
        end do
    end do

    if (total_w > 0.0) then
        ! Calculate mean angles and map back to [1, L] range
        centre_mass_x = (atan2(real(-sum_sin_x), real(-sum_cos_x)) + PI) &
                        * (real(cfg%Lx) / (2.0 * PI))
        centre_mass_y = (atan2(real(-sum_sin_y), real(-sum_cos_y)) + PI) &
                        * (real(cfg%Ly) / (2.0 * PI))
    else
        centre_mass_x = 0.0
        centre_mass_y = 0.0
    end if

end subroutine domain_masscentre

end module mod_stats