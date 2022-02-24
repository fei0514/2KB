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

my $SW = "N";
my $SW_sub = "N";
my $out;
open(OF,"> $file");
open(IF,"$TmpF");
while(<IF>){
  chomp;
  if((($_ =~ /^\s*\*/) || ($_ =~ /^\s*$/)) && ($SW_sub eq "N")){
    print OF "$_\n";
    next;
  }elsif($_ =~ /^\.SUBCKT\s+/){
    $SW_sub = "Y";
    if($_ =~ /\s+$subckt\s+/){
      $SW = "Y";
    }
    $out = sprintf("%s\n",$_);
    next;
  }elsif($_ =~ /^\.ENDS\s+/){
    $SW_sub = "N";
    if($SW eq "Y"){
      $out = sprintf("%s%s",$out,$ins);
      $SW = "N";
    }
    $out = sprintf("%s%s\n",$out,$_);
    print OF "$out";
    $out = "";
  }else{
    $_ =~ s/$subckt/${subckt}_1/g;
    $out = sprintf("%s%s\n",$out,$_);
  }
}
print OF "$out";
close IF;
close OF;
system("rm -f $TmpF");

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

sub PrintHelp{
print <<HELP;
\t$script -f <file> -sub <subckt> -ins <insert text or file>
HELP
exit;
}
