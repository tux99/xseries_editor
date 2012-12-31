#!/usr/bin/perl
#
#  Korg X Series Manger version 0.1
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

# default Korg device number (1-16)
my $dev_nr=1;

# set up main program window
my $mw=MainWindow->new();
$mw->title("X Series Manager - Voice Editor");
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
$tab[0] = $book->add('Tab0', -label=>'Common');
$tab[1] = $book->add('Tab1', -label=>'Element 1');
$tab[2] = $book->add('Tab2', -label=>'Element 2');


MainLoop;


# -----------
# Subroutines
# -----------

sub topMenubar {
}

sub StatusBar {
}

sub MidiPortList {
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

