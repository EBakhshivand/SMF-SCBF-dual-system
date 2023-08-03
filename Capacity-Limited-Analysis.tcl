 #######################################################################################################
# 	This subroutine is used to control the members of SCBFs for seismic requirements of AISC 341-16		#
# 							Written By Ehsan Bakhshivand (date: 01-Jun-2021) 							#
 #######################################################################################################

# Preliminary required functions:
# ------------------------------------------
proc Max {Var Val1 Val2} {
	upvar $Var var
	set var $Val1
	if {$Val2>$var} {
		set var $Val2
	}
}

proc Max4 {Var Val1 Val2 Val3 Val4} {
	upvar $Var var
	set var $Val1
	if {$Val2>$var} {
		set var $Val2
	}
	if {$Val3>$var} {
		set var $Val3
	}
	if {$Val4>$var} {
		set var $Val4
	}
}

proc Min4 {Var Val1 Val2 Val3 Val4} {
	upvar $Var var
	set var $Val1
	if {$Val2<$var} {
		set var $Val2
	}
	if {$Val3<$var} {
		set var $Val3
	}
	if {$Val4<$var} {
		set var $Val4
	}
}

# define UNITS written by Silvia Mazzoni & Frank McKenna, 2006---------------------------------------
set in 1.; 					# define basic units -- output units
set kip 1.; 				# define basic units -- output units
set sec 1.; 				# define basic units -- output units
set LunitTXT "inch";	    # define basic-unit text for output
set FunitTXT "kip";			# define basic-unit text for output
set TunitTXT "sec";			# define basic-unit text for output
set ft [expr 12.*$in]; 		# define engineering units
set ksi [expr $kip/pow($in,2)];
set psi [expr $ksi/1000.];
set lbf [expr $psi*$in*$in];		# pounds force
set pcf [expr $lbf/pow($ft,3)];		# pounds per cubic foot
set psf [expr $lbf/pow($ft,3)];		# pounds per square foot
set in2 [expr $in*$in]; 			# inch^2
set in4 [expr $in*$in*$in*$in]; 	# inch^4
set cm [expr $in/2.54];				# centimeter, needed for displacement input in MultipleSupport excitation
set PI [expr 2*asin(1.0)]; 			# define constants
set g [expr 32.2*$ft/pow($sec,2)]; 	# gravitational acceleration
set Ubig 1.e10; 					# a really large number
set Usmall [expr 1/$Ubig]; 			# a really small number
# ---------------------------------------------------------------------------------------------------

#source Units.tcl
#source Max.tcl
#source Max4.tcl
#source Min4.tcl

set NStory 2; # number of stories

# Insert section properties (Note: section properties can be extracted from Section-Details.xlsx)
# -----------------------------------------------------------------------------------------------
set inColumnID [open "Section_Properties/Columns.txt"]
set CsecData [split [read $inColumnID] \n]
set inBraceID [open "Section_Properties/Braces.txt"]
set BrsecData [split [read $inBraceID] \n]
set nline [llength $CsecData]
set SecOut [open BeamSections.txt w]
set CCID [open ColumnControl.txt w]

for {set i $nline} {$i>=1} {incr i -1} {
	set ColumnData [lindex $CsecData [expr abs($i-$nline)]]
	set BraceData [lindex $BrsecData [expr abs($i-$nline)]]
	set Ag_C($i)	[expr [lindex $ColumnData 0]*$in2]
	set r_C($i) 	[expr [lindex $ColumnData 1]*$in]
	set KL_C($i) 	[expr [lindex $ColumnData 2]*$in]
	set PD_C($i) 	[expr [lindex $ColumnData 3]*$kip]
	set PL_C($i) 	[expr [lindex $ColumnData 4]*$kip]
	set Ag_Br($i) 	[expr [lindex $BraceData 0]*$in2]
	set r_Br($i) 	[expr [lindex $BraceData 1]*$in]
	set KL_Br($i) 	[expr [lindex $BraceData 2]*$in]
}

# Gravity loads
# -------------
set DLroof [expr 987.5]
set DLtyp [expr 1.*1225]
set LLtyp [expr 1.*500]

# Computing compressive & tensile strength of braces
# --------------------------------------------------
set E [expr 29000.*$ksi]
set Fy_Br [expr 46*$ksi]
set Fu_Br [expr 58*$ksi]
set Fy [expr 50*$ksi]
set Fu [expr 65*$ksi]

for {set i 1} {$i<=$NStory} {incr i 1} {
	set Fe_Br($i) [expr pow($PI,2)*$E/(($KL_Br($i)/$r_Br($i))**2)]	
	if {(1.4*$Fy_Br)/$Fe_Br($i)<=2.25} {
		set Fcr_Br($i) [expr (0.658**((1.4*$Fy_Br)/$Fe_Br($i)))*(1.4*$Fy_Br)]
	} else {
		set Fcr_Br($i) [expr 0.877*$Fe_Br($i)]
	}
	set Pt_Br($i) [expr 1.4*$Fy_Br*$Ag_Br($i)]
	set PcES_Br($i) [expr 1.14*$Fcr_Br($i)*$Ag_Br($i)]
	set PcPB_Br($i) [expr 0.3*1.14*$Fcr_Br($i)*$Ag_Br($i)]
	# puts "PcES_Br($i)=$PcES_Br($i)"
	# puts "Pt_Br($i)=$Pt_Br($i)"
}

# Computing compressive & tensile strength of columns
# ---------------------------------------------------
set Fy [expr 50*$ksi]
set Fu [expr 65*$ksi]

for {set i 1} {$i<=$NStory} {incr i 1} {
	set Fe_C($i) [expr pow($PI,2)*$E/(($KL_C($i)/$r_C($i))**2)]	
	if {($Fy)/$Fe_C($i)<=2.25} {
		set Fcr_C($i) [expr (0.658**(($Fy)/$Fe_C($i)))*($Fy)]
	} else {
		set Fcr_C($i) [expr 0.877*$Fe_C($i)]
	}
	set Pc_C($i) [expr 0.9*$Fcr_C($i)*$Ag_C($i)]
	set Pt_C1($i) [expr 0.9*$Fy*$Ag_C($i)]
	set Pt_C2($i) [expr 0.75*$Fu*$Ag_C($i)]
	Max Pt_C($i) $Pt_C1($i) $Pt_C2($i)
	# puts "Pc_C($i)=$Pc_C($i)"
	# puts "Pt_C($i)=$Pt_C($i)"
}

# Computing required axial, shear and moment strength of beams for expected strength analysis
# -------------------------------------------------------------------------------------------
set teta1 [expr atan(180./120)];
set tetaTyp [expr atan(156./120)];
for {set i $NStory} {$i>=1} {incr i -1} {
	if {$i==$NStory} {
		set V_Story($i) [expr $PcES_Br($i)*cos($tetaTyp)+$Pt_Br($i)*cos($tetaTyp)]
		set v($i) [expr $V_Story($i)/(3*20.)];
		set V3($i) [expr $v($i)*20]
		set V4($i) [expr $v($i)*20]
		set Pr3($i) [expr $V3($i)-$PcES_Br($i)*cos($tetaTyp)]
		set Pr4($i) [expr $Pt_Br($i)*cos($tetaTyp)-$V4($i)]
		Max PrbES($i) $Pr3($i) $Pr4($i)
		set VrbES($i) [expr 1.*0]
		set MrbES($i) [expr 1.*0]
	} elseif {($i%2!=0)&&($i!=1)} {
		set Vbr($i) [expr $PcES_Br([expr $i+1])*sin($tetaTyp)-$Pt_Br([expr $i+1])*sin($tetaTyp)+$Pt_Br($i)*sin($tetaTyp)-$PcES_Br($i)*sin($tetaTyp)]
		set Hbr($i) [expr $Pt_Br($i)*cos($tetaTyp)+$PcES_Br($i)*cos($tetaTyp)-$PcES_Br([expr $i+1])*cos($tetaTyp)-$Pt_Br([expr $i+1])*cos($tetaTyp)]
		set RbES($i) [expr $Vbr($i)*0.5]
		set VrbES($i) [expr abs($RbES($i))]
		set MrbES($i) [expr $VrbES($i)*20./4]
		set v($i) [expr $Hbr($i)/(3*20.)]
		set V3($i) [expr $v($i)*20]
		set V4($i) [expr $v($i)*20]
		set PrbES($i) [expr $v($i)*30]
	} elseif {($i!=$NStory)&&($i%2==0)} {
		set V_Story($i) [expr $PcES_Br($i)*cos($tetaTyp)+$Pt_Br($i)*cos($tetaTyp)-$PcES_Br([expr $i+1])*cos($tetaTyp)-$Pt_Br([expr $i+1])*cos($tetaTyp)]
		set v($i) [expr $V_Story($i)/(3*20.)];
		set V3($i) [expr $v($i)*20]
		set V4($i) [expr $v($i)*20]
		set Pr3($i) [expr $V3($i)+$Pt_Br([expr $i+1])*cos($tetaTyp)-$PcES_Br($i)*cos($tetaTyp)]
		set Pr4($i) [expr $Pt_Br($i)*cos($tetaTyp)-$PcES_Br([expr $i+1])*cos($tetaTyp)-$V4($i)]
		Max PrbES($i) $Pr3($i) $Pr4($i)
		set VrbES($i) [expr 1.*0]
		set MrbES($i) [expr 1.*0]
	} else {
		set Vbr($i) [expr $PcES_Br([expr $i+1])*sin($tetaTyp)-$Pt_Br([expr $i+1])*sin($tetaTyp)+$Pt_Br($i)*sin($teta1)-$PcES_Br($i)*sin($teta1)]
		set Hbr($i) [expr -1*$Pt_Br($i)*cos($teta1)-$PcES_Br($i)*cos($teta1)+$PcES_Br([expr $i+1])*cos($tetaTyp)+$Pt_Br([expr $i+1])*cos($tetaTyp)]
		set RbES($i) [expr $Vbr($i)*0.5]
		set VrbES($i) [expr abs($RbES($i))]
		set MrbES($i) [expr $VrbES($i)*20./4]
		set v($i) [expr $Hbr($i)/(3*20.)]
		set V3($i) [expr $v($i)*20]
		set V4($i) [expr $v($i)*20]
		set PrbES($i) [expr abs($v($i)*30)]
	}
	# puts "PrbES($i)=$PrbES($i)"
	# puts "VrbES($i)=$VrbES($i)"
	# puts "MrbES($i)=$MrbES($i)"
}

# Computing required axial, shear and moment strength of beams for post buckling analysis
# ----------------------------------------------------------------------------------------
for {set i $NStory} {$i>=1} {incr i -1} {
	if {$i==$NStory} {
		set V_Story($i) [expr $PcPB_Br($i)*cos($tetaTyp)+$Pt_Br($i)*cos($tetaTyp)]
		set v($i) [expr $V_Story($i)/(3*20.)];
		set V3($i) [expr $v($i)*20]
		set V4($i) [expr $v($i)*20]
		set Pr3($i) [expr $V3($i)-$PcPB_Br($i)*cos($tetaTyp)]
		set Pr4($i) [expr $Pt_Br($i)*cos($tetaTyp)-$V4($i)]
		Max PrbPB($i) $Pr3($i) $Pr4($i)
		set VrbPB($i) [expr 1.*0]
		set MrbPB($i) [expr 1.*0]
	} elseif {($i%2!=0)&&($i!=1)} {
		set Vbr($i) [expr $PcPB_Br([expr $i+1])*sin($tetaTyp)-$Pt_Br([expr $i+1])*sin($tetaTyp)+$Pt_Br($i)*sin($tetaTyp)-$PcPB_Br($i)*sin($tetaTyp)]
		set Hbr($i) [expr $Pt_Br($i)*cos($tetaTyp)+$PcPB_Br($i)*cos($tetaTyp)-$PcPB_Br([expr $i+1])*cos($tetaTyp)-$Pt_Br([expr $i+1])*cos($tetaTyp)]
		set RbPB($i) [expr $Vbr($i)*0.5]
		set VrbPB($i) [expr abs($RbPB($i))]
		set MrbPB($i) [expr $VrbPB($i)*20./4]
		set v($i) [expr $Hbr($i)/(3*20.)]
		set V3($i) [expr $v($i)*20]
		set V4($i) [expr $v($i)*20]
		set PrbPB($i) [expr $v($i)*30]
	} elseif {($i!=$NStory)&&($i%2==0)} {
		set V_Story($i) [expr $PcPB_Br($i)*cos($tetaTyp)+$Pt_Br($i)*cos($tetaTyp)-$PcPB_Br([expr $i+1])*cos($tetaTyp)-$Pt_Br([expr $i+1])*cos($tetaTyp)]
		set v($i) [expr $V_Story($i)/(3*20.)];
		set V3($i) [expr $v($i)*20]
		set V4($i) [expr $v($i)*20]
		set Pr3($i) [expr $V3($i)+$Pt_Br([expr $i+1])*cos($tetaTyp)-$PcPB_Br($i)*cos($tetaTyp)]
		set Pr4($i) [expr $Pt_Br($i)*cos($tetaTyp)-$PcPB_Br([expr $i+1])*cos($tetaTyp)-$V4($i)]
		Max PrbPB($i) $Pr3($i) $Pr4($i)		
		set VrbPB($i) [expr 1.*0]
		set MrbPB($i) [expr 1.*0]
	} else {
		set Vbr($i) [expr $PcPB_Br([expr $i+1])*sin($tetaTyp)-$Pt_Br([expr $i+1])*sin($tetaTyp)+$Pt_Br($i)*sin($teta1)-$PcPB_Br($i)*sin($teta1)]
		set Hbr($i) [expr -1*$Pt_Br($i)*cos($teta1)-$PcPB_Br($i)*cos($teta1)+$PcPB_Br([expr $i+1])*cos($tetaTyp)+$Pt_Br([expr $i+1])*cos($tetaTyp)]
		set RbPB($i) [expr $Vbr($i)*0.5]
		set VrbPB($i) [expr abs($RbPB($i))]
		set MrbPB($i) [expr $VrbPB($i)*20./4]
		set v($i) [expr $Hbr($i)/(3*20.)]
		set V3($i) [expr $v($i)*20]
		set V4($i) [expr $v($i)*20]
		set PrbPB($i) [expr abs($v($i)*30)]
	}
	# puts "PrbPB($i)=$PrbPB($i)"
	# puts "VrbPB($i)=$VrbPB($i)"
	# puts "MrbPB($i)=$MrbPB($i)"
}

# Computing required axial strength of columns for expected strength analysis
# ---------------------------------------------------------------------------
for {set i $NStory} {$i>=1} {incr i -1} {
	if {$i==$NStory} {
		set Prc_CES($i) [expr $Pt_Br($i)*sin($tetaTyp)]
		set Prt_CES($i) [expr -1*$PcES_Br($i)*sin($tetaTyp)]
	} elseif {$i%2!=0} {
		set Prc_CES($i) [expr $Prc_CES([expr $i+1])+$RbES($i)]
		set Prt_CES($i) [expr $Prt_CES([expr $i+1])+$RbES($i)]
	} else {
		set Prc_CES($i) [expr $Prc_CES([expr $i+1])+$PcES_Br([expr $i+1])*sin($tetaTyp)+$Pt_Br($i)*sin($tetaTyp)]
		set Prt_CES($i) [expr $Prt_CES([expr $i+1])-$Pt_Br([expr $i+1])*sin($tetaTyp)-$PcES_Br($i)*sin($tetaTyp)]
	}
	# puts "Prc_CES($i)=$Prc_CES($i)"
	# puts "Prt_CES($i)=$Prt_CES($i)"
}

# Computing required axial strength of columns for post buckling analysis
# -----------------------------------------------------------------------
for {set i $NStory} {$i>=1} {incr i -1} {
	if {$i==$NStory} {
		set Prc_CPB($i) [expr $Pt_Br($i)*sin($tetaTyp)]
		set Prt_CPB($i) [expr -1*$PcPB_Br($i)*sin($tetaTyp)]
	} elseif {$i%2!=0} {
		set Prc_CPB($i) [expr $Prc_CPB([expr $i+1])+$RbPB($i)]
		set Prt_CPB($i) [expr $Prt_CPB([expr $i+1])+$RbPB($i)]
	} else {
		set Prc_CPB($i) [expr $Prc_CPB([expr $i+1])+$PcPB_Br([expr $i+1])*sin($tetaTyp)+$Pt_Br($i)*sin($tetaTyp)]
		set Prt_CPB($i) [expr $Prt_CPB([expr $i+1])-$Pt_Br([expr $i+1])*sin($tetaTyp)-$PcPB_Br($i)*sin($tetaTyp)]
	}
	# puts "Prc_CPB($i)=$Prc_CPB($i)"
	# puts "Prt_CPB($i)=$Prt_CPB($i)"
}

# Design of beams
# -----------------------------------------------------------------------
# Insert section properties
# -------------------------
set inBeamID [open "Section_Properties/Beams.txt"]
set BsecData [split [read $inBeamID] \n]
set nline [llength $BsecData]
set j 1
for {set i $NStory} {$i>=1} {incr i -1} {
	# if {$i==10} {
		# break
	# }
	while {1} {
		set BeamData [lindex $BsecData [expr $j-1]]
		set Ag_b [lindex $BeamData 1]
		set D_b [lindex $BeamData 2]
		set tw_b [lindex $BeamData 3]
		set bftf_b [lindex $BeamData 4]
		set htw_b [lindex $BeamData 5]
		set z_b [lindex $BeamData 6]
		set r_b [lindex $BeamData 7]
		set Aw_b [lindex $BeamData 8]
		set I_b [lindex $BeamData 9]
		# Computing Beta1 (second order effects)
		# --------------------------------------
		Max Pr $PrbPB($i) $PrbES($i)
		set Py [expr $Ag_b*50]
		if {$Pr/$Py<=0.5} {
			set Tawb 1.0
		} else {
			set Tawb [expr 4.*($Pr/$Py)*(1-($Pr/$Py))]
		}
		if {$i%2==0} {
			set KL_b 240.
		} else {
			set KL_b 120.
		}
		set Pe1 [expr ($PI**2*0.8*$Tawb*$E*$I_b)/($KL_b**2)]
		set Beta [expr 1/(1-$Pr/$Pe1)]
		Max Beta1 $Beta 1
		# Computing required axial, shear and moment strength
		# ---------------------------------------------------
		if {$i==$NStory} {
			set VD_g [expr 0.5*$DLroof*20*0.001]
			set VL_g [expr 1.*0]
			set MD_g [expr ($DLroof*20**2/8)*0.001]
			set ML_g [expr 1.*0]
		} else {
			set VD_g [expr 0.5*$DLtyp*20*0.001]
			set VL_g [expr 0.5*$LLtyp*20*0.001]
			set MD_g [expr ($DLtyp*20**2/8)*0.001]
			set ML_g [expr ($LLtyp*20**2/8)*0.001]
		}
		Max V_S $VrbES($i) $VrbPB($i)
		Max M_S $MrbES($i) $MrbPB($i)
		Max P_S $PrbES($i) $PrbPB($i)
		set Vr_b [expr 1.4*$VD_g+0.5*$VL_g+$V_S]
		set Mr_b [expr $Beta1*(1.4*$MD_g+0.5*$ML_g)+1.0*$M_S]
		set Pr_b [expr 1.0*$P_S]
		set MrES_b [expr $Beta1*(1.4*$MD_g+0.5*$ML_g)+1.0*$MrbES($i)]
		set PrES_b [expr 1.0*$PrbES($i)]
		set MrPB_b [expr $Beta1*(1.4*$MD_g+0.5*$ML_g)+1.0*$MrbPB($i)]
		set PrPB_b [expr 1.0*$PrbPB($i)]
		
		# Check beam for highly ductile
		set Ca [expr $Pr_b/(0.9*1.4*$Fy*$Ag_b)]
		if {$Ca<=0.114} {
			set Landaw [expr 2.57*sqrt($E/(1.4*$Fy))*(1-1.04*$Ca)]
		} else {
			Max Landaw [expr 0.88*sqrt($E/(1.4*$Fy))*(2.68-$Ca)] [expr 1.57*sqrt($E/(1.4*$Fy))]
		}
		if {($bftf_b<=(0.32*sqrt($E/(1.4*$Fy))))&&($htw_b<=$Landaw)} {
			set Landa_mod_B "OK"
		} else {
			set Landa_mod_B "Not OK"
		}

		# Check compression strength of the beam
		# Local buckling:
		if {($bftf_b<=(0.56*sqrt($E/$Fy)))&&($htw_b<=(1.49*sqrt($E/$Fy)))} {
			set Landa_c_B "OK"
		} else {
			set Landa_c_B "Not OK"
		}
		
		# Flexural buckling:
		set Fe_b [expr ($PI**2*$E)/(($KL_b/$r_b)**2)]
		if {($KL_b/$r_b)<=(4.71*sqrt($E/$Fy))} {
			set Pnc_b [expr 0.9*(0.658**($Fy/$Fe_b))*$Fy*$Ag_b]
		} else {
			set Pnc_b [expr 0.9*0.877*$Fe_b*$Ag_b]
		}
		if {$Pnc_b>=$Pr_b} {
			set FB_B "OK"
		} else {
			set FB_B "Not OK"
		}
		
		# Check flexural strength of the beam
		set Mn_b [expr 0.9*$z_b*$Fy/12]
		if {$Mn_b>=$Mr_b} {
			set MRatio_B "OK"
		} else {
			set MRatio_B "Not OK"
		}
		
		# Check shear strength of the beam
		# Computing phiv & Cv1:
		if {$htw_b<=2.24*sqrt($E/$Fy)} {
			set Phiv 1.
			set Cv1 1.
		} elseif {($htw_b>2.24*sqrt($E/$Fy))&&($htw_b<=1.1*sqrt(5.34*$E/$Fy))} {
			set Phiv 0.9
			set Cv1 1.
		} else {
			set Phiv 0.9
			set Cv1 [expr 1.1*sqrt(5.34*$E/$Fy)/$htw_b]			
		}
		set Vn_b [expr $Phiv*0.6*$Fy*$Aw_b*$Cv1]
		if {$Vn_b>=$Vr_b} {
			set VRatio_B "OK"
		} else {
			set VRatio_B "Not OK"			
		}
		
		# Check P_M ratio of beam for combined flexure and axial compression (expected strength analysis)
		if {($PrES_b/$Pnc_b)>=0.2} {
			set RatioES_b [expr ($PrES_b/$Pnc_b)+(8/9)*($MrES_b/$Mn_b)]
		} else {
			set RatioES_b [expr 0.5*($PrES_b/$Pnc_b)+($MrES_b/$Mn_b)]			
		}
		if {$RatioES_b<=1.0} {
			set PMRatioES_B "OK"
		} else {
			set PMRatioES_B "Not OK"
		}
		
		# Check P_M ratio of beam for combined flexure and axial compression (post buckling analysis)
		if {($PrPB_b/$Pnc_b)>=0.2} {
			set RatioPB_b [expr ($PrPB_b/$Pnc_b)+(8/9)*($MrPB_b/$Mn_b)]
		} else {
			set RatioPB_b [expr 0.5*($PrPB_b/$Pnc_b)+($MrPB_b/$Mn_b)]			
		}
		if {$RatioPB_b<=1.0} {
			set PMRatioPB_B "OK"
		} else {
			set PMRatioPB_B "Not OK"
		}
		
		if {($Landa_mod_B=="OK")&&($Landa_c_B=="OK")&&($FB_B=="OK")&&($MRatio_B=="OK")&&($VRatio_B=="OK")&&($PMRatioES_B=="OK")&&($PMRatioPB_B=="OK")} {
			set j 1
			set Sec($i) [lindex $BeamData 0]
			puts $SecOut "Story($i) $Sec($i) $RatioES_b $RatioPB_b [expr $Vr_b/$Vn_b] [expr $Mr_b/$Mn_b] [expr $Pr_b/$Pnc_b]"
			break
		} else {
			incr j 1
		}
		if {$j>$nline} {
			set Sec($i) 0
			puts $SecOut "Story($i) $Sec($i)"
			break
		}
		# puts "j=$j"
	}
}

# Control of columns for amplified seismic load combination
# -----------------------------------------------------------------------
# Computing required compressive and tensile strength of columns
for {set i 1} {$i<=$NStory} {incr i 1} {
	set Prc1($i) [expr 1.4*$PD_C($i)+0.5*$PL_C($i)+1.0*$Prc_CES($i)]
	set Prc2($i) [expr 1.4*$PD_C($i)+0.5*$PL_C($i)+1.0*$Prc_CPB($i)]
	set Prc3($i) [expr 0.7*$PD_C($i)+1.0*$Prc_CES($i)]
	set Prc4($i) [expr 0.7*$PD_C($i)+1.0*$Prc_CPB($i)]
	Max4 Prc_C($i) $Prc1($i) $Prc2($i) $Prc3($i) $Prc4($i)
	
	set Prt1($i) [expr 1.4*$PD_C($i)+0.5*$PL_C($i)+1.0*$Prt_CES($i)]
	set Prt2($i) [expr 1.4*$PD_C($i)+0.5*$PL_C($i)+1.0*$Prt_CPB($i)]
	set Prt3($i) [expr 0.7*$PD_C($i)+1.0*$Prt_CES($i)]
	set Prt4($i) [expr 0.7*$PD_C($i)+1.0*$Prt_CPB($i)]
	Min4 Prt_C($i) $Prt1($i) $Prt2($i) $Prt3($i) $Prt4($i)
	# puts "Prc_C($i)=$Prc_C($i)"
	# puts "Prt_C($i)=$Prt_C($i)"
	}

# Control compressive strength
for {set i 1} {$i<=$NStory} {incr i 1} {
	set Rc_C($i) [expr $Prc_C($i)/$Pc_C($i)]
	if {$Prt_C($i)>=0} {
		set Rt_C($i) 0
	} else {
		set Rt_C($i) [expr abs($Prt_C($i))/$Pt_C($i)]
	}
	if {$Rc_C($i)<=1.0} {
		set RatioC_C($i) "OK"
	} else {
		set RatioC_C($i) "NotOK"
	}
	if {$Rt_C($i)<=1.0} {
		set RatioT_C($i) "OK"
	} else {
		set RatioT_C($i) "NotOK"
	}
	puts $CCID "ColumnStory($i) $Rc_C($i) $RatioC_C($i) $Rt_C($i) $RatioT_C($i)"
}
