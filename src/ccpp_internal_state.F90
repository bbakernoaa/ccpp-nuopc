module ccpp_internal_state_mod
  use ESMF
  use, intrinsic :: iso_c_binding
  ! In a real integration, we would use the actual CCPP modules:
  ! use ccpp_types, only: ccpp_t
  ! use ccpp_framework, only: ccpp_init, ccpp_run, ccpp_finalize
  implicit none

  ! Placeholder for ccpp_t if the library is not yet compiled/linked
  type ccpp_t
     integer(c_int) :: dummy
  end type ccpp_t

  type ccpp_internal_state_type
    ! ESMF-related
    type(ESMF_Grid) :: grid

    ! Data arrays (pointers to ESMF field memory)
    ! Using c_double for consistency with CCPP requirements
    real(c_double), pointer :: temp(:,:) => null()
    real(c_double), pointer :: pres(:,:) => null()
    real(c_double), pointer :: q(:,:) => null()

    ! Diagnostic Export
    real(c_double), pointer :: rain(:,:) => null()

    ! Dimensions
    integer(c_int) :: ncol, nlev

    ! CCPP internal state handle
    type(ccpp_t) :: ccpp_state

  end type ccpp_internal_state_type

  interface
    subroutine ccpp_init(ccpp_state, suite, rc)
      import :: ccpp_t, c_int
      type(ccpp_t), intent(inout) :: ccpp_state
      character(*), intent(in)    :: suite
      integer(c_int), intent(out) :: rc
    end subroutine ccpp_init

    subroutine ccpp_run(ccpp_state, suite, ncol, nlev, temp, pres, q, rain, rc)
      import :: ccpp_t, c_int, c_double
      type(ccpp_t), intent(inout) :: ccpp_state
      character(*), intent(in)    :: suite
      integer(c_int), intent(in)  :: ncol, nlev
      real(c_double), intent(in)  :: temp(ncol, nlev), pres(ncol, nlev)
      real(c_double), intent(out) :: q(ncol, nlev), rain(ncol, nlev)
      integer(c_int), intent(out) :: rc
    end subroutine ccpp_run

    subroutine ccpp_finalize(ccpp_state, rc)
      import :: ccpp_t, c_int
      type(ccpp_t), intent(inout) :: ccpp_state
      integer(c_int), intent(out)   :: rc
    end subroutine ccpp_finalize
  end interface

end module ccpp_internal_state_mod
