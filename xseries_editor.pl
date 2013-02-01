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
use Tk::PNG;
use List::Util qw[min max];

use MIDI::ALSA ('SND_SEQ_EVENT_PORT_UNSUBSCRIBED',
                'SND_SEQ_EVENT_SYSEX');

MIDI::ALSA::client("X Series Editor PID_$$",1,1,1);
MIDI::ALSA::start();

# LCD style background color
my $LCDbg='#ECFFAF';
# title strips background and font color
my $Titlebg='#487890';
my $Titlefg='#F3F3F3';

my %Scale_defaults=(
    -width        => 8,
    -length       => 180,
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
my %RadioB_defaults=(
    -font        => 'Sans 8',
    -indicatoron => 0,
    -borderwidth => 1,
    -selectcolor => $LCDbg
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

# list of multisounds
my @X5_msounds=(
'000:A.Piano 1',  '001:A.Piano1LP', '002:A.Piano 2',  '003:E.Piano 1',  '004:E.Piano1LP',
'005:E.Piano 2',  '006:E.Piano2LP', '007:Soft EP',    '008:Soft EP LP', '009:Hard EP',
'010:Hard EP LP', '011:PianoPad 1', '012:PianoPad 2', '013:Clav',       '014:Clav LP',
'015:Harpsicord', '016:HarpsicdLP', '017:PercOrgan1', '018:PercOrg1LP', '019:PercOrgan2',
'020:PercOrg2LP', '021:Organ 1',    '022:Organ 1 LP', '023:Organ 2',    '024:Organ 2 LP',
'025:Organ 3',    '026:Organ 4',    '027:Organ 5',    '028:RotaryOrg1', '029:RotaryOrg2',
'030:PipeOrgan1', '031:PipeOrg1LP', '032:PipeOrgan2', '033:PipeOrg2LP', '034:PipeOrgan3',
'035:PipeOrg3LP', '036:Musette',    '037:Musette V',  '038:Bandneon',   '039:BandneonLP',
'040:Accordion',  '041:AcordionLP', '042:Harmonica',  '043:G.Guitar',   '044:G.GuitarLP',
'045:F.Guitar',   '046:F.GuitarLP', '047:F.Guitar V', '048:A.Gtr Harm', '049:E.Guitar 1',
'050:E.Guitr1 V', '051:E.Guitar 2', '052:E.Guitar 3', '053:MuteGuitar', '054:Funky Gtr',
'055:FunkyGtr V', '056:E.Gtr Harm', '057:DistGuitar', '058:Dist GtrLP', '059:DistGuitrV',
'060:Over Drive', '061:OverDrv LP', '062:OverDrv F4', '063:MuteDstGtr', '064:MtDstGtr V',
'065:PowerChord', '066:PowerChd V', '067:OverDvChrd', '068:Gtr Slide',  '069:GtrSlide V',
'070:Sitar 1',    '071:Sitar 2',    '072:Sitar 2 LP', '073:Santur',     '074:Bouzouki',
'075:BouzoukiLP', '076:Banjoe',     '077:Shamisen',   '078:Koto',       '079:Uood',
'080:Harp',       '081:MandlinTrm', '082:A.Bass 1',   '083:A.Bass1 LF', '084:A.Bass 2',
'085:A.Bass2 LP', '086:E.Bass 1',   '087:E.Bass1 LP', '088:E.Bass 2',   '089:E.Bass2 LP',
'090:Pick Bass1', '091:PicBass1LP', '092:Pick Bass2', '093:Fretless',   '094:FretlessLP',
'095:Slap Bass1', '096:Slap Bass2', '097:SlpBass2LP', '098:Slap Bass3', '099:SynthBassl',
'100:SynBass1LP', '101:SynthBass2', '102:SynBass2LP', '103:House Bass', '104:FM Bass',
'105:FM Bass LP', '106:Kalimba',    '107:Music Box',  '108:MusicBoxLP', '109:Log Drum',
'110:Marimba',    '111:Xylophone',  '112:Vibe',       '113:Celesta',    '114:Glocken',
'115:BrightBell', '116:B.Bell LP',  '117:Metal Bell', '118:M.Bell LP',  '119:Gamelan',
'120:Pole',       '121:Pole LP',    '122:Tubular',    '123:Split Drum', '124:Split Bell',
'125:Flute',      '126:Pan Flute',  '127:PanFluteLP', '128:Shakuhachi', '129:ShakhachLP',
'130:Bottle',     '131:Recorder',   '132:Ocarina',    '133:Oboe',       '134:EnglishHrn',
'135:Eng.HornLP', '136:BasoonOboe', '137:BsonOboeLP', '138:Clarinet',   '139:ClarinetLP',
'140:Bari Sax',   '141:Bari.SaxLP', '142:Tenor Sax',  '143:T.Sax LP',   '144:Alto Sax',
'145:A.Sax LP',   '146:SopranoSax', '147:S.Sax LP',   '148:Tuba',       '149:Tuba LP',
'150:Horn',       '151:FlugelHorn', '152:Trombone 1', '153:Trombone 2', '154:Trumpet',
'155:Trumpet LP', '156:Mute TP',    '157:Mute TP LP', '158:Brass 1',    '159:Brass 1 LP',
'160:Brass 2',    '161:Brass 2 LP', '162:StringEns.', '163:StrEns. V1', '164:StrEns. V2',
'165:StrEns. V3', '166:AnaStrings', '167:PWM',        '168:Violin',     '169:Cello',
'170:Cello LP',   '171:Pizzicato',  '172:Voice',      '173:Choir',      '174:Soft Choir',
'175:Air Vox',    '176:Doo Voice',  '177:DooVoiceLP', '178:Syn Vox',    '179:Syn Vox LP',
'180:White Pad',  '181:Ether Bell', '182:E.Bell LP',  '183:Mega Pad',   '184:Spectrum 1',
'185:Spectrum 2', '186:Stadium',    '187:Stadium NT', '188:BrushNoise', '189:BruNoiseNT',
'190:Steel Drum', '191:SteelDrmLP', '192:BrushSwirl', '193:Belltree',   '194:BelltreeNT',
'195:BeltreV NT', '196:Tri Roll',   '197:TriRoll NT', '198:Telephon',   '199:TelephonNT',
'200:Clicker',    '201:Clicker NT', '202:Crickets 1', '203:Crickts1NT', '204:Crickets 2',
'205:Crickts2NT', '206:Magic Bell', '207:Sporing',    '208:Rattle',     '209:Kava 1',
'210:Kava 2',     '211:Fever 1',    '212:Fever 2',    '213:Zappers 1',  '214:Zappers 2',
'215:Bugs',       '216:Surfy',      '217:SleighBell', '218:Elec Beat',  '219:Idling',
'220:EthnicBeat', '221:Taps',       '222:Tap 1',      '223:Tap 2',      '224:Tap 3',
'225:Tap 4',      '226:Tap 5',      '227:Orch Hit',   '228:SnareRl/Ht', '229:Syn Snare',
'230:Rev Snare',  '231:PowerSnare', '232:Orch Perc',  '233:Crash Cym',  '234:CrashCymLP',
'235:CrashLP NT', '236:China Cym',  '237:Splash Cym', '238:Orch Crash', '239:Tite HH',
'240:Tite HH NT', '241:Bell Ride',  '242:Ping Ride',  '243:Timpani',    '244:Timpani LP',
'245:Cabasa',     '246:Cabasa NT',  '247:Agogo',      '248:Cow Bell',   '249:Low Bongo',
'250:Claves',     '251:Timbale',    '252:WoodBlockl', '253:WoodBlock2', '254:WoodBlock3',
'255:Taiko Hit',  '256:Syn Claves', '257:Melo Tom',   '258:ProccesTom', '259:Syn Tom 1',
'260:Syn Tom 2',  '261:VocalSnare', '262:Zap 1',      '263:Zap 2',      '264:Fret Zap 1',
'265:Fret Zap 2', '266:Vibla Slap', '267:Indust',     '268:Thing',      '269:Thing NT',
'270:FingerSnap', '271:FingSnapNT', '272:Tambourine', '273:Hand Clap',  '274:HandClapNT',
'275:Gun Shot',   '276:Castanet',   '277:CastanetNT', '278:Snap',       '279:Snap NT',
'280:Gt Scratch', '281:Side Stick', '282:SideStikNT', '283:TimbleSide', '284:TimblSidNT',
'285:Syn Rim',    '286:Syn Rim NT', '287:Open HH',    '288:OpenSyn HH', '289:CloseSynHH',
'290:Sagat',      '291:Sagat NT',   '292:Sagatty',    '293:Sagatty NT', '294:JingleBell',
'295:Taiko',      '296:Slap Bongo', '297:Open Conga', '298:Slap Conga', '299:Palm Conga',
'300:Mute Conga', '301:Tabla 1',    '302:Tabla 2',    '303:Maracas',    '304:SynMaracas',
'305:SynMarcsNT', '306:MuteTriang', '307:OpenTriang', '308:Guiro',      '309:Guiro LP',
'310:Scratch Hi', '311:ScratcHiNT', '312:Scratch Lo', '313:ScratcLoNT', '314:ScratchDbi',
'315:ScratDblNT', '316:Mini 1a',    '317:Digital 1',  '318:VS 102',     '319:VS 48',
'320:VS 52',      '321:VS 58',      '322:VS 71',      '323:VS 72',      '324:VS 88',
'325:VS 89',      '326:13 - 35',    '327:DWGSOrgan1', '328:DWGSOrgan2', '329:DWGS E.P.',
'330:Saw',        '331:Square',     '332:Ramp',       '333:Pulse 25%',  '334:Pulse 8%',
'335:Puise 4%',   '336:Syn Sine',   '337:Sine',       '338:DJ Kit 1',   '339:DJ Kit 2');

my @X5D_msounds=( @X5_msounds,
'340:M1 Piano',   '341:Organ 6',    '342:Organ 6 LP', '343:Super BX-3', '344:SuperBX3LP',
'345:Stick',      '346:Tambura',    '347:Tambura LP', '348:SynthBass3', '349:RezBass 1',
'350:RezBass 2',  '351:MiniBass',   '352:SynMallet',  '353:Glocken 2',  '354:FingCymbal',
'355:FingCymbNT', '356:Gong',       '357:Gong Lp',    '358:HardFlute1', '359:HardFlute2',
'360:Tin Flute',  '361:TinFluteLP', '362:BrightHorn', '363:Glass Vox',  '364:Synth Pad',
'365:Synth PadA', '366:Ghostly',    '367:WhiteNoise', '368:WhiteNoiNT', '369:Jetstar',
'370:Jetstar LP', '371:JetstrLPNT', '372:Windbell',   '373:WindbellLP', '374:WindbellNT',
'375:Waterphone', '376:Wavesweep',  '377:WaveSweepA', '378:WaveSweepB', '379:Lore',
'380:Lore NT',    '381:Tron Up',    '382:Tron Up LP', '383:Tron Up NT', '384:Flute FX',
'385:FluteFX LP', '386:Flutter',    '387:Flutter LP', '388:Cast Roll',  '389:CastRollNT',
'390:Harp Up',    '391:Harp UP LP', '392:Jung Gliss', '393:JungGlisLP', '394:MalletLoop',
'395:MalletLpNT', '396:Boogeta',    '397:Moutharp1',  '398:Mouthrp1A',  '399:Moutharp2',
'400:Mouthrp2A',  '401:ChromRes',   '402:WahFuzz',    '403:OilDrum',    '404:Fist',
'405:Stick Hit',  '406:Metal Hit',  '407:GlassBreak', '408:Baya',       '409:Drop',
'410:CorkPop',    '411:Pull 1',     '412:Pull 1 NT',  '413:Pull 2',     '414:Pull 2 NT',
'415:SolidHit',   '416:HandDrill',  '417:HandDrilNT', '418:Scratch a',  '419:Samurai!',
'420:Growl!',     '421:Growl! NT',  '422:Monkey 1',   '423:Monkey 2',   '424:MouthHarps',
'425:Loopey',     '426:ClockWorks', '427:MusicaLoop', '428:Manimals',   '429:Down Lo');

my @X5_drums=(
'000:Fat Kick',   '001:Rock Kick',  '002:Ambi.Kick',  '003:Crisp Kick', '004:Punch Kick',
'005:Real Kick',  '006:Dance Kick', '007:Gated Kik',  '008:ProcesKick', '009:Metal Kick',
'010:Syn Kick 1', '011:Syn Kick 2', '012:Syn Kick 3', '013:Orch B.Drm', '014:Snare 1',
'015:Snare 2',    '016:Snare 3',    '017:Snare 4',    '018:PicloSnare', '019:Soft Snare',
'020:LightSnare', '021:TightSnare', '022:Ambi.Snare', '023:Rev Snare',  '024:RoliSnare1',
'025:RollSnare2', '026:Rock Snare', '027:GatedSnare', '028:PowerSnare', '029:Syn Snare1',
'030:Syn Snare2', '031:Gun Shot',   '032:Brush Slap', '033:BrushSwish', '034:BrushSwirl',
'035:Brush Tap',  '036:Side Stick', '037:Syn Rim',    '038:VocalSnr 1', '039:VocalSnr 2',
'040:Crash Cym',  '041:Crash LP',   '042:China Cym',  '043:China LP',   '044:Splash Cym',
'045:Splash LP',  '046:Orch Crash', '047:OrchCym LP', '048:Tite HH',    '049:Open HH',
'050:Pedal HH',   '051:CloseSynHH', '052:Open SynHH', '053:Sagat',      '054:Ride Edge',
'055:Ride Cup',   '056:Ride Cym 1', '057:Ride Cym 2', '058:Tom Hi',     '059:Tom Lo',
'060:ProcessTom', '061:SynToml Hi', '062:SynTom1 Lo', '063:Syn Tom 2',  '064:Brush Tom',
'065:Agogo',      '066:Lo Bongo',   '067:Hi Bongo',   '068:Slap Bongo', '069:Claves',
'070:Syn Claves', '071:Open Conga', '072:Slap Conga', '073:Palm Conga', '074:Mute Conga',
'075:Baya 1',     '076:Baya 2',     '077:Tabla 1',    '078:Tabla 2',    '079:Tabla 3',
'080:Maracas',    '081:Cabasa',     '082:SynMaracas', '083:MuteTriang', '084:OpenTriang',
'085:Tambourine', '086:Cowbell',    '087:SynCowbell', '088:R - Timbal', '089:Hi Timbal',
'090:Lo Timbal',  '091:WoodBlock1', '092:WoodBlock2', '093:WoodBlock3', '094:Hand Claps',
'095:Syn Claps',  '096:Zap 1',      '097:Zap 2',      '098:Scratch Hi', '099:Scratch Lo',
'100:ScratchDbl', '101:Thing',      '102:Mute Cuica', '103:Open Cuica', '104:Vibraslap',
'105:Guiro S',    '106:Guiro L',    '107:Castanet',   '108:FingerSnap', '109:Timbales',
'110:Kalimba 1',  '111:Kalimba 2',  '112:Marimba 1',  '113:Marimba 2',  '114:Marimba 3',
'115:Marimba 4',  '116:Xylofon 1',  '117:Xylofon 2',  '118:Xylofon 3',  '119:Log Drum 1',
'120:Log Drum 2', '121:Log Drum 3', '122:Log Drum 4', '123:Log Drum 5', '124:Snap',
'125:BrightBell', '126:Metal Bell', '127:Gamelan 1',  '128:Gamelan 2',  '129:Celeste',
'130:Glocken',    '131:Vibe 1',     '132:Vibe 2',     '133:Vibe 3',     '134:Vibe 4',
'135:Pole',       '136:TubulBell1', '137:TubulBell2', '138:TubulBell3', '139:Gt Scratch',
'140:Chic 1',     '141:Chic 2',     '142:Spectrum 1', '143:Spectrum 2', '144:Stadium',
'145:BrushNoise', '146:Gt Slide',   '147:Bell Tree',  '148:Tri Roll',   '149:JingleBell',
'150:Whistle S',  '151:Whistle L',  '152:Timpani',    '153:Taiko Hi',   '154:Taiko Lo',
'155:Music Box1', '156:Music Box2', '157:Clicker 1',  '158:Clicker 2',  '159:Clicker 3',
'160:Crickets',   '161:Orch Hit',   '162:Metronome1', '163:Metronome2');

my @X5D_drums=( @X5_drums,
'164:OilDrum',    '165:Fist',       '166:Close HH',   '167:Stick Hit',  '168:MetalHitHi',
'169:MetalHitLo', '170:GlassBreak', '171:Drop',       '172:CorkPop',    '173:Pull 1',
'174:Pull 2',     '175:SolidHit',   '176:HandDrill',  '177:Scratch a',  '178:Scratch b',
'179:Scratch c',  '180:Sword',      '181:BISS',       '182:BOOFN',      '183:BOOGETA',
'184:CHLACK',     '185:COOSH',      '186:COUGH',      '187:ISSH',       '188:POOM',
'189:Uhhh!',      '190:Samurai!',   '191:Growl!',     '192:Monkey 1',   '193:Monkey 2',
'194:Glocken 2',  '195:Glocken 3',  '196:FingCymbal', '197:Gong Hi',    '198:Gong Lo',
'199:WhiteNoise', '200:Jetstar',    '201:Windbell',   '202:Waterphone', '203:Lore',
'204:Tron Up',    '205:Flute FX',   '206:Flutter',    '207:Cast Roll',  '208:Harp Up',
'209:Jung Gliss', '210:MalletLoop', '211:MouthHarp1', '212:MouthHrp1A', '213:MouthHarp2',
'214:MouthHrp2A');

my @effects=(
'00:No Effect', '01:Hall', '02:Ensemble Hall', '03:Concert Hall', '04:Room', '05:Large Room',
'06:Live Stage', '07:Wet Plate', '08:Dry Plate', '09:Spring Reverb', '10:Early Reflection 1',
'11:Early Reflection 2', '12:Early Reflection 3', '13:Stereo Delay', '14:Cross Delay',
'15:Dual Mono Delay', '16:Multi Tap Delay 1', '17:Multi Tap Delay 2', '18:Multi Tap Delay 3',
'19:Stereo Chorus 1', '20:Stereo Chorus 2', '21:Quadrature Chorus', '22:Cross Over Chorus',
'23:Harmonic Chorus', '24:Symphonic Ensemble', '25:Flanger 1', '26:Flanger 2', '27:Cross Over Flanger',
'28:Exciter', '29:Enhancer', '30:Distortion', '31:Over Drive', '32:Stereo Phaser 1', '33:Stereo Phaser 2',
'34:Rotary Speaker', '35:Auto Pan', '36:Tremolo', '37:Parametric EQ', '38:Chorus-Delay', '39:Flanger-Delay',
'40:Delay / Hall', '41:Delay / Room', '42:Delay / Chorus', '43:Delay / Flanger', '44:Delay / Distortion',
'45:Delay / Over Drive', '46:Delay / Phaser', '47:Delay / Rotary Speaker'
);

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

# Pan values
my @panval=('OFF', 'A15', 'A14', 'A13', 'A12', 'A11', 'A10', 'A 9', 'A 8', 'A 7', 'A 6', 'A 5', 'A 4', 'A 3', 'A 2',
    'A 1', 'CNT', 'B 1', 'B 2', 'B 3', 'B 4', 'B 5', 'B 6', 'B 7', 'B 8', 'B 9', 'B10', 'B11', 'B12', 'B13', 'B14', 'B15');

## Program Paramters
my $modified=0;
my $prgfilename='';
# Main
my $program_name;    my $osc_mode;
my $assign;          my $hold;
my $interval;        my $detune;
my $delay;
# Pitch EG
my $PEG_SL;          my $PEG_AT;
my $PEG_AL;          my $PEG_DT;
my $PEG_RT;          my $PEG_RL;
my $PEG_level;       my $PEG_time;
# Aftertouch
my $AT_PBrange;      my $AT_VDFcoff;
my $AT_VDFmgint;     my $AT_VDAamp;
# Joystick
my $JS_PBrange;      my $JS_VDFswint;
my $JS_VDFmgint;
# VDF Cutoff MG
my $VDFmod_wav;      my $VDFmgfreq;
my $VDFmgint;        my $VDFmgdly;
my $VDF_OSC1;        my $VDF_OSC2;
my $VDFkeysync;
# Misc OSC specific
my @msound;          my @octave;
my @PEG_Int;         my @ABPan;
my @Csend_lvl;       my @Dsend_lvl;
# VDF EG
my @VDF_AT;          my @VDF_AL;
my @VDF_DT;          my @VDF_BP;
my @VDF_ST;          my @VDF_SL;
my @VDF_RT;          my @VDF_RL;
# VDF
my @VDFcoffvl;       my @VDFcoffkt;
my @VDF_EGint;       my @VDF_EGtkt;
my @VDF_EGtvs;       my @VDF_EGivs;
my @VDF_kbdtk;       my @VDFktmode;
my @VDF_CoInt;       my @VDF_CoVSn;
my @VDF_ATtv;        my @VDF_DTtv;
my @VDF_STtv;        my @VDF_RTtv;
my @VDF_ATtk;        my @VDF_DTtk;
my @VDF_STtk;        my @VDF_RTtk;
# VDA EG
my @VDA_AT;          my @VDA_AL;
my @VDA_DT;          my @VDA_BP;
my @VDA_ST;          my @VDA_SL;
my @VDA_RT;
# VDA
my @VDAosclv;        my @VDAakti;
my @VDAavs;          my @VDAegtkt;
my @VDAegtvs;        my @VDA_kbdtk;
my @VDA_ATtv;        my @VDA_DTtv;
my @VDA_STtv;        my @VDA_RTtv;
my @VDA_ATtk;        my @VDA_DTtk;
my @VDA_STtk;        my @VDA_RTtk;
my @VDAktmode;
# Pitch MG
my @PMG_freq;        my @PMG_dly;
my @PMG_Fin;         my @PMG_Int;
my @PMG_FMKT;        my @PMG_IMA;
my @PMG_IMJ;         my @PMG_FMAJ;
my @PMGmod_wav;      my @PMGkeysync;
# Effects
my @FXtype;
my @FXtoggle;
my $FXplacement;

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
my $mf1;
my $Main_Prg;
my $Pitch_EG;
my $Aftertouch;
my $Joystick;
my $VDF_Cutoff;
my @VDF;
my @VDFvs;
my @VDFkt;
my @VDF_EG;
my @VDAvs;
my @VDAkt;
my @VDA_EG;
my @Main_Osc;
my @Pitch_MG;
my @Main_FX;
my $FX_Place;
my $combwin;
my $midiupload;
my $midi_settings;

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

newProgram();

# set up main frame with top menu bar, three tabs and a status bar
topMenubar();

my $book=$mw->NoteBook(
    -borderwidth =>1,
    -ipadx       =>0
) -> pack(
    -side   => 'top',  -expand => 1,
    -fill   => 'both', -anchor => 'nw'
);

my @tab;
$tab[0] = $book->add('Tab0', -label=>'Main');
$tab[1] = $book->add('Tab1', -label=>'Oscillator 1');
$tab[2] = $book->add('Tab2', -label=>'Oscillator 2');
$tab[3] = $book->add('Tab3', -label=>'Effects');

Main_Tab(\$tab[0]);
Osc_Tabs(\$tab[1], \$tab[2]);
FX_Tab(\$tab[3]);
StatusBar();

MainLoop;


# -----------
# Subroutines
# -----------

# Main Tab
sub Main_Tab {
    my($MainTab)=@_;
    my $Col_1  =$$MainTab->Frame()->pack(-side=>'left',   -fill=>'y');
    my $Col_2  =$$MainTab->Frame()->pack(-side=>'left',   -fill=>'y');
    my $Col_34 =$$MainTab->Frame()->pack(-side=>'top',    -fill=>'both', -expand=>1);
    my $Col_34b=$$MainTab->Frame()->pack(-side=>'bottom', -fill=>'both', -expand=>1);
    my $Col_3  =$$MainTab->Frame()->pack(-side=>'left',   -fill=>'both', -expand=>1);
    my $Col_4  =$$MainTab->Frame()->pack(-side=>'left',   -fill=>'both', -expand=>1);

    $Main_Prg  =$Col_1->Frame(%Frame_defaults)->pack();
    $Pitch_EG  =$Col_2->Frame(%Frame_defaults)->pack();
    $Aftertouch=$Col_1->Frame(%Frame_defaults)->pack();
    $VDF_Cutoff=$Col_2->Frame(%Frame_defaults)->pack();
    $Joystick  =$Col_1->Frame(%Frame_defaults)->pack();

    # photo of X5DR front panel (purely for decorative purposes)
    #my $jpg1=$Col_34->Photo('-format'=>'jpeg', -file=>'x5dr.jpg');
    #$Col_34->Label(-image=>$jpg1, -borderwidth=>0, -anchor=>'n',-height=>92
    #)->pack(-anchor=>'n', -fill=>'x', -ipadx=>2);

    $midi_settings=$Col_34b->Frame(%Frame_defaults)->pack(-side=>'bottom',-fill=>'x');
    MIDI_IOconfig();

    Main_Prg_Frame();
    Aftertouch_Frame();
    Joystick_Frame();
    Pitch_EG_Frame();
    VDF_Cutoff_Frame();
}

# Osc Tabs
sub Osc_Tabs {
    my @OscTab=@_;
    for (my $n=0; $n<=1; $n++) {
        my $Col_1=${$OscTab[$n]}->Frame()->pack(-side=>'left', -fill=>'both', -expand=>1);
        my $Col_2=${$OscTab[$n]}->Frame()->pack(-side=>'left', -fill=>'both', -expand=>1);
        my $Col_3=${$OscTab[$n]}->Frame()->pack(-side=>'left', -fill=>'both', -expand=>1);
        my $Col_4=${$OscTab[$n]}->Frame()->pack(-side=>'left', -fill=>'both', -expand=>1);

        $Main_Osc[$n]=$Col_1->Frame(%Frame_defaults)->pack(-fill=>'both', -expand=>1);
        $VDF_EG[$n]  =$Col_2->Frame(%Frame_defaults)->pack(-fill=>'both', -expand=>1);
        $VDA_EG[$n]  =$Col_3->Frame(%Frame_defaults)->pack(-fill=>'both', -expand=>1);
        $Pitch_MG[$n]=$Col_4->Frame(%Frame_defaults)->pack(-fill=>'both', -expand=>1);
        $VDF[$n]     =$Col_1->Frame(%Frame_defaults)->pack(-fill=>'x');
        $VDFvs[$n]   =$Col_1->Frame(%Frame_defaults)->pack(-fill=>'x');
        $VDFkt[$n]   =$Col_2->Frame(%Frame_defaults)->pack(-fill=>'x');
        $VDAvs[$n]   =$Col_4->Frame(%Frame_defaults)->pack(-fill=>'x');
        $VDAkt[$n]   =$Col_3->Frame(%Frame_defaults)->pack(-fill=>'x');

        Main_Osc_Frame($n);
        Pitch_MG_Frame($n);
        VDF_EG_Frame($n);
        VDF_Frame($n);
        VDFvs_Frame($n);
        VDFkt_Frame($n);
        VDA_EG_Frame($n);
        VDAvs_Frame($n);
        VDAkt_Frame($n);
    }
}

# Effects Tab
sub FX_Tab {
    my($FXTab)=@_;
    my $Col_1 =$$FXTab->Frame()->pack(-side=>'left',  -fill=>'y');
    my $Col_2 =$$FXTab->Frame()->pack(-side=>'left');
    my $Col_34=$$FXTab->Frame()->pack(-side=>'right', -fill=>'y');
    for (my $n=0; $n<=1; $n++) {
        $Main_FX[$n]=$Col_1->Frame(%Frame_defaults)->pack();
        Main_FX_Frame($n);
    }
    $FX_Place=$Col_34->Frame(%Frame_defaults)->pack();
    FX_Place_Frame();
}

# top menu bar
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

# bottom status bar
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
    my $rtn='';
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
    my($win, $msg)=@_;

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
    my($win, $msg)=@_;

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

# send Program Parameter Change Messages
sub SendPaChMsg {
    my($param,$value)=@_;
    print STDOUT "par:[$param] val:[$value]\n";
    if ($midi_outdev ne '') {
        if ($value<0){ $value=$value+16384; }
        my $val_msb=chr(int($value/128));
        my $val_lsb=chr($value%128);
        my $par_msb=chr(int($param/128));
        my $par_lsb=chr($param%128);
        # switch to Program Edit mode
        my $modech="\x42".chr($dev_nr-1+48)."\x36\x4E\x03\x00";
        MIDI::ALSA::output( MIDI::ALSA::sysex( $dev_nr-1, $modech, 0 ) );
        # send Program Parameter Change message
        my $ddata="\x42".chr($dev_nr-1+48)."\x36\x41".$par_lsb.$par_msb.$val_lsb.$val_msb;
        MIDI::ALSA::output( MIDI::ALSA::sysex( $dev_nr-1, $ddata, 0 ) );
    }
}

# create an array of available midi ports
sub MidiPortList {
    my($dir)=@_;
    my @portlist;
    my %clients = MIDI::ALSA::listclients();
    my %portnrs = MIDI::ALSA::listnumports();
    my $tmp=0;
    while (my ($key, $value) = each(%clients)){
        if ($key>15 && $key<128) {
            for (my $i=0; $i<($portnrs{$key}); $i++) {
                $portlist[$tmp]=$value.":".$i;
                $tmp++;
            }
        }
    }
    return @portlist;
}

# set up a new midi connection and drop the previous one
sub MidiConSetup {
    my($dir)=@_;
    MIDI::ALSA::stop();
    if ($dir eq 'out') {
        if ($midi_outdev_prev ne '') {
            MIDI::ALSA::disconnectto(1,"$midi_outdev_prev");
        }
        $midi_outdev_prev=$midi_outdev;
        MIDI::ALSA::connectto(1,"$midi_outdev");
    } elsif ($dir eq 'in') {
        if ($midi_indev_prev ne '') {
            MIDI::ALSA::disconnectfrom(0,"$midi_indev_prev");
        }
        $midi_indev_prev=$midi_indev;
        MIDI::ALSA::connectfrom(0,"$midi_indev");
    }
    MIDI::ALSA::start();
    if (($midi_indev ne '') && ($midi_outdev ne '')) {
    #    $vcdwn_btn->configure(-state=>'active');
    } else {
    #    $vcdwn_btn->configure(-state=>'disabled');
    }
    if ($midi_outdev ne '') {
        $midiupload->configure(-state=>'active');
    } else {
        $midiupload->configure(-state=>'disabled');
    }
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

# Standard Horizontal Slider Subroutine
sub StdSlider {
    my($frame,$var,$from,$to,$intv,$incr,$param,$label)=@_;

    $$frame->Scale(%Scale_defaults,
        -variable     =>  $var,
        -to           =>  $to,
        -from         =>  $from,
        -tickinterval =>  $intv,
        -label        =>  $label,
        -command      => sub{ SendPaChMsg($param,$$var); }
    )->grid(
    $$frame->Spinbox(%Entry_defaults,
        -width        =>  3,
        -justify      => 'center',
        -font         => 'Sans 10',
        -to           =>  $to,
        -from         =>  $from,
        -increment    =>  $incr,
        -state        => 'readonly',
        -readonlybackground => $LCDbg,
        -textvariable =>  $var,
        -command      => sub{ SendPaChMsg($param,$$var); }
    ),-padx=>4);
}

# Direction Switch
sub DirSwitch {
    my($frame,$var,$parm,$desc)=@_;

    $$frame->Label(-text=>$desc, -font=>'Sans 8')->pack(-side=>'left');
    my @label=(['-','-1'],['0','0'],['+','1']);
    for (my $n=0;$n<=2;$n++) {
        $$frame->Radiobutton(%RadioB_defaults,
            -text     => $label[$n][0],
            -width    => 1,
            -value    => $label[$n][1],
            -variable => $var,
            -command  => sub{ SendPaChMsg($parm,$$var); }
        )->pack(-side=>'left', -pady=>4);
    }
}

# Standard subframe with header, returns subframe created
sub StdFrame {
    my($frame,$title)=@_;
    $$frame->Label(%TitleLbl_defaults, -text=>$title)->pack(-fill=>'x', -expand=>1, -anchor=>'n');
    my $subframe=$$frame->Frame()->pack(-fill=>'x', -expand=>1, -padx=>5, -pady=>5);
    return $subframe;
}

# initialise all Program values
sub newProgram {
    $modified=0;
    $prgfilename='';
    # Main
    $program_name='Unnamed';
    $osc_mode=1;        $assign=0;
    $hold=0;            $interval=0;
    $detune=0;          $delay=0;
    # Pitch EG
    $PEG_SL=0;          $PEG_AT=0;
    $PEG_AL=0;          $PEG_DT=0;
    $PEG_RT=0;          $PEG_RL=0;
    $PEG_level=0;       $PEG_time=0;
    # Aftertouch
    $AT_PBrange=0;      $AT_VDFcoff=0;
    $AT_VDFmgint=0;     $AT_VDAamp=0;
    # Joystick
    $JS_PBrange=0;      $JS_VDFswint=0;
    $JS_VDFmgint=0;
    # VDF Cutoff MG
    $VDFmod_wav=0;      $VDFmgfreq=0;
    $VDFmgint=0;        $VDFmgdly=0;
    $VDF_OSC1=0;        $VDF_OSC2=0;
    $VDFkeysync=0;

    for (my $osc=0; $osc<=1; $osc++) {
        $msound[$osc]='000:A.Piano 1';
        $octave[$osc]=0;
        $PEG_Int[$osc]=0;
        $ABPan[$osc]=15;
        $Csend_lvl[$osc]=0;
        $Dsend_lvl[$osc]=0;
        # VDF EG
        $VDF_AT[$osc]=0;          $VDF_AL[$osc]=0;
        $VDF_DT[$osc]=0;          $VDF_BP[$osc]=0;
        $VDF_ST[$osc]=0;          $VDF_SL[$osc]=0;
        $VDF_RT[$osc]=0;          $VDF_RL[$osc]=0;
        # VDF
        $VDFcoffvl[$osc]=0;       $VDFcoffkt[$osc]=0;
        $VDF_EGint[$osc]=0;       $VDF_EGtkt[$osc]=0;
        $VDF_EGtvs[$osc]=0;       $VDF_EGivs[$osc]=0;
        $VDF_kbdtk[$osc]='C 4';   $VDFktmode[$osc]=0;
        $VDF_CoInt[$osc]=0;       $VDF_CoVSn[$osc]=0;
        $VDF_ATtv[$osc]=0;        $VDF_DTtv[$osc]=0;
        $VDF_STtv[$osc]=0;        $VDF_RTtv[$osc]=0;
        $VDF_ATtk[$osc]=0;        $VDF_DTtk[$osc]=0;
        $VDF_STtk[$osc]=0;        $VDF_RTtk[$osc]=0;
        # VDA EG
        $VDA_AT[$osc]=0;          $VDA_AL[$osc]=0;
        $VDA_DT[$osc]=0;          $VDA_BP[$osc]=0;
        $VDA_ST[$osc]=0;          $VDA_SL[$osc]=0;
        $VDA_RT[$osc]=0;
        # VDA
        $VDAosclv[$osc]=90;       $VDAakti[$osc]=0;
        $VDAavs[$osc]=0;          $VDAegtkt[$osc]=0;
        $VDAegtvs[$osc]=0;        $VDA_kbdtk[$osc]='C 4';
        $VDAktmode[$osc]=0;
        $VDA_ATtv[$osc]=0;        $VDA_DTtv[$osc]=0;
        $VDA_STtv[$osc]=0;        $VDA_RTtv[$osc]=0;
        $VDA_ATtk[$osc]=0;        $VDA_DTtk[$osc]=0;
        $VDA_STtk[$osc]=0;        $VDA_RTtk[$osc]=0;
        # Pitch MG
        $PMG_freq[$osc]=0;        $PMG_dly[$osc]=0;
        $PMG_Fin[$osc]=0;         $PMG_Int[$osc]=0;
        $PMG_FMKT[$osc]=0;        $PMG_IMA[$osc]=0;
        $PMG_IMJ[$osc]=0;         $PMG_FMAJ[$osc]=0;
        $PMGmod_wav[$osc]=0;      $PMGkeysync[$osc]=0;
    }
    for (my $fxnr=0; $fxnr<=1; $fxnr++){
        $FXtype[$fxnr]=$effects[0];
        $FXtoggle[$fxnr]=0;
        $FXplacement=0;
    }
}

#-------------------------------------------------------------------------------------------------------------------------
# MIDI input and output devices selection

sub MIDI_IOconfig {

    $midi_settings->Label(%TitleLbl_defaults, -text=> 'MIDI Devices Configuration'
    )->pack(-fill=>'x', -expand=>1, -anchor=>'n');

    my $subframe=$midi_settings->Frame(
    )->pack(-fill=>'x', -expand=>1, -pady=>14);

# MIDI OUT device selection
    $subframe->Label(
        -text         => "Output MIDI Device to Korg: ",
        -font         => 'Sans 9',
        -justify      => 'right'
    )->grid(-row=>0, -column=>0, -sticky=>'e', -pady=>8);

    $midiout=$subframe->BrowseEntry(%BEntry_defaults,
        -variable     => \$midi_outdev,
        -choices      => \@midi_outdevs,
        -font         => 'Sans 9',
        -width        => 28,
        -listheight   => 9,
        -browsecmd    => sub{ MidiConSetup('out'); },
        -listcmd      => sub{ @midi_outdevs=MidiPortList('out');
                              $midiout->delete( 0, "end" );
                              $midiout->insert("end", $_) for (@midi_outdevs); }
    )->grid(-row=>0, -column=>1, -sticky=>'w', -pady=>8);

    $midiout->Subwidget("choices")->configure(%choices_defaults);
    $midiout->Subwidget("arrow")->configure(%arrow_defaults);


# MIDI IN device selection
    $subframe->Label(
        -text         => "Input MIDI Device from Korg: ",
        -font         => 'Sans 9',
        -justify      => 'right'
    )->grid(-row=>1, -column=>0, -sticky=>'e', -pady=>8);

    $midiin=$subframe->BrowseEntry(%BEntry_defaults,
        -variable     => \$midi_indev,
        -choices      => \@midi_indevs,
        -font         => 'Sans 9',
        -width        => 28,
        -listheight   => 9,
        -browsecmd    => sub{ MidiConSetup('in'); },
        -listcmd      => sub{ @midi_indevs=MidiPortList('in');
                              $midiin->delete( 0, "end" );
                              $midiin->insert("end", $_) for (@midi_indevs); }
    )->grid(-row=>1, -column=>1, -sticky=>'w', -pady=>8);

    $midiin->Subwidget("choices")->configure(%choices_defaults);
    $midiin->Subwidget("arrow")->configure(%arrow_defaults);

}

#-------------------------------------------------------------------------------------------------------------------------
# Main Program Editor Frame

sub Main_Prg_Frame {

    my $subframe=StdFrame(\$Main_Prg,'Main Program Parameters');

# Program Name
    my $pname=$subframe->Frame()->grid(-columnspan=>2);

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
            -command  => sub{ SendPaChMsg(0,$osc_mode);
                              # disable Osc2 tab if single or drums mode
                              if ($osc_mode == 1) {
                                  $book->pageconfigure('Tab2',-state=>'normal') }
                              else {
                                  $book->pageconfigure('Tab2',-state=>'disabled') }
                         }
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
            -command  => sub{ SendPaChMsg(1,$assign); }
        )->pack(-side=>'left');
    }

# Hold
    $asshldf->Label(-text=>'  Hold: ', -font=>'Sans 8')->pack(-side=>'left');
    $asshldf->Checkbutton(
        -text         => 'on/off',
        -font         => 'Sans 8',
        -variable     => \$hold,
        -command      => sub{ SendPaChMsg(2,$hold); }
    )->pack(-side=>'left');

# Sliders
    StdSlider(\$subframe, \$interval, -12, 12,  3, 1, 88, 'Osc1 / Osc2 Pitch Interval');
    StdSlider(\$subframe, \$detune,   -50, 50, 10, 1, 89, 'Detune Osc1 / Osc2');
    StdSlider(\$subframe, \$delay,      0, 99, 11, 1, 90, 'Delay Osc2 Start (ms)');
}

#-------------------------------------------------------------------------------------------------------------------------
# Pitch EG Frame

sub Pitch_EG_Frame {
    my $subframe=StdFrame(\$Pitch_EG,'Pitch Envelope Generator');
    StdSlider(\$subframe, \$PEG_SL,    -99, 99, 22, 1,  3, 'Start Level');
    StdSlider(\$subframe, \$PEG_AT,      0, 99, 11, 1,  4, 'Attack Time');
    StdSlider(\$subframe, \$PEG_AL,    -99, 99, 22, 1,  5, 'Attack Level');
    StdSlider(\$subframe, \$PEG_DT,      0, 99, 11, 1,  6, 'Decay Time');
    StdSlider(\$subframe, \$PEG_RT,      0, 99, 11, 1,  7, 'Release Time');
    StdSlider(\$subframe, \$PEG_RL,    -99, 99, 22, 1,  8, 'Release Level');
    StdSlider(\$subframe, \$PEG_level, -99, 99, 22, 1,  9, 'PEG Level Velocity Sensitivity');
    StdSlider(\$subframe, \$PEG_time,  -99, 99, 22, 1, 10, 'PEG Time Velocity Sensitivity');
}

#-------------------------------------------------------------------------------------------------------------------------
# Aftertouch Frame

sub Aftertouch_Frame {
    my $subframe=StdFrame(\$Aftertouch,'Aftertouch');
    StdSlider(\$subframe, \$AT_PBrange, -12, 12,  2, 1, 17, 'Pitch Bend Range');
    StdSlider(\$subframe, \$AT_VDFcoff, -99, 99, 22, 1, 18, 'VDF Cutoff Frequency');
    StdSlider(\$subframe, \$AT_VDFmgint,  0, 99, 11, 1, 19, 'VDF Modulation Intensity');
    StdSlider(\$subframe, \$AT_VDAamp,  -99, 99, 22, 1, 20, 'VDA Amplitude');
}

#-------------------------------------------------------------------------------------------------------------------------
# Joystick Frame

sub Joystick_Frame {
    my $subframe=StdFrame(\$Joystick,'Joystick');
    StdSlider(\$subframe, \$JS_PBrange,  -12, 12,  2, 1, 22, 'Pitch Bend Range');
    StdSlider(\$subframe, \$JS_VDFswint, -99, 99, 22, 1, 23, 'VDF Sweep Intensity');
    StdSlider(\$subframe, \$JS_VDFmgint,   0, 99, 11, 1, 21, 'VDF Modulation Intensity');
}

#-------------------------------------------------------------------------------------------------------------------------
# VDF Cutoff Modulation Frame

sub VDF_Cutoff_Frame {

    my $subframe=StdFrame(\$VDF_Cutoff,'VDF Cutoff Modulation');

# Modulation Waveform
    my $modwavf=$subframe->Frame()->grid(-columnspan=>2);

    $modwavf->Label(-text=>'Modulation Waveform:', -font=>'Sans 8')->grid(-row=>0, -columnspan=>6);;
    my @modwavlabel=('tri', "saw\x{2191}", "saw\x{2193}", 'sq1', 'rnd', 'sq2');
    for (my $n=0;$n<=5;$n++) {
        $modwavf->Radiobutton(%RadioB_defaults,
            -text     => $modwavlabel[$n],
            -width    => 5,
            -value    => $n,
            -variable => \$VDFmod_wav,
            -command  => sub{ SendPaChMsg(11,$VDFmod_wav); }
        )->grid(-row=>1, -column=>$n);
    }

# OSC1 Modulation Enable
    my $vdfmodf=$subframe->Frame()->grid(-columnspan=>2);

    $vdfmodf->Label(-text=>' Osc1 ena:', -font=>'Sans 8')->pack(-side=>'left');
    $vdfmodf->Checkbutton(
        -font         => 'Sans 8',
        -variable     => \$VDF_OSC1,
        -command      => sub{ SendPaChMsg(15,$VDF_OSC1+(2*$VDF_OSC2)); }
    )->pack(-side=>'left');

# OSC2 Modulation Enable
    $vdfmodf->Label(-text=>' Osc2 ena:', -font=>'Sans 8')->pack(-side=>'left');
    $vdfmodf->Checkbutton(
        -font         => 'Sans 8',
        -variable     => \$VDF_OSC2,
        -command      => sub{ SendPaChMsg(15,$VDF_OSC1+(2*$VDF_OSC2)); }
    )->pack(-side=>'left');

# Key Sync
    $vdfmodf->Label(-text=>' Key Sync:', -font=>'Sans 8')->pack(-side=>'left');
    $vdfmodf->Checkbutton(
        -font         => 'Sans 8',
        -variable     => \$VDFkeysync,
        -command      => sub{ SendPaChMsg(16,$VDFkeysync); }
    )->pack(-side=>'left');

# Sliders
    StdSlider(\$subframe, \$VDFmgfreq, 0, 99, 11, 1, 12, 'VDF Modulation Frequency');
    StdSlider(\$subframe, \$VDFmgint,  0, 99, 11, 1, 13, 'VDF Modulation Intensity');
    StdSlider(\$subframe, \$VDFmgdly,  0, 99, 11, 1, 14, 'VDF Modulation Delay');
}

#-------------------------------------------------------------------------------------------------------------------------
# VDF EG Frame

sub VDF_EG_Frame {
    my($osc)=@_;
    my $subframe=StdFrame(\$VDF_EG[$osc],'VDF'.($osc+1).' Envelope Generator');
    StdSlider(\$subframe, \$VDF_AT[$osc],   0, 99, 11, 1, (35+($osc*67)), 'AT - Attack Time');
    StdSlider(\$subframe, \$VDF_AL[$osc], -99, 99, 22, 1, (36+($osc*67)), 'AL - Attack Level');
    StdSlider(\$subframe, \$VDF_DT[$osc],   0, 99, 11, 1, (37+($osc*67)), 'DT - Decay Time');
    StdSlider(\$subframe, \$VDF_BP[$osc], -99, 99, 22, 1, (38+($osc*67)), 'BP - Break Point');
    StdSlider(\$subframe, \$VDF_ST[$osc],   0, 99, 11, 1, (39+($osc*67)), 'ST - Slope Time');
    StdSlider(\$subframe, \$VDF_SL[$osc], -99, 99, 22, 1, (40+($osc*67)), 'SL - Sustain Level');
    StdSlider(\$subframe, \$VDF_RT[$osc],   0, 99, 11, 1, (41+($osc*67)), 'RT - Release Time');
    StdSlider(\$subframe, \$VDF_RL[$osc], -99, 99, 22, 1, (42+($osc*67)), 'RL - Release Level');
}

#-------------------------------------------------------------------------------------------------------------------------
# VDF Frame

sub VDF_Frame {
    my($osc)=@_;
    my $subframe=StdFrame(\$VDF[$osc],'VDF'.($osc+1));
    StdSlider(\$subframe, \$VDFcoffvl[$osc],   0, 99, 11, 1, (31+($osc*67)), 'Cutoff Frequency');
    StdSlider(\$subframe, \$VDF_EGint[$osc],   0, 99, 11, 1, (32+($osc*67)), 'EG Intensity');
    StdSlider(\$subframe, \$VDF_CoInt[$osc],   0, 99, 11, 1, (33+($osc*67)), 'Color Intensity');
}

#-------------------------------------------------------------------------------------------------------------------------
# VDF Velocity Sensitivity Frame

sub VDFvs_Frame {
    my($osc)=@_;
    my $subframe=StdFrame(\$VDFvs[$osc],'VDF'.($osc+1).' Velocity Sensitivity');
    StdSlider(\$subframe, \$VDF_CoVSn[$osc], -99, 99, 22, 1, (34+($osc*67)), 'VDF'.($osc+1).' Color Velocity Sensitivity');
    StdSlider(\$subframe, \$VDF_EGivs[$osc], -99, 99, 22, 1, (43+($osc*67)), 'VDF'.($osc+1).' EG Intensity Velocity Sensitivity');
    StdSlider(\$subframe, \$VDF_EGtvs[$osc],   0, 99, 11, 1, (44+($osc*67)), 'VDF'.($osc+1).' EG Time Velocity Sensitivity');
    my $tmpf1=$subframe->Frame()->grid(-columnspan=>2);
    DirSwitch(\$tmpf1, \$VDF_ATtv[$osc], (45+($osc*67)), 'AT:');
    DirSwitch(\$tmpf1, \$VDF_DTtv[$osc], (46+($osc*67)), 'DT:');
    DirSwitch(\$tmpf1, \$VDF_STtv[$osc], (47+($osc*67)), 'ST:');
    DirSwitch(\$tmpf1, \$VDF_RTtv[$osc], (48+($osc*67)), 'RT:');
}

#-------------------------------------------------------------------------------------------------------------------------
# VDF Keyboard Tracking Frame

sub VDFkt_Frame {
    my($osc)=@_;
    my $subframe=StdFrame(\$VDFkt[$osc],'VDF'.($osc+1).' Keyboard Tracking');

# Keyboard Track Key
    my $VDF_kbdtk_fn=$subframe->Frame()->grid(-columnspan=>2);

    $VDF_kbdtk_fn->Label(-text=>'Keyboard Track Key: ', -font=>'Sans 8')->grid(
    my $VDF_kbdtk_entry=$VDF_kbdtk_fn->BrowseEntry(%BEntry_defaults,
        -variable     => \$VDF_kbdtk[$osc],
        -choices      => \@notes,
        -width        => 5,
        -font         => 'Fixed 8',
        -browsecmd    => sub{ SendPaChMsg((49+($osc*67)),$noteshash{$VDF_kbdtk[$osc]}); }
    ), -pady=>4);
    $VDF_kbdtk_entry->Subwidget("choices")->configure(%choices_defaults);
    $VDF_kbdtk_entry->Subwidget("arrow")->configure(%arrow_defaults);

# Keyboard Track Mode
    my $ktmodef=$subframe->Frame()->grid(-columnspan=>2);

    $ktmodef->Label(-text=>'Mode:', -font=>'Sans 8')->grid(-row=>0, -column=>0);
    my @ktmodelabel=('off','low','high','all');
    for (my $n=0;$n<=3;$n++) {
        $ktmodef->Radiobutton(
            -text     => $ktmodelabel[$n],
            -font     => 'Fixed 8',
            -value    => $n,
            -variable => \$VDFktmode[$osc],
            -command  => sub{ SendPaChMsg((50+($osc*67)),$VDFktmode[$osc]); }
        )->grid(-row=>0, -column=>$n+1);
    }

# Sliders
    StdSlider(\$subframe, \$VDFcoffkt[$osc], -99, 99, 22, 1, (51+($osc*67)), 'Cutoff Keyboard Tracking Intensity');
    StdSlider(\$subframe, \$VDF_EGtkt[$osc],   0, 99, 11, 1, (52+($osc*67)), 'VDF'.($osc+1).' EG Time Keyboard Tracking');

# Direction switches
    my $tmpf2=$subframe->Frame()->grid(-columnspan=>2);
    DirSwitch(\$tmpf2, \$VDF_ATtk[$osc], (53+($osc*67)), 'AT:');
    DirSwitch(\$tmpf2, \$VDF_DTtk[$osc], (54+($osc*67)), 'DT:');
    DirSwitch(\$tmpf2, \$VDF_STtk[$osc], (55+($osc*67)), 'ST:');
    DirSwitch(\$tmpf2, \$VDF_RTtk[$osc], (56+($osc*67)), 'RT:');
}

#-------------------------------------------------------------------------------------------------------------------------
# VDA EG Frame

sub VDA_EG_Frame {
    my($osc)=@_;
    my $subframe=StdFrame(\$VDA_EG[$osc],'VDA'.($osc+1).' Envelope Generator');
    StdSlider(\$subframe, \$VDAosclv[$osc], 0, 99, 11, 1, (25+($osc*67)), 'Oscillator Level');
    StdSlider(\$subframe, \$VDA_AT[$osc],   0, 99, 11, 1, (57+($osc*67)), 'AT - Attack Time');
    StdSlider(\$subframe, \$VDA_AL[$osc],   0, 99, 11, 1, (58+($osc*67)), 'AL - Attack Level');
    StdSlider(\$subframe, \$VDA_DT[$osc],   0, 99, 11, 1, (59+($osc*67)), 'DT - Decay Time');
    StdSlider(\$subframe, \$VDA_BP[$osc],   0, 99, 11, 1, (60+($osc*67)), 'BP - Break Point');
    StdSlider(\$subframe, \$VDA_ST[$osc],   0, 99, 11, 1, (61+($osc*67)), 'ST - Slope Time');
    StdSlider(\$subframe, \$VDA_SL[$osc],   0, 99, 11, 1, (62+($osc*67)), 'SL - Sustain Level');
    StdSlider(\$subframe, \$VDA_RT[$osc],   0, 99, 11, 1, (63+($osc*67)), 'RT - Release Time');
}

#-------------------------------------------------------------------------------------------------------------------------
# VDA Velocity Sensitivity Frame

sub VDAvs_Frame {
    my($osc)=@_;
    my $subframe=StdFrame(\$VDAvs[$osc],'VDA'.($osc+1).' Velocity Sensitivity');

# Sliders
    StdSlider(\$subframe, \$VDAavs[$osc],   -99, 99, 22, 1, (64+($osc*67)), 'VDA'.($osc+1).' EG Level Velocity Sensitivity');
    StdSlider(\$subframe, \$VDAegtvs[$osc],   0, 99, 11, 1, (65+($osc*67)), 'VDA'.($osc+1).' EG Time Velocity Sensitivity');

# Direction switches
    my $tmpf1=$subframe->Frame()->grid(-columnspan=>2);
    DirSwitch(\$tmpf1, \$VDA_ATtv[$osc], (66+($osc*67)), 'AT:');
    DirSwitch(\$tmpf1, \$VDA_DTtv[$osc], (67+($osc*67)), 'DT:');
    DirSwitch(\$tmpf1, \$VDA_STtv[$osc], (68+($osc*67)), 'ST:');
    DirSwitch(\$tmpf1, \$VDA_RTtv[$osc], (69+($osc*67)), 'RT:');
}

#-------------------------------------------------------------------------------------------------------------------------
# VDA Keyboard Tracking Frame

sub VDAkt_Frame {
    my($osc)=@_;
    my $subframe=StdFrame(\$VDAkt[$osc],'VDA'.($osc+1).' Keyboard Tracking');

# Keyboard Track Key
    my $tmpf1=$subframe->Frame()->grid(-columnspan=>2);

    $tmpf1->Label(-text=>'Keyboard Track Key: ', -font=>'Sans 8')->grid(
    my $VDA_kbdtk_entry=$tmpf1->BrowseEntry(%BEntry_defaults,
        -variable     => \$VDA_kbdtk[$osc],
        -choices      => \@notes,
        -width        => 5,
        -font         => 'Fixed 8',
        -browsecmd    => sub{ SendPaChMsg((70+($osc*67)),$noteshash{$VDA_kbdtk[$osc]}); }
    ), -pady=>4);
    $VDA_kbdtk_entry->Subwidget("choices")->configure(%choices_defaults);
    $VDA_kbdtk_entry->Subwidget("arrow")->configure(%arrow_defaults);

# Keyboard Track Mode
    my $ktmodef=$subframe->Frame()->grid(-columnspan=>2);

    $ktmodef->Label(-text=>'Mode:', -font=>'Sans 8')->grid(-row=>0, -column=>0);
    my @ktmodelabel=('off','low','high','all');
    for (my $n=0;$n<=3;$n++) {
        $ktmodef->Radiobutton(
            -text     => $ktmodelabel[$n],
            -font     => 'Fixed 8',
            -value    => $n,
            -variable => \$VDAktmode[$osc],
            -command  => sub{ SendPaChMsg((71+($osc*67)),$VDAktmode[$osc]); }
        )->grid(-row=>0, -column=>$n+1);
    }

# Sliders
    StdSlider(\$subframe, \$VDAakti[$osc],  -99, 99, 22, 1, (72+($osc*67)), 'VDA'.($osc+1).' EG Level Keyboard Tracking');
    StdSlider(\$subframe, \$VDAegtkt[$osc],   0, 99, 11, 1, (73+($osc*67)), 'VDA'.($osc+1).' EG Time Keyboard Tracking');

# Direction switches
    my $tmpf2=$subframe->Frame()->grid(-columnspan=>2);
    DirSwitch(\$tmpf2, \$VDA_ATtk[$osc], (74+($osc*67)), 'AT:');
    DirSwitch(\$tmpf2, \$VDA_DTtk[$osc], (75+($osc*67)), 'DT:');
    DirSwitch(\$tmpf2, \$VDA_STtk[$osc], (76+($osc*67)), 'ST:');
    DirSwitch(\$tmpf2, \$VDA_RTtk[$osc], (77+($osc*67)), 'RT:');
}

#-------------------------------------------------------------------------------------------------------------------------
# Pitch Modulation Generator Frame

sub Pitch_MG_Frame {
    my($osc)=@_;
    my $subframe=StdFrame(\$Pitch_MG[$osc],'Pitch'.($osc+1).' Modulation Generator');

# Key Sync
    my $keysyncf=$subframe->Frame()->grid(-columnspan=>2);

    $keysyncf->Label(-text=>'  Key Sync:', -font=>'Sans 8')->pack(-side=>'left');
    $keysyncf->Checkbutton(
        -font         => 'Sans 8',
        -text         => 'on/off',
        -variable     => \$PMGkeysync[$osc],
        -command      => sub{ SendPaChMsg((83+($osc*67)),$PMGkeysync[$osc]); }
    )->pack(-side=>'left');

# Modulation Waveform
    my $modwavf=$subframe->Frame()->grid(-columnspan=>2);

    $modwavf->Label(-text=>'Modulation Waveform:', -font=>'Sans 8')->grid(-row=>0, -columnspan=>6);
    #my @modwavlabel=('tri', "saw\x{2191}", "saw\x{2193}", 'sqr1', 'rand', 'sqr2');
    my @modwavlabel=('tri.xbm', 'sawup.xbm', 'sawdn.xbm', 'square.xbm', 'rand.xbm', 'square2.xbm');
    for (my $n=0;$n<=5;$n++) {
        $modwavf->Radiobutton(%RadioB_defaults,
            -bitmap   => '@'.$modwavlabel[$n],
            -value    => $n,
            -width    => 35,
            -height   => 23,
            -variable => \$PMGmod_wav[$osc],
            -command  => sub{ SendPaChMsg((78+($osc*67)),$PMGmod_wav[$osc]); }
        )->grid(-row=>1, -column=>$n);
    }

# Sliders
    StdSlider(\$subframe, \$PMG_freq[$osc],   0, 99, 11, 1, (79+($osc*67)), 'Frequency');
    StdSlider(\$subframe, \$PMG_Int[$osc],    0, 99, 11, 1, (80+($osc*67)), 'Intensity');
    StdSlider(\$subframe, \$PMG_dly[$osc],    0, 99, 11, 1, (81+($osc*67)), 'Initial Delay');
    StdSlider(\$subframe, \$PMG_Fin[$osc],    0, 99, 11, 1, (82+($osc*67)), 'Fade In');
    StdSlider(\$subframe, \$PMG_FMKT[$osc], -99, 99, 22, 1, (84+($osc*67)), 'Frequency Modulation by Keyboard Track');
    StdSlider(\$subframe, \$PMG_FMAJ[$osc],   0,  9,  1, 1, (85+($osc*67)), 'Frequency Modulation by AT + JS');
    StdSlider(\$subframe, \$PMG_IMA[$osc],    0, 99, 11, 1, (86+($osc*67)), 'Intensity Modulation by Aftertouch');
    StdSlider(\$subframe, \$PMG_IMJ[$osc],    0, 99, 11, 1, (87+($osc*67)), 'Intensity Modulation by Joystick');
}

#-------------------------------------------------------------------------------------------------------------------------
# Main Oscillator Frame

sub Main_Osc_Frame {
    my($osc)=@_;
    my $subframe=StdFrame(\$Main_Osc[$osc],'Osc'.($osc+1).' Main');

# Multisound
    my $OSC_msnd_fn=$subframe->Frame()->grid(-columnspan=>2);

    $OSC_msnd_fn->Label(-text=>'Multisound: ', -font=>'Sans 8')->grid(
    my $OSC_msnd_entry=$OSC_msnd_fn->BrowseEntry(%BEntry_defaults,
        -variable     => \$msound[$osc],
        -choices      => \@X5D_msounds,
        -width        => 15,
        -font         => 'Fixed 8',
        -browsecmd    => sub{ SendPaChMsg((24+($osc*67)),($msound[$osc]=~/^(\d\d\d):.*/)); }
    ));
    $OSC_msnd_entry->Subwidget("choices")->configure(%choices_defaults);
    $OSC_msnd_entry->Subwidget("arrow")->configure(%arrow_defaults);

# Octave
    my $octavef=$subframe->Frame()->grid(-columnspan=>2);

    $octavef->Label(-text=>'Octave: ', -font=>'Sans 8')->grid(-row=>0, -column=>0);
    my @octavelabel=(['4\'','1'],['8\'','0'],['16\'','-1'],['32\'','-2']);
    for (my $n=0;$n<=3;$n++) {
        $octavef->Radiobutton(
            -text     => $octavelabel[$n][0],
            -font     => 'Fixed 8',
            -value    => $octavelabel[$n][1],
            -variable => \$octave[$osc],
            -command  => sub{ SendPaChMsg((26+($osc*67)),$octave[$osc]); }
        )->grid(-row=>0, -column=>$n+1);
    }

# Pitch EG Intensity
    StdSlider(\$subframe, \$PEG_Int[$osc],   -99, 99, 22, 1, (27+($osc*67)), 'Pitch EG Intensity');

# Custom Pan Slider Subroutine
    my $pancurr=$panval[($ABPan[$osc]+1)];
    $subframe->Scale(%Scale_defaults,
        -variable     =>  \$ABPan[$osc],
        -to           =>  30,
        -from         =>  -1,
        -tickinterval =>  0,
        -label        =>  'Pan (OFF,A<-CNT->B)',
        -command      => sub{ $pancurr=$panval[($ABPan[$osc]+1)]; SendPaChMsg((28+($osc*67)),$ABPan[$osc]); }
    )->grid(
    $subframe->Label(%Scale_label_defaults,
        -width        => 4,
        -textvariable => \$pancurr
    ),-padx=>4);

# Sliders
    StdSlider(\$subframe, \$Csend_lvl[$osc],   0,  9,  1, 1, (29+($osc*67)), 'C Send Level');
    StdSlider(\$subframe, \$Dsend_lvl[$osc],   0,  9,  1, 1, (30+($osc*67)), 'D Send Level');

}

#-------------------------------------------------------------------------------------------------------------------------
# Main Effects Frame
sub Main_FX_Frame {
    my($fxnr)=@_;
    my $subframe=StdFrame(\$Main_FX[$fxnr],'Effect '.($fxnr+1));

# Effect on/off
    my $fxtogglef=$subframe->Frame()->grid(-columnspan=>2);

    $fxtogglef->Label(-text=>'Effect'.($fxnr+1).':', -font=>'Sans 8')->pack(-side=>'left');
    $fxtogglef->Checkbutton(
        -font         => 'Sans 8',
        -text         => 'on/off',
        -variable     => \$FXtoggle[$fxnr],
        -command      => sub{ SendPaChMsg((157+($fxnr*1)),$FXtoggle[$fxnr]); }
    )->pack(-side=>'left');

# Effect Type
    my $FX_type_fn=$subframe->Frame()->grid(-columnspan=>2);

    $FX_type_fn->Label(-text=>'Effect Type: ', -font=>'Sans 8')->grid(
    my $FX_type_entry=$FX_type_fn->BrowseEntry(%BEntry_defaults,
        -variable     => \$FXtype[$fxnr],
        -choices      => \@effects,
        -width        => 25,
        -font         => 'Fixed 8',
        -browsecmd    => sub{ SendPaChMsg((155+$fxnr),($FXtype[$fxnr]=~/^(\d\d):.*/)); }
    ));
    $FX_type_entry->Subwidget("choices")->configure(%choices_defaults);
    $FX_type_entry->Subwidget("arrow")->configure(%arrow_defaults);
}

#-------------------------------------------------------------------------------------------------------------------------
# FX Placement Selection
sub FX_Place_Frame {
    my $subframe=StdFrame(\$FX_Place,'Effects Placement');

    my $fxplacef=$subframe->Frame()->grid(-columnspan=>2);
    my @fxplacelabel=(['x5dr-fx-serial.png'   , 'Serial'    ],
                      ['x5dr-fx-parallel1.png', 'Parallel 1'],
                      ['x5dr-fx-parallel2.png', 'Parallel 2'],
                      ['x5dr-fx-parallel3.png', 'Parallel 3']);
    for (my $n=0;$n<=3;$n++) {
        $fxplacef->Radiobutton(
            -padx        => 0,
            -value       => $n,
            -variable    => \$FXplacement,
            -command     => sub{ SendPaChMsg(165,$FXplacement); }
        )->grid(-row=>$n, -column=>0, -sticky=>'ne');
        my $image=$subframe->Photo(-file=>$fxplacelabel[$n][0]);
        $fxplacef->Label(
            -image       => $image,
            -borderwidth => 0,
            -anchor      =>'n'
        )->grid(-row=>$n, -column=>1, -ipady=>2);
        $fxplacef->Label(
            -background  => 'white',
            -text        => $fxplacelabel[$n][1]
        )->grid(-row=>$n, -column=>1, -sticky=>'nw');
    }
}

#-------------------------------------------------------------------------------------------------------------------------

