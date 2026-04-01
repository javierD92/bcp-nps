module mod_io
  use mod_core_types
  implicit none
  public :: load_parameters, initialize_system, write_data, write_stats

contains

  subroutine load_parameters(cfg)
    type(Config_t), intent(out) :: cfg
    
    open(unit=10, file='parameters.in', status='old', action='read')
    
    ! Grid and Simulation timing
    read(10, *) cfg%Lx, cfg%Ly
    read(10, *) cfg%Np
    read(10, *) cfg%total_steps
    read(10, *) cfg%save_interval
    read(10, *) cfg%stats_interval
    read(10, *) cfg%dt
    
    ! Model B Parameters
    read(10, *) cfg%M, cfg%kappa, cfg%tau, cfg%u
    read(10, *) cfg%psimean 
    
    ! Coupling and Particle Parameters
    read(10, *) cfg%sigma, cfg%affinity
    read(10, *) cfg%Reff
    read(10, *) cfg%epsilon, cfg%R0
    read(10, *) cfg%temperature 
    read(10, *) cfg%gamm_T,cfg%gamm_R
    read(10, *) cfg%vact
    read(10,* ) cfg%noiseStrength
    read(10, *) cfg%custom_init

    close(10)

    ! Pre-calculate squared radii for performance
    cfg%Reff_2 = cfg%Reff**2
    cfg%R0_2   = cfg%R0**2

    cfg%diam = 2.0 * cfg%R0
    cfg%d_2 = cfg%diam**2
    cfg%d_6 = cfg%diam**6

    ! Yukawa cutoff
    cfg%r_cut_sq = cfg%diam**2

  end subroutine load_parameters

  subroutine initialize_system(particles, psi, cfg)
    type(Particle_t), intent(inout) :: particles(:)
    real,             intent(inout) :: psi(:,:)
    type(Config_t),   intent(in)    :: cfg
    integer :: i, j, attempts, max_attempts
    real    :: tx, ty, dx, dy, r2, safe_dist_sq
    logical :: overlapping

    ! 1. Initialize the Field
    call random_number(psi)
    psi = (psi - 0.5) * 0.1 + cfg%psimean
    
    ! 2. Initialize Particles with Overlap Check
    ! We use d^2 as a minimum safety distance (slightly less than r_cut)
    safe_dist_sq = cfg%d_2 
    max_attempts = 1000  ! Prevent infinite loops if density is too high

    do i = 1, cfg%Np
      attempts = 0
      do
        attempts = attempts + 1
        overlapping = .false.
        
        ! Generate trial position
        call random_number(tx); tx = tx * real(cfg%Lx)
        call random_number(ty); ty = ty * real(cfg%Ly)
        
        ! Check against all already placed particles
        do j = 1, i - 1
          dx = tx - particles(j)%x
          dy = ty - particles(j)%y
          
          ! Minimum Image Convention (very important even at t=0)
          if (abs(dx) > cfg%Lx * 0.5) dx = dx - sign(real(cfg%Lx), dx)
          if (abs(dy) > cfg%Ly * 0.5) dy = dy - sign(real(cfg%Ly), dy)
          
          r2 = dx**2 + dy**2
          if (r2 < safe_dist_sq) then
            overlapping = .true.
            exit ! Exit the j-loop
          end if
        end do
        
        ! If safe or we ran out of patience, accept the position
        if (.not. overlapping .or. attempts > max_attempts) then
          if (attempts > max_attempts) print*, "Warning: Could not find non-overlapping spot for particle", i
          particles(i)%x = tx
          particles(i)%y = ty
          exit ! Exit the attempt-loop
        end if
      end do

      ! Initialize other properties
      particles(i)%fx = 0.0; particles(i)%fy = 0.0
      particles(i)%fx_pp = 0.0; particles(i)%fy_pp = 0.0
      call random_number(particles(i)%phi)
      particles(i)%phi = TWO_PI * particles(i)%phi
    end do
  end subroutine initialize_system

  ! initialise custom psi
  subroutine initialize_custom_system(particles, psi, cfg)
    type(Particle_t), intent(inout) :: particles(:)
    real,             intent(inout) :: psi(:,:)
    type(Config_t),   intent(in)    :: cfg
    integer :: i, j, attempts, max_attempts
    real    :: tx, ty, dx, dy, r2, safe_dist_sq
    logical :: overlapping

    ! 1. Initialize the Field custom
    do i = 1, cfg%Lx
      do j = 1, cfg%Ly
        psi(i,j) = sin(  2*pi * real(i) / real( cfg%Lx ))
      enddo
    enddo
      
    
    ! 2. Initialize Particles with Overlap Check
    ! We use d^2 as a minimum safety distance (slightly less than r_cut)
    safe_dist_sq = cfg%d_2 
    max_attempts = 1000  ! Prevent infinite loops if density is too high

    do i = 1, cfg%Np
      attempts = 0
      do
        attempts = attempts + 1
        overlapping = .false.
        
        ! Generate trial position
        call random_number(tx); tx = tx * real(cfg%Lx)
        call random_number(ty); ty = ty * real(cfg%Ly)

        ! put all particles in one half
        tx = 0.5 * tx
        
        ! Check against all already placed particles
        do j = 1, i - 1
          dx = tx - particles(j)%x
          dy = ty - particles(j)%y
          
          ! Minimum Image Convention (very important even at t=0)
          if (abs(dx) > cfg%Lx * 0.5) dx = dx - sign(real(cfg%Lx), dx)
          if (abs(dy) > cfg%Ly * 0.5) dy = dy - sign(real(cfg%Ly), dy)
          
          r2 = dx**2 + dy**2
          if (r2 < safe_dist_sq) then
            overlapping = .true.
            exit ! Exit the j-loop
          end if
        end do
        
        ! If safe or we ran out of patience, accept the position
        if (.not. overlapping .or. attempts > max_attempts) then
          if (attempts > max_attempts) print*, "Warning: Could not find non-overlapping spot for particle", i
          particles(i)%x = tx
          particles(i)%y = ty
          exit ! Exit the attempt-loop
        end if
      end do

      ! Initialize other properties
      particles(i)%fx = 0.0; particles(i)%fy = 0.0
      particles(i)%fx_pp = 0.0; particles(i)%fy_pp = 0.0
      call random_number(particles(i)%phi)
      particles(i)%phi = TWO_PI * particles(i)%phi
    end do
  end subroutine initialize_custom_system



  subroutine write_data(psi, particles, t)
    real,             intent(in) :: psi(:,:)
    type(Particle_t), intent(in) :: particles(:)
    integer,          intent(in) :: t
    integer :: p, i, j
    character(len=64) :: pfname, ffname
    
    ! I0 will adjust the width automatically (e.g., 'particles_10.dat', 'particles_1000000.dat')
    write(pfname, '(A,I0,A)') 'particles_', t, '.txt'
    open(unit=20, file=trim(pfname), status='replace')
    do p = 1, size(particles)
      write(20, '(3F12.4)') particles(p)%x, particles(p)%y, particles(p)%phi
    end do
    close(20)

    write(ffname, '(A,I0,A)') 'field_psi_', t, '.txt'
    open(unit=30, file=trim(ffname), status='replace')
    do j = 1, size(psi, 2)
      do i = 1, size(psi, 1)
        write(30, '(2I6, F12.6)') i, j, psi(i,j)
      end do
      write(30, *) 
    end do
    close(30)
  end subroutine write_data

subroutine write_stats(t, psi, particles, cfg, energy)
    use mod_stats  ! To access calculate_domain_size
    integer,        intent(in) :: t
    real,           intent(in) :: psi(:,:)
    type(Particle_t), intent(in) :: particles(:)
    type(Config_t),   intent(in) :: cfg
    type(Energy_t),   intent(in) :: energy
    
    real    :: domain_size, e_total
    real :: psiavg, psiabsavg
    logical :: op_energy, op_stats
    logical :: file_exists

    ! 1. Calculate the physics-based statistics
    call calculate_domain_size(psi, cfg, domain_size)

    ! calculate mean value of psi and mean abolute value of psi with respect to average value 
    call psi_averages( psi, cfg, psiavg, psiabsavg )

    e_total = energy%field + energy%pp + energy%coupling

    ! 2. Handle Free Energy File (Unit 40)
    inquire(unit=40, opened=op_energy)
    if (.not. op_energy) then
        inquire(file='free_energy.dat', exist=file_exists)
        ! Use 'append' to add to the end of the file instead of replacing
        open(40, file='free_energy.dat', status='unknown', position='append')
        
        ! Only write header if the file didn't exist before
        if (.not. file_exists) then
            write(40, '(A10, 4A15)') "# Step", "E_Field", "E_PP", "E_Coupling", "E_Total"
        end if
    end if
    write(40, '(I10, 4ES15.6)') t, energy%field, energy%pp, energy%coupling, e_total
    flush(40)

    ! 3. Handle Statistics File (Unit 41)
    inquire(unit=41, opened=op_stats)
    if (.not. op_stats) then
        inquire(file='stats.dat', exist=file_exists)
        open(41, file='stats.dat', status='unknown', position='append')
        
        if (.not. file_exists) then
            write(41, '(A10, A20)') "# Step", "Domain_Size"
        end if
    end if
    write(41, '(I10, 3ES20.8E2)') t, domain_size, psiavg, psiabsavg
    flush(41)

  end subroutine write_stats

  subroutine calculate_domain_size(psi, cfg, avg_size)
        real,    intent(in)  :: psi(:,:)
        type(Config_t), intent(in) :: cfg
        real,    intent(out) :: avg_size
        integer :: i, j, crossings
        
        crossings = 0

        ! Count sign changes relative to the mean field value
        ! Horizontal crossings
        do j = 1, cfg%Ly
            do i = 1, cfg%Lx
                if ((psi(i,j) - cfg%psimean) * &
                    (psi(modulo(i, cfg%Lx)+1, j) - cfg%psimean) < 0.0) then
                    crossings = crossings + 1
                end if
            end do
        end do

        ! Vertical crossings
        do i = 1, cfg%Lx
            do j = 1, cfg%Ly
                if ((psi(i,j) - cfg%psimean) * &
                    (psi(i, modulo(j, cfg%Ly)+1) - cfg%psimean) < 0.0) then
                    crossings = crossings + 1
                end if
            end do
        end do

        ! L ~ 2 * Area / Total Interface Length
        if (crossings > 0) then
            avg_size = (2.0 * real(cfg%Lx * cfg%Ly)) / real(crossings)
        else
            avg_size = real(cfg%Lx) 
        end if
    end subroutine calculate_domain_size

  subroutine save_checkpoint(filename, t, psi, particles)
    character(len=*), intent(in) :: filename
    integer, intent(in)          :: t
    real, intent(in)             :: psi(:,:)
    type(Particle_t), intent(in) :: particles(:)
    integer :: iunit

    open(newunit=iunit, file=filename, form='unformatted', status='replace')
    write(iunit) t
    write(iunit) psi
    write(iunit) particles
    close(iunit)
  end subroutine

  subroutine load_checkpoint(filename, t, psi, particles)
    character(len=*), intent(in) :: filename
    integer, intent(out)         :: t
    real, intent(out)            :: psi(:,:)
    type(Particle_t), intent(out):: particles(:)
    integer :: iunit

    open(newunit=iunit, file=filename, form='unformatted', status='old')
    read(iunit) t
    read(iunit) psi
    read(iunit) particles
    close(iunit)
  end subroutine

end module mod_io