program main
  use mod_core_types
  use mod_field      ! Pure field thermodynamics and kinetics
  use mod_coupling   ! The specific interaction logic you provided
  use mod_particles  ! Pure particle repulsion and integration
  use mod_io         ! Parameters and output
  implicit none

  ! Data structures
  type(Config_t)                    :: cfg
  type(Particle_t), allocatable     :: particles(:)
  real, allocatable, dimension(:,:) :: psi, mu_total
  ! Pre-allocated noise buffers
  real, allocatable :: csi1(:,:)
  real, allocatable :: csi2(:,:)
  type(Energy_t)                    :: curr_energy
  integer                           :: t
  real                              :: psieq

  ! CPU time variables 
  real :: t1,t2

  ! restart variables 
  logical :: restart_found,equilibrated_found
  integer :: start_t

  ! time code starts
  call cpu_time(t1)

  ! 1. SETUP
  ! load_parameters now populates Reff_2 and R0_2 for efficiency
  call load_parameters(cfg)

  ! conversions 
  psieq = sqrt( cfg%tau  / cfg%u )
  print*, 'Equilibirum psi=',psieq

  print*, 'affinity before scaling = ',cfg%affinity
  cfg%affinity = cfg%affinity * psieq
  print*, 'affinity after scaling = ',cfg%affinity


  allocate(particles(cfg%Np))
  allocate(psi(cfg%Lx, cfg%Ly), mu_total(cfg%Lx, cfg%Ly))
  allocate(csi1(cfg%Lx, cfg%Ly),csi2(cfg%Lx, cfg%Ly))
  
  ! Initialize field noise and random particle positions
  ! CHECK FOR RESTART
  inquire(file='checkpoint.bin', exist=restart_found)

  ! CHECK FOR START FROM EQUILIBRATION
  inquire( file = 'equilibrated.bin' , exist=equilibrated_found)

  if (restart_found) then
      print *, ">>> RESTART FILE DETECTED. Loading state..."
      call load_checkpoint('checkpoint.bin', t, psi, particles)
      start_t = t + 1
  elseif (equilibrated_found) then 
      print *, ">>> EQUILIBRATED FILE DETECTED. Loading state..."
      call load_checkpoint('equilibrated.bin', t, psi, particles)
      start_t = 1
  else
      print *, ">>> No restart file. Initializing new system."
      if (cfg%custom_init) then
        print*, 'initialising with a custom-defined state'
        print*, 'by default: sinusoidal spanning whole system'
        print*, 'to modify initial custom state: ``initialize_custom_system.f90``'
        print*, '' 
        call initialize_custom_system(particles, psi, cfg)        
      else
        print*, 'initialise completely random state'
        call initialize_system(particles, psi, cfg)
      endif 
      start_t = 1
  end if

  ! Print Header to Screen
  print *, "----------------------------------------------"
  print *, "Simulation Started"
  print "(A, I4, A, I4)", " Grid Size: ", cfg%Lx, " x ", cfg%Ly
  print "(A, I6)",         " Particles: ", cfg%Np
  print "(A, I10)",        " Total Steps: ", cfg%total_steps
  print *, "----------------------------------------------"
  print *, "Additional parameters" 
  print*, "particle surface fraction ", &
            cfg%Np * pi * cfg%R0**2 / ( cfg%Lx* cfg%Ly )
  print*, "Pe ", cfg%vact / ( cfg%diam * cfg%temperature / cfg%gamm_R )


  print *, "----------------------------------------------"  
  t = start_t
  print*, 'do a <<dry>> run at t=',t, 'to calculate properties' 
  call calculate_mu_pure(mu_total, psi, cfg, curr_energy%field)
  call compute_pp_forces(particles, cfg, curr_energy%pp)
  call coupling(mu_total, psi, particles, cfg, curr_energy%coupling)

  print*, 'save initial state'
  call write_stats(t, psi, particles, cfg, curr_energy)
  call write_data(psi, particles, t)
  ! Print status to screen
  print "(A, I10, A, F6.2, A)", " >> Step: ", t, &
        " (", (real(t)/real(cfg%total_steps))*100.0, "%) - Data Saved."

  ! 2. HYBRID TIME-STEPPING (Explicit Euler-Scheme)
  do t = start_t, cfg%total_steps
    
    ! A. Thermodynamics: Field & Interaction
    ! 1. Pure Field Chemical Potential (Cahn-Hilliard bulk + surface)
    call calculate_mu_pure(mu_total, psi, cfg, curr_energy%field)
    
    ! 2. Coupling (Your specific logic: psic bump, dpsi, and integrated forces)
    ! This updates mu_total and fills particles(:)%fx and %fy
    if ( cfg%sigma>0.0 ) call coupling(mu_total, psi, particles, cfg, curr_energy%coupling)

    ! B. Field Kinetics: Diffusion Step (Model B)
    ! d_psi/dt = M * Laplacian(mu_total)
    call evolve_field_model_b(psi, mu_total, cfg)

    if ( cfg%noiseStrength > 0.0) call noise(psi, cfg,csi1,csi2)

    ! C. Particle Kinetics: Repulsion & Motion
    ! 1. Pure Particle-Particle Repulsion (using hard-core R0)
    call compute_pp_forces(particles, cfg, curr_energy%pp)
    
    ! 2. Integrate Brownian Motion (Langevin / Euler-Maruyama)
    ! Uses combined forces: F_total = F_coupling + F_repulsion
    call integrate_particles(particles, cfg)

    ! D. I/O and Standard Output
    if (mod(t, cfg%save_interval) == 0) then
        ! Print status to screen
        print "(A, I10, A, F6.2, A)", " >> Step: ", t, &
              " (", (real(t)/real(cfg%total_steps))*100.0, "%) - Data Saved."
        
        call write_data(psi, particles, t)
    end if

    ! Statistical Saving (Summary file)
    if (mod(t, cfg%stats_interval) == 0) then
      call write_stats(t, psi, particles, cfg, curr_energy)
    endif

    ! PERIODIC CHECKPOINT (e.g., every save_interval)
    if (mod(t, cfg%save_interval) == 0) then
        call save_checkpoint('checkpoint.bin', t, psi, particles)
    end if
    
  end do

  ! save final state 
  print*, "saving final state at t=",t
  print*, 'saving state at *.txt'
  call write_data(psi, particles, t)
  print*, 'saving stats at *.dat'
  call write_stats(t, psi, particles, cfg, curr_energy)
  print*, 'saving checkpoint.bin in binary file for possible restart'
  call save_checkpoint('checkpoint.bin', t, psi, particles)

  ! 3. CLEANUP
  deallocate(psi, mu_total, particles)

  ! performance information 
  call cpu_time(t2)
  open(unit=10, file='performance.txt', status='replace')
  write(10,*) 'CPU_Time_Seconds:', t2 - t1
  close(10)

  ! closing message
  print*, "program finishes normally"

end program main
