module mod_core_types
  implicit none
  public

  ! Global Constants
  real, parameter :: PI = 3.14159265358979323846
  real, parameter :: TWO_PI = 6.28318530717958647692

  ! Structure for simulation constants and parameters
  type :: Config_t
    integer :: Lx, Ly              ! Lattice dimensions
    integer :: Np                  ! Number of particles
    integer :: total_steps         ! Number of iterations
    integer :: save_interval,stats_interval       ! I/O frequency
    
    real    :: dt                  ! Time step
    real    :: temperature, gamm_T,gamm_R   ! Thermal energy and friction
    
    ! Model B Parameters
    real    :: M, kappa, tau, u, psimean    
    
    ! Coupling Parameters
    real    :: sigma, affinity     ! Interaction strength and phase preference
    real    :: Reff, R0            ! Effective interaction and hard-core radii
    real    :: Reff_2, R0_2        ! Pre-calculated squared radii for performance

    real :: epsilon    ! Interaction strength (energy scale)
    real :: diam       ! Particle diameter (d = 2*R0)
    real :: d_2, d_6   ! Pre-calculated powers for speed
    real :: r_cut_sq   ! WCA cutoff: (2^(1/6) * d)^2

    ! active parameters
    real    :: vact

    ! noise 
    real :: noiseStrength

    ! initialisation flag 
    logical :: custom_init

  end type Config_t

  ! Structure for individual particle data
  type :: Particle_t
    real :: x, y                   ! Continuous coordinates
    real :: phi                    ! orientation 
    real :: fx, fy                 ! Forces from field-particle coupling
    real :: fx_pp, fy_pp           ! Forces from particle-particle repulsion
  end type Particle_t

  type :: Energy_t
    real :: field, pp, coupling
  end type Energy_t

end module mod_core_types