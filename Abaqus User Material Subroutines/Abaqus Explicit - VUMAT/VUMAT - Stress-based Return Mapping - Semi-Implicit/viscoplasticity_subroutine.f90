!=======================================================================
! User Material Subroutine for Isotropic Elasto-Visco-Plasticity
! CDD-based Material Model
! Semi-Implicit Constitutive Integration with Stress-based Return Mapping
!
! Author: Seyed Amir Hossein Motaman
! Steel Institute (IEHK), RWTH Aachen University
!
! References:
!    Motaman, S.A.H.; Prahl, U.; 2019.
!    Microstructural constitutive model for polycrystal viscoplasticity
!    in cold and warm regimes based on continuum dislocation dynamics.
!    Journal of the Mechanics and Physics of Solids 122, 205–243.
!    doi: https://doi.org/10.1016/j.jmps.2018.09.002
!
!    Motaman, S.A.H.; Schacht K.; Haase, C.; Prahl, U.; 2019.
!    Thermo-micro-mechanical simulation of metal forming processes.
!    International Journal of Solids and Structures.
!    doi: https://doi.org/10.1016/j.ijsolstr.2019.05.028
!=======================================================================

!***********************************************************************
! subroutine header
  subroutine viscoplasticity(trial_flag, i_material, delta_t, T_hat_n, eps_bar_dot_p_corr, delta_eps_bar_p, rho_hat_cm_n, rho_hat_ci_n, rho_hat_wi_n, rho_hat_cm, rho_hat_ci, rho_hat_wi, sigma_y, H_vp, beta)

!-----------------------------------------------------------------------
!    use of global variables
     use controls
     use material_properties

!-----------------------------------------------------------------------
!    declaration of subroutine's parameters
     implicit none

     logical,       intent(in) :: &
         trial_flag

     integer(pInt), intent(in) :: &
         i_material

     real(pReal),   intent(in) :: &
         delta_t, &
         T_hat_n, &
         eps_bar_dot_p_corr, &
         delta_eps_bar_p, &
         rho_hat_cm_n, &
         rho_hat_ci_n, &
         rho_hat_wi_n

     real(pReal),   intent(out) :: &
         rho_hat_cm, &
         rho_hat_ci, &
         rho_hat_wi, &
         sigma_y, &
         H_vp, &
         beta

!-----------------------------------------------------------------------
!    declaration of Local variables
     real(pReal) :: &
         G_alpha_c, &                                                    ! combination of shear modulus and interaction coefficient associated with cell immobile dislocations at current temperature [-]
         G_alpha_w, &                                                    ! combination of shear modulus and interaction coefficient associated with wall immobile dislocations at current temperature [-]
         m_v, &                                                          ! strain rate sensitivity associated with viscous stress at current temperature [-]
         sigma_v, &                                                      ! viscous stress at current temperature and strain rate [MPa]
         sigma_pc, &                                                     ! plastic stress associated with cell immobile dislocations [MPa]
         sigma_pw, &                                                     ! plastic stress associated with wall immobile dislocations [MPa]
         m_an_cm, &                                                      ! strain rate sensitivity parameter associated with dynamic annihilation   of cell mobile   dislocations [-]
         m_an_ci, &                                                      ! strain rate sensitivity parameter associated with dynamic annihilation   of cell immobile dislocations [-]
         m_an_wi, &                                                      ! strain rate sensitivity parameter associated with dynamic annihilation   of wall immobile dislocations [-]
         m_tr_cm, &                                                      ! strain rate sensitivity parameter associated with dynamic trapping       of cell mobile   dislocations [-]
         m_nc_wi, &                                                      ! strain rate sensitivity parameter associated with dynamic nucleation     of wall immobile dislocations [-]
         m_rm_ci, &                                                      ! strain rate sensitivity parameter associated with dynamic remobilization of cell immobile dislocations [-]
         m_rm_wi, &                                                      ! strain rate sensitivity parameter associated with dynamic remobilization of wall immobile dislocations [-]
         c_gn_cm, &                                                      ! material parameter associated with dynamic generation     of cell mobile   dislocations at current temperature [-]
         c_an_cm, &                                                      ! material parameter associated with dynamic annihilation   of cell mobile   dislocations at current temperature [-]
         c_an_ci, &                                                      ! material parameter associated with dynamic annihilation   of cell immobile dislocations at current temperature [-]
         c_an_wi, &                                                      ! material parameter associated with dynamic annihilation   of wall immobile dislocations at current temperature [-]
         c_ac_ci, &                                                      ! material parameter associated with dynamic accumulation   of cell immobile dislocations at current temperature [-]
         c_ac_wi, &                                                      ! material parameter associated with dynamic accumulation   of wall immobile dislocations at current temperature [-]
         c_tr_cm, &                                                      ! material parameter associated with dynamic trapping       of cell mobile   dislocations at current temperature [-]
         c_nc_wi, &                                                      ! material parameter associated with dynamic nucleation     of cell immobile dislocations at current temperature [-]
         c_rm_ci, &                                                      ! material parameter associated with dynamic remobilization of cell immobile dislocations at current temperature [-]
         c_rm_wi, &                                                      ! material parameter associated with dynamic remobilization of wall immobile dislocations at current temperature [-]
         del_rho_hat_gn_cm_n, &                                          ! normalized dynamic generation     rate of cell mobile    dislocations w.r.t. equivalent plastic strain at the beginning of the time increment [-]
         del_rho_hat_an_cm_n, &                                          ! normalized dynamic annihilation   rate of cell mobile    dislocations w.r.t. equivalent plastic strain at the beginning of the time increment [-]
         del_rho_hat_an_ci_n, &                                          ! normalized dynamic annihilation   rate of cell immmobile dislocations w.r.t. equivalent plastic strain at the beginning of the time increment [-]
         del_rho_hat_an_wi_n, &                                          ! normalized dynamic annihilation   rate of wall immmobile dislocations w.r.t. equivalent plastic strain at the beginning of the time increment [-]
         del_rho_hat_ac_ci_n, &                                          ! normalized dynamic accumulation   rate of cell immmobile dislocations w.r.t. equivalent plastic strain at the beginning of the time increment [-]
         del_rho_hat_ac_wi_n, &                                          ! normalized dynamic accumulation   rate of wall immmobile dislocations w.r.t. equivalent plastic strain at the beginning of the time increment [-]
         del_rho_hat_tr_cm_n, &                                          ! normalized dynamic trapping       rate of cell mobile    dislocations w.r.t. equivalent plastic strain at the beginning of the time increment [-]
         del_rho_hat_nc_wi_n, &                                          ! normalized dynamic nucleation     rate of wall immmobile dislocations w.r.t. equivalent plastic strain at the beginning of the time increment [-]
         del_rho_hat_rm_ci_n, &                                          ! normalized dynamic remobilization rate of cell immmobile dislocations w.r.t. equivalent plastic strain at the beginning of the time increment [-]
         del_rho_hat_rm_wi_n, &                                          ! normalized dynamic remobilization rate of wall immmobile dislocations w.r.t. equivalent plastic strain at the beginning of the time increment [-]
         del_rho_hat_cm_n, &                                             ! derivative of cell mobile   dislocation density                       w.r.t. equivalent plastic strain at the beginning of the time increment [-]
         del_rho_hat_ci_n, &                                             ! derivative of cell immobile dislocation density                       w.r.t. equivalent plastic strain at the beginning of the time increment [-]
         del_rho_hat_wi_n                                                ! derivative of wall immobile dislocation density                       w.r.t. equivalent plastic strain at the beginning of the time increment [-]

!-----------------------------------------------------------------------
!    processing

!    calculation of temperature-dependent product of shear modulus and interaction strength, and strain rate sensitivity of viscous stress
     G_alpha_c = G_0(i_material) * alpha_c0(i_material) * (1.0e0 + r_G_alpha_c(i_material) * (T_hat_n - 1.0e0)**s_G_alpha_c(i_material))   ! {Eq. 93(c)}
     G_alpha_w = G_0(i_material) * alpha_w0(i_material) * (1.0e0 + r_G_alpha_w(i_material) * (T_hat_n - 1.0e0)**s_G_alpha_w(i_material))   ! {Eq. 93(c)}
     m_v       = m_v0(i_material) * (1.0e0 + r_mv(i_material) * (T_hat_n - 1.0e0)**s_mv(i_material))                                       ! {Eq. 94(d)}

     if (trial_flag) then
!        initializing microstructural state variables (different types of dislocation density)   {Eq. Box 1.6(c)}
         rho_hat_cm = rho_hat_cm_n
         rho_hat_ci = rho_hat_ci_n
         rho_hat_wi = rho_hat_wi_n

!        calculation of trial yield/flow stress
         sigma_v  = sigma_v00(i_material) * (1.0e0 + r_v(i_material) * (T_hat_n - 1.0e0)**s_v(i_material)) * (eps_bar_dot_p_corr / eps_bar_dot_0(i_material))**m_v   ! {Eq. 100}
         sigma_pc = M(i_material) * b(i_material) * G_alpha_c * sqrt(rho_0(i_material) * rho_hat_ci)   ! {Eq. 98}
         sigma_pw = M(i_material) * b(i_material) * G_alpha_w * sqrt(rho_0(i_material) * rho_hat_wi)   ! {Eq. 98}
         sigma_y  = sigma_v + sigma_pc + sigma_pw   ! {Eq. 97}
     else
!        calculation of strain rate sensitivity parameters associated with different dynamic dislocation processes   {Eq. 95(b)}
         m_an_cm = m_an_cm0(i_material) * (1.0e0 + r_m_an_cm(i_material) * (T_hat_n - 1.0e0)**s_m_an_cm(i_material))
         m_an_ci = m_an_ci0(i_material) * (1.0e0 + r_m_an_ci(i_material) * (T_hat_n - 1.0e0)**s_m_an_ci(i_material))
         m_an_wi = m_an_wi0(i_material) * (1.0e0 + r_m_an_wi(i_material) * (T_hat_n - 1.0e0)**s_m_an_wi(i_material))
         m_tr_cm = m_tr_cm0(i_material) * (1.0e0 + r_m_tr_cm(i_material) * (T_hat_n - 1.0e0)**s_m_tr_cm(i_material))
         m_nc_wi = m_nc_wi0(i_material) * (1.0e0 + r_m_nc_wi(i_material) * (T_hat_n - 1.0e0)**s_m_nc_wi(i_material))
         m_rm_ci = m_rm_ci0(i_material) * (1.0e0 + r_m_rm_ci(i_material) * (T_hat_n - 1.0e0)**s_m_rm_ci(i_material))
         m_rm_wi = m_rm_wi0(i_material) * (1.0e0 + r_m_rm_wi(i_material) * (T_hat_n - 1.0e0)**s_m_rm_wi(i_material))

!        calculation of probability amplitudes associated with different dynamic dislocation processes   {Eqs. 63, 95}
         c_gn_cm = c_gn_cm0(i_material)
         c_an_cm = c_an_cm0(i_material) * (1.0e0 + r_an_cm(i_material)   * (T_hat_n - 1.0e0)**s_an_cm(i_material)) * (delta_eps_bar_p / delta_t / eps_bar_dot_0(i_material))**m_an_cm
         c_an_ci = c_an_ci0(i_material) * (1.0e0 + r_an_ci(i_material)   * (T_hat_n - 1.0e0)**s_an_ci(i_material)) * (delta_eps_bar_p / delta_t / eps_bar_dot_0(i_material))**m_an_ci
         c_an_wi = c_an_wi0(i_material) * (1.0e0 + r_an_wi(i_material)   * (T_hat_n - 1.0e0)**s_an_wi(i_material)) * (delta_eps_bar_p / delta_t / eps_bar_dot_0(i_material))**m_an_wi
         c_ac_ci = c_ac_ci0(i_material)
         c_ac_wi = c_ac_wi0(i_material)
         c_tr_cm = c_tr_cm0(i_material) * (1.0e0 + r_tr_cm(i_material)   * (T_hat_n - 1.0e0)**s_tr_cm(i_material)) * (delta_eps_bar_p / delta_t / eps_bar_dot_0(i_material))**m_tr_cm
         c_nc_wi = c_nc_wi0(i_material) * (1.0e0 + r_nc_wi(i_material)   * (T_hat_n - 1.0e0)**s_nc_wi(i_material)) * (delta_eps_bar_p / delta_t / eps_bar_dot_0(i_material))**m_nc_wi
         c_rm_ci = c_rm_ci0(i_material) * (1.0e0 + r_rm_ci(i_material)   * (T_hat_n - 1.0e0)**s_rm_ci(i_material)) * (delta_eps_bar_p / delta_t / eps_bar_dot_0(i_material))**m_rm_ci
         c_rm_wi = c_rm_wi0(i_material) * (1.0e0 + r_rm_wi(i_material)   * (T_hat_n - 1.0e0)**s_rm_wi(i_material)) * (delta_eps_bar_p / delta_t / eps_bar_dot_0(i_material))**m_rm_wi

!        calculation of dimensionless rates (w.r.t. equivalent plastic strain) or kinetics of different dynamic dislocation processes at the beginning of the time increment   {Eq. 60}
         del_rho_hat_gn_cm_n = M(i_material) * c_gn_cm * rho_hat_cm_n / sqrt(rho_hat_ci_n + rho_hat_wi_n)
         del_rho_hat_an_cm_n = M(i_material) * c_an_cm * rho_hat_cm_n * rho_hat_cm_n
         del_rho_hat_an_ci_n = M(i_material) * c_an_ci * rho_hat_ci_n * rho_hat_cm_n
         del_rho_hat_an_wi_n = M(i_material) * c_an_wi * rho_hat_wi_n * rho_hat_cm_n
         del_rho_hat_ac_ci_n = M(i_material) * c_ac_ci * sqrt(rho_hat_ci_n) * rho_hat_cm_n
         del_rho_hat_ac_wi_n = M(i_material) * c_ac_wi * sqrt(rho_hat_wi_n) * rho_hat_cm_n
         del_rho_hat_tr_cm_n = M(i_material) * c_tr_cm * sqrt(rho_hat_cm_n) * rho_hat_cm_n
         del_rho_hat_nc_wi_n = M(i_material) * c_nc_wi * sqrt(rho_hat_ci_n) * rho_hat_ci_n * rho_hat_cm_n
         del_rho_hat_rm_ci_n = M(i_material) * c_rm_ci * rho_hat_ci_n
         del_rho_hat_rm_wi_n = M(i_material) * c_rm_wi * rho_hat_wi_n

!        calculation of dimensionless rates (w.r.t. equivalent plastic strain) or kinetics of different types of dislocation densities at the beginning of the time increment   {Eq. 59}
         del_rho_hat_cm_n = del_rho_hat_gn_cm_n + del_rho_hat_rm_ci_n + del_rho_hat_rm_wi_n &
                          - (2.0e0 * del_rho_hat_an_cm_n + del_rho_hat_an_ci_n + del_rho_hat_an_wi_n + del_rho_hat_ac_ci_n + del_rho_hat_ac_wi_n + del_rho_hat_tr_cm_n)
         del_rho_hat_ci_n = del_rho_hat_ac_ci_n + del_rho_hat_tr_cm_n - (del_rho_hat_an_ci_n + del_rho_hat_nc_wi_n + del_rho_hat_rm_ci_n)
         del_rho_hat_wi_n = del_rho_hat_ac_wi_n + del_rho_hat_nc_wi_n - (del_rho_hat_an_wi_n + del_rho_hat_rm_wi_n)

!        calculation of microstructural state variables (different types of dislocation density) at the end of the time increment   {Eq. 90}
         rho_hat_cm = rho_hat_cm_n + delta_eps_bar_p * del_rho_hat_cm_n
         rho_hat_ci = rho_hat_ci_n + delta_eps_bar_p * del_rho_hat_ci_n
         rho_hat_wi = rho_hat_wi_n + delta_eps_bar_p * del_rho_hat_wi_n

!        calculation of yield/flow stress
         sigma_v  = sigma_v00(i_material) * (1.0e0 + r_v(i_material) * (T_hat_n - 1.0e0)**s_v(i_material)) * (delta_eps_bar_p / delta_t / eps_bar_dot_0(i_material))**m_v   ! {Eq. 94}
         sigma_pc = M(i_material) * b(i_material) * G_alpha_c * sqrt(rho_0(i_material) * rho_hat_ci)   ! {Eq. 93}
         sigma_pw = M(i_material) * b(i_material) * G_alpha_w * sqrt(rho_0(i_material) * rho_hat_wi)   ! {Eq. 93}
         sigma_y  = sigma_v + sigma_pc + sigma_pw   ! {Eq. 131}

!        calculation of viscoplastic tangent modulus   {Eqs. 106, 107, 108}
         H_vp = m_v / delta_eps_bar_p * sigma_v &
              + (del_rho_hat_ci_n + m_tr_cm * del_rho_hat_tr_cm_n - (m_an_ci * del_rho_hat_an_ci_n + m_rm_ci * del_rho_hat_rm_ci_n + m_nc_wi * del_rho_hat_nc_wi_n)) / (2.0e0 * rho_hat_ci) * sigma_pc &
              + (del_rho_hat_wi_n + m_nc_wi * del_rho_hat_nc_wi_n - (m_an_wi * del_rho_hat_an_wi_n + m_rm_wi * del_rho_hat_rm_wi_n)) / (2.0e0 * rho_hat_wi) * sigma_pw

!        calculation of dissipation factor   {Eq. 65}
         beta = (2.0e0 * (del_rho_hat_an_cm_n + del_rho_hat_an_ci_n + del_rho_hat_an_wi_n) / del_rho_hat_gn_cm_n)**kappa(i_material)
     end if

  end subroutine viscoplasticity