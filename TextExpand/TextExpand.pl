#!/usr/bin/perl

use strict;
use Data::Dumper;
use Term::ANSIColor;

&PrintLogo;
my $script = `basename $0`;
chomp($script);

my $ifile = &Parser;
my $mode = &QA;

my $ofile = sprintf("exp_%s",$ifile);

open(IF,$ifile);
open(OF,"> $ofile");
while(<IF>){
  chomp;
 
  if($_ =~ /\w+\[\d+\:\d+\]/){
    my @reg = split(/\s+/,$_);
    my $bitchk = "N"; #bit check
    my ($part1,$part2,$part3);
    foreach my $i(@reg){
      if(($bitchk eq "N") && ($i !~ /\w+\[\d+\:\d+\]/)){
        if($part1 eq ""){
          $part1 = $i;
        }else{
          $part1 = sprintf("%s %s",$part1,$i);
        }
      }elsif(($bitchk eq "N") && ($i =~ /\w+\[\d+\:\d+\]/)){
        $bitchk = "Y";
        $part2 = &Expand($i);
      }else{ ## bitchk = Y;
        if($part3 eq ""){
          $part3 = $i;
        }else{
          $part3 = sprintf("%s %s",$part3,$i);
        }
      } 
    }
    
    my @reg2 = split(/\s+/,$part2);
    if($mode == 1){
      foreach my $i(@reg2){
        my $fullLine;
        if(! $part1){
          $fullLine = sprintf("%s %s",$i,$part3);
        }else{
          $fullLine = sprintf("%s %s %s",$part1,$i,$part3);
        }
        print OF "$fullLine\n";
      }
    }elsif($mode == 2){
      my $line = 0;
      my $sLen = length($part1);
      foreach my $i(@reg2){
        if($line < 1){
          my $fullLine;
          if(! $part1){
            $fullLine = sprintf("%s %s",$i,$part3);
          }else{
            $fullLine = sprintf("%s %s %s",$part1,$i,$part3);
          }
          print OF "$fullLine\n";
          $line++;
        }else{
          my $fullLine;
          if(! $part1){
            $fullLine = sprintf("%s",$i);
          }else{
            $fullLine = sprintf("%s %s"," "x$sLen,$i);
          }
          print OF "$fullLine\n";
        }
      }
    }
  }else{
    print OF "$_\n";
  }

}
close OF;
close IF;
    
sub QA{
  print "\n################################\n";
  print "1. keep data in the same row\n";
  print "2. only expand text\n";
  print "Select function mode:  ";
  my $mode = <STDIN>;
  chomp($mode);

  if($mode !~ /1|2/){
    print color('red');
    print "error: Only 1 or 2. \n";
    print color('reset');
  }

  return($mode);
}

sub Expand{
  my $text = shift;
  
  my $pins;
  my @reg = split(/\[/,$text);
  my $name = $reg[0];
  my $bits = $reg[1];
  $bits =~ s/\]//g;
  my @reg2 = split(/\:/,$bits);
  my $b1 = $reg2[0]; ##left bit
  my $b2 = $reg2[1]; ##right bit

  if($b1 > $b2){
    for(my $i=$b1; $i>=$b2; $i--){
      if($pins eq ""){
        $pins = sprintf("%s[%d]",$name,$i);
      }else{
        $pins = sprintf("%s %s[%d]",$pins,$name,$i);
      }
    }
  }else{
    for(my $i=$b1; $i<=$b2; $i++){
      if($pins eq ""){
        $pins = sprintf("%s[%d]",$name,$i);
      }else{
        $pins = sprintf("%s %s[%d]",$pins,$name,$i);
      }
    }
  }

  return($pins);
}

sub Parser{
  &PrintHelp if(!@ARGV);
  
  my $ifile = $ARGV[0];

  return($ifile);
}

sub PrintLogo{
  system(clear);
  print color('magenta');
  print <<LOGO;
     /|  |         _____    
    |:|  |        /::\\  \\   
    |:|  |       /:/\\:\\  \\  
  __|:|  |      /:/ /::\\__\\ 
 /\\ |:|__|____ /:/_/:/\\:|__|
 \\:\\/:::::/__/ \\:\\/:/ /:/  /
  \\::/~~/~      \\::/_/:/  / 
   \\:\\~~\\        \\:\\/:/  /  
    \\:\\__\\        \\::/  /   
     \\/__/         \\/__/   Studio
LOGO
  print color('reset');
}

sub PrintHelp{
  print <<HELP;
\n Usage:
  \t$script <file>
HELP
  exit;
}

