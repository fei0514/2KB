#!/usr/bin/perl

use strict;
use Data::Dumper;
use Term::ANSIColor;

my $script = `basename $0`;
chomp($script);

system("clear");
&PrintLogo;
my ($file) = &Parser;
#print Dumper($file,$subckt,$ins);

my ($subAns) = &Ans();
#my ($subAns) = "mom34c"; ##Test
#my ($subAns) = "inv2"; ##Test
my $PrintLen = 10;
my $ofile = sprintf("Call_Pin_List_%s",$subAns);
my %subckt;  ##{M|S}{subclt} = @pins
my @order = qw(S M); ##first print Slave , second print Master
open(OF,"> $ofile");
open(IF,"$file");
while(<IF>){ ## find User's subckt information
  chomp;

  if($_ =~ /^\.SUBCKT\s+/i){
    if($_ =~ /\s+${subAns}\s+/){
      my @reg = split(/\s+/,$_);
      foreach my $i(@reg){
        next if($i =~ /\.SUBCKT/i);
        if($i ne "$subAns"){
           push @{$subckt{M}{$subAns}},$i;
        }
      }
      last;
    }
  }
}
close IF;

my $subAns2 = "\$\[$subAns\]";
open(IF,"$file");
while(<IF>){ ## find subckt that use user subckt
  chomp;

  next if(($_ =~ /SUBCKT/i) || ($_ =~ /^\s*\*/)); ## exclude master subckt
  next if(($_ !~ /\s+\S*$subAns/) && ($_ !~ /\s+\S*$subAns2/)); ##
  my @reg = split(/\s+/,$_);
  my $check = "N";
  my @string;
  for(my $i=1; $i<=$#reg; $i++){
    next if($reg[$i] !~ /\w+/);
    if(($reg[$i] eq "$subAns") || ($reg[$i] eq "$subAns2")){ ##detect subAns is exists
      $check = "Y";
      next; ## dont record this $subAns
    }
    push @string,$reg[$i];
  }
  if($check eq "Y"){
    $subckt{S}{$reg[0]} = [@string];
  }
    
}
close IF;
#print Dumper(%{$subckt{S}});exit;

my $RowTotal;
my @output;
my @hashKey;
foreach my $s(@order){
  #foreach my $k(sort{$a<=>$b} keys %{$subckt{$s}}){
  foreach my $k(sort keys %{$subckt{$s}}){
    if($output[0] eq ""){
      $output[0] = $k;
    }else{
      $output[0] = sprintf("%-${PrintLen}s%-${PrintLen}s",$output[0],$k);
    }
  push @hashKey,$k;
  $RowTotal++;
  }
}

#print Dumper(%{subckt});exit;
my $OUT = "Y";
my $indexO = 1; ##start from output[1]
my $EndChk = 0;
while($OUT eq "Y"){
  my $string;
  my $RowCount;
  my $s;
  foreach my $k (@hashKey){
    $RowCount++;
    if($RowCount < $RowTotal){
      $s = "S";
    }else{
      $s = "M";
    }
    if($output[$indexO] eq ""){
      $output[$indexO] = $subckt{$s}{$k}[$indexO-1];
    }else{
      $output[$indexO] = sprintf("%-${PrintLen}s%-${PrintLen}s",$output[$indexO],$subckt{$s}{$k}[$indexO-1]);
    }
    my $chk = scalar(@{$subckt{$s}{$k}});
    $EndChk++ if($chk == $indexO);
  }

  if($EndChk == $RowTotal){
    $OUT = "N";
    last;
  }

  $indexO++;
}
print Dumper(\@output);
  
##print number of pin
#my $ofile = qq(${subckt}_pin);
#open(OF,">$ofile");
#print OF <<CNT;
#***********************
#* Pins = $cnt{PINs}
#*   I  = $cnt{I}
#*   O  = $cnt{O}
#*   B  = $cnt{B}
#***********************
#CNT
#
#my @pinSort = qw(NAME I O B);
#foreach my $s (@pinSort){
#  print OF "***********************\n";
#  print OF "$s => \n";
#  print OF "$pins{$s}\n\n";
#}
#close OF;
#
exit;



sub Parser{
  &PrintHelp if(!@ARGV);

  my ($file);
  for(my $i=0; $i<= $#ARGV; $i++){
    if($ARGV[$i] eq "-f"){
      $file = $ARGV[$i+1];
      $i++;
    }else{  &PrintHelp; }
  }
  return($file);
}

sub Ans{
  
  my $ans;
##Subckt information
  print "which subckt call information you want get ? ";
  $ans = <STDIN>;
  chomp($ans);

  return($ans); 
}

sub PrintLogo{
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
  \t$script -f <file> 
HELP
  exit;
}

