#!/usr/bin/perl

use strict;
use Data::Dumper;

my $script = `basename $0`;
chomp($script);

my ($file,$subckt,$ins) = &Parser;
#print Dumper($file,$subckt,$ins);

my $TmpF = "\.${file}_tmp_$$";
my $cmd_cp = qq(cp $file $TmpF);
system($cmd_cp);
sleep 3;

my ($replAns,$insAns,$cntAns) = &Ans($subckt,$ins);
my $SW = "N";
my $SW_cnt = "N";
my %cnt; ##keys:PINs,I,O,B
my $out;
open(OF,"> $file");
open(IF,"$TmpF");
while(<IF>){
  chomp;

  if($replAns eq "Y"){ ##replace subckt name
    $_ =~ s/$subckt/${subckt}_1/g;
  }
  if($_ =~ /^\.SUBCKT\s+/){
    if($replAns eq "Y"){
      if($_ =~ /\s+${subckt}_1\s+/){
        $SW = "Y";
      }
    }else{
      if($_ =~ /\s+${subckt}\s+/){
        $SW = "Y";
      }
    }
    if($SW eq "Y"){
      $SW_cnt = "Y";
      &CntPinInfo($_);
    }
    print OF "$_\n";
    next;
  }elsif($_ =~ /^\.ENDS/){
    if($SW eq "Y"){
      if($insAns eq "Y"){
        $out = sprintf("%s",$ins);
      }
      $SW = "N";
    }
    $out = sprintf("%s%s\n",$out,$_);
    print OF "$out";
    $out = "";
    next;
  }else{
    $SW_cnt = &CntPinInfo($_) if($SW_cnt eq "Y"); ##go to count number of pin and switch SW_cnt
    print OF "$_\n";
    next;
  }
}
print OF "$out";
close IF;
close OF;
system("rm -f $TmpF");

##print number of pin
print <<CNT;
***********************
* Pins = $cnt{PINs}
*   I  = $cnt{I}
*   O  = $cnt{O}
*   B  = $cnt{B}
***********************
CNT
exit;



sub Parser{
  &PrintHelp if(!@ARGV);

  my ($file,$sub,$ins);
  for(my $i=0; $i<= $#ARGV; $i++){
    if($ARGV[$i] eq "-f"){
      $file = $ARGV[$i+1];
      $i++;
    }elsif($ARGV[$i] eq "-sub"){
      $sub = $ARGV[$i+1];
      $i++;
    }elsif($ARGV[$i] eq "-ins"){
      if(-f $ARGV[$i+1]){
        my $f;
        open(INS,"$ARGV[$i+1]");
        while(<INS>){
          chomp;
          if(!$f){
            $f = sprintf("%s\n",$_);
          }else{
            $f = sprintf("%s%s\n",$f,$_);
          }
        }
        close INS;
        $ins = $f;
      }else{
        $ins = "$ARGV[$i+1]\n";
      }
      $i++;
    }else{  &PrintHelp; }
  }
  return($file,$sub,$ins);
}

sub Ans{
  chomp(my ($subckt,$ins) = @_);
  
##Rename
  print "Do rename $subckt to ${subckt}_1 [Y/N]?";
  my $ans;

  while($ans = <STDIN>){
    if($ans !~ /y|n/i){
      print "Only allow Y/N\n";
      print "Do renmae $subckt to ${subckt}_1 [Y/N]?";
    }else{last;}
  }
  chomp(my $replans = uc($ans));

##Insert
  print "Do insert XXX in $subckt [Y/N]?";
  while($ans = <STDIN>){
    if($ans !~ /y|n/i){
      print "Only allow Y/N\n";
      print "Do insert XXX in $subckt [Y/N]?";
    }else{last;}
  }
  chomp(my $insans = uc($ans));

##count pins
  print "Do count number of pin in $subckt [Y/N]?";
  while($ans = <STDIN>){
    if($ans !~ /y|n/i){
      print "Only allow Y/N\n";
      print "Do count number of pin in $subckt [Y/N]?";
    }else{last;}
  }
  chomp(my $cntans = uc($ans));

  return($replans,$insans,$cntans); 
}

sub CntPinInfo{
  my $line = shift;
  my $rSW = "Y";

  if($line =~ /^\.SUBCKT\s+$subckt/){
    my @reg = split(/\s+/,$line);
    my $size = scalar @reg;
    $cnt{"PINs"} = $size - 2;
  }elsif($line =~ /^\+\s+\w+/){
    my @reg = split(/\s+/,$line);
    my $size = scalar @reg;
    $cnt{"PINs"} = $cnt{"PINs"} + $size - 1;
  }elsif($line =~ /^\*\.PININFO\s+/){
    my @reg = split(/\s+/,$line);
    foreach my $i (@reg){
      next if($i =~ /PININFO/);
      if($i =~ /\S+\:(I|O|B)/){
        my $iob = $1;
        $cnt{$iob}++;
      }
    }
  }else{
    $rSW = "N";
  }

  return($rSW);
}

sub PrintHelp{
  print <<HELP;
  \t$script -f <file> -sub <subckt> -ins <insert text or file>
HELP
  exit;
}
