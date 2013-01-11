#!/usr/bin/perl
#
#  Korg X Series Editor version 0.1
#
#  Copyright (C) 2012-2013 LinuxTECH.NET
#
#  Korg is a registered trademark of Korg Inc.
#
#  This program is free software: you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  version 2 as published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program. If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

my $version="0.1";

use Tk;
use Tk::Pane;
use Tk::NoteBook;
use Tk::BrowseEntry;
use Tk::Optionmenu;
use Tk::JPEG;
use List::Util qw[min max];

# LCD style background color
my $LCDbg='#ECFFAF';
# title strips background and font color
my $Titlebg='#487890';
my $Titlefg='#F3F3F3';

my %Scale_defaults=(
    -width        => 10,
    -length       => 200,
    -sliderlength => 16,
    -borderwidth  => 1,
    -showvalue    => 0,
    -resolution   => 1,
    -font         => "Sans 6",
    -cursor       => 'hand2',
    -orient       => 'horizontal'
);
my %Scale_label_defaults=(
    -width        => 3,
    -height       => 1,
    -borderwidth  => 1,
    -font         => 'Sans 10',
    -foreground   => 'black',
    -background   => $LCDbg,
    -relief       => 'sunken'
);
my %Frame_defaults=(
    -borderwidth  => 2,
    -relief       => 'groove'
);
my %BEntry_defaults=(
    -state        => 'readonly',
    -font         => 'Sans 8',
    -style        => 'MSWin32',
);
my %choices_defaults=(
    -borderwidth  => 1,
    -relief       => 'raised',
    -padx         => 1,
    -pady         => 1
);
my %arrow_defaults=(
    -width        => 13,
    -height       => 12,
    -bitmap       => 'darrow'
);
my %Entry_defaults=(
    -borderwidth        => 1,
    -foreground         => 'black',
    -background         => $LCDbg,
    -highlightthickness => 0,
    -insertofftime      => 0,
    -insertwidth        => 1,
    -selectborderwidth  => 0
);
my %TitleLbl_defaults=(
        -font         => 'title',
        -foreground   => $Titlefg,
        -background   => $Titlebg
);

# down arrow bitmap for pulldown menu
my $darrow_bits=pack("b11"x10,
    "...........",
    ".111111111.",
    "...........",
    "...........",
    ".111111111.",
    "..1111111..",
    "...11111...",
    "....111....",
    ".....1.....",
    "...........");

# array mapping MIDI note numbers 0-127 to note names C-1 to G9
my @notes;
my @keys=('C ', 'C#', 'D ', 'D#', 'E ', 'F ', 'F#', 'G ', 'G#', 'A ', 'A#', 'B ');
for (my $nnr=0; $nnr<128; $nnr++) {
    my $key=($nnr%12);
    my $oct=int($nnr/12)-1;
    $notes[$nnr]=$keys[$key].$oct;
}
# hash mapping note names C-1 to G9 to MIDI note numbers 0-127
my %noteshash; @noteshash{@notes}=0..$#notes;


# program paramters
my $modified=0;
my $prgfilename='';
my $program_name;    my $osc_mode;
my $assign;          my $hold;
my $interval;        my $detune;
my $delay;
my $PEG_SL;          my $PEG_AT;
my $PEG_AL;          my $PEG_DT;
my $PEG_RT;          my $PEG_RL;
my $PEG_level;       my $PEG_time;
my $AT_PBrange;      my $AT_VDFcoff;
my $AT_VDFmgint;     my $AT_VDAamp;
my $JS_PBrange;      my $JS_VDFswint;
my $JS_VDFmgint;
my $VDFmod_wav;      my $VDFmgfreq;
my $VDFmgint;        my $VDFmgdly;
my $VDF_OSC1;        my $VDF_OSC2;
my $VDFkeysync;
my @VDF_AT;          my @VDF_AL;
my @VDF_DT;          my @VDF_BP;
my @VDF_ST;          my @VDF_SL;
my @VDF_RT;          my @VDF_RL;
my @VDFcoffvl;       my @VDFcoffkt;
my @VDF_EGint;       my @VDF_EGtkt;
my @VDF_EGtvs;       my @VDF_EGivs;
my @VDF_kbdtk;
my @VDA_AT;          my @VDA_AL;
my @VDA_DT;          my @VDA_BP;
my @VDA_ST;          my @VDA_SL;
my @VDA_RT;
my @VDAosclv;        my @VDAakti;
my @VDAavs;          my @VDAegtkt;
my @VDAegtvs;        my @VDA_kbdtk;
my @PMG_freq;        my @PMG_dly;
my @PMG_Fin;         my @PMG_Int;
my @PMG_FMKT;        my @PMG_IMA;
my @PMG_IMJ;         my @PMG_FMAJ;

# selected and available midi in/out devices
my $midi_outdev="";
my $midi_outdev_prev="";
my $midi_indev="";
my $midi_indev_prev="";
my @midi_indevs=MidiPortList('in');
my @midi_outdevs=MidiPortList('out');

# these widgets need to be global
my $midiin;
my $midiout;
my $f01;
my $f02;
my $f03;
my $f04;
my $f05;
my @f06;
my @f07;
my @f08;
my @f09;
my @f10;
my $combwin;
my $midiupload;

# default Korg device number (1-16)
my $dev_nr=1;

# set up main program window
my $mw=MainWindow->new();
$mw->title("X Series Editor - Program Editor");
$mw->resizable(0,0);

$mw->fontCreate('title', -family=>'Sans', -weight=>'bold', -size=>9);

$mw->DefineBitmap('darrow'=>11,10,$darrow_bits);

# default font
$mw->optionAdd('*font', 'Sans 10');

# for better looking menus
$mw->optionAdd('*Menu.activeBorderWidth', 1, 99);
$mw->optionAdd('*Menu.borderWidth', 1, 99);
$mw->optionAdd('*Menubutton.borderWidth', 1, 99);
$mw->optionAdd('*Optionmenu.borderWidth', 1, 99);
# set default listbox properties
$mw->optionAdd('*Listbox.borderWidth', 3, 99);
$mw->optionAdd('*Listbox.selectBorderWidth', 0, 99);
$mw->optionAdd('*Listbox.highlightThickness', 0, 99);
$mw->optionAdd('*Listbox.Relief', 'flat', 99);
$mw->optionAdd('*Listbox.Width', 0, 99);
$mw->optionAdd('*Listbox.Height', 10, 99);
# set default entry properties
$mw->optionAdd('*Entry.borderWidth', 1, 99);
$mw->optionAdd('*Entry.highlightThickness', 0, 99);
$mw->optionAdd('*Entry.disabledForeground','black',99);
$mw->optionAdd('*Entry.disabledBackground', $LCDbg,99);
# set default scrollbar properties
$mw->optionAdd('*Scrollbar.borderWidth', 1, 99);
$mw->optionAdd('*Scrollbar.highlightThickness', 0, 99);
$mw->optionAdd('*Scrollbar.Width', 10, 99);
# set default button properties
$mw->optionAdd('*Button.borderWidth', 1, 99);
$mw->optionAdd('*Checkbutton.borderWidth', 1, 99);
# set default canvas properties
$mw->optionAdd('*Canvas.highlightThickness', 0, 99);

# set up main frame with top menu bar, three tabs and a status bar
my $mf1;
topMenubar();
my $book = $mw->NoteBook(
    -borderwidth =>1,
    -ipadx       =>0
) -> pack(
    -side   => 'top',  -expand => 1,
    -fill   => 'both', -anchor => 'nw'
);
StatusBar();

my @tab;
$tab[0] = $book->add('Tab0', -label=>'Main');
$tab[1] = $book->add('Tab1', -label=>'Oscillator 1');
$tab[2] = $book->add('Tab2', -label=>'Oscillator 2');
$tab[3] = $book->add('Tab3', -label=>'Effects');

# main tab
sub Main_Tab {
    my $col1 =$tab[0]->Frame()->pack(-side=>'left', -fill=>'both', -expand=>1);
    my $col23=$tab[0]->Frame()->pack(-side=>'top',  -fill=>'x');
    my $col2 =$tab[0]->Frame()->pack(-side=>'left', -fill=>'both', -expand=>1);
    my $col3 =$tab[0]->Frame()->pack(-side=>'left', -fill=>'both', -expand=>1);

    $f01=$col1->Frame(%Frame_defaults)->pack(-fill=>'x');
    $f03=$col1->Frame(%Frame_defaults)->pack(-fill=>'x');
    $f05=$col2->Frame(%Frame_defaults)->pack(-fill=>'x');
    $f04=$col2->Frame(%Frame_defaults)->pack(-fill=>'x');
    $f02=$col3->Frame(%Frame_defaults)->pack(-fill=>'x');

    # photo of X5DR front panel (purely for decorative purposes)
    my $jpg1=$col23->Photo( '-format'=>'jpeg', -file=>'x5dr.jpg');
    $col23->Label(-image=>$jpg1, -borderwidth=>0, -relief=>'flat', -anchor=>'n',-height=>92
    )->pack(-anchor=>'n', -fill=>'x', -ipadx=>2);

    Main_Prg_Frame();
    Aftertouch_Frame();
    Joystick_Frame();
    Pitch_EG_Frame();
    VDF_Cutoff_Frame();
}

# osc tabs
sub Osc_Tabs {
    for (my $n=1; $n<=2; $n++) {
        my $col1=$tab[$n]->Frame()->pack(-side=>'left', -fill=>'both', -expand=>1);
        my $col2=$tab[$n]->Frame()->pack(-side=>'left', -fill=>'both', -expand=>1);
        my $col3=$tab[$n]->Frame()->pack(-side=>'left', -fill=>'both', -expand=>1);

        $f10[$n]=$col1->Frame(%Frame_defaults)->pack(-fill=>'x');
        $f09[$n]=$col2->Frame(%Frame_defaults)->pack(-fill=>'x');
        $f08[$n]=$col2->Frame(%Frame_defaults)->pack(-fill=>'x');
        $f07[$n]=$col3->Frame(%Frame_defaults)->pack(-fill=>'x');
        $f06[$n]=$col3->Frame(%Frame_defaults)->pack(-fill=>'x');

        VDF_EG_Frame($n);
        VDF_Frame($n);
        VDA_EG_Frame($n);
        VDA_Frame($n);
        Pitch_Mod($n);
    }
}


Main_Tab();
Osc_Tabs();


MainLoop;


# -----------
# Subroutines
# -----------

sub topMenubar {
    $mf1=$mw->Frame(-borderwidth=>1, -relief=>'raised')->pack(-side=>'top', -expand=>1, -fill=>'x', -anchor=>'n');

    my $btn0=$mf1->Menubutton(-text=>'File', -underline=>0, -tearoff=>0, -anchor=>'w',
       -menuitems => [['command'=>'New',        -accelerator=>'Ctrl+N',  -command=>sub{ newVoice();
                                                                                        UpdateWSel(1, 0);
                                                                                        UpdateWSel(2, 0);
                                                                                      }            ],
                      ['command'=>'Open...',    -accelerator=>'Ctrl+O',  -command=>\&loadPrgFile   ],
                      "-",
                      ['command'=>'Save',       -accelerator=>'Ctrl+S',  -command=>\&savePrgFile   ],
                      ['command'=>'Save As...', -accelerator=>'Ctrl+A',  -command=>\&saveasPrgFile ],
                      "-",
                      ['command'=>'Quit',       -accelerator=>'Ctrl+Q',  -command=>\&exitProgam    ]]
    )->pack(-side=>"left");
    $mw->bind($mw, "<Control-q>"=>\&exitProgam);
    $mw->bind($mw, "<Control-a>"=>\&saveasPrgFile);
    $mw->bind($mw, "<Control-s>"=>\&savePrgFile);
    $mw->bind($mw, "<Control-o>"=>\&loadPrgFile);
    $mw->bind($mw, "<Control-n>"=>sub{ newVoice(); UpdateWSel(1, 0); UpdateWSel(2, 0); });

    my $btn1=$mf1->Menubutton(-text=>'Edit', -underline=>0, -tearoff=>0, -anchor=>'w',
       -menuitems => [['command'=>'Combination Editor...', -command=>sub{ if (! Exists($combwin)) { CombEditWin(); }
                                                                         else { $combwin->deiconify(); $combwin->raise(); }
                                                                       }            ],
                      "-",
                      ['command'=>'Settings...',        -command=>\&Settings ]]
    )->pack(-side=>"left");

    my $btn2=$mf1->Menubutton(-text=>'Help', -underline=>0, -tearoff=>0, -anchor=>'w',
       -menuitems => [['command'=>'About', -accelerator=>'Alt+A', -command=>\&About, -underline=>0]]
    )->pack(-side=>'left');
    $mw->bind($mw, "<Alt-a>"=>\&About);
}

sub StatusBar {

    my $stb=$mw->Frame(
        -borderwidth  => 1,
        -relief       => 'raised'
    ) -> pack(
        -side => 'bottom', -expand => 1,
        -fill => 'both',   -anchor => 'sw'
    );

    my $file_display=$stb->Label(
        -anchor       => 'w',
        -relief       => 'sunken',
        -borderwidth  => 1,
        -width        => 82,
        -font         => 'Sans 9',
        -textvariable => \$prgfilename
    )->pack(-side=>'left', -padx=>2, -pady=>2);

    $midiupload=$stb->Button(
        -text         => 'Upload via MIDI to Korg',
        -pady         => 2,
        -underline    => 0,
        -command      => \&SysexPrgUpload
    )->pack(-side=>'right');
    $mw->bind($mw, "<Control-u>"=>\&SysexPrgUpload);

    if ($midi_outdev ne '') {
        $midiupload->configure(-state=>'active');
    } else {
        $midiupload->configure(-state=>'disabled');
    }
}

# load a program sysex dump
sub loadPrgFile {
    my $rtn="";
    if ($modified == 1) {
        $rtn=UnsavedChanges(\$mw, 'Open new file anyway?');
    }
    if ($rtn eq "Yes" || $modified == 0) {
        my $types=[ ['Sysex Files', ['.syx', '.SYX']], ['All Files', '*'] ];
        my $syx_file=$mw->getOpenFile(
            -defaultextension => '.syx',
            -filetypes        => $types,
            -title            => 'Open a Korg Program Sysex Dump file'
        );
        if ($syx_file && -r $syx_file) {
            open my $fh, '<', $syx_file;
            my $tmp_dump = do { local $/; <$fh> };
            close $fh;
            my $check=PrgSysexValidate($tmp_dump);
            if ($check ne 'ok') {
                Error(\$mw,"Error while opening $syx_file\n\n$check");
            } else {
                PrgSysexRead(\$tmp_dump);
                $modified=0;
                $prgfilename=$syx_file;
            }
        } elsif ($syx_file) {
            Error(\$mw, "Error: could not open $syx_file");
        }
    }
}

# call as: UnsavedChanges(\$parentwin, $question), returns: Yes/No
sub UnsavedChanges {
    my $win=$_[0];
    my $msg=$_[1];
    my $rtn=${$win}->messageBox(
        -title   =>'Unsaved changes',
        -icon    => 'question',
        -message =>"There are unsaved changes that will be lost unless you save them first.\n\n$msg",
        -type    =>'YesNo',
        -default =>'No'
    );
    return $rtn;
}

# Error popup window
sub Error {
    my $win=$_[0];
    my $msg=$_[1];
    ${$win}->messageBox(
        -title   =>'Error',
        -icon    => 'warning',
        -message =>"$msg",
        -type    =>'Ok',
        -default =>'Ok'
    );
}

# 'About' information window
sub About {
    $mw->messageBox(
        -title   => 'About',
        -icon    => 'info',
        -message => "        X Series Editor version $version\n
for the Korg\x{2122} X5, 05R/W, X5D, X5DR\n
         \x{00A9} 2012 LinuxTECH.NET\n\nKorg is a registered trademark of Korg Inc.",
        -type    => 'Ok',
        -default => 'Ok'
    );
}

sub PrgSysexValidate {
}

sub PrgSysexRead {
}

sub MidiPortList {
}

sub SendPaChMsg {
}

# Decodes a block of up to 7+1 7bit bytes as used by Korg sysex dumps
sub SyxBlkDecode {
    my($blk)=@_; # string with block of up to 7+1 7bit bytes
    my $output;
    my @bits=split(//,unpack('b*',substr($blk,0,1)));
    for (my $n=1; $n<length $blk; $n++) {
        $output.=chr(($bits[$n-1]*128)+ord(substr($blk,$n,1)));
    }
    return $output; # string with block of up to 7 8bit bytes
}

# Encodes a block of up to 7 8bit bytes as used by Korg sysex dumps
sub SyxBlkEncode {
    my($blk)=@_; # string with block of up to 7 8bit bytes
    my $output;
    my @bits;
    for (my $n=0; $n<length $blk; $n++) {
        my $tmp=ord(substr($blk,$n,1));
        $output.=chr($tmp%128);
        $bits[$n]=int($tmp/128);
    }
    my $first=pack('b*',join('', @bits));
    return $first.$output; # string with block of up to 7+1 7bit bytes
}

# Decodes a whole sysex data block from Korg 7bit encoding to 8bit bytes
sub SysexDecode {
    my($refsyx)=@_; # pass reference to sysex dump string without headers
    my $dlen=(length $$refsyx);
    my $decoded_dump;
    for (my $n=0; $n<=($dlen-8); $n+=8) {
        $decoded_dump.=SyxBlkDecode(substr($$refsyx,$n,8));
    }
    my $rem=($dlen%8);
    if ($rem>=2) {
        $decoded_dump.=SyxBlkDecode(substr($$refsyx,($dlen-$rem),$rem));
    }
    return $decoded_dump;
}

# Encodes a whole sysex data block from 8bit bytes to Korg 7bit encoding
sub SysexEncode {
    my($refsyx)=@_; # pass reference to 8bit sysex string without headers
    my $dlen=(length $$refsyx);
    my $encoded_dump;
    for (my $n=0; $n<=($dlen-7); $n+=7) {
        $encoded_dump.=SyxBlkEncode(substr($$refsyx,$n,7));
    }
    my $rem=($dlen%7);
    if ($rem) {
        $encoded_dump.=SyxBlkEncode(substr($$refsyx,($dlen-$rem),$rem));
    }
    return $encoded_dump;
}

#-------------------------------------------------------------------------------------------------------------------------
# Main Program Editor Frame

sub Main_Prg_Frame {

    $f01->Label(%TitleLbl_defaults, -text=> 'Main Program Parameters'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$f01->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# Program Name
    my $pname=$subframe->Frame()->grid(-columnspan=>2, -pady=>5);

    $pname->Label(-text=>'Program Name: ', -font=>'Sans 10')->grid(
    $pname->Entry(%Entry_defaults,
        -width              => 10,
        -font               => 'Fixed 10',
        -validate           => 'key',
        -validatecommand    => sub {$_[0]=~/^[\x20-\x7F]{0,10}$/},
        -invalidcommand     => sub {},
        -textvariable       => \$program_name
    ));

# Oscillator Mode
    my $oscmf=$subframe->Frame()->grid(-columnspan=>2);

    $oscmf->Label(-text=>'Osc Mode: ', -font=>'Sans 8')->pack(-side=>'left');
    my @oscmlabel=('single', 'double', 'drums');
    for (my $n=0;$n<=2;$n++) {
        $oscmf->Radiobutton(
            -text     => $oscmlabel[$n],
            -font     => 'Sans 8',
            -value    => $n,
            -variable => \$osc_mode,
            -command  => sub{ SendPaChMsg(); }
        )->pack(-side=>'left');
    }

# Assign
    my $asshldf=$subframe->Frame()->grid(-columnspan=>2);

    $asshldf->Label(-text=>'Assign: ', -font=>'Sans 8')->pack(-side=>'left');
    my @asslabel=('poly', 'mono');
    for (my $n=0;$n<=1;$n++) {
        $asshldf->Radiobutton(
            -text     => $asslabel[$n],
            -font     => 'Sans 8',
            -value    => $n,
            -variable => \$assign,
            -command  => sub{ SendPaChMsg(); }
        )->pack(-side=>'left');
    }

# Hold
    $asshldf->Label(-text=>'    Hold: ', -font=>'Sans 8')->pack(-side=>'left');
    $asshldf->Checkbutton(
        -text         => 'on/off',
        -font         => 'Sans 8',
        -variable     => \$hold,
        -command      => sub{ SendPaChMsg(); }
    )->pack(-side=>'left');

# Interval
    $subframe->Scale(%Scale_defaults,
        -variable     => \$interval,
        -to           =>  12,
        -from         => -12,
        -tickinterval =>   2,
        -label        => 'Osc2 Pitch Interval',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$interval
    ),-padx=>4);

# Detune
    $subframe->Scale(%Scale_defaults,
        -variable     => \$detune,
        -to           =>  50,
        -from         => -50,
        -tickinterval =>  10,
        -label        => 'Detune Osc1 / Osc2',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$detune
    ),-padx=>4);

# Delay Start
    $subframe->Scale(%Scale_defaults,
        -variable     => \$delay,
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>  10,
        -label        => 'Delay Osc2 Start',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$delay
    ),-padx=>4);
}

#-------------------------------------------------------------------------------------------------------------------------
# Pitch EG Frame

sub Pitch_EG_Frame {

    $f02->Label(%TitleLbl_defaults, -text=> 'Pitch Envelope Generator'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$f02->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# Start Level
    $subframe->Scale(%Scale_defaults,
        -variable     => \$PEG_SL,
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'Start Level',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$PEG_SL
    ),-padx=>4);

# Attack Time
    $subframe->Scale(%Scale_defaults,
        -variable     => \$PEG_AT,
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Attack Time',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$PEG_AT
    ),-padx=>4);

# Attack Level
    $subframe->Scale(%Scale_defaults,
        -variable     => \$PEG_AL,
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'Attack Level',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$PEG_AL
    ),-padx=>4);

# Decay Time
    $subframe->Scale(%Scale_defaults,
        -variable     => \$PEG_DT,
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Decay Time',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$PEG_DT
    ),-padx=>4);

# Release Time
    $subframe->Scale(%Scale_defaults,
        -variable     => \$PEG_RT,
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Release Time',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$PEG_RT
    ),-padx=>4);

# Release Level
    $subframe->Scale(%Scale_defaults,
        -variable     => \$PEG_RL,
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'Release Level',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$PEG_RL
    ),-padx=>4);

# EG Level Velocity Sensitivity
    $subframe->Scale(%Scale_defaults,
        -variable     => \$PEG_level,
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'EG Level Velocity Sensitivity',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$PEG_level
    ),-padx=>4);

# EG Time Velocity Sensitivity
    $subframe->Scale(%Scale_defaults,
        -variable     => \$PEG_time,
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'EG Time Velocity Sensitivity',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$PEG_time
    ),-padx=>4);
}

#-------------------------------------------------------------------------------------------------------------------------
# Aftertouch Frame

sub Aftertouch_Frame {

    $f03->Label(%TitleLbl_defaults, -text=> 'Aftertouch'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$f03->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# Pitch Bend Range
    $subframe->Scale(%Scale_defaults,
        -variable     => \$AT_PBrange,
        -to           =>  12,
        -from         => -12,
        -tickinterval =>   2,
        -label        => 'Pitch Bend Range',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$AT_PBrange
    ),-padx=>4);

# VDF Cutoff Frequency
    $subframe->Scale(%Scale_defaults,
        -variable     => \$AT_VDFcoff,
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'VDF Cutoff Frequency',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$AT_VDFcoff
    ),-padx=>4);

# VDF Modulation Intensity
    $subframe->Scale(%Scale_defaults,
        -variable     => \$AT_VDFmgint,
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>  11,
        -label        => 'VDF Modulation Intensity',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$AT_VDFmgint
    ),-padx=>4);

# VDA Amplitude
    $subframe->Scale(%Scale_defaults,
        -variable     => \$AT_VDAamp,
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'VDA Amplitude',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$AT_VDAamp
    ),-padx=>4);
}

#-------------------------------------------------------------------------------------------------------------------------
# Joystick Frame

sub Joystick_Frame {

    $f04->Label(%TitleLbl_defaults, -text=> 'Joystick'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$f04->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# Pitch Bend Range
    $subframe->Scale(%Scale_defaults,
        -variable     => \$JS_PBrange,
        -to           =>  12,
        -from         => -12,
        -tickinterval =>   2,
        -label        => 'Pitch Bend Range',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$JS_PBrange
    ),-padx=>4);

# VDF Sweep Intensity
    $subframe->Scale(%Scale_defaults,
        -variable     => \$JS_VDFswint,
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'VDF Sweep Intensity',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$JS_VDFswint
    ),-padx=>4);

# VDF Modulation Intensity
    $subframe->Scale(%Scale_defaults,
        -variable     => \$JS_VDFmgint,
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>  11,
        -label        => 'VDF Modulation Intensity',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$JS_VDFmgint
    ),-padx=>4);
}

#-------------------------------------------------------------------------------------------------------------------------
# VDF Cutoff Modulation Frame

sub VDF_Cutoff_Frame {

    $f05->Label(%TitleLbl_defaults, -text=> 'VDF Cutoff Modulation'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$f05->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# Modulation Waveform
    my $modwavf=$subframe->Frame()->grid(-columnspan=>2);

    $modwavf->Label(-text=>'Modulation Waveform:', -font=>'Sans 8')->grid(-row=>0, -columnspan=>6);;
    my @modwavlabel=('tri', "saw\x{2191}", "saw\x{2193}", 'sq1', 'rnd', 'sq2');
    for (my $n=0;$n<=5;$n++) {
        $modwavf->Radiobutton(
            -text     => $modwavlabel[$n],
            -font     => 'Sans 8',
            -value    => $n,
            -variable => \$VDFmod_wav,
            -command  => sub{ SendPaChMsg(); }
        )->grid(-row=>1, -column=>$n);
    }

# OSC1 Modulation Enable
    my $vdfmodf=$subframe->Frame()->grid(-columnspan=>2);

    $vdfmodf->Label(-text=>'  Osc1 enable:', -font=>'Sans 8')->pack(-side=>'left');
    $vdfmodf->Checkbutton(
        -font         => 'Sans 8',
        -variable     => \$VDF_OSC1,
        -command      => sub{ SendPaChMsg(); }
    )->pack(-side=>'left');

# OSC2 Modulation Enable
    $vdfmodf->Label(-text=>'  Osc2 enable:', -font=>'Sans 8')->pack(-side=>'left');
    $vdfmodf->Checkbutton(
        -font         => 'Sans 8',
        -variable     => \$VDF_OSC2,
        -command      => sub{ SendPaChMsg(); }
    )->pack(-side=>'left');

# Key Sync
    $vdfmodf->Label(-text=>'  Key Sync:', -font=>'Sans 8')->pack(-side=>'left');
    $vdfmodf->Checkbutton(
        -font         => 'Sans 8',
        -variable     => \$VDFkeysync,
        -command      => sub{ SendPaChMsg(); }
    )->pack(-side=>'left');

# VDF Modulation Frequency
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDFmgfreq,
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>  11,
        -label        => 'VDF Modulation Frequency',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDFmgfreq
    ),-padx=>4);

# VDF Modulation Intensity
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDFmgint,
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>  11,
        -label        => 'VDF Modulation Intensity',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDFmgint
    ),-padx=>4);

# VDF Modulation Delay
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDFmgdly,
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>  11,
        -label        => 'VDF Modulation Delay',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDFmgdly
    ),-padx=>4);
}

#-------------------------------------------------------------------------------------------------------------------------
# VDF EG

sub VDF_EG_Frame {
    my $osc=$_[0];

    $f06[$osc]->Label(%TitleLbl_defaults, -text=> 'VDF EG'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$f06[$osc]->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# Attack Time
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDF_AT[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Attack Time',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDF_AT[$osc]
    ),-padx=>4);

# Attack Level
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDF_AL[$osc],
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'Attack Level',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDF_AL[$osc]
    ),-padx=>4);

# Decay Time
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDF_DT[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Decay Time',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDF_DT[$osc]
    ),-padx=>4);

# Break Point
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDF_BP[$osc],
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'Break Point',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDF_BP[$osc]
    ),-padx=>4);

# Slope Time
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDF_ST[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Slope Time',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDF_ST[$osc]
    ),-padx=>4);

# Sustain Level
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDF_SL[$osc],
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'Sustain Level',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDF_SL[$osc]
    ),-padx=>4);

# Release Time
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDF_RT[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Release Time',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDF_RT[$osc]
    ),-padx=>4);

# Release Level
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDF_RL[$osc],
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'Release Level',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDF_RL[$osc]
    ),-padx=>4);

}

#-------------------------------------------------------------------------------------------------------------------------
# VDF

sub VDF_Frame {
    my $osc=$_[0];

    $f07[$osc]->Label(%TitleLbl_defaults, -text=> 'VDF'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$f07[$osc]->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# Keyboard Track Key
    my $VDF_kbdtk_fn=$subframe->Frame()->grid(-columnspan=>2);

    $VDF_kbdtk_fn->Label(-text=>'Keyboard Track Key: ', -font=>'Sans 8')->grid(
    my $VDF_kbdtk_entry=$VDF_kbdtk_fn->BrowseEntry(%BEntry_defaults,
        -variable     => \$VDF_kbdtk[$osc],
        -choices      => \@notes,
        -width        => 6,
        -font         => 'Fixed 8',
        -browsecmd    => sub{ SendPaChMsg(); }
    ));
    $VDF_kbdtk_entry->Subwidget("choices")->configure(%choices_defaults);
    $VDF_kbdtk_entry->Subwidget("arrow")->configure(%arrow_defaults);

# Cutoff Value
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDFcoffvl[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Cutoff Value',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDFcoffvl[$osc]
    ),-padx=>4);

# Cutoff Keyboard Track
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDFcoffkt[$osc],
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'Cutoff Keyboard Track',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDFcoffkt[$osc]
    ),-padx=>4);

# EG Intensity
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDF_EGint[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'EG Intensity',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDF_EGint[$osc]
    ),-padx=>4);

# EG Time Keyboard Track
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDF_EGtkt[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'EG Time Keyboard Track',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDF_EGtkt[$osc]
    ),-padx=>4);

# EG Time Velocity Sense
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDF_EGtvs[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'EG Time Velocity Sense',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDF_EGtvs[$osc]
    ),-padx=>4);

# EG Intensity Velocity Sense
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDF_EGivs[$osc],
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'EG Intensity Velocity Sense',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDF_EGivs[$osc]
    ),-padx=>4);
}

#-------------------------------------------------------------------------------------------------------------------------
# VDA EG

sub VDA_EG_Frame {
    my $osc=$_[0];

    $f08[$osc]->Label(%TitleLbl_defaults, -text=> 'VDA EG'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$f08[$osc]->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# Attack Time
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDA_AT[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Attack Time',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDA_AT[$osc]
    ),-padx=>4);

# Attack Level
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDA_AL[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Attack Level',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDA_AL[$osc]
    ),-padx=>4);

# Decay Time
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDA_DT[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Decay Time',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDA_DT[$osc]
    ),-padx=>4);

# Break Point
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDA_BP[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Break Point',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDA_BP[$osc]
    ),-padx=>4);

# Slope Time
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDA_ST[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Slope Time',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDA_ST[$osc]
    ),-padx=>4);

# Sustain Level
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDA_SL[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Sustain Level',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDA_SL[$osc]
    ),-padx=>4);

# Release Time
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDA_RT[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Release Time',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDA_RT[$osc]
    ),-padx=>4);
}

#-------------------------------------------------------------------------------------------------------------------------
# VDA

sub VDA_Frame {
    my $osc=$_[0];

    $f09[$osc]->Label(%TitleLbl_defaults, -text=> 'VDA'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$f09[$osc]->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# Keyboard Track Key
    my $VDA_kbdtk_fn=$subframe->Frame()->grid(-columnspan=>2);

    $VDA_kbdtk_fn->Label(-text=>'Keyboard Track Key: ', -font=>'Sans 8')->grid(
    my $VDA_kbdtk_entry=$VDA_kbdtk_fn->BrowseEntry(%BEntry_defaults,
        -variable     => \$VDA_kbdtk[$osc],
        -choices      => \@notes,
        -width        => 6,
        -font         => 'Fixed 8',
        -browsecmd    => sub{ SendPaChMsg(); }
    ));
    $VDA_kbdtk_entry->Subwidget("choices")->configure(%choices_defaults);
    $VDA_kbdtk_entry->Subwidget("arrow")->configure(%arrow_defaults);

# Oscillator Level
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDAosclv[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Oscillator Level',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDAosclv[$osc]
    ),-padx=>4);

# Amplifier Keyboard Tracking Intensity
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDAakti[$osc],
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'Amplifier Keyboard Tracking Intensity',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDAakti[$osc]
    ),-padx=>4);

# Amplifier Velocity Sense
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDAavs[$osc],
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'Amplifier Velocity Sense',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDAavs[$osc]
    ),-padx=>4);

# EG Time Keyboard Track
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDAegtkt[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'EG Time Keyboard Track',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDAegtkt[$osc]
    ),-padx=>4);

# EG Time Velocity Sense
    $subframe->Scale(%Scale_defaults,
        -variable     => \$VDAegtvs[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'EG Time Velocity Sense',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$VDAegtvs[$osc]
    ),-padx=>4);

}

#-------------------------------------------------------------------------------------------------------------------------
# Pitch Modulation

sub Pitch_Mod {
    my $osc=$_[0];

    $f10[$osc]->Label(%TitleLbl_defaults, -text=> 'Pitch Modulation'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$f10[$osc]->Frame(
    )->pack(-fill=>'x', -expand=>1, -padx=>10, -pady=>5);

# Frequency
    $subframe->Scale(%Scale_defaults,
        -variable     => \$PMG_freq[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Frequency',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$PMG_freq[$osc]
    ),-padx=>4);

# Delay
    $subframe->Scale(%Scale_defaults,
        -variable     => \$PMG_dly[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Delay',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$PMG_dly[$osc]
    ),-padx=>4);

# Fade in
    $subframe->Scale(%Scale_defaults,
        -variable     => \$PMG_Fin[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Fade in',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$PMG_Fin[$osc]
    ),-padx=>4);

# Intensity
    $subframe->Scale(%Scale_defaults,
        -variable     => \$PMG_Int[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Intensity',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$PMG_Int[$osc]
    ),-padx=>4);

# Frequency Modulation by Keyboard Tracking
    $subframe->Scale(%Scale_defaults,
        -variable     => \$PMG_FMKT[$osc],
        -to           =>  99,
        -from         => -99,
        -tickinterval =>  22,
        -label        => 'Frequency Modulation by Keyboard Tracking',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$PMG_FMKT[$osc]
    ),-padx=>4);

# Intensity Modulation by Aftertouch
    $subframe->Scale(%Scale_defaults,
        -variable     => \$PMG_IMA[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Intensity Modulation by Aftertouch',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$PMG_IMA[$osc]
    ),-padx=>4);

# Intensity Modulation by Joystick
    $subframe->Scale(%Scale_defaults,
        -variable     => \$PMG_IMJ[$osc],
        -to           =>  99,
        -from         =>   0,
        -tickinterval =>   9,
        -label        => 'Intensity Modulation by Joystick',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$PMG_IMJ[$osc]
    ),-padx=>4);

# Frequency Modulation by AT + JS
    $subframe->Scale(%Scale_defaults,
        -variable     => \$PMG_FMAJ[$osc],
        -to           =>   9,
        -from         =>   0,
        -tickinterval =>   1,
        -label        => 'Frequency Modulation by AT + JS',
        -command      => sub{ SendPaChMsg(); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -textvariable => \$PMG_FMAJ[$osc]
    ),-padx=>4);

}
