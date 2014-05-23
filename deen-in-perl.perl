#!/usr/bin/perl -w

=for comment
#Copyright 2014@Santosh Dwivedi(santosh@sanscreative.org), All Rights Reserved.
#The code contained herein is licensed under the GNU General Public
#License. You may obtain a copy of the GNU General Public License
#Version 2 or later at the following locations:
# http://www.opensource.org/licenses/gpl-license.html
# http://www.gnu.org/copyleft/gpl.html
# This script is to define and decode cpu register bits.
Purpose:
To encode and decode cpu register fields. useful when working with large number of registers.
Requirement:
Wx 
Wx Installation:Read More on http://www.cpan.org/modules/INSTALL.html
On Windows:
http://strawberryperl.com/ download installer and install 
Install Wx on command line using cpan (comprehensive perl archive network)
cpan -i Wx

Alien::wxWidgets  is installed automatically. This module provides your build of wxWidgets

To install a module type command line 
cpan -i wxPerl::Constructors


Development IDE:
Use ecliopse EPIC perl perspective 
For the impatient: Select Help > Install New software
in Eclipse, add the update site http://e-p-i-c.sf.net/updates/testing and follow the on-screen instructions.

General information about perl
http://www.perl.org/get.html
=cut

use warnings;
use strict;

package DecodeCpuReg;

use Cwd;
use Getopt::Std;
use vars qw( $opt_p $opt_l $opt_c $opt_d $opt_e $opt_v $opt_g);
our $workingdir;
our $regname;
sub set_workingdir;
sub list_registers();
sub config_register;
sub eval_register;
sub decode_register_byname;
sub decode_bits_from_val;
sub config_reg_cmdline;
sub show_help();

if ( !getopts('p:lc:d:e:v:g') ) {
	show_help();
}
if ( !$opt_p && !$opt_l && !$opt_e && !$opt_c && !$opt_d ) {
	show_help();
}
set_workingdir();
if ($opt_p) {
	set_workingdir($opt_p);
}
if ($opt_l) {
	list_registers();
}

if ($opt_c) {

	#clear old entries.
	open( CPUREG, ">$workingdir/$opt_c" );
	close(CPUREG);
	if ($opt_g) {
		config_register($opt_c);
	}
	else {
		config_reg_cmdline($opt_c);
	}
}

if ($opt_d) {
	if ($opt_g) {
		DecodeCpuReg->new->MainLoop;
	}
	elsif ($opt_v) {
		eval_register( $opt_d, $opt_v );
	}
	else {
		eval_register( $opt_d, 0 );
	}

}
if ($opt_e) {
	if ($opt_g) {
        DecodeCpuReg->new->MainLoop;
    }else {
       encode_register_cmdline( $opt_e );	
    }
     
}

sub set_workingdir {
	my $workdirconfig = 'workingdir.tmp';
	unless ( -e $workdirconfig ) {
		$workingdir = getcwd;
		open( MYFILE, ">$workdirconfig" );
		print MYFILE "$workingdir/cpureg";
		close(MYFILE);
		unless ( mkdir "$workingdir/cpureg" ) {
			die "Unable to create $workingdir/cpureg";
		}
	}
	if ( 1 == scalar(@_) ) {
		my $workdirroot = $_[0];
		print "\n setting working dir $workdirroot";
		open( MYFILE, ">$workdirconfig" );
		print MYFILE "$workdirroot";
		close(MYFILE);
		unless ( mkdir $workdirroot ) {
			die "Unable to create $workdirroot";
		}
	}
	open( MYFILE, "$workdirconfig" );
	$workingdir = <MYFILE>;
	close(MYFILE);

}

sub list_registers() {
	print "\n listing cpu registers ";
	opendir( WORKDIR, $workingdir ) or die $!;
	while ( my $registers = readdir(WORKDIR) ) {
		print "$registers\n";
	}
	closedir(WORKDIR);
}

sub config_register {
	$regname = $_[0];
	print "\n configuring register gui $regname with GUI\n";
	DecodeCpuReg->new->MainLoop;

}

sub eval_register {
	my $reg_name = $_[0];
	my $reg_val  = $_[1];
	print "\nDecoding register $reg_name with value $reg_val\n";
	my @bitfield_values =
	  decode_register_byname( "$workingdir/$reg_name", $reg_val );
	my $row;
	my $column;
	foreach $row ( 0 .. @bitfield_values - 1 ) {
		print "\n$bitfield_values[$row][0] = $bitfield_values[$row][3]";
	}
	return @bitfield_values;
}

sub decode_register_byname {
	my $working_reg = $_[0];
	my $working_val = $_[1];
	my $name;
	my $msb;
	my $lsb;
	my @regvalues;

	# print "$working_reg\n";
	open( FILE, $working_reg );
	while (<FILE>) {
		chomp;
		( $name, $lsb, $msb ) = split(",");
		my $decoded = decode_bits_from_val( $lsb, $msb, $working_val );
		#print "\nworking value $working_val\n";
		push @regvalues, [ $name, $lsb, $msb, $decoded ];
	}
	close(FILE);
	return @regvalues;
}

sub encode_bits_to_val {
	my $lsb          = $_[0];
	my $msb          = $_[1];
	my $value        = $_[2];
	my $length = $msb-$lsb+1; 
    my $bit_mask = ((1<< $length) -1) << $lsb;
    my $encoded_bits = ($value<<$lsb) & $bit_mask;
    my $hexval = sprintf("0x%x",$encoded_bits );
	#print "\n$value\[$lsb- $msb\] : $hexval input $value\n";
	return $encoded_bits;
}
sub encode_register_bitfields { #assembles bit fields and returns total value
    my @reg_value = @_; # takes input array content of register
    my $total_val =0;
    my $row;
   foreach $row ( 0 .. @reg_value  - 1 ) {
      my $lsb = $reg_value[$row][1];
      my $msb = $reg_value[$row][2];
      my $val = $reg_value[$row][3];
      $total_val|= encode_bits_to_val($lsb,$msb,$val);
      #print "encoding result = $total_val";
    }    
    print "encoded value $total_val";
    return $total_val;
}
sub decode_bits_from_val {
	my $lsb      = $_[0];
	my $msb      = $_[1];
	my $value    = $_[2];
	my $length   = $msb - $lsb+1;
	my $bit_mask = ( 1 << $length ) - 1;
	$bit_mask = $bit_mask << $lsb;
	my $extracted_bits =  eval($value) & $bit_mask;
	my $bitfieldval    = $extracted_bits >> $lsb;
	return $bitfieldval;
}

sub prompt_for_input {
	my ($text) = @_;
	print $text;
	my $inputval = <STDIN>;
	chomp $inputval;
	return $inputval;
}

sub write_reg_field {
	my $name = $_[0];
	my $lsb  = $_[1];
	my $msb  = $_[2];
	open( CPUREG, ">>$workingdir/$regname" );
	print CPUREG "$name,$lsb,$msb\n";
	close(CPUREG);
}

sub config_reg_cmdline {
	$regname = $_[0];
	my $name;
	my $lsb;
	my $msb;
	do {
		$name = "";
		$lsb  = "";
		$msb  = "";
		$name = prompt_for_input("bit field name : ");
		if ( $name ne "" ) {
			$lsb = prompt_for_input("LSB : ");
		}
		if ( "$lsb" ne "" ) {
			$msb = prompt_for_input("MSB : ");
		}
		if ( $name ne "" || "$lsb" ne "" || "$msb" ne "" ) {
			write_reg_field( $name, $lsb, $msb );
		}
	} while ( $name ne "" || "$lsb" ne "" || "$msb" ne "" );

}


sub encode_register_cmdline
{
	my $regname = $_[0];
    my @reg_content = eval_register($regname,0);
    my $row;
    print "\nEnter register values of  $regname\n";
    foreach $row ( 0 .. @reg_content  - 1 ) {
         my $value = prompt_for_input("\n$reg_content[$row][0]\[$reg_content[$row][1]-$reg_content[$row][2] \] : ");
        $reg_content[$row][3]= $value;
       
    }
    my $encoded_val = encode_register_bitfields(@reg_content);
    my $hexval = sprintf("0x%x",$encoded_val );
	print "\nencoded value :  $hexval\n";
}

sub show_config_menu {
	use Wx;
	use wxPerl::Constructors;
	use base 'Wx::App';

	my $frame = wxPerl::Frame->new( undef, $regname );
	$frame->SetMinSize( [ 220, 280 ] );
	my $sizer          = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $registerfields = Wx::StaticBox->new(
		$frame, 1,
		"define register bit fields[name,lsb,msb]",
		Wx::Point->new( -1, -1 ),
		Wx::Size->new( 150, 150 ),
		0, 'register_bits'
	);
	my $x_pos  = 20;
	my $y_pos  = 40;
	my $x_size = 80;
	my $y_size = 30;
	my $id     = 3;

	my $bit_filed_label = Wx::StaticText->new(
		$registerfields, $id, "field name ",
		Wx::Point->new( $x_pos, $y_pos ),
		Wx::Size->new( $x_size, $y_size ),
		&Wx::wxEXPAND
	);
	my $bit_fieled_value = Wx::TextCtrl->new(
		$registerfields, 2, " ",
		[ $x_pos + $x_size, $y_pos ],
		[ 2 * $x_size,      $y_size ]
	);
	$y_pos += 40;
	$id    += 1;
	my $bit_lsb_label = Wx::StaticText->new(
		$registerfields, $id, "LSB",
		Wx::Point->new( $x_pos, $y_pos ),
		Wx::Size->new( $x_size, $y_size ),
		&Wx::wxEXPAND
	);
	my $bit_lsb_value = Wx::TextCtrl->new(
		$registerfields, 2, "0",
		[ $x_pos + $x_size, $y_pos ],
		[ 2 * $x_size,      $y_size ]
	);

	$y_pos += 40;
	$id    += 1;
	my $bit_msb_label = Wx::StaticText->new(
		$registerfields, $id, "MSB",
		Wx::Point->new( $x_pos, $y_pos ),
		Wx::Size->new( $x_size, $y_size ),
		&Wx::wxEXPAND
	);
	my $bit_msb_value = Wx::TextCtrl->new(
		$registerfields, 2, "0",
		[ $x_pos + $x_size, $y_pos ],
		[ 2 * $x_size,      $y_size ]
	);
	$bit_fieled_value->Clear();

	$id += 1;
	$sizer->Add( $registerfields, $id, &Wx::wxEXPAND );
	my $button = wxPerl::Button->new( $frame, 'Add register bit field' );
	$id += 1;
	$sizer->Add( $button, $id, &Wx::wxEXPAND );

	my $button2 = wxPerl::Button->new( $frame, 'Done !' );
	$id += 1;
	$sizer->Add( $button2, $id, &Wx::wxEXPAND );
	Wx::Event::EVT_BUTTON(
		$button2, -1,
		sub {
			&Wx::wxTheApp->ExitMainLoop;
		}
	);

	Wx::Event::EVT_BUTTON(
		$button, -1,
		sub {
			my ( $b, $evt ) = @_;
			$b->SetLabel('Add more');
			my $name_value = $bit_fieled_value->GetValue();
			my $msb_value  = $bit_msb_value->GetValue();
			my $lsb_value  = $bit_lsb_value->GetValue();
			if ( $name_value ne '' && $msb_value <= 64 && $lsb_value < 64 ) {
				print "$name_value , $msb_value , $lsb_value\n";
				write_reg_field( $name_value, $lsb_value, $msb_value );
				$bit_fieled_value->Clear();
				$bit_msb_value->Clear();
				$bit_lsb_value->Clear();
			}

		}
	);
	$frame->SetSize( 600, 400 );
	$frame->SetSizer($sizer);
	$frame->Show;
	return 0;
}

sub show_bitfield_menu {
	use Wx;
	use wxPerl::Constructors;
	use base 'Wx::App';
	my $regname;
	my $regval =0;
    if($opt_e)
    {
        $regname = $opt_e;
    }elsif($opt_d)
    {
        $regname = $opt_d;
    }
	if($opt_v)
	{
		$regval  = $opt_v;
	}
	
	my $frame   = wxPerl::Frame->new( undef, "Encode decode register $regname" );
	$frame->SetMinSize( [ 100, 280 ] );
	my $numgridcol = 16;
	my $numrow = 4;
	my $sizer  = Wx::FlexGridSizer->new($numrow,$numgridcol,0,0);
	my $x_pos  = 20;
	my $y_pos  = 40;
	my $x_size = 80;
	my $y_size = 120;
	my $id     = 3;
	my $row;
	my @bit_field_array_text;
	my @bitfield_values = eval_register( $regname, $regval );

	my $bit_field_label = Wx::StaticText->new(
		$frame, -1,
		"$regname value=",
		Wx::Point->new( 40, 40 ),
		Wx::Size->new( $x_size, $y_size ),
		&Wx::wxALIGN_CENTER_VERTICAL
	);
	
	my $reg_field_value = Wx::TextCtrl->new(
		$frame,-1, "$regval",
		Wx::Point->new( $x_pos, $y_pos ),
		Wx::Size->new( 60, 60 )

	);
	Wx::Event::EVT_TEXT(
		$reg_field_value,
		-1,
		sub {
			my ( $txt, $evt ) = @_;
			my $val = $txt->GetValue();

			print "\n$regname value is  $val  \n";

		}
	);
	$sizer->Add( $bit_field_label, 0,&Wx::wxGROW|&Wx::wxTOP|&Wx::wxBOTTOM, 10 );
	$sizer->Add( $reg_field_value,0, &Wx::wxGROW | &Wx::wxTOP | &Wx::wxBOTTOM, 10);
	
	$id += 3;

	foreach $row ( 0 .. @bitfield_values - 1 ) {
		print "\n$bitfield_values[$row][0] = $bitfield_values[$row][3]";
		my $fl_name         = $bitfield_values[$row][0];
		my $lsbval          = $bitfield_values[$row][1];
		my $msbval          = $bitfield_values[$row][2];
		my $fieldname       = "bit field: $fl_name\[$lsbval - $msbval\]";
		my $fieldval        = $bitfield_values[$row][3];
		my $bit_field_label = Wx::StaticText->new(
			$frame, -1, "$fieldname",
			Wx::Point->new( $x_pos, $y_pos ),
			Wx::Size->new( $x_size, $y_size ),
			&Wx::wxALIGN_CENTER_VERTICAL,
		);
		my $bit_field_value = Wx::TextCtrl->new(
			$frame, -1, "$fieldval",
			Wx::Point->new( $x_pos, $y_pos ),
			Wx::Size->new( 40, 40 )
		);
		push @bit_field_array_text, $bit_field_value;
		$id += 2;
		Wx::Event::EVT_TEXT(
			$bit_field_value,
			-1,
			sub {
				my $val = eval($bit_field_value->GetValue());
				if ( $val < 0 ) {
					print "not valid number bits\n";
					$bit_field_value->Clear();
				}
			}
		);
		
		$sizer->Add( $bit_field_label, 0,&Wx::wxGROW|&Wx::wxTOP|&Wx::wxBOTTOM, 10);
		$sizer->Add( $bit_field_value, 0,&Wx::wxGROW | &Wx::wxTOP | &Wx::wxBOTTOM, 10);
	}
   my $registerlength =  (@bitfield_values+1) *2; 	
   my $coltopad = $numgridcol -($registerlength%$numgridcol); 
  foreach my $i (0..$coltopad-1)
  {
   my $pad_label = Wx::StaticText->new(
        $frame, -1,
        "-",
        Wx::Point->new( 40, 40 ),
        Wx::Size->new( 0, 0 ),
        &Wx::wxALIGN_CENTER_VERTICAL
    );
    $sizer->Add($pad_label, 0,&Wx::wxGROW|&Wx::wxTOP|&Wx::wxBOTTOM, 10 );
   
  }
  my $buttonEncode = wxPerl::Button->new( $frame, 'Encode' ,);
	$sizer->Add( $buttonEncode, 0,  &Wx::wxBOTTOM | &Wx::wxEXPAND );
	Wx::Event::EVT_BUTTON(
		$buttonEncode,
		-1,
		sub {

			my $tmp_reg_val = 0;
			foreach $row ( 0 .. @bitfield_values - 1 ) {
				my $bit_val = eval($bit_field_array_text[$row]->GetValue());
				$bitfield_values[$row][3]= $bit_val ;
				
			}
			$tmp_reg_val = encode_register_bitfields(@bitfield_values);
			my $hexval = sprintf("0x%x",$tmp_reg_val );
            $reg_field_value->SetValue($hexval);
		}
	);
	my $buttonDecode = wxPerl::Button->new( $frame, 'Decode' );
	$sizer->Add( $buttonDecode, 0,  &Wx::wxBOTTOM | &Wx::wxEXPAND );
	Wx::Event::EVT_BUTTON(
		$buttonDecode,
		-1,
		sub {
			$regval = $reg_field_value->GetValue();
			if ( hex($regval) le 64 ) {
				@bitfield_values = eval_register( $regname, $regval );
				foreach $row ( 0 .. @bitfield_values - 1 ) {
					my $bitsval = $bitfield_values[$row][3];
					$bit_field_array_text[$row]->SetValue($bitsval);

				}
			}
			else {
				print "Invalid Value.";
			}

		}
	);
	my $buttonDone = wxPerl::Button->new( $frame, 'Close' );
	$sizer->Add( $buttonDone,0,  &Wx::wxBOTTOM | &Wx::wxEXPAND );
	Wx::Event::EVT_BUTTON(
		$buttonDone,
		-1,
		sub {
			&Wx::wxTheApp->ExitMainLoop;
		}
	);

	$frame->SetSize( 1600, 600 );
	$frame->SetSizer($sizer);
	$frame->Show;
	return 0;
}

sub OnInit {
	my $ret;
	if ($opt_c) {
		$ret = show_config_menu;
	}
	elsif ($opt_d || $opt_e) {
		$ret = show_bitfield_menu;

	}
	if ($ret) {
		print "\nprobably wx widgest not installeded on system,please install or use command line \n";
		print "\ncpan -i Wx  \n";
		print "\ncpan -i wxPerl::Constructors \n";
		print "on windows install strawberryperl from strawberryperl.com\n";
	}
	return 1;
}

sub show_help() {
	print "\n Valid options are:\n";
	print "\n        -c  regname.cpureg   to configure new cpu register \n";
	print "\n        -p dir               to set dir as working directory path";
	print "\n        -l                   to list configured registers";
	print "\n        -g                   use graphical interface";
	print "\n        -d regname.cpureg -v value to decode register bit fields";
	print "\n        -e regname.cpureg    to encode register bit fields only valid as command line";

}
