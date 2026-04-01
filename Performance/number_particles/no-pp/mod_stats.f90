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

end module mod_stats